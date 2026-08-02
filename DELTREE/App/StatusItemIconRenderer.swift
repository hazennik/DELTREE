import AppKit

@MainActor
enum StatusItemIconRenderer {
    static func image(for state: StatusItemIconState) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            drawIcon(in: rect, state: state)
            return true
        }
        image.isTemplate = false
        image.accessibilityDescription = state.accessibilityDescription
        return image
    }

    private static func drawIcon(in rect: NSRect, state: StatusItemIconState) {
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

        let mainColor = NSColor.labelColor
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

        drawBadge(state.badge, in: rect, scale: min(scaleX, scaleY))
    }

    private static func drawBadge(_ badge: StatusItemIconBadge, in rect: NSRect, scale: CGFloat) {
        guard badge != .none else {
            return
        }

        let badgeColor: NSColor
        switch badge {
        case .none:
            badgeColor = .clear
        case .reclaimable:
            badgeColor = .systemGreen
        case .warning:
            badgeColor = .systemOrange
        }

        let diameter = max(4.4, 5.2 * scale)
        let badgeRect = NSRect(
            x: rect.maxX - diameter - (1.2 * scale),
            y: rect.minY + (1.2 * scale),
            width: diameter,
            height: diameter)

        let backingRect = badgeRect.insetBy(dx: -1.1 * scale, dy: -1.1 * scale)
        NSColor.windowBackgroundColor.withAlphaComponent(0.88).setFill()
        NSBezierPath(ovalIn: backingRect).fill()

        badgeColor.setFill()
        NSBezierPath(ovalIn: badgeRect).fill()
    }
}
