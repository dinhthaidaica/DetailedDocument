//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import AppKit
import SwiftUI

// MARK: - Section Card

struct SectionCard<Content: View, Trailing: View>: View {
    let title: String
    var trailingView: (() -> Trailing)? = nil
    @ViewBuilder var content: Content

    init(title: String, @ViewBuilder trailingView: @escaping () -> Trailing, @ViewBuilder content: () -> Content) {
        self.title = title; self.trailingView = trailingView; self.content = content()
    }
    init(title: String, @ViewBuilder content: () -> Content) where Trailing == EmptyView {
        self.title = title; self.trailingView = nil; self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.accentColor)
                    .frame(width: 3, height: 12)
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(.primary.opacity(0.55))
                    .tracking(1.2)
                Spacer()
                trailingView?()
            }
            content
        }
        .padding(16)
        .glassEffect(Material.regular, in: RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 26, height: 26)
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.accentColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label.uppercased())
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundStyle(.secondary)
                    .tracking(0.3)
                Text(justifiedAttributedText(
                    value,
                    size: 12,
                    weight: .semibold
                ))
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Stat Tile

struct StatTile: View {
    let title: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 8, weight: .heavy))
                .foregroundStyle(.secondary)
                .tracking(0.5)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Can Chi Pill

struct CanChiPill: View {
    let title: String
    let value: String
    var body: some View {
        VStack(spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 8, weight: .heavy))
                .foregroundStyle(.secondary)
                .tracking(0.8)
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Can chi \(title): \(value)")
    }
}

// MARK: - Hero Chip

struct HeroChip: View {
    let icon: String
    let title: String
    let value: String
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 26, height: 26)
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.accentColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(.system(size: 8, weight: .heavy))
                    .foregroundStyle(.secondary)
                    .tracking(0.5)
                Text(value)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - Hour Period Pill

struct HourPeriodPill: View {
    let hour: VietnameseHourPeriod

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.accentColor.opacity(0.2))
                .frame(width: 6, height: 6)
            VStack(alignment: .leading, spacing: 2) {
                Text(hour.canChi)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.primary)
                Text(hour.timeRange)
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.accentColor.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.accentColor.opacity(0.18), lineWidth: 0.5)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Giờ hoàng đạo \(hour.canChi), \(hour.timeRange)")
    }
}

// MARK: - Guidance Score View

struct GuidanceScoreView: View {
    let score: Int

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(scoreColor.opacity(0.15), lineWidth: 4)

            // Progress arc
            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(
                    AngularGradient(
                        colors: [scoreColor.opacity(0.6), scoreColor],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * Double(score) / 100)
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 0) {
                Text("\(score)")
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundStyle(scoreColor)
                Text("điểm")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 54, height: 54)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Điểm ngày: \(score) trên 100")
    }

    private var scoreColor: Color {
        switch score {
        case 80...:
            return .green
        case 70...79:
            return .mint
        case 55...69:
            return .orange
        default:
            return .red
        }
    }
}

// MARK: - Day Officer Panel

