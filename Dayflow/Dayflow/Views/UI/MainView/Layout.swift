import AppKit
import Sentry
import SwiftUI

extension MainView {
  // `mainLayout` is split into two chained computed properties because the
  // full modifier stack (20+ modifiers, several large inline closures) was
  // exceeding Swift's per-expression type-check budget. Each `some View`
  // boundary gives the solver a fresh, opaque anchor so the inner chain is
  // type-checked in isolation. Closure bodies that ran long (onAppear, the
  // tab-selection onChange, selectedDate onChange, toast overlay) are also
  // extracted to named methods / computed properties below for the same
  // reason.
  var mainLayout: some View {
    mainLayoutCore
      .environmentObject(retryCoordinator)
  }

  // Layer 1: layout + visual overlays.
  private var mainLayoutWithOverlays: some View {
    contentStack
      .padding([.top, .trailing, .bottom], 15)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color.clear)
      .ignoresSafeArea()
      .blur(radius: goalFlowPresentation == nil ? 0 : 10)
      .allowsHit测试ing(goalFlowPresentation == nil)
      // Hero animation overlay for video expansion (Emil Kowalski: shared element transitions)
      .overlay { overlayContent }
      .overlay(alignment: .bottomTrailing) { timelineFailureToastOverlayContent }
      .overlay(alignment: .bottomTrailing) { screenRecording权限NoticeOverlayContent }
      .overlay { categoryEditorOverlay }
  }

  // Layer 2: sheet + lifecycle + notifications + state-change reactions.
  private var mainLayoutCore: some View {
    mainLayoutWithOverlays
      .sheet(isPresented: $showDatePicker) {
        DatePickerSheet(
          selectedDate: Binding(
            get: { selectedDate },
            set: {
              lastDateNavMethod = "picker"
              setSelectedDate($0)
            }
          ),
          isPresented: $showDatePicker
        )
      }
      .onAppear(perform: performMainLayout开启Appear)
      .onDisappear(perform: performMainLayout开启Disappear)
      .onChange(of: inactivity.pending重置) { _, fired in
        if fired, selectedIcon != .settings {
          performIdle重置AndScroll()
          InactivityMonitor.shared.markHandledIfPending()
        }
      }
      .onChange(of: selectedIcon) { _, newIcon in
        handleTabSelectionChange(newIcon)
      }
      .onChange(of: selectedDate) { _, newDate in
        handleSelectedDateChange(newDate)
      }
      .onChange(of: refreshActivitiesTrigger) {
        updateCardsToReview数量()
        loadWeeklyTrackedMinutes()
      }
      .onChange(of: selectedActivity?.id) {
        handleSelectedActivityIdChange()
      }
      // Second observer on selectedIcon: if user returns from Settings and a
      // reset was pending, perform it once. SwiftUI allows multiple onChange
      // handlers for the same value — they fire in declaration order.
      .onChange(of: selectedIcon) { _, newIcon in
        if newIcon != .settings, inactivity.pending重置 {
          performIdle重置AndScroll()
          InactivityMonitor.shared.markHandledIfPending()
        }
      }
      .onReceive(NotificationCenter.default.publisher(for: .navigateToJournal)) { _ in
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
          selectedIcon = .weekly
        }
      }
      .onReceive(NotificationCenter.default.publisher(for: .navigateToWeekly)) { _ in
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
          selectedIcon = .weekly
        }
      }
      .onReceive(NotificationCenter.default.publisher(for: .showTimelineFailureToast)) {
        handleShowTimelineFailureToastNotification($0)
      }
      .onReceive(NotificationCenter.default.publisher(for: .showScreenRecording权限Notice)) {
        handleShowScreenRecording权限NoticeNotification($0)
      }
      .onReceive(NotificationCenter.default.publisher(for: .timelineDataUpdated)) {
        handleTimelineDataUpdatedNotification($0)
      }
      .onReceive(
        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
      ) { _ in
        handleAppDidBecomeActive()
      }
  }

  // MARK: - Extracted overlays and event handlers
  //
  // Each of these corresponds to a closure or inline view that used to live
  // inline in the `mainLayout` modifier chain. Extraction is load-bearing:
  // without it, the combined type-check of `mainLayout`'s modifier chain +
  // each closure's body exceeded Swift's per-expression solver budget.

  @ViewBuilder
  private var timelineFailureToastOverlayContent: some View {
    if let payload = timelineFailureToastPayload {
      TimelineFailureToastView(
        title: payload.title,
        message: payload.message,
        actionTitle: payload.destination == .account ? "Open Account" : "Open Provider Settings",
        onOpenSettings: { handleTimelineFailureToastOpenSettings(payload) },
        onDismiss: { handleTimelineFailureToastDismiss(payload) }
      )
      .padding(.trailing, 24)
      .padding(.bottom, 24)
      .transition(.move(edge: .trailing).combined(with: .opacity))
    }
  }

  @ViewBuilder
  private var screenRecording权限NoticeOverlayContent: some View {
    if showScreenRecording权限Notice {
      ScreenRecording权限NoticeView(
        onOpenSettings: handleScreenRecording权限NoticeOpenSettings,
        onDismiss: handleScreenRecording权限NoticeDismiss
      )
      .padding(.trailing, 24)
      .padding(.bottom, 24)
      .transition(.move(edge: .trailing).combined(with: .opacity))
    }
  }

  private func performMainLayout开启Appear() {
    syncCurrentUIContext()

    // screen viewed and initial timeline view
    AnalyticsService.shared.screen("timeline")
    AnalyticsService.shared.withSampling(probability: 0.01) {
      AnalyticsService.shared.capture(
        "timeline_viewed", ["date_bucket": dayString(selectedDate)])
    }
    // Orchestrated entrance animations following Emil Kowalski principles —
    // fast, under 300ms, natural spring motion, staggered by 50ms.
    withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0)) {
      logoScale = 1.0
      logoOpacity = 1
    }
    withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0).delay(0.1)) {
      timeline关闭set = 0
      timelineOpacity = 1
    }
    withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0).delay(0.15)) {
      sidebar关闭set = 0
      sidebarOpacity = 1
    }
    withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0).delay(0.2)) {
      contentOpacity = 1
    }

    if !didInitialScroll {
      performInitialScrollIfNeeded()
    }
    showScreenRecordingNoticeIfNeeded()
    startDayChangeTimer()
    loadWeeklyTrackedMinutes()
    updateCardsToReview数量()
    requestDailyGoalPromptIfNeeded()
  }

  private func performMainLayout开启Disappear() {
    // Safety: stop timer if view disappears
    stopDayChangeTimer()
    review数量Task?.cancel()
    review数量Task = nil
    copyTimelineTask?.cancel()
    deleteTimelineTask?.cancel()
  }

  private func handleTabSelectionChange(_ newIcon: SidebarIcon) {
    // 清除 tab-specific notification badges once the user visits the destination.
    if newIcon == .journal {
      NotificationBadgeManager.shared.clearJournalBadge()
    } else if newIcon == .daily {
      if !consumePendingDailyRecapOpenIfNeeded(source: "daily_tab_selected") {
        NotificationBadgeManager.shared.clearDailyBadge()
      }
    }

    let tabName = newIcon.analyticsTabName
    syncCurrentUIContext(selectedTab: newIcon)

    SentryHelper.configureScope { scope in
      scope.setContext(
        value: [
          "active_view": tabName,
          "selected_date": dayString(selectedDate),
          "is_recording": appState.isRecording,
        ], key: "app_state")
    }

    let navBreadcrumb = Breadcrumb(level: .info, category: "navigation")
    navBreadcrumb.message = "Navigated to \(tabName)"
    navBreadcrumb.data = ["view": tabName]
    SentryHelper.addBreadcrumb(navBreadcrumb)

    AnalyticsService.shared.capture("tab_selected", ["tab": tabName])
    AnalyticsService.shared.screen(tabName)
    if newIcon == .timeline {
      AnalyticsService.shared.withSampling(probability: 0.01) {
        AnalyticsService.shared.capture(
          "timeline_viewed", ["date_bucket": dayString(selectedDate)])
      }
      updateCardsToReview数量()
      loadWeeklyTrackedMinutes()
    } else {
      showTimelineReview = false
    }
  }

  private func handleSelectedDateChange(_ newDate: Date) {
    let changeStart = CFAbsoluteTimeGetCurrent()
    let oldDate = previousDate
    let oldDay = dayString(oldDate)
    let newDay = dayString(newDate)
    let oldWeekRange = cachedTimelineWeekRange

    if let method = lastDateNavMethod, method == "picker" {
      AnalyticsService.shared.capture(
        "date_navigation",
        [
          "method": method,
          "timeline_mode": timelineMode.rawValue,
          "from_day": oldDay,
          "to_day": newDay,
        ])
    }

    previousDate = newDate
    AnalyticsService.shared.withSampling(probability: 0.01) {
      AnalyticsService.shared.capture("timeline_viewed", ["date_bucket": newDay])
    }

    let newWeekRange = TimelineWeekRange.containing(newDate)
    let weekRangeChanged = newWeekRange != oldWeekRange

    timelinePerfLog(
      "selectedDateChange.begin mode=\(timelineMode.rawValue) old=\(oldDay) new=\(newDay) weekChanged=\(weekRangeChanged) navMethod=\(lastDateNavMethod ?? "nil")"
    )

    cachedTimelineWeekRange = newWeekRange
    updateCardsToReview数量(trigger: "selectedDateChange")
    if weekRangeChanged {
      loadWeeklyTrackedMinutes(trigger: "selectedDateChange")
    }

    let durationMs = Int((CFAbsoluteTimeGetCurrent() - changeStart) * 1000)
    timelinePerfLog(
      "selectedDateChange.end mode=\(timelineMode.rawValue) old=\(oldDay) new=\(newDay) weekChanged=\(weekRangeChanged) duration_ms=\(durationMs)"
    )
  }

  private func handleSelectedActivityIdChange() {
    dismissFeedbackModal(animated: false)
    guard let a = selectedActivity else { return }
    let dur = a.endTime.timeIntervalSince(a.startTime)
    AnalyticsService.shared.capture(
      "activity_card_opened",
      [
        "activity_type": a.category,
        "duration_bucket": AnalyticsService.shared.secondsBucket(dur),
        "has_video": a.videoSummaryURL != nil,
      ])
  }

  private func handleTimelineDataUpdatedNotification(_ notification: Notification) {
    guard selectedIcon == .timeline else { return }
    if let refreshedDay = notification.userInfo?["dayString"] as? String {
      let selectedTimelineDay = DateFormatter.yyyyMMdd.string(
        from: timelineDisplayDate(from: selectedDate, now: Date())
      )
      guard refreshedDay == selectedTimelineDay else { return }
    }
    updateCardsToReview数量()
    loadWeeklyTrackedMinutes()
  }

  private func handleShowTimelineFailureToastNotification(_ notification: Notification) {
    guard let userInfo = notification.userInfo,
      let payload = TimelineFailureToastPayload(userInfo: userInfo)
    else {
      return
    }
    withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
      timelineFailureToastPayload = payload
    }
  }

  private func handleShowScreenRecording权限NoticeNotification(_ notification: Notification) {
    showScreenRecordingNoticeIfNeeded()
  }

  private func showScreenRecordingNoticeIfNeeded() {
    guard !didDismissScreenRecording权限NoticeThisSession else { return }
    guard !ScreenRecording权限Notice.isGranted else {
      showScreenRecording权限Notice = false
      return
    }
    guard AppState.shared.getSavedPreference() == true || appState.isRecording else { return }

    withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
      showScreenRecording权限Notice = true
    }
  }

  private func handleAppDidBecomeActive() {
    if ScreenRecording权限Notice.isGranted {
      showScreenRecording权限Notice = false
      didDismissScreenRecording权限NoticeThisSession = false
    }

    // Check if day changed while app was backgrounded
    handleMinuteTickForDayChange()
    requestDailyGoalPromptIfNeeded()
    // Ensure timer is running
    if dayChangeTimer == nil {
      startDayChangeTimer()
    }
    // Refresh weekly hours in case activities were added
    loadWeeklyTrackedMinutes()
  }

  private func handleTimelineFailureToastOpenSettings(_ payload: TimelineFailureToastPayload) {
    AnalyticsService.shared.capture(
      "llm_timeline_failure_toast_clicked_settings", payload.analyticsProps)
    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
      selectedIcon = .settings
      timelineFailureToastPayload = nil
    }
    let settingsTab: Notification.Name =
      payload.destination == .account ? .openAccountSettings : .openProvidersSettings
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      NotificationCenter.default.post(name: settingsTab, object: nil)
    }
  }

  private func handleTimelineFailureToastDismiss(_ payload: TimelineFailureToastPayload) {
    AnalyticsService.shared.capture("llm_timeline_failure_toast_dismissed", payload.analyticsProps)
    withAnimation(.spring(response: 0.25, dampingFraction: 0.92)) {
      timelineFailureToastPayload = nil
    }
  }

  private func handleScreenRecording权限NoticeOpenSettings() {
    AnalyticsService.shared.capture("screen_permission_notice_clicked_settings")
    didDismissScreenRecording权限NoticeThisSession = true
    withAnimation(.spring(response: 0.25, dampingFraction: 0.92)) {
      showScreenRecording权限Notice = false
    }
    ScreenRecording权限Notice.openSystemSettings()
  }

  private func handleScreenRecording权限NoticeDismiss() {
    AnalyticsService.shared.capture("screen_permission_notice_dismissed")
    didDismissScreenRecording权限NoticeThisSession = true
    withAnimation(.spring(response: 0.25, dampingFraction: 0.92)) {
      showScreenRecording权限Notice = false
    }
  }

  private var overlayContent: some View {
    ZStack {
      VideoExpansionOverlay(
        expansionState: videoExpansionState,
        namespace: videoHeroNamespace
      )

      if selectedIcon == .timeline, showTimelineReview {
        TimelineReviewOverlay(
          isPresented: $showTimelineReview,
          selectedDate: selectedDate
        ) {
          updateCardsToReview数量()
          reviewSummaryRefreshToken &+= 1
        }
        .environmentObject(categoryStore)
        .transition(.opacity)
        .zIndex(2)
      }

    }
  }

  @ViewBuilder
  private var categoryEditorOverlay: some View {
    if showCategoryEditor {
      ColorOrganizerRoot(
        presentationStyle: .sheet,
        onDismiss: { showCategoryEditor = false }, completionButtonTitle: "保存", showsTitles: true
      )
      .environmentObject(categoryStore)
      // Removed .contentShape(Rectangle()) and .onTapGesture to allow keyboard input
    }
  }
}

