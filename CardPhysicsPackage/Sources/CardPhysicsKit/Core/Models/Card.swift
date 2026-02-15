import Foundation

public enum Suit: String, CaseIterable, Codable, Sendable {
    case hearts = "♥"
    case diamonds = "♦"
    case clubs = "♣"
    case spades = "♠"

    public var color: SuitColor {
        switch self {
        case .hearts, .diamonds: return .red
        case .clubs, .spades: return .black
        }
    }

    public var name: String {
        switch self {
        case .hearts: return "hearts"
        case .diamonds: return "diamonds"
        case .clubs: return "clubs"
        case .spades: return "spades"
        }
    }
}

public enum SuitColor: Sendable {
    case red, black
}

public enum Rank: Int, CaseIterable, Codable, Comparable, Sendable {
    case nine = 9
    case ten = 10
    case jack = 11
    case queen = 12
    case king = 13
    case ace = 14

    public var symbol: String {
        switch self {
        case .nine: return "9"
        case .ten: return "10"
        case .jack: return "J"
        case .queen: return "Q"
        case .king: return "K"
        case .ace: return "A"
        }
    }

    public static func < (lhs: Rank, rhs: Rank) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public var name: String {
        switch self {
        case .nine: return "nine"
        case .ten: return "ten"
        case .jack: return "jack"
        case .queen: return "queen"
        case .king: return "king"
        case .ace: return "ace"
        }
    }
}

public struct Card: Identifiable, Equatable, Codable, Hashable, Sendable {
    public let id: UUID
    public let suit: Suit
    public let rank: Rank

    public init(suit: Suit, rank: Rank) {
        self.id = UUID()
        self.suit = suit
        self.rank = rank
    }

    public var displayName: String {
        "\(rank.symbol)\(suit.rawValue)"
    }
}
