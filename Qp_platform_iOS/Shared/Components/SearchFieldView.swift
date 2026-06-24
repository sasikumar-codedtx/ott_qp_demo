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
                .fill(Color(hex: "202020"))
                .overlay(
                    RoundedRectangle(cornerRadius: UIConstants.CornerRadius.capsule, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(hex: "FF6105"),
                                    Color(hex: "D05AFF"),
                                    Color(hex: "7B2CFF")
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 2
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: UIConstants.CornerRadius.capsule, style: .continuous)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                        .blur(radius: 2)
                        .padding(2)
                )
                .shadow(color: Color(hex: "FF6105").opacity(0.18), radius: 12, x: -4, y: 0)
                .shadow(color: Color(hex: "7B2CFF").opacity(0.22), radius: 12, x: 4, y: 0)
        )
    }
}
