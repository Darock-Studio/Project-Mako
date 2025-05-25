//
//  AlbumDetailView.swift
//  Mako
//
//  Created by Mark Chan on 2025/5/5.
//

import SwiftUI
import DarockUI
import SwiftyJSON
import DarockFoundation
import SDWebImageSwiftUI
@_spi(Advanced) import SwiftUIIntrospect

struct AlbumDetailView: View {
    var id: Int64
    var type: AlbumType = .playlist
    @State var album: Album?
    @State var tracks: [Track]?
    @State var workTitleHeight: CGFloat = 0
    @State var scrollObservation: NSKeyValueObservation?
    @State var isShowingNavigationTitle = false
    @State var relatedAlbums = [SuggestionItem]()
    @State var relatedArtistName = ""
    var body: some View {
        Group {
            if let album {
                ifContainer({
                    #if !os(watchOS)
                    true
                    #else
                    false
                    #endif
                }()) { content in
                    List { content }
                } false: { content in
                    TabView {
                        content
                    }
                    #if !os(iOS)
                    .tabViewStyle(.verticalPage)
                    #endif
                } containing: {
                    VStack {
                        WebImage(url: URL(string: album.coverImgUrl)) { image in
                            image.resizable()
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray)
                                .redacted(reason: .placeholder)
                        }
                        .scaledToFill()
                        #if !os(watchOS)
                        .frame(width: 250, height: 250)
                        #else
                        .frame(width: 100, height: 100)
                        #endif
                        .clipped()
                        .cornerRadius(8)
                        .shadow(radius: 15, x: 3, y: 3)
                        #if !os(watchOS)
                        Text(album.name)
                            .font(.system(size: 18, weight: .semibold))
                            .multilineTextAlignment(.center)
                            .background {
                                GeometryReader { geometry in
                                    Color.clear
                                        .onAppear {
                                            workTitleHeight = geometry.size.height
                                        }
                                }
                            }
                            .padding([.top, .horizontal])
                        if let artists = album.artists {
                            if artists.count == 1 {
                                Button(action: {
                                    gotoArtistSubject.send(artists.first!.id)
                                }, label: {
                                    Text(artists.first!.name)
                                        .font(.system(size: 18, weight: .medium))
                                })
                                .buttonStyle(.borderless)
                            } else {
                                Menu {
                                    ForEach(artists) { artist in
                                        Button(action: {
                                            gotoArtistSubject.send(artist.id)
                                        }, label: {
                                            Label(artist.name, systemImage: "music.microphone")
                                        })
                                    }
                                } label: {
                                    Text("\(artists.first!.name) 等\(artists.count)位艺人")
                                        .font(.system(size: 18, weight: .medium))
                                        .multilineTextAlignment(.center)
                                }
                            }
                        }
                        if let tags = album.tags {
                            Menu {
                                ForEach(tags, id: \.self) { tag in
                                    Button(action: {
                                        performSearchSubject.send(tag)
                                    }, label: {
                                        Label(tag, systemImage: "magnifyingglass")
                                    })
                                }
                            } label: {
                                Text(tags.joined(separator: " · "))
                                    .font(.system(size: 11, weight: .semibold))
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(.gray)
                            }
                            .padding([.bottom, .horizontal])
                        }
                        HStack {
                            Button(action: {
                                if let tracks {
                                    PlaylistManager.shared.replace(with: tracks)
                                }
                            }, label: {
                                HStack {
                                    Image(systemName: "play.fill")
                                    Text("播放")
                                }
                                .foregroundStyle(.accent)
                                .centerAligned()
                                .padding(.vertical, 5)
                            })
                            .buttonStyle(.bordered)
                        }
                        Divider()
                            .padding(.horizontal, -50)
                            .offset(y: 10)
                        #else
                        Spacer()
                        #endif
                    }
                    .centerAligned()
                    #if !os(watchOS)
                    .listRowSeparator(.hidden)
                    #else
                    .toolbar {
                        ToolbarItemGroup(placement: .bottomBar) {
                            Button(action: {
                                if let tracks {
                                    PlaylistManager.shared.replace(with: tracks)
                                }
                            }, label: {
                                Image(systemName: "play.fill")
                            })
                            VStack {
                                MarqueeText(text: album.name, font: .systemFont(ofSize: 14, weight: .semibold), leftFade: 5, rightFade: 5, startDelay: 4, alignment: .center)
                                if let artists = album.artists {
                                    MarqueeText(text: {
                                        if artists.count == 1 {
                                            return artists.first!.name
                                        } else {
                                            return artists.map { $0.name }.joined(separator: "/")
                                        }
                                    }(), font: .systemFont(ofSize: 14, weight: .semibold), leftFade: 5, rightFade: 5, startDelay: 4, alignment: .center)
                                    .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    #endif
                    if let tracks {
                        ifContainer({
                            #if !os(watchOS)
                            true
                            #else
                            false
                            #endif
                        }()) { content in
                            content
                        } false: { content in
                            List {
                                content
                            }
                        } containing: {
                            ForEach(0..<tracks.count, id: \.self) { i in
                                Button(action: {
                                    Task {
                                        await playTrack(tracks[i])
                                    }
                                }, label: {
                                    HStack {
                                        if type == .playlist {
                                            WebImage(url: URL(string: "\(tracks[i].album.picUrl)?param=150y150")) { image in
                                                image.resizable()
                                            } placeholder: {
                                                Rectangle()
                                                    .fill(Color.gray)
                                                    .redacted(reason: .placeholder)
                                            }
                                            .scaledToFill()
                                            #if !os(watchOS)
                                            .frame(width: 50, height: 50)
                                            #else
                                            .frame(width: 35, height: 35)
                                            #endif
                                            .clipped()
                                            .cornerRadius(3)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(tracks[i].name)
                                                    .font(.system(size: 14))
                                                Text(tracks[i].artists.map(\.name).joined(separator: " / "))
                                                    .font(.system(size: 12))
                                                    .foregroundStyle(.gray)
                                            }
                                            .lineLimit(1)
                                        } else {
                                            Text(String(i + 1))
                                                .font(.system(size: 14))
                                                .foregroundStyle(.gray)
                                                .frame(width: 20)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(tracks[i].name)
                                                    .font(.system(size: 14))
                                                if let _artists = album.artists, _artists.count > 1 {
                                                    Text(tracks[i].artists.map(\.name).joined(separator: " / "))
                                                        .font(.system(size: 12))
                                                        .foregroundStyle(.gray)
                                                }
                                            }
                                            .lineLimit(1)
                                        }
                                        Spacer()
//                                        if !isDownloaded,
//                                           let _progress = downloadProgress,
//                                           _progress < 1,
//                                           let individualDownloadProgresses,
//                                           let progress = individualDownloadProgresses[track] {
//                                            Spacer()
//                                            if progress < 1 {
//                                                Gauge(value: progress, label: {})
//                                                    .gaugeStyle(.accessoryCircularCapacity)
//                                                    .tint(.accentColor)
//                                                    .scaleEffect(0.3)
//                                                    .frame(width: 20, height: 20)
//                                                    .animation(.smooth, value: progress)
//                                            } else {
//                                                Image(systemName: "checkmark.circle.fill")
//                                                    .font(.system(size: 16))
//                                                    .foregroundStyle(.gray)
//                                            }
//                                        }
                                        #if !os(watchOS)
                                        Menu("", systemImage: "ellipsis") {
                                            tracks[i].contextActions
                                        }
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color.primary)
                                        #endif
                                    }
                                })
                                #if os(watchOS)
                                .contextMenu {
                                    tracks[i].contextActions
                                }
                                #else
                                .listRowInsets(.init(top: 5, leading: 20, bottom: 5, trailing: 0))
                                #endif
                            }
                        }
                    } else {
                        ProgressView()
                            .centerAligned()
                    }
                    #if !os(watchOS)
                    HStack {
                        VStack(alignment: .leading) {
                            Text({
                                let df = DateFormatter()
                                df.dateStyle = .medium
                                df.timeStyle = .none
                                return df.string(from: album.createTime)
                            }())
                            Text("\(album.trackCount)个项目")
                        }
                        .font(.system(size: 14))
                        .foregroundStyle(.gray)
                        Spacer()
                    }
                    .padding(.vertical)
                    if !relatedAlbums.isEmpty {
                        VStack(alignment: .leading) {
                            Text(type == .playlist ? "你可能也喜欢" : "更多\(relatedArtistName)的作品")
                                .font(.system(size: 22, weight: .bold))
                                .padding(.horizontal)
                            ItemListView(items: relatedAlbums)
                        }
                        .padding(.vertical)
                        .listRowBackground(Color(UIColor.secondarySystemBackground))
                        .listRowInsets(.init(top: 0, leading: 10, bottom: 0, trailing: 0))
                        .listRowSeparator(.hidden)
                    }
                    Spacer()
                        .frame(height: 70)
                        .listRowSeparator(.hidden)
                    #endif
                }
                #if os(iOS)
                .listStyle(.plain)
                .introspect(.scrollView, on: .iOS(.v18...)) { scrollView in
                    scrollObservation = scrollView.observe(\.contentOffset, options: .new) { _, value in
                        let scrollOffset = value.newValue ?? .init()
                        DispatchQueue.main.async {
                            isShowingNavigationTitle = scrollOffset.y - workTitleHeight > 220
                        }
                    }
                }
                #endif
            } else {
                ProgressView()
                    .controlSize(.large)
            }
        }
        .navigationTitle(isShowingNavigationTitle ? (album?.name ?? "") : "")
        .navigationBarTitleDisplayMode(.inline)
        .withNowPlayingButton()
        .subjectNavigatable()
//        .toolbar {
//            if let work {
//                ToolbarItemGroup(placement: .topBarTrailing) {
//                    Menu {
//                        work.contextActions
//                    } label: {
//                        Image(systemName: "ellipsis")
//                            .padding(5)
//                    }
//                    .menuStyle(.button)
//                    .buttonStyle(.bordered)
//                    .buttonBorderShape(.circle)
//                    .padding(.horizontal, -10)
//                }
//            }
//        }
        .onAppear {
            refresh()
        }
    }
    
