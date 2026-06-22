import SwiftUI

struct SearchFieldView: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    var placeholder: String = AppStrings.Search.placeholder
    var iconName: String = AppIcons.Navigation.search

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
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: UIConstants.CornerRadius.capsule, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(hex: "F2A23A").opacity(0.95),
                                    Color(hex: "8B45FF").opacity(0.95)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1.25
                        )
                )
        )
    }
}
