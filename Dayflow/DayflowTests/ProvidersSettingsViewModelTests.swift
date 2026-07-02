import XCTest

@testable import Dayflow

@MainActor
final class ProvidersSettingsViewModelTests: XCTestCase {
  private let defaultKeys = [
    "llmLocalEngine",
    "llmLocalBaseURL",
    "llmLocalModelId",
    "llmLocalAPIKey",
    "ollamaSetupComplete",
    "geminiSetupComplete",
    "chatgpt_claudeSetupComplete",
    "chatCLIPreferredTool",
    "llmProviderType",
    "llmBackupProviderId",
    "llmBackupChatCLITool",
    "selectedLLMProvider",
    "selectedLLMProviderBaseURL",
    "selectedLLMProviderCanonical",
    "selectedLLMProviderDisplayName",
  ]

  private var savedDefaults: [String: Any?] = [:]

  override func setUp() {
    super.setUp()
    savedDefaults = Dictionary(
      uniqueKeysWithValues: defaultKeys.map { ($0, UserDefaults.standard.object(forKey: $0)) }
    )
    defaultKeys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
  }

  override func tearDown() {
    defaultKeys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
    for (key, value) in savedDefaults {
      if let value {
        UserDefaults.standard.set(value, forKey: key)
      }
    }
    savedDefaults = [:]
    super.tearDown()
  }

  func testProviderSetupCompletionRefreshesLocalModelSettingsFromDefaults() {
    UserDefaults.standard.set(LocalEngine.ollama.rawValue, forKey: "llmLocalEngine")
    UserDefaults.standard.set("http://localhost:11434", forKey: "llmLocalBaseURL")
    UserDefaults.standard.set("qwen2.5vl:7b", forKey: "llmLocalModelId")

    let viewModel = ProvidersSettingsViewModel()
    XCTAssertEqual(viewModel.localEngine, .ollama)
    XCTAssertEqual(viewModel.localModelId, "qwen2.5vl:7b")

    UserDefaults.standard.set(LocalEngine.lmstudio.rawValue, forKey: "llmLocalEngine")
    UserDefaults.standard.set("http://localhost:1234", forKey: "llmLocalBaseURL")
    UserDefaults.standard.set("gemma-4-local", forKey: "llmLocalModelId")
    UserDefaults.standard.set("local-test-key", forKey: "llmLocalAPIKey")

    viewModel.handleProviderSetupCompletion("ollama")

    XCTAssertEqual(viewModel.localEngine, .lmstudio)
    XCTAssertEqual(viewModel.localBaseURL, "http://localhost:1234")
    XCTAssertEqual(viewModel.localModelId, "gemma-4-local")
    XCTAssertEqual(viewModel.localAPIKey, "local-test-key")
  }

  func testLegacySelectedDayflowProviderMigratesToGemini() {
    UserDefaults.standard.set("dayflow", forKey: "selectedLLMProvider")

    let loadedProvider = LLMProviderType.load()
    let viewModel = ProvidersSettingsViewModel()
    viewModel.loadCurrentProvider()

    guard case .geminiDirect = loadedProvider else {
      return XCTFail("Expected legacy dayflow selection to migrate to Gemini")
    }
    XCTAssertEqual(viewModel.currentProvider, "gemini")
    XCTAssertEqual(UserDefaults.standard.string(forKey: "selectedLLMProvider"), "gemini")
  }

  func testEncodedLegacyDayflowBackendMigratesToGemini() throws {
    let encoded = try JSONEncoder().encode(LLMProviderType.dayflowBackend())
    UserDefaults.standard.set(encoded, forKey: "llmProviderType")
    UserDefaults.standard.set("dayflow", forKey: "selectedLLMProvider")

    let viewModel = ProvidersSettingsViewModel()
    viewModel.loadCurrentProvider()

    XCTAssertEqual(viewModel.currentProvider, "gemini")
    XCTAssertEqual(UserDefaults.standard.string(forKey: "selectedLLMProvider"), "gemini")

    let reloadedProvider = LLMProviderType.load()
    guard case .geminiDirect = reloadedProvider else {
      return XCTFail("Expected encoded dayflow backend to be rewritten as Gemini")
    }
  }

  func testLegacyDayflowBackupProviderIsClearedAndRemovedFromDefaults() {
    LLMProviderType.geminiDirect.persist()
    UserDefaults.standard.set("dayflow", forKey: "llmBackupProviderId")
    UserDefaults.standard.set("claude", forKey: "llmBackupChatCLITool")

    let viewModel = ProvidersSettingsViewModel()
    viewModel.loadCurrentProvider()
    viewModel.loadBackupProvider()

    XCTAssertNil(viewModel.backupProvider)
    XCTAssertNil(viewModel.backupChatCLITool)
    XCTAssertNil(UserDefaults.standard.string(forKey: "llmBackupProviderId"))
    XCTAssertNil(UserDefaults.standard.string(forKey: "llmBackupChatCLITool"))
  }

  func testRoutingProvidersExcludeDayflowPro() {
    let viewModel = ProvidersSettingsViewModel()
    let ids = viewModel.routingProviders.map(\.id)
    let titles = viewModel.routingProviders.map(\.title)

    XCTAssertFalse(ids.contains("dayflow"))
    XCTAssertFalse(titles.contains("Dayflow Pro"))
  }
}