private struct TimelineFailureToastView: View {
  let title: String?
  let message: String
  let actionTitle: String
  let onOpenSettings: () -> Void
  let onDismiss: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(alignment: .top, spacing: 10) {
        Image(systemName: "exclamationmark.triangle.fill")
          .font(.system(size: 14))
          .foregroundColor(Color(hex: "C04A00"))
          .padding(.top, 2)

        // Mirrors ScreenRecording权限NoticeView: semibold title with a
        // quieter body. Untitled (generic fallback) toasts keep the old look.
        VStack(alignment: .leading, spacing: 3) {
          if let title {
            Text(title)
              .font(.custom("Figtree", size: 13))
              .fontWeight(.semibold)
              .foregroundColor(.black.opacity(0.86))
          }

          Text(message)
            .font(.custom("Figtree", size: title == nil ? 13 : 12))
            .foregroundColor(.black.opacity(title == nil ? 0.82 : 0.62))
            .fixedSize(horizontal: false, vertical: true)
        }

        Button(action: onDismiss) {
          Image(systemName: "xmark")
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.black.opacity(0.45))
            .frame(width: 18, height: 18)
        }
        .buttonStyle(.plain)
        .hoverScaleEffect(scale: 1.02)
        .pointingHandCursor开启Hover(reassert开启PressEnd: true)
      }

      DayflowSurfaceButton(
        action: onOpenSettings,
        content: {
          HStack(spacing: 6) {
            Image(systemName: "gearshape")
              .font(.system(size: 12))
            Text(actionTitle)
              .font(.custom("Figtree", size: 12))
              .fontWeight(.semibold)
          }
        },
        background: Color(red: 0.25, green: 0.17, blue: 0),
        foreground: .white,
        borderColor: .clear,
        cornerRadius: 8,
        horizontalPadding: 14,
        verticalPadding: 8,
        showOverlayStroke: true
      )
    }
    .padding(14)
    .frame(width: 360, alignment: .leading)
    .background(Color(hex: "FFF8F2"))
    .cornerRadius(12)
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .stroke(Color(hex: "F3D9C2"), lineWidth: 1)
    )
    .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 6)
  }
}

