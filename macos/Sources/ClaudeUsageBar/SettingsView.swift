import SwiftUI
import ServiceManagement

struct SettingsWindowContent: View {
    @ObservedObject var service: UsageService
    @ObservedObject var notificationService: NotificationService
    @ObservedObject var appUpdater: AppUpdater
    @AppStorage("extraUsageCurrency") private var currency = "EUR"

    var body: some View {
        Form {
            Section("Generali") {
                LaunchAtLoginToggle()

                Picker("Aggiorna ogni", selection: Binding(
                    get: { service.pollingMinutes },
                    set: { service.updatePollingInterval($0) }
                )) {
                    ForEach(UsageService.pollingOptions, id: \.self) { mins in
                        Text(pollingOptionLabel(for: mins))
                            .tag(mins)
                    }
                }

                Picker("Valuta crediti extra", selection: $currency) {
                    Text("Euro (€)").tag("EUR")
                    Text("Dollaro ($)").tag("USD")
                }
            }

            Section("Notifiche") {
                if !notificationService.isAvailable {
                    Text(notificationsUnavailableMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if service.hasFiveHourWindow {
                    ThresholdSlider(
                        label: "Sessione (5 ore)",
                        value: notificationService.threshold5h,
                        onChange: { notificationService.setThreshold5h($0) }
                    )
                }
                ThresholdSlider(
                    label: "Settimana (7 giorni)",
                    value: notificationService.threshold7d,
                    onChange: { notificationService.setThreshold7d($0) }
                )
                ThresholdSlider(
                    label: "Crediti extra",
                    value: notificationService.thresholdExtra,
                    onChange: { notificationService.setThresholdExtra($0) }
                )
            }
            .disabled(!notificationService.isAvailable)

            if service.isAuthenticated {
                AccountSection(service: service)
            }

            Section("Aggiornamenti") {
                LabeledContent("Versione") {
                    Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "sconosciuta")
                        .textSelection(.enabled)
                }

                if appUpdater.isConfigured {
                    Toggle("Cerca aggiornamenti ogni giorno", isOn: Binding(
                        get: { appUpdater.automaticallyChecksForUpdates },
                        set: { appUpdater.setAutomaticallyChecksForUpdates($0) }
                    ))

                    Button("Cerca aggiornamenti…") {
                        appUpdater.checkForUpdates()
                    }
                    .disabled(!appUpdater.canCheckForUpdates)

                    if let error = appUpdater.lastError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                } else {
                    Text("Questa versione non ha un canale di aggiornamento: le nuove versioni si scaricano dalla pagina Release su GitHub.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .tint(Theme.accent)
        .environment(\.locale, Locale(identifier: "it_IT"))
        .frame(width: 400)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear {
            focusSettingsWindow()
        }
    }
}

private struct AccountSection: View {
    @ObservedObject var service: UsageService

    var body: some View {
        Section("Account") {
            if service.accounts.count > 1 {
                Picker("Mostra consumi di", selection: Binding(
                    get: { service.accounts.first?.id },
                    set: { if let id = $0 { service.switchAccount(to: id) } }
                )) {
                    ForEach(service.accounts.sorted { label(for: $0) < label(for: $1) }) { account in
                        Text(label(for: account)).tag(Optional(account.id))
                    }
                }
            } else if let email = service.accountEmail {
                Text(email)
            }

            if let error = service.lastError {
                ErrorLabel(message: error)
            }

            if service.isAwaitingCode {
                if service.isWaitingForBrowser {
                    BrowserSignInView(service: service)
                } else {
                    CodeEntryView(service: service)
                }
                Text("Per aggiungere un altro account, accedi prima con quell'account su claude.ai.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                HStack {
                    Button("Aggiungi account…") {
                        Task { await service.startOAuthFlow() }
                    }
                    Button("Esci dall'account") {
                        service.signOut()
                    }
                }
            }
        }
    }

    /// Adds the organization when one login is signed in to several.
    private func label(for account: StoredAccount) -> String {
        let email = account.email ?? "Account sconosciuto"
        guard service.accounts.filter({ $0.email == account.email }).count > 1,
              let organization = account.organizationName else {
            return email
        }
        return "\(email) — \(organization)"
    }
}

/// SwiftUI orders Settings front only within this app, and a menu bar app isn't
/// frontmost, so an already-open Settings window would stay behind other apps.
@MainActor
func focusSettingsWindow() {
    DispatchQueue.main.async {
        NSApp.activate(ignoringOtherApps: true)
        // Settings is the only titled window; the popover and status item aren't.
        if let window = NSApp.windows.first(where: { $0.isVisible && $0.styleMask.contains(.titled) }) {
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
        }
    }
}

struct LaunchAtLoginToggle: View {
    @StateObject private var model: LaunchAtLoginModel

    init(bundleURL: URL = Bundle.main.bundleURL) {
        _model = StateObject(
            wrappedValue: LaunchAtLoginModel(bundleURL: bundleURL)
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle("Apri all'avvio del Mac", isOn: Binding(
                get: { model.isEnabled },
                set: { model.setEnabled($0) }
            ))
            .disabled(!model.isSupported)

            if let message = model.message {
                Text(message)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

@MainActor
final class LaunchAtLoginModel: ObservableObject {
    @Published private(set) var isEnabled = false
    @Published private(set) var isSupported: Bool
    @Published private(set) var message: String?

    init(bundleURL: URL = Bundle.main.bundleURL) {
        isSupported = supportsLaunchAtLoginManagement(appURL: bundleURL)

        guard isSupported else {
            message = "Sposta l'app in Applicazioni per poterla aprire all'avvio."
            return
        }

        isEnabled = SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ enabled: Bool) {
        guard isSupported else { return }

        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            isEnabled = enabled
            message = nil
        } catch {
            isEnabled = SMAppService.mainApp.status == .enabled
            message = "Impossibile modificare l'apertura all'avvio."
        }
    }
}

func supportsLaunchAtLoginManagement(
    appURL: URL = Bundle.main.bundleURL,
    installDirectories: [URL] = launchAtLoginInstallDirectories()
) -> Bool {
    let normalizedAppURL = appURL.resolvingSymlinksInPath().standardizedFileURL

    return installDirectories.contains { directory in
        let normalizedDirectory = directory.resolvingSymlinksInPath().standardizedFileURL
        let directoryPath = normalizedDirectory.path
        let appPath = normalizedAppURL.path

        return appPath == directoryPath || appPath.hasPrefix(directoryPath + "/")
    }
}

func launchAtLoginInstallDirectories(fileManager: FileManager = .default) -> [URL] {
    [
        URL(fileURLWithPath: "/Applications", isDirectory: true),
        fileManager.homeDirectoryForCurrentUser.appending(path: "Applications", directoryHint: .isDirectory)
    ]
}

private struct ThresholdSlider: View {
    let label: String
    let value: Int
    let onChange: (Int) -> Void

    var body: some View {
        LabeledContent {
            Slider(
                value: Binding(
                    get: { Double(value) },
                    set: { onChange(Int($0)) }
                ),
                in: 0...100,
                step: 5
            )
        } label: {
            Text(label)
            Text(value > 0 ? "\(value)%" : "Spento")
                .foregroundStyle(.secondary)
        }
        .alignmentGuide(.firstTextBaseline) { d in
            d[VerticalAlignment.center]
        }
    }
}
