import Foundation

public enum ProseMetrics {
    /// Counts Han characters in article prose.
    /// Image markup, including captions, is removed. Link URLs are removed and link text is kept.
    public static func chineseCharacterCount(in markdown: String) -> Int {
        var text = markdown.replacingOccurrences(of: "\r\n", with: "\n")
        text = text.replacingOccurrences(
            of: #"!\[[^\]]*\]\([^)]*\)"#,
            with: "",
            options: .regularExpression
        )
        text = text.replacingOccurrences(
            of: #"\[([^\]]*)\]\([^)]*\)"#,
            with: "$1",
            options: .regularExpression
        )
        text = text.replacingOccurrences(
            of: #"(?m)^[ \t]*[#>]+\s*"#,
            with: "",
            options: .regularExpression
        )
        text = text.replacingOccurrences(
            of: "[*_`]",
            with: "",
            options: .regularExpression
        )

        var count = 0
        for scalar in text.unicodeScalars {
            if (0x4E00...0x9FFF).contains(scalar.value) {
                count += 1
            }
        }
        return count
    }
}
