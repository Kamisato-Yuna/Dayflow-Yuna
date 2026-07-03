import SwiftUI

struct DailyAccessIntroView: View {
  let betaNoticeCopy: String
  let progressText: String
  let canRequestAccess: Bool
  let onRequestAccess: () -> Void
  let onConfettiStart: () -> Void

  @State private var requestState: DailyAccessRequestState = .idle
  @State private var showsSuccessRing = false
  @State private var transitionTask: Task<Void, Never>? = nil

  private var stateChangeAnimation: Animation {
    .easeInOut(duration: 0.26)
  }

  private var successRingAnimation: Animation {
    .easeOut(duration: 0.24)
  }

  var body: some View {
    VStack(spacing: 18) {
      DailyAccessHeaderView()

      Text(betaNoticeCopy)
        .font(.custom("Figtree-Regular", size: 15))
        .foregroundColor(DayflowDailyToken.secondaryText)
        .multilineTextAlignment(.center)
        .frame(maxWidth: 480)
        .padding(.horizontal, 24)

      Text("分析满 5 小时的时间线数据后即可解锁每日复盘。\(progressText)")
        .font(.custom("Figtree-SemiBold", size: 13))
        .foregroundColor(DayflowDailyToken.secondaryText)
        .multilineTextAlignment(.center)
        .frame(maxWidth: 460)
        .padding(.horizontal, 24)

      DailyAnimatedRequestAccessButton(
        requestState: requestState,
        showsSuccessRing: showsSuccessRing,
        isEnabled: canRequestAccess,
        stateChangeAnimation: stateChangeAnimation,
        successRingAnimation: successRingAnimation,
        onTap: animateRequestGranted
      )
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    .onDisappear {
      transitionTask?.cancel()
      transitionTask = nil
    }
  }

  private func animateRequestGranted() {
    guard canRequestAccess else { return }
    guard requestState == .idle else { return }

    withAnimation(stateChangeAnimation) {
      requestState = .granted
    }

    withAnimation(successRingAnimation) {
      showsSuccessRing = true
    }

    onConfettiStart()

    transitionTask?.cancel()
    transitionTask = Task {
      let delayNanoseconds: UInt64 = 1_120_000_000
      try? await Task.sleep(nanoseconds: delayNanoseconds)

      guard !Task.isCancelled else { return }
      await MainActor.run {
        onRequestAccess()
      }
    }
  }
}

struct DailyNotificationOnboardingView: View {
  let notificationPermissionMessage: String
  let notificationPermissionButtonTitle: String
  let isNotificationPermissionButtonDisabled: Bool
  let isNotificationRecheckButtonDisabled: Bool
  let onNotificationPermissionAction: () -> Void
  let onRecheckPermissions: () -> Void

  var body: some View {
    VStack(spacing: 18) {
      DailyAccessHeaderView()

      DailyNotificationPermissionPanelView(
        notificationPermissionMessage: notificationPermissionMessage,
        notificationPermissionButtonTitle: notificationPermissionButtonTitle,
        isNotificationPermissionButtonDisabled: isNotificationPermissionButtonDisabled,
        isNotificationRecheckButtonDisabled: isNotificationRecheckButtonDisabled,
        onNotificationPermissionAction: onNotificationPermissionAction,
        onRecheckPermissions: onRecheckPermissions
      )
    }
  }
}

struct DailyProviderOnboardingView: View {
  let selectedProvider: DailyRecapProvider
  let providerAvailability: [DailyRecapProvider: DailyRecapProviderAvailability]
  let isRefreshingProviderAvailability: Bool
  let canContinue: Bool
  let onSelectProvider: (DailyRecapProvider) -> Void
  let onContinue: () -> Void

