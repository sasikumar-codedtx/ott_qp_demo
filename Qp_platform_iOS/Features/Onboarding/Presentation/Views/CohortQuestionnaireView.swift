import SwiftUI

struct CohortQuestionnaireResult: Equatable {
    let entertainmentScore: Int
    let sportsScore: Int
    let realityScore: Int
    let primaryCategory: QuickplayCohort
    let preference: ProfilePreference
    let confidence: Int
}

struct CohortQuestionnaireView: View {
    let onComplete: (CohortQuestionnaireResult) async -> Void

    @State private var currentIndex = 0
    @State private var answers: [CohortQuestionnaireAnswer] = []
    @State private var selectedAnswerID: String?
    @State private var backgroundName = CohortQuestionnaireBackground.randomName()
    @State private var isFinishing = false
    @State private var cohortToast: String?

    private let questions = CohortQuestionnaireQuestion.defaultQuestions

    private var currentQuestion: CohortQuestionnaireQuestion {
        questions[currentIndex]
    }

    private var progress: CGFloat {
        CGFloat(currentIndex + 1) / CGFloat(questions.count)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                background

                VStack(spacing: 0) {
                    LogoGlowView(size: 94, glowScale: 1.04)
                        .padding(.top, proxy.safeAreaInsets.top + 18)

                    Text("Let’s get the vibe right.")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.top, 8)

                    progressBar
                        .padding(.top, 30)

                    questionCard
                        .padding(.top, 40)

                    answerStack
                        .padding(.top, 50)

                    Spacer(minLength: 16)

                    Button {
                        moveNext(with: nil)
                    } label: {
                        Text("I don’t know, Next")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 48)
                    }
                    .buttonStyle(.plain)
                    .disabled(isFinishing)
                    .padding(.horizontal, 16)
                    .padding(.bottom, proxy.safeAreaInsets.bottom + 24)
                }

                if let cohortToast {
                    CohortResultToast(message: cohortToast)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, proxy.safeAreaInsets.bottom + 34)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .navigationBarBackButtonHidden(true)
    }

    private var background: some View {
        Image(backgroundName)
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
            .overlay(Color.black.opacity(0.06).ignoresSafeArea())
    }

    private var progressBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.28))

                Capsule()
                    .fill(Color.white)
                    .frame(width: max(33, proxy.size.width * progress))
            }
        }
        .frame(width: 283, height: 4)
        .animation(.easeInOut(duration: 0.25), value: progress)
    }

    private var questionCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.black.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )

            Text(currentQuestion.title)
                .font(.system(size: 30, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .lineSpacing(4)
                .padding(.horizontal, 34)
        }
        .frame(width: 380, height: 199)
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
    }

    private var answerStack: some View {
        VStack(spacing: 14) {
            ForEach(currentQuestion.answers) { answer in
                CohortAnswerButton(
                    title: answer.title,
                    isSelected: selectedAnswerID == answer.id,
                    isDisabled: isFinishing
                ) {
                    selectedAnswerID = answer.id
                    moveNext(with: answer)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private func moveNext(with answer: CohortQuestionnaireAnswer?) {
        guard !isFinishing else { return }

        if let answer {
            answers.append(answer)
        }

        if currentIndex < questions.count - 1 {
            withAnimation(.easeInOut(duration: 0.24)) {
                currentIndex += 1
                selectedAnswerID = nil
                backgroundName = CohortQuestionnaireBackground.randomName(excluding: backgroundName)
            }
            return
        }

        isFinishing = true
        let result = CohortQuestionnaireScorer.score(answers: answers)
        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
            cohortToast = "\(result.primaryCategory.title) selected"
        }
        Task {
            try? await Task.sleep(for: .milliseconds(900))
            await onComplete(result)
        }
    }
}

struct CohortResultToast: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color(hex: "F6C759"))

            Text(message)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(
            Capsule(style: .continuous)
                .fill(Color.black.opacity(0.72))
                .overlay(Capsule(style: .continuous).stroke(Color.white.opacity(0.14), lineWidth: 1))
        )
        .shadow(color: Color.black.opacity(0.35), radius: 18, x: 0, y: 8)
    }
}

private struct CohortAnswerButton: View {
    let title: String
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .lineSpacing(3)
                .frame(maxWidth: .infinity, minHeight: 84)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(hex: "171717").opacity(isSelected ? 0.94 : 0.82))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(isSelected ? Color.white.opacity(0.86) : Color.white.opacity(0.08), lineWidth: isSelected ? 1.5 : 1)
                        )
                )
        }
        .buttonStyle(LiquidButtonPressStyle())
        .disabled(isDisabled)
    }
}

private enum CohortQuestionnaireBackground {
    static let names = ["resend-otp", "resend-otp-1", "resend-otp-2"]

