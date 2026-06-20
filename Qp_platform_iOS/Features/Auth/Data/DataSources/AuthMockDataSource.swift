import Foundation

protocol AuthDataSourceProtocol {
    func requestOTP(for phoneNumber: String) async throws -> AuthSession
    func verifyOTP(phoneNumber: String, code: String) async throws -> Bool
}

final class AuthMockDataSource: AuthDataSourceProtocol {
    private let invalidCode = "000000"

    func requestOTP(for phoneNumber: String) async throws -> AuthSession {
        try await Task.sleep(for: .milliseconds(250))
        return AuthSession(phoneNumber: phoneNumber, otpLength: 6)
    }

    func verifyOTP(phoneNumber: String, code: String) async throws -> Bool {
        try await Task.sleep(for: .milliseconds(200))
        guard code != invalidCode else {
            throw AppError.invalidOTP
        }
        return code.count == 6
    }
}
