import SwiftUI
import UIKit

struct CohortQuestionnaireResult: Equatable, Sendable {
    let entertainmentScore: Int
    let sportsScore: Int
    let realityScore: Int
    let primaryCategory: QuickplayCohort
    let preference: ProfilePreference
    let confidence: Int
}

struct CohortQuestionnaireView: View {
    let profileName: String
    let profileImageName: String?
    let fallbackGlyph: String
    let onComplete: @MainActor (CohortQuestionnaireResult) -> Void

    @State private var currentIndex = 0
    @State private var scoredAnswers: [CohortSwipeAnswer] = []
    @State private var backgroundName = CohortQuestionnaireBackground.randomName()
    @State private var dragOffset: CGSize = .zero
    @State private var isAnimatingOut = false
    @State private var isPromotingNextCard = false
    @State private var isFinishing = false
    @State private var selectedResult: CohortQuestionnaireResult?

    private let questions = CohortSwipeQuestion.defaultQuestions

    init(
        profileName: String = "New Profile",
        profileImageName: String? = nil,
        fallbackGlyph: String = "P",
        onComplete: @escaping @MainActor (CohortQuestionnaireResult) -> Void
    ) {
        self.profileName = profileName
        self.profileImageName = profileImageName
        self.fallbackGlyph = fallbackGlyph
        self.onComplete = onComplete
    }

    private var currentQuestion: CohortSwipeQuestion {
        questions[min(currentIndex, questions.count - 1)]
    }

    private var nextQuestion: CohortSwipeQuestion? {
        guard currentIndex + 1 < questions.count else { return nil }
        return questions[currentIndex + 1]
    }

    private var thirdQuestion: CohortSwipeQuestion? {
        guard currentIndex + 2 < questions.count else { return nil }
        return questions[currentIndex + 2]
    }

