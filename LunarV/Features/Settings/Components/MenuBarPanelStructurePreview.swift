//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import AppKit
import SwiftUI

struct MenuBarPanelStructurePreview: View {
    let visibleCards: [PanelCardKind]

    var body: some View {
        let displayedCards = Array(visibleCards.prefix(6))

        return VStack(spacing: 0) {
            topToolbarSkeleton

            Divider().opacity(0.1)

            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 10) {
                    if visibleCards.isEmpty {
                        emptyState
                    } else {
                        ForEach(Array(displayedCards.enumerated()), id: \.element) { index, card in
                            previewCard(
                                title: card.title,
                                icon: card.icon,
                                isLastCard: index == displayedCards.count - 1
                            )
                        }
                    }
                }
                .padding(12)
            }
        }
        .background(
            LinearGradient(
                colors: [
                    Color(nsColor: .windowBackgroundColor).opacity(0.98),
                    Color.accentColor.opacity(0.03),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var topToolbarSkeleton: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(Color.accentColor.opacity(0.28))
                .frame(width: 26, height: 26)
                .overlay(
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.accentColor)
                )

            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color.primary.opacity(0.16))
                    .frame(width: 72, height: 7)
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color.primary.opacity(0.1))
                    .frame(width: 58, height: 6)
            }

            Spacer(minLength: 0)

            HStack(spacing: 6) {
                ForEach(0 ..< 4, id: \.self) { _ in
                    Circle()
                        .fill(Color.primary.opacity(0.09))
                        .frame(width: 16, height: 16)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.45))
    }

    private var emptyState: some View {
        VStack(alignment: .center, spacing: 6) {
            Image(systemName: "rectangle.stack.badge.minus")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
            Text("Không có thẻ nào đang hiển thị")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private func previewCard(
        title: String,
        icon: String,
        isLastCard: Bool
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 22, height: 22)
                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 7, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.primary.opacity(0.9))
                    .lineLimit(1)

                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color.primary.opacity(0.14))
                    .frame(height: 6)

                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color.primary.opacity(0.08))
                    .frame(width: 120, height: 6)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    Color(nsColor: .controlBackgroundColor)
                        .opacity(isLastCard ? 0.72 : 0.58)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.primary.opacity(isLastCard ? 0.16 : 0.1), lineWidth: 0.8)
        )
    }
}