struct DayOfficerPanel: View {
    let officer: LunarDayOfficerInfo

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(levelColor)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("Trực \(officer.name)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(levelColor)
                    Spacer()
                    Text(levelTitle)
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(levelColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(levelColor.opacity(0.12), in: Capsule())
                }

                Text(justifiedAttributedText(
                    officer.calculationNote,
                    size: 9,
                    weight: .semibold,
                    color: .secondaryLabelColor
                ))
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

                Text(justifiedAttributedText(
                    officer.summary,
                    size: 10,
                    weight: .medium
                ))
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(levelColor.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(levelColor.opacity(0.15), lineWidth: 0.5)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Trực \(officer.name), \(levelTitle). \(officer.summary)")
    }

    private var levelTitle: String {
        switch officer.level {
        case .favorable:
            return "Thuận lợi"
        case .neutral:
            return "Cân bằng"
        case .caution:
            return "Thận trọng"
        }
    }

    private var levelColor: Color {
        switch officer.level {
        case .favorable:
            return .green
        case .neutral:
            return .blue
        case .caution:
            return .orange
        }
    }
}

// MARK: - Activity Insight Row

struct ActivityInsightRow: View {
    let insight: LunarActivityInsightInfo
    private let categoryColumnWidth: CGFloat = 92

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(insight.categoryText)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(levelColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(levelColor.opacity(0.12), in: Capsule())
                .frame(width: categoryColumnWidth, alignment: .leading)

            Text(justifiedAttributedText(
                insight.reason,
                size: 10,
                weight: .medium
            ))
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var levelColor: Color {
        switch insight.level {
        case .favorable:
            return .green
        case .neutral:
            return .blue
        case .caution:
            return .orange
        }
    }
}

// MARK: - Guidance Block

struct GuidanceBlock: View {
    let title: String
    let items: [String]
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(tint)
                    .frame(width: 3, height: 10)
                Text(title)
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(tint.opacity(0.9))
            }
            VStack(alignment: .leading, spacing: 5) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(tint.opacity(0.6))
                            .frame(width: 4, height: 4)
                            .padding(.top, 5.5)
                        Text(justifiedAttributedText(item, size: 11, weight: .medium))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 9)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Month Day Cell View

struct MonthDayCellView: View {
    let cell: LunarMonthDayCell
    let weekdayIndex: Int
    let onHolidayHover: (String?) -> Void
    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 1) {
            if let solar = cell.solarDay, let lunar = cell.lunarDay {
                Text("\(solar)")
                    .font(.system(size: 13, weight: cell.isToday ? .heavy : .semibold, design: cell.isToday ? .rounded : .default))
                    .foregroundStyle(cell.isToday ? .white : (cell.holiday != nil || weekdayIndex >= 5 ? .red.opacity(0.9) : .primary))
                Text("\(lunar)")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(cell.isToday ? .white.opacity(0.85) : .primary.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 40)
        .background {
            if cell.isToday {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.accentColor.opacity(0.3), radius: 4, y: 2)
            } else if isHovered {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.primary.opacity(0.06))
            }
        }
        .overlay(alignment: .topTrailing) {
            if cell.holiday != nil { Circle().fill(.red).frame(width: 5).padding(3) }
            else if cell.isFirstLunarDay { Circle().fill(.orange).frame(width: 5).padding(3) }
        }
        .onHover { h in
            withAnimation(.snappy(duration: 0.1)) { isHovered = h }

            guard let holiday = cell.holiday, h else {
                onHolidayHover(nil)
                return
            }

            let detail: String
            if let solarDay = cell.solarDay, let lunarDay = cell.lunarDay {
                detail = "\(holiday) • DL \(solarDay) • AL \(lunarDay)"
            } else {
                detail = holiday
            }

            onHolidayHover(detail)
        }
        .onDisappear {
            if cell.holiday != nil {
                onHolidayHover(nil)
            }
        }
        .help(cell.holiday ?? "")
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(cellAccessibilityLabel)
    }

    private var cellAccessibilityLabel: String {
        guard let solar = cell.solarDay, let lunar = cell.lunarDay else {
            return ""
        }
        var label = "Ngày \(solar), âm lịch \(lunar)"
        if cell.isToday { label += ", hôm nay" }
        if let holiday = cell.holiday { label += ", \(holiday)" }
        return label
    }
}

// MARK: - Toolbar Hover Button Style

struct ToolbarHoverButtonStyle: ButtonStyle {
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.primary.opacity(isHovered ? 0.1 : 0.04))
            )
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
            .onHover { isHovered = $0 }
    }
}

// MARK: - Justified Attributed Text

private let justifiedParagraphStyle: NSParagraphStyle = {
    let style = NSMutableParagraphStyle()
    style.alignment = .justified
    style.hyphenationFactor = 0.8
    style.lineBreakMode = .byWordWrapping
    return style.copy() as? NSParagraphStyle ?? NSParagraphStyle.default
}()

private let justifiedFontCache: NSCache<NSString, NSFont> = {
    let cache = NSCache<NSString, NSFont>()
    cache.countLimit = 32
    return cache
}()

private func justifiedFont(size: CGFloat, weight: NSFont.Weight) -> NSFont {
    let key = "\(size)-\(weight.rawValue)" as NSString
    if let cachedFont = justifiedFontCache.object(forKey: key) {
        return cachedFont
    }

    let font = NSFont.systemFont(ofSize: size, weight: weight)
    justifiedFontCache.setObject(font, forKey: key)
    return font
}

func justifiedAttributedText(
    _ text: String,
    size: CGFloat,
    weight: NSFont.Weight = .regular,
    color: NSColor = .labelColor
) -> AttributedString {
    let attributed = NSAttributedString(
        string: text,
        attributes: [
            .font: justifiedFont(size: size, weight: weight),
            .foregroundColor: color,
            .paragraphStyle: justifiedParagraphStyle,
        ]
    )
    return AttributedString(attributed)
}

// MARK: - Glass Effect

extension View {
    func glassEffect<S: Shape>(_ material: Material = .regular, tint: Color = .clear, in shape: S) -> some View {
        self.background(material, in: shape)
            .background(tint, in: shape)
            .overlay(
                shape
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.4),
                                .white.opacity(0.1),
                                .black.opacity(0.05),
                                .white.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .blendMode(.overlay)
            )
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Entrance Animation

struct EntranceAnimationModifier: ViewModifier {
    let hasAppeared: Bool
    let reduceMotion: Bool
    func body(content: Content) -> some View {
        content.opacity(hasAppeared ? 1 : 0).offset(y: hasAppeared ? 0 : 10)
            .animation(reduceMotion ? .none : .spring(duration: 0.6, bounce: 0.3), value: hasAppeared)
    }
}

extension View {
    func entranceAnimation(hasAppeared: Bool, reduceMotion: Bool) -> some View {
        modifier(EntranceAnimationModifier(hasAppeared: hasAppeared, reduceMotion: reduceMotion))
    }
}
