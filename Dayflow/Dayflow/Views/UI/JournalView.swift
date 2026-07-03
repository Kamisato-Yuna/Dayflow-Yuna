import CryptoKit
import SwiftUI

// MARK: - Journal Coordinator

/// Coordinates journal-level UI state that needs to be shared across the view hierarchy
@MainActor
final class JournalCoordinator: ObservableObject {
  @Published var showOnboardingVideo = false
  @Published var showRemindersAfterOnboarding = false
}

struct JournalView: View {
  // MARK: - Storage & State
  @AppStorage("isJournalUnlocked") private var isUnlocked: Bool = false
  @AppStorage("hasCompletedJournalOnboarding") private var hasCompletedOnboarding: Bool = false
  @EnvironmentObject private var coordinator: JournalCoordinator
  @State private var accessCode: String = ""
  @State private var attempts: Int = 0
  @State private var showRemindersSheet: Bool = false

  // SHA256 hashed—nice try! But you're already in the source code...
  // so yes you can delete this function and build from source if you so desire.
  private let requiredCodeHash = "909ca0096d519dcf94aba6069fa664842bdf9de264725a6c543c4926abe6bdfa"
  private let betaNoticeCopy =
    "We're slowly letting people into the beta as we iterate and improve the experience. If you choose to participate in the beta, you acknowledge that you may encounter bugs and agree to provide feedback."

