import SwiftUI
import PhotosUI
import UIKit

/// PhotosPicker wrapper that returns a UIImage via callback.
///
/// Sandbox-owned copy of the `CardPhotoPicker` that CardEngine removed so
/// shipping games don't link PhotosUI unless they build their own picker.
/// Named `SandboxPhotoPicker` so it cannot collide with the engine's
/// `CardPhotoPicker` while the sandbox still builds against CardEngine 0.5.0.
struct SandboxPhotoPicker: View {
    let purpose: String
    let onImagePicked: (UIImage) -> Void

    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        PhotosPicker(
            selection: $selectedItem,
            matching: .images,
            photoLibrary: .shared()
        ) {
            Label("Choose Photo", systemImage: "photo")
        }
        .onChange(of: selectedItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    onImagePicked(image)
                }
            }
        }
    }
}
