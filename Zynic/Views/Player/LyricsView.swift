import SwiftUI

struct LyricsView: View {
    @ObservedObject var player = AudioPlayerManager.shared

    var body: some View {
        ScrollView {
            if let lyr = player.lyrics {
                VStack(alignment: .leading, spacing: 0) {
                    if lyr.synced {
                        SyncedLyricsView(raw: lyr.lyrics, currentTime: player.currentTime)
                    } else {
                        Text(lyr.lyrics)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white.opacity(0.85))
                            .lineSpacing(10)
                            .padding(24)
                    }
                }
            } else {
                VStack(spacing: 16) {
                    ProgressView().tint(.purple)
                    Text("Loading lyrics…")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            }
        }
    }
}

struct SyncedLyricsView: View {
    let raw: String
    let currentTime: Double

    struct LyricsLine: Identifiable {
        let id = UUID()
        let time: Double
        let text: String
    }

    var lines: [LyricsLine] {
        raw.components(separatedBy: "\n").compactMap { line in
            let pattern = #"^\[(\d+):(\d+)\.(\d+)\](.*)"#
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) else {
                return nil
            }
            func str(_ r: NSRange) -> String { String(line[Range(r, in: line)!]) }
            let min = Double(str(match.range(at: 1))) ?? 0
            let sec = Double(str(match.range(at: 2))) ?? 0
            let cent = Double(str(match.range(at: 3))) ?? 0
            let t = min * 60 + sec + cent / 100
            let text = str(match.range(at: 4)).trimmingCharacters(in: .whitespaces)
            return text.isEmpty ? nil : LyricsLine(time: t, text: text)
        }
    }

    var activeIndex: Int {
        var idx = 0
        for (i, l) in lines.enumerated() { if l.time <= currentTime { idx = i } }
        return idx
    }

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 12) {
            ForEach(Array(lines.enumerated()), id: \.element.id) { idx, line in
                Text(line.text)
                    .font(.system(size: idx == activeIndex ? 20 : 16,
                                  weight: idx == activeIndex ? .black : .medium))
                    .foregroundColor(idx == activeIndex ? .white : .white.opacity(0.35))
                    .animation(.spring(response: 0.3), value: activeIndex)
                    .id(idx)
            }
        }
        .padding(24)
    }
}
