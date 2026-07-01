import Foundation
import ScreenCaptureKit

enum RecordingControlMode: Equatable {
  case active
  case pausedTimed(endTime: Date)
  case pausedIndefinite
  case stopped
}

@MainActor
enum RecordingControl {
  static func currentMode() -> RecordingControlMode {
    currentMode(appState: .shared, pauseManager: .shared)
  }

  static func currentMode(
    appState: AppState,
    pauseManager: PauseManager
  ) -> RecordingControlMode {
    if appState.isRecording && pauseManager.is已暂停 {
      assertionFailure("Recording cannot be active while pause metadata is still set")
      return .active
    }

    if let endTime = pauseManager.pauseEndTime {
      return .pausedTimed(endTime: endTime)
    }

    if pauseManager.is已暂停Indefinitely {
      return .pausedIndefinite
    }

    return appState.isRecording ? .active : .stopped
  }

  static func start(reason: String) {
    Task { @MainActor in
      guard await hasScreenRecording权限() else {
        print("[RecordingControl] Screen recording permission not granted; start ignored")
        ScreenRecording权限Notice.post(reason: "recording_control_start")
        return
      }

      PauseManager.shared.clearPauseState()
      AppState.shared.setRecording(true, analyticsReason: reason)
    }
  }

  static func stop(reason: String) {
    PauseManager.shared.clearPauseState()
    AppState.shared.setRecording(false, analyticsReason: reason)
  }

  private static func hasScreenRecording权限() async -> Bool {
    guard CGPreflightScreenCaptureAccess() else { return false }

    do {
      _ = try await SCShareableContent.excludingDesktopWindows(
        false,
        onScreenWindows开启ly: true
      )
      return true
    } catch {
      return false
    }
  }
}
