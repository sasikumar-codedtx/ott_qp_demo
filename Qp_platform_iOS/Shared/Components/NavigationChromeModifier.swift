import SwiftUI
import UIKit

private struct NavigationChromeModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
            .toolbar(.hidden, for: .navigationBar)
            .background(InteractivePopGestureBridge())
    }
}

extension View {
    func routeNavigationChrome() -> some View {
        modifier(NavigationChromeModifier())
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
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }
}
