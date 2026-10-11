import Foundation

public enum SearchIndex {
    /// Title matches come first, then keyword matches, then body matches.
    public static func search(
        query: String,
        nodes: [HistoryNode],
        articles: [String: String]
    ) -> [HistoryNode] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return [] }

        var titleHits: [HistoryNode] = []
        var keywordHits: [HistoryNode] = []
        var summaryHits: [HistoryNode] = []
        var bodyHits: [HistoryNode] = []

        for node in nodes {
            if node.title.localizedStandardContains(trimmed) {
                titleHits.append(node)
            } else if node.keywords.contains(where: { $0.localizedStandardContains(trimmed) }) {
                keywordHits.append(node)
            } else if node.summary.localizedStandardContains(trimmed) {
                summaryHits.append(node)
            } else if searchableText(articles[node.id] ?? "").localizedStandardContains(trimmed) {
                bodyHits.append(node)
            }
        }

        return titleHits + keywordHits + summaryHits + bodyHits
    }

    private static func searchableText(_ markdown: String) -> String {
        markdown.replacingOccurrences(
            of: #"!?\[([^\]]*)\]\([^)]*\)"#,
            with: "$1",
            options: .regularExpression
        )
    }
}
