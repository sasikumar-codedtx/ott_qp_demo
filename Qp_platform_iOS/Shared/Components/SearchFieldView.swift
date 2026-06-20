import SwiftUI

struct SearchFieldView: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding

    var body: some View {
        HStack(spacing: UIConstants.Spacing.sm) {
            Image(systemName: AppIcons.Navigation.search)
                .font(.system(size: 19, weight: .regular))
                .foregroundStyle(Color.white.opacity(0.54))

            TextField(
                "",
                text: $text,
                prompt: Text(AppStrings.Search.placeholder).foregroundStyle(Color.white.opacity(0.42))
            )
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
            .font(.body)
            .foregroundStyle(.white)
            .focused(isFocused)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: AppIcons.Action.close)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.46))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, UIConstants.Spacing.lg)
        .frame(height: UIConstants.Size.textFieldHeight)
        .background(
            RoundedRectangle(cornerRadius: UIConstants.CornerRadius.capsule, style: .continuous)
                .fill(Color.white.opacity(0.09))
                .overlay(
                    RoundedRectangle(cornerRadius: UIConstants.CornerRadius.capsule, style: .continuous)
                        .stroke(Color.white.opacity(0.07), lineWidth: 1)
                )
        )
    }
}
