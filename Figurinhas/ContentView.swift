import SwiftUI

enum AppTab { case collection, scanner, verify }

struct ContentView: View {

    @EnvironmentObject private var collection: StickerCollection
    @State private var activeTab: AppTab = .collection

    var body: some View {
        TabView(selection: $activeTab) {
            Tab("Coleção", systemImage: "square.grid.3x3.fill", value: AppTab.collection) {
                CollectionGridView()
            }
            Tab("Scanner", systemImage: "camera.viewfinder", value: AppTab.scanner) {
                ScannerAddView(isActive: activeTab == .scanner)
            }
            Tab("Verificar", systemImage: "checkmark.circle.fill", value: AppTab.verify) {
                ScannerCheckView(isActive: activeTab == .verify)
            }
        }
        .tint(.orange)
    }
}
