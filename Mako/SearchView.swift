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
    var initialText: String?
    var isSearchKeyboardFocused: FocusState<Bool>.Binding
    @Environment(\.colorScheme) var colorScheme
    @State var searchText = ""
    @State var searchContentType = SearchResults.ContentType.song
    @State var isSearching = false
    @State var searchResults: SearchResults?
    @State var recentSearchItems = [SearchResults.CodableResult]()
    @State var recentSearchTexts = [String]()
    @State var showingTextForRecentSearch = false
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
            if searchResults == nil && !recentSearchTexts.isEmpty && !isSearching {
                #if !os(watchOS)
                Picker("", selection: $showingTextForRecentSearch) {
                    Text("项目").tag(false)
                    Text("关键词").tag(true)
                }
                .pickerStyle(.segmented)
                .listRowSeparator(.hidden, edges: .top)
                #endif
                HStack {
                    Text("最近搜索")
                        .font(.system(size: 17, weight: .semibold))
                    Spacer()
                    Button("清空", role: .destructive) {
                        recentSearchTexts.removeAll()
                        updateSearchHistory()
                    }
                    .buttonStyle(.borderless)
                }
                .onAppear {
                    if let jsonString = try? String(contentsOfFile: NSHomeDirectory() + "/Documents/RecentResultSearches.json", encoding: .utf8) {
                        recentSearchItems = getJsonData([SearchResults.CodableResult].self, from: jsonString) ?? []
                    }
                }
                #if !os(watchOS)
                .listRowSeparator(.hidden, edges: .top)
                #endif
                if !showingTextForRecentSearch {
                    SearchResults(fromCodableResults: recentSearchItems).itemsView
                } else {
                    ForEach(recentSearchTexts, id: \.self) { search in
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
                        recentSearchTexts.remove(atOffsets: indexs)
                        updateSearchHistory()
                    }
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
        .onInitialAppear {
            if let initialText {
                searchText = initialText
                Task {
                    await performSearch(initialText)
                }
            }
        }
        .onAppear {
            if let jsonString = try? String(contentsOfFile: NSHomeDirectory() + "/Documents/RecentSearches.json", encoding: .utf8) {
                recentSearchTexts = getJsonData([String].self, from: jsonString) ?? []
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
        if !recentSearchTexts.contains(text) {
            recentSearchTexts.insert(text, at: 0)
        } else {
            recentSearchTexts.move(fromOffsets: [recentSearchTexts.firstIndex(of: text)!], toOffset: 0)
        }
    }
    func updateSearchHistory() {
        if let jsonString = jsonString(from: recentSearchTexts) {
            try? jsonString.write(toFile: NSHomeDirectory() + "/Documents/RecentSearches.json", atomically: true, encoding: .utf8)
        }
    }
}
