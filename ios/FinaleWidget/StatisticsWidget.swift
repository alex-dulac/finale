import WidgetKit
import SwiftUI
import Intents

struct StatisticsProvider: IntentTimelineProvider {
    private func createEntry(for configuration: StatisticsConfigurationIntent, in context: Context, completion: @escaping (StatisticsEntry) -> Void) {
        if configuration.username == nil || configuration.username!.isEmpty {
            completion(StatisticsEntry(date: Date(), numScrobbles: nil, numTracks: nil, numArtists: nil, numAlbums: nil, configuration: configuration))
            return
        }
        
        var numScrobbles: Int?
        var numTracks: Int?
        var numArtists: Int?
        var numAlbums: Int?
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        GetRecentTracksRequest(username: configuration.username!, period: configuration.period).getTotalCount { response in
            numScrobbles = response
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        GetTopTracksRequest(username: configuration.username!, period: configuration.period).getTotalCount { response in
            numTracks = response
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        GetTopArtistsRequest(username: configuration.username!, period: configuration.period).getTotalCount { response in
            numArtists = response
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        GetTopAlbumsRequest(username: configuration.username!, period: configuration.period).getTotalCount { response in
            numAlbums = response
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(StatisticsEntry(date: Date(), numScrobbles: numScrobbles, numTracks: numTracks, numArtists: numArtists, numAlbums: numAlbums, configuration: configuration))
        }
    }
    
    func placeholder(in context: Context) -> StatisticsEntry {
        StatisticsEntry(date: Date(), numScrobbles: 0, numTracks: 0, numArtists: 0, numAlbums: 0, configuration: StatisticsConfigurationIntent())
    }
    
    func getSnapshot(for configuration: StatisticsConfigurationIntent, in context: Context, completion: @escaping (StatisticsEntry) -> ()) {
        createEntry(for: configuration, in: context, completion: completion)
    }
    
    func getTimeline(for configuration: StatisticsConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        createEntry(for: configuration, in: context) { entry in
            let timeline = Timeline(entries: [entry], policy: .atEnd)
            completion(timeline)
        }
    }
}

struct StatisticsEntry: TimelineEntry {
    let date: Date
    let numScrobbles: Int?
    let numTracks: Int?
    let numArtists: Int?
    let numAlbums: Int?
    let configuration: StatisticsConfigurationIntent
}

struct StatisticsEntryView : View {
    @Environment(\.widgetFamily) var family: WidgetFamily
    var entry: StatisticsProvider.Entry
    
    @ViewBuilder
    var body: some View {
        switch family {
        case .systemSmall: StatisticsWidgetEntryViewSmall(entry: entry)
        default: StatisticsWidgetEntryViewLarge(entry: entry)
        }
    }
}

struct StatisticsWidgetEntryViewSmall : View {
    var entry: StatisticsProvider.Entry
    
    var body: some View {
        ZStack {
            widgetBackgroundGradient
            if entry.configuration.username?.isEmpty ?? true {
                VStack {
                    Image("FinaleIconWhite")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .colorMultiply(Color("AccentColor"))
                    Text("Please enter your username in the widget settings.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color("AccentColor"))
                }
                .padding()
            } else {
                Scoreboard(alignment: .vertical, tiles: [
                    ScoreTileModel(title: "Scrobbles", value: entry.numScrobbles, icon: "Playlist"),
                    ScoreTileModel(title: "Artists", value: entry.numArtists, icon: "Artist"),
                    ScoreTileModel(title: "Albums", value: entry.numAlbums, icon: "Album"),
                    ScoreTileModel(title: "Tracks", value: entry.numTracks, icon: "MusicNote"),
                ])
                    .padding()
            }
        }
    }
}

struct StatisticsWidgetEntryViewLarge : View {
    var entry: StatisticsProvider.Entry
    
    var body: some View {
        FinaleWidgetLarge(title: "Last.fm Stats", period: entry.configuration.period, username: entry.configuration.username) {
            Scoreboard(alignment: .horizontal, tiles: [
                ScoreTileModel(title: "Scrobbles", value: entry.numScrobbles, icon: "Playlist"),
                ScoreTileModel(title: "Artists", value: entry.numArtists, icon: "Artist"),
                ScoreTileModel(title: "Albums", value: entry.numAlbums, icon: "Album"),
                ScoreTileModel(title: "Tracks", value: entry.numTracks, icon: "MusicNote"),
            ])
        }
    }
}

struct StatisticsWidget: Widget {
    let kind: String = "StatisticsWidget"
    
    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: StatisticsConfigurationIntent.self, provider: StatisticsProvider()) { entry in
            StatisticsEntryView(entry: entry)
        }
        .configurationDisplayName("Statistics")
        .description("Your statistics for a given period.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct StatisticsWidget_Previews: PreviewProvider {
    static var previews: some View {
        StatisticsEntryView(entry: StatisticsEntry(date: Date(), numScrobbles: 0, numTracks: 0, numArtists: 0, numAlbums: 0, configuration: StatisticsConfigurationIntent()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
