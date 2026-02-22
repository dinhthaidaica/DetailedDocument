//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import Foundation

/// Namespace cung cấp các hàm tính toán **siêu dữ liệu lịch Việt Nam**:
/// Can Chi (Thiên Can + Địa Chi), Tiết khí, Giờ hoàng đạo.
///
/// ## Hệ thống Can Chi
/// - **Thiên Can (Heavenly Stems)**: 10 can: Giáp, Ất, Bính, Đinh, Mậu, Kỷ, Canh, Tân, Nhâm, Quý
/// - **Địa Chi (Earthly Branches)**: 12 chi: Tý, Sửu, Dần, Mão, Thìn, Tỵ, Ngọ, Mùi, Thân, Dậu, Tuất, Hợi
/// - Chu kỳ Can Chi = LCM(10, 12) = **60 năm** (lục thập hoa giáp)
///
/// ## Hệ thống 24 Tiết khí
/// Mỗi tiết khí ứng với 15° kinh độ mặt trời. Năm dương lịch có đúng 24 tiết.
enum VietnameseCalendarMetadata {
    // MARK: - Dữ liệu cố định

    /// Danh sách 10 Thiên Can theo thứ tự (index 0–9)
    private static let heavenlyStems = ["Giáp", "Ất", "Bính", "Đinh", "Mậu", "Kỷ", "Canh", "Tân", "Nhâm", "Quý"]
    /// Danh sách 12 Địa Chi theo thứ tự (index 0–11, bắt đầu từ Tý)
    private static let earthlyBranches = ["Tý", "Sửu", "Dần", "Mão", "Thìn", "Tỵ", "Ngọ", "Mùi", "Thân", "Dậu", "Tuất", "Hợi"]
    /// Hành tương ứng với mỗi Thiên Can (2 can liên tiếp chung 1 hành)
    /// Giáp/Ất=Mộc, Bính/Đinh=Hỏa, Mậu/Kỷ=Thổ, Canh/Tân=Kim, Nhâm/Quý=Thủy
    private static let stemElements = ["Mộc", "Mộc", "Hỏa", "Hỏa", "Thổ", "Thổ", "Kim", "Kim", "Thủy", "Thủy"]

    /// Pattern giờ hoàng đạo: mỗi chuỗi 12 ký tự "0"/"1" ứng với 12 giờ địa chi trong ngày.
    /// Index pattern được chọn theo **địa chi của ngày** mod 6:
    ///   - pattern[0]: ngày Tý hoặc Ngọ   (branchIndex mod 6 == 0)
    ///   - pattern[1]: ngày Sửu hoặc Mùi  (branchIndex mod 6 == 1)
    ///   - pattern[2]: ngày Dần hoặc Thân (branchIndex mod 6 == 2)
    ///   - pattern[3]: ngày Mão hoặc Dậu  (branchIndex mod 6 == 3)
    ///   - pattern[4]: ngày Thìn hoặc Tuất(branchIndex mod 6 == 4)
    ///   - pattern[5]: ngày Tỵ hoặc Hợi   (branchIndex mod 6 == 5)
    private static let auspiciousHourPatterns = [
        "110100101100", // Tý, Ngọ
        "001101001011", // Sửu, Mùi
        "110011010010", // Dần, Thân
        "101100110100", // Mão, Dậu
        "001011001101", // Thìn, Tuất
        "010010110011", // Tỵ, Hợi
    ]

    /// Khoảng thời gian thực tế của từng Địa Chi trong ngày (12 giờ × 2 tiếng mỗi giờ).
    /// Giờ Tý bắt đầu từ 23:00 hôm trước đến 01:00 hôm sau.
    private static let earthlyBranchTimeRanges = [
        "23:00-01:00", "01:00-03:00", "03:00-05:00", "05:00-07:00",
        "07:00-09:00", "09:00-11:00", "11:00-13:00", "13:00-15:00",
        "15:00-17:00", "17:00-19:00", "19:00-21:00", "21:00-23:00",
    ]

