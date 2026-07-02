import AppKit
import Foundation
import SwiftUI

struct LLMProviderSetupView: View {
  let providerType: String  // "ollama" or "gemini"
  let onBack: () -> Void
  let onComplete: () -> Void

  var activeProviderType: String { providerType }

  var headerTitle: String {
    switch activeProviderType {
    case "ollama":
      return "本地 AI"
    case "chatgpt_claude":
      return "连接 ChatGPT 或 Claude"
    default:
      return "Gemini"
    }
  }

  // Layout constants
  let sidebarWidth: CGFloat = 250
  let fixedOffset: CGFloat = 50

  @StateObject var setupState = ProviderSetupState()
  @State var sidebarOpacity: Double = 0
  @State var contentOpacity: Double = 0

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // Header with Back button and Title on same line
      HStack(alignment: .center, spacing: 0) {
        // Back button container matching sidebar width
        HStack {
          Button(action: handleBack) {
            HStack(spacing: 12) {
              Image(systemName: "chevron.left")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.black.opacity(0.7))
                .frame(width: 20, alignment: .center)

              Text("返回")
                .font(.custom("Figtree", size: 15))
                .fontWeight(.medium)
                .foregroundColor(.black.opacity(0.7))
            }
          }
          .buttonStyle(DayflowPressScaleButtonStyle(pressedScale: 0.97))
          // Position where sidebar items start: 20 + 16 = 36px
          .padding(.leading, 36)  // Align with sidebar item structure
          .pointingHandCursor()

          Spacer()
        }
        .frame(width: sidebarWidth)

