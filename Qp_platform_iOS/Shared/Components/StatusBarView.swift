import SwiftUI

struct StatusBarView: View {
    var body: some View {
        HStack {
            Text("9:30")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.white.opacity(0.92))

            Spacer()

            HStack(spacing: UIConstants.Spacing.sm) {
                Image(systemName: "wifi")
                Image(systemName: "cellularbars")
                Image(systemName: "battery.100")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.white.opacity(0.72))
        }
    }
}

#Preview {
    StatusBarView()
        .padding()
        .background(Color.black)
}
