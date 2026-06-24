import Foundation
import NaturalLanguage

enum AISearchQueryNormalizer {
    static func localizedDisplayText(from rawQuery: String) -> String {
        localizedDisplayText(from: rawQuery, language: nil)
    }

    static func localizedDisplayText(from rawQuery: String, language: SupportedSpeechLanguage?) -> String {
        let trimmed = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        let allReplacements: [String: String] = [
            "thiraipadam": "திரைப்படம்",
            "thirai padam": "திரைப்படம்",
            "thiraipadangal": "திரைப்படங்கள்",
            "thirapadngal": "திரைப்படம்",
            "thirapadangal": "திரைப்படங்கள்",
            "thira padangal": "திரைப்படங்கள்",
            "padam": "படம்",
            "padangal": "படங்கள்",
            "tamil movie": "தமிழ் திரைப்படம்",
            "tamil movies": "தமிழ் திரைப்படங்கள்",
            "chalchitra": "चलचित्र",
            "chalachitra": "चलचित्र",
            "chitra": "चित्र",
            "hindi movie": "हिंदी चलचित्र",
            "hindi movies": "हिंदी चलचित्र",
            "hindi film": "हिंदी फिल्म",
            "film": "फिल्म"
        ]

        let tamilReplacements = allReplacements.filter { containsTamil($0.value) }
        let hindiReplacements = allReplacements.filter { containsDevanagari($0.value) }

        let replacements: [String: String]
        switch language {
        case .tamil:
            replacements = tamilReplacements
        case .hindi:
            replacements = hindiReplacements
        case .english:
            replacements = [:]
        case nil:
            replacements = allReplacements
        }

        return replacements.reduce(trimmed) { partial, pair in
            partial.replacingOccurrences(
                of: "\\b\(NSRegularExpression.escapedPattern(for: pair.key))\\b",
                with: pair.value,
                options: [.regularExpression, .caseInsensitive]
            )
        }
    }

    static func normalizedEnglishQuery(from rawQuery: String) -> String {
        let trimmed = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        let latinized = transliteratedToLatin(trimmed)
        let folded = latinized.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        let translated = dictionaryTranslated(folded)
        return translated
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func detectedLanguageDescription(for rawQuery: String) -> String? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(rawQuery)
        guard let language = recognizer.dominantLanguage, language != .undetermined else {
            return nil
        }
        return language.rawValue
    }

    private static func transliteratedToLatin(_ text: String) -> String {
        text.applyingTransform(.toLatin, reverse: false)?
            .applyingTransform(.stripCombiningMarks, reverse: false) ?? text
    }

    private static func containsTamil(_ text: String) -> Bool {
        text.unicodeScalars.contains { scalar in
            (0x0B80...0x0BFF).contains(Int(scalar.value))
        }
    }

    private static func containsDevanagari(_ text: String) -> Bool {
        text.unicodeScalars.contains { scalar in
            (0x0900...0x097F).contains(Int(scalar.value))
        }
    }

    private static func dictionaryTranslated(_ text: String) -> String {
        let replacements: [String: String] = [
            "फिल्म": "movie",
            "चलचित्र": "movie",
            "चित्र": "movie",
            "पिक्चर": "movie",
            "चित्रपट": "movie",
            "chalchitra": "movie",
            "chalachitra": "movie",
            "chitra": "movie",
            "cinema": "movie",
            "sinima": "movie",
            "padam": "movie",
            "padamulu": "movies",
            "padamgal": "movies",
            "padangal": "movies",
            "thiraipadam": "movie",
            "thirai padam": "movie",
            "thiraipadangal": "movies",
            "thirapadngal": "movie",
            "thirapadangal": "movies",
            "thira padangal": "movies",
            "படம்": "movie",
            "திரைப்படம்": "movie",
            "திரைப்படங்கள்": "movies",
            "చిత్రం": "movie",
            "సినిమా": "movie",
            "show": "show",
            "sho": "show",
            "serial": "show",
            "सीरियल": "show",
            "धारावाहिक": "show",
            "தொடர்": "show",
            "సీరియల్": "show",
            "natak": "drama",
            "naatak": "drama",
            "नाटक": "drama",
            "நாடகம்": "drama",
            "నాటకం": "drama",
            "khel": "sports",
            "खेल": "sports",
            "vilaiyattu": "sports",
            "விளையாட்டு": "sports",
            "ఆట": "sports",
            "match": "sports match",
            "मैच": "sports match",
            "கிரிக்கெட்": "cricket",
            "క్రికెట్": "cricket",
            "क्रिकेट": "cricket",
            "horror": "horror",
            "daravna": "horror",
            "डरावना": "horror",
            "comedy": "comedy",
            "காமெடி": "comedy",
            "కామెడీ": "comedy",
            "காதல்": "romance",
            "ప్రేమ": "romance",
            "prem": "romance",
            "action": "action",
            "அதிரடி": "action",
            "thriller": "thriller",
            "த்ரில்லர்": "thriller"
        ]

        return replacements.reduce(text) { partial, pair in
            partial.replacingOccurrences(
                of: "\\b\(NSRegularExpression.escapedPattern(for: pair.key))\\b",
                with: pair.value,
                options: [.regularExpression, .caseInsensitive]
            )
        }
    }
}
