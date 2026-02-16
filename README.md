# LunarV — Lịch Âm Việt Nam

Ứng dụng macOS hiển thị **lịch âm Việt Nam** trực tiếp trên thanh menu, cập nhật theo thời gian thực.

## Tính năng

- Hiển thị ngày âm lịch trên thanh menu, tự động cập nhật theo thời gian thực.
- Thông tin lịch Việt Nam đầy đủ:
  - Can Chi (ngày, tháng, năm)
  - Tiết khí
  - Con giáp
  - Giờ hoàng đạo (Can Chi theo giờ)
  - Ngũ hành ngày, tuổi xung, nhóm tam hợp
  - Gợi ý nên làm / hạn chế theo ngũ hành ngày và mùa tiết khí
- Lưới tháng hiển thị song song ngày dương / ngày âm.
- Widget cho Desktop và Notification Center.
- Giao diện macOS thuần với `MenuBarExtra`, `NSVisualEffectView` và semantic colors.
- Tự động làm mới khi:
  - Sang phút mới
  - Thay đổi đồng hồ hệ thống
  - Thay đổi múi giờ
  - Sang ngày mới
  - Máy thức dậy từ chế độ ngủ

## Yêu cầu hệ thống

- macOS 26.0 trở lên
- Chip Apple Silicon hoặc Intel

## Cài đặt

### Tải về

Tải file `.dmg` mới nhất từ trang [Releases](../../releases/latest), mở DMG và kéo **LunarV** vào thư mục **Applications**.

### Build từ mã nguồn

1. Mở `LunarV.xcodeproj` bằng Xcode.
2. Chọn scheme `LunarV`.
3. Nhấn Run (⌘R).

Hoặc build bằng dòng lệnh:

```bash
xcodebuild -project LunarV.xcodeproj -scheme LunarV -configuration Release -sdk macosx build
```

## Công nghệ

| Thành phần | Chi tiết |
|---|---|
| Ngôn ngữ | Swift 5 |
| UI | SwiftUI (macOS) |
| Widget | WidgetKit |
| Kiến trúc | MVVM |
| Build | Xcode (`.xcodeproj`) |

## Cấu trúc dự án

```text
LunarV/
├── App/                    Điểm khởi chạy ứng dụng
├── Core/
│   ├── LunarCalendar/
│   │   ├── Algorithms/     Thuật toán chuyển đổi âm lịch
│   │   ├── Models/          Các model dữ liệu
│   │   └── Services/        Dịch vụ cung cấp ngày âm lịch
│   ├── MenuBar/             Định dạng tiêu đề thanh menu
│   ├── Settings/            Cài đặt ứng dụng
│   └── System/              Khởi động cùng hệ thống
├── Features/
│   ├── MenuBar/             Giao diện & logic thanh menu
│   └── Settings/            Giao diện cài đặt
LunarVWidget/                Widget Extension
```

## Độ chính xác

Phép chuyển đổi âm lịch được tính theo múi giờ Việt Nam (`Asia/Ho_Chi_Minh`, UTC+7) để đảm bảo kết quả nhất quán với lịch âm thực tế.

## Đóng góp

Vui lòng đọc [Hướng dẫn đóng góp](CONTRIBUTING.md) trước khi tạo Pull Request.

## Nhật ký thay đổi

Xem [CHANGELOG.md](CHANGELOG.md) để theo dõi lịch sử phát triển.

## Giấy phép

Phân phối theo giấy phép **GNU Affero General Public License v3.0 (AGPL-3.0-only)**.
Xem file [LICENSE](LICENSE) để biết chi tiết.
