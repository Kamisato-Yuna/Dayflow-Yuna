import XCTest

@testable import Dayflow

final class DailyWorkflowComputationTests: XCTestCase {
  func testLegacyAndCurrentCategoryNamesShareOneWorkflowRow() {
    let categories = [
      TimelineCategory(name: "研究与分析", colorHex: "#56CFEE", order: 0)
    ]
    let cards = [
      card(category: "Research & Analysis", start: "09:00 AM", end: "09:30 AM"),
      card(category: "研究与分析", start: "09:30 AM", end: "10:00 AM"),
    ]

    let result = computeDailyWorkflow(cards: cards, categories: categories)
    let activeRows = result.rows.filter { row in
      row.slotOccupancies.contains { $0 > 0 }
    }

    XCTAssertEqual(activeRows.count, 1)
    XCTAssertEqual(activeRows.first?.name, "研究与分析")
    XCTAssertEqual(activeRows.first?.colorHex, "56CFEE")
    XCTAssertEqual(result.totals.first?.minutes, 60)
  }

  private func card(category: String, start: String, end: String) -> TimelineCard {
    TimelineCard(
      recordId: nil,
      batchId: nil,
      startTimestamp: start,
      endTimestamp: end,
      category: category,
      subcategory: "分析",
      title: "Research",
      summary: "Reviewed metrics",
      detailedSummary: "",
      day: "2026-06-15",
      distractions: nil,
      videoSummaryURL: nil,
      otherVideoSummaryURLs: nil,
      appSites: nil
    )
  }
}
