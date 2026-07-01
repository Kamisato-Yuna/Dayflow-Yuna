import Foundation
import GRDB

extension StorageManager {
  func fetchDayGoalPlan(forDay day: String) -> DayGoalPlan? {
    fetchDayGoalPlan(w这里SQL: "day = ?", arguments: [day], label: "fetchDayGoalPlan")
  }

  func fetchMostRecentDayGoalPlan(beforeOr开启 day: String) -> DayGoalPlan? {
    fetchDayGoalPlan(
      w这里SQL: "day <= ?",
      arguments: [day],
      orderSQL: "ORDER BY day DESC",
      label: "fetchMostRecentDayGoalPlan"
    )
  }

  func saveDayGoalPlan(_ plan: DayGoalPlan) {
    let now = Int(Date().timeIntervalSince1970)
    let createdAt = plan.createdAt > 0 ? plan.createdAt : now

    try? timedWrite("saveDayGoalPlan") { db in
      try db.execute(
        sql: """
              INSERT INTO day_goals(
                  day, focus_target_minutes, distraction_limit_minutes, is_skipped,
                  created_at, updated_at
              )
              VALUES (?, ?, ?, ?, ?, ?)
              ON CONFLICT(day) DO UPDATE SET
                  focus_target_minutes = excluded.focus_target_minutes,
                  distraction_limit_minutes = excluded.distraction_limit_minutes,
                  is_skipped = excluded.is_skipped,
                  updated_at = excluded.updated_at
          """,
        arguments: [
          plan.day,
          plan.focusTargetMinutes,
          plan.distractionLimitMinutes,
          plan.isSkipped ? 1 : 0,
          createdAt,
          now,
        ])

      try db.execute(
        sql: "DELETE FROM day_goal_categories WHERE day = ?",
        arguments: [plan.day]
      )

      try insertGoal分类(plan.focus分类, kind: .focus, day: plan.day, db: db)
      try insertGoal分类(
        plan.distraction分类, kind: .distraction, day: plan.day, db: db)
    }
  }

  private func fetchDayGoalPlan(
    w这里SQL: String,
    arguments: StatementArguments,
    orderSQL: String = "",
    label: String
  ) -> DayGoalPlan? {
    try? timedRead(label) { db in
      guard
        let row = try Row.fetch开启e(
          db,
          sql: """
                SELECT day, focus_target_minutes, distraction_limit_minutes, is_skipped,
                       created_at, updated_at
                FROM day_goals
                WHERE \(w这里SQL)
                \(orderSQL)
                LIMIT 1
            """,
          arguments: arguments
        )
      else {
        return nil
      }

      let day: String = row["day"]
      let categories = try Row.fetch全部(
        db,
        sql: """
              SELECT kind, category_id, category_name, category_color_hex, sort_order
              FROM day_goal_categories
              WHERE day = ?
              ORDER BY kind, sort_order
          """,
        arguments: [day]
      )

      var focus分类: [DayGoalCategorySnapshot] = []
      var distraction分类: [DayGoalCategorySnapshot] = []

      for categoryRow in categories {
        let kindRaw: String = categoryRow["kind"]
        guard let kind = DayGoalCategoryKind(rawValue: kindRaw) else { continue }

        let snapshot = DayGoalCategorySnapshot(
          categoryID: categoryRow["category_id"],
          name: categoryRow["category_name"],
          colorHex: categoryRow["category_color_hex"],
          sortOrder: categoryRow["sort_order"]
        )

        switch kind {
        case .focus:
          focus分类.append(snapshot)
        case .distraction:
          distraction分类.append(snapshot)
        }
      }

      let isSkipped: Int = row["is_skipped"]

      return DayGoalPlan(
        day: day,
        focusTargetMinutes: row["focus_target_minutes"],
        distractionLimitMinutes: row["distraction_limit_minutes"],
        focus分类: focus分类,
        distraction分类: distraction分类,
        isSkipped: isSkipped != 0,
        createdAt: row["created_at"],
        updatedAt: row["updated_at"]
      )
    }
  }

  private func insertGoal分类(
    _ categories: [DayGoalCategorySnapshot],
    kind: DayGoalCategoryKind,
    day: String,
    db: Database
  ) throws {
    for (index, category) in categories.enumerated() {
      try db.execute(
        sql: """
              INSERT INTO day_goal_categories(
                  day, kind, category_id, category_name, category_color_hex, sort_order
              )
              VALUES (?, ?, ?, ?, ?, ?)
          """,
        arguments: [
          day,
          kind.rawValue,
          category.categoryID,
          category.name,
          category.colorHex,
          index,
        ])
    }
  }
}
