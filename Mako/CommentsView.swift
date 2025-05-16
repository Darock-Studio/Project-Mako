//
//  CommentsView.swift
//  Mako
//
//  Created by Mark Chan on 2025/5/16.
//

import SwiftUI
import DarockUI
import DarockFoundation
import SDWebImageSwiftUI

struct CommentsView: View {
    var id: Int64
    @Environment(\.dismiss) var dismiss
    @State var comments = [Comment]()
    @State var currentPage = 0
    @State var isLoadingMore = false
    var body: some View {
        List {
            Section {
                if !comments.isEmpty {
                    ForEach(comments) { comment in
                        VStack(alignment: .leading) {
                            HStack {
                                WebImage(url: URL(string: "\(comment.user.avatarUrl)?param=90y90")) { image in
                                    image.resizable()
                                } placeholder: {
                                    Circle()
                                        .fill(Color.gray)
                                        .redacted(reason: .placeholder)
                                }
                                .scaledToFill()
                                .frame(width: 30, height: 30)
                                .clipShape(Circle())
                                VStack(alignment: .leading) {
                                    Text(comment.user.nickname)
                                        .font(.system(size: 14))
                                        .opacity(0.8)
                                    Text({
                                        let df = DateFormatter()
                                        df.dateStyle = .medium
                                        df.timeStyle = .none
                                        return df.string(from: comment.time)
                                    }())
                                    .font(.system(size: 10))
                                    .opacity(0.6)
                                }
                            }
                            Text(comment.content)
                        }
                        #if !os(watchOS)
                        .wrapIf(comment.id == comments.first?.id) { content in
                            content
                                .listRowSeparator(.hidden, edges: .top)
                        }
                        #endif
                        .onAppear {
                            if comment.id == comments.last?.id && !isLoadingMore {
                                loadMore()
                            }
                        }
                    }
                }
                if isLoadingMore {
                    ProgressView()
                        .centerAligned()
                    #if !os(watchOS)
                        .listRowSeparator(.hidden)
                    #endif
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("评论")
        .navigationBarTitleDisplayMode(.inline)
        .withDismissButton {
            dismiss()
        }
        .onInitialAppear {
            loadMore()
        }
    }
    
    func loadMore() {
        isLoadingMore = true
        requestJSON("\(apiBaseURL)/comment/music?id=\(id)&limit=20&offset=\(currentPage * 20)", headers: globalRequestHeaders) { respJson, isSuccess in
            if isSuccess {
                comments.append(contentsOf: getJsonData([Comment].self, from: respJson["comments"].rawString()!) ?? [])
                currentPage++
            }
            isLoadingMore = false
        }
    }
}
