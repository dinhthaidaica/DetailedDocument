//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import Foundation

enum VietnameseCalendarMetadata {
    private static let heavenlyStems = ["Giáp", "Ất", "Bính", "Đinh", "Mậu", "Kỷ", "Canh", "Tân", "Nhâm", "Quý"]
    private static let earthlyBranches = ["Tý", "Sửu", "Dần", "Mão", "Thìn", "Tỵ", "Ngọ", "Mùi", "Thân", "Dậu", "Tuất", "Hợi"]
    private static let stemElements = ["Mộc", "Mộc", "Hỏa", "Hỏa", "Thổ", "Thổ", "Kim", "Kim", "Thủy", "Thủy"]
    private static let auspiciousHourPatterns = [
        "110100101100", // Tý, Ngọ
        "001101001011", // Sửu, Mùi
        "110011010010", // Dần, Thân
        "101100110100", // Mão, Dậu
        "001011001101", // Thìn, Tuất
        "010010110011", // Tỵ, Hợi
    ]
    private static let earthlyBranchTimeRanges = [
        "23:00-01:00", "01:00-03:00", "03:00-05:00", "05:00-07:00",
        "07:00-09:00", "09:00-11:00", "11:00-13:00", "13:00-15:00",
        "15:00-17:00", "17:00-19:00", "19:00-21:00", "21:00-23:00",
    ]
    private static let solarTerms = [
        "Lập xuân", "Vũ thủy", "Kinh trập", "Xuân phân", "Thanh minh", "Cốc vũ",
        "Lập hạ", "Tiểu mãn", "Mang chủng", "Hạ chí", "Tiểu thử", "Đại thử",
        "Lập thu", "Xử thử", "Bạch lộ", "Thu phân", "Hàn lộ", "Sương giáng",
        "Lập đông", "Tiểu tuyết", "Đại tuyết", "Đông chí", "Tiểu hàn", "Đại hàn",
    ]

    static func canChiYear(lunarYear: Int) -> String {
        let stem = heavenlyStems[positiveMod(lunarYear + 6, 10)]
        let branch = earthlyBranches[positiveMod(lunarYear + 8, 12)]
        return "\(stem) \(branch)"
    }

    static func canChiMonth(lunarMonth: Int, lunarYear: Int) -> String {
        let stem = heavenlyStems[positiveMod(lunarYear * 12 + lunarMonth + 3, 10)]
        let branch = earthlyBranches[positiveMod(lunarMonth + 1, 12)]
        return "\(stem) \(branch)"
    }

    static func canChiDay(day: Int, month: Int, year: Int) -> String {
        let stem = heavenlyStems[dayStemIndex(day: day, month: month, year: year)]
        let branch = earthlyBranches[dayBranchIndex(day: day, month: month, year: year)]
        return "\(stem) \(branch)"
    }

    static func canChiHour(date: Date, day: Int, month: Int, year: Int, calendar: Calendar) -> String {
        let dayStemIndex = dayStemIndex(day: day, month: month, year: year)
        let hour = calendar.component(.hour, from: date)
        let hourBranchIndex = positiveMod((hour + 1) / 2, 12)
        return hourCanChi(dayStemIndex: dayStemIndex, hourBranchIndex: hourBranchIndex)
    }

    static func dayElement(day: Int, month: Int, year: Int) -> String {
        stemElements[dayStemIndex(day: day, month: month, year: year)]
    }

    static func dayBranch(day: Int, month: Int, year: Int) -> String {
        earthlyBranches[dayBranchIndex(day: day, month: month, year: year)]
    }

    static func dayBranchOrdinal(day: Int, month: Int, year: Int) -> Int {
        dayBranchIndex(day: day, month: month, year: year)
    }

    static func lunarMonthBranch(lunarMonth: Int) -> String {
        earthlyBranches[lunarMonthBranchOrdinal(lunarMonth: lunarMonth)]
    }

    static func lunarMonthBranchOrdinal(lunarMonth: Int) -> Int {
        positiveMod(lunarMonth + 1, 12)
    }

    static func oppositeZodiac(day: Int, month: Int, year: Int) -> String {
        let branchIndex = dayBranchIndex(day: day, month: month, year: year)
        return earthlyBranches[positiveMod(branchIndex + 6, 12)]
    }

