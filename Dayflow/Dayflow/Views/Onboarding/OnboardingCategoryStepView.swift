//
//  OnboardingCategoryStepView.swift
//  Dayflow
//
//  Onboarding step for editing category names and descriptions.
//  Matches the Figma design: two-column layout, inline card editing,
//  no color picker stage.
//

import SwiftUI

struct OnboardingCategoryStepView: View {
  let onBack: () -> Void
  let onNext: () -> Void
  @EnvironmentObject private var categoryStore: CategoryStore

  @State private var editingCategoryID: UUID?
  @State private var draftName: String = ""
  @State private var pendingDeleteCategory: TimelineCategory?

  // Analytics counters for the completion summary
  @State private var renameCount = 0
  @State private var addCount = 0
  @State private var colorChangeCount = 0
  @State private var deleteCount = 0

  private var categories: [TimelineCategory] {
    categoryStore.editableCategories
  }

  private var canAddMore: Bool {
    categories.count < 20
  }

  private var canContinue: Bool {
    !categories.isEmpty
  }

  var body: some View {
    VStack(spacing: 0) {
      Spacer().frame(height: 80)

      GeometryReader { proxy in
        let totalWidth = proxy.size.width - 160  // account for horizontal padding
        let leftWidth = totalWidth * 0.38
        let rightWidth = totalWidth * 0.55

        HStack(alignment: .top, spacing: 40) {
          instructionsColumn
            .frame(width: leftWidth, alignment: .leading)

          categoryCardsColumn
            .frame(width: rightWidth, alignment: .leading)
        }
        .padding(.horizontal, 80)
      }

      Spacer()

      buttonRow
        .padding(.bottom, 40)
        .padding(.trailing, 80)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .alert(
      "确认删除分类？",
      isPresented: deleteAlertBinding,
      presenting: pendingDeleteCategory
    ) { category in
      Button("删除", role: .destructive) {
        deleteCategory(category)
      }
      Button("取消", role: .cancel) {
        pendingDeleteCategory = nil
      }
    } message: { category in
      Text("“\(category.name)” 会从你的新手引导分类中移除。")
    }
  }

  // MARK: - Left Column

  private var instructionsColumn: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("帮助 Dayflow 理解你的工作流")
        .font(.custom("InstrumentSerif-Regular", size: 28))
        .foregroundColor(.black)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.bottom, 24)

      Text("Dayflow 会根据你提供的分类整理活动。")
        .font(.custom("Figtree", size: 14).weight(.medium))
        .foregroundColor(Color(hex: "5B5B5B"))
        .fixedSize(horizontal: false, vertical: true)

      Text(
        "以下是为你的工作准备的默认分类。填写更贴合你的内容有助于 Dayflow 更准确地理解你的行为。"
      )
      .font(.custom("Figtree", size: 14).weight(.medium))
      .foregroundColor(Color(hex: "5B5B5B"))
      .fixedSize(horizontal: false, vertical: true)

      Text("你可以随时自定义或新增分类。")
        .font(.custom("Figtree", size: 14).weight(.medium))
        .foregroundColor(Color(hex: "5B5B5B"))
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  // MARK: - Right Column

  private var categoryCardsColumn: some View {
    ScrollView(showsIndicators: false) {
      VStack(spacing: 12) {
        ForEach(categories) { category in
          if editingCategoryID == category.id {
            editingCard(for: category)
          } else {
            readOnlyCard(for: category)
          }
        }

        addCategoryButton
      }
      .padding(5)  // prevent shadow clipping
    }
  }

  // MARK: - Editing Card

  private func editingCard(for category: TimelineCategory) -> some View {
    HStack(spacing: 8) {
      colorSwatch(hex: category.colorHex)

      TextField("分类名称", text: $draftName)
        .font(.custom("Figtree", size: 12).weight(.bold))
        .textFieldStyle(.plain)
        .foregroundColor(.black)

      Spacer()

      Button {
        saveEdits(for: category)
      } label: {
        Image(systemName: "checkmark.circle.fill")
          .font(.system(size: 16))
          .foregroundColor(Color(hex: "4CAF50"))
      }
      .buttonStyle(.plain)
      .pointingHandCursor()

      if !category.isSystem {
        Button {
          requestDelete(category)
        } label: {
          Image("CategoriesDelete")
            .resizable()
            .frame(width: 16, height: 16)
            .accessibilityLabel("删除分类")
        }
        .buttonStyle(.plain)
        .pointingHandCursor()
      }

      Button {
        cancelEditing()
      } label: {
        Image(systemName: "xmark.circle.fill")
          .font(.system(size: 16))
          .foregroundColor(Color(hex: "F44336"))
      }
      .buttonStyle(.plain)
      .pointingHandCursor()
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 10)
    .dayflowOnboardingTextField()
  }

  // MARK: - Read-Only Card

  private func readOnlyCard(for category: TimelineCategory) -> some View {
    HStack(spacing: 8) {
      colorSwatch(hex: category.colorHex)

      Text(category.name)
        .font(.custom("Figtree", size: 12).weight(.bold))
        .foregroundColor(.black)

      Spacer()

      if !category.isSystem {
        HStack(spacing: 10) {
          Button {
            startEditing(category)
          } label: {
            Image(systemName: "pencil")
              .font(.system(size: 12))
              .foregroundColor(.black.opacity(0.4))
          }
          .buttonStyle(.plain)
          .pointingHandCursor()

          Button {
            requestDelete(category)
          } label: {
            Image("CategoriesDelete")
              .resizable()
              .frame(width: 16, height: 16)
            .accessibilityLabel("删除分类")
          }
          .buttonStyle(.plain)
          .pointingHandCursor()
        }
      }
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 10)
    .dayflowCard(cornerRadius: 8)
    .onTapGesture {
      if !category.isSystem {
        startEditing(category)
      }
    }
    .pointingHandCursor(enabled: !category.isSystem)
  }

