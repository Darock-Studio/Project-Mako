//
//  ContentView.swift
//  Mako
//
//  Created by Mark Chan on 2025/5/5.
//

import SwiftUI
import DarockUI
import MediaPlayer
import DarockFoundation
import SDWebImageSwiftUI
@_spi(Advanced) import SwiftUIIntrospect

#if os(iOS)
import BottomSheet
#endif

struct ContentView: View {
    @FocusState var isSearchKeyboardFocused: Bool
    @Namespace var nowPlayingCoverEffectNamespace
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("IsLoggedIn") var isLoggedIn = false
    @AppStorage("MainTabSelection") var tabSelection = 1
    @AppStorage("IsNowPlayingShowingLyrics") var isNowPlayingShowingLyrics = true
    @State var nowPlayingTrack: Track?
    @State var nowPlayingBackgroundColors = Array(repeating: Color(uiColor: .darkGray), count: 16)
    @State var isAccountManagementPresented = false
    @State var isNowPlayingStarred = false
    @State var isNowPlaying = false
    @State var presentingCommentsID: Int64?
    #if os(iOS)
    @State var nowPlayingSheetPosition = BottomSheetPosition.hidden
    @State var _volumeView = MPVolumeView()
    #endif
    var body: some View {
        ZStack(alignment: .bottom) {
            #if os(iOS)
            GenericUIViewRepresentable(view: _volumeView)
                .offset(x: 1000, y: 1000)
                .onReceive(updateSystemVolumeSubject) { value in
                    let slider = _volumeView.subviews.first(where: { $0 is UISlider }) as! UISlider
                    slider.value = value
                }
                .wrapIf(nowPlayingSheetPosition != .relativeTop(1)) { content in
                    content
                        .hidden()
                }
            #endif
            TabView(selection: $tabSelection.onUpdate { oldValue, newValue in
                if oldValue == newValue && newValue == 3 {
                    isSearchKeyboardFocused = true
                }
            }) {
                Group {
                    NavigationStack {
                        HomeView()
                            .subjectNavigatable()
                        #if !os(watchOS)
                            .toolbar {
                                ToolbarItem(placement: .topBarTrailing) {
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
                    .tag(1)
                    .tabItem {
                        Image(_internalSystemName: "home.fill")
                        Text("主页")
                    }
                    NavigationStack {
                        LibraryView()
                            .subjectNavigatable()
                            .toolbar {
                                ToolbarItem(placement: .topBarTrailing) {
                                    Button(action: {
                                        isAccountManagementPresented = true
                                    }, label: {
                                        Image(systemName: "person.crop.circle")
                                            .font(.system(size: 22, weight: .semibold))
                                            .foregroundStyle(.accent)
                                    })
                                }
                            }
                    }
                    .tag(2)
                    .tabItem {
                        Image(_internalSystemName: "music.square.stack.fill")
                        Text("资料库")
                    }
                    NavigationStack {
                        SearchView(isSearchKeyboardFocused: $isSearchKeyboardFocused)
                            .subjectNavigatable()
                        #if !os(watchOS)
                            .toolbar {
                                ToolbarItem(placement: .topBarTrailing) {
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
                    .tag(3)
                    .tabItem {
                        Image(systemName: "magnifyingglass")
                        Text("搜索")
                    }
                }
                #if os(iOS)
                .overlay {
                    VStack {
                        Spacer()
                        nowPlayingView
                    }
                }
                .ignoresSafeArea(.keyboard)
                .ignoresSafeArea(edges: .bottom)
                #endif
            }
            #if os(iOS)
            .introspect(.tabView, on: .iOS(.v18...)) { tabView in
                let tabBar = tabView.tabBar
                let appearance = UITabBarAppearance()
                appearance.configureWithTransparentBackground()
                tabBar.standardAppearance = appearance
                tabBar.scrollEdgeAppearance = appearance
            }
            #endif
            .onReceive(performSearchSubject) { text in
                if tabSelection != 3 {
                    tabSelection = 3
                    performSearchSubject.send(text)
                }
                #if os(iOS)
                nowPlayingSheetPosition = .hidden
                #endif
            }
            #if os(iOS)
            .onReceive(gotoArtistSubject) { _ in
                nowPlayingSheetPosition = .hidden
            }
            .onReceive(gotoAlbumSubject) { _ in
                nowPlayingSheetPosition = .hidden
            }
            #endif
        }
        #if os(iOS)
        .bottomSheet(bottomSheetPosition: $nowPlayingSheetPosition, switchablePositions: [.hidden, .relativeTop(1)]) {
            VStack {
                Capsule()
                    .fill(Color(UIColor.tertiaryLabel))
                    .frame(width: 36, height: 5)
                    .centerAligned()
                    .allowsHitTesting(false)
                HStack(spacing: 10) {
                    if let nowPlayingTrack {
                        if isNowPlayingShowingLyrics {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.clear)
                                .overlay {
                                    WebImage(url: URL(string: nowPlayingTrack.album.picUrl)) { image in
                                        image.resizable()
                                    } placeholder: {
                                        Rectangle()
                                            .fill(Color.gray)
                                            .redacted(reason: .placeholder)
                                    }
                                    .scaledToFill()
                                    .cornerRadius(6)
                                }
                                .matchedGeometryEffect(id: "Cover", in: nowPlayingCoverEffectNamespace, isSource: isNowPlayingShowingLyrics)
                                .frame(width: 80, height: 80)
                                .onTapGesture {
                                    withAnimation(.easeOut) {
                                        isNowPlayingShowingLyrics = false
                                    }
                                }
                            Rectangle()
                                .fill(Color.clear)
                                .overlay {
                                    VStack(alignment: .leading, spacing: 3) {
                                        MarqueeText(text: nowPlayingTrack.name, font: .systemFont(ofSize: 14, weight: .bold), leftFade: 15, rightFade: 15, startDelay: 4, alignment: .leading)
                                        Menu(nowPlayingTrack.artists.map { $0.name }.joined(separator: "/")) {
                                            ForEach(nowPlayingTrack.artists) { artist in
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
                                .matchedGeometryEffect(id: "Info", in: nowPlayingCoverEffectNamespace, isSource: isNowPlayingShowingLyrics)
                                .frame(height: 80)
                            Rectangle()
                                .fill(Color.clear)
                                .overlay {
                                    HStack(spacing: 10) {
                                        if isLoggedIn {
                                            StarButton(isStarred: $isNowPlayingStarred) {
                                                requestJSON("\(apiBaseURL)/like?id=\(nowPlayingTrack.id)&like=\(!isNowPlayingStarred)", headers: globalRequestHeaders) { _, _ in }
                                                isNowPlayingStarred.toggle()
                                            }
                                        }
                                        Menu {
                                            nowPlayingTrack.contextActions
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
                                .matchedGeometryEffect(id: "Control", in: nowPlayingCoverEffectNamespace, isSource: isNowPlayingShowingLyrics)
                                .frame(width: 100, height: 80)
                        }
                    }
                }
            }
            .padding()
            .padding(.horizontal)
            .padding(.top, UIApplication.shared.windows.filter { $0.isKeyWindow }.first!.safeAreaInsets.top)
            .environment(\.colorScheme, .dark)
        } mainContent: {
            NowPlayingView(backgroundColors: nowPlayingBackgroundColors, coverEffectNamespace: nowPlayingCoverEffectNamespace, isShowingLyrics: $isNowPlayingShowingLyrics, isNowPlayingStarred: $isNowPlayingStarred)
                .mask {
                    if isNowPlayingShowingLyrics {
                        LinearGradient(colors: [.black.opacity(0), .black, .black, .black, .black, .black, .black, .black], startPoint: .top, endPoint: .bottom)
                    } else {
                        Rectangle()
                    }
                }
        }
        .showDragIndicator(false)
        .enableSwipeToDismiss()
        .enableFloatingIPadSheet(false)
        .sheetWidth(.absolute(UIScreen.main.bounds.width))
        .customAnimation(.spring(response: 0.4, dampingFraction: 1, blendDuration: 0.8))
        .customBackground {
            MeshGradient(width: 3,
                         height: 3,
                         points: [
                            SIMD2<Float>(0.0, 0.0), SIMD2<Float>(0.5, 0.0), SIMD2<Float>(1.0, 0.0),
                            SIMD2<Float>(0.0, 0.5), SIMD2<Float>(0.45, 0.55), SIMD2<Float>(1.0, 0.5),
                            SIMD2<Float>(0.0, 1.0), SIMD2<Float>(0.5, 1.0), SIMD2<Float>(1.0, 1.0)
                         ],
                         colors: nowPlayingBackgroundColors,
                         background: .init(uiColor: .darkGray),
                         smoothsColors: true)
            .blur(radius: 10, opaque: true)
            .overlay {
                Color.black.opacity(0.6)
            }
            .clipShape(RoundedRectangle(cornerRadius: (presentingCommentsID == nil) ? (UIScreen.main.value(forKey: "_displayCornerRadius") as! Double) : 0))
            .padding(-2)
        }
        .customThreshold(0.1)
        .ignoresSafeArea(edges: .top)
        #endif
        .sheet(isPresented: $isAccountManagementPresented, content: { AccountView() })
        .sheet(item: $presentingCommentsID) { id in
            NavigationStack {
                CommentsView(id: id)
            }
        }
        .onReceive(nowPlayingMedia) { media in
            if let media {
                globalAudioPlayer.replaceCurrentItem(with: AVPlayerItem(url: URL(string: media.playURL)!))
                if !media.preventAutoPlaying {
                    try? AVAudioSession.sharedInstance().setActive(true)
                    globalAudioPlayer.play()
                }
                nowPlayingTrack = media.sourceTrack
                isNowPlayingStarred = false
                if isLoggedIn {
                    requestJSON("\(apiBaseURL)/likelist", headers: globalRequestHeaders) { respJson, isSuccess in
                        if isSuccess, let ids = respJson["ids"].arrayObject as? [Int64] {
                            isNowPlayingStarred = ids.contains(media.sourceTrack.id)
                        }
                    }
                }
                DispatchQueue(label: "com.darock.Mako.UpdateNowPlayingInfo", qos: .utility).async {
                    var nowPlayingInfo = [String: Any]()
                    if let imageUrl = URL(string: media.sourceTrack.album.picUrl),
                       let imageData = try? Data(contentsOf: imageUrl),
                       let image = UIImage(data: imageData) {
                        nowPlayingBackgroundColors = ColorThief.getPalette(from: image, colorCount: 16)!.map {
                            Color(red: Double($0.r) / 255, green: Double($0.g) / 255, blue: Double($0.b) / 255)
                        }
                        nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                    }
                    nowPlayingInfo[MPMediaItemPropertyTitle] = media.sourceTrack.name
                    nowPlayingInfo[MPMediaItemPropertyArtist] = media.sourceTrack.artists.map { $0.name }.joined(separator: "/")
                    nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = media.sourceTrack.album.name
                    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
                }
                if let observer = currentPlaybackEndObserver {
                    NotificationCenter.default.removeObserver(observer)
                    currentPlaybackEndObserver = nil
                }
                currentPlaybackEndObserver = NotificationCenter.default.addObserver(
                    forName: AVPlayerItem.didPlayToEndTimeNotification,
                    object: globalAudioPlayer.currentItem,
                    queue: .main
                ) { _ in
                    let playbackBehavior = PlaybackBehavior.init(rawValue: UserDefaults.standard.string(forKey: "PlaybackBehavior") ?? "singleLoop") ?? .pause
                    if playbackBehavior == .singleLoop {
                        globalAudioPlayer.seek(to: .zero)
                        globalAudioPlayer.play()
                    } else if playbackBehavior == .listLoop {
                        
                    }
                }
                if let jsonData = jsonString(from: media) {
                    try? jsonData.write(toFile: NSHomeDirectory() + "/Documents/LatestNowPlaying.json", atomically: true, encoding: .utf8)
                }
            }
        }
        .onReceive(globalAudioPlayer.publisher(for: \.timeControlStatus)) { status in
            isNowPlaying = status == .playing
            MPNowPlayingInfoCenter.default().playbackState = status == .playing ? .playing : .paused
        }
        .onReceive(globalAudioPlayer.publisher(for: \.currentItem)) { item in
            if let item {
                var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()
                nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = item.duration.seconds
                nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0.0
                nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
                nowPlayingInfo[MPNowPlayingInfoPropertyDefaultPlaybackRate] = 1.0
                MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            }
        }
        .onReceive(presentCommentsSubject) { id in
            presentingCommentsID = id
        }
    }
    
    #if os(iOS)
    var nowPlayingView: some View {
        HStack {
            if let nowPlayingTrack {
                WebImage(url: URL(string: nowPlayingTrack.album.picUrl)) { image in
                    image.resizable()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray)
                        .redacted(reason: .placeholder)
                }
                .scaledToFill()
                .frame(width: 40, height: 40)
                .clipped()
                .cornerRadius(10)
                Text(nowPlayingTrack.name)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                Spacer()
                Button(action: {
                    if isNowPlaying {
                        globalAudioPlayer.pause()
                    } else {
                        globalAudioPlayer.play()
                    }
                }, label: {
                    Image(systemName: isNowPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 24))
                })
                .buttonStyle(ControlButtonStyle())
                .frame(width: 40, height: 40)
            } else {
                Text("未在播放")
                Spacer()
            }
        }
        .frame(height: 53)
        .padding(.horizontal, 7)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Material.thick)
                .shadow(radius: 5, x: 1, y: 1)
        )
        .onTapGesture {
            nowPlayingSheetPosition = .relativeTop(1)
        }
        .wrapIf(nowPlayingTrack != nil) { content in
            content
                .contextMenu {
                    nowPlayingTrack!.contextActions
                } preview: {
                    nowPlayingTrack!.previewView
                }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 90)
        .background(
            GenericUIViewRepresentable(view: UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial)))
                .background(colorScheme == .dark ? Color.black.opacity(0.9) : .white.opacity(0.8))
                .mask {
                    LinearGradient(colors: [.black.opacity(0), .black.opacity(0), .black.opacity(0.5), .black.opacity(1), .black.opacity(1), .black.opacity(1), .black.opacity(1), .black.opacity(1), .black.opacity(1), .black.opacity(1), .black.opacity(1)], startPoint: .top, endPoint: .bottom)
                }
        )
    }
    #endif
}
