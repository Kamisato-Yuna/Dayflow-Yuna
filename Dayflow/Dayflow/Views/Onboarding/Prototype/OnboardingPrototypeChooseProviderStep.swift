//
//  OnboardingPrototypeChooseProviderStep.swift
//  Dayflow
//

import AppKit
import SwiftUI

// MARK: - Choose Provider Step

struct OnboardingPrototypeChooseProviderStep: View {
  let hasPaidAI: Bool
  let flowID: String
  let flowVariant: String
  let onSelect: (String) -> Void

  @State private var showAllOptions = false
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  private let layoutScale: CGFloat = 0.8
  private let textScale: CGFloat = 1.1

  private func scaled(_ value: CGFloat) -> CGFloat {
    value * layoutScale
  }

  private func scaledText(_ value: CGFloat) -> CGFloat {
    scaled(value) * textScale
  }

  private var recommendedProviders: (first: String, second: String) {
    hasPaidAI ? ("chatgpt_claude", "gemini") : ("gemini", "chatgpt_claude")
  }

  private func providerInfo(for id: String) -> (
    icon: String, title: String, pros: [String], caveats: [String]
  ) {
    switch id {
    case "chatgpt_claude":
      return (
        "chatgpt_claude_asset",
        "ChatGPT 或 Claude",
        [
          "智能性与稳定性更高",
          "每日额度占用低于 1%",
          "适合 ChatGPT Plus 或 Claude Pro 的付费用户",
        ],
          ["需要安装 Codex 或 Claude CLI"]
      )
    case "gemini":
      return (
        "gemini_asset",
        "Google Gemini",
        [
          "使用 Gemini 的免费额度（无需订阅）",
          "比本地模型更快更准确",
          "相较本地模型更容易设置",
        ],
        ["能力略低于 ChatGPT 与 Claude"]
      )
    case "local":
      return (
        "desktopcomputer",
        "Local AI",
        [
          "100% 私有，数据不离开你的电脑"
        ],
        [
          "智能水平明显偏弱",
          "不建议新手首次使用本地 LLM",
          "需 16GB+ 内存、4GB 可用磁盘空间，建议 M1 或更高芯片",
        ]
      )
    default:
      return ("", "", [], [])
    }
  }

  private func secondaryBadgeText(for providerID: String) -> String {
    switch providerID {
    case "chatgpt_claude":
      return "使用现有账号"
    case "gemini":
      return "免费设置"
    case "local":
      return "最私密"
    default:
      return "备选"
    }
  }

