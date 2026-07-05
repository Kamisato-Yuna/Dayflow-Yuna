//
//  DayDistractionSummarySection.swift
//  Dayflow
//
//  Distraction section for the Day Summary right rail.
//

import SwiftUI

struct DayDistractionSummarySection: View {
  let totalCapturedText: String
  let totalDistractedText: String
  let distractedRatio: Double
  let patternTitle: String
  let patternDescription: String
  let isSelectionEmpty: Bool
  let categories: [TimelineCategory]
  let selectedCategoryIDs: Set<UUID>
  let isEditingCategories: Bool
  var onEditCategories: () -> Void
  var onToggleCategory: (TimelineCategory) -> Void
  var onDoneEditing: () -> Void

  private enum Design {
    static let sectionSpacing: CGFloat = 16
    static let editButtonSize: CGFloat = 20
    static let editorWidth: CGFloat = 358
    static let editorOffsetX: CGFloat = -18
    static let editorOffsetY: CGFloat = 28
    static let titleColor = DayflowDailyToken.title
    static let subtitleColor = DayflowDailyToken.secondaryText
  }

  var body: some View {
    VStack(alignment: .leading, spacing: Design.sectionSpacing) {
      header

      if isSelectionEmpty {
        Text("编辑分类以计算分心时间。")
          .font(.custom("Figtree", size: 11))
          .foregroundColor(Design.subtitleColor)
      }

      DistractionSummaryCard(
        totalCaptured: totalCapturedText,
        totalDistracted: totalDistractedText,
        distractedRatio: distractedRatio,
        patternTitle: patternTitle,
        patternDescription: patternDescription
      )
      .frame(maxWidth: .infinity)
      .opacity(isSelectionEmpty ? 0.45 : 1)
    }
    .overlay(alignment: .topLeading) {
      if isEditingCategories {
        DayCategorySelectionEditor(
          categories: categories,
          selectedCategoryIDs: selectedCategoryIDs,
          helperText: "选择计入分心的分类",
          onToggle: onToggleCategory,
          onDone: onDoneEditing
        )
        .frame(width: Design.editorWidth, alignment: .leading)
        .offset(x: Design.editorOffsetX, y: Design.editorOffsetY)
        .onTapGesture {}
      }
    }
  }

  private var header: some View {
    HStack(alignment: .center, spacing: 6) {
      Text("目前分心情况")
        .font(.system(size: 22, weight: .semibold, design: .rounded))
        .foregroundColor(Design.titleColor)

      Spacer()

      CategoryEditCircleButton(
        action: onEditCategories,
        diameter: Design.editButtonSize
      )
    }
  }
}
