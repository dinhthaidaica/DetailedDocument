//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import SwiftUI
import WidgetKit

struct LunarWidgetEntryView: View {
    var entry: LunarTimelineProvider.Entry

    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetRenderingMode) private var renderingMode
    @Environment(\.colorScheme) private var colorScheme

    private var usesTintedStyle: Bool {
        switch renderingMode {
        case .fullColor:
            return false
        default:
            return true
        }
    }

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                smallWidget
            case .systemMedium:
                mediumWidget
            case .systemLarge:
                largeWidget
            default:
                mediumWidget
            }
        }
        .containerBackground(for: .widget) {
            widgetBackground
        }
        .widgetURL(URL(string: "lunarv://today"))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(entry.info.accessibilitySummary)
    }

    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                capsuleTag(text: entry.info.weekday.uppercased(), symbol: "calendar")
                Spacer(minLength: 0)
                phaseBadge
            }

            Spacer(minLength: 0)

            Text(entry.info.lunarDay)
                .font(.system(size: 50, weight: .black, design: .rounded))
                .foregroundStyle(.primary)
                .monospacedDigit()
                .minimumScaleFactor(0.65)
                .lineLimit(1)

            Text(entry.info.lunarMonthText)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Label(entry.info.solarDate, systemImage: "sun.max.fill")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Label(entry.info.canChiYear, systemImage: "sparkles")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var mediumWidget: some View {
        HStack(spacing: 10) {
            mediumHeroCard

            Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                GridRow {
                    metricCard(symbol: "calendar", title: "Dương lịch", value: entry.info.solarDate)
                    metricCard(symbol: "leaf.fill", title: "Can chi ngày", value: entry.info.canChiDay)
                }
                GridRow {
                    metricCard(symbol: "sun.max.fill", title: "Tiết khí", value: entry.info.solarTerm)
                    metricCard(symbol: "pawprint.fill", title: "Con giáp", value: entry.info.zodiac)
                }
            }
        }
        .padding(14)
    }

    private var largeWidget: some View {
        VStack(alignment: .leading, spacing: 10) {
            largeHeroCard

            Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                GridRow {
                    metricCard(symbol: "calendar", title: "Dương lịch", value: entry.info.solarDate)
                    metricCard(symbol: "leaf.fill", title: "Can chi ngày", value: entry.info.canChiDay)
                }
                GridRow {
                    metricCard(symbol: "sun.max.fill", title: "Tiết khí", value: entry.info.solarTerm)
                    metricCard(symbol: "sparkles", title: "Năm can chi", value: entry.info.canChiYear)
                }
                GridRow {
                    metricCard(symbol: "moon.stars.fill", title: "Tháng âm", value: entry.info.lunarMonthText)
                    metricCard(symbol: "pawprint.fill", title: "Con giáp", value: entry.info.zodiac)
                }
            }
        }
        .padding(16)
    }

    private var mediumHeroCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text("ÂM LỊCH")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Spacer(minLength: 0)
                phaseBadge
            }

            Spacer(minLength: 0)

            Text(entry.info.lunarDay)
                .font(.system(size: 40, weight: .black, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.65)

            Text(entry.info.lunarMonthText)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(entry.info.weekday.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.tertiary)
                .lineLimit(1)
        }
        .padding(10)
        .frame(width: 116, alignment: .leading)
        .frame(maxHeight: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(surfaceFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(surfaceStroke, lineWidth: 1)
        )
    }

    private var largeHeroCard: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.info.lunarDay)
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)

                Text(entry.info.lunarMonthYear)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 7) {
                capsuleTag(text: entry.info.weekday.uppercased(), symbol: "calendar")
                capsuleTag(text: entry.info.solarDate, symbol: "sun.max.fill")
                HStack(spacing: 6) {
                    phaseBadge
                    capsuleTag(text: entry.info.canChiYear, symbol: "sparkles")
                }
            }
            .layoutPriority(1)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(surfaceFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(surfaceStroke, lineWidth: 1)
        )
    }

    private func metricCard(symbol: String, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Label(title, systemImage: symbol)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(surfaceFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(surfaceStroke, lineWidth: 1)
        )
    }

    private func capsuleTag(text: String, symbol: String? = nil) -> some View {
        HStack(spacing: 4) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 9, weight: .semibold))
            }

            Text(text)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(surfaceFill)
        )
        .overlay(
            Capsule()
                .stroke(surfaceStroke, lineWidth: 1)
        )
    }

    private var phaseBadge: some View {
        Image(systemName: entry.info.phaseIcon)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(accentColor)
            .frame(width: 26, height: 26)
            .background(
                Circle()
                    .fill(accentBadgeFill)
            )
            .overlay(
                Circle()
                    .stroke(surfaceStroke, lineWidth: 1)
            )
    }

    @ViewBuilder
    private var widgetBackground: some View {
        if usesTintedStyle {
            Color.clear
        } else {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.cyan.opacity(colorScheme == .dark ? 0.24 : 0.2),
                        Color.blue.opacity(colorScheme == .dark ? 0.16 : 0.1),
                        Color.indigo.opacity(colorScheme == .dark ? 0.12 : 0.08),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                RadialGradient(
                    colors: [
                        Color.white.opacity(colorScheme == .dark ? 0.08 : 0.22),
                        Color.clear,
                    ],
                    center: .topLeading,
                    startRadius: 6,
                    endRadius: 180
                )

                RadialGradient(
                    colors: [
                        Color.teal.opacity(colorScheme == .dark ? 0.14 : 0.12),
                        Color.clear,
                    ],
                    center: .bottomTrailing,
                    startRadius: 12,
                    endRadius: 220
                )
            }
        }
    }

    private var accentColor: Color {
        usesTintedStyle ? .primary : .blue
    }

    private var accentBadgeFill: Color {
        if usesTintedStyle {
            return Color.primary.opacity(0.16)
        }
        return Color.white.opacity(colorScheme == .dark ? 0.08 : 0.45)
    }

    private var surfaceFill: Color {
        if usesTintedStyle {
            return Color.primary.opacity(0.1)
        }
        return Color.white.opacity(colorScheme == .dark ? 0.08 : 0.5)
    }

    private var surfaceStroke: Color {
        if usesTintedStyle {
            return Color.primary.opacity(0.18)
        }
        return Color.white.opacity(colorScheme == .dark ? 0.12 : 0.52)
    }
}
