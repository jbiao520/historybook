import Foundation

public enum HistoryLink {
    /// Parses `history://node-id` the way the article web view receives it.
    public static func nodeID(from url: URL) -> String? {
        guard url.scheme?.lowercased() == "history" else { return nil }
        if let host = url.host, !host.isEmpty {
            return host
        }
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return path.isEmpty ? nil : path
    }

    public static func linkedNodeIDs(in markdown: String) -> [String] {
        matchGroups(pattern: #"history://([A-Za-z0-9\-]+)"#, in: markdown)
    }

    static func matchGroups(pattern: String, in text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let ns = text as NSString
        let full = NSRange(location: 0, length: ns.length)
        return regex.matches(in: text, range: full).compactMap { match in
            guard match.numberOfRanges > 1 else { return nil }
            let range = match.range(at: 1)
            guard range.location != NSNotFound else { return nil }
            return ns.substring(with: range)
        }
    }
}
