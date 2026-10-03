import SwiftUI

enum Layout: CaseIterable, Hashable {
    case realistic
    case fullScreen
    case circle

    var title: LocalizedStringKey {
        switch self {
        case .fullScreen: return "Full screen"
        case .circle: return "Circle"
        case .realistic: return "Realistic"
        }
    }
}

final class SettingsStore: ObservableObject {
    @Published var timerEnabled: Bool = false
    @Published var showCountdown: Bool = false
    @Published var layout: Layout = .realistic
    @Published var redDuration: Double = 5
    @Published var greenDuration: Double = 5
    @Published var yellowDuration: Double = 5
    @Published var redEnabled: Bool = true
    @Published var yellowEnabled: Bool = true
    @Published var greenEnabled: Bool = true

    func duration(for signal: Signal) -> Double {
        switch signal {
        case .red: return redDuration
        case .green: return greenDuration
        case .yellow: return yellowDuration
        }
    }

    func isEnabled(_ signal: Signal) -> Bool {
        switch signal {
        case .red: return redEnabled
        case .yellow: return yellowEnabled
        case .green: return greenEnabled
        }
    }

    func setEnabled(_ value: Bool, for signal: Signal) {
        switch signal {
        case .red: redEnabled = value
        case .yellow: yellowEnabled = value
        case .green: greenEnabled = value
        }
    }
}

struct SettingsView: View {
    @ObservedObject var settings: SettingsStore
    @ObservedObject var remote: RemoteSession
    @Binding var isPlaying: Bool
    @StateObject private var tipStore = TipStore()
    @State private var showingRemoteControl = false

    // Toggle to false for App Store marketing screenshots (hides the tip jar).
    private let showSupportSection = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Colors") {
                    colorToggleRow(title: "Red", signal: .red)
                    colorToggleRow(title: "Yellow", signal: .yellow)
                    colorToggleRow(title: "Green", signal: .green)
                }

                Section("Mode") {
                    Picker("Mode", selection: $settings.timerEnabled) {
                        Text("Tap").tag(false)
                        Text("Timer").tag(true)
                    }
                    .pickerStyle(.segmented)

                    if settings.timerEnabled {
                        if settings.redEnabled {
                            durationRow(title: "Red", value: $settings.redDuration)
                        }
                        if settings.yellowEnabled {
                            durationRow(title: "Yellow", value: $settings.yellowDuration)
                        }
                        if settings.greenEnabled {
                            durationRow(title: "Green", value: $settings.greenDuration)
                        }
                        Toggle("Show countdown", isOn: $settings.showCountdown)
                    }
                }

                Section("Layout") {
                    Picker("Layout", selection: $settings.layout) {
                        ForEach(Layout.allCases, id: \.self) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Toggle("Allow remote control", isOn: Binding(
                        get: { remote.role == .light },
                        set: { $0 ? remote.startLight() : remote.stop() }
                    ))

                    if remote.role == .light {
                        HStack {
                            Text("Pairing code")
                            Spacer()
                            Text(remote.code)
                                .font(.title2.monospacedDigit().weight(.semibold))
                        }
                        HStack {
                            Text("Connected devices")
                            Spacer()
                            Text("\(remote.connectedControllers)")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button {
                        showingRemoteControl = true
                    } label: {
                        Label("Control another traffic light", systemImage: "iphone.radiowaves.left.and.right")
                    }
                } header: {
                    Text("Remote control")
                } footer: {
                    Text("Both iPhones must be nearby with Wi-Fi or Bluetooth on.")
                }

                if showSupportSection && !tipStore.products.isEmpty {
                    Section {
                        Menu {
                            ForEach(tipStore.products) { product in
                                Button {
                                    Task { await tipStore.purchase(product) }
                                } label: {
                                    Text(product.displayName)
                                    Text(product.displayPrice)
                                }
                            }
                        } label: {
                            Label("Buy me a coffee", systemImage: "cup.and.saucer")
                        }
                    }
                }
            }
            .navigationTitle("Simple Traffic Lights")
            .safeAreaInset(edge: .bottom) {
                Button {
                    isPlaying = true
                } label: {
                    Text("Play")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
                .padding()
            }
            .task {
                await tipStore.load()
            }
            .sheet(isPresented: $showingRemoteControl) {
                RemoteControlView(remote: remote)
            }
            .alert(
                tipStore.alertMessage ?? "",
                isPresented: Binding(
                    get: { tipStore.alertMessage != nil },
                    set: { if !$0 { tipStore.alertMessage = nil } }
                )
            ) {
                Button("OK") {}
            }
        }
    }

    @ViewBuilder
    private func colorToggleRow(title: LocalizedStringKey, signal: Signal) -> some View {
        Toggle(isOn: Binding(
            get: { settings.isEnabled(signal) },
            set: { newValue in
                guard !newValue else {
                    settings.setEnabled(true, for: signal)
                    return
                }
                let othersEnabled = Signal.allCases.contains { $0 != signal && settings.isEnabled($0) }
                if othersEnabled {
                    settings.setEnabled(false, for: signal)
                }
            }
        )) {
            Text(title)
        }
    }

    @ViewBuilder
    private func durationRow(title: LocalizedStringKey, value: Binding<Double>) -> some View {
        Stepper(value: value, in: 1...3600, step: 1) {
            HStack {
                Text(title)
                Spacer()
                Text("\(Int(value.wrappedValue))s")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
