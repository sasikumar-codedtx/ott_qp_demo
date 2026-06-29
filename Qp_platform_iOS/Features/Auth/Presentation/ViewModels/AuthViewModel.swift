import Combine
import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    private static let phoneMaxDigits = 10

    @Published var phoneNumber = "" {
        didSet {
            let normalized = Self.normalizeIndianPhone(phoneNumber)
            if phoneNumber != normalized {
                phoneNumber = normalized
            }
        }
    }
    @Published var otpCode = ""
    @Published private(set) var otpLength = 6
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var resendSecondsRemaining: Int = 0

    private let requestOTPUseCase: RequestOTPUseCase
    private let verifyOTPUseCase: VerifyOTPUseCase
    private var resendTimerCancellable: AnyCancellable?

    init(requestOTPUseCase: RequestOTPUseCase, verifyOTPUseCase: VerifyOTPUseCase) {
        self.requestOTPUseCase = requestOTPUseCase
        self.verifyOTPUseCase = verifyOTPUseCase
    }

    var isPhoneValid: Bool {
        phoneNumber.count == 10 && phoneNumber.first.map { "6789".contains($0) } ?? false
    }

    var phoneValidationError: String? {
        guard phoneNumber.count > 0 else { return nil }
        if phoneNumber.count == 10 && !( phoneNumber.first.map { "6789".contains($0) } ?? false) {
            return "Mobile numbers must start with 6, 7, 8 or 9"
        }
        if phoneNumber.count < 10 {
            return "Enter a valid 10-digit mobile number"
        }
        return nil
    }

    // Strips country code (+91 / 0) and filters non-digits, returns clean 10-digit string
    static func normalizeIndianPhone(_ raw: String) -> String {
        var digits = raw.filter(\.isNumber)
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("+91") && digits.hasPrefix("91") && digits.count > phoneMaxDigits {
            digits = String(digits.dropFirst(2))
        }
        if trimmed.hasPrefix("0") && digits.hasPrefix("0") && digits.count > phoneMaxDigits {
            digits = String(digits.dropFirst())
        }
        return String(digits.prefix(phoneMaxDigits))
    }

    var canResend: Bool { resendSecondsRemaining == 0 }

    var resendTimerString: String {
        let m = resendSecondsRemaining / 60
        let s = resendSecondsRemaining % 60
        return String(format: "%02d:%02d", m, s)
    }

    var isOTPValid: Bool {
        otpCode.count == otpLength
    }

    var otpDigits: [String] {
        let digits = otpCode.map(String.init)
        let placeholders = Array(repeating: "", count: max(otpLength - digits.count, 0))
        return digits + placeholders
    }

    func updateOTPCode(_ value: String) {
        otpCode = String(value.filter(\.isNumber).prefix(otpLength))
        errorMessage = nil
    }

    func requestOTP() async -> Bool {
        guard isPhoneValid else { return false }
        isLoading = true
        errorMessage = nil

        do {
            let session = try await requestOTPUseCase.execute(phoneNumber: phoneNumber)
            otpLength = session.otpLength
            otpCode = ""
            isLoading = false
            startResendCountdown()
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }

    func resendOTP() async {
        guard canResend else { return }
        _ = await requestOTP()
    }

    private func startResendCountdown(seconds: Int = 120) {
        resendSecondsRemaining = seconds
        resendTimerCancellable?.cancel()
        resendTimerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                if self.resendSecondsRemaining > 0 {
                    self.resendSecondsRemaining -= 1
                } else {
                    self.resendTimerCancellable?.cancel()
                }
            }
    }

    func verifyOTP() async -> Bool {
        guard isOTPValid else { return false }
        isLoading = true
        errorMessage = nil

        do {
            let isVerified = try await verifyOTPUseCase.execute(phoneNumber: phoneNumber, code: otpCode)
            isLoading = false
            return isVerified
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }

    func resetOTPState() {
        otpCode = ""
        otpLength = 6
        errorMessage = nil
        resendTimerCancellable?.cancel()
        resendSecondsRemaining = 0
    }
}
