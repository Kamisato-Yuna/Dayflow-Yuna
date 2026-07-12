//
//  OnboardingPrototypePreferencesStep.swift
//  Dayflow
//

import SwiftUI

// MARK: - Preferences Step

struct OnboardingPrototypePreferencesStep: View {
  let onContinue: (Bool) -> Void

  var body: some View {
    VStack(spacing: 0) {
      Spacer()

      VStack(spacing: 24) {
        Text("你有 ChatGPT 或 Claude 的付费账号吗？")
          .font(.custom("Figtree", size: 20))
          .foregroundColor(DayflowOnboardingToken.title)
          .multilineTextAlignment(.center)

        HStack(spacing: 8) {
          ForEach(["是", "否"], id: \.self) { option in
            Button {
              onContinue(option == "是")
            } label: {
              Text(option)
                .font(.custom("Figtree", size: 16))
                .foregroundColor(DayflowOnboardingToken.title)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .dayflowOnboardingOptionCard(isSelected: false, cornerRadius: 18)
            }
            .buttonStyle(.plain)
            .pointingHandCursor()
          }
        }
      }
      .padding(.horizontal, 28)
      .padding(.vertical, 28)
      .dayflowOnboardingPanel()

      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
