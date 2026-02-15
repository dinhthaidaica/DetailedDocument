import Foundation
import Combine
import ServiceManagement

@MainActor
final class LaunchAtLoginManager: ObservableObject {
    @Published private(set) var isEnabled: Bool
    @Published private(set) var statusHint: String?
    @Published private(set) var errorMessage: String?

    init() {
        isEnabled = false
        refreshStatus()
    }

    func refreshStatus() {
        applyStatus(Self.currentStatus)
    }

    func setEnabled(_ shouldEnable: Bool) {
        do {
            if shouldEnable {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }

            refreshStatus()
        } catch {
            refreshStatus()
            errorMessage = userFriendlyErrorMessage(from: error)
        }
    }

    private static var currentStatus: SMAppService.Status {
        SMAppService.mainApp.status
    }

    private func applyStatus(_ status: SMAppService.Status) {
        errorMessage = nil

        switch status {
        case .enabled:
            isEnabled = true
            statusHint = nil
        case .notRegistered:
            isEnabled = false
            statusHint = nil
        case .notFound:
            isEnabled = false
            statusHint = "Không tìm thấy mục đăng ký khởi động. Hãy thử tắt/bật lại tùy chọn này."
        case .requiresApproval:
            isEnabled = false
            statusHint = "macOS cần bạn xác nhận trong Cài đặt hệ thống > Đăng nhập."
        @unknown default:
            isEnabled = false
            statusHint = "Không xác định được trạng thái khởi động cùng hệ thống."
        }
    }

    private func userFriendlyErrorMessage(from error: Error) -> String {
        let nsError = error as NSError
        if nsError.localizedDescription.isEmpty {
            return "Không thể thay đổi thiết lập khởi động cùng hệ thống."
        }

        return "Không thể thay đổi thiết lập khởi động cùng hệ thống: \(nsError.localizedDescription)"
    }
}
