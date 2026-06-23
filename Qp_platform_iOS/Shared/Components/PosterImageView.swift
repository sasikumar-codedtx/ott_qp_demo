import SwiftUI
import Kingfisher

struct PosterImageView: View {
    let url: URL?
    let size: CGSize
    let cornerRadius: CGFloat
    @Environment(\.displayScale) private var displayScale
    @State private var hasLoaded = false
    @State private var isVisible = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.035))
                .overlay {
                    ShimmerView()
                        .opacity(hasLoaded ? 0 : 1)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                }

            if isVisible {
                KFImage.url(url)
                    .setProcessor(
                        DownsamplingImageProcessor(
                            size: CGSize(
                                width: max(size.width * displayScale, 1),
                                height: max(size.height * displayScale, 1)
                            )
                        )
                    )
                    .scaleFactor(displayScale)
                    .loadDiskFileSynchronously()
                    .backgroundDecode()
                    .fade(duration: 0.22)
                    .cancelOnDisappear(true)
                    .onSuccess { _ in
                        hasLoaded = true
                    }
                    .onFailure { _ in
                        hasLoaded = true
                    }
                    .resizable()
                    .scaledToFill()
                    .opacity(hasLoaded ? 1 : 0.01)
                    .scaleEffect(hasLoaded ? 1 : 1.065)
                    .animation(.interpolatingSpring(stiffness: 165, damping: 18), value: hasLoaded)
            }
        }
        .frame(width: size.width, height: size.height)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .onAppear {
            isVisible = true
            if url == nil {
                hasLoaded = true
            }
        }
        .onDisappear {
            isVisible = false
        }
    }
}

#Preview {
    PosterImageView(url: nil, size: CGSize(width: UIConstants.Size.posterWidth, height: UIConstants.Size.posterHeight), cornerRadius: UIConstants.CornerRadius.sm)
        .background(Color.black)
}
