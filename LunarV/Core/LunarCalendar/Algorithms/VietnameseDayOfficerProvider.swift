//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import Foundation

/// Namespace cung cấp **Trực ngày (Day Officer / 12 Trực)** trong lịch pháp Việt Nam.
///
/// ## 12 Trực là gì?
/// 12 Trực (còn gọi là Thập nhị Kiến Trừ) là 12 tính chất tuần hoàn của ngày,
/// xác định **mức độ thuận lợi** cho các hoạt động quan trọng.
///
/// ## Cách tính Trực ngày
/// Trực ngày được xác định bằng công thức:
/// ```
/// trực_index = (chi_ngày - chi_tháng) mod 12
/// ```
/// Trong đó:
/// - `chi_ngày`: Địa Chi của ngày dương lịch (dựa trên JDN)
/// - `chi_tháng`: Địa Chi của tháng âm lịch (tháng Giêng = Dần, tháng 2 = Mão, ...)
///
/// **Ví dụ:**
/// - Ngày Đinh Hợi (chi = Hợi = 11), tháng 2 âm (Mão = 3)
/// - Trực index = (11 - 3 + 12) mod 12 = 8 → "Thành" (thuận lợi, chốt kết quả)
///
/// 12 Trực theo thứ tự: Kiến, Trừ, Mãn, Bình, Định, Chấp, Phá, Nguy, Thành, Thu, Khai, Bế
enum VietnameseDayOfficerProvider {
    private struct DayOfficerTemplate {
        let level: VietnameseGuidanceLevel
        let summary: String
        let recommendedActivities: [String]
        let avoidActivities: [String]
    }

    /// Thứ tự 12 Trực (bắt đầu từ Kiến tương ứng offset 0)
    private static let officerOrder = [
        "Kiến", "Trừ", "Mãn", "Bình", "Định", "Chấp",
        "Phá",  "Nguy", "Thành", "Thu", "Khai", "Bế",
    ]

    private static let fallbackTemplate = DayOfficerTemplate(
        level: .neutral,
        summary: "Trực ngày ở mức cân bằng, nên ưu tiên việc có kế hoạch rõ.",
        recommendedActivities: ["Rà soát kế hoạch", "Tổng kết công việc"],
        avoidActivities: ["Khởi sự vội vàng", "Cam kết khi chưa đủ dữ liệu"]
    )

