import SwiftUI

struct LogView: View {
    @ObservedObject var monitor: PingMonitor

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(monitor.logEntries) { entry in
                            logRow(entry)
                                .id(entry.id)
                        }
                    }
                    .padding(10)
                }
                .background(Color(nsColor: .textBackgroundColor))
                .onChange(of: monitor.logEntries.count) { _, _ in
                    if let last = monitor.logEntries.last {
                        withAnimation(.easeOut(duration: 0.15)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
                .onAppear {
                    if let last = monitor.logEntries.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
        .frame(minWidth: 480, idealWidth: 560, minHeight: 320, idealHeight: 420)
    }

    private var header: some View {
        HStack {
            Image(systemName: monitor.isRunning ? "circle.fill" : "circle")
                .font(.system(size: 7))
                .foregroundStyle(.secondary)
            Text(monitor.isRunning ? "Live" : "Stopped")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Text("\(monitor.logEntries.count) entries")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("Clear") {
                monitor.clearLog()
            }
            .font(.caption)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func logRow(_ entry: LogEntry) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(entry.timestamp, format: .dateTime.hour().minute().second())
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .leading)

            Image(systemName: icon(for: entry.kind))
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 14)

            Text(entry.message)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.primary)
                .textSelection(.enabled)

            Spacer(minLength: 0)
        }
    }

    private func icon(for kind: LogKind) -> String {
        switch kind {
        case .success: return "checkmark.circle"
        case .failure: return "xmark.circle"
        case .restart: return "arrow.triangle.2.circlepath.circle"
        case .info: return "info.circle"
        }
    }
}
