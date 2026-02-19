//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import Foundation

struct SettingsSearchEntry: Identifiable {
    let id: String
    let pane: SettingsPane
    let section: String
    let title: String
    let subtitle: String
    let icon: String
    let keywords: [String]
}

enum SettingsSearchCatalog {
    static let entries: [SettingsSearchEntry] = [
        SettingsSearchEntry(
            id: "appearance.displayPreset",
            pane: .appearance,
            section: "Menu Bar",
            title: "Kiểu hiển thị Menu Bar",
            subtitle: "Chọn chế độ preset hoặc mẫu tùy chỉnh",
            icon: "menubar.rectangle",
            keywords: ["preset", "chế độ", "compact", "full", "custom", "template", "mẫu tùy chỉnh"]
        ),
        SettingsSearchEntry(
            id: "appearance.customTemplate",
            pane: .appearance,
            section: "Menu Bar",
            title: "Mẫu tùy chỉnh",
            subtitle: "Tự tạo format hiển thị bằng token",
            icon: "textformat.alt",
            keywords: ["token", "template", "mẫu", "{dd}", "{mm}", "{hh}", "{h12}", "{hh12}", "{ampm}", "{ampml}", "{ampmvn}", "{ap}", "{time12}", "{time12m}", "{wdn}", "{wdn2}", "{:}", "format", "thứ số", "1-7", "2-8", "am pm", "12h", "sáng chiều", "nhấp nháy", "dấu hai chấm"]
        ),
        SettingsSearchEntry(
            id: "appearance.fontSize",
            pane: .appearance,
            section: "Kiểu chữ",
            title: "Kích cỡ chữ Menu Bar",
            subtitle: "Điều chỉnh kích thước chữ hiển thị trên thanh menu",
            icon: "textformat.size",
            keywords: ["font size", "cỡ chữ", "kích cỡ chữ", "slider"]
        ),
        SettingsSearchEntry(
            id: "appearance.fontFamily",
            pane: .appearance,
            section: "Kiểu chữ",
            title: "Phông chữ Menu Bar",
            subtitle: "Chọn font hệ thống hoặc font cài đặt",
            icon: "character.book.closed",
            keywords: ["font", "phông chữ", "font family", "hệ thống", "gợi ý"]
        ),
        SettingsSearchEntry(
            id: "appearance.textStyle",
            pane: .appearance,
            section: "Kiểu chữ",
            title: "Định dạng chữ",
            subtitle: "Bật/tắt đậm, nghiêng và gạch chân",
            icon: "bold.italic.underline",
            keywords: ["đậm", "nghiêng", "gạch chân", "bold", "italic", "underline"]
        ),
        SettingsSearchEntry(
            id: "appearance.leadingIconVisibility",
            pane: .appearance,
            section: "Menu Bar",
            title: "Hiển thị icon bên trái",
            subtitle: "Bật/tắt icon đứng trước nội dung ngày",
            icon: "photo",
            keywords: ["icon", "biểu tượng", "leading icon", "ẩn icon", "hiện icon"]
        ),
        SettingsSearchEntry(
            id: "appearance.leadingIconSize",
            pane: .appearance,
            section: "Menu Bar",
            title: "Kích cỡ icon Menu Bar",
            subtitle: "Điều chỉnh kích thước icon ở thanh menu",
            icon: "arrow.up.left.and.arrow.down.right",
            keywords: ["icon size", "kích cỡ icon", "slider", "menu bar icon"]
        ),
        SettingsSearchEntry(
            id: "panel.order",
            pane: .panel,
            section: "Bảng điều khiển",
            title: "Sắp xếp thứ tự card",
            subtitle: "Kéo thả để đổi vị trí các thành phần",
            icon: "line.3.horizontal.decrease",
            keywords: ["kéo thả", "thứ tự", "card order", "sắp xếp", "onMove"]
        ),
        SettingsSearchEntry(
            id: "panel.visibility",
            pane: .panel,
            section: "Bảng điều khiển",
            title: "Ẩn/hiện từng card",
            subtitle: "Bật hoặc tắt thành phần trong menu",
            icon: "eye",
            keywords: ["ẩn", "hiện", "toggle", "visibility", "card", "thành phần", "menu", "hero", "can chi", "giờ hoàng đạo", "gợi ý", "lịch tháng", "chuyển đổi"]
        ),
        SettingsSearchEntry(
            id: "panel.visibilityBulk",
            pane: .panel,
            section: "Bảng điều khiển",
            title: "Hiện tất cả hoặc ẩn tất cả card",
            subtitle: "Thao tác nhanh toàn bộ thành phần",
            icon: "rectangle.on.rectangle.angled",
            keywords: ["hiện tất cả", "ẩn tất cả", "bulk", "all cards", "batch", "hàng loạt"]
        ),
        SettingsSearchEntry(
            id: "panel.windowSize",
            pane: .panel,
            section: "Bảng điều khiển",
            title: "Kích thước cửa sổ menu bar",
            subtitle: "Điều chỉnh chiều rộng và chiều cao popup menu",
            icon: "arrow.up.left.and.arrow.down.right",
            keywords: ["kích thước", "size", "panel size", "popup", "chiều rộng", "chiều cao", "width", "height", "menu bar"]
        ),
        SettingsSearchEntry(
            id: "panel.windowSizePreset",
            pane: .panel,
            section: "Bảng điều khiển",
            title: "Preset kích thước cửa sổ",
            subtitle: "Áp dụng nhanh cỡ Gọn, Tiêu chuẩn hoặc Rộng",
            icon: "rectangle.3.group.bubble.left",
            keywords: ["gọn", "tiêu chuẩn", "rộng", "preset size", "mặc định", "default size"]
        ),
        SettingsSearchEntry(
            id: "panel.windowSizeLivePreview",
            pane: .panel,
            section: "Bảng điều khiển",
            title: "Xem trước kích thước theo thời gian thực",
            subtitle: "Xem trực tiếp giao diện menu bar ngay trong Cài đặt khi kéo slider",
            icon: "play.rectangle.on.rectangle",
            keywords: ["xem trước", "preview", "thời gian thực", "real time", "live preview", "slider", "inline", "trực tiếp"]
        ),
        SettingsSearchEntry(
            id: "worldClock.selection",
            pane: .worldClock,
            section: "Giờ quốc tế",
            title: "Tuỳ chỉnh múi giờ quốc tế",
            subtitle: "Chọn thành phố hiển thị trong card giờ quốc tế",
            icon: "globe",
            keywords: ["giờ quốc tế", "múi giờ", "timezone", "world clock", "city", "thành phố", "utc"]
        ),
        SettingsSearchEntry(
            id: "worldClock.smart",
            pane: .worldClock,
            section: "Giờ quốc tế",
            title: "Gợi ý thông minh theo múi giờ máy",
            subtitle: "Áp dụng nhanh danh sách múi giờ phù hợp theo khu vực hiện tại",
            icon: "sparkles",
            keywords: ["smart", "thông minh", "gợi ý", "timezone suggestion", "auto"]
        ),
        SettingsSearchEntry(
            id: "worldClock.selectAll",
            pane: .worldClock,
            section: "Giờ quốc tế",
            title: "Chọn tất cả hoặc về mặc định múi giờ",
            subtitle: "Tác vụ nhanh cho toàn bộ danh sách thành phố",
            icon: "checklist",
            keywords: ["chọn tất cả", "mặc định", "reset timezone", "all cities", "default timezones"]
        ),
        SettingsSearchEntry(
            id: "worldClock.search",
            pane: .worldClock,
            section: "Giờ quốc tế",
            title: "Tìm thành phố hoặc mã múi giờ",
            subtitle: "Lọc nhanh theo tên thành phố, quốc gia hoặc mã UTC",
            icon: "magnifyingglass",
            keywords: ["tìm thành phố", "search city", "timezone id", "utc+7", "america/new_york"]
        ),
        SettingsSearchEntry(
            id: "worldClock.order",
            pane: .worldClock,
            section: "Giờ quốc tế",
            title: "Sắp xếp thứ tự múi giờ hiển thị",
            subtitle: "Đưa múi giờ lên trên hoặc xuống dưới",
            icon: "arrow.up.and.down.text.horizontal",
            keywords: ["thứ tự múi giờ", "đưa lên", "đưa xuống", "reorder timezone", "sort", "kéo thả", "a-z", "utc tăng", "utc giảm"]
        ),
        SettingsSearchEntry(
            id: "worldClock.addRemove",
            pane: .worldClock,
            section: "Giờ quốc tế",
            title: "Thêm hoặc bỏ múi giờ",
            subtitle: "Bật/tắt thành phố trong danh sách hiển thị",
            icon: "plusminus.circle",
            keywords: ["thêm múi giờ", "xoá múi giờ", "bỏ chọn", "remove timezone", "toggle city"]
        ),
        SettingsSearchEntry(
            id: "panel.restoreDefaultOrder",
            pane: .panel,
            section: "Bảng điều khiển",
            title: "Khôi phục thứ tự mặc định",
            subtitle: "Đưa thứ tự card về cấu hình ban đầu",
            icon: "arrow.counterclockwise",
            keywords: ["khôi phục", "default order", "reset order"]
        ),
        SettingsSearchEntry(
            id: "notifications.enable",
            pane: .notifications,
            section: "Nhắc ngày lễ",
            title: "Bật thông báo ngày lễ",
            subtitle: "Cho phép LunarV gửi nhắc lễ âm lịch",
            icon: "bell.badge",
            keywords: ["thông báo", "nhắc", "holiday", "permission", "authorization", "quyền"]
        ),
        SettingsSearchEntry(
            id: "notifications.leadDays",
            pane: .notifications,
            section: "Nhắc ngày lễ",
            title: "Nhắc trước",
            subtitle: "Chọn số ngày nhắc trước ngày lễ",
            icon: "calendar.badge.clock",
            keywords: ["nhắc trước", "lead days", "đúng ngày", "trước 1 ngày", "trước 3 ngày"]
        ),
        SettingsSearchEntry(
            id: "notifications.hour",
            pane: .notifications,
            section: "Nhắc ngày lễ",
            title: "Giờ thông báo",
            subtitle: "Chọn thời điểm nhận thông báo trong ngày",
            icon: "clock.badge",
            keywords: ["giờ", "reminder hour", "time", "08:00", "20:00"]
        ),
        SettingsSearchEntry(
            id: "notifications.windowDays",
            pane: .notifications,
            section: "Nhắc ngày lễ",
            title: "Phạm vi lập lịch",
            subtitle: "Tính trước các ngày lễ trong khoảng thời gian chọn",
            icon: "calendar.badge.plus",
            keywords: ["30 ngày", "60 ngày", "90 ngày", "180 ngày", "window days", "lập lịch"]
        ),
        SettingsSearchEntry(
            id: "notifications.permissionState",
            pane: .notifications,
            section: "Nhắc ngày lễ",
            title: "Trạng thái quyền thông báo",
            subtitle: "Kiểm tra ứng dụng đã được cấp quyền gửi thông báo hay chưa",
            icon: "checkmark.shield",
            keywords: ["quyền thông báo", "notification permission", "authorization status", "đã cấp quyền"]
        ),
        SettingsSearchEntry(
            id: "updates.autoCheck",
            pane: .updates,
            section: "Cập nhật ứng dụng",
            title: "Tự động kiểm tra cập nhật",
            subtitle: "Bật/tắt kiểm tra phiên bản mới tự động",
            icon: "arrow.triangle.2.circlepath.circle",
            keywords: ["auto update", "tự động", "check updates", "sparkle"]
        ),
        SettingsSearchEntry(
            id: "updates.frequency",
            pane: .updates,
            section: "Cập nhật ứng dụng",
            title: "Tần suất kiểm tra cập nhật",
            subtitle: "Chọn chu kỳ kiểm tra phiên bản mới",
            icon: "timer",
            keywords: ["tần suất", "mỗi giờ", "mỗi ngày", "mỗi tuần", "frequency"]
        ),
        SettingsSearchEntry(
            id: "updates.checkNow",
            pane: .updates,
            section: "Cập nhật ứng dụng",
            title: "Kiểm tra cập nhật ngay",
            subtitle: "Kiểm tra thủ công phiên bản mới",
            icon: "arrow.down.circle",
            keywords: ["check now", "kiểm tra ngay", "phiên bản mới", "github releases"]
        ),
        SettingsSearchEntry(
            id: "system.keepOnTop",
            pane: .system,
            section: "Cửa sổ Cài đặt",
            title: "Luôn ở trên cùng",
            subtitle: "Giữ cửa sổ cài đặt nổi phía trên ứng dụng khác",
            icon: "pin",
            keywords: ["floating", "always on top", "cửa sổ nổi", "window behavior"]
        ),
        SettingsSearchEntry(
            id: "system.launchAtLogin",
            pane: .system,
            section: "Tự động hóa",
            title: "Mở LunarV khi đăng nhập",
            subtitle: "Tự khởi động ứng dụng khi mở máy",
            icon: "power",
            keywords: ["launch at login", "đăng nhập", "tự khởi động", "startup"]
        ),
        SettingsSearchEntry(
            id: "system.data",
            pane: .system,
            section: "Dữ liệu & Thời gian",
            title: "Thông số tính toán lịch",
            subtitle: "Xem múi giờ và thuật toán lịch đang sử dụng",
            icon: "clock.arrow.trianglehead.counterclockwise.rotate.90",
            keywords: ["múi giờ", "timezone", "algorithm", "thuật toán", "asia ho chi minh"]
        ),
        SettingsSearchEntry(
            id: "system.reset",
            pane: .system,
            section: "Khôi phục",
            title: "Khôi phục cài đặt mặc định",
            subtitle: "Đặt lại toàn bộ tùy chỉnh về giá trị ban đầu",
            icon: "arrow.uturn.backward",
            keywords: ["reset", "khôi phục", "mặc định", "restore defaults"]
        ),
        SettingsSearchEntry(
            id: "about.version",
            pane: .about,
            section: "Thông tin ứng dụng",
            title: "Phiên bản LunarV",
            subtitle: "Xem phiên bản hiện tại của ứng dụng",
            icon: "info.circle",
            keywords: ["version", "phiên bản", "build", "about"]
        ),
        SettingsSearchEntry(
            id: "about.donation",
            pane: .about,
            section: "Hỗ trợ phát triển",
            title: "Ủng hộ dự án qua QR",
            subtitle: "Mở mã QR để đóng góp cho LunarV",
            icon: "qrcode",
            keywords: ["donate", "ủng hộ", "qr", "hỗ trợ", "quét mã"]
        ),
    ]
}
