//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
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
        ZStack(alignment: .top) {
            // Nền chung cho toàn bộ Panel
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.accentColor.opacity(controlActiveState == .active ? 0.08 : 0.03),
                            Color.clear,
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Toolbar thiết kế phẳng, căn chỉnh tuyệt đối với lề
                topToolbar
                    .padding(.horizontal, MenuBarMetrics.panelPadding)
                    .padding(.vertical, 14)
                    .background(.ultraThickMaterial.opacity(0.5))
                    .overlay(alignment: .bottom) { 
                        Divider().opacity(0.1) 
                    }

                ScrollView {
                    VStack(spacing: MenuBarMetrics.verticalStackSpacing) {
                        if viewModel.settings.showHeroCard {
                            heroCard
                        }
                        
                        if viewModel.settings.showCanChiSection {
                            canChiCard
                        }

                        if viewModel.settings.showHolidaySection && !viewModel.info.upcomingHolidays.isEmpty {
                            holidaysCard
                        }

                        if viewModel.settings.showMonthCalendar {
                            monthCalendarCard
                        }
                        
                        if viewModel.settings.showDetailSection {
                            detailCard
                        }
                    }
                    .padding(MenuBarMetrics.panelPadding)
                    .entranceAnimation(hasAppeared: hasAppeared, reduceMotion: reduceMotion)
                }
                .scrollIndicators(.hidden)
            }
        }
        .tint(viewModel.settings.customAccentColor)
        .frame(width: MenuBarMetrics.panelSize.width, height: MenuBarMetrics.panelSize.height)
        .task {
            if !hasAppeared {
                if reduceMotion {
                    hasAppeared = true
                } else {
                    withAnimation(.spring(duration: 0.6)) {
                        hasAppeared = true
                    }
                }
            }
        }
    }

    // MARK: - Top Toolbar

    private var topToolbar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                Text("LunarV")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text("Lịch âm chuyên nghiệp")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer()
            
            HStack(spacing: 8) {
                toolbarButton(icon: "doc.on.doc", help: "Sao chép ngày") {
                    copyCurrentDate()
                }
                
                SettingsLink {
                    Image(systemName: "gearshape")
                        .font(.system(size: 13, weight: .medium))
                        .frame(width: 28, height: 28)
                        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .help("Cài đặt")

                toolbarButton(icon: "power", help: "Thoát ứng dụng", color: .red) {
                    confirmExit()
                }
            }
        }
    }

    // MARK: - Hero Card

    private var heroCard: some View {
        let info = viewModel.info
        let tintOpacity = isHeroHovered && controlActiveState == .active ? 0.4 : 0.2
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(info.weekdayText.uppercased())
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.accentColor)
                        .tracking(1.2)
                    
                    Text("Ngày \(info.lunarDayText)")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    Text(info.lunarMonthYearText)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                    
                    Text(info.solarDateText)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    Image(systemName: info.lunarPhaseIcon)
                        .font(.system(size: 40, weight: .ultraLight))
                        .foregroundStyle(Color.accentColor)
                        .symbolRenderingMode(.hierarchical)
                    
                    Text(info.lunarPhaseName)
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(.tertiary)
                }
            }

            HStack(spacing: 10) {
                HeroChip(icon: "sun.max.fill", title: "Tiết khí", value: info.solarTermText)
                HeroChip(icon: "clock.fill", title: "Hoàng đạo", value: info.currentHourCanChiText)
            }
        }
        .padding(20)
        .glassEffect(Material.regular, tint: Color.accentColor.opacity(tintOpacity), in: RoundedRectangle(cornerRadius: 24))
        .onHover { h in withAnimation(.spring(duration: 0.3)) { isHeroHovered = h } }
    }

    // MARK: - Sections

    private var canChiCard: some View {
        SectionCard(title: "Can chi & Con giáp") {
            HStack(spacing: 10) {
                CanChiPill(title: "Ngày", value: viewModel.info.canChiDayText)
                CanChiPill(title: "Tháng", value: viewModel.info.canChiMonthText)
                CanChiPill(title: "Năm", value: viewModel.info.canChiYearText)
            }
        }
    }
    
    private var holidaysCard: some View {
        SectionCard(title: "Sự kiện sắp tới") {
            VStack(spacing: 8) {
                ForEach(viewModel.info.upcomingHolidays.prefix(3)) { holiday in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(holiday.name).font(.system(size: 12, weight: .bold)).foregroundStyle(.primary)
                            Text(holiday.dateText).font(.system(size: 10, weight: .medium)).foregroundStyle(.tertiary)
                        }
                        Spacer()
                        Text(holiday.daysUntil == 0 ? "Hôm nay" : "\(holiday.daysUntil) ngày nữa")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(holiday.daysUntil == 0 ? .red.opacity(0.1) : Color.accentColor.opacity(0.1), in: Capsule())
                            .foregroundStyle(holiday.daysUntil == 0 ? .red : Color.accentColor)
                    }
                    .padding(10)
                    .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private var monthCalendarCard: some View {
        SectionCard(title: "Lịch tháng", trailingView: {
            HStack(spacing: 10) {
                Button("Nay") { viewModel.goToToday() }.buttonStyle(.plain)
                    .font(.system(size: 10, weight: .bold)).foregroundStyle(Color.accentColor)
                
                HStack(spacing: 6) {
                    calendarNavButton(icon: "chevron.left") { viewModel.previousMonth() }
                    Text(viewModel.info.monthTitleText).font(.system(size: 11, weight: .bold)).frame(width: 90)
                    calendarNavButton(icon: "chevron.right") { viewModel.nextMonth() }
                }
            }
        }) {
            VStack(spacing: 8) {
                HStack(spacing: 0) {
                    ForEach(weekdayHeaders, id: \.self) { day in
                        Text(day).font(.system(size: 10, weight: .bold))
                            .foregroundStyle(day == "T7" || day == "CN" ? .red.opacity(0.7) : .secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                LazyVGrid(columns: calendarColumns, spacing: 6) {
                    ForEach(Array(viewModel.info.monthCells.enumerated()), id: \.element.id) { index, cell in
                        MonthDayCellView(cell: cell, weekdayIndex: index % 7)
                    }
                }
            }
        }
    }

    private var detailCard: some View {
        SectionCard(title: "Thông tin khác") {
            VStack(spacing: 10) {
                InfoRow(icon: "calendar.badge.clock", label: "Ngày âm lịch", value: viewModel.info.lunarDateText)
                HStack(spacing: 10) {
                    StatTile(title: "Tuần thứ", value: viewModel.info.weekOfYearText)
                    StatTile(title: "Ngày thứ", value: viewModel.info.dayOfYearText)
                }
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func toolbarButton(icon: String, help: String, color: Color = .primary, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(color.opacity(0.8))
                .frame(width: 28, height: 28)
                .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .help(help)
    }

    @ViewBuilder
    private func calendarNavButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold))
                .frame(width: 20, height: 20)
                .background(Color.primary.opacity(0.05), in: Circle())
        }
        .buttonStyle(.plain)
    }

    private func confirmExit() {
        let alert = NSAlert()
        alert.messageText = "Thoát LunarV?"
        alert.addButton(withTitle: "Thoát")
        alert.addButton(withTitle: "Huỷ")
        if alert.runModal() == .alertFirstButtonReturn { NSApp.terminate(nil) }
    }
    
    private func copyCurrentDate() {
        let info = viewModel.info
        let text = "\(info.weekdayText), \(info.solarDateText) (Âm lịch: \(info.lunarDateText) năm \(info.canChiYearText))"
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}

// MARK: - Reusable Components

private struct SectionCard<Content: View, Trailing: View>: View {
    let title: String
    var trailingView: (() -> Trailing)? = nil
    @ViewBuilder var content: Content

    init(title: String, @ViewBuilder trailingView: @escaping () -> Trailing, @ViewBuilder content: () -> Content) {
        self.title = title; self.trailingView = trailingView; self.content = content()
    }
    init(title: String, @ViewBuilder content: () -> Content) where Trailing == EmptyView {
        self.title = title; self.trailingView = nil; self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title.uppercased()).font(.system(size: 10, weight: .bold)).foregroundStyle(.tertiary).tracking(1)
                Spacer()
                trailingView?()
            }
            content
        }
        .padding(16)
        .glassEffect(Material.regular, in: RoundedRectangle(cornerRadius: 20))
    }
}

private struct CanChiPill: View {
    let title: String
    let value: String
    var body: some View {
        VStack(spacing: 4) {
            Text(title).font(.system(size: 9, weight: .bold)).foregroundStyle(.tertiary)
            Text(value).font(.system(size: 12, weight: .semibold))
        }
        .frame(maxWidth: .infinity).padding(.vertical, 10)
        .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 10, weight: .bold)).foregroundStyle(Color.accentColor)
                .frame(width: 24, height: 24).background(Color.accentColor.opacity(0.1), in: Circle())
            Text(label).font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.system(size: 12, weight: .semibold))
        }
    }
}

