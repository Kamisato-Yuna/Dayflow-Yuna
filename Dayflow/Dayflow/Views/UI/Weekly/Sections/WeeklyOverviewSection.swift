import AppKit
import SwiftUI

struct WeeklyOverviewSection: View {
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

  let snapshot: WeeklyOverviewSnapshot

  private enum Design {
    static let sectionWidth: CGFloat = 958
    static let cornerRadius: CGFloat = 4
    static let titleColor = DayflowWeeklyToken.title
    static let bodyTextColor = DayflowWeeklyToken.text
    static let secondaryTextColor = DayflowWeeklyToken.secondaryText
    static let accentUnderline = DayflowWeeklyToken.accent
    static let summaryDividerX: CGFloat = 295

    static let topPadding = EdgeInsets(top: 32, leading: 40, bottom: 32, trailing: 40)
    static let headerSpacing: CGFloat = 32
    static let chartSpacing: CGFloat = 28
    static let chartLabelGap: CGFloat = 8
    static let chartRowsSpacing: CGFloat = 2
    static let axisSpacing: CGFloat = 8
    static let rowHeight: CGFloat = 18
    static let segmentHeight: CGFloat = 12
    static let dayLabelWidth: CGFloat = 26
    static let barsWidth: CGFloat = 836
    static let axisWidth: CGFloat = 837
    static let footerHeight: CGFloat = 65

    static let dayLabels = [
      "9点", "10点", "11点", "12点", "13点", "14点", "15点", "16点", "17点", "18点",
    ]
  }

  private var topCardShape: UnevenRoundedRectangle {
    UnevenRoundedRectangle(
      cornerRadii: .init(
        topLeading: Design.cornerRadius,
        bottomLeading: 0,
        bottomTrailing: 0,
        topTrailing: Design.cornerRadius
      ),
      style: .continuous
    )
  }

  private var footerShape: UnevenRoundedRectangle {
    UnevenRoundedRectangle(
      cornerRadii: .init(
        topLeading: 0,
        bottomLeading: Design.cornerRadius,
        bottomTrailing: Design.cornerRadius,
        topTrailing: 0
      ),
      style: .continuous
    )
  }

  var body: some View {
    VStack(spacing: 0) {
      topPanel
      footerPanel
    }
    .frame(maxWidth: Design.sectionWidth, alignment: .leading)
  }

  private var topPanel: some View {
    VStack(alignment: .leading, spacing: Design.headerSpacing) {
      HStack(alignment: .bottom) {
        Text("时间分布")
          .font(.system(size: 20, weight: .semibold, design: .rounded))
          .foregroundStyle(Design.titleColor)

        Spacer(minLength: 20)

        WeeklyOverviewTabStrip()
      }

      WeeklyOverviewTimelineChart(snapshot: snapshot)
    }
    .padding(Design.topPadding)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background {
      if reduceTransparency {
        topCardShape.fill(DayflowWeeklyToken.cardFill(
          colorScheme: colorScheme,
          reduceTransparency: reduceTransparency
        ))
      } else {
        topCardShape.fill(.regularMaterial)
        topCardShape.fill(DayflowWeeklyToken.cardFill(
          colorScheme: colorScheme,
          reduceTransparency: reduceTransparency
        ))
      }
    }
    .clipShape(topCardShape)
    .overlay {
      topCardShape
        .stroke(DayflowWeeklyToken.border(
          colorScheme: colorScheme,
          increaseContrast: NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
        ), lineWidth: 1)
    }
  }

