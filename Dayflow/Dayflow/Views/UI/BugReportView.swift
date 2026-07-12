import AppKit
import SwiftUI

struct BugReportView: View {
  private let emailAddress = "jerry@dayflow.so"
  private let discordInviteURL = URL(string: "https://discord.gg/9YPAtctE6k")
  private let callBookingURL = URL(string: "https://cal.com/jerry-liu/15min")
  @State private var didCopyEmail = false
  @State private var copyResetTask: DispatchWorkItem? = nil
  @State private var didCopyDebugLogs = false
  @State private var isCopyingDebugLogs = false
  @State private var debugCopyResetTask: DispatchWorkItem? = nil

  var body: some View {
    VStack(spacing: 36) {
      VStack(spacing: 16) {
        Text("感谢使用 Dayflow")
          .font(.custom("HanziPen SC", size: 40))
          .foregroundColor(Color(nsColor: .labelColor))

        Text(
          "如果你想快速留言，可以发邮件；如果想加入社区，可以来 Discord；如果更想直接聊聊，也可以在我的日历里约个时间。我很想了解 Dayflow 哪些地方好用，哪些地方还不够好。"
        )
        .font(.custom("Figtree", size: 16))
        .foregroundColor(Color(nsColor: .secondaryLabelColor))
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: 520)
      }
      VStack(spacing: 24) {
        VStack(spacing: 12) {
          Text("联系我们")
            .font(.custom("Figtree", size: 14).weight(.medium))
            .foregroundColor(Color(nsColor: .tertiaryLabelColor))
            .textCase(.uppercase)
            .tracking(0.75)

          HStack(spacing: 16) {
            DayflowSurfaceButton(
              action: composeEmail,
              content: {
                HStack(spacing: 12) {
                  Image(systemName: "envelope.fill")
                    .font(.system(size: 18, weight: .semibold))
                  Text("发邮件")
                    .font(.custom("Figtree", size: 16).weight(.semibold))
                }
              },
              cornerRadius: 18,
              horizontalPadding: 28,
              verticalPadding: 16,
              showShadow: false,
              isSecondaryStyle: true,
            )

            DayflowSurfaceButton(
              action: openDiscord,
              content: {
                HStack(spacing: 11) {
                  DayflowExternalImageBadge(
                    imageName: "DiscordGlyph",
                    size: 26,
                    cornerRadius: 7,
                    contentScale: 0.62
                  )
                  Text("加入社区")
                    .font(.custom("Figtree", size: 16).weight(.semibold))
                }
              },
              cornerRadius: 18,
              horizontalPadding: 28,
              verticalPadding: 16,
              showShadow: false,
              isSecondaryStyle: true,
            )

            DayflowSurfaceButton(
              action: bookCall,
              content: {
                HStack(spacing: 12) {
                  Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 18, weight: .semibold))
                  Text("预约时间")
                    .font(.custom("Figtree", size: 16).weight(.semibold))
                }
              },
              cornerRadius: 18,
              horizontalPadding: 28,
              verticalPadding: 16,
              showShadow: false,
              isSecondaryStyle: true,
            )
          }
        }

