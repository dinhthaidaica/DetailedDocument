//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import AppKit
import SwiftUI


enum SettingsPane: String, CaseIterable, Identifiable, Hashable {
    case appearance
    case panel
    case worldClock
    case notifications
    case updates
    case system
    case about

    static let defaultOrder: [SettingsPane] = [
        .appearance,
        .panel,
        .worldClock,
        .notifications,
        .updates,
        .system,
        .about,
    ]

    var id: String { rawValue }

    var title: String {
        switch self {
        case .appearance:
            return "Giao diện"
        case .panel:
            return "Bảng điều khiển"
        case .worldClock:
            return "Giờ quốc tế"
        case .notifications:
            return "Thông báo"
        case .updates:
            return "Cập nhật"
        case .system:
            return "Hệ thống"
        case .about:
            return "Thông tin"
        }
    }

    var subtitle: String {
        switch self {
        case .appearance:
            return "Menu Bar và kiểu chữ"
        case .panel:
            return "Card, thứ tự và kích thước"
        case .worldClock:
            return "Múi giờ và thành phố theo dõi"
        case .notifications:
            return "Nhắc ngày lễ âm lịch"
        case .updates:
            return "Kiểm tra phiên bản mới"
        case .system:
            return "Cửa sổ, khởi động & dữ liệu"
        case .about:
            return "Phiên bản và hỗ trợ"
        }
    }

    var icon: String {
        switch self {
        case .appearance:
            return "paintbrush.fill"
        case .panel:
            return "list.bullet.indent"
        case .worldClock:
            return "globe.americas.fill"
        case .notifications:
            return "bell.badge.fill"
        case .updates:
            return "arrow.down.circle.fill"
        case .system:
            return "gearshape.2.fill"
        case .about:
            return "info.circle.fill"
        }
    }

    /// Các từ khoá tìm kiếm mở rộng cho từng tab
    var searchKeywords: [String] {
        switch self {
        case .appearance:
            return [
                "menu bar", "kiểu hiển thị", "chế độ", "preset", "compact", "full", "custom",
                "mẫu tuỳ chỉnh", "template", "token", "xem trước", "preview",
                "font", "phông chữ", "cỡ chữ", "kích cỡ chữ", "đậm", "nghiêng", "gạch chân",
                "bold", "italic", "underline", "icon", "biểu tượng", "icon bên trái",
                "thứ", "giờ", "phút", "giây", "time", "weekday"
            ]
        case .panel:
            return [
                "card", "thành phần", "thứ tự", "sắp xếp", "ẩn hiện", "hiển thị", "list", "kéo thả",
                "hero", "can chi", "con giáp", "giờ hoàng đạo", "gợi ý trong ngày",
                "sự kiện sắp tới", "lịch tháng",
                "kích thước", "size", "panel size", "popup size", "chiều rộng", "chiều cao", "width", "height",
                "chuyển đổi nhanh", "thông tin khác"
            ]
        case .worldClock:
            return [
                "giờ quốc tế", "world clock", "timezone", "múi giờ", "thành phố", "utc",
                "smart", "gợi ý", "thông minh", "thêm múi giờ", "ẩn múi giờ", "so sánh giờ",
                "tokyo", "london", "new york", "los angeles", "sydney"
            ]
        case .notifications:
            return [
                "thông báo", "nhắc", "nhắc lễ", "holiday", "permission", "authorization", "quyền",
                "nhắc trước", "giờ thông báo", "phạm vi lập lịch", "window days", "lead day",
                "đúng ngày", "trước 1 ngày", "trước 3 ngày", "bell"
            ]
        case .updates:
            return [
                "cập nhật", "update", "sparkle", "phiên bản mới", "release", "github",
                "check for updates", "kiểm tra ngay", "tự động kiểm tra", "tần suất",
                "mỗi 1 giờ", "mỗi 6 giờ", "mỗi 12 giờ", "mỗi ngày", "mỗi tuần"
            ]
        case .system:
            return [
                "hệ thống", "window", "floating", "always on top", "cửa sổ cài đặt",
                "khởi động", "đăng nhập", "launch at login", "tự động",
                "dữ liệu", "thời gian", "múi giờ", "timezone", "thuật toán", "algorithm",
                "khôi phục", "reset", "mặc định"
            ]
        case .about:
            return [
                "thông tin", "phiên bản", "version", "lunarv", "tác giả",
                "ủng hộ", "donate", "qr", "info"
            ]
        }
    }
}

