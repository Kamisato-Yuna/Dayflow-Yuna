import SwiftUI

struct SettingsDataTabView: View {
  @ObservedObject var viewModel: OtherSettingsViewModel
  @State private var activeExportDatePicker: ExportDatePicker?
  @State private var isReprocessDatePickerExpanded = false

  private enum ExportDatePicker {
    case start
    case end
  }

  var body: some View {
    VStack(alignment: .leading, spacing: SettingsStyle.sectionSpacing) {
      exportSection
      categoryMigrationSection
      reprocessSection
    }
    .sheet(isPresented: $viewModel.isCategoryMigrationPresented) {
      CategoryMigrationSheetView(viewModel: viewModel)
    }
  }

  // MARK: - Export

  private var exportSection: some View {
    let rangeInvalid =
      timelineDisplayDate(from: viewModel.exportStartDate)
      > timelineDisplayDate(from: viewModel.exportEndDate)

    return SettingsSection(
      title: "导出数据",
      subtitle: "把你的时间线带到常用工具中。"
    ) {
      VStack(alignment: .leading, spacing: 14) {
        HStack(alignment: .center, spacing: 10) {
          datePill(
            label: "开始",
            date: viewModel.exportStartDate,
            isExpanded: activeExportDatePicker == .start,
            accessibilityLabel: "导出开始日期",
            onTap: {
              withAnimation(.easeOut(duration: 0.2)) {
                activeExportDatePicker = activeExportDatePicker == .start ? nil : .start
                isReprocessDatePickerExpanded = false
              }
            }
          )

          Image(systemName: "arrow.right")
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(SettingsStyle.meta)

          datePill(
            label: "结束",
            date: viewModel.exportEndDate,
            isExpanded: activeExportDatePicker == .end,
            accessibilityLabel: "导出结束日期",
            onTap: {
              withAnimation(.easeOut(duration: 0.2)) {
                activeExportDatePicker = activeExportDatePicker == .end ? nil : .end
                isReprocessDatePickerExpanded = false
              }
            }
          )
        }

        if let activeExportDatePicker {
          inlineCalendar(
            date: exportDateBinding(for: activeExportDatePicker),
            onDateSelected: {
              withAnimation(.easeOut(duration: 0.2)) {
                self.activeExportDatePicker = nil
              }
            }
          )
          .transition(.move(edge: .top).combined(with: .opacity))
        }

        Text(
          "导出 Markdown 后，可以归档到 Notion、分享给队友，或粘贴到 ChatGPT / Claude / Gemini 做进一步分析。"
        )
        .font(.custom("Figtree", size: 12))
        .foregroundColor(SettingsStyle.secondary)
        .fixedSize(horizontal: false, vertical: true)

        HStack(spacing: 12) {
          SettingsPrimaryButton(
            title: viewModel.isExportingTimelineRange ? "导出中…" : "导出为 Markdown",
            systemImage: viewModel.isExportingTimelineRange ? nil : "square.and.arrow.down",
            isLoading: viewModel.isExportingTimelineRange,
            isDisabled: rangeInvalid,
            action: viewModel.exportTimelineRange
          )

          if rangeInvalid {
            Text("开始日期必须早于或等于结束日期。")
              .font(.custom("Figtree", size: 12))
              .foregroundColor(SettingsStyle.destructive)
          }
        }

        if let message = viewModel.exportStatusMessage {
          Text(message)
            .font(.custom("Figtree", size: 12))
            .foregroundColor(SettingsStyle.statusGood)
        }

        if let error = viewModel.exportErrorMessage {
          Text(error)
            .font(.custom("Figtree", size: 12))
            .foregroundColor(SettingsStyle.destructive)
        }
      }
    }
  }

  // MARK: - Category migration