    private var progress: CGFloat {
        guard !questions.isEmpty else { return 0 }
        return CGFloat(currentIndex + 1) / CGFloat(questions.count)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                background

                VStack(spacing: 0) {
                    header(topInset: proxy.safeAreaInsets.top + 60)

                    progressBar
                        .padding(.top, 18)

                    swipeStack(maxWidth: proxy.size.width)
                        .padding(.top, 26)

                    Spacer()
                        .frame(maxHeight: 56)

                    swipeControls
                        .padding(.bottom, proxy.safeAreaInsets.bottom + 32)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                // Skip button — top right
                VStack {
                    HStack {
                        Spacer()
                        Button(action: skipToDefault) {
                            Text("Skip")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white.opacity(0.6))
                                .underline()
                        }
                        .buttonStyle(.plain)
                        .padding(.top, proxy.safeAreaInsets.top + 18)
                        .padding(.trailing, 24)
                        .disabled(isFinishing)
                    }
                    Spacer()
                }

                if isFinishing, let selectedResult {
                    CohortCompletionOverlay(result: selectedResult)
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                        .zIndex(30)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
    .navigationBarBackButtonHidden(true)
    }

    private var background: some View {
        Image(backgroundName)
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
            .overlay(Color.black.opacity(0.08).ignoresSafeArea())
    }

    private func header(topInset: CGFloat) -> some View {
        VStack(spacing: 8) {
            ProfileAvatarView(
                imageName: profileImageName,
                fallbackGlyph: fallbackGlyph,
                size: 89.635
            )
            .shadow(color: Color.black.opacity(0.24), radius: 12, x: 0, y: 8)

            Text(profileName)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .frame(width: 120)

            Text("Let’s get the vibe right.")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .padding(.top, 3)
        }
        .padding(.top, topInset + 20)
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

    private func swipeStack(maxWidth: CGFloat) -> some View {
        let topWidth = min(380, maxWidth - 32)
        let topHeight = topWidth * (396 / 380)
        let secondWidth = topWidth * (343.535 / 380)
        let secondHeight = secondWidth * (358 / 343.535)
        let thirdWidth = topWidth * (315.707 / 380)
        let thirdHeight = thirdWidth * (329 / 315.707)

        return ZStack(alignment: .top) {
            if let thirdQuestion {
                CohortSwipeCard(
                    question: thirdQuestion,
                    backgroundName: backgroundName,
                    width: isPromotingNextCard ? secondWidth : thirdWidth,
                    height: isPromotingNextCard ? secondHeight : thirdHeight,
                    borderColor: isPromotingNextCard ? Color(hex: "703737") : Color(hex: "623030"),
                    borderWidth: isPromotingNextCard ? 3.616 : 3.323,
                    cornerRadius: isPromotingNextCard ? 27.121 : 24.924,
                    textSize: isPromotingNextCard ? 19.889 : 18.278,
                    isDimmed: !isPromotingNextCard
                )
                .offset(y: isPromotingNextCard ? 53 : 96)
                .animation(.spring(response: 0.42, dampingFraction: 0.78), value: isPromotingNextCard)
            }

            if let nextQuestion {
                CohortSwipeCard(
                    question: nextQuestion,
                    backgroundName: backgroundName,
                    width: isPromotingNextCard ? topWidth : secondWidth,
                    height: isPromotingNextCard ? topHeight : secondHeight,
                    borderColor: isPromotingNextCard ? Color(hex: "FF7B7B") : Color(hex: "703737"),
                    borderWidth: isPromotingNextCard ? 4 : 3.616,
                    cornerRadius: isPromotingNextCard ? 30 : 27.121,
                    textSize: 19.889,
                    isDimmed: false
                )
                .offset(y: isPromotingNextCard ? 0 : 53)
                .animation(.spring(response: 0.42, dampingFraction: 0.78), value: isPromotingNextCard)
                .zIndex(isPromotingNextCard ? 2 : 1)
            }

            CohortSwipeCard(
                question: currentQuestion,
                backgroundName: backgroundName,
                width: topWidth,
                height: topHeight,
                borderColor: dragOffset.width > 24 ? Color(hex: "34C759") : dragOffset.width < -24 ? Color(hex: "FF3B30") : Color(hex: "FF7B7B"),
                borderWidth: 4,
                cornerRadius: 30,
                textSize: 19.889,
                isDimmed: false,
                verdict: verdictText
            )
            .offset(dragOffset)
            .rotationEffect(.degrees(Double(dragOffset.width / 18)))
            .gesture(cardDragGesture)
            .animation(.spring(response: 0.32, dampingFraction: 0.78), value: dragOffset)
            .zIndex(3)
        }
        .frame(height: topHeight + 42)
    }

    private var cardDragGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                guard !isAnimatingOut, !isFinishing else { return }
                dragOffset = value.translation
            }
            .onEnded { value in
                guard !isAnimatingOut, !isFinishing else { return }
                if value.translation.width > 105 {
                    choose(.right)
                } else if value.translation.width < -105 {
                    choose(.left)
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.72)) {
                        dragOffset = .zero
                    }
                }
            }
    }

    private var verdictText: String? {
        if dragOffset.width > 34 {
            return "YES"
        }
        if dragOffset.width < -34 {
            return "NO"
        }
        return nil
    }

    private var swipeControls: some View {
        HStack(spacing: 103) {
            swipeControlButton(
                assetNames: ["tinderdislike"],
                fallbackSystemName: "hand.thumbsdown.fill",
                direction: .left
            )
            swipeControlButton(
                assetNames: ["tinderlike"],
                fallbackSystemName: "hand.thumbsup.fill",
                direction: .right
            )
        }
        .frame(height: 50)
    }

    private func swipeControlButton(assetNames: [String], fallbackSystemName: String, direction: CohortSwipeDirection) -> some View {
        Button {
            choose(direction)
        } label: {
            if let assetName = assetNames.first(where: { UIImage(named: $0) != nil }) {
                Image(assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
            } else {
                Image(systemName: fallbackSystemName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
                    )
            }
        }
        .buttonStyle(LiquidButtonPressStyle())
        .disabled(isFinishing || isAnimatingOut)
    }

    private func choose(_ direction: CohortSwipeDirection) {
        guard !isAnimatingOut, !isFinishing else { return }

        let answer = CohortSwipeAnswer(questionID: currentQuestion.id, direction: direction, categories: currentQuestion.categories(for: direction))
        scoredAnswers.append(answer)
        isAnimatingOut = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        withAnimation(.easeIn(duration: 0.22)) {
            dragOffset = CGSize(width: direction == .right ? 720 : -720, height: 40)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
                isPromotingNextCard = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.44) {
            moveNext()
        }
    }

    private func moveNext() {
        if currentIndex < questions.count - 1 {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                currentIndex += 1
                dragOffset = .zero
                isPromotingNextCard = false
                isAnimatingOut = false
            }
            return
        }

        finish()
    }

    private func finish() {
        isFinishing = true
        let result = CohortQuestionnaireScorer.score(answers: scoredAnswers)
        selectedResult = result
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
            isPromotingNextCard = false
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1250))
            onComplete(result)
        }
    }

    private func skipToDefault() {
        guard !isFinishing else { return }
        let result = CohortQuestionnaireResult(
            entertainmentScore: 1,
            sportsScore: 0,
            realityScore: 0,
            primaryCategory: .entertainment,
            preference: .entertainment,
            confidence: 100
        )
        isFinishing = true
        selectedResult = result
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
            isPromotingNextCard = false
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1250))
            onComplete(result)
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

