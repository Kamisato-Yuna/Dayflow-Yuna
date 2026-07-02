import AppKit
import SwiftUI

struct SettingsAccountSection: View {
  @ObservedObject private var authManager = DayflowAuthManager.shared
  @State private var isAuthSheetPresented = false
  @State private var selectedBillingInterval: DayflowBillingInterval = .yearly
  @State private var inviteEmail = ""
  @State private var applyReferralCode = ""
  @State private var copiedReferralLink = false

  var body: some View {
    VStack(alignment: .leading, spacing: SettingsStyle.sectionSpacing) {
      if authManager.entitlements.status == "active" {
        currentPlanSection
      } else {
        accountSection
        upgradeSection
      }

      referralSection

      if let errorText = authManager.errorText {
        Text(errorText)
          .font(.custom("Figtree", size: 11))
          .foregroundColor(SettingsStyle.destructive)
          .textSelection(.enabled)
      }
    }
    .sheet(isPresented: $isAuthSheetPresented) {
      DayflowSignInSheet {
        isAuthSheetPresented = false
      }
      .frame(width: 430)
    }
    .task {
      authManager.loadStoredSessionIfNeeded()
    }
    .onChange(of: authManager.pendingReferralCode) { _, pendingCode in
      guard let pendingCode, applyReferralCode.isEmpty else { return }
      applyReferralCode = pendingCode
    }
  }

  private var accountSection: some View {
    SettingsSection(
      title: "账号",
      subtitle: "登录后，Dayflow Pro 和云端功能会绑定到这台 Mac。"
    ) {
      VStack(alignment: .leading, spacing: 0) {
        SettingsRow(
          label: "Dayflow 账号",
          subtitle: authManager.isSignedIn
            ? authManager.displayIdentity
            : nil,
          showsDivider: authManager.isSignedIn
        ) {
          HStack(spacing: 8) {
            SettingsStatusDot(
              state: authManager.isSignedIn ? .good : .warn,
              label: authManager.isSignedIn ? "已登录" : "未登录"
            )

            if authManager.isSignedIn {
              SettingsSecondaryButton(
                title: "退出登录",
                systemImage: "rectangle.portrait.and.arrow.right",
                isDisabled: authManager.isBusy,
                action: { Task { await authManager.signOut() } }
              )
            } else {
              SettingsPrimaryButton(
                title: "登录",
                systemImage: "person.crop.circle",
                isLoading: authManager.isBusy && authManager.hasLoadedStoredSession == false,
                action: { isAuthSheetPresented = true }
              )
            }
          }
        }
      }
    }
  }

  private var currentPlanSection: some View {
    SettingsSection(
      title: "账号",
      subtitle: "管理你的 Dayflow 账号和订阅。"
    ) {
      ActiveProCard(
        entitlement: authManager.entitlements,
        email: authManager.displayIdentity,
        isBusy: authManager.isBusy,
        signOutAction: { Task { await authManager.signOut() } },
        manageBillingAction: { Task { await authManager.openBillingPortal() } }
      )
    }
  }

