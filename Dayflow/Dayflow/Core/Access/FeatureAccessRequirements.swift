import Foundation

enum FeatureAccessRequirements {
  static let batchDurationMinutes = 15

  static let dailyRequiredHours = 5
  static let chatRequiredHours = 10

  static var dailyRequiredBatch数量: Int {
    requiredBatch数量(forHours: dailyRequiredHours)
  }

  static var chatRequiredBatch数量: Int {
    requiredBatch数量(forHours: chatRequiredHours)
  }

  static func completedBatch数量() -> Int {
    StorageManager.shared.countCompletedAnalysisBatchesForWeeklyAccess()
  }

  static func hasRequiredBatches(_ completedBatch数量: Int, requiredBatch数量: Int) -> Bool {
    completedBatch数量 >= requiredBatch数量
  }

  static func progressText(completedBatch数量: Int, requiredHours: Int) -> String {
    let cappedBatch数量 = min(
      max(completedBatch数量, 0), requiredBatch数量(forHours: requiredHours))
    let minutes = cappedBatch数量 * batchDurationMinutes
    let hours = minutes / 60
    let remainingMinutes = minutes % 60

    if minutes == 0 {
      return "0h / \(requiredHours)h"
    }

    if hours == 0 {
      return "\(remainingMinutes)m / \(requiredHours)h"
    }

    if remainingMinutes == 0 {
      return "\(hours)h / \(requiredHours)h"
    }

    return "\(hours)h \(remainingMinutes)m / \(requiredHours)h"
  }

  private static func requiredBatch数量(forHours hours: Int) -> Int {
    (hours * 60) / batchDurationMinutes
  }
}
