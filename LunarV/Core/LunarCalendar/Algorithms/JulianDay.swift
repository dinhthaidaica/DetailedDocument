//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import Foundation

/// Namespace cung cấp các hàm tính toán liên quan đến **Số ngày Julian (Julian Day Number - JDN)**.
///
/// Julian Day Number là một hệ đếm số ngày liên tục bắt đầu từ buổi trưa ngày 1/1/4713 TCN
/// (theo lịch Julian). Đây là "đơn vị thời gian" dùng chung cho thiên văn học để so sánh ngày
/// tháng giữa các hệ lịch khác nhau mà không lo vấn đề tháng/năm nhuận.
///
/// - Note: JDN được dùng xuyên suốt toàn bộ engine chuyển đổi âm-dương lịch của ứng dụng.
enum JulianDay {
    /// Chuyển đổi một ngày Dương lịch (Gregorian) sang **Số ngày Julian (JDN)**.
    ///
    /// Công thức sử dụng thuật toán chuẩn của Meeus (Jean Meeus - "Astronomical Algorithms"),
    /// có xử lý lịch sử: trước ngày 15/10/1582 dùng lịch Julian cổ, sau đó dùng Gregorian.
    ///
    /// - Parameters:
    ///   - day:   Ngày trong tháng (1–31)
    ///   - month: Tháng (1–12)
    ///   - year:  Năm (phần lớn 1800–2100 trong ngữ cảnh app)
    /// - Returns: Số ngày Julian nguyên (Julian Day Number)
    ///
    /// **Ví dụ:**
    /// ```swift
    /// // 20/2/2026 (Dương lịch) → JDN
    /// let jdn = JulianDay.fromGregorian(day: 20, month: 2, year: 2026)
    /// // jdn == 2_461_094
    /// ```
    static func fromGregorian(day: Int, month: Int, year: Int) -> Int {
        // Nếu month = 1 hoặc 2 → (14 - month) ≥ 12 → a = 1
        // Nếu month >= 3 → a = 0
        // Jan & Feb được coi là tháng 13 và 14 của năm trước
        let a = (14 - month) / 12
        
        // `y` = năm điều chỉnh để Jan và Feb thuộc năm -1, 4800 là offset an toàn để không có số âm trong phép chia nguyên.
        let y = year + 4800 - a
        
        // `m` = tháng sau khi điều chỉnh (Mar=0, Apr=1, ..., Feb=11) → Mar là tháng đầu tiên của năm.
        let m = month + 12 * a - 3

        // Công thức Gregorian (từ 15/10/1582 trở đi)
        var jd = day + ((153 * m + 2) / 5) + (365 * y) + (y / 4) - (y / 100) + (y / 400) - 32045
        
        // Nếu kết quả < 2_299_161 (JDN tương ứng 15/10/1582), dùng công thức Julian cổ
        if jd < 2_299_161 {
            jd = day + ((153 * m + 2) / 5) + (365 * y) + (y / 4) - 32083
        }
        return jd
    }

    /// Tính **Kinh độ mặt trời (Sun Longitude)** tại một thời điểm Julian cụ thể.
    ///
    /// Kinh độ mặt trời (tính bằng radian, 0 → 2π) là vị trí góc của Trái Đất trên quỹ đạo
    /// quanh Mặt Trời, đo từ điểm Xuân phân. Nó được dùng để:
    /// - Xác định **Tiết khí** (24 tiết khí = mỗi 15° kinh độ)
    /// - Xác định **tháng 11 âm lịch** (tháng chứa Đông chí − kinh độ = 270°)
    /// - Phát hiện **tháng nhuận** (tháng có 2 trăng mới trong cùng một khoảng 30° kinh độ)
    ///
    /// - Parameter jdn: Thời điểm Julian dạng thực (Julian Day Number dạng fractional)
    /// - Returns: Kinh độ mặt trời (radians), giá trị trong khoảng [0, 2π)
    ///
    /// **Ví dụ:**
    /// ```swift
    /// // Đông chí 2025 ≈ JDN 2_461_041
    /// let lon = JulianDay.sunLongitude(jdn: 2_461_041.0)
    /// let degrees = lon * 180 / .pi  // ≈ 270° (Đông chí)
    /// ```
    static func sunLongitude(jdn: Double) -> Double {
        // `t` = số thế kỷ Julian từ J2000.0 (ngày cơ sở 1/1/2000 12:00 TT)
        let t = (jdn - 2_451_545.0) / 36525
        let t2 = t * t
        let dr = Double.pi / 180  // hệ số quy đổi độ → radian

        // `m` = Dị thường trung bình của Mặt Trời (Mean Anomaly), tính bằng độ
        // Đây là góc giả sử Trái Đất chuyển động đều trên quỹ đạo tròn
        let m = 357.52910 + 35999.05030 * t - 0.0001559 * t2 - 0.00000048 * t * t2
        // `l0` = Kinh độ trung bình (Mean Longitude) của Mặt Trời, tính bằng độ
        let l0 = 280.46645 + 36000.76983 * t + 0.0003032 * t2

        // `dl` = Hiệu chỉnh trung tâm (Equation of Center) - sai số do quỹ đạo Elip
        // Dùng chuỗi Fourier khai triển theo sin(m), sin(2m), sin(3m)
        var dl = (1.914600 - 0.004817 * t - 0.000014 * t2) * sin(dr * m)
        dl += (0.019993 - 0.000101 * t) * sin(2 * dr * m) + 0.000290 * sin(3 * dr * m)

        // `longitude` = Kinh độ thực (True Longitude) = l0 + dl (bằng độ → đổi sang radian)
        var longitude = l0 + dl
        longitude *= dr
        // Chuẩn hóa về [0, 2π): loại bỏ các vòng tròn dư
        longitude -= Double.pi * 2 * floor(longitude / (Double.pi * 2))
        return longitude
    }
}
