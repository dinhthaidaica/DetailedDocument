//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import Foundation

@MainActor
enum SettingsInternationalTimeZoneService {
    private static let internationalClockLocale = Locale(identifier: "vi_VN")
    private static var internationalClockTimeFormatterByTimeZoneID: [String: DateFormatter] = [:]
    private static var cachedUTCOffsetTextByTimeZoneID: [String: String] = [:]
    private static var utcOffsetCacheHourBucket: Int?
    private static var normalizedTimeZoneSearchValueByID: [String: String] = [:]
    private static var timeZoneSearchIndexHourBucket: Int?

    static func utcOffsetText(for timeZoneIdentifier: String, at date: Date = Date()) -> String {
        let currentHourBucket = hourBucket(for: date)
        if utcOffsetCacheHourBucket != currentHourBucket {
            utcOffsetCacheHourBucket = currentHourBucket
            cachedUTCOffsetTextByTimeZoneID.removeAll(keepingCapacity: true)
        }

        if let cached = cachedUTCOffsetTextByTimeZoneID[timeZoneIdentifier] {
            return cached
        }

        let computed = InternationalTimeFormatter.utcOffsetText(for: timeZoneIdentifier, at: date)
        cachedUTCOffsetTextByTimeZoneID[timeZoneIdentifier] = computed
        return computed
    }

    static func currentTimeText(for timeZoneIdentifier: String, at date: Date = Date()) -> String {
        guard let timeZone = TimeZone(identifier: timeZoneIdentifier) else {
            return "--:--"
        }

        return internationalClockTimeFormatter(for: timeZone).string(from: date)
    }

    static func relativeDayText(for timeZoneIdentifier: String, at date: Date = Date()) -> String {
        guard let timeZone = TimeZone(identifier: timeZoneIdentifier) else {
            return ""
        }

        return InternationalTimeFormatter.relativeDayText(
            at: date,
            targetTimeZone: timeZone
        )
    }

    static func normalizedSearchValue(
        for timeZoneIdentifier: String,
        at date: Date,
        presets: [InternationalTimeZonePreset],
        normalize: (String) -> String
    ) -> String {
        rebuildTimeZoneSearchIndexIfNeeded(
            at: date,
            presets: presets,
            normalize: normalize
        )
        return normalizedTimeZoneSearchValueByID[timeZoneIdentifier] ?? ""
    }

    private static func hourBucket(for date: Date) -> Int {
        Int(date.timeIntervalSince1970 / 3600)
    }

    private static func rebuildTimeZoneSearchIndexIfNeeded(
        at date: Date,
        presets: [InternationalTimeZonePreset],
        normalize: (String) -> String
    ) {
        let currentHourBucket = hourBucket(for: date)
        guard timeZoneSearchIndexHourBucket != currentHourBucket else {
            return
        }

        timeZoneSearchIndexHourBucket = currentHourBucket
        normalizedTimeZoneSearchValueByID = Dictionary(
            uniqueKeysWithValues: presets.map { preset in
                let offsetText = utcOffsetText(for: preset.id, at: date)
                let normalizedCombinedValues = [preset.city, preset.country, preset.id, offsetText]
                    .map(normalize)
                    .joined(separator: " ")
                return (preset.id, normalizedCombinedValues)
            }
        )
    }

    private static func internationalClockTimeFormatter(for timeZone: TimeZone) -> DateFormatter {
        if let formatter = internationalClockTimeFormatterByTimeZoneID[timeZone.identifier] {
            return formatter
        }

        let formatter = DateFormatter()
        formatter.locale = internationalClockLocale
        formatter.timeZone = timeZone
        formatter.dateFormat = "HH:mm"
        internationalClockTimeFormatterByTimeZoneID[timeZone.identifier] = formatter
        return formatter
    }
}
