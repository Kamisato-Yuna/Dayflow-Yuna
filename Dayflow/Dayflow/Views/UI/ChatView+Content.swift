import AppKit
import Charts
import SwiftUI

extension ChatView {
  var chatContent: some View {
    VStack(alignment: .leading, spacing: 0) {
      // Header buttons
      HStack(spacing: 8) {
        Spacer()

        // Clear chat button (only show if there are messages)
        if !chatService.messages.isEmpty {
          Button(action: { resetConversation() }) {
            Text("清除")
              .font(.custom("Figtree", size: 12).weight(.semibold))
              .foregroundColor(ChatSurfacePalette.secondaryText)
              .padding(.horizontal, 10)
              .padding(.vertical, 6)
              .dayflowFloatingControl(cornerRadius: 8)
          }
          .buttonStyle(.plain)
          .help("清除对话")
          .pointingHandCursor()
        }

        // Debug toggle
        Button(action: { chatService.showDebugPanel.toggle() }) {
          Image(systemName: chatService.showDebugPanel ? "ladybug.fill" : "ladybug")
            .font(.system(size: 14))
            .foregroundColor(
              chatService.showDebugPanel ? ChatSurfacePalette.accent : ChatSurfacePalette.secondaryText)
            .frame(width: 22, height: 22)
        }
        .buttonStyle(.plain)
        .dayflowFloatingControl(cornerRadius: 8)
        .help("显示或隐藏调试面板")
        .pointingHandCursor()

        Button(
          action: {
            showMemoryPanel.toggle()
            if showMemoryPanel {
              syncMemoryFromStoreIfNeeded()
              AnalyticsService.shared.capture("chat_memory_panel_opened")
            }
          }
        ) {
          Image(systemName: showMemoryPanel ? "brain.head.profile.fill" : "brain.head.profile")
            .font(.system(size: 14))
            .foregroundColor(showMemoryPanel ? ChatSurfacePalette.accent : ChatSurfacePalette.secondaryText)
            .frame(width: 22, height: 22)
        }
        .buttonStyle(.plain)
        .dayflowFloatingControl(cornerRadius: 8)
        .help("显示或隐藏记忆面板")
        .pointingHandCursor()
      }
      .padding(.trailing, 12)
      .padding(.top, 8)

      // Messages area
      ScrollViewReader { proxy in
        ScrollView {
          LazyVStack(alignment: .leading, spacing: 16) {
            // Welcome message if empty
            if chatService.messages.isEmpty {
              welcomeView
            }

            // Messages
            ForEach(Array(chatService.messages.enumerated()), id: \.element.id) { index, message in
              if let status = chatService.workStatus,
                let insertionIndex = statusInsertionIndex,
                index == insertionIndex
              {
                WorkStatusCard(status: status, showDetails: $showWorkDetails)
              }
              ChatMessageRow(
                message: message,
                showsAssistantFooter: shouldShowAssistantFeedbackFooter(for: message),
                selectedDirection: chatVoteSelections[message.id],
                showsThanks: thankedMessageIDs.contains(message.id),
                onCopy: { copyAssistantMessage(message) },
                onRate: { direction in handleAssistantRating(direction, for: message) }
              )
            }
            if let status = chatService.workStatus,
              let insertionIndex = statusInsertionIndex,
              insertionIndex == chatService.messages.count
            {
              WorkStatusCard(status: status, showDetails: $showWorkDetails)
            }

            // Follow-up suggestions (show after last assistant message when not processing)
            if !chatService.isProcessing && !chatService.currentSuggestions.isEmpty {
              followUpSuggestions
            }

            // Anchor for auto-scroll
            Color.clear
              .frame(height: 1)
              .id(bottomID)
          }
          .padding(.horizontal, 16)
          .padding(.top, 16)
          .padding(.bottom, 20)
        }
        .scrollIndicators(.never)
        .onChange(of: chatService.messages.count) {
          withAnimation(.easeOut(duration: 0.2)) {
            proxy.scrollTo(bottomID, anchor: .bottom)
          }
        }
        .onChange(of: chatService.isProcessing) {
          if chatService.isProcessing {
            showWorkDetails = false
          }
          // Auto-scroll when processing starts
          withAnimation(.easeOut(duration: 0.2)) {
            proxy.scrollTo(bottomID, anchor: .bottom)
          }
        }
      }
      .onChange(of: chatService.messages.isEmpty) { _, isEmpty in
        if isEmpty {
          didAnimateWelcome = false
          resetChatFeedbackState()
        }
      }

      Divider()
        .background(ChatSurfacePalette.separator)

      // Input area
      inputArea
    }
    .dayflowContentPanel(cornerRadius: 18)
  }