  var body: some View {
    VStack(spacing: 0) {
      // Title
      Text("选择 Dayflow 的运行方式")
        .font(.custom("HanziPen SC", size: scaledText(40)))
        .tracking(-1.2 * layoutScale)
        .multilineTextAlignment(.center)
        .foregroundColor(DayflowOnboardingToken.title)
        .frame(maxWidth: .infinity)
        .padding(.top, scaled(25))
        .padding(.bottom, scaled(30))

      // Cards area
      if showAllOptions {
        VStack(spacing: scaled(12)) {
          HStack(spacing: scaled(12)) {
            compactCard(for: "chatgpt_claude")
            compactCard(for: "gemini")
            compactCard(for: "local")
          }
        }
        .padding(.horizontal, scaled(40))
        .transition(.opacity)
      } else {
        let recs = recommendedProviders
        let first = providerInfo(for: recs.first)
        let second = providerInfo(for: recs.second)

        HStack(spacing: scaled(20)) {
          tallCard(
            icon: first.icon, title: first.title,
            badgeText: "推荐",
            badgeType: .orange,
            pros: first.pros, caveats: first.caveats,
            isHighlighted: true
          )
          tallCard(
            icon: second.icon, title: second.title,
            badgeText: secondaryBadgeText(for: recs.second),
            badgeType: .green,
            pros: second.pros, caveats: second.caveats,
            isHighlighted: false
          )
        }
        .padding(.horizontal, scaled(40))
        .transition(.opacity)
      }

      Spacer()

      // Toggle pill
      DayflowSurfaceButton(
        action: {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
          showAllOptions.toggle()
        }
        },
        content: {
          Text(showAllOptions ? "仅看推荐" : "查看全部")
            .font(.custom("Figtree", size: scaledText(16)))
        },
        background: DayflowContentToken.secondaryFill(
          colorScheme: colorScheme,
          reduceTransparency: reduceTransparency
        ),
        foreground: DayflowOnboardingToken.title,
        borderColor: contentBorder,
        cornerRadius: 999,
        horizontalPadding: scaled(20),
        verticalPadding: scaled(8),
        isSecondaryStyle: true
      )
      .padding(.bottom, scaled(30))
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  // MARK: - Tall Card (recommended view)

  private func tallCard(
    icon: String, title: String,
    badgeText: String, badgeType: BadgeType,
    pros: [String], caveats: [String],
    isHighlighted: Bool
  ) -> some View {
    VStack(spacing: 0) {
      VStack(alignment: .leading, spacing: 0) {
        HStack {
          Spacer()
          ProviderIconView(icon: icon, scale: layoutScale)
          Spacer()
        }
        .padding(.top, scaled(24))
        .padding(.bottom, scaled(16))

        HStack {
          Spacer()
          Text(title)
            .font(.custom("Figtree", size: scaledText(18)))
            .fontWeight(.semibold)
            .foregroundColor(.black.opacity(0.9))
          Spacer()
        }
        .padding(.bottom, scaled(8))

        HStack {
          Spacer()
          BadgeView(text: badgeText, type: badgeType, scale: layoutScale, fontScale: textScale)
          Spacer()
        }
        .padding(.bottom, scaled(24))

        ScrollView(.vertical, showsIndicators: false) {
          VStack(alignment: .leading, spacing: scaled(10)) {
            ForEach(pros, id: \.self) {
              FeatureRowView(feature: ($0, true), scale: layoutScale, fontScale: textScale)
            }
            ForEach(caveats, id: \.self) {
              FeatureRowView(feature: ($0, false), scale: layoutScale, fontScale: textScale)
            }
          }
          .padding(.horizontal, scaled(24))
        }
      }

      Spacer()

      selectButton(title: title)
        .padding(.horizontal, scaled(24))
        .padding(.bottom, scaled(24))
    }
    .frame(maxWidth: .infinity)
    .frame(maxHeight: scaled(432))
    .background(
      isHighlighted ? AnyView(SelectedCardBackground()) : AnyView(contentFill)
    )
    .cornerRadius(4)
    .overlay(
      isHighlighted
        ? AnyView(SelectedCardOverlay())
        : AnyView(
          RoundedRectangle(cornerRadius: 4).inset(by: 0.5).stroke(
            contentBorder,
            lineWidth: borderLineWidth
          )
        )
    )
    .modifier(CardShadowModifier(isSelected: isHighlighted))
  }

  // MARK: - Compact Card (all options view)

  private func compactCard(for id: String) -> some View {
    let info = providerInfo(for: id)

    return VStack(alignment: .leading, spacing: 0) {
      VStack(alignment: .leading, spacing: scaled(8)) {
        HStack(spacing: scaled(12)) {
          ProviderIconView(icon: info.icon, scale: layoutScale)
          Text(info.title)
            .font(.custom("Figtree", size: scaledText(18)))
            .fontWeight(.semibold)
            .foregroundColor(.black.opacity(0.9))
            .lineLimit(1)
        }

        ScrollView(.vertical, showsIndicators: false) {
          VStack(alignment: .leading, spacing: scaled(2)) {
            ForEach(info.pros, id: \.self) {
              FeatureRowView(feature: ($0, true), scale: layoutScale, fontScale: textScale)
            }
            ForEach(info.caveats, id: \.self) {
              FeatureRowView(feature: ($0, false), scale: layoutScale, fontScale: textScale)
            }
          }
        }
      }

      Spacer()

      HStack {
        Spacer()
        selectButton(title: info.title)
      }
    }
    .padding(.horizontal, scaled(20))
    .padding(.vertical, scaled(18))
    .frame(maxWidth: .infinity)
    .frame(height: scaled(205))
    .background(contentFill)
    .cornerRadius(4)
    .overlay(
      RoundedRectangle(cornerRadius: 4).inset(by: 0.5).stroke(
        contentBorder,
        lineWidth: borderLineWidth
      )
    )
  }

  private var contentFill: Color {
    DayflowContentToken.secondaryFill(
      colorScheme: colorScheme,
      reduceTransparency: reduceTransparency
    )
  }

  private var contentBorder: Color {
    DayflowContentToken.cardBorder(
      colorScheme: colorScheme,
      increaseContrast: NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
    )
  }

  private var borderLineWidth: CGFloat {
    NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast ? 1.2 : 1
  }

  private func selectButton(title: String) -> some View {
    DayflowSurfaceButton(
      action: {
        onSelect(title)
      },
      content: {
        Text("选择")
          .font(.custom("Figtree", size: scaledText(14)))
          .fontWeight(.semibold)
          .frame(maxWidth: .infinity)
      },
      background: DayflowOnboardingToken.primaryButtonFill,
      foreground: DayflowOnboardingToken.primaryButtonText,
      borderColor: .clear,
      cornerRadius: scaled(8),
      horizontalPadding: scaled(24),
      verticalPadding: scaled(12),
      showOverlayStroke: true
    )
  }
}
