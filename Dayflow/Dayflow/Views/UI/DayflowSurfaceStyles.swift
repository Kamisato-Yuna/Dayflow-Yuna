//
//  DayflowSurfaceStyles.swift
//  Dayflow
//
//  Semantic surface tokens for the macOS 15 material and macOS 26 glass paths.
//

import AppKit
import SwiftUI

enum DayflowSurfaceRole: CaseIterable {
  case windowBackground
  case sidebarSurface
  case contentPanel
  case inspectorPanel
  case floatingControl
  case popoverSurface
  case modalSurface

  var usesLiquidGlass: Bool {
    switch self {
    case .floatingControl, .popoverSurface, .modalSurface:
      return true
    case .windowBackground, .sidebarSurface, .contentPanel, .inspectorPanel:
      return false
    }
  }
}

enum DayflowSurfaceAccent {
  static let primary = Color.accentColor
  static let secondary = Color(nsColor: .secondaryLabelColor)
  static let positive = Color(nsColor: .systemGreen)
  static let warning = Color(nsColor: .systemYellow)
  static let critical = Color(nsColor: .systemRed)
}

enum DayflowSurfaceToken {
  static func material(for role: DayflowSurfaceRole) -> Material {
    switch role {
    case .windowBackground:
      return .regularMaterial
    case .sidebarSurface, .floatingControl, .popoverSurface:
      return .ultraThinMaterial
    case .contentPanel, .inspectorPanel, .modalSurface:
      return .regularMaterial
    }
  }

  static func fillColor(
    for role: DayflowSurfaceRole,
    colorScheme: ColorScheme,
    reduceTransparency: Bool
  ) -> Color {
    let isDark = colorScheme == .dark
    if reduceTransparency {
      switch role {
      case .windowBackground:
        return Color(nsColor: .windowBackgroundColor)
      case .sidebarSurface, .contentPanel, .inspectorPanel, .floatingControl, .popoverSurface,
        .modalSurface:
        return Color(nsColor: .controlBackgroundColor)
      }
    }

    switch role {
    case .windowBackground:
      return isDark ? Color.white.opacity(0.04) : Color.white.opacity(0.42)
    case .sidebarSurface:
      return isDark ? Color.white.opacity(0.07) : Color.white.opacity(0.50)
    case .contentPanel:
      return isDark ? Color.white.opacity(0.08) : Color.white.opacity(0.58)
    case .inspectorPanel:
      return isDark ? Color.white.opacity(0.09) : Color.white.opacity(0.54)
    case .floatingControl:
      return isDark ? Color.white.opacity(0.12) : Color.white.opacity(0.66)
    case .popoverSurface:
      return isDark ? Color.white.opacity(0.13) : Color.white.opacity(0.70)
    case .modalSurface:
      return isDark ? Color.white.opacity(0.11) : Color.white.opacity(0.72)
    }
  }

  static func borderColor(
    for role: DayflowSurfaceRole,
    colorScheme: ColorScheme,
    increaseContrast: Bool
  ) -> Color {
    let isDark = colorScheme == .dark
    let baseOpacity: Double
    switch role {
    case .windowBackground:
      baseOpacity = 0
    case .floatingControl, .popoverSurface, .modalSurface:
      baseOpacity = increaseContrast ? 0.34 : 0.18
    case .sidebarSurface, .contentPanel, .inspectorPanel:
      baseOpacity = increaseContrast ? 0.30 : 0.14
    }
    return (isDark ? Color.white : Color.black).opacity(baseOpacity)
  }

  static func shadow(
    for role: DayflowSurfaceRole,
    colorScheme: ColorScheme,
    reduceTransparency: Bool
  ) -> (color: Color, radius: CGFloat, y: CGFloat) {
    guard !reduceTransparency else {
      return (.clear, 0, 0)
    }

    let opacity = colorScheme == .dark ? 0.28 : 0.10
    switch role {
    case .windowBackground:
      return (.clear, 0, 0)
    case .sidebarSurface:
      return (.black.opacity(opacity * 0.55), 12, 2)
    case .contentPanel, .inspectorPanel:
      return (.black.opacity(opacity * 0.75), 16, 4)
    case .floatingControl:
      return (.black.opacity(opacity), 12, 3)
    case .popoverSurface, .modalSurface:
      return (.black.opacity(opacity * 1.15), 24, 8)
    }
  }
}

