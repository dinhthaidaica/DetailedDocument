//
//  LunarV - Lich Am Viet Nam
//  Phat trien boi Pham Hung Tien
//
import Foundation
import WidgetKit

struct LunarTimelineProvider: TimelineProvider {
    private static let lunarService = VietnameseLunarDateService()
    private static let realTimeWindowMinutes = 180

    func placeholder(in context: Context) -> LunarEntry {
        LunarEntry(date: Date(), info: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (LunarEntry) -> Void) {
        completion(makeEntry(for: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LunarEntry>) -> Void) {
        let now = Date()
        let minuteAnchor = Self.lunarService.calendar.dateInterval(of: .minute, for: now)?.start ?? now
        let dates = timelineDates(from: minuteAnchor, minutesAhead: Self.realTimeWindowMinutes)
        let entries = dates.map(makeEntry(for:))
        let reloadDate = Self.lunarService.calendar.date(byAdding: .minute, value: Self.realTimeWindowMinutes + 1, to: minuteAnchor)
            ?? now.addingTimeInterval(TimeInterval((Self.realTimeWindowMinutes + 1) * 60))
        completion(Timeline(entries: entries, policy: .after(reloadDate)))
    }

    private func timelineDates(from anchor: Date, minutesAhead: Int) -> [Date] {
        var dates: [Date] = []
        dates.reserveCapacity(minutesAhead + 1)

        for offset in 0 ... minutesAhead {
            if let date = Self.lunarService.calendar.date(byAdding: .minute, value: offset, to: anchor) {
                dates.append(date)
            }
        }
        return dates
    }

    private func makeEntry(for date: Date) -> LunarEntry {
        LunarEntry(date: date, info: info(for: date) ?? .placeholder)
    }

    private func info(for date: Date) -> WidgetLunarInfo? {
        guard let snapshot = Self.lunarService.snapshot(for: date) else {
            return nil
        }

        return WidgetLunarInfo(
            weekday: Self.lunarService.weekdayName(from: snapshot.solar.weekday),
            solarDate: snapshot.solar.formattedDate,
            lunarDay: "\(snapshot.lunar.day)",
            lunarMonthYear: "Tháng \(snapshot.lunar.month) năm \(snapshot.canChiYear)",
            canChiDay: snapshot.canChiDay,
            solarTerm: snapshot.solarTerm,
            canChiYear: snapshot.canChiYear,
            phaseIcon: LunarPhase.from(day: snapshot.lunar.day).icon,
            zodiac: snapshot.zodiac
        )
    }
}
