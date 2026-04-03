"""
============================================================
FLASK ROUTES - Live Volunteer Map Feature
============================================================
Add these routes to your Flask backend (e.g., app.py or routes.py)

Features:
- POST /api/volunteers/update-location - Update volunteer's current location
- GET /api/volunteers/with-location - Fetch all volunteers with live location
- POST /api/volunteers/toggle-location-sharing - Privacy control
- GET /api/volunteers/nearby - Get volunteers within radius (for mobile)

All endpoints include:
- Input validation
- Error handling
- Clean JSON responses
- Location privacy checks (is_location_shared flag)
============================================================
"""

from flask import request, jsonify, current_app
from datetime import datetime, timedelta
from functools import wraps
import math
import uuid

# Assume you have database connection setup
# from app import db, Volunteer  (adjust imports based on your structure)


# ============================================================
# HELPERS
# ============================================================

def calculate_distance(lat1, lon1, lat2, lon2):
    """
    Calculate distance between two coordinates in kilometers.
    Uses Haversine formula for accuracy over long distances.
    """
    if not all([lat1, lon1, lat2, lon2]):
        return None
    
    R = 6371  # Earth radius in km
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lon2 - lon1)
    
    a = math.sin(delta_phi / 2) ** 2 + \
        math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda / 2) ** 2
    c = 2 * math.asin(math.sqrt(a))
    
    return round(R * c, 2)


def require_valid_location(f):
    """Decorator to validate location data in request."""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'Request body is empty'}), 400
        
        # Validate latitude
        try:
            latitude = float(data.get('latitude'))
            if not -90 <= latitude <= 90:
                return jsonify({'error': 'Latitude must be between -90 and 90'}), 422
        except (TypeError, ValueError):
            return jsonify({'error': 'Invalid latitude format'}), 422
        
        # Validate longitude
        try:
            longitude = float(data.get('longitude'))
            if not -180 <= longitude <= 180:
                return jsonify({'error': 'Longitude must be between -180 and 180'}), 422
        except (TypeError, ValueError):
            return jsonify({'error': 'Invalid longitude format'}), 422
        
        return f(*args, **kwargs)
    return decorated_function


# ============================================================
# ENDPOINT 1: UPDATE VOLUNTEER LOCATION
# ============================================================

@current_app.route('/api/volunteers/update-location', methods=['POST'])
@require_valid_location
def update_volunteer_location():
    """
    Update current volunteer's location.
    
    Called by mobile app every 30-60 seconds to send live location.
    Privacy: Only updates if volunteer has enabled location sharing.
    
    Request Body:
    {
        "volunteer_id": "uuid-string",
        "latitude": 28.6139,
        "longitude": 77.2090
    }
    
    Response:
    {
        "success": true,
        "message": "Location updated successfully",
        "updated_at": "2024-01-15T10:30:45Z",
        "volunteer_id": "uuid"
    }
    """
    try:
        data = request.get_json()
        volunteer_id = data.get('volunteer_id', '').strip()
        latitude = float(data.get('latitude'))
        longitude = float(data.get('longitude'))
        
        # Validate volunteer_id
        if not volunteer_id:
            return jsonify({'error': 'volunteer_id is required'}), 422
        
        # Verify volunteer exists and has location sharing enabled
        volunteer = Volunteer.query.filter_by(id=volunteer_id).first()
        if not volunteer:
            return jsonify({'error': 'Volunteer not found'}), 404
        
        if not volunteer.is_location_shared:
            return jsonify({
                'error': 'Location sharing is disabled for this volunteer',
                'success': False
            }), 403
        
        # Update location
        volunteer.latitude = latitude
        volunteer.longitude = longitude
        volunteer.last_updated = datetime.utcnow()
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Location updated successfully',
            'updated_at': volunteer.last_updated.isoformat(),
            'volunteer_id': volunteer_id
        }), 200
        
    except ValueError as e:
        return jsonify({'error': f'Invalid data type: {str(e)}'}), 422
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Server error: {str(e)}'}), 500


# ============================================================
# ENDPOINT 2: FETCH VOLUNTEERS WITH LOCATION
# ============================================================

