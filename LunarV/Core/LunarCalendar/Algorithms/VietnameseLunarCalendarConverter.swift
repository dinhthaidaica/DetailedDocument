//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import Foundation

/// Protocol chung cho bất kỳ bộ chuyển đổi Dương → Âm lịch nào.
/// Cho phép inject bộ chuyển đổi khác (ví dụ mock) khi viết unit test.
protocol LunarDateConverting {
    func solarToLunar(day: Int, month: Int, year: Int) -> LunarDate
}

/// Bộ chuyển đổi Dương lịch → Âm lịch theo chuẩn **Việt Nam (UTC+7)**.
///
/// https://www.xemamlich.uhm.vn/calrules.html
///
/// ## Nguyên lý hoạt động
/// Âm lịch Việt Nam là **âm-dương lịch (lunisolar calendar)**:
/// - Mỗi tháng bắt đầu từ ngày **Sóc** (New Moon – trăng mới).
/// - Năm âm lịch căn chỉnh với năm mặt trời bằng cơ chế **tháng nhuận** (intercalary month).
/// - Múi giờ UTC+7 ảnh hưởng trực tiếp đến thời điểm Sóc, do đó khác với lịch Trung Quốc (UTC+8).
///
/// ## Thuật toán (HO NGOC DUC, dựa trên Jean Meeus)
/// 1. Tính JDN của ngày dương lịch đầu vào.
/// 2. Tính số k – chỉ số chu kỳ trăng gần nhất (tính từ mốc J2000).
/// 3. Tìm ngày Sóc của tháng âm lịch chứa ngày đó.
/// 4. Tìm ngày Đông chí (tháng 11 âm) của năm hiện tại và năm sau.
/// 5. Nếu năm có > 365 ngày giữa hai tháng 11 → có tháng nhuận; tìm vị trí tháng nhuận.
/// 6. Tính tháng âm lịch và năm âm lịch cuối cùng.
///
/// **Ví dụ:**
/// ```swift
/// let converter = VietnameseLunarCalendarConverter()
/// let lunar = converter.solarToLunar(day: 20, month: 2, year: 2026)
/// // → LunarDate(day: 3, month: 2, year: 2026, isLeapMonth: false)
/// // Tức là: 3 tháng 2 năm Bính Ngọ
/// ```
struct VietnameseLunarCalendarConverter: LunarDateConverting {
    /// Múi giờ dưới dạng offset giờ (mặc định 7.0 = UTC+7 – Việt Nam)
    private let timeZone: Double

    init(timeZone: Double = 7.0) {
        self.timeZone = timeZone
    }

    func solarToLunar(day: Int, month: Int, year: Int) -> LunarDate {
        Self.solarToLunar(day: day, month: month, year: year, timeZone: timeZone)
    }

    // MARK: - Core conversion

    private static func solarToLunar(day: Int, month: Int, year: Int, timeZone: Double) -> LunarDate {
        // Bước 1: Chuyển ngày dương sang JDN
        let dayNumber = JulianDay.fromGregorian(day: day, month: month, year: year)

        // Bước 2: Tính chỉ số k – số chu kỳ trăng kể từ mốc 1/1/1900 theo JDN 2_415_021.076998695
        // Một chu kỳ trăng = 29.530588853 ngày (synodic month)
        let k = Int(floor((Double(dayNumber) - 2_415_021.076998695) / 29.530588853))

        // Bước 3: Tìm ngày Sóc của tháng âm lịch chứa `dayNumber`
        // Thử k+1 trước (Sóc tiếp theo), nếu vẫn sau dayNumber thì lùi về k
        var monthStart = getNewMoonDay(k: k + 1, timeZone: timeZone)
        if monthStart > dayNumber {
            monthStart = getNewMoonDay(k: k, timeZone: timeZone)
        }

        // Bước 4: Tìm ngày Sóc của tháng 11 âm lịch (tháng chứa Đông chí)
        // a11 = Sóc tháng 11 của năm hiện tại hoặc năm trước
        // b11 = Sóc tháng 11 của năm kế tiếp (dùng để kiểm tra năm nhuận)
        var a11 = getLunarMonth11(year: year, timeZone: timeZone)
        var b11 = a11
        var lunarYear: Int

        if a11 >= monthStart {
            // Sóc tháng 11 năm `year` ≥ ngày đầu tháng → ngày đang thuộc năm âm lịch `year`
            // Phải lùi a11 về năm trước để tính offset từ đầu năm âm
            lunarYear = year
            a11 = getLunarMonth11(year: year - 1, timeZone: timeZone)
        } else {
            // Ngày đang thuộc năm âm lịch `year + 1`
            lunarYear = year + 1
            b11 = getLunarMonth11(year: year + 1, timeZone: timeZone)
        }

        // Bước 5: Tính ngày âm trong tháng
        let lunarDay = dayNumber - monthStart + 1

        // `diff` = số tháng kể từ tháng 11 âm (a11) tính đến tháng hiện tại
        let diff = Int(floor(Double(monthStart - a11) / 29.0))
        var lunarLeap = false
        // Tháng âm lịch thô = 11 + diff (vì đây là offset từ tháng 11)
        var lunarMonth = diff + 11

        // Bước 6: Kiểm tra + xử lý năm nhuận
        // Nếu khoảng cách giữa 2 tháng 11 liên tiếp > 365 ngày → năm đó có 13 tháng (nhuận)
        if b11 - a11 > 365 {
            let leapMonthDiff = getLeapMonthOffset(a11: a11, timeZone: timeZone)
            if diff >= leapMonthDiff {
                // Các tháng sau điểm nhuận phải lùi index 1 bậc
                lunarMonth = diff + 10
                if diff == leapMonthDiff {
                    // Chính tháng này là tháng nhuận
                    lunarLeap = true
                }
            }
        }

        // Chuẩn hóa tháng: nếu > 12 thì quay về đầu năm sau
        if lunarMonth > 12 {
            lunarMonth -= 12
        }
        // Nếu tháng lớn (>=11) và vẫn gần đầu năm (diff < 4) → năm âm thực sự là năm trước
        if lunarMonth >= 11 && diff < 4 {
            lunarYear -= 1
        }

        return LunarDate(day: lunarDay, month: lunarMonth, year: lunarYear, isLeapMonth: lunarLeap)
    }

