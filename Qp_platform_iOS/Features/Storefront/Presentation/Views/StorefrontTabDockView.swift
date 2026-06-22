import SwiftUI

struct StorefrontTabDockView: View {
    let tabs: [StorefrontTab]
    let selectedTabID: String?
    let onSelectTab: (StorefrontTab) -> Void
    let onOpenMore: () -> Void

    private var visibleTabs: [StorefrontTab] {
        Array(tabs.prefix(4))
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
                        .font(.system(size: 12, weight: selectedTabID == tab.id ? .semibold : .regular))
                        .tracking(0.48)
                        .foregroundStyle(selectedTabID == tab.id ? Color.white : Color(hex: "F0F0F0").opacity(0.9))
                        .frame(width: 70, height: 36)
                        .background(tabBackground(isSelected: selectedTabID == tab.id, position: index))
                }
                .buttonStyle(.plain)
            }

            if showsMoreButton {
                Button(action: onOpenMore) {
                    ZStack {
                        tabBackground(isSelected: false, position: visibleTabs.count)
                        Image(systemName: "chevron.up")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 40, height: 36)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func tabBackground(isSelected: Bool, position: Int) -> some View {
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: position == 0 ? 18 : 0,
            bottomLeadingRadius: position == 0 ? 18 : 0,
            bottomTrailingRadius: position == visibleTabs.count ? 18 : 0,
            topTrailingRadius: position == visibleTabs.count ? 18 : 0,
            style: .continuous
        )

        shape
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(isSelected ? 0.08 : 0.05),
                        Color(hex: "FF8100").opacity(0.06),
                        Color.black.opacity(0.9)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
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
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .background(Color.black.ignoresSafeArea())
        }
    }
}
