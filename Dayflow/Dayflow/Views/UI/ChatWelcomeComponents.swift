import AppKit
import Charts
import SwiftUI

struct WelcomePrompt {
  let icon: String
  let text: String
}

struct WelcomeSuggestionRow: View {
  let prompt: WelcomePrompt
  let action: () -> Void

  @State var isHovered = false
  @Environment(\.accessibilityReduceMotion) var reduceMotion

  var body: some View {
    Button(action: action) {
      HStack(spacing: 10) {
        Image(systemName: prompt.icon)
          .font(.system(size: 11, weight: .bold))
          .foregroundColor(ChatSurfacePalette.accent)
          .frame(width: 24, height: 24)
          .background(
            Circle()
              .fill(ChatSurfacePalette.accent.opacity(isHovered ? 0.18 : 0.12))
          )

        Text(prompt.text)
          .font(.custom("Figtree", size: 13).weight(.semibold))
          .foregroundColor(ChatSurfacePalette.primaryText)
          .frame(maxWidth: .infinity, alignment: .leading)
          .multilineTextAlignment(.leading)
          .lineLimit(2)

        Image(systemName: "arrow.up.right")
          .font(.system(size: 9, weight: .bold))
          .foregroundColor(ChatSurfacePalette.secondaryText)
          .padding(.trailing, 2)
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 10)
      .chatMessageSurface(cornerRadius: 14)
      .scaleEffect(reduceMotion ? 1 : (isHovered ? 1.01 : 1))
      .offset(y: reduceMotion ? 0 : (isHovered ? -1 : 0))
    }
    .buttonStyle(.plain)
    .pointingHandCursor()
    .onHover { hovering in
      guard !reduceMotion else {
        isHovered = false
        return
      }
      withAnimation(.timingCurve(0.22, 1, 0.36, 1, duration: 0.18)) {
        isHovered = hovering
      }
    }
  }
}

// MARK: - Suggestion Chip

struct SuggestionChip: View {
  let text: String
  let action: () -> Void

  @State var isHovered = false

  var body: some View {
    Button(action: action) {
      Text(text)
        .font(.custom("Figtree", size: 12).weight(.medium))
        .foregroundColor(isHovered ? ChatSurfacePalette.primaryText : ChatSurfacePalette.secondaryText)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(ChatSurfacePalette.accent.opacity(isHovered ? 0.14 : 0.08))
        .overlay(
          RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(ChatSurfacePalette.accent.opacity(isHovered ? 0.34 : 0.20), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .scaleEffect(isHovered ? 1.02 : 1.0)
    }
    .buttonStyle(.plain)
    .pointingHandCursor()
    .onHover { hovering in
      withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
        isHovered = hovering
      }
    }
  }
}