    // MARK: - Helper: Ngày Sóc (New Moon)

    /// Trả về JDN (số nguyên) của ngày Sóc thứ k, điều chỉnh theo múi giờ.
    ///
    /// - Parameters:
    ///   - k: Chỉ số chu kỳ trăng (k=0 ≈ 1/1/1900)
    ///   - timeZone: Offset múi giờ (7.0 = UTC+7)
    private static func getNewMoonDay(k: Int, timeZone: Double) -> Int {
        let jd = newMoon(k: k)  // JD thực của Sóc (UTC)
        // +0.5 để chuyển từ 12:00 UTC → 0:00 UTC, cộng offset múi giờ
        return Int(floor(jd + 0.5 + timeZone / 24.0))
    }

    /// Trả về **phân vùng kinh độ mặt trời** (0–11) tại ngày `dayNumber`, múi giờ UTC+offset.
    ///
    /// Mỗi phân vùng = 30° kinh độ (360°/12 phân vùng = 12 tháng mặt trời).
    /// Phân vùng 9 = 270°–300° tương ứng với **Đông chí** (Winter Solstice).
    private static func getSunLongitude(dayNumber: Int, timeZone: Double) -> Int {
        let longitude = sunLongitude(jdn: Double(dayNumber) - 0.5 - timeZone / 24.0)
        // Chia 360° thành 12 phần 30°, mỗi phần = π/6 radian
        return Int(floor(longitude / Double.pi * 6.0))
    }

    /// Tìm JDN của ngày Sóc **tháng 11 âm lịch** của năm `year`.
    ///
    /// Tháng 11 âm lịch là tháng chứa ngày **Đông chí** (Sun Longitude ≈ 270° = phân vùng 9).
    /// Đây là "neo" để xác định năm âm lịch, tương tự cách lịch Trung Hoa dùng.
    private static func getLunarMonth11(year: Int, timeZone: Double) -> Int {
        // Lấy JDN của ngày 31/12/year làm điểm bắt đầu tìm kiếm
        let off = JulianDay.fromGregorian(day: 31, month: 12, year: year) - 2_415_021
        let k = Int(floor(Double(off) / 29.530588853))
        var month11 = getNewMoonDay(k: k, timeZone: timeZone)
        let sunLongitude = getSunLongitude(dayNumber: month11, timeZone: timeZone)
        // Nếu phân vùng >= 9 (≥ 270°) thì Đông chí chưa xảy ra → lùi 1 tháng
        if sunLongitude >= 9 {
            month11 = getNewMoonDay(k: k - 1, timeZone: timeZone)
        }
        return month11
    }

