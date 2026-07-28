import Foundation
import Combine

/// Holds all user-configurable options, backed by UserDefaults so they
/// persist across launches. Shared as a singleton so both the menu bar
/// UI and the background monitor read/write the same values.
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var pingHost: String {
        didSet { UserDefaults.standard.set(pingHost, forKey: "pingHost") }
    }

    @Published var failThreshold: Int {
        didSet { UserDefaults.standard.set(failThreshold, forKey: "failThreshold") }
    }

    @Published var notificationsEnabled: Bool {
        didSet { UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled") }
    }

    @Published var interface: String {
        didSet { UserDefaults.standard.set(interface, forKey: "interface") }
    }

    @Published var pingInterval: Double {
        didSet { UserDefaults.standard.set(pingInterval, forKey: "pingInterval") }
    }

    @Published var cooldownSeconds: Double {
        didSet { UserDefaults.standard.set(cooldownSeconds, forKey: "cooldownSeconds") }
    }

    @Published var launchAtStartup: Bool {
        didSet { UserDefaults.standard.set(launchAtStartup, forKey: "launchAtStartup") }
    }

    private init() {
        let d = UserDefaults.standard
        pingHost = d.string(forKey: "pingHost") ?? "google.com"
        failThreshold = d.object(forKey: "failThreshold") != nil ? d.integer(forKey: "failThreshold") : 2
        notificationsEnabled = d.object(forKey: "notificationsEnabled") != nil ? d.bool(forKey: "notificationsEnabled") : true
        interface = d.string(forKey: "interface") ?? "en0"
        pingInterval = d.object(forKey: "pingInterval") != nil ? d.double(forKey: "pingInterval") : 1.0
        cooldownSeconds = d.object(forKey: "cooldownSeconds") != nil ? d.double(forKey: "cooldownSeconds") : 15.0
        launchAtStartup = d.object(forKey: "launchAtStartup") != nil ? d.bool(forKey: "launchAtStartup") : false
    }
}
