import Foundation
import HistorybookCore
import Observation

enum SidebarSection: String, CaseIterable, Identifiable {
    case home
    case timeline
    case topics
    case search
    case history

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "首页"
        case .timeline: "时间轴"
        case .topics: "主题探索"
        case .search: "搜索"
        case .history: "浏览历史"
        }
    }

    var symbol: String {
        switch self {
        case .home: "house"
        case .timeline: "calendar"
        case .topics: "books.vertical"
        case .search: "magnifyingglass"
        case .history: "clock"
        }
    }

    var destination: ExplorationDestination {
        switch self {
        case .home: .home
        case .timeline: .timeline
        case .topics: .topics
        case .search: .search
        case .history: .history
        }
    }
}

enum ReadingPane: Equatable {
    case section(SidebarSection)
    case article
    case trail
}

@MainActor
@Observable
final class LibraryModel {
    var library: ContentLibrary?
    var loadError: String?
    var section: SidebarSection = .home
    var pane: ReadingPane = .section(.home)
    var exploration = ExplorationModel()
    var searchQuery = ""

    var nodes: [HistoryNode] { library?.nodes ?? [] }
    var trails: [HistoryTrail] { library?.trails ?? [] }

    var currentTrail: HistoryTrail? {
        guard case .trail(let id) = exploration.destination else { return nil }
        return library?.trail(id: id)
    }

    var currentNode: HistoryNode? {
        guard let id = exploration.currentID else { return nil }
        return library?.node(id: id)
    }

    var breadcrumbNodes: [HistoryNode] {
        exploration.breadcrumbs.compactMap { library?.node(id: $0) }
    }

    var searchResults: [HistoryNode] {
        guard let library else { return [] }
        return SearchIndex.search(
            query: searchQuery,
            nodes: library.nodes,
            articles: library.markdownByID
        )
    }

    func load() {
        guard let root = ContentLocation.resolve() else {
            loadError = "没有找到内容目录。请把 Markdown、JSON 和图片放进 App 的 Content 目录。"
            return
        }
        do {
            library = try ContentLoader.load(from: root)
            loadError = nil
        } catch {
            loadError = "内容无法读取：\(error.localizedDescription)"
        }
    }

    func show(_ section: SidebarSection) {
        exploration.navigate(to: section.destination)
        synchronizePane()
    }

    func openNode(_ id: String) {
        guard library?.node(id: id) != nil else { return }
        exploration.open(id)
        synchronizePane()
    }

    func openTrail(_ id: String) {
        guard library?.trail(id: id) != nil else { return }
        exploration.navigate(to: .trail(id))
        synchronizePane()
    }

    func goBack() {
        exploration.goBack()
        synchronizePane()
    }

    func goForward() {
        exploration.goForward()
        synchronizePane()
    }

    func goToBreadcrumb(at index: Int) {
        exploration.goToBreadcrumb(at: index)
        synchronizePane()
    }

    private func synchronizePane() {
        if exploration.currentID != nil {
            pane = .article
        } else if currentTrail != nil {
            section = .topics
            pane = .trail
        } else if let section = SidebarSection.allCases.first(where: {
            $0.destination == exploration.destination
        }) {
            self.section = section
            pane = .section(section)
        }
    }

    func html(for node: HistoryNode) -> String {
        guard let library else { return "" }
        return ArticleHTML.render(
            node: node,
            markdown: library.markdown(for: node.id),
            related: library.related(to: node)
        )
    }

    func imageURL(_ fileName: String) -> URL? {
        library?.root.appendingPathComponent("images").appendingPathComponent(fileName)
    }
}