  var body: some View {
    VStack(spacing: 14) {
      DailyAccessHeaderView()

      VStack(spacing: 12) {
        VStack(spacing: 6) {
          Text("选择你的每日复盘提供商")
            .font(.custom("InstrumentSerif-Regular", size: 24))
            .foregroundColor(DayflowDailyToken.title)
            .multilineTextAlignment(.center)

          Text(
            "选择每日复盘如何生成，或关闭生成功能。之后也可以随时更改。"
          )
          .font(.custom("Figtree-Regular", size: 13))
          .foregroundColor(DayflowDailyToken.secondaryText)
          .multilineTextAlignment(.center)
          .frame(maxWidth: 420)
        }

        if isRefreshingProviderAvailability {
          ProgressView()
            .controlSize(.small)
            .tint(DayflowDailyToken.accent)
        }

        VStack(spacing: 6) {
          ForEach(DailyRecapProvider.allCases, id: \.self) { provider in
            let availability =
              providerAvailability[provider]
              ?? DailyRecapProviderAvailability(
                isAvailable: true,
                detail: provider.pickerSubtitle
              )
            let isSelected = selectedProvider == provider

            Button {
              onSelectProvider(provider)
            } label: {
              HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                  Text(provider.displayName)
                    .font(.custom("Figtree-SemiBold", size: 13))
                    .foregroundStyle(isSelected ? DayflowDailyToken.accent : DayflowDailyToken.text)

                  Text(availability.detail)
                    .font(.custom("Figtree-Regular", size: 11))
                    .foregroundStyle(
                      availability.isAvailable ? DayflowDailyToken.secondaryText : DayflowDailyToken.distraction
                    )
                    .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                  .font(.system(size: 13, weight: .semibold))
                  .foregroundStyle(
                    isSelected ? DayflowDailyToken.accent : DayflowDailyToken.tertiaryText
                  )
              }
              .padding(.horizontal, 12)
              .padding(.vertical, 10)
              .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                  .fill(
                    isSelected
                      ? DayflowDailyToken.selectedFill(colorScheme: .light)
                      : DayflowDailyToken.subtleFill(colorScheme: .light)
                  )
              )
              .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                  .stroke(
                    isSelected
                      ? DayflowDailyToken.accent.opacity(0.42)
                      : DayflowContentToken.cardBorder(
                        colorScheme: .light,
                        increaseContrast: false
                      ),
                    lineWidth: 1.2
                  )
              )
              .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!availability.isAvailable)
            .pointingHandCursor(enabled: availability.isAvailable)
          }
        }

        DayflowSurfaceButton(
          action: onContinue,
          content: {
            Text("继续使用每日复盘")
              .font(.custom("Figtree", size: 14))
              .fontWeight(.semibold)
          },
          background: Color(nsColor: .labelColor),
          foreground: .white,
          borderColor: .clear,
          cornerRadius: 10,
          horizontalPadding: 20,
          verticalPadding: 10,
          showOverlayStroke: true
        )
        .disabled(!canContinue)
        .pointingHandCursor(enabled: canContinue)
      }
      .padding(.horizontal, 28)
      .padding(.vertical, 24)
      .frame(maxWidth: 460)
      .dayflowContentPanel(cornerRadius: 24)
      .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 6)
    }
  }
}

private struct DailyAccessHeaderView: View {
  var body: some View {
    HStack(alignment: .top, spacing: 4) {
      Text("Dayflow Daily")
        .font(.custom("InstrumentSerif-Italic", size: 38))
        .foregroundColor(DayflowDailyToken.title)

      Text("测试版")
        .font(.custom("Figtree-Bold", size: 11))
        .foregroundColor(Color(nsColor: .windowBackgroundColor))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
          RoundedRectangle(cornerRadius: 6)
            .fill(DayflowDailyToken.accent)
        )
        .rotationEffect(.degrees(-12))
        .offset(x: -4, y: -4)
    }
  }
}

private enum DailyAccessRequestState {
  case idle
  case granted
}

private struct DailyAnimatedRequestAccessButton: View {
  let requestState: DailyAccessRequestState
  let showsSuccessRing: Bool
  let isEnabled: Bool
  let stateChangeAnimation: Animation
  let successRingAnimation: Animation
  let onTap: () -> Void

  private var requestFill: Color {
    guard isEnabled else {
      return Color(red: 0.68, green: 0.62, blue: 0.56)
    }

    switch requestState {
    case .idle:
      return Color(red: 0.25, green: 0.17, blue: 0)
    case .granted:
      return Color(red: 0.34, green: 0.24, blue: 0.05)
    }
  }

  private var buttonScale: CGFloat {
    return requestState == .granted ? 1.015 : 1
  }

