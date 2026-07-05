import SwiftUI

struct WeeklyHeader: View {
  let title: String
  let canNavigateForward: Bool
  let onPrevious: () -> Void
  let onNext: () -> Void

  var body: some View {
    HStack(spacing: 14) {
      WeeklyNavigationButton(systemName: "chevron.left") {
        onPrevious()
      }

      Text(title)
        .font(.system(size: 20, weight: .semibold, design: .rounded))
        .foregroundStyle(DayflowWeeklyToken.title)
        .multilineTextAlignment(.center)
        .frame(width: 344)

      WeeklyNavigationButton(systemName: "chevron.right", isEnabled: canNavigateForward) {
        onNext()
      }
    }
    .frame(maxWidth: .infinity)
    .frame(height: 29)
  }
}

private struct WeeklyNavigationButton: View {
  let systemName: String
  var isEnabled = true
  let action: () -> Void
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

  @State private var isHovering = false

  private let arrowSize: CGFloat = 24
  private let hoverCircleSize: CGFloat = 30

  var body: some View {
    Button {
      guard isEnabled else { return }
      action()
    } label: {
      ZStack {
        Circle()
          .fill(DayflowWeeklyToken.controlFill(
            isSelected: true,
            colorScheme: colorScheme,
            reduceTransparency: reduceTransparency
          ))
          .frame(width: hoverCircleSize, height: hoverCircleSize)
          .opacity(isHovering && isEnabled ? 1 : 0)

        Image(systemName: systemName)
          .font(.system(size: arrowSize * 0.58, weight: .semibold))
          .symbolRenderingMode(.hierarchical)
          .frame(width: arrowSize, height: arrowSize)
          .foregroundStyle(isEnabled ? DayflowWeeklyToken.chartText : DayflowWeeklyToken.chartTertiaryText)
          .opacity(isEnabled ? 1 : 0.35)
      }
      .frame(width: hoverCircleSize, height: hoverCircleSize)
      .contentShape(Circle())
    }
    .buttonStyle(DayflowPressScaleButtonStyle(enabled: isEnabled))
    .disabled(!isEnabled)
    .onHover { hovering in
      withAnimation(.easeOut(duration: 0.12)) {
        isHovering = isEnabled && hovering
      }
    }
    .onChange(of: isEnabled) { _, enabled in
      if !enabled {
        isHovering = false
      }
    }
    .pointingHandCursorOnHover(enabled: isEnabled, reassertOnPressEnd: true)
  }
}
