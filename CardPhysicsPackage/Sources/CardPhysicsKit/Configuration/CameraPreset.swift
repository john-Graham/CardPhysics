import Foundation
import simd

public enum CameraPreset: String, CaseIterable, Sendable {
    case side1 = "Side 1"
    case side2 = "Side 2"
    case side3 = "Side 3"
    case side4 = "Side 4"
    case overhead = "Overhead"

    public static var playerSides: [CameraPreset] {
        [.side1, .side2, .side3, .side4]
    }

    public var icon: String {
        switch self {
        case .side1: "1.circle"
        case .side2: "2.circle"
        case .side3: "3.circle"
        case .side4: "4.circle"
        case .overhead: "arrow.down.to.line"
        }
    }

    public var position: SIMD3<Float> {
        switch self {
        case .side1: [0.0, 0.55, 0.54]
        case .side2: [-0.70, 0.55, 0.0]
        case .side3: [0.0, 0.55, -0.54]
        case .side4: [0.70, 0.55, 0.0]
        case .overhead: [0.0, 1.2, 0.001]
        }
    }

    public var target: SIMD3<Float> {
        [0.0, 0.0, 0.0]
    }
}