  var body: some View {
    Button(action: onTap) {
      ZStack {
        Capsule()
          .stroke(DayflowDailyToken.accent.opacity(0.28), lineWidth: 1.5)
          .scaleEffect(showsSuccessRing ? 1.08 : 0.96)
          .opacity(showsSuccessRing ? 0 : 0.65)

        RoundedRectangle(cornerRadius: 10)
          .fill(requestFill)
          .overlay(
            RoundedRectangle(cornerRadius: 10)
              .stroke(DayflowDailyToken.accent.opacity(0.18), lineWidth: 1.5)
          )
          .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
          .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)

        ZStack {
          Text("解锁每日复盘")
            .font(.custom("Figtree", size: 15))
            .fontWeight(.semibold)
            .foregroundColor(Color(nsColor: .windowBackgroundColor))
            .opacity(requestState == .idle ? 1 : 0)
            .offset(y: requestState == .idle ? 0 : -5)

          HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
              .font(.system(size: 14, weight: .semibold))
            Text("每日复盘已解锁")
              .font(.custom("Figtree", size: 15))
              .fontWeight(.semibold)
          }
          .foregroundColor(Color(nsColor: .windowBackgroundColor))
          .opacity(requestState == .granted ? 1 : 0)
          .offset(y: requestState == .granted ? 0 : 5)
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 13)
      }
      .compositingGroup()
      .fixedSize()
      .scaleEffect(buttonScale)
      .animation(stateChangeAnimation, value: requestState)
      .animation(successRingAnimation, value: showsSuccessRing)
    }
    .buttonStyle(.plain)
    .disabled(requestState == .granted || !isEnabled)
    .pointingHandCursor(enabled: requestState == .idle && isEnabled)
  }
}

private struct DailyNotificationPermissionPanelView: View {
  let notificationPermissionMessage: String
  let notificationPermissionButtonTitle: String
  let isNotificationPermissionButtonDisabled: Bool
  let isNotificationRecheckButtonDisabled: Bool
  let onNotificationPermissionAction: () -> Void
  let onRecheckPermissions: () -> Void

  var body: some View {
    VStack(spacing: 16) {
      Text("开启通知以解锁每日复盘")
        .font(.custom("InstrumentSerif-Regular", size: 30))
        .foregroundColor(DayflowDailyToken.title)
        .multilineTextAlignment(.center)

      Text("Dayflow 会通过通知告诉你复盘何时准备好。")
        .font(.custom("Figtree-SemiBold", size: 16))
        .foregroundColor(DayflowDailyToken.text)
        .multilineTextAlignment(.center)
        .frame(maxWidth: 420)

      Text(notificationPermissionMessage)
        .font(.custom("Figtree-Regular", size: 14))
        .foregroundColor(DayflowDailyToken.secondaryText)
        .multilineTextAlignment(.center)
        .frame(maxWidth: 430)

      VStack(spacing: 10) {
        DayflowSurfaceButton(
          action: onNotificationPermissionAction,
          content: {
            Text(notificationPermissionButtonTitle)
              .font(.custom("Figtree", size: 15))
              .fontWeight(.semibold)
          },
          background: Color(nsColor: .labelColor),
          foreground: .white,
          borderColor: .clear,
          cornerRadius: 10,
          horizontalPadding: 24,
          verticalPadding: 12,
          showOverlayStroke: true
        )
        .disabled(isNotificationPermissionButtonDisabled)
        .pointingHandCursor(enabled: !isNotificationPermissionButtonDisabled)

        DayflowSurfaceButton(
          action: onRecheckPermissions,
          content: {
            Text("重新检查权限")
              .font(.custom("Figtree", size: 14))
              .fontWeight(.semibold)
          },
          background: DayflowDailyToken.subtleFill(colorScheme: .light),
          foreground: DayflowDailyToken.text,
          borderColor: DayflowContentToken.cardBorder(colorScheme: .light, increaseContrast: false),
          cornerRadius: 10,
          horizontalPadding: 20,
          verticalPadding: 11,
          isSecondaryStyle: true
        )
        .disabled(isNotificationRecheckButtonDisabled)
        .pointingHandCursor(enabled: !isNotificationRecheckButtonDisabled)
      }
    }
    .padding(.horizontal, 34)
    .padding(.vertical, 30)
    .frame(maxWidth: 560)
    .dayflowContentPanel(cornerRadius: 28)
    .shadow(color: Color.black.opacity(0.08), radius: 18, x: 0, y: 8)
  }
}