  private var upgradeSection: some View {
    SettingsSection(
      title: "升级到 Dayflow Pro",
      subtitle: "选择套餐后，通过 Stripe Checkout 安全完成付款。"
    ) {
      VStack(alignment: .leading, spacing: 16) {
        HStack(alignment: .top, spacing: 12) {
          BillingPlanCard(
            title: "月付",
            price: "$20",
            cadence: "/月",
            note: "灵活按月计费。",
            badge: nil,
            isSelected: selectedBillingInterval == .monthly
          ) {
            withAnimation(.easeOut(duration: 0.16)) {
              selectedBillingInterval = .monthly
            }
          }

          BillingPlanCard(
            title: "年付",
            price: "$15",
            cadence: "/月",
            note: "按年计费。",
            badge: "赠送 2 个月",
            isSelected: selectedBillingInterval == .yearly
          ) {
            withAnimation(.easeOut(duration: 0.16)) {
              selectedBillingInterval = .yearly
            }
          }
        }
        .padding(.leading, 2)

        ProFeatureList()

        HStack(alignment: .center, spacing: 12) {
          SettingsPrimaryButton(
            title: authManager.isSignedIn ? "开始 14 天试用" : "登录后升级",
            systemImage: authManager.isSignedIn ? "creditcard" : "person.crop.circle",
            isLoading: authManager.isBusy,
            action: upgradeAction
          )

          VStack(alignment: .leading, spacing: 4) {
            Text("可随时取消，退款无障碍。")
              .font(.custom("Figtree", size: 12))
              .foregroundColor(SettingsStyle.secondary)
              .fixedSize(horizontal: false, vertical: true)

            SettingsLinkButton(title: "隐私政策", systemImage: "lock") {
              openPrivacyPolicy()
            }
          }
        }
      }
    }
  }

  private var referralSection: some View {
    ReferralProgramCard(
      summary: authManager.referralSummary,
      inviteEmail: $inviteEmail,
      applyReferralCode: $applyReferralCode,
      copiedReferralLink: copiedReferralLink,
      isSignedIn: authManager.isSignedIn,
      isBusy: authManager.isBusy,
      copyAction: copyReferralLink,
      sendInviteAction: sendInvite,
      applyCodeAction: applyReferralCodeAction,
      signInAction: { isAuthSheetPresented = true },
      refreshAction: { Task { await authManager.refreshReferrals() } }
    )
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func upgradeAction() {
    guard authManager.isSignedIn else {
      isAuthSheetPresented = true
      return
    }

    Task {
      await authManager.openBillingCheckout(interval: selectedBillingInterval)
    }
  }

  private func openPrivacyPolicy() {
    guard let url = URL(string: "https://dayflow.so/privacy") else { return }
    NSWorkspace.shared.open(url)
  }

  private func copyReferralLink() {
    guard let inviteURL = authManager.referralSummary?.inviteURL else { return }
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(inviteURL, forType: .string)
    copiedReferralLink = true
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
      copiedReferralLink = false
    }
  }

  private func sendInvite() {
    Task {
      await authManager.sendReferralInvite(to: inviteEmail)
      if authManager.errorText == nil {
        inviteEmail = ""
      }
    }
  }

  private func applyReferralCodeAction() {
    let code = applyReferralCode.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !code.isEmpty else { return }
    Task {
      await authManager.claimReferralCode(code)
      if authManager.errorText == nil {
        applyReferralCode = ""
      }
    }
  }
}

private func formattedEntitlementDate(_ value: String?) -> String? {
  guard let value, !value.isEmpty else { return nil }

  if value.count >= 10 {
    let datePrefix = String(value.prefix(10))
    let dateOnlyFormatter = DateFormatter()
    dateOnlyFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateOnlyFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    dateOnlyFormatter.dateFormat = "yyyy-MM-dd"

    if let date = dateOnlyFormatter.date(from: datePrefix) {
      let displayFormatter = DateFormatter()
      displayFormatter.locale = Locale.current
      displayFormatter.timeZone = TimeZone(secondsFromGMT: 0)
      displayFormatter.dateStyle = .medium
      displayFormatter.timeStyle = .none
      return displayFormatter.string(from: date)
    }
  }

  let formatters: [ISO8601DateFormatter] = [
    {
      let formatter = ISO8601DateFormatter()
      formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
      return formatter
    }(),
    {
      let formatter = ISO8601DateFormatter()
      formatter.formatOptions = [.withInternetDateTime]
      return formatter
    }(),
  ]

  let date = formatters.compactMap { $0.date(from: value) }.first
  guard let date else { return nil }

  let displayFormatter = DateFormatter()
  displayFormatter.locale = Locale.current
  displayFormatter.dateStyle = .medium
  displayFormatter.timeStyle = .none
  return displayFormatter.string(from: date)
}

