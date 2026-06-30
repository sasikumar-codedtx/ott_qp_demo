import SwiftUI
import UIKit

extension View {
    /// Reports changes to the *physical* device orientation, independent of the
    /// interface orientation lock in `AppDelegate`. Use this to react to the user
    /// physically rotating the phone even when the UI itself is orientation-locked.
    ///
    /// Device-orientation notifications are reference-counted by UIKit, so multiple
    /// observers calling begin/end concurrently is safe.
    func onDeviceOrientationChange(_ action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        modifier(DeviceOrientationModifier(action: action))
    }
}

private struct DeviceOrientationModifier: ViewModifier {
    let action: (UIDeviceOrientation) -> Void

    func body(content: Content) -> some View {
        content
            .onAppear { UIDevice.current.beginGeneratingDeviceOrientationNotifications() }
            .onDisappear { UIDevice.current.endGeneratingDeviceOrientationNotifications() }
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                action(UIDevice.current.orientation)
            }
    }
}
