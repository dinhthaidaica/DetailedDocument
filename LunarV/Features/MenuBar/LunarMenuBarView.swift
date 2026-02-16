//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import AppKit
import SwiftUI

struct LunarMenuBarView: View {
    @Environment(\.controlActiveState) private var controlActiveState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openWindow) private var openWindow
    @State private var isHeroHovered = false
    @State private var hasAppeared = false
    @State private var converterMode: DateConverterMode = .solarToLunar
    @State private var solarConversionDate = Date()
    @State private var solarInputDay = Calendar(identifier: .gregorian).component(.day, from: Date())
    @State private var solarInputMonth = Calendar(identifier: .gregorian).component(.month, from: Date())
    @State private var solarInputYear = Calendar(identifier: .gregorian).component(.year, from: Date())
    @State private var solarToLunarSnapshot: VietnameseLunarSnapshot?
    @State private var lunarInputDay = 1
    @State private var lunarInputMonth = 1
    @State private var lunarInputYear = Calendar(identifier: .gregorian).component(.year, from: Date())
    @State private var lunarInputIsLeapMonth = false
    @State private var lunarToSolarResult: SolarDateComponents?
    @ObservedObject var viewModel: LunarMenuBarViewModel

    private let calendarColumns = Array(
        repeating: GridItem(.flexible(minimum: MenuBarMetrics.calendarMinimumCellWidth), spacing: MenuBarMetrics.calendarGridSpacing),
        count: 7
    )
    private let hourColumns = Array(
        repeating: GridItem(.flexible(minimum: 130), spacing: 8),
        count: 2
    )
    private let weekdayHeaders = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"]
    private var solarInputDayRange: ClosedRange<Int> {
        1 ... solarDaysInMonth(month: solarInputMonth, year: solarInputYear)
    }

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
                        ForEach(viewModel.settings.panelCardOrder) { card in
                            panelCard(for: card)
                        }
                    }
                    .padding(MenuBarMetrics.panelPadding)
                    .entranceAnimation(hasAppeared: hasAppeared, reduceMotion: reduceMotion)
                }
                .scrollIndicators(.hidden)
            }
        }
        .tint(viewModel.settings.customAccentColor)
        .frame(width: MenuBarMetrics.panelSize.width, height: MenuBarMetrics.panelSize.height, alignment: .top)
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
            refreshSolarToLunarSnapshot()
            refreshLunarToSolarResult()
            syncSolarInput(from: solarConversionDate)
        }
        .onChange(of: solarConversionDate) { _, _ in
            refreshSolarToLunarSnapshot()
            syncSolarInput(from: solarConversionDate)
        }
        .onChange(of: solarInputDay) { _, _ in
            refreshSolarConversionDateFromInputs()
        }
        .onChange(of: solarInputMonth) { _, _ in
            refreshSolarConversionDateFromInputs()
        }
        .onChange(of: solarInputYear) { _, _ in
            refreshSolarConversionDateFromInputs()
        }
        .onChange(of: lunarInputDay) { _, _ in
            refreshLunarToSolarResult()
        }
        .onChange(of: lunarInputMonth) { _, _ in
            refreshLunarToSolarResult()
        }
        .onChange(of: lunarInputYear) { _, _ in
            refreshLunarToSolarResult()
        }
        .onChange(of: lunarInputIsLeapMonth) { _, _ in
            refreshLunarToSolarResult()
        }
        .onChange(of: converterMode) { _, mode in
            if mode == .lunarToSolar {
                refreshLunarToSolarResult()
            } else {
                refreshSolarToLunarSnapshot()
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
                Text("Lịch âm Việt Nam")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer()
            
            HStack(spacing: 8) {
                toolbarButton(icon: "doc.on.doc", help: "Sao chép ngày") {
                    copyCurrentDate()
                }
                
                Button {
                    openWindow(id: "settings")
                } label: {
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
                        .foregroundStyle(.primary.opacity(0.85))
                    
                    Text(info.solarDateText)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    Image(systemName: info.lunarPhaseIcon)
                        .font(.system(size: 40, weight: .ultraLight))
                        .foregroundStyle(Color.accentColor)
                        .symbolRenderingMode(.hierarchical)
                    
                    Text(info.lunarPhaseName)
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary.opacity(0.7))
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

    @ViewBuilder
    private func panelCard(for card: PanelCardKind) -> some View {
        switch card {
        case .hero:
            if viewModel.settings.showHeroCard {
                heroCard
            }
        case .canChi:
            if viewModel.settings.showCanChiSection {
                canChiCard
            }
        case .auspiciousHours:
            if viewModel.settings.showAuspiciousHoursSection {
                auspiciousHoursCard
            }
        case .dayGuidance:
            if viewModel.settings.showDayGuidanceSection {
                guidanceCard
            }
        case .holidays:
            if viewModel.settings.showHolidaySection && !viewModel.info.upcomingHolidays.isEmpty {
                holidaysCard
            }
        case .monthCalendar:
            if viewModel.settings.showMonthCalendar {
                monthCalendarCard
            }
        case .dateConverter:
            if viewModel.settings.showDateConverter {
                converterCard
            }
        case .detail:
            if viewModel.settings.showDetailSection {
                detailCard
            }
        }
    }

    private var canChiCard: some View {
        SectionCard(title: "Can chi & Con giáp") {
            HStack(spacing: 10) {
                CanChiPill(title: "Ngày", value: viewModel.info.canChiDayText)
                CanChiPill(title: "Tháng", value: viewModel.info.canChiMonthText)
                CanChiPill(title: "Năm", value: viewModel.info.canChiYearText)
            }
        }
    }

    private var auspiciousHoursCard: some View {
        SectionCard(title: "Giờ hoàng đạo") {
            VStack(alignment: .leading, spacing: 10) {
                InfoRow(icon: "leaf.fill", label: "Ngũ hành ngày", value: viewModel.info.dayElementText)
                InfoRow(icon: "arrow.left.and.right.circle", label: "Tuổi xung", value: viewModel.info.oppositeZodiacText)
                InfoRow(icon: "person.3.sequence.fill", label: "Tam hợp", value: viewModel.info.tamHopGroupText)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Khung giờ đẹp kế tiếp")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.primary.opacity(0.7))
                    Text(justifiedAttributedText(
                        viewModel.info.nextAuspiciousHourText,
                        size: 11,
                        weight: .semibold
                    ))
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(10)
                .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))

                LazyVGrid(columns: hourColumns, spacing: 8) {
                    ForEach(viewModel.info.auspiciousHours) { hour in
                        HourPeriodPill(hour: hour)
                    }
                }

                if !viewModel.info.inauspiciousHours.isEmpty {
                    Text(justifiedAttributedText(
                        "Giờ hắc đạo: \(formattedHourSummary(viewModel.info.inauspiciousHours))",
                        size: 10,
                        weight: .medium,
                        color: .secondaryLabelColor
                    ))
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var guidanceCard: some View {
        SectionCard(title: "Gợi ý trong ngày") {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.info.dayGuidance.title)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.accentColor)
                        Text(viewModel.info.dayGuidance.ratingText)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    GuidanceScoreView(score: viewModel.info.dayGuidance.score)
                }

                Text(justifiedAttributedText(
                    viewModel.info.dayGuidance.summary,
                    size: 11,
                    weight: .medium,
                    color: .secondaryLabelColor
                ))
                .frame(maxWidth: .infinity, alignment: .leading)

                DayOfficerPanel(officer: viewModel.info.dayOfficer)

                VStack(spacing: 8) {
                    ForEach(viewModel.info.dayGuidance.activityInsights) { insight in
                        ActivityInsightRow(insight: insight)
                    }
                }

                if !viewModel.info.dayOfficer.recommendedActivities.isEmpty {
                    GuidanceBlock(
                        title: "Theo Trực ngày - Nên làm",
                        items: viewModel.info.dayOfficer.recommendedActivities,
                        tint: .mint
                    )
                }

                if !viewModel.info.dayOfficer.avoidActivities.isEmpty {
                    GuidanceBlock(
                        title: "Theo Trực ngày - Nên tránh",
                        items: viewModel.info.dayOfficer.avoidActivities,
                        tint: .pink
                    )
                }

                if !viewModel.info.dayGuidance.recommendedActivities.isEmpty {
                    GuidanceBlock(
                        title: "Nên ưu tiên",
                        items: viewModel.info.dayGuidance.recommendedActivities,
                        tint: .green
                    )
                }

                if !viewModel.info.dayGuidance.avoidActivities.isEmpty {
                    GuidanceBlock(
                        title: "Nên hạn chế",
                        items: viewModel.info.dayGuidance.avoidActivities,
                        tint: .orange
                    )
                }
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
                            Text(holiday.dateText).font(.system(size: 10, weight: .medium)).foregroundStyle(.secondary)
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
                            .foregroundStyle(day == "T7" || day == "CN" ? .red.opacity(0.8) : .primary.opacity(0.6))
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
                InfoRow(icon: "clock.arrow.circlepath", label: "Giờ Can Chi hiện tại", value: viewModel.info.currentHourCanChiText)
                HStack(spacing: 10) {
                    StatTile(title: "Tuần thứ", value: viewModel.info.weekOfYearText)
                    StatTile(title: "Ngày thứ", value: viewModel.info.dayOfYearText)
                }
            }
        }
    }

    private var converterCard: some View {
        SectionCard(title: "Chuyển đổi nhanh") {
            VStack(alignment: .leading, spacing: 12) {
                ConverterModeSelector(mode: $converterMode)

                if converterMode == .solarToLunar {
                    solarToLunarConverter
                } else {
                    lunarToSolarConverter
                }
            }
        }
    }

    private var solarToLunarConverter: some View {
        ConverterPanel(
            title: "Dương lịch -> Âm lịch",
            subtitle: "Nhập ngày dương lịch theo cùng kiểu chọn như chiều ngược lại.",
            icon: "sun.max.fill"
        ) {
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    ConverterStepperField(title: "Ngày", value: $solarInputDay, range: solarInputDayRange)
                    ConverterStepperField(title: "Tháng", value: $solarInputMonth, range: 1 ... 12)
                }

                HStack(spacing: 8) {
                    ConverterStepperField(title: "Năm dương", value: $solarInputYear, range: 1900 ... 2199)
                    ConverterActionField(
                        title: "ĐỒNG BỘ",
                        buttonTitle: "Đặt ngày hiện tại",
                        systemImage: "calendar.badge.clock"
                    ) {
                        setSolarInputToToday()
                    }
                }
            }
        } resultContent: {
            if let snapshot = solarToLunarSnapshot {
                let leapText = snapshot.lunar.isLeapMonth ? " nhuận" : ""
                let copiedText = "Dương lịch \(snapshot.solar.formattedDate) -> Âm lịch \(snapshot.lunar.day)/\(snapshot.lunar.month)\(leapText), năm \(snapshot.canChiYear)"

                ConverterResultCard(
                    title: "Âm lịch",
                    value: "\(snapshot.lunar.day)/\(snapshot.lunar.month)\(leapText), năm \(snapshot.canChiYear)",
                    detail: "Dương đã chọn: \(snapshot.solar.formattedDate) • Can chi ngày: \(snapshot.canChiDay)",
                    copyTitle: "Sao chép kết quả"
                ) {
                    copyToPasteboard(copiedText)
                }
            } else {
                ConverterErrorCard(message: "Không thể chuyển đổi ngày đã chọn.")
            }
        }
    }

    private var lunarToSolarConverter: some View {
        ConverterPanel(
            title: "Âm lịch -> Dương lịch",
            subtitle: "Nhập ngày âm lịch, bật tháng nhuận khi cần.",
            icon: "moon.stars.fill"
        ) {
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    ConverterStepperField(title: "Ngày", value: $lunarInputDay, range: 1 ... 30)
                    ConverterStepperField(title: "Tháng", value: $lunarInputMonth, range: 1 ... 12)
                }

                HStack(spacing: 8) {
                    ConverterStepperField(title: "Năm âm", value: $lunarInputYear, range: 1900 ... 2199)
                    ConverterLeapMonthField(isOn: $lunarInputIsLeapMonth)
                }
            }
        } resultContent: {
            if let solar = lunarToSolarResult {
                let lunarText = "\(lunarInputDay)/\(lunarInputMonth)\(lunarInputIsLeapMonth ? " nhuận" : "")/\(lunarInputYear)"
                let copiedText = "Âm lịch \(lunarText) -> Dương lịch \(solar.formattedDate)"

                ConverterResultCard(
                    title: "Dương lịch",
                    value: solar.formattedDate,
                    detail: "Can chi ngày: \(VietnameseCalendarMetadata.canChiDay(day: solar.day, month: solar.month, year: solar.year))",
                    copyTitle: "Sao chép kết quả"
                ) {
                    copyToPasteboard(copiedText)
                }
            } else {
                ConverterErrorCard(message: "Không tìm thấy ngày dương tương ứng với dữ liệu âm lịch này.")
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
        copyToPasteboard(text)
    }

    private func copyToPasteboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    private func formattedHourSummary(_ hours: [VietnameseHourPeriod]) -> String {
        hours
            .map { "\($0.branch) (\($0.timeRange))" }
            .joined(separator: ", ")
    }

    private func setSolarInputToToday() {
        syncSolarInput(from: Date())
    }

    private func refreshSolarConversionDateFromInputs() {
        let month = min(max(solarInputMonth, 1), 12)
        let maxDay = solarDaysInMonth(month: month, year: solarInputYear)
        let day = min(max(solarInputDay, 1), maxDay)

        if month != solarInputMonth {
            solarInputMonth = month
            return
        }

        if day != solarInputDay {
            solarInputDay = day
            return
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = VietnameseLunarDateService.defaultTimeZone

        guard let resolvedDate = calendar.date(from: DateComponents(year: solarInputYear, month: month, day: day, hour: 12)) else {
            return
        }

        if !calendar.isDate(resolvedDate, inSameDayAs: solarConversionDate) {
            solarConversionDate = resolvedDate
        }
    }

    private func syncSolarInput(from date: Date) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = VietnameseLunarDateService.defaultTimeZone
        let components = calendar.dateComponents([.day, .month, .year], from: date)

        let resolvedDay = components.day ?? solarInputDay
        let resolvedMonth = components.month ?? solarInputMonth
        let resolvedYear = components.year ?? solarInputYear

        if solarInputDay != resolvedDay { solarInputDay = resolvedDay }
        if solarInputMonth != resolvedMonth { solarInputMonth = resolvedMonth }
        if solarInputYear != resolvedYear { solarInputYear = resolvedYear }
    }

    private func solarDaysInMonth(month: Int, year: Int) -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = VietnameseLunarDateService.defaultTimeZone

        guard
            let monthDate = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
            let dayRange = calendar.range(of: .day, in: .month, for: monthDate)
        else {
            return 31
        }

        return dayRange.count
    }

    private func refreshSolarToLunarSnapshot() {
        solarToLunarSnapshot = viewModel.snapshot(for: solarConversionDate)
    }

    private func refreshLunarToSolarResult() {
        let targetLunarDate = LunarDate(
            day: lunarInputDay,
            month: lunarInputMonth,
            year: lunarInputYear,
            isLeapMonth: lunarInputIsLeapMonth
        )
        lunarToSolarResult = viewModel.solarDate(from: targetLunarDate)
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
                Text(title.uppercased()).font(.system(size: 10, weight: .bold)).foregroundStyle(.primary.opacity(0.6)).tracking(1)
                Spacer()
                trailingView?()
            }
            content
        }
        .padding(16)
        .glassEffect(Material.regular, in: RoundedRectangle(cornerRadius: 20))
    }
}

