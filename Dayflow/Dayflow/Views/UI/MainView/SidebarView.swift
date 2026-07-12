import SwiftUI

private enum SidebarMetrics {
  static let itemSpacing: CGFloat = 5.25
  static let scale: CGFloat = 1.1
  static let itemSize: CGFloat = 56 * scale
  static let surfaceCornerRadius: CGFloat = 22
  static let surfacePadding: CGFloat = 6
  static let selectedBackgroundSize: CGFloat = 30 * scale
  static let symbolSize: CGFloat = 15.5 * scale
  static let badgeSize: CGFloat = 8 * scale
  static let badgeOffsetX: CGFloat = 10 * scale
  static let badgeOffsetY: CGFloat = -10 * scale
  static let iconContainerSize: CGFloat = 34 * scale
  static let iconLabelSpacing: CGFloat = 3
  static let labelFontSize: CGFloat = 11 * scale
}

enum SidebarIcon: CaseIterable {
  case timeline
  case daily
  case weekly
  case chat
  case journal
  case bug
  case settings

  var systemName: String {
    switch self {
    case .timeline: return "clock.fill"
    case .daily: return "calendar"
    case .weekly: return "chart.bar.fill"
    case .chat: return "bubble.left.and.bubble.right.fill"
    case .journal: return "book.closed.fill"
    case .bug: return "exclamationmark.bubble.fill"
    case .settings: return "gearshape.fill"
    }
  }

  var displayName: String {
    switch self {
    case .timeline: return "时间线"
    case .daily: return "每日"
    case .weekly: return "周报"
    case .chat: return "对话"
    case .journal: return "日志"
    case .bug: return "反馈"
    case .settings: return "设置"
    }
  }

  var analyticsTabName: String {
    switch self {
    case .timeline: return "timeline"
    case .daily: return "daily"
    case .weekly: return "weekly"
    case .chat: return "dashboard"
    case .journal: return "journal"
    case .bug: return "bug_report"
    case .settings: return "settings"
    }
  }
}

struct SidebarView: View {
  @Binding var selectedIcon: SidebarIcon
  @ObservedObject private var badgeManager = NotificationBadgeManager.shared

  private var visibleIcons: [SidebarIcon] {
    SidebarIcon.allCases.filter { icon in
      icon != .journal
    }
  }

  var body: some View {
    DayflowGlassSurface(
      role: .sidebarSurface,
      cornerRadius: SidebarMetrics.surfaceCornerRadius,
      spacing: SidebarMetrics.itemSpacing
    ) {
      VStack(alignment: .center, spacing: SidebarMetrics.itemSpacing) {
        ForEach(visibleIcons, id: \.self) { icon in
          SidebarIconButton(
            icon: icon,
            isSelected: selectedIcon == icon,
            showBadge: shouldShowBadge(for: icon),
            action: { selectedIcon = icon }
          )
          .frame(width: SidebarMetrics.itemSize, height: SidebarMetrics.itemSize)
        }
      }
      .padding(SidebarMetrics.surfacePadding)
    }
  }

  private func shouldShowBadge(for icon: SidebarIcon) -> Bool {
    switch icon {
    case .journal:
      return badgeManager.hasPendingJournalReminder
    case .daily:
      return badgeManager.hasPendingDailyRecap
    default:
      return false
    }
  }
}

struct SidebarIconButton: View {
  let icon: SidebarIcon
  let isSelected: Bool
  var showBadge: Bool = false
  let action: () -> Void

  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

  private var selectedAccent: Color {
    DayflowSurfaceAccent.primary
  }

  private var inactiveForeground: Color {
    Color(nsColor: .secondaryLabelColor)
  }

  private var selectedForeground: Color {
    Color(nsColor: .labelColor)
  }

  private var selectedFill: Color {
    reduceTransparency
      ? Color(nsColor: .selectedControlColor).opacity(0.36)
      : selectedAccent.opacity(colorScheme == .dark ? 0.22 : 0.16)
  }

  private var selectedStroke: Color {
    selectedAccent.opacity(colorScheme == .dark ? 0.46 : 0.32)
  }

  var body: some View {
    Button(action: action) {
      VStack(spacing: SidebarMetrics.iconLabelSpacing) {
        ZStack {
          if isSelected {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
              .fill(selectedFill)
              .overlay(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                  .stroke(selectedStroke, lineWidth: 0.8)
              )
              .frame(
                width: SidebarMetrics.selectedBackgroundSize,
                height: SidebarMetrics.selectedBackgroundSize
              )
          }

          Image(systemName: icon.systemName)
            .font(.system(size: SidebarMetrics.symbolSize, weight: .semibold))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(isSelected ? selectedAccent : inactiveForeground)

          if showBadge {
            Circle()
              .fill(DayflowSurfaceAccent.primary)
              .frame(width: SidebarMetrics.badgeSize, height: SidebarMetrics.badgeSize)
              .offset(x: SidebarMetrics.badgeOffsetX, y: SidebarMetrics.badgeOffsetY)
          }
        }
        .frame(width: SidebarMetrics.iconContainerSize, height: SidebarMetrics.iconContainerSize)

        Text(icon.displayName)
          .font(.custom("Figtree", size: SidebarMetrics.labelFontSize))
          .lineLimit(1)
          .minimumScaleFactor(0.75)
          .foregroundColor(
            isSelected ? selectedForeground : inactiveForeground)
      }
      .frame(width: SidebarMetrics.itemSize, height: SidebarMetrics.itemSize)
      .contentShape(Rectangle())
    }
    .buttonStyle(DayflowPressScaleButtonStyle())
    .contentShape(Rectangle())
    .hoverScaleEffect(scale: 1.02)
    .pointingHandCursor()
  }
}
