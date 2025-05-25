//
//  ArtistDetailView.swift
//  Mako
//
//  Created by Mark Chan on 2025/5/11.
//

import SwiftUI
import DarockUI
import DarockFoundation
import SDWebImageSwiftUI
@_spi(Advanced) import SwiftUIIntrospect

struct ArtistDetailView: View {
    var id: Int
    @Namespace var albumNavigationNamespace
    @Environment(\.dismiss) var dismiss
    @State var artist: ArtistDetailed?
    @State var scrollObservation: NSKeyValueObservation?
    @State var isShowingNavigationTitle = false
    @State var topSongs = [Track]()
    @State var albums = [Album]()
    var body: some View {
        Group {
            if let artist {
                ScrollView {
                    ZStack(alignment: .bottom) {
                        GeometryReader { geometry in
                            let offset = geometry.frame(in: .global).minY
                            WebImage(url: URL(string: artist.cover)) { image in
                                image.resizable()
                            } placeholder: {
                                Rectangle()
                                    .fill(Color.gray)
                                    .redacted(reason: .placeholder)
                            }
                            .scaledToFill()
                            .frame(width: screenBounds.width, height: offset > 0 ? 400 + offset : 400)
                            .clipped()
                            .overlay {
                                Color.black
                                    .mask {
                                        LinearGradient(colors: [.black.opacity(0.4), .black.opacity(0.05), .black.opacity(0.05), .black.opacity(0.05), .black.opacity(0.05), .black.opacity(0.05), .black.opacity(0.05), .black.opacity(0.4)], startPoint: .top, endPoint: .bottom)
                                    }
                            }
                            .offset(y: offset > 0 ? -offset : 0)
                        }
                        .frame(height: 400)
                        HStack {
                            Text(artist.name)
                                .font(.system(size: 35, weight: .bold))
                                .foregroundStyle(.white)
                            Spacer()
                            if !topSongs.isEmpty {
                                Button(action: {
                                    PlaylistManager.shared.replace(with: topSongs)
                                }, label: {
                                    Image(systemName: "play.fill")
                                        .padding(2)
                                })
                                .buttonStyle(.borderedProminent)
                                .buttonBorderShape(.circle)
                            }
                        }
                        ._tightPadding()
                        .padding(.horizontal, 5)
                    }
                    VStack(alignment: .leading) {
                        if !topSongs.isEmpty {
                            Text("歌曲排行")
                                .font(.system(size: 22, weight: .bold))
                            ScrollView(.horizontal) {
                                LazyHGrid(rows: [.init(), .init(), .init(), .init()]) {
                                    ForEach(topSongs) { track in
                                        Button(action: {
                                            Task {
                                                await playTrack(track)
                                            }
                                        }, label: {
                                            HStack {
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
                                                .cornerRadius(5)
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(track.name)
                                                        .font(.system(size: 14))
                                                        .foregroundStyle(Color.primary)
                                                    Text(track.album.name)
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
                                        #if os(iOS)
                                        .frame(width: screenBounds.width - 60)
                                        #endif
                                        .contextMenu {
                                            track.contextActions
                                        } preview: {
                                            track.previewView
                                        }
                                    }
                                }
                                .scrollTargetLayout()
                                .scrollTransition { content, _ in
                                    content.offset(x: 14)
                                }
                            }
                            .scrollIndicators(.never)
                            .scrollTargetBehavior(.viewAligned)
                            .padding(.horizontal, -16)
                        } else {
                            ProgressView()
                        }
                        Text("专辑")
                            .font(.system(size: 22, weight: .bold))
                            .padding(.top, 5)
                        LazyVGrid(columns: [.init(), .init()], spacing: 6) {
                            if !albums.isEmpty {
                                ForEach(albums) { album in
                                    NavigationLink {
                                        AlbumDetailView(id: album.id, type: .album)
                                            .navigationTransition(.zoom(sourceID: album.id, in: albumNavigationNamespace))
                                    } label: {
                                        VStack(alignment: .leading) {
                                            WebImage(url: URL(string: album.coverImgUrl)) { image in
                                                image.resizable()
                                            } placeholder: {
                                                Rectangle()
                                                    .fill(Color.gray)
                                                    .redacted(reason: .placeholder)
                                            }
                                            .scaledToFill()
                                            .frame(width: screenBounds.width / 2 - 24, height: screenBounds.width / 2 - 24)
                                            .clipped()
                                            .cornerRadius(7)
                                            .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(Color.gray.opacity(0.6)))
                                            .matchedTransitionSource(id: album.id, in: albumNavigationNamespace)
                                            Text(album.name)
                                                .font(.system(size: 12, weight: .medium))
                                                .lineLimit(1)
                                                .foregroundStyle(Color.primary)
                                        }
                                    }
                                    .buttonStyle(.borderless)
//                                    .contextMenu {
//                                        item.contextActions
//                                    } preview: {
//                                        item.previewView
//                                    }
                                }
                            } else {
                                ForEach(0...9, id: \.self) { _ in
                                    VStack(alignment: .leading) {
                                        Rectangle()
                                            .fill(Color.gray)
                                            .frame(width: screenBounds.width / 2 - 24, height: screenBounds.width / 2 - 24)
                                            .cornerRadius(7)
                                            .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(Color.gray.opacity(0.6)))
                                            .redacted(reason: .placeholder)
                                        Text(verbatim: "Placeholder")
                                            .font(.system(size: 12, weight: .medium))
                                            .lineLimit(1)
                                            .foregroundStyle(Color.primary)
                                            .redacted(reason: .placeholder)
                                    }
                                }
                            }
                        }
                        .centerAligned()
                        .padding(.horizontal, -10)
                        #if os(iOS)
                        Spacer()
                            .frame(height: 60)
                        #endif
                    }
                    .padding()
                }
                #if os(iOS)
                .introspect(.scrollView, on: .iOS(.v18...)) { scrollView in
                    scrollObservation = scrollView.observe(\.contentOffset, options: .new) { _, value in
                        let scrollOffset = value.newValue ?? .init()
                        isShowingNavigationTitle = scrollOffset.y > 400
                    }
                }
                .navigationBarBackButtonHidden()
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        if !isShowingNavigationTitle {
                            Button(action: {
                                dismiss()
                            }, label: {
                                Image(systemName: "chevron.backward")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .padding(8)
                                    .background {
                                        GenericUIViewRepresentable(view: UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark)))
                                            .clipShape(Circle())
                                    }
                            })
                            .buttonStyle(.plain)
                        } else {
                            Button(action: {
                                dismiss()
                            }, label: {
                                Image(systemName: "chevron.backward")
                                    .fontWeight(.semibold)
                            })
                        }
                    }
                    ToolbarItem(placement: .principal) {
                        if isShowingNavigationTitle {
                            Text(artist.name)
                                .bold()
                        }
                    }
                }
                #endif
                .edgesIgnoringSafeArea(.top)
                .onAppear {
                    requestJSON("\(apiBaseURL)/artist/top/song?id=\(id)", headers: globalRequestHeaders) { respJson, isSuccess in
                        if isSuccess {
                            topSongs = getJsonData([Track].self, from: respJson["songs"].rawString()!) ?? []
                        }
                    }
                    requestJSON("\(apiBaseURL)/artist/album?id=\(id)&limit=1000", headers: globalRequestHeaders) { respJson, isSuccess in
                        if isSuccess {
                            albums = getJsonData([Album].self, from: respJson["hotAlbums"].rawString()!) ?? []
                        }
                    }
                }
            } else {
                ProgressView()
                    .controlSize(.large)
                    .task {
                        let result = await requestJSON("\(apiBaseURL)/artist/detail?id=\(id)", headers: globalRequestHeaders)
                        if case let .success(respJson) = result {
                            artist = getJsonData(ArtistDetailed.self, from: respJson["data"]["artist"].rawString()!)
                        }
                    }
            }
        }
        .subjectNavigatable()
        .toolbarBackgroundVisibility(isShowingNavigationTitle ? .visible : .hidden, for: .navigationBar)
        .transition(.opacity)
        .animation(.smooth, value: isShowingNavigationTitle)
    }
}
