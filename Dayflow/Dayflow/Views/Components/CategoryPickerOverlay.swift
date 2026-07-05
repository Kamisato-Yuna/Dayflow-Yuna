import AppKit
import SwiftUI

struct CategoryPickerOverlay: View {
  let categories: [TimelineCategory]
  let currentCategoryName: String
  var onSelect: (TimelineCategory) -> Void
  var onNavigateToEditor: () -> Void

  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

  private var orderedCategories: [TimelineCategory] {
    let trimmedCurrent = currentCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
      .lowercased()
    let sorted = categories.sorted { lhs, rhs in
      lhs.order < rhs.order
    }

    guard
      let index = sorted.firstIndex(where: {
        $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == trimmedCurrent
      })
    else {
      return sorted
    }

    var reordered = sorted
    let selected = reordered.remove(at: index)
    reordered.insert(selected, at: 0)
    return reordered
  }

  var body: some View {
    VStack(spacing: 12) {
      FlowLayout(spacing: 6, rowSpacing: 8) {
        ForEach(orderedCategories) { category in
          Button {
            onSelect(category)
          } label: {
            CategoryPickerPill(
              category: category,
              isSelected: isSelected(category)
            )
          }
          .buttonStyle(.plain)
          .pointingHandCursor()
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      Rectangle()
        .fill(
          DayflowContentToken.cardBorder(
            colorScheme: colorScheme,
            increaseContrast: NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
          )
        )
        .frame(height: 1)

      helperContent
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .dayflowPopoverSurface(cornerRadius: 6, groupingSpacing: 8)
    .clipShape(
      UnevenRoundedRectangle(
        cornerRadii: .init(
          topLeading: 0,
          bottomLeading: 0,
          bottomTrailing: 0,
          topTrailing: 6
        )
      )
    )
    .overlay(
      UnevenRoundedRectangle(
        cornerRadii: .init(
          topLeading: 0,
          bottomLeading: 0,
          bottomTrailing: 0,
          topTrailing: 6
        )
      )
      .stroke(
        DayflowContentToken.cardBorder(
          colorScheme: colorScheme,
          increaseContrast: NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
        ),
        lineWidth: 1
      )
    )
  }

  private var helperContent: some View {
    let baseFont = Font.custom("Figtree", size: 12)
    let baseColor = Color(nsColor: .secondaryLabelColor)
    let linkColor = DayflowSurfaceAccent.primary
    let linkURL = URL(string: "dayflow://category-editor")!

    var intro = AttributedString(
      "想让 Dayflow 更准确地整理你的活动记录，请在分类说明中补充更多细节，"
    )
    intro.font = baseFont
    intro.foregroundColor = baseColor

    var link = AttributedString("前往设置")
    link.font = baseFont
    link.foregroundColor = linkColor
    link.underlineStyle = .single
    link.link = linkURL

    var period = AttributedString("。")
    period.font = baseFont
    period.foregroundColor = baseColor

    let attributed = intro + link + period

    return Text(attributed)
      .fixedSize(horizontal: false, vertical: true)
      .environment(
        \.openURL,
        OpenURLAction { url in
          guard url == linkURL else { return .systemAction }
          onNavigateToEditor()
          return .handled
        })
  }

  private func isSelected(_ category: TimelineCategory) -> Bool {
    let trimmedCurrent = currentCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
      .lowercased()
    return category.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
      == trimmedCurrent
  }
}

private struct CategoryPickerPill: View {
  let category: TimelineCategory
  let isSelected: Bool

  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

  private var categoryColor: Color {
    if let nsColor = NSColor(hex: category.colorHex) {
      return Color(nsColor: nsColor)
    }
    return Color.gray
  }

  private var background: some View {
    Group {
      if isSelected {
        LinearGradient(
          colors: [
            DayflowSurfaceAccent.primary.opacity(colorScheme == .dark ? 0.30 : 0.18),
            DayflowSurfaceAccent.primary.opacity(colorScheme == .dark ? 0.18 : 0.10),
          ],
          startPoint: .leading,
          endPoint: .trailing
        )
      } else {
        DayflowContentToken.secondaryFill(
          colorScheme: colorScheme,
          reduceTransparency: reduceTransparency
        )
      }
    }
  }

  private var borderColor: Color {
    if isSelected {
      return DayflowSurfaceAccent.primary.opacity(colorScheme == .dark ? 0.86 : 0.62)
    }
    return DayflowContentToken.cardBorder(
      colorScheme: colorScheme,
      increaseContrast: NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
    )
  }

  var body: some View {
    HStack(spacing: 10) {
      Circle()
        .fill(categoryColor)
        .frame(width: 10, height: 10)

      Text(category.name)
        .font(
          Font.custom("Figtree", size: 13)
            .weight(.medium)
        )
        .foregroundColor(Color(nsColor: .labelColor))
        .lineLimit(1)
    }
    .padding(.horizontal, 6)
    .padding(.vertical, 5)
    .background(background)
    .overlay(
      RoundedRectangle(cornerRadius: 6)
        .inset(by: 0.25)
        .stroke(style: strokeStyle)
        .foregroundColor(borderColor)
    )
    .cornerRadius(6)
  }

  private var strokeStyle: StrokeStyle {
    if category.isIdle && !isSelected {
      return StrokeStyle(lineWidth: 0.75, dash: [2, 2])
    }
    return StrokeStyle(lineWidth: 0.5)
  }
}

private struct FlowLayout: Layout {
  var spacing: CGFloat = 6
  var rowSpacing: CGFloat = 6

  func makeCache(subviews: Subviews) {
    ()
  }

  func updateCache(_ cache: inout (), subviews: Subviews) {}

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    let maxWidth = proposal.width ?? .infinity
    var rowWidth: CGFloat = 0
    var rowHeight: CGFloat = 0
    var totalHeight: CGFloat = 0
    var maxRowWidth: CGFloat = 0

    for subview in subviews {
      let size = subview.sizeThatFits(.unspecified)
      let proposedWidth = size.width

      if rowWidth > 0 && rowWidth + spacing + proposedWidth > maxWidth {
        totalHeight += rowHeight + rowSpacing
        maxRowWidth = max(maxRowWidth, rowWidth)
        rowWidth = proposedWidth
        rowHeight = size.height
      } else {
        rowWidth = rowWidth == 0 ? proposedWidth : rowWidth + spacing + proposedWidth
        rowHeight = max(rowHeight, size.height)
      }
    }

    maxRowWidth = max(maxRowWidth, rowWidth)
    totalHeight += rowHeight

    return CGSize(width: maxRowWidth, height: totalHeight)
  }

  func placeSubviews(
    in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()
  ) {
    var origin = CGPoint(x: bounds.minX, y: bounds.minY)
    var currentRowHeight: CGFloat = 0

    for subview in subviews {
      let size = subview.sizeThatFits(.unspecified)
      if origin.x > bounds.minX && origin.x + size.width > bounds.maxX {
        origin.x = bounds.minX
        origin.y += currentRowHeight + rowSpacing
        currentRowHeight = 0
      }

      subview.place(
        at: CGPoint(x: origin.x, y: origin.y),
        proposal: ProposedViewSize(width: size.width, height: size.height)
      )

      origin.x += size.width + spacing
      currentRowHeight = max(currentRowHeight, size.height)
    }
  }
}
