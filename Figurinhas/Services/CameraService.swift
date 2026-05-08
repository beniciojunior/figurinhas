import AVFoundation
import Vision
import SwiftUI

// MARK: - Camera preview (UIViewRepresentable)

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> _PreviewView { _PreviewView(session: session) }
    func updateUIView(_ uiView: _PreviewView, context: Context) {}

    class _PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var layer0: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }

        init(session: AVCaptureSession) {
            super.init(frame: .zero)
            layer0.session = session
            layer0.videoGravity = .resizeAspectFill
        }
        required init?(coder: NSCoder) { fatalError() }
    }
}

// MARK: - Camera + OCR service

final class CameraService: NSObject, ObservableObject {

    @Published var isAuthorized = false
    @Published var permissionDenied = false

    let session = AVCaptureSession()

    enum ScanMode { case sticker, qr }

    /// Called on main thread when a valid sticker ID is recognized.
    var onStickerFound: ((String) -> Void)?

    /// Called on main thread when a QR code payload is recognized.
    var onQRFound: ((String) -> Void)?

    var scanMode: ScanMode = .sticker {
        didSet { recognizerQ.async { self.lastDispatchedID = nil } }
    }

    private let sessionQ    = DispatchQueue(label: "cam.session",    qos: .userInitiated)
    private let recognizerQ = DispatchQueue(label: "cam.recognize", qos: .userInitiated)
    private var lastProcess: Date = .distantPast
    private let throttle: TimeInterval = 0.12   // ~8 fps recognition

    // Last sticker ID dispatched to the main thread.
    // Guarded exclusively on recognizerQ — prevents double-firing the same ID
    // even if two OCR completions arrive before the view updates its own state.
    private var lastDispatchedID: String?

