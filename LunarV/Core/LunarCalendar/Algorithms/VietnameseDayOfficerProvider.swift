//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import Foundation

enum VietnameseDayOfficerProvider {
    private struct DayOfficerTemplate {
        let level: VietnameseGuidanceLevel
        let summary: String
        let recommendedActivities: [String]
        let avoidActivities: [String]
    }

    private static let officerOrder = [
        "Kiến", "Trừ", "Mãn", "Bình", "Định", "Chấp",
        "Phá", "Nguy", "Thành", "Thu", "Khai", "Bế",
    ]

    private static let fallbackTemplate = DayOfficerTemplate(
        level: .neutral,
        summary: "Trực ngày ở mức cân bằng, nên ưu tiên việc có kế hoạch rõ.",
        recommendedActivities: ["Rà soát kế hoạch", "Tổng kết công việc"],
        avoidActivities: ["Khởi sự vội vàng", "Cam kết khi chưa đủ dữ liệu"]
    )

    private static let templatesByName: [String: DayOfficerTemplate] = [
        "Kiến": DayOfficerTemplate(
            level: .favorable,
            summary: "Tốt cho việc bắt đầu, mở đầu chu kỳ mới và tạo đà phát triển.",
            recommendedActivities: ["Khai trương", "Mở dự án mới", "Xuất hành", "Nhận chức"],
            avoidActivities: ["Trì hoãn quyết định", "Để kế hoạch dang dở"]
        ),
        "Trừ": DayOfficerTemplate(
            level: .neutral,
            summary: "Phù hợp việc dọn dẹp, loại bỏ tồn đọng và xử lý vấn đề cũ.",
            recommendedActivities: ["Dọn dẹp nhà cửa", "Giải quyết hồ sơ tồn", "Chữa bệnh, tĩnh dưỡng"],
            avoidActivities: ["Khai trương lớn", "Ký cam kết dài hạn"]
        ),
        "Mãn": DayOfficerTemplate(
            level: .favorable,
            summary: "Thuận cho các việc cầu tài, hội họp và chốt kết quả ngắn hạn.",
            recommendedActivities: ["Họp nhóm", "Chốt chỉ tiêu", "Thu xếp tài chính"],
            avoidActivities: ["Kiện tụng", "Xử lý việc có xung đột cao"]
        ),
        "Bình": DayOfficerTemplate(
            level: .neutral,
            summary: "Nghiêng về cân bằng, hợp xử lý việc ổn định và giữ nhịp.",
            recommendedActivities: ["Hòa giải", "Ký kết nội bộ", "Điều phối công việc"],
            avoidActivities: ["Mạo hiểm vượt kế hoạch", "Đầu tư cảm tính"]
        ),
        "Định": DayOfficerTemplate(
            level: .favorable,
            summary: "Tốt cho việc cố định, chuẩn hóa và xác lập nền tảng lâu dài.",
            recommendedActivities: ["Ký hợp đồng", "Ổn định quy trình", "Đặt mục tiêu dài hạn"],
            avoidActivities: ["Thay đổi kế hoạch liên tục", "Làm việc thiếu chuẩn bị"]
        ),
        "Chấp": DayOfficerTemplate(
            level: .neutral,
            summary: "Phù hợp duy trì kỷ luật và hoàn thành phần việc đang theo đuổi.",
            recommendedActivities: ["Theo đuổi đầu việc tồn", "Gia cố hạ tầng", "Luyện tập đều đặn"],
            avoidActivities: ["Đổi hướng bất ngờ", "Bắt đầu quá nhiều việc mới"]
        ),
        "Phá": DayOfficerTemplate(
            level: .caution,
            summary: "Hợp việc tháo gỡ, sửa sai; không thuận cho việc cần tính khởi tạo.",
            recommendedActivities: ["Gỡ rối hệ thống", "Sửa sai quy trình", "Phá dỡ phần không còn phù hợp"],
            avoidActivities: ["Khai trương", "Cưới hỏi", "Cam kết lớn"]
        ),
        "Nguy": DayOfficerTemplate(
            level: .caution,
            summary: "Nên thận trọng, ưu tiên an toàn và kiểm soát rủi ro.",
            recommendedActivities: ["Kiểm tra an toàn", "Rà soát hợp đồng", "Giữ lịch nhẹ"],
            avoidActivities: ["Đi xa gấp", "Đầu tư rủi ro cao", "Tranh luận căng thẳng"]
        ),
        "Thành": DayOfficerTemplate(
            level: .favorable,
            summary: "Thuận lợi để hoàn tất việc quan trọng và chốt kết quả.",
            recommendedActivities: ["Chốt dự án", "Khai trương", "Ký kết", "Tổ chức lễ nghi"],
            avoidActivities: ["Để việc kéo dài", "Lơ là khâu kiểm tra cuối"]
        ),
        "Thu": DayOfficerTemplate(
            level: .favorable,
            summary: "Phù hợp thu hoạch thành quả, thu nợ và hoàn thiện lợi ích thực tế.",
            recommendedActivities: ["Tổng kết doanh thu", "Thu hồi công nợ", "Chốt khoản mục"],
            avoidActivities: ["Mở rộng nóng vội", "Khởi công thiếu chuẩn bị"]
        ),
        "Khai": DayOfficerTemplate(
            level: .favorable,
            summary: "Tốt cho việc mở thông, công bố và khởi tạo cơ hội mới.",
            recommendedActivities: ["Mở cửa hàng", "Ra mắt sản phẩm", "Giao tiếp đối tác"],
            avoidActivities: ["Đóng băng quyết định", "Bỏ lỡ cơ hội rõ ràng"]
        ),
        "Bế": DayOfficerTemplate(
            level: .caution,
            summary: "Nghiêng về kết thúc, đóng lại chu kỳ; không thuận cho việc khai mở.",
            recommendedActivities: ["Tổng kiểm", "Lưu trữ hồ sơ", "Nghỉ ngơi hồi phục"],
            avoidActivities: ["Khai trương", "Bắt đầu dự án lớn", "Đi xa đột xuất"]
        ),
    ]

    static func officer(
        lunarMonth: Int,
        solarDay: Int,
        solarMonth: Int,
        solarYear: Int
    ) -> VietnameseDayOfficer {
        let monthBranchIndex = VietnameseCalendarMetadata.lunarMonthBranchOrdinal(lunarMonth: lunarMonth)
        let dayBranchIndex = VietnameseCalendarMetadata.dayBranchOrdinal(
            day: solarDay,
            month: solarMonth,
            year: solarYear
        )
        let officerIndex = positiveMod(dayBranchIndex - monthBranchIndex, officerOrder.count)
        let officerName = officerOrder[officerIndex]
        let monthBranch = VietnameseCalendarMetadata.lunarMonthBranch(lunarMonth: lunarMonth)
        let dayBranch = VietnameseCalendarMetadata.dayBranch(day: solarDay, month: solarMonth, year: solarYear)
        let template = templatesByName[officerName] ?? fallbackTemplate

        return VietnameseDayOfficer(
            name: officerName,
            level: template.level,
            summary: template.summary,
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
