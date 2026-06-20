import Foundation

struct RequestOTPUseCase {
    private let repository: AuthRepository

    init(repository: AuthRepository) {
        self.repository = repository
    }

    func execute(phoneNumber: String) async throws -> AuthSession {
        try await repository.requestOTP(for: phoneNumber)
    }
}
