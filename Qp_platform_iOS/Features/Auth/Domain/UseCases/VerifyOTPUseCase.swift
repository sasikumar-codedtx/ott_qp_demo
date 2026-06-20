import Foundation

struct VerifyOTPUseCase {
    private let repository: AuthRepository

    init(repository: AuthRepository) {
        self.repository = repository
    }

    func execute(phoneNumber: String, code: String) async throws -> Bool {
        try await repository.verifyOTP(phoneNumber: phoneNumber, code: code)
    }
}
