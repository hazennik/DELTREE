import Foundation

enum DirectoryScanMode: Sendable {
    case topLevelChildren
    case matchingPackages(extensionName: String)
    case wholeRoots
}
