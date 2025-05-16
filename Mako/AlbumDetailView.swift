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
                List {
                    VStack {
                        WebImage(url: URL(string: album.coverImgUrl)) { image in
                            image.resizable()
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray)
                                .redacted(reason: .placeholder)
                        }
                        .scaledToFill()
                        .frame(width: 220, height: 220)
                        .clipped()
                        .cornerRadius(8)
                        .shadow(radius: 15, x: 3, y: 3)
                        Text(album.name)
                            .font(.system(size: 16, weight: .semibold))
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
                        #if !os(watchOS)
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
                        #endif
                    }
                    .centerAligned()
                    #if !os(watchOS)
                    .listRowSeparator(.hidden, edges: .top)
                    #endif
                    if let tracks {
                        ForEach(tracks) { track in
                            Button(action: {
                                Task {
                                    await playTrack(track)
                                }
                            }, label: {
                                HStack {
                                    if type == .playlist {
                                        WebImage(url: URL(string: "\(track.album.picUrl)?param=120y120")) { image in
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
                                            Text(track.artists.map(\.name).joined(separator: " / "))
                                                .font(.system(size: 12))
                                                .foregroundStyle(.gray)
                                        }
                                    } else {
                                        Text(track.name)
                                            .font(.system(size: 14))
                                    }
                                    Spacer()
//                                    if !isDownloaded,
//                                       let _progress = downloadProgress,
//                                       _progress < 1,
//                                       let individualDownloadProgresses,
//                                       let progress = individualDownloadProgresses[track] {
//                                        Spacer()
//                                        if progress < 1 {
//                                            Gauge(value: progress, label: {})
//                                                .gaugeStyle(.accessoryCircularCapacity)
//                                                .tint(.accentColor)
//                                                .scaleEffect(0.3)
//                                                .frame(width: 20, height: 20)
//                                                .animation(.smooth, value: progress)
//                                        } else {
//                                            Image(systemName: "checkmark.circle.fill")
//                                                .font(.system(size: 16))
//                                                .foregroundStyle(.gray)
//                                        }
//                                    }
                                    #if !os(watchOS)
                                    Menu("", systemImage: "ellipsis") {
                                        track.contextActions
                                    }
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.primary)
                                    #endif
                                }
                            })
                            .listRowInsets(.init(top: 5, leading: 20, bottom: 5, trailing: 0))
                        }
                    } else {
                        ProgressView()
                            .centerAligned()
                    }
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
                        #if os(iOS)
                        .listRowBackground(Color(UIColor.secondarySystemBackground))
                        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .listRowSeparator(.hidden)
                        #endif
                    }
                    #if os(iOS)
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
                        isShowingNavigationTitle = scrollOffset.y - workTitleHeight > 170
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