private struct ActiveProCard: View {
  let entitlement: DayflowEntitlement
  let email: String
  let isBusy: Bool
  let signOutAction: () -> Void
  let manageBillingAction: () -> Void

  private var isGifted: Bool {
    entitlement.source == "manual"
  }

  private var title: String {
    isGifted ? "赠送的 Pro" : "Dayflow Pro"
  }

  private var badge: String {
    isGifted ? "赠送" : "已启用"
  }

  private var description: String {
    if isGifted {
      return
        "你拥有赠送的 Dayflow Pro 权限，此账号无需管理账单。"
    }

    return "这台 Mac 已启用 Pro 权限，并绑定到你的 Dayflow 账号。"
  }

  private var dateLabel: String {
    if formattedEntitlementDate(entitlement.currentPeriodEnd) == nil {
      return "状态"
    }

    return isGifted ? "可用至" : "续订日期"
  }

  private var dateValue: String {
    formattedEntitlementDate(entitlement.currentPeriodEnd) ?? "已启用"
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      HStack(alignment: .top, spacing: 16) {
        planIcon

        VStack(alignment: .leading, spacing: 5) {
          HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(title)
              .font(.custom("Figtree", size: 22))
              .fontWeight(.bold)
              .foregroundColor(SettingsStyle.text)

            SettingsBadge(text: badge.uppercased(), isAccent: true)
          }

          Text(description)
            .font(.custom("Figtree", size: 13))
            .foregroundColor(SettingsStyle.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }

        Spacer(minLength: 16)

        SettingsStatusDot(state: .good, label: "已启用")
          .padding(.top, 4)
      }

      HStack(alignment: .top, spacing: 12) {
        ActiveProInfoTile(label: "登录账号", value: email)
        ActiveProInfoTile(label: dateLabel, value: dateValue)
      }

      Rectangle()
        .fill(SettingsStyle.divider)
        .frame(height: 1)

      HStack(alignment: .center, spacing: 16) {
        ProFeatureList()

        Spacer(minLength: 16)

        HStack(spacing: 8) {
          SettingsSecondaryButton(
            title: "退出登录",
            systemImage: "rectangle.portrait.and.arrow.right",
            isDisabled: isBusy,
            action: signOutAction
          )

          if !isGifted {
            SettingsPrimaryButton(
              title: "管理账单",
              systemImage: "creditcard",
              isLoading: isBusy,
              action: manageBillingAction
            )
          }
        }
      }
    }
    .padding(18)
    .background(
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .fill(Color.white)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .stroke(SettingsStyle.divider, lineWidth: 1)
    )
  }

  @ViewBuilder
  private var planIcon: some View {
    if isGifted {
      ZStack {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
          .fill(SettingsStyle.ink.opacity(0.1))
        Image(systemName: "gift.fill")
          .font(.system(size: 15, weight: .semibold))
          .foregroundColor(SettingsStyle.ink)
      }
      .frame(width: 34, height: 34)
    } else {
      Image("DayflowLogo")
        .resizable()
        .scaledToFit()
        .frame(width: 34, height: 34)
    }
  }
}

private struct ActiveProInfoTile: View {
  let label: String
  let value: String

  var body: some View {
    VStack(alignment: .leading, spacing: 5) {
      Text(label.uppercased())
        .font(.custom("Figtree", size: 10))
        .fontWeight(.bold)
        .kerning(0.5)
        .foregroundColor(SettingsStyle.meta)

      Text(value)
        .font(.custom("Figtree", size: 14))
        .fontWeight(.semibold)
        .foregroundColor(SettingsStyle.text)
        .lineLimit(1)
        .truncationMode(.middle)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(12)
    .background(
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .fill(Color.white.opacity(0.45))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .stroke(SettingsStyle.divider, lineWidth: 1)
    )
  }
}

private struct ReferralProgramCard: View {
  let summary: DayflowReferralSummary?
  @Binding var inviteEmail: String
  @Binding var applyReferralCode: String
  let copiedReferralLink: Bool
  let isSignedIn: Bool
  let isBusy: Bool
  let copyAction: () -> Void
  let sendInviteAction: () -> Void
  let applyCodeAction: () -> Void
  let signInAction: () -> Void
  let refreshAction: () -> Void

