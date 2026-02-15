import Foundation

enum VietnameseCalendarMetadata {
    private static let heavenlyStems = ["Giáp", "Ất", "Bính", "Đinh", "Mậu", "Kỷ", "Canh", "Tân", "Nhâm", "Quý"]
    private static let earthlyBranches = ["Tý", "Sửu", "Dần", "Mão", "Thìn", "Tỵ", "Ngọ", "Mùi", "Thân", "Dậu", "Tuất", "Hợi"]
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
        let jdn = JulianDay.fromGregorian(day: day, month: month, year: year)
        let stem = heavenlyStems[positiveMod(jdn + 9, 10)]
        let branch = earthlyBranches[positiveMod(jdn + 1, 12)]
        return "\(stem) \(branch)"
    }

    static func canChiHour(date: Date, day: Int, month: Int, year: Int, calendar: Calendar) -> String {
        let jdn = JulianDay.fromGregorian(day: day, month: month, year: year)
        let dayStemIndex = positiveMod(jdn + 9, 10)
        let hour = calendar.component(.hour, from: date)
        let hourBranchIndex = positiveMod((hour + 1) / 2, 12)
        let hourStemIndex = positiveMod(dayStemIndex * 2 + hourBranchIndex, 10)
        return "\(heavenlyStems[hourStemIndex]) \(earthlyBranches[hourBranchIndex])"
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

    private static func positiveMod(_ value: Int, _ modulo: Int) -> Int {
        let result = value % modulo
        return result >= 0 ? result : result + modulo
    }
}
