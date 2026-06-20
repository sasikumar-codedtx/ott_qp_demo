import Foundation

final class AuthRepositoryImpl: AuthRepository {
    private let dataSource: AuthDataSourceProtocol

    init(dataSource: AuthDataSourceProtocol) {
        self.dataSource = dataSource
    }

    func requestOTP(for phoneNumber: String) async throws -> AuthSession {
        try await dataSource.requestOTP(for: phoneNumber)
    }

    func verifyOTP(phoneNumber: String, code: String) async throws -> Bool {
        try await dataSource.verifyOTP(phoneNumber: phoneNumber, code: code)
    }
}
