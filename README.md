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

## Archive Keyboard Shortcut

Mail.app has a built-in archive shortcut, but it's awkward:

| Action  | Default Shortcut |
|---------|-----------------|
| Archive | `Ctrl+Cmd+A` |

### Set a Custom Archive Shortcut

1. Open **System Settings > Keyboard > Keyboard Shortcuts > App Shortcuts**
2. Click **+**
3. Application: **Mail**
4. Menu Title: `Archive` (exact match)
5. Keyboard Shortcut: press your desired key (e.g., `Cmd+E` for Gmail-style)
6. Click **Done**

### Single-Key Archive (Gmail-style)

macOS doesn't allow single non-modifier keys in App Shortcuts. For single-key mappings, use:

- **[Karabiner-Elements](https://karabiner-elements.pqrs.org/)** — remap `\` to `Ctrl+Cmd+A` when Mail.app is focused
- **[Hammerspoon](https://www.hammerspoon.org/)** — Lua-scriptable hotkeys with app-specific rules

Example Hammerspoon config:
```lua
hs.hotkey.bind({}, "\\", function()
  local app = hs.application.frontmostApplication()
  if app:bundleID() == "com.apple.mail" then
    hs.eventtap.keyStroke({"ctrl", "cmd"}, "a")
  end
end)
```

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15+ (for building)
- Mail.app configured with at least one account

## License

Private — not yet licensed for distribution.
