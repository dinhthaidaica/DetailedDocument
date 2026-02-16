//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import AppKit
import SwiftUI

struct AppSettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @StateObject private var launchAtLoginManager = LaunchAtLoginManager()
    @State private var isShowingResetDialog = false

    private let previewConverter = VietnameseLunarCalendarConverter(timeZone: 7.0)

    var body: some View {
        TabView {
            appearanceTab
                .tabItem { Label("Giao diện", systemImage: "paintbrush.fill") }

            panelTab
                .tabItem { Label("Menu Bar", systemImage: "list.bullet.indent") }

            systemTab
                .tabItem { Label("Hệ thống", systemImage: "gearshape.2.fill") }

            aboutTab
                .tabItem { Label("Thông tin", systemImage: "info.circle.fill") }
        }
        .frame(width: 500, height: 450)
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
                ColorPicker("Chọn màu nhấn (Accent Color)", selection: $settings.customAccentColor)
                    .help("Màu sắc này sẽ áp dụng cho các icon và thành phần quan trọng.")
                
                Text("Màu sắc này sẽ được áp dụng ngay lập tức lên Menu Bar.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Xem trước Menu Bar") {
                VStack(alignment: .leading, spacing: 12) {
                    previewCard
                    
                    Picker("Kiểu hiển thị", selection: $settings.menuBarDisplayPreset) {
                        ForEach(MenuBarDisplayPreset.allCases) { preset in
                            Text(preset.title).tag(preset)
                        }
                    }
                    .pickerStyle(.segmented)

                    if settings.menuBarDisplayPreset == .custom {
                        TextField("Mẫu tuỳ chỉnh", text: $settings.customMenuBarTemplate)
                            .textFieldStyle(.roundedBorder)
                        Text("Token: {dd} ngày, {mm} tháng, {cy} năm can chi, {z} con giáp...")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Panel Tab

    private var panelTab: some View {
        Form {
            Section("Ẩn/Hiện các thành phần trong bảng") {
                Toggle("Thẻ ngày hôm nay (Hero Card)", isOn: $settings.showHeroCard)
                Toggle("Thông tin Can chi & Con giáp", isOn: $settings.showCanChiSection)
                Toggle("Danh sách sự kiện sắp tới", isOn: $settings.showHolidaySection)
                Toggle("Lịch tháng", isOn: $settings.showMonthCalendar)
                Toggle("Thông tin vạn niên khác", isOn: $settings.showDetailSection)
            }
            
            Section {
                Text("Gợi ý: Tắt các mục không cần thiết giúp bảng menu bar gọn gàng và tải nhanh hơn.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - System Tab

    private var systemTab: some View {
        Form {
            Section("Tự động hóa") {
                Toggle("Mở LunarV khi đăng nhập máy tính", isOn: launchAtLoginBinding)
                
                if let statusHint = launchAtLoginManager.statusHint {
                    Label(statusHint, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption).foregroundStyle(.orange)
                }
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
                Text("Lịch Âm Việt Nam cho macOS").font(.subheadline).foregroundStyle(.secondary)
                Text("Phiên bản \(appVersionText)").font(.caption2).monospaced()
            }

            Divider().padding(.horizontal, 40)

            VStack(alignment: .leading, spacing: 10) {
                Text("Phát triển bởi Phạm Hùng Tiến, mang tinh hoa lịch cổ truyền lên hệ điều hành macOS hiện đại.")
                    .font(.callout).multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)

            Spacer()

            Button(role: .destructive) { isShowingResetDialog = true } label: {
                Label("Khôi phục tất cả cài đặt", systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(.bordered)
            .padding(.bottom, 20)
        }
        .padding(.top, 30)
    }

    // MARK: - Helpers

    private var previewCard: some View {
        HStack {
            Spacer()
            Text(previewMenuBarTitle)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(settings.customAccentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(settings.customAccentColor.opacity(0.3), lineWidth: 1))
            Spacer()
        }
        .padding(.vertical, 10)
        .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 10))
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(get: { launchAtLoginManager.isEnabled }, set: { launchAtLoginManager.setEnabled($0) })
    }

    private var appVersionText: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(v) (\(b))"
    }

    private var previewMenuBarTitle: String {
        let now = Date()
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")!
        let comp = cal.dateComponents([.day, .month, .year], from: now)
        let lunar = previewConverter.solarToLunar(day: comp.day!, month: comp.month!, year: comp.year!)
        let context = MenuBarTitleContext(
            lunarDay: lunar.day, lunarMonth: lunar.month, lunarYear: lunar.year, isLeapMonth: lunar.isLeapMonth,
            canChiYear: VietnameseCalendarMetadata.canChiYear(lunarYear: lunar.year),
            zodiac: VietnameseCalendarMetadata.zodiac(lunarYear: lunar.year),
            solarDay: comp.day!, solarMonth: comp.month!, solarYear: comp.year!
        )
        return MenuBarTitleFormatter.render(preset: settings.menuBarDisplayPreset, customTemplate: settings.customMenuBarTemplate, context: context)
    }
}
