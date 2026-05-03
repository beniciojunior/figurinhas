import SwiftUI

struct ScannerCheckView: View {

    let isActive: Bool

    @StateObject private var camera = CameraService()
    @EnvironmentObject private var collection: StickerCollection

    @State private var lastID: String? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                cameraLayer
                    .ignoresSafeArea()
                overlayLayer
            }
            .navigationTitle("Verificar")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            camera.requestAndSetup()
            if isActive { attachHandler(); camera.start() }
        }
        .onDisappear { deactivate() }
        .onChange(of: isActive) { _, active in
            if active { attachHandler(); camera.start() }
            else      { deactivate() }
        }
    }

    private func deactivate() {
        camera.onStickerFound = nil
        camera.stop()
    }

    // MARK: - Camera layer

    private var cameraLayer: some View {
        Group {
            if camera.isAuthorized {
                CameraPreview(session: camera.session)
            } else if camera.permissionDenied {
                permissionDeniedView
            } else {
                Color.black
            }
        }
    }

    // MARK: - Overlay

    private var overlayLayer: some View {
        VStack {
            Spacer()

            Group {
                if let id = lastID, let def = StickerData.byID[id] {
                    statusCard(def: def, count: collection.count(for: id))
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .id(id)
                } else {
                    hintPill
                        .transition(.opacity)
                }
            }
            .animation(.spring(duration: 0.35), value: lastID)
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Status card

    private func statusCard(def: StickerDef, count: Int) -> some View {
        let hasIt = count > 0

        return HStack(spacing: 14) {
            // Mini sticker card
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(hasIt ? (count > 1 ? Color.orange : Color.teal) : Color(.systemGray4))
                    .frame(width: 54, height: 66)
                    .shadow(
                        color: (hasIt ? (count > 1 ? Color.orange : Color.teal) : Color.clear).opacity(0.4),
                        radius: 6, y: 3
                    )
                VStack(spacing: 1) {
                    Text(def.code)
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                    Text(def.number)
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(def.display)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(.primary)

                HStack(spacing: 4) {
                    Image(systemName: hasIt ? "checkmark.seal.fill" : "xmark.seal.fill")
                        .foregroundStyle(hasIt ? .green : Color(.secondaryLabel))
                    Text(statusText(count: count))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(hasIt ? .primary : .secondary)
                }
            }

            Spacer()
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
    }

    private func statusText(count: Int) -> String {
        switch count {
        case 0:  return "Você não tem"
        case 1:  return "Você tem (1×)"
        default: return "Você tem (\(count)×)"
        }
    }

    private var hintPill: some View {
        HStack(spacing: 6) {
            Image(systemName: "camera.viewfinder")
            Text("Aponte para uma figurinha")
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
    }

    private var permissionDeniedView: some View {
        ContentUnavailableView {
            Label("Câmera Necessária", systemImage: "camera.fill")
        } description: {
            Text("Permita o acesso à câmera em Ajustes.")
        } actions: {
            Button("Abrir Ajustes") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Camera handler

    private func attachHandler() {
        camera.onStickerFound = { id in
            guard id != lastID else { return }

            let hasIt = collection.count(for: id) > 0
            if hasIt {
                SoundManager.playHasSticker()     // ding, no haptic
            } else {
                SoundManager.playMissingSticker() // tock + haptic warning
            }

            withAnimation(.spring(duration: 0.35)) {
                lastID = id
            }
        }
    }
}
