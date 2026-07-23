import SwiftUI

enum Signal: CaseIterable {
    case red, green, yellow

    var color: Color {
        switch self {
        case .red: return .red
        case .green: return .green
        case .yellow: return .yellow
        }
    }

    var next: Signal {
        switch self {
        case .red: return .green
        case .green: return .yellow
        case .yellow: return .red
        }
    }
}

struct SemaforoPlayView: View {
    @ObservedObject var settings: SettingsStore
    @Binding var isPlaying: Bool

    @State private var signal: Signal = .red
    @State private var secondsRemaining: Int = 0
    @State private var timer: Timer?

    var body: some View {
        GeometryReader { proxy in
            let isLandscape = proxy.size.width > proxy.size.height

            ZStack {
                Color.black.ignoresSafeArea()

                content
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard !settings.timerEnabled else { return }
                        advance()
                    }
            }
            .overlay(alignment: .topTrailing) {
                Button {
                    stopTimer()
                    isPlaying = false
                } label: {
                    Image(systemName: "gearshape")
                        .font(.title3)
                        .foregroundStyle(settings.layout == .fullScreen ? .black.opacity(0.6) : .white.opacity(0.6))
                        .padding(10)
                }
                .padding(.top, 16)
                .padding(.trailing, 20)
                .ignoresSafeArea()
            }
            .overlay(alignment: isLandscape ? .bottomTrailing : .bottom) {
                if settings.timerEnabled && settings.showCountdown {
                    Text("\(secondsRemaining)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(countdownColor)
                        .padding(.bottom, isLandscape ? 20 : 32)
                        .padding(.trailing, isLandscape ? 20 : 0)
                        .ignoresSafeArea()
                }
            }
        }
        .ignoresSafeArea()
        .statusBarHidden()
        .onAppear {
            startTimerIfNeeded()
            OrientationManager.orientationLock = orientationMask
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            stopTimer()
            OrientationManager.orientationLock = .portrait
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onChange(of: settings.timerEnabled) { _, _ in
            stopTimer()
            startTimerIfNeeded()
        }
        .onChange(of: settings.layout) { _, _ in
            OrientationManager.orientationLock = orientationMask
        }
    }

    private var orientationMask: UIInterfaceOrientationMask {
        settings.layout == .realistic ? .portrait : .allButUpsideDown
    }

    private var countdownColor: Color {
        switch settings.layout {
        case .circle, .realistic: return signal.color
        case .fullScreen: return signal.color.darker(by: 0.35)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch settings.layout {
        case .fullScreen:
            signal.color.ignoresSafeArea()
        case .circle:
            GeometryReader { proxy in
                let side = min(proxy.size.width, proxy.size.height) * 0.85
                Circle()
                    .fill(signal.color)
                    .frame(width: side, height: side)
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            }
        case .realistic:
            RealisticSignalView(signal: signal)
        }
    }

    private func startTimerIfNeeded() {
        guard settings.timerEnabled else { return }
        secondsRemaining = Int(settings.duration(for: signal))
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if secondsRemaining > 1 {
                secondsRemaining -= 1
            } else {
                advance()
                secondsRemaining = Int(settings.duration(for: signal))
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func advance() {
        signal = signal.next
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}

extension Color {
    func darker(by amount: CGFloat) -> Color {
        let uiColor = UIColor(self)
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return Color(hue: hue, saturation: saturation, brightness: max(brightness - amount, 0))
    }
}
