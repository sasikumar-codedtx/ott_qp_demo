import SwiftUI

/// Play/pause button where the icon morphs as a single shape — no image swap.
/// `progress` 0 = play (triangle), 1 = pause (two bars).
struct PlayPauseMorphButton: View {
    let isPlaying: Bool
    let size: CGFloat
    let action: () -> Void

    @State private var progress: Double = 0

    var body: some View {
        Button(action: action) {
            PlayPauseMorphShape(progress: progress)
                .fill(Color.white)
                .frame(width: size * 0.48, height: size * 0.58)
                .frame(width: size, height: size)
                .contentShape(Circle())
        }
        .buttonStyle(LiquidButtonPressStyle())
        .onAppear { progress = isPlaying ? 1.0 : 0.0 }
        .onChange(of: isPlaying) { _, playing in
            withAnimation(.spring(response: 0.36, dampingFraction: 0.70)) {
                progress = playing ? 1.0 : 0.0
            }
        }
    }
}

private struct PlayPauseMorphShape: Shape {
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        let p = progress

        // Interpolates a normalized point between play and pause positions.
        func pt(_ play: (CGFloat, CGFloat), _ pause: (CGFloat, CGFloat)) -> CGPoint {
            CGPoint(
                x: (play.0 + (pause.0 - play.0) * p) * w,
                y: (play.1 + (pause.1 - play.1) * p) * h
            )
        }

        var path = Path()

        // Left sub-shape
        //   play  → left half of triangle, inset 8% top/bottom: (0,0.08)—(0.5,0.29)—(0.5,0.71)—(0,0.92)
        //   pause → left bar, full height:                       (0,0)   —(0.38,0)  —(0.38,1) —(0,1)
        path.move(to:    pt((0.00, 0.08), (0.00, 0.00)))
        path.addLine(to: pt((0.50, 0.29), (0.38, 0.00)))
        path.addLine(to: pt((0.50, 0.71), (0.38, 1.00)))
        path.addLine(to: pt((0.00, 0.92), (0.00, 1.00)))
        path.closeSubpath()

        // Right sub-shape
        //   play  → right half of triangle (tip): (0.5,0.29)—(1,0.5)—(1,0.5)—(0.5,0.71)
        //   pause → right bar, full height:        (0.62,0)  —(1,0)  —(1,1) —(0.62,1)
        path.move(to:    pt((0.50, 0.29), (0.62, 0.00)))
        path.addLine(to: pt((1.00, 0.50), (1.00, 0.00)))
        path.addLine(to: pt((1.00, 0.50), (1.00, 1.00)))
        path.addLine(to: pt((0.50, 0.71), (0.62, 1.00)))
        path.closeSubpath()

        return path
    }
}
