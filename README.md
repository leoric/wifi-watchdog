# Wi-Fi Watchdog (macOS menu bar app)

Pings a host continuously; if N pings in a row fail, it toggles Wi-Fi
off/on. Lives only in the menu bar (no Dock icon), and can notify you
when the connection comes back.

## What's in this folder

```
WifiWatchdog/
  WifiWatchdogApp.swift   – app entry point / menu bar icon / window scenes
  AppSettings.swift       – persisted options (UserDefaults)
  PingMonitor.swift       – background ping loop, wifi restart, log entries
  MenuContentView.swift   – the dropdown menu
  SettingsView.swift      – the Options window (grouped, icon-labeled sections)
  LogView.swift           – live-updating ping log window
```

This is Swift source only — building a proper `.app` needs Xcode,
which isn't available in the environment I ran in. Setup takes about
5 minutes.

## 1. Create the Xcode project

1. Open Xcode → **File → New → Project**
2. Choose **macOS → App**, click Next
3. Product Name: `WifiWatchdog`, Interface: **SwiftUI**, Language: **Swift**
4. Uncheck "Use Core Data" / "Include Tests" (not needed)
5. Save it anywhere

## 2. Add the source files

Delete the auto-generated `ContentView.swift` and the default
`WifiWatchdogApp.swift`. Drag the 5 `.swift` files from this folder
into the Xcode project navigator (check "Copy items if needed").

## 3. Hide the Dock icon

Select the project in the navigator → target **WifiWatchdog** → **Info** tab
→ add a new key:

```
Key: Application is agent (UIElement)
Type: Boolean
Value: YES
```

(This is `LSUIElement` in the raw Info.plist — same thing.)

## 4. Turn off App Sandbox

The app needs to run `/sbin/ping` and `/usr/sbin/networksetup` as
subprocesses, which the sandbox blocks. Go to target →
**Signing & Capabilities** → remove the **App Sandbox** capability
(click the `x` on that capability card). This is fine for a
personal-use utility you're running unsigned/locally.

## 5. Set deployment target

Target → **General** → set **Minimum Deployments** to **macOS 14.0**
(uses `MenuBarExtra` + `openSettings`, both introduced in Sonoma).

## 6. Build & run

⌘R. You should see a Wi-Fi icon appear in the menu bar with no Dock
icon or app switcher entry. Click it for status / Start-Stop / Options.
First launch will prompt for notification permission — allow it if
you want the reconnect alerts.

## 7. (Optional) Launch at login

System Settings → General → Login Items → add `WifiWatchdog.app`
(export it via Product → Archive → Distribute App → Copy App, or just
drag the built `.app` from Xcode's DerivedData/Products folder into
`/Applications` first).

## Options available in the menu

- **Host to ping** — defaults to `google.com`
- **Wi-Fi interface** — defaults to `en0`; check yours with
  `networksetup -listallhardwareports`
- **Packet loss tolerance** — defaults to 2 consecutive failures
- **Ping interval / cooldown after restart** — tunable timing
- **Notify when connection is restored** — toggle, on by default

## Live ping log

Menu bar icon → **View Ping Log…** (⌘L) opens a window that streams
every ping result in real time — green for success (with round-trip
time when available), red for failures, orange for restart events,
gray for status messages. Auto-scrolls to the newest entry, keeps the
last 300 entries, and has a **Clear** button. Text is selectable if
you want to copy a line out.

## Notes

- The menu bar icon switches between `wifi` (running) and `wifi.slash`
  (stopped) so you can tell watchdog state at a glance.
- Restarting Wi-Fi does `networksetup -setairportpower <iface> off`,
  waits 3s, then `on` — same as the shell script version.
- After a restart it waits for the configured cooldown before
  resuming failure counting, so it doesn't immediately re-trigger
  while the interface reassociates.
