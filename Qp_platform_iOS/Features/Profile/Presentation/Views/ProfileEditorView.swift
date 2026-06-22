import SwiftUI

struct ProfileEditorView: View {
    @ObservedObject var viewModel: ProfileEditorViewModel
    let onBack: () -> Void
    let onChooseAvatar: () -> Void
    let onSave: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    titleBar

                    if viewModel.step == .details {
                        detailsContent
                    } else {
                        cohortContent
                    }

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(Color.red.opacity(0.92))
                    }
                }
                .padding(.horizontal, UIConstants.Spacing.lg)
                .padding(.top, UIConstants.Spacing.lg)
                .padding(.bottom, 120)
            }

            if viewModel.isGenderPickerPresented || viewModel.isDatePickerPresented {
                Color.black.opacity(0.82)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.isGenderPickerPresented = false
                            viewModel.isDatePickerPresented = false
                        }
                    }
            }

            bottomSheetOverlay
        }
        .safeAreaInset(edge: .bottom) {
            Button(action: handlePrimaryAction) {
                Text(viewModel.callToActionTitle)
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
            .opacity(viewModel.isGenderPickerPresented || viewModel.isDatePickerPresented ? 0 : 1)
            .allowsHitTesting(!(viewModel.isGenderPickerPresented || viewModel.isDatePickerPresented))
        }
        .animation(.easeInOut(duration: 0.22), value: viewModel.step)
        .animation(.easeInOut(duration: 0.22), value: viewModel.isGenderPickerPresented)
        .animation(.easeInOut(duration: 0.22), value: viewModel.isDatePickerPresented)
    }

    private var titleBar: some View {
        HStack {
            Button(action: handleBackTap) {
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

            Text(viewModel.title)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)

            Spacer()

            Color.clear.frame(width: 46, height: 46)
        }
    }

    private var detailsContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            avatarStrip
            nameField
            dateOfBirthField
            genderField
            preferredContentField
            kidsToggleField
        }
    }

    private var avatarStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(viewModel.avatarOptions) { option in
                    Button {
                        viewModel.selectAvatar(option)
                    } label: {
                        VStack(spacing: 8) {
                            ProfileAvatarView(
                                imageName: option.imageName,
                                fallbackGlyph: option.label.prefix(1).uppercased(),
                                size: 90
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 19.2, style: .continuous)
                                    .stroke(option.imageName == viewModel.draft.imageName ? Color.white : .clear, lineWidth: 3)
                                    .padding(-8)
                            )

                            Text(option.label)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .frame(width: 90)
                    }
                    .buttonStyle(.plain)
                }

                Button(action: onChooseAvatar) {
                    VStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.white.opacity(0.04))
                            .frame(width: 106, height: 106)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(Color.white, lineWidth: 3)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 19.2, style: .continuous)
                                    .fill(Color.black.opacity(0.52))
                                    .padding(8)
                            )
                            .overlay(
                                Image(systemName: "pencil.slash")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.92))
                            )

                        Text(AppStrings.Profile.addProfile)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 4)
        }
    }

    private var nameField: some View {
        ProfileFieldShell(isTopRounded: true, isBottomRounded: false) {
            HStack(spacing: 10) {
                Image(systemName: "person")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.28))

                TextField("", text: $viewModel.draft.name, prompt: Text(AppStrings.Profile.namePlaceholder).foregroundStyle(Color.white.opacity(0.38)))
                    .textInputAutocapitalization(.words)
                    .foregroundStyle(.white)
            }
        }
    }

    private var dateOfBirthField: some View {
        Button {
            viewModel.isDatePickerPresented = true
        } label: {
            ProfileFieldShell(isTopRounded: false, isBottomRounded: false) {
                HStack(spacing: 10) {
                    Image(systemName: "calendar")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.28))

                    Text(viewModel.formattedDateOfBirth())
                        .foregroundStyle(.white)

                    Spacer()
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var genderField: some View {
        Button {
            viewModel.isGenderPickerPresented = true
        } label: {
            ProfileFieldShell(isTopRounded: false, isBottomRounded: false) {
                HStack(spacing: 10) {
                    Text(viewModel.draft.gender.map { "Gender : \($0.displayName)" } ?? AppStrings.Profile.selectGender)
                        .foregroundStyle(viewModel.draft.gender == nil ? Color.white.opacity(0.38) : .white)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var preferredContentField: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(AppStrings.Profile.preferredContent)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                Spacer()
            }
            .padding(.horizontal, UIConstants.Spacing.lg)
            .frame(height: 56)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(ProfileLanguage.allCases) { language in
                    ProfileLanguageCard(
                        language: language,
                        isSelected: viewModel.draft.preferredLanguages.contains(language)
                    ) {
                        viewModel.toggleLanguage(language)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 2)
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1.2)
                )
        )
    }

    private var kidsToggleField: some View {
        HStack {
            Text(AppStrings.Profile.kidsProfile)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)

            Spacer()

            Toggle("", isOn: $viewModel.draft.isKidsProfile)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: Color(hex: "3595DE")))
        }
        .padding(.horizontal, UIConstants.Spacing.lg)
        .frame(height: 56)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1.2)
                )
        )
    }

    private var cohortContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                ProfileAvatarView(
                    imageName: viewModel.draft.imageName,
                    fallbackGlyph: String(viewModel.draft.name.prefix(1)).uppercased(),
                    size: 66
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.draft.name.nilIfEmpty ?? "New Profile")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                    Text(AppStrings.Profile.chooseCohortSubtitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Color.white.opacity(0.56))
                }
            }
            .padding(.bottom, 6)

            VStack(spacing: 12) {
                ForEach(ProfilePreference.allCases) { preference in
                    CohortPreferenceCard(
                        preference: preference,
                        isSelected: preference == viewModel.draft.preference,
                        languages: viewModel.preferredLanguages(for: preference)
                    ) {
                        viewModel.selectPreference(preference)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text(AppStrings.Profile.cohortChipsTitle)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)

                Text(AppStrings.Profile.cohortChipsSubtitle)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.58))

                FlexibleChipLayout(items: viewModel.draft.preferredLanguages) { language in
                    Text(language.englishTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color.white.opacity(0.08))
                        )
                }
            }
            .padding(.top, 6)
        }
    }

    @ViewBuilder
    private var bottomSheetOverlay: some View {
        if viewModel.isGenderPickerPresented {
            BottomSheetContainer {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Spacer()
                        Text(AppStrings.Profile.chooseGender)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                        Spacer()

                        Button {
                            viewModel.isGenderPickerPresented = false
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white.opacity(0.82))
                                .frame(width: 24, height: 24)
                                .background(Circle().fill(Color.white.opacity(0.08)))
                        }
                        .buttonStyle(.plain)
                    }

                    VStack(spacing: 4) {
                        ForEach(Array(ProfileGender.allCases.enumerated()), id: \.element.id) { index, gender in
                            Button {
                                viewModel.selectGender(gender)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: viewModel.draft.gender == gender ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(viewModel.draft.gender == gender ? Color(hex: "4DA3FF") : .white.opacity(0.7))

                                    Text(gender.displayName)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(.white)

                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: roundedCorner(for: index, count: ProfileGender.allCases.count), style: .continuous)
                                        .fill(Color.white.opacity(0.05))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        } else if viewModel.isDatePickerPresented {
            BottomSheetContainer {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Text(AppStrings.Profile.selectDateOfBirth)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)

                        Spacer()

                        Button {
                            viewModel.isDatePickerPresented = false
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white.opacity(0.82))
                                .frame(width: 24, height: 24)
                                .background(Circle().fill(Color.white.opacity(0.08)))
                        }
                        .buttonStyle(.plain)
                    }

                    DatePicker(
                        "",
                        selection: $viewModel.draft.dateOfBirth,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .tint(Color(hex: "4DA3FF"))
                    .colorScheme(.dark)

                    Button {
                        viewModel.isDatePickerPresented = false
                    } label: {
                        Text(AppStrings.Profile.continueProfile)
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
                }
            }
        }
    }

    private func handlePrimaryAction() {
        if viewModel.isSaveStep {
            onSave()
        } else {
            _ = viewModel.advanceStepIfPossible()
        }
    }

    private func handleBackTap() {
        if viewModel.handleBack() {
            return
        }
        onBack()
    }

    private func roundedCorner(for index: Int, count: Int) -> CGFloat {
        switch index {
        case 0:
            return 16
        case count - 1:
            return 16
        default:
            return 6
        }
    }
}

