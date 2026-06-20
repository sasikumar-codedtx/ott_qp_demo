import SwiftUI

struct ProfileSelectionView: View {
    @ObservedObject var viewModel: ProfileSelectionViewModel
    let onSelect: (Profile) -> Void
    let onAddProfile: () -> Void
    let onManageProfiles: () -> Void

    var body: some View {
        VStack(spacing: UIConstants.Spacing.xl) {
            Spacer(minLength: UIConstants.Spacing.xl)
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 82, height: 82)

            Text(AppStrings.Profile.chooseProfile)
                .font(.largeTitle.weight(.black))
                .foregroundStyle(.white)

            content

            Button(action: onManageProfiles) {
                Text(AppStrings.Profile.manageProfile)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, UIConstants.Spacing.xl)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: UIConstants.CornerRadius.md, style: .continuous)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.horizontal, UIConstants.Spacing.lg)
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
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: UIConstants.Spacing.xl) {
                ForEach(viewModel.selectionProfiles) { profile in
                    Button {
                        onSelect(profile)
                    } label: {
                        VStack(spacing: UIConstants.Spacing.md) {
                            ProfileAvatarView(imageName: profile.imageName, fallbackGlyph: profile.fallbackGlyph, size: UIConstants.Size.avatarLarge)
                            Text(profile.name)
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }

                Button(action: onAddProfile) {
                    VStack(spacing: UIConstants.Spacing.md) {
                        ZStack {
                            RoundedRectangle(cornerRadius: UIConstants.Size.avatarLarge / 4, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                                .frame(width: UIConstants.Size.avatarLarge, height: UIConstants.Size.avatarLarge)

                            Image(systemName: AppIcons.Action.plus)
                                .font(.title2.weight(.bold))
                                .foregroundStyle(.white)
                        }
                        Text(AppStrings.Profile.addProfile)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
