import SwiftUI

struct ScannerCheckView: View {

    let isActive: Bool

    @StateObject private var camera = CameraService()
    @EnvironmentObject private var collection: StickerCollection

    @State private var checkTab: CheckTab = .sticker

    // Sticker tab state
    @State private var lastID: String? = nil

    // QR tab state
    @State private var qrState: QrState = .myQr
    @State private var tradeResult: TradeResult? = nil
    @State private var qrImage: UIImage? = nil
    @State private var lastScannedQr: String? = nil

    enum CheckTab { case sticker, qr }
    enum QrState  { case myQr, scanning, result }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                picker
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                Divider()

                Group {
                    switch checkTab {
                    case .sticker: stickerTab
                    case .qr:      qrTab
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: checkTab)
            }
            .navigationTitle("Verificar")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            camera.requestAndSetup()
            if isActive { activate() }
        }
        .onDisappear { deactivate() }
        .onChange(of: isActive) { _, active in
            if active { activate() } else { deactivate() }
        }
        .onChange(of: checkTab) { _, tab in
            camera.scanMode = (tab == .sticker) ? .sticker : .qr
            lastID = nil
            lastScannedQr = nil
            if tab == .qr { generateQR() }
        }
    }

    // MARK: - Picker

    private var picker: some View {
        Picker("Modo", selection: $checkTab) {
            Label("Figurinha", systemImage: "viewfinder").tag(CheckTab.sticker)
            Label("Troca QR",  systemImage: "arrow.2.squarepath").tag(CheckTab.qr)
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Sticker tab

    private var stickerTab: some View {
        ZStack {
            cameraLayer.ignoresSafeArea()
            VStack {
                Spacer()
                Group {
                    if let id = lastID, let def = StickerData.byID[id] {
                        statusCard(def: def, count: collection.count(for: id))
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .id(id)
                    } else {
                        hintPill("Aponte para uma figurinha", icon: "camera.viewfinder")
                            .transition(.opacity)
                    }
                }
                .animation(.spring(duration: 0.35), value: lastID)
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - QR tab

    @ViewBuilder
    private var qrTab: some View {
        switch qrState {
        case .myQr:    myQrView
        case .scanning: qrScanView
        case .result:  tradeResultView
        }
    }

    // Show my QR code
    private var myQrView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Meu QR Code")
                    .font(.headline)
                Text("Mostre para o colega escanear e ver as possíveis trocas")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Group {
                    if let img = qrImage {
                        Image(uiImage: img)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 260, height: 260)
                    } else {
                        ProgressView()
                            .frame(width: 260, height: 260)
                    }
                }
                .padding(12)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                Button {
                    qrState = .scanning
                    camera.scanMode = .qr
                    camera.start()
                } label: {
                    Label("Escanear QR do colega", systemImage: "qrcode.viewfinder")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(24)
        }
    }

    // Scanning their QR
    private var qrScanView: some View {
        ZStack {
            if camera.isAuthorized {
                CameraPreview(session: camera.session).ignoresSafeArea()
            }
            VStack {
                Spacer()
                VStack(spacing: 12) {
                    hintPill("Aponte para o QR do colega", icon: "qrcode.viewfinder")
                    Button("Cancelar") {
                        qrState = .myQr
                        lastScannedQr = nil
                        camera.scanMode = .qr
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                }
                .padding(.bottom, 40)
            }
        }
    }

    // Trade result
    private var tradeResultView: some View {
        VStack(spacing: 0) {
            if let result = tradeResult {
                List {
                    Section {
                        tradeSection(
                            title: "Eu posso dar (\(result.iCanGive.count))",
                            stickers: result.iCanGive,
                            color: .green,
                            icon: "arrow.up.circle.fill",
                            emptyText: "Nenhuma repetida que você precise"
                        )
                    }
                    Section {
                        tradeSection(
                            title: "Eles podem me dar (\(result.theyCanGive.count))",
                            stickers: result.theyCanGive,
                            color: .blue,
                            icon: "arrow.down.circle.fill",
                            emptyText: "Nenhuma repetida deles que você precise"
                        )
                    }
                }
                .listStyle(.insetGrouped)

                HStack(spacing: 12) {
                    Button {
                        let iGive = result.iCanGive.isEmpty ? "nenhuma"
                            : result.iCanGive.map(\.display).joined(separator: ", ")
                        let theyGive = result.theyCanGive.isEmpty ? "nenhuma"
                            : result.theyCanGive.map(\.display).joined(separator: ", ")
                        let text = "Troca de figurinhas:\nEu dou: \(iGive)\nEles dão: \(theyGive)"
                        let av = UIActivityViewController(
                            activityItems: [text], applicationActivities: nil)
                        UIApplication.shared.connectedScenes
                            .compactMap { $0 as? UIWindowScene }
                            .first?.windows.first?
                            .rootViewController?.present(av, animated: true)
                    } label: {
                        Label("Compartilhar", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)

                    Button {
                        qrState = .myQr
                        tradeResult = nil
                        lastScannedQr = nil
                        camera.scanMode = .qr
                    } label: {
                        Label("Nova troca", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
        }
    }

    @ViewBuilder
    private func tradeSection(
        title: String,
        stickers: [StickerDef],
        color: Color,
        icon: String,
        emptyText: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .foregroundStyle(color)
                .font(.subheadline.bold())
            if stickers.isEmpty {
                Text(emptyText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                let grouped = Dictionary(grouping: stickers) { $0.code }
                ForEach(grouped.keys.sorted(), id: \.self) { code in
                    let nums = grouped[code]!.map(\.number).joined(separator: ", ")
                    Text("\(code): \(nums)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
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

    // MARK: - Shared components

    private func statusCard(def: StickerDef, count: Int) -> some View {
        let hasIt = count > 0
        let accent: Color = hasIt ? (count > 1 ? .orange : .teal) : Color(.systemGray4)

        return HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(accent)
                    .frame(width: 54, height: 66)
                    .shadow(color: (hasIt ? accent : .clear).opacity(0.4), radius: 6, y: 3)
                VStack(spacing: 1) {
                    Text(def.code).font(.system(size: 8, weight: .bold, design: .rounded)).foregroundStyle(.white.opacity(0.8))
                    Text(def.number).font(.system(size: 20, weight: .black, design: .rounded)).foregroundStyle(.white)
                }
            }
            VStack(alignment: .leading, spacing: 5) {
                Text(def.display).font(.system(size: 17, weight: .black, design: .rounded))
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
        case 0: return "Você não tem"
        case 1: return "Você tem (1×)"
        default: return "Você tem (\(count)×)"
        }
    }

    private func hintPill(_ text: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(text)
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

    // MARK: - Lifecycle

    private func activate() {
        camera.scanMode = (checkTab == .sticker) ? .sticker : .qr
        camera.start()
        if checkTab == .sticker { attachStickerHandler() }
        else { attachQrHandler(); generateQR() }
    }

    private func deactivate() {
        camera.onStickerFound = nil
        camera.onQRFound = nil
        camera.stop()
    }

    private func generateQR() {
        let counts = collection.counts
        Task.detached(priority: .userInitiated) {
            let hex = QrCodeUtils.encode(counts: counts)
            let img = QrCodeUtils.generateQRImage(from: hex)
            await MainActor.run { qrImage = img }
        }
    }

    private func attachStickerHandler() {
        camera.onQRFound = nil
        camera.onStickerFound = { id in
            guard id != lastID else { return }
            let hasIt = collection.count(for: id) > 0
            if hasIt { SoundManager.playHasSticker() } else { SoundManager.playMissingSticker() }
            withAnimation(.spring(duration: 0.35)) { lastID = id }
        }
    }

    private func attachQrHandler() {
        camera.onStickerFound = nil
        camera.onQRFound = { payload in
            guard payload != lastScannedQr else { return }
            lastScannedQr = payload
            guard let theirCounts = QrCodeUtils.decode(hex: payload) else { return }
            let result = QrCodeUtils.computeTrades(
                myCounts: collection.counts,
                theirCounts: theirCounts
            )
            withAnimation { tradeResult = result; qrState = .result }
        }
    }
}
