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
            default:
                smallWidget
            }
        }
        .containerBackground(for: .widget) {
            widgetBackground
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(entry.info.accessibilitySummary)
    }

    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(entry.info.weekday.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(secondaryLabelColor)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Image(systemName: entry.info.phaseIcon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(accentColor)
            }

            Spacer(minLength: 0)

            Text(entry.info.lunarDay)
                .font(.system(size: 46, weight: .black, design: .rounded))
                .foregroundStyle(.primary)
                .monospacedDigit()
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Text(entry.info.lunarMonthText)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(secondaryLabelColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Label(entry.info.zodiac, systemImage: "pawprint.fill")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(secondaryLabelColor.opacity(0.9))
                .lineLimit(1)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var mediumWidget: some View {
        HStack(spacing: 14) {
            smallWidget
                .frame(width: 132)
                .overlay(alignment: .trailing) {
                    Rectangle()
                        .fill(.primary.opacity(0.08))
                        .frame(width: 1)
                }

            VStack(alignment: .leading, spacing: 9) {
                infoRow(symbol: "calendar", title: "Dương lịch", value: entry.info.solarDate)
                infoRow(symbol: "leaf.fill", title: "Can chi ngày", value: entry.info.canChiDay)
                infoRow(symbol: "sun.max.fill", title: "Tiết khí", value: entry.info.solarTerm)
                infoRow(symbol: "sparkles", title: "Năm", value: entry.info.canChiYear)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.trailing, 14)
            .padding(.vertical, 12)
        }
    }

    private func infoRow(symbol: String, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Label(title, systemImage: symbol)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(secondaryLabelColor)
                .lineLimit(1)
            Text(value)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    @ViewBuilder
    private var widgetBackground: some View {
        if usesTintedStyle {
            Color.clear
        } else {
            LinearGradient(
                colors: [
                    Color.cyan.opacity(0.24),
                    Color.blue.opacity(0.12),
                    Color.clear,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var accentColor: Color {
        usesTintedStyle ? .primary : .blue
    }

    private var secondaryLabelColor: Color {
        .secondary
    }
}
