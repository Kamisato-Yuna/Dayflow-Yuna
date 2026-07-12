import AppKit
import SwiftUI

struct SettingsProvidersTabView: View {
  @ObservedObject var viewModel: ProvidersSettingsViewModel

  var body: some View {
    VStack(alignment: .leading, spacing: SettingsStyle.sectionSpacing) {
      if viewModel.currentProvider == "ollama", viewModel.showLocalModelUpgradeBanner {
        LocalModelUpgradeBanner(
          preset: .qwen3VL4B,
          onKeepLegacy: { viewModel.markUpgradeBannerKeepLegacy() },
          onUpgrade: {
            viewModel.markUpgradeBannerUpgrade()
            viewModel.isShowingLocalModelUpgradeSheet = true
          }
        )
        .transition(.opacity)
      }

      if let status = viewModel.upgradeStatusMessage {
        Text(status)
          .font(.custom("Figtree", size: 13))
          .foregroundColor(SettingsStyle.statusGood)
      }

      currentConfigurationSection
      connectionHealthSection
      failoverRoutingSection

      if viewModel.currentProvider == "gemini" {
        geminiModelSection
      }

      promptCustomizationSection
    }
  }

  // MARK: - Current configuration

  private var currentConfigurationSection: some View {
    SettingsSection(
      title: "当前配置",
      subtitle: "当前启用的提供商和运行方式详情。"
    ) {
      VStack(alignment: .leading, spacing: 0) {
        summaryRows

        HStack(spacing: 8) {
          SettingsSecondaryButton(
            title: "编辑配置",
            action: { viewModel.editProviderConfiguration(viewModel.primaryRoutingProviderId) }
          )

          if viewModel.currentProvider == "ollama" {
            SettingsSecondaryButton(
              title: viewModel.usingRecommendedLocalModel
                ? "管理本地模型" : "升级本地模型",
              action: { viewModel.isShowingLocalModelUpgradeSheet = true }
            )
          }
        }
        .padding(.top, 18)
      }
    }
  }

  @ViewBuilder
  private var summaryRows: some View {
    SettingsRow(label: "主要提供商") {
      HStack(spacing: 8) {
        SettingsMetadata(
          text: viewModel.providerDisplayName(viewModel.primaryRoutingProviderId))
        SettingsBadge(text: "主要", isAccent: true)
      }
    }

    if let backupProvider = viewModel.secondaryRoutingProviderId {
      SettingsRow(label: "备用提供商") {
        HStack(spacing: 8) {
          SettingsMetadata(text: viewModel.providerDisplayName(backupProvider))
          SettingsBadge(text: "备用")
        }
      }
    } else {
      SettingsRow(label: "备用提供商") {
        SettingsMetadata(text: "未配置")
      }
    }

    switch viewModel.currentProvider {
    case "ollama":
      SettingsRow(label: "引擎") { SettingsMetadata(text: viewModel.localEngine.displayName) }
      SettingsRow(label: "模型") {
        SettingsMetadata(
          text: viewModel.localModelId.isEmpty ? "未配置" : viewModel.localModelId)
      }
      SettingsRow(label: "端点") { SettingsMetadata(text: viewModel.localBaseURL) }
      let hasKey = !viewModel.localAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      SettingsRow(label: "API Key", showsDivider: false) {
        SettingsMetadata(text: hasKey ? "已存入 UserDefaults" : "未设置")
      }
    case "gemini":
      SettingsRow(label: "模型偏好") {
        SettingsMetadata(text: viewModel.selectedGeminiModel.displayName)
      }
      SettingsRow(label: "API Key", showsDivider: false) {
        SettingsMetadata(
          text: KeychainManager.shared.retrieve(for: "gemini") != nil
            ? "已安全存入 Keychain" : "未设置")
      }
    case "chatgpt_claude":
      SettingsRow(label: "CLI 偏好") {
        SettingsMetadata(text: viewModel.chatCLIStatusLabel())
      }
    default:
      SettingsRow(label: "状态", showsDivider: false) {
        SettingsMetadata(text: "即将推出")
      }
    }
  }

