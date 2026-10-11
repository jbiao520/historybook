import Foundation

public enum MarkdownHTML {
    public static func imageSources(in markdown: String) -> [String] {
        HistoryLink.matchGroups(pattern: #"!\[[^\]]*\]\(([^)]+)\)"#, in: markdown)
    }

    public static func bodyFragment(from markdown: String) -> String {
        let normalized = markdown.replacingOccurrences(of: "\r\n", with: "\n")
        let blocks = normalized.components(separatedBy: "\n\n")
        return blocks.map(renderBlock).filter { !$0.isEmpty }.joined(separator: "\n")
    }

    private static func renderBlock(_ block: String) -> String {
        let trimmed = block.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "" }
        if trimmed.hasPrefix("## ") {
            return "<h2>\(inline(String(trimmed.dropFirst(3))))</h2>"
        }
        if trimmed.range(of: #"^!\[[^\]]*\]\([^)]+\)$"#, options: .regularExpression) != nil {
            return inline(trimmed)
        }
        if trimmed.hasPrefix(">") {
            let quote = trimmed.split(separator: "\n", omittingEmptySubsequences: false).map { line -> String in
                var text = String(line)
                if text.hasPrefix("> ") {
                    text.removeFirst(2)
                } else if text.hasPrefix(">") {
                    text.removeFirst(1)
                }
                return text
            }.joined()
            return "<blockquote><p>\(inline(quote))</p></blockquote>"
        }
        let classAttribute = trimmed.contains("【争议】") ? " class=\"dispute\"" : ""
        let flattened = trimmed.replacingOccurrences(of: "\n", with: "")
        return "<p\(classAttribute)>\(inline(flattened))</p>"
    }

    static func inline(_ raw: String) -> String {
        let pattern = #"!\[([^\]]*)\]\(([^)]+)\)|\[([^\]]+)\]\((history://[^)\s]+)\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return escape(raw)
        }
        let ns = raw as NSString
        let matches = regex.matches(in: raw, range: NSRange(location: 0, length: ns.length))
        var result = ""
        var cursor = 0
        for match in matches {
            let range = match.range
            if range.location > cursor {
                let preceding = NSRange(location: cursor, length: range.location - cursor)
                result += escape(ns.substring(with: preceding))
            }
            let imageAlt = match.range(at: 1)
            if imageAlt.location != NSNotFound {
                let alt = ns.substring(with: imageAlt)
                let source = ns.substring(with: match.range(at: 2))
                result += figure(source: source, caption: alt)
            } else {
                let text = ns.substring(with: match.range(at: 3))
                let href = ns.substring(with: match.range(at: 4))
                result += "<a href=\"\(escape(href))\">\(escape(text))</a>"
            }
            cursor = range.location + range.length
        }
        if cursor < ns.length {
            result += escape(ns.substring(from: cursor))
        }
        return result
    }

    private static func figure(source: String, caption: String) -> String {
        let visibleCaption = caption.isEmpty
            ? "历史场景重建，非原始史料"
            : "\(escape(caption))（历史场景重建，非原始史料）"
        return "<figure><img src=\"\(escape(source))\" alt=\"\(escape(caption))\"><figcaption>\(visibleCaption)</figcaption></figure>"
    }

    public static func escape(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
