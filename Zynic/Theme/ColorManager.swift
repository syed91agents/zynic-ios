import SwiftUI
import UIKit

// MARK: - Global accent color that drives the whole UI
final class ColorManager: ObservableObject {
    static let shared = ColorManager()

    @Published var accent: Color      = Color(red: 0.66, green: 0.33, blue: 1.0)
    @Published var accentUI: UIColor  = UIColor(red: 0.66, green: 0.33, blue: 1.0, alpha: 1)
    @Published var accentSecondary: Color = Color(red: 0.39, green: 0.40, blue: 0.95)
    @Published var isDark = true

    private init() {}

    // Extract dominant color from album art URL
    func updateFromURL(_ urlStr: String?) {
        guard let urlStr, let url = URL(string: urlStr) else { return }
        Task {
            guard let (data, _) = try? await URLSession.shared.data(from: url),
                  let img = UIImage(data: data),
                  let color = img.dominantColor() else { return }
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.8)) {
                    self.accentUI = color
                    self.accent   = Color(uiColor: color)
                    // Complementary secondary
                    var h: CGFloat = 0; var s: CGFloat = 0; var b: CGFloat = 0; var a: CGFloat = 0
                    color.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
                    let secondHue = (h + 0.08).truncatingRemainder(dividingBy: 1.0)
                    self.accentSecondary = Color(hue: secondHue, saturation: s * 0.8, brightness: b * 0.9)
                }
            }
        }
    }

    var gradient: LinearGradient {
        LinearGradient(colors: [accent, accentSecondary],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    var gradientH: LinearGradient {
        LinearGradient(colors: [accent, accentSecondary],
                       startPoint: .leading, endPoint: .trailing)
    }
    var glowColor: Color { accent.opacity(0.4) }
}

// MARK: - UIImage dominant color extraction
extension UIImage {
    func dominantColor() -> UIColor? {
        guard let cgImg = self.cgImage else { return nil }
        let size = CGSize(width: 40, height: 40)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var rawData = [UInt8](repeating: 0, count: 4 * Int(size.width) * Int(size.height))
        guard let ctx = CGContext(data: &rawData,
                                  width: Int(size.width), height: Int(size.height),
                                  bitsPerComponent: 8, bytesPerRow: 4 * Int(size.width),
                                  space: colorSpace,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        ctx.draw(cgImg, in: CGRect(origin: .zero, size: size))

        var r: CGFloat = 0; var g: CGFloat = 0; var b: CGFloat = 0; var count: CGFloat = 0
        let len = rawData.count
        stride(from: 0, to: len, by: 4).forEach { i in
            let ri = CGFloat(rawData[i]) / 255
            let gi = CGFloat(rawData[i+1]) / 255
            let bi = CGFloat(rawData[i+2]) / 255
            // Skip near-white and near-black
            if ri + gi + bi > 0.3 && ri + gi + bi < 2.7 {
                r += ri; g += gi; b += bi; count += 1
            }
        }
        guard count > 0 else { return UIColor(red: 0.66, green: 0.33, blue: 1, alpha: 1) }
        // Boost saturation
        let avg = UIColor(red: r/count, green: g/count, blue: b/count, alpha: 1)
        var hue: CGFloat = 0; var sat: CGFloat = 0; var bri: CGFloat = 0; var alp: CGFloat = 0
        avg.getHue(&hue, saturation: &sat, brightness: &bri, alpha: &alp)
        return UIColor(hue: hue, saturation: min(1, sat * 1.5 + 0.3), brightness: max(0.5, bri), alpha: 1)
    }
}
