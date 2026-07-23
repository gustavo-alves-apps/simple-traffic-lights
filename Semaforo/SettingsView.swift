import SwiftUI

enum Layout: CaseIterable, Hashable {
    case fullScreen
    case circle
    case realistic

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
    @Published var layout: Layout = .fullScreen
    @Published var redDuration: Double = 5
    @Published var greenDuration: Double = 5
    @Published var yellowDuration: Double = 5

    func duration(for signal: Signal) -> Double {
        switch signal {
        case .red: return redDuration
        case .green: return greenDuration
        case .yellow: return yellowDuration
        }
    }
}

struct SettingsView: View {
    @ObservedObject var settings: SettingsStore
    @Binding var isPlaying: Bool
    @StateObject private var tipStore = TipStore()

    var body: some View {
        NavigationStack {
            Form {
                Section("Mode") {
                    Picker("Mode", selection: $settings.timerEnabled) {
                        Text("Tap").tag(false)
                        Text("Timer").tag(true)
                    }
                    .pickerStyle(.segmented)

                    if settings.timerEnabled {
                        durationRow(title: "Red", value: $settings.redDuration)
                        durationRow(title: "Green", value: $settings.greenDuration)
                        durationRow(title: "Yellow", value: $settings.yellowDuration)
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

                Section("Support") {
                    ForEach(tipStore.products) { product in
                        Button {
                            Task { await tipStore.purchase(product) }
                        } label: {
                            HStack {
                                Text(product.displayName)
                                Spacer()
                                Text(product.displayPrice)
                                    .foregroundStyle(.secondary)
                            }
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