private struct CohortCompletionOverlay: View {
    let result: CohortQuestionnaireResult
    @State private var pulse = false

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(
                    LinearGradient(
                        colors: [Color.black.opacity(0.56), Color.black.opacity(0.82)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Image(systemName: "sparkles")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(Color(hex: "F6C759"))
                    .scaleEffect(pulse ? 1.18 : 0.92)
                    .opacity(pulse ? 1 : 0.55)
                    .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: pulse)

                VStack(spacing: 8) {
                    Text("Finding your vibe")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)

                    Text("\(result.primaryCategory.title) selected")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.72))
                }

                ProgressView()
                    .tint(.white)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 26)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.black.opacity(0.54))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.34), radius: 24, x: 0, y: 14)
        }
        .onAppear {
            pulse = true
        }
    }
}

private struct CohortSwipeCard: View {
    let question: CohortSwipeQuestion
    let backgroundName: String
    let width: CGFloat
    let height: CGFloat
    let borderColor: Color
    let borderWidth: CGFloat
    let cornerRadius: CGFloat
    let textSize: CGFloat
    let isDimmed: Bool
    var verdict: String?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "4E4E4E"), Color(hex: "181818")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Image(backgroundName)
                .resizable()
                .scaledToFill()
                .opacity(isDimmed ? 0.62 : 0.88)
                .frame(width: width, height: height)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))

            LinearGradient(
                colors: [Color.black.opacity(0.08), Color.black.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )

            Text(question.title)
                .font(.system(size: textSize, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .textCase(.uppercase)
                .lineSpacing(6)
                .padding(.horizontal, 30)

            tag

            if let verdict {
                Text(verdict)
                    .font(.system(size: 34, weight: .black))
                    .foregroundStyle(verdict == "YES" ? Color(hex: "7AFFB8") : Color(hex: "FF3B30"))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(verdict == "YES" ? Color(hex: "7AFFB8") : Color(hex: "FF3B30"), lineWidth: 3)
                    )
                    .rotationEffect(.degrees(verdict == "YES" ? 12 : -12))
                    .offset(x: verdict == "YES" ? 66 : -66, y: -92)
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(4)
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(borderColor, lineWidth: borderWidth)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 28, x: 0, y: 0)
        .opacity(isDimmed ? 0.5 : 1)
    }

    private var tag: some View {
        VStack {
            HStack {
                Text(question.tag)
                    .font(.system(size: 13.297, weight: .bold))
                    .foregroundStyle(.white)
                    .textCase(.uppercase)
                    .padding(.horizontal, 16)
                    .frame(height: 32)
                    .background(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 25,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 11,
                            topTrailingRadius: 18,
                            style: .continuous
                        )
                        .fill(borderColor)
                    )
                Spacer()
            }
            Spacer()
        }
    }
}

