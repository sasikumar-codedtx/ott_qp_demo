import Foundation

protocol AuthRepository {
    func requestOTP(for phoneNumber: String) async throws -> AuthSession
    func verifyOTP(phoneNumber: String, code: String) async throws -> Bool
}
