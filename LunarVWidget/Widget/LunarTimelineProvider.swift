//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import Foundation
import WidgetKit

struct LunarTimelineProvider: TimelineProvider {
    // Widget shows day-level info (no hours/minutes), so hourly steps suffice.
    private static let realTimeWindowMinutes = 360
    private static let timelineStepMinutes = 60

    func placeholder(in context: Context) -> LunarEntry {
        LunarEntry(date: Date(), info: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (LunarEntry) -> Void) {
        if context.isPreview {
            completion(LunarEntry(date: Date(), info: .placeholder))
            return
        }

        let service = VietnameseLunarDateService()
        completion(makeEntry(for: Date(), service: service))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LunarEntry>) -> Void) {
        if context.isPreview {
            let previewEntry = LunarEntry(date: Date(), info: .placeholder)
            completion(Timeline(entries: [previewEntry], policy: .atEnd))
            return
        }

        let service = VietnameseLunarDateService()
        let now = Date()
        let minuteAnchor = service.calendar.dateInterval(of: .minute, for: now)?.start ?? now
        let dates = timelineDates(
            from: minuteAnchor,
            minutesAhead: Self.realTimeWindowMinutes,
            stepMinutes: Self.timelineStepMinutes,
            calendar: service.calendar
        )
        let entries = dates.map { makeEntry(for: $0, service: service) }
        let reloadDate = service.calendar.date(byAdding: .minute, value: Self.realTimeWindowMinutes + 1, to: minuteAnchor)
            ?? now.addingTimeInterval(TimeInterval((Self.realTimeWindowMinutes + 1) * 60))
        completion(Timeline(entries: entries, policy: .after(reloadDate)))
    }

    private func timelineDates(
        from anchor: Date,
        minutesAhead: Int,
        stepMinutes: Int,
        calendar: Calendar
    ) -> [Date] {
        let safeStep = max(stepMinutes, 1)
        var dates: [Date] = []
        dates.reserveCapacity(minutesAhead / safeStep + 1)

        for offset in stride(from: 0, through: minutesAhead, by: safeStep) {
            if let date = calendar.date(byAdding: .minute, value: offset, to: anchor) {
                dates.append(date)
            }
        }
        return dates
    }

    private func makeEntry(for date: Date, service: VietnameseLunarDateService) -> LunarEntry {
        LunarEntry(date: date, info: info(for: date, service: service) ?? .placeholder)
    }

    private func info(for date: Date, service: VietnameseLunarDateService) -> WidgetLunarInfo? {
        guard let snapshot = service.snapshot(for: date) else {
            return nil
        }

        return WidgetLunarInfo(
            weekday: service.weekdayName(from: snapshot.solar.weekday),
            solarDate: snapshot.solar.formattedDate,
            lunarDay: "\(snapshot.lunar.day)",
            lunarMonthText: "Tháng \(snapshot.lunar.month)",
            lunarMonthYear: "Tháng \(snapshot.lunar.month) năm \(snapshot.canChiYear)",
            canChiDay: snapshot.canChiDay,
            solarTerm: snapshot.solarTerm,
            canChiYear: snapshot.canChiYear,
            phaseIcon: LunarPhase.from(day: snapshot.lunar.day).icon,
            zodiac: snapshot.zodiac
        )
    }
}
