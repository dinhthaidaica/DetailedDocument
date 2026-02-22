//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import Foundation

/// Namespace cung cấp **Hướng dẫn ngày (Day Guidance)** dựa trên Hành của ngày và Tiết khí.
///
/// ## Nguyên lý
/// Mỗi ngày được gắn với một trong 5 Hành: Mộc, Hỏa, Thổ, Kim, Thủy.
/// Hành ngày kết hợp với Tiết khí (Mùa) tạo ra tính chất tổng hợp của ngày,
/// ảnh hưởng đến 5 lĩnh vực: Công việc, Tài chính, Học tập, Di chuyển, Gia đình.
///
/// ## Cấu trúc tính điểm
/// - `baseScore`: Điểm cơ bản từ Hành ngày (71–76 điểm)
/// - `scoreDelta`: Điều chỉnh từ Mùa (-2 đến +4)
/// - `score final` = clamp(baseScore + scoreDelta, 0, 100)
/// - Rating: ≥80 = Excellent, 70–79 = Positive, 55–69 = Balanced, <55 = Caution
enum VietnameseDayGuidanceProvider {
    private enum Season {
        case spring
        case summer
        case autumn
        case winter
    }

    // MARK: - Templates

    private struct GuidanceTemplate {
        let title: String
        let summary: String
        let baseScore: Int
        let recommendedActivities: [String]
        let avoidActivities: [String]
        let categoryLevels: [VietnameseActivityCategory: VietnameseGuidanceLevel]
    }

    private struct SeasonAdjustment {
        let scoreDelta: Int
        let categoryOverrides: [VietnameseActivityCategory: VietnameseGuidanceLevel]
    }

    /// Template dự phòng khi không tìm thấy Hành (không nên xảy ra trong thực tế)
    private static let fallbackTemplate = GuidanceTemplate(
        title: "Ngày cân bằng",
        summary: "Năng lượng ngày ở mức trung tính, phù hợp xử lý việc quan trọng theo kế hoạch rõ ràng.",
        baseScore: 62,
        recommendedActivities: ["Lập kế hoạch", "Tổng kết công việc", "Sắp xếp lịch cá nhân"],
        avoidActivities: ["Ra quyết định vội vàng", "Trì hoãn quá lâu", "Ôm quá nhiều việc cùng lúc"],
        categoryLevels: [
            .work: .neutral, .finance: .neutral, .study: .neutral, .travel: .neutral, .family: .neutral,
        ]
    )

    /// Bảng template theo Hành ngày. Mỗi Hành có tính chất đặc trưng riêng:
    /// - **Mộc**: Phát triển, mở rộng, học tập, kết nối → score 76
    /// - **Hỏa**: Chủ động, truyền thông, thuyết phục → score 72
    /// - **Thổ**: Củng cố nền tảng, tài chính, quy trình → score 74
    /// - **Kim**: Kỷ luật, chính xác, ký kết → score 71
    /// - **Thủy**: Linh hoạt, phân tích, giao tiếp → score 73
    private static let templatesByElement: [String: GuidanceTemplate] = [
        "Mộc": GuidanceTemplate(
            title: "Ngày hành Mộc",
            summary: "Thuận cho việc phát triển, mở rộng kết nối và bắt đầu chuỗi công việc mới.",
            baseScore: 76,
            recommendedActivities: ["Khởi động dự án", "Học tập - nghiên cứu", "Trao đổi với đối tác", "Lên kế hoạch dài hạn"],
            avoidActivities: ["Chốt việc quá nóng vội", "Tách đội nhóm đột ngột", "Bỏ dở giữa chừng"],
            categoryLevels: [.work: .favorable, .finance: .neutral, .study: .favorable, .travel: .neutral, .family: .favorable]
        ),
        "Hỏa": GuidanceTemplate(
            title: "Ngày hành Hỏa",
            summary: "Năng lượng mạnh, hợp các công việc cần chủ động, truyền thông và tạo ảnh hưởng.",
            baseScore: 72,
            recommendedActivities: ["Thuyết trình", "Đàm phán", "Ra mắt ý tưởng", "Đẩy nhanh đầu việc tồn đọng"],
            avoidActivities: ["Tranh luận căng thẳng", "Phản hồi thiếu kiểm soát", "Quyết định khi đang nóng"],
            categoryLevels: [.work: .favorable, .finance: .neutral, .study: .neutral, .travel: .neutral, .family: .caution]
        ),
        "Thổ": GuidanceTemplate(
            title: "Ngày hành Thổ",
            summary: "Tốt cho các việc củng cố nền tảng và xử lý hạng mục cần độ chắc chắn cao.",
            baseScore: 74,
            recommendedActivities: ["Chuẩn hóa quy trình", "Rà soát tài chính", "Hoàn thiện hồ sơ", "Sắp xếp nhà cửa"],
            avoidActivities: ["Mở rộng quá nhanh", "Thử nghiệm rủi ro cao", "Để công việc kéo dài"],
            categoryLevels: [.work: .favorable, .finance: .favorable, .study: .neutral, .travel: .caution, .family: .favorable]
        ),
        "Kim": GuidanceTemplate(
            title: "Ngày hành Kim",
            summary: "Phù hợp các việc cần tính kỷ luật, chuẩn xác và quyết đoán.",
            baseScore: 71,
            recommendedActivities: ["Ký kết hợp đồng", "Kiểm tra chất lượng", "Rà soát pháp lý", "Dọn dẹp dữ liệu"],
            avoidActivities: ["Chi tiêu cảm tính", "Cam kết thiếu căn cứ", "Bỏ qua chi tiết nhỏ"],
            categoryLevels: [.work: .favorable, .finance: .favorable, .study: .neutral, .travel: .neutral, .family: .caution]
        ),
        "Thủy": GuidanceTemplate(
            title: "Ngày hành Thủy",
            summary: "Thuận cho tư duy linh hoạt, kết nối thông tin và công việc cần sự thích nghi.",
            baseScore: 73,
            recommendedActivities: ["Phân tích dữ liệu", "Viết nội dung", "Điều phối giao tiếp", "Lên phương án dự phòng"],
            avoidActivities: ["Giữ lịch quá cứng", "Làm việc thiếu phản hồi", "Quá sa đà vào tiểu tiết"],
            categoryLevels: [.work: .neutral, .finance: .neutral, .study: .favorable, .travel: .favorable, .family: .neutral]
        ),
    ]

