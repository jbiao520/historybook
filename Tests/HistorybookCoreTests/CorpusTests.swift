import CryptoKit
import Foundation
import ImageIO
import Testing
@testable import HistorybookCore

struct CorpusFixture {
    static var contentRoot: URL {
        if let path = ProcessInfo.processInfo.environment["HISTORYBOOK_CONTENT_ROOT"] {
            return URL(fileURLWithPath: path, isDirectory: true)
        }
        return URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Sources/Historybook/Content")
    }

    static func load() throws -> ContentLibrary {
        try ContentLoader.load(from: contentRoot)
    }
}

@Test func corpusShapeAndNamedYears() throws {
    let library = try CorpusFixture.load()
    #expect(library.nodes.count == 45)
    #expect(library.nodes.filter { $0.type == .event }.count == 14)
    #expect(library.nodes.filter { $0.type == .person }.count == 13)
    #expect(library.nodes.filter { $0.type == .place }.count == 7)
    #expect(library.nodes.filter { $0.type == .culture }.count == 11)

    let titles = Set(library.nodes.map(\.title))
    for title in ["陈桥兵变", "澶渊之盟", "王安石变法", "靖康之变", "赵匡胤", "宋真宗", "范仲淹", "王安石", "东京汴梁", "燕云十六州", "临安", "科举制度", "宋朝商业", "军事制度", "城市生活"] {
        #expect(titles.contains(title), "\(title)")
    }

    #expect(library.node(id: "chenqiao-mutiny")?.year == 960)
    #expect(library.node(id: "chanyuan-treaty")?.year == 1005)
    #expect(library.node(id: "wang-anshi-reforms")?.year == 1069)
    #expect(library.node(id: "jingkang-incident")?.year == 1127)
    #expect(library.home?.title == "宋朝")
    #expect(library.home?.startYear == 960)
    #expect(library.home?.endYear == 1279)
    for id in library.home?.featuredIds ?? [] {
        #expect(library.node(id: id) != nil)
    }
}

@Test func articlesLengthRelationsLinksAndDisputeMarks() throws {
    let library = try CorpusFixture.load()
    let ids = Set(library.nodes.map(\.id))
    for node in library.nodes {
        let markdown = library.markdown(for: node.id)
        let count = ProseMetrics.chineseCharacterCount(in: markdown)
        #expect(count >= 800, "\(node.id) \(count)")
        #expect(count <= 1500, "\(node.id) \(count)")
        #expect(markdown.contains("【争议】"), "\(node.id)")

        #expect(!node.summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "\(node.id)")
        #expect(HistoryLink.linkedNodeIDs(in: markdown).count >= 3, "\(node.id)")
        #expect(node.relatedIds.count >= 3, "\(node.id)")
        #expect(node.relatedIds.count <= 6, "\(node.id)")
        #expect(Set(node.relatedIds).count == node.relatedIds.count)
        for related in node.relatedIds {
            #expect(ids.contains(related), "\(node.id) -> \(related)")
            #expect(related != node.id)
        }

        let figures = MarkdownHTML.imageSources(in: markdown)
        #expect((2...4).contains(figures.count), "\(node.id) \(figures.count)")
        for link in HistoryLink.linkedNodeIDs(in: markdown) {
            #expect(library.node(id: link) != nil, "\(node.id) history://\(link)")
        }
    }
}

@Test func renderedHTMLUsesLocalImagesAndResolvingLinks() throws {
    let library = try CorpusFixture.load()
    for node in library.nodes {
        let html = ArticleHTML.render(
            node: node,
            markdown: library.markdown(for: node.id),
            related: library.related(to: node)
        )
        #expect(html.contains("<h1>\(node.title)</h1>"))
        #expect(html.contains("历史场景重建"))
        #expect(html.contains("images/\(node.cover)"))
        #expect(!html.contains("http:"))
        #expect(!html.contains("https:"))
        #expect(!node.references.isEmpty, "\(node.id) needs reading references")
        #expect(html.contains("阅读线索"))
        #expect(library.related(to: node).count == node.relatedIds.count)
        for link in HistoryLink.linkedNodeIDs(in: html) {
            #expect(library.node(id: link) != nil, "\(link)")
        }
    }
    let url = try #require(URL(string: "history://chanyuan-treaty"))
    #expect(HistoryLink.nodeID(from: url) == "chanyuan-treaty")
}

