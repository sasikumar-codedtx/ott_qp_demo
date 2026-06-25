import SwiftUI
import Kingfisher

struct StorefrontSportsHeroView: View {
    let items: [StorefrontItem]
    let onSelectItem: (StorefrontItem) -> Void

    @State private var currentIndex: Int = 0
    @State private var dragX: CGFloat = 0
    @State private var frontOpacity: CGFloat = 1.0
    @State private var isAnimating: Bool = false

    // Leading-edge ratios — step 5% apart so all three cards are visible:
    //   card1: 10%→85%,  card2: 15%→90%,  card3: 20%→95%
    @State private var card2LeadingRatio: CGFloat = 0.10
    @State private var card3LeadingRatio: CGFloat = 0.15

    @State private var card2Brightness: CGFloat = -0.12
    @State private var card3Brightness: CGFloat = -0.22

    private let cardWidthRatio: CGFloat = 0.80
    private let frontLeading:   CGFloat = 0.05
    private let restLeading2:   CGFloat = 0.10
    private let restLeading3:   CGFloat = 0.15
    private let restBright2:    CGFloat = -0.12
    private let restBright3:    CGFloat = -0.22
    private var featuredItems: [StorefrontItem] { Array(items.prefix(8)) }
    private var count: Int { max(1, featuredItems.count) }
    private func wrap(_ i: Int) -> Int { ((i % count) + count) % count }

    var body: some View {
        VStack(spacing: 15) {
            GeometryReader { geo in
                let W         = geo.size.width
                let H         = geo.size.height
                let cardWidth = W * cardWidthRatio
                let midY      = H / 2

                // .position() is a real layout placement (not just visual like .offset),
                // so card2 and card3 peeking areas are never clipped by the ZStack.
                ZStack {
                    // Card 3 — furthest back
                    sportsCard(item: featuredItems[wrap(currentIndex + 2)], width: cardWidth)
                        .brightness(card3Brightness)
                        .position(x: W * card3LeadingRatio + cardWidth / 2, y: midY)
                        .zIndex(8)

                    // Card 2 — middle
                    sportsCard(item: featuredItems[wrap(currentIndex + 1)], width: cardWidth)
                        .brightness(card2Brightness)
                        .position(x: W * card2LeadingRatio + cardWidth / 2, y: midY)
                        .zIndex(9)

                    // Card 1 — front, follows drag
                    sportsCard(item: featuredItems[currentIndex], width: cardWidth)
                        .opacity(frontOpacity)
                        .position(x: W * frontLeading + cardWidth / 2 + dragX, y: midY)
                        .zIndex(10)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .gesture(swipeGesture(screenWidth: W))
            }
            .frame(height: StorefrontHeroMetrics.mediaHeight)

            pageIndicator
        }
        .task(id: currentIndex) {
            let urls: [URL] = (1..<6).compactMap { offset in
                featuredItems[wrap(currentIndex + offset)].imageURL(for: "0-2x3", width: 980)
            }
            ImagePrefetcher(urls: urls).start()
        }
    }

    // MARK: - Gestures

    private func swipeGesture(screenWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                guard !isAnimating else { return }
                dragX = value.translation.width
                let p = max(0.0, min(1.0, -dragX / 180.0))
                card2LeadingRatio = restLeading2 - (restLeading2 - frontLeading) * p
                card3LeadingRatio = restLeading3 - (restLeading3 - restLeading2) * p
                frontOpacity      = 1.0 - p * 0.4
                card2Brightness   = restBright2 * (1.0 - p)
                card3Brightness   = restBright3 + (restBright2 - restBright3) * p
            }
            .onEnded { value in
                guard !isAnimating else { return }
                let velocity = value.predictedEndTranslation.width
                if dragX < -10 || velocity < -80 {
                    // Any leftward drag commits — card exits in the direction it was moved
                    throwCardLeft(screenWidth: screenWidth)
                } else if dragX > 60 || velocity > 200 {
                    pullCardBack(screenWidth: screenWidth)
                } else {
                    snapBack()
                }
            }
    }

