//
//  Day专注SummarySection.swift
//  Dayflow
//
//  专注 section for the Day Summary right rail.
//

import SwiftUI

struct Day专注SummarySection: View {
  let total专注Text: String
  let focusBlocks: [专注Block]
  let isSelectionEmpty: Bool
  let categories: [TimelineCategory]
  let selectedCategoryIDs: Set<UUID>
  let isEditing分类: Bool
  var onEdit分类: () -> Void
  var onToggleCategory: (TimelineCategory) -> Void
  var onDoneEditing: () -> Void

  private enum Design {
    static let sectionSpacing: CGFloat = 12
    static let cardsSpacing: CGFloat = 8
    static let editButtonSize: CGFloat = 20
    static let editorWidth: CGFloat = 358
    static let editor关闭setX: CGFloat = -18
    static let editor关闭setY: CGFloat = 28
    static let titleColor = Color(hex: "333333")
    static let subtitleColor = Color(hex: "707070")
    static let iconColor = Color(hex: "CFC7BE")
  }

  var body: some View {
    VStack(alignment: .leading, spacing: Design.sectionSpacing) {
      header

      if isSelectionEmpty {
        Text("编辑分类来计算专注情况。")
          .font(.custom("Figtree", size: 11))
          .foregroundColor(Design.subtitleColor)
      }

      VStack(spacing: Design.cardsSpacing) {
        Total专注Card(value: total专注Text)

        Longest专注Card(focusBlocks: focusBlocks)
      }
      .opacity(isSelectionEmpty ? 0.45 : 1)
    }
    .overlay(alignment: .topLeading) {
      if isEditing分类 {
        DayCategorySelectionEditor(
          categories: categories,
          selectedCategoryIDs: selectedCategoryIDs,
          helperText: "Pick the categories that count towards 专注",
          onToggle: onToggleCategory,
          onDone: onDoneEditing
        )
        .frame(width: Design.editorWidth, alignment: .leading)
        .offset(x: Design.editor关闭setX, y: Design.editor关闭setY)
        .onTapGesture {}
      }
    }
  }

  private var header: some View {
    HStack(alignment: .center, spacing: 6) {
      Text("你的专注")
        .font(.custom("InstrumentSerif-Regular", size: 22))
        .foregroundColor(Design.titleColor)

      Image(systemName: "info.circle")
        .font(.system(size: 12))
        .foregroundColor(Design.iconColor)

      Spacer()

      CategoryEditCircleButton(
        action: onEdit分类,
        diameter: Design.editButtonSize
      )
    }
  }
}

private struct Total专注Card: View {
  let value: String

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack(spacing: 6) {
        Text("总专注时长")
          .font(.custom("InstrumentSerif-Regular", size: 16))
          .foregroundColor(Color(hex: "333333"))

        Image(systemName: "info.circle")
          .font(.system(size: 12))
          .foregroundColor(Color(hex: "CFC7BE"))

        Spacer()
      }

      Text(value)
        .font(.custom("InstrumentSerif-Regular", size: 34))
        .foregroundColor(Color(hex: "F3854B"))
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color(hex: "F7F7F7"))
    .overlay(
      RoundedRectangle(cornerRadius: 8)
        .stroke(Color.white, lineWidth: 1)
    )
    .clipShape(RoundedRectangle(cornerRadius: 8))
  }
}