  // MARK: - Connection health

  private var connectionHealthSection: some View {
    SettingsSection(
      title: "连接状态",
      subtitle: "快速测试主要提供商是否可用。"
    ) {
      VStack(alignment: .leading, spacing: 14) {
        Text(viewModel.connectionHealthLabel)
          .font(.custom("Figtree", size: 13))
          .fontWeight(.semibold)
          .foregroundColor(SettingsStyle.text)

        switch viewModel.currentProvider {
        case "gemini":
          TestConnectionView(onTestComplete: { _ in })
        case "ollama":
          LocalLLMTestView(
            baseURL: $viewModel.localBaseURL,
            modelId: $viewModel.localModelId,
            apiKey: $viewModel.localAPIKey,
            engine: viewModel.localEngine,
            showInputs: viewModel.localEngine == .custom,
            onTestComplete: { _ in viewModel.handleLocalTestCompletion() }
          )
        case "chatgpt_claude":
          ChatCLITestView(
            selectedTool: viewModel.preferredCLITool,
            onTestComplete: { _ in }
          )
        default:
          Text("诊断即将推出")
            .font(.custom("Figtree", size: 13))
            .foregroundColor(SettingsStyle.secondary)
        }
      }
    }
  }

  // MARK: - Failover routing

  private var failoverRoutingSection: some View {
    SettingsSection(
      title: "故障转移路由",
      subtitle: "选择主要和备用提供商。"
    ) {
      VStack(alignment: .leading, spacing: 0) {
        let providers = viewModel.routingProviders
        ForEach(Array(providers.enumerated()), id: \.element.id) { index, provider in
          routingRow(
            provider: provider,
            showsDivider: index < providers.count - 1
          )
        }
      }
    }
  }

