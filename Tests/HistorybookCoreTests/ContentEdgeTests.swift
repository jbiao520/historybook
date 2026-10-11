import Foundation
import Testing
@testable import HistorybookCore

@Test func prdMetadataExampleLoadsWithoutOptionalKeywords() throws {
    let data = Data("""
    {"id":"chanyuan-treaty","title":"澶渊之盟","type":"event","year":1005,
    "dynasty":"北宋","location":"澶州","cover":"cover.webp","article":"treaty.md",
    "relatedIds":["song-zhenzong","sixteen-prefectures","chanzhou"]}
    """.utf8)
    let node = try JSONDecoder().decode(HistoryNode.self, from: data)
    #expect(node.keywords.isEmpty)
    #expect(node.yearEnd == nil)
    #expect(node.timeLabel == "1005")
    #expect(try JSONDecoder().decode(HistoryNode.self, from: JSONEncoder().encode(node)) == node)
}

@Test func loaderRejectsDuplicateIDsInsteadOfSilentlyOverwritingArticles() throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: folder.appendingPathComponent("metadata"), withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: folder.appendingPathComponent("articles"), withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: folder) }
    let json = """
    {"id":"duplicate","title":"重复","type":"event","year":1005,"dynasty":"北宋",
    "cover":"cover.webp","article":"article.md","relatedIds":[]}
    """
    try json.write(to: folder.appendingPathComponent("metadata/a.json"), atomically: true, encoding: .utf8)
    try json.write(to: folder.appendingPathComponent("metadata/b.json"), atomically: true, encoding: .utf8)
    try "正文".write(to: folder.appendingPathComponent("articles/article.md"), atomically: true, encoding: .utf8)
    do {
        _ = try ContentLoader.load(from: folder)
        Issue.record("Duplicate node ids should fail loading.")
    } catch ContentLoader.LoadError.duplicateID(let id) {
        #expect(id == "duplicate")
    }
}

@Test func loaderRejectsDuplicateTrailStepsAndMissingTrailsStayOptional() throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: folder.appendingPathComponent("metadata"), withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: folder.appendingPathComponent("articles"), withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: folder) }
    let json = """
    {"id":"only-node","title":"仅有","type":"event","year":1000,"dynasty":"北宋","cover":"cover.webp","article":"only-node.md","relatedIds":[]}
    """
    try json.write(to: folder.appendingPathComponent("metadata/only-node.json"), atomically: true, encoding: .utf8)
    try "正文".write(to: folder.appendingPathComponent("articles/only-node.md"), atomically: true, encoding: .utf8)
    let trails = """
    [{"id":"same","title":"重复步骤","question":"问","introduction":"介","cover":"cover.webp","steps":[{"nodeID":"only-node","reason":"先读"},{"nodeID":"only-node","reason":"再读"}]}]
    """
    try trails.write(to: folder.appendingPathComponent("trails.json"), atomically: true, encoding: .utf8)
    do {
        _ = try ContentLoader.load(from: folder)
        Issue.record("Repeated trail steps should fail loading.")
    } catch ContentLoader.LoadError.invalidTrail(let message) {
        #expect(message.contains("only-node"))
    }
}

@Test func summaryMatchRanksAheadOfBodyMatch() throws {
    let summaryNode = try JSONDecoder().decode(HistoryNode.self, from: Data("""
    {"id":"summary-node","title":"甲","type":"event","year":1000,"dynasty":"北宋","cover":"a.webp","article":"a.md","keywords":[],"relatedIds":[],"summary":"独有简介词"}
    """.utf8))
    let bodyNode = try JSONDecoder().decode(HistoryNode.self, from: Data("""
    {"id":"body-node","title":"乙","type":"event","year":1001,"dynasty":"北宋","cover":"b.webp","article":"b.md","keywords":[],"relatedIds":[]}
    """.utf8))
    let hits = SearchIndex.search(
        query: "独有简介词",
        nodes: [bodyNode, summaryNode],
        articles: ["body-node": "正文里出现独有简介词。", "summary-node": "没有这个说法。"]
    )
    #expect(hits.map(\.id) == ["summary-node", "body-node"])
}

@Test func searchMatchesVisibleTextWithoutMatchingResourcePaths() throws {
    let library = try CorpusFixture.load()
    #expect(SearchIndex.search(query: "  澶渊之盟\n", nodes: library.nodes, articles: library.markdownByID).first?.id == "chanyuan-treaty")
    #expect(SearchIndex.search(query: "history://", nodes: library.nodes, articles: library.markdownByID).isEmpty)
    #expect(SearchIndex.search(query: "plate-", nodes: library.nodes, articles: library.markdownByID).isEmpty)
    #expect(SearchIndex.search(query: "\n  ", nodes: library.nodes, articles: library.markdownByID).isEmpty)
}
