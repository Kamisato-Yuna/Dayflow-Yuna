//
//  DayflowButton.swift
//  Dayflow
//
//  Custom button component with Dayflow branding
//

import AppKit
import SwiftUI

struct DayflowButton: View {
  let title: String
  let action: () -> Void
  var width: CGFloat = 160
  var fontSize: CGFloat = 16
  var isSubtle: Bool = false

  @State private var isPressed = false
  @State private var isHovered = false
  @State private var showPulse = false
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.colorScheme) private var colorScheme

  // Animation constants following Emil Kowalski principles
  private let hoverAnimation = Animation.spring(
    response: 0.22, dampingFraction: 0.8, blendDuration: 0)
  private let pressAnimation = Animation.spring(
    response: 0.3, dampingFraction: 0.65, blendDuration: 0)

  private var foregroundColor: Color {
    isSubtle ? Color(nsColor: .labelColor) : Color(nsColor: .selectedMenuItemTextColor)
  }

  private var accentFill: Color {
    DayflowSurfaceAccent.primary.opacity(colorScheme == .dark ? 0.76 : 0.86)
  }

  private var subtleFill: Color {
    Color(nsColor: .controlBackgroundColor).opacity(colorScheme == .dark ? 0.32 : 0.48)
  }

  private var borderColor: Color {
    isSubtle
      ? Color(nsColor: .separatorColor).opacity(isHovered ? 0.46 : 0.30)
      : Color(nsColor: .highlightColor).opacity(isHovered ? 0.28 : 0.18)
  }

  var body: some View {
    Button(action: {
      // Trigger pulse animation
      withAnimation(.easeOut(duration: 0.1)) {
        isPressed = true
      }

      // Haptic feedback on macOS 11+
      if #available(macOS 11.0, *) {
        NSHapticFeedbackManager.defaultPerformer.perform(
          .levelChange,
          performanceTime: .default
        )
      }

      // Reset and call action
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        withAnimation(pressAnimation) {
          isPressed = false
          showPulse = true
        }
        action()

        // Reset pulse
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
          showPulse = false
        }
      }
    }) {
      Text(title)
        .font(.custom("Figtree", size: fontSize))
        .fontWeight(.semibold)
        .foregroundColor(foregroundColor)
        .frame(width: width, height: 56, alignment: .center)
        .background(
          ZStack {
            if !isSubtle {
              accentFill
            } else {
              subtleFill
            }

            // Pulse effect
            if showPulse {
              Group {
                if isSubtle {
                  DayflowSurfaceAccent.primary.opacity(0.08)
                } else {
                  Color(nsColor: .highlightColor).opacity(0.22)
                }
              }
              .scaleEffect(1.2)
              .blur(radius: 10)
              .animation(.easeOut(duration: 0.3), value: showPulse)
            }
          }
        )
        .cornerRadius(12)
        // Enhanced shadows with hover state
        .shadow(
          color: .black.opacity(isHovered ? 0.35 : 0.25),
          radius: isHovered ? 0.5 : 0.25,
          x: 0,
          y: isHovered ? 1 : 0.5
        )
        .shadow(
          color: .black.opacity(isHovered ? 0.22 : 0.16),
          radius: isHovered ? 1 : 0.5,
          x: 0,
          y: isHovered ? 2 : 1
        )
        .shadow(
          color: .black.opacity(isHovered ? 0.4 : 0.3),
          radius: isHovered ? 10 : 6,
          x: 0,
          y: isHovered ? 4 : 2
        )
        .overlay(
          RoundedRectangle(cornerRadius: 12)
            .inset(by: 0.75)
            .stroke(borderColor, lineWidth: 1.5)
        )
        .dayflowFloatingControl(cornerRadius: 12)
        .dayflowPressScale(
          isPressed,
          enabled: !reduceMotion,
          pressedScale: 0.97,
          animation: pressAnimation
        )
        .scaleEffect(reduceMotion ? 1.0 : (isHovered ? 1.02 : 1.0))
        .offset(y: reduceMotion ? 0 : (isHovered ? (isSubtle ? -1 : -2) : 0))
        .brightness(isHovered ? (isSubtle ? 0.05 : 0.08) : 0)
    }
    .buttonStyle(.plain)  // Remove default button styling
    .pointingHandCursor()
    .onHover { hovering in
      withAnimation(hoverAnimation) {
        isHovered = hovering
      }
    }
  }
}

struct DayflowButton_Previews: PreviewProvider {
  static var previews: some View {
    VStack(spacing: 20) {
      DayflowButton(title: "开始", action: {})
      DayflowButton(title: "继续", action: {}, width: 200)
      DayflowButton(title: "下一步", action: {}, width: 120, fontSize: 14)
      DayflowButton(title: "轻量", action: {}, isSubtle: true)
    }
    .padding(40)
    .background(Color.gray.opacity(0.1))
  }
}