  private func routingRow(
    provider: CompactProviderInfo,
    showsDivider: Bool
  ) -> some View {
    let isConfigured = viewModel.isProviderConfigured(provider.id)
    let isPrimary = viewModel.primaryRoutingProviderId == provider.id
    let isSecondary = viewModel.isBackupProvider(provider.id)
    let canSetSecondary = viewModel.canAssignSecondary(provider.id) || !isConfigured

    return VStack(alignment: .leading, spacing: 10) {
      HStack(alignment: .center, spacing: 10) {
        ProviderIconView(icon: provider.icon, scale: 0.72)

        VStack(alignment: .leading, spacing: 2) {
          Text(provider.providerTableName)
            .font(.custom("Figtree", size: 14))
            .fontWeight(.semibold)
            .foregroundColor(SettingsStyle.text)

          Text(provider.summary)
            .font(.custom("Figtree", size: 12))
            .foregroundColor(SettingsStyle.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }

        Spacer()

        if isPrimary {
          SettingsBadge(text: "主要", isAccent: true)
        } else if isSecondary {
          SettingsBadge(text: "备用")
        } else if isConfigured {
          SettingsBadge(text: "已配置")
        } else {
          SettingsBadge(text: "未设置")
        }
      }

      HStack(spacing: 8) {
        if !isConfigured {
          SettingsSecondaryButton(title: "设置") {
            viewModel.beginProviderSetup(provider.id, role: .setupOnly)
          }
        }

        SettingsSecondaryButton(title: "编辑配置") {
          viewModel.editProviderConfiguration(provider.id)
        }

        if !isPrimary {
          SettingsSecondaryButton(title: "设为主要") {
            viewModel.setPrimaryOrSetup(provider.id)
          }
        }

        if !isSecondary {
          SettingsSecondaryButton(title: "设为备用", isDisabled: !canSetSecondary) {
            viewModel.setSecondaryOrSetup(provider.id)
          }
        } else {
          SettingsSecondaryButton(title: "取消备用") {
            viewModel.clearBackupProvider()
          }
        }
      }
    }
    .padding(.vertical, 14)
    .overlay(alignment: .bottom) {
      if showsDivider {
        Rectangle().fill(SettingsStyle.divider).frame(height: 1)
      }
    }
  }

  // MARK: - Gemini model preference

  private var geminiModelSection: some View {
    SettingsSection(
      title: "Gemini 模型偏好",
      subtitle: "选择 Dayflow 优先使用的 Gemini 模型。"
    ) {
      VStack(alignment: .leading, spacing: 14) {
        Picker("Gemini 模型", selection: $viewModel.selectedGeminiModel) {
          ForEach(GeminiModel.allCases, id: \.self) { model in
            Text(model.displayName).tag(model)
          }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .onChange(of: viewModel.selectedGeminiModel) { _, newValue in
          viewModel.persistGeminiModelSelection(newValue, source: "settings")
        }

        Text(GeminiModelPreference(primary: viewModel.selectedGeminiModel).fallbackSummary)
          .font(.custom("Figtree", size: 12))
          .foregroundColor(SettingsStyle.secondary)

        Text(
          "如果所选模型受到速率限制或暂时不可用，Dayflow 会自动降级。"
        )
        .font(.custom("Figtree", size: 11))
        .foregroundColor(SettingsStyle.meta)
      }
    }
  }

  // MARK: - Prompt customization

  @ViewBuilder
  private var promptCustomizationSection: some View {
    switch viewModel.currentProvider {
    case "gemini":
      promptSection(
        title: "Gemini 提示词自定义",
        subtitle: "覆盖 Dayflow 默认提示词，以调整卡片生成效果。",
        intro:
          "只有打开开关的部分会覆盖默认值；未勾选的部分会继续使用 Dayflow 默认提示词。",
        sections: [
          promptEditorConfig(
            heading: "卡片标题",
            description: "调整卡片标题的表达方式和示例列表。",
            isEnabled: $viewModel.useCustomGeminiTitlePrompt,
            text: $viewModel.geminiTitlePromptText,
            defaultText: GeminiPromptDefaults.titleBlock
          ),
          promptEditorConfig(
            heading: "卡片摘要",
            description: "控制摘要字段的语气和风格。",
            isEnabled: $viewModel.useCustomGeminiSummaryPrompt,
            text: $viewModel.geminiSummaryPromptText,
            defaultText: GeminiPromptDefaults.summaryBlock
          ),
          promptEditorConfig(
            heading: "详细摘要",
            description: "定义逐分钟拆解的格式和示例。",
            isEnabled: $viewModel.useCustomGeminiDetailedPrompt,
            text: $viewModel.geminiDetailedPromptText,
            defaultText: GeminiPromptDefaults.detailedSummaryBlock
          ),
        ],
        onReset: viewModel.resetGeminiPromptOverrides
      )
    case "ollama":
      promptSection(
        title: "本地提示词自定义",
        subtitle: "调整本地时间线摘要使用的提示词。",
        intro: "自定义本地模型生成摘要和标题时使用的提示词。",
        sections: [
          promptEditorConfig(
            heading: "时间线摘要",
            description: "控制本地模型如何撰写 2-3 句卡片摘要。",
            isEnabled: $viewModel.useCustomOllamaSummaryPrompt,
            text: $viewModel.ollamaSummaryPromptText,
            defaultText: OllamaPromptDefaults.summaryBlock
          ),
          promptEditorConfig(
            heading: "卡片标题",
            description: "调整本地标题生成的语气和示例。",
            isEnabled: $viewModel.useCustomOllamaTitlePrompt,
            text: $viewModel.ollamaTitlePromptText,
            defaultText: OllamaPromptDefaults.titleBlock
          ),
        ],
        onReset: viewModel.resetOllamaPromptOverrides
      )
    case "chatgpt_claude":
      promptSection(
        title: "ChatGPT / Claude 提示词自定义",
        subtitle: "覆盖 Dayflow 默认提示词，以调整卡片生成效果。",
        intro:
          "只有打开开关的部分会覆盖默认值；未勾选的部分会继续使用 Dayflow 默认提示词。",
        sections: [
          promptEditorConfig(
            heading: "卡片标题",
            description: "调整卡片标题的表达方式和示例列表。",
            isEnabled: $viewModel.useCustomChatCLITitlePrompt,
            text: $viewModel.chatCLITitlePromptText,
            defaultText: ChatCLIPromptDefaults.titleBlock
          ),
          promptEditorConfig(
            heading: "卡片摘要",
            description: "控制摘要字段的语气和风格。",
            isEnabled: $viewModel.useCustomChatCLISummaryPrompt,
            text: $viewModel.chatCLISummaryPromptText,
            defaultText: ChatCLIPromptDefaults.summaryBlock
          ),
          promptEditorConfig(
            heading: "详细摘要",
            description: "定义逐分钟拆解的格式和示例。",
            isEnabled: $viewModel.useCustomChatCLIDetailedPrompt,
            text: $viewModel.chatCLIDetailedPromptText,
            defaultText: ChatCLIPromptDefaults.detailedSummaryBlock
          ),
        ],
        onReset: viewModel.resetChatCLIPromptOverrides
      )
    default:
      EmptyView()
    }
  }

  private struct PromptEditorConfig {
    let heading: String
    let description: String
    let isEnabled: Binding<Bool>
    let text: Binding<String>
    let defaultText: String
  }

  private func promptEditorConfig(
    heading: String,
    description: String,
    isEnabled: Binding<Bool>,
    text: Binding<String>,
    defaultText: String
  ) -> PromptEditorConfig {
    PromptEditorConfig(
      heading: heading, description: description, isEnabled: isEnabled, text: text,
      defaultText: defaultText)
  }

  private func promptSection(
    title: String,
    subtitle: String,
    intro: String,
    sections: [PromptEditorConfig],
    onReset: @escaping () -> Void
  ) -> some View {
    SettingsSection(title: title, subtitle: subtitle) {
      VStack(alignment: .leading, spacing: 18) {
        Text(intro)
          .font(.custom("Figtree", size: 12))
          .foregroundColor(SettingsStyle.secondary)
          .fixedSize(horizontal: false, vertical: true)

        ForEach(sections.indices, id: \.self) { index in
          promptEditorBlock(config: sections[index])
        }

        HStack {
          Spacer()
          SettingsSecondaryButton(
            title: "恢复 Dayflow 默认值",
            systemImage: "arrow.counterclockwise",
            action: onReset
          )
        }
      }
    }
  }

  /// A prompt-customization block: toggle + text-editor pair. Keeps its
  /// own subtle container because the text editor needs input-affordance
  /// against the paper background.
  private func promptEditorBlock(config: PromptEditorConfig) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Toggle(isOn: config.isEnabled) {
        VStack(alignment: .leading, spacing: 3) {
          Text(config.heading)
            .font(.custom("Figtree", size: 14))
            .fontWeight(.semibold)
            .foregroundColor(SettingsStyle.text)
          Text(config.description)
            .font(.custom("Figtree", size: 12))
            .foregroundColor(SettingsStyle.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
      .toggleStyle(SwitchToggleStyle(tint: SettingsStyle.ink))
      .pointingHandCursor()

      ZStack(alignment: .topLeading) {
        if config.text.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          Text(config.defaultText)
            .font(.custom("Figtree", size: 12))
            .foregroundColor(SettingsStyle.meta)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .fixedSize(horizontal: false, vertical: true)
            .allowsHitTesting(false)
        }

        TextEditor(text: config.text)
          .font(.custom("Figtree", size: 12))
          .foregroundColor(SettingsStyle.text.opacity(config.isEnabled.wrappedValue ? 1 : 0.4))
          .scrollContentBackground(.hidden)
          .disabled(!config.isEnabled.wrappedValue)
          .padding(.horizontal, 10)
          .padding(.vertical, 8)
          .frame(minHeight: config.isEnabled.wrappedValue ? 140 : 120)
      }
      .settingsControlSurface(cornerRadius: 7)
      .opacity(config.isEnabled.wrappedValue ? 1 : 0.6)
    }
  }
}

// MARK: - Upgrade banner

private struct LocalModelUpgradeBanner: View {
  let preset: LocalModelPreset
  let onKeepLegacy: () -> Void
  let onUpgrade: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack(spacing: 10) {
        Image(systemName: "sparkles")
          .foregroundStyle(SettingsStyle.ink)
          .padding(8)
          .background(SettingsStyle.selectedFill)
          .clipShape(RoundedRectangle(cornerRadius: 8))
        VStack(alignment: .leading, spacing: 4) {
          Text("升级到 \(preset.displayName)")
            .font(.custom("Figtree", size: 16))
            .fontWeight(.semibold)
            .foregroundColor(SettingsStyle.text)
          Text("升级到 Qwen3VL，可显著提升质量。")
            .font(.custom("Figtree", size: 13))
            .foregroundColor(SettingsStyle.secondary)
        }
        Spacer()
      }

      VStack(alignment: .leading, spacing: 6) {
        ForEach(preset.settingsHighlightBullets, id: \.self) { bullet in
          HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
              .font(.system(size: 12))
              .foregroundColor(SettingsStyle.statusGood)
              .padding(.top, 2)
            Text(bullet)
              .font(.custom("Figtree", size: 13))
              .foregroundColor(SettingsStyle.text)
          }
        }
      }

      HStack(spacing: 12) {
        Button(action: onKeepLegacy) {
          Text("保留 Qwen2.5")
            .font(.custom("Figtree", size: 13))
            .fontWeight(.semibold)
            .foregroundColor(SettingsStyle.ink)
            .padding(.horizontal, 18)
            .padding(.vertical, 9)
            .settingsControlSurface(cornerRadius: 8)
        }
        .buttonStyle(.plain)
        .pointingHandCursor()

        Button(action: onUpgrade) {
          HStack(spacing: 6) {
            Text("立即升级")
              .font(.custom("Figtree", size: 13))
              .fontWeight(.semibold)
            Image(systemName: "arrow.right")
              .font(.system(size: 12, weight: .semibold))
          }
          .foregroundColor(Color(nsColor: .selectedMenuItemTextColor))
          .padding(.horizontal, 18)
          .padding(.vertical, 9)
          .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
              .fill(SettingsStyle.ink.opacity(0.92))
          )
        }
        .buttonStyle(.plain)
        .pointingHandCursor()
      }
    }
    .padding(20)
    .dayflowContentPanel(cornerRadius: 14)
  }
}

