import SwiftUI

struct ErrorView: View {
    let title: String
    let message: String
    let onRetry: (() -> Void)?

    var body: some View {
        VStack(spacing: UIConstants.Spacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40, weight: .medium))
                .foregroundStyle(.white.opacity(0.78))

            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.68))
                .multilineTextAlignment(.center)

            if let onRetry {
                Button(AppStrings.Common.tryAgain, action: onRetry)
                    .buttonStyle(.borderedProminent)
                    .tint(.white)
            }
        }
        .padding(UIConstants.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ErrorView(title: "Error", message: "Something went wrong", onRetry: {})
        .background(Color.black)
}
