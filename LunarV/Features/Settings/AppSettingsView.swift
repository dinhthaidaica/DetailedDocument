//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import AppKit
import SwiftUI

struct AppSettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var notificationManager: HolidayNotificationManager
    @StateObject private var launchAtLoginManager = LaunchAtLoginManager()
    @State private var selectedPane: SettingsPane = .appearance
    @State private var isShowingResetDialog = false

    private let previewLunarService = VietnameseLunarDateService()

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailPane
                .frame(minWidth: 400, minHeight: 400)
        }
        .navigationSplitViewStyle(.balanced)
        .frame(width: 820, height: 600)
        .containerBackground(.thinMaterial, for: .window)
        .toolbar(removing: .title)
        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        .overlay(alignment: .top) {
            Color.clear
                .frame(height: 26)
                .contentShape(Rectangle())
                .gesture(WindowDragGesture())
                .allowsWindowActivationEvents(true)
                .accessibilityHidden(true)
        }
        .background(SettingsWindowBehavior(keepOnTop: settings.keepSettingsOnTop))
        .onAppear {
            launchAtLoginManager.refreshStatus()
        }
        .confirmationDialog(
            "Khôi phục cài đặt mặc định?",
            isPresented: $isShowingResetDialog,
            titleVisibility: .visible
        ) {
            Button("Xác nhận khôi phục", role: .destructive) { settings.resetAllSettings() }
            Button("Huỷ", role: .cancel) {}
        } message: {
            Text("Tất cả các tuỳ chỉnh về hiển thị và màu sắc sẽ quay về giá trị ban đầu.")
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(selection: $selectedPane) {
            ForEach(SettingsPane.allCases) { pane in
                LunarSettingsSidebarRow(pane: pane)
                    .tag(pane)
                    .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 160, ideal: 200, max: 240)
    }

    // MARK: - Detail Pane Router

    @ViewBuilder
    private var detailPane: some View {
        switch selectedPane {
        case .appearance:
            appearancePane
        case .panel:
            panelPane
        case .system:
            systemPane
        case .about:
            aboutPane
        }
    }

    // MARK: - Appearance Pane

    private var appearancePane: some View {
        ScrollView {
            LazyVStack(spacing: 18) {
                LunarSettingsHeader(
                    title: "Giao diện",
                    subtitle: "Tùy chỉnh màu sắc và cách hiển thị LunarV trên thanh Menu Bar.",
                    icon: "paintbrush.fill"
                ) {
                    VStack(alignment: .trailing, spacing: 6) {
                        LunarSettingsStatusPill(text: settings.menuBarDisplayPreset.title, color: .accentColor)
                        LunarSettingsStatusPill(
                            text: settings.showMenuBarLeadingIconValue ? "Icon: Bật" : "Icon: Tắt",
                            color: settings.showMenuBarLeadingIconValue ? .green : .secondary
                        )
                    }
                }

                LunarSettingsCard(
                    title: "Màu sắc chủ đạo",
                    subtitle: "Accent color cho điểm nhấn chính",
                    icon: "paintpalette.fill"
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        ColorPicker("Màu nhấn (Accent Color)", selection: $settings.customAccentColor)
                        Text("Màu này sẽ áp dụng cho icon và các điểm nhấn trên giao diện.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                LunarSettingsCard(
                    title: "Kiểu hiển thị Menu Bar",
                    subtitle: "Preset nhanh hoặc mẫu tuỳ chỉnh",
                    icon: "menubar.rectangle"
                ) {
                    VStack(alignment: .leading, spacing: 16) {
                        previewCard

                        Picker("Chế độ", selection: $settings.menuBarDisplayPreset) {
                            ForEach(MenuBarDisplayPreset.allCases) { preset in
                                Text(preset.title).tag(preset)
                            }
                        }
                        .pickerStyle(.segmented)

                        if settings.menuBarDisplayPreset == .custom {
                            customTemplateEditor
                        } else {
                            Text(settings.menuBarDisplayPreset.subtitle)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)
                        }

                        Divider()

                        menuBarTitleFontControl
                        menuBarLeadingIconControl
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(20)
        }
        .lunarSettingsBackground()
    }

    private var customTemplateEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Mẫu tuỳ chỉnh")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                TextField("Ví dụ: {dd}/{mm} ÂL", text: $settings.customMenuBarTemplate)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
            }

            Text("Chạm để chèn nhanh mã hiển thị:")
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 10) {
                Text("ÂM LỊCH")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundStyle(.orange.opacity(0.8))
                TokenFlowLayout(tokens: DisplayToken.lunarTokens) { token in
                    insertToken(token.code)
                }

                Text("DƯƠNG LỊCH")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundStyle(.blue.opacity(0.8))
                TokenFlowLayout(tokens: DisplayToken.solarTokens) { token in
                    insertToken(token.code)
                }

                Text("KHÁC")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundStyle(.secondary)
                TokenFlowLayout(tokens: DisplayToken.otherTokens) { token in
                    insertToken(token.code)
                }
            }
            .padding(10)
            .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private var menuBarTitleFontControl: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Kích cỡ chữ trên Menu Bar")
                    .font(.system(size: 13, weight: .semibold))
                Spacer(minLength: 0)
                Text("\(settings.menuBarTitleFontSizeValue.formatted(.number.precision(.fractionLength(1))))pt")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            Slider(
                value: menuBarTitleFontSizeBinding,
                in: AppSettings.menuBarTitleFontSizeRange
            )

            HStack {
                Text("Cỡ chữ này áp dụng cho phần ngày hiển thị trên thanh Menu Bar.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)

                Button("Mặc định 12pt") {
                    settings.setMenuBarTitleFontSize(AppSettings.defaultMenuBarTitleFontSize)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var menuBarLeadingIconControl: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Hiển thị icon bên trái ngày trên Menu Bar", isOn: menuBarLeadingIconVisibilityBinding)
                .lunarSettingsSwitchToggle()

            if settings.showMenuBarLeadingIconValue {
                HStack {
                    Text("Kích cỡ icon")
                        .font(.system(size: 13, weight: .semibold))
                    Spacer(minLength: 0)
                    Text("\(settings.menuBarLeadingIconSizeValue.formatted(.number.precision(.fractionLength(1))))pt")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                Slider(
                    value: menuBarLeadingIconSizeBinding,
                    in: AppSettings.menuBarLeadingIconSizeRange
                )

                Text("Apple khuyến nghị icon menu bar nên gọn để cân bằng với chữ và độ dày thanh menu.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Icon và chữ hiện có hai thanh điều chỉnh riêng.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Panel Pane

    private var panelPane: some View {
        ScrollView {
            LazyVStack(spacing: 18) {
                LunarSettingsHeader(
                    title: "Bảng điều khiển",
                    subtitle: "Sắp xếp thứ tự và quản lý hiển thị các card trong menu.",
                    icon: "list.bullet.indent"
                ) {
                    VStack(alignment: .trailing, spacing: 6) {
                        LunarSettingsStatusPill(text: "Hiển thị: \(visiblePanelCardCount)/\(settings.panelCardOrder.count)")
                    }
                }

                LunarSettingsCard(
                    title: "Thành phần hiển thị",
                    subtitle: "Kéo thả để đổi thứ tự card",
                    icon: "rectangle.grid.1x2.fill"
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Kéo thả để thay đổi thứ tự card hiển thị trên bảng Menu Bar. Gạt công tắc để ẩn/hiện từng card.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        List {
                            ForEach(settings.panelCardOrder) { card in
                                PanelCardOrderRow(
                                    card: card,
                                    isVisible: panelCardVisibilityBinding(for: card)
                                )
                            }
                            .onMove(perform: settings.movePanelCard)
                        }
                        .frame(height: 300)
                        .listStyle(.inset)

                        HStack {
                            Text("Kéo-thả trực tiếp các hàng để đổi vị trí.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer(minLength: 0)
                            Button("Khôi phục thứ tự mặc định") {
                                settings.resetPanelCardOrder()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(20)
        }
        .lunarSettingsBackground()
    }

    private var visiblePanelCardCount: Int {
        settings.panelCardOrder.filter { settings.isPanelCardVisible($0) }.count
    }

    // MARK: - System Pane

    private var systemPane: some View {
        ScrollView {
            LazyVStack(spacing: 18) {
                LunarSettingsHeader(
                    title: "Hệ thống",
                    subtitle: "Quản lý hành vi cửa sổ, tự động hóa và nhắc ngày lễ.",
                    icon: "gearshape.2.fill"
                ) {
                    VStack(alignment: .trailing, spacing: 6) {
                        LunarSettingsStatusPill(
                            text: launchAtLoginManager.isEnabled ? "Tự khởi động: Bật" : "Tự khởi động: Tắt",
                            color: launchAtLoginManager.isEnabled ? .accentColor : .secondary
                        )
                        LunarSettingsStatusPill(
                            text: settings.enableHolidayNotifications ? "Nhắc lễ: Bật" : "Nhắc lễ: Tắt",
                            color: settings.enableHolidayNotifications ? .green : .secondary
                        )
                    }
                }

                LunarSettingsCard(
                    title: "Cửa sổ Cài đặt",
                    subtitle: "Hành vi hiển thị cửa sổ",
                    icon: "rectangle.inset.filled.and.person.filled"
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("Luôn ở trên cùng (Floating)", isOn: $settings.keepSettingsOnTop)
                            .lunarSettingsSwitchToggle()
                        Text("Khi bật, cửa sổ Cài đặt sẽ luôn nằm trên các cửa sổ khác để bạn dễ dàng tuỳ chỉnh và quan sát Menu Bar.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                LunarSettingsCard(
                    title: "Tự động hóa",
                    subtitle: "Khởi chạy ứng dụng cùng hệ thống",
                    icon: "power.circle.fill"
                ) {
                    Toggle("Mở LunarV khi đăng nhập máy tính", isOn: launchAtLoginBinding)
                        .lunarSettingsSwitchToggle()
                }

                LunarSettingsCard(
                    title: "Nhắc ngày lễ",
                    subtitle: "Lập lịch thông báo theo lịch âm",
                    icon: "bell.badge.fill"
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Bật thông báo ngày lễ", isOn: holidayNotificationBinding)
                            .lunarSettingsSwitchToggle()

                        Divider()

                        HStack {
                            Text("Nhắc trước")
                                .font(.system(size: 13, weight: .medium))
                            Spacer(minLength: 0)
                            Picker("", selection: $settings.holidayReminderLeadDays) {
                                Text("Đúng ngày").tag(0)
                                Text("Trước 1 ngày").tag(1)
                                Text("Trước 3 ngày").tag(3)
                            }
                            .labelsHidden()
                            .frame(width: 150)
                            .disabled(!settings.enableHolidayNotifications)
                        }

                        HStack {
                            Text("Giờ thông báo")
                                .font(.system(size: 13, weight: .medium))
                            Spacer(minLength: 0)
                            Picker("", selection: $settings.holidayReminderHour) {
                                ForEach([6, 7, 8, 9, 18, 20, 21], id: \.self) { hour in
                                    Text(hourDisplay(hour)).tag(hour)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 150)
                            .disabled(!settings.enableHolidayNotifications)
                        }

                        HStack {
                            Text("Phạm vi lập lịch")
                                .font(.system(size: 13, weight: .medium))
                            Spacer(minLength: 0)
                            Picker("", selection: $settings.notificationWindowDays) {
                                Text("30 ngày tới").tag(30)
                                Text("60 ngày tới").tag(60)
                                Text("90 ngày tới").tag(90)
                                Text("180 ngày tới").tag(180)
                            }
                            .labelsHidden()
                            .frame(width: 150)
                            .disabled(!settings.enableHolidayNotifications)
                        }

                        Text(notificationManager.authorizationDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                LunarSettingsCard(
                    title: "Dữ liệu & Thời gian",
                    subtitle: "Thông số tính toán lịch",
                    icon: "clock.arrow.trianglehead.counterclockwise.rotate.90"
                ) {
                    VStack(spacing: 10) {
                        settingsInfoRow(title: "Múi giờ tính toán", value: "Asia/Ho_Chi_Minh (GMT+7)")
                        Divider()
                        settingsInfoRow(title: "Thuật toán", value: "Vietnamese Lunar Calendar 2.0")
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(20)
        }
        .lunarSettingsBackground()
    }

    @ViewBuilder
    private func settingsInfoRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)
        }
    }

    // MARK: - About Pane

    private var aboutPane: some View {
        ScrollView {
            LazyVStack(spacing: 18) {
                LunarSettingsHeader(
                    title: "Thông tin",
                    subtitle: "Thông tin dự án và hỗ trợ phát triển LunarV.",
                    icon: "info.circle.fill"
                ) {
                    LunarSettingsStatusPill(text: "Phiên bản \(appVersionText)", color: .accentColor)
                }

                LunarSettingsCard(
                    title: "LunarV",
                    subtitle: "Lịch Âm Việt Nam cho macOS",
                    icon: "moon.stars.fill"
                ) {
                    VStack(spacing: 16) {
                        Image(nsImage: NSApp.applicationIconImage)
                            .resizable()
                            .frame(width: 72, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                        VStack(spacing: 4) {
                            Text("LunarV")
                                .font(.title3.bold())
                            Text("Phiên bản \(appVersionText)")
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }

                        Text("Phát triển bởi Phạm Hùng Tiến, mang tinh hoa lịch cổ truyền lên hệ điều hành macOS hiện đại.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 540)

                        donationQRCodeCard
                    }
                    .frame(maxWidth: .infinity)
                }

                LunarSettingsCard(
                    title: "Khôi phục cài đặt",
                    subtitle: "Đưa toàn bộ tuỳ chỉnh về mặc định",
                    icon: "arrow.counterclockwise"
                ) {
                    HStack {
                        Text("Bạn có thể đặt lại nhanh tất cả cấu hình giao diện, hiển thị và thông báo.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 0)
                        Button(role: .destructive) {
                            isShowingResetDialog = true
                        } label: {
                            Label("Khôi phục", systemImage: "arrow.counterclockwise")
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(20)
        }
        .lunarSettingsBackground()
    }

    private var donationQRCodeCard: some View {
        VStack(spacing: 10) {
            Text("Ủng hộ phát triển LunarV")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)

            Image("QRDonate")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 180, height: 180)

            Text("Quét mã QR để ủng hộ dự án.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    // MARK: - Helpers

    private var previewCard: some View {
        VStack(spacing: 8) {
            Text("XEM TRƯỚC")
                .font(.system(size: 9, weight: .heavy))
                .foregroundStyle(.tertiary)

            HStack {
                HStack(spacing: AppSettings.menuBarIconTitleSpacing) {
                    if settings.showMenuBarLeadingIconValue {
                        Image("LunarVMenubar")
                            .resizable()
                            .renderingMode(.template)
                            .interpolation(.high)
                            .scaledToFit()
                            .frame(
                                width: menuBarLeadingIconPreviewSize,
                                height: menuBarLeadingIconPreviewSize
                            )
                    }

                    Text(previewMenuBarTitle)
                        .font(Font(NSFont.menuBarFont(ofSize: settings.menuBarTitleFontSizeCGFloat)))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(settings.customAccentColor.opacity(0.12), in: Capsule())
                .overlay(Capsule().stroke(settings.customAccentColor.opacity(0.3), lineWidth: 1))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 16))
    }

    private func insertToken(_ code: String) {
        if settings.customMenuBarTemplate.isEmpty {
            settings.customMenuBarTemplate = code
        } else {
            settings.customMenuBarTemplate += " " + code
        }
    }

    private func panelCardVisibilityBinding(for card: PanelCardKind) -> Binding<Bool> {
        Binding(
            get: { settings.isPanelCardVisible(card) },
            set: { isVisible in
                settings.setPanelCardVisible(isVisible, for: card)
            }
        )
    }

    private var menuBarTitleFontSizeBinding: Binding<Double> {
        Binding(
            get: { settings.menuBarTitleFontSizeValue },
            set: { settings.setMenuBarTitleFontSize($0) }
        )
    }

    private var menuBarLeadingIconSizeBinding: Binding<Double> {
        Binding(
            get: { settings.menuBarLeadingIconSizeValue },
            set: { settings.setMenuBarLeadingIconSize($0) }
        )
    }

    private var menuBarLeadingIconVisibilityBinding: Binding<Bool> {
        Binding(
            get: { settings.showMenuBarLeadingIconValue },
            set: { settings.setShowMenuBarLeadingIcon($0) }
        )
    }

    private var menuBarLeadingIconPreviewSize: CGFloat {
        let statusBarMax = max(NSStatusBar.system.thickness - 2, 10)
        return min(settings.menuBarLeadingIconSizeCGFloat, statusBarMax)
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(get: { launchAtLoginManager.isEnabled }, set: { launchAtLoginManager.setEnabled($0) })
    }

    private var holidayNotificationBinding: Binding<Bool> {
        Binding(
            get: { settings.enableHolidayNotifications },
            set: { isEnabled in
                guard isEnabled else {
                    settings.enableHolidayNotifications = false
                    Task { @MainActor in
                        await notificationManager.clearPendingHolidayNotifications()
                    }
                    return
                }

                Task { @MainActor in
                    let granted = await notificationManager.requestAuthorizationIfNeeded()
                    settings.enableHolidayNotifications = granted
                    await notificationManager.synchronizeSchedules()
                }
            }
        )
    }

    private func hourDisplay(_ hour: Int) -> String {
        String(format: "%02d:00", hour)
    }

    private var appVersionText: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(v) (\(b))"
    }

    private var previewMenuBarTitle: String {
        let now = Date()
        guard let snapshot = previewLunarService.snapshot(for: now) else {
            return "--"
        }
        let context = MenuBarTitleContext(
            lunarDay: snapshot.lunar.day,
            lunarMonth: snapshot.lunar.month,
            lunarYear: snapshot.lunar.year,
            isLeapMonth: snapshot.lunar.isLeapMonth,
            canChiYear: snapshot.canChiYear,
            zodiac: snapshot.zodiac,
            solarDay: snapshot.solar.day,
            solarMonth: snapshot.solar.month,
            solarYear: snapshot.solar.year
        )
        return MenuBarTitleFormatter.render(
            preset: settings.menuBarDisplayPreset,
            customTemplate: settings.customMenuBarTemplate,
            context: context
        )
    }
}

// MARK: - Pane Definitions

private enum SettingsPane: String, CaseIterable, Identifiable {
    case appearance
    case panel
    case system
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .appearance:
            return "Giao diện"
        case .panel:
            return "Bảng điều khiển"
        case .system:
            return "Hệ thống"
        case .about:
            return "Thông tin"
        }
    }

    var subtitle: String {
        switch self {
        case .appearance:
            return "Màu sắc và hiển thị"
        case .panel:
            return "Sắp xếp card"
        case .system:
            return "Tự động hoá & thông báo"
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
        case .system:
            return "gearshape.2.fill"
        case .about:
            return "info.circle.fill"
        }
    }
}

// MARK: - Settings UI Components

private struct LunarSettingsSidebarRow: View {
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

private struct LunarSettingsStatusPill: View {
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

private struct LunarSettingsHeader<Trailing: View>: View {
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
                    .fill(Color(NSColor.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.primary.opacity(colorScheme == .dark ? 0.2 : 0.08), lineWidth: 1)
                    )

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(accent)
            }
            .frame(width: 42, height: 42)

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
        .padding(16)
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
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.28 : 0.12), radius: 10, x: 0, y: 5)
    }
}

private struct LunarSettingsCard<Content: View, Trailing: View>: View {
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
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.12))
                        .frame(width: 28, height: 28)

                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
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
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.primary.opacity(colorScheme == .dark ? 0.06 : 0.03))

            Divider()
                .opacity(0.5)

            content
                .padding(16)
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

private struct LunarSettingsBackgroundModifier: ViewModifier {
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

private extension View {
    func lunarSettingsBackground() -> some View {
        modifier(LunarSettingsBackgroundModifier())
    }

    func lunarSettingsSwitchToggle() -> some View {
        toggleStyle(.switch)
            .controlSize(.small)
            .tint(Color.accentColor)
    }
}

// MARK: - Token Components

private struct PanelCardOrderRow: View {
    let card: PanelCardKind
    @Binding var isVisible: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: card.icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 24, height: 24)
                .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 7))

            VStack(alignment: .leading, spacing: 2) {
                Text(card.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(card.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isVisible)
                .labelsHidden()
                .lunarSettingsSwitchToggle()
                .help(isVisible ? "Đang hiển thị" : "Đang ẩn")
        }
        .padding(.vertical, 2)
    }
}

private struct DisplayToken: Identifiable {
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

    static let otherTokens = [
        DisplayToken(code: "{al}", label: "Chữ 'ÂL'", color: .secondary),
        DisplayToken(code: "•", label: "Dấu chấm", color: .secondary),
        DisplayToken(code: "/", label: "Gạch chéo", color: .secondary),
        DisplayToken(code: "-", label: "Gạch ngang", color: .secondary),
    ]
}

private struct TokenFlowLayout: View {
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

private struct FlowLayout: Layout {
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
