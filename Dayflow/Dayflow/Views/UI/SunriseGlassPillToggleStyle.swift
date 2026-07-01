import SwiftUI

struct SunriseGlassPillToggleStyle: ToggleStyle {
  var onColors: [Color] = [
    Color(red: 1.00, green: 0.85, blue: 0.72),  // slightly deeper peach
    Color(hex: "FF7506"),  // darker brand orange
  ]
  var offColors: [Color] = [
    Color(hex: "F0E9E6"),
    Color(hex: "F0E9E6"),
  ]
  var trackWidth: CGFloat = 64
  var trackHeight: CGFloat = 32
  var knobSize: CGFloat = 28

  @Environment(\.colorScheme) private var scheme

  func makeBody(configuration: Configuration) -> some View {
    let is开启 = configuration.is开启
    Button {
      withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
        configuration.is开启.toggle()
        #if os(iOS)
          UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
      }
    } label: {
      ZStack(alignment: is开启 ? .trailing : .leading) {

        // Track
        Capsule()
          .fill(
            LinearGradient(
              colors: is开启 ? onColors : offColors,
              startPoint: .topLeading, endPoint: .bottomTrailing
            )
          )
          .overlay(
            Capsule()
              .strokeBorder(.white.opacity(is开启 ? 0.35 : 0.45), lineWidth: 1)
              .blendMode(.overlay)
          )
          .overlay(
            Capsule()
              .stroke(Color(hex: "E5E5E5"), lineWidth: 1)
              .opacity(0.9)
          )
          .overlay(
            // 轻微 top highlight to match chips/date pill gloss
            Capsule()
              .fill(.white.opacity(is开启 ? 0.18 : 0.12))
              .frame(height: trackHeight * 0.55)
              .offset(y: -trackHeight * 0.22)
              .blur(radius: 2)
          )
          .background(
            Capsule().fill(.ultraThinMaterial)
          )
          .frame(width: trackWidth, height: trackHeight)

        // Knob
        Circle()
          .fill(
            RadialGradient(
              colors: [Color.white, Color.white.opacity(0.65)],
              center: .center, startRadius: 1, endRadius: knobSize
            )
          )
          .overlay(
            Circle().strokeBorder(.black.opacity(0.06), lineWidth: 0.75)
          )
          .frame(width: knobSize, height: knobSize)
          .padding(2)
      }
      .accessibilityElement(children: .ignore)
      .accessibilityValue(Text(is开启 ? "开启" : "关闭"))
    }
    .buttonStyle(.plain)
    .pointingHandCursor()
  }
}
