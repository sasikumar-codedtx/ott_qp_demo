import SwiftUI

struct ProfileEditorView: View {
    @ObservedObject var viewModel: ProfileEditorViewModel
    let onBack: () -> Void
    let onChooseAvatar: () -> Void
    let onSave: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: UIConstants.Spacing.xl) {
                titleBar

                HStack(spacing: UIConstants.Spacing.lg) {
                    ProfileAvatarView(
                        imageName: viewModel.draft.imageName,
                        fallbackGlyph: String((viewModel.draft.name.nilIfEmpty ?? "P").prefix(1)).uppercased(),
                        size: UIConstants.Size.avatarLarge
                    )

                    Button(action: onChooseAvatar) {
                        Text(AppStrings.Profile.selectAvatar)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, UIConstants.Spacing.lg)
                            .frame(height: 42)
                            .background(
                                RoundedRectangle(cornerRadius: UIConstants.CornerRadius.md, style: .continuous)
                                    .fill(Color.white.opacity(0.1))
                            )
                    }
                    .buttonStyle(.plain)
                }

                formSection

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(Color.red.opacity(0.92))
                }

                Button(action: onSave) {
                    Text(AppStrings.Profile.saveProfile)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: UIConstants.CornerRadius.md, style: .continuous)
                                .fill(Color.white)
                        )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isLoading)
            }
            .padding(UIConstants.Spacing.lg)
        }
    }

    private var titleBar: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: AppIcons.Navigation.back)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(
                        RoundedRectangle(cornerRadius: UIConstants.CornerRadius.lg, style: .continuous)
                            .fill(Color.white.opacity(0.08))
                    )
            }
            .buttonStyle(.plain)

            Spacer()

            Text(viewModel.mode == .editExisting ? AppStrings.Profile.editProfile : AppStrings.Profile.createProfile)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)

            Spacer()
            Color.clear.frame(width: 46, height: 46)
        }
    }

    private var formSection: some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.lg) {
            labeledField(title: AppStrings.Profile.namePlaceholder) {
                TextField("", text: $viewModel.draft.name)
                    .textInputAutocapitalization(.words)
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: UIConstants.Spacing.sm) {
                Text(AppStrings.Profile.preferredContent)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.72))

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: UIConstants.Spacing.sm) {
                    ForEach(PreferredContent.allCases) { content in
                        let isSelected = viewModel.draft.preferredContent.contains(content)
                        Button {
                            if isSelected {
                                viewModel.draft.preferredContent.remove(content)
                            } else {
                                viewModel.draft.preferredContent.insert(content)
                            }
                        } label: {
                            Text(content.displayName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(isSelected ? .black : .white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 42)
                                .background(
                                    RoundedRectangle(cornerRadius: UIConstants.CornerRadius.md, style: .continuous)
                                        .fill(isSelected ? Color.white : Color.white.opacity(0.08))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Toggle(AppStrings.Profile.kidsProfile, isOn: $viewModel.draft.isKidsProfile)
                .tint(.white)
                .foregroundStyle(.white)
        }
    }

    private func labeledField(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.sm) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.72))

            content()
                .padding(.horizontal, UIConstants.Spacing.lg)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: UIConstants.CornerRadius.md, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                )
        }
    }
}
