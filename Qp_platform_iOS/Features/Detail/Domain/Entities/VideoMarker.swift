import Foundation

struct VideoMarker: Codable, Identifiable {
    let id: String
    let timestampSeconds: Double
    let type: VideoMarkerType
    let label: String
    let playerName: String?

    enum VideoMarkerType: String, Codable {
        case four      = "four"
        case six       = "six"
        case wicket    = "wicket"
        case milestone = "milestone"
    }

    var assetName: String {
        switch type {
        case .four:      return "cue_four"
        case .six:       return "cue_six"
        case .wicket:    return "cue_wicket"
        case .milestone: return label == "100" ? "cue_hundred" : "cue_fifty"
        }
    }
}

struct VideoMarkers: Codable {
    let contentId: String
    let totalDurationSeconds: Double
    let markers: [VideoMarker]

    static func load(named filename: String) -> VideoMarkers? {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(VideoMarkers.self, from: data)
        else { return nil }
        return decoded
    }
}
