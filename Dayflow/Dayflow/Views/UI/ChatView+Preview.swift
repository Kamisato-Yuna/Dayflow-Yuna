import AppKit
import Charts
import SwiftUI

// MARK: - Preview

#Preview("Chat View") {
  ChatView()
    .frame(width: 400, height: 600)
}

#Preview("思考中 Indicator") {
  思考中Indicator()
    .padding()
    .background(Color(hex: "FFFAF5"))
}
