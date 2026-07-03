//
//  DayflowGlassSurface.swift
//  Dayflow
//
//  Wrapper for grouped functional surfaces that can participate in Liquid Glass.
//

import SwiftUI

struct DayflowGlassSurface<Content: View>: View {
  let role: DayflowSurfaceRole
  let cornerRadius: CGFloat
  let spacing: CGFloat
  @ViewBuilder let content: () -> Content

  init(
    role: DayflowSurfaceRole = .floatingControl,
    cornerRadius: CGFloat = 12,
    spacing: CGFloat = 8,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.role = role
    self.cornerRadius = cornerRadius
    self.spacing = spacing
    self.content = content
  }

  var body: some View {
    if #available(macOS 26.0, *), role.usesLiquidGlass {
      GlassEffectContainer(spacing: spacing) {
        surface
      }
    } else {
      surface
    }
  }

  private var surface: some View {
    content()
      .modifier(DayflowSurfaceModifier(role: role, cornerRadius: cornerRadius))
  }
}