        VStack(spacing: 12) {
          Text("快捷工具")
            .font(.custom("Figtree", size: 14).weight(.medium))
            .foregroundColor(Color(nsColor: .tertiaryLabelColor))
            .textCase(.uppercase)
            .tracking(0.75)

          HStack(spacing: 16) {
            DayflowSurfaceButton(
              action: copyEmail,
              content: {
                HStack(spacing: 10) {
                  Image(systemName: "doc.on.doc")
                    .font(.system(size: 16, weight: .semibold))
                  Text(didCopyEmail ? "已复制" : "复制邮箱")
                    .font(.custom("Figtree", size: 15).weight(.semibold))
                }
              },
              cornerRadius: 14,
              horizontalPadding: 22,
              verticalPadding: 14,
              showShadow: false,
              isSecondaryStyle: true,
            )
            .opacity(didCopyEmail ? 0.85 : 1.0)

            DayflowSurfaceButton(
              action: copyDebugLogs,
              content: {
                HStack(spacing: 10) {
                  Image(systemName: "ladybug.fill")
                    .font(.system(size: 16, weight: .semibold))
                  Text(
                    didCopyDebugLogs
                      ? "已复制" : (isCopyingDebugLogs ? "准备中…" : "复制调试日志")
                  )
                  .font(.custom("Figtree", size: 15).weight(.semibold))
                }
              },
              cornerRadius: 14,
              horizontalPadding: 20,
              verticalPadding: 14,
              showShadow: false,
              isSecondaryStyle: true,
            )
            .opacity(didCopyDebugLogs ? 0.85 : 1.0)
          }
        }
      }
      .padding(.horizontal, 8)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(.top, 100)
    .padding(.horizontal, 48)
  }

  private func composeEmail() {
    AnalyticsService.shared.capture("bug_report_email_tapped", ["destination": emailAddress])

    var components = URLComponents()
    components.scheme = "mailto"
    components.path = emailAddress
    components.queryItems = [
      URLQueryItem(name: "subject", value: "Dayflow 反馈")
    ]

    guard let url = components.url else { return }
    NSWorkspace.shared.open(url)
  }

  private func copyEmail() {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(emailAddress, forType: .string)
    AnalyticsService.shared.capture("bug_report_email_copied")

    withAnimation(.easeOut(duration: 0.2)) {
      didCopyEmail = true
    }

    copyResetTask?.cancel()
    let work = DispatchWorkItem {
      withAnimation(.easeInOut(duration: 0.25)) {
        didCopyEmail = false
      }
      self.copyResetTask = nil
    }
    copyResetTask = work
    DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: work)
  }

  private func openDiscord() {
    AnalyticsService.shared.capture("bug_report_discord_tapped")

    guard let url = discordInviteURL else { return }
    NSWorkspace.shared.open(url)
  }

  private func bookCall() {
    AnalyticsService.shared.capture("bug_report_call_tapped")

    guard let url = callBookingURL else { return }
    NSWorkspace.shared.open(url)
  }

  private func copyDebugLogs() {
    guard !isCopyingDebugLogs else { return }

    isCopyingDebugLogs = true

    Task {
      // Fetch recent timeline cards first
      let timeline = StorageManager.shared.fetchRecentTimelineCardsForDebug(limit: 5)

      // Extract unique batch IDs from timeline cards
      let batchIds = Array(Set(timeline.compactMap { $0.batchId }))

      // Fetch LLM calls, falling back to global recent calls if we have no timeline batches
      let llmCalls: [LLMCallDebugEntry]
      let llmCallSource: String
      if batchIds.isEmpty {
        llmCalls = StorageManager.shared.fetchRecentLLMCallsForDebug(limit: 20)
        llmCallSource = "global"
      } else {
        llmCalls = StorageManager.shared.fetchLLMCallsForBatches(batchIds: batchIds, limit: 100)
        llmCallSource = "timeline_batches"
      }

      let batches = StorageManager.shared.fetchRecentAnalysisBatchesForDebug(limit: 5)

      let logString = DebugLogFormatter.makeLog(
        timeline: timeline, llmCalls: llmCalls, batches: batches)

      await MainActor.run {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(logString, forType: .string)

        AnalyticsService.shared.capture(
          "bug_report_debug_logs_copied",
          [
            "timeline_count": timeline.count,
            "llm_call_count": llmCalls.count,
            "llm_call_source": llmCallSource,
            "batch_count": batches.count,
          ]
        )

        withAnimation(.easeOut(duration: 0.2)) {
          didCopyDebugLogs = true
        }

        debugCopyResetTask?.cancel()
        let work = DispatchWorkItem {
          withAnimation(.easeInOut(duration: 0.25)) {
            didCopyDebugLogs = false
          }
          self.debugCopyResetTask = nil
        }
        debugCopyResetTask = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: work)

        isCopyingDebugLogs = false
      }
    }
  }
}

#Preview {
  BugReportView()
}
