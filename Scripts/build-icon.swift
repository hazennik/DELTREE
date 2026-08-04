#!/usr/bin/env swift
import AppKit
import Foundation

struct IconSlot {
    let idiom = "mac"
    let size: Int
    let scale: Int

    var pixels: Int { size * scale }
    var filename: String {
        scale == 1 ? "app-icon-\(size).png" : "app-icon-\(size)@\(scale)x.png"
    }
}

let slots = [
    IconSlot(size: 16, scale: 1),
    IconSlot(size: 16, scale: 2),
    IconSlot(size: 32, scale: 1),
    IconSlot(size: 32, scale: 2),
    IconSlot(size: 128, scale: 1),
    IconSlot(size: 128, scale: 2),
    IconSlot(size: 256, scale: 1),
    IconSlot(size: 256, scale: 2),
    IconSlot(size: 512, scale: 1),
    IconSlot(size: 512, scale: 2),
]

var outputDirectory = "DELTREE/Assets.xcassets/AppIcon.appiconset"
var previewPath = "docs/assets/deltree-icon-preview.png"
var arguments = Array(CommandLine.arguments.dropFirst())

while arguments.isEmpty == false {
    let argument = arguments.removeFirst()
    switch argument {
    case "--output-dir":
        outputDirectory = arguments.removeFirst()
    case "--preview":
        previewPath = arguments.removeFirst()
    default:
        fputs("Unknown argument: \(argument)\n", stderr)
        exit(2)
    }
}

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(calibratedRed: red / 255, green: green / 255, blue: blue / 255, alpha: alpha)
}

func drawIcon(pixels: Int) throws -> NSBitmapImageRep {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0)
    else {
        throw NSError(domain: "DELTREEIcon", code: 1)
    }
    bitmap.size = NSSize(width: pixels, height: pixels)

    guard let graphicsContext = NSGraphicsContext(bitmapImageRep: bitmap) else {
        throw NSError(domain: "DELTREEIcon", code: 2)
    }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = graphicsContext
    defer { NSGraphicsContext.restoreGraphicsState() }

    let context = graphicsContext.cgContext

    context.setShouldAntialias(true)
    context.setAllowsAntialiasing(true)
    context.interpolationQuality = .none

    let rect = CGRect(origin: .zero, size: CGSize(width: pixels, height: pixels))
    context.clear(rect)

    let inset = CGFloat(pixels) * 0.08
    let body = rect.insetBy(dx: inset, dy: inset)
    let radius = CGFloat(pixels) * 0.19
    let bodyPath = NSBezierPath(roundedRect: body, xRadius: radius, yRadius: radius)

    color(4, 6, 5).setFill()
    bodyPath.fill()

    color(54, 255, 140).setStroke()
    bodyPath.lineWidth = max(2, CGFloat(pixels) * 0.018)
    bodyPath.stroke()

    let titleBar = CGRect(
        x: body.minX + body.width * 0.08,
        y: body.maxY - body.height * 0.22,
        width: body.width * 0.84,
        height: max(2, body.height * 0.055))
    color(246, 183, 40).setFill()
    NSBezierPath(roundedRect: titleBar, xRadius: titleBar.height / 2, yRadius: titleBar.height / 2).fill()

    let prompt = pixels < 64 ? ">" : "C:\\>"
    let promptSize = CGFloat(pixels) * (pixels < 64 ? 0.48 : 0.2)
    let promptFont = NSFont.monospacedSystemFont(ofSize: promptSize, weight: .bold)
    let promptAttributes: [NSAttributedString.Key: Any] = [
        .font: promptFont,
        .foregroundColor: color(72, 255, 154),
    ]
    let promptRect = CGRect(
        x: body.minX + body.width * 0.16,
        y: body.minY + body.height * (pixels < 64 ? 0.28 : 0.38),
        width: body.width * 0.78,
        height: body.height * 0.3)
    (prompt as NSString).draw(in: promptRect, withAttributes: promptAttributes)

    if pixels >= 128 {
        let labelFont = NSFont.monospacedSystemFont(ofSize: CGFloat(pixels) * 0.115, weight: .semibold)
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: labelFont,
            .foregroundColor: color(246, 183, 40),
        ]
        let labelRect = CGRect(
            x: body.minX + body.width * 0.18,
            y: body.minY + body.height * 0.22,
            width: body.width * 0.74,
            height: body.height * 0.18)
        ("DELTREE" as NSString).draw(in: labelRect, withAttributes: labelAttributes)
    }

    let cursorRect = CGRect(
        x: body.minX + body.width * 0.68,
        y: body.minY + body.height * 0.34,
        width: max(2, body.width * 0.1),
        height: max(2, body.height * 0.06))
    color(246, 183, 40).setFill()
    NSBezierPath(rect: cursorRect).fill()

    return bitmap
}

func writePNG(_ bitmap: NSBitmapImageRep, to url: URL) throws {
    guard let png = bitmap.representation(using: .png, properties: [:])
    else {
        throw NSError(domain: "DELTREEIcon", code: 3)
    }

    try png.write(to: url, options: .atomic)
}

let fileManager = FileManager.default
let outputURL = URL(fileURLWithPath: outputDirectory, isDirectory: true)
try fileManager.createDirectory(at: outputURL, withIntermediateDirectories: true)

for slot in slots {
    try writePNG(try drawIcon(pixels: slot.pixels), to: outputURL.appendingPathComponent(slot.filename))
}

let contents: [String: Any] = [
    "images": slots.map {
        [
            "filename": $0.filename,
            "idiom": $0.idiom,
            "scale": "\($0.scale)x",
            "size": "\($0.size)x\($0.size)",
        ]
    },
    "info": [
        "author": "xcode",
        "version": 1,
    ],
]
let json = try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
try json.write(to: outputURL.appendingPathComponent("Contents.json"), options: .atomic)

let previewURL = URL(fileURLWithPath: previewPath)
try fileManager.createDirectory(at: previewURL.deletingLastPathComponent(), withIntermediateDirectories: true)
try writePNG(try drawIcon(pixels: 512), to: previewURL)

print("Generated DELTREE app icon assets.")
