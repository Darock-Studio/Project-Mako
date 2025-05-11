//
//  Models.swift
//  Mako
//
//  Created by Mark Chan on 2025/5/5.
//

import SwiftUI
import NotifKit
import SwiftyJSON
import DarockFoundation
import SDWebImageSwiftUI

struct SuggestionItem: Identifiable {
    var type: SuggestionItemType
    var id: Int
    var name: String
    var picUrl: String
}
enum SuggestionItemType {
    case album
    case song
}

struct Album: Identifiable, Decodable {
    var id: Int64
    var name: String
    var coverImgUrl: String
    var createTime: Date
    var updateTime: Date?
    var trackCount: Int
    var description: String
    var tags: [String]?
    
    enum CodingKeys: CodingKey {
        case id
        case name
        case picUrl
        case coverImgUrl
        case publishTime
        case createTime
        case updateTime
        case trackCount
        case description
        case tags
        case size
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int64.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.description = try container.decode(String.self, forKey: .description)
        if let coverImgUrl = try container.decodeIfPresent(String.self, forKey: .coverImgUrl) {
            self.coverImgUrl = coverImgUrl
            self.createTime = Date(timeIntervalSince1970: Double(try container.decode(Int.self, forKey: .createTime)) / 1000)
            self.updateTime = Date(timeIntervalSince1970: Double(try container.decode(Int.self, forKey: .updateTime)) / 1000)
            self.trackCount = try container.decode(Int.self, forKey: .trackCount)
            self.tags = try container.decodeIfPresent([String].self, forKey: .tags)
        } else {
            self.coverImgUrl = try container.decode(String.self, forKey: .picUrl)
            self.createTime = Date(timeIntervalSince1970: Double(try container.decode(Int.self, forKey: .publishTime)) / 1000)
            self.trackCount = try container.decode(Int.self, forKey: .size)
        }
    }
}

struct Track: Identifiable, Codable {
    var id: Int64
    var name: String
    var artists: [Artist]
    var album: Album
    
    enum CodingKeys: CodingKey {
        case id
        case name
        case ar
        case al
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int64.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.artists = try container.decode([Artist].self, forKey: .ar)
        self.album = try container.decode(Track.Album.self, forKey: .al)
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(artists, forKey: .ar)
        try container.encode(album, forKey: .al)
    }
    
    @ViewBuilder
    var contextActions: some View {
        Section {
            if UserDefaults.standard.bool(forKey: "IsLoggedIn") {
                
            }
        }
        Section {
            Link(destination: URL(string: "https://music.163.com/#/song?id=\(self.id)")!) {
                Label("在浏览器中打开", systemImage: "safari")
            }
            ShareLink("分享歌曲...", item: URL(string: "https://music.163.com/#/song?id=\(self.id)")!)
        }
    }
    
    struct Album: Identifiable, Codable {
        var id: Int
        var name: String
        var picUrl: String
    }
}

struct Artist: Identifiable, Codable {
    var id: Int
    var name: String
    var picUrl: String?
}

struct SearchResults {
    var contentType: ContentType
    
    private var anyResults: [Any] = []
    
    init(type: ContentType, keyword: String) async {
        self.contentType = type
        
        let result = await requestJSON("\(apiBaseURL)/cloudsearch?keywords=\(keyword)&type=\(type.rawValue)", headers: globalRequestHeaders)
        if case let .success(respJson) = result {
            switch type {
            case .song:
                anyResults = getJsonData([Track].self, from: respJson["result"]["songs"].rawString()!) ?? []
            case .album:
                anyResults = getJsonData([Album].self, from: respJson["result"]["albums"].rawString()!) ?? []
            case .artist:
                anyResults = getJsonData([Artist].self, from: respJson["result"]["artists"].rawString()!) ?? []
            case .playlist:
                anyResults = getJsonData([Album].self, from: respJson["result"]["playlists"].rawString()!) ?? []
            case .lyrics:
                break // TODO: Add lyric searching feature
            }
        }
    }
    
    var isEmpty: Bool {
        anyResults.isEmpty
    }
    
    @ViewBuilder var itemsView: some View {
        switch contentType {
        case .song:
            ForEach(anyResults as! [Track]) { track in
                Button(action: {
                    Task {
                        await playTrack(track)
                    }
                }, label: {
                    HStack {
                        WebImage(url: URL(string: track.album.picUrl)) { image in
                            image.resizable()
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray)
                                .redacted(reason: .placeholder)
                        }
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipped()
                        .cornerRadius(3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(track.name)
                                .font(.system(size: 14))
                            Text("歌曲 · \(track.artists.map(\.name).joined(separator: " / "))")
                                .font(.system(size: 12))
                                .foregroundStyle(.gray)
                        }
                    }
                })
            }
        case .album:
            ForEach(anyResults as! [Album]) { album in
                HStack {
                    WebImage(url: URL(string: album.coverImgUrl)) { image in
                        image.resizable()
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray)
                            .redacted(reason: .placeholder)
                    }
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipped()
                    .cornerRadius(3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(album.name)
                            .font(.system(size: 14))
                        Text("专辑")
                            .font(.system(size: 12))
                            .foregroundStyle(.gray)
                    }
                }
            }
        case .artist:
            ForEach(anyResults as! [Artist]) { artist in
                HStack {
                    WebImage(url: URL(string: artist.picUrl!)) { image in
                        image.resizable()
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray)
                            .redacted(reason: .placeholder)
                    }
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipped()
                    .cornerRadius(3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(artist.name)
                            .font(.system(size: 14))
                        Text("艺人")
                            .font(.system(size: 12))
                            .foregroundStyle(.gray)
                    }
                }
            }
        case .playlist:
            ForEach(anyResults as! [Album]) { artist in
                HStack {
                    WebImage(url: URL(string: artist.coverImgUrl)) { image in
                        image.resizable()
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray)
                            .redacted(reason: .placeholder)
                    }
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipped()
                    .cornerRadius(3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(artist.name)
                            .font(.system(size: 14))
                        Text("播放列表")
                            .font(.system(size: 12))
                            .foregroundStyle(.gray)
                    }
                }
            }
        case .lyrics:
            EmptyView()
        }
    }
    
    enum ContentType: Int {
        case song = 1
        case album = 10
        case artist = 100
        case playlist = 1000
        case lyrics = 1006
    }
}

struct NowPlayingInfo: Codable {
    var sourceTrack: Track
    var playURL: String
    var lyrics: [Double: String]?
    var preventAutoPlaying: Bool = false
}

enum PlaybackBehavior: String {
    case pause
    case singleLoop
    case listLoop
}
