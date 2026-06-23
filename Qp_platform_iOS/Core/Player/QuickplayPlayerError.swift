import Foundation

enum QuickplayPlayerError: LocalizedError, Equatable {
    case sdkUnavailable
    case authFailed(String)
    case playbackFailed(String)

    var errorDescription: String? {
        switch self {
        case .sdkUnavailable:
            return "Quickplay player SDK is not installed. Run pod install and open the workspace."
        case .authFailed(let message):
            return "Auth failed: \(message)"
        case .playbackFailed(let message):
            return "Playback failed: \(message)"
        }
    }
}
