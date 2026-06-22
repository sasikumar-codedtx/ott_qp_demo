import SwiftUI
import Kingfisher

struct PosterImageView: View {
    let url: URL?
    let size: CGSize
    let cornerRadius: CGFloat
    @Environment(\.displayScale) private var displayScale
    @State private var hasLoaded = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay {
                    ShimmerView()
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                }

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
                .fade(duration: 0.18)
                .cancelOnDisappear(false)
                .onSuccess { _ in
                    hasLoaded = true
                }
                .onFailure { _ in
                    hasLoaded = true
                }
                .resizable()
                .scaledToFill()
                .opacity(hasLoaded ? 1 : 0.01)
                .scaleEffect(hasLoaded ? 1 : 1.035)
                .animation(.spring(response: 0.42, dampingFraction: 0.86), value: hasLoaded)
        }
        .frame(width: size.width, height: size.height)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .onAppear {
            if url == nil {
                hasLoaded = true
            }
        }
    }
}

#Preview {
    PosterImageView(url: nil, size: CGSize(width: UIConstants.Size.posterWidth, height: UIConstants.Size.posterHeight), cornerRadius: UIConstants.CornerRadius.sm)
        .background(Color.black)
}