  // MARK: - Debug Panel

  var debugPanel: some View {
    VStack(alignment: .leading, spacing: 0) {
      // Header
      HStack {
        Text("调试日志")
          .font(.custom("Figtree", size: 12).weight(.bold))
          .foregroundColor(ChatSurfacePalette.secondaryText)

        Spacer()

        Button(action: { copyDebugLog() }) {
          Image(systemName: "doc.on.doc")
            .font(.system(size: 11))
            .foregroundColor(ChatSurfacePalette.secondaryText)
        }
        .buttonStyle(.plain)
        .help("复制全部")
        .dayflowFloatingControl(cornerRadius: 6)
        .pointingHandCursor()

        Button(action: { chatService.clearDebugLog() }) {
          Image(systemName: "trash")
            .font(.system(size: 11))
            .foregroundColor(ChatSurfacePalette.secondaryText)
        }
        .buttonStyle(.plain)
        .help("清除日志")
        .dayflowFloatingControl(cornerRadius: 6)
        .pointingHandCursor()
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .background {
        Color.clear
          .dayflowFloatingControl(cornerRadius: 8)
      }

      Divider()

      // Log entries
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 8) {
          ForEach(chatService.debugLog) { entry in
            DebugLogEntry(entry: entry)
          }
        }
        .padding(12)
      }
    }
    .frame(width: 350)
    .dayflowInspectorPanel(cornerRadius: 0)
    .overlay(
      Rectangle()
        .fill(ChatSurfacePalette.separator)
        .frame(width: 1),
      alignment: .leading
    )
  }

  // MARK: - Memory Panel

  var memoryPanel: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack {
        Text("记忆")
          .font(.custom("Figtree", size: 12).weight(.bold))
          .foregroundColor(ChatSurfacePalette.secondaryText)
        Spacer()
        Text("\(memoryCharacterCount)/\(DashboardChatMemoryStore.maxCharacters)")
          .font(.custom("Figtree", size: 11))
          .foregroundColor(ChatSurfacePalette.tertiaryText)
      }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
      .background {
        Color.clear
          .dayflowFloatingControl(cornerRadius: 8)
      }

      Divider()

      VStack(alignment: .leading, spacing: 8) {
        Text("会根据助手回复自动更新，你也可以手动编辑。")
          .font(.custom("Figtree", size: 11))
          .foregroundColor(ChatSurfacePalette.secondaryText)

        TextEditor(text: $memoryDraft)
          .font(.custom("Figtree", size: 12))
          .padding(8)
          .dayflowOnboardingTextField()
          .onChange(of: memoryDraft) { _, newValue in
            guard newValue.count > DashboardChatMemoryStore.maxCharacters else { return }
            memoryDraft = String(newValue.prefix(DashboardChatMemoryStore.maxCharacters))
          }

        HStack {
          Text("最后更新：\(memoryUpdatedLabel)")
            .font(.custom("Figtree", size: 10))
            .foregroundColor(ChatSurfacePalette.tertiaryText)
          Spacer()
        }

        HStack(spacing: 8) {
          Button("保存") { saveMemoryDraft() }
            .buttonStyle(.plain)
            .font(.custom("Figtree", size: 11).weight(.bold))
            .foregroundColor(isMemoryDirty ? ChatSurfacePalette.accent : ChatSurfacePalette.tertiaryText)
            .disabled(!isMemoryDirty)
            .pointingHandCursor()

          Button("重新载入") { reloadMemoryDraft() }
            .buttonStyle(.plain)
            .font(.custom("Figtree", size: 11).weight(.bold))
            .foregroundColor(isMemoryDirty ? ChatSurfacePalette.secondaryText : ChatSurfacePalette.tertiaryText)
            .disabled(!isMemoryDirty)
            .pointingHandCursor()

          Spacer()

          Button("清除") { clearMemoryDraft() }
            .buttonStyle(.plain)
            .font(.custom("Figtree", size: 11).weight(.bold))
            .foregroundColor(storedMemoryBlob.isEmpty ? ChatSurfacePalette.tertiaryText : ChatSurfacePalette.critical)
            .disabled(storedMemoryBlob.isEmpty)
            .pointingHandCursor()
        }
      }
      .padding(12)
    }
    .frame(width: 360)
    .dayflowInspectorPanel(cornerRadius: 0)
    .overlay(
      Rectangle()
        .fill(ChatSurfacePalette.separator)
        .frame(width: 1),
      alignment: .leading
    )
  }

  // MARK: - Welcome View

  var welcomeView: some View {
    VStack(spacing: 0) {
      ZStack {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
          .fill(Color.clear)
          .dayflowContentPanel(cornerRadius: 24)

        VStack(spacing: 16) {
          HStack(alignment: .center, spacing: 12) {
            ZStack {
              Circle()
                .fill(
                  LinearGradient(
                    colors: [Color(hex: "FFE5CD"), Color(hex: "FFCF9D")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                  )
                )
              Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(hex: "C9670D"))
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 2) {
              Text("询问你的 Dayflow 数据")
                .font(.custom("HanziPen SC", size: 30))
                .foregroundColor(ChatSurfacePalette.primaryText)

              Text("提问、分析时间线，并生成图表。")
                .font(.custom("Figtree", size: 13).weight(.semibold))
                .foregroundColor(ChatSurfacePalette.secondaryText)

              Text("我会记住你的回复偏好，你可以随时教我你的风格。")
                .font(.custom("Figtree", size: 12))
                .foregroundColor(ChatSurfacePalette.tertiaryText)
            }

            Spacer(minLength: 0)
          }

          VStack(alignment: .leading, spacing: 10) {
            Text("试试这些问题")
              .font(.custom("Figtree", size: 12).weight(.bold))
              .foregroundColor(ChatSurfacePalette.secondaryText)

            ForEach(Array(welcomePrompts.enumerated()), id: \.offset) { index, prompt in
              WelcomeSuggestionRow(prompt: prompt) {
                sendMessage(prompt.text)
              }
              .opacity(didAnimateWelcome ? 1 : 0)
              .offset(y: didAnimateWelcome ? 0 : 8)
              .animation(welcomeSuggestionAnimation(at: index), value: didAnimateWelcome)
            }
          }
        }
        .padding(.horizontal, 24)
        .padding(.top, 22)
        .padding(.bottom, 24)
      }
      .frame(maxWidth: 760)
      .opacity(didAnimateWelcome ? 1 : 0)
      .scaleEffect(reduceMotion ? 1 : (didAnimateWelcome ? 1 : 0.985))
      .blur(radius: reduceMotion || didAnimateWelcome ? 0 : 6)
      .onAppear {
        guard !didAnimateWelcome else { return }
        withAnimation(welcomeHeroAnimation) {
          didAnimateWelcome = true
        }
      }

      Spacer(minLength: 8)
    }
    .frame(maxWidth: .infinity, minHeight: 420, alignment: .top)
    .padding(.bottom, 24)
  }

  // MARK: - Beta Lock Screen

  var betaLockScreen: some View {
    VStack(spacing: 16) {
      Spacer()

      // Header: "Unlock Beta" with BETA badge
      HStack(alignment: .top, spacing: 4) {
        Text("解锁测试版")
          .font(.system(size: 38, weight: .semibold, design: .rounded))
          .italic()
          .foregroundColor(ChatSurfacePalette.primaryText)

        Text("测试版")
          .font(.custom("Figtree-Bold", size: 11))
          .foregroundColor(.white)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(
            RoundedRectangle(cornerRadius: 6)
              .fill(Color(hex: "F98D3D"))
          )
          .rotationEffect(.degrees(-12))
          .offset(x: -4, y: -4)
      }

      // Feature description (below title)
      VStack(spacing: 6) {
        Text(
          "对话功能可以回答关于 Dayflow 活动的问题，并生成总结、对比和洞察。"
        )
          .font(.custom("Figtree-Regular", size: 14))
        .foregroundColor(ChatSurfacePalette.secondaryText)
        .multilineTextAlignment(.center)
        .frame(maxWidth: 600)

        Text("如果遇到问题或异常行为，请随时反馈！")
          .font(.custom("Figtree-SemiBold", size: 14))
          .foregroundColor(ChatSurfacePalette.primaryText)
          .multilineTextAlignment(.center)
      }

      // Main content card
      VStack(spacing: 16) {
        // Runtime requirement section
        VStack(spacing: 12) {
          Image(
            systemName: hasChatMinimumAccess && anyRuntimeAvailable
              ? "checkmark.circle.fill"
              : "bolt.horizontal.circle"
          )
          .font(.system(size: 32))
          .foregroundColor(
            hasChatMinimumAccess && anyRuntimeAvailable
              ? ChatSurfacePalette.positive : ChatSurfacePalette.accent
          )
          .contentTransition(.symbolEffect(.replace))
          .animation(.easeOut(duration: 0.2), value: anyRuntimeAvailable)
          .animation(.easeOut(duration: 0.2), value: hasChatMinimumAccess)

          if !hasChatMinimumAccess {
            Text("需要 10 小时时间线数据")
              .font(.custom("Figtree-SemiBold", size: 15))
              .foregroundColor(ChatSurfacePalette.primaryText)

            Text(
              "Dayflow 分析足够活动后会解锁对话功能。\(chatAccessProgressText)"
            )
            .font(.custom("Figtree-Regular", size: 13))
            .foregroundColor(ChatSurfacePalette.secondaryText)
            .multilineTextAlignment(.center)
          } else if anyRuntimeAvailable {
            Text("已检测到 Gemini Key 或 CLI 运行方式")
              .font(.custom("Figtree-SemiBold", size: 15))
              .foregroundColor(ChatSurfacePalette.positive)
              .transition(.opacity.combined(with: .scale(scale: 0.95)))
          } else {
            Text("需要 Gemini API Key 或 CLI")
              .font(.custom("Figtree-SemiBold", size: 15))
              .foregroundColor(ChatSurfacePalette.primaryText)

            Text(
              "你可以在设置中添加 Gemini API Key，或安装 Codex/Claude CLI 来解锁对话。"
            )
            .font(.custom("Figtree-Regular", size: 13))
            .foregroundColor(ChatSurfacePalette.secondaryText)
            .multilineTextAlignment(.center)
          }
        }
        .animation(.easeOut(duration: 0.25), value: anyRuntimeAvailable)
        .animation(.easeOut(duration: 0.25), value: hasChatMinimumAccess)

        // Continue button
        Button(action: {
          refreshChatAccessProgress()
          guard hasChatMinimumAccess && anyRuntimeAvailable else { return }

          withAnimation(.easeOut(duration: 0.25)) {
            hasBetaAccepted = true
          }
        }) {
          Text(chatUnlockButtonTitle)
            .font(.custom("Figtree-SemiBold", size: 15))
            .foregroundColor(
              hasChatMinimumAccess && anyRuntimeAvailable
                ? ChatSurfacePalette.primaryText
                : ChatSurfacePalette.tertiaryText
            )
            .padding(.horizontal, 28)
            .padding(.vertical, 12)
            .background(
              Capsule()
                .fill(
                  hasChatMinimumAccess && anyRuntimeAvailable
                    ? LinearGradient(
                      colors: [
                        Color(nsColor: .controlBackgroundColor).opacity(0.70),
                        ChatSurfacePalette.accent.opacity(0.16),
                      ],
                      startPoint: .top,
                      endPoint: .bottom
                    )
                    : LinearGradient(
                      colors: [
                        Color(hex: "F0F0F0"),
                        Color(hex: "E8E8E8"),
                      ],
                      startPoint: .top,
                      endPoint: .bottom
                    )
                )
                .overlay(
                  Capsule()
                    .stroke(
                      hasChatMinimumAccess && anyRuntimeAvailable
                        ? ChatSurfacePalette.accent.opacity(0.28)
                        : ChatSurfacePalette.separator,
                      lineWidth: 1
                    )
                )
            )
        }
        .buttonStyle(BetaButtonStyle(isEnabled: hasChatMinimumAccess && anyRuntimeAvailable))
        .disabled(!hasChatMinimumAccess || !anyRuntimeAvailable)
      }
      .padding(20)
      .background(
        RoundedRectangle(cornerRadius: 20, style: .continuous)
          .fill(Color.clear)
          .dayflowContentPanel(cornerRadius: 20)
      )
      .frame(maxWidth: 420)

      // Privacy Note (at bottom)
      VStack(spacing: 4) {
        Text("隐私说明")
          .font(.custom("Figtree-SemiBold", size: 12))
          .foregroundColor(ChatSurfacePalette.secondaryText)

        Text(
          "测试版期间，你的问题会被记录以帮助改进产品。回复内容不会被记录，以保护你的隐私。"
        )
        .font(.custom("Figtree-Regular", size: 12))
        .foregroundColor(ChatSurfacePalette.tertiaryText)
        .multilineTextAlignment(.center)
        .frame(maxWidth: 600)
      }
      .padding(.top, 4)

      Spacer()
    }
    .padding(.horizontal)
    .padding(.vertical, 12)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(nsColor: .windowBackgroundColor))
  }

  var chatUnlockButtonTitle: String {
    if !hasChatMinimumAccess {
      return "继续录制以解锁"
    }

    if !anyRuntimeAvailable {
      return "配置运行方式后继续"
    }

    return "解锁测试版"
  }

  // MARK: - Input Area

  var inputArea: some View {
    VStack(spacing: 0) {
      // Text input
      AppKitComposerTextField(
        text: $inputText,
        isFocused: $isInputFocused,
        focusToken: composerFocusToken,
        placeholder: "询问你的 Dayflow 数据…",
        onSubmit: submitCurrentInputIfAllowed
      )
      .frame(height: 50, alignment: .leading)

      Rectangle()
        .fill(ChatSurfacePalette.separator)
        .frame(height: 1)

      // Bottom toolbar
      HStack(spacing: 8) {
        // Provider toggle
        providerToggle

        Spacer()

        if chatService.isProcessing {
          HStack(spacing: 6) {
            ProgressView()
              .scaleEffect(0.55)
              .tint(ChatSurfacePalette.accent)
            Text("正在回答")
              .font(.custom("Figtree", size: 11).weight(.bold))
              .foregroundColor(ChatSurfacePalette.secondaryText)
          }
          .padding(.horizontal, 9)
          .padding(.vertical, 5)
          .dayflowFloatingControl(cornerRadius: 14)
        }

        // Send button
        Button(action: { submitCurrentInputIfAllowed() }) {
          ZStack {
            if chatService.isProcessing {
              ProgressView()
                .scaleEffect(0.6)
                .tint(Color(nsColor: .windowBackgroundColor))
            } else {
              Image(systemName: "arrow.up")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(nsColor: .windowBackgroundColor))
            }
          }
          .frame(width: 32, height: 32)
          .dayflowFloatingControl(cornerRadius: 16, isInteractive: canSubmitCurrentInput)
          .overlay(
            Circle()
              .stroke(ChatSurfacePalette.tertiaryText.opacity(0.4), lineWidth: canSubmitCurrentInput ? 0 : 1)
          )
        }
        .buttonStyle(PressScaleButtonStyle(isEnabled: canSubmitCurrentInput))
        .disabled(!canSubmitCurrentInput)
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 9)
      .frame(minHeight: 48)
    }
    .dayflowFloatingControl(cornerRadius: 16)
    .overlay(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .stroke(composerBorderColor, lineWidth: isInputFocused ? 1.2 : 1)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .inset(by: 0.6)
        .stroke(isInputFocused ? ChatSurfacePalette.accent.opacity(0.28) : Color.clear, lineWidth: 0.8)
    )
    .animation(.easeOut(duration: 0.16), value: isInputFocused)
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
  }

  var providerToggle: some View {
    HStack(spacing: 6) {
      ProviderTogglePill(
        title: "Gemini",
        isSelected: selectedProvider == .gemini,
        isEnabled: isProviderAvailable(.gemini)
      ) {
        handleProviderSelection(.gemini)
      }
      ProviderTogglePill(
        title: "Codex",
        isSelected: selectedProvider == .codex,
        isEnabled: isProviderAvailable(.codex)
      ) {
        handleProviderSelection(.codex)
      }
      ProviderTogglePill(
        title: "Claude",
        isSelected: selectedProvider == .claude,
        isEnabled: isProviderAvailable(.claude)
      ) {
        handleProviderSelection(.claude)
      }
    }
    .padding(4)
    .background(
      RoundedRectangle(cornerRadius: 11, style: .continuous)
        .fill(Color.clear)
    )
    .dayflowFloatingControl(cornerRadius: 11)
    .help(providerToggleHelpText)
  }

  var statusInsertionIndex: Int? {
    guard chatService.workStatus != nil else { return nil }
    // Always show at the end (after the latest user message)
    return chatService.messages.count
  }

  // MARK: - Follow-up Suggestions

  var followUpSuggestions: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("继续追问")
        .font(.custom("Figtree", size: 11).weight(.semibold))
        .foregroundColor(Color(hex: "999999"))

      ChatFlowLayout(spacing: 8) {
        ForEach(chatService.currentSuggestions, id: \.self) { suggestion in
          SuggestionChip(text: suggestion) {
            inputText = suggestion
            isInputFocused = true
            composerFocusToken += 1
          }
        }
      }
    }
    .padding(.top, 4)
  }

}
