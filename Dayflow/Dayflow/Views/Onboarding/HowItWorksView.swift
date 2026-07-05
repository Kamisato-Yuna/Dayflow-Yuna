//
//  HowItWorksView.swift
//  Dayflow
//
//  Re-responsive + scroll-safe rewrite, August 2025
//

import SwiftUI

struct HowItWorksView: View {
  @State private var titleOpacity: Double = 0
  @State private var cardOffsets: [CGFloat] = [50, 50, 50]
  @State private var cardOpacities: [Double] = [0, 0, 0]
  @State private var buttonsOpacity: Double = 0

  private let fullText = "Dayflow 工作原理"

  // Navigation callbacks
  var onBack: () -> Void
  var onNext: () -> Void

  private let cards: [(systemIcon: String, title: String, body: String)] = [
    (
      "bolt.fill",
      "安装后即可使用",
      "Dayflow 会定期截图以理解你正在进行的工作，所有内容均私有保存于你的设备。你可随时在偏好设置中关闭此功能。"
    ),
    (
      "lock.shield.fill",
      "默认隐私保护",
      "Dayflow 可完全基于本地 AI 运行，这意味着你的数据不会离开你的设备。下方可查看源代码，欢迎给我们点 Star。"
    ),
    (
      "sparkles",
      "洞察你的工作",
      "它能分辨“教程”和“分心内容”，帮助你更准确地理解自己当下正在做的事情。"
    ),
  ]

  var body: some View {
    ScrollView(.vertical, showsIndicators: false) {
      VStack(spacing: 40) {
        Text(fullText)
          .font(.custom("HanziPen SC", size: 48))
          .multilineTextAlignment(.center)
          .frame(maxWidth: .infinity, minHeight: 60)
          .foregroundColor(DayflowOnboardingToken.title)
          .opacity(titleOpacity)
          .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
              titleOpacity = 1
            }
            // Animate cards after title appears
            animateCards()
          }

        VStack(spacing: 16) {
          ForEach(cards.indices, id: \.self) { idx in
            HowItWorksCard(
              systemIcon: cards[idx].systemIcon,
              title: cards[idx].title,
              description: cards[idx].body
            )
            .offset(y: cardOffsets[idx])
            .opacity(cardOpacities[idx])
          }
        }

      }
      .frame(maxWidth: 600)  // Match card width

      // Navigation section - all buttons on same line
      HStack {
        DayflowSurfaceButton(
          action: onBack,
          content: { Text("返回").font(.custom("Figtree", size: 14)).fontWeight(.semibold) },
          background: Color(nsColor: .controlBackgroundColor).opacity(0.72),
          foreground: DayflowOnboardingToken.secondaryButtonText,
          borderColor: Color(nsColor: .separatorColor).opacity(0.5),
          cornerRadius: 8,
          horizontalPadding: 20,
          verticalPadding: 12,
          minWidth: 120,
          isSecondaryStyle: true
        )

        Spacer()

        DayflowSurfaceButton(
          action: {
            if let url = URL(string: "https://github.com/jerryzliu/Dayflow") {
              NSWorkspace.shared.open(url)
            }
          },
          content: {
            HStack(spacing: 12) {
              DayflowExternalImageBadge(
                imageName: "GithubIcon",
                size: 24,
                cornerRadius: 7,
                contentScale: 0.68
              )
              Text("在 GitHub 上给 Dayflow 点赞").font(.custom("Figtree", size: 14)).fontWeight(.medium)
            }
          },
          background: DayflowOnboardingToken.primaryButtonFill,
          foreground: DayflowOnboardingToken.primaryButtonText,
          borderColor: .clear,
          cornerRadius: 8,
          horizontalPadding: 24,
          verticalPadding: 12,
          showOverlayStroke: true
        )

        Spacer()

        DayflowSurfaceButton(
          action: onNext,
          content: { Text("下一步").font(.custom("Figtree", size: 14)).fontWeight(.semibold) },
          background: DayflowOnboardingToken.primaryButtonFill,
          foreground: DayflowOnboardingToken.primaryButtonText,
          borderColor: .clear,
          cornerRadius: 8,
          horizontalPadding: 20,
          verticalPadding: 12,
          minWidth: 120,
          showOverlayStroke: true
        )
      }
      .frame(maxWidth: 600)  // Match card width
      .padding(.top, 40)
      .opacity(buttonsOpacity)  // Use separate opacity for buttons

      // Overall breathing room
      .padding(.horizontal, 40)
      .padding(.bottom, 40)
    }
  }
}

extension HowItWorksView {
  fileprivate func animateCards() {
    for idx in cards.indices {
      // Each card appears 1 second after the previous one
      // First card appears after 1 second, then 1 second between each
      let delay = 1.0 + Double(idx) * 1.0

      DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
        withAnimation(
          .spring(
            response: 0.8,
            dampingFraction: 0.75,
            blendDuration: 0)
        ) {
          cardOffsets[idx] = 0
          cardOpacities[idx] = 1
        }
      }
    }

    // Animate buttons 1 second after the last card
    let buttonsDelay = 1.0 + Double(cards.count) * 1.0
    DispatchQueue.main.asyncAfter(deadline: .now() + buttonsDelay) {
      withAnimation(.easeInOut(duration: 0.6)) {
        buttonsOpacity = 1
      }
    }
  }
}
