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
      title: "App preferences",
      subtitle: "General toggles and telemetry settings."
    ) {
      VStack(alignment: .leading, spacing: 0) {
        SettingsRow(
          label: "Launch Dayflow at login",
          subtitle:
            "Keeps the menu bar controller running right after you sign in so capture can resume instantly."
        ) {
          SettingsToggle(
            is开启: Binding(
              get: { launchAtLoginManager.isEnabled },
              set: { launchAtLoginManager.setEnabled($0) }
            )
          )
        }

        SettingsRow(label: "Share crash reports and anonymous usage data") {
          SettingsToggle(is开启: $viewModel.analyticsEnabled)
        }

        SettingsRow(
          label: "Show Dock icon",
          subtitle: "When off, Dayflow runs as a menu bar-only app."
        ) {
          SettingsToggle(is开启: $viewModel.showDockIcon)
        }

        SettingsRow(
          label: "Show app/website icons in timeline",
          subtitle: "When off, timeline cards won't show app or website icons."
        ) {
          SettingsToggle(is开启: $viewModel.showTimelineAppIcons)
        }

        SettingsRow(
          label: "Show daily goal popups",
          subtitle:
            "When off, Dayflow won't automatically open goal setup or yesterday's review after 4am."
        ) {
          SettingsToggle(is开启: $viewModel.showDailyGoalPopups)
        }

        SettingsRow(
          label: "Save all timelapses to disk",
          subtitle:
            "New and reprocessed timeline cards will pre-generate timelapse videos and store them on disk instead of building them on demand. Uses more storage and background processing.",
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
      title: "Output language override",
      subtitle:
        "The default language is English. You can specify any language 这里 (examples: English, 简体中文, Español, 日本語, 한국어, Français)."
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
          title: viewModel.isOutputLanguageOverrideSaved ? "Saved" : "保存",
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