  private var footerPanel: some View {
    HStack(spacing: 0) {
      WeeklyOverviewSummaryGroup(
        title: "上下文切换",
        metrics: [
          .init(label: "总计", value: "\(snapshot.contextSwitchTotal) 次"),
          .init(label: "平均", value: "\(snapshot.contextSwitchAverage) 次 / 天"),
        ]
      )
      .frame(width: Design.summaryDividerX, alignment: .leading)

      WeeklyOverviewSummaryGroup(
        title: "专注",
        metrics: [
          .init(label: "总时长", value: compactDurationText(snapshot.totalFocusMinutes)),
          .init(label: "最长时段", value: longestFocusText),
          .init(label: "主要专注", value: primaryFocusText),
        ]
      )
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .frame(height: Design.footerHeight)
    .background(
      HStack(spacing: 0) {
        DayflowWeeklyToken.secondaryFill(
          colorScheme: colorScheme,
          reduceTransparency: reduceTransparency
        )
          .frame(width: Design.summaryDividerX)
        DayflowWeeklyToken.secondaryFill(
          colorScheme: colorScheme,
          reduceTransparency: reduceTransparency
        )
      }
    )
    .clipShape(footerShape)
    .overlay {
      GeometryReader { geometry in
        let width = geometry.size.width
        let height = geometry.size.height
        let radius = Design.cornerRadius

        Path { path in
          path.move(to: CGPoint(x: 0, y: 0))
          path.addLine(to: CGPoint(x: 0, y: height - radius))
          path.addQuadCurve(
            to: CGPoint(x: radius, y: height),
            control: CGPoint(x: 0, y: height)
          )

          path.move(to: CGPoint(x: radius, y: height))
          path.addLine(to: CGPoint(x: width - radius, y: height))

          path.move(to: CGPoint(x: width, y: 0))
          path.addLine(to: CGPoint(x: width, y: height - radius))
          path.addQuadCurve(
            to: CGPoint(x: width - radius, y: height),
            control: CGPoint(x: width, y: height)
          )

          path.move(to: CGPoint(x: Design.summaryDividerX, y: 0))
          path.addLine(to: CGPoint(x: Design.summaryDividerX, y: height))
        }
        .stroke(DayflowWeeklyToken.border(
          colorScheme: colorScheme,
          increaseContrast: NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
        ), lineWidth: 1)
      }
    }
  }

  private var longestFocusText: String {
    guard let longestFocus = snapshot.longestFocus else {
      return "暂无专注记录"
    }
    return "\(compactDurationText(longestFocus.minutes)), \(longestFocus.weekdayName)"
  }

  private var primaryFocusText: String {
    guard let primaryFocus = snapshot.primaryFocus else {
      return "暂无专注记录"
    }
    return "\(primaryFocus.name), \(compactDurationText(primaryFocus.minutes))"
  }

  private func compactDurationText(_ minutes: Int) -> String {
    let hours = minutes / 60
    let remainingMinutes = minutes % 60

    if hours > 0 && remainingMinutes > 0 {
      return "\(hours) 小时 \(remainingMinutes) 分钟"
    }
    if hours > 0 {
      return "\(hours) 小时"
    }
    return "\(remainingMinutes) 分钟"
  }
}

private struct WeeklyOverviewTimelineChart: View {
  let snapshot: WeeklyOverviewSnapshot

  private enum Design {
    static let chartSpacing: CGFloat = 28
    static let rowSpacing: CGFloat = 2
    static let axisSpacing: CGFloat = 8
    static let dayLabelWidth: CGFloat = 26
    static let labelGap: CGFloat = 8
    static let barsWidth: CGFloat = 836
    static let axisWidth: CGFloat = 837
    static let rowHeight: CGFloat = 18
    static let segmentHeight: CGFloat = 12
    static let axisLabels = [
      "9点", "10点", "11点", "12点", "13点", "14点", "15点", "16点", "17点", "18点",
    ]
  }

