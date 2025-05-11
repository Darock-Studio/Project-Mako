//
//  MakoApp.swift
//  Mako
//
//  Created by Mark Chan on 2025/5/5.
//

import SwiftUI
import SDWebImage
import MediaPlayer
import AVFoundation
import DarockFoundation

@main
struct MakoApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor var appDelegate: AppDelegate
    #else
    @WKApplicationDelegateAdaptor var appDelegate: AppDelegate
    #endif
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

#if os(iOS)
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        SDImageCache.shared.config.shouldCacheImagesInMemory = false
        SDImageCache.shared.config.shouldUseWeakMemoryCache = true
        
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.addTarget { _ in
            globalAudioPlayer.play()
            return .success
        }
        commandCenter.pauseCommand.addTarget { _ in
            globalAudioPlayer.pause()
            return .success
        }
        commandCenter.skipForwardCommand.addTarget { _ in
            globalAudioPlayer.seek(
                to: CMTime(seconds: globalAudioPlayer.currentTime().seconds + 15, preferredTimescale: 60000),
                toleranceBefore: .zero,
                toleranceAfter: .zero)
            return .success
        }
        commandCenter.skipBackwardCommand.addTarget { _ in
            globalAudioPlayer.seek(
                to: CMTime(seconds: globalAudioPlayer.currentTime().seconds - 15, preferredTimescale: 60000),
                toleranceBefore: .zero,
                toleranceAfter: .zero)
            return .success
        }
        MPRemoteCommandCenter.shared().changePlaybackPositionCommand.isEnabled = true
        MPRemoteCommandCenter.shared().changePlaybackPositionCommand.addTarget { event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            let time = CMTime(seconds: event.positionTime, preferredTimescale: 60000)
            globalAudioPlayer.seek(to: time) { _ in
                MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = event.positionTime
            }
            return .success
        }
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        if let _latestNowPlaying = try? String(contentsOfFile: NSHomeDirectory() + "/Documents/LatestNowPlaying.json", encoding: .utf8),
           var latestNowPlaying = getJsonData(NowPlayingInfo.self, from: _latestNowPlaying) {
            latestNowPlaying.preventAutoPlaying = true
            nowPlayingMedia.send(latestNowPlaying)
            Task {
                latestNowPlaying.playURL = await getPlayURL(forTrackID: latestNowPlaying.sourceTrack.id)
                nowPlayingMedia.send(latestNowPlaying)
            }
        }
        
        if !UserDefaults.standard.bool(forKey: "IsLoggedIn") {
            requestJSON("\(apiBaseURL)/register/anonimous") { respJson, isSuccess in
                if isSuccess, let cookie = respJson["cookie"].string {
                    UserDefaults.standard.set(
                        cookie
                            .components(separatedBy: ";")
                            .map { $0.trimmingCharacters(in: .whitespaces) }
                            .filter { $0.contains("=") && !$0.lowercased().hasPrefix("max-age") && !$0.lowercased().hasPrefix("expires") && !$0.lowercased().hasPrefix("path") }
                            .joined(separator: "; "),
                        forKey: "AccountCookie"
                    )
                }
            }
        }
        
        return true
    }
}
#else
class AppDelegate: NSObject, WKApplicationDelegate {
    func applicationDidFinishLaunching() {
        SDImageCache.shared.config.shouldCacheImagesInMemory = false
        SDImageCache.shared.config.shouldUseWeakMemoryCache = true
        
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.addTarget { _ in
            globalAudioPlayer.play()
            return .success
        }
        commandCenter.pauseCommand.addTarget { _ in
            globalAudioPlayer.pause()
            return .success
        }
        commandCenter.skipForwardCommand.addTarget { _ in
            globalAudioPlayer.seek(
                to: CMTime(seconds: globalAudioPlayer.currentTime().seconds + 15, preferredTimescale: 60000),
                toleranceBefore: .zero,
                toleranceAfter: .zero)
            return .success
        }
        commandCenter.skipBackwardCommand.addTarget { _ in
            globalAudioPlayer.seek(
                to: CMTime(seconds: globalAudioPlayer.currentTime().seconds - 15, preferredTimescale: 60000),
                toleranceBefore: .zero,
                toleranceAfter: .zero)
            return .success
        }
        MPRemoteCommandCenter.shared().changePlaybackPositionCommand.isEnabled = true
        MPRemoteCommandCenter.shared().changePlaybackPositionCommand.addTarget { event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            let time = CMTime(seconds: event.positionTime, preferredTimescale: 60000)
            globalAudioPlayer.seek(to: time) { _ in
                MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = event.positionTime
            }
            return .success
        }
        
        if let _latestNowPlaying = try? String(contentsOfFile: NSHomeDirectory() + "/Documents/LatestNowPlaying.json", encoding: .utf8),
           var latestNowPlaying = getJsonData(NowPlayingInfo.self, from: _latestNowPlaying) {
            latestNowPlaying.preventAutoPlaying = true
            nowPlayingMedia.send(latestNowPlaying)
            Task {
                latestNowPlaying.playURL = await getPlayURL(forTrackID: latestNowPlaying.sourceTrack.id)
                nowPlayingMedia.send(latestNowPlaying)
            }
        }
        
        if !UserDefaults.standard.bool(forKey: "IsLoggedIn") {
            requestJSON("\(apiBaseURL)/register/anonimous") { respJson, isSuccess in
                if isSuccess, let cookie = respJson["cookie"].string {
                    UserDefaults.standard.set(
                        cookie
                            .components(separatedBy: ";")
                            .map { $0.trimmingCharacters(in: .whitespaces) }
                            .filter { $0.contains("=") && !$0.lowercased().hasPrefix("max-age") && !$0.lowercased().hasPrefix("expires") && !$0.lowercased().hasPrefix("path") }
                            .joined(separator: "; "),
                        forKey: "AccountCookie"
                    )
                }
            }
        }
    }
}
#endif
