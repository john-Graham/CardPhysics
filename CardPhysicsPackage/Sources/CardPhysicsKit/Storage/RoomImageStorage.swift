import UIKit

@MainActor
enum RoomImageStorage {
    private static var roomBackgroundsDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("RoomBackgrounds", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Saves a panoramic room image to the RoomBackgrounds directory.
    /// Validates aspect ratio (~2:1 for equirectangular), downscales to max 4096px width.
    /// Returns the filename on success, nil if validation fails or save fails.
    static func saveImage(_ image: UIImage) -> String? {
        let size = image.size

        // Validate aspect ratio (~2:1 for equirectangular panoramas)
        let aspectRatio = size.width / size.height
        let targetRatio: CGFloat = 2.0
        let tolerance: CGFloat = 0.2 // Allow 1.8:1 to 2.2:1

        if abs(aspectRatio - targetRatio) > tolerance {
            print("⚠️ Invalid aspect ratio for panoramic image: \(aspectRatio):1 (expected ~2:1)")
            return nil
        }

        // Downscale to max 4096px width
        let maxWidth: CGFloat = 4096
        let scaled: UIImage

        if size.width > maxWidth {
            let scale = maxWidth / size.width
            let newSize = CGSize(width: maxWidth, height: size.height * scale)
            let renderer = UIGraphicsImageRenderer(size: newSize)
            scaled = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: newSize))
            }
        } else {
            scaled = image
        }

        guard let data = scaled.jpegData(compressionQuality: 0.85) else { return nil }

        let filename = "room_\(UUID().uuidString).jpg"
        let url = roomBackgroundsDirectory.appendingPathComponent(filename)

        do {
            try data.write(to: url)
            return filename
        } catch {
            print("⚠️ Failed to save room background image: \(error)")
            return nil
        }
    }

    /// Returns the full URL for a stored room image filename
    static func imageURL(for filename: String) -> URL {
        roomBackgroundsDirectory.appendingPathComponent(filename)
    }

    /// Removes a previously saved room image
    static func removeImage(filename: String) {
        let url = imageURL(for: filename)
        try? FileManager.default.removeItem(at: url)
    }
}