    /// Card 1 exits fully off-screen first; then cards 2 and 3 cascade left into position.
    private func throwCardLeft(screenWidth: CGFloat) {
        isAnimating = true

        // Step 1 — card exits fully off-screen (easeIn = accelerates like a throw, no deceleration)
        withAnimation(.easeIn(duration: 0.18)) {
            dragX        = -(screenWidth + screenWidth * cardWidthRatio)
            frontOpacity = 0.0
        }

        // Step 2 — once card is gone, cascade remaining cards into their new positions
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeOut(duration: 0.22)) {
                card2LeadingRatio = frontLeading
                card3LeadingRatio = restLeading2
                card2Brightness   = 0.0
                card3Brightness   = restBright2
            }
        }

        // Step 3 — swap content + reset positions (card 1 is fully invisible/off-screen)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.40) {
            var t = Transaction()
            t.disablesAnimations = true
            withTransaction(t) {
                currentIndex      = wrap(currentIndex + 1)
                dragX             = 0
                frontOpacity      = 1.0
                card2LeadingRatio = restLeading2
                card3LeadingRatio = restLeading3
                card2Brightness   = restBright2
                card3Brightness   = restBright3
            }
            isAnimating = false
        }
    }

    /// Previous card slides in from the left.
    private func pullCardBack(screenWidth: CGFloat) {
        guard count > 1 else { snapBack(); return }
        isAnimating = true

        var t = Transaction()
        t.disablesAnimations = true
        withTransaction(t) {
            currentIndex      = wrap(currentIndex - 1)
            dragX             = -(screenWidth + 180)
            frontOpacity      = 1.0
            card2LeadingRatio = restLeading2
            card3LeadingRatio = restLeading3
            card2Brightness   = restBright2
            card3Brightness   = restBright3
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            withAnimation(.easeOut(duration: 0.28)) {
                dragX = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                isAnimating = false
            }
        }
    }

    private func snapBack() {
        withAnimation(.easeOut(duration: 0.22)) {
            dragX             = 0
            frontOpacity      = 1.0
            card2LeadingRatio = restLeading2
            card3LeadingRatio = restLeading3
            card2Brightness   = restBright2
            card3Brightness   = restBright3
        }
    }

    // MARK: - Card UI

    private func sportsCard(item: StorefrontItem, width: CGFloat) -> some View {
        let height = StorefrontHeroMetrics.mediaHeight

        return ZStack(alignment: .bottom) {
            PosterImageView(
                url: item.imageURL(for: "0-2x3", width: 980),
                size: CGSize(width: width, height: height),
                cornerRadius: 20
            )

            LinearGradient(
                colors: [
                    Color.black.opacity(0.06),
                    Color.clear,
                    Color.black.opacity(0.34),
                    Color.black.opacity(0.94),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            LinearGradient(
                colors: [
                    Color.black.opacity(0.58),
                    Color.black.opacity(0.18),
                    Color.clear
                ],
                startPoint: .bottomLeading,
                endPoint: .topTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                if let rank = item.trendingRankText {
                    trendingBadge(rank)
                }

                Text(item.title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                if let meta = item.primaryMetaText.nilIfEmpty {
                    Text(meta)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.70))
                        .lineLimit(1)
                }

                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(Circle().fill(Color.black.opacity(0.26)))
                            .overlay(Circle().stroke(Color.white.opacity(0.16), lineWidth: 1))
                        Image(systemName: AppIcons.Action.plus)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 42, height: 42)

                    ZStack {
                        Circle()
                            .fill(.white)
                            .shadow(color: Color.white.opacity(0.20), radius: 14, x: 0, y: 4)
                        Image(systemName: AppIcons.Action.play)
                            .font(.system(size: 16, weight: .black))
                            .foregroundStyle(.black)
                            .offset(x: 1)
                    }
                    .frame(width: 50, height: 50)

                    Spacer()
                }
                .padding(.top, 2)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 0.8)
        )
        .shadow(color: Color.black.opacity(0.45), radius: 24, x: 0, y: 14)
    }

    private func trendingBadge(_ text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 9, weight: .bold))
            Text(text)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(Color(hex: "FBBF1B"))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule(style: .continuous)
                .fill(Color(hex: "FBBF1B").opacity(0.15))
                .overlay(Capsule().stroke(Color(hex: "FBBF1B").opacity(0.30), lineWidth: 0.8))
        )
    }

    // MARK: - Page indicator

    private var pageIndicator: some View {
        HStack(spacing: 4) {
            ForEach(featuredItems.indices, id: \.self) { i in
                Capsule(style: .continuous)
                    .fill(i == currentIndex % count ? Color.white : Color.white.opacity(0.22))
                    .frame(width: i == currentIndex % count ? 24 : 6, height: 6)
                    .animation(.spring(response: 0.28, dampingFraction: 0.72), value: currentIndex)
            }
        }
    }
}

private extension StorefrontItem {
    var trendingRankText: String? {
        let src = title + " " + (genres.first ?? "")
        guard let r = src.range(of: #"#\d+ in \w+"#, options: .regularExpression) else { return nil }
        return String(src[r])
    }
}
