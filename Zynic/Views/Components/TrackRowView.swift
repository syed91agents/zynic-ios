import SwiftUI

struct TrackRowView: View {
    let track: Track
    let index: Int?
    var onTap: (() -> Void)?

    @ObservedObject var player = AudioPlayerManager.shared
    @ObservedObject var colors = ColorManager.shared
    private var isCurrentTrack: Bool { player.currentTrack?.id == track.id }

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 12) {
                // Index / waveform
                if let idx = index {
                    if isCurrentTrack && player.isPlaying {
                        WaveformBars(isPlaying: true, barCount: 3)
                            .frame(width: 22, height: 22)
                    } else {
                        Text("\(idx)")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(isCurrentTrack ? colors.accent : .secondary)
                            .frame(width: 22, alignment: .center)
                    }
                }

                // Thumbnail
                ZStack {
                    AsyncImage(url: track.thumbnailURL) { img in
                        img.resizable().scaledToFill()
                    } placeholder: {
                        ZStack {
                            colors.accent.opacity(0.25)
                            Image(systemName: "music.note")
                                .foregroundColor(colors.accent.opacity(0.7))
                                .font(.system(size: 14))
                        }
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    if isCurrentTrack {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(colors.accent, lineWidth: 1.5)
                    }
                }

                // Title + artist
                VStack(alignment: .leading, spacing: 3) {
                    Text(track.title)
                        .font(.system(size: 15, weight: isCurrentTrack ? .bold : .semibold))
                        .foregroundStyle(isCurrentTrack ? AnyShapeStyle(colors.gradient) : AnyShapeStyle(Color.primary))
                        .lineLimit(1)
                    Text(track.displayArtist)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if let dur = track.duration {
                    Text(dur)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.secondary)
                }

                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary.opacity(0.5))
                    .font(.system(size: 13))
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 4)
            .background(
                isCurrentTrack
                ? RoundedRectangle(cornerRadius: 12)
                    .fill(colors.accent.opacity(0.08))
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .stroke(colors.accent.opacity(0.2), lineWidth: 1))
                : nil
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .scaleEffect(isCurrentTrack ? 1.01 : 1.0)
        .animation(.spring(response: 0.3), value: isCurrentTrack)
    }
}
