import SwiftUI

struct SearchFieldView: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    var placeholder: String = AppStrings.Search.placeholder
    var iconName: String = AppIcons.Navigation.search
    var onSubmit: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: UIConstants.Spacing.sm) {
            Image(systemName: iconName)
                .font(.system(size: 19, weight: .regular))
                .foregroundStyle(Color.white.opacity(0.54))

            TextField(
                "",
                text: $text,
                prompt: Text(placeholder).foregroundStyle(Color.white.opacity(0.42))
            )
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
            .font(.body)
            .foregroundStyle(.white)
            .focused(isFocused)
            .submitLabel(.search)
            .onSubmit {
                onSubmit?()
            }

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: AppIcons.Action.close)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.46))
                }
                .buttonStyle(LiquidButtonPressStyle())
            }
        }
        .padding(.horizontal, UIConstants.Spacing.lg)
        .frame(height: UIConstants.Size.textFieldHeight)
        .background(
            RoundedRectangle(cornerRadius: UIConstants.CornerRadius.capsule, style: .continuous)
                .fill(Color.black.opacity(0.74))
                .overlay(
                    RoundedRectangle(cornerRadius: UIConstants.CornerRadius.capsule, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.28),
                                    Color.white.opacity(0.08)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.26), radius: 12, x: 0, y: 6)
        )
    }
}
