import Foundation

public enum ArticleHTML {
    /// Deterministic local HTML used by both the tests and the article WKWebView.
    public static func render(
        node: HistoryNode,
        markdown: String,
        related: [HistoryNode]
    ) -> String {
        let body = MarkdownHTML.bodyFragment(from: markdown)
        let location = node.location.map { " · \(MarkdownHTML.escape($0))" } ?? ""
        let summary = node.summary.isEmpty ? "" : "<p class=\"summary\">\(MarkdownHTML.escape(node.summary))</p>"
        let cards = related.map { item in
            """
            <a class="related-card" href="history://\(MarkdownHTML.escape(item.id))"><span class="related-type">\(MarkdownHTML.escape(item.type.displayName))</span><span class="related-title">\(MarkdownHTML.escape(item.title))</span><span class="related-time">\(MarkdownHTML.escape(item.timeLabel))</span></a>
            """
        }.joined(separator: "\n")
        let references = node.references.isEmpty ? "" : """
        <section class="sources" aria-label="阅读线索">
        <h2>阅读线索</h2>
        <p>以下为相关史料的阅读入口。史书的记载仍须结合成书背景与不同材料理解。</p>
        <ul>\(node.references.map { "<li>\(MarkdownHTML.escape($0))</li>" }.joined())</ul>
        </section>
        """

        return """
        <!DOCTYPE html>
        <html lang="zh-Hans">
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <link rel="stylesheet" href="styles/article.css">
        <title>\(MarkdownHTML.escape(node.title))</title>
        </head>
        <body>
        <article>
        <header class="article-header">
        <p class="kicker">\(MarkdownHTML.escape(node.type.displayName)) · \(MarkdownHTML.escape(node.dynasty))</p>
        <h1>\(MarkdownHTML.escape(node.title))</h1>
        <p class="meta">\(MarkdownHTML.escape(node.timeLabel))\(location)</p>
        \(summary)
        </header>
        <figure class="cover">
        <img src="images/\(MarkdownHTML.escape(node.cover))" alt="\(MarkdownHTML.escape(node.title))">
        <figcaption>封面：\(MarkdownHTML.escape(node.title))（历史场景重建，非原始史料）</figcaption>
        </figure>
        <p class="reconstruction-notice">文中配图均为历史场景重建，用于帮助想象当时的情景，不能当作原始史料或照片。</p>
        \(body)
        \(references)
        <section class="related">
        <h2>继续探索</h2>
        <div class="related-grid">
        \(cards)
        </div>
        </section>
        </article>
        </body>
        </html>
        """
    }
}
