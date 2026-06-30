import SwiftUI

struct StorefrontTabDockView: View {
    let tabs: [StorefrontTab]
    let selectedTabID: String?
    let onSelectTab: (StorefrontTab) -> Void
    let onOpenMore: () -> Void

    var body: some View {
        // Try 3 visible tabs first; if they don't fit, fall back to 2, then 1.
        // ViewThatFits picks the first option whose natural width fits the container.
        ViewThatFits(in: .horizontal) {
            chipRow(maxVisible: 3)
            chipRow(maxVisible: 2)
            chipRow(maxVisible: 1)
        }
    }

    @ViewBuilder
    private func chipRow(maxVisible: Int) -> some View {
        let count = min(maxVisible, tabs.count)
        let hasMore = tabs.count > count

        HStack(spacing: -1) {
            ForEach(Array(tabs.prefix(count).enumerated()), id: \.element.id) { index, tab in
                let isFirst = index == 0
                let isLast = !hasMore && index == count - 1

                Button { onSelectTab(tab) } label: {
                    Text(tab.title)
                        .font(.system(size: 12, weight: .regular))
                        .tracking(0.48)
                        .foregroundStyle(Color(hex: "F0F0F0").opacity(selectedTabID == tab.id ? 1 : 0.9))
                        .lineLimit(1)
                        .padding(.horizontal, 16)
                        .frame(height: 36)
                        .contentShape(Rectangle())
                }
                .contentShape(Rectangle())
                .buttonStyle(LiquidButtonPressStyle())
                .background(chipBackground(isFirst: isFirst, isLast: isLast))
                .fixedSize()
            }

            if hasMore {
                Button(action: onOpenMore) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                        .frame(width: 40, height: 36)
                        .contentShape(Rectangle())
                }
                .contentShape(Rectangle())
                .buttonStyle(LiquidButtonPressStyle())
                .background(chipBackground(isFirst: false, isLast: true))
                .fixedSize()
            }
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private func chipBackground(isFirst: Bool, isLast: Bool) -> some View {
        chipSurface(shape: UnevenRoundedRectangle(
            topLeadingRadius:    isFirst ? 300 : 0,
            bottomLeadingRadius: isFirst ? 300 : 0,
            bottomTrailingRadius: isLast ? 300 : 0,
            topTrailingRadius:    isLast ? 300 : 0,
            style: .continuous
        ))
    }

    @ViewBuilder
    private func chipSurface<S: Shape>(shape: S) -> some View {
        shape.fill(.ultraThinMaterial)
            .overlay(shape.fill(Color.black.opacity(0.9)))
            .overlay(
                shape.fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.05), location: 0),
                            .init(color: Color(hex: "FF8100").opacity(0.05), location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            )
            .overlay(shape.stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}

struct StorefrontAllTabsSheet: View {
    let tabs: [StorefrontTab]
    let selectedTabID: String?
    let onSelectTab: (StorefrontTab) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(tabs) { tab in
                        Button {
                            onSelectTab(tab)
                        } label: {
                            HStack {
                                Text(tab.title)
                                    .font(.headline.weight(selectedTabID == tab.id ? .bold : .medium))
                                    .foregroundStyle(.white)
                                Spacer()
                                if selectedTabID == tab.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color(hex: "DAB316"))
                                }
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.white.opacity(0.06))
                            )
                        }
                        .buttonStyle(LiquidButtonPressStyle())
                    }
                }
                .padding(16)
            }
            .background(Color.black.ignoresSafeArea())
        }
    }
}
