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
          DailyNotificationOnboardingView(
            notificationPermissionMessage: notificationPermissionMessage,
            notificationPermissionButtonTitle: notificationPermissionButtonTitle,
            isNotificationPermissionButtonDisabled: isNotificationPermissionButtonDisabled,
            isNotificationRecheckButtonDisabled: isNotificationRecheckButtonDisabled,
            onNotificationPermissionAction: handleNotificationPermissionAction,
            onRecheckPermissions: checkNotificationAuthorizationForUnlock
          )
          .transition(.opacity.combined(with: .move(edge: .trailing)))
        } else {
          DailyProviderOnboardingView(
            selectedProvider: dailyRecapProvider,
            providerAvailability: providerAvailability,
            isRefreshingProviderAvailability: isRefreshingProviderAvailability,
            canContinue: canFinishDailyProviderOnboarding,
            onSelectProvider: selectDailyRecapProvider,
            onContinue: finishDailyProviderOnboarding
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
      DayflowContentPreviewFrame(cornerRadius: 18) {
        Image("JournalPreview")
          .resizable()
          .scaledToFill()
          .frame(width: geo.size.width, height: geo.size.height)
          .clipped()
          .overlay(Color(nsColor: .windowBackgroundColor).opacity(0.16))
      }
      .allowsHitTesting(false)
    }
  }
  var isNotificationPermissionButtonDisabled: Bool {
    isCheckingNotificationAuthorization || isRequestingNotificationPermission
  }
  var isNotificationRecheckButtonDisabled: Bool {
    isCheckingNotificationAuthorization || isRequestingNotificationPermission
  }
  var notificationPermissionButtonTitle: String {
    if isCheckingNotificationAuthorization || isRequestingNotificationPermission {
      return "正在检查..."
    }

    if notificationAuthorizationStatus == .authorized {
      return "正在打开 Daily..."
    }

    if notificationAuthorizationStatus == .denied {
      return "打开系统设置"
    }

    return "开启通知"
  }
  var notificationPermissionMessage: String {
    if notificationAuthorizationStatus == .denied {
      return
        "Dayflow 的通知当前已关闭。请在系统设置中开启通知以完成 Daily 解锁。"
    }

    if notificationAuthorizationStatus == .authorized {
      return "通知已开启。我们会自动打开 Daily。"
    }

    return
      "开启通知即可继续。从系统设置回来后，我们会自动检查。"
  }
  func checkNotificationAuthorizationForUnlock() {
    guard !isCheckingNotificationAuthorization, !isRequestingNotificationPermission else {
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
  func handleNotificationPermissionAction() {
    if notificationAuthorizationStatus == .authorized {
      advanceToDailyProviderStep()
    } else if notificationAuthorizationStatus == .denied {
      openNotificationSettings()
    } else {
      requestNotificationPermissionForUnlock()
    }
  }
  func requestNotificationPermissionForUnlock() {
    guard !isRequestingNotificationPermission else { return }
    isRequestingNotificationPermission = true

    Task {
      let granted = await NotificationService.shared.requestPermission()
      let status = await NotificationService.shared.authorizationStatus()

      await MainActor.run {
        isRequestingNotificationPermission = false
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
  func finishDailyProviderOnboarding() {
    guard canFinishDailyProviderOnboarding else {
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
    standupRegenerateResetTask?.cancel()
    standupRegenerateResetTask = nil
    standupRegenerateState = .idle
    standupRegeneratingDotsPhase = 1
    loadedStandupDraftDay = nil
    loadedStandupFallbackSourceDay = nil
    standupSourceDay = nil

    refreshWorkflowData()
  }
}
