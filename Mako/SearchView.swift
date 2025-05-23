//
//  SearchView.swift
//  Mako
//
//  Created by Mark Chan on 2025/5/10.
//

import SwiftUI
import DarockUI
import DarockFoundation
import SDWebImageSwiftUI

struct SearchView: View {
    var isSearchKeyboardFocused: FocusState<Bool>.Binding
    @Environment(\.colorScheme) var colorScheme
    @State var searchText = ""
    @State var searchContentType = SearchResults.ContentType.song
    @State var isSearching = false
    @State var searchResults: SearchResults?
    @State var recentSearches = [String]()
    var body: some View {
        List {
            if !searchText.isEmpty {
                ScrollView(.horizontal) {
                    HStack {
                        Button(action: {
                            Task {
                                searchContentType = .song
                                if !isSearchKeyboardFocused.wrappedValue {
                                    await performSearch(searchText)
                                }
                            }
                        }, label: {
                            Text("歌曲")
                        })
                        .wrapIf(searchContentType != .song) { button in
                            button
                                .foregroundStyle(Color.primary)
                            #if !os(watchOS)
                                .tint(.init(uiColor: .systemBackground))
                            #endif
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        Button(action: {
                            Task {
                                searchContentType = .album
                                if !isSearchKeyboardFocused.wrappedValue {
                                    await performSearch(searchText)
                                }
                            }
                        }, label: {
                            Text("专辑")
                        })
                        .wrapIf(searchContentType != .album) { button in
                            button
                                .foregroundStyle(Color.primary)
                            #if !os(watchOS)
                                .tint(.init(uiColor: .systemBackground))
                            #endif
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        Button(action: {
                            Task {
                                searchContentType = .artist
                                if !isSearchKeyboardFocused.wrappedValue {
                                    await performSearch(searchText)
                                }
                            }
                        }, label: {
                            Text("艺人")
                        })
                        .wrapIf(searchContentType != .artist) { button in
                            button
                                .foregroundStyle(Color.primary)
                            #if !os(watchOS)
                                .tint(.init(uiColor: .systemBackground))
                            #endif
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                    }
                }
                .listRowBackground(Color.clear)
                #if !os(watchOS)
                .listRowSeparator(.hidden)
                #endif
            }
            if let results = searchResults {
                results.itemsView
            }
            if searchResults == nil && !recentSearches.isEmpty && !isSearching {
                HStack {
                    Text("最近搜索")
                        .font(.system(size: 17, weight: .semibold))
                    Spacer()
                    Button("清空", role: .destructive) {
                        recentSearches.removeAll()
                        updateSearchHistory()
                    }
                    .buttonStyle(.borderless)
                }
                #if !os(watchOS)
                .listRowSeparator(.hidden, edges: .top)
                #endif
                ForEach(recentSearches, id: \.self) { search in
                    Button(action: {
                        Task {
                            searchText = search
                            await performSearch(search)
                        }
                    }, label: {
                        Text(search)
                    })
                }
                .onDelete { indexs in
                    recentSearches.remove(atOffsets: indexs)
                    updateSearchHistory()
                }
            } else if isSearching {
                ProgressView()
                    .controlSize(.large)
                    .centerAligned()
                #if !os(watchOS)
                    .listRowSeparator(.hidden)
                #endif
            }
            Spacer()
                .frame(height: 50)
            #if !os(watchOS)
                .listRowSeparator(.hidden, edges: .bottom)
            #endif
        }
        #if !os(watchOS)
        .listStyle(.plain)
        #endif
        .searchable(text: $searchText, prompt: "艺人、歌曲、歌词，以及更多")
        #if !os(watchOS)
        .searchFocused(isSearchKeyboardFocused)
        #endif
        .onSubmit(of: .search) {
            Task {
                await performSearch(searchText)
            }
            recentSearchInsert(searchText)
            updateSearchHistory()
        }
        .navigationTitle("搜索")
        .withNowPlayingButton()
        .onAppear {
            if let jsonString = try? String(contentsOfFile: NSHomeDirectory() + "/Documents/RecentSearches.json", encoding: .utf8) {
                recentSearches = getJsonData([String].self, from: jsonString) ?? []
            }
        }
        .onChange(of: searchText) {
            if searchText.isEmpty {
                searchResults = nil
            }
        }
        .onReceive(performSearchSubject) { text in
            Task {
                await performSearch(text)
            }
            searchText = text
            recentSearchInsert(searchText)
            updateSearchHistory()
        }
    }
    
    func performSearch(_ text: String) async {
        isSearching = true
        searchResults = await .init(type: searchContentType, keyword: text)
        isSearching = false
    }
    func recentSearchInsert(_ text: String) {
        if !recentSearches.contains(text) {
            recentSearches.insert(text, at: 0)
        } else {
            recentSearches.move(fromOffsets: [recentSearches.firstIndex(of: text)!], toOffset: 0)
        }
    }
    func updateSearchHistory() {
        if let jsonString = jsonString(from: recentSearches) {
            try? jsonString.write(toFile: NSHomeDirectory() + "/Documents/RecentSearches.json", atomically: true, encoding: .utf8)
        }
    }
}
