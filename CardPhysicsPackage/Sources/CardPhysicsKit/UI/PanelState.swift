import Observation

enum PanelKind: Hashable {
    case dealSettings
    case pickUpSettings
    case inHandsSettings
    case cardDesign
    case roomBackground
    case tableTheme
    case lighting
    case cardEffects
    case environmentalEffects
    case cameraSettings
    case gravitySettings
}

/// Consolidates all panel visibility state for CardPhysicsView.
///
/// Using `@Observable` allows SwiftUI to track individual property access,
/// so toggling one panel only invalidates the views that read that property.
@MainActor
@Observable
final class PanelState {
    var activePanel: PanelKind?

    func show(_ panel: PanelKind) {
        activePanel = panel
    }

    func close() {
        activePanel = nil
    }

    func closeIfShowing(_ panel: PanelKind) {
        if activePanel == panel {
            close()
        }
    }

    func isShowing(_ panel: PanelKind) -> Bool {
        activePanel == panel
    }
}
