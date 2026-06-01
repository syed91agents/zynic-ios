import SwiftUI

struct MiniPlayerView: View {
    @ObservedObject var player  = AudioPlayerManager.shared
    @ObservedObject var library = LibraryStore.shared
    @ObservedObject var colors  = ColorManager.shared
    @Binding var showFullPlayer: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Accent progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Color.white.opacity(0.07)
                    colors.gradient
                        .frame(width: geo.size.width * player.progress)
                        .animation(.linear(duration: 0.5), value: player.progress)
                }
            }
            .frame(height: 2)

            HStack(spacing: 14) {
                // Rotating artwork
                ZStack {
                    AsyncImage(url: player.currentTrack?.thumbnailURL) { img in
                        img.resizable().scaledToFill()
                    } placeholder: {
                        colors.accent.opacity(0.4)
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                    .rotationEffect(.degrees(player.isPlaying ? 360 : 0))
                    .animation(
                        player.isPlaying
                        ? .linear(duration: 8).repeatForever(autoreverses: false)
                        : .default,
                        value: player.isPlaying
                    )
                    .shadow(color: colors.glowColor, radius: 8)

                    // Vinyl centre dot
                    Circle()
                        .fill(Color.black)
                        .frame(width: 8, height: 8)
                }

                // Title
                VStack(alignment: .leading, spacing: 2) {
                    Text(player.currentTrack?.title ?? "Not Playing")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text(player.currentTrack?.displayArtist ?? "—")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .onTapGesture { showFullPlayer = true }

                // Waveform indicator
                WaveformBars(isPlaying: player.isPlaying, barCount: 4)
                    .frame(width: 24, height: 20)

                // Like
                Button {
                    if let t = player.currentTrack {
                        if library.contains(t) { library.remove(t) } else { library.add(t) }
                    }
                } label: {
                    let liked = player.currentTrack.map { library.contains($0) } ?? false
                    Image(systemName: liked ? "heart.fill" : "heart")
                        .font(.system(size: 16))
                        .foregroundColor(liked ? .pink : .secondary)
                }

                // Play/Pause
                Button { player.togglePlayPause() } label: {
                    ZStack {
                        Circle()
                            .fill(colors.gradient)
                            .frame(width: 38, height: 38)
                            .shadow(color: colors.glowColor, radius: 8)
                        if player.isLoading {
                            ProgressView().tint(.white).scaleEffect(0.7)
                        } else {
                            Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        }
                    }
                }

                // Next
                Button { player.next() } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .background(
            ZStack {
                Color.black.opacity(0.85)
                colors.accent.opacity(0.08)
            }
            .background(.ultraThinMaterial)
            .overlay(
                Rectangle()
                    .stroke(
                        LinearGradient(colors: [colors.accent.opacity(0.4), .clear],
                                       startPoint: .top, endPoint: .bottom),
                        lineWidth: 0.5
                    )
            )
        )
        .onTapGesture { showFullPlayer = true }
    }
}