  private var categoryMigrationSection: some View {
    SettingsSection(
      title: "分类数据迁移",
      subtitle: "先预览影响范围，再把旧英文分类名写入为当前中文分类名。"
    ) {
      VStack(alignment: .leading, spacing: 12) {
        Text("读取和统计已经会显示中文别名；这里只在你确认后修改数据库原值。")
          .font(.custom("Figtree", size: 12))
          .foregroundColor(SettingsStyle.secondary)
          .fixedSize(horizontal: false, vertical: true)

        HStack(spacing: 12) {
          SettingsPrimaryButton(
            title: "打开迁移工具",
            systemImage: "arrow.triangle.2.circlepath",
            action: viewModel.presentCategoryMigration
          )

          if let message = viewModel.categoryMigrationStatusMessage {
            Text(message)
              .font(.custom("Figtree", size: 12))
              .foregroundColor(SettingsStyle.secondary)
              .lineLimit(2)
          }
        }

        if let error = viewModel.categoryMigrationErrorMessage {
          Text(error)
            .font(.custom("Figtree", size: 12))
            .foregroundColor(SettingsStyle.destructive)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
    }
  }

  // MARK: - Reprocess day

  private var reprocessSection: some View {
    let normalizedDate = timelineDisplayDate(from: viewModel.reprocessDayDate)
    let dayString = DateFormatter.yyyyMMdd.string(from: normalizedDate)

    return SettingsSection(
      title: "重新处理某天",
      subtitle: "对某个时间线日期的所有批次重新运行分析。"
    ) {
      VStack(alignment: .leading, spacing: 14) {
        datePill(
          label: "日期",
          date: viewModel.reprocessDayDate,
          isExpanded: isReprocessDatePickerExpanded,
          accessibilityLabel: "重新处理日期",
          disabled: viewModel.isReprocessingDay,
          onTap: {
            withAnimation(.easeOut(duration: 0.2)) {
              isReprocessDatePickerExpanded.toggle()
              activeExportDatePicker = nil
            }
          }
        )

        if isReprocessDatePickerExpanded {
          inlineCalendar(
            date: $viewModel.reprocessDayDate,
            disabled: viewModel.isReprocessingDay,
            onDateSelected: {
              withAnimation(.easeOut(duration: 0.2)) {
                isReprocessDatePickerExpanded = false
              }
            }
          )
          .transition(.move(edge: .top).combined(with: .opacity))
        }

        Text(dayString)
          .font(.custom("Figtree", size: 12))
          .foregroundColor(SettingsStyle.meta)

        VStack(alignment: .leading, spacing: 4) {
          Text(
            "清除当天已有的卡片和观察记录，然后基于原始录制重新运行分析。"
          )
          .font(.custom("Figtree", size: 12))
          .foregroundColor(SettingsStyle.secondary)
          .fixedSize(horizontal: false, vertical: true)

          Text("注意：这可能消耗大量 API 调用。")
            .font(.custom("Figtree", size: 12))
            .fontWeight(.semibold)
            .foregroundColor(SettingsStyle.text)
        }

        HStack(spacing: 12) {
          SettingsPrimaryButton(
            title: viewModel.isReprocessingDay ? "重新处理中…" : "重新处理当天",
            systemImage: viewModel.isReprocessingDay ? nil : "arrow.clockwise",
            isLoading: viewModel.isReprocessingDay,
            action: { viewModel.showReprocessDayConfirm = true }
          )

          if let status = viewModel.reprocessStatusMessage {
            Text(status)
              .font(.custom("Figtree", size: 12))
              .foregroundColor(SettingsStyle.secondary)
          }
        }

        if let error = viewModel.reprocessErrorMessage {
          Text(error)
            .font(.custom("Figtree", size: 12))
            .foregroundColor(SettingsStyle.destructive)
        }
      }
      .alert("重新处理当天？", isPresented: $viewModel.showReprocessDayConfirm) {
        Button("取消", role: .cancel) {}
        Button("重新处理", role: .destructive) { viewModel.reprocessSelectedDay() }
      } message: {
        Text(
          "这会删除 \(dayString) 的现有时间线卡片并重新运行分析，可能消耗大量 API 调用。"
        )
      }
    }
  }

  // MARK: - Date pill
  //
  // A small label+date button that opens the inline calendar. Visually
  // aligned with SettingsSecondaryButton but with a top-label for form
  // clarity. One style, used for all date inputs.

  private func datePill(
    label: String,
    date: Date,
    isExpanded: Bool,
    accessibilityLabel: String,
    disabled: Bool = false,
    onTap: @escaping () -> Void
  ) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(label)
        .font(.custom("Figtree", size: 11))
        .fontWeight(.semibold)
        .textCase(.uppercase)
        .foregroundColor(SettingsStyle.meta)

      Button {
        guard !disabled else { return }
        onTap()
      } label: {
        HStack(spacing: 8) {
          Text(formattedTimelineDate(date))
            .font(.custom("Figtree", size: 13))
            .fontWeight(.semibold)
            .foregroundColor(SettingsStyle.ink.opacity(disabled ? 0.4 : 1))

          Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(SettingsStyle.ink.opacity(disabled ? 0.4 : 0.65))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(minWidth: 170, alignment: .leading)
        .settingsControlSurface(isActive: isExpanded, cornerRadius: 7)
      }
      .buttonStyle(.plain)
      .disabled(disabled)
      .pointingHandCursor()
      .accessibilityLabel(Text(accessibilityLabel))
    }
  }

  // MARK: - Inline calendar
  //
  // Shown as an expanded panel underneath a date pill. Keeps its own
  // surface because it's an input
  // widget, not a section container — like any dropdown menu.

  private func inlineCalendar(
    date: Binding<Date>,
    disabled: Bool = false,
    onDateSelected: @escaping () -> Void
  ) -> some View {
    DayflowCalendarGrid(selectedDate: date, onDateSelected: onDateSelected)
      .disabled(disabled)
      .opacity(disabled ? 0.7 : 1)
  }

  // MARK: - Helpers

  private func formattedTimelineDate(_ date: Date) -> String {
    Self.dateLabelFormatter.string(from: timelineDisplayDate(from: date))
  }

  private func exportDateBinding(for picker: ExportDatePicker) -> Binding<Date> {
    switch picker {
    case .start: return $viewModel.exportStartDate
    case .end: return $viewModel.exportEndDate
    }
  }

  private static let dateLabelFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "zh_Hans")
    formatter.setLocalizedDateFormatFromTemplate("yyyyMMMd")
    return formatter
  }()
}

