import SwiftUI
import SwiftData
import AVFoundation
import MediaPlayer


struct MusicPlayer: View {
    @Query(sort: \Item.order) private var songList: [Item]
    @StateObject private var musicPlayer = MusicPlayerControl()
    public let firstTrackId :Int
    
    init (trackId: Int) {
        firstTrackId = trackId
    }
    
    var body: some View {
        VStack {
            if let image = musicPlayer.currentSongImage {
                Image(uiImage: UIImage(data: image) ?? UIImage())
                    .resizable()
                    .scaledToFit()
                    .padding(.horizontal)
                    .cornerRadius(10)
                    .padding(.top, 20)
            }
            

            VStack(alignment: .leading) {
                Text(musicPlayer.currentSongTitle)
                    .font(.title3)
                    .fontWeight(.bold)
                    .padding(.top, 10)
                
                Text(musicPlayer.currentSongAuthor)
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.top, 2)
            }
            .padding(.horizontal)
            
            Spacer()
            
            Slider(value: $musicPlayer.playbackProgress, in: 0...1, onEditingChanged: { editing in
                if editing {
                    print("1")
                    musicPlayer.stopProgressTimer()
                } else {// finish editing
                    print("2")
                    musicPlayer.startProgressTimer()
                    musicPlayer.seekToProgress(musicPlayer.playbackProgress)
                }
            })
            .padding()

            HStack {
                Button(action: {
                    musicPlayer.playPreviousTrack()
                }) {
                    Image(systemName: "backward.fill")
                        .font(.largeTitle)
                }
                .padding()

                Button(action: {
                    musicPlayer.togglePlayPause()
                }) {
                    Image(systemName: musicPlayer.isPlaying ? "pause.fill" : "play.fill")
                        .font(.largeTitle)
                }
                .padding()

                Button(action: {
                    musicPlayer.playNextTrack()
                }) {
                    Image(systemName: "forward.fill")
                        .font(.largeTitle)
                }
                .padding()
            }
            .frame(height: 120)
        }
        .onAppear {
            musicPlayer.setupRemoteTransportControls()
            musicPlayer.setupSongList(songList: songList)
            musicPlayer.playTrack(trackId: 0)
            print("appear")
        }
        .onDisappear {
            if musicPlayer.isPlaying {
                musicPlayer.togglePlayPause()
            }
        }
    }
}

class MusicPlayerControl: ObservableObject {
    private var songList: [Item]?
    
    private var currentSongIndex = 0
    private var timer: Timer?
    private var player: AVPlayer?
    
    @Published var isPlaying = false
    @Published var currentSongTitle = ""
    @Published var currentSongAuthor = ""
    @Published var currentSongImage :Data?
    @Published var playbackProgress: Double = 0.0
    
    func playTrack(trackId: Int) {
        currentSongIndex = trackId
        isPlaying = false
        player?.pause()
        updateNowPlayingInfo()
        playCurrentTrack()
    }
    
    func setupSongList(songList: [Item]) {
        self.songList = songList
    }
    
    func playCurrentTrack() {
        startProgressTimer()
        Task {
            guard let songList = songList else {
                print("songList not exist")
                return
            }
            let songId = songList[currentSongIndex].videoId
            print(songId)
            let sondLink = try await fetchStreamURL(videoId: songId)
            guard let url = URL(string: sondLink) else {
                print("URL not valid")
                return
            }
            let asset = AVAsset(url: url)
            print("bbb")
            let duration = CMTimeGetSeconds(try await asset.load(.duration)) / 2
            print("aaa")
            let playerItem = AVPlayerItem(asset: asset)
            playerItem.forwardPlaybackEndTime = CMTime(seconds: duration, preferredTimescale: 600)
            
            isPlaying = true
            currentSongTitle = try await fetchTitle(videoId: songId)
            currentSongImage = try await fetchImage(videoId: songId)
            currentSongAuthor = try await fetchAuthor(videoId: songId)
            
            player = AVPlayer(playerItem: playerItem)
            player?.play()

            // 當播放完畢時，播放下一首
            NotificationCenter.default.addObserver(self, selector: #selector(songDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        }
    }

    func togglePlayPause() {
        if isPlaying {
            player?.pause()
            stopProgressTimer()
        } else {
            player?.play()
            startProgressTimer()
        }
        isPlaying.toggle()
        updateNowPlayingInfo()
    }

    @objc func songDidFinishPlaying() {
        print("hii")
        playNextTrack()
    }

    func playPreviousTrack() {
        guard let songList = songList else {
            print("songList not exist")
            return
        }
        playTrack(trackId: (currentSongIndex - 1 + songList.count) % songList.count)
    }

    func playNextTrack() {
        guard let songList = songList else {
            print("songList not exist")
            return
        }
        playTrack(trackId: (currentSongIndex + 1) % songList.count)
    }

    // 設置遠端控制中心（包括播放、暫停、下一首、上一首以及進度調整）
    func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()

        // 設置播放/暫停控制
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [unowned self] event in
            if !self.isPlaying {
                self.togglePlayPause()
            }
            return .success
        }

        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] event in
            if let self = self, self.isPlaying {
                self.togglePlayPause()
            }
            return .success
        }

        // 設置上一首和下一首控制
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [weak self] event in
            if let self = self {
                self.playPreviousTrack()
            }
            
            return .success
        }

        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { [weak self] event in
            if let self = self {
                self.playNextTrack()
            }
            return .success
        }

        // 設置進度條調整
        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            if let self = self, let positionEvent = event as? MPChangePlaybackPositionCommandEvent {
                self.seekToTime(positionEvent.positionTime)
            }
            return .success
        }
    }

    func updateNowPlayingInfo() {
        guard let player = player, let currentItem = player.currentItem else {
            return
        }
        
        let duration = currentItem.forwardPlaybackEndTime.seconds
        
        if duration <= 0 {
            return
        }
        
        let currentTime = player.currentTime().seconds
        
        self.playbackProgress = currentTime / duration
        
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = currentSongTitle
        if let imageData = currentSongImage, let image = UIImage(data: imageData) {
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in return image }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }
        nowPlayingInfo[MPMediaItemPropertyArtist] = currentSongAuthor
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    func startProgressTimer() {
        stopProgressTimer()  // 確保不會有多餘的 timer

        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else {
                return
            }
            self.updateNowPlayingInfo()  // 確保進度在 Now Playing Info 中更新
        }
    }

    func stopProgressTimer() {
        timer?.invalidate()
        timer = nil
    }

    // 當使用者拖動進度條時呼叫，或者通過遠端控制調整進度
    func seekToProgress(_ progress: Double) {
        guard let player = player, let currentItem = player.currentItem else { return }

        let duration = currentItem.forwardPlaybackEndTime.seconds
        let newTime = CMTime(seconds: duration * progress, preferredTimescale: 600)
        player.seek(to: newTime)
    }

    // 用於 MPRemoteCommandCenter 的播放進度控制
    func seekToTime(_ time: TimeInterval) {
        guard let player = player else { return }

        let newTime = CMTime(seconds: time, preferredTimescale: 600)
        player.seek(to: newTime)
    }
}
