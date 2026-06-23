import SwiftUI
import UIKit

private var navigationPopDelegateKey: UInt8 = 0

private struct NavigationChromeModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
            .toolbarRole(.editor)
            .toolbar(.visible, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .background(InteractivePopGestureBridge())
    }
}

extension View {
    func routeNavigationChrome() -> some View {
        modifier(NavigationChromeModifier())
    }
}

struct NavigationChromeButton: View {
    let icon: String
    var isHighlighted = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 45.5, height: 45.5)
                .background(navigationChromeBackground)
                .contentShape(navigationChromeShape)
        }
        .buttonStyle(.plain)
    }

    private var navigationChromeShape: some Shape {
        let isBackButton = icon == AppIcons.Navigation.back
        return UnevenRoundedRectangle(
            topLeadingRadius: isBackButton ? 18 : 8,
            bottomLeadingRadius: isBackButton ? 18 : 8,
            bottomTrailingRadius: isBackButton ? 8 : 18,
            topTrailingRadius: isBackButton ? 8 : 18,
            style: .continuous
        )
    }

    private var navigationChromeBackground: some View {
        navigationChromeShape
            .fill(Color(hex: "CFCFCF").opacity(0.1))
            .overlay(navigationChromeShape.stroke(Color.white.opacity(0.1), lineWidth: 1.211))
    }
}

struct NavigationChromeTitle: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(.white)
            .lineLimit(1)
    }
}

private struct InteractivePopGestureBridge: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> InteractivePopGestureController {
        InteractivePopGestureController()
    }

    func updateUIViewController(_ uiViewController: InteractivePopGestureController, context: Context) {
        uiViewController.refreshNavigationController()
    }
}

private final class InteractivePopGestureController: UIViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshNavigationController()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshNavigationController()
    }

    func refreshNavigationController() {
        navigationItem.hidesBackButton = true
        applyInteractivePopFix()
        DispatchQueue.main.async { [weak self] in
            self?.applyInteractivePopFix()
        }
    }

    private func applyInteractivePopFix() {
        guard let navigationController = nearestNavigationController else { return }

        let popDelegate: InteractivePopGestureDelegate
        if let existing = objc_getAssociatedObject(navigationController, &navigationPopDelegateKey) as? InteractivePopGestureDelegate {
            popDelegate = existing
        } else {
            popDelegate = InteractivePopGestureDelegate(navigationController: navigationController)
            objc_setAssociatedObject(
                navigationController,
                &navigationPopDelegateKey,
                popDelegate,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }

        navigationController.interactivePopGestureRecognizer?.isEnabled = true
        navigationController.interactivePopGestureRecognizer?.delegate = popDelegate
    }

    private var nearestNavigationController: UINavigationController? {
        if let navigationController {
            return navigationController
        }

        var parentController = parent
        while let current = parentController {
            if let navigationController = current as? UINavigationController {
                return navigationController
            }
            if let navigationController = current.navigationController {
                return navigationController
            }
            parentController = current.parent
        }

        return nil
    }
}

private final class InteractivePopGestureDelegate: NSObject, UIGestureRecognizerDelegate {
    weak var navigationController: UINavigationController?

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        super.init()
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let navigationController else { return false }
        return navigationController.viewControllers.count > 1 && navigationController.transitionCoordinator == nil
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
}
