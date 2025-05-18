//
//  SettingsView.swift
//  Mako
//
//  Created by Mark Chan on 2025/5/16.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            Section {
                NavigationLink(destination: { AudioQualitySettingsView() }, label: {
                    Text("音频质量")
                })
            }
        }
        .formStyle(.grouped)
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    struct AudioQualitySettingsView: View {
        @AppStorage("AQIsLoselessAudioEnabled") var isLoselessAudioEnabled = false
        @State var celluarStreamQuality = AudioQuality.highQuality
        @State var wifiStreamQuality = AudioQuality.highQuality
        @State var downloadQuality = AudioQuality.highQuality
        var body: some View {
            List {
                Section {
                    Toggle("无损音频", isOn: $isLoselessAudioEnabled)
                } footer: {
                    Text("无损文件保留了原始音频的所有细节。打开此设置将显著消耗更多数据。")
                }
                if isLoselessAudioEnabled {
                    Section {
                        NavigationLink(destination: { QualitySelectorView(quality: $celluarStreamQuality) }, label: {
                            HStack {
                                Text("蜂窝网络流播放")
                                Spacer()
                                Text(celluarStreamQuality.localizedName)
                                    .foregroundStyle(.gray)
                            }
                        })
                        NavigationLink(destination: { QualitySelectorView(quality: $wifiStreamQuality) }, label: {
                            HStack {
                                Text("Wi-Fi流播放")
                                Spacer()
                                Text(wifiStreamQuality.localizedName)
                                    .foregroundStyle(.gray)
                            }
                        })
                        NavigationLink(destination: { QualitySelectorView(quality: $downloadQuality) }, label: {
                            HStack {
                                Text("下载")
                                Spacer()
                                Text(downloadQuality.localizedName)
                                    .foregroundStyle(.gray)
                            }
                        })
                    } footer: {
                        Text("之前下载的内容将继续以最初下载时的解析度播放。")
                    }
                }
            }
            .navigationTitle("音频质量")
            .onAppear {
                celluarStreamQuality = .init(rawValue: UserDefaults.standard.string(forKey: "AQCelluarStreamQuality") ?? "") ?? .highQuality
                wifiStreamQuality = .init(rawValue: UserDefaults.standard.string(forKey: "AQWiFiStreamQuality") ?? "") ?? .highQuality
                downloadQuality = .init(rawValue: UserDefaults.standard.string(forKey: "AQDownloadQuality") ?? "") ?? .highQuality
            }
            .onChange(of: celluarStreamQuality) {
                UserDefaults.standard.set(celluarStreamQuality.rawValue, forKey: "AQCelluarStreamQuality")
            }
            .onChange(of: wifiStreamQuality) {
                UserDefaults.standard.set(wifiStreamQuality.rawValue, forKey: "AQWiFiStreamQuality")
            }
            .onChange(of: downloadQuality) {
                UserDefaults.standard.set(downloadQuality.rawValue, forKey: "AQDownloadQuality")
            }
        }
        
        struct QualitySelectorView: View {
            @Binding var quality: AudioQuality
            var body: some View {
                Form {
                    Section {
                        Picker(selection: $quality) {
                            ForEach(AudioQuality.allCases) { q in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(q.localizedName)
                                    Text(q.localizedDetail)
                                        .font(.callout)
                                        .opacity(0.6)
                                }
                                .tag(q)
                            }
                        } label: {
                            
                        }
                        .pickerStyle(.inline)
                    } footer: {
                        Text("""
                        无损流播放将显著消耗更多数据。
                        
                        一首三分钟的歌曲大约消耗：
                         - 1.5MB，高效
                         - 6MB，高质量（256kbps）
                         - 36MB，无损（24位/48kHz）
                         - 145MB，高解析度无损（24位/192kHz）
                        
                        支持情况视歌曲提供、网络状况和所连接扬声器或耳机的功能而异。
                        """)
                    }
                }
            }
        }
    }
}