    func refresh() {
        if type == .playlist {
            requestJSON("\(apiBaseURL)/playlist/detail?id=\(id)", headers: globalRequestHeaders) { respJson, isSuccess in
                if isSuccess {
                    album = getJsonData(Album.self, from: respJson["playlist"].rawString()!)
                }
            }
            requestJSON("\(apiBaseURL)/playlist/track/all?id=\(id)", headers: globalRequestHeaders) { respJson, isSuccess in
                if isSuccess {
                    tracks = getJsonData([Track].self, from: respJson["songs"].rawString()!)
                }
            }
            requestJSON("\(apiBaseURL)/related/playlist?id=\(id)", headers: globalRequestHeaders) { respJson, isSuccess in
                if isSuccess {
                    relatedAlbums.removeAll()
                    for album in respJson["playlists"] {
                        relatedAlbums.append(.init(type: .playlist, id: Int(album.1["id"].stringValue)!, name: album.1["name"].stringValue, picUrl: album.1["coverImgUrl"].stringValue))
                    }
                }
            }
        } else {
            requestJSON("\(apiBaseURL)/album?id=\(id)", headers: globalRequestHeaders) { respJson, isSuccess in
                if isSuccess {
                    album = getJsonData(Album.self, from: respJson["album"].rawString()!)
                    tracks = getJsonData([Track].self, from: respJson["songs"].rawString()!)
                    if let artistID = respJson["album"]["artists"][0]["id"].int {
                        relatedArtistName = respJson["album"]["artists"][0]["name"].stringValue
                        requestJSON("\(apiBaseURL)/artist/album?id=\(artistID)", headers: globalRequestHeaders) { respJson, isSuccess in
                            if isSuccess {
                                relatedAlbums.removeAll()
                                for album in respJson["hotAlbums"] {
                                    relatedAlbums.append(.init(type: .album, id: Int(album.1["id"].stringValue)!, name: album.1["name"].stringValue, picUrl: album.1["picUrl"].stringValue))
                                }
                            }
                        }
                    }
                }
            }
            
        }
    }
    
    enum AlbumType {
        case playlist
        case album
    }
}
