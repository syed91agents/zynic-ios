import SwiftUI

// MARK: - Sprite sheet animation spec (matches web: 8 cols × 9 rows)
struct SpriteAnim {
    let row: Int
    let frames: Int

    static let idle         = SpriteAnim(row: 0, frames: 6)
    static let runningRight  = SpriteAnim(row: 1, frames: 8)
    static let runningLeft   = SpriteAnim(row: 2, frames: 8)
    static let waving        = SpriteAnim(row: 3, frames: 4)
    static let jumping       = SpriteAnim(row: 4, frames: 5)
    static let waiting       = SpriteAnim(row: 6, frames: 6)
    static let running       = SpriteAnim(row: 7, frames: 6)
}

let SHEET_COLS = 8
let SHEET_ROWS = 9

// MARK: - Image cache for spritesheets
final class SpriteCache {
    static let shared = SpriteCache()
    private var cache = NSCache<NSString, UIImage>()
    private var loading = Set<String>()
    private init() { cache.countLimit = 100 }

    func image(for url: String) -> UIImage? {
        cache.object(forKey: url as NSString)
    }

    func load(_ url: String) async -> UIImage? {
        if let img = cache.object(forKey: url as NSString) { return img }
        guard let u = URL(string: url) else { return nil }
        var req = URLRequest(url: u)
        req.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        guard let (data, _) = try? await URLSession.shared.data(for: req),
              let img = UIImage(data: data) else { return nil }
        cache.setObject(img, forKey: url as NSString)
        return img
    }
}

// MARK: - Static single-frame sprite (clean crop of one frame)
struct StaticSpriteView: View {
    let spritesheetUrl: String
    var anim: SpriteAnim = .idle
    var frame: Int = 0
    var size: CGFloat = 90

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let img = image {
                SpriteFrame(image: img, row: anim.row, col: frame, size: size)
            } else {
                ProgressView().scaleEffect(0.6).tint(.purple)
            }
        }
        .frame(width: size, height: size)
        .task {
            if let cached = SpriteCache.shared.image(for: spritesheetUrl) {
                image = cached
            } else {
                image = await SpriteCache.shared.load(spritesheetUrl)
            }
        }
    }
}

// MARK: - Animated sprite (cycles through frames of a row)
struct AnimatedSpriteView: View {
    let spritesheetUrl: String
    var anim: SpriteAnim
    var size: CGFloat = 120
    var fps: Double = 8

    @State private var image: UIImage?
    @State private var currentFrame = 0
    @State private var timer: Timer?

    var body: some View {
        ZStack {
            if let img = image {
                SpriteFrame(image: img, row: anim.row, col: currentFrame, size: size)
            } else {
                ProgressView().tint(.purple)
            }
        }
        .frame(width: size, height: size)
        .task {
            if let cached = SpriteCache.shared.image(for: spritesheetUrl) {
                image = cached
            } else {
                image = await SpriteCache.shared.load(spritesheetUrl)
            }
            startAnimating()
        }
        .onChange(of: anim.row) { _ in
            currentFrame = 0
            startAnimating()
        }
        .onDisappear { timer?.invalidate() }
    }

    private func startAnimating() {
        timer?.invalidate()
        guard image != nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / fps, repeats: true) { _ in
            currentFrame = (currentFrame + 1) % anim.frames
        }
    }
}

// MARK: - Crops exactly one frame (col, row) from an 8×9 sheet
struct SpriteFrame: View {
    let image: UIImage
    let row: Int
    let col: Int
    var size: CGFloat

    var body: some View {
        let cellW = image.size.width / CGFloat(SHEET_COLS)
        let cellH = image.size.height / CGFloat(SHEET_ROWS)
        // Scale so one cell fills `size`
        let scale = size / max(cellW, cellH)
        let sheetW = image.size.width * scale
        let sheetH = image.size.height * scale
        let frameW = cellW * scale
        let frameH = cellH * scale
        // Center the frame within the square
        let padX = (size - frameW) / 2
        let padY = (size - frameH) / 2

        return Image(uiImage: image)
            .resizable()
            .interpolation(.none)               // crisp pixel art
            .frame(width: sheetW, height: sheetH)
            .offset(
                x: -CGFloat(col) * frameW + padX,
                y: -CGFloat(row) * frameH + padY
            )
            .frame(width: size, height: size, alignment: .topLeading)
            .clipped()
    }
}
