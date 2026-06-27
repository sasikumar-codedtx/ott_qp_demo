import SwiftUI
import UIKit

struct DetailInlinePlayerView: View {
    @ObservedObject var engine: QuickplayPlayerEngine
    let content: QuickplayPlaybackContent
    let posterURL: URL?
    let height: CGFloat
    @Binding var isFullscreenPresented: Bool

    var body: some View {
        ZStack {
            poster

            if !isFullscreenPresented {
                QuickplayPlayerSurfaceView(engine: engine)
                    .opacity(engine.isReady ? 1 : 0)
                    .animation(.easeInOut(duration: 0.45), value: engine.isReady)
            }

            LinearGradient(
                colors: [
                    .black.opacity(0.42),
                    .clear,
                    .black.opacity(0.62)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack {
                Spacer()
                if engine.error != nil {
                    DetailPlayerErrorToast()
                        .padding(.bottom, 64)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: engine.error != nil)

            inlineControls
        }
        .frame(height: height)
        .clipped()
        .task(id: content.id) {
            engine.release()
            await engine.load(content: content)
        }
    }

    private var poster: some View {
        PosterImageView(
            url: posterURL,
            size: CGSize(width: UIScreen.main.bounds.width, height: height),
            cornerRadius: 0
        )
    }

    private var inlineControls: some View {
        VStack {
            Spacer()
            HStack(spacing: 10) {
                PlayerChromeIconButton(
                    systemImage: engine.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                    action: engine.toggleMute
                )

                Spacer()

                PlayerChromeIconButton(systemImage: "arrow.up.left.and.arrow.down.right") {
                    isFullscreenPresented = true
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
    }
}

struct DetailFullscreenPlayerView: View {
    @ObservedObject var engine: QuickplayPlayerEngine
    let content: QuickplayPlaybackContent
    let posterURL: URL?
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            PosterImageView(
                url: posterURL,
                size: UIScreen.main.bounds.size,
                cornerRadius: 0
            )
            .opacity(engine.isReady ? 0 : 1)

            QuickplayPlayerSurfaceView(engine: engine)
                .ignoresSafeArea()
                .opacity(engine.isReady ? 1 : 0)

            fullscreenChrome

            if !engine.isReady || engine.isBuffering {
                DetailPlayerLoadingBadge()
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { lockLandscape() }
        .onDisappear { lockPortrait() }
    }

    private var fullscreenChrome: some View {
        VStack {
            HStack(spacing: 12) {
                NavigationChromeButton(icon: AppIcons.Navigation.back, action: onDismiss)

                VStack(alignment: .leading, spacing: 2) {
                    Text(content.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }

                Spacer()

                PlayerChromeIconButton(
                    systemImage: engine.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                    action: engine.toggleMute
                )
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            Spacer()
        }
        .background(alignment: .top) {
            LinearGradient(colors: [.black.opacity(0.78), .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: 120)
                .ignoresSafeArea(edges: .top)
        }
    }

    private func lockLandscape() {
        AppDelegate.orientationLock = .landscape
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            scene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape))
        }
        UIViewController.attemptRotationToDeviceOrientation()
    }

    private func lockPortrait() {
        AppDelegate.orientationLock = .portrait
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            scene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
        }
        UIViewController.attemptRotationToDeviceOrientation()
    }
}

private struct PlayerChromeIconButton: View {
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(.black.opacity(0.34), in: Circle())
                .overlay(Circle().stroke(.white.opacity(0.16), lineWidth: 1))
                .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 6)
        }
        .buttonStyle(LiquidButtonPressStyle())
    }
}

private struct DetailPlayerLoadingBadge: View {
    var body: some View {
        HStack(spacing: 8) {
            ProgressView()
                .tint(.white)
            Text("Loading video")
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .frame(height: 34)
        .background(.black.opacity(0.36), in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.14), lineWidth: 1))
    }
}

private struct DetailPlayerErrorToast: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text("Unable to load video")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .frame(height: 40)
        .background(.black.opacity(0.82), in: Capsule())
        .overlay(Capsule().stroke(.red.opacity(0.55), lineWidth: 1))
        .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)
    }
}
