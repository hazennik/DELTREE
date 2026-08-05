import AppKit
import Testing
@testable import DELTREE

@MainActor
struct StatusItemIconRendererTests {
    @Test func classicAndModernIconsShareBaseSilhouette() throws {
        let state = StatusItemIconState(isFilled: false, badge: .none)

        let classicMask = try Self.alphaMask(for: StatusItemIconRenderer.image(for: state, visualMode: .classic))
        let modernMask = try Self.alphaMask(for: StatusItemIconRenderer.image(for: state, visualMode: .modern))

        #expect(classicMask == modernMask)
    }

    private static func alphaMask(for image: NSImage) throws -> [Bool] {
        let pixelSize = 18
        let size = NSSize(width: pixelSize, height: pixelSize)
        let rep = try #require(NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: pixelSize,
            pixelsHigh: pixelSize,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0))

        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        NSColor.clear.setFill()
        NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()
        image.draw(in: NSRect(origin: .zero, size: size), from: .zero, operation: .copy, fraction: 1)

        return (0..<pixelSize).flatMap { y in
            (0..<pixelSize).map { x in
                (rep.colorAt(x: x, y: y)?.alphaComponent ?? 0) > 0.01
            }
        }
    }
}
