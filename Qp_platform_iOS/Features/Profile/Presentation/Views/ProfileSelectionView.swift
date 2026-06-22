import SwiftUI

struct ProfileSelectionView: View {
    @ObservedObject var viewModel: ProfileSelectionViewModel
    let onSelect: (Profile) -> Void
    let onAddProfile: () -> Void
    let onManageProfiles: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Image("sliceBg")
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                    .ignoresSafeArea()

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.06),
                        Color.black.opacity(0.2),
                        Color.black.opacity(0.7),
                        Color.black.opacity(0.96)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                Circle()
                    .fill(Color.white.opacity(0.09))
                    .frame(width: 590, height: 434)
                    .blur(radius: 34)
                    .offset(y: proxy.size.height * 0.39)

                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: proxy.safeAreaInsets.top + 74)

                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 94, height: 94)

                    Spacer()

                    Text(AppStrings.Profile.chooseProfile)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.bottom, 60)

                    content

                    Button(action: onManageProfiles) {
                        HStack(spacing: 6) {
                            Text(AppStrings.Profile.editProfile)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)

                            Image(systemName: "pencil")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 34)

                    Spacer()
                        .frame(height: max(proxy.safeAreaInsets.bottom, 24))
                }
                .padding(.horizontal, 16)
            }
        }
        .task {
            if viewModel.profiles.isEmpty {
                await viewModel.load()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            LoadingView()
        } else if let errorMessage = viewModel.errorMessage {
            ErrorView(title: AppStrings.Profile.yourProfiles, message: errorMessage, onRetry: {
                Task { await viewModel.load() }
            })
        } else {
            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(90), spacing: 32, alignment: .center), count: 3),
                alignment: .center,
                spacing: 32
            ) {
                ForEach(viewModel.selectionProfiles) { profile in
                    Button {
                        onSelect(profile)
                    } label: {
                        VStack(spacing: 8) {
                            ProfileAvatarView(
                                imageName: profile.imageName,
                                fallbackGlyph: profile.fallbackGlyph,
                                size: 90
                            )
                            Text(profile.name)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                        }
                        .frame(width: 90)
                    }
                    .buttonStyle(.plain)
                }

                Button(action: onAddProfile) {
                    VStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                                .frame(width: 90, height: 90)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                )

                            Image(systemName: AppIcons.Action.plus)
                                .font(.title2.weight(.bold))
                                .foregroundStyle(.white)
                        }
                        Text(AppStrings.Profile.addProfile)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 90)
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