  // MARK: - Color Swatch

  private func colorSwatch(hex: String) -> some View {
    RoundedRectangle(cornerRadius: 6)
      .fill(Color(hex: hex))
      .frame(width: 16, height: 16)
      .overlay(
        RoundedRectangle(cornerRadius: 6)
          .stroke(Color(nsColor: .windowBackgroundColor), lineWidth: 1.5)
      )
      .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 0)
  }

  // MARK: - Add Category Button

  private var addCategoryButton: some View {
    Button {
      commitPendingEdits()
      categoryStore.markOnboardingCategoriesCustomized()
      categoryStore.addCategory(name: "新分类")
      addCount += 1
      AnalyticsService.shared.capture(
        "onboarding_category_added",
        [
          "total_count": categories.count + 1,
          "surface": "onboarding",
        ])
      if let newCat = categoryStore.editableCategories.last {
        startEditing(newCat)
      }
    } label: {
      Text("+ 添加分类")
        .font(.custom("Figtree", size: 12).weight(.medium))
        .foregroundColor(Color(hex: "2B2B2B"))
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .dayflowFloatingControl(cornerRadius: 8)
    }
    .buttonStyle(.plain)
    .pointingHandCursor(enabled: canAddMore)
    .opacity(canAddMore ? 1 : 0.45)
    .disabled(!canAddMore)
  }

  // MARK: - Back / Next Buttons

  private var buttonRow: some View {
    HStack(spacing: 15) {
      Spacer()

      // Back button (outlined)
      DayflowSurfaceButton(
        action: onBack,
        content: {
          Text("返回")
            .font(.custom("Figtree", size: 12).weight(.medium))
            .tracking(-0.48)
        },
        background: Color(nsColor: .controlBackgroundColor).opacity(0.72),
        foreground: DayflowOnboardingToken.secondaryButtonText.opacity(0.58),
        borderColor: DayflowOnboardingToken.secondaryButtonText.opacity(0.28),
        cornerRadius: 8,
        horizontalPadding: 40,
        verticalPadding: 12,
        isSecondaryStyle: true
      )

      // Next button (filled)
      DayflowSurfaceButton(
        action: {
          commitPendingEdits()
          categoryStore.persist()
          AnalyticsService.shared.capture(
            "onboarding_categories_completed",
            [
              "category_count": categories.count,
              "renamed_count": renameCount,
              "added_count": addCount,
              "color_changed_count": colorChangeCount,
              "deleted_count": deleteCount,
            ])
          onNext()
        },
        content: {
          Text("下一步")
            .font(.custom("Figtree", size: 12).weight(.medium))
            .tracking(-0.48)
        },
        background: DayflowOnboardingToken.primaryButtonFill,
        foreground: DayflowOnboardingToken.primaryButtonText,
        borderColor: .clear,
        cornerRadius: 8,
        horizontalPadding: 40,
        verticalPadding: 12,
        showOverlayStroke: true
      )
      .opacity(canContinue ? 1 : 0.45)
      .allowsHitTesting(canContinue)
    }
  }

  // MARK: - Editing Helpers

  private func startEditing(_ category: TimelineCategory) {
    commitPendingEdits()
    editingCategoryID = category.id
    draftName = category.name
  }

  private func saveEdits(for category: TimelineCategory) {
    let trimmedName = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
    if !trimmedName.isEmpty, trimmedName != category.name {
      categoryStore.markOnboardingCategoriesCustomized()
      categoryStore.renameCategory(id: category.id, to: trimmedName)
      renameCount += 1
      AnalyticsService.shared.capture(
        "onboarding_category_renamed",
        [
          "category_name": trimmedName,
          "previous_name": category.name,
          "surface": "onboarding",
        ])
    }
    editingCategoryID = nil
  }

  private var deleteAlertBinding: Binding<Bool> {
    Binding(
      get: { pendingDeleteCategory != nil },
      set: { isPresented in
        if !isPresented {
          pendingDeleteCategory = nil
        }
      }
    )
  }

  private func requestDelete(_ category: TimelineCategory) {
    pendingDeleteCategory = category
  }

  private func deleteCategory(_ category: TimelineCategory) {
    pendingDeleteCategory = nil
    categoryStore.markOnboardingCategoriesCustomized()

    if editingCategoryID == category.id {
      cancelEditing()
    }

    categoryStore.removeCategory(id: category.id)
    deleteCount += 1

    AnalyticsService.shared.capture(
      "onboarding_category_deleted",
      [
        "category_name": category.name,
        "remaining_count": categoryStore.editableCategories.count,
        "surface": "onboarding",
      ])
  }

  private func cancelEditing() {
    editingCategoryID = nil
    draftName = ""
  }

  private func commitPendingEdits() {
    guard let editingID = editingCategoryID,
      let category = categories.first(where: { $0.id == editingID })
    else { return }
    saveEdits(for: category)
  }
}

#Preview("Onboarding Categories") {
  OnboardingCategoryStepView(
    onBack: {},
    onNext: {}
  )
  .environmentObject(CategoryStore.shared)
  .frame(width: 1200, height: 680)
  .dayflowWindowBackground()
}
