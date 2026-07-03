//
//  OnboardingLLMSelectionView.swift
//  Dayflow
//
//  LLM provider selection view for onboarding flow
//

import AppKit
import SwiftUI

struct OnboardingLLMSelectionView: View {
  // Navigation callbacks
  var onBack: () -> Void
  var onNext: (String) -> Void  // Now passes the selected provider

  @AppStorage("selectedLLMProvider") private var selectedProvider: String = "gemini"  // Default to "Bring your own API"
  @State private var titleOpacity: Double = 0
  @State private var cardsOpacity: Double = 0
  @State private var bottomTextOpacity: Double = 0
  @State private var hasAppeared: Bool = false
  @State private var cliDetected: Bool = false
  @State private var cliDetectionTask: Task<Void, Never>?
  @State private var didUserSelectProvider: Bool = false

  var body: some View {
    GeometryReader { geometry in
      let windowWidth = geometry.size.width
      let windowHeight = geometry.size.height

      // Constants
      let edgePadding: CGFloat = 40
      let cardGap: CGFloat = 20
      let headerHeight: CGFloat = 70
      let footerHeight: CGFloat = 40

      // Card width calc (no min width, cap at 480)
      let availableWidth = windowWidth - (edgePadding * 2)
      let rawCardWidth = (availableWidth - (cardGap * 2)) / 3
      let cardWidth = max(1, min(480, floor(rawCardWidth)))

      // Card height calc
      let availableHeight = windowHeight - headerHeight - footerHeight
      let cardHeight = min(500, max(300, availableHeight - 20))

      // Title font size
      let titleSize: CGFloat = windowWidth <= 900 ? 32 : 48

      VStack(spacing: 0) {
        // Header
        Text("选择 Dayflow 的运行方式")
          .font(.custom("InstrumentSerif-Regular", size: titleSize))
          .multilineTextAlignment(.center)
          .foregroundColor(.black.opacity(0.9))
          .frame(maxWidth: .infinity)
          .frame(height: headerHeight)
          .opacity(titleOpacity)
          .onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
            detectCLIInstallation()
            withAnimation(.easeOut(duration: 0.6)) { titleOpacity = 1 }
            animateContent()
          }

        // Dynamic card area
        Spacer(minLength: 10)

        HStack(spacing: cardGap) {
          ForEach(providerCards, id: \.id) { card in
            card
              .frame(width: cardWidth, height: cardHeight)
          }
        }
        .padding(.horizontal, edgePadding)
        .opacity(cardsOpacity)

        Spacer(minLength: 10)

        // Footer
        HStack(spacing: 0) {
          Group {
            if cliDetected {
              Text("你已安装 Codex/Claude CLI！")
                .foregroundColor(.black.opacity(0.6))
                + Text("建议你用它来获得最佳体验。")
                .fontWeight(.semibold)
                .foregroundColor(.black.opacity(0.8))
                + Text(" 你可随时在设置中切换。")
                .foregroundColor(.black.opacity(0.6))
            } else {
              Text("不知道该选哪个？")
                .foregroundColor(.black.opacity(0.6))
                + Text("带自有密钥是最简单的设置方式（30 秒）。")
                .fontWeight(.semibold)
                .foregroundColor(.black.opacity(0.8))
                + Text(" 你可随时在设置中切换。")
                .foregroundColor(.black.opacity(0.6))
            }
          }
          .font(.custom("Figtree", size: 14))
          .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: footerHeight)
        .opacity(bottomTextOpacity)
      }
      .animation(.easeOut(duration: 0.2), value: cardWidth)
      .animation(.easeOut(duration: 0.2), value: cardHeight)
    }
    .onDisappear {
      cliDetectionTask?.cancel()
      cliDetectionTask = nil
    }
  }

  // Create provider cards as a computed property for reuse
  private var providerCards: [FlexibleProviderCard] {
    [
      // Run locally card
      FlexibleProviderCard(
        id: "ollama",
        title: "本地 AI",
        badgeText: "最私有",
        badgeType: .green,
        icon: "desktopcomputer",
        features: [
          ("100% 私有化，所有内容都在你的电脑上处理", true),
          ("可完全离线运行", true),
          ("智能性明显弱于在线模型", false),
          ("需要更多设置步骤", false),
          ("建议 16GB+ 内存", false),
          ("可能更耗电", false),
        ],
        isSelected: selectedProvider == "ollama",
        buttonMode: .onboarding(onProceed: {
          // Only proceed if this provider is selected
          if selectedProvider == "ollama" {
            saveProviderSelection()
            onNext("ollama")
          } else {
            // Select the card first
            withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
              didUserSelectProvider = true
              selectedProvider = "ollama"
            }
          }
        }),
        onSelect: {
          withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
            didUserSelectProvider = true
            selectedProvider = "ollama"
          }
        }
      ),

      // Bring your own API card (selected by default)
      FlexibleProviderCard(
        id: "gemini",
        title: "Gemini",
        badgeText: cliDetected ? "新增" : "推荐",
        badgeType: cliDetected ? .blue : .orange,
        icon: "gemini_asset",
        features: [
          ("通过 Google Gemini 模型使用更强 AI 能力", true),
          ("使用 Gemini 的免费额度（无需信用卡）", true),
          ("比本地模型更快更准确", true),
          ("需要获取 API 密钥（约 2 次点击）", false),
        ],
        isSelected: selectedProvider == "gemini",
        buttonMode: .onboarding(onProceed: {
          // Only proceed if this provider is selected
          if selectedProvider == "gemini" {
            saveProviderSelection()
            onNext("gemini")
          } else {
            // Select the card first
            withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
              didUserSelectProvider = true
              selectedProvider = "gemini"
            }
          }
        }),
        onSelect: {
          withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
            didUserSelectProvider = true
            selectedProvider = "gemini"
          }
        }
      ),

      // ChatGPT/Claude CLI card
      FlexibleProviderCard(
        id: "chatgpt_claude",
        title: "ChatGPT 或 Claude",
        badgeText: cliDetected ? "推荐" : "新增",
        badgeType: cliDetected ? .orange : .blue,
        icon: "chatgpt_claude_asset",
        features: [
          ("适合现有 ChatGPT Plus 或 Claude Pro 订阅用户", true),
          ("智能性与稳定性更强", true),
          ("对每日额度影响极小（<1%）", true),
          ("需要安装 Codex 或 Claude CLI", false),
          ("需要有效的 ChatGPT 或 Claude 付费订阅", false),
        ],
        isSelected: selectedProvider == "chatgpt_claude",
        buttonMode: .onboarding(onProceed: {
          if selectedProvider == "chatgpt_claude" {
            saveProviderSelection()
            onNext("chatgpt_claude")
          } else {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
              didUserSelectProvider = true
              selectedProvider = "chatgpt_claude"
            }
          }
        }),
        onSelect: {
          withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
            didUserSelectProvider = true
            selectedProvider = "chatgpt_claude"
          }
        }
      ),

    ]
  }

  private func saveProviderSelection() {
    let providerType: LLMProviderType

    switch selectedProvider {
    case "ollama":
      providerType = .ollamaLocal()
    case "gemini":
      providerType = .geminiDirect
    case "chatgpt_claude":
      providerType = .chatGPTClaude
    default:
      providerType = .geminiDirect
    }

    providerType.persist()
  }

  private func animateContent() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
      withAnimation(.easeOut(duration: 0.6)) {
        cardsOpacity = 1
      }
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
      withAnimation(.easeOut(duration: 0.4)) {
        bottomTextOpacity = 1
      }
    }
  }

  private func detectCLIInstallation() {
    cliDetectionTask?.cancel()
    cliDetectionTask = Task { @MainActor in
      let installed = await Task.detached(priority: .utility) {
        let codexInstalled = CLIDetector.isInstalled(.codex)
        let claudeInstalled = CLIDetector.isInstalled(.claude)
        return codexInstalled || claudeInstalled
      }.value

      guard !Task.isCancelled else { return }

      cliDetected = installed

      if !didUserSelectProvider {
        selectedProvider = installed ? "chatgpt_claude" : "gemini"
      }
    }
  }
}

struct OnboardingLLMSelectionView_Previews: PreviewProvider {
  static var previews: some View {
    OnboardingLLMSelectionView(
      onBack: {},
      onNext: { _ in }  // Takes provider string now
    )
    .frame(width: 1400, height: 900)
    .dayflowWindowBackground()
  }
}
