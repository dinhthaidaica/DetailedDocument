//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import Foundation
import os
import Sparkle

@MainActor
final class SparkleUpdaterDelegate: NSObject, SPUUpdaterDelegate {
    private let settings: AppSettings

    init(settings: AppSettings) {
        self.settings = settings
        super.init()
    }

    func updater(_ updater: SPUUpdater, willInstallUpdate item: SUAppcastItem) {
        settings.persistForUpdateSafety()
        AppLogger.system.info("Persisted settings snapshot before installing update")
    }
}
