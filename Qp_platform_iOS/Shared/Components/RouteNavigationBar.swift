import SwiftUI

struct RouteNavigationBar<Trailing: View>: View {
    let title: String?
    let onBack: () -> Void
    @ViewBuilder let trailing: Trailing

    init(
        title: String? = nil,
        onBack: @escaping () -> Void,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.onBack = onBack
        self.trailing = trailing()
    }

    var body: some View {
        ZStack {
            if let title {
                NavigationChromeTitle(title: title)
                    .frame(maxWidth: 220)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 12) {
                NavigationChromeButton(icon: AppIcons.Navigation.back, action: onBack)

                Spacer()

                trailing
                    .frame(minWidth: 46, alignment: .trailing)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 58)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.72), Color.black.opacity(0.28), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)
        )
    }
}

struct RouteNavigationIconButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

extension View {
    func routeNavigationOverlay<Trailing: View>(
        title: String? = nil,
        onBack: @escaping () -> Void,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) -> some View {
        overlay(alignment: .top) {
            GeometryReader { proxy in
                RouteNavigationBar(title: title, onBack: onBack, trailing: trailing)
                    .padding(.top, proxy.safeAreaInsets.top)
                    .frame(maxWidth: .infinity)
                    .frame(height: proxy.safeAreaInsets.top + 58, alignment: .top)
                    .ignoresSafeArea(edges: .top)
            }
            .allowsHitTesting(true)
            .frame(height: 120, alignment: .top)
        }
    }
}
