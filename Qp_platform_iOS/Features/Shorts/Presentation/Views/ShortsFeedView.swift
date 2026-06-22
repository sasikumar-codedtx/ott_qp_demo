import AVFoundation
import SwiftUI
import UIKit

struct ShortsTabView: View {
    @ObservedObject var viewModel: ShortsFeedViewModel
    let profileName: String
    let onOpenHome: () -> Void
    let onOpenSearch: () -> Void
    let onOpenHot: () -> Void
    let onProfileTap: () -> Void

    private let bottomBarClearance: CGFloat = 108

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()

            if viewModel.isLoadingInitial && viewModel.visiblePosts.isEmpty {
                LoadingView()
            } else if let errorMessage = viewModel.errorMessage, viewModel.visiblePosts.isEmpty {
                ErrorView(title: "Shorts unavailable", message: errorMessage, onRetry: {
                    Task { await viewModel.reload() }
                })
            } else {
                ShortsFeedView(viewModel: viewModel, bottomBarClearance: bottomBarClearance)
            }

            BottomNavigationBar(
                selection: .shorts,
                profileImageName: ProfileArtworkResolver.imageName(forName: profileName),
                onHomeTap: onOpenHome,
                onSearchTap: onOpenSearch,
                onShortsTap: {},
                onHotTap: onOpenHot,
                onProfileTap: onProfileTap
            )
        }
    }
}

private struct ShortsFeedView: View {
    @ObservedObject var viewModel: ShortsFeedViewModel
    let bottomBarClearance: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let safeAreaInsets = proxy.safeAreaInsets
            let pageWidth = proxy.size.width + safeAreaInsets.leading + safeAreaInsets.trailing
            let pageHeight = proxy.size.height + safeAreaInsets.top + safeAreaInsets.bottom

            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.visiblePosts) { post in
                        ShortsVideoCardView(
                            post: post,
                            isActive: viewModel.currentPostID == post.id,
                            isMuted: viewModel.isMuted,
                            isLiked: viewModel.likedPostIDs.contains(post.id),
                            safeAreaInsets: safeAreaInsets,
                            bottomBarClearance: bottomBarClearance,
                            onToggleMute: viewModel.toggleMute,
                            onLike: {
                                viewModel.like(postID: post.id)
                            }
                        )
                        .frame(width: pageWidth, height: pageHeight)
                        .id(post.id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $viewModel.currentPostID)
            .frame(width: proxy.size.width, height: proxy.size.height)
            .background(Color.black)
            .ignoresSafeArea()
            .offset(x: -safeAreaInsets.leading, y: -safeAreaInsets.top)
            .task {
                await viewModel.loadInitialBatchIfNeeded()
            }
            .onChange(of: viewModel.currentPostID) { _, newValue in
                viewModel.handleVisiblePostChange(newValue)
            }
        }
        .background(Color.black)
        .ignoresSafeArea()
    }
}

private struct ShortsVideoCardView: View {
    let post: ShortsPost
    let isActive: Bool
    let isMuted: Bool
    let isLiked: Bool
    let safeAreaInsets: EdgeInsets
    let bottomBarClearance: CGFloat
    let onToggleMute: () -> Void
    let onLike: () -> Void