  var body: some View {
    ZStack {
      if isUnlocked {
        unlockedContent
          .transition(.opacity)
      } else {
        lockScreen
          .transition(.opacity.combined(with: .move(edge: .bottom)))
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    .sheet(isPresented: $showRemindersSheet) {
      JournalRemindersView(
        onSave: {
          showRemindersSheet = false
          coordinator.showRemindersAfterOnboarding = false
        },
        onCancel: {
          showRemindersSheet = false
          coordinator.showRemindersAfterOnboarding = false
        }
      )
    }
    .onChange(of: coordinator.showRemindersAfterOnboarding) { _, shouldShow in
      if shouldShow {
        showRemindersSheet = true
      }
    }
  }

  // MARK: - Lock Screen View
  var lockScreen: some View {
    VStack(spacing: 24) {
      Spacer()

      // Header: "Dayflow Journal" with BETA badge
      HStack(alignment: .top, spacing: 4) {
        Text("Dayflow 日志")
          .font(.custom("InstrumentSerif-Italic", size: 38))
          .foregroundColor(Color(red: 0.35, green: 0.22, blue: 0.12))

        // BETA badge
        Text("测试版")
          .font(.custom("Figtree-Bold", size: 11))
          .foregroundColor(.white)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(
            RoundedRectangle(cornerRadius: 6)
              .fill(Color(red: 0.98, green: 0.55, blue: 0.20))
          )
          .rotationEffect(.degrees(-12))
          .offset(x: -4, y: -4)
      }

      // Subtitle
      Text(betaNoticeCopy)
        .font(.custom("Figtree-Regular", size: 15))
        .foregroundColor(Color(red: 0.35, green: 0.22, blue: 0.12).opacity(0.8))
        .multilineTextAlignment(.center)
        .frame(maxWidth: 480)
        .padding(.horizontal, 24)

      Spacer().frame(height: 20)

      // Access code card
      accessCodeCard
        .modifier(Shake(animatableData: CGFloat(attempts)))

      Spacer()
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    .background(
      GeometryReader { geo in
        Image("JournalPreview")
          .resizable()
          .scaledToFill()
          .frame(width: geo.size.width, height: geo.size.height)
          .clipped()
          .allowsHitTesting(false)
      }
    )
  }

  // MARK: - Access Code Card
  // JournalLock is the entire card image (gradient bg + lock icon baked in)
  private var accessCodeCard: some View {
    ZStack(alignment: .bottom) {
      // Card background image (contains gradient + lock icon)
      Image("JournalLock")
        .resizable()
        .aspectRatio(contentMode: .fit)

      // Overlay content: title, text field, button (anchored to bottom)
      VStack(spacing: 16) {
        // Title
        Text("输入访问码")
          .font(.custom("Figtree-SemiBold", size: 20))
          .foregroundColor(Color(red: 0.85, green: 0.45, blue: 0.25))

        // Text field
        TextField("", text: $accessCode)
          .textFieldStyle(.plain)
          .font(.custom("Figtree-Medium", size: 15))
          .foregroundColor(Color(red: 0.25, green: 0.15, blue: 0.10))
          .multilineTextAlignment(.center)
          .padding(.horizontal, 14)
          .padding(.vertical, 12)
          .background(
            RoundedRectangle(cornerRadius: 8)
              .fill(Color.white)
          )
          .padding(.horizontal, 80)
          .submitLabel(.go)
          .onSubmit { validateCode() }

        // Submit button
        Button(action: validateCode) {
          Text("获取抢先体验")
            .font(.custom("Figtree-SemiBold", size: 15))
            .foregroundColor(Color(red: 0.35, green: 0.22, blue: 0.12))
            .padding(.horizontal, 28)
            .padding(.vertical, 10)
            .background(
              Capsule()
                .fill(
                  LinearGradient(
                    colors: [
                      Color(red: 1.0, green: 0.92, blue: 0.82),
                      Color(red: 1.0, green: 0.85, blue: 0.70),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                  )
                )
                .overlay(
                  Capsule()
                    .stroke(Color(red: 0.90, green: 0.75, blue: 0.55), lineWidth: 1)
                )
            )
        }
        .buttonStyle(.plain)
        .pointingHandCursor()
      }
      .padding(.bottom, 28)
    }
    .frame(width: 380)
    .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 6)
  }

  // MARK: - Unlocked Content
  @ViewBuilder
  var unlockedContent: some View {
    if hasCompletedOnboarding {
      // Main journal view
      JournalDayView(
        onSetReminders: { showRemindersSheet = true }
      )
      .frame(maxWidth: 980, alignment: .center)
      .padding(.horizontal, 12)
    } else {
      // Journal onboarding screen
      JournalOnboardingView(onStartOnboarding: {
        AnalyticsService.shared.capture("journal_onboarding_started")
        coordinator.showOnboardingVideo = true
      })
    }
  }

  // MARK: - Logic
  func validateCode() {
    // Lowercase input and compute SHA256 hash
    let inputLowercased = accessCode.lowercased()
    let inputData = Data(inputLowercased.utf8)
    let inputHash = SHA256.hash(data: inputData)
    let inputHashString = inputHash.compactMap { String(format: "%02x", $0) }.joined()

    if inputHashString == requiredCodeHash {
      AnalyticsService.shared.capture("journal_unlocked")
      withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
        isUnlocked = true
      }
    } else {
      withAnimation(.default) {
        attempts += 1
        accessCode = ""
      }
    }
  }
}

// MARK: - Journal Onboarding View

private struct JournalOnboardingView: View {
  var onStartOnboarding: () -> Void

  var body: some View {
    VStack(spacing: 24) {
      Spacer()

      // Title
      Text("设定今天的意图")
        .font(.custom("InstrumentSerif-Regular", size: 42))
        .foregroundColor(Color(red: 0.85, green: 0.45, blue: 0.15))
        .multilineTextAlignment(.center)

      // Description
      Text(
        "Dayflow 帮你追踪每日和长期目标，留出复盘空间，并生成每天的总结。"
      )
      .font(.custom("Figtree-Regular", size: 16))
      .foregroundColor(Color(red: 0.25, green: 0.15, blue: 0.10).opacity(0.8))
      .multilineTextAlignment(.center)
      .frame(maxWidth: 640)
      .padding(.horizontal, 24)

      Spacer()

      // Start onboarding button
      Button(action: onStartOnboarding) {
        Text("开始引导")
          .font(.custom("Figtree-SemiBold", size: 16))
          .foregroundColor(Color(red: 0.35, green: 0.22, blue: 0.12))
          .padding(.horizontal, 32)
          .padding(.vertical, 12)
          .background(
            Capsule()
              .fill(
                LinearGradient(
                  colors: [
                    Color(red: 1.0, green: 0.96, blue: 0.92),
                    Color(red: 1.0, green: 0.90, blue: 0.82),
                  ],
                  startPoint: .top,
                  endPoint: .bottom
                )
              )
              .overlay(
                Capsule()
                  .stroke(Color(red: 0.92, green: 0.85, blue: 0.78), lineWidth: 1)
              )
          )
      }
      .buttonStyle(.plain)
      .pointingHandCursor()

      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

// MARK: - Journal Onboarding Animation View

struct JournalOnboardingAnimationView: View {
  var onComplete: () -> Void

  @State private var hasCompleted = false

  var body: some View {
    DayflowLineAnimationView(
      variant: .journalOnboarding,
      onCompleted: { _ in
        completeVideo()
      }
    )
  }

  private func completeVideo() {
    guard !hasCompleted else { return }
    hasCompleted = true
    AnalyticsService.shared.capture("journal_onboarding_completed")
    onComplete()
  }
}

// MARK: - Helpers

// Shake Effect
struct Shake: GeometryEffect {
  var amount: CGFloat = 10
  var shakesPerUnit: CGFloat = 3
  var animatableData: CGFloat

  func effectValue(size: CGSize) -> ProjectionTransform {
    ProjectionTransform(
      CGAffineTransform(
        translationX:
          amount * sin(animatableData * .pi * shakesPerUnit),
        y: 0))
  }
}

#Preview {
  JournalView()
}
