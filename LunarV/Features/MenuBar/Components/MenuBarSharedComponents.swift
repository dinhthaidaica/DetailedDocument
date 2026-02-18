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
            HStack {
                Text(title.uppercased()).font(.system(size: 10, weight: .bold)).foregroundStyle(.primary.opacity(0.6)).tracking(1)
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
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon).font(.system(size: 10, weight: .bold)).foregroundStyle(Color.accentColor)
                .frame(width: 24, height: 24).background(Color.accentColor.opacity(0.1), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.primary.opacity(0.65))
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
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.system(size: 9, weight: .bold)).foregroundStyle(.primary.opacity(0.5))
            Text(value).font(.system(size: 12, weight: .bold)).foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(10)
        .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Can Chi Pill

struct CanChiPill: View {
    let title: String
    let value: String
    var body: some View {
        VStack(spacing: 4) {
            Text(title).font(.system(size: 9, weight: .bold)).foregroundStyle(.primary.opacity(0.5))
            Text(value).font(.system(size: 12, weight: .bold)).foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 10)
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
            Image(systemName: icon).font(.system(size: 11, weight: .semibold)).foregroundStyle(Color.accentColor)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.system(size: 9, weight: .bold)).foregroundStyle(.primary.opacity(0.6))
                Text(value).font(.system(size: 11, weight: .bold)).foregroundStyle(.primary).lineLimit(1)
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
        VStack(alignment: .leading, spacing: 2) {
            Text(hour.canChi)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.primary)
            Text(hour.timeRange)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.accentColor.opacity(0.25), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Giờ hoàng đạo \(hour.canChi), \(hour.timeRange)")
    }
}

// MARK: - Guidance Score View

struct GuidanceScoreView: View {
    let score: Int

    var body: some View {
        VStack(spacing: 2) {
            Text("\(score)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(scoreColor)
            Text("/100")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(width: 52, height: 52)
        .background(scoreColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(scoreColor.opacity(0.35), lineWidth: 1)
        )
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
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("Trực \(officer.name)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(levelColor)
                Spacer()
                Text(levelTitle)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(levelColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(levelColor.opacity(0.14), in: Capsule())
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(levelColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(levelColor.opacity(0.22), lineWidth: 1)
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
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(tint.opacity(0.9))
            VStack(alignment: .leading, spacing: 4) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 6) {
                        Circle()
                            .fill(tint.opacity(0.8))
                            .frame(width: 5, height: 5)
                            .padding(.top, 5)
                        Text(justifiedAttributedText(item, size: 11, weight: .medium))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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
        VStack(spacing: 0) {
            if let solar = cell.solarDay, let lunar = cell.lunarDay {
                Text("\(solar)").font(.system(size: 13, weight: cell.isToday ? .bold : .semibold))
                    .foregroundStyle(cell.isToday ? Color.accentColor : (cell.holiday != nil || weekdayIndex >= 5 ? .red.opacity(0.9) : .primary))
                Text("\(lunar)").font(.system(size: 9, weight: .medium))
                    .foregroundStyle(cell.isToday ? Color.accentColor.opacity(0.8) : .primary.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 38)
        .background(cell.isToday ? Color.accentColor.opacity(0.15) : (isHovered ? Color.primary.opacity(0.05) : .clear), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(cell.isToday ? Color.accentColor.opacity(0.5) : .clear, lineWidth: 1.5))
        .overlay(alignment: .topTrailing) {
            if cell.holiday != nil { Circle().fill(.red).frame(width: 4).padding(4) }
            else if cell.isFirstLunarDay { Circle().fill(.orange).frame(width: 4).padding(4) }
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

// MARK: - Justified Attributed Text

func justifiedAttributedText(
    _ text: String,
    size: CGFloat,
    weight: NSFont.Weight = .regular,
    color: NSColor = .labelColor
) -> AttributedString {
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .justified
    paragraphStyle.hyphenationFactor = 0.8
    paragraphStyle.lineBreakMode = .byWordWrapping

    let attributed = NSAttributedString(
        string: text,
        attributes: [
            .font: NSFont.systemFont(ofSize: size, weight: weight),
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle,
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
