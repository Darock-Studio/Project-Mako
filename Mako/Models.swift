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
    
//    private struct PreviewView: View {
//        var body: some View {
//            /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Hello, world!@*/Text("Hello, world!")/*@END_MENU_TOKEN@*/
//        }
//    }
}
enum SuggestionItemType {
    case playlist
    case album
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
    
    var previewView: some View {
        VStack(alignment: .leading) {
            WebImage(url: URL(string: self.album.picUrl)) { image in
                image.resizable()
            } placeholder: {
                Rectangle()
                    .fill(Color.gray)
                    .redacted(reason: .placeholder)
            }
            .scaledToFill()
            .frame(width: screenBounds.width - 100, height: screenBounds.width - 100)
            .clipped()
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.vertical, 5)
            Group {
                Text(self.name)
                    .font(.system(size: 16, weight: .semibold))
                Text(self.artists.map { $0.name }.joined(separator: "/"))
                    .foregroundStyle(.gray)
            }
            .padding(.horizontal)
        }
        .frame(width: screenBounds.width - 70, height: screenBounds.width)
    }
    @ViewBuilder
    var contextActions: some View {
        ContextActionsView(track: self)
    }
    private struct ContextActionsView: View {
        var track: Track
        @State var isFavorited: Bool?
        var body: some View {
            Section {
                if UserDefaults.standard.bool(forKey: "IsLoggedIn") {
                    if let isFavorited {
                        if isFavorited {
                            Button("取消喜欢", systemImage: "star.slash", role: .destructive) {
                                requestJSON("\(apiBaseURL)/like?id=\(track.id)&like=false", headers: globalRequestHeaders) { _, isSuccess in
                                    if !isSuccess {
                                        NKTipper.automaticStyle.present(text: "移除时出错", symbol: "xmark.circle.fill")
                                    }
                                }
                            }
                        } else {
                            Button("喜欢", systemImage: "star") {
                                requestJSON("\(apiBaseURL)/like?id=\(track.id)&like=true", headers: globalRequestHeaders) { _, isSuccess in
                                    if isSuccess {
                                        NKTipper.automaticStyle.present(text: "已添加到收藏", symbol: "checkmark.circle.fill")
                                    } else {
                                        NKTipper.automaticStyle.present(text: "收藏时出错", symbol: "xmark.circle.fill")
                                    }
                                }
                            }
                        }
                    } else {
                        Text("正在载入...")
                            .task {
                                let result = await requestJSON("\(apiBaseURL)/likelist", headers: globalRequestHeaders)
                                if case let .success(respJson) = result, let ids = respJson["ids"].arrayObject as? [Int64] {
                                    isFavorited = ids.contains(track.id)
                                } else {
                                    isFavorited = false
                                }
                            }
                    }
                }
            }
            Section {
                Button("查看评论", systemImage: "text.bubble") {
                    presentCommentsSubject.send(track.id)
                }
            }
            Section {
                if track.artists.count == 1 {
                    Button("转到艺人", systemImage: "music.microphone") {
                        gotoArtistSubject.send(track.artists.first!.id)
                    }
                } else {
                    #if !os(watchOS)
                    Menu("转到艺人", systemImage: "music.microphone") {
                        ForEach(track.artists) { artist in
                            Button(artist.name, systemImage: "person") {
                                gotoArtistSubject.send(artist.id)
                            }
                        }
                    }
                    #else
                    ForEach(track.artists) { artist in
                        Button(artist.name, systemImage: "person") {
                            gotoArtistSubject.send(artist.id)
                        }
                    }
                    #endif
                }
                Button(action: {
                    gotoAlbumSubject.send(Int64(track.album.id))
                }, label: {
                    Image(_internalSystemName: "music.square")
                    Text("转到专辑")
                })
            }
            Section {
                Link(destination: URL(string: "https://music.163.com/#/song?id=\(track.id)")!) {
                    Label("在浏览器中打开", systemImage: "safari")
                }
                ShareLink("分享歌曲...", item: URL(string: "https://music.163.com/#/song?id=\(track.id)")!)
            }
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
struct ArtistDetailed: Identifiable, Decodable {
    var id: Int
    var name: String
    var cover: String
    var avatar: String
    var briefDesc: String
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
                        WebImage(url: URL(string: "\(track.album.picUrl)?param=240y240")) { image in
                            image.resizable()
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray)
                                .redacted(reason: .placeholder)
                        }
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipped()
                        .cornerRadius(5)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(track.name)
                                .font(.system(size: 14))
                            Text("歌曲 · \(track.artists.map(\.name).joined(separator: " / "))")
                                .font(.system(size: 12))
                                .foregroundStyle(.gray)
                        }
                        Spacer()
                        #if !os(watchOS)
                        Menu("", systemImage: "ellipsis") {
                            track.contextActions
                        }
                        .foregroundStyle(Color.primary)
                        #endif
                    }
                })
                .listRowInsets(.init(top: 10, leading: 20, bottom: 10, trailing: 0))
            }
        case .album:
            ForEach(anyResults as! [Album]) { album in
                NavigationLink(destination: { AlbumDetailView(id: album.id, type: .album) }, label: {
                    HStack {
                        WebImage(url: URL(string: "\(album.coverImgUrl)?param=240y240")) { image in
                            image.resizable()
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray)
                                .redacted(reason: .placeholder)
                        }
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipped()
                        .cornerRadius(5)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(album.name)
                                .font(.system(size: 14))
                            Text("专辑")
                                .font(.system(size: 12))
                                .foregroundStyle(.gray)
                        }
                    }
                })
                .listRowInsets(.init(top: 10, leading: 20, bottom: 10, trailing: 20))
            }
        case .artist:
            ForEach(anyResults as! [Artist]) { artist in
                NavigationLink(destination: { ArtistDetailView(id: artist.id) }, label: {
                    HStack {
                        WebImage(url: URL(string: "\(artist.picUrl ?? "")?param=240y240")) { image in
                            image.resizable()
                        } placeholder: {
                            Image(systemName: "music.microphone.circle.fill")
                                .resizable()
                                .font(.system(size: 100))
                                .foregroundStyle(.white, .gray)
                        }
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(artist.name)
                                .font(.system(size: 14))
                            Text("艺人")
                                .font(.system(size: 12))
                                .foregroundStyle(.gray)
                        }
                    }
                })
                .listRowInsets(.init(top: 10, leading: 20, bottom: 10, trailing: 20))
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