private struct CategoryMigrationSheetView: View {
  @ObservedObject var viewModel: OtherSettingsViewModel
  @Environment(\.dismiss) private var dismiss
  @State private var step: Step = .edit

  private enum Step {
    case edit
    case preview
    case confirm
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      header
      Divider()
      content
      Spacer(minLength: 0)
      footer
    }
    .padding(24)
    .frame(width: 760, height: 620)
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("分类数据迁移")
        .font(.custom("Figtree", size: 20))
        .fontWeight(.semibold)
        .foregroundColor(SettingsStyle.text)

      Text(stepTitle)
        .font(.custom("Figtree", size: 12))
        .foregroundColor(SettingsStyle.secondary)
    }
  }

  @ViewBuilder
  private var content: some View {
    switch step {
    case .edit:
      mappingEditor
    case .preview:
      scanPreview
    case .confirm:
      confirmationView
    }
  }

  private var mappingEditor: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("默认映射")
          .font(.custom("Figtree", size: 14))
          .fontWeight(.semibold)
          .foregroundColor(SettingsStyle.text)
        Spacer()
        Button("恢复默认") {
          viewModel.resetCategoryMigrationMappings()
        }
        .buttonStyle(.plain)
        .foregroundColor(SettingsStyle.ink)
      }

      ScrollView {
        VStack(alignment: .leading, spacing: 8) {
          ForEach($viewModel.categoryMigrationMappings) { $mapping in
            HStack(spacing: 10) {
              Toggle("", isOn: $mapping.isEnabled)
                .labelsHidden()

              TextField("源分类", text: $mapping.source)
                .textFieldStyle(.roundedBorder)
                .frame(minWidth: 190)

              Image(systemName: "arrow.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(SettingsStyle.meta)

              TextField("目标分类", text: $mapping.target)
                .textFieldStyle(.roundedBorder)
                .frame(minWidth: 190)
            }
            .padding(.vertical, 2)
          }
        }
      }
    }
  }

  private var scanPreview: some View {
    VStack(alignment: .leading, spacing: 12) {
      if viewModel.isScanningCategoryMigration {
        ProgressView("正在扫描分类数据…")
      } else if let result = viewModel.categoryMigrationScanResult {
        if result.isEmpty {
          Text("没有发现需要迁移的分类数据。")
            .font(.custom("Figtree", size: 13))
            .foregroundColor(SettingsStyle.secondary)
        } else {
          Text("共命中 \(result.totalRows) 行，约 \(result.totalDurationMinutes) 分钟。")
            .font(.custom("Figtree", size: 13))
            .fontWeight(.semibold)
            .foregroundColor(SettingsStyle.text)

          migrationEntries(result.entries)
        }
      } else {
        Text("点击扫描后会按表展示命中行数、总时长和日期范围。")
          .font(.custom("Figtree", size: 13))
          .foregroundColor(SettingsStyle.secondary)
      }
    }
  }

  private var confirmationView: some View {
    VStack(alignment: .leading, spacing: 12) {
      if viewModel.isPerformingCategoryMigration {
        ProgressView("正在执行迁移…")
      }

      if let result = viewModel.categoryMigrationResult {
        Text("迁移完成")
          .font(.custom("Figtree", size: 15))
          .fontWeight(.semibold)
          .foregroundColor(SettingsStyle.statusGood)
        Text("已更新 \(result.updatedTimelineCardRows) 条时间线卡片、\(result.updatedDayGoalCategoryRows) 条每日目标分类。")
          .font(.custom("Figtree", size: 13))
          .foregroundColor(SettingsStyle.text)
        Text("备份：\(result.backupURL.path)")
          .font(.custom("Figtree", size: 12))
          .foregroundColor(SettingsStyle.secondary)
          .textSelection(.enabled)
      } else if let result = viewModel.categoryMigrationScanResult, !result.isEmpty {
        Text("执行前会先创建数据库备份，然后在一次事务中更新两张表。")
          .font(.custom("Figtree", size: 13))
          .foregroundColor(SettingsStyle.secondary)
        migrationEntries(result.entries)
      } else {
        Text("当前没有可执行的迁移项。")
          .font(.custom("Figtree", size: 13))
          .foregroundColor(SettingsStyle.secondary)
      }
    }
  }

  private func migrationEntries(_ entries: [CategoryMigrationScanEntry]) -> some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 8) {
        ForEach(entries) { entry in
          VStack(alignment: .leading, spacing: 5) {
            HStack {
              Text(entry.tableName)
                .font(.custom("Figtree", size: 12))
                .fontWeight(.semibold)
              Spacer()
              Text("\(entry.rowCount) 行")
                .font(.custom("Figtree", size: 12))
                .foregroundColor(SettingsStyle.secondary)
            }
            Text("\(entry.source) → \(entry.target)")
              .font(.custom("Figtree", size: 13))
              .foregroundColor(SettingsStyle.text)
            Text(entryDetail(entry))
              .font(.custom("Figtree", size: 12))
              .foregroundColor(SettingsStyle.secondary)
          }
          .padding(10)
          .settingsControlSurface(cornerRadius: 7)
        }
      }
    }
  }

  private var footer: some View {
    VStack(alignment: .leading, spacing: 10) {
      if let error = viewModel.categoryMigrationErrorMessage {
        Text(error)
          .font(.custom("Figtree", size: 12))
          .foregroundColor(SettingsStyle.destructive)
          .fixedSize(horizontal: false, vertical: true)
      } else if let message = viewModel.categoryMigrationStatusMessage {
        Text(message)
          .font(.custom("Figtree", size: 12))
          .foregroundColor(SettingsStyle.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }

      HStack {
        Button("取消") {
          dismiss()
        }
        .keyboardShortcut(.cancelAction)
        .disabled(viewModel.isScanningCategoryMigration || viewModel.isPerformingCategoryMigration)

        Spacer()

        if step != .edit {
          Button("返回编辑") {
            step = .edit
          }
          .disabled(viewModel.isScanningCategoryMigration || viewModel.isPerformingCategoryMigration)
        }

        switch step {
        case .edit:
          Button(viewModel.isScanningCategoryMigration ? "扫描中…" : "扫描") {
            viewModel.scanCategoryMigration()
            step = .preview
          }
          .keyboardShortcut(.defaultAction)
          .disabled(viewModel.isScanningCategoryMigration || viewModel.isPerformingCategoryMigration)

        case .preview:
          Button("下一步") {
            step = .confirm
          }
          .keyboardShortcut(.defaultAction)
          .disabled((viewModel.categoryMigrationScanResult?.isEmpty ?? true)
            || viewModel.isScanningCategoryMigration)

        case .confirm:
          Button(viewModel.isPerformingCategoryMigration ? "执行中…" : "执行迁移") {
            viewModel.performCategoryMigration()
          }
          .keyboardShortcut(.defaultAction)
          .disabled((viewModel.categoryMigrationScanResult?.isEmpty ?? true)
            || viewModel.isPerformingCategoryMigration
            || viewModel.categoryMigrationResult != nil)
        }
      }
    }
  }

  private var stepTitle: String {
    switch step {
    case .edit:
      return "调整源分类到目标分类的映射。禁用的映射不会参与扫描或迁移。"
    case .preview:
      return "预览数据库中会被更新的记录。"
    case .confirm:
      return "确认后才会写入数据库。"
    }
  }

  private func entryDetail(_ entry: CategoryMigrationScanEntry) -> String {
    var parts: [String] = []
    if entry.totalDurationMinutes > 0 {
      parts.append("约 \(entry.totalDurationMinutes) 分钟")
    }
    if let firstDay = entry.firstDay, let lastDay = entry.lastDay {
      parts.append(firstDay == lastDay ? firstDay : "\(firstDay) 至 \(lastDay)")
    }
    return parts.isEmpty ? "无时长字段" : parts.joined(separator: "，")
  }
}

