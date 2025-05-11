//
//  HomeView.swift
//  Mako
//
//  Created by Mark Chan on 2025/5/5.
//

import SwiftUI
import DarockFoundation

struct HomeView: View {
    @AppStorage("IsLoggedIn") var isLoggedIn = false
    @State var personalAlbumSuggestions = [SuggestionItem]()
    @State var albumSuggestions = [SuggestionItem]()
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                if isLoggedIn {
                    Text("专属精选推荐")
                        .font(.system(size: 22, weight: .bold))
                    ItemListView(items: personalAlbumSuggestions)
                }
                Text("热门")
                    .font(.system(size: 22, weight: .bold))
                ItemListView(items: albumSuggestions)
                Spacer()
                    .frame(height: 20)
            }
            .padding()
        }
        .navigationTitle("主页")
        .withNowPlayingButton()
        .refreshable {
            refresh()
        }
        .onAppear {
            refresh()
        }
    }
    
    func refresh() {
        if isLoggedIn {
            requestJSON("\(apiBaseURL)/recommend/songs", headers: globalRequestHeaders) { respJson, isSuccess in
                if isSuccess {
                    personalAlbumSuggestions.removeAll()
                    for album in respJson["data"]["dailySongs"] {
                        personalAlbumSuggestions.append(.init(type: .album, id: album.1["al"]["id"].intValue, name: album.1["al"]["name"].stringValue, picUrl: album.1["al"]["picUrl"].stringValue))
                    }
                }
            }
        }
        requestJSON("\(apiBaseURL)/personalized", headers: globalRequestHeaders) { respJson, isSuccess in
            if isSuccess {
                albumSuggestions.removeAll()
                for album in respJson["result"] {
                    albumSuggestions.append(.init(type: .album, id: album.1["id"].intValue, name: album.1["name"].stringValue, picUrl: album.1["picUrl"].stringValue))
                }
            }
        }
    }
}
