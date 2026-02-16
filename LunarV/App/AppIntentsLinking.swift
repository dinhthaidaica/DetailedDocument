//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import AppIntents
import SwiftUI

// MARK: - Intents

struct GetLunarDateIntent: AppIntent {
    static var title: LocalizedStringResource = "Lấy ngày âm lịch hiện tại"
    static var description = IntentDescription("Trả về thông tin ngày âm lịch hôm nay.")

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let now = Date()
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.day, .month, .year], from: now)
        
        let converter = VietnameseLunarCalendarConverter(timeZone: 7.0)
        let lunar = converter.solarToLunar(day: components.day!, month: components.month!, year: components.year!)
        
        let result = "\(lunar.day)/\(lunar.month)\(lunar.isLeapMonth ? " nhuận" : "")"
        return .result(value: result)
    }
}

struct GetCanChiIntent: AppIntent {
    static var title: LocalizedStringResource = "Lấy Can Chi hôm nay"
    static var description = IntentDescription("Trả về thông tin Can Chi của ngày hiện tại.")

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let now = Date()
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.day, .month, .year], from: now)
        
        let canChiDay = VietnameseCalendarMetadata.canChiDay(day: components.day!, month: components.month!, year: components.year!)
        let canChiYear = VietnameseCalendarMetadata.canChiYear(lunarYear: components.year!) 
        
        let result = "Ngày \(canChiDay), năm \(canChiYear)"
        return .result(value: result)
    }
}

struct CopyLunarDateIntent: AppIntent {
    static var title: LocalizedStringResource = "Sao chép ngày âm lịch"
    static var description = IntentDescription("Sao chép thông tin đầy đủ ngày âm lịch vào bộ nhớ tạm.")

    @MainActor
    func perform() async throws -> some IntentResult {
        let now = Date()
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.day, .month, .year], from: now)
        
        let converter = VietnameseLunarCalendarConverter(timeZone: 7.0)
        let lunar = converter.solarToLunar(day: components.day!, month: components.month!, year: components.year!)
        let canChiDay = VietnameseCalendarMetadata.canChiDay(day: components.day!, month: components.month!, year: components.year!)
        
        let text = "Hôm nay âm lịch là ngày \(lunar.day) tháng \(lunar.month) năm \(canChiDay)"
        
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
