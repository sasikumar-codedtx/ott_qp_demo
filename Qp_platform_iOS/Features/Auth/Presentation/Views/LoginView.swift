import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: AuthViewModel
    let onBack: () -> Void
    let onContinue: () -> Void

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                titleBar(topInset: geometry.safeAreaInsets.top)

                Spacer(minLength: 36)

                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 94, height: 94)

                Spacer()

                VStack(spacing: 30) {
                    VStack(spacing: 16) {
                        phoneInput

                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(Color.red.opacity(0.92))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button(action: onContinue) {
                            Text(AppStrings.Auth.continueLabel)
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: UIConstants.CornerRadius.md, style: .continuous)
                                        .fill(viewModel.isPhoneValid ? Color.white : Color.white.opacity(0.35))
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(!viewModel.isPhoneValid || viewModel.isLoading)
                    }

                    VStack(spacing: 12) {
                        Text("Already have an account?")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(Color(hex: "6D6D6D"))

                        Button(action: {}) {
                            HStack(spacing: 6) {
                                Text("Sign in via Email ID or Social Media")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.white)

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                    }

                    Text(legalAttributedText)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .frame(maxWidth: 364)
                }
                .frame(maxWidth: 380)
                .padding(.horizontal, UIConstants.Spacing.lg)
                .padding(.bottom, max(geometry.safeAreaInsets.bottom + 34, 67))
            }
        }
    }

    private func titleBar(topInset: CGFloat) -> some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: AppIcons.Navigation.back)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(
                        UnevenRoundedRectangle(
                            cornerRadii: .init(
                                topLeading: 8,
                                bottomLeading: 8,
                                bottomTrailing: 18,
                                topTrailing: 18
                            ),
                            style: .continuous
                        )
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            UnevenRoundedRectangle(
                                cornerRadii: .init(
                                    topLeading: 8,
                                    bottomLeading: 8,
                                    bottomTrailing: 18,
                                    topTrailing: 18
                                ),
                                style: .continuous
                            )
                            .stroke(Color.white.opacity(0.1), lineWidth: 1.2)
                        )
                    )
            }
            .buttonStyle(.plain)

            Spacer()
            Text(AppStrings.Auth.signInTitle)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
            Spacer()
            Color.clear.frame(width: 46, height: 46)
        }
        .padding(.horizontal, UIConstants.Spacing.lg)
        .padding(.top, max(topInset + 2, UIConstants.Spacing.sm))
    }

    private var phoneInput: some View {
        HStack(spacing: 4) {
            fieldShell(width: 64) {
                Text("+91")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white)
            }

            fieldShell(width: nil) {
                TextField(
                    "",
                    text: Binding(
                        get: { viewModel.phoneNumber },
                        set: { viewModel.phoneNumber = String($0.filter(\.isNumber).prefix(10)) }
                    ),
                    prompt: Text(AppStrings.Auth.phonePlaceholder).foregroundStyle(Color.white.opacity(0.5))
                )
                .keyboardType(.numberPad)
                .textContentType(.telephoneNumber)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.white)
            }
        }
    }

    private func fieldShell(width: CGFloat?, @ViewBuilder content: () -> some View) -> some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, UIConstants.Spacing.lg)
            .frame(height: 56)
            .frame(width: width)
            .background(
                RoundedRectangle(cornerRadius: UIConstants.CornerRadius.sm, style: .continuous)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: UIConstants.CornerRadius.sm, style: .continuous)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1.2)
                    )
                    .shadow(color: Color.white.opacity(0.05), radius: 3, x: 0, y: 0)
            )
    }

    private var legalAttributedText: AttributedString {
        var text = AttributedString(AppStrings.Auth.legalPrefix)
        text.foregroundColor = UIColor.white.withAlphaComponent(0.38)
        text.font = .systemFont(ofSize: 14, weight: .regular)

        var terms = AttributedString(AppStrings.Auth.termsOfUse)
        terms.foregroundColor = UIColor.white.withAlphaComponent(0.78)
        terms.font = .systemFont(ofSize: 14, weight: .semibold)
        terms.underlineStyle = .single

        var andText = AttributedString(" & ")
        andText.foregroundColor = UIColor.white.withAlphaComponent(0.38)
        andText.font = .systemFont(ofSize: 14, weight: .regular)

        var privacy = AttributedString(AppStrings.Auth.privacyPolicy)
        privacy.foregroundColor = UIColor.white.withAlphaComponent(0.78)
        privacy.font = .systemFont(ofSize: 14, weight: .semibold)
        privacy.underlineStyle = .single

        text.append(terms)
        text.append(andText)
        text.append(privacy)
        return text
    }
}

#Preview {
    LoginView(
        viewModel: AuthViewModel(
            requestOTPUseCase: RequestOTPUseCase(repository: AuthRepositoryImpl(dataSource: AuthMockDataSource())),
            verifyOTPUseCase: VerifyOTPUseCase(repository: AuthRepositoryImpl(dataSource: AuthMockDataSource()))
        ),
        onBack: {},
        onContinue: {}
    )
    .background(AppBackgroundView(style: .auth))
}
