//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import AppKit
import Sparkle
import SwiftUI

enum SettingsUpdateCheckFrequency: TimeInterval, CaseIterable, Identifiable {
    case hourly = 3600
    case everySixHours = 21600
    case everyTwelveHours = 43200
    case daily = 86400
    case everyThreeDays = 259200
    case weekly = 604800

    var id: TimeInterval { rawValue }

    var title: String {
        switch self {
        case .hourly:
            return "Mỗi 1 giờ"
        case .everySixHours:
            return "Mỗi 6 giờ"
        case .everyTwelveHours:
            return "Mỗi 12 giờ"
        case .daily:
            return "Mỗi ngày"
        case .everyThreeDays:
            return "Mỗi 3 ngày"
        case .weekly:
            return "Mỗi tuần"
        }
    }

    static func nearest(for interval: TimeInterval) -> SettingsUpdateCheckFrequency {
        allCases.min(by: { abs($0.rawValue - interval) < abs($1.rawValue - interval) }) ?? .daily
    }
}

struct SettingsNotificationsPane: View {
    let holidayNotificationBinding: Binding<Bool>
    @Binding var holidayReminderLeadDays: Int
    @Binding var holidayReminderHour: Int
    @Binding var notificationWindowDays: Int
    let authorizationDescription: String

    private let trailingControlColumnWidth: CGFloat = 170

    private var isNotificationsEnabled: Bool {
        holidayNotificationBinding.wrappedValue
    }

    private var notificationLeadSummary: String {
        switch holidayReminderLeadDays {
        case 0:
            return "Nhắc đúng ngày"
        case 1:
            return "Nhắc trước 1 ngày"
        default:
            return "Nhắc trước \(holidayReminderLeadDays) ngày"
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                LunarSettingsHeader(
                    title: "Thông báo",
                    subtitle: "Thiết lập nhắc ngày lễ âm lịch theo thời điểm bạn muốn nhận.",
                    icon: "bell.badge.fill"
                ) {
                    VStack(alignment: .trailing, spacing: 6) {
                        LunarSettingsStatusPill(
                            text: isNotificationsEnabled ? "Nhắc lễ: Bật" : "Nhắc lễ: Tắt",
                            color: isNotificationsEnabled ? .green : .secondary
                        )
                        if isNotificationsEnabled {
                            LunarSettingsStatusPill(text: notificationLeadSummary, color: .accentColor)
                        }
                    }
                }

                holidayNotificationsCard
            }
            .frame(maxWidth: .infinity)
            .padding(14)
        }
        .lunarSettingsBackground()
    }

    private var holidayNotificationsCard: some View {
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
                    isEnabled: isNotificationsEnabled
                ) {
                    Picker("", selection: $holidayReminderLeadDays) {
                        Text("Đúng ngày").tag(0)
                        Text("Trước 1 ngày").tag(1)
                        Text("Trước 3 ngày").tag(3)
                    }
                }

                settingsPickerRow(
                    title: "Giờ thông báo",
                    isEnabled: isNotificationsEnabled
                ) {
                    Picker("", selection: $holidayReminderHour) {
                        ForEach([6, 7, 8, 9, 18, 20, 21], id: \.self) { hour in
                            Text(hourDisplay(hour)).tag(hour)
                        }
                    }
                }

                settingsPickerRow(
                    title: "Phạm vi lập lịch",
                    isEnabled: isNotificationsEnabled
                ) {
                    Picker("", selection: $notificationWindowDays) {
                        Text("30 ngày tới").tag(30)
                        Text("60 ngày tới").tag(60)
                        Text("90 ngày tới").tag(90)
                        Text("180 ngày tới").tag(180)
                    }
                }

                HStack(spacing: 10) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.accentColor)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Trạng thái quyền thông báo")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.primary)
                        Text(authorizationDescription)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color.accentColor.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.accentColor.opacity(0.1), lineWidth: 0.5)
                )
            }
        }
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
        .padding(.vertical, 2)
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

    private func hourDisplay(_ hour: Int) -> String {
        String(format: "%02d:00", hour)
    }
}