        // Title in the content area
        HStack {
          Text(headerTitle)
            .font(.custom("Figtree", size: 32))
            .fontWeight(.semibold)
            .foregroundColor(.black.opacity(0.9))

          Spacer()
        }
        .padding(.leading, 40)  // Gap between sidebar and content
      }
      .padding(.leading, fixedOffset)
      .padding(.top, fixedOffset / 2)
      .padding(.bottom, 20)

      // Main content area with sidebar and content
      HStack(alignment: .top, spacing: 40) {
        // Sidebar - fixed width 250px
        VStack(alignment: .leading, spacing: 0) {
          SetupSidebarView(
            steps: setupState.steps,
            currentStepId: setupState.currentStep.id,
            onStepSelected: { setupState.navigateToStep($0) }
          )
          Spacer()
        }
        .frame(width: sidebarWidth)
        .opacity(sidebarOpacity)

        // Content area - wrapped in VStack to match sidebar alignment
        VStack(alignment: .leading, spacing: 0) {
          currentStepContent
            .frame(maxWidth: 500, alignment: .leading)
          Spacer()
        }
        .opacity(contentOpacity)
        .textSelection(.enabled)
      }
      .padding(.leading, fixedOffset)

      Spacer()  // Push everything to top
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .onAppear {
      setupState.configureSteps(for: activeProviderType)
      animateAppearance()
    }
    .preferredColorScheme(.light)
  }

  var nextButtonText: String {
    if (setupState.currentStep.id == "test" || setupState.currentStep.id == "verify")
      && !setupState.testSuccessful
    {
      return "请先完成测试"
    }
    return "下一步"
  }

  @ViewBuilder
  var nextButton: some View {
    if setupState.isLastStep {
      DayflowSurfaceButton(
        action: {
          saveConfiguration()
          onComplete()
        },
        content: {
          HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill").font(.system(size: 14))
            Text("完成设置").font(.custom("Figtree", size: 14)).fontWeight(.semibold)
          }
        },
        background: Color(red: 0.25, green: 0.17, blue: 0),
        foreground: .white,
        borderColor: .clear,
        cornerRadius: 8,
        horizontalPadding: 24,
        verticalPadding: 12,
        showOverlayStroke: true
      )
    } else {
      DayflowSurfaceButton(
        action: handleContinue,
        content: {
          HStack(spacing: 6) {
            Text(nextButtonText).font(.custom("Figtree", size: 14)).fontWeight(.semibold)
            if nextButtonText == "下一步" {
              Image(systemName: "chevron.right").font(.system(size: 12, weight: .medium))
            }
          }
        },
        background: Color(red: 0.25, green: 0.17, blue: 0),
        foreground: .white,
        borderColor: .clear,
        cornerRadius: 8,
        horizontalPadding: 24,
        verticalPadding: 12,
        showOverlayStroke: true
      )
      .disabled(!setupState.canContinue)
      .opacity(!setupState.canContinue ? 0.5 : 1.0)
    }
  }

  @ViewBuilder
  var currentStepContent: some View {
    let step = setupState.currentStep

    switch step.contentType {
    case .localChoice:
      VStack(alignment: .leading, spacing: 20) {
        VStack(alignment: .leading, spacing: 8) {
          Text("选择本地 AI 引擎")
            .font(.custom("Figtree", size: 24))
            .fontWeight(.semibold)
            .foregroundColor(.black.opacity(0.9))
          Text(
            "对于本地使用，LM Studio 最可靠；Ollama 在 onboarding 中已知会遇到无法关闭“思考模式”的问题，并且性能不稳定。"
          )
          .font(.custom("Figtree", size: 14))
          .foregroundColor(.black.opacity(0.6))
        }
        HStack(alignment: .center, spacing: 12) {
          DayflowSurfaceButton(
            action: {
              setupState.selectEngine(.lmstudio)
              openLMStudioDownload()
            },
            content: {
              AsyncImage(
                url: URL(
                  string:
                    "https://lmstudio.ai/_next/image?url=%2F_next%2Fstatic%2Fmedia%2Flmstudio-app-logo.11b4d746.webp&w=96&q=75"
                )
              ) { phase in
                switch phase {
                case .success(let image): image.resizable().scaledToFit()
                case .failure(_):
                  Image(systemName: "desktopcomputer").resizable().scaledToFit().foregroundColor(
                    .white.opacity(0.6))
                case .empty: ProgressView().scaleEffect(0.7)
                @unknown default: EmptyView()
                }
              }
              .frame(width: 18, height: 18)
              Text("下载 LM Studio")
                .font(.custom("Figtree", size: 14))
                .fontWeight(.semibold)
            },
            background: Color(red: 0.25, green: 0.17, blue: 0),
            foreground: .white,
            borderColor: .clear,
            cornerRadius: 8,
            showOverlayStroke: true
          )
        }
        Text(
          "你已经有本地服务了吗？请确认其兼容 OpenAI API。下一步可设置自定义 Base URL。"
        )
        .font(.custom("Figtree", size: 13))
        .foregroundColor(.black.opacity(0.6))
        HStack {
          Spacer()
          nextButton
        }
      }
    case .localModelInstall:
      VStack(alignment: .leading, spacing: 16) {
        Text("安装 Qwen3-VL 4B")
          .font(.custom("Figtree", size: 24))
          .fontWeight(.semibold)
          .foregroundColor(.black.opacity(0.9))
        if setupState.localEngine == .ollama {
          Text("安装并启动 Ollama 后，在终端运行以下命令下载模型（约 5GB）：")
            .font(.custom("Figtree", size: 14))
            .foregroundColor(.black.opacity(0.6))
          TerminalCommandView(
            title: "执行以下命令：",
            subtitle: "用于为 Ollama 下载 Qwen3-VL 4B",
            command: "ollama pull qwen3-vl:4b"
          )
        } else if setupState.localEngine == .lmstudio {
          VStack(alignment: .leading, spacing: 16) {
            Text("安装 LM Studio 后，下载推荐模型：")
              .font(.custom("Figtree", size: 14))
              .foregroundColor(.black.opacity(0.6))

            DayflowSurfaceButton(
              action: openLMStudioModelDownload,
              content: {
                HStack(spacing: 8) {
                  Image(systemName: "arrow.down.circle.fill").font(.system(size: 14))
                  Text("在 LM Studio 中下载 Qwen3-VL 4B").font(.custom("Figtree", size: 14))
                    .fontWeight(.semibold)
                }
              },
              background: Color(red: 0.25, green: 0.17, blue: 0),
              foreground: .white,
              borderColor: .clear,
              cornerRadius: 8,
              horizontalPadding: 24,
              verticalPadding: 12,
              showOverlayStroke: true
            )

            VStack(alignment: .leading, spacing: 6) {
              Text("此操作会打开 LM Studio，并提示你下载该模型（约 3GB）。")
                .font(.custom("Figtree", size: 13))
                .foregroundColor(.black.opacity(0.65))

              Text(
                "下载完成后，在 LM Studio 开启“Local Server”（默认地址 http://localhost:1234）"
              )
              .font(.custom("Figtree", size: 13))
              .foregroundColor(.black.opacity(0.65))
            }
            .padding(.top, 4)

            // Fallback manual instructions
            VStack(alignment: .leading, spacing: 4) {
              Text("手动设置：")
                .font(.custom("Figtree", size: 12))
                .fontWeight(.semibold)
                .foregroundColor(.black.opacity(0.5))
              Text("1. 打开 LM Studio 的 Models 标签页")
                .font(.custom("Figtree", size: 12))
                .foregroundColor(.black.opacity(0.45))
              Text("2. 搜索“Qwen3-VL-4B”，安装 Instruct 版本")
                .font(.custom("Figtree", size: 12))
                .foregroundColor(.black.opacity(0.45))
            }
            .padding(.top, 8)
          }
        } else {
          VStack(alignment: .leading, spacing: 8) {
            Text("使用任意 OpenAI 兼容 VLM")
              .font(.custom("Figtree", size: 16))
              .fontWeight(.semibold)
              .foregroundColor(.black.opacity(0.85))
            Text(
              "请确认你的服务端暴露了 OpenAI Chat Completions API，并安装了 Qwen3-VL 4B（若需要旧版模型可选 Qwen2.5-VL 3B）。"
            )
            .font(.custom("Figtree", size: 14))
            .foregroundColor(.black.opacity(0.75))
          }
        }
        HStack {
          Spacer()
          nextButton
        }
      }
    case .terminalCommand(let command):
      VStack(alignment: .leading, spacing: 24) {
        TerminalCommandView(
          title: "终端命令：",
          subtitle: "复制以下命令并在终端执行",
          command: command
        )

        HStack {
          Spacer()
          nextButton
        }
      }

    case .apiKeyInput:
      VStack(alignment: .leading, spacing: 24) {
        APIKeyInputView(
          apiKey: $setupState.apiKey,
          title: "输入你的 API Key：",
          subtitle: "请在下方粘贴 Gemini API Key",
          placeholder: "AQ...",
          onValidate: { key in
            key.components(separatedBy: .whitespacesAndNewlines).joined().count > 10
          }
        )
        .onChange(of: setupState.apiKey) { _, _ in
          setupState.clearGeminiAPIKeySaveError()
        }

        if let message = setupState.geminiAPIKeySaveError {
          HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
              .font(.system(size: 12))
              .foregroundColor(Color(hex: "E91515"))

            Text(message)
              .font(.custom("Figtree", size: 13))
              .foregroundColor(Color(hex: "E91515"))
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 10)
          .background(
            RoundedRectangle(cornerRadius: 4)
              .fill(Color(hex: "E91515").opacity(0.1))
          )
          .overlay(
            RoundedRectangle(cornerRadius: 4)
              .stroke(Color(hex: "E91515").opacity(0.3), lineWidth: 1)
          )
        }

        VStack(alignment: .leading, spacing: 12) {
          Text(
            "请选择 Gemini 模型。推荐 3.5 Flash，3.1 Flash-Lite 可作为备用。"
          )
          .font(.custom("Figtree", size: 16))
          .fontWeight(.semibold)
          .foregroundColor(.black.opacity(0.85))

          Picker("Gemini 模型", selection: $setupState.geminiModel) {
            ForEach(GeminiModel.allCases, id: \.self) { model in
              Text(model.shortLabel).tag(model)
            }
          }
          .pickerStyle(.segmented)

          Text(GeminiModelPreference(primary: setupState.geminiModel).fallbackSummary)
            .font(.custom("Figtree", size: 13))
            .foregroundColor(.black.opacity(0.55))
        }
        .onChange(of: setupState.geminiModel) {
          setupState.persistGeminiModelSelection(source: "onboarding_picker")
        }

        HStack {
          Spacer()
          nextButton
        }
      }

    case .modelDownload(let command):
      VStack(alignment: .leading, spacing: 24) {
        VStack(alignment: .leading, spacing: 8) {
          Text("下载 AI 模型")
            .font(.custom("Figtree", size: 24))
            .fontWeight(.semibold)
            .foregroundColor(.black.opacity(0.9))

          Text("该模型可帮助 Dayflow 理解你当前屏幕内容")
            .font(.custom("Figtree", size: 14))
            .foregroundColor(.black.opacity(0.6))
        }

        TerminalCommandView(
          title: "执行以下命令：",
          subtitle:
            "此命令将下载 \(LocalModelPreset.qwen3VL4B.displayName)（约 5GB）",
          command: command
        )

        HStack {
          Spacer()
          nextButton
        }
      }

    case .information(let title, let description):
      VStack(alignment: .leading, spacing: 24) {
        VStack(alignment: .leading, spacing: 16) {
          Text(title)
            .font(.custom("Figtree", size: 24))
            .fontWeight(.semibold)
            .foregroundColor(.black.opacity(0.9))
          if !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Text(description)
              .font(.custom("Figtree", size: 14))
              .foregroundColor(.black.opacity(0.6))
              .fixedSize(horizontal: false, vertical: true)
              .multilineTextAlignment(.leading)
              .lineLimit(nil)
            // Additional guidance for the local intro step only
            if step.id == "intro" && providerType == "ollama" {
              (Text("高级用户可任意选择") + Text("具备视觉能力").fontWeight(.bold)
                + Text("的 LLM，但基于内部测试更推荐使用 Qwen3-VL 4B。"))
                .font(.custom("Figtree", size: 14))
                .foregroundColor(.black.opacity(0.6))
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
            }
          }
        }

        // Content area scrolls if needed; Next stays visible below
        ScrollView(.vertical, showsIndicators: true) {
          VStack(alignment: .leading, spacing: 16) {
            if step.id == "test" || step.id == "verify" {
              if providerType == "gemini" {
                TestConnectionView(
                  onTestComplete: { success in
                    setupState.hasTestedConnection = true
                    setupState.testSuccessful = success
                  }
                )
              } else if providerType == "chatgpt_claude" {
                ChatCLITestView(
                  selectedTool: setupState.preferredCLITool,
                  onTestComplete: { success in
                    setupState.hasTestedConnection = true
                    setupState.testSuccessful = success
                  }
                )
              } else {
                // Engine selection: LM Studio or Custom
                VStack(alignment: .leading, spacing: 12) {
                  Text("你正在使用哪种工具？")
                    .font(.custom("Figtree", size: 14))
                    .foregroundColor(.black.opacity(0.65))
                  Picker("引擎", selection: $setupState.localEngine) {
                    Text("LM Studio").tag(LocalEngine.lmstudio)
                    Text("自定义模型").tag(LocalEngine.custom)
                  }
                  .pickerStyle(.segmented)
                  .frame(maxWidth: 380)
                }
                .onChange(of: setupState.localEngine) { _, newValue in
                  setupState.selectEngine(newValue)
                }

                LocalLLMTestView(
                  baseURL: $setupState.localBaseURL,
                  modelId: $setupState.localModelId,
                  apiKey: $setupState.localAPIKey,
                  engine: setupState.localEngine,
                  showInputs: setupState.localEngine == .custom,
                  onTestComplete: { success in
                    setupState.hasTestedConnection = true
                    setupState.testSuccessful = success
                  }
                )
              }
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.trailing, 2)
        }
        .frame(maxHeight: 420)

        HStack {
          Spacer()
          nextButton
        }
      }

    case .cliDetection:
      ChatCLIDetectionStepView(
        codexStatus: setupState.codexCLIStatus,
        codexReport: setupState.codexCLIReport,
        claudeStatus: setupState.claudeCLIStatus,
        claudeReport: setupState.claudeCLIReport,
        isChecking: setupState.isCheckingCLIStatus,
        onRetry: { setupState.refreshCLIStatuses() },
        onInstall: { tool in openChatCLIInstallPage(for: tool) },
        selectedTool: setupState.preferredCLITool,
        onSelectTool: { tool in setupState.selectPreferredCLITool(tool) },
        nextButton: { nextButton }
      )
      .onAppear {
        setupState.ensureCLICheckStarted()
      }

    case .apiKeyInstructions:
      VStack(alignment: .leading, spacing: 24) {
        VStack(alignment: .leading, spacing: 8) {
          Text("获取你的 Gemini API Key")
            .font(.custom("Figtree", size: 24))
            .fontWeight(.semibold)
            .foregroundColor(.black.opacity(0.9))

          Text(
            "你可使用该方式免费使用 Dayflow。你只需一个 Google 账号，无需提供信用卡。"
          )
          .font(.custom("Figtree", size: 14))
          .foregroundColor(.black.opacity(0.6))
        }

        VStack(alignment: .leading, spacing: 16) {
          HStack(alignment: .top, spacing: 12) {
            Text("1.")
              .font(.custom("Figtree", size: 14))
              .foregroundColor(.black.opacity(0.6))
              .frame(width: 20, alignment: .leading)

            Group {
              Text("打开 Google AI Studio")
                .font(.custom("Figtree", size: 14))
                .foregroundColor(.black.opacity(0.8))
                + Text("(aistudio.google.com)")
                .font(.custom("Figtree", size: 14))
                .foregroundColor(Color(red: 1, green: 0.42, blue: 0.02))
                .underline()
            }
            .onTapGesture { openGoogleAIStudio() }
            .pointingHandCursor()
          }

          HStack(alignment: .top, spacing: 12) {
            Text("2.")
              .font(.custom("Figtree", size: 14))
              .foregroundColor(.black.opacity(0.6))
              .frame(width: 20, alignment: .leading)

            Text("点击右上角“获取 API key”")
              .font(.custom("Figtree", size: 14))
              .foregroundColor(.black.opacity(0.8))
          }

          HStack(alignment: .top, spacing: 12) {
            Text("3.")
              .font(.custom("Figtree", size: 14))
              .foregroundColor(.black.opacity(0.6))
              .frame(width: 20, alignment: .leading)

            Text("创建新的 API Key 并复制")
              .font(.custom("Figtree", size: 14))
              .foregroundColor(.black.opacity(0.8))
          }
        }
        .padding(.vertical, 12)

        // Buttons row with Open Google AI Studio on left, Next on right
        HStack {
          DayflowSurfaceButton(
            action: openGoogleAIStudio,
            content: {
              HStack(spacing: 8) {
                Image(systemName: "safari").font(.system(size: 14))
                Text("打开 Google AI Studio").font(.custom("Figtree", size: 14)).fontWeight(
                  .semibold)
              }
            },
            background: Color(red: 0.25, green: 0.17, blue: 0),
            foreground: .white,
            borderColor: .clear,
            cornerRadius: 8,
            horizontalPadding: 24,
            verticalPadding: 12,
            showOverlayStroke: true
          )
          Spacer()
          nextButton
        }
      }
    }
  }

  func handleBack() {
    if setupState.currentStepIndex == 0 {
      onBack()
    } else {
      setupState.goBack()
    }
  }

  func handleContinue() {
    // Persist local config immediately after a successful local test when user advances
    if activeProviderType == "ollama" {
      if case .information = setupState.currentStep.contentType,
        (setupState.currentStep.id == "verify" || setupState.currentStep.id == "test"),
        setupState.testSuccessful
      {
        persistLocalSettings()
      }
    }

    if setupState.isLastStep {
      saveConfiguration()
      onComplete()
    } else {
      setupState.markCurrentStepCompleted()
      setupState.goNext()
    }
  }

  func saveConfiguration() {
    // Save API key to keychain for Gemini
    if activeProviderType == "gemini" && !setupState.apiKey.isEmpty {
      let cleanedKey = setupState.apiKey.components(separatedBy: .whitespacesAndNewlines).joined()
      KeychainManager.shared.store(cleanedKey, for: "gemini")
      GeminiModelPreference(primary: setupState.geminiModel).save()
    }

    // Save local endpoint for local engine selection
    if activeProviderType == "ollama" {
      persistLocalSettings()
    }

    // Mark setup as complete
    UserDefaults.standard.set(true, forKey: "\(activeProviderType)SetupComplete")
  }

  // Persist provider choice + local settings without marking setup complete
  func persistLocalSettings() {
    let endpoint = setupState.localBaseURL
    let type = LLMProviderType.ollamaLocal(endpoint: endpoint)
    type.persist()
    // Store model id for local engines
    UserDefaults.standard.set(setupState.localModelId, forKey: "llmLocalModelId")
    LocalModelPreferences.syncPreset(for: setupState.localEngine, modelId: setupState.localModelId)
    // Store local engine selection for header/model defaults
    UserDefaults.standard.set(setupState.localEngine.rawValue, forKey: "llmLocalEngine")
    // Also store the endpoint explicitly for other parts of the app if needed
    UserDefaults.standard.set(endpoint, forKey: "llmLocalBaseURL")
    persistLocalAPIKey(setupState.localAPIKey)
  }

  func persistLocalAPIKey(_ value: String) {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty {
      UserDefaults.standard.removeObject(forKey: "llmLocalAPIKey")
    } else {
      UserDefaults.standard.set(trimmed, forKey: "llmLocalAPIKey")
    }
  }

  func openGoogleAIStudio() {
    if let url = URL(string: "https://aistudio.google.com/app/apikey") {
      NSWorkspace.shared.open(url)
    }
  }

  func openLMStudioDownload() {
    if let url = URL(string: "https://lmstudio.ai/") {
      NSWorkspace.shared.open(url)
    }
  }

  func openLMStudioModelDownload() {
    if let url = URL(
      string: "https://model.lmstudio.ai/download/lmstudio-community/Qwen3-VL-4B-Instruct-GGUF")
    {
      NSWorkspace.shared.open(url)
    }
  }

  func openChatCLIInstallPage(for tool: CLITool) {
    guard let url = tool.installURL else { return }
    NSWorkspace.shared.open(url)
  }

  func animateAppearance() {
    withAnimation(.easeOut(duration: 0.4)) {
      sidebarOpacity = 1
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      withAnimation(.easeOut(duration: 0.4)) {
        contentOpacity = 1
      }
    }
  }
}