    static func tamHopGroup(day: Int, month: Int, year: Int) -> String {
        let branchIndex = dayBranchIndex(day: day, month: month, year: year)
        switch branchIndex {
        case 0, 4, 8:
            return "Thân - Tý - Thìn"
        case 2, 6, 10:
            return "Dần - Ngọ - Tuất"
        case 3, 7, 11:
            return "Hợi - Mão - Mùi"
        default:
            return "Tỵ - Dậu - Sửu"
        }
    }

    static func hourPeriods(day: Int, month: Int, year: Int) -> [VietnameseHourPeriod] {
        let branchIndex = dayBranchIndex(day: day, month: month, year: year)
        let stemIndex = dayStemIndex(day: day, month: month, year: year)
        let pattern = Array(auspiciousHourPatterns[positiveMod(branchIndex, 12) % 6])

        return earthlyBranches.indices.map { hourIndex in
            VietnameseHourPeriod(
                branchIndex: hourIndex,
                branch: earthlyBranches[hourIndex],
                canChi: hourCanChi(dayStemIndex: stemIndex, hourBranchIndex: hourIndex),
                timeRange: earthlyBranchTimeRanges[hourIndex],
                isAuspicious: pattern[hourIndex] == "1"
            )
        }
    }

    static func zodiac(lunarYear: Int) -> String {
        earthlyBranches[positiveMod(lunarYear + 8, 12)]
    }

    static func solarTerm(date: Date, timeZone: TimeZone) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let components = calendar.dateComponents([.day, .month, .year, .hour, .minute], from: date)
        guard
            let day = components.day,
            let month = components.month,
            let year = components.year
        else {
            return "--"
        }

        let jdn = Double(JulianDay.fromGregorian(day: day, month: month, year: year))
        let hour = Double(components.hour ?? 0)
        let minute = Double(components.minute ?? 0)
        let timeOffsetHours = Double(timeZone.secondsFromGMT(for: date)) / 3600.0
        let fractionalDay = (hour + minute / 60.0) / 24.0
        let utcJdn = jdn - 0.5 - timeOffsetHours / 24.0 + fractionalDay
        let longitude = sunLongitude(jdn: utcJdn)
        let longitudeDegrees = longitude * 180.0 / Double.pi
        let index = positiveMod(Int(floor((longitudeDegrees + 45.0) / 15.0)), 24)
        return solarTerms[index]
    }

    private static func sunLongitude(jdn: Double) -> Double {
        let t = (jdn - 2_451_545.0) / 36525
        let t2 = t * t
        let dr = Double.pi / 180
        let m = 357.52910 + 35999.05030 * t - 0.0001559 * t2 - 0.00000048 * t * t2
        let l0 = 280.46645 + 36000.76983 * t + 0.0003032 * t2

        var dl = (1.914600 - 0.004817 * t - 0.000014 * t2) * sin(dr * m)
        dl += (0.019993 - 0.000101 * t) * sin(2 * dr * m) + 0.000290 * sin(3 * dr * m)

        var longitude = l0 + dl
        longitude *= dr
        longitude -= Double.pi * 2 * floor(longitude / (Double.pi * 2))
        return longitude
    }

    private static func dayStemIndex(day: Int, month: Int, year: Int) -> Int {
        let jdn = JulianDay.fromGregorian(day: day, month: month, year: year)
        return positiveMod(jdn + 9, 10)
    }

    private static func dayBranchIndex(day: Int, month: Int, year: Int) -> Int {
        let jdn = JulianDay.fromGregorian(day: day, month: month, year: year)
        return positiveMod(jdn + 1, 12)
    }

    private static func hourCanChi(dayStemIndex: Int, hourBranchIndex: Int) -> String {
        let hourStemIndex = positiveMod(dayStemIndex * 2 + hourBranchIndex, 10)
        return "\(heavenlyStems[hourStemIndex]) \(earthlyBranches[hourBranchIndex])"
    }

    private static func positiveMod(_ value: Int, _ modulo: Int) -> Int {
        let result = value % modulo
        return result >= 0 ? result : result + modulo
    }
}