    @StateObject private var playback = ShortsPlaybackController()
    @State private var showHeartBurst = false
    @State private var showMuteIndicator = false
    @State private var shareItem: ShortsSharePayload?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            GeometryReader { proxy in
                ShortsLoopingPlayerView(
                    player: playback.player,
                    onSingleTap: {
                        onToggleMute()
                        ShortsHaptic.muteToggle()
                        animateMuteIndicator()
                    },
                    onDoubleTap: {
                        let willLike = !isLiked
                        onLike()

                        if willLike {
                            ShortsHaptic.like()
                            animateHeartBurst()
                        } else {
                            ShortsHaptic.secondaryAction()
                        }
                    }
                )
                .frame(width: proxy.size.width, height: proxy.size.height)
                .background(Color.black)
                .background(Color(hex: post.accentHex).opacity(0.42))
                .clipped()
                .overlay {
                    if playback.isLoading {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.2)
                    }
                }
            }
            .ignoresSafeArea()

            LinearGradient(
                colors: [.black.opacity(0.08), .clear, .black.opacity(0.84)],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)

            if showHeartBurst {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 118, height: 118)
                        .blur(radius: 6)

                    Image(systemName: "heart.fill")
                        .font(.system(size: 92, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "FF7A8F"), Color(hex: "ED2E4A")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .black.opacity(0.28), radius: 12, y: 5)
                }
                .transition(.scale(scale: 0.72).combined(with: .opacity))
                .allowsHitTesting(false)
            }

            if showMuteIndicator {
                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.title.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(18)
                    .background(.black.opacity(0.45), in: Circle())
                    .transition(.scale.combined(with: .opacity))
                    .allowsHitTesting(false)
            }

            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                HStack(alignment: .bottom, spacing: 18) {
                    VStack(alignment: .leading, spacing: 12) {
                        ShortsBrandView(lines: post.brandLines)

                        Text(post.creator)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.94))

                        Text(post.caption)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(.white.opacity(0.82))
                            .lineSpacing(4)
                            .lineLimit(3)

                        HStack(spacing: 8) {
                            ShortsPrimaryButton(title: "Watch Now", action: {
                                ShortsHaptic.primaryAction()
                            })

                            ShortsInfoButton(action: {
                                ShortsHaptic.secondaryAction()
                            })
                        }
                    }
                    .frame(maxWidth: 260, alignment: .leading)

                    Spacer(minLength: 0)

                    VStack(spacing: 22) {
                        ShortsRailActionButton(
                            symbol: isLiked ? "heart.fill" : "heart",
                            tint: isLiked ? Color(hex: "FF5B75") : .white,
                            value: post.likeCountLabel(isLiked: isLiked),
                            action: {
                                onLike()
                                ShortsHaptic.like()
                                animateHeartBurst()
                            }
                        )

                        ShortsRailActionButton(
                            symbol: "paperplane",
                            tint: .white,
                            value: post.shareCountLabel,
                            action: {
                                ShortsHaptic.secondaryAction()
                                shareItem = ShortsSharePayload(
                                    title: post.creator,
                                    caption: post.caption,
                                    url: post.videoURL
                                )
                            }
                        )

                        ShortsRailActionButton(
                            symbol: isMuted ? "speaker.slash" : "speaker.wave.2",
                            tint: .white,
                            value: nil,
                            action: {
                                onToggleMute()
                                ShortsHaptic.muteToggle()
                                animateMuteIndicator()
                            }
                        )
                    }
                    .padding(.bottom, bottomBarClearance + 8)
                }
            }
            .padding(.leading, safeAreaInsets.leading + 16)
            .padding(.trailing, safeAreaInsets.trailing + 16)
            .padding(.top, safeAreaInsets.top + 14)
            .padding(.bottom, safeAreaInsets.bottom + bottomBarClearance)
            .foregroundStyle(.white)
        }
        .contentShape(Rectangle())
        .clipped()
        .ignoresSafeArea()
        .background(Color.black)
        .sheet(item: $shareItem) { item in
            ShortsShareSheet(items: item.activityItems)
        }
        .onAppear {
            playback.prepare(remoteURL: post.videoURL)
            playback.setMuted(isMuted)
            playback.setPlaying(isActive)
        }
        .onDisappear {
            playback.setPlaying(false)
        }
        .onChange(of: isActive) { _, newValue in
            playback.setPlaying(newValue)
        }
        .onChange(of: isMuted) { _, newValue in
            playback.setMuted(newValue)
        }
    }

    private func animateHeartBurst() {
        withAnimation(.spring(response: 0.26, dampingFraction: 0.72)) {
            showHeartBurst = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
            withAnimation(.easeOut(duration: 0.18)) {
                showHeartBurst = false
            }
        }
    }

    private func animateMuteIndicator() {
        withAnimation(.spring(response: 0.22, dampingFraction: 0.78)) {
            showMuteIndicator = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            withAnimation(.easeOut(duration: 0.18)) {
                showMuteIndicator = false
            }
        }
    }
}