// MARK: - Upgrade sheet (unchanged — it's a modal, not a settings surface)

struct LocalModelUpgradeSheet: View {
  let preset: LocalModelPreset
  let initialEngine: LocalEngine
  let initialBaseURL: String
  let initialModelId: String
  let initialAPIKey: String
  let onCancel: () -> Void
  let onUpgradeSuccess: (LocalEngine, String, String, String) -> Void

  @State private var selectedEngine: LocalEngine
  @State private var candidateBaseURL: String
  @State private var candidateModelId: String
  @State private var candidateAPIKey: String
  @State private var didApplyUpgrade = false

  init(
    preset: LocalModelPreset,
    initialEngine: LocalEngine,
    initialBaseURL: String,
    initialModelId: String,
    initialAPIKey: String,
    onCancel: @escaping () -> Void,
    onUpgradeSuccess: @escaping (LocalEngine, String, String, String) -> Void
  ) {
    self.preset = preset
    self.initialEngine = initialEngine
    self.initialBaseURL = initialBaseURL
    self.initialModelId = initialModelId
    self.initialAPIKey = initialAPIKey
    self.onCancel = onCancel
    self.onUpgradeSuccess = onUpgradeSuccess

    let startingEngine = initialEngine
    _selectedEngine = State(initialValue: startingEngine)
    _candidateBaseURL = State(
      initialValue: initialBaseURL.isEmpty ? startingEngine.defaultBaseURL : initialBaseURL)
    let recommendedModel = preset.modelId(for: startingEngine == .custom ? .ollama : startingEngine)
    _candidateModelId = State(initialValue: recommendedModel)
    _candidateAPIKey = State(initialValue: initialAPIKey)
  }

