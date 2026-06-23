import SwiftUI

struct QuickplayQualityDialog: View {
    @ObservedObject var engine: QuickplayPlayerEngine
    @Binding var isPresented: Bool
    @State private var selectedQuality: Quality = .auto

    enum Quality: String, CaseIterable {
        case auto = "Auto"
        case sd = "SD (480p)"
        case hd = "HD (720p)"
        case fullHD = "Full HD (1080p)"
        case ultraHD = "4K UHD (2160p)"

        var bitrate: Double {
            switch self {
            case .auto: return 0
            case .sd: return 1_500_000
            case .hd: return 4_000_000
            case .fullHD: return 8_000_000
            case .ultraHD: return 20_000_000
            }
        }
    }

    var body: some View {
        HStack {
            Spacer()
            VStack(alignment: .leading, spacing: 0) {
                Text("Video Quality")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 16)

                ForEach(Quality.allCases, id: \.self) { quality in
                    Button {
                        selectedQuality = quality
                        engine.setPreferredBitrate(quality.bitrate)
                        isPresented = false
                    } label: {
                        HStack {
                            Text(quality.rawValue)
                                .foregroundStyle(.white)
                            Spacer()
                            if quality == selectedQuality {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color(hex: "FF6D2E"))
                            }
                        }
                        .padding(.horizontal, 24)
                        .frame(height: 46)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(LiquidButtonPressStyle())
                }

                Spacer()
            }
            .frame(width: max(280, UIScreen.main.bounds.width * 0.34))
            .background(Color(hex: "0D0D0D").opacity(0.96))
        }
        .ignoresSafeArea()
    }
}

#if canImport(FLPlayerInterface)
import FLPlayerInterface

struct QuickplaySubtitleDialog: View {
    @ObservedObject var engine: QuickplayPlayerEngine
    @Binding var isPresented: Bool

    var body: some View {
        HStack {
            Spacer()
            VStack(alignment: .leading, spacing: 0) {
                Text("Audio & Subtitles")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 16)

                let audioTracks = engine.audioTracks
                if audioTracks.isEmpty == false {
                    sectionHeader("Audio")
                    ForEach(Array(audioTracks.enumerated()), id: \.offset) { _, track in
                        trackButton(
                            title: track.displayName ?? "Audio",
                            isSelected: engine.selectedAudioTrack() == track
                        ) {
                            engine.selectAudioTrack(track)
                        }
                    }
                }

                sectionHeader("Subtitles")
                trackButton(title: "Off", isSelected: engine.selectedSubtitleTrack() == nil) {
                    engine.selectSubtitleTrack(nil)
                }

                ForEach(Array(engine.subtitleTracks.enumerated()), id: \.offset) { _, track in
                    trackButton(
                        title: track.displayName ?? "Subtitle",
                        isSelected: engine.selectedSubtitleTrack() == track
                    ) {
                        engine.selectSubtitleTrack(track)
                    }
                }

                Spacer()
            }
            .frame(width: max(300, UIScreen.main.bounds.width * 0.55))
            .background(Color(hex: "0D0D0D").opacity(0.96))
        }
        .ignoresSafeArea()
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(Color.white.opacity(0.48))
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 4)
    }

    private func trackButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundStyle(.white)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color(hex: "FF6D2E"))
                }
            }
            .padding(.horizontal, 24)
            .frame(height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(LiquidButtonPressStyle())
    }
}
#endif
