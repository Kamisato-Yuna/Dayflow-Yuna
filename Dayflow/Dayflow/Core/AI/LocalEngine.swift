import Foundation

enum Local引擎: String, CaseIterable, Identifiable, Codable {
  case ollama
  case lmstudio
  case custom

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .ollama: return "Ollama"
    case .lmstudio: return "LM Studio"
    case .custom: return "自定义"
    }
  }

  var defaultBaseURL: String {
    switch self {
    case .ollama: return "http://localhost:11434"
    case .lmstudio: return "http://localhost:1234"
    case .custom: return "http://localhost:11434"
    }
  }
}
