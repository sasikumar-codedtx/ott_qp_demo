import SwiftUI
import UIKit

struct ProfileEditorView: View {
    @ObservedObject var viewModel: ProfileEditorViewModel
    let onBack: () -> Void
    let onChooseAvatar: () -> Void
    let onSave: () -> Void
    let onDelete: () -> Void
    @FocusState private var isNameFieldFocused: Bool
    @State private var isDeleteAlertPresented = false

    var body: some View {
        ZStack(alignment: .top) {
            Color(hex: "0A0A0A")
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
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
                .padding(.top, 104)
                .padding(.bottom, 120)
            }
            .scrollDismissesKeyboard(.interactively)

            if viewModel.isGenderPickerPresented || viewModel.isDatePickerPresented {
                Color.black.opacity(0.82)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismissPickers()
                    }
            }

            bottomSheetOverlay

            profileEditorTopBar

            if viewModel.step == .cohortSelection {
                CohortQuestionnaireView(
                    profileName: profileDisplayName,
                    profileImageName: viewModel.draft.imageName,
                    fallbackGlyph: String(profileDisplayName.prefix(1)).uppercased()
                ) { result in
                    viewModel.applyCohortQuestionnaireResult(result)
                    onSave()
                }
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .navigationBarBackButtonHidden(true)
        .alert("Delete Profile?", isPresented: $isDeleteAlertPresented) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive, action: onDelete)
        } message: {
            Text("This profile will be removed from the device.")
        }
        .safeAreaInset(edge: .bottom) {
            Button(action: handlePrimaryAction) {
                Text(viewModel.callToActionTitle)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: "151424"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(LiquidGlassBackground(cornerRadius: UIConstants.CornerRadius.sm, tone: .light, isHighlighted: true))
            }
            .buttonStyle(LiquidButtonPressStyle())
            .padding(.horizontal, UIConstants.Spacing.lg)
            .padding(.top, 12)
            .padding(.bottom, 14)
            .background(
                LinearGradient(
                    colors: [Color.black.opacity(0), Color(hex: "0A0A0A"), Color(hex: "0A0A0A")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .opacity(viewModel.isGenderPickerPresented || viewModel.isDatePickerPresented || viewModel.step == .cohortSelection ? 0 : 1)
            .allowsHitTesting(!(viewModel.isGenderPickerPresented || viewModel.isDatePickerPresented || viewModel.step == .cohortSelection))
        }
        .animation(.easeInOut(duration: 0.22), value: viewModel.step)
        .animation(.easeInOut(duration: 0.22), value: viewModel.isGenderPickerPresented)
        .animation(.easeInOut(duration: 0.22), value: viewModel.isDatePickerPresented)
    }

    private var profileEditorTopBar: some View {
        VStack {
            HStack {
                NavigationChromeButton(icon: AppIcons.Navigation.back, action: handleBackTap)

                Spacer()

                NavigationChromeTitle(title: viewModel.title)

                Spacer()

                if viewModel.canDeleteProfile {
                    Button {
                        dismissKeyboard()
                        isDeleteAlertPresented = true
                    } label: {
                        Image("delete")
                            .resizable()
                            .renderingMode(.template)
                            .scaledToFit()
                            .foregroundStyle(.white.opacity(0.9))
                            .frame(width: 25, height: 25)
                            .frame(width: 46, height: 46)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                } else {
                    Color.clear
                        .frame(width: 46, height: 46)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .allowsHitTesting(true)
    }

    private var detailsContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            avatarStrip
                .padding(.bottom, 18)
            nameField
            dateOfBirthField
            genderField
            preferredContentField
            if viewModel.mode == .editExisting {
                storefrontPolicyField
            }
            kidsToggleField
        }
    }

    private var avatarStrip: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 24) {
                        ForEach(editorCarouselProfiles) { profile in
                            editorProfileTile(profile)
                                .id(profile.id)
                        }
                    }
                    .padding(.horizontal, max(16, (geometry.size.width - 105.6) / 2))
                    .padding(.top, 4)
                    .padding(.bottom, 12)
                }
                .onAppear {
                    centerSelectedAvatar(using: proxy)
                }
                .onChange(of: viewModel.draft.sourceID) { _, _ in
                    centerSelectedAvatar(using: proxy)
                }
            }
        }
        .frame(height: 130)
        .padding(.horizontal, -UIConstants.Spacing.lg)
        .overlay(alignment: .leading) {
            LinearGradient(colors: [Color.black.opacity(0.75), Color.clear], startPoint: .leading, endPoint: .trailing)
                .frame(width: 40)
                .frame(height: 124.328)
                .allowsHitTesting(false)
        }
        .overlay(alignment: .trailing) {
            LinearGradient(colors: [Color.clear, Color.black.opacity(0.75)], startPoint: .leading, endPoint: .trailing)
                .frame(width: 40)
                .frame(height: 124.328)
                .allowsHitTesting(false)
        }
    }

    private func centerSelectedAvatar(using proxy: ScrollViewProxy) {
        guard let selectedID = editorCarouselProfiles.first(where: { profile in
            profile.id == viewModel.draft.sourceID || (profile.imageName == viewModel.draft.imageName && viewModel.mode == .createNew)
        })?.id else { return }

        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.24)) {
                proxy.scrollTo(selectedID, anchor: .center)
            }
        }
    }

    private var editorCarouselProfiles: [Profile] {
        let temporaryProfile = Profile(
            id: viewModel.draft.sourceID ?? UUID(),
            name: profileDisplayName,
            imageName: viewModel.draft.imageName,
            cohort: viewModel.draft.isKidsProfile ? .kids : viewModel.draft.cohort,
            preference: viewModel.draft.preference,
            preferredLanguages: viewModel.draft.preferredLanguages,
            dateOfBirth: viewModel.draft.dateOfBirth,
            gender: viewModel.draft.gender,
            isKidsProfile: viewModel.draft.isKidsProfile,
            showOnSelection: true
        )

        if viewModel.mode == .editExisting {
            return viewModel.profiles
        }

        return [temporaryProfile] + Array(viewModel.profiles.prefix(4))
    }

    private func editorProfileTile(_ profile: Profile) -> some View {
        let isSelected = profile.id == viewModel.draft.sourceID || profile.imageName == viewModel.draft.imageName && viewModel.mode == .createNew

        return Button {
            if isSelected {
                handleChooseAvatar()
            } else {
                selectProfileForEditing(profile)
            }
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(Color.white, lineWidth: 3)
                            .frame(width: 105.6, height: 105.6)
                    }

                    ProfileAvatarView(
                        imageName: profile.imageName,
                        fallbackGlyph: profile.fallbackGlyph,
                        size: 89.636
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 19.208, style: .continuous))
                    .overlay {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 19.208, style: .continuous)
                                .fill(Color.black.opacity(0.5))
                        }
                    }

                    if isSelected {
                        Image(systemName: "pencil.line")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                    }
                }
                .frame(width: 105.6, height: 105.6)

                Text(profile.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .frame(width: 104)
            }
            .frame(width: 104)
        }
        .buttonStyle(LiquidButtonPressStyle())
    }

    private var profileDisplayName: String {
        viewModel.draft.name.nilIfEmpty ?? "New Profile"
    }

    private var nameField: some View {
        ProfileFieldShell(isTopRounded: true, isBottomRounded: false) {
            HStack(spacing: 10) {
                Image(systemName: "person")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.28))

                TextField("", text: $viewModel.draft.name, prompt: Text(AppStrings.Profile.namePlaceholder).foregroundStyle(Color.white.opacity(0.38)))
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .focused($isNameFieldFocused)
                    .onSubmit(dismissKeyboard)
                    .foregroundStyle(.white)
            }
        }
    }

    private var dateOfBirthField: some View {
        Button {
            presentDatePicker()
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
        .buttonStyle(LiquidButtonPressStyle())
    }

    private var genderField: some View {
        Button {
            presentGenderPicker()
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
        .buttonStyle(LiquidButtonPressStyle())
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

            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        ForEach(Array(ProfileLanguage.allCases.enumerated()).filter { $0.offset.isMultiple(of: 2) }, id: \.element.id) { _, language in
                            ProfileLanguageCard(
                                language: language,
                                isSelected: viewModel.draft.preferredLanguages.contains(language)
                            ) {
                                selectLanguage(language)
                            }
                        }
                    }

                    HStack(spacing: 10) {
                        ForEach(Array(ProfileLanguage.allCases.enumerated()).filter { !$0.offset.isMultiple(of: 2) }, id: \.element.id) { _, language in
                            ProfileLanguageCard(
                                language: language,
                                isSelected: viewModel.draft.preferredLanguages.contains(language)
                            ) {
                                selectLanguage(language)
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 2)
                .padding(.bottom, 20)
            }
        }
        .background(
            ProfilePanelBackground(cornerRadius: 8)
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
        .simultaneousGesture(TapGesture().onEnded(dismissKeyboard))
        .padding(.horizontal, UIConstants.Spacing.lg)
        .frame(height: 56)
        .background(
            ProfilePanelBackground(cornerRadius: 20)
        )
    }

    private var storefrontPolicyField: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Storefront Test Policy")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)

                Text("Choose the exact chrt value for this profile. Saving clears this profile's click data.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.5))
            }
            .padding(.horizontal, 4)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(StorefrontPolicy.allCases) { policy in
                    StorefrontPolicyCard(
                        policy: policy,
                        isSelected: viewModel.selectedStorefrontPolicy == policy
                    ) {
                        selectStorefrontPolicy(policy)
                    }
                }
            }
        }
        .padding(.horizontal, UIConstants.Spacing.lg)
        .padding(.vertical, 16)
        .background(ProfilePanelBackground(cornerRadius: 20))
    }

    private var cohortContent: some View {
        EmptyView()
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
                            dismissPickers()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white.opacity(0.82))
                                .frame(width: 24, height: 24)
                                .background(LiquidGlassCircleBackground(tone: .dark))
                        }
                        .buttonStyle(LiquidButtonPressStyle())
                    }

                    VStack(spacing: 4) {
                        ForEach(Array(ProfileGender.allCases.enumerated()), id: \.element.id) { index, gender in
                            Button {
                                dismissKeyboard()
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
                                    ProfileGenderRowBackground(
                                        cornerRadius: roundedCorner(for: index, count: ProfileGender.allCases.count),
                                        isSelected: viewModel.draft.gender == gender
                                    )
                                )
                            }
                            .buttonStyle(LiquidButtonPressStyle())
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
                            dismissPickers()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white.opacity(0.82))
                                .frame(width: 24, height: 24)
                                .background(LiquidGlassCircleBackground(tone: .dark))
                        }
                        .buttonStyle(LiquidButtonPressStyle())
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
                        dismissPickers()
                    } label: {
                        Text(AppStrings.Profile.continueProfile)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color(hex: "151424"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(LiquidGlassBackground(cornerRadius: UIConstants.CornerRadius.sm, tone: .light, isHighlighted: true))
                    }
                    .buttonStyle(LiquidButtonPressStyle())
                }
            }
        }
    }

    private func handlePrimaryAction() {
        dismissKeyboard()
        if viewModel.isSaveStep {
            onSave()
        } else {
            _ = viewModel.advanceStepIfPossible()
        }
    }

    private func handleBackTap() {
        dismissKeyboard()
        if viewModel.handleBack() {
            return
        }
        onBack()
    }

    private func handleChooseAvatar() {
        dismissKeyboard()
        dismissPickers(animated: false)
        onChooseAvatar()
    }

    private func selectProfileForEditing(_ profile: Profile) {
        dismissKeyboard()
        dismissPickers(animated: false)
        withAnimation(.easeInOut(duration: 0.22)) {
            viewModel.selectProfileForEditing(profile)
        }
    }

    private func selectLanguage(_ language: ProfileLanguage) {
        dismissKeyboard()
        viewModel.toggleLanguage(language)
    }

    private func selectPreference(_ preference: ProfilePreference) {
        dismissKeyboard()
        viewModel.selectPreference(preference)
    }

    private func selectStorefrontPolicy(_ policy: StorefrontPolicy) {
        dismissKeyboard()
        viewModel.selectStorefrontPolicy(policy)
    }

    private func presentDatePicker() {
        dismissKeyboard()
        withAnimation(.easeInOut(duration: 0.2)) {
            viewModel.isGenderPickerPresented = false
            viewModel.isDatePickerPresented = true
        }
    }

    private func presentGenderPicker() {
        dismissKeyboard()
        withAnimation(.easeInOut(duration: 0.2)) {
            viewModel.isDatePickerPresented = false
            viewModel.isGenderPickerPresented = true
        }
    }

    private func dismissPickers(animated: Bool = true) {
        dismissKeyboard()
        let updates = {
            viewModel.isGenderPickerPresented = false
            viewModel.isDatePickerPresented = false
        }

        if animated {
            withAnimation(.easeInOut(duration: 0.2), updates)
        } else {
            updates()
        }
    }

    private func dismissKeyboard() {
        isNameFieldFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
                .fill(Color.white.opacity(0.05))
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

private struct ProfilePanelBackground: View {
    let cornerRadius: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1.2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.03), lineWidth: 1)
                    .blur(radius: 2)
            )
    }
}

