import SwiftUI

struct SunriseGlassPillToggleStyle: ToggleStyle {
  var onColors: [Color] = [
    DayflowSurfaceAccent.primary.opacity(0.34),
    DayflowSurfaceAccent.primary.opacity(0.72),
  ]
  var offColors: [Color] = [
    Color(nsColor: .controlBackgroundColor).opacity(0.52),
    Color(nsColor: .controlBackgroundColor).opacity(0.32),
  ]
  var trackWidth: CGFloat = 64
  var trackHeight: CGFloat = 32
  var knobSize: CGFloat = 28

  @Environment(\.colorScheme) private var scheme

  func makeBody(configuration: Configuration) -> some View {
    let isOn = configuration.isOn
    Button {
      withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
        configuration.isOn.toggle()
        #if os(iOS)
          UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
      }
    } label: {
      ZStack(alignment: isOn ? .trailing : .leading) {

        // Track
        Capsule()
          .fill(
            LinearGradient(
              colors: isOn ? onColors : offColors,
              startPoint: .topLeading, endPoint: .bottomTrailing
            )
          )
          .overlay(
            Capsule()
              .strokeBorder(
                Color(nsColor: .highlightColor).opacity(isOn ? 0.28 : 0.36),
                lineWidth: 1
              )
              .blendMode(.overlay)
          )
          .overlay(
            Capsule()
              .stroke(
                isOn
                  ? DayflowSurfaceAccent.primary.opacity(0.36)
                  : Color(nsColor: .separatorColor).opacity(0.42),
                lineWidth: 1
              )
          )
          .overlay(
            Capsule()
              .fill(Color(nsColor: .highlightColor).opacity(isOn ? 0.18 : 0.12))
              .frame(height: trackHeight * 0.55)
              .offset(y: -trackHeight * 0.22)
              .blur(radius: 2)
          )
          .background(
            Capsule().fill(.ultraThinMaterial)
          )
          .dayflowFloatingControl(cornerRadius: trackHeight / 2)
          .frame(width: trackWidth, height: trackHeight)

        // Knob
        Circle()
          .fill(
            RadialGradient(
              colors: [
                Color(nsColor: .controlBackgroundColor),
                Color(nsColor: .controlBackgroundColor).opacity(0.65),
              ],
              center: .center, startRadius: 1, endRadius: knobSize
            )
          )
          .overlay(
            Circle()
              .strokeBorder(Color(nsColor: .separatorColor).opacity(0.30), lineWidth: 0.75)
          )
          .frame(width: knobSize, height: knobSize)
          .padding(2)
      }
      .accessibilityElement(children: .ignore)
      .accessibilityValue(Text(isOn ? "开启" : "关闭"))
    }
    .buttonStyle(.plain)
    .pointingHandCursor()
  }
}
