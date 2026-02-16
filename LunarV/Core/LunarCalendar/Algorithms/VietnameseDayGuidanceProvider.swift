//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import Foundation

enum VietnameseDayGuidanceProvider {
    private enum Season {
        case spring
        case summer
        case autumn
        case winter
    }

    private struct GuidanceTemplate {
        let title: String
        let summary: String
        let recommendedActivities: [String]
        let avoidActivities: [String]
    }

    private static let fallbackTemplate = GuidanceTemplate(
        title: "Ngày cân bằng",
        summary: "Năng lượng ngày ở mức trung tính, phù hợp xử lý việc quan trọng theo kế hoạch rõ ràng.",
        recommendedActivities: ["Lập kế hoạch", "Tổng kết công việc", "Sắp xếp lịch cá nhân"],
        avoidActivities: ["Ra quyết định vội vàng", "Trì hoãn quá lâu", "Ôm quá nhiều việc cùng lúc"]
    )

    private static let templatesByElement: [String: GuidanceTemplate] = [
        "Mộc": GuidanceTemplate(
            title: "Ngày hành Mộc",
            summary: "Thuận cho việc phát triển, mở rộng kết nối và bắt đầu chuỗi công việc mới.",
            recommendedActivities: ["Khởi động dự án", "Học tập - nghiên cứu", "Trao đổi với đối tác", "Lên kế hoạch dài hạn"],
            avoidActivities: ["Chốt việc quá nóng vội", "Tách đội nhóm đột ngột", "Bỏ dở giữa chừng"]
        ),
        "Hỏa": GuidanceTemplate(
            title: "Ngày hành Hỏa",
            summary: "Năng lượng mạnh, hợp các công việc cần chủ động, truyền thông và tạo ảnh hưởng.",
            recommendedActivities: ["Thuyết trình", "Đàm phán", "Ra mắt ý tưởng", "Đẩy nhanh đầu việc tồn đọng"],
            avoidActivities: ["Tranh luận căng thẳng", "Phản hồi thiếu kiểm soát", "Quyết định khi đang nóng"]
        ),
        "Thổ": GuidanceTemplate(
            title: "Ngày hành Thổ",
            summary: "Tốt cho các việc củng cố nền tảng và xử lý hạng mục cần độ chắc chắn cao.",
            recommendedActivities: ["Chuẩn hóa quy trình", "Rà soát tài chính", "Hoàn thiện hồ sơ", "Sắp xếp nhà cửa"],
            avoidActivities: ["Mở rộng quá nhanh", "Thử nghiệm rủi ro cao", "Để công việc kéo dài"]
        ),
        "Kim": GuidanceTemplate(
            title: "Ngày hành Kim",
            summary: "Phù hợp các việc cần tính kỷ luật, chuẩn xác và quyết đoán.",
            recommendedActivities: ["Ký kết hợp đồng", "Kiểm tra chất lượng", "Rà soát pháp lý", "Dọn dẹp dữ liệu"],
            avoidActivities: ["Chi tiêu cảm tính", "Cam kết thiếu căn cứ", "Bỏ qua chi tiết nhỏ"]
        ),
        "Thủy": GuidanceTemplate(
            title: "Ngày hành Thủy",
            summary: "Thuận cho tư duy linh hoạt, kết nối thông tin và công việc cần sự thích nghi.",
            recommendedActivities: ["Phân tích dữ liệu", "Viết nội dung", "Điều phối giao tiếp", "Lên phương án dự phòng"],
            avoidActivities: ["Giữ lịch quá cứng", "Làm việc thiếu phản hồi", "Quá sa đà vào tiểu tiết"]
        ),
    ]

    static func guidance(dayElement: String, solarTerm: String) -> VietnameseDayGuidance {
        let template = templatesByElement[dayElement] ?? fallbackTemplate
        let seasonalHint = seasonalHint(for: solarTerm)
        let summary = "\(template.summary) \(seasonalHint)"

        return VietnameseDayGuidance(
            title: template.title,
            summary: summary,
            recommendedActivities: template.recommendedActivities,
            avoidActivities: template.avoidActivities
        )
    }

    private static func seasonalHint(for solarTerm: String) -> String {
        switch season(for: solarTerm) {
        case .spring:
            return "Mùa xuân nên ưu tiên khởi động việc mới và tạo đà tăng trưởng."
        case .summer:
            return "Mùa hạ hợp đẩy tiến độ, nhưng cần quản trị nhịp làm việc để tránh quá tải."
        case .autumn:
            return "Mùa thu phù hợp tối ưu chất lượng, chốt mục tiêu và củng cố kết quả."
        case .winter:
            return "Mùa đông hợp rà soát, chuẩn bị nguồn lực và xây nền cho chu kỳ kế tiếp."
        }
    }

    private static func season(for solarTerm: String) -> Season {
        switch solarTerm {
        case "Lập xuân", "Vũ thủy", "Kinh trập", "Xuân phân", "Thanh minh", "Cốc vũ":
            return .spring
        case "Lập hạ", "Tiểu mãn", "Mang chủng", "Hạ chí", "Tiểu thử", "Đại thử":
            return .summer
        case "Lập thu", "Xử thử", "Bạch lộ", "Thu phân", "Hàn lộ", "Sương giáng":
            return .autumn
        default:
            return .winter
        }
    }
}
