import SwiftUI

struct ProfileAvatarView: View {
    let imageName: String?
    let fallbackGlyph: String
    let size: CGFloat

    var body: some View {
        Group {
            if let imageName, !imageName.isEmpty {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: size / 4, style: .continuous)
                        .fill(Color.white.opacity(0.12))
                    Text(fallbackGlyph)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size / 4, style: .continuous))
    }
}

#Preview {
    ProfileAvatarView(imageName: nil, fallbackGlyph: "R", size: UIConstants.Size.avatarLarge)
        .background(Color.black)
}
