import Foundation

protocol AuthDataSourceProtocol {
    func requestOTP(for phoneNumber: String) async throws -> AuthSession
    func verifyOTP(phoneNumber: String, code: String) async throws -> Bool
}

final class AuthMockDataSource: AuthDataSourceProtocol {
    private let validCode = "121212"

    func requestOTP(for phoneNumber: String) async throws -> AuthSession {
        try await Task.sleep(for: .milliseconds(850))
        return AuthSession(phoneNumber: phoneNumber, otpLength: 6)
    }

    func verifyOTP(phoneNumber: String, code: String) async throws -> Bool {
        try await Task.sleep(for: .milliseconds(900))
        guard code == validCode else {
            throw AppError.invalidOTP
        }
        return true
    }
}
