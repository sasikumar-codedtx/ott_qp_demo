import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: AuthViewModel
    let onBack: () -> Void
    let onContinue: () -> Void

    @FocusState private var isPhoneFocused: Bool
    @State private var submittedPhoneNumber: String?

    var body: some View {
        GeometryReader { geometry in
            let scale = min(geometry.size.width / 412, 1)

            ZStack(alignment: .top) {
                AuthFigmaTitleBar(
                    title: AppStrings.Auth.signInTitle,
                    topInset: geometry.safeAreaInsets.top,
                    showsBackButton: false,
                    onBack: onBack
                )

                LogoGlowView(size: 94, glowScale: 1)
                    .position(x: geometry.size.width / 2, y: designY(198, scale: scale))

                VStack(spacing: 46) {
                    phoneInput

                    VStack(spacing: 12) {
                        Text("Already have an account?")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(Color(hex: "6D6D6D"))
                            .frame(maxWidth: .infinity)

                        Button(action: {}) {
                            HStack(spacing: 6) {
                                Text("Sign in via Email ID or Social Media")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.white)

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 24)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(width: min(380, geometry.size.width - 44))
                .position(x: geometry.size.width / 2, y: designY(493, scale: scale))

                legalCopy
                    .frame(width: min(364, geometry.size.width - 48))
                    .position(x: geometry.size.width / 2, y: designY(811, scale: scale))

                if viewModel.isLoading {
                    VStack {
                        Spacer()
                        AuthLoadingToast(title: "Sending OTP")
                            .padding(.bottom, max(geometry.safeAreaInsets.bottom + 28, 42))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                if !viewModel.isLoading {
                    isPhoneFocused = true
                }
            }
            .task {
                try? await Task.sleep(for: .milliseconds(250))
                if !viewModel.isLoading {
                    isPhoneFocused = true
                }
            }
            .onChange(of: viewModel.phoneNumber) { _, newValue in
                guard newValue.count == 10 else {
                    submittedPhoneNumber = nil
                    return
                }

                guard submittedPhoneNumber != newValue else { return }
                submittedPhoneNumber = newValue
                isPhoneFocused = false
                onContinue()
            }
            .onChange(of: viewModel.isLoading) { _, isLoading in
                if isLoading {
                    isPhoneFocused = false
                }
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .navigationBarBackButtonHidden(true)
    }

    private var phoneInput: some View {
        HStack(spacing: 4) {
            AuthFigmaField(width: 64) {
                Text("+91")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white)
            }

            AuthFigmaField(width: nil) {
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
                .focused($isPhoneFocused)
            }
        }
        .frame(height: 56)
    }

    private var legalCopy: some View {
        Text(legalAttributedText)
            .multilineTextAlignment(.center)
            .lineSpacing(4)
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

    private func designY(_ y: CGFloat, scale: CGFloat) -> CGFloat {
        y * scale
    }
}

struct AuthFigmaTitleBar: View {
    let title: String
    let topInset: CGFloat
    var showsBackButton = true
    let onBack: () -> Void

    var body: some View {
        HStack {
            if showsBackButton {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 29.5, height: 29.5)
                        .padding(8)
                        .background(
                            UnevenRoundedRectangle(
                                topLeadingRadius: 18,
                                bottomLeadingRadius: 18,
                                bottomTrailingRadius: 8,
                                topTrailingRadius: 8,
                                style: .continuous
                            )
                            .fill(Color(hex: "CFCFCF").opacity(0.1))
                            .overlay(
                                UnevenRoundedRectangle(
                                    topLeadingRadius: 18,
                                    bottomLeadingRadius: 18,
                                    bottomTrailingRadius: 8,
                                    topTrailingRadius: 8,
                                    style: .continuous
                                )
                                .stroke(Color.white.opacity(0.1), lineWidth: 1.2)
                            )
                        )
                }
                .buttonStyle(.plain)
            } else {
                Color.clear
                    .frame(width: 46, height: 46)
            }

            Spacer()

            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer()

            Color.clear
                .frame(width: 46, height: 46)
        }
        .padding(.horizontal, 22)
        .padding(.top, max(topInset + 8, 44))
    }
}

struct AuthLoadingToast: View {
    let title: String

    var body: some View {
        HStack(spacing: 10) {
            ProgressView()
                .controlSize(.small)
                .tint(.white)

            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .background(
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(Color.black.opacity(0.42).clipShape(Capsule(style: .continuous)))
                .overlay(Capsule(style: .continuous).stroke(Color.white.opacity(0.14), lineWidth: 1))
        )
        .shadow(color: Color.black.opacity(0.32), radius: 18, x: 0, y: 10)
    }
}

struct AuthNavigationBackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 29.5, height: 29.5)
                .padding(8)
                .background(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 18,
                        bottomLeadingRadius: 18,
                        bottomTrailingRadius: 8,
                        topTrailingRadius: 8,
                        style: .continuous
                    )
                    .fill(Color(hex: "CFCFCF").opacity(0.1))
                    .overlay(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 18,
                            bottomLeadingRadius: 18,
                            bottomTrailingRadius: 8,
                            topTrailingRadius: 8,
                            style: .continuous
                        )
                        .stroke(Color.white.opacity(0.1), lineWidth: 1.2)
                    )
                )
        }
        .buttonStyle(.plain)
    }
}

struct AuthFigmaField<Content: View>: View {
    let width: CGFloat?
    let content: Content

    init(width: CGFloat?, @ViewBuilder content: () -> Content) {
        self.width = width
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .frame(height: 56)
            .frame(width: width)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1.2)
                    )
                    .shadow(color: Color.white.opacity(0.05), radius: 3)
            )
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
