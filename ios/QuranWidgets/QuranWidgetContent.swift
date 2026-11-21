import SwiftUI
import WidgetKit

private let groupID = "group.com.coreinfinite.quran.widgets"

struct WidgetContent: Decodable {
  let start: Int64
  let label: String
  let heading: String
  let path: String
  var detail: String?
  var footer: String?
  var arabic: String?
  var footerPath: String?
  var prayerPhase: String?
  var progress: Double?
  var date: Date { Date(timeIntervalSince1970: Double(start) / 1_000) }
}

private struct WidgetSnapshot: Decodable {
  let language: String
  let dark: Bool
  let widgets: [String: [WidgetContent]]

  static func load() -> WidgetSnapshot? {
    guard
      let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID),
      let data = try? Data(contentsOf: url.appendingPathComponent("widgets.json"))
    else { return nil }
    return try? JSONDecoder().decode(Self.self, from: data)
  }
}

enum Kind: String {
  case prayer, reading, ayah, azkar, fasting, hifz, goal

  var title: String {
    switch self {
    case .prayer: return "Next Prayer"
    case .reading: return "Continue Reading"
    case .ayah: return "Ayah of the Day"
    case .azkar: return "Morning & Evening Azkar"
    case .fasting: return "Fasting"
    case .hifz: return "Hifz Review"
    case .goal: return "Daily Reading Goal"
    }
  }

  var families: [WidgetFamily] {
    switch self {
    case .prayer: return [.systemSmall, .systemMedium]
    case .ayah, .fasting: return [.systemMedium]
    default: return [.systemSmall]
    }
  }

  var description: String {
    switch self {
    case .prayer: return "See the next prayer time and your prayer location."
    case .reading: return "Resume reading at the ayah where you stopped."
    case .ayah: return "Read a daily ayah in Arabic and translation."
    case .azkar: return "Open morning or evening remembrance."
    case .fasting: return "See Sehri and Iftar times and open your fasting journal."
    case .hifz: return "See how many ayahs are due for review."
    case .goal: return "See how much you have read toward today’s goal."
    }
  }

  var sample: WidgetContent {
    switch self {
    case .prayer:
      return WidgetContent(start: 0, label: title, heading: "Asr", path: "/widget-prayer",
        detail: "4:26 PM", footer: "Karachi")
    case .reading:
      return WidgetContent(start: 0, label: title, heading: "Al-Kahf", path: "/", detail: "Ayah 24", progress: 0.22)
    case .ayah:
      return WidgetContent(start: 0, label: title, heading: "Ash-Sharh (94:5)", path: "/",
        detail: "So, surely with hardship comes ease.", arabic: "فَإِنَّ مَعَ الْعُسْرِ يُسْرًا")
    case .azkar:
      return WidgetContent(start: 0, label: title, heading: "Morning Azkar", path: "/", detail: "Open collection")
    case .fasting:
      return WidgetContent(start: 0, label: title, heading: "Fasting times", path: "/",
        detail: "Sehri ends 5:12 AM\nIftar 5:44 PM", footer: "Fasting journal")
    case .hifz:
      return WidgetContent(start: 0, label: title, heading: "5", path: "/", detail: "Due for review")
    case .goal:
      return WidgetContent(start: 0, label: title, heading: "7 / 10", path: "/", detail: "ayahs", progress: 0.7)
    }
  }

  var setup: WidgetContent {
    WidgetContent(start: 0, label: title, heading: "Open Quran to set up", path: "/")
  }
}

struct QuranEntry: TimelineEntry {
  let date: Date
  let content: WidgetContent
  var dark = false
  var rtl = false
  var isSetup = false
}

struct QuranProvider: TimelineProvider {
  let kind: Kind

  func placeholder(in context: Context) -> QuranEntry {
    QuranEntry(date: .now, content: kind.sample)
  }

  func getSnapshot(in context: Context, completion: @escaping (QuranEntry) -> Void) {
    if context.isPreview {
      completion(placeholder(in: context))
      return
    }
    completion(entries().first ?? QuranEntry(date: .now, content: kind.setup, isSetup: true))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<QuranEntry>) -> Void) {
    let scheduled = entries()
    completion(Timeline(
      entries: scheduled.isEmpty ? [QuranEntry(date: .now, content: kind.setup, isSetup: true)] : scheduled,
      policy: .never
    ))
  }

  private func entries() -> [QuranEntry] {
    let now = Date()
    guard
      let snapshot = WidgetSnapshot.load(),
      let contents = snapshot.widgets[kind.rawValue],
      let current = contents.last(where: { $0.date <= now })
    else { return [] }
    let rtl = snapshot.language == "ar" || snapshot.language == "ur"
    return [QuranEntry(date: now, content: current, dark: snapshot.dark, rtl: rtl)] +
      contents.lazy.filter { $0.date > now }.map {
        QuranEntry(date: $0.date, content: $0, dark: snapshot.dark, rtl: rtl)
      }
  }
}
