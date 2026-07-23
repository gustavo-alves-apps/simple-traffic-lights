import SwiftUI

struct RealisticSignalView: View {
    let signal: Signal

    private let aspectRatio: CGFloat = 0.35
    private let earRatio: CGFloat = 0.16

    var body: some View {
        GeometryReader { proxy in
            let maxWidthWithEars = proxy.size.width * 0.94
            let totalHeightBudget = proxy.size.height * 0.82

            let housingHeightFromWidth = (maxWidthWithEars / (1 + 2 * earRatio)) / aspectRatio
            let housingHeight = min(housingHeightFromWidth, totalHeightBudget)
            let housingWidth = housingHeight * aspectRatio

            housing(width: housingWidth, height: housingHeight)
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .center)
        }
    }

    private var housingGradient: LinearGradient {
        LinearGradient(
            colors: [Color(white: 0.17), Color(white: 0.06), Color(white: 0.025)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var edgeStroke: Color {
        Color.white.opacity(0.16)
    }

    private func metalSurface<S: Shape>(_ shape: S) -> some View {
        shape
            .fill(housingGradient)
            .overlay(BrushedMetalTexture().clipShape(shape))
            .overlay(shape.stroke(edgeStroke, lineWidth: 1))
    }

    private func housing(width: CGFloat, height: CGFloat) -> some View {
        let cornerRadius = width * 0.14
        let lensDiameter = width * 0.72
        let slots: CGFloat = 3
        let spacing = (height - lensDiameter * slots) / (slots + 1)
        let earWidth = width * earRatio
        let earHeight = lensDiameter * 0.86
        let seam1Y = 1.5 * spacing + lensDiameter
        let seam2Y = 2.5 * spacing + 2 * lensDiameter

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

            metalSurface(RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(seam(width: width * 0.92).offset(y: seam1Y - height / 2))
                .overlay(seam(width: width * 0.92).offset(y: seam2Y - height / 2))
                .overlay(
                    VStack(spacing: spacing) {
                        lens(.red, diameter: lensDiameter)
                        lens(.yellow, diameter: lensDiameter)
                        lens(.green, diameter: lensDiameter)
                    }
                    .padding(.vertical, spacing)
                )
                .overlay(
                    joinScrews(width: width, height: height, spacing: spacing, seam1Y: seam1Y, seam2Y: seam2Y)
                )
                .frame(width: width, height: height)
        }
        .shadow(color: .black.opacity(0.6), radius: width * 0.12, y: width * 0.08)
    }

    private func seam(width: CGFloat) -> some View {
        VStack(spacing: 0) {
            Rectangle().fill(Color.black.opacity(0.55)).frame(width: width, height: 1.5)
            Rectangle().fill(Color.white.opacity(0.08)).frame(width: width, height: 1)
        }
    }

    private func joinScrews(width: CGFloat, height: CGFloat, spacing: CGFloat, seam1Y: CGFloat, seam2Y: CGFloat) -> some View {
        let size = width * 0.05
        let insetX = width * 0.16

        return ZStack {
            screw(size: size, rotation: 12).position(x: insetX, y: spacing * 0.5)
            screw(size: size, rotation: 100).position(x: width - insetX, y: spacing * 0.5)

            screw(size: size, rotation: 48).position(x: insetX, y: seam1Y)
            screw(size: size, rotation: 140).position(x: width - insetX, y: seam1Y)

            screw(size: size, rotation: 75).position(x: insetX, y: seam2Y)
            screw(size: size, rotation: 20).position(x: width - insetX, y: seam2Y)

            screw(size: size, rotation: 60).position(x: insetX, y: height - spacing * 0.5)
            screw(size: size, rotation: 155).position(x: width - insetX, y: height - spacing * 0.5)
        }
        .frame(width: width, height: height)
    }

    private func screw(size: CGFloat, rotation: Double) -> some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(white: 0.7), Color(white: 0.18)],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: size
                    )
                )
                .overlay(Circle().stroke(Color.black.opacity(0.6), lineWidth: max(size * 0.06, 0.5)))

            Rectangle()
                .fill(Color.black.opacity(0.55))
                .frame(width: size * 0.68, height: max(size * 0.12, 0.6))
                .rotationEffect(.degrees(rotation))
        }
        .frame(width: size, height: size)
    }

    private func ear(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            metalSurface(Ellipse())

            screw(size: width * 0.22, rotation: 30)
                .position(x: width, y: height / 2)
        }
        .frame(width: width * 2, height: height)
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
                    .frame(width: diameter * 1.5, height: diameter * 1.5)
                    .blur(radius: diameter * 0.25)
                    .opacity(0.3)
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

}

private struct BrushedMetalTexture: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 1.8
            let diagonal = size.width + size.height
            var offset: CGFloat = -size.height
            var index = 0

            while offset < diagonal {
                var path = Path()
                path.move(to: CGPoint(x: offset, y: 0))
                path.addLine(to: CGPoint(x: offset + size.height, y: size.height))
                let opacity: Double = index.isMultiple(of: 2) ? 0.12 : 0.05
                context.stroke(path, with: .color(.white.opacity(opacity)), lineWidth: 1)
                offset += spacing
                index += 1
            }
        }
        .blendMode(.plusLighter)
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
