import SwiftUI

struct LoadingView: View {
    var body: some View {
        VStack(spacing: UIConstants.Spacing.md) {
            ProgressView()
                .tint(.white)
            Text(AppStrings.App.loading)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.72))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    LoadingView()
        .background(Color.black)
}