private struct ProfileFieldShell<Content: View>: View {
    let isTopRounded: Bool
    let isBottomRounded: Bool
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(.horizontal, UIConstants.Spacing.lg)
            .frame(height: 56)
            .background(
                UnevenRoundedRectangle(
                    topLeadingRadius: isTopRounded ? 20 : 8,
                    bottomLeadingRadius: isBottomRounded ? 20 : 8,
                    bottomTrailingRadius: isBottomRounded ? 20 : 8,
                    topTrailingRadius: isTopRounded ? 20 : 8,
                    style: .continuous
                )
                .fill(Color.white.opacity(0.08))
                .overlay(
                    UnevenRoundedRectangle(
                        topLeadingRadius: isTopRounded ? 20 : 8,
                        bottomLeadingRadius: isBottomRounded ? 20 : 8,
                        bottomTrailingRadius: isBottomRounded ? 20 : 8,
                        topTrailingRadius: isTopRounded ? 20 : 8,
                        style: .continuous
                    )
                    .stroke(Color.white.opacity(0.05), lineWidth: 1.2)
                )
            )
    }
}

private struct ProfileLanguageCard: View {
    let language: ProfileLanguage
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(language.monogram)
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.7))

                VStack(alignment: .leading, spacing: 4) {
                    Text(language.nativeTitle)
                        .font(.system(size: 15, weight: .regular))
                    Text(language.englishTitle)
                        .font(.system(size: 15, weight: .regular))
                }
                .foregroundStyle(.white)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color(hex: "4DA3FF"))
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 74)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color(hex: "3595DE").opacity(0.16) : Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.white.opacity(isSelected ? 0.16 : 0.05), lineWidth: 1.2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