private struct ProfileLanguageCardBackground: View {
    let isSelected: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color(hex: "282828"), Color(hex: "1E1D1D")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                if isSelected {
                    Color(hex: "3595DE").opacity(0.4)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1.334)
            )
    }
}

private struct ProfileGenderRowBackground: View {
    let cornerRadius: CGFloat
    let isSelected: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.white.opacity(0.05))
            .overlay {
                if isSelected {
                    Color(hex: "3595DE").opacity(0.22)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(isSelected ? 0.12 : 0.05), lineWidth: 1.2)
            )
    }
}

private struct ProfileLanguageCard: View {
    let language: ProfileLanguage
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                HStack(spacing: 12) {
                    Text(language.monogram)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.7))
                        .frame(width: 32, alignment: .leading)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(language.nativeTitle)
                            .font(.system(size: 16, weight: .regular))
                            .lineLimit(1)
                            .minimumScaleFactor(0.76)
                            .fixedSize(horizontal: true, vertical: false)

                        Text(language.englishTitle)
                            .font(.system(size: 16, weight: .regular))
                            .lineLimit(1)
                            .minimumScaleFactor(0.76)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .foregroundStyle(.white)

                    Spacer(minLength: 0)
                }
                .padding(.leading, 16)
                .padding(.trailing, 28)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(10)
                }
            }
            .frame(width: 162, alignment: .leading)
            .frame(height: 74.72)
            .background(
                ProfileLanguageCardBackground(isSelected: isSelected)
            )
        }
        .buttonStyle(LiquidButtonPressStyle())
    }
}

private struct StorefrontPolicyCard: View {
    let policy: StorefrontPolicy
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(policy.displayName)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .minimumScaleFactor(0.86)

                        Text("chrt=\(policy.chrtValue)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(isSelected ? Color(hex: "151424") : Color(hex: "F6C759"))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }

                    Spacer(minLength: 4)

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(isSelected ? Color(hex: "4DA3FF") : Color.white.opacity(0.42))
                }

                Text(policy.subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 94, alignment: .top)
            .padding(14)
            .background(
                LiquidGlassBackground(cornerRadius: 20, tone: .accent, isHighlighted: isSelected)
            )
        }
        .buttonStyle(LiquidButtonPressStyle())
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
                            colors: [Color(hex: "181818"), Color(hex: "0A0A0A")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
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
