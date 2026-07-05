//
//  SettingsView.swift
//  Dayflow
//
//  Settings screen with compact material styling and split layout
//

import Foundation
import SwiftUI

struct SettingsView: View {
  private enum SettingsTab: String, CaseIterable, Identifiable {
    case storage
    case privacy
    case providers
    case data
    case other

    var id: String { rawValue }

    var title: String {
      switch self {
      case .storage: return "存储"
      case .privacy: return "隐私"
      case .providers: return "AI 提供商"
      case .data: return "数据"
      case .other: return "其他"
      }
    }
  }

  @State private var selectedTab: SettingsTab = .providers

  @Namespace private var sidebarSelectionNamespace

  @ObservedObject private var launchAtLoginManager = LaunchAtLoginManager.shared

  @StateObject private var storageViewModel = StorageSettingsViewModel()
  @StateObject private var privacyViewModel = RecordingPrivacySettingsViewModel()
  @StateObject private var providersViewModel = ProvidersSettingsViewModel()
  @StateObject private var otherViewModel = OtherSettingsViewModel()

  var body: some View {
    contentWithSheets
  }

  private var contentWithSheets: some View {
    contentWithLifecycle
      .sheet(
        item: Binding(
          get: { providersViewModel.setupModalProvider.map { ProviderSetupWrapper(id: $0) } },
          set: { providersViewModel.setupModalProvider = $0?.id }
        )
      ) { wrapper in
        LLMProviderSetupView(
          providerType: wrapper.id,
          onBack: { providersViewModel.setupModalProvider = nil },
          onComplete: {
            providersViewModel.handleProviderSetupCompletion(wrapper.id)
            providersViewModel.setupModalProvider = nil
          }
        )
        .frame(minWidth: 900, minHeight: 650)
      }
      .sheet(isPresented: $providersViewModel.isShowingLocalModelUpgradeSheet) {
        LocalModelUpgradeSheet(
          preset: .qwen3VL4B,
          initialEngine: providersViewModel.localEngine,
          initialBaseURL: providersViewModel.localBaseURL,
          initialModelId: providersViewModel.localModelId,
          initialAPIKey: providersViewModel.localAPIKey,
          onCancel: { providersViewModel.isShowingLocalModelUpgradeSheet = false },
          onUpgradeSuccess: { engine, baseURL, modelId, apiKey in
            providersViewModel.handleUpgradeSuccess(
              engine: engine, baseURL: baseURL, modelId: modelId, apiKey: apiKey)
            providersViewModel.isShowingLocalModelUpgradeSheet = false
          }
        )
        .frame(minWidth: 720, minHeight: 560)
      }
  }

  private var contentWithLifecycle: some View {
    GeometryReader { proxy in
      mainContent
        .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
    }
    .onAppear {
      providersViewModel.handleOnAppear()
      otherViewModel.refreshAnalyticsState()
      storageViewModel.refreshStorageIfNeeded(isStorageTab: selectedTab == .storage)
      AnalyticsService.shared.capture("settings_opened")
      launchAtLoginManager.refreshStatus()
    }
    .onChange(of: selectedTab) { _, newValue in
      if newValue == .storage {
        storageViewModel.refreshStorageIfNeeded(isStorageTab: true)
      } else if newValue == .privacy {
        privacyViewModel.handleOnAppear()
      }
    }
    .onReceive(NotificationCenter.default.publisher(for: .openProvidersSettings)) { _ in
      guard selectedTab != .providers else { return }
      withAnimation(.easeOut(duration: 0.18)) {
        selectedTab = .providers
      }
    }
    .onReceive(NotificationCenter.default.publisher(for: .openAccountSettings)) { _ in
      guard selectedTab != .providers else { return }
      withAnimation(.easeOut(duration: 0.18)) {
        selectedTab = .providers
      }
    }
  }

  private var mainContent: some View {
    HStack(alignment: .top, spacing: 20) {
      sidebar
        .frame(maxHeight: .infinity, alignment: .topLeading)

      settingsContent

      Spacer(minLength: 0)
    }
    .padding(20)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .dayflowWindowBackground()
  }

