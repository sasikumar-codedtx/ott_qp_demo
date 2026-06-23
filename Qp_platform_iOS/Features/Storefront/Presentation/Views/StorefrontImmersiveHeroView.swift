import SwiftUI

struct StorefrontImmersiveHeroView: View {
    let items: [StorefrontItem]
    let onSelectItem: (StorefrontItem) -> Void
    @State private var currentItemID: String?

    private var featuredItems: [StorefrontItem] {
        Array(items.prefix(5))
    }

    private var currentIndex: Int {
        guard
            let currentItemID,
            let index = featuredItems.firstIndex(where: { $0.id == currentItemID })
        else {
            return 0
        }
        return index
    }

    var body: some View {
        VStack(spacing: 12) {
            GeometryReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 0) {
                        ForEach(featuredItems) { item in
                            Button {
                                onSelectItem(item)
                            } label: {
                                immersiveCard(item: item, width: proxy.size.width)
                            }
                            .buttonStyle(LiquidButtonPressStyle())
                            .id(item.id)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $currentItemID, anchor: .center)
            }
            .frame(height: 552)
            .onAppear {
                if currentItemID == nil {
                    currentItemID = featuredItems.first?.id
                }
            }

            HStack(spacing: 7) {
                ForEach(featuredItems.indices, id: \.self) { index in
                    Capsule(style: .continuous)
                        .fill(index == currentIndex ? Color.white : Color.white.opacity(0.25))
                        .frame(width: index == currentIndex ? 28 : 7, height: 7)
                }
            }
        }
    }

    private func immersiveCard(item: StorefrontItem, width: CGFloat) -> some View {
        ZStack(alignment: .bottom) {
            backgroundMedia(item: item, width: width)

            posterCollage(width: width)
                .opacity(item.previewURL == nil ? 1 : 0.46)

            LinearGradient(
                colors: [
                    Color.black.opacity(0.02),
                    Color.black.opacity(0.1),
                    Color.black.opacity(0.76),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 14) {
                Text(item.title)
                    .font(.system(size: 34, weight: .black))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 30)

                Text(metaLine(for: item))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(1)

                if !item.description.isEmpty {
                    Text(item.description)
                        .font(.system(size: 15, weight: .medium))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.76))
                        .lineLimit(3)
                        .padding(.horizontal, 34)
                }

                HStack(spacing: 12) {
                    SonyGlassPrimaryButton(
                        title: item.previewURL == nil ? "More Info" : "Watch Preview",
                        systemImage: "info.circle.fill",
                        minWidth: 196,
                        height: 54
                    ) {
                        onSelectItem(item)
                    }

                    SonyGlassIconButton(
                        systemImage: AppIcons.Action.plus,
                        size: 54,
                        iconSize: 23,
                        cornerStyle: .circle,
                        action: {}
                    )
                }
            }
            .padding(.bottom, 28)

            VStack {
                HStack {
                    Text("Sony LIV")
                        .font(.system(size: 34, weight: .black))
                        .foregroundStyle(.white)

                    Spacer()

                    ProfileAvatarView(imageName: ProfileArtworkResolver.imageName(forName: "Prabhu"), fallbackGlyph: "P", size: 42)
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)

                Spacer()
            }
        }
        .frame(width: width, height: 552)
    }

    private func backgroundMedia(item: StorefrontItem, width: CGFloat) -> some View {
        Group {
            PosterImageView(
                url: item.imageURL(for: "0-16x9", width: Int(width * 3)),
                size: CGSize(width: width, height: 552),
                cornerRadius: 0
            )
        }
        .frame(width: width, height: 552)
        .overlay(Color.black.opacity(0.2))
    }

    private func posterCollage(width: CGFloat) -> some View {
        let tiles = Array(featuredItems.prefix(8).enumerated())
        let tileWidth = max(96, min(130, width * 0.3))
        let tileHeight = tileWidth * 1.45

        return ZStack {
            ForEach(tiles, id: \.element.id) { index, item in
                posterTile(item: item, size: CGSize(width: tileWidth, height: tileHeight))
                    .rotationEffect(.degrees(collageRotation(for: index)))
                    .offset(x: collageX(for: index, width: width), y: collageY(for: index))
                    .zIndex(Double(index))
            }
        }
        .frame(width: width, height: 552)
        .clipped()
    }

    private func posterTile(item: StorefrontItem, size: CGSize) -> some View {
        PosterImageView(
            url: item.imageURL(for: "0-2x3", width: 420),
            size: size,
            cornerRadius: 14
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.46), radius: 18, x: 0, y: 12)
    }

    private func collageX(for index: Int, width: CGFloat) -> CGFloat {
        let positions: [CGFloat] = [-0.42, -0.17, 0.12, 0.39, -0.32, -0.05, 0.24, 0.48]
        return width * (positions[index % positions.count])
    }

    private func collageY(for index: Int) -> CGFloat {
        let positions: [CGFloat] = [-118, -138, -118, -134, 48, 24, 48, 18]
        return positions[index % positions.count]
    }

    private func collageRotation(for index: Int) -> Double {
        let rotations: [Double] = [-8, 4, -3, 8, 5, -5, 4, -7]
        return rotations[index % rotations.count]
    }

    private func metaLine(for item: StorefrontItem) -> String {
        let genreText = item.genres.prefix(2).joined(separator: " • ")
        let parts = [item.contentType.capitalized.nilIfEmpty, genreText.nilIfEmpty, item.rating != nil ? "A" : nil].compactMap { $0 }
        return parts.joined(separator: " • ")
    }
}
