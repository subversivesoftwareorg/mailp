# Mail+

A macOS power-user companion for Mail.app — account stats at a glance, activity tracking over time, message snoozing, and quick archive.

## Features

- **Menu bar dashboard** — see unread counts across all accounts without opening Mail
- **Full dashboard window** — detailed per-account stats and activity history
- **Activity tracking** — records inbox/sent/trash counts over time (local SQLite via SwiftData)
- **Snooze messages** — hide and resurface later, or notify-only reminders (1d, 3d, 7d, next Monday)
- **MailKit extension** — runs inside Mail.app for future integration points

## Setup

### Build & Run

```bash
open MailPlus.xcodeproj
```

Build and run from Xcode (Cmd+R). The app lives in the menu bar.

### Enable the Mail Extension

1. Open **Mail.app** > **Settings** > **Extensions**
2. Enable **MailPlusExtension**

### Grant Automation Permission

On first run, macOS will prompt you to allow Mail+ to control Mail.app. Click **OK**.
If you missed it: **System Settings > Privacy & Security > Automation > Mail+** > enable Mail.app.

## Keyboard Shortcuts

Mail+ adds Gmail-style single-key shortcuts when Mail.app is focused. Enable them from the menu bar popover toggle.

| Key | Action | How it works |
|-----|--------|--------------|
| `d` | Delete (trash) | Posts `Cmd+Delete` |
| `a` | Archive | Posts `Ctrl+Cmd+A` |
| `r` | Reply | Posts `Cmd+R` |
| `f` | Forward | AppleScript `forward` command |
| `h` | Hold (snooze 1 day) | Moves to snooze mailbox, resurfaces tomorrow |

Shortcuts only fire when the message list or viewer is focused — they're automatically disabled in compose windows, search fields, and other text input areas.

### Setup

1. Enable **Keyboard Shortcuts** in the Mail+ menu bar popover
2. Grant **Accessibility** permission when prompted (System Settings > Privacy & Security > Accessibility)

### Archive Notes

Archive (`a`) requires an account type that supports archiving (IMAP/Gmail). POP accounts do not have an archive mailbox.

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15+ (for building)
- Mail.app configured with at least one account

## License

Private — not yet licensed for distribution.
