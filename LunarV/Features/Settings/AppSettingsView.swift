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
    @State private var searchText = ""
    @State private var isShowingFontPicker = false
    @State private var fontSearchText = ""

    private let previewLunarService = VietnameseLunarDateService()
    private let trailingControlColumnWidth: CGFloat = 170
    private let recommendedFontFamilies = [
        "SF Pro Text",
        "Avenir Next",
        "Helvetica Neue",
        "Menlo",
        "Be Vietnam Pro",
    ]

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
        resolvedMenuBarFont(size: settings.menuBarTitleFontSizeCGFloat)
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

    private func resolvedMenuBarFont(size: CGFloat) -> NSFont {
        let desiredFamily = settings.menuBarTitleFontFamilyValue
        let traits = settings.menuBarTitleItalicValue ? NSFontTraitMask.italicFontMask : []
        let weight = settings.menuBarTitleBoldValue ? 9 : 5

        if !desiredFamily.isEmpty,
           let custom = NSFontManager.shared.font(
               withFamily: desiredFamily,
               traits: traits,
               weight: weight,
               size: size
           ) {
            return custom
        }

        let base = NSFont.menuBarFont(ofSize: size)
        let descriptorTraits = resolvedSymbolicTraits(for: base.fontDescriptor.symbolicTraits)
        let descriptor = base.fontDescriptor.withSymbolicTraits(descriptorTraits)
        if let resolved = NSFont(descriptor: descriptor, size: size) {
            return resolved
        }
        return base
    }

    private func resolvedSymbolicTraits(for current: NSFontDescriptor.SymbolicTraits) -> NSFontDescriptor.SymbolicTraits {
        var traits = current
        if settings.menuBarTitleBoldValue {
            traits.insert(.bold)
        } else {
            traits.remove(.bold)
        }
        if settings.menuBarTitleItalicValue {
            traits.insert(.italic)
        } else {
            traits.remove(.italic)
        }
        return traits
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

    /// Các từ khoá tìm kiếm mở rộng cho từng tab
    var searchKeywords: [String] {
        switch self {
        case .appearance:
            return ["menu bar", "chế độ", "mẫu tuỳ chỉnh", "template", "cỡ chữ", "font", "icon", "biểu tượng", "xem trước", "paintbrush", "thứ", "giờ", "phút", "giây", "time", "weekday", "đậm", "nghiêng", "gạch chân", "bold", "italic", "underline", "phông chữ"]
        case .panel:
            return ["card", "thành phần", "thứ tự", "sắp xếp", "ẩn hiện", "hiển thị", "list", "kéo thả"]
        case .system:
            return ["khởi động", "đăng nhập", "login", "tự động", "thông báo", "ngày lễ", "nhắc nhở", "holiday", "múi giờ", "timezone", "thuật toán", "algorithm", "gear"]
        case .about:
            return ["phiên bản", "version", "tác giả", "ủng hộ", "donate", "qr", "khôi phục", "reset", "đặt lại", "info"]
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
            .tint(Color(nsColor: .controlAccentColor))
    }
}

// MARK: - Token Components

private struct PanelCardOrderRow: View {
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

private struct PanelCardHintChip: View {
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

private struct MenuBarFontPickerRow: View {
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

private struct MenuBarTextStyleButton: View {
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
