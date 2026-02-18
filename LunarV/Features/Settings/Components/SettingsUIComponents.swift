//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import AppKit
import SwiftUI


enum SettingsPane: String, CaseIterable, Identifiable {
    case appearance
    case panel
    case notifications
    case updates
    case system
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .appearance:
            return "Giao diện"
        case .panel:
            return "Bảng điều khiển"
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
            return "Sắp xếp card"
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
                "sự kiện sắp tới", "lịch tháng", "chuyển đổi nhanh", "thông tin khác"
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
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(Color.primary.opacity(colorScheme == .dark ? 0.18 : 0.1), lineWidth: 1)
                    )

                Image(systemName: pane.icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }
            .frame(width: 24, height: 24)

            Text(pane.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
        .help(pane.subtitle)
    }
}

struct LunarSettingsStatusPill: View {
    let text: String
    var color: Color = .accentColor
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(color.opacity(colorScheme == .dark ? 0.24 : 0.12))
            )
            .overlay(
                Capsule()
                    .stroke(color.opacity(colorScheme == .dark ? 0.45 : 0.3), lineWidth: 1)
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
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.primary.opacity(colorScheme == .dark ? 0.2 : 0.08), lineWidth: 1)
                    )

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(accent)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
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
        .padding(12)
        .frame(maxWidth: 760)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor).opacity(colorScheme == .dark ? 0.78 : 0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    accent.opacity(colorScheme == .light ? 0.14 : 0.2),
                                    accent.opacity(0.04),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.primary.opacity(colorScheme == .dark ? 0.22 : 0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.28 : 0.12), radius: 8, x: 0, y: 4)
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
                    Circle()
                        .fill(Color.accentColor.opacity(0.12))
                        .frame(width: 24, height: 24)

                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)

                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)

                trailing
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.primary.opacity(colorScheme == .dark ? 0.06 : 0.03))

            Divider()
                .opacity(0.5)

            content
                .padding(12)
        }
        .frame(maxWidth: 760)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor).opacity(colorScheme == .dark ? 0.78 : 0.95))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.primary.opacity(colorScheme == .dark ? 0.22 : 0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.1), radius: 8, x: 0, y: 4)
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
    let card: PanelCardKind
    @Binding var isVisible: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 10) {
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
            }

            Spacer()

            Toggle("", isOn: $isVisible)
                .labelsHidden()
                .lunarSettingsSwitchToggle()
                .frame(width: 40, alignment: .trailing)
                .help(isVisible ? "Đang hiển thị" : "Đang ẩn")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor).opacity(colorScheme == .dark ? 0.72 : 0.96))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.primary.opacity(colorScheme == .dark ? 0.2 : 0.08), lineWidth: 1)
        )
    }
}

struct PanelCardHintChip: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            Text(text)
                .font(.caption2.weight(.medium))
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.primary.opacity(0.06), in: Capsule())
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
        DisplayToken(code: "{wd}", label: "Thứ đầy đủ", color: .mint),
        DisplayToken(code: "{wds}", label: "Thứ ngắn", color: .mint),
        DisplayToken(code: "{hh}", label: "Giờ (00-23)", color: .mint),
        DisplayToken(code: "{min}", label: "Phút (00)", color: .mint),
        DisplayToken(code: "{ss}", label: "Giây (00)", color: .mint),
        DisplayToken(code: "{time}", label: "Giờ đầy đủ", color: .mint),
    ]

    static let otherTokens = [
        DisplayToken(code: "{al}", label: "Chữ 'ÂL'", color: .secondary),
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
                    HStack(spacing: 4) {
                        Text(token.code)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                        Text(token.label)
                            .font(.system(size: 9))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(token.color.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(token.color.opacity(0.2), lineWidth: 1)
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
