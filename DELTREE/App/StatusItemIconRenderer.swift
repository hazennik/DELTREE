import AppKit

@MainActor
enum StatusItemIconRenderer {
    static func image(for state: StatusItemIconState, visualMode: AppVisualMode = .modern) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            drawIcon(in: rect, state: state, visualMode: visualMode)
            return true
        }
        image.isTemplate = false
        image.accessibilityDescription = state.accessibilityDescription
        return image
    }

    private static func drawIcon(in rect: NSRect, state: StatusItemIconState, visualMode: AppVisualMode) {
        let scaleX = rect.width / 18
        let scaleY = rect.height / 18

        func scaled(_ value: CGFloat, axisScale: CGFloat) -> CGFloat {
            value * axisScale
        }

        func point(_ x: CGFloat, _ y: CGFloat) -> NSPoint {
            NSPoint(
                x: rect.minX + scaled(x, axisScale: scaleX),
                y: rect.minY + scaled(y, axisScale: scaleY))
        }

        func frame(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> NSRect {
            NSRect(
                x: rect.minX + scaled(x, axisScale: scaleX),
                y: rect.minY + scaled(y, axisScale: scaleY),
                width: scaled(width, axisScale: scaleX),
                height: scaled(height, axisScale: scaleY))
        }

        let mainColor = visualMode == .classic
            ? NSColor(srgbRed: 0.78, green: 0.86, blue: 0.83, alpha: 1)
            : NSColor.labelColor
        let strokeColor = mainColor.withAlphaComponent(state.isFilled ? 0.95 : 0.82)
        let fillColor = mainColor.withAlphaComponent(state.isFilled ? 0.9 : 0)
        let lineWidth = max(1, scaled(1.35, axisScale: min(scaleX, scaleY)))

        let connector = NSBezierPath()
        connector.lineWidth = lineWidth
        connector.lineCapStyle = .round
        connector.lineJoinStyle = .round
        connector.move(to: point(9, 11.4))
        connector.line(to: point(9, 9.2))
        connector.line(to: point(5, 8))
        connector.move(to: point(9, 9.2))
        connector.line(to: point(13, 8))
        strokeColor.setStroke()
        connector.stroke()

        let nodes = [
            frame(6.3, 11.2, 5.4, 5.4),
            frame(2.3, 2.9, 5.4, 5.4),
            frame(10.3, 2.9, 5.4, 5.4),
        ]

        for node in nodes {
            let path = NSBezierPath(roundedRect: node, xRadius: scaled(1.1, axisScale: scaleX), yRadius: scaled(1.1, axisScale: scaleY))
            fillColor.setFill()
            path.fill()
            strokeColor.setStroke()
            path.lineWidth = lineWidth
            path.stroke()
        }

        drawBadge(state.badge, in: rect, scale: min(scaleX, scaleY), visualMode: visualMode)
    }

    private static func drawBadge(
        _ badge: StatusItemIconBadge,
        in rect: NSRect,
        scale: CGFloat,
        visualMode: AppVisualMode)
    {
        guard badge != .none else {
            return
        }

        let badgeColor: NSColor
        switch badge {
        case .none:
            badgeColor = .clear
        case .reclaimable:
            badgeColor = visualMode == .classic ? NSColor(srgbRed: 0.0, green: 0.95, blue: 0.98, alpha: 1) : .systemGreen
        case .warning:
            badgeColor = visualMode == .classic ? NSColor(srgbRed: 1.0, green: 0.72, blue: 0.22, alpha: 1) : .systemOrange
        }

        let diameter = max(4.4, 5.2 * scale)
        let badgeRect = NSRect(
            x: rect.maxX - diameter - (1.2 * scale),
            y: rect.minY + (1.2 * scale),
            width: diameter,
            height: diameter)

        let backingRect = badgeRect.insetBy(dx: -1.1 * scale, dy: -1.1 * scale)
        let backingColor = visualMode == .classic
            ? NSColor(srgbRed: 0.01, green: 0.03, blue: 0.02, alpha: 0.92)
            : NSColor.windowBackgroundColor.withAlphaComponent(0.88)
        backingColor.setFill()
        NSBezierPath(ovalIn: backingRect).fill()

        badgeColor.setFill()
        NSBezierPath(ovalIn: badgeRect).fill()
    }
}