private struct StatTile: View {
    let title: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.system(size: 9, weight: .bold)).foregroundStyle(.tertiary)
            Text(value).font(.system(size: 12, weight: .semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(10)
        .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct MonthDayCellView: View {
    let cell: LunarMonthDayCell
    let weekdayIndex: Int
    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 0) {
            if let solar = cell.solarDay, let lunar = cell.lunarDay {
                Text("\(solar)").font(.system(size: 13, weight: cell.isToday ? .bold : .semibold))
                    .foregroundStyle(cell.isToday ? Color.accentColor : (cell.holiday != nil || weekdayIndex >= 5 ? .red.opacity(0.8) : .primary))
                Text("\(lunar)").font(.system(size: 9, weight: .medium))
                    .foregroundStyle(cell.isToday ? Color.accentColor.opacity(0.8) : .secondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 38)
        .background(cell.isToday ? Color.accentColor.opacity(0.15) : (isHovered ? Color.primary.opacity(0.05) : .clear), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(cell.isToday ? Color.accentColor.opacity(0.5) : .clear, lineWidth: 1.5))
        .overlay(alignment: .topTrailing) {
            if cell.holiday != nil { Circle().fill(.red).frame(width: 4).padding(4) }
            else if cell.isFirstLunarDay { Circle().fill(.orange).frame(width: 4).padding(4) }
        }
        .onHover { h in withAnimation(.snappy(duration: 0.1)) { isHovered = h } }
    }
}

private struct HeroChip: View {
    let icon: String
    let title: String
    let value: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 11, weight: .semibold)).foregroundStyle(Color.accentColor)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.system(size: 9, weight: .bold)).foregroundStyle(.tertiary)
                Text(value).font(.system(size: 11, weight: .semibold)).lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Extensions

extension View {
    func glassEffect<S: Shape>(_ material: Material = .regular, tint: Color = .clear, in shape: S) -> some View {
        self.background(material, in: shape)
            .background(tint, in: shape)
    }
}

private struct EntranceAnimationModifier: ViewModifier {
    let hasAppeared: Bool
    let reduceMotion: Bool
    func body(content: Content) -> some View {
        content.opacity(hasAppeared ? 1 : 0).offset(y: hasAppeared ? 0 : 10)
            .animation(reduceMotion ? .none : .spring(duration: 0.6, bounce: 0.3), value: hasAppeared)
    }
}

extension View {
    func entranceAnimation(hasAppeared: Bool, reduceMotion: Bool) -> some View {
        modifier(EntranceAnimationModifier(hasAppeared: hasAppeared, reduceMotion: reduceMotion))
    }
}

// MARK: - Metrics

private enum MenuBarMetrics {
    static let panelSize = CGSize(width: 360, height: 600)
    static let panelPadding: CGFloat = 16
    static let verticalStackSpacing: CGFloat = 12
    static let calendarGridSpacing: CGFloat = 6
    static let calendarMinimumCellWidth: CGFloat = 32
}
