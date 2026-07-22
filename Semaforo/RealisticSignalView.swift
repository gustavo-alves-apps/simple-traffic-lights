import SwiftUI

struct RealisticSignalView: View {
    let signal: Signal

    private let aspectRatio: CGFloat = 0.42
    private let earRatio: CGFloat = 0.34

    var body: some View {
        GeometryReader { proxy in
            let maxWidthWithEars = proxy.size.width * 0.9
            let housingWidthFromWidth = maxWidthWithEars / (1 + 2 * earRatio)
            let maxHeight = proxy.size.height * 0.8
            let housingHeight = min(maxHeight, housingWidthFromWidth / aspectRatio)
            let housingWidth = housingHeight * aspectRatio
            let poleHeight = max(proxy.size.height * 0.86 - housingHeight - housingWidth * 0.14, 0)

            VStack(spacing: 0) {
                topCap(width: housingWidth)
                housing(width: housingWidth, height: housingHeight)
                pole(width: housingWidth * 0.16, height: poleHeight)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }

    private var housingGradient: LinearGradient {
        LinearGradient(
            colors: [Color(white: 0.24), Color(white: 0.1), Color(white: 0.04)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func topCap(width: CGFloat) -> some View {
        Capsule()
            .fill(housingGradient)
            .overlay(Capsule().stroke(Color.black.opacity(0.85), lineWidth: 1))
            .frame(width: width * 0.32, height: width * 0.16)
            .padding(.bottom, -width * 0.04)
    }

    private func housing(width: CGFloat, height: CGFloat) -> some View {
        let cornerRadius = width * 0.14
        let lensDiameter = width * 0.72
        let slots: CGFloat = 3
        let spacing = (height - lensDiameter * slots) / (slots + 1)
        let earWidth = width * earRatio
        let earHeight = lensDiameter * 0.86

        return ZStack {
            VStack(spacing: spacing) {
                ForEach(0..<3, id: \.self) { _ in
                    HStack(spacing: 0) {
                        ear(width: earWidth, height: earHeight)
                        Spacer(minLength: 0)
                        ear(width: earWidth, height: earHeight)
                            .scaleEffect(x: -1, y: 1)
                    }
                    .frame(height: lensDiameter)
                }
            }
            .padding(.vertical, spacing)
            .frame(width: width + earWidth * 2, height: height)

            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(housingGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.black.opacity(0.85), lineWidth: max(width * 0.012, 1))
                )
                .overlay(
                    VStack(spacing: spacing) {
                        lens(.red, diameter: lensDiameter)
                        lens(.yellow, diameter: lensDiameter)
                        lens(.green, diameter: lensDiameter)
                    }
                    .padding(.vertical, spacing)
                )
                .overlay(screws(cornerRadius: cornerRadius))
                .frame(width: width, height: height)
        }
        .shadow(color: .black.opacity(0.6), radius: width * 0.12, y: width * 0.08)
    }

    private func ear(width: CGFloat, height: CGFloat) -> some View {
        Ellipse()
            .fill(housingGradient)
            .frame(width: width * 2, height: height)
            .overlay(
                Ellipse()
                    .stroke(Color.black.opacity(0.7), lineWidth: 1)
                    .frame(width: width * 2, height: height)
            )
            .mask(
                HStack(spacing: 0) {
                    Rectangle().frame(width: width)
                    Color.clear.frame(width: width)
                }
            )
    }

    @ViewBuilder
    private func lens(_ target: Signal, diameter: CGFloat) -> some View {
        let isOn = target == signal
        let base = target.color

        ZStack {
            if isOn {
                Circle()
                    .fill(base)
                    .frame(width: diameter * 2.3, height: diameter * 2.3)
                    .blur(radius: diameter * 0.45)
                    .opacity(0.55)
            }

            Circle()
                .fill(Color.black.opacity(0.9))
                .frame(width: diameter * 1.24, height: diameter * 1.24)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.87, green: 0.8, blue: 0.6), Color(red: 0.55, green: 0.48, blue: 0.32)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: diameter * 1.1, height: diameter * 1.1)

            Circle()
                .fill(
                    RadialGradient(
                        colors: isOn
                            ? [base.opacity(1), base, base.darker(by: 0.35)]
                            : [base.darker(by: 0.4).opacity(0.9), base.darker(by: 0.7).opacity(0.9)],
                        center: UnitPoint(x: 0.35, y: 0.28),
                        startRadius: 0,
                        endRadius: diameter * 0.78
                    )
                )
                .frame(width: diameter, height: diameter)

            LEDDotGrid(diameter: diameter * 0.94, color: base, isOn: isOn)

            Circle()
                .strokeBorder(Color.white.opacity(isOn ? 0.35 : 0.1), lineWidth: diameter * 0.02)
                .frame(width: diameter * 0.96, height: diameter * 0.96)

            topHood(diameter: diameter)

            Ellipse()
                .fill(Color.white.opacity(isOn ? 0.6 : 0.15))
                .frame(width: diameter * 0.4, height: diameter * 0.22)
                .rotationEffect(.degrees(-30))
                .offset(x: -diameter * 0.16, y: -diameter * 0.22)
                .blur(radius: diameter * 0.03)

            Ellipse()
                .fill(Color.white.opacity(isOn ? 0.85 : 0.2))
                .frame(width: diameter * 0.12, height: diameter * 0.07)
                .rotationEffect(.degrees(-30))
                .offset(x: -diameter * 0.22, y: -diameter * 0.28)
        }
        .frame(width: diameter, height: diameter)
    }

    private func topHood(diameter: CGFloat) -> some View {
        Circle()
            .trim(from: 0.64, to: 0.86)
            .stroke(Color.black.opacity(0.75), style: StrokeStyle(lineWidth: diameter * 0.09, lineCap: .round))
            .frame(width: diameter * 1.18, height: diameter * 1.18)
            .offset(y: -diameter * 0.02)
    }

    private func screws(cornerRadius: CGFloat) -> some View {
        GeometryReader { proxy in
            let inset = cornerRadius * 0.8
            let size = cornerRadius * 0.3
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(white: 0.6), Color(white: 0.15)],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: size
                        )
                    )
                    .frame(width: size, height: size)
                    .position(
                        x: index % 2 == 0 ? inset : proxy.size.width - inset,
                        y: index < 2 ? inset : proxy.size.height - inset
                    )
            }
        }
    }

    private func pole(width: CGFloat, height: CGFloat) -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color(white: 0.4), Color(white: 0.15), Color(white: 0.3)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: max(width, 5), height: max(height, 0))
    }
}

private struct LEDDotGrid: View {
    let diameter: CGFloat
    let color: Color
    let isOn: Bool

    var body: some View {
        Canvas { context, size in
            let spacing = size.width / 11
            let dotRadius = spacing * 0.3
            let rowHeight = spacing * 0.87
            let dotColor = isOn ? color.opacity(0.9) : Color.black.opacity(0.3)

            var row = 0
            var y = dotRadius
            while y < size.height {
                let offsetX = row.isMultiple(of: 2) ? 0 : spacing / 2
                var x = dotRadius + offsetX
                while x < size.width {
                    let rect = CGRect(x: x - dotRadius, y: y - dotRadius, width: dotRadius * 2, height: dotRadius * 2)
                    context.fill(Path(ellipseIn: rect), with: .color(dotColor))
                    x += spacing
                }
                y += rowHeight
                row += 1
            }
        }
        .frame(width: diameter, height: diameter)
        .clipShape(Circle())
        .blendMode(isOn ? .screen : .normal)
        .opacity(isOn ? 1 : 0.5)
    }
}
