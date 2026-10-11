import Foundation

public enum Timeline {
    public static func datedEvents(
        in nodes: [HistoryNode],
        from startYear: Int = 960,
        through endYear: Int = 1279
    ) -> [HistoryNode] {
        nodes
            .filter { $0.type == .event && $0.year >= startYear && $0.year <= endYear }
            .sorted { lhs, rhs in
                if lhs.year != rhs.year { return lhs.year < rhs.year }
                return lhs.id < rhs.id
            }
    }

    public static func select(_ id: String, in nodes: [HistoryNode]) -> HistoryNode? {
        nodes.first { $0.id == id }
    }
}
