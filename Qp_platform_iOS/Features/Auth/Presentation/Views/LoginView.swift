import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: AuthViewModel
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            titleBar
            Spacer(minLength: UIConstants.Spacing.xxl)
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 94, height: 94)

            Spacer(minLength: 84)

            VStack(spacing: UIConstants.Spacing.xl) {
                phoneInput

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

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(Color.red.opacity(0.92))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, UIConstants.Spacing.lg)

            Spacer()
        }
        .padding(.top, UIConstants.Spacing.sm)
    }

    private var titleBar: some View {
        HStack {
            Color.clear.frame(width: 46, height: 46)
            Spacer()
            Text(AppStrings.Auth.signInTitle)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
            Spacer()
            Color.clear.frame(width: 46, height: 46)
        }
        .padding(.horizontal, UIConstants.Spacing.lg)
    }

    private var phoneInput: some View {
        VStack(spacing: UIConstants.Spacing.sm) {
            HStack(spacing: UIConstants.Spacing.sm) {
                fieldShell(width: 64) {
                    Text("+91")
                        .font(.body.weight(.medium))
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
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white)
                }
            }

            Text(AppStrings.Auth.phoneHint)
                .font(.footnote)
                .foregroundStyle(Color.white.opacity(0.62))
                .frame(maxWidth: .infinity, alignment: .leading)
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
                            .stroke(Color.white.opacity(0.06), lineWidth: 1.2)
                    )
            )
    }
}

#Preview {
    LoginView(
        viewModel: AuthViewModel(
            requestOTPUseCase: RequestOTPUseCase(repository: AuthRepositoryImpl(dataSource: AuthMockDataSource())),
            verifyOTPUseCase: VerifyOTPUseCase(repository: AuthRepositoryImpl(dataSource: AuthMockDataSource()))
        ),
        onContinue: {}
    )
    .background(AppBackgroundView(style: .auth))
}