private struct DayflowWindowBackgroundModifier: ViewModifier {
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

  func body(content: Content) -> some View {
    content
      .background {
        ZStack {
          Color(nsColor: .windowBackgroundColor)

          if !reduceTransparency {
            LinearGradient(
              colors: [
                DayflowSurfaceToken.fillColor(
                  for: .windowBackground,
                  colorScheme: colorScheme,
                  reduceTransparency: reduceTransparency
                ),
                Color(nsColor: .controlBackgroundColor).opacity(colorScheme == .dark ? 0.20 : 0.36),
              ],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          }
        }
        .ignoresSafeArea()
      }
  }
}

struct DayflowSurfaceModifier: ViewModifier {
  let role: DayflowSurfaceRole
  let cornerRadius: CGFloat

  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

  func body(content: Content) -> some View {
    let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    let increaseContrast = NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
    let shadow = DayflowSurfaceToken.shadow(
      for: role,
      colorScheme: colorScheme,
      reduceTransparency: reduceTransparency
    )

    content
      .background {
        if reduceTransparency {
          shape.fill(
            DayflowSurfaceToken.fillColor(
              for: role,
              colorScheme: colorScheme,
              reduceTransparency: reduceTransparency
            )
          )
        } else {
          shape.fill(DayflowSurfaceToken.material(for: role))
          shape.fill(
            DayflowSurfaceToken.fillColor(
              for: role,
              colorScheme: colorScheme,
              reduceTransparency: reduceTransparency
            )
          )
        }
      }
      .overlay {
        shape.stroke(
          DayflowSurfaceToken.borderColor(
            for: role,
            colorScheme: colorScheme,
            increaseContrast: increaseContrast
          ),
          lineWidth: increaseContrast ? 1.2 : 0.8
        )
      }
      .shadow(color: shadow.color, radius: shadow.radius, x: 0, y: shadow.y)
      .clipShape(shape)
      .modifier(DayflowLiquidGlassModifier(isEnabled: role.usesLiquidGlass))
  }
}

private struct DayflowLiquidGlassModifier: ViewModifier {
  let isEnabled: Bool

  @ViewBuilder
  func body(content: Content) -> some View {
    if #available(macOS 26.0, *), isEnabled {
      content.glassEffect()
    } else {
      content
    }
  }
}

extension View {
  func dayflowWindowBackground() -> some View {
    modifier(DayflowWindowBackgroundModifier())
  }

  func dayflowContentPanel(cornerRadius: CGFloat = 14) -> some View {
    modifier(DayflowSurfaceModifier(role: .contentPanel, cornerRadius: cornerRadius))
  }

  func dayflowSidebarSurface(cornerRadius: CGFloat = 14) -> some View {
    modifier(DayflowSurfaceModifier(role: .sidebarSurface, cornerRadius: cornerRadius))
  }

  func dayflowInspectorPanel(cornerRadius: CGFloat = 14) -> some View {
    modifier(DayflowSurfaceModifier(role: .inspectorPanel, cornerRadius: cornerRadius))
  }

  func dayflowFloatingControl(cornerRadius: CGFloat = 12) -> some View {
    modifier(DayflowSurfaceModifier(role: .floatingControl, cornerRadius: cornerRadius))
  }

  func dayflowPopoverSurface(cornerRadius: CGFloat = 16) -> some View {
    modifier(DayflowSurfaceModifier(role: .popoverSurface, cornerRadius: cornerRadius))
  }

  func dayflowModalSurface(cornerRadius: CGFloat = 18) -> some View {
    modifier(DayflowSurfaceModifier(role: .modalSurface, cornerRadius: cornerRadius))
  }
}
