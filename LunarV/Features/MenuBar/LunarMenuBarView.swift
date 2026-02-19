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
    @State private var hoveredCalendarHolidayText: String?
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
        .tint(.accentColor)
        .frame(
            width: viewModel.settings.menuBarPanelWidthCGFloat,
            height: viewModel.settings.menuBarPanelHeightCGFloat,
            alignment: .top
        )
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
        .onChange(of: viewModel.info.monthTitleText) { _, _ in
            hoveredCalendarHolidayText = nil
        }
    }

    // MARK: - Top Toolbar

    private var topToolbar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 28, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                VStack(alignment: .leading, spacing: 1) {
                    Text("LunarV")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("Lịch âm Việt Nam")
                        .font(.system(size: 9.5, weight: .medium, design: .rounded))
                        .foregroundStyle(.tertiary)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("LunarV – Lịch âm Việt Nam")

            Spacer()

            HStack(spacing: 6) {
                toolbarButton(icon: "doc.on.doc", help: "Sao chép ngày") {
                    copyCurrentDate()
                }

                toolbarButton(icon: "gearshape", help: "Cài đặt") {
                    openWindow(id: "settings")
                }

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
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.accentColor)
                        .tracking(1.6)

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

                VStack(alignment: .trailing, spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.08))
                            .frame(width: 56, height: 56)
                        Image(systemName: info.lunarPhaseIcon)
                            .font(.system(size: 32, weight: .ultraLight))
                            .foregroundStyle(Color.accentColor)
                            .symbolRenderingMode(.hierarchical)
                    }

                    Text(info.lunarPhaseName)
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary.opacity(0.6))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.primary.opacity(0.04), in: Capsule())
                }
            }

            HStack(spacing: 8) {
                HeroChip(icon: "sun.max.fill", title: "Tiết khí", value: info.solarTermText)
                HeroChip(icon: "clock.fill", title: "Hoàng đạo", value: info.currentHourCanChiText)
            }
        }
        .padding(20)
        .glassEffect(Material.regular, tint: Color.accentColor.opacity(tintOpacity), in: RoundedRectangle(cornerRadius: 24))
        .onHover { h in withAnimation(.spring(duration: 0.3)) { isHeroHovered = h } }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Ngày âm lịch: \(info.weekdayText), ngày \(info.lunarDayText), \(info.lunarMonthYearText). Dương lịch: \(info.solarDateText). Pha trăng: \(info.lunarPhaseName). Tiết khí: \(info.solarTermText)")
    }

    // MARK: - Panel Card Router

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
        case .internationalTimes:
            if viewModel.settings.showInternationalTimesSection {
                internationalTimesCard
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

    // MARK: - Cards

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
                .fixedSize(horizontal: false, vertical: true)

                DayOfficerPanel(officer: viewModel.info.dayOfficer)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.info.dayGuidance.activityInsights) { insight in
                        ActivityInsightRow(insight: insight)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

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
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var holidaysCard: some View {
        SectionCard(title: "Sự kiện sắp tới") {
            VStack(spacing: 8) {
                ForEach(viewModel.info.upcomingHolidays.prefix(3)) { holiday in
                    let isToday = holiday.daysUntil == 0
                    HStack(alignment: .center, spacing: 10) {
                        // Countdown circle
                        ZStack {
                            Circle()
                                .fill(isToday ? Color.red.opacity(0.12) : Color.accentColor.opacity(0.1))
                                .frame(width: 36, height: 36)
                            if isToday {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.red)
                            } else {
                                Text("\(holiday.daysUntil)")
                                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                                    .monospacedDigit()
                                    .foregroundStyle(Color.accentColor)
                            }
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(justifiedAttributedText(
                                holiday.name,
                                size: 12,
                                weight: .bold
                            ))
                            .frame(maxWidth: .infinity, alignment: .leading)

                            HStack(spacing: 4) {
                                Text(holiday.dateText)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(.secondary)
                                Text("•")
                                    .font(.system(size: 8))
                                    .foregroundStyle(.secondary.opacity(0.5))
                                Text(isToday ? "Hôm nay" : "\(holiday.daysUntil) ngày nữa")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(isToday ? .red : Color.accentColor)
                            }
                        }
                    }
                    .padding(10)
                    .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private var internationalTimesCard: some View {
        SectionCard(title: "Giờ quốc tế", trailingView: {
            Button {
                copyInternationalTimes()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 8, weight: .bold))
                    Text("Sao chép")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(Color.accentColor)
            }
            .buttonStyle(.plain)
            .help("Sao chép danh sách giờ quốc tế")
        }) {
            if viewModel.info.internationalTimes.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "globe")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary.opacity(0.5))
                    Text("Không có dữ liệu múi giờ quốc tế.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
            } else {
                VStack(spacing: 6) {
                    ForEach(viewModel.info.internationalTimes) { cityTime in
                        HStack(alignment: .center, spacing: 10) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(cityTime.city)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.primary)
                                HStack(spacing: 4) {
                                    Text(cityTime.weekdayText)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(.secondary)
                                    Text("•")
                                        .font(.system(size: 8))
                                        .foregroundStyle(.secondary.opacity(0.5))
                                    Text(cityTime.utcOffsetText)
                                        .font(.system(size: 10, weight: .medium, design: .rounded))
                                        .monospacedDigit()
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer(minLength: 0)

                            VStack(alignment: .trailing, spacing: 2) {
                                Text(cityTime.timeText)
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .monospacedDigit()
                                    .foregroundStyle(Color.accentColor)
                                Text(cityTime.relativeDayText)
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(cityTime.city), \(cityTime.timeText), \(cityTime.weekdayText), \(cityTime.relativeDayText), \(cityTime.utcOffsetText)")
                    }
                }
            }
        }
    }

    private var monthCalendarCard: some View {
        SectionCard(title: "Lịch tháng", trailingView: {
            HStack(spacing: 10) {
                Button("Nay") { viewModel.goToToday() }.buttonStyle(.plain)
                    .font(.system(size: 10, weight: .bold)).foregroundStyle(Color.accentColor)
                    .accessibilityLabel("Về hôm nay")

                HStack(spacing: 6) {
                    calendarNavButton(icon: "chevron.left") { viewModel.previousMonth() }
                        .accessibilityLabel("Tháng trước")
                    Text(viewModel.info.monthTitleText).font(.system(size: 11, weight: .bold)).frame(width: 90)
                        .accessibilityLabel("Tháng hiện tại: \(viewModel.info.monthTitleText)")
                    calendarNavButton(icon: "chevron.right") { viewModel.nextMonth() }
                        .accessibilityLabel("Tháng sau")
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
                        MonthDayCellView(
                            cell: cell,
                            weekdayIndex: index % 7
                        ) { hoverText in
                            hoveredCalendarHolidayText = hoverText
                        }
                    }
                }

                HStack(spacing: 6) {
                    Image(systemName: hoveredCalendarHolidayText != nil ? "calendar.badge.exclamationmark" : "sparkles")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(hoveredCalendarHolidayText != nil ? .red : Color.accentColor)

                    Text(hoveredCalendarHolidayText ?? "Rê chuột vào ô có chấm đỏ để xem tên ngày lễ.")
                        .font(.system(size: 10, weight: hoveredCalendarHolidayText != nil ? .semibold : .medium))
                        .foregroundStyle(hoveredCalendarHolidayText == nil ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .animation(.easeInOut(duration: 0.15), value: hoveredCalendarHolidayText)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    hoveredCalendarHolidayText != nil ? Color.red.opacity(0.04) : Color.primary.opacity(0.03),
                    in: RoundedRectangle(cornerRadius: 10)
                )
                .animation(.easeInOut(duration: 0.15), value: hoveredCalendarHolidayText != nil)
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
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(color.opacity(0.7))
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(ToolbarHoverButtonStyle())
        .help(help)
    }

    @ViewBuilder
    private func calendarNavButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.secondary)
                .frame(width: 22, height: 22)
                .contentShape(Circle())
        }
        .buttonStyle(ToolbarHoverButtonStyle())
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

    private func copyInternationalTimes() {
        let lines = viewModel.info.internationalTimes.map {
            "\($0.city): \($0.timeText) (\($0.weekdayText), \($0.utcOffsetText), \($0.relativeDayText))"
        }
        guard !lines.isEmpty else {
            return
        }
        copyToPasteboard(lines.joined(separator: "\n"))
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

// MARK: - Metrics

enum MenuBarMetrics {
    static let panelSize = CGSize(width: 360, height: 600)
    static let panelPadding: CGFloat = 16
    static let verticalStackSpacing: CGFloat = 12
    static let calendarGridSpacing: CGFloat = 6
    static let calendarMinimumCellWidth: CGFloat = 32
}
