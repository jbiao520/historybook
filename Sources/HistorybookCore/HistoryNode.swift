import Foundation

public enum NodeType: String, Codable, Sendable, CaseIterable {
    case event
    case person
    case place
    case culture

    public var displayName: String {
        switch self {
        case .event: "历史事件"
        case .person: "历史人物"
        case .place: "历史地点"
        case .culture: "制度与文化"
        }
    }
}

public struct HistoryNode: Codable, Identifiable, Sendable, Equatable {
    public let id: String
    public let title: String
    public let type: NodeType
    public let year: Int
    public let yearEnd: Int?
    public let dynasty: String
    public let location: String?
    public let cover: String
    public let article: String
    public let keywords: [String]
    public let relatedIds: [String]
    public let references: [String]
    public let summary: String
    public let dateLabel: String?

    private enum CodingKeys: String, CodingKey {
        case id, title, type, year, yearEnd, dynasty, location, cover, article, keywords, relatedIds, references, summary, dateLabel
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        title = try values.decode(String.self, forKey: .title)
        type = try values.decode(NodeType.self, forKey: .type)
        year = try values.decode(Int.self, forKey: .year)
        yearEnd = try values.decodeIfPresent(Int.self, forKey: .yearEnd)
        dynasty = try values.decode(String.self, forKey: .dynasty)
        location = try values.decodeIfPresent(String.self, forKey: .location)
        cover = try values.decode(String.self, forKey: .cover)
        article = try values.decode(String.self, forKey: .article)
        keywords = try values.decodeIfPresent([String].self, forKey: .keywords) ?? []
        relatedIds = try values.decode([String].self, forKey: .relatedIds)
        references = try values.decodeIfPresent([String].self, forKey: .references) ?? []
        summary = try values.decodeIfPresent(String.self, forKey: .summary) ?? ""
        dateLabel = try values.decodeIfPresent(String.self, forKey: .dateLabel)
    }

    public var timeLabel: String {
        if let dateLabel, !dateLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return dateLabel
        }
        if let yearEnd, yearEnd != year {
            return "\(year)–\(yearEnd)"
        }
        return "\(year)"
    }
}

public struct HomePage: Codable, Sendable, Equatable {
    public let title: String
    public let startYear: Int
    public let endYear: Int
    public let introduction: String
    public let background: String
    public let featuredIds: [String]
}
