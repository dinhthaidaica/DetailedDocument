//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import Foundation
import os

enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.lunarv"

    static let calendar = Logger(subsystem: subsystem, category: "calendar")
    static let ui = Logger(subsystem: subsystem, category: "ui")
    static let notification = Logger(subsystem: subsystem, category: "notification")
    static let system = Logger(subsystem: subsystem, category: "system")
}
