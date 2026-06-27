import SwiftUI
import UIKit
// MARK: - Video Quality (full-screen fade overlay)

struct QuickplayQualityDialog: View {
    @ObservedObject var engine: QuickplayPlayerEngine
    @Binding var isPresented: Bool
    @State private var selected: Quality = .auto

    enum Quality: String, CaseIterable {
        case auto     = "Auto"
        case sd       = "SD (480p)"
        case hd       = "HD (720p)"
        case fullHD   = "Full HD (1080p)"
        case ultraHD  = "4K UHD (2160p)"

        var bitrate: Double {
            switch self {
            case .auto:    return 0
            case .sd:      return 1_500_000
            case .hd:      return 4_000_000
            case .fullHD:  return 8_000_000
            case .ultraHD: return 20_000_000
            }
        }
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.regularMaterial)
                .overlay(Color.black.opacity(0.50))
                .ignoresSafeArea()

            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Video Quality")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 56)
                        .padding(.top, 16)
                        .padding(.bottom, 20)

                    VStack(spacing: 0) {
                        ForEach(Quality.allCases, id: \.self) { quality in
                            Button {
                                selected = quality
                                engine.setPreferredBitrate(quality.bitrate)
                            } label: {
                                HStack(spacing: 16) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .opacity(quality == selected ? 1 : 0)
                                        .frame(width: 20)

                                    Text(quality.rawValue)
                                        .font(.system(size: 16, weight: quality == selected ? .semibold : .regular))
                                        .foregroundStyle(quality == selected ? .white : .white.opacity(0.55))
                                }
                                .frame(height: 48)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(LiquidButtonPressStyle())
                        }
                    }
                    .padding(.horizontal, 56)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                Button { isPresented = false } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .contentShape(Rectangle())
                }
                .buttonStyle(LiquidButtonPressStyle())
                .padding(.top, 16)
                .padding(.trailing, 16)
            }
        }
    }
}

// MARK: - Audio & Subtitles

#if canImport(FLPlayerInterface)
import FLPlayerInterface

struct QuickplaySubtitleDialog: View {
    @ObservedObject var engine: QuickplayPlayerEngine
    @Binding var isPresented: Bool

    @State private var selectedSubtitle: SubtitleOption = .off

    private enum SubtitleOption { case off, english }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.regularMaterial)
                .overlay(Color.black.opacity(0.70))
                .ignoresSafeArea()

            ZStack(alignment: .topTrailing) {
                HStack(alignment: .top, spacing: 40) {
                    audioColumn.frame(maxWidth: .infinity, alignment: .leading)
                    subtitleColumn.frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 150)
                .padding(.top, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                Button { isPresented = false } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .contentShape(Rectangle())
                }
                .buttonStyle(LiquidButtonPressStyle())
                .padding(.top, 16)
                .padding(.trailing, 16)
            }
        }
    }

    private var audioColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            columnHeader("Audio")
            let tracks = engine.audioTracks
            if tracks.isEmpty {
                emptyNote("No audio tracks")
            } else {
                ForEach(Array(tracks.enumerated()), id: \.offset) { _, track in
                    trackRow(
                        title: track.displayName ?? "Audio",
                        isSelected: engine.selectedAudioTrack() == track
                    ) { engine.selectAudioTrack(track) }
                }
            }
        }
    }

    private var subtitleColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            columnHeader("Subtitles")
            trackRow(title: "Off", isSelected: selectedSubtitle == .off) {
                selectedSubtitle = .off
                engine.selectSubtitleTrack(nil)
            }
            trackRow(title: "English", isSelected: selectedSubtitle == .english) {
                selectedSubtitle = .english
                engine.selectSubtitleTrack(engine.subtitleTracks.first)
            }
        }
    }

    private func columnHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(.white)
            .padding(.bottom, 16)
    }

    private func trackRow(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .opacity(isSelected ? 1 : 0)
                    .frame(width: 20)
                Text(title)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.55))
            }
            .frame(height: 44)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(LiquidButtonPressStyle())
    }

    private func emptyNote(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14))
            .foregroundStyle(.white.opacity(0.3))
            .padding(.vertical, 12)
    }
    
}
#endif