    /// Điều chỉnh điểm và category level theo Mùa.
    /// Ưu tiên: seasonAdjustment.categoryOverrides > template.categoryLevels
    private static let seasonAdjustments: [Season: SeasonAdjustment] = [
        .spring: SeasonAdjustment(
            scoreDelta: +4,  // Mùa xuân = thời điểm năng lượng cao nhất
            categoryOverrides: [.work: .favorable, .study: .favorable]
        ),
        .summer: SeasonAdjustment(
            scoreDelta: +1,  // Mùa hè = năng lượng cao nhưng cần cân bằng sức khỏe
            categoryOverrides: [.travel: .caution]
        ),
        .autumn: SeasonAdjustment(
            scoreDelta: +3,  // Mùa thu = tốt tài chính và thu hoạch
            categoryOverrides: [.finance: .favorable]
        ),
        .winter: SeasonAdjustment(
            scoreDelta: -2,  // Mùa đông = năng lượng thấp hơn, hạn chế di chuyển
            categoryOverrides: [.travel: .caution, .study: .favorable]
        ),
    ]

    // MARK: - Public API

    /// Tạo `VietnameseDayGuidance` từ Hành ngày và Tiết khí hiện tại.
    ///
    /// **Luồng xử lý:**
    /// 1. Lấy template theo Hành ngày (Mộc/Hỏa/Thổ/Kim/Thủy)
    /// 2. Lấy điều chỉnh theo Mùa (xuân/hạ/thu/đông)
    /// 3. Tính điểm cuối = clamp(baseScore + scoreDelta, 0, 100)
    /// 4. Map điểm → Rating (Excellent / Positive / Balanced / Caution)
    /// 5. Tạo ActivityInsights: 5 lĩnh vực, season override ưu tiên hơn template base
    ///
    /// **Ví dụ:**
    /// - Ngày hành Mộc (score 76) + Mùa xuân (+4) → score 80 → Rating: **Excellent**
    /// - Ngày hành Kim (score 71) + Mùa đông (-2) → score 69 → Rating: **Balanced**
    static func guidance(dayElement: String, solarTerm: String) -> VietnameseDayGuidance {
        let template = templatesByElement[dayElement] ?? fallbackTemplate
        let season = season(for: solarTerm)
        let seasonAdjustment = seasonAdjustments[season] ?? SeasonAdjustment(scoreDelta: 0, categoryOverrides: [:])
        let seasonalHint = seasonalHint(for: solarTerm)
        let summary = "\(template.summary) \(seasonalHint)"
        let score = min(max(template.baseScore + seasonAdjustment.scoreDelta, 0), 100)
        let rating = rating(for: score)
        let activityInsights = buildActivityInsights(template: template, season: season, seasonAdjustment: seasonAdjustment)

        return VietnameseDayGuidance(
            title: template.title,
            summary: summary,
            score: score,
            rating: rating,
            recommendedActivities: template.recommendedActivities,
            avoidActivities: template.avoidActivities,
            activityInsights: activityInsights
        )
    }

    // MARK: - Private Helpers

