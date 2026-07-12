import AppKit
import Foundation
import SwiftUI
import UserNotifications

extension DailyView {
  var canFinishDailyProviderOnboarding: Bool {
    guard !(isRefreshingProviderAvailability && providerAvailability.isEmpty) else {
      return false
    }

    return selectedProviderAvailability.isAvailable
  }
  var selectedProviderAvailability: DailyRecapProviderAvailability {
    providerAvailability[dailyRecapProvider]
      ?? DailyRecapProviderAvailability(
        isAvailable: true,
        detail: dailyRecapProvider.pickerSubtitle
      )
  }
  var canRegenerateStandup: Bool {
    dailyRecapProvider.canGenerate
      && selectedProviderAvailability.isAvailable
      && standupRegenerateState != .regenerating
  }
  var regenerateButtonHelpText: String {
    if !dailyRecapProvider.canGenerate {
      return DailyStandupPlaceholder.noProviderSelectedMessage
    }

    if !selectedProviderAvailability.isAvailable {
      return selectedProviderAvailability.detail
    }

    return "重新生成站会重点"
  }
  func dailyProviderButton(scale: CGFloat) -> some View {
    Button {
      if !isShowingProviderPicker {
        refreshProviderAvailability()
      }
      isShowingProviderPicker.toggle()
    } label: {
      ZStack {
        Circle()
          .fill(DayflowDailyToken.subtleFill(colorScheme: colorScheme))

        Circle()
          .stroke(
            DayflowContentToken.cardBorder(
              colorScheme: colorScheme,
              increaseContrast: NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
            ),
            lineWidth: max(1.1, 1.3 * scale)
          )

        Image(systemName: "gearshape.fill")
          .font(.system(size: 13 * scale, weight: .semibold))
          .foregroundStyle(DayflowDailyToken.accent)
      }
      .frame(width: 38 * scale, height: 38 * scale)
      .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
      .contentShape(Circle())
    }
    .buttonStyle(DailyCopyPressButtonStyle())
    .disabled(standupRegenerateState == .regenerating)
    .pointingHandCursorOnHover(
      enabled: standupRegenerateState != .regenerating,
      reassertOnPressEnd: true
    )
    .accessibilityLabel(Text("选择每日复盘提供商"))
    .help("每日复盘提供商：\(dailyRecapProvider.selectionLabel)")
    .popover(isPresented: $isShowingProviderPicker, arrowEdge: .bottom) {
      dailyProviderPicker(scale: scale)
        .padding(16)
        .frame(width: 312)
        .dayflowPopoverSurface(cornerRadius: 18)
    }
  }
  func dailyProviderPicker(scale: CGFloat) -> some View {
    VStack(alignment: .leading, spacing: 12 * scale) {
      HStack(alignment: .firstTextBaseline) {
        VStack(alignment: .leading, spacing: 2 * scale) {
          Text("每日复盘提供商")
            .font(.system(size: 22 * scale, weight: .semibold, design: .rounded))
            .foregroundStyle(DayflowDailyToken.title)

          Text("选择每日复盘如何生成，或关闭生成功能。")
            .font(.custom("Figtree-Regular", size: 12 * scale))
            .foregroundStyle(DayflowDailyToken.secondaryText)
        }

        Spacer(minLength: 0)

        if isRefreshingProviderAvailability {
          ProgressView()
            .controlSize(.small)
            .tint(DayflowDailyToken.accent)
        }
      }

      VStack(spacing: 8 * scale) {
        ForEach(DailyRecapProvider.allCases, id: \.self) { provider in
          let availability =
            providerAvailability[provider]
            ?? DailyRecapProviderAvailability(isAvailable: true, detail: provider.pickerSubtitle)
          let isSelected = dailyRecapProvider == provider

          Button {
            selectDailyRecapProvider(provider)
          } label: {
            HStack(alignment: .top, spacing: 10 * scale) {
              VStack(alignment: .leading, spacing: 2 * scale) {
                Text(provider.displayName)
                  .font(.custom("Figtree-SemiBold", size: 13 * scale))
                  .foregroundStyle(isSelected ? DayflowDailyToken.accent : DayflowDailyToken.text)

                Text(availability.detail)
                  .font(.custom("Figtree-Regular", size: 12 * scale))
                  .foregroundStyle(
                    availability.isAvailable ? DayflowDailyToken.secondaryText : DayflowDailyToken.distraction
                  )
                  .multilineTextAlignment(.leading)
              }

              Spacer(minLength: 0)

              Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 14 * scale, weight: .semibold))
                .foregroundStyle(
                  isSelected ? DayflowDailyToken.accent : DayflowDailyToken.tertiaryText
                )
            }
            .padding(.horizontal, 12 * scale)
            .padding(.vertical, 10 * scale)
            .background(
              RoundedRectangle(cornerRadius: 14 * scale, style: .continuous)
                .fill(
                  isSelected
                    ? DayflowDailyToken.selectedFill(colorScheme: colorScheme)
                    : DayflowDailyToken.subtleFill(colorScheme: colorScheme)
                )
            )
            .overlay(
              RoundedRectangle(cornerRadius: 14 * scale, style: .continuous)
                .stroke(
                  isSelected
                    ? DayflowDailyToken.accent.opacity(0.42)
                    : DayflowContentToken.cardBorder(
                      colorScheme: colorScheme,
                      increaseContrast: NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
                    ),
                  lineWidth: max(1, 1.2 * scale)
                )
            )
            .contentShape(RoundedRectangle(cornerRadius: 14 * scale, style: .continuous))
          }
          .buttonStyle(.plain)
          .disabled(!availability.isAvailable)
          .pointingHandCursorOnHover(enabled: availability.isAvailable, reassertOnPressEnd: true)
        }
      }
    }
  }
  func selectDailyRecapProvider(_ provider: DailyRecapProvider) {
    let previousProvider = dailyRecapProvider
    guard previousProvider != provider else {
      isShowingProviderPicker = false
      return
    }

    dailyRecapProvider = provider
    DailyRecapGenerator.shared.persistSelectedProvider(provider)
    isShowingProviderPicker = false
    standupRegenerateResetTask?.cancel()
    standupRegenerateResetTask = nil
    standupRegenerateState = .idle
    loadedStandupDraftDay = nil
    loadedStandupFallbackSourceDay = nil

    AnalyticsService.shared.capture(
      "daily_provider_selected",
      [
        "previous_daily_provider": previousProvider.analyticsName,
        "previous_daily_provider_label": previousProvider.displayName,
        "daily_provider": provider.analyticsName,
        "daily_provider_label": provider.displayName,
        "daily_runtime": provider.runtimeLabel,
        "daily_model_or_tool": provider.modelOrTool as Any,
      ]
    )

    refreshWorkflowData()
  }
  func refreshProviderAvailability() {
    providerAvailabilityTask?.cancel()
    isRefreshingProviderAvailability = true

    providerAvailabilityTask = Task.detached(priority: .utility) {
      let snapshot = DailyRecapGenerator.shared.availabilitySnapshot()
      guard !Task.isCancelled else { return }

      await MainActor.run {
        providerAvailability = snapshot
        isRefreshingProviderAvailability = false
        providerAvailabilityTask = nil
      }
    }
  }
}
