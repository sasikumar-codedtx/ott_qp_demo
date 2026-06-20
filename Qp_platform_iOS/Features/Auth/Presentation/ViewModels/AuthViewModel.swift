import Combine
import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var phoneNumber = ""
    @Published var otpCode = ""
    @Published private(set) var otpLength = 6
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let requestOTPUseCase: RequestOTPUseCase
    private let verifyOTPUseCase: VerifyOTPUseCase

    init(requestOTPUseCase: RequestOTPUseCase, verifyOTPUseCase: VerifyOTPUseCase) {
        self.requestOTPUseCase = requestOTPUseCase
        self.verifyOTPUseCase = verifyOTPUseCase
    }

    var isPhoneValid: Bool {
        phoneNumber.count == 10
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
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
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
    }
}