    static func randomName(excluding current: String? = nil) -> String {
        let candidates = names.filter { $0 != current }
        return candidates.randomElement() ?? names[0]
    }
}

struct CohortQuestionnaireQuestion: Identifiable {
    let id = UUID()
    let title: String
    let answers: [CohortQuestionnaireAnswer]

    static let defaultQuestions: [CohortQuestionnaireQuestion] = [
        CohortQuestionnaireQuestion(
            title: "It’s Friday night. Which sounds more appealing",
            answers: [
                CohortQuestionnaireAnswer(title: "Watching something completely unpredictable unfold", category: .entertainment),
                CohortQuestionnaireAnswer(title: "Watching a high-stakes showdown where every moment matters", category: .sports),
                CohortQuestionnaireAnswer(title: "Watching real people compete, react, and surprise everyone", category: .reality)
            ]
        ),
        CohortQuestionnaireQuestion(
            title: "What pulls you into a show fastest?",
            answers: [
                CohortQuestionnaireAnswer(title: "Great storytelling with twists, emotion, and scale", category: .entertainment),
                CohortQuestionnaireAnswer(title: "Competitive action where every second changes the result", category: .sports),
                CohortQuestionnaireAnswer(title: "Real people, real pressure, and dramatic reactions", category: .reality)
            ]
        ),
        CohortQuestionnaireQuestion(
            title: "Pick the energy you want from your feed",
            answers: [
                CohortQuestionnaireAnswer(title: "Cinematic worlds, characters, music, and mystery", category: .entertainment),
                CohortQuestionnaireAnswer(title: "Big match tension, rivalries, and last-minute wins", category: .sports),
                CohortQuestionnaireAnswer(title: "Competition, eliminations, judges, and surprises", category: .reality)
            ]
        ),
        CohortQuestionnaireQuestion(
            title: "Which moment would you replay?",
            answers: [
                CohortQuestionnaireAnswer(title: "A hero reveal or a finale twist nobody saw coming", category: .entertainment),
                CohortQuestionnaireAnswer(title: "A clutch play that changes the entire game", category: .sports),
                CohortQuestionnaireAnswer(title: "A confession, argument, or win that feels personal", category: .reality)
            ]
        ),
        CohortQuestionnaireQuestion(
            title: "What should we recommend first?",
            answers: [
                CohortQuestionnaireAnswer(title: "Movies, originals, thrillers, and binge-worthy shows", category: .entertainment),
                CohortQuestionnaireAnswer(title: "Matches, highlights, analysis, and sports stories", category: .sports),
                CohortQuestionnaireAnswer(title: "Reality contests, celebrity moments, and unscripted drama", category: .reality)
            ]
        )
    ]
}

struct CohortQuestionnaireAnswer: Identifiable, Equatable {
    let id = UUID().uuidString
    let title: String
    let category: CohortQuestionnaireCategory
}

enum CohortQuestionnaireCategory: CaseIterable, Equatable {
    case entertainment
    case sports
    case reality

    var cohort: QuickplayCohort {
        switch self {
        case .entertainment:
            return .entertainment
        case .sports:
            return .sports
        case .reality:
            return .realityShows
        }
    }

    var preference: ProfilePreference {
        switch self {
        case .entertainment:
            return .entertainment
        case .sports:
            return .sports
        case .reality:
            return .realityShows
        }
    }
}

enum CohortQuestionnaireScorer {
    static func score(answers: [CohortQuestionnaireAnswer]) -> CohortQuestionnaireResult {
        guard !answers.isEmpty else {
            return CohortQuestionnaireResult(
                entertainmentScore: 0,
                sportsScore: 0,
                realityScore: 0,
                primaryCategory: .entertainment,
                preference: .entertainment,
                confidence: 0
            )
        }

        let entertainmentScore = answers.filter { $0.category == .entertainment }.count
        let sportsScore = answers.filter { $0.category == .sports }.count
        let realityScore = answers.filter { $0.category == .reality }.count
        let counts: [CohortQuestionnaireCategory: Int] = [
            .entertainment: entertainmentScore,
            .sports: sportsScore,
            .reality: realityScore
        ]
        let highestScore = counts.values.max() ?? 0
        let tiedCategories = counts.filter { $0.value == highestScore }.map(\.key)
        let latestTieAnswer = answers.reversed().first { tiedCategories.contains($0.category) }?.category
        let winner = latestTieAnswer ?? [.sports, .entertainment, .reality].first { tiedCategories.contains($0) } ?? .entertainment
        let totalAnswers = max(answers.count, 1)
        let confidence = Int(round((Double(highestScore) / Double(totalAnswers)) * 100))

        return CohortQuestionnaireResult(
            entertainmentScore: entertainmentScore,
            sportsScore: sportsScore,
            realityScore: realityScore,
            primaryCategory: winner.cohort,
            preference: winner.preference,
            confidence: confidence
        )
    }
}