@Test func rastersDecodeAtRequiredSizeAndCoversDiffer() throws {
    let library = try CorpusFixture.load()
    var coverDigests = Set<String>()
    for node in library.nodes {
        let coverURL = library.root.appendingPathComponent("images").appendingPathComponent(node.cover)
        coverDigests.insert(try sha256(of: coverURL))
        try assertRaster(coverURL)
        for source in MarkdownHTML.imageSources(in: library.markdown(for: node.id)) {
            try assertRaster(library.root.appendingPathComponent(source))
        }
    }
    #expect(coverDigests.count == library.nodes.count)
}

@Test func searchTitleAndBodyWord() throws {
    let library = try CorpusFixture.load()
    let titleHits = SearchIndex.search(
        query: "澶渊之盟",
        nodes: library.nodes,
        articles: library.markdownByID
    )
    #expect(titleHits.first?.id == "chanyuan-treaty")

    let treaty = try #require(library.node(id: "chanyuan-treaty"))
    #expect(!treaty.title.contains("关南之地"))
    #expect(!treaty.keywords.contains { $0.contains("关南之地") })
    #expect(library.markdown(for: treaty.id).contains("关南之地"))
    let bodyHits = SearchIndex.search(
        query: "关南之地",
        nodes: library.nodes,
        articles: library.markdownByID
    )
    #expect(bodyHits.map(\.id) == ["chanyuan-treaty"])
}

@Test func timelineOrderAndSelection() throws {
    let library = try CorpusFixture.load()
    let events = Timeline.datedEvents(in: library.nodes)
    #expect(events.count == 14)
    for event in events {
        #expect(event.type == .event)
        #expect(event.year >= 960)
        #expect(event.year <= 1279)
    }
    for pair in zip(events, events.dropFirst()) {
        #expect(pair.0.year <= pair.1.year)
    }
    let selected = Timeline.select("chanyuan-treaty", in: library.nodes)
    #expect(selected?.id == "chanyuan-treaty")
    #expect(events.first { $0.id == "chanyuan-treaty" }?.id == selected?.id)
}

@Test func explorationStackBreadcrumbsAndHistory() throws {
    let library = try CorpusFixture.load()
    #expect(library.node(id: "chenqiao-mutiny") != nil)
    #expect(library.node(id: "zhao-kuangyin") != nil)
    #expect(library.node(id: "release-military-power") != nil)

    var model = ExplorationModel()
    model.open("chenqiao-mutiny")
    model.open("zhao-kuangyin")
    model.open("release-military-power")
    #expect(model.breadcrumbs == ["chenqiao-mutiny", "zhao-kuangyin", "release-military-power"])
    #expect(model.visitHistory == ["chenqiao-mutiny", "zhao-kuangyin", "release-military-power"])

    model.goBack()
    #expect(model.currentID == "zhao-kuangyin")
    #expect(model.breadcrumbs == ["chenqiao-mutiny", "zhao-kuangyin"])
    #expect(model.visitHistory == ["chenqiao-mutiny", "zhao-kuangyin", "release-military-power"])
    #expect(model.canGoForward)

    model.goForward()
    #expect(model.currentID == "release-military-power")
    #expect(model.breadcrumbs == ["chenqiao-mutiny", "zhao-kuangyin", "release-military-power"])
    #expect(model.visitHistory == ["chenqiao-mutiny", "zhao-kuangyin", "release-military-power"])
}

@Test func stylesIncludeWarmPaperAndDarkScheme() throws {
    let css = try String(contentsOf: CorpusFixture.contentRoot.appendingPathComponent("styles/article.css"), encoding: .utf8)
    #expect(css.contains("#f6f1e6"))
    #expect(css.contains("prefers-color-scheme: dark"))
}

@Test func extraNodeLoadsWithoutSwiftChange() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent("historybook-fixture-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: directory.appendingPathComponent("metadata"), withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: directory.appendingPathComponent("articles"), withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }

    let json = """
    {"id":"extra-node","title":"额外节点","type":"event","year":1000,"dynasty":"北宋","location":"测试","cover":"extra.webp","article":"extra-node.md","keywords":["额外"],"relatedIds":[]}
    """
    try json.write(to: directory.appendingPathComponent("metadata/extra-node.json"), atomically: true, encoding: .utf8)
    try "这是额外节点的正文，用来证明加载器只看文件。".write(to: directory.appendingPathComponent("articles/extra-node.md"), atomically: true, encoding: .utf8)

    let loaded = try ContentLoader.load(from: directory)
    #expect(loaded.nodes.map(\.id) == ["extra-node"])
    #expect(loaded.node(id: "extra-node")?.title == "额外节点")
    #expect(loaded.markdown(for: "extra-node").contains("只看文件"))
    #expect(loaded.trails.isEmpty)
}

