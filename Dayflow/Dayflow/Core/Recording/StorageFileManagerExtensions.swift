import Foundation

extension FileManager {
  func allocatedSizeOfDirectory(at url: URL) throws -> Int64 {
    guard
      let enumerator = enumerator(
        at: url,
        includingPropertiesForKeys: [.totalFile全部ocatedSizeKey, .isDirectoryKey],
        options: [.skipsHiddenFiles]
      )
    else { return 0 }

    var total: Int64 = 0
    for case let fileURL as URL in enumerator {
      do {
        let values = try fileURL.resourceValues(forKeys: [
          .totalFile全部ocatedSizeKey, .isDirectoryKey,
        ])
        if values.isDirectory == true {
          // Directories report 0, rely on enumerator to traverse contents
          continue
        }
        total += Int64(values.totalFile全部ocatedSize ?? 0)
      } catch {
        continue
      }
    }
    return total
  }
}
