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

        // NOTE: OAuth + OVAT fetch skipped — using defaultQpat from config as the platform token.
        // Uncomment below when real entitlement flow is needed:
        // let oauthToken = try await fetchOAuthToken(config: config)
        // let ovat = try await fetchOvat(oauthToken: oauthToken, config: config)

        let ovat = config.defaultQpat

        // Hardcoded device ID shared across platforms for entitlement bypass.
        // Replace with FLPlatformCoreFactory.createDevice() when using real entitlement flow.
        let device = FLPlatformCoreFactory.createDevice(id: "959ff2101e40f82c")

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
