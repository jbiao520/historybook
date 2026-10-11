import Foundation

public struct ContentLibrary: Sendable {
    public let root: URL
    public let home: HomePage?
    public let nodes: [HistoryNode]
    public let markdownByID: [String: String]
    public let trails: [HistoryTrail]

    public func trail(id: String) -> HistoryTrail? {
        trails.first { $0.id == id }
    }

    public func node(id: String) -> HistoryNode? {
        nodes.first { $0.id == id }
    }

    public func markdown(for id: String) -> String {
        markdownByID[id] ?? ""
    }

    public func related(to node: HistoryNode) -> [HistoryNode] {
        node.relatedIds.compactMap { self.node(id: $0) }
    }
}

public enum ContentLoader {
    public enum LoadError: LocalizedError {
        case emptyLibrary
        case duplicateID(String)
        case invalidTrail(String)

        public var errorDescription: String? {
            switch self {
            case .emptyLibrary: "内容目录中没有知识节点。"
            case .duplicateID(let id): "知识节点 ID 重复：\(id)。请检查 JSON 元数据。"
            case .invalidTrail(let message): "主题路线无效：\(message)"
            }
        }
    }

    /// Loads every `metadata/*.json` node and its Markdown article from `root`.
    /// A new node is picked up by adding those files. Node ids are not listed in Swift.
    public static func load(from root: URL) throws -> ContentLibrary {
        let fileManager = FileManager.default
        let metadataURL = root.appendingPathComponent("metadata")
        let articleDirectory = root.appendingPathComponent("articles")
        let jsonURLs = try fileManager.contentsOfDirectory(
            at: metadataURL,
            includingPropertiesForKeys: nil
        )
        .filter { $0.pathExtension.lowercased() == "json" }
        .sorted { $0.lastPathComponent < $1.lastPathComponent }

        let decoder = JSONDecoder()
        var nodes: [HistoryNode] = []
        var markdownByID: [String: String] = [:]
        nodes.reserveCapacity(jsonURLs.count)

        for url in jsonURLs {
            let data = try Data(contentsOf: url)
            let node = try decoder.decode(HistoryNode.self, from: data)
            guard markdownByID[node.id] == nil else {
                throw LoadError.duplicateID(node.id)
            }
            let articleURL = articleDirectory.appendingPathComponent(node.article)
            markdownByID[node.id] = try String(contentsOf: articleURL, encoding: .utf8)
            nodes.append(node)
        }

        guard !nodes.isEmpty else { throw LoadError.emptyLibrary }

        nodes.sort { lhs, rhs in
            if lhs.year != rhs.year { return lhs.year < rhs.year }
            return lhs.id < rhs.id
        }

        let homeURL = root.appendingPathComponent("home.json")
        let home: HomePage?
        if fileManager.fileExists(atPath: homeURL.path) {
            home = try decoder.decode(HomePage.self, from: Data(contentsOf: homeURL))
        } else {
            home = nil
        }

        let trailsURL = root.appendingPathComponent("trails.json")
        let trails = fileManager.fileExists(atPath: trailsURL.path)
            ? try decoder.decode([HistoryTrail].self, from: Data(contentsOf: trailsURL))
            : []
        let nodeIDs = Set(nodes.map(\.id))
        var trailIDs = Set<String>()
        for trail in trails {
            guard !trail.id.isEmpty, trailIDs.insert(trail.id).inserted else {
                throw LoadError.invalidTrail("路线 ID 为空或重复：\(trail.id)")
            }
            guard !trail.steps.isEmpty else {
                throw LoadError.invalidTrail("\(trail.title)没有阅读步骤。")
            }
            var stepIDs = Set<String>()
            for step in trail.steps {
                guard nodeIDs.contains(step.nodeID), stepIDs.insert(step.nodeID).inserted else {
                    throw LoadError.invalidTrail("\(trail.title)引用了不存在或重复的节点：\(step.nodeID)")
                }
                guard !step.reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    throw LoadError.invalidTrail("\(trail.title)的步骤缺少阅读说明。")
                }
            }
        }

        return ContentLibrary(
            root: root,
            home: home,
            nodes: nodes,
            markdownByID: markdownByID,
            trails: trails
        )
    }
}
