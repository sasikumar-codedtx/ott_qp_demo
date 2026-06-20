import Foundation

struct AuthProfileDTO: Codable {
    let phoneNumber: String
    let otpLength: Int

    func toDomain() -> AuthSession {
        AuthSession(phoneNumber: phoneNumber, otpLength: otpLength)
    }
}