  @State private var selectedTab: ReferralTab = .refer

  private enum ReferralTab: CaseIterable, Hashable {
    case refer
    case past
    case apply
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 23) {
      header

      VStack(alignment: .leading, spacing: 16) {
        tabBar
        contentPanel
      }
    }
    .padding(20)
    .background(
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .fill(Color.white)
    )
    .task {
      if isSignedIn && summary == nil {
        refreshAction()
      }
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("邀请好友，获得奖励")
        .font(.custom("Figtree", size: 16))
        .fontWeight(.bold)
        .foregroundColor(Color(hex: "333333"))

      Text("送出 1 个月 Dayflow Pro；每成功邀请 1 人，你可获得 $20 抵扣金。")
        .font(.custom("Figtree", size: 12))
        .foregroundColor(Color(hex: "333333"))
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var tabBar: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(spacing: 24) {
        ForEach(ReferralTab.allCases, id: \.self) { tab in
          Button {
            withAnimation(.easeOut(duration: 0.16)) {
              selectedTab = tab
            }
          } label: {
            Text(tabTitle(for: tab))
              .font(.custom("Figtree", size: 12))
              .fontWeight(selectedTab == tab ? .bold : .regular)
              .foregroundColor(Color(hex: "333333"))
              .padding(.bottom, 8)
              .overlay(alignment: .bottom) {
                if selectedTab == tab {
                  Rectangle()
                    .fill(Color(hex: "333333"))
                    .frame(height: 2)
                }
              }
          }
          .buttonStyle(.plain)
          .pointingHandCursor()
        }

        Spacer()
      }
      .padding(.leading, 8)

      Rectangle()
        .fill(Color(hex: "DFDDDB"))
        .frame(height: 1)
    }
  }

  private var contentPanel: some View {
    VStack(alignment: .center, spacing: 28) {
      switch selectedTab {
      case .refer:
        referPanel
      case .past:
        pastInvitesPanel
      case .apply:
        applyCodePanel
      }
    }
    .padding(20)
    .frame(maxWidth: .infinity)
    .background(
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .fill(Color(hex: "F5F4F1"))
    )
  }