private struct ConverterModeSelector: View {
    @Binding var mode: DateConverterMode

    var body: some View {
        HStack(spacing: 8) {
            ForEach(DateConverterMode.allCases) { modeItem in
                let isActive = modeItem == mode

                Button {
                    withAnimation(.snappy(duration: 0.2)) {
                        mode = modeItem
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: modeItem.icon)
                            .font(.system(size: 10, weight: .bold))
                        Text(modeItem.title)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(isActive ? Color.accentColor : .primary.opacity(0.75))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isActive ? Color.accentColor.opacity(0.16) : Color.primary.opacity(0.04))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isActive ? Color.accentColor.opacity(0.35) : Color.primary.opacity(0.08),
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct ConverterPanel<InputContent: View, ResultContent: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    private let inputContent: InputContent
    private let resultContent: ResultContent

    init(
        title: String,
        subtitle: String,
        icon: String,
        @ViewBuilder inputContent: () -> InputContent,
        @ViewBuilder resultContent: () -> ResultContent
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.inputContent = inputContent()
        self.resultContent = resultContent()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 24, height: 24)
                    .background(Color.accentColor.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            inputContent
            resultContent
        }
        .padding(12)
        .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct ConverterResultCard: View {
    let title: String
    let value: String
    let detail: String
    let copyTitle: String
    let onCopy: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Color.accentColor.opacity(0.9))
                .tracking(0.6)

            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(justifiedAttributedText(
                detail,
                size: 10,
                weight: .medium,
                color: .secondaryLabelColor
            ))
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(copyTitle, action: onCopy)
                .buttonStyle(.plain)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.accentColor)
                .padding(.top, 2)
        }
        .padding(10)
        .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accentColor.opacity(0.24), lineWidth: 1)
        )
    }
}

