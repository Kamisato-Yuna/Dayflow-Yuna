import XCTest

@testable import Dayflow

final class CategoryAliasResolverTests: XCTestCase {
  func testLegacyEnglishNamesDisplayAsChineseAliases() {
    XCTAssertEqual(CategoryAliasResolver.displayName(for: "Research & Analysis"), "研究与分析")
    XCTAssertEqual(CategoryAliasResolver.displayName(for: "Specs & Planning"), "方案与规划")
    XCTAssertEqual(CategoryAliasResolver.displayName(for: "Communication"), "沟通")
    XCTAssertEqual(CategoryAliasResolver.displayName(for: "Personal"), "个人")
    XCTAssertEqual(CategoryAliasResolver.displayName(for: "Distraction"), "分心")
    XCTAssertEqual(CategoryAliasResolver.displayName(for: "Idle"), "空闲")
  }

  func testUnknownAndBlankNamesUseExpectedFallbacks() {
    XCTAssertEqual(CategoryAliasResolver.displayName(for: "Deep Work"), "Deep Work")
    XCTAssertEqual(CategoryAliasResolver.displayName(for: "   "), "未分类")
  }

  func testSystemIsNotDefaultMigrated() {
    XCTAssertEqual(CategoryAliasResolver.displayName(for: "System"), "System")
    XCTAssertFalse(
      CategoryAliasResolver.defaultMappings.contains {
        CategoryAliasResolver.rawNormalizedKey($0.source)
          == CategoryAliasResolver.rawNormalizedKey("System")
      }
    )
  }

  func testAliasesShareNormalizedKeyWithCurrentNames() {
    XCTAssertEqual(
      CategoryAliasResolver.normalizedKey("Research & Analysis"),
      CategoryAliasResolver.normalizedKey("研究与分析")
    )
    XCTAssertEqual(
      CategoryAliasResolver.normalizedKey("Distraction"),
      CategoryAliasResolver.normalizedKey("分心")
    )
  }
}