@current_app.route('/api/volunteers/with-location', methods=['GET'])
def get_volunteers_with_location():
    """
    Fetch all volunteers with their live location.
    
    Only returns volunteers who have enabled location sharing.
    Includes calculated distance from user if user_latitude & user_longitude provided.
    
    Query Parameters (all optional):
    ?user_latitude=28.6139&user_longitude=77.2090
    &locality=Bangalore
    &radius_km=50
    
    Response:
    {
        "success": true,
        "volunteers": [
            {
                "id": "uuid",
                "name": "John Doe",
                "phone": "+91-98765-43210",
                "email": "john@example.com",
                "locality": "Bangalore",
                "city": "Bangalore",
                "state": "Karnataka",
                "skills": ["Medical", "First Aid"],
                "availability": "available_now",
                "is_active": true,
                "latitude": 28.6139,
                "longitude": 77.2090,
                "distance_km": 2.5,
                "last_updated": "2024-01-15T10:30:45Z"
            },
            ...
        ],
        "total": 15,
        "user_latitude": 28.6139,
        "user_longitude": 77.2090
    }
    """
    try:
        # Parse query parameters
        user_latitude_str = request.args.get('user_latitude')
        user_longitude_str = request.args.get('user_longitude')
        locality = request.args.get('locality', '').strip()
        radius_km_str = request.args.get('radius_km', '50')
        
        # Validate optional location parameters
        user_latitude = None
        user_longitude = None
        
        if user_latitude_str and user_longitude_str:
            try:
                user_latitude = float(user_latitude_str)
                user_longitude = float(user_longitude_str)
                
                if not (-90 <= user_latitude <= 90):
                    return jsonify({'error': 'Invalid user latitude'}), 422
                if not (-180 <= user_longitude <= 180):
                    return jsonify({'error': 'Invalid user longitude'}), 422
            except ValueError:
                return jsonify({'error': 'Invalid location coordinates'}), 422
        
        try:
            radius_km = float(radius_km_str)
            if radius_km <= 0:
                radius_km = 50
        except ValueError:
            radius_km = 50
        
        # Build query
        query = Volunteer.query.filter(
            Volunteer.consent_given.is_(True),
            Volunteer.is_location_shared.is_(True),
            Volunteer.latitude.isnot(None),
            Volunteer.longitude.isnot(None)
        )
        
        # Filter by locality if provided
        if locality:
            query = query.filter(
                Volunteer.locality.ilike(f'%{locality}%')
            )
        
        volunteers = query.all()
        
        # Filter by radius if user location provided
        if user_latitude is not None and user_longitude is not None:
            volunteers = [
                v for v in volunteers
                if (distance := calculate_distance(
                    user_latitude, user_longitude, v.latitude, v.longitude
                )) and distance <= radius_km
            ]
        
        # Sort by distance if user location provided
        if user_latitude is not None and user_longitude is not None:
            volunteers.sort(
                key=lambda v: calculate_distance(
                    user_latitude, user_longitude, v.latitude, v.longitude
                ) or float('inf')
            )
        
        # Build response with distance
        volunteers_data = []
        for volunteer in volunteers:
            vol_dict = {
                'id': str(volunteer.id),
                'name': volunteer.name,
                'phone': volunteer.phone,
                'email': volunteer.email,
                'locality': volunteer.locality,
                'city': volunteer.city,
                'state': volunteer.state,
                'skills': volunteer.skills or [],
                'availability': volunteer.availability,
                'is_active': volunteer.is_active,
                'latitude': volunteer.latitude,
                'longitude': volunteer.longitude,
                'is_location_shared': volunteer.is_location_shared,
                'last_updated': volunteer.last_updated.isoformat() if volunteer.last_updated else None,
            }
            
            # Add distance if user location provided
            if user_latitude is not None and user_longitude is not None:
                vol_dict['distance_km'] = calculate_distance(
                    user_latitude, user_longitude,
                    volunteer.latitude, volunteer.longitude
                )
            
            volunteers_data.append(vol_dict)
        
        return jsonify({
            'success': True,
            'volunteers': volunteers_data,
            'total': len(volunteers_data),
            'user_latitude': user_latitude,
            'user_longitude': user_longitude
        }), 200
        
    except Exception as e:
        return jsonify({'error': f'Server error: {str(e)}'}), 500


# ============================================================
# ENDPOINT 3: TOGGLE LOCATION SHARING (PRIVACY)
# ============================================================

@current_app.route('/api/volunteers/toggle-location-sharing', methods=['POST'])
def toggle_location_sharing():
    """
    Enable or disable location sharing for a volunteer.
    
    Request Body:
    {
        "volunteer_id": "uuid-string",
        "is_location_shared": true/false
    }
    
    Response:
    {
        "success": true,
        "message": "Location sharing enabled",
        "is_location_shared": true
    }
    """
    try:
        data = request.get_json()
        volunteer_id = data.get('volunteer_id', '').strip()
        is_location_shared = data.get('is_location_shared')
        
        # Validate inputs
        if not volunteer_id:
            return jsonify({'error': 'volunteer_id is required'}), 422
        
        if not isinstance(is_location_shared, bool):
            return jsonify({'error': 'is_location_shared must be boolean'}), 422
        
        # Find and update volunteer
        volunteer = Volunteer.query.filter_by(id=volunteer_id).first()
        if not volunteer:
            return jsonify({'error': 'Volunteer not found'}), 404
        
        volunteer.is_location_shared = is_location_shared
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Location sharing ' + ('enabled' if is_location_shared else 'disabled'),
            'is_location_shared': is_location_shared
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Server error: {str(e)}'}), 500


