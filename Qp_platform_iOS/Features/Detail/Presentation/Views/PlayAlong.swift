import Combine
import SwiftUI

// MARK: - Model

struct PlayAlongQuestion: Identifiable, Equatable {
    struct Option: Identifiable, Equatable {
        let letter: String
        let text: String
        var id: String { letter }
    }

    let id: String
    let start: Double          // seconds — question appears
    let end: Double            // seconds — answer locks
    let revealAt: Double       // seconds — overlay dismisses (video reveals the answer)
    let question: String
    let options: [Option]
    let correctLetter: String? // nil for "arrange"-type questions
    let answerText: String

    /// Length of the answering window — drives the countdown (e.g. 36s).
    var answerDuration: Double { max(0, end - start) }

    /// When the overlay dismisses: a fixed short hold after the lock so the revealed
    /// answer + animation are clearly visible, then it closes. (The data's
    /// answer_revealed_time is unreliable — often at/before end_time — so it's not used.)
    var dismissTime: Double { end + revealHold }

    private var revealHold: Double { 5 }
}

// MARK: - Catalog (gated to the KBC / play-along content)

enum PlayAlongCatalog {
    static let contentID = "DFE596C8-9216-4483-8530-3FB880610015"

    /// Questions for the given content id, or empty when play-along is not enabled for it.
    static func questions(forContentID id: String?) -> [PlayAlongQuestion] {
        guard let id, id.caseInsensitiveCompare(contentID) == .orderedSame else { return [] }
        return parsed
    }

    private static func seconds(_ value: String) -> Double {
        let parts = value.split(separator: ":").compactMap { Double($0) }
        guard parts.count == 2 else { return Double(value) ?? 0 }
        return parts[0] * 60 + parts[1]
    }

    private struct RawCatalog: Decodable { let questions: [RawQuestion] }
    private struct RawQuestion: Decodable {
        let start_time: String
        let end_time: String
        let answer_revealed_time: String
        let question: String
        let options: [String: String]
        let answer: String?
        let correct_answer: String?
    }

    private static let parsed: [PlayAlongQuestion] = {
        guard
            let data = json.data(using: .utf8),
            let raw = try? JSONDecoder().decode(RawCatalog.self, from: data)
        else { return [] }

        return raw.questions.enumerated().map { index, q in
            let options = q.options
                .sorted { $0.key < $1.key }
                .map { PlayAlongQuestion.Option(letter: $0.key, text: $0.value) }

            let answerText = q.correct_answer ?? q.answer ?? ""
            let correctLetter = q.correct_answer.flatMap { correct in
                options.first { $0.text == correct }?.letter
            }

            return PlayAlongQuestion(
                id: "q\(index)",
                start: seconds(q.start_time),
                end: seconds(q.end_time),
                revealAt: seconds(q.answer_revealed_time),
                question: q.question,
                options: options,
                correctLetter: correctLetter,
                answerText: answerText
            )
        }
        .sorted { $0.start < $1.start }
    }()

