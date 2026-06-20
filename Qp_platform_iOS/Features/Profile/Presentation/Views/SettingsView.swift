import SwiftUI

struct SettingsView: View {
    let onBack: () -> Void
    let onSignOut: () -> Void

    private let sections: [[SettingsRow]] = [
        [
            SettingsRow(icon: AppIcons.Action.person, title: AppStrings.Profile.account, subtitle: "Personal details & parental controls"),
            SettingsRow(icon: AppIcons.Action.receipt, title: AppStrings.Profile.manageSubscription, subtitle: "view purchase history and upgrade plans"),
            SettingsRow(icon: AppIcons.Action.bolt, title: AppStrings.Profile.flipkart, subtitle: "Get discounts using flipkart's super coins"),
            SettingsRow(icon: AppIcons.Action.tv, title: AppStrings.Profile.activateTV, subtitle: "Connect and manage TV settings")
        ],
        [
            SettingsRow(icon: AppIcons.Action.video, title: AppStrings.Profile.videoSettings, subtitle: "Video quality, streaming, PIP mode"),
            SettingsRow(icon: AppIcons.Action.headphones, title: AppStrings.Profile.audioSettings, subtitle: "Audio, language and subtitle preference")
        ],
        [
            SettingsRow(icon: AppIcons.Action.question, title: AppStrings.Profile.faqs, subtitle: nil),
            SettingsRow(icon: AppIcons.Action.doc, title: AppStrings.Profile.terms, subtitle: nil),
            SettingsRow(icon: AppIcons.Action.shield, title: AppStrings.Profile.privacy, subtitle: nil),
            SettingsRow(icon: AppIcons.Action.logout, title: AppStrings.Profile.signOut, subtitle: nil, accent: Color.orange)
        ]
    ]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: UIConstants.Spacing.xl) {
                header
                subscriptionCard

                ForEach(Array(sections.enumerated()), id: \.offset) { _, group in
                    settingsGroup(group)
                }

                footer
            }
            .padding(.horizontal, UIConstants.Spacing.lg)
            .padding(.bottom, UIConstants.Spacing.xxl)
        }
    }

    private var header: some View {
        VStack(spacing: UIConstants.Spacing.lg) {
            StatusBarView()
                .padding(.horizontal, UIConstants.Spacing.xs)
                .padding(.top, UIConstants.Spacing.sm + 2)

            HStack {
                Button(action: onBack) {
                    Image(systemName: AppIcons.Navigation.back)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: UIConstants.CornerRadius.lg, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                        )
                }
                .buttonStyle(.plain)

                Spacer()

                Text(AppStrings.Profile.settings)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)

                Spacer()

                Image(systemName: AppIcons.Action.headphones)
                    .font(.title3.weight(.regular))
                    .foregroundStyle(.white.opacity(0.72))
                    .frame(width: 44, height: 44)
            }
        }
    }

    private var subscriptionCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: UIConstants.Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.orange)
                    Image(systemName: "exclamationmark")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(AppEnvironment.AuthSession.hasActiveSubscription ? "Active Subscription" : AppStrings.Profile.noActiveSubscription)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                    Text(AppEnvironment.AuthSession.supportPhoneNumber)
                        .font(.subheadline)
                        .foregroundStyle(Color.white.opacity(0.7))
                }

                Spacer()

                Image(systemName: AppIcons.Navigation.next)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .padding(UIConstants.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "17113A"), Color(hex: "40160E")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )

            Text("Upgrade to 4K UHD • Dolby Atoms • Ads Free")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, UIConstants.Spacing.sm + 2)
                .background(Color(hex: "F6B52E"))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .offset(y: -12)
                .padding(.horizontal, 4)
                .padding(.bottom, -12)
        }
    }

    private func settingsGroup(_ rows: [SettingsRow]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                Button(action: {
                    if row.title == AppStrings.Profile.signOut {
                        onSignOut()
                    }
                }) {
                    HStack(spacing: UIConstants.Spacing.md) {
                        Image(systemName: row.icon)
                            .font(.body.weight(.medium))
                            .foregroundStyle(row.accent ?? Color.white.opacity(0.76))
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.title)
                                .font(.body.weight(.medium))
                                .foregroundStyle(row.accent ?? .white)
                            if let subtitle = row.subtitle {
                                Text(subtitle)
                                    .font(.caption)
                                    .foregroundStyle(Color.white.opacity(0.4))
                            }
                        }

                        Spacer()

                        if row.title != AppStrings.Profile.signOut {
                            Image(systemName: AppIcons.Navigation.next)
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(Color.white.opacity(0.72))
                        }
                    }
                    .padding(.horizontal, UIConstants.Spacing.lg)
                    .padding(.vertical, UIConstants.Spacing.lg)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if index < rows.count - 1 {
                    Divider()
                        .overlay(Color.white.opacity(0.05))
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }

    private var footer: some View {
        VStack(spacing: UIConstants.Spacing.md) {
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 82, height: 82)

            Text(AppStrings.Profile.sonyFooter)
                .font(.footnote)
                .foregroundStyle(Color.white.opacity(0.42))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, UIConstants.Spacing.md)
    }
}

private struct SettingsRow: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String?
    var accent: Color?
}
