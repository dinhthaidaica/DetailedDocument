import AppKit
import SwiftUI

struct LunarMenuBarView: View {
    @Environment(\.controlActiveState) private var controlActiveState
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @State private var isHeroHovered = false
    @ObservedObject var viewModel: LunarMenuBarViewModel

    private let calendarColumns = Array(
        repeating: GridItem(.flexible(minimum: MenuBarMetrics.calendarMinimumCellWidth), spacing: MenuBarMetrics.calendarGridSpacing),
        count: 7
    )
    private let weekdayHeaders = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"]

    var body: some View {
        ZStack {
            NativePanelBackground()
            LinearGradient(
                colors: [
                    Color.accentColor.opacity(controlActiveState == .active ? 0.06 : 0.02),
                    Color.clear,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                topToolbar
                    .padding(.horizontal, MenuBarMetrics.panelPadding)
                    .padding(.top, MenuBarMetrics.panelPadding)
                    .padding(.bottom, 8)

                ScrollView {
                    VStack(spacing: MenuBarMetrics.verticalStackSpacing) {
                        heroCard
                        canChiCard
                        detailCard
                        monthCalendarCard
                    }
                    .padding(.horizontal, MenuBarMetrics.panelPadding)
                    .padding(.bottom, MenuBarMetrics.panelPadding)
                }
            }
        }
        .scrollIndicators(.hidden)
        .frame(width: MenuBarMetrics.panelSize.width, height: MenuBarMetrics.panelSize.height)
    }

    private var topToolbar: some View {
        HStack(spacing: 10) {
            Button {
                confirmExit()
            } label: {
                toolbarIcon(systemName: "power")
                    .foregroundStyle(.red.opacity(controlActiveState == .active ? 0.85 : 0.65))
            }
            .buttonStyle(.plain)
            .help("Thoát ứng dụng")
            .accessibilityLabel("Thoát ứng dụng")

            VStack(alignment: .leading, spacing: 1) {
                Text("LunarV")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text("Lịch âm tự động cập nhật")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            SettingsLink {
                toolbarIcon(systemName: "gearshape")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Mở cài đặt")
            .accessibilityLabel("Mở cài đặt")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    reduceTransparency
                        ? AnyShapeStyle(Color(nsColor: .windowBackgroundColor))
                        : AnyShapeStyle(.ultraThinMaterial)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(nsColor: .separatorColor).opacity(0.35), lineWidth: 1)
        )
    }

    private var heroCard: some View {
        let info = viewModel.info
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: MenuBarMetrics.heroColumnSpacing) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Hôm nay")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(info.weekdayText)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text(info.solarDateText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Âm lịch: \(info.lunarDateText)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    if let leapMonthText = info.leapMonthText {
                        Text(leapMonthText.uppercased())
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.primary.opacity(0.10), in: Capsule())
                            .foregroundStyle(.primary)
                    }
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Ngày âm")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text(info.lunarDayText)
                        .font(.system(size: 46, weight: .heavy, design: .rounded))
                        .foregroundStyle(.primary)
                    Text(info.lunarMonthYearText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                }
            }

            HStack(spacing: 8) {
                HeroChip(icon: "sun.max.fill", title: "Tiết khí", value: info.solarTermText)
                HeroChip(icon: "hare.fill", title: "Con giáp", value: info.zodiacText)
            }
        }
        .padding(MenuBarMetrics.heroPadding)
        .background(
            RoundedRectangle(cornerRadius: MenuBarMetrics.heroCornerRadius, style: .continuous)
                .fill(
                    reduceTransparency
                        ? AnyShapeStyle(Color(nsColor: .windowBackgroundColor))
                        : AnyShapeStyle(.thinMaterial)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: MenuBarMetrics.heroCornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: heroTintColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: MenuBarMetrics.heroCornerRadius, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: MenuBarMetrics.heroCornerRadius, style: .continuous)
                .stroke(Color(nsColor: .separatorColor).opacity(0.5), lineWidth: 1)
        )
        .shadow(
            color: heroShadowColor,
            radius: isHeroHovered && controlActiveState == .active ? 12 : 0,
            x: 0,
            y: isHeroHovered && controlActiveState == .active ? 4 : 0
        )
        .contentShape(RoundedRectangle(cornerRadius: MenuBarMetrics.heroCornerRadius, style: .continuous))
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.16)) {
                isHeroHovered = hovering
            }
        }
    }

    private var canChiCard: some View {
        let info = viewModel.info

        return SectionCard(title: "Can chi") {
            HStack(spacing: MenuBarMetrics.elementSpacing) {
                CanChiPill(title: "Ngày", value: info.canChiDayText)
                CanChiPill(title: "Tháng", value: info.canChiMonthText)
                CanChiPill(title: "Năm", value: info.canChiYearText)
            }
        }
    }

    private var detailCard: some View {
        let info = viewModel.info

        return SectionCard(title: "Thông tin vạn niên") {
            VStack(spacing: MenuBarMetrics.elementSpacing) {
                InfoRow(icon: "clock", label: "Giờ can chi", value: info.currentHourCanChiText)
                InfoRow(icon: "calendar.badge.clock", label: "Ngày âm", value: info.lunarDateText)
                HStack(spacing: MenuBarMetrics.elementSpacing) {
                    StatTile(title: "Tuần", value: info.weekOfYearText)
                    StatTile(title: "Trong năm", value: info.dayOfYearText)
                }
            }
        }
    }

    private var monthCalendarCard: some View {
        let info = viewModel.info

        return SectionCard(title: "Lịch tháng", trailingText: info.monthTitleText) {
            VStack(spacing: MenuBarMetrics.calendarGridSpacing) {
                Text("Số lớn: dương lịch • Số nhỏ: âm lịch • Chấm vàng: mùng 1 âm")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: MenuBarMetrics.calendarGridSpacing) {
                    ForEach(weekdayHeaders, id: \.self) { weekday in
                        Text(weekday)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(weekday == "T7" || weekday == "CN" ? Color(nsColor: .systemRed).opacity(0.85) : Color.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }

                LazyVGrid(columns: calendarColumns, spacing: MenuBarMetrics.calendarGridSpacing) {
                    ForEach(Array(info.monthCells.enumerated()), id: \.element.id) { index, cell in
                        MonthDayCellView(cell: cell, weekdayIndex: index % 7)
                    }
                }
            }
        }
    }

    private var heroTintColors: [Color] {
        let hoverBoost = isHeroHovered && controlActiveState == .active ? 1.25 : 1.0

        if controlActiveState == .active {
            return [
                Color.accentColor.opacity(0.20 * hoverBoost),
                Color.accentColor.opacity(0.10 * hoverBoost),
            ]
        }

        return [
            Color(nsColor: .tertiaryLabelColor).opacity(0.10),
            Color(nsColor: .quaternaryLabelColor).opacity(0.08),
        ]
    }

    private var heroShadowColor: Color {
        if controlActiveState == .active {
            return Color.accentColor.opacity(0.16)
        }
        return .clear
    }

    @ViewBuilder
    private func toolbarIcon(systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 12, weight: .semibold))
            .frame(width: 28, height: 24)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        reduceTransparency
                            ? AnyShapeStyle(Color(nsColor: .windowBackgroundColor))
                            : AnyShapeStyle(.regularMaterial)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color(nsColor: .separatorColor).opacity(0.35), lineWidth: 1)
            )
    }

    private func confirmExit() {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Thoát LunarV?"
        alert.informativeText = "LunarV sẽ dừng chạy và biến mất khỏi menu bar."
        alert.addButton(withTitle: "Thoát ứng dụng")
        alert.addButton(withTitle: "Huỷ")

        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            NSApp.terminate(nil)
        }
    }
}

