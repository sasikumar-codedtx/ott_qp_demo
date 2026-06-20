import SwiftUI

struct AvatarPickerView: View {
    @ObservedObject var viewModel: ProfileEditorViewModel
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: UIConstants.Spacing.xl) {
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
                Text(AppStrings.Profile.selectAvatar)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                Spacer()
                Color.clear.frame(width: 46, height: 46)
            }
            .padding(.horizontal, UIConstants.Spacing.lg)

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: UIConstants.Spacing.lg) {
                    ForEach(viewModel.avatarOptions) { option in
                        Button {
                            viewModel.selectAvatar(option)
                            onBack()
                        } label: {
                            VStack(spacing: UIConstants.Spacing.sm) {
                                ProfileAvatarView(imageName: option.imageName, fallbackGlyph: option.label.prefix(1).uppercased(), size: UIConstants.Size.avatarLarge)
                                Text(option.label)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(UIConstants.Spacing.lg)
            }
        }
    }
}
