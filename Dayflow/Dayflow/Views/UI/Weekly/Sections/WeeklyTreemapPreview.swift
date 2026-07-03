import AppKit
import SwiftUI

#Preview("Weekly Treemap", traits: .fixedLayout(width: 958, height: 549)) {
  WeeklyTreemapPreviewHarness()
    .dayflowWindowBackground()
}

struct WeeklyTreemapPreviewHarness: View {
  @State var selectedDataset = WeeklyTreemapPreviewDataset.balanced
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack(spacing: 10) {
        ForEach(WeeklyTreemapPreviewDataset.allCases) { dataset in
          Button {
            selectedDataset = dataset
          } label: {
            Text(dataset.title)
              .font(.custom("Figtree-Regular", size: 12))
              .foregroundStyle(
                selectedDataset == dataset ? Color(nsColor: .selectedMenuItemTextColor) : DayflowWeeklyToken.text
              )
              .padding(.horizontal, 12)
              .padding(.vertical, 6)
              .background(
                Capsule(style: .continuous)
                  .fill(
                    selectedDataset == dataset
                      ? DayflowWeeklyToken.accent
                      : DayflowWeeklyToken.secondaryFill(
                        colorScheme: colorScheme,
                        reduceTransparency: reduceTransparency
                      ))
              )
              .overlay(
                Capsule(style: .continuous)
                  .stroke(Color(hex: "E3D6CF"), lineWidth: 1)
              )
          }
          .buttonStyle(.plain)
        }
      }

      WeeklyTreemapSection(snapshot: selectedDataset.snapshot)
    }
    .padding(18)
  }
}

enum WeeklyTreemapPreviewDataset: String, CaseIterable, Identifiable {
  case balanced
  case dominant
  case tinyTail
  case crowded

  var id: String { rawValue }

  var title: String {
    switch self {
    case .balanced:
      return "Balanced"
    case .dominant:
      return "Dominant"
    case .tinyTail:
      return "Tiny Tail"
    case .crowded:
      return "Crowded"
    }
  }

  var snapshot: WeeklyTreemapSnapshot {
    switch self {
    case .balanced:
      return .figmaPreview
    case .dominant:
      return .dominantCategoryPreview
    case .tinyTail:
      return .tinyTailPreview
    case .crowded:
      return .crowdedPreview
    }
  }
}
