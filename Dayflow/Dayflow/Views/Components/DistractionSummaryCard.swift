//
//  DistractionSummaryCard.swift
//  Dayflow
//
//  Summary block showing captured vs distracted time and a distraction pattern note
//

import SwiftUI

struct DistractionSummaryCard: View {
  let totalCaptured: String
  let totalDistracted: String
  let distractedRatio: Double
  let patternTitle: String
  let patternDescription: String
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

  init(
    totalCaptured: String,
    totalDistracted: String,
    distractedRatio: Double,
    patternTitle: String = "Main distraction pattern",
    patternDescription: String
  ) {
    self.totalCaptured = totalCaptured
    self.totalDistracted = totalDistracted
    self.distractedRatio = distractedRatio
    self.patternTitle = patternTitle
    self.patternDescription = patternDescription
  }

  private enum Design {
    static let contentWidth: CGFloat = 293
    static let sectionSpacing: CGFloat = 16
    static let rowSpacing: CGFloat = 27
    static let statsSpacing: CGFloat = 24
    static let statsWidth: CGFloat = 130

    static let donutSize: CGFloat = 136
    static let donutInnerMaxSize: CGFloat = 136
    static let donutInnerBottomInset: CGFloat = 4.868

    static let capturedTextColor = DayflowDailyToken.secondaryText
    static let capturedValueColor = DayflowDailyToken.title
    static let distractedTextColor = DayflowDailyToken.distraction
    static let bodyTextColor = DayflowDailyToken.text

    static let labelFont = Font.system(size: 14, weight: .medium, design: .rounded)
    static let valueFont = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let patternTitleFont = Font.custom("Figtree", size: 12).weight(.bold)
    static let patternBodyFont = Font.custom("Figtree", size: 12)
  }

  var body: some View {
    let showPattern = !patternDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

    VStack(alignment: .center, spacing: showPattern ? Design.sectionSpacing : 0) {
      HStack(alignment: .center, spacing: Design.rowSpacing) {
        donut
        statsBlock
      }

      if showPattern {
        patternBlock
      }
    }
    .frame(width: Design.contentWidth, alignment: .center)
  }

  private var donut: some View {
    let clampedRatio = min(max(distractedRatio, 0), 1)
    let innerDiameter = Design.donutInnerMaxSize * sqrt(clampedRatio)
    let innerX = (Design.donutSize - innerDiameter) / 2
    let innerY = Design.donutSize - Design.donutInnerBottomInset - innerDiameter
    let donutFill = DayflowDailyToken.secondaryFill(
      colorScheme: colorScheme,
      reduceTransparency: reduceTransparency
    )

    return ZStack(alignment: .topLeading) {
      Circle()
        .fill(donutFill)
        .overlay(
          Circle()
            .stroke(DayflowDailyToken.separator, lineWidth: 1)
        )
        .frame(width: Design.donutSize, height: Design.donutSize)

      if innerDiameter > 0.5 {
        Circle()
          .fill(
            LinearGradient(
              stops: [
                .init(color: DayflowDailyToken.distraction.opacity(0.20), location: 0),
                .init(color: DayflowDailyToken.distraction.opacity(0.90), location: 0.78306),
                .init(color: DayflowDailyToken.distraction.opacity(0.90), location: 1),
              ],
              startPoint: .leading,
              endPoint: .trailing
            )
          )
          .frame(width: innerDiameter, height: innerDiameter)
          .rotationEffect(.degrees(90))
          .offset(x: innerX, y: innerY)
      }
    }
    .frame(width: Design.donutSize, height: Design.donutSize)
  }

  private var statsBlock: some View {
    VStack(alignment: .leading, spacing: Design.statsSpacing) {
      statText(
        title: "总记录时长",
        value: totalCaptured,
        labelColor: Design.capturedTextColor,
        valueColor: Design.capturedValueColor
      )

      statText(
        title: "分心总时长",
        value: totalDistracted,
        labelColor: Design.distractedTextColor.opacity(0.86),
        valueColor: Design.distractedTextColor
      )
    }
    .frame(width: Design.statsWidth, alignment: .leading)
  }

  private func statText(title: String, value: String, labelColor: Color, valueColor: Color) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(title)
        .font(Design.labelFont)
        .foregroundColor(labelColor)
      Text(value)
        .font(Design.valueFont)
        .foregroundColor(valueColor)
    }
    .lineSpacing(2)
  }

  private var patternBlock: some View {
    VStack(alignment: .leading, spacing: 2) {
      HStack(spacing: 2) {
        Image(systemName: "exclamationmark.triangle.fill")
          .font(.system(size: 13, weight: .semibold))
          .symbolRenderingMode(.hierarchical)
          .foregroundStyle(DayflowDailyToken.distraction)
          .frame(width: 16, height: 16)

        Text(patternTitle)
          .font(Design.patternTitleFont)
          .foregroundColor(Design.bodyTextColor)
      }

      Text(patternDescription)
        .font(Design.patternBodyFont)
        .foregroundColor(Design.bodyTextColor)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }
    .frame(width: Design.contentWidth, alignment: .leading)
  }
}

#Preview("Distraction Summary Card") {
  DistractionSummaryCard(
    totalCaptured: "8小时49分钟",
    totalDistracted: "2小时7分钟",
    distractedRatio: 0.24,
    patternTitle: "主要分心模式",
    patternDescription:
      "YouTube 推荐内容会把注意力从一个视频带到下一个视频，持续占用较长时间。"
  )
  .padding(24)
  .dayflowCard(cornerRadius: 12)
}
