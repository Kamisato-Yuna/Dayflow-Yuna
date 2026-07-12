import Foundation
import GRDB

extension StorageManager {
  func scanCategoryNameMigration(mappings: [CategoryNameMapping]) throws
    -> CategoryMigrationScanResult
  {
    let enabledMappings = CategoryAliasResolver.enabledMappings(mappings)
    guard enabledMappings.isEmpty == false else {
      return CategoryMigrationScanResult(entries: [])
    }

    return try timedRead("scanCategoryNameMigration") { db in
      var entries: [CategoryMigrationScanEntry] = []
      for mapping in enabledMappings {
        if let timelineEntry = try scanTimelineCards(mapping: mapping, db: db) {
          entries.append(timelineEntry)
        }
        if let dayGoalEntry = try scanDayGoalCategories(mapping: mapping, db: db) {
          entries.append(dayGoalEntry)
        }
      }
      return CategoryMigrationScanResult(entries: entries)
    }
  }

  func performCategoryNameMigration(mappings: [CategoryNameMapping]) throws
    -> CategoryMigrationResult
  {
    let enabledMappings = CategoryAliasResolver.enabledMappings(mappings)
    let scanResult = try scanCategoryNameMigration(mappings: enabledMappings)
    let backupURL = try createCategoryMigrationBackup()

    var updatedTimelineRows = 0
    var updatedDayGoalRows = 0

    try timedWrite("performCategoryNameMigration") { db in
      try db.inTransaction {
        for mapping in enabledMappings {
          updatedTimelineRows += try countTimelineCards(source: mapping.source, db: db)
          try db.execute(
            sql: """
                  UPDATE timeline_cards
                  SET category = ?
                  WHERE category = ?
                    AND is_deleted = 0
              """,
            arguments: [mapping.target, mapping.source]
          )

          updatedDayGoalRows += try countDayGoalCategories(source: mapping.source, db: db)
          try db.execute(
            sql: """
                  UPDATE day_goal_categories
                  SET category_name = ?
                  WHERE category_name = ?
              """,
            arguments: [mapping.target, mapping.source]
          )
        }
        return .commit
      }
    }

    return CategoryMigrationResult(
      scanResult: scanResult,
      updatedTimelineCardRows: updatedTimelineRows,
      updatedDayGoalCategoryRows: updatedDayGoalRows,
      backupURL: backupURL
    )
  }

  private func createCategoryMigrationBackup() throws -> URL {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd_HHmmss"
    let timestamp = formatter.string(from: Date())
    let backupURL = backupsDir.appendingPathComponent("category-migration-\(timestamp).sqlite")
    let destination = try DatabaseQueue(path: backupURL.path)
    try db.backup(to: destination)
    return backupURL
  }

  private func scanTimelineCards(
    mapping: CategoryNameMapping,
    db: Database
  ) throws -> CategoryMigrationScanEntry? {
    guard
      let row = try Row.fetchOne(
        db,
        sql: """
              SELECT COUNT(*) AS row_count,
                     COALESCE(SUM(MAX(end_ts - start_ts, 0)), 0) AS duration_seconds,
                     MIN(day) AS first_day,
                     MAX(day) AS last_day
              FROM timeline_cards
              WHERE category = ?
                AND is_deleted = 0
          """,
        arguments: [mapping.source]
      )
    else {
      return nil
    }

    let rowCount: Int = row["row_count"] ?? 0
    guard rowCount > 0 else { return nil }
    let durationSeconds: Int = row["duration_seconds"] ?? 0

    return CategoryMigrationScanEntry(
      tableName: "timeline_cards",
      source: mapping.source,
      target: mapping.target,
      rowCount: rowCount,
      totalDurationMinutes: Int((Double(durationSeconds) / 60.0).rounded()),
      firstDay: row["first_day"],
      lastDay: row["last_day"]
    )
  }

  private func scanDayGoalCategories(
    mapping: CategoryNameMapping,
    db: Database
  ) throws -> CategoryMigrationScanEntry? {
    guard
      let row = try Row.fetchOne(
        db,
        sql: """
              SELECT COUNT(*) AS row_count,
                     MIN(day) AS first_day,
                     MAX(day) AS last_day
              FROM day_goal_categories
              WHERE category_name = ?
          """,
        arguments: [mapping.source]
      )
    else {
      return nil
    }

    let rowCount: Int = row["row_count"] ?? 0
    guard rowCount > 0 else { return nil }

    return CategoryMigrationScanEntry(
      tableName: "day_goal_categories",
      source: mapping.source,
      target: mapping.target,
      rowCount: rowCount,
      totalDurationMinutes: 0,
      firstDay: row["first_day"],
      lastDay: row["last_day"]
    )
  }

  private func countTimelineCards(source: String, db: Database) throws -> Int {
    try Int.fetchOne(
      db,
      sql: """
            SELECT COUNT(*)
            FROM timeline_cards
            WHERE category = ?
              AND is_deleted = 0
        """,
      arguments: [source]
    ) ?? 0
  }

  private func countDayGoalCategories(source: String, db: Database) throws -> Int {
    try Int.fetchOne(
      db,
      sql: """
            SELECT COUNT(*)
            FROM day_goal_categories
            WHERE category_name = ?
        """,
      arguments: [source]
    ) ?? 0
  }
}