@Test func trailsMatchConfiguredOrderAndReachEveryNewNode() throws {
    let library = try CorpusFixture.load()
    let expected: [(String, [String])] = [
        ("founding-song", ["chenqiao-mutiny", "zhao-kuangyin", "release-military-power", "song-unification", "military-system"]),
        ("reform-difficulty", ["song-renzong", "fan-zhongyan", "qingli-reforms", "wang-anshi", "wang-anshi-reforms", "sima-guang", "agricultural-waterworks", "zhu-xi"]),
        ("borders-and-war", ["sixteen-prefectures", "yongxi-expedition", "chanyuan-treaty", "maritime-alliance", "jingkang-incident"]),
        ("lives-in-ci", ["ci-poetry", "su-shi", "li-qingzhao", "urban-life", "linan"]),
        ("paper-porcelain-ships", ["shen-kuo", "movable-type", "chengdu", "jiaozi", "song-porcelain", "maritime-trade", "quanzhou"]),
        ("southern-defense", ["song-gaozong", "yue-fei", "yancheng-battle", "shaoxing-peace", "caishi-battle", "xiangyang", "xiangyang-siege", "wen-tianxiang", "yashan-battle"]),
    ]
    #expect(library.trails.map(\.id) == expected.map(\.0))
    for (id, steps) in expected {
        let trail = try #require(library.trail(id: id))
        #expect(trail.steps.map(\.nodeID) == steps)
        #expect(!trail.question.isEmpty)
        #expect(!trail.introduction.isEmpty)
        #expect(FileManager.default.fileExists(atPath: library.root.appendingPathComponent("images").appendingPathComponent(trail.cover).path))
    }

    let original: Set<String> = [
        "caishi-battle", "chanyuan-treaty", "chanzhou", "chenqiao-mutiny", "ci-poetry",
        "dongjing-bianliang", "fan-zhongyan", "imperial-exam", "jiaozi", "jingkang-incident",
        "linan", "maritime-alliance", "military-system", "movable-type", "neo-confucianism",
        "qingli-reforms", "quanzhou", "release-military-power", "shaoxing-peace", "sima-guang",
        "sixteen-prefectures", "song-commerce", "song-gaozong", "song-zhenzong", "urban-life",
        "wang-anshi-reforms", "wang-anshi", "yashan-battle", "yue-fei", "zhao-kuangyin",
    ]
    let newIDs = Set(library.nodes.map(\.id)).subtracting(original)
    #expect(newIDs.count == 15)
    let trailNodes = Set(library.trails.flatMap { $0.steps.map(\.nodeID) })
    for id in newIDs {
        #expect(trailNodes.contains(id), "\(id) is not on a trail")
        let mentioned = original.contains { source in
            library.markdown(for: source).contains("history://\(id)")
        }
        #expect(mentioned, "\(id) is not linked from an original article")
    }
    let updatedOriginals = original.filter { source in
        newIDs.contains { library.markdown(for: source).contains("history://\($0)") }
    }
    #expect(updatedOriginals.count >= 12)

    #expect(library.node(id: "li-qingzhao")?.timeLabel.contains("约") == true)
    let wen = library.markdown(for: "wen-tianxiang")
    #expect(wen.contains("公历"))
    #expect(wen.contains("至元十九年"))
    let summaryHits = SearchIndex.search(query: "卒年未定", nodes: library.nodes, articles: library.markdownByID)
    #expect(summaryHits.first?.id == "li-qingzhao")
}

private func sha256(of url: URL) throws -> String {
    let data = try Data(contentsOf: url)
    return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
}

private func assertRaster(_ url: URL) throws {
    #expect(FileManager.default.fileExists(atPath: url.path), "\(url.path)")
    let source = try #require(CGImageSourceCreateWithURL(url as CFURL, nil))
    let image = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
    let width = image.width
    let height = image.height
    #expect(max(width, height) >= 800, "\(url.lastPathComponent)")
    let ratio = Double(width) / Double(height)
    let sixteenByNine = 16.0 / 9.0
    let threeByTwo = 3.0 / 2.0
    let matches = abs(ratio - sixteenByNine) / sixteenByNine <= 0.05 || abs(ratio - threeByTwo) / threeByTwo <= 0.05
    #expect(matches, "\(url.lastPathComponent) ratio \(ratio)")
}
