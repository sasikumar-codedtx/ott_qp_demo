import AVFoundation
import Combine
import Foundation
import Speech

@MainActor
final class SpeechRecognitionService: ObservableObject {
    @Published private(set) var transcript = ""
    @Published private(set) var isRecording = false
    @Published private(set) var statusText = "Tap the mic and start speaking"
    @Published private(set) var selectedLanguage: SupportedSpeechLanguage = .english

    private let audioEngine = AVAudioEngine()
    private var recognitionSessions: [RecognitionSession] = []
    private var isInputTapInstalled = false

    func setLanguage(_ language: SupportedSpeechLanguage) {
        guard selectedLanguage != language else { return }
        let wasRecording = isRecording
        stop()
        selectedLanguage = language
        transcript = ""
        statusText = wasRecording ? "Switching to \(language.displayName)..." : "Tap the mic and start speaking"
    }

    @discardableResult
    func prepareSession() async -> Bool {
        guard !isRecording else { return true }
        statusText = "Getting voice ready..."

        do {
            try await requestPermissions()
            try activateAudioSession()
            statusText = "Starting microphone..."
            print("[SpeechRecognition] Session prepared for \(selectedLanguage.locale.identifier)")
            return true
        } catch {
            print("[SpeechRecognition] Prepare failed: \(error.localizedDescription)")
            statusText = "Speech unavailable. Type your query instead."
            return false
        }
    }

    func start() async {
        guard !isRecording else { return }

        do {
            try await requestPermissions()
            try await startRecognitionWithRetry()
        } catch {
            print("[SpeechRecognition] Start failed: \(error.localizedDescription)")
            cleanupRecognitionSession()
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            statusText = "Speech unavailable. Type your query instead."
        }
    }

    func stop() {
        audioEngine.stop()
        if isInputTapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            isInputTapInstalled = false
        }
        recognitionSessions.forEach { session in
            session.request.endAudio()
            session.task?.cancel()
        }
        recognitionSessions = []
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        isRecording = false
        if transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            statusText = "No speech detected"
        }
    }

    func reset() {
        stop()
        transcript = ""
        statusText = "Tap the mic and start speaking"
    }

    private func requestPermissions() async throws {
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        guard speechStatus == .authorized else {
            print("[SpeechRecognition] Speech authorization denied: \(speechStatus.rawValue)")
            throw AppError.invalidResponse
        }

        let audioGranted = await AVAudioApplication.requestRecordPermission()
        guard audioGranted else {
            print("[SpeechRecognition] Microphone permission denied")
            throw AppError.invalidResponse
        }
    }

    private func activateAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(
            .playAndRecord,
            mode: .measurement,
            options: [.duckOthers, .defaultToSpeaker, .allowBluetoothHFP]
        )
        try audioSession.setPreferredIOBufferDuration(0.005)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }

    private func startRecognitionWithRetry() async throws {
        do {
            try startRecognition()
        } catch {
            print("[SpeechRecognition] First start attempt failed: \(error.localizedDescription)")
            cleanupRecognitionSession()
            try? await Task.sleep(for: .milliseconds(450))
            try startRecognition()
        }
    }

    private func startRecognition() throws {
        cleanupRecognitionSession()
        audioEngine.reset()
        transcript = ""

        guard let recognizer = SFSpeechRecognizer(locale: selectedLanguage.locale), recognizer.isAvailable else {
            statusText = "\(selectedLanguage.displayName) speech is unavailable. Try English or type your query."
            print("[SpeechRecognition] Recognizer unavailable for \(selectedLanguage.locale.identifier)")
            throw AppError.invalidResponse
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.taskHint = .search
        if #available(iOS 16.0, *) {
            request.addsPunctuation = false
        }
        let session = RecognitionSession(language: selectedLanguage, recognizer: recognizer, request: request)
        let sessions = [session]
        recognitionSessions = sessions

        try activateAudioSession()

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        guard recordingFormat.sampleRate.isFinite,
              recordingFormat.sampleRate > 0,
              recordingFormat.channelCount > 0 else {
            statusText = "Microphone unavailable. Type your query instead."
            print("[SpeechRecognition] Invalid recording format: sampleRate=\(recordingFormat.sampleRate) channels=\(recordingFormat.channelCount)")
            throw AppError.invalidResponse
        }

        if isInputTapInstalled {
            inputNode.removeTap(onBus: 0)
            isInputTapInstalled = false
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }
        isInputTapInstalled = true

        audioEngine.prepare()
        try audioEngine.start()
        isRecording = true
        statusText = "Listening in \(selectedLanguage.displayName)..."
        print("[SpeechRecognition] Listening started locale=\(selectedLanguage.locale.identifier) sampleRate=\(recordingFormat.sampleRate) channels=\(recordingFormat.channelCount)")

        session.task = recognizer.recognitionTask(with: request) { [weak self, weak session] result, error in
            Task { @MainActor in
                guard let self, let session else { return }

                if let result {
                    self.consume(result: result, language: session.language)
                }

                if let error {
                    print("[SpeechRecognition] Recognition error: \(error.localizedDescription)")
                    session.didFail = true
                    self.handleRecognitionFailureIfNeeded()
                }
            }
        }
    }

    private func consume(result: SFSpeechRecognitionResult, language: SupportedSpeechLanguage) {
        let candidate = result.bestTranscription.formattedString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !candidate.isEmpty else { return }

        transcript = candidate
        statusText = result.isFinal ? "Searching..." : "Listening in \(language.displayName)..."

        if result.isFinal {
            stop()
        }
    }

    private func handleRecognitionFailureIfNeeded() {
        guard recognitionSessions.isEmpty == false else { return }
        if recognitionSessions.allSatisfy(\.didFail), transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            stop()
        }
    }

    private func cleanupRecognitionSession() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }

        if isInputTapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            isInputTapInstalled = false
        }

        recognitionSessions.forEach { session in
            session.request.endAudio()
            session.task?.cancel()
        }
        recognitionSessions = []
        isRecording = false
    }
}

enum SupportedSpeechLanguage: String, CaseIterable, Identifiable {
    case english
    case tamil
    case hindi

    var id: String { rawValue }

    var locale: Locale {
        switch self {
        case .english:
            return Locale(identifier: "en_IN")
        case .tamil:
            return Locale(identifier: "ta_IN")
        case .hindi:
            return Locale(identifier: "hi_IN")
        }
    }

    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .tamil:
            return "தமிழ்"
        case .hindi:
            return "हिन्दी"
        }
    }

    var menuTitle: String {
        switch self {
        case .english:
            return "English"
        case .tamil:
            return "Tamil"
        case .hindi:
            return "Hindi"
        }
    }
}

private final class RecognitionSession {
    let language: SupportedSpeechLanguage
    let recognizer: SFSpeechRecognizer
    let request: SFSpeechAudioBufferRecognitionRequest
    var task: SFSpeechRecognitionTask?
    var didFail = false

    init(
        language: SupportedSpeechLanguage,
        recognizer: SFSpeechRecognizer,
        request: SFSpeechAudioBufferRecognitionRequest
    ) {
        self.language = language
        self.recognizer = recognizer
        self.request = request
    }
}
