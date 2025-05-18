//
//  View+SubjectNavigatable.swift
//  Mako
//
//  Created by Mark Chan on 2025/5/11.
//

import SwiftUI

private struct SubjectNavigatableModifier: ViewModifier {
    @State var navigationArtistID: Int?
    @State var navigationAlbumID: Int64?
    @State var isVisible = false
    func body(content: Content) -> some View {
        content
            .onAppear {
                isVisible = true
            }
            .onDisappear {
                isVisible = false
            }
            .navigationDestination(item: $navigationArtistID) { id in
                ArtistDetailView(id: id)
            }
            .navigationDestination(item: $navigationAlbumID) { id in
                AlbumDetailView(id: id, type: .album)
            }
            .onReceive(gotoArtistSubject) { id in
                if isVisible {
                    navigationArtistID = id
                }
            }
            .onReceive(gotoAlbumSubject) { id in
                if isVisible {
                    navigationAlbumID = id
                }
            }
    }
}
extension View {
    func subjectNavigatable() -> some View {
        self.modifier(SubjectNavigatableModifier())
    }
}