  var body: some View {
    VStack(alignment: .leading, spacing: Design.chartSpacing) {
      HStack(alignment: .top, spacing: Design.labelGap) {
        VStack(alignment: .leading, spacing: 6) {
          ForEach(snapshot.rows) { row in
            Text(row.label)
              .font(.custom("Figtree-Regular", size: 12))
              .foregroundStyle(DayflowWeeklyToken.chartText)
              .frame(width: Design.dayLabelWidth, height: 14, alignment: .leading)
          }
        }

        VStack(alignment: .leading, spacing: Design.axisSpacing) {
          VStack(spacing: Design.rowSpacing) {
            ForEach(snapshot.rows) { row in
              WeeklyOverviewTimelineBar(row: row)
            }
          }

          HStack {
            ForEach(Design.axisLabels, id: \.self) { label in
              Text(label)
                .font(.custom("Figtree-Regular", size: 10))
                .foregroundStyle(DayflowWeeklyToken.chartSecondaryText)
              if label != Design.axisLabels.last {
                Spacer(minLength: 0)
              }
            }
          }
          .frame(width: Design.axisWidth, alignment: .leading)
        }
      }

      HStack(spacing: 25) {
        ForEach(snapshot.legendItems) { item in
          HStack(spacing: 6) {
            Text(item.name)
              .font(.custom("Figtree-Regular", size: 10))
              .foregroundStyle(DayflowWeeklyToken.chartText)

            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
              .fill(Color(hex: item.colorHex))
              .frame(width: 12, height: 8)
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .center)
      .frame(minHeight: 8)
    }
  }
}

private struct WeeklyOverviewTimelineBar: View {
  let row: WeeklyOverviewRow
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

  private enum Design {
    static let barWidth: CGFloat = 836
    static let rowHeight: CGFloat = 18
    static let segmentHeight: CGFloat = 12
    static let visibleStartMinute = 9.0 * 60.0
    static let visibleEndMinute = 18.0 * 60.0
  }

  var body: some View {
    ZStack(alignment: .leading) {
      RoundedRectangle(cornerRadius: 2, style: .continuous)
        .fill(DayflowWeeklyToken.emptyCellFill(
          colorScheme: colorScheme,
          reduceTransparency: reduceTransparency
        ))
        .frame(width: Design.barWidth, height: Design.rowHeight)
        .overlay {
          RoundedRectangle(cornerRadius: 2, style: .continuous)
            .stroke(DayflowWeeklyToken.chartDivider(colorScheme: colorScheme), lineWidth: 0.5)
        }

      ForEach(row.segments) { segment in
        segmentView(segment)
      }
    }
    .frame(width: Design.barWidth, height: Design.rowHeight, alignment: .leading)
  }

  private func segmentView(_ segment: WeeklyOverviewSegment) -> some View {
    let visibleDuration = Design.visibleEndMinute - Design.visibleStartMinute
    let xProgress = (segment.startMinute - Design.visibleStartMinute) / visibleDuration
    let widthProgress = (segment.endMinute - segment.startMinute) / visibleDuration
    let segmentX = max(0, CGFloat(xProgress) * Design.barWidth)
    let segmentWidth = max(2, (CGFloat(widthProgress) * Design.barWidth) - 2)

    return RoundedRectangle(cornerRadius: 1, style: .continuous)
      .fill(gradient(for: segment.colorHex))
      .frame(width: segmentWidth, height: Design.segmentHeight)
      .offset(x: segmentX + 1)
  }

  private func gradient(for colorHex: String) -> LinearGradient {
    let baseColor = NSColor(hex: colorHex) ?? .systemGray
    let leading = baseColor.blended(with: 0.22, of: .white) ?? baseColor
    let trailing = baseColor.blended(with: 0.08, of: .black) ?? baseColor

    return LinearGradient(
      colors: [Color(nsColor: leading), Color(nsColor: trailing)],
      startPoint: .leading,
      endPoint: .trailing
    )
  }
}

private struct WeeklyOverviewTabStrip: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack(spacing: 12) {
        Text("全部")
          .font(.custom("Figtree-Bold", size: 12))
          .foregroundStyle(DayflowWeeklyToken.chartText)

        Text("最长专注时段")
          .font(.custom("Figtree-Medium", size: 12))
          .foregroundStyle(DayflowWeeklyToken.chartSecondaryText)

        Text("最少上下文切换")
          .font(.custom("Figtree-Medium", size: 12))
          .foregroundStyle(DayflowWeeklyToken.chartSecondaryText)

        Text("最多上下文切换")
          .font(.custom("Figtree-Medium", size: 12))
          .foregroundStyle(DayflowWeeklyToken.chartSecondaryText)
      }

      Rectangle()
        .fill(Color(hex: "F0A54D"))
        .frame(width: 22, height: 1)
    }
  }
}

private struct WeeklyOverviewSummaryGroup: View {
  let title: String
  let metrics: [WeeklyOverviewSummaryMetric]

  var body: some View {
    HStack(alignment: .top, spacing: 20) {
      Text(title)
        .font(.system(size: 16, weight: .medium, design: .rounded))
        .foregroundStyle(DayflowWeeklyToken.title)

      HStack(alignment: .top, spacing: 20) {
        ForEach(metrics) { metric in
          VStack(alignment: .leading, spacing: 8) {
            Text(metric.label)
              .font(.custom("Figtree-Regular", size: 12))
              .foregroundStyle(DayflowWeeklyToken.chartSecondaryText)

            Text(metric.value)
              .font(.system(size: 18, weight: .semibold, design: .rounded))
              .foregroundStyle(DayflowWeeklyToken.chartText)
              .lineLimit(1)
          }
        }
      }
    }
    .padding(.horizontal, 24)
    .padding(.vertical, 18)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
  }
}

private struct WeeklyOverviewSummaryMetric: Identifiable {
  let id = UUID()
  let label: String
  let value: String
}