    /// 24 Tiết khí theo thứ tự kinh độ mặt trời (bắt đầu từ 315° = Lập xuân)
    /// Mỗi tiết cách nhau 15° kinh độ. Index 0 = 315°, index 23 = 300° (Đại hàn)
    private static let solarTerms = [
        "Lập xuân", "Vũ thủy", "Kinh trập", "Xuân phân", "Thanh minh", "Cốc vũ",
        "Lập hạ",   "Tiểu mãn", "Mang chủng", "Hạ chí",   "Tiểu thử", "Đại thử",
        "Lập thu",  "Xử thử",   "Bạch lộ",    "Thu phân",  "Hàn lộ",  "Sương giáng",
        "Lập đông", "Tiểu tuyết","Đại tuyết",  "Đông chí",  "Tiểu hàn","Đại hàn",
    ]

    // MARK: - Can Chi Năm / Tháng / Ngày / Giờ

    /// Tính Can Chi của **năm âm lịch**.
    ///
    /// **Công thức:**
    /// - Can = (năm âm + 6) mod 10  → vì năm 4 TCN (năm 0) bắt đầu chu kỳ Giáp
    /// - Chi = (năm âm + 8) mod 12  → vì năm 4 TCN bắt đầu chu kỳ Tý
    ///
    /// **Ví dụ:** Năm 2026 dương = năm Bính Ngọ âm lịch
    /// - Can: (2026 + 6) % 10 = 2032 % 10 = 2 → "Bính"
    /// - Chi: (2026 + 8) % 12 = 2034 % 12 = 6 → "Ngọ"
    static func canChiYear(lunarYear: Int) -> String {
        let stem = heavenlyStems[positiveMod(lunarYear + 6, 10)]
        let branch = earthlyBranches[positiveMod(lunarYear + 8, 12)]
        return "\(stem) \(branch)"
    }

    /// Tính Can Chi của **tháng âm lịch**.
    ///
    /// **Công thức:**
    /// - Can tháng phụ thuộc cả năm âm và tháng (chu kỳ 5 năm = 60 tháng):
    ///   `(năm âm × 12 + tháng + 3) mod 10`
    /// - Chi tháng: `(tháng + 1) mod 12` (tháng Giêng = Dần = index 2)
    ///
    /// **Ví dụ:** Tháng 2 năm Bính Ngọ (2026)
    /// - Can: (2026 × 12 + 2 + 3) % 10 = 24317 % 10 = 7 → "Tân"
    /// - Chi: (2 + 1) % 12 = 3 → "Mão" → "Tân Mão"
    static func canChiMonth(lunarMonth: Int, lunarYear: Int) -> String {
        let stem = heavenlyStems[positiveMod(lunarYear * 12 + lunarMonth + 3, 10)]
        let branch = earthlyBranches[positiveMod(lunarMonth + 1, 12)]
        return "\(stem) \(branch)"
    }

    /// Tính Can Chi của **ngày dương lịch** dựa trên JDN.
    ///
    /// **Công thức:**
    /// - Can ngày: `(JDN + 9) mod 10`
    /// - Chi ngày: `(JDN + 1) mod 12`
    ///
    /// Đây là cách chuẩn vì JDN tăng đều 1 mỗi ngày, nên Can lặp 10 ngày, Chi lặp 12 ngày.
    ///
    /// **Ví dụ:** 20/2/2026 → JDN = 2_461_094
    /// - Can: (2_461_094 + 9) % 10 = 3 → "Đinh"
    /// - Chi: (2_461_094 + 1) % 12 = 11 → "Hợi" → "Đinh Hợi"
    static func canChiDay(day: Int, month: Int, year: Int) -> String {
        let stem = heavenlyStems[dayStemIndex(day: day, month: month, year: year)]
        let branch = earthlyBranches[dayBranchIndex(day: day, month: month, year: year)]
        return "\(stem) \(branch)"
    }

    /// Tính Can Chi của **giờ** trong ngày.
    ///
    /// **Quy tắc:**
    /// - Chi giờ: `(giờ + 1) / 2 mod 12`   (mỗi giờ địa chi = 2 giờ đồng hồ, bắt đầu từ 23:00)
    /// - Can giờ: `(can ngày × 2 + chi giờ) mod 10`  (chu kỳ phụ thuộc can ngày)
    static func canChiHour(date: Date, day: Int, month: Int, year: Int, calendar: Calendar) -> String {
        let dayStemIndex = dayStemIndex(day: day, month: month, year: year)
        let hour = calendar.component(.hour, from: date)
        // Giờ 23:00–01:00 = Tý (index 0), 01:00–03:00 = Sửu (index 1), ...
        let hourBranchIndex = positiveMod((hour + 1) / 2, 12)
        return hourCanChi(dayStemIndex: dayStemIndex, hourBranchIndex: hourBranchIndex)
    }

