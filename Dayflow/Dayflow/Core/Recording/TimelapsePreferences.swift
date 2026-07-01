import Foundation

enum TimelapsePreferences {
  static let save全部TimelapsesToDiskKey = "save全部TimelapsesToDisk"

  static var save全部TimelapsesToDisk: Bool {
    get {
      UserDefaults.standard.object(forKey: save全部TimelapsesToDiskKey) as? Bool ?? false
    }
    set {
      UserDefaults.standard.set(newValue, forKey: save全部TimelapsesToDiskKey)
    }
  }
}
