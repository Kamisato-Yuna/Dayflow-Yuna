//
//  VideoLaunchView.swift
//  Dayflow
//
//  Launch animation screen that plays before onboarding or main app
//

import SwiftUI

struct VideoLaunchView: View {
  @State private var hasCompleted = false
  private var onComplete: (() -> Void)?

  func onVideoComplete(_ completion: @escaping () -> Void) -> VideoLaunchView {
    var view = self
    view.onComplete = completion
    return view
  }

  var body: some View {
    DayflowLineAnimationView(
      variant: .appLaunch,
      onCompleted: { _ in
        completeVideo()
      }
    )
    .onAppear {
      // Focus the window
      NSApp.activate(ignoringOtherApps: true)
    }
  }

  private func completeVideo() {
    guard !hasCompleted else { return }
    hasCompleted = true
    onComplete?()
  }
}

// Preview for development
struct VideoLaunchView_Previews: PreviewProvider {
  static var previews: some View {
    VideoLaunchView()
      .onVideoComplete {
        print("Video completed")
      }
  }
}
