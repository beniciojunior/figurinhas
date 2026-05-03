import SwiftUI

@main
struct FigurinhasApp: App {

    @StateObject private var collection = StickerCollection()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(collection)
        }
    }
}
