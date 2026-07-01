import AppKit
import Foundation
import SwiftUI
import UserNotifications

extension DailyView {
  var lockScreen: some View {
    ZStack {
      dailyLockScreenBackground

      Group {
        if accessFlowStep == .intro {
          DailyAccessIntroView(
            betaNoticeCopy: betaNoticeCopy,
            progressText: dailyAccessProgressText,
            canRequestAccess: hasDailyMinimumAccess,
            onRequestAccess: startDailyAccessFlow,
            onConfettiStart: triggerLockScreenConfetti
          )
          .transition(.opacity.combined(with: .move(edge: .leading)))
        } else if accessFlowStep == .notifications {
          DailyNotification开启boardingView(
            notification权限Message: notification权限Message,
            notification权限ButtonTitle: notification权限ButtonTitle,
            isNotification权限ButtonDisabled: isNotification权限ButtonDisabled,
            isNotificationRecheckButtonDisabled: isNotificationRecheckButtonDisabled,
            onNotification权限Action: handleNotification权限Action,
            onRecheck权限s: checkNotificationAuthorizationForUnlock
          )
          .transition(.opacity.combined(with: .move(edge: .trailing)))
        } else {
          DailyProvider开启boardingView(
            selectedProvider: dailyRecapProvider,
            providerAvailability: providerAvailability,
            isRefreshingProviderAvailability: isRefreshingProviderAvailability,
            canContinue: canFinishDailyProvider开启boarding,
            onSelectProvider: selectDailyRecapProvider,
            onContinue: finishDailyProvider开启boarding
          )
          .transition(.opacity.combined(with: .move(edge: .trailing)))
        }
      }
      .padding(.horizontal, 24)
      .padding(.vertical, 28)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

      if lockScreenConfettiTrigger > 0 {
        ConfettiBurstView(trigger: lockScreenConfettiTrigger)
          .zIndex(10)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    .animation(.spring(response: 0.42, dampingFraction: 0.88), value: accessFlowStep)
  }
  var dailyLockScreenBackground: some View {
    GeometryReader { geo in
      Image("JournalPreview")
        .resizable()
        .scaledToFill()
        .frame(width: geo.size.width, height: geo.size.height)
        .clipped()
        .allowsHit测试ing(false)
    }
  }
  var isNotification权限ButtonDisabled: Bool {
    isCheckingNotificationAuthorization || isRequestingNotification权限
  }
  var isNotificationRecheckButtonDisabled: Bool {
    isCheckingNotificationAuthorization || isRequestingNotification权限
  }
  var notification权限ButtonTitle: String {
    if isCheckingNotificationAuthorization || isRequestingNotification权限 {
      return "检查中…"
    }

    if notificationAuthorizationStatus == .authorized {
      return "Opening Daily..."
    }

    if notificationAuthorizationStatus == .denied {
      return "打开系统设置"
    }

    return "Turn on notifications"
  }
  var notification权限Message: String {
    if notificationAuthorizationStatus == .denied {
      return
        "Notifications are currently off for Dayflow. Enable them in System Settings to finish unlocking Daily."
    }

    if notificationAuthorizationStatus == .authorized {
      return "Notifications are already enabled. We'll open Daily automatically."
    }

    return
      "Turn them on to continue. If you come back from System Settings, we'll check automatically."
  }
  func checkNotificationAuthorizationForUnlock() {
    guard !isCheckingNotificationAuthorization, !isRequestingNotification权限 else {
      return
    }

    isCheckingNotificationAuthorization = true

    Task {
      let status = await NotificationService.shared.authorizationStatus()

      await MainActor.run {
        isCheckingNotificationAuthorization = false
        notificationAuthorizationStatus = status

        guard !isUnlocked else {
          return
        }

        if canUnlockDaily(for: status) {
          handleAuthorizedDailyAccessStatus()
        }
      }
    }
  }
  func handleNotification权限Action() {
    if notificationAuthorizationStatus == .authorized {
      advanceToDailyProviderStep()
    } else if notificationAuthorizationStatus == .denied {
      openNotificationSettings()
    } else {
      requestNotification权限ForUnlock()
    }
  }
  func requestNotification权限ForUnlock() {
    guard !isRequestingNotification权限 else { return }
    isRequestingNotification权限 = true

    Task {
      let granted = await NotificationService.shared.request权限()
      let status = await NotificationService.shared.authorizationStatus()

      await MainActor.run {
        isRequestingNotification权限 = false
        notificationAuthorizationStatus = status

        if granted || canUnlockDaily(for: status) {
          advanceToDailyProviderStep()
        } else {
          openNotificationSettings()
        }
      }
    }
  }
  func openNotificationSettings() {
    let bundleID = Bundle.main.bundleIdentifier ?? "ai.dayflow.Dayflow"
    let settingsURLString =
      "x-apple.systempreferences:com.apple.preference.notifications?id=\(bundleID)"

    if let settingsURL = URL(string: settingsURLString) {
      _ = NSWorkspace.shared.open(settingsURL)
      return
    }

    if let fallbackURL = URL(string: "x-apple.systempreferences:com.apple.preference.notifications")
    {
      _ = NSWorkspace.shared.open(fallbackURL)
    }
  }
  func completeDailyUnlock() {
    AnalyticsService.shared.capture("daily_unlocked")

    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
      isUnlocked = true
    }
  }
  func canUnlockDaily(for status: UNAuthorizationStatus) -> Bool {
    switch status {
    case .authorized:
      return true
    case .provisional, .notDetermined, .denied:
      return false
    @unknown default:
      return false
    }
  }
  func handleAuthorizedDailyAccessStatus() {
    guard accessFlowStep == .notifications else {
      return
    }

    advanceToDailyProviderStep()
  }
  func advanceToDailyProviderStep() {
    dailyRecapProvider = DailyRecapGenerator.shared.selectedProvider()
    refreshProviderAvailability()

    withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
      accessFlowStep = .provider
    }
  }
  func triggerLockScreenConfetti() {
    lockScreenConfettiTrigger += 1
  }
  func startDailyAccessFlow() {
    refreshDailyAccessProgress()
    guard hasDailyMinimumAccess else { return }

    AnalyticsService.shared.capture(
      "daily_access_requested",
      ["source": "daily_intro"]
    )

    refreshProviderAvailability()

    withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
      accessFlowStep =
        canUnlockDaily(for: notificationAuthorizationStatus) ? .provider : .notifications
    }
  }
  func finishDailyProvider开启boarding() {
    guard canFinishDailyProvider开启boarding else {
      return
    }

    prepareTodayDailyGenerationAfterUnlock()
    completeDailyUnlock()

    if dailyRecapProvider.canGenerate {
      Task { @MainActor in
        regenerateStandupFromTimeline()
      }
    }
  }
  func prepareTodayDailyGenerationAfterUnlock() {
    let today = Date()
    selectedDate = today

    standupRegenerateTask?.cancel()
    standupRegenerateTask = nil
    standupRegenerate重置Task?.cancel()
    standupRegenerate重置Task = nil
    standupRegenerateState = .idle
    standupRegeneratingDotsPhase = 1
    loadedStandupDraftDay = nil
    loadedStandupFallbackSourceDay = nil
    standupSourceDay = nil

    refreshWorkflowData()
  }
}
