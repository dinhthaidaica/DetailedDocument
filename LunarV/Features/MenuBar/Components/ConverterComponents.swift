//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import SwiftUI

// MARK: - Converter Mode

enum DateConverterMode: String, CaseIterable, Identifiable {
    case solarToLunar
    case lunarToSolar

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .solarToLunar:
            return "sun.max.fill"
        case .lunarToSolar:
            return "moon.stars.fill"
        }
    }

    var title: String {
        switch self {
        case .solarToLunar:
            return "Dương -> Âm"
        case .lunarToSolar:
            return "Âm -> Dương"
        }
    }
}

// MARK: - Converter Mode Selector

struct ConverterModeSelector: View {
    @Binding var mode: DateConverterMode

    var body: some View {
        HStack(spacing: 0) {
            ForEach(DateConverterMode.allCases) { modeItem in
                let isActive = modeItem == mode

                Button {
                    withAnimation(.snappy(duration: 0.2)) {
                        mode = modeItem
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: modeItem.icon)
                            .font(.system(size: 10, weight: .bold))
                        Text(modeItem.title)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(isActive ? Color.accentColor : .primary.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isActive ? Color.accentColor.opacity(0.14) : .clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Converter Panel

struct ConverterPanel<InputContent: View, ResultContent: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    private let inputContent: InputContent
    private let resultContent: ResultContent

    init(
        title: String,
        subtitle: String,
        icon: String,
        @ViewBuilder inputContent: () -> InputContent,
        @ViewBuilder resultContent: () -> ResultContent
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.inputContent = inputContent()
        self.resultContent = resultContent()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 24, height: 24)
                    .background(Color.accentColor.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.primary)
                    Text(justifiedAttributedText(
                        subtitle,
                        size: 10,
                        weight: .medium,
                        color: .secondaryLabelColor
                    ))
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            inputContent
            resultContent
        }
        .padding(12)
        .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Converter Result Card

struct ConverterResultCard: View {
    let title: String
    let value: String
    let detail: String
    let copyTitle: String
    let onCopy: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title.uppercased())
                    .font(.system(size: 8, weight: .heavy))
                    .foregroundStyle(Color.accentColor.opacity(0.8))
                    .tracking(0.8)

                Text(value)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Text(justifiedAttributedText(
                    detail,
                    size: 10,
                    weight: .medium,
                    color: .secondaryLabelColor
                ))
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer(minLength: 0)

            Button(action: onCopy) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 28, height: 28)
                    .background(Color.accentColor.opacity(0.1), in: Circle())
            }
            .buttonStyle(.plain)
            .help(copyTitle)
        }
        .padding(12)
        .background(Color.accentColor.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accentColor.opacity(0.18), lineWidth: 0.5)
        )
    }
}

// MARK: - Converter Error Card

struct ConverterErrorCard: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12))
                .foregroundStyle(.orange)
            Text(justifiedAttributedText(
                message,
                size: 10,
                weight: .medium,
                color: .secondaryLabelColor
            ))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .background(Color.orange.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.18), lineWidth: 0.5)
        )
    }
}

// MARK: - Converter Stepper Field

struct ConverterStepperField: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 8, weight: .heavy))
                .foregroundStyle(.secondary)
                .tracking(0.8)

            HStack(spacing: 6) {
                stepButton(
                    icon: "minus",
                    isDisabled: value <= range.lowerBound
                ) {
                    value = max(value - 1, range.lowerBound)
                }

                Text("\(value)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)

                stepButton(
                    icon: "plus",
                    isDisabled: value >= range.upperBound
                ) {
                    value = min(value + 1, range.upperBound)
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func stepButton(
        icon: String,
        isDisabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .heavy))
                .foregroundStyle(isDisabled ? Color.primary.opacity(0.25) : Color.accentColor)
                .frame(width: 24, height: 24)
                .background(isDisabled ? Color.primary.opacity(0.04) : Color.accentColor.opacity(0.1), in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

// MARK: - Converter Action Field

struct ConverterActionField: View {
    let title: String
    let buttonTitle: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 8, weight: .heavy))
                .foregroundStyle(.secondary)
                .tracking(0.8)

            Button(action: action) {
                HStack(spacing: 5) {
                    Image(systemName: systemImage)
                        .font(.system(size: 9, weight: .bold))
                    Text(buttonTitle)
                        .font(.system(size: 10, weight: .semibold))
                        .lineLimit(1)
                }
                .foregroundStyle(Color.accentColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Converter Leap Month Field

struct ConverterLeapMonthField: View {
    @Binding var isOn: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("THÁNG NHUẬN")
                .font(.system(size: 8, weight: .heavy))
                .foregroundStyle(.secondary)
                .tracking(0.8)

            HStack(spacing: 8) {
                Circle()
                    .fill(isOn ? Color.accentColor : Color.primary.opacity(0.15))
                    .frame(width: 6, height: 6)
                Text(isOn ? "Đang bật" : "Đang tắt")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(isOn ? Color.accentColor : .secondary)
                Spacer(minLength: 0)
                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .tint(Color(nsColor: .controlAccentColor))
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
    }
}
