import SwiftUI

/// Hero surface for journal entry previews.
struct JournalHeroView: View {
  var summary: JournalHeroSummary
  var onReflect: (() -> Void)?

  init(summary: JournalHeroSummary = .preview, onReflect: (() -> Void)? = nil) {
    self.summary = summary
    self.onReflect = onReflect
  }

  var body: some View {
    ZStack {
      backgroundLayer

      VStack(spacing: 32) {
        badgeHeader
        entryCard

        if let onReflect {
          ReflectButton(title: summary.ctaTitle, action: onReflect)
        }
      }
      .frame(maxWidth: 920)
      .padding(.horizontal, 28)
      .padding(.vertical, 36)
    }
    .dayflowContentPanel(cornerRadius: 24)
  }
}

// MARK: - Layers

extension JournalHeroView {
  fileprivate var backgroundLayer: some View {
    ZStack {
      LinearGradient(
        colors: [
          Color(nsColor: .controlBackgroundColor).opacity(0.36),
          Color(nsColor: .windowBackgroundColor).opacity(0.58),
          Color.accentColor.opacity(0.08),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )

      RadialGradient(
        colors: [Color(nsColor: .controlAccentColor).opacity(0.10), Color.clear],
        center: .bottomLeading,
        startRadius: 90,
        endRadius: 520
      )

      RadialGradient(
        colors: [Color(nsColor: .separatorColor).opacity(0.16), Color.clear],
        center: .topLeading,
        startRadius: 140,
        endRadius: 520
      )
    }
  }
}

// MARK: - Components

extension JournalHeroView {
  fileprivate var badgeHeader: some View {
    Text(summary.headline)
      .font(.custom("Figtree-SemiBold", size: 30))
      .kerning(-0.4)
      .foregroundStyle(.clear)  // fill via gradient mask
      .overlay(
        JournalHeroTokens.badgeTextGradient
          .mask(
            Text(summary.headline)
              .font(.custom("Figtree-SemiBold", size: 30))
              .kerning(-0.4)
          )
      )
      .padding(.horizontal, 30)
      .padding(.vertical, 14)
      .background(
        RoundedRectangle(cornerRadius: 32, style: .continuous)
          .fill(JournalHeroTokens.badgeBackground)
          .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
              .stroke(JournalHeroTokens.badgeStroke, lineWidth: 1)
          )
      )
      .overlay(
        RoundedRectangle(cornerRadius: 32, style: .continuous)
          .stroke(JournalHeroTokens.badgeInnerHighlight, lineWidth: 0.6)
          .blur(radius: 0.8)
      )
      .shadow(color: JournalHeroTokens.badgeShadow, radius: 18, y: 12)
  }

  fileprivate var entryCard: some View {
    ZStack(alignment: .topLeading) {
      RoundedRectangle(cornerRadius: 20, style: .continuous)
        .fill(JournalHeroTokens.entryBackground)
        .overlay(
          RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(JournalHeroTokens.entryStroke, lineWidth: 1)
        )
        .shadow(color: JournalHeroTokens.entryShadow, radius: 30, y: 18)

      Text(summary.entry)
        .lineSpacing(8)
        .kerning(-0.2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 26)
        .padding(.vertical, 24)
        .multilineTextAlignment(.leading)

      // Fade out toward the bottom to mirror the Figma glow
      RoundedRectangle(cornerRadius: 20, style: .continuous)
        .fill(JournalHeroTokens.entryFade)
        .allowsHitTesting(false)
    }
    .padding(.horizontal, 6)
    .frame(maxWidth: .infinity, alignment: .leading)
    .dayflowCard(cornerRadius: 20)
  }
}

private struct ReflectButton: View {
  var title: String
  var action: () -> Void

  var body: some View {
    Button(action: action) {
      Text(title)
        .font(.custom("Figtree-SemiBold", size: 15))
    }
    .buttonStyle(JournalHeroPillButtonStyle())
  }
}

