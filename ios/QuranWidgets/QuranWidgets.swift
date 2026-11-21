import SwiftUI
import WidgetKit

private struct QuranWidgetView: View {
  @Environment(\.widgetFamily) private var family
  @Environment(\.layoutDirection) private var systemDirection
  let kind: Kind
  let entry: QuranEntry

  private var paper: Bool { [.reading, .ayah, .goal].contains(kind) }
  private var ink: Color { paper && !entry.dark ? Color(red: 0.13, green: 0.22, blue: 0.19) : .white }
  private var secondary: Color {
    paper && !entry.dark ? Color(red: 0.26, green: 0.34, blue: 0.29) : Color(red: 0.95, green: 0.91, blue: 0.86)
  }
  private var direction: LayoutDirection { entry.isSetup ? systemDirection : (entry.rtl ? .rightToLeft : .leftToRight) }
  private var symbol: String {
    switch kind {
    case .prayer: return "sun.horizon"
    case .reading: return "book"
    case .ayah: return "text.book.closed"
    case .azkar: return "sunrise"
    case .fasting: return "moon"
    case .hifz: return "graduationcap"
    case .goal: return "scope"
    }
  }
  private var artwork: String {
    if kind == .prayer { return "widget_prayer_" + (entry.content.prayerPhase ?? "dhuhr") }
    if paper && entry.dark { return "widget_" + kind.rawValue + "_dark" }
    if kind == .fasting && direction == .rightToLeft { return "widget_" + kind.rawValue + "_rtl" }
    return "widget_" + kind.rawValue
  }

  private var background: some View {
    GeometryReader { geometry in
      ZStack {
        (paper && !entry.dark ? Color(red: 0.93, green: 0.90, blue: 0.83) : Color(red: 0.13, green: 0.21, blue: 0.18))
        if let url = Bundle.main.url(forResource: artwork, withExtension: "jpg", subdirectory: "drawable-nodpi"),
           let image = UIImage(contentsOfFile: url.path) {
          Image(uiImage: image).resizable().scaledToFill()
        }
      }
      .frame(width: geometry.size.width, height: geometry.size.height)
      .clipped()
    }.accessibilityHidden(true)
  }

  var body: some View {
    if #available(iOS 17.0, *) {
      content.containerBackground(for: .widget) { background }
    } else {
      content.padding(13).background(background)
    }
  }

  private var content: some View {
    let value = entry.content
    let mediumPrayer = kind == .prayer && family == .systemMedium
    let prayerTime = kind == .prayer && value.detail != nil
    let metric = (kind == .hifz || kind == .goal) && value.heading.first?.isNumber == true
    return GeometryReader { geometry in
      VStack(alignment: .leading, spacing: 2) {
        HStack(spacing: 5) {
          Image(systemName: symbol).accessibilityHidden(true)
          (entry.isSetup ? Text(LocalizedStringKey(value.label)) : Text(value.label))
            .lineLimit(2).minimumScaleFactor(0.85)
        }
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(kind == .ayah ? secondary : .white)
        Spacer(minLength: 2)
        VStack(alignment: .leading, spacing: 2) {
          if let arabic = value.arabic {
            Text(arabic).font(.system(size: 22)).lineLimit(2)
              .frame(maxWidth: .infinity, alignment: .leading)
              .environment(\.layoutDirection, .rightToLeft)
          } else {
            (entry.isSetup ? Text(LocalizedStringKey(value.heading)) : Text(value.heading))
              .font(.system(size: metric ? 30 : prayerTime ? 18 : 21, weight: .semibold))
              .lineLimit(2).minimumScaleFactor(0.78)
          }
          if let detail = value.detail {
            Text(detail)
              .font(.system(size: prayerTime ? (mediumPrayer ? 32 : 28) : 13, weight: prayerTime ? .semibold : .regular))
              .lineLimit(value.arabic == nil ? 2 : 1)
              .foregroundStyle(prayerTime ? ink : secondary)
          }
          if let progress = value.progress {
            GeometryReader { track in
              ZStack(alignment: .leading) {
                Capsule().fill(ink.opacity(0.18))
                Capsule().fill(entry.dark ? Color(red: 0.69, green: 0.86, blue: 0.78) : Color(red: 0.21, green: 0.45, blue: 0.39))
                  .frame(width: track.size.width * max(0, min(progress, 1)))
              }
            }
            .frame(height: 4).padding(.top, 3)
            .accessibilityLabel(Text(progress, format: .percent))
          }
          if mediumPrayer, let location = value.footer {
            HStack(spacing: 4) {
              Image(systemName: "mappin").accessibilityHidden(true)
              Text(location).lineLimit(1)
            }
            .font(.system(size: 13, weight: .semibold)).foregroundStyle(secondary).padding(.top, 1)
          } else if let footer = value.arabic == nil ? value.footer : value.heading {
            linkedText(footer, path: value.footerPath, size: 11, weight: .semibold, lines: 1)
              .foregroundStyle(secondary).padding(.top, 1)
          }
        }
        .frame(width: kind == .fasting ? geometry.size.width * 0.65 : geometry.size.width, alignment: .leading)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    .foregroundStyle(ink)
    .environment(\.layoutDirection, direction)
    .widgetURL(url(value.path))
  }

  @ViewBuilder
  private func linkedText(_ value: String, path: String?, size: CGFloat, weight: Font.Weight, lines: Int) -> some View {
    let label = Text(value).font(.system(size: size, weight: weight)).lineLimit(lines)
    if family == .systemMedium, let path, let destination = url(path) {
      Link(destination: destination) { label }
    } else {
      label
    }
  }

  private func url(_ path: String) -> URL? { URL(string: "quranwidget://open\(path)") }
}

private struct QuranWidget: Widget {
  let kind: Kind

  init() { kind = .prayer }

  init(kind: Kind) { self.kind = kind }

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind.rawValue, provider: QuranProvider(kind: kind)) {
      QuranWidgetView(kind: kind, entry: $0)
    }
    .configurationDisplayName(LocalizedStringKey(kind.title))
    .description(LocalizedStringKey(kind.description))
    .supportedFamilies(kind.families)
  }
}

@main
struct QuranWidgets: WidgetBundle {
  var body: some Widget {
    QuranWidget(kind: .prayer)
    QuranWidget(kind: .reading)
    QuranWidget(kind: .ayah)
    QuranWidget(kind: .azkar)
    QuranWidget(kind: .fasting)
    QuranWidget(kind: .hifz)
    QuranWidget(kind: .goal)
  }
}
