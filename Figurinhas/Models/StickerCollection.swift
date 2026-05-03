import SwiftUI

@MainActor
final class StickerCollection: ObservableObject {

    @Published private(set) var counts: [String: Int] = [:]

    private let key = "figurinhas.counts.v1"

    init() {
        if let saved = UserDefaults.standard.dictionary(forKey: key) as? [String: Int] {
            counts = saved
        }
    }

    // MARK: - Queries

    func count(for id: String) -> Int { counts[id, default: 0] }

    var totalOwned: Int  { counts.values.filter { $0 >= 1 }.count }
    var totalExtra: Int  { counts.values.filter { $0 > 1 }.reduce(0) { $0 + $1 - 1 } }
    var totalAll: Int    { StickerData.allDefs.count }

    // MARK: - Mutations

    func add(_ id: String) {
        counts[id, default: 0] += 1
        save()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func remove(_ id: String) {
        guard (counts[id] ?? 0) > 0 else { return }
        counts[id]! -= 1
        save()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    // MARK: - Persistence

    private func save() {
        UserDefaults.standard.set(counts, forKey: key)
    }
}
