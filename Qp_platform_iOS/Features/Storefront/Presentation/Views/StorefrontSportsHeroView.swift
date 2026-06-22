import SwiftUI

struct StorefrontSportsHeroView: View {
    let items: [StorefrontItem]
    let onSelectItem: (StorefrontItem) -> Void
    @State private var currentIndex = 0

    private var featuredItems: [StorefrontItem] {
        Array(items.prefix(5))
    }

    var body: some View {
        VStack(spacing: 24) {
            TabView(selection: $currentIndex) {
                ForEach(Array(featuredItems.enumerated()), id: \.element.id) { index, item in
                    Button {
                        onSelectItem(item)
                    } label: {
                        sportsCard(item: item)
                    }
                    .buttonStyle(.plain)
                    .tag(index)
                }
            }
            .frame(height: 420)
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onAppear {
                guard !featuredItems.isEmpty else { return }
                if currentIndex >= featuredItems.count {
                    currentIndex = 0
                } else if currentIndex == 0, featuredItems.count > 1 {
                    currentIndex = Int.random(in: 0..<featuredItems.count)
                }
            }

            HStack(spacing: 4) {
                ForEach(featuredItems.indices, id: \.self) { index in
                    Capsule(style: .continuous)
                        .fill(index == currentIndex ? Color(hex: "FBBF1B") : Color.white.opacity(0.2))
                        .frame(width: index == currentIndex ? 24 : 6, height: 6)
                }
            }
        }
    }

    private func sportsCard(item: StorefrontItem) -> some View {
        let previousIndex = currentIndex == 0 ? max(featuredItems.count - 1, 0) : currentIndex - 1
        let nextIndex = min(currentIndex + 1, max(featuredItems.count - 1, 0))
        let leftItem = featuredItems[safe: previousIndex] ?? item
        let rightItem = featuredItems[safe: nextIndex] ?? item

        return ZStack {
            HStack(spacing: -178) {
                heroLayer(item: leftItem, width: 227, height: 369)
                    .offset(x: -10, y: 25)
                    .scaleEffect(0.985)
                    .opacity(0.92)

                heroLayer(item: rightItem, width: 227, height: 369)
                    .offset(x: 10, y: 25)
                    .scaleEffect(0.985)
                    .opacity(0.92)
            }
            .animation(.spring(response: 0.34, dampingFraction: 0.84), value: currentIndex)

            mainCard(item: item)
        }
        .frame(maxWidth: .infinity)
    }

    private func heroLayer(item: StorefrontItem, width: CGFloat, height: CGFloat) -> some View {
        PosterImageView(
            url: item.imageURL(for: "0-2x3", width: 720),
            size: CGSize(width: width, height: height),
            cornerRadius: 14
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(hex: "318AC5"), lineWidth: 1)
        )
    }

    private func mainCard(item: StorefrontItem) -> some View {
        ZStack(alignment: .bottomLeading) {
            PosterImageView(
                url: item.imageURL(for: "0-2x3", width: 980),
                size: CGSize(width: 349, height: 420),
                cornerRadius: 12
            )

            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.clear, Color.black.opacity(0.5), Color.black.opacity(0.82)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    liveBadge

                    Text(item.title.replacingOccurrences(of: " vs ", with: " vs "))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    Text(item.description.nilIfEmpty ?? item.primaryMetaText.nilIfEmpty ?? item.watchLabel)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    HStack(spacing: 3) {
                        Image(systemName: "soccerball")
                            .font(.system(size: 11, weight: .regular))
                        Text(item.contentType.capitalized == "Tvchannel" ? "Football" : item.contentType.capitalized)
                            .font(.system(size: 12, weight: .regular))
                    }
                    .foregroundStyle(.white.opacity(0.92))
                }

                Spacer()

                ZStack {
                    Circle()
                        .fill(Color(hex: "E8B61A"))
                    Image(systemName: AppIcons.Action.play)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 42, height: 42)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 18)
        }
        .frame(width: 349, height: 420)
        .background(Color.black.opacity(0.001))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: Color.black.opacity(0.5), radius: 4, x: 5, y: 0)
        .shadow(color: Color.black.opacity(0.5), radius: 4, x: -5, y: 0)
    }

    private var liveBadge: some View {
        HStack(spacing: 3) {
            Circle()
                .fill(Color(hex: "E42121"))
                .frame(width: 4, height: 4)
            Text("Live")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color.white.opacity(0.18))
        )
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