  var body: some View {
    ScrollView(.vertical, showsIndicators: true) {
      VStack(alignment: .leading, spacing: 24) {
        HStack {
          VStack(alignment: .leading, spacing: 6) {
            Text("升级到 \(preset.displayName)")
              .font(.custom("Figtree", size: 22))
              .fontWeight(.semibold)
            Text(
              "按下面步骤操作并运行快速测试；成功后 Dayflow 会自动切换。"
            )
            .font(.custom("Figtree", size: 13))
            .foregroundColor(SettingsStyle.secondary)
          }
          Spacer()
          Button(action: onCancel) {
            Image(systemName: "xmark.circle.fill")
              .font(.system(size: 20))
              .foregroundColor(SettingsStyle.meta)
          }
          .buttonStyle(.plain)
          .pointingHandCursor()
        }

        VStack(alignment: .leading, spacing: 6) {
          ForEach(preset.settingsHighlightBullets, id: \.self) { bullet in
            HStack(spacing: 8) {
              Image(systemName: "sparkle")
                .font(.system(size: 12))
                .foregroundColor(SettingsStyle.ink)
              Text(bullet)
                .font(.custom("Figtree", size: 13))
                .foregroundColor(SettingsStyle.text)
            }
          }
        }

        VStack(alignment: .leading, spacing: 12) {
          Text("你正在使用哪种本地运行方式？")
            .font(.custom("Figtree", size: 14))
            .foregroundColor(SettingsStyle.secondary)
          Picker("引擎", selection: $selectedEngine) {
            Text("Ollama").tag(LocalEngine.ollama)
            Text("LM Studio").tag(LocalEngine.lmstudio)
            Text("自定义").tag(LocalEngine.custom)
          }
          .pickerStyle(.segmented)
          .frame(maxWidth: 420)
        }

        instructionView(for: selectedEngine)

        LocalLLMTestView(
          baseURL: $candidateBaseURL,
          modelId: $candidateModelId,
          apiKey: $candidateAPIKey,
          engine: selectedEngine,
          showInputs: true,
          buttonLabel: "测试升级",
          basePlaceholder: selectedEngine.defaultBaseURL,
          modelPlaceholder: preset.modelId(
            for: selectedEngine == .custom ? .ollama : selectedEngine),
          onTestComplete: { success in
            if success && !didApplyUpgrade {
              didApplyUpgrade = true
              onUpgradeSuccess(selectedEngine, candidateBaseURL, candidateModelId, candidateAPIKey)
            }
          }
        )

        Text(
          "测试成功后，Dayflow 会自动把设置更新为 \(preset.displayName)。"
        )
        .font(.custom("Figtree", size: 12))
        .foregroundColor(SettingsStyle.secondary)

        HStack {
          Spacer()
          SettingsSecondaryButton(title: "关闭", action: onCancel)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(32)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .onChange(of: selectedEngine) { _, newEngine in
      candidateModelId = preset.modelId(for: newEngine == .custom ? .ollama : newEngine)
      if newEngine != .custom {
        candidateBaseURL = newEngine.defaultBaseURL
        candidateAPIKey = ""
      }
    }
  }

  @ViewBuilder
  private func instructionView(for engine: LocalEngine) -> some View {
    let instruction = preset.settingsInstructions(for: engine == .custom ? .ollama : engine)
    VStack(alignment: .leading, spacing: 12) {
      Text(instruction.title)
        .font(.custom("Figtree", size: 16))
        .fontWeight(.semibold)
      Text(instruction.subtitle)
        .font(.custom("Figtree", size: 13))
        .foregroundColor(SettingsStyle.secondary)
      VStack(alignment: .leading, spacing: 6) {
        ForEach(Array(instruction.bullets.enumerated()), id: \.offset) { index, bullet in
          HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("\(index + 1).")
              .font(.custom("Figtree", size: 13))
              .foregroundColor(SettingsStyle.secondary)
              .frame(width: 18, alignment: .leading)
            Text(bullet)
              .font(.custom("Figtree", size: 13))
              .foregroundColor(SettingsStyle.text)
          }
        }
      }

      if let command = instruction.command,
        let commandTitle = instruction.commandTitle,
        let commandSubtitle = instruction.commandSubtitle
      {
        TerminalCommandView(
          title: commandTitle,
          subtitle: commandSubtitle,
          command: command
        )
      }

      if let buttonTitle = instruction.buttonTitle,
        let url = instruction.buttonURL
      {
        SettingsPrimaryButton(
          title: buttonTitle,
          systemImage: "arrow.down.circle.fill",
          action: { NSWorkspace.shared.open(url) }
        )
      }

      if let note = instruction.note {
        Text(note)
          .font(.custom("Figtree", size: 12))
          .foregroundColor(SettingsStyle.secondary)
      }
    }
    .padding(20)
    .dayflowCard(cornerRadius: 12)
  }
}

private extension LocalModelPreset {
  var settingsHighlightBullets: [String] {
    switch self {
    case .qwen3VL4B:
      return [
        "新的、更强的本地 VLM",
        "复杂使用场景下拥有更长推理链",
        "适配大多数 Apple Silicon 设备（约 5GB 显存）",
      ]
    case .qwen25VL3B:
      return [
        "Dayflow 本地模式的旧默认模型",
        "显存占用更低，但感知能力较弱",
      ]
    }
  }

  func settingsInstructions(for engine: LocalEngine) -> LocalModelInstructionSet {
    switch engine {
    case .ollama, .custom:
      return LocalModelInstructionSet(
        title: "通过 Ollama 安装",
        subtitle: "拉取模型前，请确认 Ollama 已升级到 0.12.10 或更新版本。",
        bullets: [
          "打开终端",
          "运行下面的拉取命令（约 5GB 下载）",
          "保持 Ollama 在后台运行",
        ],
        commandTitle: "运行此命令：",
        commandSubtitle: "为 Ollama 下载 \(displayName)",
        command: ollamaPullCommand,
        buttonTitle: nil,
        buttonURL: nil,
        note: "需要继续使用 Qwen2.5？保留当前模型并跳过本次升级即可。"
      )
    case .lmstudio:
      return LocalModelInstructionSet(
        title: "在 LM Studio 中安装",
        subtitle: "请确认 LM Studio 已升级到 0.3.31，并使用模型浏览器下载 GGUF 构建。",
        bullets: [
          "打开 LM Studio 并点击 Models 标签",
          "搜索“\(modelId(for: .lmstudio))”",
          "下载 Instruct 变体，然后启动 Local Server",
        ],
        commandTitle: nil,
        commandSubtitle: nil,
        command: nil,
        buttonTitle: "在 LM Studio 中打开下载",
        buttonURL: lmStudioDownloadURL,
        note:
          "提示：启用“Launch local server”，让 Dayflow 可以通过 \(LocalEngine.lmstudio.defaultBaseURL) 连接 LM Studio。"
      )
    }
  }
}
