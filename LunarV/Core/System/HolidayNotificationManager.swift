//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import AppKit
import Combine
import Foundation
import UserNotifications

@MainActor
final class HolidayNotificationManager: ObservableObject {
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private enum Constants {
        static let identifierPrefix = "holiday.reminder"
        static let minimumWindowDays = 14
        static let maximumWindowDays = 180
    }

    private let settings: AppSettings
    private let lunarService: VietnameseLunarDateService
    private let center: UNUserNotificationCenter
    private var settingsCancellables = Set<AnyCancellable>()
    private var systemNotificationObservers: [NSObjectProtocol] = []
    private var workspaceNotificationObservers: [NSObjectProtocol] = []

    init(
        settings: AppSettings,
        lunarService: VietnameseLunarDateService? = nil,
        center: UNUserNotificationCenter = .current()
    ) {
        self.settings = settings
        self.lunarService = lunarService ?? VietnameseLunarDateService()
        self.center = center

        startObservingSettings()
        startObservingSystemChanges()

        Task { [weak self] in
            guard let self else { return }
            await self.bootstrap()
        }
    }

    deinit {
        systemNotificationObservers.forEach { observer in
            NotificationCenter.default.removeObserver(observer)
        }

        let workspaceCenter = NSWorkspace.shared.notificationCenter
        workspaceNotificationObservers.forEach { observer in
            workspaceCenter.removeObserver(observer)
        }
    }

    var authorizationDescription: String {
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return "Thông báo đã được cấp quyền."
        case .denied:
            return "Thông báo đang bị tắt trong System Settings."
        case .notDetermined:
            return "Bật để LunarV xin quyền gửi nhắc lễ."
        @unknown default:
            return "Không xác định trạng thái thông báo."
        }
    }

    func bootstrap() async {
        await refreshAuthorizationStatus()
        await synchronizeSchedules()
    }

    @discardableResult
    func requestAuthorizationIfNeeded() async -> Bool {
        await refreshAuthorizationStatus()

        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
            await refreshAuthorizationStatus()
            return granted
        @unknown default:
            return false
        }
    }

    func synchronizeSchedules() async {
        guard settings.enableHolidayNotifications else {
            await clearPendingHolidayNotifications()
            return
        }

        let granted = await requestAuthorizationIfNeeded()
        guard granted else {
            settings.enableHolidayNotifications = false
            await clearPendingHolidayNotifications()
            return
        }

        await scheduleHolidayNotifications()
    }

    func clearPendingHolidayNotifications() async {
        let requests = await center.fetchPendingNotificationRequests()
        let ids = requests
            .map(\.identifier)
            .filter { $0.hasPrefix(Constants.identifierPrefix) }

        guard !ids.isEmpty else {
            return
        }

        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    private func scheduleHolidayNotifications() async {
        await clearPendingHolidayNotifications()

        let now = Date()
        let calendar = lunarService.calendar
        let dayStart = calendar.startOfDay(for: now)
        let leadDays = max(settings.holidayReminderLeadDays, 0)
        let hour = min(max(settings.holidayReminderHour, 0), 23)
        let windowDays = min(max(settings.notificationWindowDays, Constants.minimumWindowDays), Constants.maximumWindowDays)

        var requests: [UNNotificationRequest] = []
        requests.reserveCapacity(windowDays)

        for offset in 0 ... windowDays {
            guard
                let eventDate = calendar.date(byAdding: .day, value: offset, to: dayStart),
                let solar = lunarService.solarComponents(from: eventDate),
                let lunar = lunarService.lunarDate(from: eventDate)
            else {
                continue
            }

            let resolvedHoliday: (name: String, isLunar: Bool)?
            if let name = HolidayProvider.solarHoliday(day: solar.day, month: solar.month) {
                resolvedHoliday = (name: name, isLunar: false)
            } else if let name = HolidayProvider.lunarHoliday(day: lunar.day, month: lunar.month) {
                resolvedHoliday = (name: name, isLunar: true)
            } else {
                resolvedHoliday = nil
            }

            guard let holiday = resolvedHoliday else {
                continue
            }

            guard
                let reminderBaseDate = calendar.date(byAdding: .day, value: -leadDays, to: eventDate),
                let reminderDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: reminderBaseDate),
                reminderDate > now
            else {
                continue
            }

            let content = UNMutableNotificationContent()
            content.title = leadDays == 0 ? "Hôm nay: \(holiday.name)" : "\(holiday.name) sau \(leadDays) ngày"
            content.body = holidayBody(
                holidayName: holiday.name,
                isLunarHoliday: holiday.isLunar,
                solar: solar,
                lunar: lunar,
                leadDays: leadDays
            )
            content.sound = .default

            let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
            let identifier = notificationIdentifier(solar: solar, isLunarHoliday: holiday.isLunar, leadDays: leadDays)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            requests.append(request)
        }

        for request in requests {
            do {
                try await center.addRequest(request)
            } catch {
                continue
            }
        }
    }

    private func holidayBody(
        holidayName: String,
        isLunarHoliday: Bool,
        solar: SolarDateComponents,
        lunar: LunarDate,
        leadDays: Int
    ) -> String {
        let leadText = leadDays == 0 ? "Đến ngày" : "Sắp đến"
        if isLunarHoliday {
            let leapText = lunar.isLeapMonth ? " nhuận" : ""
            return "\(leadText) \(holidayName): \(lunar.day)/\(lunar.month)\(leapText) ÂL, dương lịch \(solar.formattedDate)."
        }
        return "\(leadText) \(holidayName): dương lịch \(solar.formattedDate), âm lịch \(lunar.day)/\(lunar.month)."
    }

    private func notificationIdentifier(
        solar: SolarDateComponents,
        isLunarHoliday: Bool,
        leadDays: Int
    ) -> String {
        let type = isLunarHoliday ? "lunar" : "solar"
        return "\(Constants.identifierPrefix).\(solar.year)-\(solar.month)-\(solar.day).\(type).\(leadDays)"
    }

    private func refreshAuthorizationStatus() async {
        let settings = await center.fetchNotificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    private func startObservingSettings() {
        settings.objectWillChange
            .debounce(for: .milliseconds(250), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else {
                    return
                }

                Task { @MainActor [weak self] in
                    await self?.synchronizeSchedules()
                }
            }
            .store(in: &settingsCancellables)
    }

    private func startObservingSystemChanges() {
        let defaultCenter = NotificationCenter.default
        let systemNames: [Notification.Name] = [
            .NSSystemClockDidChange,
            .NSSystemTimeZoneDidChange,
            .NSCalendarDayChanged,
        ]

        systemNotificationObservers = systemNames.map { name in
            defaultCenter.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.synchronizeSchedules()
                }
            }
        }

        let workspaceCenter = NSWorkspace.shared.notificationCenter
        let wakeObserver = workspaceCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.synchronizeSchedules()
            }
        }
        workspaceNotificationObservers = [wakeObserver]
    }
}

private extension UNUserNotificationCenter {
    func fetchNotificationSettings() async -> UNNotificationSettings {
        await withCheckedContinuation { continuation in
            getNotificationSettings { settings in
                continuation.resume(returning: settings)
            }
        }
    }

    func fetchPendingNotificationRequests() async -> [UNNotificationRequest] {
        await withCheckedContinuation { continuation in
            getPendingNotificationRequests { requests in
                continuation.resume(returning: requests)
            }
        }
    }

    func addRequest(_ request: UNNotificationRequest) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            add(request) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
