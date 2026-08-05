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

    @Test func classicReclaimableBadgeUsesNeutralGray() throws {
        let state = StatusItemIconState(isFilled: false, badge: .reclaimable)
        let rep = try Self.bitmapRep(for: StatusItemIconRenderer.image(for: state, visualMode: .classic))

        let coloredPixels = (0..<rep.pixelsHigh).flatMap { y in
            (0..<rep.pixelsWide).compactMap { x -> NSColor? in
                guard let color = rep.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB),
                      color.alphaComponent > 0.5
                else {
                    return nil
                }
                return color
            }
        }

        #expect(coloredPixels.isEmpty == false)
        for color in coloredPixels {
            let spread = max(color.redComponent, color.greenComponent, color.blueComponent)
                - min(color.redComponent, color.greenComponent, color.blueComponent)
            #expect(spread < 0.08)
        }
    }

    private static func alphaMask(for image: NSImage) throws -> [Bool] {
        let rep = try bitmapRep(for: image)

        return (0..<rep.pixelsHigh).flatMap { y in
            (0..<rep.pixelsWide).map { x in
                (rep.colorAt(x: x, y: y)?.alphaComponent ?? 0) > 0.01
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
