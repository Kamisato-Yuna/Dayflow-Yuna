//
//  DayflowLineAnimationView.swift
//  Dayflow
//

import SwiftUI

enum DayflowLineAnimationVariant {
  case appLaunch
  case onboardingIntro
  case journalOnboarding

  var accent: Color {
    switch self {
    case .appLaunch:
      return Color(red: 0.84, green: 0.88, blue: 0.96)
    case .onboardingIntro:
      return Color(red: 0.95, green: 0.80, blue: 0.62)
    case .journalOnboarding:
      return Color(red: 0.92, green: 0.72, blue: 0.54)
    }
  }

  var secondaryAccent: Color {
    switch self {
    case .appLaunch:
      return Color(red: 0.64, green: 0.72, blue: 0.84)
    case .onboardingIntro:
      return Color(red: 0.74, green: 0.78, blue: 0.86)
    case .journalOnboarding:
      return Color(red: 0.78, green: 0.70, blue: 0.84)
    }
  }

  var baseDuration: TimeInterval {
    switch self {
    case .appLaunch:
      return 2.4
    case .onboardingIntro:
      return 3.0
    case .journalOnboarding:
      return 2.8
    }
  }
}

struct DayflowLineAnimationView: View {
  let variant: DayflowLineAnimationVariant
  var onStarted: () -> Void = {}
  var onCompleted: (String) -> Void

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var startDate = Date()
  @State private var hasStarted = false
  @State private var hasCompleted = false

  var body: some View {
    TimelineView(.animation) { timeline in
      Canvas { context, size in
        draw(in: &context, size: size, date: timeline.date)
      }
    }
    .background(background)
    .ignoresSafeArea()
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Dayflow intro animation")
    .onAppear(perform: startIfNeeded)
  }

  private var background: some View {
    ZStack {
      Color(red: 0.08, green: 0.085, blue: 0.09)
      RadialGradient(
        colors: [
          variant.accent.opacity(0.16),
          Color.clear,
        ],
        center: .center,
        startRadius: 20,
        endRadius: 520
      )
      LinearGradient(
        colors: [
          Color.white.opacity(0.08),
          Color.clear,
          Color.black.opacity(0.18),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    }
  }

  private func startIfNeeded() {
    guard !hasStarted else { return }
    hasStarted = true
    startDate = Date()
    onStarted()

    let delay = reduceMotion ? 0.85 : variant.baseDuration
    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
      completeIfNeeded(reason: reduceMotion ? "reduced_motion_completed" : "completed")
    }
  }

  private func completeIfNeeded(reason: String) {
    guard !hasCompleted else { return }
    hasCompleted = true
    onCompleted(reason)
  }

  private func draw(in context: inout GraphicsContext, size: CGSize, date: Date) {
    let elapsed = reduceMotion ? variant.baseDuration : date.timeIntervalSince(startDate)
    let progress = min(max(elapsed / variant.baseDuration, 0), 1)
    let eased = easeInOut(progress)
    let phase = reduceMotion ? 0.62 : elapsed
    let center = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
    let scale = min(size.width, size.height) / 720

    drawOrbit(
      in: &context,
      center: center,
      radius: 154 * scale,
      phase: phase * 0.65,
      progress: eased,
      color: variant.accent,
      width: 2.2 * scale
    )
    drawOrbit(
      in: &context,
      center: center,
      radius: 104 * scale,
      phase: -phase * 0.85,
      progress: min(1, eased + 0.18),
      color: variant.secondaryAccent,
      width: 1.6 * scale
    )
    drawSignalLines(in: &context, size: size, phase: phase, progress: eased, scale: scale)
    drawWordmark(in: &context, center: center, progress: eased, scale: scale)
  }

  private func drawOrbit(
    in context: inout GraphicsContext,
    center: CGPoint,
    radius: CGFloat,
    phase: TimeInterval,
    progress: Double,
    color: Color,
    width: CGFloat
  ) {
    var path = Path()
    let start = Double.pi * 1.12 + phase
    let end = start + Double.pi * (1.15 + progress * 0.72)

    path.addArc(
      center: center,
      radius: radius,
      startAngle: .radians(start),
      endAngle: .radians(end),
      clockwise: false
    )

    context.stroke(
      path,
      with: .color(color.opacity(0.22 + progress * 0.62)),
      style: StrokeStyle(lineWidth: max(1, width), lineCap: .round, lineJoin: .round)
    )
  }

  private func drawSignalLines(
    in context: inout GraphicsContext,
    size: CGSize,
    phase: TimeInterval,
    progress: Double,
    scale: CGFloat
  ) {
    let laneCount = 7
    let verticalCenter = size.height * 0.5
    let maxLength = size.width * 0.46

    for index in 0..<laneCount {
      let laneOffset = CGFloat(index - laneCount / 2) * 30 * scale
      let wave = sin(phase * 1.2 + Double(index) * 0.62)
      let reveal = min(1, max(0, progress * 1.35 - Double(index) * 0.055))
      let length = (0.24 + 0.76 * reveal) * maxLength
      let inset = (maxLength - length) * 0.5
      let y = verticalCenter + laneOffset + CGFloat(wave) * 7 * scale
      let x1 = size.width * 0.5 - maxLength * 0.5 + inset
      let x2 = size.width * 0.5 + maxLength * 0.5 - inset

      var path = Path()
      path.move(to: CGPoint(x: x1, y: y))
      path.addCurve(
        to: CGPoint(x: x2, y: y),
        control1: CGPoint(x: x1 + length * 0.28, y: y - 28 * scale * CGFloat(wave)),
        control2: CGPoint(x: x2 - length * 0.28, y: y + 22 * scale * CGFloat(wave))
      )

      let color = index.isMultiple(of: 2) ? variant.accent : variant.secondaryAccent
      context.stroke(
        path,
        with: .color(color.opacity(0.16 + reveal * 0.52)),
        style: StrokeStyle(lineWidth: max(1, 1.3 * scale), lineCap: .round)
      )
    }
  }

  private func drawWordmark(
    in context: inout GraphicsContext,
    center: CGPoint,
    progress: Double,
    scale: CGFloat
  ) {
    let dotRadius = max(3, 4.5 * scale)
    let dotSpacing = max(14, 18 * scale)
    let opacity = 0.18 + progress * 0.58

    for index in 0..<5 {
      let x = center.x + CGFloat(index - 2) * dotSpacing
      let rect = CGRect(
        x: x - dotRadius,
        y: center.y + 104 * scale - dotRadius,
        width: dotRadius * 2,
        height: dotRadius * 2
      )
      var path = Path()
      path.addEllipse(in: rect)
      let color = index == 2 ? variant.accent : Color.white
      context.fill(path, with: .color(color.opacity(opacity)))
    }
  }

  private func easeInOut(_ value: Double) -> Double {
    value * value * (3 - 2 * value)
  }
}

#Preview("Launch Animation") {
  DayflowLineAnimationView(variant: .appLaunch) { _ in }
    .frame(width: 900, height: 600)
}