struct SettingsUpdatesPane: View {
    @Binding var automaticallyChecksForUpdates: Bool
    @Binding var updateCheckFrequency: SettingsUpdateCheckFrequency
    let appVersionText: String
    let updater: SPUUpdater

    private let trailingControlColumnWidth: CGFloat = 170

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                LunarSettingsHeader(
                    title: "Cập nhật",
                    subtitle: "Theo dõi phiên bản mới và chọn chế độ kiểm tra phù hợp.",
                    icon: "arrow.down.circle.fill"
                ) {
                    VStack(alignment: .trailing, spacing: 6) {
                        LunarSettingsStatusPill(
                            text: automaticallyChecksForUpdates ? "Tự kiểm tra: Bật" : "Tự kiểm tra: Tắt",
                            color: automaticallyChecksForUpdates ? .green : .secondary
                        )
                        LunarSettingsStatusPill(text: "Phiên bản \(appVersionText)", color: .accentColor)
                    }
                }

                updatesSettingsCard
            }
            .frame(maxWidth: .infinity)
            .padding(14)
        }
        .lunarSettingsBackground()
    }

    private var updatesSettingsCard: some View {
        LunarSettingsCard(
            title: "Cập nhật ứng dụng",
            subtitle: "Kiểm tra phiên bản mới từ GitHub Releases",
            icon: "arrow.down.circle.fill"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                settingsInfoRow(title: "Phiên bản hiện tại", value: appVersionText)

                Divider()

                settingsToggleRow(
                    title: "Tự động kiểm tra cập nhật",
                    isOn: $automaticallyChecksForUpdates
                )

                settingsPickerRow(
                    title: "Tần suất kiểm tra",
                    isEnabled: automaticallyChecksForUpdates
                ) {
                    Picker("", selection: $updateCheckFrequency) {
                        ForEach(SettingsUpdateCheckFrequency.allCases) { frequency in
                            Text(frequency.title).tag(frequency)
                        }
                    }
                    .pickerStyle(.menu)
                    .controlSize(.regular)
                }

                Text(
                    automaticallyChecksForUpdates
                        ? "Khi bật, LunarV sẽ tự kiểm tra theo tần suất bạn chọn."
                        : "Khi tắt, LunarV chỉ kiểm tra khi bạn bấm nút bên dưới."
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                Text("Việc cập nhật phiên bản mới sẽ giữ nguyên toàn bộ cài đặt hiện tại của bạn.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    CheckForUpdatesView(updater: updater)
                    Spacer(minLength: 0)
                }
            }
        }
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
        .padding(.vertical, 2)
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

    @ViewBuilder
    private func settingsInfoRow(title: String, value: String, isHighlighted: Bool = false) -> some View {
        let valueColor: Color = isHighlighted ? .accentColor : .primary
        let badgeBackground: Color = isHighlighted ? Color.accentColor.opacity(0.14) : Color.primary.opacity(0.05)

        HStack(alignment: .center) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(valueColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(badgeBackground, in: RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(
                            isHighlighted ? Color.accentColor.opacity(0.22) : Color.clear,
                            lineWidth: 0.6
                        )
                )
        }
    }
}

struct SettingsSystemPane: View {
    @Binding var keepSettingsOnTop: Bool
    @Binding var launchAtLogin: Bool
    let launchAtLoginEnabled: Bool
    let onResetSettings: () -> Void

    private let trailingControlColumnWidth: CGFloat = 170

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                LunarSettingsHeader(
                    title: "Hệ thống",
                    subtitle: "Quản lý cửa sổ, tự khởi động và thông số dữ liệu của ứng dụng.",
                    icon: "gearshape.2.fill"
                ) {
                    VStack(alignment: .trailing, spacing: 6) {
                        LunarSettingsStatusPill(
                            text: launchAtLoginEnabled ? "Tự khởi động: Bật" : "Tự khởi động: Tắt",
                            color: launchAtLoginEnabled ? .accentColor : .secondary
                        )
                        LunarSettingsStatusPill(
                            text: keepSettingsOnTop ? "Cửa sổ nổi: Bật" : "Cửa sổ nổi: Tắt",
                            color: keepSettingsOnTop ? .green : .secondary
                        )
                    }
                }

