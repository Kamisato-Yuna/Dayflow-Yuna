import SwiftUI

struct WeeklyHighlightsSection: View {
  let snapshot: WeeklyHighlightsSnapshot
  let width: CGFloat

  init(snapshot: WeeklyHighlightsSnapshot, width: CGFloat = Design.width) {
    self.snapshot = snapshot
    self.width = width
  }

  private enum Design {
    static let width: CGFloat = 470
    static let height: CGFloat = 298
    static let titleColor = DayflowWeeklyToken.title
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text("重点亮点")
        .font(.custom("InstrumentSerif-Regular", size: 20))
        .foregroundStyle(Design.titleColor)

      VStack(alignment: .leading, spacing: 19) {
        ForEach(snapshot.highlights) { highlight in
          HStack(alignment: .top, spacing: 18) {
            Text(highlight.tag)
              .font(.custom("Figtree-SemiBold", size: 8))
              .foregroundStyle(Color(hex: "DF8351"))
              .lineLimit(1)
              .padding(.horizontal, 6)
              .padding(.vertical, 4)
              .background(DayflowWeeklyToken.accent.opacity(0.12))
              .overlay(
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                  .stroke(DayflowWeeklyToken.accent.opacity(0.24), lineWidth: 1)
              )
              .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
              .frame(width: 84, alignment: .leading)

            Text(highlight.text)
              .font(.custom("Figtree-Regular", size: 12))
              .foregroundStyle(Color(hex: "333333"))
              .lineSpacing(1)
              .frame(maxWidth: .infinity, alignment: .leading)
          }
        }
      }
      .padding(.top, 26)

      Spacer(minLength: 0)
    }
    .padding(.top, 19)
    .padding(.horizontal, 18)
    .frame(width: width, height: Design.height, alignment: .topLeading)
    .dayflowCard(cornerRadius: 4)
  }
}

struct WeeklyHighlightsSnapshot {
  let highlights: [WeeklyHighlight]

  static let figmaPreview = WeeklyHighlightsSnapshot(
    highlights: [
      WeeklyHighlight(
        id: "editorial-nls",
        tag: "EDITORIAL NLS",
        text:
          "Iterated on ZSR and sparse results design explorations (zero-result states, best match redirects, query rephrasing guidance)"
      ),
      WeeklyHighlight(
        id: "editorial-video-nls",
        tag: "EDITORIAL VIDEO NLS",
        text:
          "Conducted competitive analysis of NLS video search tools (TwelveLabs, WayinVideo, AP Moments, YouTube Ask) during Pod 1 Review"
      ),
      WeeklyHighlight(
        id: "editorial-sbi",
        tag: "EDITORIAL SBI",
        text:
          "Reviewed scope-switching and SBI handling flows; drafted \"Areas requiring additional PD input\" spec with ClickUp links; synced with Jason Ross on SBI UX details"
      ),
    ]
  )
}

struct WeeklyHighlight: Identifiable {
  let id: String
  let tag: String
  let text: String
}

#Preview("Top Highlights", traits: .fixedLayout(width: 470, height: 298)) {
  WeeklyHighlightsSection(snapshot: .figmaPreview)
    .padding(24)
    .dayflowWindowBackground()
}
