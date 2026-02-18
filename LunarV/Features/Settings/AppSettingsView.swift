//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import AppKit
import Sparkle
import SwiftUI

struct AppSettingsView: View {
    let updater: SPUUpdater

    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var notificationManager: HolidayNotificationManager
    @StateObject private var launchAtLoginManager = LaunchAtLoginManager()
    @State private var selectedPane: SettingsPane = .appearance
    @State private var isShowingResetDialog = false
    @State private var searchText = ""
    @State private var isShowingFontPicker = false
    @State private var fontSearchText = ""
    @State private var automaticallyChecksForUpdates: Bool
    @State private var updateCheckFrequency: UpdateCheckFrequency

    private let previewLunarService = VietnameseLunarDateService()
    private let trailingControlColumnWidth: CGFloat = 170
    private let recommendedFontFamilies = [
        "SF Pro Text",
        "Avenir Next",
        "Helvetica Neue",
        "Menlo",
        "Be Vietnam Pro",
    ]
    private let sidebarMinimumWidth: CGFloat = 230
    private let sidebarMaximumWidth: CGFloat = 320

    private struct SettingsSearchEntry: Identifiable {
        let id: String
        let pane: SettingsPane
        let section: String
        let title: String
        let subtitle: String
        let icon: String
        let keywords: [String]
    }

