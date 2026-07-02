import XCTest
@testable import Dayflow

final class TimeParsingTests: XCTestCase {
    func testValidTimes() {
        XCTAssertEqual(parseTimeHMMA(timeString: "9:30 AM"), 9 * 60 + 30)
        XCTAssertEqual(parseTimeHMMA(timeString: "11:59 PM"), 23 * 60 + 59)
    }

    func testInvalidTimes() {
        XCTAssertNil(parseTimeHMMA(timeString: ""))
        XCTAssertNil(parseTimeHMMA(timeString: "invalid"))
    }
}

final class DayGoalPlanTests: XCTestCase {
    func testDefaultPlanTreatsEnglishAndChineseDistractionCategoriesAsDistraction() {
        let categories = [
            TimelineCategory(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                name: "Work",
                colorHex: "#111111",
                order: 0
            ),
            TimelineCategory(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
                name: "Distraction",
                colorHex: "#222222",
                order: 1
            ),
            TimelineCategory(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
                name: "Distractions",
                colorHex: "#333333",
                order: 2
            ),
            TimelineCategory(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
                name: "分心",
                colorHex: "#444444",
                order: 3
            ),
            TimelineCategory(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
                name: "空闲",
                colorHex: "#555555",
                order: 4,
                isSystem: true,
                isIdle: true
            ),
        ]

        let plan = DayGoalPlan.defaultPlan(day: "2026-07-02", categories: categories)

        XCTAssertEqual(plan.focusCategories.map(\.name), ["Work"])
        XCTAssertEqual(plan.distractionCategories.map(\.name), ["Distraction", "Distractions", "分心"])
    }
}