  private var referPanel: some View {
    VStack(alignment: .center, spacing: 28) {
      ReferralPassCard()

      VStack(alignment: .leading, spacing: 22) {
        howItWorks
        if isSignedIn {
          inviteLinkControl
        } else {
          signInReferralPrompt
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  private var signInReferralPrompt: some View {
    HStack(alignment: .center, spacing: 12) {
      VStack(alignment: .leading, spacing: 4) {
        Text("登录后获取你的邀请链接")
          .font(.custom("Figtree", size: 12))
          .fontWeight(.bold)
          .foregroundColor(Color(hex: "333333"))

        Text(
          "推荐奖励会绑定到你的 Dayflow 账号，好友加入后我们才能为你发放奖励。"
        )
        .font(.custom("Figtree", size: 11))
        .foregroundColor(Color(hex: "72706D"))
        .fixedSize(horizontal: false, vertical: true)
      }

      Spacer(minLength: 12)

      ReferralMiniButton(
        title: "登录",
        style: .send,
        isDisabled: isBusy,
        action: signInAction
      )
    }
  }

  private var inviteLinkControl: some View {
    VStack(alignment: .leading, spacing: 5) {
      Text("你的邀请链接")
        .font(.custom("Figtree", size: 12))
        .foregroundColor(Color(hex: "333333"))

      HStack(spacing: 8) {
        ReferralFieldText(
          icon: "link",
          text: summary?.inviteURL ?? "正在加载邀请链接...",
          color: Color(hex: "333333")
        )

        ReferralMiniButton(
          title: copiedReferralLink ? "已复制" : "复制",
          style: .copy,
          isDisabled: summary == nil,
          action: copyAction
        )
      }
    }
  }

  private var sendInviteControl: some View {
    VStack(alignment: .leading, spacing: 5) {
      Text("发送邀请")
        .font(.custom("Figtree", size: 12))
        .foregroundColor(Color(hex: "333333"))

      HStack(spacing: 8) {
        ReferralEmailField(email: $inviteEmail, isDisabled: isBusy)

        ReferralMiniButton(
          title: "发送",
          style: .send,
          isDisabled: isBusy || inviteEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
          action: sendInviteAction
        )
      }
    }
  }

  private var howItWorks: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("奖励规则")
        .font(.custom("Figtree", size: 12))
        .fontWeight(.bold)
        .foregroundColor(Color(hex: "333333"))

      VStack(alignment: .leading, spacing: 4) {
        ReferralStepRow(
          icon: .system("point.3.connected.trianglepath.dotted"),
          content: Text("分享你的邀请链接")
        )
        ReferralStepRow(
          icon: .menuBarMark,
          content: Text("对方注册后可获得 ") + Text("1 个月免费 Dayflow Pro！").bold()
        )
        ReferralStepRow(
          icon: .system("sparkles"),
          content: Text("当对方连续使用 Dayflow 一周后，你将获得 ")
            + Text("1 个月 Dayflow Pro（可叠加）").bold()
            + Text("。")
        )
      }
    }
    .frame(width: 332, alignment: .leading)
  }

  private var pastInvitesPanel: some View {
    VStack(alignment: .leading, spacing: 18) {
      if let invites = summary?.invites, !invites.isEmpty {
        VStack(alignment: .leading, spacing: 0) {
          ForEach(invites.prefix(8)) { invite in
            HStack(spacing: 12) {
              VStack(alignment: .leading, spacing: 3) {
                Text(invite.email)
                  .font(.custom("Figtree", size: 12))
                  .fontWeight(.semibold)
                  .foregroundColor(Color(hex: "333333"))
                  .lineLimit(1)
                  .truncationMode(.middle)

                Text(inviteStatusText(invite))
                  .font(.custom("Figtree", size: 11))
                  .foregroundColor(Color(hex: "72706D"))
              }

              Spacer()

              SettingsBadge(
                text: inviteStatusBadgeText(invite),
                isAccent: invite.unlockedAt != nil
              )
            }
            .padding(.vertical, 8)

            if invite.id != invites.prefix(8).last?.id {
              Rectangle()
                .fill(Color(hex: "DFDDDB"))
                .frame(height: 1)
            }
          }
        }
      } else {
        EmptyReferralState(text: "还没有邀请记录。")
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var applyCodePanel: some View {
    VStack(alignment: .leading, spacing: 18) {
      Text("兑换推荐码")
        .font(.custom("Figtree", size: 12))
        .fontWeight(.bold)
        .foregroundColor(Color(hex: "333333"))

      HStack(spacing: 8) {
        ReferralCodeField(code: $applyReferralCode, isDisabled: isBusy)

        ReferralMiniButton(
          title: "兑换",
          style: .send,
          isDisabled: isBusy || applyReferralCode.count != 6,
          action: applyCodeAction
        )
      }
    }
    .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
  }

  private func tabTitle(for tab: ReferralTab) -> String {
    switch tab {
    case .refer:
      return "邀请"
    case .past:
      return "历史邀请（\(summary?.invites.count ?? 0)）"
    case .apply:
      return "兑换推荐码"
    }
  }

  private func inviteStatusText(_ invite: DayflowReferralInvite) -> String {
    if invite.unlockedAt != nil {
      return "奖励已获得"
    }
    if invite.claimedAt != nil {
      return "已记录 \(String(format: "%.1f", invite.usageHours)) / 40 小时"
    }
    return "邀请已发送"
  }

  private func inviteStatusBadgeText(_ invite: DayflowReferralInvite) -> String {
    if invite.unlockedAt != nil {
      return "已奖励"
    }
    if invite.claimedAt != nil {
      return "进行中"
    }
    return "已发送"
  }
}

private struct BillingPlanCard: View {
  let title: String
  let price: String
  let cadence: String
  let note: String
  let badge: String?
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(alignment: .leading, spacing: 12) {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
          Text(title)
            .font(.custom("Figtree", size: 13))
            .fontWeight(.bold)
            .foregroundColor(SettingsStyle.text)

          Spacer(minLength: 8)

          if let badge {
            SettingsBadge(text: badge.uppercased(), isAccent: true)
          }
        }

        HStack(alignment: .firstTextBaseline, spacing: 4) {
          Text(price)
            .font(.custom("InstrumentSerif-Regular", size: 38))
            .foregroundColor(SettingsStyle.text)
          Text(cadence)
            .font(.custom("Figtree", size: 13))
            .fontWeight(.semibold)
            .foregroundColor(SettingsStyle.secondary)
        }

        Text(note)
          .font(.custom("Figtree", size: 12))
          .foregroundColor(SettingsStyle.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
      .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
      .padding(14)
      .background(
        RoundedRectangle(cornerRadius: 8, style: .continuous)
          .fill(isSelected ? SettingsStyle.ink.opacity(0.06) : Color.white.opacity(0.55))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 8, style: .continuous)
          .stroke(isSelected ? SettingsStyle.ink.opacity(0.8) : SettingsStyle.divider, lineWidth: 1)
      )
    }
    .buttonStyle(.plain)
    .pointingHandCursor()
  }
}

private struct ProFeatureList: View {
  private let features = [
    "免配置云端 AI 生成时间线",
    "无需配置提供商即可生成每日复盘和周报",
    "优先支持",
    "安全处理，绝不会用于训练 AI 模型",
  ]

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      ForEach(features, id: \.self) { feature in
        HStack(alignment: .top, spacing: 8) {
          Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(SettingsStyle.statusGood)
            .padding(.top, 1)

          Text(feature)
            .font(.custom("Figtree", size: 12))
            .foregroundColor(SettingsStyle.text)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
    }
    .padding(.top, 2)
  }
}

private struct DayflowSignInSheet: View {
  private enum Step {
    case email
    case code
  }

  private enum Field {
    case email
    case code
  }

  @ObservedObject private var authManager = DayflowAuthManager.shared
  @FocusState private var focusedField: Field?

  let onDismiss: () -> Void

  @State private var step: Step = .email
  @State private var emailAddress = ""
  @State private var verificationEmail: String?
  @State private var verificationCode = ""
  @State private var didAutoSubmitCode = false

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      header

      switch step {
      case .email:
        emailForm
      case .code:
        codeForm
      }

      if let errorText = authManager.errorText {
        Text(errorText)
          .font(.custom("Figtree", size: 12))
          .foregroundColor(SettingsStyle.destructive)
          .textSelection(.enabled)
      }
    }
    .padding(26)
    .background(Color.white)
    .onAppear {
      emailAddress = authManager.signedInEmail ?? emailAddress
      focusedField = step == .email ? .email : .code
    }
    .onChange(of: authManager.isSignedIn) { _, isSignedIn in
      guard isSignedIn else { return }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
        onDismiss()
      }
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 5) {
      Text(step == .email ? "登录 Dayflow" : "检查你的邮箱")
        .font(.custom("InstrumentSerif-Regular", size: 30))
        .foregroundColor(SettingsStyle.text)

      Text(
        step == .email
          ? "输入邮箱，Dayflow 会发送 6 位验证码。"
          : "输入发送到 \(verificationEmail ?? authManager.pendingEmail ?? emailAddressTrimmed) 的验证码。"
      )
      .font(.custom("Figtree", size: 13))
      .foregroundColor(SettingsStyle.secondary)
      .fixedSize(horizontal: false, vertical: true)
    }
  }

