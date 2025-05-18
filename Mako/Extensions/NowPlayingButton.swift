//
//  NowPlayingButton.swift
//  Mako
//
//  Created by Mark Chan on 2025/5/11.
//

import SwiftUI

#if os(watchOS)

struct NowPlayingButton: View {
    @State private var drawingHeight = true
    @State var isAudioPlaying = globalAudioPlayer.timeControlStatus == .playing
    @State var isNowPlayingViewPresented = false
    @State var nowPlayingBackgroundColors = Array(repeating: Color(uiColor: .darkGray), count: 16)
    var animation: Animation {
        return .linear(duration: 0.5).repeatForever()
    }
    var body: some View {
        Button(action: {
            isNowPlayingViewPresented = true
        }, label: {
            if isAudioPlaying {
                HStack(spacing: 2) {
                    bar(low: 0.4)
                        .animation(animation.speed(1.8), value: drawingHeight)
                    bar(low: 0.3)
                        .animation(animation.speed(2.4), value: drawingHeight)
                    bar(low: 0.5)
                        .animation(animation.speed(2.0), value: drawingHeight)
                    bar(low: 0.3)
                        .animation(animation.speed(3.0), value: drawingHeight)
                    bar(low: 0.5)
                        .animation(animation.speed(2.0), value: drawingHeight)
                }
                .onAppear {
                    drawingHeight.toggle()
                }
            } else {
                HStack(spacing: 2) {
                    bar(low: 0.3, high: 0.3)
                    bar(low: 0.5, high: 0.5)
                    bar(low: 0.3, high: 0.3)
                    bar(low: 0.5, high: 0.5)
                    bar(low: 0.3, high: 0.3)
                }
            }
        })
        .sheet(isPresented: $isNowPlayingViewPresented) {
            NowPlayingView(backgroundColors: nowPlayingBackgroundColors)
                .foregroundStyle(.white)
        }
        .onReceive(globalAudioPlayer.publisher(for: \.timeControlStatus)) { status in
            isAudioPlaying = status == .playing
        }
        .onReceive(nowPlayingMedia) { media in
            if let media {
                DispatchQueue(label: "com.darock.Mako.UpdateNowPlayingBackground", qos: .utility).async {
                    if let imageUrl = URL(string: media.sourceTrack.album.picUrl),
                       let imageData = try? Data(contentsOf: imageUrl),
                       let image = UIImage(data: imageData) {
                        nowPlayingBackgroundColors = ColorThief.getPalette(from: image, colorCount: 16)!.map {
                            Color(red: Double($0.r) / 255, green: Double($0.g) / 255, blue: Double($0.b) / 255)
                        }
                    }
                }
            }
        }
    }
    
    func bar(low: CGFloat = 0.0, high: CGFloat = 1.0) -> some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color.accent)
            .frame(height: (drawingHeight ? high : low) * 10)
            .frame(width: 2, height: 10)
//            .padding(.horizontal, -2)
    }
}

#endif

extension View {
    func withNowPlayingButton() -> some View {
        #if os(watchOS)
        self
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NowPlayingButton()
                }
            }
        #else
        self
        #endif
    }
}
