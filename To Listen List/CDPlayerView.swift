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
}