                systemWindowBehaviorCard
                systemLaunchAtLoginCard
                systemDataCard
                resetSettingsCard
            }
            .frame(maxWidth: .infinity)
            .padding(14)
        }
        .lunarSettingsBackground()
    }

    private var systemWindowBehaviorCard: some View {
        LunarSettingsCard(
            title: "Cửa sổ Cài đặt",
            subtitle: "Hành vi hiển thị cửa sổ",
            icon: "rectangle.inset.filled.and.person.filled"
        ) {
            VStack(alignment: .leading, spacing: 10) {
                settingsToggleRow(
                    title: "Luôn ở trên cùng (Floating)",
                    isOn: $keepSettingsOnTop
                )
                Text("Khi bật, cửa sổ Cài đặt sẽ luôn nằm trên các cửa sổ khác để bạn vừa chỉnh vừa quan sát Menu Bar dễ hơn.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var systemLaunchAtLoginCard: some View {
        LunarSettingsCard(
            title: "Tự động hóa",
            subtitle: "Khởi chạy ứng dụng cùng hệ thống",
            icon: "power.circle.fill"
        ) {
            settingsToggleRow(
                title: "Mở LunarV khi đăng nhập máy tính",
                isOn: $launchAtLogin
            )
        }
    }

    private var systemDataCard: some View {
        LunarSettingsCard(
            title: "Dữ liệu & Thời gian",
            subtitle: "Thông số tính toán lịch",
            icon: "clock.arrow.trianglehead.counterclockwise.rotate.90"
        ) {
            VStack(spacing: 10) {
                settingsInfoRow(title: "Múi giờ tính toán", value: "Asia/Ho_Chi_Minh (GMT+7)")
                Divider().opacity(0.5)
                settingsInfoRow(title: "Thuật toán", value: "Vietnamese Lunar Calendar 2.0")
            }
        }
    }

    private var resetSettingsCard: some View {
        LunarSettingsCard(
            title: "Khôi phục cài đặt",
            subtitle: "Đưa toàn bộ tuỳ chỉnh về mặc định",
            icon: "arrow.counterclockwise"
        ) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Đặt lại nhanh tất cả cấu hình")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.primary)
                    Text("Giao diện, hiển thị và thông báo sẽ quay về giá trị ban đầu.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Button(role: .destructive) {
                    onResetSettings()
                } label: {
                    Label("Khôi phục", systemImage: "arrow.counterclockwise")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.bordered)
            }
        }
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
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private func settingsInfoRow(title: String, value: String, isHighlighted: Bool = false) -> some View {
        let valueColor: Color = isHighlighted ? .accentColor : .primary
        let badgeBackground: Color = isHighlighted ? Color.accentColor.opacity(0.14) : Color.primary.opacity(0.05)

        HStack(alignment: .center) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(valueColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(badgeBackground, in: RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(
                            isHighlighted ? Color.accentColor.opacity(0.22) : Color.clear,
                            lineWidth: 0.6
                        )
                )
        }
    }
}

struct SettingsAboutPane: View {
    let appVersionText: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
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
                    VStack(spacing: 20) {
                        Image(nsImage: NSApp.applicationIconImage)
                            .resizable()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)

                        VStack(spacing: 6) {
                            Text("LunarV")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                            Text("Phiên bản \(appVersionText)")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 3)
                                .background(Color.primary.opacity(0.05), in: Capsule())
                        }

                        Text("Phát triển bởi Phạm Hùng Tiến, mang tinh hoa lịch cổ truyền lên hệ điều hành macOS hiện đại.")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 480)

                        donationQRCodeCard
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }

            }
            .frame(maxWidth: .infinity)
            .padding(14)
        }
        .lunarSettingsBackground()
    }

    private var donationQRCodeCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.pink)
                Text("Ủng hộ phát triển LunarV")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.primary)
            }

            Image("QRDonate")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 180, height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)

            Text("Quét mã QR để ủng hộ dự án.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.primary.opacity(colorScheme == .dark ? 0.04 : 0.02))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
        )
    }
}
