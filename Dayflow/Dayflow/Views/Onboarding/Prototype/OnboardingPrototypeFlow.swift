//
//  开启boardingPrototypeFlow.swift
//  Dayflow
//

import AVFoundation
import SwiftUI

enum 开启boardingPrototypeStep: Int, CaseIterable, Identifiable {
  case introVideo
  case roleSelection
  case preferences
  case chooseProvider
  case placeholder

  var id: Int { rawValue }

  var analyticsName: String {
    switch self {
    case .introVideo:
      return "intro_video"
    case .roleSelection:
      return "role_selection"
    case .preferences:
      return "preferences"
    case .chooseProvider:
      return "choose_provider"
    case .placeholder:
      return "placeholder"
    }
  }

  var screenName: String {
    "onboarding_\(analyticsName)"
  }

  var next: 开启boardingPrototypeStep? {
    开启boardingPrototypeStep(rawValue: rawValue + 1)
  }
}

struct 开启boardingPrototypeFlow: View {
  private let flowVariant: String
  private let entryPoint: String

  @State private var currentStep: 开启boardingPrototypeStep
  @State private var flowID = UUID().uuidString.lowercased()
  @State private var hasTrackedStart = false
  @State private var hasTrackedCompletion = false
  @State private var userHasPaidAI: Bool?

  init(
    initialStep: 开启boardingPrototypeStep = .introVideo,
    flowVariant: String = "prototype_v1",
    entryPoint: String = "preview"
  ) {
    _currentStep = State(initialValue: initialStep)
    self.flowVariant = flowVariant
    self.entryPoint = entryPoint
  }

