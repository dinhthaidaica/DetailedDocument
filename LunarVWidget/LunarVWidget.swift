//
//  LunarVWidget.swift
//  LunarVWidget
//
//  Phát triển bởi Phạm Hùng Tiến
//

import Foundation
import SwiftUI
import WidgetKit

private struct WidgetLunarInfo {
    let weekday: String
    let solarDate: String
    let lunarDay: String
    let lunarMonthYear: String
    let canChiDay: String
    let solarTerm: String
    let canChiYear: String
    let phaseIcon: String
    let zodiac: String

    static let placeholder = WidgetLunarInfo(
        weekday: "THỨ HAI",
        solarDate: "16/02/2026",
        lunarDay: "29",
        lunarMonthYear: "Tháng 12 năm Ất Tỵ",
        canChiDay: "Canh Thân",
        solarTerm: "Lập Xuân",
        canChiYear: "Ất Tỵ",
        phaseIcon: "moonphase.waxing.crescent",
        zodiac: "Rắn"
    )

    var lunarMonthText: String {
        lunarMonthYear.components(separatedBy: " năm").first ?? lunarMonthYear
    }

    var accessibilitySummary: String {
        "Ngày âm \(lunarDay), \(lunarMonthYear), \(canChiDay), dương lịch \(solarDate)"
    }
}

private struct LunarEntry: TimelineEntry {
    let date: Date
    let info: WidgetLunarInfo
}

private struct LunarTimelineProvider: TimelineProvider {
    private static let vietnamTimeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")
        ?? TimeZone(secondsFromGMT: 7 * 3600)
        ?? .current
    private static let converter = VietnameseLunarCalendarConverter(timeZone: 7.0)
    private static let weekdayNames = ["Chủ Nhật", "Thứ Hai", "Thứ Ba", "Thứ Tư", "Thứ Năm", "Thứ Sáu", "Thứ Bảy"]
    private static let realTimeWindowMinutes = 180

