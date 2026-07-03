//
//  SetupSidebarView.swift
//  Dayflow
//
//  Sidebar navigation for LLM provider setup flow
//

import SwiftUI

struct SetupSidebarView: View {
  let steps: [SetupStep]
  let currentStepId: String
  let onStepSelected: (String) -> Void

  @Namespace private var selectionNamespace

  var body: some View {
    DayflowGlassSurface(role: .sidebarSurface, cornerRadius: 16, spacing: 8) {
      VStack(alignment: .leading, spacing: 8) {
        ForEach(Array(steps.enumerated()), id: \.element.id) { _, step in
          SetupSidebarItem(
            title: step.title,
            isSelected: step.id == currentStepId,
            isCompleted: isStepCompleted(step: step, currentId: currentStepId, in: steps),
            namespace: selectionNamespace,
            onTap: {
              onStepSelected(step.id)
            }
          )
        }
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 12)
    }
    .frame(maxWidth: .infinity)
  }

  private func isStepCompleted(step: SetupStep, currentId: String, in steps: [SetupStep]) -> Bool {
    guard let currentIndex = steps.firstIndex(where: { $0.id == currentId }),
      let stepIndex = steps.firstIndex(where: { $0.id == step.id })
    else {
      return false
    }
    return stepIndex < currentIndex || step.isCompleted
  }
}

struct SetupSidebarItem: View {
  let title: String
  let isSelected: Bool
  let isCompleted: Bool
  let namespace: Namespace.ID
  let onTap: () -> Void

  @State private var isHovered = false

  var body: some View {
    Button(action: onTap) {
      HStack(alignment: .center, spacing: 12) {
        // Step indicator - fixed width for consistent alignment
        Group {
          if isCompleted && !isSelected {
            Image(systemName: "checkmark.circle.fill")
              .font(.system(size: 14))
              .foregroundColor(DayflowSurfaceAccent.positive)
          } else if isSelected {
            Image(systemName: "chevron.right")
              .font(.system(size: 12, weight: .semibold))
              .foregroundColor(DayflowOnboardingToken.accent)
          } else {
            Color.clear  // Placeholder for unselected items
          }
        }
        .frame(width: 20, height: 20)  // Fixed frame for consistent centering

        Text(title)
          .font(.custom("Figtree", size: 15))
          .fontWeight(isSelected ? .semibold : .medium)
          .foregroundColor(textColor)

        Spacer()  // Push content to fill the button area
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .frame(maxWidth: .infinity, alignment: .leading)
      .contentShape(Rectangle())  // Make entire area clickable
      .background(backgroundView)
      .overlay(overlayView)
    }
    .buttonStyle(DayflowPressScaleButtonStyle(pressedScale: 0.97))
    .pointingHandCursor()
    .scaleEffect(isHovered && !isSelected ? 1.02 : 1.0)
    .animation(.spring(response: 0.3, dampingFraction: 0.9), value: isSelected)
    .animation(.easeOut(duration: 0.2), value: isHovered)
    .onHover { hovering in
      isHovered = hovering
    }
  }

  @ViewBuilder
  private var backgroundView: some View {
    if isSelected {
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .fill(DayflowOnboardingToken.accent.opacity(0.14))
        .matchedGeometryEffect(id: "selection", in: namespace)
    } else if isHovered {
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .fill(Color(nsColor: .controlBackgroundColor).opacity(0.28))
    } else {
      Color.clear
    }
  }

  @ViewBuilder
  private var overlayView: some View {
    if isSelected {
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .inset(by: 0.5)
        .stroke(DayflowOnboardingToken.accent.opacity(0.45), lineWidth: 1)
    }
  }

  private var textColor: Color {
    if isSelected {
      return DayflowOnboardingToken.title
    } else if isCompleted {
      return DayflowOnboardingToken.secondaryText
    } else {
      return Color(nsColor: .tertiaryLabelColor)
    }
  }
}
