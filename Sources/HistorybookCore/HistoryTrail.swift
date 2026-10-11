import Foundation

public struct TrailStep: Codable, Equatable, Sendable {
    public let nodeID: String
    public let reason: String
}

public struct HistoryTrail: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let question: String
    public let introduction: String
    public let cover: String
    public let steps: [TrailStep]
}
