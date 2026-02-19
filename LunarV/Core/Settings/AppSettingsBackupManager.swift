//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import Combine
import Foundation
import os

@MainActor
final class AppSettingsBackupManager {
    private static let settingsBackupDirectoryName = "LunarV"
    private static let settingsBackupFileName = "settings-backup.plist"
    private static let legacyDefaultsSuites = [
        "phamhungtien.LunarV",
        "com.phamhungtien.phtv",
    ]
    private static let defaultSettingsValues: [String: Any] = [
        "settings.menuBar.displayPreset": MenuBarDisplayPreset.compact.rawValue,
        "settings.menuBar.weekdayDisplayStyle": AppSettings.defaultMenuBarWeekdayDisplayStyle.rawValue,
        "settings.menuBar.customTemplate": "",
        "settings.menuBar.titleFontSize": AppSettings.defaultMenuBarTitleFontSize,
        "settings.menuBar.titleFontFamily": AppSettings.defaultMenuBarTitleFontFamily,
        "settings.menuBar.titleBold": AppSettings.defaultMenuBarTitleBold,
        "settings.menuBar.titleItalic": AppSettings.defaultMenuBarTitleItalic,
        "settings.menuBar.titleUnderline": AppSettings.defaultMenuBarTitleUnderline,
        "settings.menuBar.showLeadingIcon": true,
        "settings.menuBar.leadingIconSize": AppSettings.defaultMenuBarLeadingIconSize,
        "settings.panel.showHeroCard": true,
        "settings.panel.showCanChiSection": true,
        "settings.panel.showHolidaySection": true,
        "settings.panel.showInternationalTimesSection": true,
        "settings.panel.showMonthCalendar": true,
        "settings.panel.showAuspiciousHoursSection": true,
        "settings.panel.showDayGuidanceSection": true,
        "settings.panel.showDetailSection": true,
        "settings.panel.showDateConverter": true,
        "settings.panel.windowWidth": AppSettings.defaultMenuBarPanelWidth,
        "settings.panel.windowHeight": AppSettings.defaultMenuBarPanelHeight,
        "settings.panel.internationalTimeZoneIDs": AppSettings.defaultInternationalTimeZoneIDs.joined(separator: ","),
        "settings.panel.cardOrder": PanelCardKind.serialized(PanelCardKind.defaultOrder),
        "settings.window.keepSettingsOnTop": true,
        "settings.notifications.enableHolidayNotifications": false,
        "settings.notifications.holidayReminderLeadDays": 1,
        "settings.notifications.holidayReminderHour": 8,
        "settings.notifications.windowDays": 60,
    ]

    private var defaultsChangeCancellables: Set<AnyCancellable> = []
    private var isApplyingRecoveredSettings = false
    private var lastPersistedSettingsSnapshotData: Data?

    func restoreSettingsFromBackupIfNeeded(defaults: UserDefaults = .standard) {
        guard let recoverySnapshot = Self.loadRecoverySnapshot(), !recoverySnapshot.isEmpty else {
            return
        }

        isApplyingRecoveredSettings = true
        defer {
            isApplyingRecoveredSettings = false
        }

        var restoredCount = 0
        for (key, value) in recoverySnapshot where Self.shouldPersistSetting(key: key) {
            let currentValue = defaults.object(forKey: key)

            if key.hasPrefix("settings.") {
                guard currentValue == nil || Self.matchesDefaultSettingValue(currentValue, for: key) else {
                    continue
                }
            } else {
                guard currentValue == nil else {
                    continue
                }
            }

            defaults.set(value, forKey: key)
            restoredCount += 1
        }

        guard restoredCount > 0 else {
            return
        }

        _ = CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
        AppLogger.system.info("Recovered \(restoredCount) settings key(s) from upgrade snapshot")
    }

    func persistForUpdateSafety(defaults: UserDefaults = .standard) {
        let snapshot = Self.settingsSnapshot(from: defaults.dictionaryRepresentation())
        guard !snapshot.isEmpty else {
            return
        }

        do {
            let data = try PropertyListSerialization.data(
                fromPropertyList: snapshot,
                format: .xml,
                options: 0
            )
            guard data != lastPersistedSettingsSnapshotData else {
                return
            }

            let backupURL = try Self.settingsBackupURL()
            try FileManager.default.createDirectory(
                at: backupURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: backupURL, options: .atomic)
            lastPersistedSettingsSnapshotData = data
            _ = CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
        } catch {
            AppLogger.system.error("Failed to backup settings before update: \(error.localizedDescription)")
        }
    }

    func observeDefaultsChangesForUpdateSafety(defaults: UserDefaults = .standard) {
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification, object: defaults)
            .debounce(for: .seconds(2), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self, !self.isApplyingRecoveredSettings else {
                    return
                }
                self.persistForUpdateSafety(defaults: defaults)
            }
            .store(in: &defaultsChangeCancellables)
    }

    private static func settingsSnapshot(from dictionary: [String: Any]) -> [String: Any] {
        dictionary.filter { shouldPersistSetting(key: $0.key) }
    }

    private static func matchesDefaultSettingValue(_ value: Any?, for key: String) -> Bool {
        guard
            let value,
            let defaultValue = defaultSettingsValues[key],
            let lhs = value as? NSObject,
            let rhs = defaultValue as? NSObject
        else {
            return false
        }
        return lhs == rhs
    }

    private static func loadRecoverySnapshot() -> [String: Any]? {
        if
            let backupURL = try? settingsBackupURL(),
            let data = try? Data(contentsOf: backupURL),
            let propertyList = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
            let snapshot = propertyList as? [String: Any],
            !snapshot.isEmpty
        {
            return snapshot
        }

        for suiteName in legacyDefaultsSuites {
            guard let suiteDefaults = UserDefaults(suiteName: suiteName) else {
                continue
            }
            let snapshot = settingsSnapshot(from: suiteDefaults.dictionaryRepresentation())
            if !snapshot.isEmpty {
                return snapshot
            }
        }
        return nil
    }

    private static func shouldPersistSetting(key: String) -> Bool {
        key.hasPrefix("settings.") || key.hasPrefix("SU")
    }

    private static func settingsBackupURL() throws -> URL {
        let appSupportURL = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        return appSupportURL
            .appendingPathComponent(settingsBackupDirectoryName, isDirectory: true)
            .appendingPathComponent(settingsBackupFileName)
    }
}
