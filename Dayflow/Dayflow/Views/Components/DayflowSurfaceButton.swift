//
//  DayflowSurfaceButton.swift
//  Dayflow
//
//  Generic content button with unified Emil‑style hover/press interactions
//

import SwiftUI

struct DayflowSurfaceButton<Content: View>: View {
  let action: () -> Void
  @ViewBuilder let content: () -> Content

  var background: Color?
  var foreground: Color?
  var borderColor: Color?
  var cornerRadius: CGFloat = 0
  var horizontalPadding: CGFloat = 18
  var verticalPadding: CGFloat = 12
  var minWidth: CGFloat? = nil
  var showShadow: Bool = true
  var showOverlayStroke: Bool = false
  var isSecondaryStyle: Bool = false
  var style: DayflowSurfaceButtonStyle = .primary

  /// Set `isDisabledStyle` only when the button visual should stay disabled regardless
  /// of parent `.disabled(...)` state.
  var isDisabledStyle: Bool = false

  @State private var isHovered = false
  @State private var isPressed = false
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.isEnabled) private var isEnabled
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
  private var isDisabledState: Bool { isDisabledStyle || !isEnabled }
  private var resolvedStyle: DayflowSurfaceButtonStyle {
    if isDisabledState {
      return .disabled
    }

    if isSecondaryStyle {
      return .secondary
    }

    return style
  }

  private var resolvedBackground: Color {
    if let background {
      return background
    }

    return DayflowSurfaceButtonToken.background(
      for: resolvedStyle,
      colorScheme: colorScheme,
      reduceTransparency: reduceTransparency,
      isHovered: isHovered
    )
  }

  private var resolvedForeground: Color {
    let fallback = DayflowSurfaceButtonToken.foreground(
      for: resolvedStyle,
      colorScheme: colorScheme,
      reduceTransparency: reduceTransparency
    )
    return (foreground ?? fallback).opacity(resolvedStyle == .disabled ? 0.68 : 0.94)
  }

  private var resolvedBorder: Color {
    if let borderColor {
      return borderColor
    }
    return DayflowSurfaceButtonToken.border(
      for: resolvedStyle,
      colorScheme: colorScheme,
      increaseContrast: NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
    )
  }

  private var resolvedOverlayStroke: Color {
    if let borderColor, isSecondaryStyle {
      return borderColor
    }

    if showOverlayStroke {
      return DayflowSurfaceButtonToken.overlayStroke(
        for: resolvedStyle,
        colorScheme: colorScheme
      )
    }

    return resolvedBorder
  }

  private var resolvedShadow: (color: Color, radius: CGFloat, y: CGFloat) {
    return DayflowSurfaceButtonToken.shadow(
      for: resolvedStyle,
      colorScheme: colorScheme,
      reduceTransparency: reduceTransparency
    )
  }

  private let hoverAnim = Animation.spring(response: 0.22, dampingFraction: 0.85)
  private let pressAnim = Animation.spring(response: 0.26, dampingFraction: 0.75)

  var body: some View {
      Button(action: {
        guard !isDisabledState else { return }

        withAnimation(pressAnim) { isPressed = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
          withAnimation(pressAnim) { isPressed = false }
        action()
      }
    }) {
      HStack(spacing: 10) {
        content()
          .foregroundColor(resolvedForeground)
      }
      .padding(.horizontal, horizontalPadding)
      .padding(.vertical, verticalPadding)
      .frame(minWidth: minWidth)
      .background(resolvedBackground)
      .overlay(
        Group {
          if isSecondaryStyle {
            RoundedRectangle(cornerRadius: cornerRadius)
              .inset(by: 0.75)
              .stroke(
                DayflowSurfaceToken.borderColor(
                  for: .floatingControl,
                  colorScheme: colorScheme,
                  increaseContrast: NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
                ).opacity(1),
                lineWidth: 1.5
              )
          } else if showOverlayStroke {
            RoundedRectangle(cornerRadius: cornerRadius)
              .inset(by: 0.75)
              .stroke(resolvedOverlayStroke, lineWidth: 1.5)
          } else {
            RoundedRectangle(cornerRadius: cornerRadius)
              .inset(by: 0.5)
              .stroke(isHovered ? resolvedBorder.opacity(1.0) : resolvedBorder, lineWidth: 1)
          }
        }
      )
      .cornerRadius(cornerRadius)
      .if(isSecondaryStyle) { view in
        view
          .shadow(color: resolvedShadow.color, radius: max(resolvedShadow.radius * 0.45, 0.25), x: 0, y: max(resolvedShadow.y * 0.45, 0.5))
      }
      .if(!isSecondaryStyle) { view in
        view
          .if(showShadow) { view in
            view
              .shadow(
                color: resolvedShadow.color.opacity(isHovered ? 0.86 : 0.66),
                radius: isHovered ? resolvedShadow.radius : max(resolvedShadow.radius * 0.5, 1.2),
                x: 0,
                y: isHovered ? resolvedShadow.y : max(resolvedShadow.y * 0.7, 1.2)
              )
          }
          .if(showShadow) { view in
            view.shadow(
              color: resolvedShadow.color.opacity(isHovered ? 0.46 : 0.32),
              radius: isHovered ? max(resolvedShadow.radius * 0.25, 0.8) : max(resolvedShadow.radius * 0.15, 0.4),
              x: 0,
              y: 1
            )
          }
      }
      .brightness(isHovered ? 0.02 : 0)
      .dayflowPressScale(
        isPressed,
        enabled: !reduceMotion,
        pressedScale: 0.985,
        animation: pressAnim
      )
      .scaleEffect(reduceMotion ? 1.0 : (isHovered ? 1.02 : 1.0))
      .offset(y: reduceMotion ? 0 : (isHovered ? -1 : 0))
    }
    .buttonStyle(.plain)
    .onHover { hovering in
      withAnimation(hoverAnim) { isHovered = hovering }
    }
    .pointingHandCursor()
    .if(isDisabledState) { view in
      view.opacity(0.72)
    }
    .disabled(isDisabledState)
  }
}
