import SwiftUI

private struct DemoAlertModifier: ViewModifier {
    @Binding var isPresented: Bool

    func body(content: Content) -> some View {
        content
            .alert("Demo Application", isPresented: $isPresented) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("This is demo application specially designed for Sony LIV. This feature will be available going forward")
            }
    }
}

extension View {
    func demoAlert(isPresented: Binding<Bool>) -> some View {
        modifier(DemoAlertModifier(isPresented: isPresented))
    }
}
