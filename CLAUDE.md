# Triage — Mail.app Power Tools

See [SUBVERSIVE_MACOS_ARCH.md](../SUBVERSIVE_MACOS_ARCH.md) for shared architecture conventions.

## What This App Does

Menu bar app + MailKit extension adding power-user features to Mail.app:
- **Account dashboard** — unread counts, totals per account (menu bar popover + full window)
- **Activity tracking** — sent, received, deleted snapshots over time (SwiftData)
- **Snooze/remind** — hide a message and resurface it later, or notify-only (1d, 3d, 7d, next Monday)
- **Archive shortcut** — documented in README (macOS App Shortcuts or Hammerspoon)

## App-Specific Deviations

| Convention | This App |
|------------|----------|
| Standard window app | **Menu bar app** (`LSUIElement`, `MenuBarExtra`) + optional dashboard window |
| No extensions | **MailKit extension** target (`TriageExtension`) embedded in the app |
| Single target | **Two targets** — app + extension, communicating via App Groups |

## Targets

1. **Triage** — SwiftUI menu bar app
   - Queries Mail.app via `osascript` subprocess (AppleScript)
   - Polls periodically (default 60s), persists to SwiftData
   - Bundle ID: `com.subversivesoftware.triage`

2. **TriageExtension** — MailKit extension
   - `MEComposeSessionHandler` (extensible for future mail actions)
   - Bundle ID: `com.subversivesoftware.triage.extension`

## Build

```bash
swift build                    # Main app via SPM (no extension)
xcodebuild -scheme Triage build   # Full build including extension
open Triage.xcodeproj    # IDE development
```

## Key Files

- `Info.plist` — app bundle config (at repo root per convention)
- `Triage.entitlements` — Apple Events automation permission
- `Triage/Store/StatsStore.swift` — central state container, polling logic
- `Triage/Services/MailQueryService.swift` — AppleScript bridge to Mail.app
- `Triage/Services/SnoozeService.swift` — snooze timer management

## Permissions Required

- **Automation** — System Settings > Privacy > Automation > Triage > Mail.app
- **Mail Extension** — Mail > Settings > Extensions > enable TriageExtension
- **Notifications** — for snooze reminders
