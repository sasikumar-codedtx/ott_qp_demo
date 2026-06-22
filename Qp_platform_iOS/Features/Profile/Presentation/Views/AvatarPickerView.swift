import SwiftUI

struct AvatarPickerView: View {
    @ObservedObject var viewModel: ProfileEditorViewModel
    let onBack: () -> Void
    let onContinue: () -> Void

    private let columns = Array(repeating: GridItem(.fixed(90), spacing: 16), count: 3)

    var body: some View {
        VStack(spacing: 0) {
            titleBar
                .padding(.horizontal, UIConstants.Spacing.lg)
                .padding(.bottom, 18)

            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.displayAvatarOptions) { option in
                        Button {
                            viewModel.selectAvatar(option)
                            onContinue()
                        } label: {
                            ProfileAvatarTile(
                                imageName: option.imageName,
                                isSelected: option.imageName == viewModel.draft.imageName
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, UIConstants.Spacing.xl)
                .padding(.bottom, 112)
                .padding(.top, 8)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button(action: onContinue) {
                Text(AppStrings.Profile.saveProfile)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: "151424"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: UIConstants.CornerRadius.sm, style: .continuous)
                            .fill(Color.white)
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, UIConstants.Spacing.lg)
            .padding(.top, 12)
            .padding(.bottom, 14)
            .background(Color.black.opacity(0.96))
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

            Text(AppStrings.Profile.selectAvatar)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)

            Spacer()

            Color.clear.frame(width: 46, height: 46)
        }
        .padding(.top, UIConstants.Spacing.lg)
    }
}

private struct ProfileAvatarTile: View {
    let imageName: String?
    let isSelected: Bool

    var body: some View {
        ZStack {
            ProfileAvatarView(
                imageName: imageName,
                fallbackGlyph: "P",
                size: 90
            )

            if isSelected {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white, lineWidth: 2.25)
                    .padding(1)

                Color.black.opacity(0.32)
                    .clipShape(RoundedRectangle(cornerRadius: 13.5, style: .continuous))

                Circle()
                    .fill(Color.white)
                    .frame(width: 38, height: 38)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 17, weight: .black))
                            .foregroundStyle(Color(hex: "D3147C"))
                    )
            }
        }
        .frame(width: 90, height: 90)
        .clipShape(RoundedRectangle(cornerRadius: 13.5, style: .continuous))
    }
}