// MARK: - Settings UI Components

struct LunarSettingsSidebarRow: View {
    let pane: SettingsPane
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.accentColor.opacity(colorScheme == .dark ? 0.28 : 0.18),
                                Color.accentColor.opacity(colorScheme == .dark ? 0.14 : 0.08),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Image(systemName: pane.icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }
            .frame(width: 26, height: 26)

            VStack(alignment: .leading, spacing: 1) {
                Text(pane.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(pane.subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 3)
        .help(pane.subtitle)
    }
}

struct LunarSettingsStatusPill: View {
    let text: String
    var color: Color = .accentColor
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 5, height: 5)

            Text(text)
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(color.opacity(colorScheme == .dark ? 0.18 : 0.1))
        )
        .foregroundStyle(color)
    }
}

struct LunarSettingsHeader<Trailing: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    var accent: Color = .accentColor
    let trailing: Trailing

    @Environment(\.colorScheme) private var colorScheme

    init(
        title: String,
        subtitle: String,
        icon: String,
        accent: Color = .accentColor,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.accent = accent
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                accent.opacity(colorScheme == .dark ? 0.32 : 0.2),
                                accent.opacity(colorScheme == .dark ? 0.16 : 0.08),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(accent)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            trailing
        }
        .padding(14)
        .frame(maxWidth: 760)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor).opacity(colorScheme == .dark ? 0.78 : 0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    accent.opacity(colorScheme == .light ? 0.12 : 0.18),
                                    accent.opacity(0.02),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(accent.opacity(colorScheme == .dark ? 0.2 : 0.12), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.22 : 0.08), radius: 10, x: 0, y: 4)
    }
}

struct LunarSettingsCard<Content: View, Trailing: View>: View {
    let title: String
    let subtitle: String?
    let icon: String
    let trailing: Trailing
    let content: Content

    @Environment(\.colorScheme) private var colorScheme

    init(
        title: String,
        subtitle: String? = nil,
        icon: String,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() },
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.trailing = trailing()
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.accentColor.opacity(colorScheme == .dark ? 0.24 : 0.16),
                                    Color.accentColor.opacity(colorScheme == .dark ? 0.12 : 0.06),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 26, height: 26)

                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.primary)

                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)

                trailing
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(Color.primary.opacity(colorScheme == .dark ? 0.05 : 0.025))

            Divider()
                .opacity(0.4)

            content
                .padding(14)
        }
        .frame(maxWidth: 760)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor).opacity(colorScheme == .dark ? 0.78 : 0.95))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.primary.opacity(colorScheme == .dark ? 0.18 : 0.1), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.06), radius: 8, x: 0, y: 3)
    }
}

struct LunarSettingsBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(NSColor.windowBackgroundColor).opacity(colorScheme == .light ? 0.98 : 1.0),
                            Color(NSColor.controlBackgroundColor).opacity(colorScheme == .light ? 0.96 : 1.0),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    RadialGradient(
                        colors: [
                            Color.accentColor.opacity(colorScheme == .light ? 0.06 : 0.12),
                            Color.clear,
                        ],
                        center: .topLeading,
                        startRadius: 24,
                        endRadius: 540
                    )
                }
                .ignoresSafeArea()
            )
    }
}

extension View {
    func lunarSettingsBackground() -> some View {
        modifier(LunarSettingsBackgroundModifier())
    }

    func lunarSettingsSwitchToggle() -> some View {
        toggleStyle(.switch)
            .tint(Color(nsColor: .controlAccentColor))
    }
}

// MARK: - Token Components