    private static var vietnamCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = vietnamTimeZone
        calendar.locale = Locale(identifier: "vi_VN")
        return calendar
    }

    func placeholder(in context: Context) -> LunarEntry {
        LunarEntry(date: Date(), info: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (LunarEntry) -> Void) {
        completion(makeEntry(for: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LunarEntry>) -> Void) {
        let now = Date()
        let minuteAnchor = Self.vietnamCalendar.dateInterval(of: .minute, for: now)?.start ?? now
        let dates = timelineDates(from: minuteAnchor, minutesAhead: Self.realTimeWindowMinutes)
        let entries = dates.map(makeEntry(for:))
        let reloadDate = Self.vietnamCalendar.date(byAdding: .minute, value: Self.realTimeWindowMinutes + 1, to: minuteAnchor)
            ?? now.addingTimeInterval(TimeInterval((Self.realTimeWindowMinutes + 1) * 60))
        completion(Timeline(entries: entries, policy: .after(reloadDate)))
    }

    private func timelineDates(from anchor: Date, minutesAhead: Int) -> [Date] {
        var dates: [Date] = []
        dates.reserveCapacity(minutesAhead + 1)

        for offset in 0 ... minutesAhead {
            if let date = Self.vietnamCalendar.date(byAdding: .minute, value: offset, to: anchor) {
                dates.append(date)
            }
        }
        return dates
    }

    private func makeEntry(for date: Date) -> LunarEntry {
        LunarEntry(date: date, info: info(for: date) ?? .placeholder)
    }

    private func info(for date: Date) -> WidgetLunarInfo? {
        let calendar = Self.vietnamCalendar
        let components = calendar.dateComponents([.day, .month, .year, .weekday], from: date)
        guard
            let day = components.day,
            let month = components.month,
            let year = components.year
        else {
            return nil
        }

        let lunar = Self.converter.solarToLunar(day: day, month: month, year: year)
        let canChiDay = VietnameseCalendarMetadata.canChiDay(day: day, month: month, year: year)
        let canChiYear = VietnameseCalendarMetadata.canChiYear(lunarYear: lunar.year)
        let zodiac = VietnameseCalendarMetadata.zodiac(lunarYear: lunar.year)
        let solarTerm = VietnameseCalendarMetadata.solarTerm(date: date, timeZone: Self.vietnamTimeZone)

        return WidgetLunarInfo(
            weekday: weekdayName(from: components.weekday),
            solarDate: String(format: "%02d/%02d/%04d", day, month, year),
            lunarDay: "\(lunar.day)",
            lunarMonthYear: "Tháng \(lunar.month) năm \(canChiYear)",
            canChiDay: canChiDay,
            solarTerm: solarTerm,
            canChiYear: canChiYear,
            phaseIcon: lunarPhaseIcon(lunarDay: lunar.day),
            zodiac: zodiac
        )
    }

    private func weekdayName(from weekday: Int?) -> String {
        guard let weekday, (1 ... Self.weekdayNames.count).contains(weekday) else {
            return Self.weekdayNames[0]
        }
        return Self.weekdayNames[weekday - 1]
    }

    private func lunarPhaseIcon(lunarDay: Int) -> String {
        switch lunarDay {
        case 1: return "moonphase.new.moon"
        case 2 ... 7: return "moonphase.waxing.crescent"
        case 8: return "moonphase.first.quarter"
        case 9 ... 14: return "moonphase.waxing.gibbous"
        case 15: return "moonphase.full.moon"
        case 16 ... 22: return "moonphase.waning.gibbous"
        case 23: return "moonphase.last.quarter"
        default: return "moonphase.waning.crescent"
        }
    }
}

private struct LunarWidgetEntryView: View {
    var entry: LunarTimelineProvider.Entry

    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetRenderingMode) private var renderingMode

    private var usesTintedStyle: Bool {
        switch renderingMode {
        case .fullColor:
            return false
        default:
            return true
        }
    }

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                smallWidget
            case .systemMedium:
                mediumWidget
            default:
                smallWidget
            }
        }
        .containerBackground(for: .widget) {
            widgetBackground
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(entry.info.accessibilitySummary)
    }

    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(entry.info.weekday.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(secondaryLabelColor)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Image(systemName: entry.info.phaseIcon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(accentColor)
            }

            Spacer(minLength: 0)

            Text(entry.info.lunarDay)
                .font(.system(size: 46, weight: .black, design: .rounded))
                .foregroundStyle(.primary)
                .monospacedDigit()
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Text(entry.info.lunarMonthText)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(secondaryLabelColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Label(entry.info.zodiac, systemImage: "pawprint.fill")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(secondaryLabelColor.opacity(0.9))
                .lineLimit(1)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var mediumWidget: some View {
        HStack(spacing: 14) {
            smallWidget
                .frame(width: 132)
                .overlay(alignment: .trailing) {
                    Rectangle()
                        .fill(.primary.opacity(0.08))
                        .frame(width: 1)
                }

            VStack(alignment: .leading, spacing: 9) {
                infoRow(symbol: "calendar", title: "Dương lịch", value: entry.info.solarDate)
                infoRow(symbol: "leaf.fill", title: "Can chi ngày", value: entry.info.canChiDay)
                infoRow(symbol: "sun.max.fill", title: "Tiết khí", value: entry.info.solarTerm)
                infoRow(symbol: "sparkles", title: "Năm", value: "\(entry.info.canChiYear) • \(entry.info.zodiac)")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.trailing, 14)
            .padding(.vertical, 12)
        }
    }

    private func infoRow(symbol: String, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Label(title, systemImage: symbol)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(secondaryLabelColor)
                .lineLimit(1)
            Text(value)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    @ViewBuilder
    private var widgetBackground: some View {
        if usesTintedStyle {
            Color.clear
        } else {
            LinearGradient(
                colors: [
                    Color.cyan.opacity(0.24),
                    Color.blue.opacity(0.12),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var accentColor: Color {
        usesTintedStyle ? .primary : .blue
    }

    private var secondaryLabelColor: Color {
        .secondary
    }
}

struct LunarVWidget: Widget {
    let kind: String = "LunarVWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LunarTimelineProvider()) { entry in
            LunarWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Lịch Âm LunarV")
        .description("Xem nhanh ngày âm lịch, can chi và tiết khí.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
