import AppKit
import SwiftUI

struct LunarMenuBarView: View {
    @Environment(\.controlActiveState) private var controlActiveState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHeroHovered = false
    @State private var hasAppeared = false
    @ObservedObject var viewModel: LunarMenuBarViewModel

    private let calendarColumns = Array(
        repeating: GridItem(.flexible(minimum: MenuBarMetrics.calendarMinimumCellWidth), spacing: MenuBarMetrics.calendarGridSpacing),
        count: 7
    )
    private let weekdayHeaders = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.accentColor.opacity(controlActiveState == .active ? 0.03 : 0.01),
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
                    GlassEffectContainer(spacing: 16) {
                        VStack(spacing: MenuBarMetrics.verticalStackSpacing) {
                            heroCard
                                .entranceAnimation(hasAppeared: hasAppeared, reduceMotion: reduceMotion, delay: 0)

                            canChiCard
                                .entranceAnimation(hasAppeared: hasAppeared, reduceMotion: reduceMotion, delay: 0.05)

                            detailCard
                                .entranceAnimation(hasAppeared: hasAppeared, reduceMotion: reduceMotion, delay: 0.10)

                            monthCalendarCard
                                .entranceAnimation(hasAppeared: hasAppeared, reduceMotion: reduceMotion, delay: 0.15)
                        }
                        .padding(.horizontal, MenuBarMetrics.panelPadding)
                        .padding(.bottom, MenuBarMetrics.panelPadding)
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
        .frame(width: MenuBarMetrics.panelSize.width, height: MenuBarMetrics.panelSize.height)
        .task {
            guard !hasAppeared else { return }
            if reduceMotion {
                hasAppeared = true
            } else {
                try? await Task.sleep(for: .milliseconds(50))
                withAnimation {
                    hasAppeared = true
                }
            }
        }
        .onDisappear {
            hasAppeared = false
        }
    }

    // MARK: - Top Toolbar

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
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text("Lịch âm tự động cập nhật")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.tertiary)
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
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Hero Card

    private var heroCard: some View {
        let info = viewModel.info
        let tintOpacity = isHeroHovered && controlActiveState == .active ? 0.35 : 0.25
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: MenuBarMetrics.heroColumnSpacing) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("HÔM NAY")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.tertiary)
                        .tracking(1.2)
                    Text(info.weekdayText)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                    Text(info.solarDateText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                    Text("Âm lịch: \(info.lunarDateText)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
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
                    Text("NGÀY ÂM")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(.tertiary)
                        .tracking(1.0)
                    Text(info.lunarDayText)
                        .font(.system(size: 52, weight: .heavy, design: .rounded))
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText(countsDown: false))
                        .animation(.spring(duration: 0.4, bounce: 0.1), value: info.lunarDayText)
                    Text(info.lunarMonthYearText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                        .contentTransition(.numericText())
                }
            }

            HStack(spacing: 8) {
                HeroChip(icon: "sun.max.fill", title: "Tiết khí", value: info.solarTermText)
                HeroChip(icon: "hare.fill", title: "Con giáp", value: info.zodiacText)
            }
        }
        .padding(MenuBarMetrics.heroPadding)
        .glassEffect(
            .regular.tint(Color.accentColor.opacity(tintOpacity)),
            in: RoundedRectangle(cornerRadius: MenuBarMetrics.heroCornerRadius, style: .continuous)
        )
        .contentShape(RoundedRectangle(cornerRadius: MenuBarMetrics.heroCornerRadius, style: .continuous))
        .onHover { hovering in
            withAnimation(.spring(duration: 0.25, bounce: 0.15)) {
                isHeroHovered = hovering
            }
        }
    }

    // MARK: - Section Cards

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
                    .foregroundStyle(.quaternary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: MenuBarMetrics.calendarGridSpacing) {
                    ForEach(weekdayHeaders, id: \.self) { weekday in
                        Text(weekday)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(weekday == "T7" || weekday == "CN" ? Color(nsColor: .systemRed).opacity(0.85) : Color.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }

                Divider()
                    .opacity(0.4)

                LazyVGrid(columns: calendarColumns, spacing: MenuBarMetrics.calendarGridSpacing) {
                    ForEach(Array(info.monthCells.enumerated()), id: \.element.id) { index, cell in
                        MonthDayCellView(cell: cell, weekdayIndex: index % 7)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func toolbarIcon(systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 12, weight: .semibold))
            .frame(width: 28, height: 24)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
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

// MARK: - Entrance Animation Modifier

private struct EntranceAnimationModifier: ViewModifier {
    let hasAppeared: Bool
    let reduceMotion: Bool
    let delay: Double

    func body(content: Content) -> some View {
        content
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 8)
            .animation(
                reduceMotion ? .none : .spring(duration: 0.4, bounce: 0.1).delay(delay),
                value: hasAppeared
            )
    }
}

private extension View {
    func entranceAnimation(hasAppeared: Bool, reduceMotion: Bool, delay: Double) -> some View {
        modifier(EntranceAnimationModifier(hasAppeared: hasAppeared, reduceMotion: reduceMotion, delay: delay))
    }
}

// MARK: - SectionCard

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
                        .contentTransition(.numericText())
                }
            }

            content
        }
        .padding(MenuBarMetrics.sectionPadding)
        .glassEffect(
            isHovered && controlActiveState == .active
                ? .regular.tint(Color.accentColor.opacity(0.12))
                : .regular,
            in: RoundedRectangle(cornerRadius: MenuBarMetrics.sectionCornerRadius, style: .continuous)
        )
        .contentShape(RoundedRectangle(cornerRadius: MenuBarMetrics.sectionCornerRadius, style: .continuous))
        .onHover { hovering in
            withAnimation(.snappy(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - CanChiPill

private struct CanChiPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, minHeight: 56)
        .padding(.vertical, 8)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - InfoRow

private struct InfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.tint)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(Color.accentColor.opacity(0.08))
                )
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
        }
    }
}

