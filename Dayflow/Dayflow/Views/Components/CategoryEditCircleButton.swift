import SwiftUI

struct CategoryEditCircleButton: View {
  let action: () -> Void
  var diameter: CGFloat = 30
  var iconSize: CGFloat? = nil
  var accessibilityLabel: String = "Edit categories"

  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    let resolvedIconSize = iconSize ?? diameter * 0.48

    Button(action: action) {
      Image(systemName: "pencil")
        .font(.system(size: resolvedIconSize, weight: .semibold))
        .foregroundStyle(DayflowSurfaceAccent.primary)
        .frame(width: resolvedIconSize, height: resolvedIconSize)
        .frame(width: diameter, height: diameter)
        .background(DayflowSurfaceAccent.primary.opacity(colorScheme == .dark ? 0.20 : 0.13))
        .dayflowFloatingControl(
          cornerRadius: diameter / 2,
          shape: .circle,
          isInteractive: true
        )
    }
    .buttonStyle(DayflowPressScaleButtonStyle(pressedScale: 0.97))
    .hoverScaleEffect(scale: 1.02)
    .pointingHandCursorOnHover(reassertOnPressEnd: true)
    .accessibilityLabel(accessibilityLabel)
  }
}