private enum ShortsHaptic {
    static func like() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    static func muteToggle() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred(intensity: 0.7)
    }

    static func primaryAction() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred(intensity: 0.8)
    }

    static func secondaryAction() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}

private struct ShortsBrandView: View {
    let lines: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: -2) {
            ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                Text(line)
                    .font(.system(size: 27, weight: .black, design: .rounded))
                    .tracking(-0.6)
                    .foregroundStyle(index == 0 ? .white : Color(hex: "FF5428"))
            }
        }
        .shadow(color: .black.opacity(0.26), radius: 8, y: 3)
    }
}

private struct ShortsPrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.black)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(Color.white, in: Capsule())
                .shadow(color: .white.opacity(0.12), radius: 4, y: 1)
        }
        .buttonStyle(.plain)
    }
}

private struct ShortsInfoButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "info.circle")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(Color.white.opacity(0.18), in: Circle())
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct ShortsRailActionButton: View {
    let symbol: String
    let tint: Color
    let value: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 24, weight: .regular))
                    .foregroundStyle(tint)
                    .frame(width: 28, height: 28)

                Text(value ?? "0")
                    .font(.system(size: 12, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .frame(height: 16)
                    .opacity(value == nil ? 0 : 1)
            }
            .frame(width: 60, height: 62, alignment: .top)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

private struct ShortsLoopingPlayerView: UIViewRepresentable {
    let player: AVPlayer
    let onSingleTap: () -> Void
    let onDoubleTap: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onSingleTap: onSingleTap, onDoubleTap: onDoubleTap)
    }

    func makeUIView(context: Context) -> ShortsPlayerContainerView {
        let view = ShortsPlayerContainerView()
        view.playerLayer.player = player
        view.backgroundColor = .black
        view.layer.backgroundColor = UIColor.black.cgColor
        view.playerLayer.backgroundColor = UIColor.black.cgColor
        view.configureGestures(with: context.coordinator)
        return view
    }

    func updateUIView(_ uiView: ShortsPlayerContainerView, context: Context) {
        uiView.playerLayer.player = player
        uiView.backgroundColor = .black
        uiView.layer.backgroundColor = UIColor.black.cgColor
        uiView.playerLayer.backgroundColor = UIColor.black.cgColor
        context.coordinator.onSingleTap = onSingleTap
        context.coordinator.onDoubleTap = onDoubleTap
    }

    final class Coordinator: NSObject {
        var onSingleTap: () -> Void
        var onDoubleTap: () -> Void

        init(onSingleTap: @escaping () -> Void, onDoubleTap: @escaping () -> Void) {
            self.onSingleTap = onSingleTap
            self.onDoubleTap = onDoubleTap
        }

        @objc func handleSingleTap() {
            onSingleTap()
        }

        @objc func handleDoubleTap() {
            onDoubleTap()
        }
    }
}

private final class ShortsPlayerContainerView: UIView {
    private var hasConfiguredGestures = false

    override static var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = true
        isUserInteractionEnabled = true
        backgroundColor = .black
        layer.backgroundColor = UIColor.black.cgColor
        clipsToBounds = true
        contentMode = .scaleAspectFill
        playerLayer.backgroundColor = UIColor.black.cgColor
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.masksToBounds = true
    }

    func configureGestures(with coordinator: ShortsLoopingPlayerView.Coordinator) {
        guard !hasConfiguredGestures else { return }

        let singleTap = UITapGestureRecognizer(
            target: coordinator,
            action: #selector(ShortsLoopingPlayerView.Coordinator.handleSingleTap)
        )
        singleTap.numberOfTapsRequired = 1

        let doubleTap = UITapGestureRecognizer(
            target: coordinator,
            action: #selector(ShortsLoopingPlayerView.Coordinator.handleDoubleTap)
        )
        doubleTap.numberOfTapsRequired = 2

        singleTap.require(toFail: doubleTap)

        addGestureRecognizer(singleTap)
        addGestureRecognizer(doubleTap)
        hasConfiguredGestures = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private struct ShortsSharePayload: Identifiable {
    let id = UUID()
    let title: String
    let caption: String
    let url: URL

    var activityItems: [Any] {
        ["\(title)\n\(caption)", url]
    }
}

private struct ShortsShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
