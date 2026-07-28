import Foundation
import UserNotifications
import Combine

enum LogKind {
    case success
    case failure
    case restart
    case info
}

struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let message: String
    let kind: LogKind
}

@MainActor
final class PingMonitor: ObservableObject {
    @Published var isRunning = false
    @Published var statusText = "Idle"
    @Published var lastRestart: Date?
    @Published private(set) var logEntries: [LogEntry] = []

    private let maxLogEntries = 300

    private var loopTask: Task<Void, Never>?
    private let settings = AppSettings.shared

    private func log(_ message: String, kind: LogKind) {
        logEntries.append(LogEntry(timestamp: Date(), message: message, kind: kind))
        if logEntries.count > maxLogEntries {
            logEntries.removeFirst(logEntries.count - maxLogEntries)
        }
    }

    func clearLog() {
        logEntries.removeAll()
    }

    func start() {
        guard loopTask == nil else { return }
        isRunning = true
        statusText = "Starting…"
        loopTask = Task { await runLoop() }
    }

    func stop() {
        loopTask?.cancel()
        loopTask = nil
        isRunning = false
        statusText = "Stopped"
        log("Watchdog stopped by user", kind: .info)
    }

    // MARK: - Main loop

    private func runLoop() async {
        var failCount = 0
        var wasDown = false

        log("Watchdog started — pinging \(settings.pingHost)", kind: .info)

        while !Task.isCancelled {
            let host = settings.pingHost
            let result = await ping(host: host)

            if Task.isCancelled { break }

            if result.ok {
                if wasDown {
                    wasDown = false
                    log("Reconnected — \(host) reachable again", kind: .success)
                    if settings.notificationsEnabled {
                        notify(title: "Wi-Fi Watchdog", body: "Reconnected — \(host) is reachable again.")
                    }
                } else {
                    let timing = result.timeMs.map { " (\($0) ms)" } ?? ""
                    log("Ping OK — \(host)\(timing)", kind: .success)
                }
                failCount = 0
                statusText = "OK — \(host) reachable"
            } else {
                failCount += 1
                statusText = "Ping failed (\(failCount)/\(settings.failThreshold))"
                log("Ping failed — \(host) (\(failCount)/\(settings.failThreshold))", kind: .failure)

                if failCount >= settings.failThreshold {
                    wasDown = true
                    await restartWifi()
                    failCount = 0
                    let cooldown = max(0, settings.cooldownSeconds)
                    log("Cooling down for \(Int(cooldown))s before resuming checks", kind: .info)
                    try? await Task.sleep(nanoseconds: UInt64(cooldown * 1_000_000_000))
                    continue
                }
            }

            let interval = max(0.2, settings.pingInterval)
            try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
        }
    }

    // MARK: - Ping

    nonisolated private func ping(host: String) async -> (ok: Bool, timeMs: String?) {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/sbin/ping")
                process.arguments = ["-c", "1", "-t", "2", host]
                let outPipe = Pipe()
                process.standardOutput = outPipe
                process.standardError = Pipe()
                do {
                    try process.run()
                    let data = outPipe.fileHandleForReading.readDataToEndOfFile()
                    process.waitUntilExit()
                    let ok = process.terminationStatus == 0
                    var timeMs: String? = nil
                    if ok, let text = String(data: data, encoding: .utf8),
                       let range = text.range(of: "time="),
                       let unitRange = text.range(of: " ms", range: range.upperBound..<text.endIndex) {
                        timeMs = String(text[range.upperBound..<unitRange.lowerBound])
                    }
                    continuation.resume(returning: (ok, timeMs))
                } catch {
                    continuation.resume(returning: (false, nil))
                }
            }
        }
    }

    // MARK: - Wi-Fi restart

    private func restartWifi() async {
        statusText = "Restarting Wi-Fi…"
        let iface = settings.interface
        log("Threshold reached — restarting Wi-Fi (\(iface))", kind: .restart)
        _ = await runProcess("/usr/sbin/networksetup", ["-setairportpower", iface, "off"])
        try? await Task.sleep(nanoseconds: 3_000_000_000)
        _ = await runProcess("/usr/sbin/networksetup", ["-setairportpower", iface, "on"])
        lastRestart = Date()
        log("Wi-Fi restart complete", kind: .restart)
    }

    @discardableResult
    nonisolated private func runProcess(_ path: String, _ args: [String]) async -> Int32 {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: path)
                process.arguments = args
                do {
                    try process.run()
                    process.waitUntilExit()
                    continuation.resume(returning: process.terminationStatus)
                } catch {
                    continuation.resume(returning: -1)
                }
            }
        }
    }

    // MARK: - Notifications

    private func notify(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
