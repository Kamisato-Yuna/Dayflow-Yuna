//
//  OnboardingPrototypeRoleSelectionStep.swift
//  Dayflow
//

import SwiftUI

struct OnboardingPrototypeRoleSelectionStep: View {
  let onContinue: (String) -> Void

  private let roles = [
    "软件工程师", "创始人 / 高管", "设计师", "学生", "产品经理",
    "数据科学家", "其他",
  ]
  @State private var selectedRole: String?
  @State private var otherText = ""

  private var resolvedRole: String? {
    guard let selectedRole else { return nil }
    if selectedRole == "其他" {
      return otherText.trimmingCharacters(in: .whitespaces).isEmpty
        ? nil : otherText.trimmingCharacters(in: .whitespaces)
    }
    return selectedRole
  }

  var body: some View {
    VStack(spacing: 0) {
      Spacer()
        .frame(height: 39)

      Text("帮 Dayflow 更准确地了解你的工作场景。")
        .font(.custom("HanziPen SC", size: 40))
        .tracking(-1.2)
        .multilineTextAlignment(.center)
        .foregroundColor(DayflowOnboardingToken.title)
        .lineSpacing(40 * 0.2)
        .frame(maxWidth: 708)
        .fixedSize(horizontal: false, vertical: true)

      Spacer()
        .frame(height: 60)

      VStack(spacing: 24) {
        VStack(spacing: 4) {
          Text("你是做什么工作的？")
            .font(.custom("Figtree", size: 20))
            .foregroundColor(DayflowOnboardingToken.title)

          Text("这会帮助 Dayflow 生成更贴合你的分类。")
            .font(.custom("Figtree", size: 20))
            .foregroundColor(DayflowOnboardingToken.secondaryText)
        }
        .multilineTextAlignment(.center)

        VStack(spacing: 8) {
          HStack(spacing: 8) {
            ForEach(roles.prefix(4), id: \.self) { role in
              roleChip(role)
            }
          }
          HStack(spacing: 8) {
            ForEach(roles.dropFirst(4), id: \.self) { role in
              roleChip(role)
            }
          }
        }
      }
      .padding(.horizontal, 28)
      .padding(.vertical, 28)
      .dayflowOnboardingPanel()

      if selectedRole == "其他" {
        VStack(spacing: 16) {
          Text("请填写")
            .font(.custom("Figtree", size: 20))
            .foregroundColor(DayflowOnboardingToken.title)

          TextField("", text: $otherText)
            .font(.custom("Figtree", size: 16))
            .foregroundColor(DayflowOnboardingToken.title)
            .textFieldStyle(.plain)
            .padding(.horizontal, 12)
            .frame(width: 353, height: 34)
            .dayflowOnboardingTextField()
        }
        .padding(.top, 32)
        .transition(.opacity.combined(with: .move(edge: .top)))
      }

      Spacer()

      DayflowSurfaceButton(
        action: {
          if let role = resolvedRole {
            onContinue(role)
          }
        },
        content: {
          Text("继续")
            .font(.custom("Figtree", size: 14))
            .fontWeight(.semibold)
        },
        background: DayflowOnboardingToken.primaryButtonFill,
        foreground: DayflowOnboardingToken.primaryButtonText,
        borderColor: .clear,
        cornerRadius: 8,
        horizontalPadding: 59,
        verticalPadding: 12,
        minWidth: 234,
        showOverlayStroke: true
      )
      .opacity(resolvedRole == nil ? 0.4 : 1.0)
      .allowsHitTesting(resolvedRole != nil)
      .animation(.easeInOut(duration: 0.2), value: resolvedRole)

      Spacer()
        .frame(height: 60)
    }
    .animation(.easeInOut(duration: 0.25), value: selectedRole == "Other")
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private func roleChip(_ role: String) -> some View {
    let isSelected = selectedRole == role
    return Button {
      selectedRole = role
    } label: {
      Text(role)
        .font(.custom("Figtree", size: 16))
        .foregroundColor(DayflowOnboardingToken.title)
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .dayflowOnboardingOptionCard(isSelected: isSelected, cornerRadius: 18)
    }
    .buttonStyle(.plain)
    .pointingHandCursor()
  }
}
