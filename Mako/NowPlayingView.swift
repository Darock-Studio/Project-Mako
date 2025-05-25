//
//  NowPlayingView.swift
//  Mako
//
//  Created by Mark Chan on 2025/5/10.
//

import AVKit
import SwiftUI
import DarockUI
import MediaPlayer
import AVFoundation
import DarockFoundation
import SDWebImageSwiftUI

struct NowPlayingView: View {
    var backgroundColors: [Color]
    #if !os(watchOS)
    var coverEffectNamespace: Namespace.ID
    @Binding var isShowingLyrics: Bool
    @Binding var isShowingPlaylists: Bool
    @Binding var isNowPlayingStarred: Bool
    #else
    @State var isShowingLyrics = true
    @State var isShowingPlaylists = false
    #endif
    @AppStorage("IsLoggedIn") var isLoggedIn = false
    @State var nowPlaying: NowPlayingInfo?
    @State var currentPlaybackTime = globalAudioPlayer.currentTime().seconds
    @State var playbackBehavior = PlaybackBehavior.singleLoop
    @State var currentItemTotalTime = 0.0
    @State var currentScrolledId = 0.0
    @State var isShowingControls = false
    @State var isPlaying = false
    @State var isProgressDraging = false
    @State var progressDragingNewTime = 0.0
    @State var controlMenuDismissTimer: Timer?
    @State var isSoftScrolling = true
    @State var softScrollingResetTask: Task<Void, Never>?
    @State var isUserScrolling = false
    @State var userScrollingResetTimer: Timer?
    @State var lyricScrollProxy: ScrollViewProxy?
    @State var isVolumeDraging = false
    @State var volumeDragingNewValue = 0.0
    @State var currentVolume = AVAudioSession.sharedInstance().outputVolume
    @State var volumeObserver: NSKeyValueObservation?
    @State var playlists = [Track]()
    var body: some View {
        VStack {
            if let nowPlaying {
                ZStack {
                    if isShowingLyrics {
                        if let lyrics = nowPlaying.lyrics, !lyrics.isEmpty {
                            ScrollViewReader { scrollProxy in
                                let lyricKeys = Array<Double>(lyrics.keys).sorted(by: { lhs, rhs in lhs < rhs })
                                ScrollView {
                                    VStack(alignment: .leading, spacing: 20) {
                                        Spacer()
                                            .frame(height: 20)
                                        if let firstKey = lyricKeys.first {
                                            if firstKey >= 2.0 {
                                                WaitingDotsView(startTime: 0.0, endTime: firstKey)
                                            }
                                        }
                                        ForEach(0..<lyricKeys.count, id: \.self) { i in
                                            HStack {
                                                if !lyrics[lyricKeys[i]]!.isEmpty {
                                                    HStack {
                                                        if ({
                                                            var singerSplitCount = 0
                                                            for key in lyricKeys[0...i] {
                                                                if let src = lyrics[key]!.components(separatedBy: "%tranlyric@")[from: 0], src.hasSuffix("：") {
                                                                    singerSplitCount++
                                                                }
                                                            }
                                                            return singerSplitCount % 2 == 1
                                                        }()) {
                                                            Spacer()
                                                        }
                                                        VStack(alignment: .leading) {
                                                            if lyrics[lyricKeys[i]]!.contains("%tranlyric@"),
                                                               let src = lyrics[lyricKeys[i]]!.components(separatedBy: "%tranlyric@")[from: 0],
                                                               let trans = lyrics[lyricKeys[i]]!.components(separatedBy: "%tranlyric@")[from: 1] {
                                                                Text(src)
                                                                #if !os(watchOS)
                                                                    .font(.system(size: 30, weight: .bold))
                                                                #else
                                                                    .font(.system(size: 16, weight: .semibold))
                                                                #endif
                                                                    .fixedSize(horizontal: false, vertical: true)
                                                                Spacer()
                                                                    .frame(height: 4)
                                                                Text(trans)
                                                                #if !os(watchOS)
                                                                    .font(.system(size: 18, weight: .bold))
                                                                #else
                                                                    .font(.system(size: 14, weight: .semibold))
                                                                #endif
                                                                    .fixedSize(horizontal: false, vertical: true)
                                                            } else if lyrics[lyricKeys[i]]!.hasPrefix("%credits@") {
                                                                Text(String(lyrics[lyricKeys[i]]!.dropFirst("%credits@".count)))
                                                                #if !os(watchOS)
                                                                    .font(.system(size: 20, weight: .bold))
                                                                #else
                                                                    .font(.system(size: 12, weight: .semibold))
                                                                #endif
                                                                    .fixedSize(horizontal: false, vertical: true)
                                                            } else {
                                                                Text(lyrics[lyricKeys[i]]!)
                                                                #if !os(watchOS)
                                                                    .font(.system(size: lyrics[lyricKeys[i]]!.hasSuffix("：") ? 20 : 30, weight: .bold))
                                                                #else
                                                                    .font(.system(size: lyrics[lyricKeys[i]]!.hasSuffix("：") ? 14 : 16, weight: .semibold))
                                                                #endif
                                                                    .fixedSize(horizontal: false, vertical: true)
                                                                    .padding(.bottom, lyrics[lyricKeys[i]]!.hasSuffix("：") ? -3 : 0)
                                                            }
                                                        }
                                                        .multilineTextAlignment({
                                                            var singerSplitCount = 0
                                                            for key in lyricKeys[0...i] {
                                                                if let src = lyrics[key]!.components(separatedBy: "%tranlyric@")[from: 0], src.hasSuffix("：") {
                                                                    singerSplitCount++
                                                                }
                                                            }
                                                            return singerSplitCount % 2 == 0 ? .leading : .trailing
                                                        }())
                                                        if ({
                                                            var singerSplitCount = 0
                                                            for key in lyricKeys[0...i] {
                                                                if let src = lyrics[key]!.components(separatedBy: "%tranlyric@")[from: 0], src.hasSuffix("：") {
                                                                    singerSplitCount++
                                                                }
                                                            }
                                                            return singerSplitCount % 2 == 0
                                                        }()) {
                                                            Spacer(minLength: 20)
                                                        }
                                                    }
                                                    .opacity(currentScrolledId == lyricKeys[i] ? 1.0 : 0.6)
                                                    .blur(radius: currentScrolledId == lyricKeys[i] || isUserScrolling || (lyrics[lyricKeys[i]]!.hasPrefix("%credits@") && currentScrolledId == lyricKeys[from: lyricKeys.count - 2]) ? 0 : abs(currentScrolledId - lyricKeys[i]) / 3)
                                                    .padding(.vertical, 5)
                                                    .animation(.smooth, value: currentScrolledId)
                                                    .modifier(LyricButtonModifier {
                                                        globalAudioPlayer.seek(to: CMTime(seconds: lyricKeys[i], preferredTimescale: 60000),
                                                                               toleranceBefore: .zero,
                                                                               toleranceAfter: .zero)
                                                        globalAudioPlayer.play()
                                                        currentScrolledId = lyricKeys[i]
                                                        isSoftScrolling = true
                                                        withAnimation(.easeOut(duration: 0.5)) {
                                                            lyricScrollProxy?.scrollTo(lyricKeys[i], anchor: .init(x: 0.5, y: 0.2))
                                                        }
                                                        Task {
                                                            try? await Task.sleep(for: .seconds(0.6)) // Animation may take longer time than duration
                                                            DispatchQueue.main.async {
                                                                isSoftScrolling = false
                                                            }
                                                        }
                                                    })
                                                    .allowsHitTesting(isUserScrolling)
                                                } else {
                                                    if let endTime = lyricKeys[from: i &+ 1], endTime - lyricKeys[i] > 2.0 {
                                                        WaitingDotsView(startTime: lyricKeys[i], endTime: endTime)
                                                        Spacer()
                                                    }
                                                }
                                            }
                                            .id(lyricKeys[i])
                                        }
                                        .scrollTransition { content, phase in
                                            content
                                                .scaleEffect(phase.isIdentity ? 1 : 0.98)
                                                .opacity(phase.isIdentity ? 1 : 0.5)
                                                .offset(y: phase == .bottomTrailing ? 10 : 0)
                                        }
                                        Spacer()
                                            .frame(height: 200)
                                    }
                                    #if !os(watchOS)
                                    .padding(.horizontal, 30)
                                    .padding(.vertical)
                                    #endif
                                }
                                .withScrollOffsetUpdate()
                                .onPreferenceChange(ScrollViewOffsetPreferenceKey.self) { _ in
                                    if !isSoftScrolling {
                                        // Scrolled by user (not auto scrolling lyrics)
                                        isUserScrolling = true
                                        userScrollingResetTimer?.invalidate()
                                        userScrollingResetTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { _ in
                                            isUserScrolling = false
                                        }
                                    }
                                }
                                .onAppear {
                                    lyricScrollProxy = scrollProxy
                                }
                                .onReceive(globalAudioPlayer.periodicTimePublisher(forInterval: .init(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))) { _ in
                                    var newScrollId = 0.0
                                    var isUpdatedScrollId = false
                                    for i in 0..<lyricKeys.count where globalAudioPlayer.currentTime().seconds < lyricKeys[i] {
                                        if let newKey = lyricKeys[from: i - 1] {
                                            newScrollId = newKey
                                        } else {
                                            newScrollId = lyricKeys[i]
                                        }
                                        isUpdatedScrollId = true
                                        break
                                    }
                                    if _slowPath(!isUpdatedScrollId && !lyricKeys.isEmpty) {
                                        newScrollId = lyricKeys.last!
                                    }
                                    if _slowPath(newScrollId != currentScrolledId && !isUserScrolling) {
                                        softScrollingResetTask?.cancel()
                                        currentScrolledId = newScrollId
                                        isSoftScrolling = true
                                        withAnimation(.easeOut(duration: 0.5)) {
                                            scrollProxy.scrollTo(newScrollId, anchor: .init(x: 0.5, y: 0.2))
                                        }
                                        softScrollingResetTask = Task {
                                            do {
                                                try await Task.sleep(for: .seconds(1.5)) // Animation may take longer time than duration
                                                guard !Task.isCancelled else { return }
                                                DispatchQueue.main.async {
                                                    isSoftScrolling = false
                                                }
                                            } catch {
                                                // Catch if task was canceled, do nothing.
                                            }
                                        }
                                    }
                                }
                            }
                            .onAppear {
                                // rdar://FB268002074511
                                isSoftScrolling = false
                            }
                        } else {
                            Text("文本不可用")
                        }
                    } else if !isShowingPlaylists {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.clear)
                            .overlay {
                                WebImage(url: URL(string: nowPlaying.sourceTrack.album.picUrl)) { image in
                                    image.resizable()
                                } placeholder: {
                                    Rectangle()
                                        .fill(Color.gray)
                                        .redacted(reason: .placeholder)
                                }
                                .scaledToFill()
                                .cornerRadius(8)
                            }
                            #if !os(watchOS)
                            .matchedGeometryEffect(id: "Cover", in: coverEffectNamespace, isSource: !isShowingLyrics)
                            #endif
                            .frame(width: screenBounds.width - (isPlaying ? 70 : 120), height: screenBounds.width - (isPlaying ? 70 : 120))
                            .shadow(radius: 15, x: 3, y: 3)
                            .padding(.bottom, 400)
                            .allowsHitTesting(false)
                    } else {
                        VStack {
                            HStack {
                                Button(action: {
                                    switch playbackBehavior {
                                    case .pause:
                                        playbackBehavior = .singleLoop
                                    case .singleLoop:
                                        playbackBehavior = .listLoop
                                    case .listLoop:
                                        playbackBehavior = .pause
                                    }
                                    resetMenuDismissTimer()
                                }, label: {
                                    switch playbackBehavior {
                                    case .pause:
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color.gray.opacity(0.4))
                                            Image(systemName: "repeat")
                                                .font(.system(size: 16))
                                                .foregroundStyle(.white)
                                        }
                                        .frame(height: 40)
                                    case .singleLoop:
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.white.opacity(0.6))
                                            .frame(height: 40)
                                            .reversedMask {
                                                Image(systemName: "repeat.1")
                                                    .font(.system(size: 16))
                                            }
                                    case .listLoop:
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.white.opacity(0.6))
                                            .frame(height: 40)
                                            .reversedMask {
                                                Image(systemName: "repeat")
                                                    .font(.system(size: 16))
                                            }
                                    }
                                })
                            }
                            .buttonStyle(.borderless)
                            .padding(.horizontal, 30)
                            List {
                                Group {
                                    Text("继续播放")
                                        .font(.headline)
                                    ForEach(playlists) { track in
                                        HStack {
                                            Button(action: {
                                                Task {
                                                    await playTrack(track)
                                                }
                                            }, label: {
                                                WebImage(url: URL(string: "\(track.album.picUrl)?param=150y150")) { image in
                                                    image.resizable()
                                                } placeholder: {
                                                    Rectangle()
                                                        .fill(Color.gray)
                                                        .redacted(reason: .placeholder)
                                                }
                                                .scaledToFill()
                                                .frame(width: 50, height: 50)
                                                .clipped()
                                                .cornerRadius(6)
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(track.name)
                                                        .font(.system(size: 14))
                                                        .foregroundStyle(.white)
                                                    Text(track.artists.map(\.name).joined(separator: " / "))
                                                        .font(.system(size: 12))
                                                        .foregroundStyle(.white)
                                                        .opacity(0.6)
                                                }
                                                .lineLimit(1)
                                            })
                                            .buttonStyle(.plain)
                                            .contextMenu {
                                                track.contextActions
                                            } preview: {
                                                track.previewView
                                            }
                                            Spacer()
                                            Image(systemName: "line.3.horizontal")
                                                .font(.system(size: 22))
                                                .opacity(0.6)
                                        }
                                    }
                                    .onMove { source, destination in
                                        PlaylistManager.shared.move(fromOffsets: source, toOffset: destination)
                                    }
                                    .onDelete { indexs in
                                        PlaylistManager.shared.remove(atOffsets: indexs)
                                    }
                                    Spacer()
                                }
                                .listRowBackground(Color.clear)
                                .listRowInsets(.init(top: 5, leading: 30, bottom: 5, trailing: 30))
                                #if !os(watchOS)
                                .listRowSeparator(.hidden)
                                #endif
                            }
                            .listStyle(.plain)
                            .scrollContentBackground(.hidden)
                            .mask {
                                LinearGradient(colors: [.black, .black, .black, .black, .black, .black, .black, .black, .black, .black, .black.opacity(0)], startPoint: .top, endPoint: .bottom)
                            }
                        }
                        .padding(.bottom, 300)
                    }
                    // Audio Controls
                    MeshGradient(width: 3,
                                 height: 3,
                                 points: [
                                    SIMD2<Float>(0.0, 0.0), SIMD2<Float>(0.5, 0.0), SIMD2<Float>(1.0, 0.0),
                                    SIMD2<Float>(0.0, 0.5), SIMD2<Float>(0.45, 0.55), SIMD2<Float>(1.0, 0.5),
                                    SIMD2<Float>(0.0, 1.0), SIMD2<Float>(0.5, 1.0), SIMD2<Float>(1.0, 1.0)
                                 ],
                                 colors: backgroundColors,
                                 background: .init(uiColor: .darkGray),
                                 smoothsColors: true)
                    .blur(radius: 10, opaque: true)
                    .overlay {
                        Color.black.opacity(0.6)
                    }
                    .opacity(isShowingControls || nowPlaying.lyrics == nil ? 1.0 : 0.0)
                    .offset(y: isShowingControls || nowPlaying.lyrics == nil ? 0 : 10)
                    .animation(.easeOut(duration: 0.2), value: isShowingControls)
                    .mask {
                        #if !os(watchOS)
                        LinearGradient(colors: [.black.opacity(0), .black.opacity(0), .black.opacity(0), .black.opacity(0), .black, .black, .black, .black], startPoint: .top, endPoint: .bottom)
                        #else
                        LinearGradient(colors: [.black.opacity(0), .black.opacity(0), .black.opacity(0), .black.opacity(0), .black.opacity(0), .black, .black, .black], startPoint: .top, endPoint: .bottom)
                        #endif
                    }
                    .allowsHitTesting(false)
                    #if os(watchOS)
                    .ignoresSafeArea()
                    #endif
                    VStack {
                        Spacer()
                        VStack {
                            #if !os(watchOS)
                            if !isShowingLyrics && !isShowingPlaylists {
                                HStack {
                                    Rectangle()
                                        .fill(Color.clear)
                                        .overlay {
                                            VStack(alignment: .leading, spacing: 3) {
                                                MarqueeText(text: nowPlaying.sourceTrack.name, font: .systemFont(ofSize: 14, weight: .bold), leftFade: 15, rightFade: 15, startDelay: 4, alignment: .leading)
                                                Menu(nowPlaying.sourceTrack.artists.map { $0.name }.joined(separator: "/")) {
                                                    ForEach(nowPlaying.sourceTrack.artists) { artist in
                                                        Button(action: {
                                                            gotoArtistSubject.send(artist.id)
                                                        }, label: {
                                                            Label(artist.name, systemImage: "music.microphone")
                                                        })
                                                    }
                                                }
                                                .font(.system(size: 14))
                                                .lineLimit(1)
                                                .foregroundStyle(.white)
                                                .opacity(0.6)
                                            }
                                        }
                                        .matchedGeometryEffect(id: "Info", in: coverEffectNamespace, isSource: !isShowingLyrics)
                                        .frame(height: 100)
                                    Spacer()
                                    Rectangle()
                                        .fill(Color.clear)
                                        .overlay {
                                            HStack(spacing: 10) {
                                                if isLoggedIn {
                                                    StarButton(isStarred: $isNowPlayingStarred) {
                                                        requestJSON("\(apiBaseURL)/like?id=\(nowPlaying.sourceTrack.id)&like=\(!isNowPlayingStarred)", headers: globalRequestHeaders) { _, _ in }
                                                        isNowPlayingStarred.toggle()
                                                    }
                                                }
                                                Menu {
                                                    nowPlaying.sourceTrack.contextActions
                                                } label: {
                                                    Image(systemName: "ellipsis")
                                                        .font(.system(size: 14, weight: .bold))
                                                        .foregroundStyle(.white)
                                                        .padding(6)
                                                }
                                                .menuStyle(.button)
                                                .buttonStyle(.bordered)
                                                .buttonBorderShape(.circle)
                                                .padding(.horizontal, -10)
                                            }
                                        }
                                        .matchedGeometryEffect(id: "Control", in: coverEffectNamespace, isSource: !isShowingLyrics)
                                        .frame(width: 100, height: 80)
                                }
                                .padding(.horizontal, 30)
                            }
                            #endif
                            VStack {
                                CustomProgressView(value: isProgressDraging ? progressDragingNewTime : currentPlaybackTime, total: currentItemTotalTime)
                                    .shadow(radius: isProgressDraging ? 2 : 0)
                                    .gesture(
                                        DragGesture()
                                            .onChanged { value in
                                                isProgressDraging = true
                                                let newTime = currentPlaybackTime + value.translation.width
                                                if newTime >= 0 && newTime <= currentItemTotalTime {
                                                    progressDragingNewTime = newTime
                                                } else {
                                                    if newTime < 0 {
                                                        progressDragingNewTime = 0
                                                    } else if newTime > currentItemTotalTime {
                                                        progressDragingNewTime = currentItemTotalTime
                                                    }
                                                }
                                            }
                                            .onEnded { _ in
                                                globalAudioPlayer.seek(to: CMTime(seconds: progressDragingNewTime, preferredTimescale: 60000),
                                                                       toleranceBefore: .zero,
                                                                       toleranceAfter: .zero)
                                                currentPlaybackTime = progressDragingNewTime
                                                var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()
                                                nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentPlaybackTime
                                                MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
                                                isProgressDraging = false
                                            }
                                    )
                                    .frame(height: 20)
                                HStack {
                                    Text(formattedTime(from: currentPlaybackTime))
                                        .font(.system(size: 11, weight: .semibold))
                                    Spacer()
                                    Text(formattedTime(from: currentItemTotalTime))
                                        .font(.system(size: 11, weight: .semibold))
                                }
                                .padding(.top, -14)
                            }
                            .opacity(isProgressDraging ? 1 : 0.6)
                            .scaleEffect(isProgressDraging ? 1.05 : 1)
                            .contentShape(Rectangle())
                            .animation(.easeOut(duration: 0.2), value: isProgressDraging)
                            #if !os(watchOS)
                            .padding(.horizontal, 30)
                            #else
                            .padding(.horizontal, 5)
                            #endif
                            #if !os(watchOS)
                            HStack {
                                Spacer()
                                Button(action: {
                                    globalAudioPlayer.seek(
                                        to: CMTime(seconds: globalAudioPlayer.currentTime().seconds - 10, preferredTimescale: 60000),
                                        toleranceBefore: .zero,
                                        toleranceAfter: .zero)
                                    var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()
                                    nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = globalAudioPlayer.currentTime().seconds - 10
                                    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
                                    resetMenuDismissTimer()
                                }, label: {
                                    Image(systemName: "10.arrow.trianglehead.counterclockwise")
                                        .font(.system(size: 30))
                                })
                                .buttonStyle(ControlButtonStyle())
                                .frame(width: 50, height: 50)
                                Button(action: {
                                    if isPlaying {
                                        globalAudioPlayer.pause()
                                    } else {
                                        globalAudioPlayer.play()
                                    }
                                    resetMenuDismissTimer()
                                }, label: {
                                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                        .font(.system(size: 50))
                                })
                                .buttonStyle(ControlButtonStyle())
                                .frame(width: 75, height: 75)
                                .padding(.horizontal, 40)
                                Button(action: {
                                    globalAudioPlayer.seek(
                                        to: CMTime(seconds: globalAudioPlayer.currentTime().seconds + 10, preferredTimescale: 60000),
                                        toleranceBefore: .zero,
                                        toleranceAfter: .zero)
                                    var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()
                                    nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = globalAudioPlayer.currentTime().seconds + 10
                                    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
                                    resetMenuDismissTimer()
                                }, label: {
                                    Image(systemName: "10.arrow.trianglehead.clockwise")
                                        .font(.system(size: 30))
                                })
                                .buttonStyle(ControlButtonStyle())
                                .frame(width: 50, height: 50)
                                Spacer()
                            }
                            .padding(.horizontal, 5)
                            .padding(.bottom, 30)
                            #else
                            HStack {
                                Button(action: {
                                    globalAudioPlayer.seek(
                                        to: CMTime(seconds: globalAudioPlayer.currentTime().seconds - 10, preferredTimescale: 60000),
                                        toleranceBefore: .zero,
                                        toleranceAfter: .zero)
                                    var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()
                                    nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = globalAudioPlayer.currentTime().seconds - 10
                                    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
                                    resetMenuDismissTimer()
                                }, label: {
                                    Image(systemName: "10.arrow.trianglehead.counterclockwise")
                                        .font(.system(size: 20))
                                })
                                .buttonStyle(ControlButtonStyle())
                                .frame(width: 35, height: 35)
                                Spacer()
                                Button(action: {
                                    if isPlaying {
                                        globalAudioPlayer.pause()
                                    } else {
                                        globalAudioPlayer.play()
                                    }
                                    resetMenuDismissTimer()
                                }, label: {
                                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                        .font(.system(size: 30))
                                })
                                .buttonStyle(ControlButtonStyle())
                                .frame(width: 40, height: 40)
                                Spacer()
                                Button(action: {
                                    switch playbackBehavior {
                                    case .pause:
                                        playbackBehavior = .singleLoop
                                    case .singleLoop:
                                        playbackBehavior = .listLoop
                                    case .listLoop:
                                        playbackBehavior = .pause
                                    }
                                    resetMenuDismissTimer()
                                }, label: {
                                    switch playbackBehavior {
                                    case .pause:
                                        Image(systemName: "repeat")
                                            .font(.system(size: 20))
                                            .foregroundStyle(.white)
                                            .opacity(0.6)
                                    case .singleLoop:
                                        RoundedRectangle(cornerRadius: 7)
                                            .fill(Color.white.opacity(0.6))
                                            .frame(width: 30, height: 30)
                                            .reversedMask {
                                                Image(systemName: "repeat.1")
                                                    .font(.system(size: 20))
                                            }
                                    case .listLoop:
                                        RoundedRectangle(cornerRadius: 7)
                                            .fill(Color.white.opacity(0.6))
                                            .frame(width: 30, height: 30)
                                            .reversedMask {
                                                Image(systemName: "repeat")
                                                    .font(.system(size: 20))
                                            }
                                    }
                                })
                                .buttonStyle(.borderless)
                            }
                            .padding(.horizontal, 30)
                            #endif
                            #if !os(watchOS)
                            HStack {
                                Image(systemName: "speaker.fill")
                                    .font(.system(size: 14))
                                CustomProgressView(value: isVolumeDraging ? volumeDragingNewValue : Double(currentVolume))
                                    .shadow(radius: isVolumeDraging ? 2 : 0)
                                    .gesture(
                                        DragGesture()
                                            .onChanged { value in
                                                isVolumeDraging = true
                                                let newVolume = Double(currentVolume) + value.translation.width / 240
                                                if newVolume >= 0 && newVolume <= 1 {
                                                    volumeDragingNewValue = newVolume
                                                }
                                            }
                                            .onEnded { _ in
                                                updateSystemVolumeSubject.send(Float(volumeDragingNewValue))
                                                isVolumeDraging = false
                                            }
                                    )
                                    .frame(height: 6)
                                Image(systemName: "speaker.wave.3.fill")
                                    .font(.system(size: 14))
                            }
                            .opacity(0.6)
                            .scaleEffect(isVolumeDraging ? 1.05 : 1)
                            .contentShape(Rectangle())
                            .padding(.horizontal, 40)
                            .animation(.easeOut(duration: 0.2), value: isVolumeDraging)
                            #endif
                            #if !os(watchOS)
                            HStack {
                                Spacer()
                                Button(action: {
                                    withAnimation(.easeOut) {
                                        isShowingLyrics.toggle()
                                        isShowingPlaylists = false
                                    }
                                    isShowingControls = true
                                    resetMenuDismissTimer()
                                }, label: {
                                    if isShowingLyrics {
                                        RoundedRectangle(cornerRadius: 7)
                                            .fill(Color.white.opacity(0.6))
                                            .frame(width: 30, height: 30)
                                            .reversedMask {
                                                Image(systemName: "quote.bubble")
                                                    .font(.system(size: 20))
                                            }
                                    } else {
                                        Image(systemName: "quote.bubble")
                                            .font(.system(size: 20))
                                            .foregroundStyle(.white)
                                            .opacity(0.6)
                                    }
                                })
                                .buttonStyle(.borderless)
                                Spacer()
                                GenericUIViewRepresentable(view: {
                                    let view = AVRoutePickerView()
                                    view.tintColor = UIColor(white: 1, alpha: 0.6)
                                    view.activeTintColor = UIColor(white: 1, alpha: 0.6)
                                    return view
                                }())
                                .frame(width: 50, height: 50)
                                Spacer()
                                Button(action: {
                                    withAnimation(.easeOut) {
                                        isShowingPlaylists.toggle()
                                        isShowingLyrics = false
                                    }
                                    isShowingControls = true
                                    resetMenuDismissTimer()
                                }, label: {
                                    if isShowingPlaylists {
                                        RoundedRectangle(cornerRadius: 7)
                                            .fill(Color.white.opacity(0.6))
                                            .frame(width: 30, height: 30)
                                            .reversedMask {
                                                Image(systemName: "list.bullet")
                                                    .font(.system(size: 20))
                                            }
                                    } else {
                                        Image(systemName: "list.bullet")
                                            .font(.system(size: 20))
                                            .foregroundStyle(.white)
                                            .opacity(0.6)
                                    }
                                })
                                .buttonStyle(.borderless)
                                Spacer()
                            }
                            .padding(.top)
                            #endif
                        }
                        #if !os(watchOS)
                        .padding(.bottom, 40)
                        #endif
                        .opacity(isShowingControls || nowPlaying.lyrics == nil || !isShowingLyrics ? 1.0 : 0.0)
                        .offset(y: isShowingControls || nowPlaying.lyrics == nil || !isShowingLyrics ? 0 : 10)
                        .animation(.easeOut(duration: 0.2), value: isShowingControls)
                    }
                    .ignoresSafeArea()
                }
                .navigationTitle(nowPlaying.sourceTrack.name)
                .onTapGesture { location in
                    if location.y > screenBounds.height / 2 {
                        isShowingControls = true
                        resetMenuDismissTimer()
                    } else {
                        isShowingControls = false
                    }
                }
            } else {
                Text("未在播放")
            }
        }
        #if os(watchOS)
        .background {
            MeshGradient(width: 3,
                         height: 3,
                         points: [
                            SIMD2<Float>(0.0, 0.0), SIMD2<Float>(0.5, 0.0), SIMD2<Float>(1.0, 0.0),
                            SIMD2<Float>(0.0, 0.5), SIMD2<Float>(0.45, 0.55), SIMD2<Float>(1.0, 0.5),
                            SIMD2<Float>(0.0, 1.0), SIMD2<Float>(0.5, 1.0), SIMD2<Float>(1.0, 1.0)
                         ],
                         colors: backgroundColors,
                         background: .init(uiColor: .darkGray),
                         smoothsColors: true)
            .blur(radius: 10, opaque: true)
            .overlay {
                Color.black.opacity(0.6)
            }
            .ignoresSafeArea()
        }
        #endif
        .onAppear {
            nowPlaying = nowPlayingMedia.value
            isPlaying = globalAudioPlayer.timeControlStatus == .playing
            currentItemTotalTime = globalAudioPlayer.currentItem?.duration.seconds ?? 0.0
            playbackBehavior = PlaybackBehavior.init(rawValue: UserDefaults.standard.string(forKey: "PlaybackBehavior") ?? "singleLoop") ?? .singleLoop
            playlists = PlaylistManager.shared.tracks
            isShowingControls = true
            resetMenuDismissTimer()
            #if os(iOS)
            UIApplication.shared.isIdleTimerDisabled = true
            #endif
            volumeObserver = AVAudioSession.sharedInstance().observe(\.outputVolume, options: .new) { _, observedValue in
                if let newValue = observedValue.newValue {
                    currentVolume = newValue
                }
            }
        }
        .onDisappear {
            #if os(iOS)
            UIApplication.shared.isIdleTimerDisabled = false
            #endif
        }
        .environment(\.colorScheme, .dark)
        .onChange(of: playbackBehavior) {
            UserDefaults.standard.set(playbackBehavior.rawValue, forKey: "PlaybackBehavior")
        }
        .onReceive(nowPlayingMedia) { value in
            nowPlaying = value
        }
        .onReceive(globalAudioPlayer.publisher(for: \.timeControlStatus)) { status in
            isPlaying = status == .playing
            if status != .waitingToPlayAtSpecifiedRate {
                currentItemTotalTime = globalAudioPlayer.currentItem?.duration.seconds ?? 0.0
                debugPrint(currentItemTotalTime)
            }
        }
        .onReceive(globalAudioPlayer.publisher(for: \.currentItem)) { item in
            if let item {
                currentItemTotalTime = item.duration.seconds
            }
        }
        .onReceive(globalAudioPlayer.periodicTimePublisher()) { time in
            // Code in this closure runs at nearly each frame, optimizing for speed is important.
            if time.seconds - currentPlaybackTime >= 0.5 || time.seconds < currentPlaybackTime {
                currentPlaybackTime = time.seconds
            }
        }
        .onReceive(PlaylistManager.shared.publisherForTracks) { tracks in
            playlists = tracks
        }
    }
    
    struct WaitingDotsView: View {
        var startTime: Double
        var endTime: Double
        @State var currentTime = globalAudioPlayer.currentTime().seconds
        @State var dot1Opacity = 0.2
        @State var dot2Opacity = 0.2
        @State var dot3Opacity = 0.2
        @State var scale: CGFloat = 1
        @State var isVisible = false
        @State var verticalPadding: CGFloat = -15
        var body: some View {
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.white)
                        .opacity(dot1Opacity)
                    #if !os(watchOS)
                        .frame(width: 12, height: 12)
                    #else
                        .frame(width: 8, height: 8)
                    #endif
                    Circle()
                        .fill(Color.white)
                        .opacity(dot2Opacity)
                    #if !os(watchOS)
                        .frame(width: 12, height: 12)
                    #else
                        .frame(width: 8, height: 8)
                    #endif
                    Circle()
                        .fill(Color.white)
                        .opacity(dot3Opacity)
                    #if !os(watchOS)
                        .frame(width: 12, height: 12)
                    #else
                        .frame(width: 8, height: 8)
                    #endif
                }
                #if !os(watchOS)
                .padding(.horizontal, 5)
                #else
                .padding()
                #endif
                .scaleEffect(scale)
                Spacer(minLength: 5)
            }
            .padding(.vertical, verticalPadding)
            .opacity(isVisible ? 1.0 : kViewMinimumRenderableOpacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever()) {
                    if scale > 1.0 {
                        scale = 1.0
                    } else {
                        scale = 1.2
                    }
                }
            }
            .onChange(of: currentTime) {
                if _fastPath(!isVisible) {
                    isVisible = currentTime >= startTime + 0.2 && currentTime <= endTime
                }
                if currentTime >= startTime && currentTime <= endTime
                    && dot1Opacity == 0.2 && dot2Opacity == 0.2 && dot3Opacity == 0.2 {
                    let pieceTime = (endTime - startTime - 1.0) / 3.0
                    withAnimation(.linear(duration: pieceTime)) {
                        dot1Opacity = 1.0
                    } completion: {
                        withAnimation(.linear(duration: pieceTime)) {
                            dot2Opacity = 1.0
                        } completion: {
                            withAnimation(.linear(duration: pieceTime)) {
                                dot3Opacity = 1.0
                            } completion: {
                                withAnimation(.easeInOut(duration: 0.6)) {
                                    scale = 1.3
                                } completion: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        scale = 0.02
                                        dot1Opacity = 0.02
                                        dot2Opacity = 0.02
                                        dot3Opacity = 0.02
                                    } completion: {
                                        isVisible = false
                                        Task {
                                            try? await Task.sleep(for: .seconds(0.5))
                                            dot1Opacity = 0.2
                                            dot2Opacity = 0.2
                                            dot3Opacity = 0.2
                                            scale = 1
                                            withAnimation(.easeInOut(duration: 2.0).repeatForever()) {
                                                scale = 1.2
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .onChange(of: isVisible) {
                if isVisible {
                    withAnimation(.easeOut(duration: 0.3)) {
                        verticalPadding = 0
                    }
                } else {
                    withAnimation(.easeOut) {
                        verticalPadding = -15
                    }
                }
            }
            .onReceive(globalAudioPlayer.periodicTimePublisher()) { time in
                if time.seconds - currentTime >= 0.1 || time.seconds < currentTime {
                    currentTime = time.seconds
                }
            }
        }
    }
    struct LyricButtonModifier: ViewModifier {
        var buttonAction: () -> Void
        @State private var isPressed = false
        func body(content: Content) -> some View {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray)
                    .scaleEffect(isPressed ? 0.9 : 1)
                    .opacity(isPressed ? 0.4 : 0)
                content
                    .scaleEffect(isPressed ? 0.9 : 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 10))
            ._onButtonGesture(pressing: { isPressing in
                isPressed = isPressing
            }, perform: buttonAction)
            .onLongPressGesture(minimumDuration: 1.0) {
                
            }
            .animation(.easeOut(duration: 0.2), value: isPressed)
        }
    }
    
    func resetMenuDismissTimer() {
        controlMenuDismissTimer?.invalidate()
        controlMenuDismissTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            if !isProgressDraging && !isVolumeDraging {
                isShowingControls = false
            } else {
                resetMenuDismissTimer()
            }
        }
    }
}

@_effects(readnone)
private func formattedTime(from seconds: Double) -> String {
    if seconds.isNaN {
        return "00:00"
    }
    let minutes = Int(seconds) / 60
    let remainingSeconds = Int(seconds) % 60
    return String(format: "%02d:%02d", minutes, remainingSeconds)
}

struct CustomProgressView: View {
    var value: Double
    var total: Double = 1.0
    var animationDuration: Double = 0.3
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(.white.opacity(0.2))
                    .frame(height: 6)
                Rectangle()
                    .fill(.white)
                    .frame(width: value / total * geometry.size.width, height: 6)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .animation(.linear(duration: animationDuration), value: value)
        }
    }
}

struct ControlButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Circle()
                .fill(Color.gray)
                .scaleEffect(configuration.isPressed ? 0.9 : 1)
                .opacity(configuration.isPressed ? 0.4 : kViewMinimumRenderableOpacity)
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.9 : 1)
        }
    }
}
