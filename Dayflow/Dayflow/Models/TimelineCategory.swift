import Foundation
import SwiftUI

struct TimelineCategory: Identifiable, Codable, Equatable, Sendable {
  var id: UUID
  var name: String
  var colorHex: String
  var details: String
  var order: Int
  var isSystem: Bool
  var isIdle: Bool
  var isNew: Bool
  var createdAt: Date
  var updatedAt: Date

  init(
    id: UUID = UUID(),
    name: String,
    colorHex: String,
    details: String = "",
    order: Int,
    isSystem: Bool = false,
    isIdle: Bool = false,
    isNew: Bool = false,
    createdAt: Date = Date(),
    updatedAt: Date = Date()
  ) {
    self.id = id
    self.name = name
    self.colorHex = colorHex
    self.details = details
    self.order = order
    self.isSystem = isSystem
    self.isIdle = isIdle
    self.isNew = isNew
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
}

struct LLMCategoryDescriptor: Codable, Equatable, Hashable, Sendable {
  let id: UUID
  let name: String
  let colorHex: String
  let description: String?
  let isSystem: Bool
  let isIdle: Bool
}

func firstCategoryLookup(
  from categories: [TimelineCategory],
  normalizedKey: (String) -> String
) -> [String: TimelineCategory] {
  var lookup: [String: TimelineCategory] = [:]
  lookup.reserveCapacity(categories.count)

  for category in categories {
    let key = normalizedKey(category.name)
    if lookup[key] == nil {
      lookup[key] = category
    }
  }

  return lookup
}

func firstCategoryLookup(from categories: [TimelineCategory]) -> [String: TimelineCategory] {
  firstCategoryLookup(from: categories, normalizedKey: CategoryAliasResolver.normalizedKey)
}

@MainActor
final class CategoryStore: ObservableObject {
  static let shared = CategoryStore()
  enum StoreKeys {
    static let categories = "colorCategories"
    static let hasUsedApp = "hasUsedApp"
    static let onboardingSelectedRole = "onboardingSelectedRole"
    static let onboardingAppliedCategoryPreset = "onboardingAppliedCategoryPreset"
    static let onboardingCategoriesCustomized = "onboardingCategoriesCustomized"
  }

  @Published private(set) var categories: [TimelineCategory] = []

  init() {
    load()
  }

  var editableCategories: [TimelineCategory] {
    categories.filter { !$0.isSystem }.sorted { $0.order < $1.order }
  }

  var idleCategory: TimelineCategory? {
    categories.first(where: { $0.isIdle })
  }

  func setOnboardingRole(_ role: String) {
    UserDefaults.standard.set(role, forKey: StoreKeys.onboardingSelectedRole)
  }

  func applyOnboardingPresetIfNeeded() {
    let defaults = UserDefaults.standard
    guard let roleName = defaults.string(forKey: StoreKeys.onboardingSelectedRole) else {
      return
    }

    if defaults.bool(forKey: StoreKeys.onboardingCategoriesCustomized) {
      return
    }

    let preset = OnboardingCategoryPreset(roleName: roleName)
    let appliedPreset = defaults.string(forKey: StoreKeys.onboardingAppliedCategoryPreset)

    if appliedPreset == preset.rawValue && !categories.isEmpty {
      return
    }

    categories = CategoryPersistence.ensureIdleCategoryPresent(in: preset.categories)
    save()
    defaults.set(preset.rawValue, forKey: StoreKeys.onboardingAppliedCategoryPreset)
    defaults.set(false, forKey: StoreKeys.onboardingCategoriesCustomized)
  }

  func markOnboardingCategoriesCustomized() {
    UserDefaults.standard.set(true, forKey: StoreKeys.onboardingCategoriesCustomized)
  }

  func addCategory(name: String, colorHex: String? = nil) {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    let nextOrder = (categories.map { $0.order }.max() ?? -1) + 1
    let now = Date()
    let category = TimelineCategory(
      name: trimmed,
      colorHex: colorHex ?? "#E5E7EB",
      details: "",
      order: nextOrder,
      isSystem: false,
      isIdle: false,
      isNew: true,
      createdAt: now,
      updatedAt: now
    )
    categories.append(category)
    save()

    if UserDefaults.standard.bool(forKey: StoreKeys.hasUsedApp) == false {
      UserDefaults.standard.set(true, forKey: StoreKeys.hasUsedApp)
    }
  }

  func updateCategory(id: UUID, mutate: (inout TimelineCategory) -> Void) {
    guard let idx = categories.firstIndex(where: { $0.id == id }) else { return }
    var category = categories[idx]
    mutate(&category)
    category.updatedAt = Date()
    category.isNew = false
    categories[idx] = category
    save()
  }

