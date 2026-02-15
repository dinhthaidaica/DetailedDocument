import SwiftUI

struct AppSettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @StateObject private var launchAtLoginManager = LaunchAtLoginManager()

    private let previewConverter = VietnameseLunarCalendarConverter(timeZone: 7.0)
    private let templateTokens = MenuBarTemplateToken.allCases

    var body: some View {
        Form {
            Section("Hiển thị menu bar") {
                Picker("Kiểu hiển thị", selection: $settings.menuBarDisplayPreset) {
                    ForEach(MenuBarDisplayPreset.allCases) { preset in
                        Text(preset.title).tag(preset)
                    }
                }

                Text(settings.menuBarDisplayPreset.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if settings.menuBarDisplayPreset == .custom {
                    TextField("Mẫu hiển thị", text: $settings.customMenuBarTemplate)
                        .textFieldStyle(.roundedBorder)

                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 74), spacing: 8)],
                        alignment: .leading,
                        spacing: 8
                    ) {
                        ForEach(templateTokens) { token in
                            Button(token.rawValue) {
                                insertToken(token.rawValue)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .help(token.helpText)
                        }
                    }

                    Text("Token khả dụng: {d}, {dd}, {m}, {mm}, {cy}, {z}, {al}, {leap}, {sd}, {sdd}, {sm}, {smm}, {yyyy}, {sy}")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Ví dụ: {dd}/{mm} {al} • {cy}")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                LabeledContent("Xem trước") {
                    Text(previewMenuBarTitle)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                }

                Button("Khôi phục mặc định") {
                    settings.resetMenuBarDisplaySettings()
                }
                .buttonStyle(.link)
            }

            Section("Khởi động cùng hệ thống") {
                Toggle("Mở LunarV khi đăng nhập", isOn: launchAtLoginBinding)
                Text("Thiết lập này dùng ServiceManagement của macOS và áp dụng ngay lập tức.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let statusHint = launchAtLoginManager.statusHint {
                    Text(statusHint)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                if let errorMessage = launchAtLoginManager.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(width: 560)
        .onAppear {
            launchAtLoginManager.refreshStatus()
        }
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { launchAtLoginManager.isEnabled },
            set: { launchAtLoginManager.setEnabled($0) }
        )
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

#Preview {
    AppSettingsView()
        .environmentObject(AppSettings())
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

    var helpText: String {
        switch self {
        case .d:
            return "Ngày âm (1 chữ số nếu < 10)"
        case .dd:
            return "Ngày âm (2 chữ số)"
        case .m:
            return "Tháng âm (1 chữ số nếu < 10)"
        case .mm:
            return "Tháng âm (2 chữ số)"
        case .yyyy:
            return "Năm âm dạng số"
        case .sy:
            return "Năm dương dạng số"
        case .sd:
            return "Ngày dương (1 chữ số nếu < 10)"
        case .sdd:
            return "Ngày dương (2 chữ số)"
        case .sm:
            return "Tháng dương (1 chữ số nếu < 10)"
        case .smm:
            return "Tháng dương (2 chữ số)"
        case .cy:
            return "Năm can chi"
        case .z:
            return "Con giáp"
        case .al:
            return "Chữ viết tắt ÂL"
        case .leap:
            return "N nếu là tháng nhuận"
        }
    }
}