private enum CohortQuestionnaireBackground {
    static let names = ["resend-otp", "resend-otp-1", "resend-otp-2"]

    static func randomName(excluding current: String? = nil) -> String {
        let candidates = names.filter { $0 != current }
        return candidates.randomElement() ?? names[0]
    }
}

private enum CohortSwipeDirection: Sendable {
    case left
    case right

    var logValue: String {
        switch self {
        case .left:
            return "left-no"
        case .right:
            return "right-yes"
        }
    }
}

private struct CohortSwipeQuestion: Identifiable, Sendable {
    let id = UUID().uuidString
    let title: String
    let tag: String
    let rightCategories: [CohortQuestionnaireCategory]
    let leftCategories: [CohortQuestionnaireCategory]

    func categories(for direction: CohortSwipeDirection) -> [CohortQuestionnaireCategory] {
        direction == .right ? rightCategories : leftCategories
    }

    static let defaultQuestions: [CohortSwipeQuestion] = [
        CohortSwipeQuestion(
            title: "Are people and personalities more interesting than competition?",
            tag: "People",
            rightCategories: [.reality],
            leftCategories: [.sports]
        ),
        CohortSwipeQuestion(
            title: "Do you love binge-watching stories?",
            tag: "Binge",
            rightCategories: [.entertainment],
            leftCategories: [.sports]
        ),
        CohortSwipeQuestion(
            title: "Do you enjoy seeing what happens next more than who wins?",
            tag: "Twist Ending",
            rightCategories: [.entertainment, .reality],
            leftCategories: [.sports]
        ),
        CohortSwipeQuestion(
            title: "Would you rather follow people than scores?",
            tag: "Follow",
            rightCategories: [.reality],
            leftCategories: [.sports]
        ),
        CohortSwipeQuestion(
            title: "Do cliffhangers keep you hooked?",
            tag: "Cliffhanger",
            rightCategories: [.entertainment],
            leftCategories: [.sports]
        ),
        CohortSwipeQuestion(
            title: "Do you enjoy watching real-life drama unfold?",
            tag: "Drama",
            rightCategories: [.reality],
            leftCategories: [.sports, .entertainment]
        ),
        CohortSwipeQuestion(
            title: "Do you like cheering for winners?",
            tag: "Winners",
            rightCategories: [.sports],
            leftCategories: [.entertainment, .reality]
        ),
        CohortSwipeQuestion(
            title: "Would you open a Starting Live Now notification immediately?",
            tag: "Live Now",
            rightCategories: [.sports],
            leftCategories: [.entertainment]
        )
    ]
}

private struct CohortSwipeAnswer: Equatable, Sendable {
    let questionID: String
    let direction: CohortSwipeDirection
    let categories: [CohortQuestionnaireCategory]
}

enum CohortQuestionnaireCategory: CaseIterable, Equatable, Sendable {
    case entertainment
    case sports
    case reality

    var logValue: String {
        switch self {
        case .entertainment:
            return "entertainment"
        case .sports:
            return "sports"
        case .reality:
            return "reality"
        }
    }

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

private enum CohortQuestionnaireScorer {
    static func score(answers: [CohortSwipeAnswer]) -> CohortQuestionnaireResult {
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

        var scores: [CohortQuestionnaireCategory: Int] = [
            .entertainment: 0,
            .sports: 0,
            .reality: 0
        ]

        for answer in answers {
            for category in answer.categories {
                scores[category, default: 0] += 1
            }
        }

        let entertainmentScore = scores[.entertainment, default: 0]
        let sportsScore = scores[.sports, default: 0]
        let realityScore = scores[.reality, default: 0]
        let rankedCategories: [CohortQuestionnaireCategory] = [.entertainment, .sports, .reality]
        let winner = rankedCategories.max { left, right in
            scores[left, default: 0] < scores[right, default: 0]
        } ?? .entertainment
        let highestScore = scores[winner, default: 0]
        let totalSignals = max(scores.values.reduce(0, +), 1)
        let confidence = Int(round((Double(highestScore) / Double(totalSignals)) * 100))

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
