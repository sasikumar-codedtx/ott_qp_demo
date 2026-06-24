import Foundation
import UIKit

#if canImport(FLPlatformCore) && canImport(FLContentAuthorizer) && canImport(FLFoundation)
import FLContentAuthorizer
import FLFoundation
import FLPlatformCore

final class QuickplayAuthRegistry {
    static let shared = QuickplayAuthRegistry()

    private(set) var platformAuthorizer: (any PlatformAuthorizer)?
    private(set) var contentAuthorizer: (any ContentAuthorizer)?
    private(set) var platformClient: (any PlatformClient)?
    private(set) var isReady = false

    private init() {}

    func enroll(config: QuickplayPlayerConfig) async throws {
        if isReady { return }

        let oauthToken = try await fetchOAuthToken(config: config)
        let ovat = try await fetchOvat(oauthToken: oauthToken, config: config)
        let device = FLPlatformCoreFactory.createDevice()
        let authConfig = FLPlatformCoreFactory.authorizerConfiguration(
            clientId: config.clientId,
            clientSecret: config.clientSecret,
            xClientId: config.xClientId,
            tokenEndPoint: config.oauthEndpoint
        )

        guard let authorizer = FLPlatformCoreFactory.authorizer(
            configuration: authConfig,
            userAuthorizationDelegate: QuickplayOvatDelegate(token: ovat)
        ) else {
            throw QuickplayPlayerError.authFailed("Failed to create platform authorizer")
        }

        let contentAuthConfig = FLContentAuthorizerFactory.contentAuthorizerConfiguration(
            endPoint: config.contentAuthEndpoint,
            deviceRegistrationEndPoint: config.registrationEndpoint
        )

        let contentAuth = FLContentAuthorizerFactory.contentAuthorizer(
            configuration: contentAuthConfig,
            device: device,
            platformAuthorizer: authorizer
        )

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            authorizer.ensureAuthorization { result in
                switch result {
                case .success:
                    contentAuth.ensureDeviceRegistration { regResult in
                        switch regResult {
                        case .success:
                            continuation.resume()
                        case .failure(let error):
                            continuation.resume(throwing: QuickplayPlayerError.authFailed("Device registration failed: \(error.localizedDescription)"))
                        }
                    }
                case .failure(let error):
                    continuation.resume(throwing: QuickplayPlayerError.authFailed("Platform auth failed: \(error.localizedDescription)"))
                }
            }
        }

        platformClient = device
        platformAuthorizer = authorizer
        contentAuthorizer = contentAuth
        isReady = true
    }

    func authorizeContent(content: QuickplayPlaybackContent) async throws -> any PlaybackAsset {
        guard let contentAuthorizer else {
            throw QuickplayPlayerError.authFailed("Content authorizer is not enrolled")
        }

        let asset = FLContentAuthorizerFactory.vodPlatformAsset(
            contentId: content.contentId,
            catalogType: content.contentType.catalogType,
            mediaFormat: .hls,
            drm: .fairplay
        )

        return try await withCheckedThrowingContinuation { continuation in
            contentAuthorizer.authorizeContent(asset: asset, delivery: .streaming) { result in
                switch result {
                case .success(let playbackAsset):
                    continuation.resume(returning: playbackAsset)
                case .failure(let error):
                    continuation.resume(throwing: QuickplayPlayerError.authFailed("Content auth failed: \(error.localizedDescription)"))
                }
            }
        }
    }

    func reset() {
        platformAuthorizer?.dispose()
        platformAuthorizer = nil
        contentAuthorizer = nil
        platformClient = nil
        isReady = false
    }

    private func fetchOAuthToken(config: QuickplayPlayerConfig) async throws -> String {
        guard let url = URL(string: config.oauthEndpoint) else {
            throw QuickplayPlayerError.authFailed("Invalid OAuth endpoint")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = "grant_type=client_credentials&client_id=\(config.clientId)&client_secret=\(config.clientSecret)".data(using: .utf8)

        NetworkLogger.logRequest(request)
        let (data, response) = try await URLSession.shared.data(for: request)
        NetworkLogger.logResponse(request: request, data: data, response: response)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw QuickplayPlayerError.authFailed("OAuth token request failed")
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let token = json?["access_token"] as? String else {
            throw QuickplayPlayerError.authFailed("Missing access_token")
        }
        return token
    }

    private func fetchOvat(oauthToken: String, config: QuickplayPlayerConfig) async throws -> String {
        guard let url = URL(string: "\(config.guestFlatEndpoint)/platform/access/token") else {
            throw QuickplayPlayerError.authFailed("Invalid guest flat endpoint")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(oauthToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(config.xClientId, forHTTPHeaderField: "x-client-id")

        let deviceId = await UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        let deviceName = await UIDevice.current.name
        request.httpBody = try JSONSerialization.data(withJSONObject: ["deviceName": deviceName, "deviceId": deviceId])

        NetworkLogger.logRequest(request)
        let (data, response) = try await URLSession.shared.data(for: request)
        NetworkLogger.logResponse(request: request, data: data, response: response)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw QuickplayPlayerError.authFailed("OVAT request failed")
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let dataObject = json?["data"] as? [String: Any]
        guard let token = dataObject?["token"] as? String else {
            throw QuickplayPlayerError.authFailed("Missing OVAT token")
        }
        return token
    }
}

private final class QuickplayOvatDelegate: UserAuthorizationDelegate {
    private let token: String

    init(token: String) {
        self.token = token
    }

    func didProvideUserAuthorizationTokenRequest(
        completionHandler: @escaping (Result<UserAuthorizationData, any Error>) -> Void
    ) {
        completionHandler(.success(UserAuthorizationData(accessToken: token)))
    }
}
#endif
