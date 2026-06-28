import SwiftUI
import UIKit

// MARK: - Video Quality

struct QuickplayQualityDialog: View {
    @ObservedObject var engine: QuickplayPlayerEngine
    @Binding var isPresented: Bool

    @State private var variants: [VideoVariant] = []
    @State private var isLoading = true

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

                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .padding(.horizontal, 56)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(variants) { variant in
                                let isSelected = engine.preferredVideoMaxHeight == variant.maxHeight
                                Button {
                                    engine.setVideoQuality(variant)
                                    isPresented = false
                                } label: {
                                    HStack(spacing: 16) {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(.white)
                                            .opacity(isSelected ? 1 : 0)
                                            .frame(width: 20)
                                        Text(variant.displayName)
                                            .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                                            .foregroundStyle(isSelected ? .white : .white.opacity(0.55))
                                    }
                                    .frame(height: 48)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(LiquidButtonPressStyle())
                            }
                        }
                        .padding(.horizontal, 56)
                    }

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
        .task {
            variants = await engine.fetchVideoVariants()
            isLoading = false
        }
    }
}

// MARK: - Audio & Subtitles

#if canImport(FLPlayerInterface)
import FLPlayerInterface

private extension MediaTrack {
    var resolvedDisplayName: String {
        // If displayName looks like a real label (more than a bare code), use it
        if let name = displayName, name.count > 3, !name.allSatisfy({ $0.isLetter }) {
            return name
        }
        // Resolve from locale
        if let locale,
           let name = Locale.current.localizedString(forIdentifier: locale.identifier), !name.isEmpty {
            return name
        }
        // Resolve from isoLanguageCode
        if let code = isoLanguageCode, !code.isEmpty,
           let name = Locale.current.localizedString(forLanguageCode: code), !name.isEmpty {
            return name
        }
        return displayName ?? "Unknown"
    }
}

struct QuickplaySubtitleDialog: View {
    @ObservedObject var engine: QuickplayPlayerEngine
    @Binding var isPresented: Bool
    var contentLanguage: String? = nil

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

    // MARK: Audio

    private var audioColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            columnHeader("Audio")
            let tracks = engine.audioTracks
            if tracks.isEmpty {
                emptyNote("No audio tracks")
            } else {
                ForEach(Array(tracks.enumerated()), id: \.offset) { _, track in
                    trackRow(
                        title: audioDisplayName(for: track),
                        isSelected: engine.selectedAudioTrack() == track
                    ) {
                        engine.selectAudioTrack(track)
                    }
                }
            }
        }
    }

    private func audioDisplayName(for track: MediaTrack) -> String {
        // When the track is tagged "en" but the content has an original language,
        // use the content's language code instead (mirrors Android ACL logic).
        if let code = track.isoLanguageCode, code.lowercased() == "en",
           let acl = contentLanguage, !acl.isEmpty, acl.lowercased() != "en" {
            return Locale.current.localizedString(forLanguageCode: acl) ?? acl
        }
        return track.resolvedDisplayName
    }

    // MARK: Subtitles

    private var subtitleColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            columnHeader("Subtitles")

            trackRow(
                title: "Off",
                isSelected: engine.selectedSubtitleTrack() == nil
            ) {
                engine.selectSubtitleTrack(nil)
            }

            ForEach(Array(engine.subtitleTracks.enumerated()), id: \.offset) { _, track in
                trackRow(
                    title: track.resolvedDisplayName,
                    isSelected: engine.selectedSubtitleTrack() == track
                ) {
                    engine.selectSubtitleTrack(track)
                }
            }
        }
    }

    // MARK: Helpers

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
