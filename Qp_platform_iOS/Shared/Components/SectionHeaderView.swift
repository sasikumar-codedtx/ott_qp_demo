import SwiftUI

struct SectionHeaderView: View {
    let title: String
    let onTap: (() -> Void)?

    init(title: String, onTap: (() -> Void)? = nil) {
        self.title = title
        self.onTap = onTap
    }

    var body: some View {
        Group {
            if let onTap {
                Button(action: onTap) {
                    headerContent
                }
                .buttonStyle(LiquidButtonPressStyle())
            } else {
                headerContent
            }
        }
    }

    private var headerContent: some View {
        HStack(spacing: UIConstants.Spacing.sm) {
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)

            Spacer()

            if onTap != nil {
                Image(systemName: AppIcons.Navigation.next)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.82))
            }
        }
    }
}

#Preview {
    SectionHeaderView(title: "Popular Search")
        .padding()
        .background(Color.black)
}