private struct SectionCard<Content: View>: View {
    @Environment(\.controlActiveState) private var controlActiveState
    @State private var isHovered = false

    let title: String
    var trailingText: String? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: MenuBarMetrics.sectionContentSpacing) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Spacer()
                if let trailingText {
                    Text(trailingText)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }

            content
        }
        .padding(MenuBarMetrics.sectionPadding)
        .background(
            RoundedRectangle(cornerRadius: MenuBarMetrics.sectionCornerRadius, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MenuBarMetrics.sectionCornerRadius, style: .continuous)
                .stroke(sectionBorderColor, lineWidth: 1)
        )
        .shadow(
            color: sectionShadowColor,
            radius: isHovered && controlActiveState == .active ? 10 : 0,
            x: 0,
            y: isHovered && controlActiveState == .active ? 3 : 0
        )
        .scaleEffect(isHovered && controlActiveState == .active ? 1.003 : 1.0)
        .contentShape(RoundedRectangle(cornerRadius: MenuBarMetrics.sectionCornerRadius, style: .continuous))
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.14)) {
                isHovered = hovering
            }
        }
    }

    private var sectionBorderColor: Color {
        if isHovered && controlActiveState == .active {
            return Color.accentColor.opacity(0.35)
        }
        return Color(nsColor: .separatorColor).opacity(0.45)
    }

    private var sectionShadowColor: Color {
        if controlActiveState == .active {
            return Color.black.opacity(0.14)
        }
        return .clear
    }
}

