import SwiftUI

struct OTPView: View {
    @ObservedObject var viewModel: AuthViewModel
    let onBack: () -> Void
    let onVerify: () -> Void
    @FocusState private var isOTPFieldFocused: Bool
    @State private var autoSubmittedCode: String?

    var body: some View {
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

            guard newValue.count == viewModel.otpLength, autoSubmittedCode != newValue, !viewModel.isLoading else {
                return
            }

            autoSubmittedCode = newValue
            onVerify()
        }
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
            .fill(Color.white.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: UIConstants.CornerRadius.md, style: .continuous)
                    .stroke(borderColor(isActive: isActive, hasError: hasError), lineWidth: hasError || isActive ? 1.2 : 1)
            )
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .overlay {
                Text(digit)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(digit.isEmpty ? Color.white.opacity(0.4) : .white)
            }
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