  func assignColor(_ hex: String, to id: UUID) {
    let previousHex = categories.first(where: { $0.id == id })?.colorHex
    let categoryName = categories.first(where: { $0.id == id })?.name ?? "unknown"
    updateCategory(id: id) { cat in
      cat.colorHex = hex
    }
    if hex != previousHex {
      AnalyticsService.shared.capture(
        "category_color_changed",
        [
          "category_name": categoryName,
          "color_hex": hex,
          "previous_color_hex": previousHex ?? "none",
        ])
    }
  }

  func updateDetails(_ details: String, for id: UUID) {
    updateCategory(id: id) { cat in
      cat.details = details
    }
  }

  func renameCategory(id: UUID, to newName: String) {
    let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    updateCategory(id: id) { cat in
      cat.name = trimmed
    }
  }

  func removeCategory(id: UUID) {
    guard let category = categories.first(where: { $0.id == id }) else { return }
    guard category.isSystem == false else { return }
    categories.removeAll { $0.id == id }
    save()
  }

  func persist() {
    save()
  }

  private func load() {
    let decoded = CategoryPersistence.loadPersistedCategories()
    let effective = decoded.isEmpty ? CategoryPersistence.defaultCategories : decoded
    categories = CategoryPersistence.ensureIdleCategoryPresent(in: effective)
  }

  private func save() {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    if let data = try? encoder.encode(categories) {
      UserDefaults.standard.set(data, forKey: StoreKeys.categories)
    }
  }

}

extension CategoryStore {
  nonisolated static func descriptorsForLLM() -> [LLMCategoryDescriptor] {
    let categories = CategoryPersistence.loadPersistedCategories()
    let effective = categories.isEmpty ? CategoryPersistence.defaultCategories : categories
    return
      effective
      .sorted { $0.order < $1.order }
      .map { category in
        LLMCategoryDescriptor(
          id: category.id,
          name: category.name,
          colorHex: category.colorHex,
          description: {
            if category.isIdle {
              return "当用户在该时间段里超过一半时间处于空闲状态时使用。"
            }
            let trimmed = category.details.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
          }(),
          isSystem: category.isSystem,
          isIdle: category.isIdle
        )
      }
  }
}

extension CategoryStore {
  fileprivate static func ensureIdleCategoryPresent(in categories: [TimelineCategory])
    -> [TimelineCategory]
  {
    CategoryPersistence.ensureIdleCategoryPresent(in: categories)
  }
}

private enum OnboardingCategoryPreset: String {
  case softwareEngineer
  case founderExecutive
  case designer
  case student
  case productManager
  case dataScientist
  case other

  init(roleName: String) {
    switch roleName {
    case "Software Engineer":
      self = .softwareEngineer
    case "Founder / Executive":
      self = .founderExecutive
    case "Designer":
      self = .designer
    case "Student":
      self = .student
    case "Product Manager":
      self = .productManager
    case "Data Scientist":
      self = .dataScientist
    default:
      self = .other
    }
  }

  var categories: [TimelineCategory] {
    let now = Date()
    return categoryDefinitions.enumerated().map { index, definition in
      TimelineCategory(
        name: definition.name,
        colorHex: definition.colorHex,
        details: definition.details,
        order: index,
        isSystem: false,
        isIdle: false,
        isNew: false,
        createdAt: now,
        updatedAt: now
      )
    }
  }