struct PanelCardOrderRow: View {
    let index: Int
    let card: PanelCardKind
    @Binding var isVisible: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            orderIndicator
            cardTextBlock
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(0)
            visibilityStatusBlock
                .frame(width: 68, alignment: .trailing)
                .layoutPriority(1)
            trailingVisibilityControl
                .frame(width: 48, alignment: .trailing)
                .layoutPriority(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(rowBackgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(rowBorderColor, lineWidth: 1)
        )
        .opacity(isVisible ? 1 : 0.88)
        .help("Kéo-thả để đổi thứ tự. Thứ tự này sẽ hiển thị đúng trong menu bar.")
    }

    private var orderIndicator: some View {
        VStack(spacing: 3) {
            Text("\(index + 1)")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(width: 22, height: 22)
                .background(Color.primary.opacity(0.06), in: Circle())

            Image(systemName: "line.3.horizontal")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.secondary.opacity(0.6))
        }
        .frame(width: 26)
        .help("Kéo để đổi vị trí")
    }

    private var cardTextBlock: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 22, height: 22)

                Image(systemName: card.icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(card.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.primary)

                Text(card.subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
    }

    private var visibilityStatusBlock: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(isVisible ? "Đang bật" : "Đang ẩn")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(visibilityStatusColor)
            Text("Thành phần")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }

    private var trailingVisibilityControl: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Toggle("", isOn: $isVisible)
                .labelsHidden()
                .lunarSettingsSwitchToggle()
                .controlSize(.small)
                .frame(width: 48, alignment: .trailing)
                .fixedSize(horizontal: true, vertical: false)
                .help(isVisible ? "Đang hiển thị" : "Đang ẩn")
        }
    }

    private var visibilityStatusColor: Color {
        isVisible ? .secondary : .orange
    }

    private var rowBackgroundColor: Color {
        if isVisible {
            return Color(NSColor.controlBackgroundColor).opacity(colorScheme == .dark ? 0.72 : 0.96)
        }
        return Color.orange.opacity(colorScheme == .dark ? 0.1 : 0.06)
    }

    private var rowBorderColor: Color {
        if isVisible {
            return Color.primary.opacity(colorScheme == .dark ? 0.2 : 0.08)
        }
        return Color.orange.opacity(colorScheme == .dark ? 0.4 : 0.25)
    }
}

struct PanelCardHintChip: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold))
            Text(text)
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.primary.opacity(0.05), in: Capsule())
    }
}

