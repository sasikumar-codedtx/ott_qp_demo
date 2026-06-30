import SwiftUI
import Kingfisher

struct StorefrontSportsHeroView: View {
    let items: [StorefrontItem]
    let onSelectItem: (StorefrontItem) -> Void

    @State private var position: CGFloat = 0
    @State private var dragStartPosition: CGFloat? = nil
    @State private var isDragging = false

    private let cardWidthRatio: CGFloat = 0.80
    private let frontLeading:   CGFloat = 0.05   // front card leading edge (ratio of width)
    private let peekStepRatio:  CGFloat = 0.05   // each card behind peeks this much further right

    private var featuredItems: [StorefrontItem] { Array(items.prefix(8)) }
    private var count: Int { max(1, featuredItems.count) }
    private func wrap(_ i: Int) -> Int { ((i % count) + count) % count }

    private var baseIndex: Int { Int(position.rounded()) }
    private var displayIndex: Int { wrap(baseIndex) }

    var body: some View {
        VStack(spacing: 15) {
            GeometryReader { geo in
                let W         = geo.size.width
                let H         = geo.size.height
                let cardWidth = W * cardWidthRatio
                let midY      = H / 2
                // Finger travel that advances exactly one card. Sized so the front
                // card — which tracks the finger 1:1 — fully clears the screen by the
                // time a whole step completes. A real swipe commits well before that
                // via the velocity/threshold logic in onEnded, then springs the rest.
                let step      = W * 0.92

                // .position() is a real layout placement (not just visual like .offset),
                // so the peeking areas of the cards behind are never clipped by the ZStack.
                ZStack {
                    if count <= 1 {
                        sportsCard(item: featuredItems[0], width: cardWidth)
                            .position(x: slotCenterX(0, width: W, cardWidth: cardWidth, step: step), y: midY)
                            .onTapGesture {
                                guard featuredItems[0].canOpenDetail else { return }
                                onSelectItem(featuredItems[0])
                            }
                    } else {
                        // Identity is the LOGICAL index (the item), not the slot, so the
                        // persistent cards keep their views (and Kingfisher images) across
                        // an index rebase — only the entering/leaving card is rebuilt.
                        ForEach(Array((baseIndex - 1)...(baseIndex + 3)), id: \.self) { logical in
                            let s = CGFloat(logical) - position   // continuous slot: 0 == front
                            sportsCard(item: featuredItems[wrap(logical)], width: cardWidth)
                                .brightness(slotBrightness(s))
                                .opacity(slotOpacity(s))
                                .position(x: slotCenterX(s, width: W, cardWidth: cardWidth, step: step), y: midY)
                                .zIndex(Double(-s))
                                .allowsHitTesting(abs(s) < 0.5)
                                .onTapGesture {
                                    guard !isDragging,
                                          abs(position - position.rounded()) < 0.05,
                                          featuredItems[wrap(logical)].canOpenDetail else { return }
                                    onSelectItem(featuredItems[wrap(logical)])
                                }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .gesture(swipeGesture(step: step))
            }
            .frame(height: StorefrontHeroMetrics.mediaHeight)

            pageIndicator
        }
        .task(id: displayIndex) {
            let urls: [URL] = (1..<6).compactMap { offset in
                featuredItems[wrap(displayIndex + offset)].imageURL(for: "0-2x3", width: 980)
            }
            ImagePrefetcher(urls: urls).start()
        }
    }

    // MARK: - Gesture

    private func swipeGesture(step: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                guard count > 1 else { return }
                if dragStartPosition == nil {
                    // Capture the position at touch-down. If a settle spring is still
                    // running this is its in-flight target, so a new drag simply takes
                    // over from here — no lockout, fully interruptible and reversible.
                    dragStartPosition = position
                    isDragging = true
                }
                let start = dragStartPosition ?? position
                // Drag left (negative width) advances; drag right goes back. Symmetric:
                // whichever card is arriving at the front from the left tracks the finger 1:1.
                position = start - value.translation.width / step
            }
            .onEnded { value in
                guard count > 1 else { return }
                let start = dragStartPosition ?? position
                dragStartPosition = nil
                isDragging = false

                let current   = start - value.translation.width / step
                let predicted = start - value.predictedEndTranslation.width / step
                let velocity  = predicted - current      // signed projected continuation

                // Land on an adjacent integer: a flick decides the direction, otherwise
                // settle to the nearest. Always within one step of `current`, so a card
                // is never skipped and the gesture stays fully reversible.
                let target: CGFloat
                if velocity > 0.2 {
                    target = current.rounded(.down) + 1
                } else if velocity < -0.2 {
                    target = current.rounded(.up) - 1
                } else {
                    target = current.rounded()
                }

                withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.82, blendDuration: 0.2)) {
                    position = target
                }
            }
    }

    // MARK: - Continuous slot appearance (pure functions of slot `s`; 0 == front)

    /// Horizontal centre for a card at continuous slot `s`.
    /// `s <= 0`  → front card / exiting-left / entering-from-left: moves with the
    ///             finger 1:1 (slope == step) so it is "held" while dragged.
    /// `s > 0`   → cards stacked behind, peeking subtly to the right.
    private func slotCenterX(_ s: CGFloat, width W: CGFloat, cardWidth: CGFloat, step: CGFloat) -> CGFloat {
        let frontCenter = W * frontLeading + cardWidth / 2
        if s <= 0 {
            return frontCenter + s * step
        } else {
            return frontCenter + s * (W * peekStepRatio)
        }
    }

    private func slotBrightness(_ s: CGFloat) -> CGFloat {
        if s <= 0 { return 0 }
        if s <= 1 { return -0.12 * s }
        if s <= 2 { return -0.12 - 0.10 * (s - 1) }
        return -0.22
    }

    private func slotOpacity(_ s: CGFloat) -> CGFloat {
        // Stay fully opaque (image + bottom gradient together) the whole time the
        // card is on screen; only fade the final sliver as it clears the left edge.
        // This keeps the bottom gradient at full strength throughout a swipe-back
        // slide instead of only once the card has fully arrived.
        if s <= -1    { return 0 }              // fully off the left edge
        if s < -0.75  { return (s + 1) / 0.25 } // brief fade across [-1, -0.75]
        if s <= 2     { return 1 }
        if s < 3      { return 3 - s }          // fade in/out at the back of the stack
        return 0
    }

    // MARK: - Card UI

    private func sportsCard(item: StorefrontItem, width: CGFloat) -> some View {
        let height = StorefrontHeroMetrics.mediaHeight

        return ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(hex: "1E1E1E"))

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
                    .fill(i == displayIndex ? Color.white : Color.white.opacity(0.22))
                    .frame(width: i == displayIndex ? 24 : 6, height: 6)
                    .animation(.spring(response: 0.28, dampingFraction: 0.72), value: displayIndex)
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
