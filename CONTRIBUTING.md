# Hướng dẫn đóng góp

Cảm ơn bạn đã quan tâm đến LunarV! Dưới đây là hướng dẫn để bạn có thể đóng góp hiệu quả.

## Yêu cầu phát triển

- macOS 26.0 trở lên
- Xcode phiên bản ổn định mới nhất
- Swift toolchain đi kèm Xcode

## Build trên máy

```bash
xcodebuild -project LunarV.xcodeproj -scheme LunarV -configuration Debug -sdk macosx build
```

## Quy ước nhánh

- `main`: nhánh ổn định, luôn ở trạng thái có thể release.
- Tạo nhánh riêng cho mỗi thay đổi, ví dụ:
  - `feat/menu-ui-improvements`
  - `fix/lunar-conversion-edge-case`

## Quy ước commit

Sử dụng [Conventional Commits](https://www.conventionalcommits.org/):

| Prefix | Ý nghĩa |
|---|---|
| `feat:` | Tính năng mới |
| `fix:` | Sửa lỗi |
| `refactor:` | Tái cấu trúc code |
| `docs:` | Cập nhật tài liệu |
| `chore:` | Công việc bảo trì |

## Pull Request

Trước khi mở PR, hãy đảm bảo:

1. Build thành công trên máy.
2. Thay đổi tập trung vào một mục đích duy nhất.
3. Cập nhật tài liệu nếu hành vi ứng dụng thay đổi.
4. Bổ sung test nếu có thể.

## Quy chuẩn code

- Tuân thủ style Swift hiện có trong dự án.
- Sử dụng semantic colors và materials cho giao diện macOS.
- Giữ business logic trong `ViewModel` / `Core`, Views chỉ khai báo giao diện.

## Báo lỗi

Sử dụng [GitHub Issues](../../issues/new/choose) và chọn mẫu phù hợp.
