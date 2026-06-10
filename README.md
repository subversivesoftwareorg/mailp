# Mail+

A macOS menu bar app that adds power-user keyboard shortcuts and account monitoring to Mail.app.

## Features

### Keyboard Shortcuts

Gmail-style single-key shortcuts when Mail.app is focused. Shortcuts are intercepted before they reach Mail.app (no type-to-select interference).

| Key | Action | Details |
|-----|--------|---------|
| `d` | Delete | Move to Trash |
| `a` | Archive | Archive message (IMAP/Gmail) |
| `r` | Reply | Open reply |
| `f` | Forward | Open forward |
| `t` | Task | Create a Reminder — due tomorrow 9am |
| `b` | Block sender | Add sender to block rule, trash message |
| `⇧B` | Block domain | Block the entire `@domain` |
| `h` | Remind tonight | Mail.app Remind Me — tonight |
| `j` | Remind tomorrow | Mail.app Remind Me — tomorrow |
| `k` | Remind later | Mail.app Remind Me — opens date picker |
| `⌘S` | Send | Remaps to `⌘⇧D` (Mail.app Send) |

Single-key shortcuts are automatically disabled in compose windows, search fields, and text inputs.

### Account Dashboard

- **Menu bar** — unread count badge, one-click access
- **Overview** — per-account unread/inbox counts in a table
- **Today summary** — unread change, inbox change, peak unread
- **Activity history** — aggregated hourly (24h) or daily (7d/30d)
- **Per-account detail** — select an account for stats and history

### Blocking

Press `b` to block a sender or `⇧B` to block an entire domain. Blocks are stored as a single Mail.app rule ("Mail+ Blocks") with `delete message` enabled — no parallel data, works across all accounts. The dashboard Blocks page shows the block list with unblock support.

### Reminders Integration

Press `t` to create a Reminder from the selected message. Sets "Follow up: [subject]" with the sender in the body, due tomorrow at 9am, in the default Reminders list.

### Remind Me

Press `h`/`j`/`k` to use Mail.app's native Remind Me feature. Reminders appear in Mail.app's own UI.

## Setup

### Build & Run

```bash
open MailPlus.xcodeproj    # Xcode development (includes MailKit extension)
swift build                 # SPM build (main app only)
swift test                  # Run tests
```

Build and run from Xcode (Cmd+R). The app lives in the menu bar.

### Permissions

On first launch, macOS prompts for each permission as needed:

| Permission | Where to grant | Why |
|------------|---------------|-----|
| **Automation (Mail.app)** | System Settings > Privacy > Automation | Read accounts, move messages |
| **Accessibility** | System Settings > Privacy > Accessibility | Keyboard shortcuts (CGEvent tap) |
| **Automation (System Events)** | System Settings > Privacy > Automation | Remind Me, block via menu items |
| **Reminders** | System Settings > Privacy > Reminders | Create tasks from emails |
| **Notifications** | System Settings > Notifications > Mail+ | Block/task confirmation alerts |

### Enable the Mail Extension

1. Open **Mail.app** > **Settings** > **Extensions**
2. Enable **MailPlusExtension**

### Enable Keyboard Shortcuts

1. Click the Mail+ menu bar icon
2. Flip the **Keyboard Shortcuts** toggle
3. Grant Accessibility permission when prompted (green checkmark confirms it's active)

## Distribution

### Build a signed DMG

```bash
./Scripts/create-dmg.sh                   # full build + sign + notarize
./Scripts/create-dmg.sh --skip-notarize   # build + sign only (for testing)
```

The script:
1. Auto-increments the build number in Info.plist
2. Builds a universal binary (arm64 + x86_64) via xcodebuild
3. Signs the MailKit extension and app with Developer ID Application
4. Creates a DMG with drag-to-install layout
5. Notarizes via `xcrun notarytool` and staples the result
6. Commits the build number bump and tags the release

Prerequisites: `brew install create-dmg` (optional — falls back to `hdiutil`)

Environment variables (prompted if not set):
- `APPLE_ID` — Apple ID email for notarization
- `APP_PASSWORD` — app-specific password ([appleid.apple.com](https://appleid.apple.com))
- `TEAM_ID` — Developer team ID (default: 84CC987JU3)

### Create a GitHub release

After building the DMG:

```bash
# Push the build commit and tag
git push && git push --tags

# Create the release with the DMG attached
gh release create v1.0-b5 \
  --title "Mail+ 1.0 (build 5)" \
  --notes "$(cat <<'EOF'
## What's new
- Gmail-style keyboard shortcuts (d/a/r/f/t/b/h/j/k)
- Sender and domain blocking via Mail.app rules
- Reminders integration (t key)
- Account dashboard with activity tracking
- Cmd+S to send in compose
EOF
)" \
  build/MailPlus-1.0-b5.dmg
```

Replace the version/build numbers to match the output of `create-dmg.sh`. The `gh` CLI authenticates via `gh auth login`.

## Architecture

- **Menu bar app** — `LSUIElement`, `MenuBarExtra` with `.window` style
- **MailKit extension** — embedded `MEComposeSessionHandler` (extensible)
- **Keyboard shortcuts** — `CGEvent` tap intercepts keys before Mail.app, suppresses originals
- **Mail.app communication** — AppleScript via `osascript` subprocess
- **Data** — SwiftData for activity history; Mail.app rules for block list; Reminders.app for tasks
- **Zero third-party dependencies**

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15+ (for building)
- Mail.app configured with at least one account

## License

Private — not yet licensed for distribution.
