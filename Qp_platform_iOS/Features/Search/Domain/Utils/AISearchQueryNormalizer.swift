import Foundation
import NaturalLanguage

enum AISearchQueryNormalizer {
    static func localizedDisplayText(from rawQuery: String) -> String {
        let trimmed = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        let replacements: [String: String] = [
            "thiraipadam": "திரைப்படம்",
            "thiraipadangal": "திரைப்படங்கள்",
            "thirapadngal": "திரைப்படம்",
            "thirapadangal": "திரைப்படங்கள்",
            "padam": "படம்",
            "padangal": "படங்கள்",
            "hindi film": "हिंदी फिल्म",
            "film": "फिल्म"
        ]

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

    private static func dictionaryTranslated(_ text: String) -> String {
        let replacements: [String: String] = [
            "फिल्म": "movie",
            "पिक्चर": "movie",
            "चित्रपट": "movie",
            "cinema": "movie",
            "sinima": "movie",
            "padam": "movie",
            "padamulu": "movies",
            "padamgal": "movies",
            "padangal": "movies",
            "thiraipadam": "movie",
            "thiraipadangal": "movies",
            "thirapadngal": "movie",
            "thirapadangal": "movies",
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