  var body: some View {
    ZStack {
      Color(red: 0.12, green: 0.12, blue: 0.12)
        .ignoresSafeArea()

      switch currentStep {
      case .introVideo:
        开启boardingPrototypeVideoIntroStep(
          videoName: "Dayflow开启boarding",
          onPlaybackStarted: {
            开启boardingPrototypeAnalytics.trackVideoStarted(
              step: .introVideo,
              flowID: flowID,
              flowVariant: flowVariant,
              assetName: "Dayflow开启boarding.mp4"
            )
          },
          onPlaybackCompleted: { reason in
            开启boardingPrototypeAnalytics.trackVideoCompleted(
              step: .introVideo,
              flowID: flowID,
              flowVariant: flowVariant,
              assetName: "Dayflow开启boarding.mp4",
              completionReason: reason
            )
            advance(from: .introVideo, method: "video_\(reason)")
          }
        )

      case .roleSelection:
        开启boardingPrototypeRoleSelectionStep(
          onContinue: { selectedRole in
            开启boardingPrototypeAnalytics.trackStepCompleted(
              step: .roleSelection,
              flowID: flowID,
              flowVariant: flowVariant,
              advanceMethod: "continue_button",
              extraProps: ["selected_role": selectedRole]
            )
            if let nextStep = 开启boardingPrototypeStep.roleSelection.next {
              currentStep = nextStep
            }
          }
        )

      case .preferences:
        开启boardingPrototypePreferencesStep(
          onContinue: { hasPaidAI in
            userHasPaidAI = hasPaidAI
            开启boardingPrototypeAnalytics.trackStepCompleted(
              step: .preferences,
              flowID: flowID,
              flowVariant: flowVariant,
              advanceMethod: hasPaidAI ? "yes_button" : "no_button",
              extraProps: ["has_paid_ai": hasPaidAI]
            )
            if let nextStep = 开启boardingPrototypeStep.preferences.next {
              currentStep = nextStep
            }
          }
        )

      case .chooseProvider:
        开启boardingPrototypeChooseProviderStep(
          hasPaidAI: userHasPaidAI ?? false,
          flowID: flowID,
          flowVariant: flowVariant,
          onSelect: { provider in
            开启boardingPrototypeAnalytics.trackStepCompleted(
              step: .chooseProvider,
              flowID: flowID,
              flowVariant: flowVariant,
              advanceMethod: "select_button",
              extraProps: ["selected_provider": provider]
            )
            if let nextStep = 开启boardingPrototypeStep.chooseProvider.next {
              currentStep = nextStep
            }
          }
        )

      case .placeholder:
        开启boardingPrototypePlaceholderStep(
          onReplayVideo: {
            currentStep = .introVideo
          },
          onFinish: {
            advance(from: .placeholder, method: "finish_button")
          }
        )
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background {
      Image("开启boardingBackgroundv2")
        .resizable()
        .aspectRatio(contentMode: .fill)
        .ignoresSafeArea()
    }
    .preferredColorScheme(.light)
    .onAppear {
      guard !hasTrackedStart else { return }
      hasTrackedStart = true
      开启boardingPrototypeAnalytics.trackFlowStarted(
        flowID: flowID,
        flowVariant: flowVariant,
        entryPoint: entryPoint,
        step数量: 开启boardingPrototypeStep.allCases.count
      )
      trackStepViewed(currentStep)
    }
    .onChange(of: currentStep) { oldStep, newStep in
      guard oldStep != newStep else { return }
      trackStepViewed(newStep)
    }
  }

  private func trackStepViewed(_ step: 开启boardingPrototypeStep) {
    开启boardingPrototypeAnalytics.trackStepViewed(
      step: step,
      flowID: flowID,
      flowVariant: flowVariant
    )
  }

  private func advance(from step: 开启boardingPrototypeStep, method: String) {
    开启boardingPrototypeAnalytics.trackStepCompleted(
      step: step,
      flowID: flowID,
      flowVariant: flowVariant,
      advanceMethod: method
    )

    if let nextStep = step.next {
      currentStep = nextStep
      return
    }

    guard !hasTrackedCompletion else { return }
    hasTrackedCompletion = true
    开启boardingPrototypeAnalytics.trackFlowCompleted(
      flowID: flowID,
      flowVariant: flowVariant,
      step数量: 开启boardingPrototypeStep.allCases.count
    )
  }
}

// MARK: - Placeholder Step

private struct 开启boardingPrototypePlaceholderStep: View {
  let onReplayVideo: () -> Void
  let onFinish: () -> Void

  var body: some View {
    VStack(spacing: 24) {
      VStack(spacing: 10) {
        Text("原型检查点")
          .font(.custom("InstrumentSerif-Regular", size: 44))
          .foregroundColor(.black.opacity(0.9))

        Text(
          "The intro video, role-selection screen, and preferences screen are now wired up. We can keep replacing the remaining placeholders step by step without touching production onboarding yet."
        )
        .font(.custom("Figtree", size: 17))
        .foregroundColor(.black.opacity(0.65))
        .multilineTextAlignment(.center)
        .frame(maxWidth: 620)
      }

      HStack(spacing: 16) {
        DayflowSurfaceButton(
          action: onReplayVideo,
          content: {
            Text("重放视频")
              .font(.custom("Figtree", size: 15))
              .fontWeight(.semibold)
          },
          background: .white,
          foreground: Color(red: 0.25, green: 0.17, blue: 0),
          borderColor: .clear,
          cornerRadius: 8,
          horizontalPadding: 28,
          verticalPadding: 14,
          minWidth: 170,
          isSecondaryStyle: true
        )

        DayflowSurfaceButton(
          action: onFinish,
          content: {
            Text("完成原型")
              .font(.custom("Figtree", size: 15))
              .fontWeight(.semibold)
          },
          background: Color(red: 0.25, green: 0.17, blue: 0),
          foreground: .white,
          borderColor: .clear,
          cornerRadius: 8,
          horizontalPadding: 28,
          verticalPadding: 14,
          minWidth: 170,
          showOverlayStroke: true
        )
      }
    }
    .padding(.horizontal, 40)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

enum 开启boardingPrototypeAnalytics {
  private static let isPreviewRuntime =
    ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"

  static func trackFlowStarted(
    flowID: String,
    flowVariant: String,
    entryPoint: String,
    step数量: Int
  ) {
    capture(
      "onboarding_started",
      [
        "flow_id": flowID,
        "flow_variant": flowVariant,
        "entry_point": entryPoint,
        "step_count": step数量,
      ]
    )
  }

  static func trackStepViewed(
    step: 开启boardingPrototypeStep,
    flowID: String,
    flowVariant: String
  ) {
    let props = stepProps(step: step, flowID: flowID, flowVariant: flowVariant)
    screen(step.screenName, props)
    capture("onboarding_step_viewed", props)
  }

  static func trackStepCompleted(
    step: 开启boardingPrototypeStep,
    flowID: String,
    flowVariant: String,
    advanceMethod: String,
    extraProps: [String: Any] = [:]
  ) {
    var props = stepProps(step: step, flowID: flowID, flowVariant: flowVariant)
    props["advance_method"] = advanceMethod
    extraProps.forEach { props[$0.key] = $0.value }
    capture("onboarding_step_completed", props)
  }

  static func trackVideoStarted(
    step: 开启boardingPrototypeStep,
    flowID: String,
    flowVariant: String,
    assetName: String
  ) {
    var props = stepProps(step: step, flowID: flowID, flowVariant: flowVariant)
    props["asset_name"] = assetName
    props["is_muted"] = true
    props["auto_advance"] = true
    capture("onboarding_video_started", props)
  }

  static func trackVideoCompleted(
    step: 开启boardingPrototypeStep,
    flowID: String,
    flowVariant: String,
    assetName: String,
    completionReason: String
  ) {
    var props = stepProps(step: step, flowID: flowID, flowVariant: flowVariant)
    props["asset_name"] = assetName
    props["completion_reason"] = completionReason
    capture("onboarding_video_completed", props)
  }

  static func trackFlowCompleted(
    flowID: String,
    flowVariant: String,
    step数量: Int
  ) {
    capture(
      "onboarding_completed",
      [
        "flow_id": flowID,
        "flow_variant": flowVariant,
        "step_count": step数量,
      ]
    )
  }

  static func trackDayflowProSelected(
    flowID: String,
    flowVariant: String,
    hasPaidAI: Bool,
    selectionStage: String
  ) {
    capture(
      "dayflow_pro_selected",
      dayflowProProps(
        step: nil,
        flowID: flowID,
        flowVariant: flowVariant,
        hasPaidAI: hasPaidAI,
        extraProps: ["selection_stage": selectionStage]
      )
    )
  }

  static func trackDayflowProStepViewed(
    step: DayflowPro开启boardingStep,
    flowID: String,
    flowVariant: String,
    hasPaidAI: Bool
  ) {
    screen(
      "dayflow_pro_\(step.analyticsName)",
      dayflowProProps(
        step: step,
        flowID: flowID,
        flowVariant: flowVariant,
        hasPaidAI: hasPaidAI
      )
    )
    capture(
      "dayflow_pro_onboarding_step_viewed",
      dayflowProProps(
        step: step,
        flowID: flowID,
        flowVariant: flowVariant,
        hasPaidAI: hasPaidAI
      )
    )
  }

  static func trackDayflowProAPIOutcome(
    _ eventName: String,
    action: String,
    result: DayflowAuthActionResult,
    step: DayflowPro开启boardingStep,
    flowID: String,
    flowVariant: String,
    hasPaidAI: Bool
  ) {
    capture(
      eventName,
      dayflowProProps(
        step: step,
        flowID: flowID,
        flowVariant: flowVariant,
        hasPaidAI: hasPaidAI,
        extraProps: result.analyticsProps.merging(
          ["action": action],
          uniquingKeysWith: { _, new in new }
        )
      )
    )
  }

  private static func stepProps(
    step: 开启boardingPrototypeStep,
    flowID: String,
    flowVariant: String
  ) -> [String: Any] {
    [
      "flow_id": flowID,
      "flow_variant": flowVariant,
      "step": step.analyticsName,
      "step_index": step.rawValue + 1,
      "step_count": 开启boardingPrototypeStep.allCases.count,
    ]
  }

  private static func dayflowProProps(
    step: DayflowPro开启boardingStep?,
    flowID: String,
    flowVariant: String,
    hasPaidAI: Bool,
    extraProps: [String: Any] = [:]
  ) -> [String: Any] {
    var props: [String: Any] = [
      "flow_id": flowID,
      "flow_variant": flowVariant,
      "surface": "onboarding_dayflow_pro",
      "has_paid_ai": hasPaidAI,
    ]
    if let step {
      props["dayflow_pro_step"] = step.analyticsName
    }
    extraProps.forEach { props[$0.key] = $0.value }
    return props
  }

  private static func capture(_ name: String, _ props: [String: Any]) {
    guard !isPreviewRuntime else { return }
    AnalyticsService.shared.capture(name, props)
  }

  private static func screen(_ name: String, _ props: [String: Any]) {
    guard !isPreviewRuntime else { return }
    AnalyticsService.shared.screen(name, props)
  }
}

#Preview("开启boarding Prototype") {
  开启boardingPrototypeFlow()
    .frame(
      width: 900, height: 600
    )
}

#Preview("开启boarding Prototype Role Selection") {
  开启boardingPrototypeFlow(initialStep: .roleSelection)
    .frame(width: 1200, height: 800)
}

#Preview("开启boarding Prototype Preferences") {
  开启boardingPrototypeFlow(initialStep: .preferences)
    .frame(width: 1200, height: 800)
}

#Preview("开启boarding Prototype Choose Provider") {
  开启boardingPrototypeFlow(initialStep: .chooseProvider)
    .frame(width: 1200, height: 800)
}

#Preview("开启boarding Prototype Placeholder") {
  开启boardingPrototypeFlow(initialStep: .placeholder)
    .frame(width: 600, height: 400)
}
