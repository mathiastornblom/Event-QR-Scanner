# Event QR Scanner

## Overview
Event QR Scanner is an iOS app for scanning event QR codes and validating rights (stations). It supports event branding, station selection, scan feedback with clear success/denial/error states, and a scan history filtered per event/station.

## Key Features
- Event selection with branding (logo + colors).
- Station selection per event (rights).
- QR code scanning with clear feedback:
  - Approved (green)
  - Denied (red)
  - Technical error (yellow)
- Scan history (filtered by selected event and station).
- Debug toggle in iOS Settings (Settings.bundle).

## App Flow
1. Select an event.
2. Select a station (right).
3. Scan QR codes.
4. Review scan history (per event/station).

## Configuration
### API
The base URL and API key are configured in `APIClient` and Info.plist:
- Base URL: `APIClient.shared` in `Event QR Scanner/Event QR Scanner/Networking/APIClient.swift`.
- API key: `API_KEY` in Info.plist.

### iOS Settings
Debug and clear-all history live in the system Settings app:
`Settings.app -> Event QR Scanner`.

## Build
Open the Xcode project and build using the default scheme.

## Localization
App strings are stored in:
- `Event QR Scanner/Event QR Scanner/Resources/Localizable.xcstrings`

Settings bundle strings are stored in:
- `Event QR Scanner/Event QR Scanner/Settings.bundle/en.lproj/Root.strings`
- `Event QR Scanner/Event QR Scanner/Settings.bundle/sv.lproj/Root.strings`

## Documentation
See `docs/TECHNICAL.md` for architecture, module descriptions, and API details.
