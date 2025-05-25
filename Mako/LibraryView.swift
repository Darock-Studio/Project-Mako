//
//  LibraryView.swift
//  Mako
//
//  Created by Mark Chan on 2025/5/18.
//

import SwiftUI
import DarockUI
import SwiftyJSON
import DarockFoundation

struct LibraryView: View {
    @AppStorage("IsLoggedIn") var isLoggedIn = false
    @AppStorage("UserID") var userID = ""
    @State var isAccountManagementPresented = false
    var body: some View {
        Group {
            if isLoggedIn {
                List {
                    NavigationLink(destination: { PlaylistView(uid: userID) }, label: {
                        Label("播放列表", systemImage: "music.note.list")
                    })
                }
                .listStyle(.plain)
            } else {
                ContentUnavailableView("需要登录", systemImage: "music.square.stack.fill", description: Text("在“账户”页面登录以访问资料库"))
            }
        }
        .navigationTitle("资料库")
        .navigationBarTitleDisplayMode(.large)
        .withNowPlayingButton()
        #if os(watchOS)
        .sheet(isPresented: $isAccountManagementPresented, content: { AccountView() })
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    isAccountManagementPresented = true
                }, label: {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.accent)
                })
            }
        }
        #endif
    }
    
    struct PlaylistView: View {
        var uid: String
        @State var playlists = [SuggestionItem]()
        var body: some View {
            List {
                if !playlists.isEmpty {
                    ItemListView(items: playlists)
                        .itemListStyle(.plain)
                    #if os(iOS)
                    Spacer()
                        .frame(height: 60)
                        .listRowSeparator(.hidden, edges: .bottom)
                    #endif
                } else {
                    ProgressView()
                        .controlSize(.large)
                        .centerAligned()
                    #if os(iOS)
                        .listRowSeparator(.hidden)
                    #endif
                }
            }
            .listStyle(.plain)
            .navigationTitle("播放列表")
            .navigationBarTitleDisplayMode(.large)
            .subjectNavigatable()
            .withNowPlayingButton()
            .onAppear {
                requestJSON("\(apiBaseURL)/user/playlist?uid=\(uid)&limit=10000", headers: globalRequestHeaders) { respJson, isSuccess in
                    if isSuccess {
                        debugPrint(respJson)
                        let albums = getJsonData([Album].self, from: respJson["playlist"].rawString()!) ?? []
                        playlists.removeAll()
                        for album in albums {
                            playlists.append(.init(type: .playlist, id: Int(album.id), name: album.name, picUrl: album.coverImgUrl))
                        }
                    }
                }
            }
        }
    }
}