extension WeeklyOverviewSnapshot {
  static let figmaPreview = WeeklyOverviewSnapshot(
    rows: [
      WeeklyOverviewRow(
        id: "mon",
        label: "周一",
        weekdayName: "星期一",
        segments: [
          segment("mon-alignment-1", "alignment", "6CDACD", 555, 573),
          segment("mon-testing", "testing", "FFA189", 574, 725),
          segment("mon-general-1", "general", "BFB6AE", 727, 771),
          segment("mon-alignment-2", "alignment", "6CDACD", 773, 873),
          segment("mon-general-2", "general", "BFB6AE", 875, 919),
          segment("mon-research", "research", "93BCFF", 921, 1065),
        ]
      ),
      WeeklyOverviewRow(
        id: "tue",
        label: "周二",
        weekdayName: "星期二",
        segments: [
          segment("tue-testing", "testing", "FFA189", 547, 731),
          segment("tue-design", "design", "DE9DFC", 732, 760),
          segment("tue-alignment", "alignment", "6CDACD", 761, 880),
          segment("tue-research", "research", "93BCFF", 881, 1040),
        ]
      ),
      WeeklyOverviewRow(
        id: "wed",
        label: "周三",
        weekdayName: "星期三",
        segments: [
          segment("wed-alignment-1", "alignment", "6CDACD", 555, 572),
          segment("wed-design-1", "design", "DE9DFC", 574, 754),
          segment("wed-research-1", "research", "93BCFF", 755, 773),
          segment("wed-design-2", "design", "DE9DFC", 774, 815),
          segment("wed-research-2", "research", "93BCFF", 816, 856),
          segment("wed-design-3", "design", "DE9DFC", 858, 899),
          segment("wed-alignment-2", "alignment", "6CDACD", 900, 1017),
        ]
      ),
      WeeklyOverviewRow(
        id: "thu",
        label: "周四",
        weekdayName: "星期四",
        segments: [
          segment("thu-alignment-1", "alignment", "6CDACD", 542, 603),
          segment("thu-design-1", "design", "DE9DFC", 604, 736),
          segment("thu-testing", "testing", "FFA189", 737, 782),
          segment("thu-general", "general", "BFB6AE", 783, 826),
          segment("thu-design-2", "design", "DE9DFC", 827, 871),
          segment("thu-alignment-2", "alignment", "6CDACD", 872, 1010),
          segment("thu-design-3", "design", "DE9DFC", 1011, 1038),
          segment("thu-alignment-3", "alignment", "6CDACD", 1039, 1052),
        ]
      ),
      WeeklyOverviewRow(
        id: "fri",
        label: "周五",
        weekdayName: "星期五",
        segments: [
          segment("fri-alignment-1", "alignment", "6CDACD", 547, 567),
          segment("fri-design", "design", "DE9DFC", 569, 766),
          segment("fri-alignment-2", "alignment", "6CDACD", 767, 863),
          segment("fri-testing", "testing", "FFA189", 864, 1007),
          segment("fri-alignment-3", "alignment", "6CDACD", 1008, 1019),
        ]
      ),
    ],
    legendItems: [
      WeeklyOverviewLegendItem(id: "research", name: "研究", colorHex: "93BCFF"),
      WeeklyOverviewLegendItem(id: "design", name: "设计", colorHex: "DE9DFC"),
      WeeklyOverviewLegendItem(id: "alignment", name: "协作", colorHex: "6CDACD"),
      WeeklyOverviewLegendItem(id: "testing", name: "测试", colorHex: "FFA189"),
      WeeklyOverviewLegendItem(id: "general", name: "常规", colorHex: "BFB6AE"),
    ],
    contextSwitchTotal: 52,
    contextSwitchAverage: 7,
    totalFocusMinutes: 1478,
    longestFocus: WeeklyOverviewFocusSummary(weekdayName: "星期三", minutes: 245),
    primaryFocus: WeeklyOverviewCategorySummary(
      name: "设计",
      minutes: 734,
      colorHex: "DE9DFC"
    )
  )

  fileprivate static func segment(
    _ id: String,
    _ categoryKey: String,
    _ colorHex: String,
    _ startMinute: Double,
    _ endMinute: Double
  ) -> WeeklyOverviewSegment {
    WeeklyOverviewSegment(
      id: id,
      categoryKey: categoryKey,
      colorHex: colorHex,
      startMinute: startMinute,
      endMinute: endMinute
    )
  }
}

#Preview("Weekly Overview Section", traits: .fixedLayout(width: 958, height: 339)) {
  WeeklyOverviewSection(snapshot: .figmaPreview)
    .padding(24)
    .dayflowWindowBackground()
}
