import SwiftUI

struct SettingsOtherTabView: View {
  @ObservedObject var viewModel: OtherSettingsViewModel
  @ObservedObject var launchAtLoginManager: LaunchAtLoginManager
  @专注State private var isOutputLanguage专注ed: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: SettingsStyle.sectionSpacing) {
      appPreferencesSection
      outputLanguageSection
    }
  }

  // MARK: - App preferences

  private var appPreferencesSection: some View {
    SettingsSection(
      title: "应用偏好",
      subtitle: "常用开关与数据上报设置。"
    ) {
      VStack(alignment: .leading, spacing: 0) {
        SettingsRow(
          label: "登录后自动启动 Dayflow",
          subtitle:
            "登录后自动启动菜单栏服务，录制可在你开机后立即恢复。"
        ) {
          SettingsToggle(
            is开启: Binding(
              get: { launchAtLoginManager.isEnabled },
              set: { launchAtLoginManager.setEnabled($0) }
            )
          )
        }

        SettingsRow(label: "分享崩溃报告与匿名使用数据") {
          SettingsToggle(is开启: $viewModel.analyticsEnabled)
        }

        SettingsRow(
          label: "显示 Dock 图标",
          subtitle: "关闭后，Dayflow 将仅在菜单栏运行。"
        ) {
          SettingsToggle(is开启: $viewModel.showDockIcon)
        }

        SettingsRow(
          label: "显示应用和网站图标",
          subtitle: "关闭后，时间线卡片不再显示应用或网站图标。"
        ) {
          SettingsToggle(is开启: $viewModel.showTimelineAppIcons)
        }

        SettingsRow(
          label: "显示每日目标弹窗",
          subtitle:
            "关闭后，Dayflow 不再在凌晨 4 点后自动打开目标设置或昨日复盘。"
        ) {
          SettingsToggle(is开启: $viewModel.showDailyGoalPopups)
        }

        SettingsRow(
          label: "将所有延时摄影保存到磁盘",
          subtitle:
            "新建与重处理时间线卡片会提前生成延时摄影并保存在磁盘中，不再按需生成。此功能会增加磁盘占用和后台处理。",
          showsDivider: false
        ) {
          SettingsToggle(is开启: $viewModel.save全部TimelapsesToDisk)
        }
      }
    }
  }

  // MARK: - Output language override

  private var outputLanguageSection: some View {
    SettingsSection(
      title: "AI 输出语言",
      subtitle:
        "该设置控制 AI 回复使用的语言，不影响界面语言（默认显示中文）。你可以填写任意语言，例如：English、简体中文、Español、日本語、한국어、Français。"
    ) {
      HStack(spacing: 10) {
        TextField("English", text: $viewModel.outputLanguageOverride)
          .textFieldStyle(.roundedBorder)
          .disableAutocorrection(true)
          .frame(maxWidth: 220)
          .focused($isOutputLanguage专注ed)
          .onChange(of: viewModel.outputLanguageOverride) {
            viewModel.markOutputLanguageOverrideEdited()
          }

        SettingsSecondaryButton(
          title: viewModel.isOutputLanguageOverrideSaved ? "已保存" : "保存",
          systemImage: viewModel.isOutputLanguageOverrideSaved
            ? "checkmark" : nil,
          isDisabled: viewModel.isOutputLanguageOverrideSaved,
          action: {
            viewModel.saveOutputLanguageOverride()
            isOutputLanguage专注ed = false
          }
        )

        SettingsSecondaryButton(
          title: "重置",
          action: {
            viewModel.resetOutputLanguageOverride()
            isOutputLanguage专注ed = false
          }
        )

        Spacer()
      }
    }
  }
}
