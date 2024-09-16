//
//  CDPlayer.swift
//  To Listen List
//
//  Created by paul on 2024/9/7.
//

import AVKit
import SwiftUI
import SwiftData

struct CDPlayer: View {
    @Query(sort: \Item.index) private var items: [Item]
    @State private var current_audio_id :Int = 0
    @State private var notificationHandlers: [NSObjectProtocol] = []
    @State private var player = AVPlayer()
    private let first_audio_id: Int
    static let resetPlayerEvent = Notification.Name("resetPlayerEvent")
    init (audio_id: Int) {
        try! AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        first_audio_id = audio_id
    }
    
    var body: some View {
        VideoPlayer(player: player)
            .navigationBarBackButtonHidden(false) // 强制显示返回按钮
            .navigationBarTitleDisplayMode(.automatic)
            .onDisappear {
                print("bye")
                for handler in notificationHandlers {
                    NotificationCenter.default.removeObserver(handler)
                }
                notificationHandlers.removeAll()
                player.replaceCurrentItem(with: nil)
            }
            .onAppear {
                print("hi")
                notificationHandlers.append(NotificationCenter.default.addObserver(
                    forName: CDPlayer.resetPlayerEvent,
                    object: nil,
                    queue: .main
                ){_ in
                    print("play")
                    Task {
                        let newItem = try await getAVPlayerItem(item: items[current_audio_id])
                        player.replaceCurrentItem(with: newItem)
                        player.play()
                    }
                })
                notificationHandlers.append(NotificationCenter.default.addObserver(
                    forName: .AVPlayerItemDidPlayToEndTime,
                    object: nil,
                    queue: .main
                ) { _ in
                    print("next")
                    current_audio_id = (current_audio_id + 1) % items.count
                    NotificationCenter.default.post(name: CDPlayer.resetPlayerEvent, object: nil)
                })
                
                current_audio_id = first_audio_id
                NotificationCenter.default.post(name: CDPlayer.resetPlayerEvent, object: nil)
            }
        }
    
    private func fetchStreamURL(videoId: String) async throws -> String {
        let url = URL(string: "https://downloader.freemake.com/api/videoinfo/\(videoId)")!
        var request = URLRequest(url: url)
        request.setValue("UA-18256617-1", forHTTPHeaderField: "x-analytics-header")

        let (data, _) = try await URLSession.shared.data(for: request)
        
        if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
           let testId = json["videoId"] as? String,
           let qualities = json["qualities"] as? [[String: Any]],
           let lastQuality = qualities.last,
           let audioUrl = lastQuality["url"] as? String {
            if videoId == testId {
                return audioUrl
            }
        }
        throw URLError(.badServerResponse)
    }
    
    private func getAVPlayerItem(item: Item) async throws -> AVPlayerItem {
        let asset :AVAsset!
        let duration :Double
        if let streamURL = item.streamURL, let url = URL(string: streamURL) {
            let temp = AVAsset(url: url)
            do{
                duration = CMTimeGetSeconds(try await temp.load(.duration)) / 2
                asset = temp
                print("load success")
            } catch {
                let streamURL = try await fetchStreamURL(videoId: item.videoId)
                let url = URL(string: streamURL)!
                asset = AVAsset(url: url)
                duration = CMTimeGetSeconds(try await asset.load(.duration)) / 2
                item.streamURL = streamURL
            }
        } else {
            let streamURL = try await fetchStreamURL(videoId: item.videoId)
            let url = URL(string: streamURL)!
            asset = AVAsset(url: url)
            duration = CMTimeGetSeconds(try await asset.load(.duration)) / 2
            item.streamURL = streamURL
        }
        
        // 创建播放器
        let playerItem = AVPlayerItem(asset: asset)
        playerItem.forwardPlaybackEndTime = CMTime(seconds: duration, preferredTimescale: 600)
        
        // Set metadata for the player item
        let titleMetadata = AVMutableMetadataItem()
        titleMetadata.key = AVMetadataKey.commonKeyTitle as NSString
        titleMetadata.keySpace = .common
        titleMetadata.value = item.title as NSString
        
        let data = item.image
        let artworkMetadata = AVMutableMetadataItem()
        artworkMetadata.key = AVMetadataKey.commonKeyArtwork as NSString
        artworkMetadata.keySpace = .common
        artworkMetadata.value = data as NSData
        
        playerItem.externalMetadata = [titleMetadata, artworkMetadata]
        
        return playerItem
    }
}