// MARK: - StatTile

private struct StatTile: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - MonthDayCellView

private struct MonthDayCellView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovered = false
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
                        .stroke(borderColor, lineWidth: cell.isToday ? 1.5 : isHovered ? 1 : 0.5)
                )
                .overlay(alignment: .topTrailing) {
                    if cell.isFirstLunarDay {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 5, height: 5)
                            .padding(4)
                    }
                }
                .scaleEffect(isHovered && !cell.isToday ? 1.05 : 1.0)
                .onHover { hovering in
                    withAnimation(.snappy(duration: 0.15)) {
                        isHovered = hovering
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
            return Color.accentColor.opacity(colorScheme == .dark ? 0.30 : 0.20)
        }
        if isHovered {
            return Color.primary.opacity(colorScheme == .dark ? 0.14 : 0.08)
        }
        return Color.primary.opacity(colorScheme == .dark ? 0.06 : 0.03)
    }

    private var borderColor: Color {
        if cell.isToday {
            return Color.accentColor.opacity(0.8)
        }
        if isHovered {
            return Color.accentColor.opacity(0.4)
        }
        return Color(nsColor: .separatorColor).opacity(0.3)
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

// MARK: - HeroChip

private struct HeroChip: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.tertiary)
                Text(value)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - Preview

#Preview {
    LunarMenuBarView(viewModel: LunarMenuBarViewModel())
}

// MARK: - Metrics

private enum MenuBarMetrics {
    static let panelSize = CGSize(width: 392, height: 576)

    static let panelPadding: CGFloat = 16
    static let verticalStackSpacing: CGFloat = 10
    static let elementSpacing: CGFloat = 8
    static let calendarGridSpacing: CGFloat = 5
    static let calendarMinimumCellWidth: CGFloat = 30

    static let heroCornerRadius: CGFloat = 20
    static let heroPadding: CGFloat = 16
    static let heroColumnSpacing: CGFloat = 12

    static let sectionCornerRadius: CGFloat = 16
    static let sectionPadding: CGFloat = 14
    static let sectionContentSpacing: CGFloat = 10
}
