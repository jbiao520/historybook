import Foundation

public enum ExplorationDestination: Equatable, Sendable {
    case home
    case timeline
    case search
    case history
    case topics
    case trail(String)
    case article(String)

    public var nodeID: String? {
        if case .article(let id) = self { return id }
        return nil
    }
}

public struct ExplorationModel: Equatable, Sendable {
    public private(set) var backStack: [ExplorationDestination] = []
    public private(set) var forwardStack: [ExplorationDestination] = []
    public private(set) var destination: ExplorationDestination = .home
    public private(set) var visitHistory: [String] = []

    public init() {}

    public var currentID: String? { destination.nodeID }

    /// The uninterrupted article trail since the most recent sidebar page.
    public var breadcrumbs: [String] {
        guard let currentID else { return [] }
        return backStack.reversed().prefix { $0.nodeID != nil }
            .reversed().compactMap(\.nodeID) + [currentID]
    }

    public var canGoBack: Bool { !backStack.isEmpty }
    public var canGoForward: Bool { !forwardStack.isEmpty }

    public mutating func open(_ id: String) {
        navigate(to: .article(id))
    }

    public mutating func navigate(to next: ExplorationDestination) {
        guard next != destination else { return }
        backStack.append(destination)
        destination = next
        forwardStack.removeAll()
        if let id = next.nodeID { visitHistory.append(id) }
    }

    public mutating func goBack() {
        guard let previous = backStack.popLast() else { return }
        forwardStack.append(destination)
        destination = previous
    }

    public mutating func goForward() {
        guard let next = forwardStack.popLast() else { return }
        backStack.append(destination)
        destination = next
    }

    /// Navigate through the existing stack, preserving forward navigation.
    /// An index distinguishes repeated visits to the same node.
    public mutating func goToBreadcrumb(at index: Int) {
        let trail = breadcrumbs
        guard trail.indices.contains(index) else { return }
        for _ in 0..<(trail.count - index - 1) { goBack() }
    }
}