    /// Thư viện mô tả chi tiết từng Trực với mức độ và gợi ý hoạt động
    private static let templatesByName: [String: DayOfficerTemplate] = [
        /// Kiến = "Lập dựng" – thuận cho khởi đầu, mở đầu chu kỳ mới
        "Kiến": DayOfficerTemplate(
            level: .favorable,
            summary: "Tốt cho việc bắt đầu, mở đầu chu kỳ mới và tạo đà phát triển.",
            recommendedActivities: ["Khai trương", "Mở dự án mới", "Xuất hành", "Nhận chức"],
            avoidActivities: ["Trì hoãn quyết định", "Để kế hoạch dang dở"]
        ),
        /// Trừ = "Trừ bỏ" – phù hợp dọn dẹp, giải quyết tồn đọng
        "Trừ": DayOfficerTemplate(
            level: .neutral,
            summary: "Phù hợp việc dọn dẹp, loại bỏ tồn đọng và xử lý vấn đề cũ.",
            recommendedActivities: ["Dọn dẹp nhà cửa", "Giải quyết hồ sơ tồn", "Chữa bệnh, tĩnh dưỡng"],
            avoidActivities: ["Khai trương lớn", "Ký cam kết dài hạn"]
        ),
        /// Mãn = "Đầy đủ" – thuận cầu tài, họp mặt
        "Mãn": DayOfficerTemplate(
            level: .favorable,
            summary: "Thuận cho các việc cầu tài, hội họp và chốt kết quả ngắn hạn.",
            recommendedActivities: ["Họp nhóm", "Chốt chỉ tiêu", "Thu xếp tài chính"],
            avoidActivities: ["Kiện tụng", "Xử lý việc có xung đột cao"]
        ),
        /// Bình = "Cân bằng" – nghiêng về ổn định, giữ nhịp
        "Bình": DayOfficerTemplate(
            level: .neutral,
            summary: "Nghiêng về cân bằng, hợp xử lý việc ổn định và giữ nhịp.",
            recommendedActivities: ["Hòa giải", "Ký kết nội bộ", "Điều phối công việc"],
            avoidActivities: ["Mạo hiểm vượt kế hoạch", "Đầu tư cảm tính"]
        ),
        /// Định = "Định rõ" – tốt cố định, chuẩn hóa nền tảng lâu dài
        "Định": DayOfficerTemplate(
            level: .favorable,
            summary: "Tốt cho việc cố định, chuẩn hóa và xác lập nền tảng lâu dài.",
            recommendedActivities: ["Ký hợp đồng", "Ổn định quy trình", "Đặt mục tiêu dài hạn"],
            avoidActivities: ["Thay đổi kế hoạch liên tục", "Làm việc thiếu chuẩn bị"]
        ),
        /// Chấp = "Duy trì" – phù hợp kỷ luật, hoàn thành việc đang theo đuổi
        "Chấp": DayOfficerTemplate(
            level: .neutral,
            summary: "Phù hợp duy trì kỷ luật và hoàn thành phần việc đang theo đuổi.",
            recommendedActivities: ["Theo đuổi đầu việc tồn", "Gia cố hạ tầng", "Luyện tập đều đặn"],
            avoidActivities: ["Đổi hướng bất ngờ", "Bắt đầu quá nhiều việc mới"]
        ),
        /// Phá = "Phá vỡ" – hợp tháo gỡ, sửa sai; không thuận khởi tạo
        "Phá": DayOfficerTemplate(
            level: .caution,
            summary: "Hợp việc tháo gỡ, sửa sai; không thuận cho việc cần tính khởi tạo.",
            recommendedActivities: ["Gỡ rối hệ thống", "Sửa sai quy trình", "Phá dỡ phần không còn phù hợp"],
            avoidActivities: ["Khai trương", "Cưới hỏi", "Cam kết lớn"]
        ),
        /// Nguy = "Nguy hiểm" – cần thận trọng, ưu tiên an toàn
        "Nguy": DayOfficerTemplate(
            level: .caution,
            summary: "Nên thận trọng, ưu tiên an toàn và kiểm soát rủi ro.",
            recommendedActivities: ["Kiểm tra an toàn", "Rà soát hợp đồng", "Giữ lịch nhẹ"],
            avoidActivities: ["Đi xa gấp", "Đầu tư rủi ro cao", "Tranh luận căng thẳng"]
        ),
        /// Thành = "Thành công" – thuận hoàn tất, chốt kết quả
        "Thành": DayOfficerTemplate(
            level: .favorable,
            summary: "Thuận lợi để hoàn tất việc quan trọng và chốt kết quả.",
            recommendedActivities: ["Chốt dự án", "Khai trương", "Ký kết", "Tổ chức lễ nghi"],
            avoidActivities: ["Để việc kéo dài", "Lơ là khâu kiểm tra cuối"]
        ),
        /// Thu = "Thu hoạch" – phù hợp thu thành quả, thu nợ
        "Thu": DayOfficerTemplate(
            level: .favorable,
            summary: "Phù hợp thu hoạch thành quả, thu nợ và hoàn thiện lợi ích thực tế.",
            recommendedActivities: ["Tổng kết doanh thu", "Thu hồi công nợ", "Chốt khoản mục"],
            avoidActivities: ["Mở rộng nóng vội", "Khởi công thiếu chuẩn bị"]
        ),
        /// Khai = "Mở thông" – tốt công bố, khởi tạo cơ hội
        "Khai": DayOfficerTemplate(
            level: .favorable,
            summary: "Tốt cho việc mở thông, công bố và khởi tạo cơ hội mới.",
            recommendedActivities: ["Mở cửa hàng", "Ra mắt sản phẩm", "Giao tiếp đối tác"],
            avoidActivities: ["Đóng băng quyết định", "Bỏ lỡ cơ hội rõ ràng"]
        ),
        /// Bế = "Đóng lại" – nghiêng kết thúc chu kỳ; không thuận khai mở
        "Bế": DayOfficerTemplate(
            level: .caution,
            summary: "Nghiêng về kết thúc, đóng lại chu kỳ; không thuận cho việc khai mở.",
            recommendedActivities: ["Tổng kiểm", "Lưu trữ hồ sơ", "Nghỉ ngơi hồi phục"],
            avoidActivities: ["Khai trương", "Bắt đầu dự án lớn", "Đi xa đột xuất"]
        ),
    ]

    // MARK: - Public API

    /// Tính **Trực ngày** cho một ngày dương lịch với tháng âm lịch cho trước.
    ///
    /// - Parameters:
    ///   - lunarMonth:  Tháng âm lịch (1–12) — dùng để lấy chi tháng
    ///   - solarDay:    Ngày dương lịch
    ///   - solarMonth:  Tháng dương lịch
    ///   - solarYear:   Năm dương lịch
    /// - Returns: `VietnameseDayOfficer` chứa tên Trực, mức độ và gợi ý hoạt động
    static func officer(
        lunarMonth: Int,
        solarDay: Int,
        solarMonth: Int,
        solarYear: Int
    ) -> VietnameseDayOfficer {
        // Lấy index chi tháng âm (ví dụ tháng 2 âm = Mão = index 3)
        let monthBranchIndex = VietnameseCalendarMetadata.lunarMonthBranchOrdinal(lunarMonth: lunarMonth)
        // Lấy index chi ngày dương (từ JDN)
        let dayBranchIndex = VietnameseCalendarMetadata.dayBranchOrdinal(
            day: solarDay,
            month: solarMonth,
            year: solarYear
        )
        // Tính offset trực: (chi ngày - chi tháng) mod 12
        let officerIndex = positiveMod(dayBranchIndex - monthBranchIndex, officerOrder.count)
        let officerName = officerOrder[officerIndex]
        let monthBranch = VietnameseCalendarMetadata.lunarMonthBranch(lunarMonth: lunarMonth)
        let dayBranch = VietnameseCalendarMetadata.dayBranch(day: solarDay, month: solarMonth, year: solarYear)
        let template = templatesByName[officerName] ?? fallbackTemplate

        return VietnameseDayOfficer(
            name: officerName,
            level: template.level,
            summary: template.summary,
            // Ghi chú tính toán để người dùng / developer có thể kiểm chứng
            calculationNote: "Tháng \(monthBranch) gặp ngày \(dayBranch) -> Trực \(officerName)",
            recommendedActivities: template.recommendedActivities,
            avoidActivities: template.avoidActivities
        )
    }

    private static func positiveMod(_ value: Int, _ modulo: Int) -> Int {
        let result = value % modulo
        return result >= 0 ? result : result + modulo
    }
}
