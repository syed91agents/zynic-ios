import SwiftUI

struct MusicCardView: View {
    let track: Track
    var onTap: (() -> Void)?
    var width: CGFloat = 150

    @ObservedObject var colors = ColorManager.shared
    @State private var pressed = false

    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack(alignment: .bottomTrailing) {
                    // Artwork
                    AsyncImage(url: track.thumbnailURL) { img in
                        img.resizable().scaledToFill()
                    } placeholder: {
                        ZStack {
                            colors.gradient
                            Image(systemName: "music.note.list")
                                .font(.system(size: 32))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                    .frame(width: width, height: width)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                LinearGradient(colors: [
                                    colors.accent.opacity(0.4),
                                    .white.opacity(0.08),
                                    colors.accentSecondary.opacity(0.2)
                                ], startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: colors.accent.opacity(0.2), radius: 12, y: 6)

                    // Play button overlay
                    ZStack {
                        Circle()
                            .fill(.black.opacity(0.5))
                            .background(.ultraThinMaterial, in: Circle())
                            .frame(width: 36, height: 36)
                        Image(systemName: "play.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.white)
                    }
                    .padding(8)
                    .opacity(pressed ? 1 : 0)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(track.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .frame(width: width, alignment: .leading)

                    if let sub = track.subtitle ?? track.artist {
                        Text(sub)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .frame(width: width, alignment: .leading)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(pressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: pressed)
        .simultaneousGesture(DragGesture(minimumDistance: 0)
            .onChanged { _ in pressed = true }
            .onEnded   { _ in pressed = false }
        )
    }
}

// MARK: - Horizontal shelf
struct ShelfView: View {
    let shelf: Shelf
    var onTrackTap: ((Track, [Track]) -> Void)?
    @ObservedObject var colors = ColorManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(shelf.title)
                    .font(.system(size: 19, weight: .black))
                    .foregroundColor(.white)
                Spacer()
                Text("See all")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(colors.gradient)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 16) {
                    ForEach(shelf.items) { track in
                        MusicCardView(track: track, onTap: {
                            onTrackTap?(track, shelf.items)
                        }, width: 150)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 4)
            }
        }
    }
}