  private var categoryDefinitions: [(name: String, colorHex: String, details: String)] {
    switch self {
    case .softwareEngineer:
      return [
        (
          "编码与调试",
          "#6A7EFF",
          "在 IDE 或终端中编写、重构并修复代码"
        ),
        (
          "代码审查",
          "#56CFEE",
          "审查 PR、阅读代码差异并留下评审意见"
        ),
        (
          "研究",
          "#C787F7",
          "阅读文档、Stack Overflow、探索工具和 API，并撰写设计文档或技术说明"
        ),
        (
          "沟通",
          "#FFAE8C",
          "会议、站会、Slack、邮件、视频通话、消息同步与群聊"
        ),
        (
          "分心",
          "#FF4721",
          "无目的的浏览与被动消费：社媒动态、随机视频、刷屏浏览、缺乏明确目标的娱乐和游戏"
        ),
        (
          "个人",
          "#ADE3E3",
          "有目的的非工作活动，如与朋友和家人交流、管理财务、订票、跑腿、生活事务与兴趣爱好"
        ),
      ]

    case .founderExecutive:
      return [
        (
          "工程与产品",
          "#6A7EFF",
          "编写代码、设计工作、交付功能并动手实现"
        ),
        (
          "研究与策略",
          "#56CFEE",
          "竞品研究、市场定位、深度思考与投资人材料准备"
        ),
        (
          "数据与洞察",
          "#C787F7",
          "仪表盘、留存数据、漏斗与财务数据"
        ),
        (
          "沟通",
          "#FFAE8C",
          "团队同步、投资人通话、用户演示与招聘"
        ),
        (
          "分心",
          "#FF4721",
          "无目的的浏览与被动消费：社媒动态、随机视频、刷屏浏览、缺乏明确目标的娱乐和游戏"
        ),
        (
          "个人",
          "#ADE3E3",
          "有目的的非工作活动，如与朋友和家人交流、管理财务、订票、跑腿、生活事务与兴趣爱好"
        ),
      ]

    case .designer:
      return [
        (
          "设计",
          "#6A7EFF",
          "制作原型、UI 组件、用户流程、视觉设计与交付规范"
        ),
        (
          "研究",
          "#56CFEE",
          "观察浏览模式、竞品审计、用户研究并复盘指标"
        ),
        (
          "沟通",
          "#FFAE8C",
          "设计评审、站会、评审讨论与概念展示"
        ),
        (
          "分心",
          "#FF4721",
          "无目的的浏览与被动消费：社媒动态、随机视频、刷屏浏览、缺乏明确目标的娱乐和游戏"
        ),
        (
          "个人",
          "#ADE3E3",
          "有目的的非工作活动，如与朋友和家人交流、管理财务、订票、跑腿、生活事务与兴趣爱好"
        ),
      ]

    case .student:
      return [
        (
          "学习",
          "#6A7EFF",
          "听课、阅读、复盘幻灯片、刷题卡与课程资料"
        ),
        (
          "作业",
          "#56CFEE",
          "论文、问题集、编程项目与实验报告"
        ),
        (
          "沟通",
          "#FFAE8C",
          "学习小组、助教答疑、群聊和给老师发邮件"
        ),
        (
          "分心",
          "#FF4721",
          "无目的的浏览与被动消费：社媒动态、随机视频、刷屏浏览、缺乏明确目标的娱乐和游戏"
        ),
        (
          "个人",
          "#ADE3E3",
          "有目的的非工作活动，如与朋友和家人交流、管理财务、订票、跑腿、生活事务与兴趣爱好"
        ),
      ]

    case .productManager:
      return [
        (
          "方案与规划",
          "#6A7EFF",
          "PRD、路线图、待办梳理、冲刺规划与工单"
        ),
        (
          "研究与分析",
          "#56CFEE",
          "用户研究、指标复盘、竞品分析与 A/B 测试"
        ),
        (
          "沟通",
          "#FFAE8C",
          "站会、利益相关人同步、设计评审与工程对齐"
        ),
        (
          "分心",
          "#FF4721",
          "无目的的浏览与被动消费：社媒动态、随机视频、刷屏浏览、缺乏明确目标的娱乐和游戏"
        ),
        (
          "个人",
          "#ADE3E3",
          "有目的的非工作活动，如与朋友和家人交流、管理财务、订票、跑腿、生活事务与兴趣爱好"
        ),
      ]

    case .dataScientist:
      return [
        (
          "分析与建模",
          "#6A7EFF",
          "Notebook、统计分析、ML 训练与数据探索"
        ),
        (
          "数据工程",
          "#56CFEE",
          "SQL 查询、数据管道、清洗与 ETL 脚本"
        ),
        (
          "研究",
          "#C787F7",
          "阅读论文、文档并探索新方法和工具"
        ),
        (
          "沟通",
          "#FFAE8C",
          "汇报发现、与利益相关人同步并进行团队讨论"
        ),
        (
          "分心",
          "#FF4721",
          "无目的的浏览与被动消费：社媒动态、随机视频、刷屏浏览、缺乏明确目标的娱乐和游戏"
        ),
        (
          "个人",
          "#ADE3E3",
          "有目的的非工作活动，如与朋友和家人交流、管理财务、订票、跑腿、生活事务与兴趣爱好"
        ),
      ]

    case .other:
      return [
        (
          "工作",
          "#6A7EFF",
          "不属于更具体分类的聚焦工作任务与职业责任"
        ),
        (
          "沟通",
          "#FFAE8C",
          "会议、站会、Slack、邮件、视频通话、消息同步与群聊"
        ),
        (
          "分心",
          "#FF4721",
          "无目的的浏览与被动消费：社媒动态、随机视频、刷屏浏览、缺乏明确目标的娱乐和游戏"
        ),
        (
          "个人",
          "#ADE3E3",
          "有目的的非工作活动，如与朋友和家人交流、管理财务、订票、跑腿、生活事务与兴趣爱好"
        ),
      ]
    }
  }
}

enum CategoryPersistence {
  static func loadPersistedCategories() -> [TimelineCategory] {
    guard let data = UserDefaults.standard.data(forKey: CategoryStore.StoreKeys.categories) else {
      return []
    }
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    if let categories = try? decoder.decode([TimelineCategory].self, from: data) {
      return ensureIdleCategoryPresent(in: categories.map(migrateLegacyPresetCopy))
    }
    struct LegacyColorCategory: Codable {
      let id: Int64
      var name: String
      var color: String?
      var details: String
      var isNew: Bool?
    }
    if let legacy = try? decoder.decode([LegacyColorCategory].self, from: data) {
      var order = 0
      let converted = legacy.map { item -> TimelineCategory in
        defer { order += 1 }
        let category = TimelineCategory(
          id: UUID(),
          name: item.name,
          colorHex: item.color ?? "#E5E7EB",
          details: item.details,
          order: order,
          isSystem: false,
          isIdle: false,
          isNew: item.isNew ?? false
        )
        return migrateLegacyPresetCopy(category)
      }
      return ensureIdleCategoryPresent(in: converted)
    }
    return []
  }

