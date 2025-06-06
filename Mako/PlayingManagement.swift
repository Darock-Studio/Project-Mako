//
//  PlayingManagement.swift
//  Mako
//
//  Created by Mark Chan on 2025/5/10.
//

import AVKit
import OSLog
import Combine
import Foundation
import AVFoundation
import DarockFoundation

var globalAudioPlayer = AVPlayer()
var nowPlayingMedia = CurrentValueSubject<NowPlayingInfo?, Never>(nil)
var currentPlaybackEndObserver: Any?

class PlaylistManager {
    static let shared = PlaylistManager()
    
    let publisherForTracks = PassthroughSubject<[Track], Never>()
    private(set) var tracks: [Track] {
        get {
            playlist
        }
        set {
            playlist = newValue
            publisherForTracks.send(newValue)
            if let jsonString = jsonString(from: newValue) {
                try? jsonString.write(toFile: NSHomeDirectory() + "/Documents/Playlist.json", atomically: true, encoding: .utf8)
            }
        }
    }
    var isEmpty: Bool { tracks.isEmpty }
    
    private var playlist = [Track]()
    
    private init() {
        if let jsonString = try? String(contentsOfFile: NSHomeDirectory() + "/Documents/Playlist.json", encoding: .utf8) {
            playlist = getJsonData([Track].self, from: jsonString) ?? []
        }
    }
    
    func replace(with tracks: [Track], playFirst: Bool = true) {
        self.tracks = tracks
        if playFirst {
            playNext()
            UserDefaults.standard.set(PlaybackBehavior.listLoop.rawValue, forKey: "PlaybackBehavior")
        }
    }
    func append(_ track: Track) {
        tracks.append(track)
    }
    func insertFirst(_ track: Track) {
        tracks.insert(track, at: 0)
    }
    func move(fromOffsets from: IndexSet, toOffset to: Int) {
        tracks.move(fromOffsets: from, toOffset: to)
    }
    func remove(at index: Int) {
        tracks.remove(at: index)
    }
    func remove(atOffsets offsets: IndexSet) {
        tracks.remove(atOffsets: offsets)
    }
    func removeAll() {
        tracks.removeAll()
    }
    
    @discardableResult
    func playNext() async -> Track? {
        if !tracks.isEmpty {
            let playing = tracks.removeFirst()
            tracks.append(playing)
            await playTrack(playing)
            return playing
        } else {
            return nil
        }
    }
    func playNext(completion: ((Track?) -> Void)? = nil) {
        if !tracks.isEmpty {
            let playing = tracks.removeFirst()
            tracks.append(playing)
            Task {
                await playTrack(playing)
                completion?(playing)
            }
        } else {
            completion?(nil)
        }
    }
    
    
}

func playTrack(_ track: Track) async {
    var lyrics = [Double: String]()
    let result = await requestJSON("\(apiBaseURL)/lyric?id=\(track.id)", headers: globalRequestHeaders)
    if case let .success(respJson) = result {
        if let lyric = respJson["lrc"]["lyric"].string {
            let lineSpd = lyric.components(separatedBy: "\n")
            for lineText in lineSpd {
                if lineText.contains(/\[[0-9]*:[0-9]*.[0-9]*\].*/) {
                    if let text = lineText.components(separatedBy: "]")[from: 1],
                       let time = lineText.components(separatedBy: "[")[from: 1]?.components(separatedBy: "]")[from: 0],
                       let dTime = lyricTimeStringToSeconds(String(time)) {
                        lyrics.updateValue(String(text).removePrefix(" "), forKey: dTime)
                    }
                }
            }
            if let tlyric = respJson["tlyric"]["lyric"].string {
                let lineSpd = tlyric.components(separatedBy: "\n")
                for lineText in lineSpd {
                    if lineText.contains(/\[[0-9]*:[0-9]*.[0-9]*\].*/) {
                        if let text = lineText.components(separatedBy: "]")[from: 1],
                           let time = lineText.components(separatedBy: "[")[from: 1]?.components(separatedBy: "]")[from: 0],
                           let dTime = lyricTimeStringToSeconds(String(time)),
                           let sourceLyric = lyrics[dTime],
                           !sourceLyric.isEmpty && !text.isEmpty {
                            lyrics.updateValue("\(sourceLyric)%tranlyric@\(text.removePrefix(" "))", forKey: dTime)
                        }
                    }
                }
            }
        }
        var credits = [String]()
        for key in lyrics.keys.sorted() {
            let value = lyrics[key]!
            if value.contains(/^.*：.*$/) || value.contains(/^.*:.*$/) {
                credits.append(value)
                lyrics.removeValue(forKey: key)
            } else {
                break
            }
        }
        if !credits.isEmpty, let lastKey = lyrics.keys.sorted().last {
            lyrics.updateValue("%credits@\(credits.joined(separator: "\n"))", forKey: lastKey + 100)
        }
    }
    let playURL = await getPlayURL(forTrackID: track.id)
    DispatchQueue.main.async {
        nowPlayingMedia.send(.init(sourceTrack: track, playURL: playURL, lyrics: !lyrics.isEmpty ? lyrics : nil))
    }
}
func getPlayURL(forTrackID id: Int64) async -> String {
    var playURL: String?
    if UserDefaults.standard.string(forKey: "AccountCookie") != nil {
        let quality: String
        if UserDefaults.standard.bool(forKey: "AQIsLoselessAudioEnabled") {
            let celluarStreamQuality = AudioQuality(rawValue: UserDefaults.standard.string(forKey: "AQCelluarStreamQuality") ?? "") ?? .highQuality
            let wifiStreamQuality = AudioQuality(rawValue: UserDefaults.standard.string(forKey: "AQWiFiStreamQuality") ?? "") ?? .highQuality
            #if !os(watchOS)
            quality = reachability == .wifi ? wifiStreamQuality.requestParameter : celluarStreamQuality.requestParameter
            #else
            quality = wifiStreamQuality.requestParameter
            #endif
        } else {
            #if !os(watchOS)
            quality = reachability == .wifi ? "exhigh" : "higher"
            #else
            quality = "higher"
            #endif
        }
        let result = await requestJSON("\(apiBaseURL)/song/url/v1?id=\(id)&level=\(quality)", headers: globalRequestHeaders)
        if case let .success(respJson) = result {
            playURL = respJson["data"][0]["url"].string
        }
    }
    if playURL == nil {
        playURL = "https://music.163.com/song/media/outer/url?id=\(id).mp3"
        Logger().error("Failed to get high quality music playing URL, falling back to lower one.")
    }
    return playURL!
}

@_effects(readnone)
private func lyricTimeStringToSeconds(_ timeString: String) -> Double? {
    let components = timeString.split(separator: ":")
    guard components.count == 2,
          let minutes = Double(components[0]),
          let seconds = Double(components[1]) else {
        return nil
    }
    return minutes * 60 + seconds
}

extension String {
    func removePrefix(_ c: String) -> Self {
        var selfCopy = self
        while selfCopy.hasPrefix(c) {
            selfCopy.removeFirst()
        }
        return selfCopy
    }
}
