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

    private let heroCornerRadius: CGFloat = 16
    private let cardCornerRadius: CGFloat = 12

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
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                capsuleTag(text: entry.info.weekday.uppercased(), symbol: "calendar")
                Spacer(minLength: 0)
                phaseBadge
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(entry.info.lunarDay)
                    .font(.system(size: 56, weight: .black, design: .rounded))
                    .foregroundStyle(heroNumberStyle)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)

                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.info.lunarMonthText)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(secondaryTextColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    compactMetaRow(symbol: "sparkles", text: entry.info.canChiYear, fontSize: 9, weight: .bold)
                }
                .padding(.top, 6)
            }

            compactMetaRow(symbol: "sun.max.fill", text: entry.info.solarDate)
            compactMetaRow(symbol: "leaf.fill", text: entry.info.canChiDay)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var mediumWidget: some View {
        HStack(spacing: 12) {
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
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 6) {
                Text("HÔM NAY")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundStyle(secondaryTextColor)
                    .lineLimit(1)

                Spacer(minLength: 0)
                phaseBadge
            }

            Text(entry.info.lunarDay)
                .font(.system(size: 42, weight: .black, design: .rounded))
                .foregroundStyle(heroNumberStyle)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.65)

            Text(entry.info.lunarMonthText)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(secondaryTextColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Rectangle()
                .fill(surfaceStroke)
                .frame(height: 1)

            compactMetaRow(symbol: "calendar", text: entry.info.weekday.uppercased(), fontSize: 9, weight: .bold)
            compactMetaRow(symbol: "sparkles", text: entry.info.canChiYear, fontSize: 9, weight: .bold)
        }
        .padding(11)
        .frame(width: 122, alignment: .leading)
        .frame(maxHeight: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: heroCornerRadius, style: .continuous)
                .fill(surfaceFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: heroCornerRadius, style: .continuous)
                .stroke(surfaceStroke, lineWidth: 1)
        )
    }

    private var largeHeroCard: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.info.lunarDay)
                    .font(.system(size: 54, weight: .black, design: .rounded))
                    .foregroundStyle(heroNumberStyle)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)

                Text(entry.info.lunarMonthYear)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(secondaryTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                compactMetaRow(symbol: "leaf.fill", text: entry.info.canChiDay, fontSize: 11)
            }

            Spacer(minLength: 6)

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
            RoundedRectangle(cornerRadius: heroCornerRadius, style: .continuous)
                .fill(surfaceFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: heroCornerRadius, style: .continuous)
                .stroke(surfaceStroke, lineWidth: 1)
        )
    }

    private func metricCard(symbol: String, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(accentColor)
                    .symbolRenderingMode(.hierarchical)

                Text(title)
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundStyle(secondaryTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

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
            RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                .fill(surfaceFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                .stroke(surfaceStroke, lineWidth: 1)
        )
    }

    private func compactMetaRow(symbol: String, text: String, fontSize: CGFloat = 10, weight: Font.Weight = .semibold) -> some View {
        HStack(spacing: 5) {
            Image(systemName: symbol)
                .font(.system(size: max(fontSize - 1, 8), weight: .bold))
                .symbolRenderingMode(.hierarchical)

            Text(text)
                .font(.system(size: fontSize, weight: weight, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(secondaryTextColor)
    }

    private func capsuleTag(text: String, symbol: String? = nil) -> some View {
        HStack(spacing: 4) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 9, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(accentColor)
            }

            Text(text)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(secondaryTextColor)
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
            .frame(width: 28, height: 28)
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
                    colors: backgroundGradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                RadialGradient(
                    colors: [
                        Color.white.opacity(colorScheme == .dark ? 0.08 : 0.32),
                        Color.clear,
                    ],
                    center: .topLeading,
                    startRadius: 8,
                    endRadius: 180
                )

                Circle()
                    .fill(backgroundOrbPrimary)
                    .frame(width: 132, height: 132)
                    .blur(radius: 2)
                    .offset(x: -62, y: 58)

                Circle()
                    .fill(backgroundOrbSecondary)
                    .frame(width: 90, height: 90)
                    .blur(radius: 3)
                    .offset(x: 62, y: -54)
            }
        }
    }

    private var heroNumberStyle: AnyShapeStyle {
        if usesTintedStyle {
            return AnyShapeStyle(Color.primary)
        }
        let colors: [Color]
        if colorScheme == .dark {
            colors = [
                Color(red: 0.98, green: 0.84, blue: 0.52),
                Color(red: 0.98, green: 0.66, blue: 0.34),
            ]
        } else {
            colors = [
                Color(red: 0.20, green: 0.25, blue: 0.33),
                Color(red: 0.45, green: 0.28, blue: 0.14),
            ]
        }
        return AnyShapeStyle(
            LinearGradient(
                colors: colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var accentColor: Color {
        if usesTintedStyle {
            return .primary
        }
        return colorScheme == .dark
            ? Color(red: 0.97, green: 0.73, blue: 0.37)
            : Color(red: 0.70, green: 0.43, blue: 0.16)
    }

    private var accentBadgeFill: Color {
        if usesTintedStyle {
            return Color.primary.opacity(0.16)
        }
        return Color.white.opacity(colorScheme == .dark ? 0.12 : 0.74)
    }

    private var surfaceFill: Color {
        if usesTintedStyle {
            return Color.primary.opacity(0.1)
        }
        return Color.white.opacity(colorScheme == .dark ? 0.12 : 0.82)
    }

    private var surfaceStroke: Color {
        if usesTintedStyle {
            return Color.primary.opacity(0.18)
        }
        return colorScheme == .dark
            ? Color.white.opacity(0.18)
            : Color.black.opacity(0.08)
    }

    private var secondaryTextColor: Color {
        if usesTintedStyle {
            return .secondary
        }
        return colorScheme == .dark
            ? Color.white.opacity(0.82)
            : Color.black.opacity(0.66)
    }

    private var backgroundGradientColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(red: 0.10, green: 0.12, blue: 0.16),
                Color(red: 0.14, green: 0.17, blue: 0.22),
                Color(red: 0.18, green: 0.15, blue: 0.12),
            ]
        }
        return [
            Color(red: 0.98, green: 0.97, blue: 0.94),
            Color(red: 0.95, green: 0.96, blue: 0.99),
            Color(red: 0.99, green: 0.94, blue: 0.88),
        ]
    }

    private var backgroundOrbPrimary: Color {
        colorScheme == .dark
            ? Color(red: 0.95, green: 0.66, blue: 0.33).opacity(0.24)
            : Color(red: 0.99, green: 0.78, blue: 0.52).opacity(0.26)
    }

    private var backgroundOrbSecondary: Color {
        colorScheme == .dark
            ? Color(red: 0.69, green: 0.74, blue: 0.91).opacity(0.18)
            : Color(red: 0.82, green: 0.86, blue: 0.97).opacity(0.22)
    }
}