  private static func migrateLegacyPresetCopy(_ category: TimelineCategory) -> TimelineCategory {
    var migrated = category
    switch (category.name, category.details) {
    case ("Idle", _):
      migrated.name = "空闲"
      migrated.details = "将用户大部分时间处于空闲状态的时段标记为此分类。"
      migrated.isSystem = true
      migrated.isIdle = true

    case (
      "Coding / Debugging",
      "Writing, refactoring, and fixing code in an IDE or terminal"
    ):
      migrated.name = "编码与调试"
      migrated.details = "在 IDE 或终端中编写、重构并修复代码"

    case (
      "Code Review",
      "Reviewing PRs, reading diffs, and leaving comments"
    ):
      migrated.name = "代码审查"
      migrated.details = "审查 PR、阅读代码差异并留下评审意见"

    case (
      "Research",
      "Reading docs, Stack Overflow, exploring tools and APIs, and writing design docs or technical specs"
    ):
      migrated.name = "研究"
      migrated.details = "阅读文档、Stack Overflow、探索工具和 API，并撰写设计文档或技术说明"

    case (
      "Communication",
      "Meetings, standups, Slack, email, video calls, messaging, and syncs"
    ):
      migrated.name = "沟通"
      migrated.details = "会议、站会、Slack、邮件、视频通话、消息同步与群聊"

    case (
      "Engineering / Product",
      "Coding, design work, shipping features, and hands-on building"
    ):
      migrated.name = "工程与产品"
      migrated.details = "编写代码、设计工作、交付功能并动手实现"

    case (
      "Research & Strategy",
      "Competitive research, positioning, long-form thinking, and investor prep"
    ):
      migrated.name = "研究与策略"
      migrated.details = "竞品研究、市场定位、深度思考与投资人材料准备"

    case (
      "Data & Insights",
      "Dashboards, retention data, funnels, and financials"
    ):
      migrated.name = "数据与洞察"
      migrated.details = "仪表盘、留存数据、漏斗与财务数据"

    case (
      "Communication",
      "Team syncs, investor calls, user demos, and hiring"
    ):
      migrated.name = "沟通"
      migrated.details = "团队同步、投资人通话、用户演示与招聘"

    case (
      "Design",
      "Prototyping, UI components, user flows, visual design, and handoff specs"
    ):
      migrated.name = "设计"
      migrated.details = "制作原型、UI 组件、用户流程、视觉设计与交付规范"

    case (
      "Research",
      "Browsing patterns, competitive audits, user studies, and reviewing metrics"
    ):
      migrated.name = "研究"
      migrated.details = "观察浏览模式、竞品审计、用户研究并复盘指标"

    case (
      "Communication",
      "Design reviews, standups, critique sessions, and presenting concepts"
    ):
      migrated.name = "沟通"
      migrated.details = "设计评审、站会、评审讨论与概念展示"

    case (
      "Studying",
      "Lectures, reading, reviewing slides, flashcards, and course material"
    ):
      migrated.name = "学习"
      migrated.details = "听课、阅读、复盘幻灯片、刷题卡与课程资料"

    case (
      "Assignments",
      "Papers, problem sets, coding projects, and lab reports"
    ):
      migrated.name = "作业"
      migrated.details = "论文、问题集、编程项目与实验报告"

    case (
      "Communication",
      "Study groups, office hours, group chats, and emailing professors"
    ):
      migrated.name = "沟通"
      migrated.details = "学习小组、助教答疑、群聊和给老师发邮件"

    case (
      "Specs & Planning",
      "PRDs, roadmaps, backlog grooming, sprint planning, and tickets"
    ):
      migrated.name = "方案与规划"
      migrated.details = "PRD、路线图、待办梳理、冲刺规划与工单"

    case (
      "Research & Analysis",
      "User research, metrics review, competitive analysis, and A/B tests"
    ):
      migrated.name = "研究与分析"
      migrated.details = "用户研究、指标复盘、竞品分析与 A/B 测试"

    case (
      "Communication",
      "Standups, stakeholder syncs, design reviews, and engineering check-ins"
    ):
      migrated.name = "沟通"
      migrated.details = "站会、利益相关人同步、设计评审与工程对齐"

    case (
      "Analysis & Modeling",
      "Notebooks, statistical analysis, ML training, and data exploration"
    ):
      migrated.name = "分析与建模"
      migrated.details = "Notebook、统计分析、ML 训练与数据探索"

    case (
      "Data Engineering",
      "SQL queries, pipelines, data cleaning, and ETL scripts"
    ):
      migrated.name = "数据工程"
      migrated.details = "SQL 查询、数据管道、清洗与 ETL 脚本"

    case (
      "Research",
      "Reading papers, docs, and exploring new methods and tools"
    ):
      migrated.name = "研究"
      migrated.details = "阅读论文、文档并探索新方法和工具"

    case (
      "Communication",
      "Presenting findings, stakeholder syncs, and team discussions"
    ):
      migrated.name = "沟通"
      migrated.details = "汇报发现、与利益相关人同步并进行团队讨论"

    case (
      "Work",
      "Focused work tasks and professional responsibilities that do not fit a more specific category"
    ):
      migrated.name = "工作"
      migrated.details = "不属于更具体分类的聚焦工作任务与职业责任"

    case (
      "Distraction",
      "Unfocused browsing and passive content consumption: social media feeds, random videos, idle scrolling, entertainment with no clear intent, and gaming"
    ):
      migrated.name = "分心"
      migrated.details = "无目的的浏览与被动消费：社媒动态、随机视频、刷屏浏览、缺乏明确目标的娱乐和游戏"

    case (
      "Personal",
      "Intentional non-work activity with a purpose: messaging friends and family, managing finances, booking travel, errands, life admin, and hobbies"
    ):
      migrated.name = "个人"
      migrated.details = "有目的的非工作活动，如与朋友和家人交流、管理财务、订票、跑腿、生活事务与兴趣爱好"

    default:
      break
    }
    return migrated
  }