    /// Trả về **Hành** (ngũ hành) của ngày, dựa trên Thiên Can của ngày.
    static func dayElement(day: Int, month: Int, year: Int) -> String {
        stemElements[dayStemIndex(day: day, month: month, year: year)]
    }

    /// Trả về **Địa Chi** (tên) của ngày.
    static func dayBranch(day: Int, month: Int, year: Int) -> String {
        earthlyBranches[dayBranchIndex(day: day, month: month, year: year)]
    }

    /// Trả về **index Địa Chi** (0–11) của ngày.
    static func dayBranchOrdinal(day: Int, month: Int, year: Int) -> Int {
        dayBranchIndex(day: day, month: month, year: year)
    }

    /// Trả về **Địa Chi của tháng âm** (tên chi tương ứng tháng âm lịch).
    static func lunarMonthBranch(lunarMonth: Int) -> String {
        earthlyBranches[lunarMonthBranchOrdinal(lunarMonth: lunarMonth)]
    }

    /// Trả về **index Địa Chi của tháng âm** (tháng 1 âm = Dần = index 2, v.v.)
    ///
    /// **Công thức:** `(tháng + 1) mod 12`
    /// - Tháng 1 (Giêng): (1+1)%12 = 2 = Dần ✓
    /// - Tháng 11: (11+1)%12 = 0 = Tý ✓
    static func lunarMonthBranchOrdinal(lunarMonth: Int) -> Int {
        positiveMod(lunarMonth + 1, 12)
    }

    // MARK: - Xung Chiếu / Tam Hợp

    /// Trả về **Con giáp xung** với ngày hiện tại (đối xung = cách 6 chi).
    ///
    /// Trong lý học, xung = đối nhau trên vòng 12 chi:
    /// Tý ↔ Ngọ, Sửu ↔ Mùi, Dần ↔ Thân, Mão ↔ Dậu, Thìn ↔ Tuất, Tỵ ↔ Hợi
    static func oppositeZodiac(day: Int, month: Int, year: Int) -> String {
        let branchIndex = dayBranchIndex(day: day, month: month, year: year)
        return earthlyBranches[positiveMod(branchIndex + 6, 12)]
    }

    /// Trả về **Nhóm Tam Hợp** chứa ngày hiện tại.
    ///
    /// Tam Hợp là 3 chi cộng năng lượng cho nhau:
    /// - Thân-Tý-Thìn (index 8, 0, 4): Hành Thủy
    /// - Dần-Ngọ-Tuất (index 2, 6, 10): Hành Hỏa
    /// - Hợi-Mão-Mùi  (index 11, 3, 7): Hành Mộc
    /// - Tỵ-Dậu-Sửu   (index 4, 8, 1): Hành Kim
    ///
    /// Các index trong switch là index của chi ngày.
    static func tamHopGroup(day: Int, month: Int, year: Int) -> String {
        let branchIndex = dayBranchIndex(day: day, month: month, year: year)
        switch branchIndex {
        case 0, 4, 8:  return "Thân - Tý - Thìn"   // Tý(0), Thìn(4), Thân(8)
        case 2, 6, 10: return "Dần - Ngọ - Tuất"   // Dần(2), Ngọ(6), Tuất(10)
        case 3, 7, 11: return "Hợi - Mão - Mùi"    // Mão(3), Mùi(7), Hợi(11)
        default:       return "Tỵ - Dậu - Sửu"     // Sửu(1), Tỵ(5), Dậu(9)
        }
    }

    // MARK: - Giờ Hoàng Đạo