  private var emailForm: some View {
    VStack(alignment: .leading, spacing: 14) {
      TextField("you@example.com", text: $emailAddress)
        .textFieldStyle(.roundedBorder)
        .font(.custom("Figtree", size: 14))
        .focused($focusedField, equals: .email)
        .disabled(authManager.isBusy)
        .onSubmit { sendCode() }

      HStack(spacing: 10) {
        SettingsPrimaryButton(
          title: "继续",
          systemImage: "arrow.right",
          isLoading: authManager.isBusy,
          isDisabled: emailAddressTrimmed.isEmpty,
          action: sendCode
        )

        SettingsSecondaryButton(
          title: "取消",
          isDisabled: authManager.isBusy,
          action: onDismiss
        )
      }
    }
  }

  private var codeForm: some View {
    VStack(alignment: .leading, spacing: 14) {
      TextField("000000", text: $verificationCode)
        .textFieldStyle(.plain)
        .font(.system(size: 30, weight: .semibold, design: .monospaced))
        .multilineTextAlignment(.center)
        .tracking(8)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
          RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color.black.opacity(0.04))
        )
        .overlay(
          RoundedRectangle(cornerRadius: 8, style: .continuous)
            .stroke(SettingsStyle.divider, lineWidth: 1)
        )
        .focused($focusedField, equals: .code)
        .disabled(authManager.isBusy)
        .onChange(of: verificationCode) { _, newValue in
          let digits = String(newValue.filter(\.isNumber).prefix(6))
          if digits != newValue {
            verificationCode = digits
          }
          guard digits.count == 6, !didAutoSubmitCode, !authManager.isBusy else { return }
          didAutoSubmitCode = true
          verifyCode()
        }
        .onSubmit { verifyCode() }

