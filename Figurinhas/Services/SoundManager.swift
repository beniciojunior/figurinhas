import AudioToolbox
import UIKit

// System sound IDs used:
//  1519 = "Peek"  — very short tap (~40 ms), neutral
//  1520 = "Pop"   — very short pop (~50 ms), slightly brighter

enum SoundManager {

    // MARK: - Tab 2 (Scanner Add/Remove)

    static func playAdded() {
        AudioServicesPlaySystemSound(1520)  // short pop
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func playRemoved() {
        AudioServicesPlaySystemSound(1519)  // shorter peek
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func playNoOp() {
        AudioServicesPlaySystemSound(1519)
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    // MARK: - Tab 3 (Scanner Check)

    static func playHasSticker() {
        AudioServicesPlaySystemSound(1520)  // pop, no haptic
    }

    static func playMissingSticker() {
        AudioServicesPlaySystemSound(1519)  // peek
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