    // The play-along question track (Response.json).
    private static let json = #"""
    {
      "questions": [
    { "start_time": "0:5", "end_time": "21.2", "question": "The term 'getting a shock' is associated with which of these?", "options": { "A": "Paper", "B": "Electricity", "C": "Wood", "D": "Wind" }, "correct_answer": "Electricity", "answer_revealed_time": "3:45" },
        { "start_time": "3:23", "end_time": "3:46", "question": "The term 'getting a shock' is associated with which of these?", "options": { "A": "Paper", "B": "Electricity", "C": "Wood", "D": "Wind" }, "correct_answer": "Electricity", "answer_revealed_time": "3:45" },
        { "start_time": "4:14", "end_time": "4:39", "question": "Which of these food items is usually not prepared by frying?", "options": { "A": "Poori", "B": "Samosa", "C": "Jalebi", "D": "Kheer" }, "correct_answer": "Kheer", "answer_revealed_time": "4:38" },
        { "start_time": "5:43", "end_time": "6:12", "question": "Usually, among these birds, which one has the longest legs?", "options": { "A": "Eagle", "B": "Pigeon", "C": "Crane", "D": "Owl" }, "correct_answer": "Crane", "answer_revealed_time": "6:11" },
        { "start_time": "6:22", "end_time": "7:00", "question": "Which was the only undefeated side in the group stages of the 2023 ODI World Cup?", "options": { "A": "India", "B": "South Africa", "C": "Australia", "D": "New Zealand" }, "correct_answer": "India", "answer_revealed_time": "6:59" },
        { "start_time": "7:12", "end_time": "8:44", "question": "Which tree's leaves are shown here?", "options": { "A": "Coconut", "B": "Tulsi", "C": "Mango", "D": "Banana" }, "correct_answer": "Mango", "answer_revealed_time": "8:43" },
        { "start_time": "11:35", "end_time": "12:09", "question": "Which of these is issued under the National Food Security Act?", "options": { "A": "Driving license", "B": "Ration card", "C": "Aadhaar card", "D": "PAN Card" }, "correct_answer": "Ration card", "answer_revealed_time": "12:08" },
        { "start_time": "13:24", "end_time": "15:43", "question": "Who among these organised the Indian Ambulance Corps in Natal, South Africa in 1899?", "options": { "A": "Pandit Jawaharlal Nehru", "B": "Dr S Radhakrishnan", "C": "Lokmanya Tilak", "D": "Mahatma Gandhi" }, "correct_answer": "Mahatma Gandhi", "answer_revealed_time": "15:42" },
        { "start_time": "16:26", "end_time": "16:58", "question": "Which of these sportspersons has never played in the Olympics?", "options": { "A": "PV Sindhu", "B": "Sunil Chhetri", "C": "Milkha Singh", "D": "Major Dhyan Chand" }, "correct_answer": "Sunil Chhetri", "answer_revealed_time": "16:57" },
        { "start_time": "17:25", "end_time": "18:13", "question": "According to the Rigveda, which of these gods was born out of the breath of the Vishwapurusha?", "options": { "A": "Lord Vayu", "B": "Lord Agni", "C": "Lord Ganesh", "D": "Lord Rama" }, "correct_answer": "Lord Vayu", "answer_revealed_time": "18:12" },
        { "start_time": "19:05", "end_time": "20:19", "question": "Which of these states' capital is not named after a person?", "options": { "A": "Gujarat", "B": "Rajasthan", "C": "Chhattisgarh", "D": "Karnataka" }, "correct_answer": "Karnataka", "answer_revealed_time": "20:17" },
        { "start_time": "23:54", "end_time": "25:02", "question": "What is the last name of Sarat Chandra Chattopadhyay's character 'Devdas', who has appeared in many film adaptations?", "options": { "A": "Mukherjee", "B": "Chatterjee", "C": "Banerjee", "D": "Sen" }, "correct_answer": "Mukherjee", "answer_revealed_time": "25:01" },
        { "start_time": "26:14", "end_time": "26:55", "question": "Arrange these vehicles based on their usual seating capacity from the most to the least.", "options": { "A": "Train", "B": "Bicycle", "C": "Bus", "D": "Car" }, "answer": "A, C, D, B", "answer_revealed_time": "26:54" },
        { "start_time": "30:44", "end_time": "31:16", "question": "If you were eating a softie, what would you be eating?", "options": { "A": "Walnut", "B": "Papad", "C": "Laddu", "D": "Ice cream" }, "correct_answer": "Ice cream", "answer_revealed_time": "31:15" },
        { "start_time": "31:22", "end_time": "31:50", "question": "Which of these plants mainly grows in an aquatic environment?", "options": { "A": "Willow", "B": "Cactus", "C": "Seaweed", "D": "Eucalyptus" }, "correct_answer": "Seaweed", "answer_revealed_time": "31:49" },
        { "start_time": "31:57", "end_time": "32:34", "question": "If you take the audience poll lifeline what is the sum total of the percentages the options get?", "options": { "A": "25", "B": "100", "C": "50", "D": "20" }, "correct_answer": "100", "answer_revealed_time": "32:33" },
        { "start_time": "34:38", "end_time": "35:29", "question": "This is the 2.0 version of which song?", "options": { "A": "Character Sheela", "B": "Dabangg", "C": "Balam Pichkari", "D": "Badtameez Dil" }, "correct_answer": "Character Sheela", "answer_revealed_time": "35:28" },
        { "start_time": "35:39", "end_time": "36:12", "question": "Which of these words denotes both a small village, and a tragedy written by William Shakespeare?", "options": { "A": "Borough", "B": "Metropolis", "C": "Hamlet", "D": "Outpost" }, "correct_answer": "Hamlet", "answer_revealed_time": "36:11" },
        { "start_time": "36:44", "end_time": "37:33", "question": "Which of these animals does not live in Africa?", "options": { "A": "Image Option A", "B": "Image Option B", "C": "Image Option C", "D": "Image Option D" }, "correct_answer": "Image Option B", "answer_revealed_time": "37:32" },
        { "start_time": "37:55", "end_time": "39:55", "question": "The Sheetla Mata mandir in Gurugram is dedicated to a deity believed to be the wife of which figure from the Mahabharata?", "options": { "A": "Ashwatthama", "B": "Abhimanyu", "C": "Ghatotkacha", "D": "Dronacharya" }, "correct_answer": "Dronacharya", "answer_revealed_time": "39:55" },
        { "start_time": "40:24", "end_time": "41:33", "question": "From which source is the highest share of electricity generated in India?", "options": { "A": "Coal", "B": "Nuclear", "C": "Hydro", "D": "Solar" }, "correct_answer": "Coal", "answer_revealed_time": "41:32" },
        { "start_time": "42:20", "end_time": "45:44", "question": "In 2023, which Indian was a joint winner of the International Emmy Award for Best Comedy Series?", "options": { "A": "Kapil Sharma", "B": "Mallika Dua", "C": "Vir Das", "D": "Zakir Khan" }, "correct_answer": "Vir Das", "answer_revealed_time": "45:37" },
        { "start_time": "47:00", "end_time": "48:06", "question": "Arrange these parts of speech as they appear in this sentence: Brave Chintu quickly ran.", "options": { "A": "Noun", "B": "Adverb", "C": "Verb", "D": "Adjective" }, "answer": "D, A, B, C", "answer_revealed_time": "47:43" },
        { "start_time": "50:04", "end_time": "50:33", "question": "Which of these food items is not served as a liquid usually?", "options": { "A": "Sambar", "B": "Soup", "C": "Idli", "D": "Rasam" }, "correct_answer": "Idli", "answer_revealed_time": "50:32" },
        { "start_time": "50:41", "end_time": "51:17", "question": "Which of these practices is recommended to reduce waste and help the environment?", "options": { "A": "Recycle", "B": "Relocate", "C": "Burning", "D": "Digging" }, "correct_answer": "Recycle", "answer_revealed_time": "51:16" },
        { "start_time": "51:31", "end_time": "52:02", "question": "Fill in the blank of this song from the film Parichay: \"_____ soon Aaron, na char hai na thikana.\"", "options": { "A": "Malang", "B": "Musafir", "C": "Beqarar", "D": "Naaraaz" }, "correct_answer": "Musafir", "answer_revealed_time": "52:00" },
        { "start_time": "53:41", "end_time": "54:24", "question": "What household chore is this object used for?", "options": { "A": "Scrubbing clothes", "B": "Cutting vegetables", "C": "Dusting", "D": "Drying Utensils" }, "correct_answer": "Drying Utensils", "answer_revealed_time": "54:23" },
        { "start_time": "54:58", "end_time": "55:15", "question": "Which of these is not a district in Uttar Pradesh?", "options": { "A": "Agra", "B": "Amroha", "C": "Ghaziabad", "D": "Bhagalpur" }, "correct_answer": "Bhagalpur", "answer_revealed_time": "55:14" }
      ]
    }
    """#
}

// MARK: - Director

/// Drives the play-along from the player's seek position: a 3s teaser, the question
/// window with a live countdown to lock, then the reveal until the video reveals it.
/// If the user scrubs *into* a question window (rather than playing through), that
/// question is suppressed so it doesn't pop up unexpectedly.
@MainActor
final class PlayAlongDirector: ObservableObject {
    enum Stage: Equatable {
        case idle
        case teaser(PlayAlongQuestion)
        case asking(PlayAlongQuestion)
        case revealing(PlayAlongQuestion)
    }

    @Published private(set) var stage: Stage = .idle
    @Published private(set) var selection: String?
    @Published private(set) var remainingSeconds: Int = 0   // live countdown to lock (drives the ring)

    private var questions: [PlayAlongQuestion] = []
    private var suppressed: Set<String> = []
    private var activeID: String?
    private var openedID: String?   // question the user opened by tapping the teaser
    private var pendingSeek = false // a real seek happened; the next time tick is a jump landing
    private var lastTime: Double = 0

    private let teaserLead: Double = 3   // seconds before start_time the teaser appears

    var activeQuestion: PlayAlongQuestion? {
        switch stage {
        case .idle: return nil
        case let .teaser(q), let .asking(q), let .revealing(q): return q
        }
    }

    func configure(questions: [PlayAlongQuestion]) {
        self.questions = questions
        stage = .idle
        selection = nil
        suppressed = []
        activeID = nil
        openedID = nil
        pendingSeek = false
    }

    /// Called when the player reports a real user-initiated seek (not normal playback).
    /// The next `update(time:)` tick is treated as a jump landing.
    func markSeek() {
        pendingSeek = true
    }

    func update(time t: Double) {
        guard !questions.isEmpty else { return }

        // A real seek re-arms every question, then ignores only the one we landed
        // inside of — so jumping into a question's window skips it (don't auto-show),
        // while rewinding to re-watch lets its teaser arm again normally.
        if pendingSeek {
            pendingSeek = false
            suppressed.removeAll()
            if let landed = questions.first(where: { t >= $0.start - teaserLead && t < $0.dismissTime }) {
                suppressed.insert(landed.id)
            }
        }

        guard let q = questions.first(where: { t >= $0.start - teaserLead && t < $0.dismissTime }) else {
            if stage != .idle { stage = .idle }
            return
        }

        guard !suppressed.contains(q.id) else {
            if stage != .idle { stage = .idle }
            return
        }

        if activeID != q.id {
            activeID = q.id
            openedID = nil
            selection = nil
        }

        let opened = (openedID == q.id)

        // State machine:
        //  • [start-3, start)  → teaser button (only the tap opens the QA).
        //  • [start, end)      → QA panel, but ONLY if the user tapped the teaser;
        //                        otherwise the question is skipped (button hides at start).
        //  • [end, revealAt)   → reveal the answer, but ONLY if it was opened AND answered;
        //                        opened-but-unanswered (or never opened) just closes/ignores.
        let next: Stage
        if t < q.start {
            next = opened ? .asking(q) : .teaser(q)
        } else if t < q.end {
            next = opened ? .asking(q) : .idle
        } else {
            next = (opened && selection != nil) ? .revealing(q) : .idle
        }
        if next != stage {
            stage = next
        }

        // Live countdown to lock (only meaningful while an opened question is being answered).
        let r = (opened && t < q.end) ? max(0, Int(ceil(q.end - t))) : 0
        if r != remainingSeconds {
            remainingSeconds = r
        }
    }

    /// Hide everything and forget the in-flight question (e.g. when the full-screen
    /// player takes over). Keeps the configured questions so play-along re-arms on return.
    func suspend() {
        stage = .idle
        selection = nil
        openedID = nil
        activeID = nil
        pendingSeek = false
        remainingSeconds = 0
    }

    /// The QA panel opens only when the user taps the teaser button.
    func openFromTeaser() {
        if case let .teaser(q) = stage {
            openedID = q.id
            stage = .asking(q)
        }
    }

    func select(_ letter: String) {
        guard case .asking = stage else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.7)
        selection = letter
    }

    func remaining(at time: Double) -> Int {
        guard case let .asking(q) = stage else { return 0 }
        return max(0, Int(ceil(q.end - time)))
    }
}

// MARK: - Teaser button (big, shaking, slides up from the bottom)

struct PlayAlongTeaserButton: View {
    let onTap: () -> Void
    @State private var wiggle = false

    var body: some View {
        Button(action: onTap) {
            Image("playalone")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: 112)
                .shadow(color: Color.black.opacity(0.45), radius: 16, x: 0, y: 8)
                .rotationEffect(.degrees(wiggle ? 2.5 : -2.5))
                .scaleEffect(wiggle ? 1.03 : 0.99)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.22).repeatForever(autoreverses: true)) {
                wiggle = true
            }
        }
    }
}
