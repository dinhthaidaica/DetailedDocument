//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import XCTest
@testable import LunarV

final class LunarCalendarTests: XCTestCase {

    private let converter = VietnameseLunarCalendarConverter(timeZone: 7.0)
    private let vietnamTimeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh") ?? .current
    private lazy var service = VietnameseLunarDateService(
        timeZone: vietnamTimeZone,
        solarTimeZone: vietnamTimeZone
    )

    // MARK: - Solar to Lunar Conversion

    func testTetNguyenDan2025() {
        // 29/01/2025 (Dương) = Mùng 1 Tết Ất Tỵ (1/1 Âm)
        let lunar = converter.solarToLunar(day: 29, month: 1, year: 2025)
        XCTAssertEqual(lunar.day, 1)
        XCTAssertEqual(lunar.month, 1)
        XCTAssertEqual(lunar.year, 2025)
        XCTAssertFalse(lunar.isLeapMonth)
    }

    func testTetNguyenDan2026() {
        // 17/02/2026 (Dương) = Mùng 1 Tết Bính Ngọ (1/1 Âm)
        let lunar = converter.solarToLunar(day: 17, month: 2, year: 2026)
        XCTAssertEqual(lunar.day, 1)
        XCTAssertEqual(lunar.month, 1)
        XCTAssertEqual(lunar.year, 2026)
        XCTAssertFalse(lunar.isLeapMonth)
    }

    func testMidAutumn2025() {
        // 06/10/2025 (Dương) = 15/8 Âm lịch (Trung Thu)
        let lunar = converter.solarToLunar(day: 6, month: 10, year: 2025)
        XCTAssertEqual(lunar.day, 15)
        XCTAssertEqual(lunar.month, 8)
        XCTAssertEqual(lunar.year, 2025)
    }

    func testLeapMonth2025() {
        // Năm 2025 có tháng 6 nhuận
        // 25/07/2025 nằm trong tháng 6 nhuận
        let lunar = converter.solarToLunar(day: 25, month: 7, year: 2025)
        XCTAssertEqual(lunar.month, 6)
        XCTAssertTrue(lunar.isLeapMonth)
    }

    func testEndOfYear() {
        // 31/12/2025
        let lunar = converter.solarToLunar(day: 31, month: 12, year: 2025)
        XCTAssertEqual(lunar.month, 11)
        XCTAssertEqual(lunar.year, 2025)
    }

    func testStartOfYear() {
        // 01/01/2025
        let lunar = converter.solarToLunar(day: 1, month: 1, year: 2025)
        XCTAssertEqual(lunar.month, 12)
        XCTAssertEqual(lunar.year, 2024)
    }

    // MARK: - Lunar to Solar (Reverse Conversion)

    func testLunarToSolarTet() {
        let target = LunarDate(day: 1, month: 1, year: 2025, isLeapMonth: false)
        let solar = service.solarDate(from: target)
        XCTAssertNotNil(solar)
        XCTAssertEqual(solar?.day, 29)
        XCTAssertEqual(solar?.month, 1)
        XCTAssertEqual(solar?.year, 2025)
    }

    func testLunarToSolarRoundTrip() {
        // Chuyển đổi qua lại phải cho kết quả ban đầu
        let originalSolarDay = 15
        let originalSolarMonth = 6
        let originalSolarYear = 2025

        let lunar = converter.solarToLunar(day: originalSolarDay, month: originalSolarMonth, year: originalSolarYear)
        let solar = service.solarDate(from: lunar)

        XCTAssertNotNil(solar)
        XCTAssertEqual(solar?.day, originalSolarDay)
        XCTAssertEqual(solar?.month, originalSolarMonth)
        XCTAssertEqual(solar?.year, originalSolarYear)
    }

    // MARK: - Julian Day

    func testJulianDayKnownDate() {
        // J2000.0 epoch: 01/01/2000 12:00 TT = JD 2451545.0
        // JulianDay.fromGregorian cho ngày 01/01/2000 = 2451545
        let jd = JulianDay.fromGregorian(day: 1, month: 1, year: 2000)
        XCTAssertEqual(jd, 2451545)
    }

    func testJulianDaySequential() {
        // Hai ngày liên tiếp phải cách nhau 1
        let jd1 = JulianDay.fromGregorian(day: 15, month: 3, year: 2025)
        let jd2 = JulianDay.fromGregorian(day: 16, month: 3, year: 2025)
        XCTAssertEqual(jd2 - jd1, 1)
    }

    // MARK: - Can Chi

    func testCanChiYear2025() {
        // 2025 = Ất Tỵ
        let canChi = VietnameseCalendarMetadata.canChiYear(lunarYear: 2025)
        XCTAssertEqual(canChi, "Ất Tỵ")
    }

    func testCanChiYear2026() {
        // 2026 = Bính Ngọ
        let canChi = VietnameseCalendarMetadata.canChiYear(lunarYear: 2026)
        XCTAssertEqual(canChi, "Bính Ngọ")
    }

    func testZodiac2025() {
        let zodiac = VietnameseCalendarMetadata.zodiac(lunarYear: 2025)
        XCTAssertEqual(zodiac, "Tỵ")
    }

    func testZodiac2024() {
        let zodiac = VietnameseCalendarMetadata.zodiac(lunarYear: 2024)
        XCTAssertEqual(zodiac, "Thìn")
    }

    // MARK: - Lunar Phase

    func testLunarPhaseNewMoon() {
        let phase = LunarPhase.from(day: 1)
        XCTAssertEqual(phase.icon, "moonphase.new.moon")
        XCTAssertEqual(phase.name, "Trăng mới")
    }