private struct CanChiPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, minHeight: 56)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.thinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color(nsColor: .separatorColor).opacity(0.25), lineWidth: 1)
        )
    }
}

private struct InfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.tint)
                .frame(width: 22, height: 22)
                .background(
                    Circle()
                        .fill(Color(nsColor: .controlBackgroundColor))
                )
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
        }
    }
}

private struct StatTile: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.thinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color(nsColor: .separatorColor).opacity(0.2), lineWidth: 1)
        )
    }
}

private struct MonthDayCellView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    let cell: LunarMonthDayCell
    let weekdayIndex: Int

    var body: some View {
        Group {
            if let solarDay = cell.solarDay, let lunarDay = cell.lunarDay {
                VStack(spacing: 1) {
                    Text("\(solarDay)")
                        .font(.system(size: 12, weight: cell.isToday ? .bold : .semibold, design: .rounded))
                        .foregroundStyle(solarTextColor)
                    Text("\(lunarDay)")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(lunarTextColor)
                }
                .frame(maxWidth: .infinity, minHeight: 36)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(backgroundColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(borderColor, lineWidth: cell.isToday ? 1.5 : 1)
                )
                .overlay(alignment: .topTrailing) {
                    if cell.isFirstLunarDay {
                        Circle()
                            .fill(Color(red: 0.88, green: 0.55, blue: 0.22))
                            .frame(width: 5, height: 5)
                            .padding(4)
                    }
                }
            } else {
                Color.clear
                    .frame(maxWidth: .infinity, minHeight: 36)
            }
        }
    }

    private var backgroundColor: Color {
        if cell.isToday {
            return Color.accentColor.opacity(colorScheme == .dark ? 0.34 : 0.22)
        }
        if reduceTransparency {
            return Color(nsColor: .windowBackgroundColor)
        }
        return Color.primary.opacity(colorScheme == .dark ? 0.10 : 0.05)
    }

    private var borderColor: Color {
        if cell.isToday {
            return Color.accentColor.opacity(0.8)
        }
        return Color(nsColor: .separatorColor).opacity(0.45)
    }

    private var solarTextColor: Color {
        if cell.isToday {
            return .primary
        }
        if isWeekend {
            return Color(nsColor: .systemRed).opacity(0.9)
        }
        return .primary
    }

    private var lunarTextColor: Color {
        if cell.isToday {
            return .primary
        }
        if isWeekend {
            return Color(nsColor: .systemRed).opacity(0.75)
        }
        return .secondary
    }

    private var isWeekend: Bool {
        weekdayIndex == 5 || weekdayIndex == 6
    }
}

#Preview {
    LunarMenuBarView(viewModel: LunarMenuBarViewModel())
}

private struct NativePanelBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.state = .followsWindowActiveState
        view.material = .menu
        view.blendingMode = .withinWindow
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.state = .followsWindowActiveState
        nsView.material = .menu
    }
}

private struct HeroChip: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundStyle(.primary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.thinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color(nsColor: .separatorColor).opacity(0.25), lineWidth: 1)
        )
    }
}

private enum MenuBarMetrics {
    static let panelSize = CGSize(width: 392, height: 576)

    static let panelPadding: CGFloat = 14
    static let verticalStackSpacing: CGFloat = 12
    static let elementSpacing: CGFloat = 8
    static let calendarGridSpacing: CGFloat = 6
    static let calendarMinimumCellWidth: CGFloat = 30

    static let heroCornerRadius: CGFloat = 18
    static let heroPadding: CGFloat = 14
    static let heroColumnSpacing: CGFloat = 12

    static let sectionCornerRadius: CGFloat = 14
    static let sectionPadding: CGFloat = 12
    static let sectionContentSpacing: CGFloat = 10
}
