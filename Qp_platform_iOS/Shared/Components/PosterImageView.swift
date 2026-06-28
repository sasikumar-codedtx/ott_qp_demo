import SwiftUI
import Kingfisher

struct PosterImageView: View {
    let url: URL?
    let size: CGSize
    let cornerRadius: CGFloat
    var contentMode: SwiftUI.ContentMode = .fill
    @Environment(\.displayScale) private var displayScale
    @State private var hasLoaded = false
    @State private var hasFailed = false

    private var scaledSize: CGSize {
        CGSize(
            width: max(size.width * displayScale, 1),
            height: max(size.height * displayScale, 1)
        )
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(hasFailed ? Color(hex: "181818") : Color.white.opacity(0.035))
                .overlay {
                    ShimmerView()
                        .opacity(hasLoaded ? 0 : 1)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                }

            // LazyVStack already ensures KFImage is only created when the cell enters the
            // viewport, so the `isVisible` gate is redundant and was the source of flicker:
            // it reset to false on disappear, causing shimmer + animation to replay for
            // memory-cached images when the cell scrolled back into view.
            KFImage.url(url)
                .setProcessor(DownsamplingImageProcessor(size: scaledSize))
                .scaleFactor(displayScale)
                .loadDiskFileSynchronously()
                .backgroundDecode()
                .cancelOnDisappear(true)
                .onSuccess { _ in
                    guard !hasLoaded else { return }
                    withAnimation(.easeInOut(duration: 0.22)) { hasLoaded = true }
                }
                .onFailure { _ in
                    guard !hasFailed else { return }
                    hasFailed = true
                    hasLoaded = true
                }
                .resizable()
                .aspectRatio(contentMode: contentMode)
                .opacity(hasLoaded ? 1 : 0.001)
                .scaleEffect(hasLoaded ? 1 : 1.065)
                .animation(hasFailed ? nil : .interpolatingSpring(stiffness: 165, damping: 18), value: hasLoaded)
        }
        .frame(width: size.width, height: size.height)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .onAppear {
            guard !hasLoaded else { return }
            if url == nil { hasLoaded = true; return }
            // Synchronous memory-cache hit → skip shimmer and animation entirely.
            // This is the fix for the scroll-back flicker: the image was already in RAM
            // but @State had reset, causing the load sequence to replay from scratch.
            if let url {
                let processor = DownsamplingImageProcessor(size: scaledSize)
                if ImageCache.default.retrieveImageInMemoryCache(
                    forKey: url.absoluteString,
                    options: [.processor(processor)]
                ) != nil {
                    hasLoaded = true
                }
            }
        }
    }
}

#Preview {
    PosterImageView(url: nil, size: CGSize(width: UIConstants.Size.posterWidth, height: UIConstants.Size.posterHeight), cornerRadius: UIConstants.CornerRadius.sm)
        .background(Color.black)
}
