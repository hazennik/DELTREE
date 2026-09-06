import AppKit
import Testing
@testable import DELTREE

@MainActor
struct StatusItemIconRendererTests {
    @Test func menuBarIconDoesNotChangeWithVisualMode() throws {
        let states = [
            StatusItemIconState(isFilled: false, badge: .none),
            StatusItemIconState(isFilled: true, badge: .reclaimable),
            StatusItemIconState(isFilled: false, badge: .warning),
        ]

        for state in states {
            let classicPixels = try Self.pixelColors(for: StatusItemIconRenderer.image(for: state, visualMode: .classic))
            let modernPixels = try Self.pixelColors(for: StatusItemIconRenderer.image(for: state, visualMode: .modern))

            #expect(classicPixels == modernPixels)
        }
    }

    private static func pixelColors(for image: NSImage) throws -> [[CGFloat]] {
        let rep = try bitmapRep(for: image)
        return (0..<rep.pixelsHigh).flatMap { y in
            (0..<rep.pixelsWide).map { x in
                guard let color = rep.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB) else {
                    return [0, 0, 0, 0]
                }
                return [color.redComponent, color.greenComponent, color.blueComponent, color.alphaComponent]
            }
        }
    }

    private static func bitmapRep(for image: NSImage) throws -> NSBitmapImageRep {
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

        return rep
    }
}
