import Foundation

enum StorageFormatters {
    static func byteCount(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    static func ageString(from date: Date?, now: Date = Date()) -> String {
        guard let date else {
            return "Never"
        }

        let seconds = max(0, Int(now.timeIntervalSince(date)))
        if seconds < 60 {
            return "Now"
        }
        if seconds < 3_600 {
            return "\(seconds / 60)m ago"
        }
        if seconds < 86_400 {
            return "\(seconds / 3_600)h ago"
        }
        return "\(seconds / 86_400)d ago"
    }

    static func dateTime(_ date: Date?) -> String {
        guard let date else {
            return "Unknown"
        }
        return date.formatted(date: .abbreviated, time: .shortened)
    }
}
