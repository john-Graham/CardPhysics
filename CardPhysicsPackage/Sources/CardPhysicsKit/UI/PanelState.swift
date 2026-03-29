import Observation

/// Consolidates all panel visibility state for CardPhysicsView.
///
/// Using `@Observable` allows SwiftUI to track individual property access,
/// so toggling one panel only invalidates the views that read that property.
@MainActor
@Observable
final class PanelState {
    var showDealSettings = false
    var showPickUpSettings = false
    var showInHandsSettings = false
    var showCardDesign = false
    var showRoomBackground = false
    var showTableTheme = false
    var showLighting = false
    var showCardEffects = false
    var showEnvironmentalEffects = false
    var showCameraSettings = false

    /// Dismisses every panel.
    func closeAll() {
        showDealSettings = false
        showPickUpSettings = false
        showInHandsSettings = false
        showCardDesign = false
        showRoomBackground = false
        showTableTheme = false
        showLighting = false
        showCardEffects = false
        showEnvironmentalEffects = false
        showCameraSettings = false
    }
}
