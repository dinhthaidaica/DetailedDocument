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
    @State private var isShowingResetDialog = false

    private let previewLunarService = VietnameseLunarDateService()

    var body: some View {
        TabView {
            appearanceTab
                .tabItem { Label("Giao diện", systemImage: "paintbrush.fill") }

            panelTab
                .tabItem { Label("Bảng điều khiển", systemImage: "list.bullet.indent") }

            systemTab
                .tabItem { Label("Hệ thống", systemImage: "gearshape.2.fill") }

            aboutTab
                .tabItem { Label("Thông tin", systemImage: "info.circle.fill") }
        }
        .frame(width: 550, height: 520)
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

    // MARK: - Appearance Tab

    private var appearanceTab: some View {
        Form {
            Section("Màu sắc chủ đạo") {
                ColorPicker("Màu nhấn (Accent Color)", selection: $settings.customAccentColor)
                Text("Màu này sẽ áp dụng cho icon và các điểm nhấn trên giao diện.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section("Kiểu hiển thị trên Menu Bar") {
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
                .padding(.vertical, 8)
            }
        }
        .formStyle(.grouped)
    }

    private var customTemplateEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Mẫu tuỳ chỉnh").font(.caption.bold()).foregroundStyle(.secondary)
                TextField("Ví dụ: {dd}/{mm} ÂL", text: $settings.customMenuBarTemplate)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
            }

            Text("Chạm để chèn nhanh mã hiển thị:").font(.caption).foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 10) {
                // Nhóm Âm lịch
                Text("ÂM LỊCH").font(.system(size: 9, weight: .heavy)).foregroundStyle(.orange.opacity(0.8))
                TokenFlowLayout(tokens: DisplayToken.lunarTokens) { token in
                    insertToken(token.code)
                }

                // Nhóm Dương lịch
                Text("DƯƠNG LỊCH").font(.system(size: 9, weight: .heavy)).foregroundStyle(.blue.opacity(0.8))
                TokenFlowLayout(tokens: DisplayToken.solarTokens) { token in
                    insertToken(token.code)
                }
                
                // Nhóm Khác
                Text("KHÁC").font(.system(size: 9, weight: .heavy)).foregroundStyle(.secondary)
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

    // MARK: - Panel Tab

    private var panelTab: some View {
        Form {
            Section("Các thành phần hiển thị") {
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
                .frame(height: 280)
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
        .formStyle(.grouped)
    }

    // MARK: - System Tab

    private var systemTab: some View {
        Form {
            Section("Cửa sổ Cài đặt") {
                Toggle("Luôn ở trên cùng (Floating)", isOn: $settings.keepSettingsOnTop)
                Text("Khi bật, cửa sổ Cài đặt sẽ luôn nằm trên các cửa sổ khác để bạn dễ dàng tuỳ chỉnh và quan sát Menu Bar.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section("Tự động hóa") {
                Toggle("Mở LunarV khi đăng nhập máy tính", isOn: launchAtLoginBinding)
            }

            Section("Nhắc ngày lễ") {
                Toggle("Bật thông báo ngày lễ", isOn: holidayNotificationBinding)

                Picker("Nhắc trước", selection: $settings.holidayReminderLeadDays) {
                    Text("Đúng ngày").tag(0)
                    Text("Trước 1 ngày").tag(1)
                    Text("Trước 3 ngày").tag(3)
                }
                .disabled(!settings.enableHolidayNotifications)

                Picker("Giờ thông báo", selection: $settings.holidayReminderHour) {
                    ForEach([6, 7, 8, 9, 18, 20, 21], id: \.self) { hour in
                        Text(hourDisplay(hour)).tag(hour)
                    }
                }
                .disabled(!settings.enableHolidayNotifications)

                Picker("Phạm vi lập lịch", selection: $settings.notificationWindowDays) {
                    Text("30 ngày tới").tag(30)
                    Text("60 ngày tới").tag(60)
                    Text("90 ngày tới").tag(90)
                    Text("180 ngày tới").tag(180)
                }
                .disabled(!settings.enableHolidayNotifications)

                Text(notificationManager.authorizationDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Dữ liệu & Thời gian") {
                LabeledContent("Múi giờ tính toán", value: "Asia/Ho_Chi_Minh (GMT+7)")
                LabeledContent("Thuật toán", value: "Vietnamese Lunar Calendar 2.0")
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - About Tab

    private var aboutTab: some View {
        VStack(spacing: 20) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable().frame(width: 64, height: 64)
            
            VStack(spacing: 4) {
                Text("LunarV").font(.title2.bold())
                Text("Phiên bản \(appVersionText)").font(.caption).monospaced().foregroundStyle(.secondary)
            }

            Text("Phát triển bởi Phạm Hùng Tiến, mang tinh hoa lịch cổ truyền lên hệ điều hành macOS hiện đại.")
                .font(.callout).multilineTextAlignment(.center).padding(.horizontal, 50)

            donationQRCodeCard

            Spacer(minLength: 0)

            Button(role: .destructive) { isShowingResetDialog = true } label: {
                Label("Khôi phục cài đặt gốc", systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(.bordered).padding(.bottom, 30)
        }
        .padding(.top, 40)
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
                .clipShape(RoundedRectangle(cornerRadius: 14))

            Text("Quét mã QR để ủng hộ dự án.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Helpers

    private var previewCard: some View {
        VStack(spacing: 8) {
            Text("XEM TRƯỚC").font(.system(size: 9, weight: .heavy)).foregroundStyle(.tertiary)
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
                        .font(.system(size: settings.menuBarTitleFontSizeCGFloat, weight: .semibold, design: .rounded))
                        .monospacedDigit()
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
        return MenuBarTitleFormatter.render(preset: settings.menuBarDisplayPreset, customTemplate: settings.customMenuBarTemplate, context: context)
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
        DisplayToken(code: "{leap}", label: "Nhuận", color: .orange)
    ]

    static let solarTokens = [
        DisplayToken(code: "{sd}", label: "Ngày DL", color: .blue),
        DisplayToken(code: "{sdd}", label: "Ngày DL (01)", color: .blue),
        DisplayToken(code: "{sm}", label: "Tháng DL", color: .blue),
        DisplayToken(code: "{smm}", label: "Tháng DL (01)", color: .blue),
        DisplayToken(code: "{sy}", label: "Năm DL", color: .blue)
    ]
    
    static let otherTokens = [
        DisplayToken(code: "{al}", label: "Chữ 'ÂL'", color: .secondary),
        DisplayToken(code: "•", label: "Dấu chấm", color: .secondary),
        DisplayToken(code: "/", label: "Gạch chéo", color: .secondary),
        DisplayToken(code: "-", label: "Gạch ngang", color: .secondary)
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
                        Text(token.code).font(.system(size: 10, weight: .bold, design: .monospaced))
                        Text(token.label).font(.system(size: 9))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(token.color.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(token.color.opacity(0.2), lineWidth: 1))
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
        let maxWidth: CGFloat = proposal.width ?? 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            offsets.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            totalHeight = max(totalHeight, currentY + size.height)
        }

        return (CGSize(width: maxWidth, height: totalHeight), offsets)
    }
}
