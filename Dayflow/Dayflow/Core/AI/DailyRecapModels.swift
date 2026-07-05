import Foundation

enum DailyRecapProvider: String, Codable, CaseIterable, Sendable {
  case dayflow
  case local
  case gemini
  case chatgpt
  case claude
  case none

  private static let storageKey = "dailyRecapProvider_v1"
  static let allCases: [DailyRecapProvider] = [
    .claude,
    .chatgpt,
    .gemini,
    .local,
    .none,
  ]

  static func load(from defaults: UserDefaults = .standard) -> DailyRecapProvider {
    if let rawValue = defaults.string(forKey: storageKey) {
      if rawValue == DailyRecapProvider.dayflow.rawValue {
        let provider = migrateInitialSelection(from: defaults)
        provider.save(to: defaults)
        return provider
      }

      if let provider = DailyRecapProvider(rawValue: rawValue) {
        return provider
      }
    }

    let provider = migrateInitialSelection(from: defaults)
    provider.save(to: defaults)
    return provider
  }

  func save(to defaults: UserDefaults = .standard) {
    if self == .dayflow {
      Self.migrateInitialSelection(from: defaults).save(to: defaults)
      return
    }

    defaults.set(rawValue, forKey: Self.storageKey)
  }

  private static func migrateInitialSelection(from defaults: UserDefaults) -> DailyRecapProvider {
    switch LLMProviderType.load(from: defaults) {
    case .geminiDirect, .dayflowBackend:
      return .gemini
    case .chatGPTClaude:
      let preferredTool = defaults.string(forKey: "chatCLIPreferredTool") ?? "codex"
      return preferredTool == "claude" ? .claude : .chatgpt
    case .ollamaLocal:
      return .local
    }
  }

  var isUserSelectable: Bool {
    self != .dayflow
  }

  var analyticsName: String {
    rawValue
  }

  var displayName: String {
    switch self {
    case .dayflow:
      return "Dayflow backend"
    case .local:
      return "Local"
    case .gemini:
      return "Gemini"
    case .chatgpt:
      return "ChatGPT"
    case .claude:
      return "Claude"
    case .none:
      return "No provider"
    }
  }

  var selectionLabel: String {
    switch self {
    case .dayflow:
      return "Legacy Dayflow backend"
    case .local:
      return "Local"
    case .gemini:
      return "Gemini 3.5 Flash"
    case .chatgpt:
      return "GPT-5.4"
    case .claude:
      return "Claude Opus"
    case .none:
      return "No provider selected (Daily off)"
    }
  }

  var pickerSubtitle: String {
    switch self {
    case .dayflow:
      return "Legacy Dayflow backend is no longer available."
    case .local:
      return "Uses Ollama, LM Studio, or another local-compatible server on this Mac."
    case .gemini:
      return "Gemini 3.5 Flash"
    case .chatgpt:
      return "GPT-5.4"
    case .claude:
      return "Claude Opus"
    case .none:
      return "Turns off Daily recap generation until you pick another provider."
    }
  }

  var runtimeLabel: String {
    switch self {
    case .dayflow:
      return "legacy_dayflow_backend"
    case .local:
      return "local_llm"
    case .gemini:
      return "gemini_direct"
    case .chatgpt, .claude:
      return "chat_cli"
    case .none:
      return "disabled"
    }
  }

  var modelOrTool: String? {
    switch self {
    case .dayflow:
      return nil
    case .local:
      return Self.currentLocalModelID()
    case .gemini:
      return GeminiModel.flash35.rawValue
    case .chatgpt:
      return "gpt-5.4"
    case .claude:
      return "opus"
    case .none:
      return nil
    }
  }

  var canGenerate: Bool {
    isUserSelectable && self != .none
  }

  private static func currentLocalModelID(from defaults: UserDefaults = .standard) -> String? {
    let trimmed = defaults.string(forKey: "llmLocalModelId")?
      .trimmingCharacters(in: .whitespacesAndNewlines)
    if let trimmed, !trimmed.isEmpty {
      return trimmed
    }

    let rawEngine = defaults.string(forKey: "llmLocalEngine") ?? LocalEngine.ollama.rawValue
    let engine = LocalEngine(rawValue: rawEngine) ?? .ollama
    return LocalModelPreferences.defaultModelId(for: engine)
  }
}

