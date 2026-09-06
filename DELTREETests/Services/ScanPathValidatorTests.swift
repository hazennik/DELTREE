import Foundation
import Testing
@testable import DELTREE

struct ScanPathValidatorTests {
    @Test func rejectsRelativeAndBroadSystemPaths() {
        #expect(throws: ScanPathValidationError.relativePath) {
            try ScanPathValidator.validatedPath("relative/path")
        }
        #expect(throws: ScanPathValidationError.protectedRoot("/")) {
            try ScanPathValidator.validatedPath("/")
        }
        #expect(throws: ScanPathValidationError.protectedRoot("/System")) {
            try ScanPathValidator.validatedPath("/System")
        }
    }

    @Test func rejectsHomeDirectoryAndOverlappingRoots() {
        let home = URL(fileURLWithPath: "/Users/fixture", isDirectory: true)
        #expect(throws: ScanPathValidationError.protectedRoot("/Users/fixture")) {
            try ScanPathValidator.validatedPath("/Users/fixture", homeDirectory: home)
        }
        #expect(throws: ScanPathValidationError.overlappingPath("/tmp/project/nested")) {
            try ScanPathValidator.validatedPath(
                "/tmp/project/nested",
                existingPaths: ["/tmp/project"],
                homeDirectory: home)
        }
    }

    @Test func rootExclusionCoversEveryPathDefensively() {
        var configuration = StorageScanConfiguration.standard
        configuration.excludedPaths = ["/"]

        #expect(configuration.isExcluded("/Users/fixture/project"))
    }
}