    init(updater: SPUUpdater) {
        self.updater = updater
        _automaticallyChecksForUpdates = State(initialValue: updater.automaticallyChecksForUpdates)
        _updateCheckFrequency = State(initialValue: UpdateCheckFrequency.nearest(for: updater.updateCheckInterval))
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailPaneContainer
        }
        .navigationSplitViewStyle(.balanced)
        .frame(width: 820, height: 600)
        .containerBackground(.thinMaterial, for: .window)
        .tint(.accentColor)
        .toolbar(removing: .title)
        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        .overlay(alignment: .top) {
            Color.clear
                .frame(height: 26)
                .contentShape(Rectangle())
                .gesture(WindowDragGesture())
                .allowsWindowActivationEvents(true)
                .accessibilityHidden(true)
        }
        .background(SettingsWindowBehavior(keepOnTop: settings.keepSettingsOnTop))
        .onAppear {
            launchAtLoginManager.refreshStatus()
            automaticallyChecksForUpdates = updater.automaticallyChecksForUpdates
            updateCheckFrequency = UpdateCheckFrequency.nearest(for: updater.updateCheckInterval)
        }
        .onChange(of: automaticallyChecksForUpdates) { newValue in
            updater.automaticallyChecksForUpdates = newValue
        }
        .onChange(of: updateCheckFrequency) { newValue in
            updater.updateCheckInterval = newValue.rawValue
        }
        .onChange(of: searchText) { newValue in
            let matches = filteredPanes(for: newValue)
            guard
                let firstMatch = matches.first,
                !matches.contains(selectedPane)
            else {
                return
            }
            selectedPane = firstMatch
        }
        .confirmationDialog(
            "Khôi phục cài đặt mặc định?",
            isPresented: $isShowingResetDialog,
            titleVisibility: .visible
        ) {
            Button("Xác nhận khôi phục", role: .destructive) { settings.resetAllSettings() }
            Button("Huỷ", role: .cancel) {}
        } message: {
            Text("Tất cả các tuỳ chỉnh về hiển thị và thông báo sẽ quay về giá trị ban đầu.")
        }
    }

    @ViewBuilder
    private var detailPaneContainer: some View {
        if #available(macOS 26.0, *) {
            detailPane
                .frame(minWidth: 400, minHeight: 400)
                .backgroundExtensionEffect()
        } else {
            detailPane
                .frame(minWidth: 400, minHeight: 400)
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        let panes = filteredPanes

        return List(selection: $selectedPane) {
            if panes.isEmpty {
                Text("Không tìm thấy tuỳ chọn phù hợp")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(panes) { pane in
                    LunarSettingsSidebarRow(pane: pane)
                        .tag(pane)
                        .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                }
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: sidebarWidth, ideal: sidebarWidth, max: sidebarWidth)
        .searchable(text: $searchText, placement: .sidebar, prompt: "Tìm tính năng...")
    }

    private var sidebarWidth: CGFloat {
        let font = NSFont.systemFont(ofSize: 13, weight: .medium)
        let maxTitleWidth = SettingsPane.allCases
            .map { pane -> CGFloat in
                (pane.title as NSString).size(withAttributes: [.font: font]).width
            }
            .max() ?? 0

        // icon + spacing + text + row/list paddings + safety padding.
        let requiredWidth = ceil(maxTitleWidth + 24 + 10 + 8 + 8 + 72)
        return min(max(requiredWidth, sidebarMinimumWidth), sidebarMaximumWidth)
    }

    private var hasActiveSearchQuery: Bool {
        !normalizedSearchValue(searchText).isEmpty
    }

    private var settingsSearchIndex: [SettingsSearchEntry] {
        [
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
                keywords: ["token", "template", "mẫu", "{dd}", "{mm}", "{hh}", "format"]
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
                keywords: ["ẩn", "hiện", "toggle", "visibility", "card", "thành phần"]
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

    private var filteredPanes: [SettingsPane] {
        filteredPanes(for: searchText)
    }

    private func filteredPanes(for query: String) -> [SettingsPane] {
        let normalizedQuery = normalizedSearchValue(query)
        guard !normalizedQuery.isEmpty else {
            return SettingsPane.allCases
        }
        let queryTokens = normalizedQuery.split(separator: " ").map(String.init)
        let resultPanes = Set(searchResults(for: query).map(\.pane))

        return SettingsPane.allCases.filter { pane in
            resultPanes.contains(pane) ||
            matchesSearchQuery(
                normalizedQuery: normalizedQuery,
                queryTokens: queryTokens,
                values: paneSearchValues(for: pane)
            )
        }
    }

    private var searchResults: [SettingsSearchEntry] {
        searchResults(for: searchText)
    }

    private func searchResults(for query: String) -> [SettingsSearchEntry] {
        let normalizedQuery = normalizedSearchValue(query)
        guard !normalizedQuery.isEmpty else {
            return []
        }
        let queryTokens = normalizedQuery.split(separator: " ").map(String.init)
        let paneOrderMap = Dictionary(
            uniqueKeysWithValues: SettingsPane.allCases.enumerated().map { ($1, $0) }
        )

        return settingsSearchIndex
            .compactMap { entry -> (SettingsSearchEntry, Int)? in
                let score = searchScore(
                    for: entry,
                    normalizedQuery: normalizedQuery,
                    queryTokens: queryTokens
                )
                guard score > 0 else {
                    return nil
                }
                return (entry, score)
            }
            .sorted { lhs, rhs in
                if lhs.1 != rhs.1 {
                    return lhs.1 > rhs.1
                }

                let lhsPaneOrder = paneOrderMap[lhs.0.pane] ?? .max
                let rhsPaneOrder = paneOrderMap[rhs.0.pane] ?? .max
                if lhsPaneOrder != rhsPaneOrder {
                    return lhsPaneOrder < rhsPaneOrder
                }

                return lhs.0.title.localizedCaseInsensitiveCompare(rhs.0.title) == .orderedAscending
            }
            .map(\.0)
    }

    private func searchScore(
        for entry: SettingsSearchEntry,
        normalizedQuery: String,
        queryTokens: [String]
    ) -> Int {
        let title = normalizedSearchValue(entry.title)
        let section = normalizedSearchValue(entry.section)
        let subtitle = normalizedSearchValue(entry.subtitle)
        let keywords = entry.keywords.map(normalizedSearchValue)
        let combinedValues = ([title, section, subtitle] + keywords).joined(separator: " ")

        guard
            combinedValues.contains(normalizedQuery) ||
            queryTokens.allSatisfy({ combinedValues.contains($0) })
        else {
            return 0
        }

        var score = 0
        if title.contains(normalizedQuery) { score += 120 }
        if section.contains(normalizedQuery) { score += 85 }
        if subtitle.contains(normalizedQuery) { score += 70 }
        if keywords.contains(where: { $0.contains(normalizedQuery) }) { score += 95 }

        for token in queryTokens {
            if title.contains(token) { score += 16 }
            if section.contains(token) { score += 11 }
            if subtitle.contains(token) { score += 9 }
            if keywords.contains(where: { $0.contains(token) }) { score += 14 }
        }

        return max(score, 1)
    }

    private func matchesSearchQuery(
        normalizedQuery: String,
        queryTokens: [String],
        values: [String]
    ) -> Bool {
        let normalizedValues = values.map(normalizedSearchValue)
        let combinedValues = normalizedValues.joined(separator: " ")

        if combinedValues.contains(normalizedQuery) {
            return true
        }

        return queryTokens.allSatisfy { token in
            combinedValues.contains(token)
        }
    }

    private func paneSearchValues(for pane: SettingsPane) -> [String] {
        [pane.title, pane.subtitle] + pane.searchKeywords
    }

    private func normalizedSearchValue(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive, .widthInsensitive], locale: .current)
            .replacingOccurrences(of: "[\\p{P}\\p{S}]+", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Detail Pane Router

    @ViewBuilder
    private var detailPane: some View {
        if hasActiveSearchQuery {
            searchResultsPane
        } else {
            switch selectedPane {
            case .appearance:
                appearancePane
            case .panel:
                panelPane
            case .notifications:
                notificationsPane
            case .updates:
                updatesPane
            case .system:
                systemPane
            case .about:
                aboutPane
            }
        }
    }

    // MARK: - Search Results Pane

    private var searchResultsPane: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                LunarSettingsHeader(
                    title: "Kết quả tìm kiếm",
                    subtitle: "Hiển thị theo từng chức năng giống cách Apple tổ chức trong Settings.",
                    icon: "magnifyingglass"
                ) {
                    LunarSettingsStatusPill(text: "\(searchResults.count) kết quả", color: .accentColor)
                }

                if searchResults.isEmpty {
                    LunarSettingsCard(
                        title: "Không tìm thấy kết quả",
                        subtitle: "Thử từ khóa ngắn hơn hoặc đổi cách diễn đạt",
                        icon: "magnifyingglass.circle"
                    ) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Không có chức năng nào khớp với từ khóa \"\(searchText.trimmingCharacters(in: .whitespacesAndNewlines))\".")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("Gợi ý: thử các từ như \"menu bar\", \"cập nhật\", \"nhắc lễ\", \"đăng nhập\", \"khôi phục\".")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    ForEach(searchResultGroups) { group in
                        LunarSettingsCard(
                            title: group.pane.title,
                            subtitle: group.pane.subtitle,
                            icon: group.pane.icon
                        ) {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(group.results) { result in
                                    searchResultRow(result)
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(14)
        }
        .lunarSettingsBackground()
    }

    private struct SettingsSearchResultGroup: Identifiable {
        let pane: SettingsPane
        let results: [SettingsSearchEntry]
        var id: String { pane.id }
    }

    private var searchResultGroups: [SettingsSearchResultGroup] {
        let groupedResults = Dictionary(grouping: searchResults, by: \.pane)

        return SettingsPane.allCases.compactMap { pane in
            guard let results = groupedResults[pane], !results.isEmpty else {
                return nil
            }
            return SettingsSearchResultGroup(pane: pane, results: results)
        }
    }

    @ViewBuilder
    private func searchResultRow(_ result: SettingsSearchEntry) -> some View {
        Button {
            selectedPane = result.pane
            searchText = ""
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Color.accentColor.opacity(0.12))
                        .frame(width: 24, height: 24)
                    Image(systemName: result.icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(result.title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text("\(result.section) • \(result.subtitle)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                Image(systemName: "arrow.forward.circle.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 9))
            .overlay(
                RoundedRectangle(cornerRadius: 9)
                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Appearance Pane

    private var appearancePane: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                LunarSettingsHeader(
                    title: "Giao diện",
                    subtitle: "Tùy chỉnh cách hiển thị LunarV trên thanh Menu Bar.",
                    icon: "paintbrush.fill"
                ) {
                    VStack(alignment: .trailing, spacing: 6) {
                        LunarSettingsStatusPill(text: settings.menuBarDisplayPreset.title, color: .accentColor)
                        LunarSettingsStatusPill(
                            text: "Font: \(menuBarFontStatusText)",
                            color: settings.menuBarTitleFontFamilyValue.isEmpty ? .secondary : .accentColor
                        )
                        LunarSettingsStatusPill(
                            text: settings.showMenuBarLeadingIconValue ? "Icon: Bật" : "Icon: Tắt",
                            color: settings.showMenuBarLeadingIconValue ? .green : .secondary
                        )
                    }
                }

                LunarSettingsCard(
                    title: "Kiểu hiển thị Menu Bar",
                    subtitle: "Preset nhanh hoặc mẫu tuỳ chỉnh",
                    icon: "menubar.rectangle"
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        previewCard

                        settingsPickerRow(title: "Chế độ", isEnabled: true) {
                            Picker("Chế độ", selection: $settings.menuBarDisplayPreset) {
                                ForEach(MenuBarDisplayPreset.allCases) { preset in
                                    Text(preset.title).tag(preset)
                                }
                            }
                            .pickerStyle(.menu)
                            .controlSize(.regular)
                        }

                        if settings.menuBarDisplayPreset == .custom {
                            customTemplateEditor
                        } else {
                            Text(settings.menuBarDisplayPreset.subtitle)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)
                        }

                        Divider()

                        menuBarTitleFontControl
                        menuBarTitleTypographyControl
                        menuBarLeadingIconControl
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(14)
        }
        .lunarSettingsBackground()
    }

    private var customTemplateEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Mẫu tuỳ chỉnh")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                TextField("Ví dụ: {dd}/{mm} {al} • {wds} • {hh}:{min}:{ss}", text: $settings.customMenuBarTemplate)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
            }

            Text("Chạm để chèn nhanh mã hiển thị:")
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 10) {
                Text("ÂM LỊCH")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundStyle(.orange.opacity(0.8))
                TokenFlowLayout(tokens: DisplayToken.lunarTokens) { token in
                    insertToken(token.code)
                }

                Text("DƯƠNG LỊCH")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundStyle(.blue.opacity(0.8))
                TokenFlowLayout(tokens: DisplayToken.solarTokens) { token in
                    insertToken(token.code)
                }

                Text("THỜI GIAN")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundStyle(.mint.opacity(0.8))
                TokenFlowLayout(tokens: DisplayToken.timeTokens) { token in
                    insertToken(token.code)
                }

                Text("KHÁC")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundStyle(.secondary)
                TokenFlowLayout(tokens: DisplayToken.otherTokens) { token in
                    insertToken(token.code)
                }
            }
            .padding(10)
            .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private var menuBarTitleFontControl: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Kích cỡ chữ trên Menu Bar")
                    .font(.system(size: 13, weight: .medium))
                Spacer(minLength: 0)
                Text("\(settings.menuBarTitleFontSizeValue.formatted(.number.precision(.fractionLength(1))))pt")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            continuousMacSlider(
                value: menuBarTitleFontSizeBinding,
                range: AppSettings.menuBarTitleFontSizeRange
            )

            HStack {
                Text("Cỡ chữ này áp dụng cho phần ngày hiển thị trên thanh Menu Bar.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)

                Button("Mặc định 12pt") {
                    settings.setMenuBarTitleFontSize(AppSettings.defaultMenuBarTitleFontSize)
                }
                .buttonStyle(.link)
            }
        }
    }

    private var menuBarTitleTypographyControl: some View {
        VStack(alignment: .leading, spacing: 10) {
            settingsPickerRow(title: "Phông chữ", isEnabled: true) {
                menuBarFontPickerButton
            }

            if !settings.menuBarTitleFontFamilyValue.isEmpty && !isValidFontFamily(settings.menuBarTitleFontFamilyValue) {
                Text("Font này chưa khả dụng trên máy, LunarV sẽ tự dùng font mặc định để đảm bảo dễ đọc.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Định dạng chữ")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    MenuBarTextStyleButton(
                        title: "Đậm",
                        symbol: "bold",
                        isEnabled: menuBarTitleBoldBinding
                    )
                    MenuBarTextStyleButton(
                        title: "Nghiêng",
                        symbol: "italic",
                        isEnabled: menuBarTitleItalicBinding
                    )
                    MenuBarTextStyleButton(
                        title: "Gạch chân",
                        symbol: "underline",
                        isEnabled: menuBarTitleUnderlineBinding
                    )
                }
            }

            HStack {
                Text("Ưu tiên font đậm vừa phải để menu bar rõ nhưng không quá nặng.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)

                Button("Mặc định kiểu chữ") {
                    settings.setMenuBarTitleFontFamily(AppSettings.defaultMenuBarTitleFontFamily)
                    settings.setMenuBarTitleBold(AppSettings.defaultMenuBarTitleBold)
                    settings.setMenuBarTitleItalic(AppSettings.defaultMenuBarTitleItalic)
                    settings.setMenuBarTitleUnderline(AppSettings.defaultMenuBarTitleUnderline)
                }
                .buttonStyle(.link)
            }
        }
    }

    private var menuBarLeadingIconControl: some View {
        VStack(alignment: .leading, spacing: 6) {
            settingsToggleRow(
                title: "Hiển thị icon bên trái ngày trên Menu Bar",
                isOn: menuBarLeadingIconVisibilityBinding
            )

            if settings.showMenuBarLeadingIconValue {
                HStack {
                    Text("Kích cỡ icon")
                        .font(.system(size: 13, weight: .medium))
                    Spacer(minLength: 0)
                    Text("\(settings.menuBarLeadingIconSizeValue.formatted(.number.precision(.fractionLength(1))))pt")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                continuousMacSlider(
                    value: menuBarLeadingIconSizeBinding,
                    range: AppSettings.menuBarLeadingIconSizeRange
                )

                Text("Apple khuyến nghị icon menu bar nên gọn để cân bằng với chữ và độ dày thanh menu.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Panel Pane

    private var panelPane: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                LunarSettingsHeader(
                    title: "Bảng điều khiển",
                    subtitle: "Sắp xếp thứ tự và quản lý hiển thị các card trong menu.",
                    icon: "list.bullet.indent"
                ) {
                    VStack(alignment: .trailing, spacing: 6) {
                        LunarSettingsStatusPill(text: "Hiển thị: \(visiblePanelCardCount)/\(settings.panelCardOrder.count)")
                    }
                }

                LunarSettingsCard(
                    title: "Thành phần hiển thị",
                    subtitle: "Sắp xếp thứ tự và bật/tắt từng card",
                    icon: "rectangle.grid.1x2.fill"
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text("Kéo-thả để đổi thứ tự, dùng công tắc để ẩn/hiện card trong menu.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)

                            Spacer(minLength: 0)

                            if hiddenPanelCardCount > 0 {
                                LunarSettingsStatusPill(text: "Ẩn: \(hiddenPanelCardCount)", color: .orange)
                            } else {
                                LunarSettingsStatusPill(text: "Tất cả đang hiển thị", color: .green)
                            }
                        }

                        panelOrderList

                        HStack(spacing: 8) {
                            Button("Hiện tất cả") {
                                setAllPanelCardsVisible(true)
                            }
                            .buttonStyle(.bordered)

                            Button("Ẩn tất cả") {
                                setAllPanelCardsVisible(false)
                            }
                            .buttonStyle(.bordered)

                            Spacer(minLength: 0)

                            Button("Khôi phục thứ tự mặc định") {
                                settings.resetPanelCardOrder()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(14)
        }
        .lunarSettingsBackground()
    }

    private var visiblePanelCardCount: Int {
        settings.panelCardOrder.filter { settings.isPanelCardVisible($0) }.count
    }

    private var hiddenPanelCardCount: Int {
        max(settings.panelCardOrder.count - visiblePanelCardCount, 0)
    }

    private var panelOrderList: some View {
        List {
            ForEach(settings.panelCardOrder) { card in
                PanelCardOrderRow(
                    card: card,
                    isVisible: panelCardVisibilityBinding(for: card)
                )
                .listRowInsets(EdgeInsets(top: 4, leading: 10, bottom: 4, trailing: 10))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            .onMove(perform: settings.movePanelCard)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.defaultMinListRowHeight, 60)
        .frame(height: panelOrderListHeight)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.primary.opacity(0.045))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var panelOrderListHeight: CGFloat {
        let rowHeight: CGFloat = 60
        let visibleRows = min(max(settings.panelCardOrder.count, 4), 8)
        return CGFloat(visibleRows) * rowHeight
    }

    private func setAllPanelCardsVisible(_ isVisible: Bool) {
        withAnimation(.easeInOut(duration: 0.2)) {
            for card in settings.panelCardOrder {
                settings.setPanelCardVisible(isVisible, for: card)
            }
        }
    }

    // MARK: - Notifications Pane

    private var notificationsPane: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                LunarSettingsHeader(
                    title: "Thông báo",
                    subtitle: "Thiết lập nhắc ngày lễ âm lịch theo thời điểm bạn muốn nhận.",
                    icon: "bell.badge.fill"
                ) {
                    VStack(alignment: .trailing, spacing: 6) {
                        LunarSettingsStatusPill(
                            text: settings.enableHolidayNotifications ? "Nhắc lễ: Bật" : "Nhắc lễ: Tắt",
                            color: settings.enableHolidayNotifications ? .green : .secondary
                        )
                        if settings.enableHolidayNotifications {
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

    // MARK: - Updates Pane

    private var updatesPane: some View {
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

    // MARK: - System Pane

    private var systemPane: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                LunarSettingsHeader(
                    title: "Hệ thống",
                    subtitle: "Quản lý cửa sổ, tự khởi động và thông số dữ liệu của ứng dụng.",
                    icon: "gearshape.2.fill"
                ) {
                    VStack(alignment: .trailing, spacing: 6) {
                        LunarSettingsStatusPill(
                            text: launchAtLoginManager.isEnabled ? "Tự khởi động: Bật" : "Tự khởi động: Tắt",
                            color: launchAtLoginManager.isEnabled ? .accentColor : .secondary
                        )
                        LunarSettingsStatusPill(
                            text: settings.keepSettingsOnTop ? "Cửa sổ nổi: Bật" : "Cửa sổ nổi: Tắt",
                            color: settings.keepSettingsOnTop ? .green : .secondary
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
                    isOn: $settings.keepSettingsOnTop
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
                isOn: launchAtLoginBinding
            )
        }
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
                    isEnabled: settings.enableHolidayNotifications
                ) {
                    Picker("", selection: $settings.holidayReminderLeadDays) {
                        Text("Đúng ngày").tag(0)
                        Text("Trước 1 ngày").tag(1)
                        Text("Trước 3 ngày").tag(3)
                    }
                }

                settingsPickerRow(
                    title: "Giờ thông báo",
                    isEnabled: settings.enableHolidayNotifications
                ) {
                    Picker("", selection: $settings.holidayReminderHour) {
                        ForEach([6, 7, 8, 9, 18, 20, 21], id: \.self) { hour in
                            Text(hourDisplay(hour)).tag(hour)
                        }
                    }
                }

                settingsPickerRow(
                    title: "Phạm vi lập lịch",
                    isEnabled: settings.enableHolidayNotifications
                ) {
                    Picker("", selection: $settings.notificationWindowDays) {
                        Text("30 ngày tới").tag(30)
                        Text("60 ngày tới").tag(60)
                        Text("90 ngày tới").tag(90)
                        Text("180 ngày tới").tag(180)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Trạng thái quyền thông báo")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(notificationManager.authorizationDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
            }
        }
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
                        ForEach(UpdateCheckFrequency.allCases) { frequency in
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

    private var systemDataCard: some View {
        LunarSettingsCard(
            title: "Dữ liệu & Thời gian",
            subtitle: "Thông số tính toán lịch",
            icon: "clock.arrow.trianglehead.counterclockwise.rotate.90"
        ) {
            VStack(spacing: 10) {
                settingsInfoRow(title: "Múi giờ tính toán", value: "Asia/Ho_Chi_Minh (GMT+7)")
                Divider()
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
            HStack {
                Text("Bạn có thể đặt lại nhanh tất cả cấu hình giao diện, hiển thị và thông báo.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
                Button(role: .destructive) {
                    isShowingResetDialog = true
                } label: {
                    Label("Khôi phục", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var notificationLeadSummary: String {
        switch settings.holidayReminderLeadDays {
        case 0:
            return "Nhắc đúng ngày"
        case 1:
            return "Nhắc trước 1 ngày"
        default:
            return "Nhắc trước \(settings.holidayReminderLeadDays) ngày"
        }
    }

    @ViewBuilder
    private func settingsInfoRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)
        }
    }

    // MARK: - About Pane

    private var aboutPane: some View {
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
                    VStack(spacing: 16) {
                        Image(nsImage: NSApp.applicationIconImage)
                            .resizable()
                            .frame(width: 72, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                        VStack(spacing: 4) {
                            Text("LunarV")
                                .font(.title3.bold())
                            Text("Phiên bản \(appVersionText)")
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }

                        Text("Phát triển bởi Phạm Hùng Tiến, mang tinh hoa lịch cổ truyền lên hệ điều hành macOS hiện đại.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 540)

                        donationQRCodeCard
                    }
                    .frame(maxWidth: .infinity)
                }

            }
            .frame(maxWidth: .infinity)
            .padding(14)
        }
        .lunarSettingsBackground()
    }

    private var donationQRCodeCard: some View {
        VStack(spacing: 10) {
            Text("Ủng hộ phát triển LunarV")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)

            Image("QRDonate")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 180, height: 180)

            Text("Quét mã QR để ủng hộ dự án.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    // MARK: - Helpers

    private var previewCard: some View {
        VStack(spacing: 8) {
            Text("XEM TRƯỚC")
                .font(.system(size: 9, weight: .heavy))
                .foregroundStyle(.tertiary)

            HStack {
                HStack(spacing: AppSettings.menuBarIconTitleSpacing) {
                    if settings.showMenuBarLeadingIconValue {
                        Image("LunarVMenubar")
                            .resizable()
                            .renderingMode(.template)
                            .interpolation(.high)
                            .scaledToFit()
                            .frame(
                                width: menuBarLeadingIconPreviewSize,
                                height: menuBarLeadingIconPreviewSize
                            )
                    }

                    TimelineView(.periodic(from: .now, by: 1)) { timeline in
                        Text(previewMenuBarTitle(at: timeline.date))
                            .font(Font(previewMenuBarFont))
                            .underline(settings.menuBarTitleUnderlineValue)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.accentColor.opacity(0.12), in: Capsule())
                .overlay(Capsule().stroke(Color.accentColor.opacity(0.3), lineWidth: 1))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 16))
    }

    private func insertToken(_ code: String) {
        var template = settings.customMenuBarTemplate
        let compactSeparators: Set<String> = [":", "/", "-"]

        guard !template.isEmpty else {
            settings.customMenuBarTemplate = code
            return
        }

        if compactSeparators.contains(code), template.hasSuffix(" ") {
            template.removeLast()
        }

        let trailingSeparator = template.last.map { compactSeparators.contains(String($0)) } ?? false
        if compactSeparators.contains(code) || trailingSeparator {
            template += code
        } else if template.hasSuffix(" ") {
            template += code
        } else {
            template += " " + code
        }

        settings.customMenuBarTemplate = template
    }

    private func panelCardVisibilityBinding(for card: PanelCardKind) -> Binding<Bool> {
        Binding(
            get: { settings.isPanelCardVisible(card) },
            set: { isVisible in
                settings.setPanelCardVisible(isVisible, for: card)
            }
        )
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

    private var menuBarTitleFontSizeBinding: Binding<Double> {
        Binding(
            get: { settings.menuBarTitleFontSizeValue },
            set: { settings.setMenuBarTitleFontSize($0) }
        )
    }

    private var menuBarTitleBoldBinding: Binding<Bool> {
        Binding(
            get: { settings.menuBarTitleBoldValue },
            set: { settings.setMenuBarTitleBold($0) }
        )
    }

    private var menuBarTitleItalicBinding: Binding<Bool> {
        Binding(
            get: { settings.menuBarTitleItalicValue },
            set: { settings.setMenuBarTitleItalic($0) }
        )
    }

    private var menuBarTitleUnderlineBinding: Binding<Bool> {
        Binding(
            get: { settings.menuBarTitleUnderlineValue },
            set: { settings.setMenuBarTitleUnderline($0) }
        )
    }

    private var installedFontFamilies: [String] {
        NSFontManager.shared.availableFontFamilies.sorted()
    }

    private var recommendedFontPickerOptions: [String] {
        let installed = Set(installedFontFamilies)
        return recommendedFontFamilies.filter { installed.contains($0) }
    }

    private var filteredFontPickerOptions: [String] {
        let query = fontSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return installedFontFamilies
        }
        return installedFontFamilies.filter { $0.localizedCaseInsensitiveContains(query) }
    }

    private var filteredRecommendedFontPickerOptions: [String] {
        let filtered = Set(filteredFontPickerOptions)
        return recommendedFontPickerOptions.filter { filtered.contains($0) }
    }

    private var filteredOtherFontPickerOptions: [String] {
        let recommended = Set(recommendedFontPickerOptions)
        return filteredFontPickerOptions.filter { !recommended.contains($0) }
    }

    private var menuBarFontPickerButton: some View {
        Button {
            fontSearchText = ""
            isShowingFontPicker = true
        } label: {
            HStack(spacing: 8) {
                Text(menuBarFontStatusText)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(width: trailingControlColumnWidth, alignment: .trailing)
            .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .popover(isPresented: $isShowingFontPicker, arrowEdge: .top) {
            menuBarFontPickerPopover
        }
    }

    private var menuBarFontPickerPopover: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Chọn phông chữ Menu Bar")
                .font(.system(size: 12, weight: .semibold))

            TextField("Tìm phông chữ...", text: $fontSearchText)
                .textFieldStyle(.roundedBorder)

            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    MenuBarFontPickerRow(
                        title: "Mặc định hệ thống",
                        subtitle: "Tối ưu cho macOS Menu Bar",
                        previewFontName: nil,
                        isSelected: settings.menuBarTitleFontFamilyValue.isEmpty
                    ) {
                        settings.setMenuBarTitleFontFamily(AppSettings.defaultMenuBarTitleFontFamily)
                        isShowingFontPicker = false
                    }

                    if !filteredRecommendedFontPickerOptions.isEmpty {
                        Text("Gợi ý")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)

                        ForEach(filteredRecommendedFontPickerOptions, id: \.self) { family in
                            MenuBarFontPickerRow(
                                title: family,
                                subtitle: "Khuyến nghị hiển thị rõ trên menu",
                                previewFontName: family,
                                isSelected: settings.menuBarTitleFontFamilyValue == family
                            ) {
                                settings.setMenuBarTitleFontFamily(family)
                                isShowingFontPicker = false
                            }
                        }
                    }

                    if !filteredOtherFontPickerOptions.isEmpty {
                        Text("Tất cả phông chữ")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)

                        ForEach(filteredOtherFontPickerOptions, id: \.self) { family in
                            MenuBarFontPickerRow(
                                title: family,
                                subtitle: family,
                                previewFontName: family,
                                isSelected: settings.menuBarTitleFontFamilyValue == family
                            ) {
                                settings.setMenuBarTitleFontFamily(family)
                                isShowingFontPicker = false
                            }
                        }
                    }

                    if filteredFontPickerOptions.isEmpty {
                        Text("Không tìm thấy phông chữ phù hợp.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 10)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 330)
        }
        .padding(12)
        .frame(width: 340)
    }

    private var menuBarFontStatusText: String {
        settings.menuBarTitleFontFamilyValue.isEmpty ? "Hệ thống" : settings.menuBarTitleFontFamilyValue
    }

    private var previewMenuBarFont: NSFont {
        MenuBarFontResolver.resolve(
            family: settings.menuBarTitleFontFamilyValue,
            size: settings.menuBarTitleFontSizeCGFloat,
            bold: settings.menuBarTitleBoldValue,
            italic: settings.menuBarTitleItalicValue
        )
    }

    private var menuBarLeadingIconSizeBinding: Binding<Double> {
        Binding(
            get: { settings.menuBarLeadingIconSizeValue },
            set: { settings.setMenuBarLeadingIconSize($0) }
        )
    }

    private var menuBarLeadingIconVisibilityBinding: Binding<Bool> {
        Binding(
            get: { settings.showMenuBarLeadingIconValue },
            set: { settings.setShowMenuBarLeadingIcon($0) }
        )
    }

    private var menuBarLeadingIconPreviewSize: CGFloat {
        let statusBarMax = max(NSStatusBar.system.thickness - 2, 10)
        return min(settings.menuBarLeadingIconSizeCGFloat, statusBarMax)
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(get: { launchAtLoginManager.isEnabled }, set: { launchAtLoginManager.setEnabled($0) })
    }

    @ViewBuilder
    private func continuousMacSlider(value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        HStack(spacing: 8) {
            Text("\(Int(range.lowerBound))")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(minWidth: 16, alignment: .trailing)

            Slider(value: value, in: range)
                .controlSize(.small)
                .tint(Color(nsColor: .controlAccentColor))

            Text("\(Int(range.upperBound))")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(minWidth: 16, alignment: .leading)
        }
    }

    private var holidayNotificationBinding: Binding<Bool> {
        Binding(
            get: { settings.enableHolidayNotifications },
            set: { isEnabled in
                guard isEnabled else {
                    settings.enableHolidayNotifications = false
                    Task { @MainActor in
                        await notificationManager.clearPendingHolidayNotifications()
                    }
                    return
                }

                Task { @MainActor in
                    let granted = await notificationManager.requestAuthorizationIfNeeded()
                    settings.enableHolidayNotifications = granted
                    await notificationManager.synchronizeSchedules()
                }
            }
        )
    }

    private func hourDisplay(_ hour: Int) -> String {
        String(format: "%02d:00", hour)
    }

    private var appVersionText: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(v) (\(b))"
    }

    private func isValidFontFamily(_ family: String) -> Bool {
        guard !family.isEmpty else {
            return true
        }
        return NSFontManager.shared.availableFontFamilies.contains(family)
    }

    private enum UpdateCheckFrequency: TimeInterval, CaseIterable, Identifiable {
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

        static func nearest(for interval: TimeInterval) -> UpdateCheckFrequency {
            allCases.min(by: { abs($0.rawValue - interval) < abs($1.rawValue - interval) }) ?? .daily
        }
    }


    private func previewMenuBarTitle(at now: Date) -> String {
        guard let snapshot = previewLunarService.snapshot(for: now) else {
            return "--"
        }
        let timeComponents = previewLunarService.calendar.dateComponents([.hour, .minute, .second], from: now)
        let context = MenuBarTitleContext(
            lunarDay: snapshot.lunar.day,
            lunarMonth: snapshot.lunar.month,
            lunarYear: snapshot.lunar.year,
            isLeapMonth: snapshot.lunar.isLeapMonth,
            canChiYear: snapshot.canChiYear,
            zodiac: snapshot.zodiac,
            solarDay: snapshot.solar.day,
            solarMonth: snapshot.solar.month,
            solarYear: snapshot.solar.year,
            solarWeekdayName: previewLunarService.weekdayName(from: snapshot.solar.weekday),
            solarWeekdayShortName: previewLunarService.weekdayShortName(from: snapshot.solar.weekday),
            hour: timeComponents.hour ?? 0,
            minute: timeComponents.minute ?? 0,
            second: timeComponents.second ?? 0
        )
        return MenuBarTitleFormatter.render(
            preset: settings.menuBarDisplayPreset,
            customTemplate: settings.customMenuBarTemplate,
            context: context
        )
    }
}
