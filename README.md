# Wi-Fi Watchdog (macOS menu bar app)

Pings a host continuously; if N pings in a row fail, it toggles Wi-Fi
off/on. Lives only in the menu bar (no Dock icon), and can notify you
when the connection comes back.

## Installation

1. Move `WifiWatchdog.app` to `/Applications`.
2. It's unsigned (no Apple Developer ID), so Gatekeeper will refuse to
   open it and likely claim it's "damaged" — it isn't, that's just what
   Gatekeeper says about unsigned apps. One-time fix:

execute
   ```bash
   xattr -cr /Applications/WifiWatchdog.app
   ```
in Terminal

3. Launch normally.

## Options available in the menu

- **Host to ping** — defaults to `google.com`
- **Wi-Fi interface** — defaults to `en0`; check yours with
  `networksetup -listallhardwareports`
- **Packet loss tolerance** — defaults to 2 consecutive failures
- **Ping interval / cooldown after restart** — tunable timing
- **Notify when connection is restored** — toggle, on by default

## Live ping log

Menu bar icon → **View Ping Log…** (⌘L) opens a window that streams
every ping result in real time.

## Notes

- The menu bar icon switches between `wifi` (running) and `wifi.slash`
  (stopped) so you can tell watchdog state at a glance.
- Restarting Wi-Fi does `networksetup -setairportpower <iface> off`,
  waits 3s, then `on` — same as the shell script version.
- After a restart it waits for the configured cooldown before
  resuming failure counting, so it doesn't immediately re-trigger
  while the interface reassociates.
