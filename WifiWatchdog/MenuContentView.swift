import SwiftUI
import AppKit

struct MenuContentView: View {
    @ObservedObject var monitor: PingMonitor
    @ObservedObject var settings: AppSettings
    @Environment(\.openSettings) private var openSettings
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Text(monitor.statusText)

        if let last = monitor.lastRestart {
            Text("Last Wi-Fi restart: \(last.formatted(date: .omitted, time: .standard))")
                .foregroundColor(.secondary)
        }

        Divider()

        if monitor.isRunning {
            Button("Stop Monitoring") { monitor.stop() }
        } else {
            Button("Start Monitoring") { monitor.start() }
        }

        Button("View Ping Log…") { showWindow { openWindow(id: "pingLog") } }
            .keyboardShortcut("l")

        Divider()

        Button("Options…") { showWindow { openSettings() } }
            .keyboardShortcut(",")

        Divider()

        Button("Quit Wi-Fi Watchdog") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }

    /// Agent apps (no Dock icon) don't automatically become frontmost when a
    /// window opens, so new windows can appear behind whatever else is
    /// focused. Activate the app first, then open the window, and bring it
    /// forward once it exists.
    private func showWindow(_ open: () -> Void) {
        NSApp.activate(ignoringOtherApps: true)
        open()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            NSApp.windows.last(where: { $0.isVisible })?.makeKeyAndOrderFront(nil)
        }
    }
}