      HStack(spacing: 10) {
        SettingsPrimaryButton(
          title: "验证",
          systemImage: "checkmark",
          isLoading: authManager.isBusy,
          isDisabled: verificationCodeTrimmed.count != 6,
          action: verifyCode
        )

        SettingsSecondaryButton(
          title: "重新发送",
          isDisabled: authManager.isBusy,
          action: {
            Task {
              didAutoSubmitCode = false
              verificationCode = ""
              await authManager.sendCode(to: verificationEmail ?? emailAddressTrimmed)
              verificationEmail = authManager.pendingEmail ?? verificationEmail
              focusedField = .code
            }
          }
        )

        SettingsSecondaryButton(
          title: "更换邮箱",
          isDisabled: authManager.isBusy,
          action: {
            authManager.useDifferentEmail()
            verificationEmail = nil
            verificationCode = ""
            didAutoSubmitCode = false
            step = .email
            focusedField = .email
          }
        )
      }
    }
  }

  private func sendCode() {
    guard !emailAddressTrimmed.isEmpty else { return }
    Task {
      await authManager.sendCode(to: emailAddressTrimmed)
      if authManager.canVerifyCode, authManager.errorText == nil {
        verificationEmail = authManager.pendingEmail ?? emailAddressTrimmed
        verificationCode = ""
        didAutoSubmitCode = false
        step = .code
        focusedField = .code
      }
    }
  }

  private func verifyCode() {
    guard verificationCodeTrimmed.count == 6 else { return }
    guard let email = verificationEmail ?? authManager.pendingEmail else {
      step = .email
      focusedField = .email
      return
    }
    Task {
      await authManager.verifyCode(verificationCodeTrimmed, for: email)
      if authManager.errorText != nil {
        didAutoSubmitCode = false
      }
    }
  }

  private var emailAddressTrimmed: String {
    emailAddress.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private var verificationCodeTrimmed: String {
    String(verificationCode.filter(\.isNumber).prefix(6))
  }
}
