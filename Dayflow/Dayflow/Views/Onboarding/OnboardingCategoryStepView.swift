//
//  开启boardingCategoryStepView.swift
//  Dayflow
//
//  开启boarding step for editing category names and descriptions.
//  Matches the Figma design: two-column layout, inline card editing,
//  no color picker stage.
//

import SwiftUI

struct 开启boardingCategoryStepView: View {
  let onBack: () -> Void
  let onNext: () -> Void
  @EnvironmentObject private var categoryStore: CategoryStore

  @State private var editingCategoryID: UUID?
  @State private var draftName: String = ""
  @State private var pendingDeleteCategory: TimelineCategory?

  // Analytics counters for the completion summary
  @State private var rename数量 = 0
  @State private var add数量 = 0
  @State private var colorChange数量 = 0
  @State private var delete数量 = 0

  private var categories: [TimelineCategory] {
    categoryStore.editable分类
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
      "删除分类?",
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
      Text("“\(category.name)” will be removed from your onboarding categories.")
    }
  }

  // MARK: - Left Column

  private var instructionsColumn: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Help Dayflow understand your workflow")
        .font(.custom("InstrumentSerif-Regular", size: 28))
        .foregroundColor(.black)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.bottom, 24)

      Text("Dayflow will organize your activities based on the categories you provide.")
        .font(.custom("Figtree", size: 14).weight(.medium))
        .foregroundColor(Color(hex: "5B5B5B"))
        .fixedSize(horizontal: false, vertical: true)

      Text(
        "Here are options tailored to your work to help you get started. Provide more personalized descriptions to help Dayflow better understand your actions."
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
            read开启lyCard(for: category)
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
          Image("分类Delete")
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
    .background(Color.white)
    .cornerRadius(4)
    .overlay(
      RoundedRectangle(cornerRadius: 4)
        .stroke(Color(hex: "E3DBD9"), lineWidth: 0.5)
    )
    .shadow(color: Color(hex: "FCB278"), radius: 3, x: 0, y: 0)
  }

  // MARK: - Read-开启ly Card

  private func read开启lyCard(for category: TimelineCategory) -> some View {
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
            Image("分类Delete")
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
    .background(Color.white)
    .cornerRadius(6)
    .overlay(
      RoundedRectangle(cornerRadius: 6)
        .stroke(Color(hex: "E3DBD9"), lineWidth: 0.5)
    )
    .shadow(color: Color(hex: "DCCDC1").opacity(0.5), radius: 3, x: 0, y: 0)
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
          .stroke(Color.white, lineWidth: 1.5)
      )
      .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 0)
  }

  // MARK: - Add Category Button

  private var addCategoryButton: some View {
    Button {
      commitPendingEdits()
      categoryStore.mark开启boarding分类自定义ized()
      categoryStore.addCategory(name: "New Category")
      add数量 += 1
      AnalyticsService.shared.capture(
        "onboarding_category_added",
        [
          "total_count": categories.count + 1,
          "surface": "onboarding",
        ])
      if let newCat = categoryStore.editable分类.last {
        startEditing(newCat)
      }
    } label: {
      Text("+ 添加分类")
        .font(.custom("Figtree", size: 12).weight(.medium))
        .foregroundColor(Color(hex: "2B2B2B"))
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(hex: "FFBA81").opacity(0.3))
        .cornerRadius(4)
        .overlay(
          RoundedRectangle(cornerRadius: 4)
            .stroke(Color(hex: "F3A462"), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.06), radius: 2, x: 0, y: 0)
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
      Button(action: onBack) {
        Text("返回")
          .font(.custom("Figtree", size: 12).weight(.medium))
          .tracking(-0.48)
          .foregroundColor(Color(hex: "B6B6B6"))
          .padding(.horizontal, 40)
          .padding(.vertical, 12)
          .overlay(
            RoundedRectangle(cornerRadius: 4)
              .stroke(Color(hex: "B6B6B6"), lineWidth: 1)
          )
      }
      .buttonStyle(.plain)
      .pointingHandCursor()

      // Next button (filled)
      Button {
        commitPendingEdits()
        categoryStore.persist()
        AnalyticsService.shared.capture(
          "onboarding_categories_completed",
          [
            "category_count": categories.count,
            "renamed_count": rename数量,
            "added_count": add数量,
            "color_changed_count": colorChange数量,
            "deleted_count": delete数量,
          ])
        onNext()
      } label: {
        Text("下一步")
          .font(.custom("Figtree", size: 12).weight(.medium))
          .tracking(-0.48)
          .foregroundColor(.white)
          .padding(.horizontal, 40)
          .padding(.vertical, 12)
          .background(Color(hex: "402B00"))
          .cornerRadius(4)
      }
      .buttonStyle(.plain)
      .pointingHandCursor()
      .opacity(canContinue ? 1 : 0.45)
      .allowsHit测试ing(canContinue)
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
      categoryStore.mark开启boarding分类自定义ized()
      categoryStore.renameCategory(id: category.id, to: trimmedName)
      rename数量 += 1
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
    categoryStore.mark开启boarding分类自定义ized()

    if editingCategoryID == category.id {
      cancelEditing()
    }

    categoryStore.removeCategory(id: category.id)
    delete数量 += 1

    AnalyticsService.shared.capture(
      "onboarding_category_deleted",
      [
        "category_name": category.name,
        "remaining_count": categoryStore.editable分类.count,
        "surface": "onboarding",
      ])
  }

  private func cancelEditing() {
    editingCategoryID = nil
    draftName = ""
  }

  private func commitPendingEdits() {
    guard let editingID = editingCategoryID,
      let category = categories.first(w这里: { $0.id == editingID })
    else { return }
    saveEdits(for: category)
  }
}

#Preview("开启boarding 分类") {
  开启boardingCategoryStepView(
    onBack: {},
    onNext: {}
  )
  .environmentObject(CategoryStore.shared)
  .frame(width: 1200, height: 680)
  .background {
    Image("开启boardingBackgroundv2")
      .resizable()
      .aspectRatio(contentMode: .fill)
      .ignoresSafeArea()
  }
}