    /// Tìm **offset của tháng nhuận** trong năm âm lịch (tính từ tháng 11 âm = a11).
    ///
    /// Tháng nhuận là tháng mà **không có Trung khí** (major solar term) nằm trong đó.
    /// Thuật toán: duyệt qua từng tháng kể từ a11, tìm tháng đầu tiên mà kinh độ mặt trời
    /// sang tháng đó không thay đổi so với tháng trước (tức cùng phân vùng kinh độ 30°).
    ///
    /// **Ví dụ:** Năm 2023 có tháng nhuận 2 → `leapMonthDiff = 3` (đếm từ tháng 11 âm 2022)
    private static func getLeapMonthOffset(a11: Int, timeZone: Double) -> Int {
        let k = Int(floor((Double(a11) - 2_415_021.076998695) / 29.530588853 + 0.5))
        var lastArc = 0
        var i = 1
        // Kinh độ mặt trời của tháng tiếp theo
        var arc = getSunLongitude(dayNumber: getNewMoonDay(k: k + i, timeZone: timeZone), timeZone: timeZone)

        // Lặp cho đến khi tìm thấy tháng có cùng phân vùng kinh độ với tháng trước (= nhuận)
        // Tối đa 14 tháng để tránh vòng lặp vô hạn
        repeat {
            lastArc = arc
            i += 1
            arc = getSunLongitude(dayNumber: getNewMoonDay(k: k + i, timeZone: timeZone), timeZone: timeZone)
        } while arc != lastArc && i < 14

        return i - 1
    }

    // MARK: - Astronomical: Ngày Sóc chính xác (Jean Meeus Chapter 49)

    /// Tính **thời điểm Sóc (New Moon) thứ k** chính xác theo thiên văn học.
    ///
    /// Công thức của Jean Meeus ("Astronomical Algorithms", chương 49) với độ chính xác < 3 phút.
    /// Áp dụng chuỗi Taylor khai triển với biến thời gian T (thế kỷ Julian).
    ///
    /// - Parameter k: Chỉ số trăng (k=0 = Sóc 1/1/1900; k=1 = Sóc tháng sau; v.v.)
    /// - Returns: Julian Day Number dạng thực của khoảnh khắc Sóc (UTC)
    private static func newMoon(k: Int) -> Double {
        // T = số thế kỷ Julian (100 năm) kể từ J1900 (dùng 1236.85 = số Sóc/thế kỷ)
        let t = Double(k) / 1236.85
        let t2 = t * t
        let t3 = t2 * t
        let dr = Double.pi / 180

        // JD cơ bản của Sóc (Mean New Moon) + hiệu chỉnh nhỏ từ Mặt Trăng
        var jd1 = 2_415_020.75933 + 29.53058868 * Double(k) + 0.0001178 * t2 - 0.000000155 * t3
        jd1 += 0.00033 * sin((166.56 + 132.87 * t - 0.009173 * t2) * dr)

        // M  = Dị thường trung bình của Mặt Trời (Sun's Mean Anomaly)
        let m = 359.2242 + 29.10535608 * Double(k) - 0.0000333 * t2 - 0.00000347 * t3
        // M' = Dị thường trung bình của Mặt Trăng (Moon's Mean Anomaly)
        let mPrime = 306.0253 + 385.81691806 * Double(k) + 0.0107306 * t2 + 0.00001236 * t3
        // F  = Đối số vĩ độ Mặt Trăng (Moon's Argument of Latitude)
        let f = 21.2964 + 390.67050646 * Double(k) - 0.0016528 * t2 - 0.00000239 * t3

        // c1 = Tổng hiệu chỉnh từ nhiễu loạn hấp dẫn (perturbations)
        // Mỗi số hạng là hiệu chỉnh từ Mặt Trời (M), Mặt Trăng (M'), góc vĩ độ (F)
        var c1 = (0.1734 - 0.000393 * t) * sin(m * dr) + 0.0021 * sin(2 * dr * m)
        c1 -= 0.4068 * sin(mPrime * dr) + 0.0161 * sin(2 * dr * mPrime)
        c1 -= 0.0004 * sin(3 * dr * mPrime)
        c1 += 0.0104 * sin(2 * dr * f) - 0.0051 * sin(dr * (m + mPrime))
        c1 -= 0.0074 * sin(dr * (m - mPrime)) + 0.0004 * sin(dr * (2 * f + m))
        c1 -= 0.0004 * sin(dr * (2 * f - m)) - 0.0006 * sin(dr * (2 * f + mPrime))
        c1 += 0.0010 * sin(dr * (2 * f - mPrime)) + 0.0005 * sin(dr * (2 * mPrime + m))

        // Delta T = hiệu giữa Terrestrial Time (TT) và Universal Time (UT)
        // Cần trừ đi để ra UT (thời gian dân dụng)
        let deltaT: Double
        if t < -11 {
            // Công thức cho thời điểm xa trong quá khứ (trước ~1620)
            deltaT = 0.001 + 0.000839 * t + 0.0002261 * t2 - 0.00000845 * t3 - 0.000000081 * t * t3
        } else {
            // Công thức cho phần lớn phạm vi sử dụng thực tế
            deltaT = -0.000278 + 0.000265 * t + 0.000262 * t2
        }

        return jd1 + c1 - deltaT
    }

    private static func sunLongitude(jdn: Double) -> Double {
        JulianDay.sunLongitude(jdn: jdn)
    }
}
