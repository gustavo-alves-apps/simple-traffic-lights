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
            }
            .navigationTitle("Traffic Light")
            .safeAreaInset(edge: .bottom) {
                Button("Play") {
                    isPlaying = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .padding()
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