enum DailyStandupPlaceholder {
  static let notGeneratedMessage =
    "Daily 数据尚未生成。如果这不符合预期，请提交反馈。"
  static let todayNotGeneratedMessage = "今天的每日复盘会在明早生成。"
  static let insufficientHistoryMessage =
    "过去 3 天捕获的活动不足，暂时无法生成站会更新。"
  static let noProviderSelectedMessage =
    "尚未选择每日复盘提供商。点击上方齿轮按钮并选择提供商，即可重新开启复盘生成。"
}

struct DailyStandupGenerationMetadata: Codable, Equatable, Sendable {
  var provider: DailyRecapProvider
  var runtime: String
  var modelOrTool: String?
  var sourceDay: String?
  var generatedAt: Date?

  init(
    provider: DailyRecapProvider,
    runtime: String? = nil,
    modelOrTool: String? = nil,
    sourceDay: String? = nil,
    generatedAt: Date? = Date()
  ) {
    self.provider = provider
    self.runtime = runtime ?? provider.runtimeLabel
    self.modelOrTool = modelOrTool ?? provider.modelOrTool
    self.sourceDay = sourceDay
    self.generatedAt = generatedAt
  }

  static let legacyDayflow = DailyStandupGenerationMetadata(
    provider: .dayflow,
    generatedAt: nil
  )

  var displayLabel: String {
    switch provider {
    case .dayflow:
      return "Dayflow backend"
    case .local:
      return modelOrTool ?? "Local"
    case .gemini:
      return "Gemini 3.5 Flash"
    case .chatgpt:
      return "GPT-5.4"
    case .claude:
      return "Claude Opus"
    case .none:
      return "No provider"
    }
  }
}

struct DailyBulletItem: Identifiable, Codable, Equatable, Sendable {
  var id: UUID = UUID()
  var text: String
}

struct DailyStandupDraft: Codable, Equatable, Sendable {
  var highlightsTitle: String
  var highlights: [DailyBulletItem]
  var tasksTitle: String
  var tasks: [DailyBulletItem]
  var blockersTitle: String
  var blockersBody: String
  var generation: DailyStandupGenerationMetadata?

  private static let legacyPlaceholderTranslations: [String: String] = [
    "Daily data has not been generated yet. If this is unexpected, please report a bug.":
      DailyStandupPlaceholder.notGeneratedMessage,
    "Today's daily recap will be generated tomorrow morning.":
      DailyStandupPlaceholder.todayNotGeneratedMessage,
    "Not enough captured activity in the previous 3 days to generate a standup.":
      DailyStandupPlaceholder.insufficientHistoryMessage,
    "No Daily provider is selected. Click the gear button above, then choose a provider to turn recap generation back on.":
      DailyStandupPlaceholder.noProviderSelectedMessage,
  ]

  private static let legacyTitleTranslations: [String: String] = [
    "Yesterday's highlights": "昨日重点",
    "Today's tasks": "今日任务",
    "Recent highlights": "最近重点",
    "Tasks": "任务",
    "Blockers": "阻碍",
  ]

  static let `default` = DailyStandupDraft(
    highlightsTitle: "昨日重点",
    highlights: [DailyBulletItem(text: DailyStandupPlaceholder.notGeneratedMessage)],
    tasksTitle: "今日任务",
    tasks: [DailyBulletItem(text: DailyStandupPlaceholder.notGeneratedMessage)],
    blockersTitle: "阻碍",
    blockersBody: DailyStandupPlaceholder.notGeneratedMessage,
    generation: nil
  )

  static let todayPlaceholder = DailyStandupDraft(
    highlightsTitle: "昨日重点",
    highlights: [DailyBulletItem(text: DailyStandupPlaceholder.todayNotGeneratedMessage)],
    tasksTitle: "今日任务",
    tasks: [DailyBulletItem(text: DailyStandupPlaceholder.todayNotGeneratedMessage)],
    blockersTitle: "阻碍",
    blockersBody: DailyStandupPlaceholder.todayNotGeneratedMessage,
    generation: nil
  )

