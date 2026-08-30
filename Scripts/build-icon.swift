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
var sourceImagePath = "docs/assets/deltree-icon-source.png"
var classicImageDirectory = "DELTREE/Assets.xcassets/ClassicAppIcon.imageset"
var classicPreviewPath = "docs/assets/deltree-icon-classic-preview.png"
var classicSourceImagePath = "docs/assets/deltree-icon-classic-source.png"
var arguments = Array(CommandLine.arguments.dropFirst())

while arguments.isEmpty == false {
    let argument = arguments.removeFirst()
    switch argument {
    case "--output-dir":
        outputDirectory = arguments.removeFirst()
    case "--preview":
        previewPath = arguments.removeFirst()
    case "--source":
        sourceImagePath = arguments.removeFirst()
    case "--classic-output-dir":
        classicImageDirectory = arguments.removeFirst()
    case "--classic-preview":
        classicPreviewPath = arguments.removeFirst()
    case "--classic-source":
        classicSourceImagePath = arguments.removeFirst()
    default:
        fputs("Unknown argument: \(argument)\n", stderr)
        exit(2)
    }
}

func makeImageSourceRect(for image: NSImage) -> NSRect {
    let sourceSize = image.size
    let cropSide = min(sourceSize.width, sourceSize.height)

    return NSRect(
        x: (sourceSize.width - cropSide) / 2,
        y: (sourceSize.height - cropSide) / 2,
        width: cropSide,
        height: cropSide)
}

func drawIcon(from sourceImage: NSImage, pixels: Int) throws -> NSBitmapImageRep {
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
    context.interpolationQuality = .high

    let rect = CGRect(origin: .zero, size: CGSize(width: pixels, height: pixels))
    context.clear(rect)

    sourceImage.draw(
        in: rect,
        from: makeImageSourceRect(for: sourceImage),
        operation: .copy,
        fraction: 1,
        respectFlipped: false,
        hints: [.interpolation: NSImageInterpolation.high])

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
let classicOutputURL = URL(fileURLWithPath: classicImageDirectory, isDirectory: true)
try fileManager.createDirectory(at: classicOutputURL, withIntermediateDirectories: true)

guard let sourceImage = NSImage(contentsOfFile: sourceImagePath) else {
    fputs("Unable to load icon source image: \(sourceImagePath)\n", stderr)
    exit(3)
}
guard let classicSourceImage = NSImage(contentsOfFile: classicSourceImagePath) else {
    fputs("Unable to load classic icon source image: \(classicSourceImagePath)\n", stderr)
    exit(3)
}

for slot in slots {
    try writePNG(try drawIcon(from: sourceImage, pixels: slot.pixels), to: outputURL.appendingPathComponent(slot.filename))
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
try writePNG(try drawIcon(from: sourceImage, pixels: 512), to: previewURL)

let classicAssetFilename = "classic-app-icon.png"
try writePNG(try drawIcon(from: classicSourceImage, pixels: 1024), to: classicOutputURL.appendingPathComponent(classicAssetFilename))

let classicContents: [String: Any] = [
    "images": [
        [
            "filename": classicAssetFilename,
            "idiom": "universal",
            "scale": "1x",
        ],
    ],
    "info": [
        "author": "xcode",
        "version": 1,
    ],
]
let classicJSON = try JSONSerialization.data(withJSONObject: classicContents, options: [.prettyPrinted, .sortedKeys])
try classicJSON.write(to: classicOutputURL.appendingPathComponent("Contents.json"), options: .atomic)

let classicPreviewURL = URL(fileURLWithPath: classicPreviewPath)
try fileManager.createDirectory(at: classicPreviewURL.deletingLastPathComponent(), withIntermediateDirectories: true)
try writePNG(try drawIcon(from: classicSourceImage, pixels: 512), to: classicPreviewURL)

print("Generated DELTREE app icon assets.")