private struct CohortPreferenceCard: View {
    let preference: ProfilePreference
    let isSelected: Bool
    let languages: [ProfileLanguage]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: preference.symbolName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(isSelected ? Color(hex: "151424") : Color(hex: "F6C759"))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(preference.displayName)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                        Text(preference.subtitle)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(Color.white.opacity(0.58))
                    }

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(Color(hex: "4DA3FF"))
                    }
                }

                FlexibleChipLayout(items: languages) { language in
                    Text(language.englishTitle)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(isSelected ? Color(hex: "151424") : .white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(
                            Capsule(style: .continuous)
                                .fill(isSelected ? Color.white.opacity(0.92) : Color.white.opacity(0.08))
                        )
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: isSelected
                                ? [Color(hex: "31204E"), Color(hex: "4A1E21"), Color(hex: "8B4D12")]
                                : [Color.white.opacity(0.08), Color.white.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(isSelected ? Color(hex: "F5B919").opacity(0.7) : Color.white.opacity(0.05), lineWidth: 1.2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

private struct BottomSheetContainer<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 0) {
                content
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                    .padding(.bottom, 28)
            }
            .background(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "191919"), Color(hex: "070708")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(alignment: .top) {
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.14))
                    .frame(width: 54, height: 5)
                    .padding(.top, 10)
            }
        }
        .ignoresSafeArea()
    }
}

private struct FlexibleChipLayout<Item: Identifiable, Chip: View>: View {
    let items: [Item]
    let chip: (Item) -> Chip

    init(items: [Item], @ViewBuilder chip: @escaping (Item) -> Chip) {
        self.items = items
        self.chip = chip
    }

    var body: some View {
        ViewThatFits(in: .vertical) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 10)], alignment: .leading, spacing: 10) {
                ForEach(items) { item in
                    chip(item)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(items) { item in
                        chip(item)
                    }
                }
            }
        }
    }
}
