//
//  ScreenRecordingPermissionView.swift
//  Dayflow
//
//  Screen recording permission request using idiomatic ScreenCaptureKit approach
//

import AppKit
import CoreGraphics
import ScreenCaptureKit
import SwiftUI

struct ScreenRecordingPermissionView: View {
  var onBack: () -> Void
  var onNext: () -> Void

  @State private var permissionState: PermissionState = .notRequested
  @State private var isCheckingPermission = false
  @State private var initiatedFlow = false

  enum PermissionState {
    case notRequested
    case granted
    case needsAction  // requested or settings opened, awaiting quit & reopen / toggle
  }

  private let actionAccent = DayflowOnboardingToken.primaryButtonFill
  private let privacyTextColor = Color(nsColor: .labelColor)

  var body: some View {
    ZStack(alignment: .bottomTrailing) {
      HStack(alignment: .top, spacing: 60) {
        // Left side — text and controls
        VStack(alignment: .leading, spacing: 10) {
          Text("最后一步！")
            .font(.custom("Figtree-Bold", size: 16))
            .foregroundColor(Color(hex: "F96E00"))

          Text("权限")
            .font(.system(size: 28, weight: .semibold, design: .rounded))
            .foregroundColor(.black)

          Text("Dayflow 可以帮助你理解当日工作。")
            .font(.custom("Figtree-Medium", size: 14))
            .foregroundColor(Color(hex: "5B5B5B"))
            .fixedSize(horizontal: false, vertical: true)

          // Privacy info box
          VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 8) {
              Image(systemName: "shield.fill")
                .font(.system(size: 14))
                .foregroundColor(privacyTextColor)
              Text("Dayflow 设计注重隐私与安全。")
                .font(.custom("Figtree-Bold", size: 14))
                .foregroundColor(privacyTextColor)
                .fixedSize(horizontal: false, vertical: true)
            }

            Text(
              "Dayflow 将所有录屏保存在你的 Mac 本地，并可使用本地 AI 模型完成私有化处理。"
            )
            .font(.custom("Figtree-Medium", size: 14))
            .foregroundColor(privacyTextColor)

            Text("你始终掌握控制权，随时可暂停或关闭 Dayflow。")
              .font(.custom("Figtree-Medium", size: 14))
              .foregroundColor(privacyTextColor)
          }
          .padding(16)
          .frame(maxWidth: 351, alignment: .leading)
          .dayflowCard(cornerRadius: 10)

          // State-based messaging
          Group {
            switch permissionState {
            case .notRequested:
              EmptyView()
            case .granted:
              Text("✓ 已获得权限，可继续下一步。")
                .font(.custom("Figtree", size: 14))
                .foregroundColor(.green)
            case .needsAction:
              Text("请为 Dayflow 开启录屏权限，随后退出并重新打开应用完成设置。")
                .font(.custom("Figtree", size: 14))
                .foregroundColor(.orange)
            }
          }

          // Action buttons
          Group {
            switch permissionState {
            case .notRequested:
              DayflowSurfaceButton(
                action: requestPermission,
                content: {
                  HStack(spacing: 6) {
                    if isCheckingPermission {
                      ProgressView()
                        .scaleEffect(0.7)
                        .progressViewStyle(CircularProgressViewStyle())
                    }
                    Text(isCheckingPermission ? "检查中..." : "打开系统设置")
                      .font(.custom("Figtree-SemiBold", size: 12))
                      .tracking(-0.48)
                  }
                },
                background: actionAccent,
                foreground: DayflowOnboardingToken.primaryButtonText,
                borderColor: .clear,
                cornerRadius: 8,
                horizontalPadding: 12,
                verticalPadding: 12,
                showOverlayStroke: true
              )
              .disabled(isCheckingPermission)

            case .needsAction:
              HStack {
                Spacer(minLength: 0)

                HStack(spacing: 12) {
                  DayflowSurfaceButton(
                    action: openSystemSettings,
                    content: {
                      Text("打开系统设置")
                        .font(.custom("Figtree-SemiBold", size: 12))
                        .tracking(-0.48)
                    },
                    background: Color(nsColor: .controlBackgroundColor).opacity(0.82),
                    foreground: actionAccent,
                    borderColor: actionAccent.opacity(0.36),
                    cornerRadius: 8,
                    horizontalPadding: 12,
                    verticalPadding: 12,
                    showOverlayStroke: true,
                    isSecondaryStyle: true,
                  )

                  DayflowSurfaceButton(
                    action: quitAndReopen,
                    content: {
                      Text("退出并重开")
                        .font(.custom("Figtree-SemiBold", size: 12))
                        .tracking(-0.48)
                    },
                    background: Color(nsColor: .controlBackgroundColor).opacity(0.82),
                    foreground: actionAccent,
                    borderColor: actionAccent.opacity(0.36),
                    cornerRadius: 8,
                    horizontalPadding: 12,
                    verticalPadding: 12,
                    showOverlayStroke: true,
                    isSecondaryStyle: true,
                  )
                }
              }
            case .granted:
              EmptyView()
            }
          }

          Spacer()
        }
        .frame(maxWidth: 374)

        Spacer()

        // Right side - image
        if let image = NSImage(named: "ScreenRecordingPermissions") {
          Image(nsImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: 486)
            .dayflowCard(cornerRadius: 12)
        }
      }