struct Comment: Identifiable, Decodable {
    var commentId: Int64
    var content: String
    var time: Date
    var likedCount: Int
    var liked: Bool
    var user: User
    
    enum CodingKeys: CodingKey {
        case commentId
        case content
        case time
        case likedCount
        case liked
        case user
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.commentId = try container.decode(Int64.self, forKey: .commentId)
        self.content = try container.decode(String.self, forKey: .content)
        self.time = Date(timeIntervalSince1970: Double(try container.decode(Int.self, forKey: .time)) / 1000)
        self.likedCount = try container.decode(Int.self, forKey: .likedCount)
        self.liked = try container.decode(Bool.self, forKey: .liked)
        self.user = try container.decode(Comment.User.self, forKey: .user)
    }
    
    var id: Int64 { commentId }
    
    struct User: Decodable {
        var userId: Int
        var nickname: String
        var avatarUrl: String
    }
}

enum AudioQuality: String, CaseIterable, Identifiable {
    case highEfficiency
    case highQuality
    case loseless
    case hiResLoseless
    
    var id: String { self.rawValue }
    
    var localizedName: LocalizedStringKey {
        switch self {
        case .highEfficiency: "高效"
        case .highQuality:    "高质量"
        case .loseless:       "无损"
        case .hiResLoseless:  "高解析度无损"
        }
    }
    var localizedDetail: LocalizedStringKey {
        switch self {
        case .highEfficiency: "HE-AAC，数据用量较低"
        case .highQuality:    "AAC 256 kbps"
        case .loseless:       "ALAC（最高24位/48kHZ）"
        case .hiResLoseless:  "ALAC（最高24位/192kHZ）"
        }
    }
    var requestParameter: String {
        switch self {
        case .highEfficiency: "higher"
        case .highQuality:    "exhigh"
        case .loseless:       "lossless"
        case .hiResLoseless:  "hires"
        }
    }
}
