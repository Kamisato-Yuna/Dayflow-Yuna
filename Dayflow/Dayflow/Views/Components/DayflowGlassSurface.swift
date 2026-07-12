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
  let shape: DayflowGlassSurfaceShape?
  let isInteractive: Bool
  let shouldGroupGlassEffects: Bool
  @ViewBuilder let content: () -> Content

  init(
    role: DayflowSurfaceRole = .floatingControl,
    cornerRadius: CGFloat = 12,
    spacing: CGFloat = 8,
    shape: DayflowGlassSurfaceShape? = nil,
    isInteractive: Bool = true,
    shouldGroupGlassEffects: Bool = false,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.role = role
    self.cornerRadius = cornerRadius
    self.spacing = spacing
    self.shape = shape
    self.isInteractive = isInteractive
    self.shouldGroupGlassEffects = shouldGroupGlassEffects
    self.content = content
  }

  var body: some View {
    surface
  }

  private var surface: some View {
    content()
      .modifier(
        DayflowSurfaceModifier(
          role: role,
          cornerRadius: cornerRadius,
          glassShape: shape,
          isGlassInteractive: isInteractive,
          glassGroupingSpacing: shouldGroupGlassEffects ? spacing : nil
        )
      )
  }
}
