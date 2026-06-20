import SwiftUI

struct SectionHeaderView: View {
    let title: String

    var body: some View {
        HStack(spacing: UIConstants.Spacing.sm) {
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)

            Spacer()

            Image(systemName: AppIcons.Navigation.next)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white.opacity(0.82))
        }
    }
}

#Preview {
    SectionHeaderView(title: "Popular Search")
        .padding()
        .background(Color.black)
}