# ============================================================
# ENDPOINT 4: GET NEARBY VOLUNTEERS (MOBILE OPTIMIZED)
# ============================================================

@current_app.route('/api/volunteers/nearby', methods=['GET'])
def get_nearby_volunteers():
    """
    Mobile-optimized endpoint to get volunteers within radius.
    Automatically filters for location-sharing enabled volunteers.
    
    Query Parameters:
    ?latitude=28.6139&longitude=77.2090&radius_km=5&limit=20
    
    Response:
    {
        "success": true,
        "nearby": [
            {
                "id": "uuid",
                "name": "John Doe",
                "skills": ["Medical"],
                "distance_km": 0.5,
                "availability": "available_now",
                "is_active": true
            },
            ...
        ],
        "total": 5
    }
    """
    try:
        latitude_str = request.args.get('latitude')
        longitude_str = request.args.get('longitude')
        radius_km_str = request.args.get('radius_km', '5')
        limit_str = request.args.get('limit', '20')
        
        # Validate required parameters
        if not latitude_str or not longitude_str:
            return jsonify({
                'error': 'latitude and longitude are required'
            }), 422
        
        try:
            user_latitude = float(latitude_str)
            user_longitude = float(longitude_str)
            radius_km = float(radius_km_str)
            limit = int(limit_str)
            
            if not (-90 <= user_latitude <= 90):
                return jsonify({'error': 'Invalid latitude'}), 422
            if not (-180 <= user_longitude <= 180):
                return jsonify({'error': 'Invalid longitude'}), 422
            if radius_km <= 0 or radius_km > 100:
                radius_km = 5
            if limit <= 0 or limit > 100:
                limit = 20
                
        except ValueError:
            return jsonify({'error': 'Invalid coordinate format'}), 422
        
        # Fetch location-sharing enabled volunteers
        volunteers = Volunteer.query.filter(
            Volunteer.consent_given.is_(True),
            Volunteer.is_location_shared.is_(True),
            Volunteer.latitude.isnot(None),
            Volunteer.longitude.isnot(None)
        ).all()
        
        # Calculate distance and filter
        nearby = []
        for v in volunteers:
            distance = calculate_distance(
                user_latitude, user_longitude, v.latitude, v.longitude
            )
            if distance and distance <= radius_km:
                nearby.append({
                    'id': str(v.id),
                    'name': v.name,
                    'skills': v.skills or [],
                    'distance_km': distance,
                    'availability': v.availability,
                    'is_active': v.is_active,
                    'locality': v.locality,
                })
        
        # Sort by distance and limit results
        nearby.sort(key=lambda x: x['distance_km'])
        nearby = nearby[:limit]
        
        return jsonify({
            'success': True,
            'nearby': nearby,
            'total': len(nearby)
        }), 200
        
    except Exception as e:
        return jsonify({'error': f'Server error: {str(e)}'}), 500


# ============================================================
# BONUS: CLEANUP OLD LOCATIONS (Admin task)
# ============================================================

@current_app.route('/api/admin/cleanup-stale-locations', methods=['POST'])
def cleanup_stale_locations():
    """
    Admin endpoint to mark locations as outdated.
    Run this periodically (e.g., every hour) to remove locations older than 24 hours.
    """
    try:
        cutoff_time = datetime.utcnow() - timedelta(hours=24)
        
        stale_count = Volunteer.query.filter(
            Volunteer.last_updated < cutoff_time
        ).update({'is_location_shared': False})
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': f'{stale_count} stale location records disabled'
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Server error: {str(e)}'}), 500


# ============================================================
# DATABASE MODEL UPDATE
# ============================================================
"""
Update your Volunteer SQLAlchemy model to include new fields:

class Volunteer(db.Model):
    __tablename__ = 'volunteers'
    
    # ... existing columns ...
    
    # NEW COLUMNS FOR LOCATION TRACKING
    latitude = db.Column(db.Float, nullable=True)
    longitude = db.Column(db.Float, nullable=True)
    last_updated = db.Column(
        db.DateTime(timezone=True),
        default=datetime.utcnow,
        onupdate=datetime.utcnow
    )
    is_location_shared = db.Column(db.Boolean, default=False, nullable=False)
    
    # Add indexes for performance
    __table_args__ = (
        db.Index('idx_volunteers_location_shared', 'is_location_shared'),
        db.Index('idx_volunteers_coordinates', 'latitude', 'longitude'),
    )
"""
