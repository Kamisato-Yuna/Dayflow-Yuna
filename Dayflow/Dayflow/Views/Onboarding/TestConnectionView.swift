//
//  测试ConnectionView.swift
//  Dayflow
//
//  测试 connection button for Gemini API
//

import SwiftUI

struct 测试ConnectionView: View {
  let on测试Complete: ((Bool) -> Void)?

  @State private var is测试ing = false
  @State private var testResult: 测试Result?

  init(on测试Complete: ((Bool) -> Void)? = nil) {
    self.on测试Complete = on测试Complete
  }

  enum 测试Result {
    case success(String)
    case failure(String)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      SettingsPrimaryButton(
        title: is测试ing ? "测试ing…" : "测试 connection",
        systemImage: "bolt.fill",
        isLoading: is测试ing,
        action: testConnection
      )

      if let result = testResult {
        SettingsStatusDot(
          state: result.isSuccess ? .good : .bad,
          label: result.message
        )
      }
    }
  }

  private func testConnection() {
    guard !is测试ing else { return }

    guard
      let apiKey = KeychainManager.shared.retrieve(for: "gemini")?
        .components(separatedBy: .whitespacesAndNewlines).joined(),
      !apiKey.isEmpty
    else {
      testResult = .failure("No API key found. Enter your API key first.")
      on测试Complete?(false)
      AnalyticsService.shared.capture(
        "connection_test_failed", ["provider": "gemini", "error_code": "no_api_key"])
      return
    }

    is测试ing = true
    testResult = nil
    AnalyticsService.shared.capture("connection_test_started", ["provider": "gemini"])

    Task {
      do {
        let _ = try await GeminiAPIHelper.shared.testConnection(apiKey: apiKey)
        await MainActor.run {
          testResult = .success("Connection successful.")
          is测试ing = false
          on测试Complete?(true)
        }
        AnalyticsService.shared.capture("connection_test_succeeded", ["provider": "gemini"])
      } catch GeminiAPIHelper.APIError.rateLimited {
        await MainActor.run {
          testResult = .success("API key works, but Gemini is rate limited right now.")
          is测试ing = false
          on测试Complete?(true)
        }
        AnalyticsService.shared.capture(
          "connection_test_succeeded",
          [
            "provider": "gemini",
            "status": "rate_limited",
            "model": GeminiModel.flashLite31.rawValue,
          ])
      } catch {
        await MainActor.run {
          testResult = .failure(error.localizedDescription)
          is测试ing = false
          on测试Complete?(false)
        }
        AnalyticsService.shared.capture(
          "connection_test_failed",
          ["provider": "gemini", "error_code": String((error as NSError).code)])
      }
    }
  }
}

extension 测试ConnectionView.测试Result {
  var isSuccess: Bool {
    switch self {
    case .success: return true
    case .failure: return false
    }
  }

  var message: String {
    switch self {
    case .success(let msg): return msg
    case .failure(let msg): return msg
    }
  }
}