  static let insufficientHistory = DailyStandupDraft(
    highlightsTitle: "最近重点",
    highlights: [DailyBulletItem(text: DailyStandupPlaceholder.insufficientHistoryMessage)],
    tasksTitle: "任务",
    tasks: [DailyBulletItem(text: DailyStandupPlaceholder.insufficientHistoryMessage)],
    blockersTitle: "阻碍",
    blockersBody: DailyStandupPlaceholder.insufficientHistoryMessage,
    generation: nil
  )

  static let noProviderSelected = DailyStandupDraft(
    highlightsTitle: "昨日重点",
    highlights: [DailyBulletItem(text: DailyStandupPlaceholder.noProviderSelectedMessage)],
    tasksTitle: "今日任务",
    tasks: [DailyBulletItem(text: DailyStandupPlaceholder.noProviderSelectedMessage)],
    blockersTitle: "阻碍",
    blockersBody: DailyStandupPlaceholder.noProviderSelectedMessage,
    generation: nil
  )

  func encodedJSONString() -> String? {
    guard let data = try? JSONEncoder().encode(self) else { return nil }
    return String(data: data, encoding: .utf8)
  }

  var hasGeneratedContent: Bool {
    !highlights.isEmpty || !tasks.isEmpty
      || !blockersBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  func localizedLegacyPlaceholders() -> DailyStandupDraft {
    var copy = self
    copy.highlightsTitle = Self.legacyTitleTranslations[copy.highlightsTitle] ?? copy.highlightsTitle
    copy.tasksTitle = Self.legacyTitleTranslations[copy.tasksTitle] ?? copy.tasksTitle
    copy.blockersTitle = Self.legacyTitleTranslations[copy.blockersTitle] ?? copy.blockersTitle
    copy.highlights = copy.highlights.map { item in
      DailyBulletItem(
        id: item.id,
        text: Self.legacyPlaceholderTranslations[item.text] ?? item.text
      )
    }
    copy.tasks = copy.tasks.map { item in
      DailyBulletItem(
        id: item.id,
        text: Self.legacyPlaceholderTranslations[item.text] ?? item.text
      )
    }
    copy.blockersBody =
      Self.legacyPlaceholderTranslations[copy.blockersBody] ?? copy.blockersBody
    return copy
  }
}

struct DailyRecapSourceDayCandidate: Equatable, Sendable {
  let dayString: String
  let startOfDay: Date
  let endOfDay: Date
}

enum DailyRecapSourceDayResolver {
  static func consumedSourceDays(from entries: [DailyStandupEntry]) -> Set<String> {
    entries.reduce(into: Set<String>()) { result, entry in
      guard
        let data = entry.payloadJSON.data(using: .utf8),
        let draft = try? JSONDecoder().decode(DailyStandupDraft.self, from: data),
        let sourceDay = draft.generation?.sourceDay?
          .trimmingCharacters(in: .whitespacesAndNewlines),
        !sourceDay.isEmpty
      else {
        return
      }

      result.insert(sourceDay)
    }
  }

  static func sourceDay(
    before targetStart: Date,
    lookbackWindowDays: Int,
    consumedSourceDays: Set<String>,
    hasMinimumActivity: (String) -> Bool
  ) -> DailyRecapSourceDayCandidate? {
    guard lookbackWindowDays > 0 else { return nil }

    let calendar = Calendar.current
    for offset in 1...lookbackWindowDays {
      guard
        let sourceStart = calendar.date(byAdding: .day, value: -offset, to: targetStart)
      else {
        continue
      }

      let dayString = DateFormatter.yyyyMMdd.string(from: sourceStart)
      guard !consumedSourceDays.contains(dayString),
        hasMinimumActivity(dayString),
        let sourceEnd = calendar.date(byAdding: .day, value: 1, to: sourceStart)
      else {
        continue
      }

      return DailyRecapSourceDayCandidate(
        dayString: dayString,
        startOfDay: sourceStart,
        endOfDay: sourceEnd
      )
    }

    return nil
  }
}
