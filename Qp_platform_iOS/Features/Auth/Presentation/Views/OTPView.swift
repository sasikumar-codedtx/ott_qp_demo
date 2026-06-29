import SwiftUI

struct OTPView: View {
    @ObservedObject var viewModel: AuthViewModel
    let onBack: () -> Void
    let onVerify: () async -> Bool
    let onContinueAfterSuccess: () async -> Void

    @FocusState private var isOTPFieldFocused: Bool
    @State private var autoSubmittedCode: String?
    @State private var isVerifying = false
    @State private var editedDigitIndex: Int?

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // ── Main content — adaptive to keyboard ─────────────────
                VStack(spacing: 0) {
                    // reserve space for the top bar
                    Color.clear.frame(height: geometry.safeAreaInsets.top + 64)

                    LogoGlowView(size: 94, glowScale: 1)
                        .padding(.top, 24)
                        .padding(.bottom, 28)

                    VStack(spacing: 46) {
                        recipientBlock

                        VStack(spacing: 10) {
                            otpInput

                            if viewModel.errorMessage != nil {
                                Text(AppStrings.Auth.invalidOTPShort)
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundStyle(Color(hex: "D40202"))
                                    .frame(maxWidth: .infinity)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .animation(.easeInOut(duration: 0.18), value: viewModel.errorMessage != nil)

                        resendRow
                    }
                    .frame(width: min(380, geometry.size.width - 44))
                    .frame(maxWidth: .infinity)

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // ── Top bar always on top ────────────────────────────────
                authTopBar(topInset: geometry.safeAreaInsets.top)

                // ── Hidden input ─────────────────────────────────────────
                hiddenOTPField

                // ── Verifying toast ──────────────────────────────────────
                if isVerifying {
                    VStack {
                        Spacer()
                        AuthLoadingToast(title: "Verifying OTP")
                            .padding(.bottom, max(geometry.safeAreaInsets.bottom + 28, 42))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                if !isVerifying { isOTPFieldFocused = false }
            }
            .task {
                try? await Task.sleep(for: .milliseconds(250))
                isOTPFieldFocused = true
            }
            .onChange(of: viewModel.otpCode) { _, newValue in
                handleOTPChange(newValue)
            }
            .allowsHitTesting(!isVerifying)
            .animation(.easeInOut(duration: 0.22), value: isVerifying)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .navigationBarBackButtonHidden(true)
    }

    private func authTopBar(topInset: CGFloat) -> some View {
        VStack {
            HStack {
                AuthNavigationBackButton(action: onBack)

                Spacer()

                Text(AppStrings.Auth.otpTitle)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Spacer()

                Color.clear
                    .frame(width: 46, height: 46)
            }
            .padding(.horizontal, 22)
            .padding(.top, topInset + 8)

            Spacer()
        }
        .ignoresSafeArea(edges: .top)
    }

    private var recipientBlock: some View {
        VStack(spacing: 12) {
            Text(AppStrings.Auth.otpSubtitle)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(Color(hex: "6D6D6D"))
                .frame(maxWidth: .infinity)

            HStack(spacing: 12) {
                Text(maskedPhoneNumber)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)

                Button(action: onBack) {
                    Image(systemName: "pencil.line")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var otpInput: some View {
        GeometryReader { proxy in
            let slotSpacing: CGFloat = 10
            let availableWidth = proxy.size.width
            let slotWidth = min(61, (availableWidth - (slotSpacing * CGFloat(max(viewModel.otpLength - 1, 0)))) / CGFloat(max(viewModel.otpLength, 1)))

            HStack(spacing: slotSpacing) {
                ForEach(Array(viewModel.otpDigits.enumerated()), id: \.offset) { index, digit in
                    otpSlot(
                        index: index,
                        digit: digit,
                        width: slotWidth,
                        isActive: isOTPFieldFocused && index == min(viewModel.otpCode.count, viewModel.otpLength - 1),
                        hasError: viewModel.errorMessage != nil
                    )
                }
            }
            .frame(width: availableWidth, height: 56)
        }
        .frame(height: 56)
        .onTapGesture {
            isOTPFieldFocused = true
        }
    }

    private func otpSlot(index: Int, digit: String, width: CGFloat, isActive: Bool, hasError: Bool) -> some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color.white.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(hasError ? Color(hex: "D40202") : Color.white.opacity(0.05), lineWidth: 1.2)
            )
            .shadow(color: Color.white.opacity(0.05), radius: 3)
            .frame(width: width, height: 56)
            .scaleEffect(editedDigitIndex == index && !digit.isEmpty ? 1.035 : 1)
            .overlay {
                Text(digit.isEmpty ? "0" : digit)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(digit.isEmpty ? Color(hex: "6D6D6D") : .white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .animation(.spring(response: 0.22, dampingFraction: 0.72), value: digit)
    }

    private var resendRow: some View {
        Group {
            if viewModel.canResend {
                Button(action: { Task { await viewModel.resendOTP() } }) {
                    Text("Resend OTP")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(hex: "3595DE"))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            } else {
                HStack(spacing: 0) {
                    Text(AppStrings.Auth.resendPrefix)
                        .foregroundStyle(Color(hex: "6D6D6D"))

                    Text(viewModel.resendTimerString)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(hex: "3595DE"))
                }
                .font(.system(size: 14, weight: .regular))
                .frame(maxWidth: .infinity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.canResend)
    }

    private var hiddenOTPField: some View {
        TextField(
            "",
            text: Binding(
                get: { viewModel.otpCode },
                set: { viewModel.updateOTPCode($0) }
            )
        )
        .keyboardType(.numberPad)
        .textContentType(.oneTimeCode)
        .focused($isOTPFieldFocused)
        .opacity(0)
        .frame(width: 1, height: 1)
        .position(x: 1, y: 1)
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

    private var maskedPhoneNumber: String {
        let digits = viewModel.phoneNumber.filter(\.isNumber)
        guard digits.count >= 4 else { return "+91 \(digits)" }
        let prefix = String(digits.prefix(2))
        let suffix = String(digits.suffix(2))
        let hidden = String(repeating: "*", count: max(digits.count - 4, 0))
        return "+91 \(prefix)\(hidden)\(suffix)"
    }

    private func handleOTPChange(_ newValue: String) {
        let changedIndex = max(newValue.count - 1, 0)
        editedDigitIndex = changedIndex

        Task {
            try? await Task.sleep(for: .milliseconds(170))
            guard editedDigitIndex == changedIndex else { return }
            editedDigitIndex = nil
        }

        if newValue.count < viewModel.otpLength {
            autoSubmittedCode = nil
            return
        }

        guard newValue.count == viewModel.otpLength, autoSubmittedCode != newValue else {
            return
        }

        autoSubmittedCode = newValue
        Task {
            await verifyIfNeeded(code: newValue)
        }
    }

    private func verifyIfNeeded(code: String) async {
        guard !isVerifying else { return }
        isOTPFieldFocused = false
        isVerifying = true

        let didVerify = await onVerify()
        isVerifying = false

        guard didVerify, autoSubmittedCode == code else {
            autoSubmittedCode = nil
            return
        }

        try? await Task.sleep(for: .milliseconds(350))
        await onContinueAfterSuccess()
    }

}

#Preview {
    OTPView(
        viewModel: AuthViewModel(
            requestOTPUseCase: RequestOTPUseCase(repository: AuthRepositoryImpl(dataSource: AuthMockDataSource())),
            verifyOTPUseCase: VerifyOTPUseCase(repository: AuthRepositoryImpl(dataSource: AuthMockDataSource()))
        ),
        onBack: {},
        onVerify: { false },
        onContinueAfterSuccess: {}
    )
    .background(AppBackgroundView(style: .auth))
}