private struct ConverterErrorCard: View {
    let message: String

    var body: some View {
        Text(justifiedAttributedText(
            message,
            size: 10,
            weight: .medium,
            color: .secondaryLabelColor
        ))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.24), lineWidth: 1)
        )
    }
}

private struct ConverterStepperField: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.primary.opacity(0.55))
                .tracking(0.6)

            HStack(spacing: 8) {
                stepButton(
                    icon: "minus",
                    isDisabled: value <= range.lowerBound
                ) {
                    value = max(value - 1, range.lowerBound)
                }

                Text("\(value)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .frame(maxWidth: .infinity)

                stepButton(
                    icon: "plus",
                    isDisabled: value >= range.upperBound
                ) {
                    value = min(value + 1, range.upperBound)
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func stepButton(
        icon: String,
        isDisabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
                .frame(width: 22, height: 22)
                .background(Color.primary.opacity(0.08), in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.45 : 1)
    }
}

private struct ConverterActionField: View {
    let title: String
    let buttonTitle: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.primary.opacity(0.55))
                .tracking(0.6)

            Button(action: action) {
                HStack(spacing: 6) {
                    Image(systemName: systemImage)
                        .font(.system(size: 10, weight: .bold))
                    Text(buttonTitle)
                        .font(.system(size: 10, weight: .semibold))
                        .lineLimit(1)
                }
                .foregroundStyle(Color.accentColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.accentColor.opacity(0.28), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct ConverterLeapMonthField: View {
    @Binding var isOn: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("THÁNG NHUẬN")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.primary.opacity(0.55))
                .tracking(0.6)

            HStack(spacing: 8) {
                Text(isOn ? "Đang bật" : "Đang tắt")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(isOn ? Color.accentColor : .secondary)
                Spacer(minLength: 0)
                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .toggleStyle(.switch)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct CanChiPill: View {
    let title: String
    let value: String
    var body: some View {
        VStack(spacing: 4) {
            Text(title).font(.system(size: 9, weight: .bold)).foregroundStyle(.primary.opacity(0.5))
            Text(value).font(.system(size: 12, weight: .bold)).foregroundStyle(.primary)
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
            Text(label).font(.system(size: 12, weight: .medium)).foregroundStyle(.primary.opacity(0.8))
            Spacer()
            Text(value).font(.system(size: 12, weight: .semibold)).foregroundStyle(.primary)
        }
    }
}

private struct StatTile: View {
    let title: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.system(size: 9, weight: .bold)).foregroundStyle(.primary.opacity(0.5))
            Text(value).font(.system(size: 12, weight: .bold)).foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(10)
        .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct HourPeriodPill: View {
    let hour: VietnameseHourPeriod

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(hour.canChi)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.primary)
            Text(hour.timeRange)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.accentColor.opacity(0.25), lineWidth: 1)
        )
    }
}

private struct GuidanceScoreView: View {
    let score: Int

    var body: some View {
        VStack(spacing: 2) {
            Text("\(score)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(scoreColor)
            Text("/100")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(width: 52, height: 52)
        .background(scoreColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(scoreColor.opacity(0.35), lineWidth: 1)
        )
    }

    private var scoreColor: Color {
        switch score {
        case 80...:
            return .green
        case 70...79:
            return .mint
        case 55...69:
            return .orange
        default:
            return .red
        }
    }
}

private struct DayOfficerPanel: View {
    let officer: LunarDayOfficerInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("Trực \(officer.name)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(levelColor)
                Spacer()
                Text(levelTitle)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(levelColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(levelColor.opacity(0.14), in: Capsule())
            }

            Text(justifiedAttributedText(
                officer.calculationNote,
                size: 9,
                weight: .semibold,
                color: .secondaryLabelColor
            ))
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(justifiedAttributedText(
                officer.summary,
                size: 10,
                weight: .medium
            ))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .background(levelColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(levelColor.opacity(0.22), lineWidth: 1)
        )
    }

    private var levelTitle: String {
        switch officer.level {
        case .favorable:
            return "Thuận lợi"
        case .neutral:
            return "Cân bằng"
        case .caution:
            return "Thận trọng"
        }
    }

    private var levelColor: Color {
        switch officer.level {
        case .favorable:
            return .green
        case .neutral:
            return .blue
        case .caution:
            return .orange
        }
    }
}

private struct ActivityInsightRow: View {
    let insight: LunarActivityInsightInfo
    private let categoryColumnWidth: CGFloat = 92

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(insight.categoryText)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(levelColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(levelColor.opacity(0.12), in: Capsule())
                .frame(width: categoryColumnWidth, alignment: .leading)

            Text(justifiedAttributedText(
                insight.reason,
                size: 10,
                weight: .medium
            ))
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var levelColor: Color {
        switch insight.level {
        case .favorable:
            return .green
        case .neutral:
            return .blue
        case .caution:
            return .orange
        }
    }
}

private struct GuidanceBlock: View {
    let title: String
    let items: [String]
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(tint.opacity(0.9))
            VStack(alignment: .leading, spacing: 4) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 6) {
                        Circle()
                            .fill(tint.opacity(0.8))
                            .frame(width: 5, height: 5)
                            .padding(.top, 5)
                        Text(justifiedAttributedText(item, size: 11, weight: .medium))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
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
                    .foregroundStyle(cell.isToday ? Color.accentColor : (cell.holiday != nil || weekdayIndex >= 5 ? .red.opacity(0.9) : .primary))
                Text("\(lunar)").font(.system(size: 9, weight: .medium))
                    .foregroundStyle(cell.isToday ? Color.accentColor.opacity(0.8) : .primary.opacity(0.5))
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
                Text(title).font(.system(size: 9, weight: .bold)).foregroundStyle(.primary.opacity(0.6))
                Text(value).font(.system(size: 11, weight: .bold)).foregroundStyle(.primary).lineLimit(1)
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
            .overlay(
                shape
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.4),
                                .white.opacity(0.1),
                                .black.opacity(0.05),
                                .white.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .blendMode(.overlay)
            )
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

private func justifiedAttributedText(
    _ text: String,
    size: CGFloat,
    weight: NSFont.Weight = .regular,
    color: NSColor = .labelColor
) -> AttributedString {
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .justified
    paragraphStyle.hyphenationFactor = 0.8
    paragraphStyle.lineBreakMode = .byWordWrapping

    let attributed = NSAttributedString(
        string: text,
        attributes: [
            .font: NSFont.systemFont(ofSize: size, weight: weight),
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle,
        ]
    )
    return AttributedString(attributed)
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

private enum DateConverterMode: String, CaseIterable, Identifiable {
    case solarToLunar
    case lunarToSolar

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .solarToLunar:
            return "sun.max.fill"
        case .lunarToSolar:
            return "moon.stars.fill"
        }
    }

    var title: String {
        switch self {
        case .solarToLunar:
            return "Dương -> Âm"
        case .lunarToSolar:
            return "Âm -> Dương"
        }
    }
}
