import SwiftUI

struct RemoteControlView: View {
    @ObservedObject var remote: RemoteSession
    @Environment(\.dismiss) private var dismiss

    @State private var code = ""
    @FocusState private var codeFocused: Bool

    var body: some View {
        NavigationStack {
            Group {
                if remote.role == .controller && remote.controllerStatus == .connected {
                    controls
                } else {
                    pairing
                }
            }
            .navigationTitle("Remote control")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onDisappear {
            if remote.role == .controller {
                remote.stop()
            }
        }
    }

    // MARK: Pairing

    private var pairing: some View {
        VStack(spacing: 24) {
            Text("On the other iPhone, turn on “Allow remote control”, then enter its code here.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            TextField("0000", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .font(.system(size: 48, weight: .bold, design: .rounded).monospacedDigit())
                .multilineTextAlignment(.center)
                .focused($codeFocused)
                .onChange(of: code) { _, newValue in
                    let digits = String(newValue.filter(\.isNumber).prefix(4))
                    if digits != newValue { code = digits }
                }
                .disabled(isSearching)

            statusMessage

            Button {
                codeFocused = false
                remote.connect(code: code)
            } label: {
                Text("Connect")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .disabled(code.count != 4 || isSearching)

            Spacer()
        }
        .padding()
        .onAppear { codeFocused = true }
    }

    private var isSearching: Bool {
        remote.role == .controller && remote.controllerStatus == .searching
    }

    @ViewBuilder
    private var statusMessage: some View {
        switch remote.controllerStatus {
        case .searching where remote.role == .controller:
            HStack(spacing: 8) {
                ProgressView()
                Text("Searching…")
            }
            .foregroundStyle(.secondary)
        case .notFound:
            Label("No traffic light found with this code.", systemImage: "exclamationmark.triangle")
                .foregroundStyle(.orange)
        case .disconnected:
            Label("Connection lost.", systemImage: "wifi.slash")
                .foregroundStyle(.orange)
        default:
            EmptyView()
        }
    }

    // MARK: Controls

    private var controls: some View {
        VStack(spacing: 32) {
            Label("Connected", systemImage: "antenna.radiowaves.left.and.right")
                .foregroundStyle(.green)

            HStack(spacing: 20) {
                ForEach(Signal.displayOrder.filter(remote.remoteEnabled.contains), id: \.self) { signal in
                    Button {
                        remote.send(signal: signal)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    } label: {
                        Circle()
                            .fill(signal.color.opacity(remote.remoteSignal == signal ? 1 : 0.3))
                            .overlay {
                                Circle().strokeBorder(.primary.opacity(remote.remoteSignal == signal ? 0.8 : 0), lineWidth: 4)
                            }
                            .frame(width: 90, height: 90)
                    }
                    .buttonStyle(.plain)
                }
            }
            .disabled(remote.remoteTimerEnabled)

            Button {
                remote.sendNext()
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } label: {
                Label("Next", systemImage: "arrow.forward")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .disabled(remote.remoteTimerEnabled)

            Group {
                if remote.remoteTimerEnabled {
                    Label("Timer mode: the colors change on their own.", systemImage: "timer")
                } else {
                    Text("The traffic light must be playing to change color.")
                }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
        .padding(.top, 24)
    }
}
