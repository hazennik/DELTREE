import Foundation
import Testing
@testable import DELTREE

struct FileSizeScannerTests {
    @Test(.timeLimit(.minutes(1))) func totalsNestedFilesAndSkipsSymlinks() throws {
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
        #expect(beforeSymlink.scannedEntryCount >= 2)
        #expect(beforeSymlink.isComplete)
        #expect(afterSymlink.bytes == beforeSymlink.bytes)
        #expect(afterSymlink.unreadablePaths.isEmpty)
        #expect(afterSymlink.isComplete)
    }

    @Test(.timeLimit(.minutes(1))) func budgetMarksLargeDirectoryIncomplete() throws {
        let fileManager = FileManager.default
        let root = try Self.makeTemporaryDirectory()
        defer { try? fileManager.removeItem(at: root) }

        for index in 0..<10 {
            try Data(repeating: UInt8(index), count: 64)
                .write(to: root.appendingPathComponent("file-\(index).bin"))
        }

        let scanner = LiveFileSizeScanner(
            fileManager: fileManager,
            budget: FileSizeScanBudget(maxEntryCount: 3))
        let result = scanner.size(of: root)

        #expect(result.scannedEntryCount == 3)
        #expect(result.isComplete == false)
        #expect(result.incompleteReason == "Entry budget exceeded after 3 entries.")
    }

    @Test(.timeLimit(.minutes(1))) func cancelledTaskReturnsIncompleteResult() async throws {
        let fileManager = FileManager.default
        let root = try Self.makeTemporaryDirectory()
        defer { try? fileManager.removeItem(at: root) }
        try Data(repeating: 1, count: 64).write(to: root.appendingPathComponent("file.bin"))

        let scanner = LiveFileSizeScanner(fileManager: fileManager)
        let task = Task {
            scanner.size(of: root)
        }
        task.cancel()
        let result = await task.value

        #expect(result.isComplete == false)
        #expect(result.incompleteReason?.contains("cancelled") == true)
    }

    @Test(.timeLimit(.minutes(1))) func derivedDataFixtureWithSymlinkLoopStaysBounded() throws {
        let fileManager = FileManager.default
        let root = try Self.makeTemporaryDirectory()
        defer { try? fileManager.removeItem(at: root) }

        let derivedData = root.appendingPathComponent(
            "SecretApp-1234567890abcdef",
            isDirectory: true)
        let index = derivedData.appendingPathComponent("Index.noindex/DataStore", isDirectory: true)
        try fileManager.createDirectory(at: index, withIntermediateDirectories: true)
        for item in 0..<50 {
            try Data(repeating: UInt8(item % 255), count: 32)
                .write(to: index.appendingPathComponent("record-\(item).db"))
        }
        try fileManager.createSymbolicLink(
            at: index.appendingPathComponent("loop"),
            withDestinationURL: derivedData)

        let result = LiveFileSizeScanner(fileManager: fileManager).size(of: root)

        #expect(result.bytes >= 1_600)
        #expect(result.scannedEntryCount >= 50)
        #expect(result.isComplete)
        #expect(result.unreadablePaths.isEmpty)
    }

    @Test(.timeLimit(.minutes(1))) func unreadableDirectoryIsReportedWithoutFailingScan() throws {
        let fileManager = FileManager.default
        let root = try Self.makeTemporaryDirectory()
        let unreadable = root.appendingPathComponent("Unreadable", isDirectory: true)
        defer {
            try? fileManager.setAttributes([.posixPermissions: 0o700], ofItemAtPath: unreadable.path)
            try? fileManager.removeItem(at: root)
        }
        try fileManager.createDirectory(at: unreadable, withIntermediateDirectories: true)
        try fileManager.setAttributes([.posixPermissions: 0o000], ofItemAtPath: unreadable.path)

        let result = LiveFileSizeScanner(fileManager: fileManager).size(of: root)

        #expect(result.isComplete)
        #expect(result.bytes >= 0)
    }

    @Test(.timeLimit(.minutes(1))) func incompleteSizeResultIsCopiedToItemMetadata() async throws {
        let fileManager = FileManager.default
        let root = try Self.makeTemporaryDirectory()
        defer { try? fileManager.removeItem(at: root) }
        let result = FileSizeResult(
            bytes: 128,
            unreadablePaths: [],
            scannedEntryCount: 3,
            isComplete: false,
            incompleteReason: "Entry budget exceeded after 3 entries.")
        let now = Date()
        let context = DomainScanContext(
            fileManager: fileManager,
            fileSizeScanner: LiveFileSizeScanner(fileManager: fileManager),
            simctlDevices: [],
            codexSessions: [],
            processSnapshot: ProcessSnapshot(sampledAt: now, processes: []),
            attributionTracker: LiveAttributionTracker(),
            configuration: .standard,
            now: now)

        let item = await StorageItemFactory.makeItem(
            url: root,
            domain: .derivedData,
            kind: .derivedData,
            size: result,
            metadata: [:],
            isActive: false,
            explicitLastUsedAt: nil,
            context: context)

        #expect(item.metadata["scanComplete"] == "false")
        #expect(item.metadata["scannedEntryCount"] == "3")
        #expect(item.metadata["scanIncompleteReason"] == "Entry budget exceeded after 3 entries.")
    }

    private static func makeTemporaryDirectory() throws -> URL {
        let fileManager = FileManager.default
        let root = fileManager.temporaryDirectory.appendingPathComponent("DELTREE-file-size-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }
}
