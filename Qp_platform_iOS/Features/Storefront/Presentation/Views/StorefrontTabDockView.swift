import SwiftUI

struct StorefrontTabDockView: View {
    let tabs: [StorefrontTab]
    let selectedTabID: String?
    let onSelectTab: (StorefrontTab) -> Void
    let onOpenMore: () -> Void

    private var visibleTabs: [StorefrontTab] {
        Array(tabs.prefix(showsMoreButton ? 3 : 4))
    }

    private var showsMoreButton: Bool {
        tabs.count > 4
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(visibleTabs.enumerated()), id: \.element.id) { index, tab in
                Button {
                    onSelectTab(tab)
                } label: {
                    Text(tab.title)
                        .font(.system(size: 12, weight: .regular))
                        .tracking(0.48)
                        .foregroundStyle(Color(hex: "F0F0F0").opacity(selectedTabID == tab.id ? 1 : 0.9))
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)
                        .frame(width: 70, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(LiquidButtonPressStyle())
                .background(tabCellBackground(index: index))
            }

            if showsMoreButton {
                Button(action: onOpenMore) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                        .frame(width: 40, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(LiquidButtonPressStyle())
                .background(moreCellBackground)
            }
        }
        .padding(.horizontal, 16)
    }

    private func tabCellBackground(index: Int) -> some View {
        let isFirst = index == 0
        let isLast = !showsMoreButton && index == visibleTabs.count - 1

        return UnevenRoundedRectangle(
            topLeadingRadius: isFirst ? 300 : 0,
            bottomLeadingRadius: isFirst ? 300 : 0,
            bottomTrailingRadius: isLast ? 300 : 0,
            topTrailingRadius: isLast ? 300 : 0,
            style: .continuous
        )
        .fill(menuCellFill)
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius: isFirst ? 300 : 0,
                bottomLeadingRadius: isFirst ? 300 : 0,
                bottomTrailingRadius: isLast ? 300 : 0,
                topTrailingRadius: isLast ? 300 : 0,
                style: .continuous
            )
            .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private var moreCellBackground: some View {
        UnevenRoundedRectangle(
            topLeadingRadius: 0,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: 300,
            topTrailingRadius: 300,
            style: .continuous
        )
        .fill(menuCellFill)
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 300,
                topTrailingRadius: 300,
                style: .continuous
            )
            .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private var menuCellFill: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.05),
                Color(hex: "FF8100").opacity(0.05),
                Color.black.opacity(0.9),
                Color.black.opacity(0.9)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
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
