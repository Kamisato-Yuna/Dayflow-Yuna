import AppKit
import Charts
import SwiftUI

extension ChatView {
  var selectedProvider: DashboardChatProvider {
    DashboardChatProvider.fromStoredValue(selectedProviderRaw)
  }

  var isUnlocked: Bool {
    hasBetaAccepted && hasChatMinimumAccess
  }

  var anyRuntimeAvailable: Bool {
    geminiConfigured || codexDetected || claudeDetected
  }

  var hasChatMinimumAccess: Bool {
    FeatureAccessRequirements.hasRequiredBatches(
      completedAccessBatchCount,
      requiredBatchCount: FeatureAccessRequirements.chatRequiredBatchCount
    )
  }

  var chatAccessProgressText: String {
    FeatureAccessRequirements.progressText(
      completedBatchCount: completedAccessBatchCount,
      requiredHours: FeatureAccessRequirements.chatRequiredHours
    )
  }

  var selectedProviderAvailable: Bool {
    isProviderAvailable(selectedProvider)
  }

  var welcomePrompts: [WelcomePrompt] {
    [
      WelcomePrompt(icon: "doc.text", text: "生成昨天的站会更新"),
      WelcomePrompt(icon: "checkmark.seal", text: "我上周完成了什么？"),
      WelcomePrompt(
        icon: "exclamationmark.bubble", text: "这周什么时候最专注？"),
      WelcomePrompt(
        icon: "sparkles", text: "对比这周和上周"),
    ]
  }

  var welcomeHeroAnimation: Animation {
    if reduceMotion {
      return .easeOut(duration: 0.01)
    }
    return .timingCurve(0.16, 1, 0.3, 1, duration: 0.42)
  }

  var feedbackStateAnimation: Animation {
    if reduceMotion {
      return .easeOut(duration: 0.01)
    }
    return .easeOut(duration: 0.18)
  }

  var feedbackModalAnimation: Animation {
    if reduceMotion {
      return .easeOut(duration: 0.01)
    }
    return .spring(response: 0.28, dampingFraction: 0.88)
  }

  func welcomeSuggestionAnimation(at index: Int) -> Animation {
    if reduceMotion {
      return .easeOut(duration: 0.01)
    }
    return .timingCurve(0.16, 1, 0.3, 1, duration: 0.34)
      .delay(Double(index) * 0.045)
  }

  var trimmedInputText: String {
    inputText.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  var canSubmitCurrentInput: Bool {
    !chatService.isProcessing && !trimmedInputText.isEmpty && selectedProviderAvailable
  }

  var composerBorderColor: Color {
    if isInputFocused {
      return ChatSurfacePalette.accent.opacity(
        NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast ? 0.78 : 0.58
      )
    }
    return ChatSurfacePalette.border(
      colorScheme: colorScheme,
      increaseContrast: NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
    )
  }

  var memoryCharacterCount: Int {
    memoryDraft.count
  }

  var isMemoryDirty: Bool {
    memoryDraft != storedMemoryBlob
  }

  var memoryUpdatedLabel: String {
    guard let memoryUpdatedAt else { return "尚未保存" }
    return chatViewMemoryUpdatedFormatter.string(from: memoryUpdatedAt)
  }
}
