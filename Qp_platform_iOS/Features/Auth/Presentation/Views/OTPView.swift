import SwiftUI

struct OTPView: View {
    @ObservedObject var viewModel: AuthViewModel
    let onBack: () -> Void
    let onVerify: () async -> Bool
    let onContinueAfterSuccess: () async -> Void

    @FocusState private var isOTPFieldFocused: Bool
    @State private var autoSubmittedCode: String?
    @State private var isVerifying = false
    @State private var showsSuccessOverlay = false

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                titleBar

                Spacer(minLength: 28)

                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 94, height: 94)

                Spacer(minLength: 54)

                VStack(spacing: 12) {
                    Text(AppStrings.Auth.otpSubtitle)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(Color.white.opacity(0.42))

                    phoneRow
                }

                Spacer(minLength: 42)

                otpInput
                    .padding(.horizontal, UIConstants.Spacing.lg)

                if viewModel.errorMessage != nil {
                    Text(AppStrings.Auth.invalidOTPShort)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(Color(hex: "D40202"))
                        .padding(.top, 10)
                } else {
                    Spacer()
                        .frame(height: 34)
                }

                HStack(spacing: 0) {
                    Text(AppStrings.Auth.resendPrefix)
                        .foregroundStyle(Color.white.opacity(0.38))
                    Text(AppStrings.Auth.resendTimer)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(hex: "3595DE"))
                }
                .font(.system(size: 14, weight: .regular))

                Spacer(minLength: 28)

                legalCopy
                    .padding(.horizontal, 24)

                Spacer()
            }
            .padding(.top, UIConstants.Spacing.sm)
            .contentShape(Rectangle())
            .onTapGesture {
                isOTPFieldFocused = true
            }
            .task {
                isOTPFieldFocused = true
            }
            .onChange(of: viewModel.otpCode) { _, newValue in
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
            .allowsHitTesting(!showsSuccessOverlay)

            if showsSuccessOverlay {
                Color.black.opacity(0.82)
                    .ignoresSafeArea()

                successOverlay
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.28), value: showsSuccessOverlay)
    }

    private var titleBar: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: AppIcons.Navigation.back)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(
                        RoundedRectangle(cornerRadius: UIConstants.CornerRadius.lg, style: .continuous)
                            .fill(Color.white.opacity(0.08))
                    )
            }
            .buttonStyle(.plain)

            Spacer()

            Text(AppStrings.Auth.otpTitle)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)

            Spacer()

            Color.clear.frame(width: 46, height: 46)
        }
        .padding(.horizontal, UIConstants.Spacing.lg)
    }

    private var phoneRow: some View {
        HStack(spacing: 10) {
            Text(maskedPhoneNumber)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)

            Button(action: onBack) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.88))
            }
            .buttonStyle(.plain)
        }
    }

    private var otpInput: some View {
        ZStack {
            TextField(
                "",
                text: Binding(
                    get: { viewModel.otpCode },
                    set: { viewModel.updateOTPCode($0) }
                ),
                prompt: Text(AppStrings.Auth.otpPlaceholder).foregroundStyle(.clear)
            )
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .focused($isOTPFieldFocused)
            .opacity(0.015)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack(spacing: 10) {
                ForEach(Array(viewModel.otpDigits.enumerated()), id: \.offset) { index, digit in
                    otpSlot(
                        digit: digit,
                        isActive: isOTPFieldFocused && index == min(viewModel.otpCode.count, viewModel.otpLength - 1),
                        hasError: viewModel.errorMessage != nil
                    )
                }
            }
        }
        .frame(height: 64)
        .onTapGesture {
            isOTPFieldFocused = true
        }
    }

    private func otpSlot(digit: String, isActive: Bool, hasError: Bool) -> some View {
        RoundedRectangle(cornerRadius: UIConstants.CornerRadius.md, style: .continuous)
            .fill(Color.white.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: UIConstants.CornerRadius.md, style: .continuous)
                    .stroke(borderColor(isActive: isActive, hasError: hasError), lineWidth: hasError || isActive ? 1.2 : 1)
            )
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .overlay {
                Text(verbatim: digit.isEmpty ? "" : "*")
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(digit.isEmpty ? 0 : 0.96))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
    }

    private var legalCopy: some View {
        Text(legalAttributedText)
            .multilineTextAlignment(.center)
            .lineSpacing(4)
    }

    private var successOverlay: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "06350E"), Color(hex: "0A0A0F"), Color(hex: "070708")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay {
                        Circle()
                            .fill(Color.green.opacity(0.12))
                            .frame(width: 320, height: 320)
                            .blur(radius: 12)
                            .offset(y: -22)
                    }

                Button(action: {}) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.72))
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                }
                .buttonStyle(.plain)
                .padding(.top, 10)
                .padding(.trailing, 12)
                .allowsHitTesting(false)

                VStack(spacing: 14) {
                    Image(systemName: "checkmark.seal")
                        .font(.system(size: 62, weight: .medium))
                        .foregroundStyle(Color.green)
                        .padding(.top, 30)

                    Text(AppStrings.Auth.signedInTitle)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)

                    Text("demoquickplay@gmail.com | \(maskedPhoneNumber)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: "FFC100"))
                        .multilineTextAlignment(.center)

                    HStack(spacing: 8) {
                        Image(systemName: AppIcons.Action.crown)
                            .font(.system(size: 14, weight: .bold))
                        Text(AppStrings.Auth.subscriptionActive)
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundStyle(Color(hex: "3F1F00"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(hex: "F5B919"))
                    )
                    .padding(.horizontal, 84)
                    .padding(.top, 18)

                    Text(AppStrings.Auth.subscriptionStatus)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(.white.opacity(0.86))
                        .padding(.bottom, 30)
                }
                .padding(.horizontal, 24)
            }
            .frame(height: 322)
            .padding(.horizontal, 6)
        }
        .ignoresSafeArea()
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

    private func verifyIfNeeded(code: String) async {
        guard !isVerifying, !showsSuccessOverlay else { return }
        isVerifying = true

        let didVerify = await onVerify()
        isVerifying = false

        guard didVerify, autoSubmittedCode == code else {
            autoSubmittedCode = nil
            return
        }

        isOTPFieldFocused = false
        showsSuccessOverlay = true

        try? await Task.sleep(for: .seconds(1.65))
        guard showsSuccessOverlay else { return }
        await onContinueAfterSuccess()
    }

    private func borderColor(isActive: Bool, hasError: Bool) -> Color {
        if hasError {
            return Color(hex: "D40202")
        }

        if isActive {
            return Color.white.opacity(0.72)
        }

        return Color.white.opacity(0.06)
    }
}
