import AppKit
import Charts
import SwiftUI

// MARK: - Message Bubble

struct MessageBubble: View {
  let message: ChatMessage

  var body: some View {
    switch message.role {
    case .user:
      userBubble
    case .assistant:
      assistantBubble
    case .toolCall:
      ToolCallBubble(message: message)
    }
  }

  var userBubble: some View {
    HStack {
      Spacer(minLength: 60)
      Text(message.content)
        .font(.custom("Figtree", size: 13).weight(.medium))
        .foregroundColor(Color(nsColor: .windowBackgroundColor))
        .textSelection(.enabled)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(nsColor: .labelColor))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
  }

  var assistantBubble: some View {
    let blocks = ChatContentParser.blocks(from: message.content)
    return HStack {
      VStack(alignment: .leading, spacing: 10) {
        ForEach(blocks) { block in
          switch block {
          case .text(_, let content):
            ChatMarkdownContentView(content: content)
          case .chart(let spec):
            ChatChartBlockView(spec: spec)
          }
        }
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 10)
      .chatMessageSurface(cornerRadius: 16)
      .contextMenu {
        Button("复制") {
          copyAssistantMessageToPasteboard()
        }
      }
      .environment(
        \.openURL,
        OpenURLAction { url in
          handleAssistantLinkTap(url)
        })
      Spacer(minLength: 60)
    }
  }

  func handleAssistantLinkTap(_ url: URL) -> OpenURLAction.Result {
    guard let externalURL = normalizedExternalURL(from: url) else {
      print("[ChatView] Blocked unsupported URL: \(url.absoluteString)")
      return .discarded
    }

    let configuration = NSWorkspace.OpenConfiguration()
    NSWorkspace.shared.open(externalURL, configuration: configuration) { _, error in
      if let error {
        print(
          "[ChatView] Failed opening URL \(externalURL.absoluteString): \(error.localizedDescription)"
        )
      }
    }
    return .handled
  }

  func normalizedExternalURL(from rawURL: URL) -> URL? {
    if let scheme = rawURL.scheme?.lowercased() {
      switch scheme {
      case "http", "https", "mailto":
        return rawURL
      default:
        return nil
      }
    }

    let trimmed = rawURL.absoluteString.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }

    let prefixed =
      trimmed.hasPrefix("//")
      ? "https:\(trimmed)"
      : "https://\(trimmed)"

    guard let normalized = URL(string: prefixed),
      let scheme = normalized.scheme?.lowercased(),
      scheme == "http" || scheme == "https",
      let host = normalized.host,
      !host.isEmpty
    else {
      return nil
    }

    return normalized
  }

  func copyAssistantMessageToPasteboard() {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(message.content, forType: .string)
  }
}

struct ChatFeedbackTarget: Identifiable {
  let messageID: UUID
  let content: String
  let direction: TimelineRatingDirection

  var id: UUID { messageID }

  var message: ChatMessage {
    ChatMessage(id: messageID, role: .assistant, content: content)
  }
}

struct ChatMessageRow: View {
  let message: ChatMessage
  let showsAssistantFooter: Bool
  let selectedDirection: TimelineRatingDirection?
  let showsThanks: Bool
  let onCopy: () -> Void
  let onRate: (TimelineRatingDirection) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      MessageBubble(message: message)

      if showsAssistantFooter {
        HStack(spacing: 0) {
          AssistantMessageFeedbackRow(
            selectedDirection: selectedDirection,
            showsThanks: showsThanks,
            onCopy: onCopy,
            onRate: onRate
          )
          .padding(.leading, 10)

          Spacer(minLength: 60)
        }
      }
    }
  }
}

struct AssistantMessageFeedbackRow: View {
  let selectedDirection: TimelineRatingDirection?
  let showsThanks: Bool
  let onCopy: () -> Void
  let onRate: (TimelineRatingDirection) -> Void

  @Environment(\.accessibilityReduceMotion) var reduceMotion

  var thanksTransition: AnyTransition {
    if reduceMotion {
      return .opacity
    }
    return .opacity.combined(with: .move(edge: .leading))
  }

  var body: some View {
    HStack(spacing: 8) {
      AssistantMessageIconButton(
        systemName: "doc.on.doc",
        accessibilityLabel: "复制回答",
        action: onCopy
      )

      ThumbRatingButtons(selectedDirection: selectedDirection) { direction in
        onRate(direction)
      }

      if showsThanks {
        Text("感谢")
          .font(.custom("Figtree", size: 11).weight(.semibold))
          .foregroundColor(ChatSurfacePalette.secondaryText)
          .transition(thanksTransition)
      }
    }
    .padding(.vertical, 2)
  }
}

struct AssistantMessageIconButton: View {
  let systemName: String
  let accessibilityLabel: String
  let action: () -> Void

  @State var isHovered = false
  @Environment(\.accessibilityReduceMotion) var reduceMotion

  var hoverAnimation: Animation {
    if reduceMotion {
      return .easeOut(duration: 0.01)
    }
    return .easeOut(duration: 0.14)
  }

  var body: some View {
    Button(action: action) {
      Image(systemName: systemName)
        .font(.system(size: 11, weight: .semibold))
        .foregroundColor(ChatSurfacePalette.secondaryText)
        .frame(width: 22, height: 22)
        .background(
          Circle()
            .fill(isHovered ? Color(nsColor: .controlBackgroundColor).opacity(0.75) : Color.clear)
        )
        .overlay(
          Circle()
            .stroke(ChatSurfacePalette.separator, lineWidth: isHovered ? 1 : 0)
        )
    }
    .buttonStyle(.plain)
    .hoverScaleEffect(scale: 1.02)
    .pointingHandCursorOnHover(reassertOnPressEnd: true)
    .accessibilityLabel(Text(accessibilityLabel))
    .onHover { hovering in
      withAnimation(hoverAnimation) {
        isHovered = hovering
      }
    }
  }
}
