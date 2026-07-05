import AppKit
import SwiftUI

enum DayflowBrandIconTreatment {
  case original
  case template
}

struct DayflowBrandIconView: View {
  let imageName: String
  let size: CGFloat
  let cornerRadius: CGFloat
  let treatment: DayflowBrandIconTreatment

  init(
    imageName: String,
    size: CGFloat = 40,
    cornerRadius: CGFloat = 10,
    treatment: DayflowBrandIconTreatment = .original
  ) {
    self.imageName = imageName
    self.size = size
    self.cornerRadius = cornerRadius
    self.treatment = treatment
  }

  var body: some View {
    Image(imageName)
      .resizable()
      .renderingMode(treatment == .template ? .template : .original)
      .interpolation(.high)
      .antialiased(true)
      .scaledToFit()
      .foregroundColor(treatment == .template ? Color(nsColor: .labelColor) : nil)
      .frame(width: size, height: size)
  }
}

struct DayflowExternalIconBadge<Content: View>: View {
  let size: CGFloat
  let cornerRadius: CGFloat
  let contentScale: CGFloat
  let content: () -> Content

  init(
    size: CGFloat = 40,
    cornerRadius: CGFloat = 10,
    contentScale: CGFloat = 0.68,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.size = size
    self.cornerRadius = cornerRadius
    self.contentScale = contentScale
    self.content = content
  }

  var body: some View {
    content()
      .frame(width: size * contentScale, height: size * contentScale)
      .frame(width: size, height: size)
      .modifier(DayflowExternalIconBadgeSurface(cornerRadius: cornerRadius))
  }
}

struct DayflowExternalImageBadge: View {
  let imageName: String
  let size: CGFloat
  let cornerRadius: CGFloat
  let contentScale: CGFloat
  let treatment: DayflowBrandIconTreatment

  init(
    imageName: String,
    size: CGFloat = 40,
    cornerRadius: CGFloat = 10,
    contentScale: CGFloat = 0.68,
    treatment: DayflowBrandIconTreatment = .original
  ) {
    self.imageName = imageName
    self.size = size
    self.cornerRadius = cornerRadius
    self.contentScale = contentScale
    self.treatment = treatment
  }

  var body: some View {
    DayflowExternalIconBadge(
      size: size,
      cornerRadius: cornerRadius,
      contentScale: contentScale
    ) {
      DayflowBrandIconView(
        imageName: imageName,
        size: size * contentScale,
        cornerRadius: cornerRadius,
        treatment: treatment
      )
    }
  }
}

struct DayflowSystemIconBadge: View {
  let systemName: String
  let size: CGFloat
  let cornerRadius: CGFloat
  let symbolSize: CGFloat

  init(
    systemName: String,
    size: CGFloat = 40,
    cornerRadius: CGFloat = 10,
    symbolSize: CGFloat = 20
  ) {
    self.systemName = systemName
    self.size = size
    self.cornerRadius = cornerRadius
    self.symbolSize = symbolSize
  }

  var body: some View {
    DayflowExternalIconBadge(size: size, cornerRadius: cornerRadius, contentScale: 1) {
      Image(systemName: systemName)
        .font(.system(size: symbolSize, weight: .medium))
        .foregroundColor(Color(nsColor: .labelColor).opacity(0.82))
    }
  }
}

struct DayflowFaviconBadge<Content: View>: View {
  let size: CGFloat
  let cornerRadius: CGFloat
  let content: () -> Content

  init(
    size: CGFloat,
    cornerRadius: CGFloat? = nil,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.size = size
    self.cornerRadius = cornerRadius ?? max(4, size * 0.24)
    self.content = content
  }

  var body: some View {
    content()
      .frame(width: max(1, size - 6), height: max(1, size - 6))
      .frame(width: size, height: size)
      .modifier(DayflowExternalIconBadgeSurface(cornerRadius: cornerRadius))
  }
}

struct DayflowContentPreviewFrame<Content: View>: View {
  let cornerRadius: CGFloat
  let content: () -> Content

  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

  init(cornerRadius: CGFloat = 16, @ViewBuilder content: @escaping () -> Content) {
    self.cornerRadius = cornerRadius
    self.content = content
  }

  var body: some View {
    content()
      .overlay {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
          .fill(previewMaskColor)
      }
      .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
      .modifier(DayflowContentPreviewSurface(cornerRadius: cornerRadius))
  }

  private var previewMaskColor: Color {
    if colorScheme == .dark {
      return Color.black.opacity(reduceTransparency ? 0.28 : 0.18)
    }
    return Color(nsColor: .windowBackgroundColor).opacity(reduceTransparency ? 0.10 : 0.06)
  }
}

private struct DayflowExternalIconBadgeSurface: ViewModifier {
  let cornerRadius: CGFloat

  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

  func body(content: Content) -> some View {
    let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    let increaseContrast = NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
    let shadow = DayflowSurfaceToken.shadow(
      for: .floatingControl,
      colorScheme: colorScheme,
      reduceTransparency: reduceTransparency
    )

    content
      .background {
        if reduceTransparency {
          shape.fill(DayflowContentToken.secondaryFill(
            colorScheme: colorScheme,
            reduceTransparency: reduceTransparency
          ))
        } else {
          shape.fill(.regularMaterial)
          shape.fill(DayflowContentToken.secondaryFill(
            colorScheme: colorScheme,
            reduceTransparency: reduceTransparency
          ))
        }
      }
      .overlay {
        shape.stroke(
          DayflowContentToken.cardBorder(
            colorScheme: colorScheme,
            increaseContrast: increaseContrast
          ),
          lineWidth: increaseContrast ? 1 : 0.7
        )
      }
      .shadow(color: shadow.color.opacity(0.55), radius: shadow.radius * 0.55, x: 0, y: shadow.y)
      .clipShape(shape)
  }
}

private struct DayflowContentPreviewSurface: ViewModifier {
  let cornerRadius: CGFloat

  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

  func body(content: Content) -> some View {
    let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    let increaseContrast = NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast

    content
      .background {
        if reduceTransparency {
          shape.fill(Color(nsColor: .controlBackgroundColor))
        } else {
          shape.fill(.regularMaterial)
          shape.fill(DayflowContentToken.cardFill(
            colorScheme: colorScheme,
            reduceTransparency: reduceTransparency
          ))
        }
      }
      .overlay {
        shape.stroke(
          DayflowContentToken.cardBorder(
            colorScheme: colorScheme,
            increaseContrast: increaseContrast
          ),
          lineWidth: increaseContrast ? 1 : 0.75
        )
      }
      .clipShape(shape)
  }
}
