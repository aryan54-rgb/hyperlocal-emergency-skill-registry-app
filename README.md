# 🚨 Hyperlocal Emergency Skill Registry System

A production-ready Flutter mobile application that bridges the critical 5–10 minute gap between emergencies and professional help by connecting users with trained volunteers nearby.

---

## 📐 Architecture

```
MVVM + Provider + Clean Architecture
├── core/           → Theme, constants, animations, API service
├── models/         → Volunteer, request/response DTOs
├── viewmodels/     → State management (Provider)
├── views/          → All screens
└── widgets/        → Reusable UI components
```

---

## 📁 File Structure

```
lib/
├── main.dart                          ← App entry point, routing, Provider setup
├── core/
│   ├── constants.dart                 ← Base URL, app config, skill lists
│   ├── theme.dart                     ← Full design system (dark/light/HC/large text)
│   ├── animations.dart                ← FadeSlideIn, ShakeWidget, AnimatedGradient
│   └── api_service.dart               ← HTTP client, all error handling
├── models/
│   ├── volunteer.dart                 ← Core volunteer entity
│   ├── request_models.dart            ← RegisterRequest, SearchRequest
│   └── response_models.dart           ← RegisterResponse, SearchResponse, DashboardStats
├── viewmodels/
│   ├── app_settings_viewmodel.dart    ← Dark mode, HC, large text, notifications
│   ├── register_viewmodel.dart        ← Registration form state + API
│   └── search_viewmodel.dart          ← Search state + API
├── views/
│   ├── onboarding_screen.dart         ← 3-slide cinematic onboarding
│   ├── home_screen.dart               ← Immersive hero screen
│   ├── register_screen.dart           ← Full registration form + success
│   ├── search_screen.dart             ← Volunteer search + staggered results
│   ├── dashboard_screen.dart          ← Impact metrics + progress bars
│   └── settings_screen.dart          ← Theme + accessibility + team
└── widgets/
    ├── animated_button.dart           ← Glow + bounce gradient buttons
    ├── glowing_card.dart              ← Glassmorphism cards with lift
    ├── animated_stat_counter.dart     ← Count-up number animation
    ├── emergency_fab.dart             ← Pulsing red emergency button
    └── support_modal.dart             ← Global FAQ + disclaimer panel
```

---

## 🚀 Setup

### Prerequisites
- Flutter ≥ 3.16.0 (stable)
- Dart ≥ 3.0.0
- Android SDK or Xcode (iOS)

### Install & Run

```bash
cd hyperlocal_emergency
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=your_publishable_key
```

### Configure Backend URL

Edit `lib/core/constants.dart`:
```dart
static const String baseUrl = 'https://your-api.example.com';
```

### Supabase Security Config

- Never hardcode Supabase keys in source files.
- Pass only the publishable key to client apps.
- Do not expose `service_role` in Flutter/web/mobile code.

---

## 📡 API Contract

### POST `/api/volunteers/register`
**Body:**
```json
{
  "name": "string",
  "phone": "string",
  "email": "string (optional)",
  "locality": "string",
  "city": "string",
  "state": "string",
  "skills": ["CPR Certified", "First Aid"],
  "availability": "Always Available",
  "consent_given": true
}
```
**Responses:** 200/201 success, 400 validation, 500 server error

---

### GET `/api/volunteers/search?locality=&emergency_type=`
**Responses:**
```json
{
  "volunteers": [
    {
      "id": "string",
      "name": "string",
      "phone": "string",
      "locality": "string",
      "skills": ["CPR Certified"],
      "availability": "string",
      "is_active": true
    }
  ],
  "total": 5
}
```
200 success, 404 → treated as empty (not error), 500 server error

---

## 🎨 Design System

| Element | Value |
|---------|-------|
| Primary gradient | `#FF2D55 → #7B2FBE` |
| Background | `#050A1A` |
| Card | `#132133` |
| Font | Montserrat ExtraBold + Inter |
| Border radius | 14–24px |
| Animation curve | `easeOutCubic` |

---

## ♿ Accessibility Features

- **Semantic labels** on all interactive elements
- **High Contrast mode** (yellow on black)
- **Large Text toggle** (1.2x scale factor)
- **Screen reader** compatible

---

## 📦 Dependencies

| Package | Purpose |
|---------|---------|
| `provider` | State management |
| `http` | REST API calls |
| `shared_preferences` | Settings persistence |
| `confetti` | Registration success animation |
| `vibration` | Emergency FAB haptic feedback |
| `google_fonts` | Montserrat + Inter typography |
| `url_launcher` | Email contact link |

---

## ⚠️ Important Disclaimer

This app is a **civic tech tool** and does **NOT** replace emergency services.  
**Always call 112 first** in any life-threatening emergency.

---

*Built with ❤️ by the Civic Tech Initiative*