    func testLunarPhaseFullMoon() {
        let phase = LunarPhase.from(day: 15)
        XCTAssertEqual(phase.icon, "moonphase.full.moon")
        XCTAssertEqual(phase.name, "Trăng tròn")
    }

    // MARK: - Holiday Provider

    func testSolarHolidays() {
        XCTAssertEqual(HolidayProvider.solarHoliday(day: 1, month: 1), "Tết Dương lịch")
        XCTAssertEqual(HolidayProvider.solarHoliday(day: 2, month: 9), "Quốc khánh")
        XCTAssertEqual(HolidayProvider.solarHoliday(day: 30, month: 4), "Giải phóng miền Nam")
        XCTAssertEqual(HolidayProvider.solarHoliday(day: 20, month: 11), "Ngày Nhà giáo Việt Nam")
        XCTAssertNil(HolidayProvider.solarHoliday(day: 15, month: 6))
    }

    func testLunarHolidays() {
        XCTAssertEqual(HolidayProvider.lunarHoliday(day: 1, month: 1), "Mùng 1 Tết")
        XCTAssertEqual(HolidayProvider.lunarHoliday(day: 15, month: 8), "Tết Trung Thu")
        XCTAssertEqual(HolidayProvider.lunarHoliday(day: 10, month: 3), "Giỗ tổ Hùng Vương")
        XCTAssertEqual(HolidayProvider.lunarHoliday(day: 3, month: 3), "Tết Hàn Thực")
        XCTAssertEqual(HolidayProvider.lunarHoliday(day: 5, month: 5), "Tết Đoan Ngọ")
        XCTAssertNil(HolidayProvider.lunarHoliday(day: 20, month: 6))
    }

    // MARK: - Service Snapshot

    func testSnapshotReturnsValidData() {
        let snapshot = service.snapshot(for: makeDate(year: 2026, month: 2, day: 18, hour: 9))
        XCTAssertNotNil(snapshot)
        XCTAssertGreaterThan(snapshot!.lunar.day, 0)
        XCTAssertGreaterThan(snapshot!.lunar.month, 0)
        XCTAssertGreaterThan(snapshot!.lunar.year, 2000)
        XCTAssertFalse(snapshot!.canChiDay.isEmpty)
        XCTAssertFalse(snapshot!.canChiYear.isEmpty)
        XCTAssertFalse(snapshot!.zodiac.isEmpty)
        XCTAssertFalse(snapshot!.solarTerm.isEmpty)
    }

    func testHourPeriodsAlways12() {
        let snapshot = service.snapshot(for: makeDate(year: 2026, month: 2, day: 18, hour: 21))
        XCTAssertNotNil(snapshot)
        XCTAssertEqual(snapshot!.hourPeriods.count, 12)
    }

    // MARK: - International Time Formatter

    func testUTCOffsetTextFormatting() {
        let referenceDate = makeDate(year: 2026, month: 2, day: 1, hour: 12)
        guard
            let hoChiMinh = TimeZone(identifier: "Asia/Ho_Chi_Minh"),
            let kolkata = TimeZone(identifier: "Asia/Kolkata")
        else {
            XCTFail("Unable to resolve expected time zones for UTC offset test")
            return
        }

        XCTAssertEqual(
            InternationalTimeFormatter.utcOffsetText(for: hoChiMinh, at: referenceDate),
            "UTC+07"
        )
        XCTAssertEqual(
            InternationalTimeFormatter.utcOffsetText(for: kolkata, at: referenceDate),
            "UTC+05:30"
        )
        XCTAssertEqual(
            InternationalTimeFormatter.utcOffsetText(for: "Invalid/Zone", at: referenceDate),
            "UTC?"
        )
    }

    func testRelativeDayTextMapping() {
        XCTAssertEqual(InternationalTimeFormatter.relativeDayText(for: 0), "Hôm nay")
        XCTAssertEqual(InternationalTimeFormatter.relativeDayText(for: 1), "Ngày mai")
        XCTAssertEqual(InternationalTimeFormatter.relativeDayText(for: -1), "Hôm qua")
        XCTAssertEqual(InternationalTimeFormatter.relativeDayText(for: 2), "+2 ngày")
        XCTAssertEqual(InternationalTimeFormatter.relativeDayText(for: -2), "-2 ngày")
    }

    func testRelativeDayOffsetAcrossTimeZones() {
        var localCalendar = Calendar(identifier: .gregorian)
        localCalendar.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh") ?? .current
        guard
            let referenceDate = localCalendar.date(
                from: DateComponents(year: 2026, month: 1, day: 1, hour: 0, minute: 30, second: 0)
            ),
            let losAngeles = TimeZone(identifier: "America/Los_Angeles"),
            let tokyo = TimeZone(identifier: "Asia/Tokyo")
        else {
            XCTFail("Unable to resolve reference date or expected time zones")
            return
        }

        XCTAssertEqual(
            InternationalTimeFormatter.relativeDayOffset(
                at: referenceDate,
                localCalendar: localCalendar,
                targetTimeZone: losAngeles
            ),
            -1
        )
        XCTAssertEqual(
            InternationalTimeFormatter.relativeDayOffset(
                at: referenceDate,
                localCalendar: localCalendar,
                targetTimeZone: tokyo
            ),
            0
        )
    }

    private func makeDate(year: Int, month: Int, day: Int, hour: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = vietnamTimeZone
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: 0, second: 0))
            ?? Date(timeIntervalSince1970: 0)
    }
}
