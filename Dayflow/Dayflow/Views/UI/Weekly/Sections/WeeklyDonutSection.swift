import Charts
import SwiftUI

struct WeeklyDonutSection: View {
  let snapshot: WeeklyDonutSnapshot
  let isLoading: Bool
  let width: CGFloat

  init(
    snapshot: WeeklyDonutSnapshot,
    isLoading: Bool,
    width: CGFloat = Design.cardWidth
  ) {
    self.snapshot = snapshot
    self.isLoading = isLoading
    self.width = width
  }

  private enum Design {
    static let cardWidth: CGFloat = 461
    static let cardHeight: CGFloat = 300
    static let cornerRadius: CGFloat = 4
    static let titleColor = DayflowWeeklyToken.title
    static let contentHorizontalPadding: CGFloat = 18
    static let contentSpacing: CGFloat = 18
    static let donutSize: CGFloat = 205
  }

  private var donutSize: CGFloat {
    min(235, max(176, width * 0.43))
  }

  var body: some View {
    ZStack(alignment: .topLeading) {
      Text("周分布")
        .font(.system(size: 20, weight: .semibold, design: .rounded))
        .foregroundStyle(Design.titleColor)
        .padding(.top, 16)
        .padding(.leading, 18)

      HStack(alignment: .center, spacing: Design.contentSpacing) {
        donutContent

        legendContent
      }
      .padding(.top, 56)
      .padding(.horizontal, Design.contentHorizontalPadding)

    }
    .frame(width: width, height: Design.cardHeight, alignment: .topLeading)
    .dayflowWeeklySectionSurface(cornerRadius: 6)
  }

  @ViewBuilder
  private var donutContent: some View {
    if isLoading {
      ProgressView()
        .frame(width: donutSize, height: donutSize)
    } else if snapshot.items.isEmpty {
      WeeklyDonutEmptyState(size: donutSize)
    } else {
      WeeklyDonutChart(
        snapshot: snapshot,
        size: donutSize
      )
    }
  }

  private var legendContent: some View {
    VStack(alignment: .leading, spacing: 8) {
      ForEach(snapshot.items) { item in
        WeeklyDonutLegendRow(
          item: item,
          totalMinutes: snapshot.totalMinutes
        )
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

private struct WeeklyDonutChart: View {
  let snapshot: WeeklyDonutSnapshot
  let size: CGFloat
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

  private let innerRadiusRatio: CGFloat = 0.62
  private let innerGap: CGFloat = 8

  private var chartSize: CGFloat {
    size - 8
  }

  var body: some View {
    ZStack {
      Circle()
        .fill(DayflowWeeklyToken.donutBaseFill(
          colorScheme: colorScheme,
          reduceTransparency: reduceTransparency
        ))
        .frame(width: size, height: size)
        .shadow(
          color: DayflowWeeklyToken.displayShadow(
            colorScheme: colorScheme,
            reduceTransparency: reduceTransparency
          ),
          radius: 5
        )

      Chart(snapshot.items) { item in
        SectorMark(
          angle: .value("Minutes", item.minutes),
          innerRadius: .ratio(innerRadiusRatio),
          angularInset: 1.5
        )
        .cornerRadius(6)
        .foregroundStyle(Color(hex: item.colorHex))
      }
      .chartLegend(.hidden)
      .frame(width: chartSize, height: chartSize)

      Circle()
        .fill(
          RadialGradient(
            stops: [
              .init(color: .white.opacity(0.35), location: innerRadiusRatio),
              .init(color: .white.opacity(0), location: 1),
            ],
            center: .center,
            startRadius: 0,
            endRadius: chartSize / 2
          )
        )
        .frame(width: chartSize, height: chartSize)
        .allowsHitTesting(false)

      Circle()
        .fill(DayflowWeeklyToken.donutBaseFill(
          colorScheme: colorScheme,
          reduceTransparency: reduceTransparency
        ))
        .frame(
          width: chartSize * innerRadiusRatio - innerGap,
          height: chartSize * innerRadiusRatio - innerGap
        )

      WeeklyDonutCenterContent(totalMinutes: snapshot.totalMinutes)
    }
    .frame(width: size, height: size)
  }
}

private struct WeeklyDonutCenterContent: View {
  let totalMinutes: Int

  private var totalHours: Int { totalMinutes / 60 }
  private var remainingMinutes: Int { totalMinutes % 60 }

  var body: some View {
    VStack(spacing: 4) {
      Text("总计")
        .font(.custom("Figtree-Bold", size: 8))
        .foregroundStyle(Color(hex: "A5A5A5"))

      VStack(spacing: 0) {
        Text("\(totalHours) \(hourLabel)")
          .font(.system(size: 16, weight: .medium, design: .rounded))
          .foregroundStyle(DayflowWeeklyToken.chartText)

        Text("\(remainingMinutes) \(minuteLabel)")
          .font(.system(size: 16, weight: .medium, design: .rounded))
          .foregroundStyle(DayflowWeeklyToken.chartText)
      }
    }
  }

  private var hourLabel: String {
    "小时"
  }

  private var minuteLabel: String {
    "分钟"
  }
}

private struct WeeklyDonutLegendRow: View {
  let item: WeeklyDonutItem
  let totalMinutes: Int

  private var percentageText: String {
    guard totalMinutes > 0 else { return "0%" }
    let share = (Double(item.minutes) / Double(totalMinutes)) * 100
    return "\(Int(share.rounded()))%"
  }

  var body: some View {
    HStack(spacing: 0) {
      HStack(spacing: 8) {
        RoundedRectangle(cornerRadius: 1.5, style: .continuous)
          .fill(Color(hex: item.colorHex))
          .frame(width: 12, height: 8)

        Text(item.name)
          .font(.custom("Figtree-Regular", size: 14))
          .foregroundStyle(DayflowWeeklyToken.chartText)
          .lineLimit(1)
          .layoutPriority(1)
      }

      Spacer(minLength: 8)

      Text(percentageText)
        .font(.custom("Figtree-Regular", size: 14))
        .foregroundStyle(DayflowWeeklyToken.chartSecondaryText)
        .frame(minWidth: 32, alignment: .trailing)
    }
  }
}

private struct WeeklyDonutEmptyState: View {
  let size: CGFloat
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

  var body: some View {
    ZStack {
      Circle()
        .fill(DayflowWeeklyToken.donutBaseFill(
          colorScheme: colorScheme,
          reduceTransparency: reduceTransparency
        ))
        .frame(width: size, height: size)
        .shadow(
          color: DayflowWeeklyToken.displayShadow(
            colorScheme: colorScheme,
            reduceTransparency: reduceTransparency
          ),
          radius: 5
        )

      Circle()
        .stroke(DayflowWeeklyToken.donutRingStroke(colorScheme: colorScheme), lineWidth: 20)
        .frame(width: size - 20, height: size - 20)

      VStack(spacing: 4) {
        Text("总计")
          .font(.custom("Figtree-Bold", size: 8))
          .foregroundStyle(Color(hex: "A5A5A5"))

        Text("暂无活动")
          .font(.system(size: 16, weight: .medium, design: .rounded))
          .foregroundStyle(DayflowWeeklyToken.chartSecondaryText)
      }
    }
    .frame(width: size, height: size)
  }
}

#Preview("Weekly Donut Section", traits: .fixedLayout(width: 488, height: 305)) {
  WeeklyDonutSection(
    snapshot: .figmaPreview,
    isLoading: false
  )
  .padding(16)
  .dayflowWindowBackground()
}
