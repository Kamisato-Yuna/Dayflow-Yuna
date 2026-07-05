//
//  APIKeyInputView.swift
//  Dayflow
//
//  API key input component for Gemini setup
//

import SwiftUI

struct APIKeyInputView: View {
  @Binding var apiKey: String
  let title: String
  let subtitle: String
  let placeholder: String
  let onValidate: (String) -> Bool

  @State private var showPassword = false
  @State private var validationState: ValidationState = .none
  @FocusState private var isFocused: Bool

  enum ValidationState {
    case none
    case valid
    case invalid
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text(title)
        .font(.custom("Figtree", size: 16))
        .fontWeight(.semibold)
        .foregroundColor(Color(nsColor: .labelColor).opacity(0.9))

      Text(subtitle)
        .font(.custom("Figtree", size: 14))
        .foregroundColor(Color(nsColor: .secondaryLabelColor))

      // Input field container
      VStack(alignment: .leading, spacing: 8) {
        HStack(spacing: 12) {
          Group {
            if showPassword {
              TextField(placeholder, text: $apiKey)
                .textFieldStyle(.plain)
            } else {
              SecureField(placeholder, text: $apiKey)
                .textFieldStyle(.plain)
            }
          }
          .font(.custom("SF Mono", size: 13))
          .focused($isFocused)
          .onChange(of: apiKey) { _, newValue in
            let cleaned = cleanedAPIKey(newValue)
            guard cleaned == newValue else {
              apiKey = cleaned
              return
            }
            validateKey(cleaned)
          }

          Button(action: { showPassword.toggle() }) {
            Image(systemName: showPassword ? "eye.slash" : "eye")
              .font(.system(size: 14, weight: .medium))
              .foregroundColor(Color(nsColor: .tertiaryLabelColor))
          }
          .buttonStyle(.plain)
          .pointingHandCursor()

          // Validation indicator
          if validationState != .none {
            Image(
              systemName: validationState == .valid ? "checkmark.circle.fill" : "xmark.circle.fill"
            )
            .font(.system(size: 16))
            .foregroundColor(
              validationState == .valid
                ? DayflowSurfaceAccent.positive : DayflowSurfaceAccent.critical
            )
            .transition(.scale.combined(with: .opacity))
          }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .dayflowOnboardingTextField()
        .overlay(
          RoundedRectangle(cornerRadius: 8)
            .stroke(borderColor, lineWidth: isFocused ? 2 : 1)
        )

        // Validation message
        if validationState == .invalid {
          Text("密钥长度至少为 10 个字符以上")
            .font(.custom("Figtree", size: 12))
            .foregroundColor(DayflowSurfaceAccent.critical)
            .transition(.opacity)
        }
      }
      .animation(.easeOut(duration: 0.2), value: validationState)

      // Help text
      HStack(spacing: 4) {
        Image(systemName: "lock.shield.fill")
          .font(.system(size: 12))
          .foregroundColor(DayflowSurfaceAccent.positive.opacity(0.72))

        Text("你的密钥会经过加密后存储在系统钥匙串，不会上传到任何地方")
          .font(.custom("Figtree", size: 12))
          .foregroundColor(Color(nsColor: .tertiaryLabelColor))
      }
    }
  }

  private var borderColor: Color {
    if isFocused {
      switch validationState {
      case .valid:
        return DayflowSurfaceAccent.positive.opacity(0.6)
      case .invalid:
        return DayflowSurfaceAccent.critical.opacity(0.6)
      case .none:
        return DayflowOnboardingToken.accent.opacity(0.6)
      }
    } else {
      return Color(nsColor: .separatorColor).opacity(0.34)
    }
  }

  private func validateKey(_ key: String) {
    guard !key.isEmpty else {
      validationState = .none
      return
    }

    withAnimation(.easeOut(duration: 0.2)) {
      validationState = onValidate(key) ? .valid : .invalid
    }
  }

  private func cleanedAPIKey(_ key: String) -> String {
    key.components(separatedBy: .whitespacesAndNewlines).joined()
  }
}
