import AppKit
import SwiftUI

struct AppSettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @StateObject private var launchAtLoginManager = LaunchAtLoginManager()
    @State private var isShowingResetDialog = false

    private let previewConverter = VietnameseLunarCalendarConverter(timeZone: 7.0)
    private let templateTokens = MenuBarTemplateToken.allCases

    var body: some View {
        TabView {
            appearanceContent
                .tabItem {
                    Label("Hiển thị", systemImage: "menubar.rectangle")
                }

            systemContent
                .tabItem {
                    Label("Hệ thống", systemImage: "gearshape.2")
                }

            aboutContent
                .tabItem {
                    Label("Thông tin", systemImage: "info.circle")
                }
        }
        .onAppear {
            launchAtLoginManager.refreshStatus()
        }
        .confirmationDialog(
            "Khôi phục cài đặt hiển thị mặc định?",
            isPresented: $isShowingResetDialog,
            titleVisibility: .visible
        ) {
            Button("Khôi phục", role: .destructive) {
                settings.resetMenuBarDisplaySettings()
            }
            Button("Huỷ", role: .cancel) {}
        } message: {
            Text("Preset sẽ về 'Gọn' và mẫu tuỳ chỉnh sẽ bị xoá.")
        }
    }

    // MARK: - Appearance Content

    private var appearanceContent: some View {
        Form {
            Section {
                previewCard
            }

            Section("Kiểu hiển thị menu bar") {
                Picker("Preset", selection: $settings.menuBarDisplayPreset) {
                    ForEach(MenuBarDisplayPreset.allCases) { preset in
                        Text(preset.title).tag(preset)
                    }
                }
                .pickerStyle(.segmented)

                Text(settings.menuBarDisplayPreset.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if settings.menuBarDisplayPreset == .custom {
                Section("Mẫu tuỳ chỉnh") {
                    TextField("Ví dụ: {dd}/{mm} {al} • {cy}", text: $settings.customMenuBarTemplate)
                        .textFieldStyle(.roundedBorder)

                    Text("Mẫu gợi ý")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        ForEach(templateSamples) { sample in
                            Button(sample.title) {
                                applyTemplate(sample.template)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .help(sample.template)
                        }
                    }

                    Text("Chạm token để chèn nhanh")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 96), spacing: 8)],
                        alignment: .leading,
                        spacing: 8
                    ) {
                        ForEach(templateTokens) { token in
                            Button {
                                insertToken(token.rawValue)
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(token.rawValue)
                                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                        .foregroundStyle(.primary)
                                    Text(token.shortLabel)
                                        .font(.system(size: 9, weight: .medium, design: .rounded))
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .help(token.helpText)
                        }
                    }

                    Text("Token khả dụng: {d}, {dd}, {m}, {mm}, {cy}, {z}, {al}, {leap}, {sd}, {sdd}, {sm}, {smm}, {yyyy}, {sy}")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Khôi phục") {
                Button(role: .destructive) {
                    isShowingResetDialog = true
                } label: {
                    Label("Khôi phục cài đặt hiển thị", systemImage: "arrow.counterclockwise")
                }
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Preview Card

    private var previewCard: some View {
        LabeledContent {
            HStack(spacing: 8) {
                Text(previewMenuBarTitle)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .contentTransition(.numericText())

                Button {
                    copyPreviewToPasteboard()
                } label: {
                    Image(systemName: "document.on.document")
                }
                .buttonStyle(.borderless)
                .help("Sao chép nội dung xem trước")
            }
        } label: {
            Label("Xem trước menu bar", systemImage: "menubar.rectangle")
        }
    }

    // MARK: - System Content

    private var systemContent: some View {
        Form {
            Section("Khởi động cùng hệ thống") {
                Toggle("Mở LunarV khi đăng nhập", isOn: launchAtLoginBinding)

                Text("Thiết lập này dùng ServiceManagement của macOS và áp dụng ngay.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let statusHint = launchAtLoginManager.statusHint {
                    StatusMessageRow(
                        icon: "exclamationmark.triangle.fill",
                        tint: .orange,
                        message: statusHint
                    )
                }

                if let errorMessage = launchAtLoginManager.errorMessage {
                    StatusMessageRow(
                        icon: "xmark.octagon.fill",
                        tint: .red,
                        message: errorMessage
                    )
                }

                if launchAtLoginManager.statusHint != nil {
                    Button("Mở Cài đặt hệ thống > Đăng nhập") {
                        openLoginItemsSettings()
                    }
                }

                Button("Làm mới trạng thái") {
                    launchAtLoginManager.refreshStatus()
                }
                .buttonStyle(.link)
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - About Content

    private var aboutContent: some View {
        Form {
            Section("Ứng dụng") {
                LabeledContent("Phiên bản") {
                    Text(appVersionText)
                }
                LabeledContent("Múi giờ lịch âm") {
                    Text("Asia/Ho_Chi_Minh (GMT+7)")
                }
                LabeledContent("Hệ điều hành") {
                    Text("macOS \(ProcessInfo.processInfo.operatingSystemVersionString)")
                }
            }

            Section("Giới thiệu") {
                Text("LunarV hiển thị lịch âm Việt Nam trực tiếp trên menu bar. Ứng dụng tự động cập nhật theo thời gian thực, hỗ trợ Can Chi, tiết khí, con giáp và nhiều tính năng khác.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Helpers

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { launchAtLoginManager.isEnabled },
            set: { launchAtLoginManager.setEnabled($0) }
        )
    }

    private var templateSamples: [TemplateSample] {
        [
            TemplateSample(title: "Gọn", template: "{dd}/{mm} {al}"),
            TemplateSample(title: "Tiêu chuẩn", template: "{dd}/{mm} {al} {cy}"),
            TemplateSample(title: "Chi tiết", template: "{dd}/{mm} {al} • {cy} • {z}"),
        ]
    }

    private var appVersionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        return "\(version) (\(build))"
    }

    private func applyTemplate(_ template: String) {
        settings.menuBarDisplayPreset = .custom
        settings.customMenuBarTemplate = template
    }

    private func copyPreviewToPasteboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(previewMenuBarTitle, forType: .string)
    }

    private func openLoginItemsSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    private func insertToken(_ token: String) {
        let text = settings.customMenuBarTemplate
        if text.isEmpty {
            settings.customMenuBarTemplate = token
            return
        }

        if text.hasSuffix(" ") {
            settings.customMenuBarTemplate += token
        } else {
            settings.customMenuBarTemplate += " \(token)"
        }
    }

    private var previewMenuBarTitle: String {
        let now = Date()

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh") ?? .current

        let components = calendar.dateComponents([.day, .month, .year], from: now)
        guard
            let day = components.day,
            let month = components.month,
            let year = components.year
        else {
            return "--"
        }

        let lunar = previewConverter.solarToLunar(day: day, month: month, year: year)

        let context = MenuBarTitleContext(
            lunarDay: lunar.day,
            lunarMonth: lunar.month,
            lunarYear: lunar.year,
            isLeapMonth: lunar.isLeapMonth,
            canChiYear: VietnameseCalendarMetadata.canChiYear(lunarYear: lunar.year),
            zodiac: VietnameseCalendarMetadata.zodiac(lunarYear: lunar.year),
            solarDay: day,
            solarMonth: month,
            solarYear: year
        )

        return MenuBarTitleFormatter.render(
            preset: settings.menuBarDisplayPreset,
            customTemplate: settings.customMenuBarTemplate,
            context: context
        )
    }
}

// MARK: - Supporting Types

private struct TemplateSample: Identifiable {
    let title: String
    let template: String

    var id: String { "\(title)-\(template)" }
}

private struct StatusMessageRow: View {
    let icon: String
    let tint: Color
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .frame(width: 14)
                .padding(.top, 1)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private enum MenuBarTemplateToken: String, CaseIterable, Identifiable {
    case d = "{d}"
    case dd = "{dd}"
    case m = "{m}"
    case mm = "{mm}"
    case yyyy = "{yyyy}"
    case sy = "{sy}"
    case sd = "{sd}"
    case sdd = "{sdd}"
    case sm = "{sm}"
    case smm = "{smm}"
    case cy = "{cy}"
    case z = "{z}"
    case al = "{al}"
    case leap = "{leap}"

    var id: String { rawValue }

    var shortLabel: String {
        switch self {
        case .d: return "Ngày âm"
        case .dd: return "Ngày âm 2 số"
        case .m: return "Tháng âm"
        case .mm: return "Tháng âm 2 số"
        case .yyyy: return "Năm âm số"
        case .sy: return "Năm dương số"
        case .sd: return "Ngày dương"
        case .sdd: return "Ngày dương 2 số"
        case .sm: return "Tháng dương"
        case .smm: return "Tháng dương 2 số"
        case .cy: return "Can chi năm"
        case .z: return "Con giáp"
        case .al: return "ÂL"
        case .leap: return "Tháng nhuận"
        }
    }

    var helpText: String {
        switch self {
        case .d: return "Ngày âm (1 chữ số nếu < 10)"
        case .dd: return "Ngày âm (2 chữ số)"
        case .m: return "Tháng âm (1 chữ số nếu < 10)"
        case .mm: return "Tháng âm (2 chữ số)"
        case .yyyy: return "Năm âm dạng số"
        case .sy: return "Năm dương dạng số"
        case .sd: return "Ngày dương (1 chữ số nếu < 10)"
        case .sdd: return "Ngày dương (2 chữ số)"
        case .sm: return "Tháng dương (1 chữ số nếu < 10)"
        case .smm: return "Tháng dương (2 chữ số)"
        case .cy: return "Năm can chi"
        case .z: return "Con giáp"
        case .al: return "Chữ viết tắt ÂL"
        case .leap: return "N nếu là tháng nhuận"
        }
    }
}

#Preview {
    AppSettingsView()
        .environmentObject(AppSettings())
}
