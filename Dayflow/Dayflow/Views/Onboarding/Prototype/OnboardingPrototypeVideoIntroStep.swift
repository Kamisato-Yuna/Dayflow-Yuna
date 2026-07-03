//
//  OnboardingPrototypeVideoIntroStep.swift
//  Dayflow
//

import SwiftUI

struct OnboardingPrototypeVideoIntroStep: View {
  let animationName: String
  let onPlaybackStarted: () -> Void
  let onPlaybackCompleted: (String) -> Void

  @State private var hasCompletedPlayback = false

  var body: some View {
    DayflowLineAnimationView(
      variant: .onboardingIntro,
      onStarted: onPlaybackStarted,
      onCompleted: { reason in
        finishPlayback(reason: reason)
      }
    )
    .accessibilityIdentifier(animationName)
  }

  private func finishPlayback(reason: String) {
    guard !hasCompletedPlayback else { return }
    hasCompletedPlayback = true

    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
      onPlaybackCompleted(reason)
    }
  }
}
