import AppKit
import Charts
import SwiftUI

// MARK: - Work Status Card

struct WorkStatusCard: View {
  let status: ChatWorkStatus
  @Binding var showDetails: Bool

  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 10) {
        header

        if status.stage == .error, let message = status.errorMessage, !message.isEmpty {
          Text(message)
            .font(.custom("Figtree", size: 12).weight(.semibold))
            .foregroundColor(ChatSurfacePalette.critical)
        }

        if !status.tools.isEmpty {
          VStack(alignment: .leading, spacing: 8) {
            ForEach(status.tools) { tool in
              ToolStatusRow(tool: tool, showDetails: showDetails)
            }
          }
        }

        if status.hasDetails {
          Button(action: { showDetails.toggle() }) {
            HStack(spacing: 4) {
              Text(showDetails ? "隐藏详情" : "显示详情")
              Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                .font(.system(size: 9, weight: .semibold))
            }
            .font(.custom("Figtree", size: 11).weight(.semibold))
            .foregroundColor(ChatSurfacePalette.secondaryText)
          }
          .buttonStyle(DayflowPressScaleButtonStyle(pressedScale: 0.97))
          .pointingHandCursor()
        }

        if showDetails, !status.thinkingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
          Text(status.thinkingText.trimmingCharacters(in: .whitespacesAndNewlines))
            .font(.system(size: 10, design: .monospaced))
            .foregroundColor(ChatSurfacePalette.primaryText)
            .textSelection(.enabled)
            .padding(8)
            .chatMessageSurface(cornerRadius: 8)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 14)
      .padding(.vertical, 12)
      .chatMessageSurface(cornerRadius: 16)
      .overlay(statusBorder)

      Spacer(minLength: 60)
    }
  }

  var header: some View {
    HStack(spacing: 6) {
      Image(systemName: headerIcon)
        .font(.system(size: 12, weight: .semibold))
        .foregroundColor(accentColor)
        .frame(width: 14, height: 14, alignment: .center)

      HStack(spacing: 0) {
        Text(headerTitle)
        if showsEllipsis {
          AnimatedEllipsis()
        }
      }
      .font(.custom("Figtree", size: 12).weight(.semibold))
      .foregroundColor(ChatSurfacePalette.primaryText)

      Spacer()
    }
  }

  var headerTitle: String {
    switch status.stage {
    case .thinking:
      return "思考中"
    case .runningTools:
      return "正在运行工具"
    case .answering:
      return "正在回答"
    case .error:
      return "出了点问题"
    }
  }

  var showsEllipsis: Bool {
    switch status.stage {
    case .thinking, .runningTools, .answering:
      return true
    case .error:
      return false
    }
  }

  var headerIcon: String {
    switch status.stage {
    case .thinking:
      return "sparkles"
    case .runningTools:
      return "wrench.and.screwdriver"
    case .answering:
      return "text.bubble"
    case .error:
      return "exclamationmark.triangle.fill"
    }
  }

  var accentColor: Color {
    switch status.stage {
    case .error:
      return ChatSurfacePalette.critical
    default:
      return ChatSurfacePalette.accent
    }
  }

  var borderColor: Color {
    switch status.stage {
    case .error:
      return ChatSurfacePalette.critical.opacity(0.30)
    default:
      return ChatSurfacePalette.accent.opacity(0.22)
    }
  }

  var statusBorder: some View {
    RoundedRectangle(cornerRadius: 16, style: .continuous)
      .stroke(borderColor, lineWidth: 1)
  }
}

struct AnimatedEllipsis: View {
  let interval: TimeInterval = 0.45

  var body: some View {
    TimelineView(.periodic(from: .now, by: interval)) { context in
      let step = Int(context.date.timeIntervalSinceReferenceDate / interval) % 3 + 1
      Text(String(repeating: ".", count: step))
        .accessibilityHidden(true)
    }
  }
}

struct ToolStatusRow: View {
  let tool: ChatWorkStatus.ToolRun
  let showDetails: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack(spacing: 6) {
        statusIcon
          .frame(width: 14, height: 14, alignment: .center)
        Text(tool.summary)
          .font(.custom("Figtree", size: 12).weight(.semibold))
          .foregroundColor(textColor)
      }

      if showDetails {
        Text(tool.command)
          .font(.system(size: 10, design: .monospaced))
          .foregroundColor(ChatSurfacePalette.secondaryText)
          .textSelection(.enabled)
          .lineLimit(3)

        if !trimmedOutput.isEmpty {
          Text(trimmedOutput)
            .font(.system(size: 10, design: .monospaced))
            .foregroundColor(ChatSurfacePalette.primaryText)
            .lineLimit(6)
            .textSelection(.enabled)
            .padding(6)
            .chatMessageSurface(cornerRadius: 6)
        }
      }
    }
  }

  var trimmedOutput: String {
    tool.output.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  @ViewBuilder
  var statusIcon: some View {
    switch tool.state {
    case .running:
      ProgressView()
        .scaleEffect(0.6)
        .tint(ChatSurfacePalette.accent)
    case .completed:
      Image(systemName: "checkmark.circle.fill")
        .font(.system(size: 12, weight: .semibold))
        .foregroundColor(ChatSurfacePalette.positive)
    case .failed:
      Image(systemName: "xmark.circle.fill")
        .font(.system(size: 12, weight: .semibold))
        .foregroundColor(ChatSurfacePalette.critical)
    }
  }

  var textColor: Color {
    switch tool.state {
    case .failed:
      return ChatSurfacePalette.critical
    default:
      return ChatSurfacePalette.primaryText
    }
  }
}
