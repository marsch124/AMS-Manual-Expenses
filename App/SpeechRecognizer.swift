import AVFoundation
import Speech

/// Records from the microphone and turns speech into text.
/// Stops by itself after a short pause, then calls `onFinish` with the sentence.
@MainActor
final class SpeechRecognizer: ObservableObject {
    @Published private(set) var transcript = ""
    @Published private(set) var isRecording = false
    @Published var errorMessage: String?
    var onFinish: ((String) -> Void)?

    private var engine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var silenceTimer: Task<Void, Never>?

    func toggle(localeID: String) {
        if isRecording {
            finish()
        } else {
            Task { await start(localeID: localeID) }
        }
    }

    private func authorize() async -> Bool {
        let speechAllowed = await withCheckedContinuation { (c: CheckedContinuation<Bool, Never>) in
            SFSpeechRecognizer.requestAuthorization { c.resume(returning: $0 == .authorized) }
        }
        guard speechAllowed else {
            errorMessage = "Speech recognition is turned off. Allow it in Settings › Expenses."
            return false
        }
        guard await AVAudioApplication.requestRecordPermission() else {
            errorMessage = "Microphone access is turned off. Allow it in Settings › Expenses."
            return false
        }
        return true
    }

    private func start(localeID: String) async {
        errorMessage = nil
        guard await authorize() else { return }
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: localeID)), recognizer.isAvailable else {
            errorMessage = "Speech recognition for this language is not available right now."
            return
        }
        transcript = ""
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let engine = AVAudioEngine()
            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            Self.installTap(on: engine.inputNode, feeding: request)
            engine.prepare()
            try engine.start()

            self.engine = engine
            self.request = request
            isRecording = true
            task = Self.recognize(with: recognizer, request: request) { [weak self] text, done in
                Task { @MainActor in
                    guard let self, self.isRecording else { return }
                    if let text {
                        self.transcript = text
                        self.restartSilenceTimer(seconds: 1.8)
                    }
                    if done { self.finish() }
                }
            }
            restartSilenceTimer(seconds: 6)
        } catch {
            errorMessage = "Could not start the microphone: \(error.localizedDescription)"
            teardown()
        }
    }

    // Audio and recognition callbacks arrive on background threads, so they are set up outside the main actor.
    private nonisolated static func installTap(on input: AVAudioInputNode, feeding request: SFSpeechAudioBufferRecognitionRequest) {
        input.installTap(onBus: 0, bufferSize: 1024, format: input.outputFormat(forBus: 0)) { buffer, _ in
            request.append(buffer)
        }
    }

    private nonisolated static func recognize(
        with recognizer: SFSpeechRecognizer,
        request: SFSpeechAudioBufferRecognitionRequest,
        handler: @escaping @Sendable (String?, Bool) -> Void
    ) -> SFSpeechRecognitionTask {
        recognizer.recognitionTask(with: request) { result, error in
            handler(result?.bestTranscription.formattedString, error != nil || (result?.isFinal ?? false))
        }
    }

    private func restartSilenceTimer(seconds: Double) {
        silenceTimer?.cancel()
        silenceTimer = Task { [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled else { return }
            self?.finish()
        }
    }

    private func finish() {
        guard isRecording else { return }
        teardown()
        let text = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty {
            errorMessage = "Nothing heard. Tap the microphone and try again."
        } else {
            onFinish?(text)
        }
    }

    private func teardown() {
        silenceTimer?.cancel()
        silenceTimer = nil
        engine?.stop()
        engine?.inputNode.removeTap(onBus: 0)
        engine = nil
        request?.endAudio()
        request = nil
        task?.cancel()
        task = nil
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