    /// Map điểm số → Rating:
    /// - 80+:    Excellent (rất tốt)
    /// - 70–79:  Positive  (tốt)
    /// - 55–69:  Balanced  (trung bình)
    /// - <55:    Caution   (cần thận trọng)
    private static func rating(for score: Int) -> VietnameseDayRating {
        switch score {
        case 80...: return .excellent
        case 70...79: return .positive
        case 55...69: return .balanced
        default: return .caution
        }
    }

    /// Xây dựng danh sách `ActivityInsight` cho 5 lĩnh vực.
    /// Level cuối cho mỗi lĩnh vực: Season override (nếu có) > Template base > neutral
    private static func buildActivityInsights(
        template: GuidanceTemplate,
        season: Season,
        seasonAdjustment: SeasonAdjustment
    ) -> [VietnameseActivityInsight] {
        VietnameseActivityCategory.allCases.map { category in
            let level = seasonAdjustment.categoryOverrides[category]
                ?? template.categoryLevels[category]
                ?? .neutral
            return VietnameseActivityInsight(
                category: category,
                level: level,
                reason: reason(for: category, level: level, season: season)
            )
        }
    }

    /// Tạo chuỗi lý giải ngắn gọn cho từng cặp (lĩnh vực, mức độ),
    /// kèm thêm ghi chú mùa phù hợp nếu có.
    private static func reason(
        for category: VietnameseActivityCategory,
        level: VietnameseGuidanceLevel,
        season: Season
    ) -> String {
        let base: String
        switch (category, level) {
        case (.work, .favorable):   base = "Dễ tạo tiến độ nếu có kế hoạch rõ và ưu tiên đúng việc."
        case (.work, .neutral):     base = "Nên giữ nhịp ổn định, tránh đổi hướng đột ngột."
        case (.work, .caution):     base = "Nên hạn chế quyết định nóng và xung đột không cần thiết."
        case (.finance, .favorable): base = "Phù hợp rà soát ngân sách, chốt khoản mục quan trọng."
        case (.finance, .neutral):  base = "Giữ nguyên kế hoạch chi tiêu, ưu tiên kiểm soát rủi ro."
        case (.finance, .caution):  base = "Tránh đầu tư cảm tính hoặc cam kết tài chính lớn."
        case (.study, .favorable):  base = "Dễ hấp thụ kiến thức mới và hoàn thành phần việc trí tuệ."
        case (.study, .neutral):    base = "Phù hợp ôn tập và hệ thống lại kiến thức hiện có."
        case (.study, .caution):    base = "Tránh học dàn trải, nên tập trung một trọng tâm."
        case (.travel, .favorable): base = "Thuận cho di chuyển, gặp gỡ và kết nối bên ngoài."
        case (.travel, .neutral):   base = "Di chuyển bình thường, nên chuẩn bị lịch trình trước."
        case (.travel, .caution):   base = "Ưu tiên an toàn và hạn chế lịch trình dày đặc."
        case (.family, .favorable): base = "Phù hợp tăng tương tác, hàn gắn và chăm sóc gia đạo."
        case (.family, .neutral):   base = "Nên duy trì giao tiếp nhẹ nhàng, tránh hiểu lầm nhỏ."
        case (.family, .caution):   base = "Tránh tranh luận gay gắt, ưu tiên lắng nghe."
        }

        // Ghi chú mùa bổ sung cho một số cặp đặc biệt
        let seasonalTail: String
        switch (season, category) {
        case (.summer, .travel):        seasonalTail = " Mùa hạ nên chú ý sức khỏe và thời gian nghỉ."
        case (.winter, .travel):        seasonalTail = " Mùa đông cần chừa thêm biên độ thời gian khi đi lại."
        case (.autumn, .finance):       seasonalTail = " Mùa thu hợp chốt kế hoạch tài chính ngắn hạn."
        case (.spring, .work),
             (.spring, .study):        seasonalTail = " Mùa xuân thuận để khởi tạo nhịp mới."
        default:                        seasonalTail = ""
        }

        return base + seasonalTail
    }

    /// Gợi ý ngắn theo mùa để ghép vào cuối summary
    private static func seasonalHint(for solarTerm: String) -> String {
        switch season(for: solarTerm) {
        case .spring: return "Mùa xuân nên ưu tiên khởi động việc mới và tạo đà tăng trưởng."
        case .summer: return "Mùa hạ hợp đẩy tiến độ, nhưng cần quản trị nhịp làm việc để tránh quá tải."
        case .autumn: return "Mùa thu phù hợp tối ưu chất lượng, chốt mục tiêu và củng cố kết quả."
        case .winter: return "Mùa đông hợp rà soát, chuẩn bị nguồn lực và xây nền cho chu kỳ kế tiếp."
        }
    }

    /// Ánh xạ tên Tiết khí → Mùa. Default case = Mùa đông (Lập đông, Tiểu/Đại tuyết, Đông chí, Tiểu/Đại hàn)
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