      // Navigation buttons — bottom right
      HStack(spacing: 15) {
        DayflowSurfaceButton(
          action: onBack,
          content: { Text("返回").font(.custom("Figtree-Medium", size: 12)).tracking(-0.48) },
          background: Color(nsColor: .controlBackgroundColor).opacity(0.72),
          foreground: Color(hex: "B6B6B6"),
          borderColor: Color(hex: "B6B6B6"),
          cornerRadius: 4,
          horizontalPadding: 40,
          verticalPadding: 12,
          isSecondaryStyle: true
        )
        DayflowSurfaceButton(
          action: {
            if permissionState == .granted { onNext() }
          },
          content: { Text("下一步").font(.custom("Figtree-Medium", size: 12)).tracking(-0.48) },
          background: permissionState == .granted
            ? DayflowOnboardingToken.primaryButtonFill
            : DayflowOnboardingToken.primaryButtonFill.opacity(0.3),
          foreground: DayflowOnboardingToken.primaryButtonText,
          borderColor: .clear,
          cornerRadius: 4,
          horizontalPadding: 40,
          verticalPadding: 12,
          showOverlayStroke: permissionState == .granted
        )
        .disabled(permissionState != .granted)
      }
    }
    .padding(.leading, 105)
    .padding(.trailing, 60)
    .padding(.top, 30)
    .padding(.bottom, 40)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .onAppear {
      // If already granted, mark as granted; otherwise start in notRequested
      if CGPreflightScreenCaptureAccess() {
        permissionState = .granted
        Task { @MainActor in AppDelegate.allowTermination = false }
      } else {
        permissionState = .notRequested
        Task { @MainActor in AppDelegate.allowTermination = true }
      }
    }
    // Re-check when app becomes active again (e.g., returning from System Settings)
    .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification))
    { _ in
      // Only transition to granted here; avoid flipping notChecked to denied automatically
      if CGPreflightScreenCaptureAccess() {
        permissionState = .granted
        Task { @MainActor in AppDelegate.allowTermination = false }
      }
    }
    .onDisappear {
      Task { @MainActor in AppDelegate.allowTermination = false }
    }
  }

  private func requestPermission() {
    guard !isCheckingPermission else { return }
    isCheckingPermission = true
    initiatedFlow = true

    // This will prompt and register the app with TCC; may return false
    _ = CGRequestScreenCaptureAccess()
    if CGPreflightScreenCaptureAccess() {
      permissionState = .granted
      AnalyticsService.shared.capture("screen_permission_granted")
      Task { @MainActor in AppDelegate.allowTermination = false }
    } else {
      permissionState = .needsAction
      AnalyticsService.shared.capture("screen_permission_denied")
      Task { @MainActor in AppDelegate.allowTermination = true }
    }
    isCheckingPermission = false
  }

  private func openSystemSettings() {
    initiatedFlow = true
    Task { @MainActor in AppDelegate.allowTermination = true }
    if let url = URL(
      string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")
    {
      _ = NSWorkspace.shared.open(url)
    }
    // Move to needsAction so we show Quit & Reopen guidance
    if permissionState != .granted { permissionState = .needsAction }
  }

  private func quitAndReopen() {
    Task { @MainActor in
      AppDelegate.allowTermination = true
      NSApp.terminate(nil)
    }
  }
}
