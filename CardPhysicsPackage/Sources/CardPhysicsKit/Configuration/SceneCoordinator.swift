import Foundation

public enum DealMode: String, CaseIterable, Sendable {
    case four = "4 Cards"
    case twelve = "12 Cards"
    case twenty = "20 Cards"
    case euchre = "Euchre"
    case inHands = "In Hands"

    var cardCount: Int {
        switch self {
        case .four: return 4
        case .twelve: return 12
        case .twenty: return 20
        case .euchre: return 20
        case .inHands: return 20
        }
    }
}

public enum GatherCorner: String, CaseIterable, Sendable {
    case bottomLeft = "Bottom Left"
    case topLeft = "Top Left"
    case topRight = "Top Right"
    case bottomRight = "Bottom Right"
}

@MainActor
@Observable
public class SceneCoordinator {
    public var dealCardsAction: ((DealMode) async -> Void)?
    public var pickUpCardAction: ((GatherCorner) async -> Void)?
    public var fanInHandsAction: (() async -> Void)?
    public var updateInHandsPositionsAction: (() -> Void)?
    public var resetCardsAction: (() -> Void)?
    public var updateTableMaterialsAction: (() -> Void)?

    public init() {}
}
