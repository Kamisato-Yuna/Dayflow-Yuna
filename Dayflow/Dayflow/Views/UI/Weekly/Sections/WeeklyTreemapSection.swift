import SwiftUI

let weeklyTreemapContentCoordinateSpace = "weekly-treemap-content"

struct WeeklyTreemapSection: View {
  let snapshot: WeeklyTreemapSnapshot
  let width: CGFloat
  let paletteColorScheme: ColorScheme?
  @Environment(\.colorScheme) private var colorScheme
  @State var hoveredLeaf: WeeklyTreemapHoverState?

  init(
    snapshot: WeeklyTreemapSnapshot,
    width: CGFloat = Design.sectionSize.width,
    paletteColorScheme: ColorScheme? = nil
  ) {
    self.snapshot = snapshot
    self.width = width
    self.paletteColorScheme = paletteColorScheme
  }

  enum Design {
    static let sectionSize = CGSize(width: 958, height: 549)
    static let cornerRadius: CGFloat = 4
    static let contentSize = CGSize(width: 797, height: 400)
    static let categoryGap: CGFloat = 6
    static let hoverCardSize = CGSize(width: 176, height: 92)
    static let hoverCardGap: CGFloat = 10
  }

  private var contentWidth: CGFloat {
    max(
      1,
      width - DayflowWeeklySectionChrome.titleLeading - DayflowWeeklySectionChrome.contentTrailing
    )
  }

  private var resolvedPaletteColorScheme: ColorScheme {
    paletteColorScheme ?? colorScheme
  }

  var body: some View {
    VStack(alignment: .leading, spacing: DayflowWeeklySectionChrome.titleToContentSpacing) {
      Text(snapshot.title)
        .font(.system(size: 20, weight: .semibold, design: .rounded))
        .foregroundStyle(DayflowWeeklyToken.title)
        .lineLimit(1)
        .minimumScaleFactor(0.8)

      contentLayer
        .frame(width: contentWidth, height: Design.contentSize.height)
    }
    .padding(.top, DayflowWeeklySectionChrome.titleTop)
    .padding(.leading, DayflowWeeklySectionChrome.titleLeading)
    .padding(.trailing, DayflowWeeklySectionChrome.contentTrailing)
    .padding(.bottom, DayflowWeeklySectionChrome.contentBottom)
    .frame(width: width, height: Design.sectionSize.height, alignment: .topLeading)
    .dayflowWeeklySectionSurface(cornerRadius: 6)
  }

  var contentLayer: some View {
    GeometryReader { proxy in
      let placements = SquarifiedTreemapLayout.place(
        snapshot.categories,
        value: { $0.weight },
        order: WeeklyTreemapCategory.displayOrder,
        in: CGRect(origin: .zero, size: proxy.size),
        gap: Design.categoryGap
      )

      ZStack(alignment: .topLeading) {
        ForEach(placements) { placement in
          WeeklyTreemapCategoryCard(
            category: placement.item,
            colorScheme: resolvedPaletteColorScheme,
            onLeafHover: { state in
              withAnimation(.easeOut(duration: 0.14)) {
                hoveredLeaf = state
              }
            }
          )
          .frame(width: placement.frame.width, height: placement.frame.height)
          .offset(x: placement.frame.minX, y: placement.frame.minY)
        }

        if let hoveredLeaf {
          WeeklyTreemapHoverCard(
            app: hoveredLeaf.app,
            palette: hoveredLeaf.palette,
            colorScheme: resolvedPaletteColorScheme
          )
          .frame(width: Design.hoverCardSize.width, height: Design.hoverCardSize.height)
          .offset(
            x: hoverCardOrigin(for: hoveredLeaf.frame, in: proxy.size).x,
            y: hoverCardOrigin(for: hoveredLeaf.frame, in: proxy.size).y
          )
          .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .center)))
          .zIndex(10)
          .allowsHitTesting(false)
        }
      }
      .coordinateSpace(name: weeklyTreemapContentCoordinateSpace)
    }
  }

  func hoverCardOrigin(for frame: CGRect, in size: CGSize) -> CGPoint {
    let cardWidth = Design.hoverCardSize.width
    let cardHeight = Design.hoverCardSize.height

    let centeredX = frame.midX - (cardWidth / 2)
    let x = min(max(centeredX, 0), size.width - cardWidth)

    let preferredAboveY = frame.minY - cardHeight - Design.hoverCardGap
    if preferredAboveY >= 0 {
      return CGPoint(x: x, y: preferredAboveY)
    }

    let belowY = frame.maxY + Design.hoverCardGap
    let clampedBelowY = min(belowY, size.height - cardHeight)
    return CGPoint(x: x, y: max(clampedBelowY, 0))
  }
}
