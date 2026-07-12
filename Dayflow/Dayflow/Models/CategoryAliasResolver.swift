import Foundation

struct CategoryNameMapping: Identifiable, Equatable, Sendable {
  var source: String
  var target: String
  var isEnabled: Bool

  var id: String {
    "\(CategoryAliasResolver.normalizedKey(source))->\(CategoryAliasResolver.normalizedKey(target))"
  }
}

struct CategoryMigrationScanEntry: Identifiable, Equatable, Sendable {
  let tableName: String
  let source: String
  let target: String
  let rowCount: Int
  let totalDurationMinutes: Int
  let firstDay: String?
  let lastDay: String?

  var id: String {
    "\(tableName)-\(CategoryAliasResolver.normalizedKey(source))-\(CategoryAliasResolver.normalizedKey(target))"
  }
}

struct CategoryMigrationScanResult: Equatable, Sendable {
  let entries: [CategoryMigrationScanEntry]

  var totalRows: Int {
    entries.reduce(0) { $0 + $1.rowCount }
  }

  var totalDurationMinutes: Int {
    entries.reduce(0) { $0 + $1.totalDurationMinutes }
  }

  var isEmpty: Bool {
    entries.isEmpty
  }
}

struct CategoryMigrationResult: Equatable, Sendable {
  let scanResult: CategoryMigrationScanResult
  let updatedTimelineCardRows: Int
  let updatedDayGoalCategoryRows: Int
  let backupURL: URL

  var totalUpdatedRows: Int {
    updatedTimelineCardRows + updatedDayGoalCategoryRows
  }
}

enum CategoryAliasResolver {
  static let uncategorizedName = "未分类"

  static let defaultMappings: [CategoryNameMapping] = [
    .init(source: "Work", target: "工作", isEnabled: true),
    .init(source: "Coding / Debugging", target: "编码与调试", isEnabled: true),
    .init(source: "Code Review", target: "代码审查", isEnabled: true),
    .init(source: "Research", target: "研究", isEnabled: true),
    .init(source: "Engineering / Product", target: "工程与产品", isEnabled: true),
    .init(source: "Research & Strategy", target: "研究与策略", isEnabled: true),
    .init(source: "Data & Insights", target: "数据与洞察", isEnabled: true),
    .init(source: "Design", target: "设计", isEnabled: true),
    .init(source: "Studying", target: "学习", isEnabled: true),
    .init(source: "Assignments", target: "作业", isEnabled: true),
    .init(source: "Specs & Planning", target: "方案与规划", isEnabled: true),
    .init(source: "Research & Analysis", target: "研究与分析", isEnabled: true),
    .init(source: "Analysis & Modeling", target: "分析与建模", isEnabled: true),
    .init(source: "Data Engineering", target: "数据工程", isEnabled: true),
    .init(source: "Communication", target: "沟通", isEnabled: true),
    .init(source: "Personal", target: "个人", isEnabled: true),
    .init(source: "Distraction", target: "分心", isEnabled: true),
    .init(source: "Idle", target: "空闲", isEnabled: true),
  ]

  private static let defaultAliasLookup: [String: String] = {
    Dictionary(
      uniqueKeysWithValues: defaultMappings.map { mapping in
        (rawNormalizedKey(mapping.source), mapping.target)
      }
    )
  }()

  static func displayName(for value: String, fallback: String = uncategorizedName) -> String {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmed.isEmpty == false else { return fallback }
    return defaultAliasLookup[rawNormalizedKey(trimmed)] ?? trimmed
  }

  static func normalizedKey(_ value: String) -> String {
    let displayName = defaultAliasLookup[rawNormalizedKey(value)] ?? value
    return rawNormalizedKey(displayName)
  }

  static func rawNormalizedKey(_ value: String) -> String {
    let folded =
      value
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
      .lowercased()
    let parts = folded.map { character -> String in
      character.isLetter || character.isNumber ? String(character) : "_"
    }
    return parts.joined().split(separator: "_").joined(separator: "_")
  }

  static func enabledMappings(_ mappings: [CategoryNameMapping]) -> [CategoryNameMapping] {
    mappings.compactMap { mapping in
      let source = mapping.source.trimmingCharacters(in: .whitespacesAndNewlines)
      let target = mapping.target.trimmingCharacters(in: .whitespacesAndNewlines)
      guard mapping.isEnabled, source.isEmpty == false, target.isEmpty == false else {
        return nil
      }
      guard rawNormalizedKey(source) != rawNormalizedKey(target) else {
        return nil
      }
      return CategoryNameMapping(source: source, target: target, isEnabled: true)
    }
  }
}