  @ViewBuilder
  private var settingsContent: some View {
    if selectedTab == .privacy {
      VStack(alignment: .leading, spacing: 24) {
        tabContent
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .padding(22)
      .frame(maxWidth: 780, maxHeight: .infinity, alignment: .topLeading)
      .dayflowContentPanel(cornerRadius: 14)
    } else {
      ScrollView(.vertical, showsIndicators: false) {
        VStack(alignment: .leading, spacing: 24) {
          tabContent
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .frame(maxWidth: .infinity, minHeight: 0, alignment: .topLeading)
      }
      .frame(maxWidth: 640, maxHeight: .infinity, alignment: .topLeading)
      .dayflowContentPanel(cornerRadius: 14)
    }
  }

  private var sidebar: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text("设置")
        .font(.system(size: 22, weight: .semibold, design: .rounded))
        .foregroundColor(SettingsStyle.text)
        .padding(.leading, 10)
        .padding(.bottom, 18)

      VStack(alignment: .leading, spacing: 2) {
        ForEach(SettingsTab.allCases) { tab in
          sidebarButton(for: tab)
        }
      }

      Spacer()

      sidebarFooter
        .padding(.leading, 10)
    }
    .padding(.top, 0)
    .padding(12)
    .frame(width: 172, alignment: .topLeading)
    .dayflowSidebarSurface(cornerRadius: 14)
  }

  private var sidebarFooter: some View {
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    return VStack(alignment: .leading, spacing: 8) {
      Text("Dayflow v\(version)")
        .font(.custom("Figtree", size: 11))
        .foregroundColor(SettingsStyle.meta)

      Button {
        NotificationCenter.default.post(name: .showWhatsNew, object: nil)
      } label: {
        HStack(spacing: 4) {
          Text("发布说明")
            .font(.custom("Figtree", size: 11))
            .fontWeight(.semibold)
          Image(systemName: "arrow.up.right")
            .font(.system(size: 9, weight: .semibold))
        }
        .foregroundColor(SettingsStyle.ink)
      }
      .buttonStyle(.plain)
      .pointingHandCursor()
    }
  }

  private func sidebarButton(for tab: SettingsTab) -> some View {
    Button {
      withAnimation(.easeOut(duration: 0.18)) {
        selectedTab = tab
      }
    } label: {
      Text(tab.title)
        .font(.custom("Figtree", size: 13))
        .fontWeight(.semibold)
        .foregroundColor(selectedTab == tab ? SettingsStyle.text : SettingsStyle.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background {
          if selectedTab == tab {
            RoundedRectangle(cornerRadius: 7)
              .fill(SettingsStyle.selectedFill)
              .matchedGeometryEffect(id: "sidebarSelection", in: sidebarSelectionNamespace)
          }
        }
        .overlay {
          if selectedTab == tab {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
              .stroke(SettingsStyle.ink.opacity(0.24), lineWidth: 0.8)
          }
        }
    }
    .buttonStyle(SettingsSidebarButtonStyle())
    .pointingHandCursor()
  }

  @ViewBuilder
  private var tabContent: some View {
    // Content swap is a pure fade. The sidebar pill's matchedGeometryEffect
    // carries the "where you went" signal — the content doesn't need to
    // redundantly slide horizontally, which implied a carousel that doesn't
    // actually exist (the sidebar is vertical, not left/right tabs).
    Group {
      switch selectedTab {
      case .storage:
        SettingsStorageTabView(viewModel: storageViewModel)
      case .privacy:
        SettingsRecordingPrivacyTabView(viewModel: privacyViewModel)
      case .providers:
        SettingsProvidersTabView(viewModel: providersViewModel)
      case .data:
        SettingsDataTabView(viewModel: otherViewModel)
      case .other:
        SettingsOtherTabView(viewModel: otherViewModel, launchAtLoginManager: launchAtLoginManager)
      }
    }
    .id(selectedTab)
    .transition(.opacity)
  }
}

private struct ProviderSetupWrapper: Identifiable {
  let id: String
}

struct SettingsView_Previews: PreviewProvider {
  static var previews: some View {
    SettingsView()
      .environmentObject(UpdaterManager.shared)
      .frame(width: 1400, height: 860)
  }
}

private struct SettingsSidebarButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
      .dayflowPressScale(
        configuration.isPressed,
        pressedScale: 0.98,
        animation: .spring(response: 0.25, dampingFraction: 0.7)
      )
  }
}
