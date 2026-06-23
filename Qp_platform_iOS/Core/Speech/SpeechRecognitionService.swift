import AVFoundation
import Combine
import Foundation
import Speech

@MainActor
final class SpeechRecognitionService: ObservableObject {
    @Published private(set) var transcript = ""
    @Published private(set) var isRecording = false
    @Published private(set) var statusText = "Tap the mic and start speaking"

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en_IN"))
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    func start() async {
        guard !isRecording else { return }

        do {
            try await requestPermissions()
            try startRecognition()
        } catch {
            statusText = "Speech unavailable. Type your query instead."
            stop()
        }
    }

    func stop() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
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
            throw AppError.invalidResponse
        }

        let audioGranted = await AVAudioApplication.requestRecordPermission()
        guard audioGranted else {
            throw AppError.invalidResponse
        }
    }

    private func startRecognition() throws {
        recognitionTask?.cancel()
        recognitionTask = nil
        transcript = ""

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak request] buffer, _ in
            request?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
        isRecording = true
        statusText = "Listening..."

        recognitionTask = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }

                if let result {
                    self.transcript = result.bestTranscription.formattedString
                    self.statusText = result.isFinal ? "Searching..." : "Listening..."
                    if result.isFinal {
                        self.stop()
                    }
                }

                if error != nil {
                    self.stop()
                }
            }
        }
    }
}