    /// Trả về danh sách **12 giờ địa chi trong ngày**, kèm thông tin Hoàng Đạo / Hắc Đạo.
    ///
    /// Mỗi giờ bao gồm: tên chi, can chi, khoảng thời gian thực, và trạng thái hoàng đạo.
    static func hourPeriods(day: Int, month: Int, year: Int) -> [VietnameseHourPeriod] {
        let branchIndex = dayBranchIndex(day: day, month: month, year: year)
        let stemIndex = dayStemIndex(day: day, month: month, year: year)
        // Pattern hoàng đạo chọn theo (branchIndex mod 6) — 6 cặp đối xung chia sẻ cùng pattern
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

    // MARK: - Zodiac & Tiết khí

    /// Trả về **Con giáp** của năm âm lịch (dựa theo Địa Chi năm).
    /// Ví dụ: Năm 2026 = Bính Ngọ → con giáp là "Ngọ" (Ngựa)
    static func zodiac(lunarYear: Int) -> String {
        earthlyBranches[positiveMod(lunarYear + 8, 12)]
    }

    /// Xác định **Tiết khí** của một ngày/giờ cụ thể.
    ///
    /// **Thuật toán:**
    /// 1. Tính JDN của ngày + phần lẻ thời gian trong ngày (fractional day)
    /// 2. Đổi sang UTC (trừ offset múi giờ)
    /// 3. Tính kinh độ mặt trời (Sun Longitude) tại thời điểm UTC đó
    /// 4. Ánh xạ kinh độ sang 1 trong 24 tiết khí:
    ///    - Index = `floor((longitude_degrees + 45) / 15) mod 24`
    ///    - Offset +45° là điều chỉnh để Lập xuân (315°) map vào index 0
    ///
    /// **Ví dụ:** Nếu kinh độ = 315° → (315 + 45)/15 = 24 → mod 24 = 0 → "Lập xuân"
    /// **Ví dụ:** Nếu kinh độ = 270° → (270 + 45)/15 = 21 → "Đông chí"
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
        // Phần lẻ của ngày (0.0 = đầu ngày, 0.5 = giữa ngày)
        let fractionalDay = (hour + minute / 60.0) / 24.0
        // Chuyển sang UTC: JDN nguyên tại 12:00 UTC → trừ 0.5 để về 00:00 UTC → trừ offset múi giờ
        let utcJdn = jdn - 0.5 - timeOffsetHours / 24.0 + fractionalDay
        let longitude = JulianDay.sunLongitude(jdn: utcJdn)
        let longitudeDegrees = longitude * 180.0 / Double.pi
        // Map 360° thành 24 tiết, với điều chỉnh +45° để Lập xuân (315°) = index 0
        let index = positiveMod(Int(floor((longitudeDegrees + 45.0) / 15.0)), 24)
        return solarTerms[index]
    }

    // MARK: - Private Helpers

    /// Index Thiên Can của ngày: `(JDN + 9) mod 10`
    private static func dayStemIndex(day: Int, month: Int, year: Int) -> Int {
        let jdn = JulianDay.fromGregorian(day: day, month: month, year: year)
        return positiveMod(jdn + 9, 10)
    }

    /// Index Địa Chi của ngày: `(JDN + 1) mod 12`
    private static func dayBranchIndex(day: Int, month: Int, year: Int) -> Int {
        let jdn = JulianDay.fromGregorian(day: day, month: month, year: year)
        return positiveMod(jdn + 1, 12)
    }

    /// Tính Can Chi giờ từ Can ngày và Chi giờ:
    /// - Can giờ: `(can ngày × 2 + chi giờ) mod 10`
    ///
    /// **Quy tắc lý học:** Ngày Giáp/Kỷ → giờ Tý bắt đầu bằng Giáp
    /// Ngày Ất/Canh → giờ Tý bắt đầu bằng Bính ... (chu kỳ 5 ngày)
    private static func hourCanChi(dayStemIndex: Int, hourBranchIndex: Int) -> String {
        let hourStemIndex = positiveMod(dayStemIndex * 2 + hourBranchIndex, 10)
        return "\(heavenlyStems[hourStemIndex]) \(earthlyBranches[hourBranchIndex])"
    }

    /// Modulo luôn trả về số dương (tránh kết quả âm khi value < 0 trong Swift).
    private static func positiveMod(_ value: Int, _ modulo: Int) -> Int {
        let result = value % modulo
        return result >= 0 ? result : result + modulo
    }
}
