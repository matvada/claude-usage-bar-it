import SwiftUI

struct PopoverView: View {
    @ObservedObject var service: UsageService
    @ObservedObject var historyService: UsageHistoryService
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ClaudeMark()
                    .frame(width: 18, height: 18)
                Text("Consumi Claude")
                    .font(Theme.serif(.title3, weight: .medium))
            }
            .padding(.bottom, 2)
            if !service.isAuthenticated {
                signInView
            } else {
                usageView
            }
        }
        .padding(16)
        .frame(width: 340)
        .background(Theme.paper)
        .tint(Theme.accent)
        .environment(\.locale, Locale(identifier: "it_IT"))
    }

    @ViewBuilder
    private var signInView: some View {
        if service.isWaitingForBrowser {
            BrowserSignInView(service: service)
        } else if service.isAwaitingCode {
            CodeEntryView(service: service)
        } else {
            Text("Accedi per vedere i tuoi consumi.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                Task { await service.startOAuthFlow() }
            } label: {
                Text("Accedi con Claude")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }

        if let error = service.lastError {
            ErrorLabel(message: error)
        }

        Divider()
        HStack {
            settingsButton
            Spacer()
            quitButton
        }
    }

    @ViewBuilder
    private var usageView: some View {
        if service.hasFiveHourWindow {
            UsageBucketRow(
                label: "Sessione (5 ore)",
                bucket: service.usage?.fiveHour
            )
        }

        UsageBucketRow(
            label: "Settimana (7 giorni)",
            bucket: service.usage?.sevenDay
        )

        let perModel = service.usage?.perModelWeekly ?? []
        if !perModel.isEmpty {
            Divider()
            Text("Per modello (7 giorni)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            perModelRows(perModel)
        }

        if let extra = service.usage?.extraUsage, extra.isEnabled {
            Divider()
            ExtraUsageRow(extra: extra)
        }

        Divider()
        UsageChartView(historyService: historyService, showsFiveHour: service.hasFiveHourWindow)

        if let error = service.lastError {
            Divider()
            ErrorLabel(message: error)
        }

        Divider()

        HStack(spacing: 12) {
            if let updated = service.lastUpdated {
                Text("Aggiornato \(updated, style: .relative) fa")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }

        HStack(spacing: 12) {
            settingsButton
            Spacer()
            Button("Aggiorna") {
                Task { await service.fetchUsage() }
            }
            .buttonStyle(.borderless)
            .font(.caption)
            quitButton
        }
    }

    /// How many per-model rows render inline before the section starts scrolling.
    private static let inlinePerModelRowLimit = 6
    /// Approximate height of one `UsageBucketRow`, used only to size the scroller.
    private static let perModelRowHeight: CGFloat = 52

    /// The number of model-scoped windows the server reports is unbounded, and
    /// the popover has a fixed width and no outer scroll view — so past a
    /// handful of rows this section scrolls instead of pushing the chart and
    /// the controls off-screen.
    @ViewBuilder
    private func perModelRows(_ entries: [PerModelUsage]) -> some View {
        let rows = VStack(alignment: .leading, spacing: 8) {
            ForEach(entries) { entry in
                UsageBucketRow(label: entry.displayName, bucket: entry.bucket)
            }
        }

        if entries.count > Self.inlinePerModelRowLimit {
            ScrollView {
                rows
            }
            .frame(height: CGFloat(Self.inlinePerModelRowLimit) * Self.perModelRowHeight)
        } else {
            rows
        }
    }

    private var settingsButton: some View {
        Button("Impostazioni…") {
            openSettings()
            focusSettingsWindow()
        }
        .buttonStyle(.borderless)
        .font(.caption)
    }

    private var quitButton: some View {
        Button("Esci") { NSApplication.shared.terminate(nil) }
            .buttonStyle(.borderless)
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}

// MARK: - Subviews

struct BrowserSignInView: View {
    @ObservedObject var service: UsageService

    var body: some View {
        Text("Autorizza l'accesso nel browser per completare l'accesso.")
            .font(.subheadline)
            .foregroundStyle(.secondary)

        HStack {
            Button("Annulla") {
                service.endOAuthFlow()
            }
            .buttonStyle(.borderless)
            Spacer()
            Button("Incolla un codice") {
                service.switchToPastedCode()
            }
            .buttonStyle(.borderless)
        }
    }
}

struct CodeEntryView: View {
    @ObservedObject var service: UsageService
    @State private var code = ""

    var body: some View {
        Text("Incolla il codice dal browser:")
            .font(.subheadline)
            .foregroundStyle(.secondary)

        HStack(spacing: 4) {
            TextField("codice#stato", text: $code)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
                .onSubmit { submit() }
            Button {
                if let str = NSPasteboard.general.string(forType: .string) {
                    code = str.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            } label: {
                Image(systemName: "doc.on.clipboard")
            }
            .buttonStyle(.borderless)
        }

        HStack {
            Button("Annulla") {
                service.endOAuthFlow()
            }
            .buttonStyle(.borderless)
            Spacer()
            Button("Conferma") { submit() }
                .buttonStyle(.borderedProminent)
                .disabled(code.isEmpty)
        }
    }

    private func submit() {
        let value = code
        Task { await service.submitOAuthCode(value) }
    }
}

struct ErrorLabel: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle")
            .foregroundStyle(Theme.red)
            .font(.caption)
    }
}

private struct UsageBucketRow: View {
    let label: String
    let bucket: UsageBucket?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text(percentageText)
                    .font(Theme.serif(.body, weight: .semibold))
                    .monospacedDigit()
            }
            ClaudeBar(fraction: (bucket?.utilization ?? 0) / 100.0)
            if let resetDate = bucket?.resetsAtDate {
                Text("Si azzera tra \(resetDate, style: .relative)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var percentageText: String {
        guard let pct = bucket?.utilization else { return "—" }
        return "\(Int(round(pct)))%"
    }
}

private struct ExtraUsageRow: View {
    let extra: ExtraUsage

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Crediti extra")
                .font(.subheadline)
                .fontWeight(.medium)
            if let used = extra.usedCreditsAmount, let limit = extra.monthlyLimitAmount {
                HStack {
                    Text("\(extra.formatAmount(used)) / \(extra.formatAmount(limit))")
                        .font(.caption)
                        .monospacedDigit()
                    Spacer()
                    if let pct = extra.utilization {
                        Text("\(Int(round(pct)))%")
                            .font(.caption)
                            .monospacedDigit()
                    }
                }
                ClaudeBar(fraction: (extra.utilization ?? 0) / 100.0, color: Theme.orange)
            }
        }
    }
}

/// Il logo di Claude in terracotta.
struct ClaudeMark: View {
    var body: some View {
        if let image = claudeLogoTemplate {
            Image(nsImage: image)
                .renderingMode(.template)
                .resizable()
                .foregroundStyle(Theme.orange)
        } else {
            Image(systemName: "sparkle").foregroundStyle(Theme.orange)
        }
    }
}
