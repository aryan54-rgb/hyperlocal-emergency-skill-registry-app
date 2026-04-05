# HOME SCREEN - Map Navigation Integration

## 📝 Add Map Button to Home Screen

To make the Live Map feature accessible, add a navigation button to your home screen.

### Option 1: Add Button in Home Screen Header

If you want to add a "View Map" button to the app bar:

```dart
// In lib/views/home_screen.dart - Update AppBar

AppBar(
  backgroundColor: AppColors.darkBg,
  elevation: 0,
  title: const Text(
    'Emergency Registry',
    style: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: AppColors.textLight,
    ),
  ),
  actions: [
    // NEW: Map button
    IconButton(
      icon: const Icon(Icons.map, color: AppColors.accentBlue),
      tooltip: 'View Live Volunteer Map',
      onPressed: () => Navigator.pushNamed(context, '/map'),
    ),
    // ... existing buttons ...
  ],
)
```

### Option 2: Add Card in Home Screen Body

If you want to add a prominent card for the map feature:

```dart
// In lib/views/home_screen.dart - Add to home screen body

Column(
  children: [
    // ... existing content ...
    
    // NEW: Map Feature Card
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/map'),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.accentBlue.withOpacity(0.2),
                AppColors.accentBlue.withOpacity(0.05),
              ],
            ),
            border: Border.all(
              color: AppColors.accentBlue.withOpacity(0.4),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.location_on,
                color: AppColors.accentBlue,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Live Volunteer Map',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'See registered volunteers near you',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.accentBlue,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    ),
  ],
)
```

### Option 3: Add Floating Button

If you want a floating action button for quick access:

```dart
// In lib/views/home_screen.dart - Add to Scaffold

floatingActionButton: Stack(
  children: [
    // Existing FAB (Emergency)
    FloatingActionButton(
      onPressed: () {}, // existing emergency FAB
      backgroundColor: AppColors.accentRed,
      child: const Icon(Icons.emergency),
    ),
    // NEW: Map FAB (positioned to left)
    Positioned(
      bottom: 16,
      right: 90,
      child: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/map'),
        backgroundColor: AppColors.accentBlue.withOpacity(0.8),
        mini: true,
        child: const Icon(Icons.map, size: 20),
      ),
    ),
  ],
)
```

### Option 4: Add Badge to Existing Button

If you have a navigation menu, add it there:

```dart
// Example: Add to navigation menu

ListTile(
  leading: const Icon(Icons.map, color: AppColors.accentBlue),
  title: const Text('Live Map'),
  subtitle: const Text('View volunteers on map'),
  onTap: () => Navigator.pushNamed(context, '/map'),
)
```

---

## 🔗 Add to Navigation

Make sure the `/map` route is reachable from home:

```dart
// Already added in main.dart:
routes: {
  // ...
  '/map': (_) => ChangeNotifierProvider(
    create: (_) => MapViewModel.instance,
    child: const MapScreen(),
  ),
  // ...
}
```

---

## ✅ Testing Navigation

1. Run the app: `flutter run`
2. Go to home screen
3. Tap the "{Map Button}" you added
4. Should navigate to `/map` route
5. MapScreen should initialize and fetch volunteers
6. Map should load with markers

---

## 💡 Recommendation

**Best approach:** Add Option 2 (Card in body) or Option 1 (Header button)
- Card is more discoverable and explains the feature
- Header button is quick and minimal
- Better than floating button which conflicts with emergency FAB
