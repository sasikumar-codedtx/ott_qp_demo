import SwiftUI

struct PosterImageView: View {
    let url: URL?
    let size: CGSize
    let cornerRadius: CGFloat

    var body: some View {
        CachedAsyncImage(url: url) { image in
            image
                .resizable()
                .scaledToFill()
        } placeholder: {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.12), Color.white.opacity(0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .frame(width: size.width, height: size.height)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

#Preview {
    PosterImageView(url: nil, size: CGSize(width: UIConstants.Size.posterWidth, height: UIConstants.Size.posterHeight), cornerRadius: UIConstants.CornerRadius.sm)
        .background(Color.black)
}
