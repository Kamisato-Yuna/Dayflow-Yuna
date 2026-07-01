//
//  ChatView.swift
//  Dayflow
//
//  Chat interface for asking questions about activity data.
//

import AppKit
import Charts
import SwiftUI

let chatViewDebugTimestampFormatter: DateFormatter = {
  let formatter = DateFormatter()
  formatter.dateFormat = "HH:mm:ss.SSS"
  return formatter
}()

let chatView记忆UpdatedFormatter: DateFormatter = {
  let formatter = DateFormatter()
  formatter.dateFormat = "MMM d, h:mm a"
  return formatter
}()

struct ChatView: View {
  @ObservedObject var chatService = ChatService.shared
  @State var inputText = ""
  @State var showWorkDetails = false
  @State var isInput专注ed = false
  @State var composer专注Token = 0
  @Namespace var bottomID
  @AppStorage("dashboardChatProvider") var selectedProviderRaw: String = "gemini"
  @AppStorage("chatCLIPreferredTool") var chatCLIPreferredTool: String = "codex"
  @AppStorage("hasChatBetaAccepted") var hasBetaAccepted: Bool = false
  @State var geminiConfigured = false
  @State var codexDetected = false
  @State var claudeDetected = false
  @State var completedAccessBatch数量 = 0
  @State var cliDetectionTask: Task<Void, Never>?
  @State var didCheckCLI = false
  @State var showToolSwitchConfirm = false
  @State var pendingProviderSelection: DashboardChatProvider?
  @State var conversationId: UUID?
  @State var didAnimateWelcome = false
  @State var show记忆Panel = false
  @State var memoryDraft = ""
  @State var stored记忆Blob = ""
  @State var memoryUpdatedAt: Date?
  @State var chatVoteSelections: [UUID: TimelineRatingDirection] = [:]
  @State var thankedMessageIDs: Set<UUID> = []
  @State var thank重置Tasks: [UUID: Task<Void, Never>] = [:]
  @State var chatFeedbackTarget: ChatFeedbackTarget?
  @State var chatFeedbackMessage = ""
  @State var chatFeedbackShareLogs = true
  @State var chatFeedbackMode: TimelineFeedbackMode = .form
  @Environment(\.accessibilityReduceMotion) var reduceMotion

  var body: some View {
    ZStack {
      if isUnlocked {
        HStack(spacing: 0) {
          chatContent
          if show记忆Panel {
            memoryPanel
          }
          if chatService.showDebugPanel {
            debugPanel
          }
        }
        .allowsHit测试ing(chatFeedbackTarget == nil)
        .transition(.opacity)

        if let chatFeedbackTarget {
          TimelineFeedbackModal(
            message: $chatFeedbackMessage,
            shareLogs: $chatFeedbackShareLogs,
            direction: chatFeedbackTarget.direction,
            mode: chatFeedbackMode,
            content: .chat,
            onSubmit: submitChatFeedback,
            onClose: { dismissChatFeedback() }
          )
          .padding(.leading, 20)
          .padding(.bottom, 16)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
          .transition(.move(edge: .bottom).combined(with: .opacity))
          .zIndex(2)
        }
      } else {
        betaLockScreen
          .transition(.opacity.combined(with: .move(edge: .bottom)))
      }
    }
    .task {
      guard !didCheckCLI else { return }
      didCheckCLI = true
      refreshChatAccessProgress()
      await refreshRuntimeAvailability()
    }
    .onAppear {
      refreshChatAccessProgress()
      load记忆FromStore(resetDraft: true)
      Task { await refreshRuntimeAvailability() }
    }
    .onReceive(Timer.publish(every: 30, on: .main, in: .common).autoconnect()) { _ in
      refreshChatAccessProgress()
    }
    .onDisappear {
      cliDetectionTask?.cancel()
      cliDetectionTask = nil
      for task in thank重置Tasks.values {
        task.cancel()
      }
      thank重置Tasks.remove全部()
    }
    .onChange(of: chatService.messages.count) { _, _ in
      sync记忆FromStoreIfNeeded()
    }
    .alert("切换提供方？", isPresented: $showToolSwitchConfirm) {
      Button("切换并重置", role: .destructive) {
        confirmProviderSwitch()
      }
      Button("取消", role: .cancel) {
        pendingProviderSelection = nil
      }
    } message: {
      Text("切换为 \(pendingProviderLabel) 后会清空当前对话的上下文。")
    }
    .environment(\.colorScheme, .light)
  }
}
