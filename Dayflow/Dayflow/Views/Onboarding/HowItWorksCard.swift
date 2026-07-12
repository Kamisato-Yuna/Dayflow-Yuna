//
//  HowItWorksCard.swift
//  Dayflow
//
//  Card component for How It Works section
//

import SwiftUI

struct HowItWorksCard: View {
  let systemIcon: String
  let title: String
  let description: String

  var body: some View {
    HStack(alignment: .top, spacing: 16) {
      Image(systemName: systemIcon)
        .font(.system(size: 22, weight: .semibold))
        .symbolRenderingMode(.hierarchical)
        .foregroundStyle(DayflowOnboardingToken.primaryButtonFill)
        .frame(width: 40, height: 40)

      // Text content
      VStack(alignment: .leading, spacing: 4) {
        // Heading
        Text(title)
          .font(.custom("Figtree", size: 16))
          .fontWeight(.semibold)
          .foregroundColor(DayflowOnboardingToken.title)
          .multilineTextAlignment(.leading)
          .fixedSize(horizontal: false, vertical: true)

        // Body
        Text(description)
          .font(.custom("Figtree", size: 14))
          .fontWeight(.regular)
          .foregroundColor(DayflowOnboardingToken.secondaryText)
          .multilineTextAlignment(.leading)
          .fixedSize(horizontal: false, vertical: true)
          .lineLimit(nil)
      }
      Spacer(minLength: 0)
    }
    .padding(16)
    .frame(width: 580, alignment: .topLeading)
    .dayflowCard(cornerRadius: 5)
  }
}

struct HowItWorksCard_Previews: PreviewProvider {
  static var previews: some View {
    VStack(spacing: 20) {
      HowItWorksCard(
        systemIcon: "bolt.fill",
        title: "安装后即可使用",
        description:
          "Dayflow 会定期截图以理解你正在进行的工作，所有内容均私有保存于你的设备。"
      )

      HowItWorksCard(
        systemIcon: "lock.shield.fill",
        title: "洞察你的工作",
        description:
          "Dayflow 结合本地 AI 分析你的活动并生成当日时间线，全程不上传到云端。"
      )

      HowItWorksCard(
        systemIcon: "sparkles",
        title: "回看今日",
        description:
          "用清晰可视化和可执行的洞察，快速查看你的时间去向与效率表现。"
      )
    }
    .padding(40)
    .background(Color.gray.opacity(0.1))
  }
}