    // Pre-compiled regex — avoids re-allocating on every frame
    private static let glueRegex: NSRegularExpression? =
        try? NSRegularExpression(pattern: #"(?<![A-Z])([A-Z0-9]{2,3})([0-9ILOSB\|]{1,2})(?![A-Z0-9])"#)
    private static let spacedRegex: NSRegularExpression? =
        try? NSRegularExpression(pattern: #"(?<![A-Z])([A-Z0-9]{2,3})(?:\s+|[-_:])([0-9ILOSB\|]{1,2})(?![0-9A-Z])"#)

    // Center strip of the frame (normalized, Vision origin = bottom-left).
    // Focusing here avoids wasting time on background clutter at the edges.
    private static let roi = CGRect(x: 0.05, y: 0.10, width: 0.90, height: 0.80)

    // MARK: Auth + Setup

    func requestAndSetup() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.main.async { self.isAuthorized = true }
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                    self?.permissionDenied = !granted
                }
                if granted { self?.setupSession() }
            }
        default:
            DispatchQueue.main.async {
                self.isAuthorized = false
                self.permissionDenied = true
            }
        }
    }

    private func setupSession() {
        sessionQ.async { [weak self] in
            guard let self else { return }
            self.session.beginConfiguration()
            self.session.sessionPreset = .hd1280x720

            guard
                let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                let input  = try? AVCaptureDeviceInput(device: device),
                self.session.canAddInput(input)
            else { self.session.commitConfiguration(); return }

            self.session.addInput(input)

            let output = AVCaptureVideoDataOutput()
            output.alwaysDiscardsLateVideoFrames = true
            output.setSampleBufferDelegate(self, queue: self.recognizerQ)

            if self.session.canAddOutput(output) { self.session.addOutput(output) }

            // Portrait rotation
            if let conn = output.connection(with: .video) {
                if conn.isVideoRotationAngleSupported(90) {
                    conn.videoRotationAngle = 90
                }
            }

            self.session.commitConfiguration()
        }
    }

    // MARK: Start / Stop

    func start() {
        sessionQ.async { [weak self] in
            guard let self, !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    func stop() {
        sessionQ.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    /// Clears the last-dispatched guard so the same sticker can fire again.
    /// Call this when the user explicitly asks to re-scan (e.g. taps "Limpar").
    func resetLastFound() {
        recognizerQ.async { [weak self] in self?.lastDispatchedID = nil }
    }
}

// MARK: - Sample buffer delegate + OCR

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {

        let now = Date()
        guard now.timeIntervalSince(lastProcess) >= throttle else { return }
        lastProcess = now

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        if scanMode == .qr {
            let req = VNDetectBarcodesRequest { [weak self] request, _ in
                guard let self else { return }
                guard let obs = (request.results as? [VNBarcodeObservation])?
                    .first(where: { $0.symbology == .qr }),
                      let payload = obs.payloadStringValue,
                      payload != self.lastDispatchedID else { return }
                self.lastDispatchedID = payload
                DispatchQueue.main.async { self.onQRFound?(payload) }
            }
            req.symbologies = [.qr]
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)
            try? handler.perform([req])
            return
        }

        let req = VNRecognizeTextRequest { [weak self] request, _ in
            guard let self else { return }
            let observations = (request.results as? [VNRecognizedTextObservation]) ?? []
            let strings = observations.compactMap { $0.topCandidates(1).first?.string }
            guard let id = self.findStickerID(in: strings) else { return }

            // Already dispatched this ID — drop until resetLastFound() is called.
            // This runs on recognizerQ (serial), so the check+write is atomic.
            guard id != self.lastDispatchedID else { return }
            self.lastDispatchedID = id

            DispatchQueue.main.async { self.onStickerFound?(id) }
        }
        req.recognitionLevel = .fast
        req.usesLanguageCorrection = false
        req.recognitionLanguages = ["en-US"]   // skip multi-language detection
        req.minimumTextHeight = 0.02           // ignore very small text (faster)
        req.regionOfInterest = CameraService.roi

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)
        try? handler.perform([req])
    }

    // MARK: - Pattern matching

    private func findStickerID(in texts: [String]) -> String? {
        // First, try direct CODE+NUMBER matching per OCR line ("ESP 1", "PAN19", etc.).
        if let id = findViaLineRegex(in: texts) { return id }
        // Primary strategy: token-based — more resilient to OCR splitting "19" → "1" + "9"
        if let id = findViaTokens(in: texts) { return id }
        let joined = texts.joined(separator: " ").uppercased()
        // Fallback: regex on the joined string (handles code+number glued without space)
        if let id = findViaRegex(in: joined) { return id }
        // Cross-observation fallback: code and number may be in separate OCR observations
        // ("SUI" in one line, "13" in another). Apply spaced regex to the joined text.
        return findViaLineRegex(in: [joined])
    }

    private func findViaLineRegex(in texts: [String]) -> String? {
        guard let regex = CameraService.spacedRegex else { return nil }

        for raw in texts {
            let text = raw.uppercased()
            let ns = text as NSString
            let matches = regex.matches(in: text, range: NSRange(location: 0, length: ns.length))

            for m in matches {
                guard
                    let cr = Range(m.range(at: 1), in: text),
                    let nr = Range(m.range(at: 2), in: text)
                else { continue }
                let code = normalizeOCRCodeToken(String(text[cr]))
                guard code.count >= 2, code.count <= 3 else { continue }
                let number = normalizeOCRNumberToken(String(text[nr]))
                let id = "\(code)\(number)"
                if StickerData.validIDs.contains(id) { return id }
            }
        }
        return nil
    }

    /// Splits each OCR string into whitespace tokens and walks them looking for
    /// CODE (2-3 letters) followed by a number.  Critically, it tries to form a
    /// 2-digit number **before** accepting a 1-digit one, which prevents "PAN 1"
    /// being returned when the actual sticker is "PAN 19" and the OCR emitted
    /// the digits as two separate tokens ("1" and "9").
    private func findViaTokens(in texts: [String]) -> String? {
        for raw in texts {
            let normalized = raw.uppercased()
            let tokens = normalized
                .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
                .map(String.init)
                .filter { !$0.isEmpty }

            for i in 0 ..< tokens.count {
                let token = normalizeOCRCodeToken(tokens[i])

                // Must be 2–3 purely alphabetic uppercase chars to be a sticker code
                guard (2...3).contains(token.count),
                      token.unicodeScalars.allSatisfy({ CharacterSet.uppercaseLetters.contains($0) })
                else { continue }

                let code = token
                guard i + 1 < tokens.count else { continue }
                let next = tokens[i + 1]

                // Case A: next token is already a 2-digit number ("PAN" + "19")
                let normalizedNext = normalizeOCRNumberToken(next)
                if normalizedNext.count == 2, normalizedNext.allSatisfy(\.isNumber) {
                    let id = "\(code)\(normalizedNext)"
                    if StickerData.validIDs.contains(id) { return id }
                }

                // Case B: next token is 1 digit + token after is 1 digit
                // We only combine within the same OCR observation line.
                if normalizedNext.count == 1, normalizedNext.allSatisfy(\.isNumber), i + 2 < tokens.count {
                    let after = tokens[i + 2]
                    let normalizedAfter = normalizeOCRNumberToken(after)
                    if normalizedAfter.count == 1, normalizedAfter.allSatisfy(\.isNumber) {
                        let id = "\(code)\(normalizedNext)\(normalizedAfter)"
                        if StickerData.validIDs.contains(id) { return id }
                    }
                }

                // Case C: next token is a single-digit number (true 1-digit sticker)
                if normalizedNext.count == 1, normalizedNext.allSatisfy(\.isNumber) {
                    let id = "\(code)\(normalizedNext)"
                    if StickerData.validIDs.contains(id) { return id }
                }
            }
        }
        return nil
    }

    /// Regex fallback for when code and number are glued together (e.g. "PAN19").
    private func findViaRegex(in text: String) -> String? {
        guard let regex = CameraService.glueRegex else { return nil }

        let ns = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: ns.length))

        for m in matches {
            guard
                let cr = Range(m.range(at: 1), in: text),
                let nr = Range(m.range(at: 2), in: text)
            else { continue }
            let code = normalizeOCRCodeToken(String(text[cr]))
            guard code.count >= 2, code.count <= 3 else { continue }
            let number = normalizeOCRNumberToken(String(text[nr]))
            let id = "\(code)\(number)"
            if StickerData.validIDs.contains(id) { return id }
        }
        return nil
    }

    /// Converts common OCR confusions in numeric tokens.
    /// Example: "I" -> "1", "l" -> "1", "|" -> "1", "O" -> "0".
    private func normalizeOCRNumberToken(_ raw: String) -> String {
        let upper = raw.uppercased()
        return String(upper.map { ch in
            switch ch {
            case "I", "L", "|": return "1"
            case "O": return "0"
            case "S": return "5"
            case "B": return "8"
            default: return ch
            }
        })
    }

    /// Converts common OCR confusions in country codes.
    /// Example: "CR0" -> "CRO", "SU1" -> "SUI", "5UI" -> "SUI", "E6Y" -> "EGY".
    private func normalizeOCRCodeToken(_ raw: String) -> String {
        let upper = raw.uppercased()
        return String(upper.map { ch in
            switch ch {
            case "0": return "O"
            case "1", "|": return "I"
            case "5": return "S"
            case "6": return "G"
            case "8": return "B"
            default: return ch
            }
        })
    }
}
