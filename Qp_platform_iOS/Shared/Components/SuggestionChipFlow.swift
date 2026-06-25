import SwiftUI

struct SuggestionChipFlow: View {
    let suggestions: [String]
    var maxRows = 2
    var maxItemsPerRow = 2
    var horizontalPadding: CGFloat = 16
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(rows, id: \.self) { row in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(row, id: \.self) { suggestion in
                            Button {
                                onSelect(suggestion)
                            } label: {
                                SuggestionChip(title: suggestion)
                            }
                            .buttonStyle(LiquidButtonPressStyle())
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                }
            }
        }
    }

    private var rows: [[String]] {
        let visibleItems = Array(suggestions.prefix(maxRows * maxItemsPerRow))
        return stride(from: 0, to: visibleItems.count, by: maxItemsPerRow).map { start in
            Array(visibleItems[start..<min(start + maxItemsPerRow, visibleItems.count)])
        }
    }
}

private struct SuggestionChip: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color.white.opacity(0.9))
            .lineLimit(1)
            .truncationMode(.tail)
            .padding(.horizontal, 12)
            .frame(height: 32)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.11),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .stroke(Color.white.opacity(0.18), lineWidth: 0.8)
                    )
            )
    }
}
