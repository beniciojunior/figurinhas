import SwiftUI

struct ScannerAddView: View {

    let isActive: Bool

    @StateObject private var camera = CameraService()
    @EnvironmentObject private var collection: StickerCollection

    @State private var mode: ScannerMode = .add
    @State private var lastScannedID: String? = nil
    @State private var lastWasNoop = false
    @State private var undoAction: UndoAction? = nil

    private struct UndoAction {
        let id: String
        let mode: ScannerMode
    }

    var body: some View {
        NavigationStack {
            ZStack {
                cameraLayer
                    .ignoresSafeArea()
                overlayLayer
            }
            .navigationTitle("Scanner")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            camera.requestAndSetup()
            // Only start if this tab is actually visible
            if isActive { attachHandler(); camera.start() }
        }
        .onDisappear { deactivate() }
        .onChange(of: isActive) { _, active in
            if active { attachHandler(); camera.start() }
            else      { deactivate() }
        }
        .onChange(of: mode) {
            lastScannedID = nil
            camera.resetLastFound()
        }
    }

    private func deactivate() {
        camera.onStickerFound = nil   // drop any results already queued on main thread
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
        VStack(spacing: 0) {
            // Mode picker at top
            Picker("Modo", selection: $mode) {
                ForEach(ScannerMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .colorMultiply(.white)

            Spacer()

            // Status area (always at bottom)
            Group {
                if lastScannedID != nil {
                    actionStatusCard
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    hintPill
                        .transition(.opacity)
                }
            }
            .animation(.spring(duration: 0.35), value: lastScannedID)
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Action status card

    @ViewBuilder
    private var actionStatusCard: some View {
        if let id = lastScannedID, let def = StickerData.byID[id] {
            let count = collection.count(for: id)

            HStack(spacing: 14) {
                // Mini sticker visual
                miniCard(def: def, count: count)

                VStack(alignment: .leading, spacing: 5) {
                    Text(def.display)
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(.primary)

                    HStack(spacing: 4) {
                        Image(systemName: actionIcon(count: count))
                            .foregroundStyle(actionColor(count: count))
                        Text(actionLabel(count: count))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(actionColor(count: count))
                    }
                }

                Spacer()

                // Limpar button — lets the user re-scan the same sticker
                VStack(spacing: 8) {
                    Button {
                        performUndo()
                    } label: {
                        Text("Desfazer")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(undoAction == nil ? Color.secondary : Color.teal)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background((undoAction == nil ? Color.gray : Color.teal).opacity(0.18), in: Capsule())
                    }
                    .disabled(undoAction == nil)

                    Button {
                        camera.resetLastFound()
                        withAnimation(.spring(duration: 0.3)) { lastScannedID = nil }
                    } label: {
                        Text("Limpar")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.orange.opacity(0.18), in: Capsule())
                    }
                }
            }
            .padding(14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
            .id(id)   // forces re-render transition when sticker changes
        }
    }

    // MARK: - Mini sticker card

    private func miniCard(def: StickerDef, count: Int) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(cardColor(count: count))
                .frame(width: 54, height: 66)
                .shadow(color: cardColor(count: count).opacity(0.45), radius: 6, y: 3)
            VStack(spacing: 1) {
                Text(def.code)
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
                Text(def.number)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
    }

    // MARK: - Label helpers

    private func cardColor(count: Int) -> Color {
        if count == 0 { return .gray }
        if count == 1 { return .teal }
        return .orange
    }

    private func actionIcon(count: Int) -> String {
        if lastWasNoop { return "xmark.circle.fill" }
        return mode == .add ? "plus.circle.fill" : "minus.circle.fill"
    }

    private func actionColor(count: Int) -> Color {
        if lastWasNoop { return .secondary }
        return mode == .add ? .green : .red
    }

    private func actionLabel(count: Int) -> String {
        if lastWasNoop { return "Não tinha para remover" }
        if mode == .add {
            return count == 1 ? "Adicionada! (1×)" : "Adicionada! (\(count)×)"
        } else {
            return count == 0 ? "Removida! (0 restantes)" : "Removida! (\(count)× restante)"
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
            Text("Permita o acesso à câmera em Ajustes para usar o scanner.")
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
            // Ignore if same sticker as last scanned (until Limpar is tapped)
            guard id != lastScannedID else { return }

            let currentCount = collection.count(for: id)

            if mode == .add {
                collection.add(id)
                lastWasNoop = false
                undoAction = UndoAction(id: id, mode: .add)
                SoundManager.playAdded()
            } else {
                if currentCount > 0 {
                    collection.remove(id)
                    lastWasNoop = false
                    undoAction = UndoAction(id: id, mode: .remove)
                    SoundManager.playRemoved()
                } else {
                    lastWasNoop = true
                    undoAction = nil
                    SoundManager.playNoOp()
                }
            }

            withAnimation(.spring(duration: 0.35)) {
                lastScannedID = id
            }
        }
    }

    private func performUndo() {
        guard let action = undoAction else { return }

        if action.mode == .add {
            if collection.count(for: action.id) > 0 {
                collection.remove(action.id)
                SoundManager.playRemoved()
            }
        } else {
            collection.add(action.id)
            SoundManager.playAdded()
        }

        undoAction = nil
    }
}
