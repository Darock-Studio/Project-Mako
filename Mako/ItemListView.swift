//
//  ItemListView.swift
//  Mako
//
//  Created by Mark Chan on 2025/5/5.
//

import SwiftUI
import DarockUI
import SDWebImageSwiftUI

struct ItemListView: View {
    var items: [SuggestionItem]
    private var style: ItemListViewStyle = .horizontalScroll
    private var onLastItemAppear: (() -> Void)?
    @Namespace private var navigationNamespace
    
    init(items: [SuggestionItem]) {
        self.items = items
        self.style = .horizontalScroll
    }
    
    var body: some View {
        switch style {
        case .horizontalScroll:
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    if !items.isEmpty {
                        ForEach(items) { item in
                            NavigationLink {
                                AlbumDetailView(id: Int64(item.id), type: item.type == .playlist ? .playlist : .album)
                                    .navigationTransition(.zoom(sourceID: item.id, in: navigationNamespace))
                            } label: {
                                VStack(alignment: .leading) {
                                    WebImage(url: URL(string: item.picUrl)) { image in
                                        image.resizable()
                                    } placeholder: {
                                        Rectangle()
                                            .fill(Color.gray)
                                            .redacted(reason: .placeholder)
                                    }
                                    .scaledToFill()
                                    #if !os(watchOS)
                                    .frame(width: 150, height: 150)
                                    #else
                                    .frame(width: 100, height: 100)
                                    #endif
                                    .clipped()
                                    .cornerRadius(7)
                                    .matchedTransitionSource(id: item.id, in: navigationNamespace)
                                    Text(item.name)
                                        .font(.system(size: 12, weight: .medium))
                                        .lineLimit(2, reservesSpace: true)
                                        .multilineTextAlignment(.leading)
                                        .foregroundStyle(Color.primary)
                                }
                                #if !os(watchOS)
                                .frame(width: 160)
                                #else
                                .frame(width: 110)
                                #endif
                            }
                            .buttonStyle(.borderless)
//                            #if !os(watchOS)
//                            .contextMenu {
//                                item.contextActions
//                            } preview: {
//                                item.previewView
//                            }
//                            #endif
                            .onAppear {
                                if item.id == items.last?.id {
                                    onLastItemAppear?()
                                }
                            }
                        }
                    } else {
                        ForEach(0...5, id: \.self) { _ in
                            VStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray)
                                    .frame(width: 150, height: 150)
                                    .cornerRadius(7)
                                    .redacted(reason: .placeholder)
                                Text(verbatim: "Title")
                                    .font(.system(size: 12, weight: .medium))
                                    .lineLimit(1)
                                    .foregroundStyle(Color.primary)
                                    .redacted(reason: .placeholder)
                            }
                            .frame(width: 160)
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
        case .grid:
            LazyVGrid(columns: [.init(), .init()], spacing: 6) {
                if !items.isEmpty {
                    ForEach(items) { item in
                        NavigationLink {
                            AlbumDetailView(id: Int64(item.id), type: item.type == .playlist ? .playlist : .album)
                                .navigationTransition(.zoom(sourceID: item.id, in: navigationNamespace))
                        } label: {
                            VStack(alignment: .leading) {
                                WebImage(url: URL(string: item.picUrl)) { image in
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
                                .matchedTransitionSource(id: item.id, in: navigationNamespace)
                                Text(item.name)
                                    .font(.system(size: 12, weight: .medium))
                                    .lineLimit(1)
                                    .foregroundStyle(Color.primary)
                            }
                        }
                        .buttonStyle(.borderless)
//                        #if !os(watchOS)
//                        .contextMenu {
//                            item.contextActions
//                        } preview: {
//                            item.previewView
//                        }
//                        #endif
                        .onAppear {
                            if item.id == items.last?.id {
                                onLastItemAppear?()
                            }
                        }
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
                            Text(verbatim: "Title")
                                .font(.system(size: 12, weight: .medium))
                                .lineLimit(1)
                                .foregroundStyle(Color.primary)
                                .redacted(reason: .placeholder)
                            Text(verbatim: "Placeholder")
                                .font(.system(size: 12))
                                .lineLimit(1)
                                .foregroundStyle(.gray)
                                .redacted(reason: .placeholder)
                        }
                    }
                }
            }
            .centerAligned()
            .padding(.horizontal, -10)
        case .plain:
            ForEach(items) { item in
                NavigationLink { AlbumDetailView(id: Int64(item.id), type: item.type == .playlist ? .playlist : .album) } label: {
                    HStack {
                        WebImage(url: URL(string: item.picUrl)) { image in
                            image.resizable()
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray)
                                .redacted(reason: .placeholder)
                        }
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipped()
                        .cornerRadius(6)
                        Text(item.name)
                            .font(.system(size: 13))
                            .lineLimit(1)
                            .foregroundStyle(Color.primary)
                    }
                }
//                #if !os(watchOS)
//                .contextMenu {
//                    item.contextActions
//                } preview: {
//                    item.previewView
//                }
//                #endif
                .onAppear {
                    if item.id == items.last?.id {
                        onLastItemAppear?()
                    }
                }
            }
        }
    }
    
    enum ItemListViewStyle {
        case horizontalScroll
        case grid
        case plain
    }
}
extension ItemListView {
    func itemListStyle(_ style: ItemListViewStyle) -> Self {
        var mutableCopy = self
        mutableCopy.style = style
        return mutableCopy
    }
    func onLastItemAppear(perform action: (() -> Void)?) -> Self {
        var mutableCopy = self
        mutableCopy.onLastItemAppear = action
        return mutableCopy
    }
}
