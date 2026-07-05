import SwiftUI

struct TabFilterBar: View {
  let categories: [TimelineCategory]
  let idleCategory: TimelineCategory?
  let onManageCategories: () -> Void

  private let editButtonSize: CGFloat = 24
  private let chipButtonSpacing: CGFloat = 8
  private let chipSpacing: CGFloat = 5
  private let rowSpacing: CGFloat = 8

  var body: some View {
    HStack(alignment: .top, spacing: chipButtonSpacing) {
      ChipFlowLayout(spacing: chipSpacing, rowSpacing: rowSpacing) {
        ForEach(displayCategories) { category in
          CategoryChip(category: category, isIdle: category.isIdle)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.top, 1)

      editButton
        .padding(.top, 2)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  struct CategoryChip: View {
    let category: TimelineCategory
    let isIdle: Bool
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
      HStack(spacing: 10) {
        Circle()
          .fill(Color(hex: category.colorHex))
          .frame(width: 10, height: 10)

        Text(category.name)
          .font(
            Font.custom("Figtree", size: 13)
              .weight(.medium)
          )
          .foregroundColor(DayflowDailyToken.text)
          .lineLimit(1)
          .fixedSize()
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 5)
      .frame(height: 26)
      .background(
        DayflowContentToken.secondaryFill(
          colorScheme: colorScheme,
          reduceTransparency: reduceTransparency
        )
      )
      .cornerRadius(6)
      .overlay(
        RoundedRectangle(cornerRadius: 6)
          .inset(by: 0.25)
          .stroke(
            DayflowContentToken.cardBorder(
              colorScheme: colorScheme,
              increaseContrast: false
            ),
            lineWidth: 0.5
          )
      )
    }
  }

  private var displayCategories: [TimelineCategory] {
    if let idleCategory {
      return categories + [idleCategory]
    }
    return categories
  }

  private var editButton: some View {
    CategoryEditCircleButton(
      action: onManageCategories,
      diameter: editButtonSize
    )
  }

}

private struct ChipFlowLayout: Layout {
  var spacing: CGFloat
  var rowSpacing: CGFloat

  func sizeThatFits(
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout ()
  ) -> CGSize {
    let rows = arrangeRows(proposalWidth: proposal.width, subviews: subviews)
    let width = rows.reduce(CGFloat.zero) { max($0, $1.width) }
    let height =
      rows.reduce(CGFloat.zero) { $0 + $1.height }
      + CGFloat(max(0, rows.count - 1)) * rowSpacing
    return CGSize(width: width, height: height)
  }

  func placeSubviews(
    in bounds: CGRect,
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout ()
  ) {
    let rows = arrangeRows(proposalWidth: bounds.width, subviews: subviews)
    var y = bounds.minY

    for row in rows {
      var x = bounds.minX
      for item in row.items {
        item.subview.place(
          at: CGPoint(x: x, y: y),
          proposal: ProposedViewSize(item.size)
        )
        x += item.size.width + spacing
      }
      y += row.height + rowSpacing
    }
  }

  private func arrangeRows(proposalWidth: CGFloat?, subviews: Subviews) -> [Row] {
    let maxWidth = max(1, proposalWidth ?? .greatestFiniteMagnitude)
    var rows: [Row] = []
    var currentItems: [Row.Item] = []
    var currentWidth: CGFloat = 0
    var currentHeight: CGFloat = 0

    for subview in subviews {
      let size = subview.sizeThatFits(.unspecified)
      let item = Row.Item(subview: subview, size: size)
      let candidateWidth = currentItems.isEmpty ? size.width : currentWidth + spacing + size.width

      if candidateWidth > maxWidth && !currentItems.isEmpty {
        rows.append(Row(items: currentItems, width: currentWidth, height: currentHeight))
        currentItems = [item]
        currentWidth = size.width
        currentHeight = size.height
      } else {
        currentItems.append(item)
        currentWidth = candidateWidth
        currentHeight = max(currentHeight, size.height)
      }
    }

    if !currentItems.isEmpty {
      rows.append(Row(items: currentItems, width: currentWidth, height: currentHeight))
    }

    return rows
  }

  private struct Row {
    struct Item {
      let subview: LayoutSubview
      let size: CGSize
    }

    let items: [Item]
    let width: CGFloat
    let height: CGFloat
  }
}
