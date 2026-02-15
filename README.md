# LunarV

A native macOS menu bar app that shows the Vietnamese lunar calendar (`Âm lịch`) in real time.

## Highlights

- Real-time lunar date updates directly in the menu bar.
- Vietnamese calendar metadata:
  - Can Chi (day, month, year)
  - Solar term (`Tiết khí`)
  - Zodiac
  - Can Chi hour
- Monthly grid with solar/lunar day mapping.
- Native macOS visual style using `MenuBarExtra`, `NSVisualEffectView`, and semantic colors/materials.
- Automatic refresh on:
  - minute boundaries
  - system clock changes
  - timezone changes
  - day changes
  - wake from sleep

## Tech Stack

- Swift 5
- SwiftUI (macOS)
- Xcode project (`.xcodeproj`)

## Project Structure

```text
LunarV/
  App/
    LunarVApp.swift
  Core/
    LunarCalendar/
      JulianDay.swift
      LunarDate.swift
      VietnameseLunarCalendarConverter.swift
      VietnameseCalendarMetadata.swift
  Features/
    MenuBar/
      LunarMenuBarModels.swift
      LunarMenuBarViewModel.swift
      LunarMenuBarView.swift
```

## Getting Started

1. Open `LunarV.xcodeproj` in Xcode.
2. Select scheme `LunarV`.
3. Run on macOS.

Or build from CLI:

```bash
xcodebuild -project LunarV.xcodeproj -scheme LunarV -configuration Debug -sdk macosx build
```

## Release DMG (GitHub Actions)

- Workflow: `.github/workflows/release-dmg.yml`
- Auto trigger when pushing tag `v*.*.*` (for example `v1.0.0`)
- Manual trigger from **Actions > Release DMG > Run workflow** (optional `version`)
- Output: release `.dmg` with:
  - `LunarV.app`
  - `Applications` shortcut (drag-and-drop install style)
- Upload thêm:
  - DMG artifact
  - build log artifact

## Accuracy Notes

- Lunar conversion is calculated using Vietnam timezone (`Asia/Ho_Chi_Minh`, UTC+7).
- Display and conversion are intentionally aligned to Vietnam time for consistent results.

## Contributing

Please read:

- `CONTRIBUTING.md`
- `CODE_OF_CONDUCT.md`
- `SECURITY.md`

## Changelog

Project history is tracked in `CHANGELOG.md`.

## License

Licensed under **GNU Affero General Public License v3.0 (AGPL-3.0-only)**.
See `LICENSE` for full text.
