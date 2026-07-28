import SwiftUI
import UserNotifications

@main
struct WifiWatchdogApp: App {
    @StateObject private var settings = AppSettings.shared
    @StateObject private var monitor = PingMonitor()

    init() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    var body: some Scene {
        MenuBarExtra(monitor.isRunning ? "Wi-Fi Watchdog — running" : "Wi-Fi Watchdog — stopped",
                     systemImage: monitor.isRunning ? "wifi" : "wifi.slash") {
            MenuContentView(monitor: monitor, settings: settings)
                .onAppear {
                    if !monitor.isRunning {
                        monitor.start()
                    }
                }
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView(settings: settings)
        }

        WindowGroup("Ping Log", id: "pingLog") {
            LogView(monitor: monitor)
        }
        .defaultSize(width: 560, height: 420)
        .windowResizability(.contentSize)
    }
}
