import SwiftUI

struct KeyboardOverlayBackdropView: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.28)

            Color.black.opacity(0.62)
        }
        .allowsHitTesting(false)
    }
}