private struct JournalHeroPillButtonStyle: ButtonStyle {
  var horizontalPadding: CGFloat = 24
  var verticalPadding: CGFloat = 10

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .foregroundStyle(JournalHeroTokens.ctaText)
      .padding(.horizontal, horizontalPadding)
      .padding(.vertical, verticalPadding)
      .dayflowFloatingControl(cornerRadius: 100)
      .dayflowPressScale(
        configuration.isPressed,
        pressedScale: 0.98,
        animation: .spring(response: 0.25, dampingFraction: 0.85)
      )
      .pointingHandCursor()
  }
}

// MARK: - Models

struct JournalHeroSummary {
  var headline: String
  var entry: AttributedString
  var ctaTitle: String
}

extension JournalHeroSummary {
  static var preview: JournalHeroSummary {
    .init(
      headline: "每日日志",
      entry: .sampleEntry,
      ctaTitle: "用 Dayflow 复盘"
    )
  }
}

extension AttributedString {
  fileprivate static var sampleEntry: AttributedString {
    var base = AttributeContainer()
    base.font = .system(size: 30, weight: .semibold, design: .rounded)
    base.foregroundColor = JournalHeroTokens.entryPrimary

    var emphasized = AttributeContainer()
    emphasized.font = .system(size: 32, weight: .semibold, design: .rounded)
    emphasized.foregroundColor = JournalHeroTokens.entryEmphasis

    var secondary = AttributeContainer()
    secondary.font = .system(size: 28, weight: .semibold, design: .rounded)
    secondary.foregroundColor = JournalHeroTokens.entrySecondary

    var text = AttributedString(
      "Started the morning deep in debugging mode around ", attributes: base)
    text += AttributedString("8:45 AM", attributes: emphasized)
    text += AttributedString(", wrestling with dashboard cards that refused to ", attributes: base)
    text += AttributedString("show up.", attributes: emphasized)
    text += AttributedString(
      " Classic case of “why isn’t this simple thing working?” Had to dig through using Claude and even fire up Beekeeper Studio to check logs.",
      attributes: secondary)
    return text
  }
}

// MARK: - Tokens

private enum JournalHeroTokens {
  static let badgeTextGradient = LinearGradient(
    colors: [Color(nsColor: .labelColor), Color.accentColor],
    startPoint: .leading,
    endPoint: .trailing
  )

  static let badgeBackground = LinearGradient(
    colors: [
      Color(nsColor: .controlBackgroundColor).opacity(0.76),
      Color(nsColor: .windowBackgroundColor).opacity(0.48),
    ],
    startPoint: .top,
    endPoint: .bottom
  )

  static let badgeStroke = Color(nsColor: .separatorColor).opacity(0.24)
  static let badgeInnerHighlight = Color(nsColor: .highlightColor).opacity(0.20)
  static let badgeShadow = Color.black.opacity(0.08)

  static let entryBackground = Color(nsColor: .controlBackgroundColor).opacity(0.18)
  static let entryStroke = Color.clear
  static let entryShadow = Color.clear
  static let entryPrimary = Color(nsColor: .labelColor)
  static let entrySecondary = Color(nsColor: .secondaryLabelColor)
  static let entryEmphasis = Color.accentColor
  static let entryFade = LinearGradient(
    colors: [Color.clear, Color(nsColor: .windowBackgroundColor).opacity(0.70)],
    startPoint: .center,
    endPoint: .bottom
  )

  static let ctaBackground = LinearGradient(
    colors: [Color.accentColor.opacity(0.20), Color.accentColor.opacity(0.10)],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
  )
  static let ctaStroke = Color(nsColor: .separatorColor)
  static let ctaText = Color(nsColor: .labelColor)
  static let ctaShadow = Color.black.opacity(0.08)
}

// MARK: - Preview

struct JournalHeroView_Previews: PreviewProvider {
  static var previews: some View {
    JournalHeroView()
      .frame(width: 1180, height: 820)
      .preferredColorScheme(.light)
  }
}