struct MenuBarFontPickerRow: View {
    let title: String
    let subtitle: String
    let previewFontName: String?
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(previewFont)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        isSelected
                            ? Color.accentColor.opacity(colorScheme == .dark ? 0.2 : 0.1)
                            : Color.primary.opacity(colorScheme == .dark ? 0.1 : 0.04)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(
                        isSelected
                            ? Color.accentColor.opacity(colorScheme == .dark ? 0.45 : 0.28)
                            : Color.primary.opacity(colorScheme == .dark ? 0.16 : 0.08),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var previewFont: Font {
        guard let previewFontName else {
            return .system(size: 12, weight: .semibold)
        }
        return .custom(previewFontName, size: 12)
    }
}

struct MenuBarTextStyleButton: View {
    let title: String
    let symbol: String
    @Binding var isEnabled: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button {
            isEnabled.toggle()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 10, weight: .semibold))
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(isEnabled ? Color.accentColor : .secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        isEnabled
                            ? Color.accentColor.opacity(colorScheme == .dark ? 0.24 : 0.12)
                            : Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.05)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(
                        isEnabled
                            ? Color.accentColor.opacity(colorScheme == .dark ? 0.5 : 0.32)
                            : Color.primary.opacity(colorScheme == .dark ? 0.18 : 0.1),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct DisplayToken: Identifiable {
    let id = UUID()
    let code: String
    let label: String
    let color: Color

    static let lunarTokens = [
        DisplayToken(code: "{d}", label: "Ngày AL", color: .orange),
        DisplayToken(code: "{dd}", label: "Ngày AL (01)", color: .orange),
        DisplayToken(code: "{m}", label: "Tháng AL", color: .orange),
        DisplayToken(code: "{mm}", label: "Tháng AL (01)", color: .orange),
        DisplayToken(code: "{cy}", label: "Năm Can Chi", color: .orange),
        DisplayToken(code: "{z}", label: "Con Giáp", color: .orange),
        DisplayToken(code: "{leap}", label: "Nhuận", color: .orange),
    ]

    static let solarTokens = [
        DisplayToken(code: "{sd}", label: "Ngày DL", color: .blue),
        DisplayToken(code: "{sdd}", label: "Ngày DL (01)", color: .blue),
        DisplayToken(code: "{sm}", label: "Tháng DL", color: .blue),
        DisplayToken(code: "{smm}", label: "Tháng DL (01)", color: .blue),
        DisplayToken(code: "{sy}", label: "Năm DL", color: .blue),
    ]

    static let timeTokens = [
        DisplayToken(code: "{wd}", label: "Thứ đầy đủ (Thứ Hai)", color: .mint),
        DisplayToken(code: "{wds}", label: "Thứ ngắn (T2)", color: .mint),
        DisplayToken(code: "{wdn}", label: "Thứ số chuẩn (1-7)", color: .mint),
        DisplayToken(code: "{wdn2}", label: "Thứ số mở rộng (2-8)", color: .mint),
        DisplayToken(code: "{h12}", label: "Giờ 12h (1-12)", color: .mint),
        DisplayToken(code: "{hh12}", label: "Giờ 12h (01-12)", color: .mint),
        DisplayToken(code: "{ampm}", label: "AM/PM (in hoa)", color: .mint),
        DisplayToken(code: "{ampml}", label: "am/pm (in thường)", color: .mint),
        DisplayToken(code: "{ampmvn}", label: "SA/CH (tiếng Việt)", color: .mint),
        DisplayToken(code: "{ap}", label: "A/P (1 ký tự)", color: .mint),
        DisplayToken(code: "{time12m}", label: "Giờ 12h (không giây)", color: .mint),
        DisplayToken(code: "{time12}", label: "Giờ 12h (đầy đủ)", color: .mint),
        DisplayToken(code: "{hh}", label: "Giờ (00-23)", color: .mint),
        DisplayToken(code: "{min}", label: "Phút (00)", color: .mint),
        DisplayToken(code: "{ss}", label: "Giây (00)", color: .mint),
        DisplayToken(code: "{time}", label: "Giờ đầy đủ", color: .mint),
    ]

    static let otherTokens = [
        DisplayToken(code: "{al}", label: "Chữ 'ÂL'", color: .secondary),
        DisplayToken(code: "{:}", label: "Dấu : nhấp nháy mỗi giây", color: .secondary),
        DisplayToken(code: "•", label: "Dấu chấm", color: .secondary),
        DisplayToken(code: ":", label: "Dấu hai chấm", color: .secondary),
        DisplayToken(code: "/", label: "Gạch chéo", color: .secondary),
        DisplayToken(code: "-", label: "Gạch ngang", color: .secondary),
    ]
}

struct TokenFlowLayout: View {
    let tokens: [DisplayToken]
    let action: (DisplayToken) -> Void

    var body: some View {
        FlowLayout(alignment: .leading, spacing: 6) {
            ForEach(tokens) { token in
                Button(action: { action(token) }) {
                    HStack(spacing: 5) {
                        Text(token.code)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(token.color)
                        Text(token.label)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.primary.opacity(0.7))
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(token.color.opacity(0.08), in: RoundedRectangle(cornerRadius: 7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(token.color.opacity(0.15), lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Simple Flow Layout

struct FlowLayout: Layout {
    var alignment: Alignment = .center
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            var point = result.offsets[index]
            point.x += bounds.minX
            point.y += bounds.minY
            subview.place(at: point, proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, offsets: [CGPoint]) {
        var offsets: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxLineWidth: CGFloat = 0
        let maxWidth = proposal.width ?? .greatestFiniteMagnitude

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                maxLineWidth = max(maxLineWidth, currentX - spacing)
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            offsets.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }

        maxLineWidth = max(maxLineWidth, max(0, currentX - spacing))
        let totalHeight = offsets.isEmpty ? 0 : currentY + lineHeight
        let fittedWidth = proposal.width ?? maxLineWidth

        return (CGSize(width: fittedWidth, height: totalHeight), offsets)
    }
}
