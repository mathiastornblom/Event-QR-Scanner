# Technical Documentation

## Architecture
The app is a SwiftUI application with a lightweight MVVM structure:
- **Views**: SwiftUI screens and UI components.
- **ViewModels**: Async API calls and UI state management.
- **Networking**: `APIClient` handles all API communication.
- **Models**: Codable types representing API payloads and UI state.

## Entry Points
- `Event_QR_ScannerApp.swift` bootstraps the app and loads `SplashView`.
- `ContentView.swift` decides whether to show station selection or main tabs based on selection.

## Core Views
- `MainTabView.swift`: Tab navigation (Scan, Settings, History, About).
- `ScanView.swift`: Scanner UI, scan feedback, flashlight toggle.
- `SettingsView.swift`: Event and station selection, scan delay.
- `EventSelectionView.swift`: Event selection flow (card UI).
- `StationSelectionView.swift`: Station selection flow (card UI).
- `HistoryView.swift`: Scan history list filtered by event/station with clear actions.
- `EventBrandingHeaderView.swift`: Event branding header with logo and name.
- `CardViews.swift`: Shared UI cards for events, stations, and empty states.

## ViewModels
- `EventsViewModel.swift`: Fetches events and handles loading/error state.
- `ScanningStationViewModel.swift`: Fetches rights (stations) per event.
- `QRCodeProcessingViewModel.swift`: Validates scans and handles feedback.
- `ScanHistoryStore.swift`: Stores history entries in `UserDefaults`.
- `AppSettings.swift`: Persists selected event, station, scan delay, debug.

## Scan Feedback Logic
`QRCodeProcessingViewModel` classifies scans into:
- **Approved**: green icon, success haptics/sound.
- **Denied**: red icon, denial haptics/sound.
- **Technical error** (network/backend/etc): yellow warning icon, technical haptics/sound.

### Debug vs non-debug
- Debug details are only shown if `isDebugEnabled` is true.
- Debug is controlled via iOS Settings (Settings.bundle).

## History
- Each scan adds a `ScanHistoryItem` containing code, person, event, station, status, and timestamp.
- History list is filtered by currently selected event and station.
- Clear actions:
  - Clear current filter (event/station).
  - Clear all history via Settings.bundle request and in-app confirmation.

## Networking
`APIClient` defines all endpoints:
- `GET /api/events`
- `GET /api/events/:id`
- `GET /api/events/:id/logo`
- `GET /api/rights?eventId=xxx`
- `GET /api/scan/verify/:code`
- `POST /api/scan`
- `GET /api/codes?eventId=xxx`
- `GET /api/code-rights?codeId=xxx`
- `GET /api/code-rights/grid?eventId=xxx`

### API Reference (Backend)
- Base URL: `https://qrapi.handbollost.se:3001/api`
- Content-Type: `application/json`
- Auth: `Authorization: Bearer <jwt>` or `X-Api-Key: <key>` (read requires authenticate, write requires admin)

### Scan Verify Response (Current)
`GET /api/scan/verify/:code` returns:
- `code`: string
- `person`: string (flat name)
- `club`: string
- `team`: string
- `role`: string
- `eventId`: string
- `event`: string (display name)
- `rights`: array of rights:
  - `name`: string
  - `slug`: string
  - `remaining`: integer or `null` for unlimited
  - `total`: integer or `null` (max count for the right)
  - `used`: integer (times used)
  - `unlimited`: boolean
  - `uses`: array of recent OK scans for this right:
    - `timestamp`: ISO-8601 string
    - `station`: optional string
    - `by`: optional string

Query params:
- `eventId`: required if the same code exists in multiple events
- `limit`: max uses per right (default 10, max 50)

### Scan (Write)
`POST /api/scan` consumes a right:
- Request: `{ "code": "...", "right": "<slug>", "event_id": "...", "scanner_device": "...", "location": "..." }`
- Response: `status` = `ok` or `denied` with `reason`

### Auth
- `X-Api-Key` from Info.plist key `API_KEY`.
- Optional Bearer token from Info.plist key `API_BEARER_TOKEN`.

## Settings.bundle
System settings are defined in:
- `Event QR Scanner/Event QR Scanner/Settings.bundle/Root.plist`
- `.../Settings.bundle/en.lproj/Root.strings`
- `.../Settings.bundle/sv.lproj/Root.strings`

Current options:
- Debug toggle
- Clear-all history request

## Localization
- App strings: `Event QR Scanner/Event QR Scanner/Resources/Localizable.xcstrings`
- Settings strings: `Settings.bundle/.../Root.strings`

## Files of Interest
- `Networking/APIClient.swift`
- `ViewModels/QRCodeProcessingViewModel.swift`
- `Views/ScanView.swift`
- `Views/HistoryView.swift`
- `Views/SettingsView.swift`
- `Views/EventSelectionView.swift`
- `Views/StationSelectionView.swift`
- `Views/EventBrandingHeaderView.swift`
- `Views/CardViews.swift`

## Notes
- Case sensitivity for codes is preserved.
- Debug UI is intentionally hidden in-app to keep scanning fast.
