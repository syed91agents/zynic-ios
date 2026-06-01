import AVFoundation
import MediaPlayer
import Combine

final class AudioPlayerManager: NSObject, ObservableObject {
    static let shared = AudioPlayerManager()

    // MARK: - Published state
    @Published var currentTrack: Track?
    @Published var queue: [Track] = []
    @Published var queueIndex: Int = 0
    @Published var isPlaying = false
    @Published var isLoading = false
    @Published var progress: Double = 0
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var volume: Float = 1.0
    @Published var errorMessage: String?
    @Published var lyrics: LyricsResponse?
    @Published var isShuffled = false
    @Published var repeatMode: RepeatMode = .none
    @Published var isLoadingLyrics = false

    enum RepeatMode { case none, one, all }

    // MARK: - Private
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    private var statusObservation: NSKeyValueObservation?
    private var endObserver: NSObjectProtocol?

    // EQ
    private var audioEngine = AVAudioEngine()
    private var playerNode = AVAudioPlayerNode()
    private var eqNode = AVAudioUnitEQ(numberOfBands: 5)
    private var useEngine = false

    override private init() {
        super.init()
        setupAudioSession()
        setupRemoteControls()
        setupEQ()
    }

    // MARK: - Audio Session
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.allowAirPlay, .allowBluetooth, .mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch { print("[Audio] Session error: \(error)") }
    }

    // MARK: - EQ setup
    private func setupEQ() {
        let freqs: [Float] = [60, 230, 910, 4000, 14000]
        for (i, freq) in freqs.enumerated() {
            eqNode.bands[i].frequency  = freq
            eqNode.bands[i].filterType = .parametric
            eqNode.bands[i].gain       = 0
            eqNode.bands[i].bandwidth  = 1.0
            eqNode.bands[i].bypass     = false
        }
    }

    func setEQGain(_ gain: Float, band: Int) {
        guard band < eqNode.bands.count else { return }
        eqNode.bands[band].gain = gain
    }

    // MARK: - Dynamic color update when track changes
    private func updateAccentColor(for track: Track) {
        ColorManager.shared.updateFromURL(track.thumbnail)
    }

    // MARK: - Play
    func play(_ track: Track, queue: [Track] = []) {
        let q = queue.isEmpty ? [track] : queue
        let idx = q.firstIndex(where: { $0.id == track.id }) ?? 0
        play(tracks: q, startAt: idx)
    }

    func play(tracks: [Track], startAt: Int = 0) {
        guard startAt < tracks.count else { return }
        queue      = tracks
        queueIndex = startAt
        let track  = tracks[startAt]
        currentTrack = track
        lyrics = nil
        isLoadingLyrics = false
        updateAccentColor(for: track)
        loadStream(track)
    }

    private func loadStream(_ track: Track) {
        let videoId = track.videoId ?? (track.id.count == 11 ? track.id : nil)
        guard let vid = videoId, !vid.isEmpty else {
            DispatchQueue.main.async { self.errorMessage = "Not a playable track" }
            return
        }

        DispatchQueue.main.async { self.isLoading = true; self.isPlaying = false }
        tearDown()

        Task { @MainActor in
            do {
                let stream = try await APIClient.shared.stream(vid)
                guard let url = APIClient.shared.resolveStreamURL(stream.url) else {
                    self.isLoading = false; return
                }
                self.startAVPlayer(url: url, track: track)
                // Load lyrics in parallel
                Task { await self.fetchLyrics(track) }
            } catch {
                self.isLoading  = false
                self.errorMessage = "Stream failed: \(error.localizedDescription)"
                print("[Audio] Stream error: \(error)")
            }
        }
    }

    // MARK: - AVPlayer startup
    private func startAVPlayer(url: URL, track: Track) {
        print("[Audio] Loading URL: \(url.absoluteString.prefix(80))")

        let asset = AVURLAsset(url: url, options: [
            "AVURLAssetHTTPHeaderFieldsKey": [
                "User-Agent": "Zynic/1.0 iOS/\(UIDevice.current.systemVersion)",
                "Range":      "bytes=0-"
            ]
        ])
        let item = AVPlayerItem(asset: asset)
        playerItem = item

        // Observe status
        statusObservation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            DispatchQueue.main.async { self?.handleStatus(item) }
        }

        if player == nil { player = AVPlayer() }
        player?.replaceCurrentItem(with: item)
        player?.volume = volume

        // Progress observer
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self, let item = self.player?.currentItem else { return }
            let cur = CMTimeGetSeconds(time)
            let dur = CMTimeGetSeconds(item.duration)
            if dur.isFinite && dur > 0 {
                self.duration    = dur
                self.currentTime = cur
                self.progress    = cur / dur
            }
        }

        // End notification
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main
        ) { [weak self] _ in self?.handleEnd() }

        player?.play()
        isPlaying = true
        updateNowPlaying(track: track)
    }

    private func handleStatus(_ item: AVPlayerItem) {
        switch item.status {
        case .readyToPlay:
            isLoading = false
            player?.play()
            isPlaying = true
            print("[Audio] Ready to play")
        case .failed:
            isLoading  = false
            isPlaying  = false
            errorMessage = item.error?.localizedDescription ?? "Playback failed"
            print("[Audio] Failed: \(item.error?.localizedDescription ?? "?")")
        default: break
        }
    }

    private func tearDown() {
        if let obs = timeObserver { player?.removeTimeObserver(obs); timeObserver = nil }
        if let obs = endObserver  { NotificationCenter.default.removeObserver(obs); endObserver = nil }
        statusObservation?.invalidate(); statusObservation = nil
        player?.pause()
        player?.replaceCurrentItem(with: nil)
    }

    // MARK: - Controls
    func togglePlayPause() {
        guard let player else { return }
        if isPlaying { player.pause(); isPlaying = false }
        else         { player.play();  isPlaying = true  }
        updateNowPlaying(track: currentTrack)
    }

    func next() {
        var idx = queueIndex + 1
        if isShuffled { idx = Int.random(in: 0..<max(1, queue.count)) }
        if idx < queue.count {
            queueIndex = idx; currentTrack = queue[idx]; loadStream(queue[idx])
        } else if repeatMode == .all, !queue.isEmpty {
            queueIndex = 0; currentTrack = queue[0]; loadStream(queue[0])
        }
    }

    func previous() {
        if currentTime > 3 { seek(to: 0); return }
        let idx = max(0, queueIndex - 1)
        queueIndex = idx; currentTrack = queue[idx]; loadStream(queue[idx])
    }

    func seek(to fraction: Double) {
        guard duration > 0 else { return }
        let t = CMTime(seconds: fraction * duration, preferredTimescale: 600)
        player?.seek(to: t)
    }

    func seekSeconds(_ s: Double) {
        seek(to: max(0, min(1, (currentTime + s) / max(1, duration))))
    }

    func setVolume(_ v: Float) { volume = v; player?.volume = v }
    func toggleShuffle()       { isShuffled.toggle() }
    func cycleRepeat() {
        switch repeatMode {
        case .none: repeatMode = .all
        case .all:  repeatMode = .one
        case .one:  repeatMode = .none
        }
    }

    func addToQueue(_ t: Track) { queue.append(t) }

    private func handleEnd() {
        if repeatMode == .one {
            seek(to: 0); player?.play(); return
        }
        next()
    }

    // MARK: - Lyrics
    @MainActor
    func fetchLyrics(_ track: Track) async {
        isLoadingLyrics = true
        do {
            lyrics = try await APIClient.shared.lyrics(
                title: track.title, artist: track.displayArtist
            )
        } catch { lyrics = nil }
        isLoadingLyrics = false
    }

    // MARK: - Now Playing
    private func updateNowPlaying(track: Track?) {
        guard let track else { return }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle:                       track.title,
            MPMediaItemPropertyArtist:                      track.displayArtist,
            MPNowPlayingInfoPropertyElapsedPlaybackTime:    currentTime,
            MPMediaItemPropertyPlaybackDuration:            duration,
            MPNowPlayingInfoPropertyPlaybackRate:           isPlaying ? 1.0 : 0.0
        ]
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        if let urlStr = track.thumbnail, let url = URL(string: urlStr) {
            Task {
                if let (data, _) = try? await URLSession.shared.data(from: url),
                   let img = UIImage(data: data) {
                    info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: img.size) { _ in img }
                    MPNowPlayingInfoCenter.default().nowPlayingInfo = info
                }
            }
        }
    }

    // MARK: - Remote Controls
    private func setupRemoteControls() {
        let cc = MPRemoteCommandCenter.shared()
        cc.playCommand.addTarget  { [weak self] _ in self?.togglePlayPause(); return .success }
        cc.pauseCommand.addTarget { [weak self] _ in self?.togglePlayPause(); return .success }
        cc.nextTrackCommand.addTarget     { [weak self] _ in self?.next();     return .success }
        cc.previousTrackCommand.addTarget { [weak self] _ in self?.previous(); return .success }
        cc.changePlaybackPositionCommand.addTarget { [weak self] event in
            if let e = event as? MPChangePlaybackPositionCommandEvent, let self {
                self.seek(to: e.positionTime / max(1, self.duration))
            }
            return .success
        }
    }
}
