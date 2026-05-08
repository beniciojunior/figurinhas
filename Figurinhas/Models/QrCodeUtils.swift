import UIKit
import CoreImage

struct TradeResult {
    let iCanGive: [StickerDef]
    let theyCanGive: [StickerDef]
}

enum QrCodeUtils {

    private static let sortedIDs: [String] = StickerData.allDefs.map(\.id)

    // MARK: - Encode / Decode

    static func encode(counts: [String: Int]) -> String {
        sortedIDs.map { id in
            let n = min(counts[id] ?? 0, 15)
            return String(n, radix: 16)
        }.joined()
    }

    static func decode(hex: String) -> [String: Int]? {
        guard hex.count == sortedIDs.count else { return nil }
        var result: [String: Int] = [:]
        for (i, char) in hex.enumerated() {
            guard let n = Int(String(char), radix: 16) else { return nil }
            if n > 0 { result[sortedIDs[i]] = n }
        }
        return result
    }

    // MARK: - Trades

    static func computeTrades(myCounts: [String: Int], theirCounts: [String: Int]) -> TradeResult {
        var iCanGive: [StickerDef] = []
        var theyCanGive: [StickerDef] = []
        for id in sortedIDs {
            let mine   = myCounts[id]   ?? 0
            let theirs = theirCounts[id] ?? 0
            guard let def = StickerData.byID[id] else { continue }
            if mine > 1 && theirs == 0 { iCanGive.append(def) }
            if theirs > 1 && mine == 0 { theyCanGive.append(def) }
        }
        return TradeResult(iCanGive: iCanGive, theyCanGive: theyCanGive)
    }

    // MARK: - QR Generation

    static func generateQRImage(from string: String, size: CGFloat = 280) -> UIImage? {
        guard let data = string.data(using: .isoLatin1),
              let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        guard let ciImage = filter.outputImage else { return nil }
        let scale = size / ciImage.extent.width
        let transformed = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let context = CIContext()
        guard let cgImage = context.createCGImage(transformed, from: transformed.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
