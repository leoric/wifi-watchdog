import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        VStack(spacing: 0) {
            header

            Form {
                Section {
                    LabeledContent("Host") {
                        TextField("", text: $settings.pingHost, prompt: Text("google.com"))
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 180)
                    }

                    Stepper(value: $settings.failThreshold, in: 1...10) {
                        LabeledContent("Packet loss tolerance") {
                            Text("\(settings.failThreshold) in a row")
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Label("Monitoring", systemImage: "antenna.radiowaves.left.and.right")
                } footer: {
                    Text("Wi-Fi restarts after this many consecutive failed pings.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Toggle(isOn: $settings.notificationsEnabled) {
                        Label("Notify when reconnected", systemImage: "bell.badge")
                    }
                } header: {
                    Label("Notifications", systemImage: "bell")
                }

                Section {
                    LabeledContent("Wi-Fi interface") {
                        TextField("", text: $settings.interface, prompt: Text("en0"))
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                    }

                    LabeledContent("Ping interval") {
                        HStack(spacing: 4) {
                            TextField("", value: $settings.pingInterval, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 50)
                            Text("sec").foregroundStyle(.secondary)
                        }
                    }

                    LabeledContent("Cooldown after restart") {
                        HStack(spacing: 4) {
                            TextField("", value: $settings.cooldownSeconds, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 50)
                            Text("sec").foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Label("Advanced", systemImage: "gearshape.2")
                } footer: {
                    Text("Interface is usually en0 — check with: networksetup -listallhardwareports")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 440, height: 525)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "wifi.circle.fill")
                .font(.system(size: 28))
                .foregroundStyle(.blue)
            VStack(alignment: .leading, spacing: 1) {
                Text("Wi-Fi Watchdog")
                    .font(.headline)
                Text("Configure ping monitoring and auto-restart")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 4)
    }
}