  static var defaultCategories: [TimelineCategory] {
    let now = Date()
    let base: [(String, String, Bool, Bool, String)] = [
      (
        "工作",
        "#B984FF",
        false,
        false,
        "工作、学习或其他提升产能的活动（项目、邮件、作业、视频通话、技能学习等）"
      ),
      (
        "个人",
        "#6AADFF",
        false,
        false,
        "有目的的非工作活动或生活事务（缴费、运动记录、餐食规划、个人研究、兴趣爱好等）"
      ),
      (
        "分心",
        "#FF5950",
        false,
        false,
        "被动消费或无目的浏览（刷动态、看随机视频、点击新闻、玩无目的游戏等）"
      ),
      (
        "空闲",
        "#A0AEC0",
        true,
        true,
        "用于用户大部分时间处于空闲状态的场景。"
      ),
    ]
    return base.enumerated().map { idx, entry in
      TimelineCategory(
        name: entry.0,
        colorHex: entry.1,
        details: entry.4,
        order: idx,
        isSystem: entry.2,
        isIdle: entry.3,
        isNew: false,
        createdAt: now,
        updatedAt: now
      )
    }
  }

  static func ensureIdleCategoryPresent(in categories: [TimelineCategory]) -> [TimelineCategory] {
    let migrated = categories.map(migrateLegacyPresetCopy)
    if migrated.contains(where: { $0.isIdle }) {
      return migrated.sorted { $0.order < $1.order }
    }

    var updated = migrated
    let order = (migrated.map { $0.order }.max() ?? -1) + 1
    let now = Date()
    let idle = TimelineCategory(
      name: "空闲",
      colorHex: "#A0AEC0",
      details: "将用户大部分时间处于空闲状态的时段标记为此分类。",
      order: order,
      isSystem: true,
      isIdle: true,
      isNew: false,
      createdAt: now,
      updatedAt: now
    )
    updated.append(idle)
    return updated.sorted { $0.order < $1.order }
  }
}