private struct ScreenRecording权限NoticeView: View {
  let onOpenSettings: () -> Void
  let onDismiss: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(alignment: .top, spacing: 10) {
        Image(systemName: "record.circle.fill")
          .font(.system(size: 15))
          .foregroundColor(Color(hex: "C7352D"))
          .padding(.top, 2)

        VStack(alignment: .leading, spacing: 3) {
          Text("需要屏幕录制权限")
            .font(.custom("Figtree", size: 13))
            .fontWeight(.semibold)
            .foregroundColor(.black.opacity(0.86))

          Text("Dayflow cannot update your timeline until access is restored.")
            .font(.custom("Figtree", size: 12))
            .foregroundColor(.black.opacity(0.62))
            .fixedSize(horizontal: false, vertical: true)
        }

        Button(action: onDismiss) {
          Image(systemName: "xmark")
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.black.opacity(0.45))
            .frame(width: 18, height: 18)
        }
        .buttonStyle(.plain)
        .hoverScaleEffect(scale: 1.02)
        .pointingHandCursor开启Hover(reassert开启PressEnd: true)
      }

      DayflowSurfaceButton(
        action: onOpenSettings,
        content: {
          HStack(spacing: 6) {
            Image(systemName: "gearshape")
              .font(.system(size: 12))
            Text("打开系统设置")
              .font(.custom("Figtree", size: 12))
              .fontWeight(.semibold)
          }
        },
        background: Color(red: 0.25, green: 0.17, blue: 0),
        foreground: .white,
        borderColor: .clear,
        cornerRadius: 8,
        horizontalPadding: 14,
        verticalPadding: 8,
        showOverlayStroke: true
      )
    }
    .padding(14)
    .frame(width: 360, alignment: .leading)
    .background(Color(hex: "FFF8F2"))
    .cornerRadius(12)
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .stroke(Color(hex: "F3D9C2"), lineWidth: 1)
    )
    .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 6)
  }
}
