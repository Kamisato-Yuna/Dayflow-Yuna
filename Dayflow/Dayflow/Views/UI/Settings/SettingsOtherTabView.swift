import SwiftUI

struct SettingsOtherTabView: View {
  @ObservedObject var viewModel: OtherSettingsViewModel
  @ObservedObject var launchAtLoginManager: LaunchAtLoginManager
  @FocusState private var isOutputLanguageFocused: Bool

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
      subtitle: "通用开关和遥测设置。"
    ) {
      VStack(alignment: .leading, spacing: 0) {
        SettingsRow(
          label: "登录时启动 Dayflow",
          subtitle:
            "你登录系统后立即运行菜单栏控制器，方便录制马上恢复。"
        ) {
          SettingsToggle(
            isOn: Binding(
              get: { launchAtLoginManager.isEnabled },
              set: { launchAtLoginManager.setEnabled($0) }
            )
          )
        }

        SettingsRow(label: "共享崩溃报告和匿名使用数据") {
          SettingsToggle(isOn: $viewModel.analyticsEnabled)
        }

        SettingsRow(
          label: "显示 Dock 图标",
          subtitle: "关闭后，Dayflow 仅作为菜单栏应用运行。"
        ) {
          SettingsToggle(isOn: $viewModel.showDockIcon)
        }

        SettingsRow(
          label: "在时间线中显示应用/网站图标",
          subtitle: "关闭后，时间线卡片不会显示应用或网站图标。"
        ) {
          SettingsToggle(isOn: $viewModel.showTimelineAppIcons)
        }

        SettingsRow(
          label: "显示每日目标弹窗",
          subtitle:
            "关闭后，Dayflow 不会在凌晨 4 点后自动打开目标设置或昨日回顾。"
        ) {
          SettingsToggle(isOn: $viewModel.showDailyGoalPopups)
        }

        SettingsRow(
          label: "将所有延时视频保存到磁盘",
          subtitle:
            "新的和重新处理的时间线卡片会预先生成延时视频并保存到磁盘，而不是按需生成。这会占用更多存储并增加后台处理。",
          showsDivider: false
        ) {
          SettingsToggle(isOn: $viewModel.saveAllTimelapsesToDisk)
        }
      }
    }
  }

  // MARK: - Output language override

  private var outputLanguageSection: some View {
    SettingsSection(
      title: "AI 输出语言",
      subtitle:
        "这里控制 AI 生成的复盘、摘要和对话语言，不影响应用界面语言。留空则使用默认输出语言；也可以输入 English、简体中文、Español、日本語、한국어、Français。"
    ) {
      HStack(spacing: 10) {
        TextField("例如：简体中文", text: $viewModel.outputLanguageOverride)
          .textFieldStyle(.roundedBorder)
          .disableAutocorrection(true)
          .frame(maxWidth: 220)
          .focused($isOutputLanguageFocused)
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
            isOutputLanguageFocused = false
          }
        )

        SettingsSecondaryButton(
          title: "重置",
          action: {
            viewModel.resetOutputLanguageOverride()
            isOutputLanguageFocused = false
          }
        )

        Spacer()
      }
    }
  }
}