// MARK: - Custom calendar grid
//
// Renamed and restyled — no amber accents, ink-brown selection circle,
// hairline black stroke on the panel. Everything else (layout, keyboard
// handling, month nav) preserved from the previous implementation.

private struct DayflowCalendarGrid: View {
  @Binding var selectedDate: Date
  var onDateSelected: () -> Void

  @State private var displayedMonth: Date = Date()
  @Environment(\.isEnabled) private var isEnabled

  private let calendar = Calendar.current
  private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)

  var body: some View {
    VStack(spacing: 12) {
      monthHeader
      weekdayLabels
      dayGrid
    }
    .padding(14)
    .frame(maxWidth: 290, alignment: .leading)
    .opacity(isEnabled ? 1 : 0.62)
    .dayflowPopoverSurface(cornerRadius: 10)
    .onAppear {
      displayedMonth =
        calendar.date(
          from: calendar.dateComponents([.year, .month], from: selectedDate)
        ) ?? selectedDate
    }
  }

  private var monthHeader: some View {
    HStack {
      Text(monthYearString)
        .font(.custom("Figtree", size: 14))
        .fontWeight(.semibold)
        .foregroundColor(SettingsStyle.text)

      Spacer()

      HStack(spacing: 2) {
        Button {
          changeMonth(by: -1)
        } label: {
          Image(systemName: "chevron.left")
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(SettingsStyle.ink)
            .frame(width: 24, height: 24)
            .settingsControlSurface(cornerRadius: 6)
        }
        .buttonStyle(.plain)
        .pointingHandCursor()

        Button {
          changeMonth(by: 1)
        } label: {
          Image(systemName: "chevron.right")
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(SettingsStyle.ink)
            .frame(width: 24, height: 24)
            .settingsControlSurface(cornerRadius: 6)
        }
        .buttonStyle(.plain)
        .pointingHandCursor()
      }
    }
  }

  private var weekdayLabels: some View {
    let symbols = calendar.veryShortWeekdaySymbols
    let firstWeekday = calendar.firstWeekday
    let ordered = Array(symbols[(firstWeekday - 1)...]) + Array(symbols[..<(firstWeekday - 1)])

    return LazyVGrid(columns: columns, spacing: 2) {
      ForEach(ordered, id: \.self) { symbol in
        Text(symbol)
          .font(.custom("Figtree", size: 11))
          .fontWeight(.medium)
          .foregroundColor(SettingsStyle.meta)
          .frame(maxWidth: .infinity)
          .frame(height: 22)
      }
    }
  }

  private var dayGrid: some View {
    let firstOfMonth = calendar.date(
      from: calendar.dateComponents([.year, .month], from: displayedMonth)
    )!
    let daysInMonth = calendar.range(of: .day, in: .month, for: firstOfMonth)!.count
    let weekday = calendar.component(.weekday, from: firstOfMonth)
    let offset = (weekday - calendar.firstWeekday + 7) % 7

    return LazyVGrid(columns: columns, spacing: 2) {
      ForEach(0..<offset, id: \.self) { _ in
        Color.clear.frame(height: 30)
      }

      ForEach(1...daysInMonth, id: \.self) { day in
        let date = makeDate(
          year: calendar.component(.year, from: firstOfMonth),
          month: calendar.component(.month, from: firstOfMonth),
          day: day)
        let isSelected = date.map { calendar.isDate($0, inSameDayAs: selectedDate) } ?? false
        let isToday = date.map { calendar.isDateInToday($0) } ?? false

        Button {
          if let date {
            selectedDate = date
            onDateSelected()
          }
        } label: {
          Text("\(day)")
            .font(.custom("Figtree", size: 13))
            .fontWeight(isSelected ? .bold : (isToday ? .semibold : .regular))
            .foregroundColor(
              isSelected ? .white : (isToday ? SettingsStyle.ink : SettingsStyle.text)
            )
            .frame(maxWidth: .infinity)
            .frame(height: 30)
            .background {
              if isSelected {
                Circle().fill(SettingsStyle.ink).frame(width: 28, height: 28)
              } else if isToday {
                Circle()
                  .stroke(SettingsStyle.ink.opacity(0.35), lineWidth: 1.2)
                  .frame(width: 28, height: 28)
              }
            }
        }
        .buttonStyle(.plain)
        .pointingHandCursor()
      }
    }
  }

  private var monthYearString: String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "zh_Hans")
    formatter.dateFormat = "yyyy年M月"
    return formatter.string(from: displayedMonth)
  }

  private func changeMonth(by value: Int) {
    var components = calendar.dateComponents([.year, .month], from: displayedMonth)
    components.month = (components.month ?? 1) + value
    displayedMonth = calendar.date(from: components) ?? displayedMonth
  }

  private func makeDate(year: Int, month: Int, day: Int) -> Date? {
    calendar.date(from: DateComponents(year: year, month: month, day: day))
  }
}
