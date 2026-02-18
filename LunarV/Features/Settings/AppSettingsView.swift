//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import AppKit
import Sparkle
import SwiftUI

struct AppSettingsView: View {
    let updater: SPUUpdater

    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var notificationManager: HolidayNotificationManager
    @StateObject private var launchAtLoginManager = LaunchAtLoginManager()
    @State private var selectedPane: SettingsPane = .appearance
    @State private var isShowingResetDialog = false
    @State private var searchText = ""
    @State private var isShowingFontPicker = false
    @State private var fontSearchText = ""
    @State private var automaticallyChecksForUpdates: Bool

    private let previewLunarService = VietnameseLunarDateService()
    private let trailingControlColumnWidth: CGFloat = 170
    private let recommendedFontFamilies = [
        "SF Pro Text",
        "Avenir Next",
        "Helvetica Neue",
        "Menlo",
        "Be Vietnam Pro",
    ]

    init(updater: SPUUpdater) {
        self.updater = updater
        _automaticallyChecksForUpdates = State(initialValue: updater.automaticallyChecksForUpdates)
    }

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
        .tint(.accentColor)
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
            automaticallyChecksForUpdates = updater.automaticallyChecksForUpdates
        }
        .onChange(of: automaticallyChecksForUpdates) { _, newValue in
            updater.automaticallyChecksForUpdates = newValue
        }
        .confirmationDialog(
            "Khôi phục cài đặt mặc định?",
            isPresented: $isShowingResetDialog,
            titleVisibility: .visible
        ) {
            Button("Xác nhận khôi phục", role: .destructive) { settings.resetAllSettings() }
            Button("Huỷ", role: .cancel) {}
        } message: {
            Text("Tất cả các tuỳ chỉnh về hiển thị và thông báo sẽ quay về giá trị ban đầu.")
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(selection: $selectedPane) {
            ForEach(filteredPanes) { pane in
                LunarSettingsSidebarRow(pane: pane)
                    .tag(pane)
                    .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 160, ideal: 200, max: 240)
        .searchable(text: $searchText, placement: .sidebar, prompt: "Tìm kiếm cài đặt...")
    }

    private var filteredPanes: [SettingsPane] {
        if searchText.isEmpty {
            return SettingsPane.allCases
        } else {
            return SettingsPane.allCases.filter { pane in
                pane.title.localizedCaseInsensitiveContains(searchText) ||
                pane.subtitle.localizedCaseInsensitiveContains(searchText) ||
                pane.searchKeywords.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
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
            LazyVStack(spacing: 12) {
                LunarSettingsHeader(
                    title: "Giao diện",
                    subtitle: "Tùy chỉnh cách hiển thị LunarV trên thanh Menu Bar.",
                    icon: "paintbrush.fill"
                ) {
                    VStack(alignment: .trailing, spacing: 6) {
                        LunarSettingsStatusPill(text: settings.menuBarDisplayPreset.title, color: .accentColor)
                        LunarSettingsStatusPill(
                            text: "Font: \(menuBarFontStatusText)",
                            color: settings.menuBarTitleFontFamilyValue.isEmpty ? .secondary : .accentColor
                        )
                        LunarSettingsStatusPill(
                            text: settings.showMenuBarLeadingIconValue ? "Icon: Bật" : "Icon: Tắt",
                            color: settings.showMenuBarLeadingIconValue ? .green : .secondary
                        )
                    }
                }

                LunarSettingsCard(
                    title: "Kiểu hiển thị Menu Bar",
                    subtitle: "Preset nhanh hoặc mẫu tuỳ chỉnh",
                    icon: "menubar.rectangle"
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        previewCard

                        settingsPickerRow(title: "Chế độ", isEnabled: true) {
                            Picker("Chế độ", selection: $settings.menuBarDisplayPreset) {
                                ForEach(MenuBarDisplayPreset.allCases) { preset in
                                    Text(preset.title).tag(preset)
                                }
                            }
                            .pickerStyle(.menu)
                            .controlSize(.regular)
                        }

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
                        menuBarTitleTypographyControl
                        menuBarLeadingIconControl
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(14)
        }
        .lunarSettingsBackground()
    }

    private var customTemplateEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Mẫu tuỳ chỉnh")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                TextField("Ví dụ: {dd}/{mm} {al} • {wds} • {hh}:{min}:{ss}", text: $settings.customMenuBarTemplate)
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

                Text("THỜI GIAN")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundStyle(.mint.opacity(0.8))
                TokenFlowLayout(tokens: DisplayToken.timeTokens) { token in
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
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Kích cỡ chữ trên Menu Bar")
                    .font(.system(size: 13, weight: .medium))
                Spacer(minLength: 0)
                Text("\(settings.menuBarTitleFontSizeValue.formatted(.number.precision(.fractionLength(1))))pt")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            continuousMacSlider(
                value: menuBarTitleFontSizeBinding,
                range: AppSettings.menuBarTitleFontSizeRange
            )

            HStack {
                Text("Cỡ chữ này áp dụng cho phần ngày hiển thị trên thanh Menu Bar.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)

                Button("Mặc định 12pt") {
                    settings.setMenuBarTitleFontSize(AppSettings.defaultMenuBarTitleFontSize)
                }
                .buttonStyle(.link)
            }
        }
    }

    private var menuBarTitleTypographyControl: some View {
        VStack(alignment: .leading, spacing: 10) {
            settingsPickerRow(title: "Phông chữ", isEnabled: true) {
                menuBarFontPickerButton
            }

            if !settings.menuBarTitleFontFamilyValue.isEmpty && !isValidFontFamily(settings.menuBarTitleFontFamilyValue) {
                Text("Font này chưa khả dụng trên máy, LunarV sẽ tự dùng font mặc định để đảm bảo dễ đọc.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Định dạng chữ")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    MenuBarTextStyleButton(
                        title: "Đậm",
                        symbol: "bold",
                        isEnabled: menuBarTitleBoldBinding
                    )
                    MenuBarTextStyleButton(
                        title: "Nghiêng",
                        symbol: "italic",
                        isEnabled: menuBarTitleItalicBinding
                    )
                    MenuBarTextStyleButton(
                        title: "Gạch chân",
                        symbol: "underline",
                        isEnabled: menuBarTitleUnderlineBinding
                    )
                }
            }

            HStack {
                Text("Ưu tiên font đậm vừa phải để menu bar rõ nhưng không quá nặng.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)

                Button("Mặc định kiểu chữ") {
                    settings.setMenuBarTitleFontFamily(AppSettings.defaultMenuBarTitleFontFamily)
                    settings.setMenuBarTitleBold(AppSettings.defaultMenuBarTitleBold)
                    settings.setMenuBarTitleItalic(AppSettings.defaultMenuBarTitleItalic)
                    settings.setMenuBarTitleUnderline(AppSettings.defaultMenuBarTitleUnderline)
                }
                .buttonStyle(.link)
            }
        }
    }

    private var menuBarLeadingIconControl: some View {
        VStack(alignment: .leading, spacing: 6) {
            settingsToggleRow(
                title: "Hiển thị icon bên trái ngày trên Menu Bar",
                isOn: menuBarLeadingIconVisibilityBinding
            )

            if settings.showMenuBarLeadingIconValue {
                HStack {
                    Text("Kích cỡ icon")
                        .font(.system(size: 13, weight: .medium))
                    Spacer(minLength: 0)
                    Text("\(settings.menuBarLeadingIconSizeValue.formatted(.number.precision(.fractionLength(1))))pt")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                continuousMacSlider(
                    value: menuBarLeadingIconSizeBinding,
                    range: AppSettings.menuBarLeadingIconSizeRange
                )

                Text("Apple khuyến nghị icon menu bar nên gọn để cân bằng với chữ và độ dày thanh menu.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Panel Pane

    private var panelPane: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
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
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Kéo để đổi thứ tự card, gạt công tắc để ẩn/hiện.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 8) {
                            PanelCardHintChip(icon: "line.3.horizontal", text: "Kéo để đổi vị trí")
                            PanelCardHintChip(icon: "eye.fill", text: "Bật/tắt để ẩn hiện")
                            Spacer(minLength: 0)
                            Text("\(settings.panelCardOrder.count) mục")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }

                        panelOrderList

                        HStack {
                            Text("Kéo-thả trực tiếp trên từng hàng.")
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
            .padding(14)
        }
        .lunarSettingsBackground()
    }

    private var visiblePanelCardCount: Int {
        settings.panelCardOrder.filter { settings.isPanelCardVisible($0) }.count
    }

    private var panelOrderList: some View {
        List {
            ForEach(settings.panelCardOrder) { card in
                PanelCardOrderRow(
                    card: card,
                    isVisible: panelCardVisibilityBinding(for: card)
                )
                .listRowInsets(EdgeInsets(top: 3, leading: 8, bottom: 3, trailing: 8))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            .onMove(perform: settings.movePanelCard)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .frame(height: panelOrderListHeight)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.primary.opacity(0.035))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var panelOrderListHeight: CGFloat {
        let rowHeight: CGFloat = 54
        let visibleRows = min(max(settings.panelCardOrder.count, 4), 8)
        return CGFloat(visibleRows) * rowHeight
    }

    // MARK: - System Pane

    private var systemPane: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
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
                        settingsToggleRow(
                            title: "Luôn ở trên cùng (Floating)",
                            isOn: $settings.keepSettingsOnTop
                        )
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
                    settingsToggleRow(
                        title: "Mở LunarV khi đăng nhập máy tính",
                        isOn: launchAtLoginBinding
                    )
                }

                LunarSettingsCard(
                    title: "Nhắc ngày lễ",
                    subtitle: "Lập lịch thông báo theo lịch âm",
                    icon: "bell.badge.fill"
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        settingsToggleRow(
                            title: "Bật thông báo ngày lễ",
                            isOn: holidayNotificationBinding
                        )

                        Divider()

                        settingsPickerRow(
                            title: "Nhắc trước",
                            isEnabled: settings.enableHolidayNotifications
                        ) {
                            Picker("", selection: $settings.holidayReminderLeadDays) {
                                Text("Đúng ngày").tag(0)
                                Text("Trước 1 ngày").tag(1)
                                Text("Trước 3 ngày").tag(3)
                            }
                        }

                        settingsPickerRow(
                            title: "Giờ thông báo",
                            isEnabled: settings.enableHolidayNotifications
                        ) {
                            Picker("", selection: $settings.holidayReminderHour) {
                                ForEach([6, 7, 8, 9, 18, 20, 21], id: \.self) { hour in
                                    Text(hourDisplay(hour)).tag(hour)
                                }
                            }
                        }

                        settingsPickerRow(
                            title: "Phạm vi lập lịch",
                            isEnabled: settings.enableHolidayNotifications
                        ) {
                            Picker("", selection: $settings.notificationWindowDays) {
                                Text("30 ngày tới").tag(30)
                                Text("60 ngày tới").tag(60)
                                Text("90 ngày tới").tag(90)
                                Text("180 ngày tới").tag(180)
                            }
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
            .padding(14)
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
            LazyVStack(spacing: 12) {
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
                    title: "Cập nhật ứng dụng",
                    subtitle: "Kiểm tra phiên bản mới từ GitHub Releases",
                    icon: "arrow.down.circle.fill"
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        settingsToggleRow(
                            title: "Tự động kiểm tra cập nhật",
                            isOn: $automaticallyChecksForUpdates
                        )

                        Text("Khi bật, LunarV sẽ tự kiểm tra bản mới theo lịch của Sparkle.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack {
                            CheckForUpdatesView(updater: updater)
                            Spacer(minLength: 0)
                        }
                    }
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
            .padding(14)
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

                    TimelineView(.periodic(from: .now, by: 1)) { timeline in
                        Text(previewMenuBarTitle(at: timeline.date))
                            .font(Font(previewMenuBarFont))
                            .underline(settings.menuBarTitleUnderlineValue)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.accentColor.opacity(0.12), in: Capsule())
                .overlay(Capsule().stroke(Color.accentColor.opacity(0.3), lineWidth: 1))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 16))
    }

    private func insertToken(_ code: String) {
        var template = settings.customMenuBarTemplate
        let compactSeparators: Set<String> = [":", "/", "-"]

        guard !template.isEmpty else {
            settings.customMenuBarTemplate = code
            return
        }

        if compactSeparators.contains(code), template.hasSuffix(" ") {
            template.removeLast()
        }

        let trailingSeparator = template.last.map { compactSeparators.contains(String($0)) } ?? false
        if compactSeparators.contains(code) || trailingSeparator {
            template += code
        } else if template.hasSuffix(" ") {
            template += code
        } else {
            template += " " + code
        }

        settings.customMenuBarTemplate = template
    }

    private func panelCardVisibilityBinding(for card: PanelCardKind) -> Binding<Bool> {
        Binding(
            get: { settings.isPanelCardVisible(card) },
            set: { isVisible in
                settings.setPanelCardVisible(isVisible, for: card)
            }
        )
    }

    @ViewBuilder
    private func settingsToggleRow(title: String, isOn: Binding<Bool>) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)

            Spacer(minLength: 0)

            Toggle("", isOn: isOn)
                .labelsHidden()
                .lunarSettingsSwitchToggle()
                .frame(width: trailingControlColumnWidth, alignment: .trailing)
        }
    }

    @ViewBuilder
    private func settingsPickerRow<Control: View>(
        title: String,
        isEnabled: Bool,
        @ViewBuilder control: () -> Control
    ) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)

            Spacer(minLength: 0)

            control()
                .labelsHidden()
                .frame(width: trailingControlColumnWidth, alignment: .trailing)
                .disabled(!isEnabled)
        }
    }

    private var menuBarTitleFontSizeBinding: Binding<Double> {
        Binding(
            get: { settings.menuBarTitleFontSizeValue },
            set: { settings.setMenuBarTitleFontSize($0) }
        )
    }

    private var menuBarTitleBoldBinding: Binding<Bool> {
        Binding(
            get: { settings.menuBarTitleBoldValue },
            set: { settings.setMenuBarTitleBold($0) }
        )
    }

    private var menuBarTitleItalicBinding: Binding<Bool> {
        Binding(
            get: { settings.menuBarTitleItalicValue },
            set: { settings.setMenuBarTitleItalic($0) }
        )
    }

    private var menuBarTitleUnderlineBinding: Binding<Bool> {
        Binding(
            get: { settings.menuBarTitleUnderlineValue },
            set: { settings.setMenuBarTitleUnderline($0) }
        )
    }

    private var installedFontFamilies: [String] {
        NSFontManager.shared.availableFontFamilies.sorted()
    }

    private var recommendedFontPickerOptions: [String] {
        let installed = Set(installedFontFamilies)
        return recommendedFontFamilies.filter { installed.contains($0) }
    }

    private var filteredFontPickerOptions: [String] {
        let query = fontSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return installedFontFamilies
        }
        return installedFontFamilies.filter { $0.localizedCaseInsensitiveContains(query) }
    }

    private var filteredRecommendedFontPickerOptions: [String] {
        let filtered = Set(filteredFontPickerOptions)
        return recommendedFontPickerOptions.filter { filtered.contains($0) }
    }

    private var filteredOtherFontPickerOptions: [String] {
        let recommended = Set(recommendedFontPickerOptions)
        return filteredFontPickerOptions.filter { !recommended.contains($0) }
    }

    private var menuBarFontPickerButton: some View {
        Button {
            fontSearchText = ""
            isShowingFontPicker = true
        } label: {
            HStack(spacing: 8) {
                Text(menuBarFontStatusText)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(width: trailingControlColumnWidth, alignment: .trailing)
            .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .popover(isPresented: $isShowingFontPicker, arrowEdge: .top) {
            menuBarFontPickerPopover
        }
    }

    private var menuBarFontPickerPopover: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Chọn phông chữ Menu Bar")
                .font(.system(size: 12, weight: .semibold))

            TextField("Tìm phông chữ...", text: $fontSearchText)
                .textFieldStyle(.roundedBorder)

            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    MenuBarFontPickerRow(
                        title: "Mặc định hệ thống",
                        subtitle: "Tối ưu cho macOS Menu Bar",
                        previewFontName: nil,
                        isSelected: settings.menuBarTitleFontFamilyValue.isEmpty
                    ) {
                        settings.setMenuBarTitleFontFamily(AppSettings.defaultMenuBarTitleFontFamily)
                        isShowingFontPicker = false
                    }

                    if !filteredRecommendedFontPickerOptions.isEmpty {
                        Text("Gợi ý")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)

                        ForEach(filteredRecommendedFontPickerOptions, id: \.self) { family in
                            MenuBarFontPickerRow(
                                title: family,
                                subtitle: "Khuyến nghị hiển thị rõ trên menu",
                                previewFontName: family,
                                isSelected: settings.menuBarTitleFontFamilyValue == family
                            ) {
                                settings.setMenuBarTitleFontFamily(family)
                                isShowingFontPicker = false
                            }
                        }
                    }

                    if !filteredOtherFontPickerOptions.isEmpty {
                        Text("Tất cả phông chữ")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)

                        ForEach(filteredOtherFontPickerOptions, id: \.self) { family in
                            MenuBarFontPickerRow(
                                title: family,
                                subtitle: family,
                                previewFontName: family,
                                isSelected: settings.menuBarTitleFontFamilyValue == family
                            ) {
                                settings.setMenuBarTitleFontFamily(family)
                                isShowingFontPicker = false
                            }
                        }
                    }

                    if filteredFontPickerOptions.isEmpty {
                        Text("Không tìm thấy phông chữ phù hợp.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 10)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 330)
        }
        .padding(12)
        .frame(width: 340)
    }

    private var menuBarFontStatusText: String {
        settings.menuBarTitleFontFamilyValue.isEmpty ? "Hệ thống" : settings.menuBarTitleFontFamilyValue
    }

    private var previewMenuBarFont: NSFont {
        MenuBarFontResolver.resolve(
            family: settings.menuBarTitleFontFamilyValue,
            size: settings.menuBarTitleFontSizeCGFloat,
            bold: settings.menuBarTitleBoldValue,
            italic: settings.menuBarTitleItalicValue
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

    @ViewBuilder
    private func continuousMacSlider(value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        HStack(spacing: 8) {
            Text("\(Int(range.lowerBound))")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(minWidth: 16, alignment: .trailing)

            Slider(value: value, in: range)
                .controlSize(.small)
                .tint(Color(nsColor: .controlAccentColor))

            Text("\(Int(range.upperBound))")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(minWidth: 16, alignment: .leading)
        }
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

    private func isValidFontFamily(_ family: String) -> Bool {
        guard !family.isEmpty else {
            return true
        }
        return NSFontManager.shared.availableFontFamilies.contains(family)
    }


    private func previewMenuBarTitle(at now: Date) -> String {
        guard let snapshot = previewLunarService.snapshot(for: now) else {
            return "--"
        }
        let timeComponents = previewLunarService.calendar.dateComponents([.hour, .minute, .second], from: now)
        let context = MenuBarTitleContext(
            lunarDay: snapshot.lunar.day,
            lunarMonth: snapshot.lunar.month,
            lunarYear: snapshot.lunar.year,
            isLeapMonth: snapshot.lunar.isLeapMonth,
            canChiYear: snapshot.canChiYear,
            zodiac: snapshot.zodiac,
            solarDay: snapshot.solar.day,
            solarMonth: snapshot.solar.month,
            solarYear: snapshot.solar.year,
            solarWeekdayName: previewLunarService.weekdayName(from: snapshot.solar.weekday),
            solarWeekdayShortName: previewLunarService.weekdayShortName(from: snapshot.solar.weekday),
            hour: timeComponents.hour ?? 0,
            minute: timeComponents.minute ?? 0,
            second: timeComponents.second ?? 0
        )
        return MenuBarTitleFormatter.render(
            preset: settings.menuBarDisplayPreset,
            customTemplate: settings.customMenuBarTemplate,
            context: context
        )
    }
}

