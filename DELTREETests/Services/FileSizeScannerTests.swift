import Foundation
import Testing
@testable import DELTREE

struct FileSizeScannerTests {
    @Test func totalsNestedFilesAndSkipsSymlinks() throws {
        let fileManager = FileManager.default
        let root = fileManager.temporaryDirectory.appendingPathComponent("DELTREE-file-size-\(UUID().uuidString)", isDirectory: true)
        defer { try? fileManager.removeItem(at: root) }

        let nested = root.appendingPathComponent("Nested", isDirectory: true)
        try fileManager.createDirectory(at: nested, withIntermediateDirectories: true)
        let first = root.appendingPathComponent("first.bin")
        let second = nested.appendingPathComponent("second.bin")
        try Data(repeating: 1, count: 128).write(to: first)
        try Data(repeating: 2, count: 256).write(to: second)

        let scanner = LiveFileSizeScanner(fileManager: fileManager)
        let beforeSymlink = scanner.size(of: root)

        try fileManager.createSymbolicLink(
            at: nested.appendingPathComponent("first-link.bin"),
            withDestinationURL: first)
        let afterSymlink = scanner.size(of: root)

        #expect(beforeSymlink.bytes >= 384)
        #expect(afterSymlink.bytes == beforeSymlink.bytes)
        #expect(afterSymlink.unreadablePaths.isEmpty)
    }
}
