//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import AppKit
import AppIntents
import SwiftUI

private enum IntentLunarContext {
    static let lunarService = VietnameseLunarDateService()

    static func currentSnapshot() -> VietnameseLunarSnapshot? {
        lunarService.snapshot(for: Date())
    }
}

// MARK: - Intents

struct GetLunarDateIntent: AppIntent {
    static var title: LocalizedStringResource = "Lấy ngày âm lịch hiện tại"
    static var description = IntentDescription("Trả về thông tin ngày âm lịch hôm nay.")

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        guard let snapshot = IntentLunarContext.currentSnapshot() else {
            return .result(value: "--/--")
        }

        let result = "\(snapshot.lunar.day)/\(snapshot.lunar.month)\(snapshot.lunar.isLeapMonth ? " nhuận" : "")"
        return .result(value: result)
    }
}

struct GetCanChiIntent: AppIntent {
    static var title: LocalizedStringResource = "Lấy Can Chi hôm nay"
    static var description = IntentDescription("Trả về thông tin Can Chi của ngày hiện tại.")

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        guard let snapshot = IntentLunarContext.currentSnapshot() else {
            return .result(value: "--")
        }

        let result = "Ngày \(snapshot.canChiDay), năm \(snapshot.canChiYear)"
        return .result(value: result)
    }
}

struct CopyLunarDateIntent: AppIntent {
    static var title: LocalizedStringResource = "Sao chép ngày âm lịch"
    static var description = IntentDescription("Sao chép thông tin đầy đủ ngày âm lịch vào bộ nhớ tạm.")

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let snapshot = IntentLunarContext.currentSnapshot() else {
            return .result(dialog: "Không thể lấy dữ liệu lịch âm ở thời điểm hiện tại.")
        }

        let text = "Hôm nay âm lịch là ngày \(snapshot.lunar.day) tháng \(snapshot.lunar.month) năm \(snapshot.canChiYear)"
        
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        
        return .result(dialog: "Đã sao chép: \(text)")
    }
}

// MARK: - Shortcuts Provider

struct LunarVShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetLunarDateIntent(),
            phrases: [
                "Ngày âm hôm nay là bao nhiêu trong \(.applicationName)",
                "Lấy ngày âm lịch \(.applicationName)",
                "Hôm nay là mấy tháng mấy âm \(.applicationName)"
            ],
            shortTitle: "Lấy ngày âm",
            systemImageName: "calendar"
        )
        
        AppShortcut(
            intent: GetCanChiIntent(),
            phrases: [
                "Hôm nay là ngày gì can chi \(.applicationName)",
                "Xem can chi hôm nay \(.applicationName)"
            ],
            shortTitle: "Xem Can Chi",
            systemImageName: "leaf.fill"
        )
        
        AppShortcut(
            intent: CopyLunarDateIntent(),
            phrases: [
                "Sao chép ngày âm \(.applicationName)",
                "Copy ngày âm lịch \(.applicationName)"
            ],
            shortTitle: "Sao chép ngày âm",
            systemImageName: "doc.on.doc"
        )
    }
}
