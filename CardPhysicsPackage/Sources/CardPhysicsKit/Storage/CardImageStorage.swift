import UIKit

@MainActor
enum CardImageStorage {
    private static var designsDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("CardDesigns", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Saves an image to the CardDesigns directory, downscaled to max 1024px.
    /// Returns the filename on success.
    static func saveImage(_ image: UIImage, purpose: String) -> String? {
        let maxDimension: CGFloat = 1024
        let scaled: UIImage
        let size = image.size

        if size.width > maxDimension || size.height > maxDimension {
            let scale = min(maxDimension / size.width, maxDimension / size.height)
            let newSize = CGSize(width: size.width * scale, height: size.height * scale)
            let renderer = UIGraphicsImageRenderer(size: newSize)
            scaled = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: newSize))
            }
        } else {
            scaled = image
        }

        guard let data = scaled.jpegData(compressionQuality: 0.85) else { return nil }

        let filename = "\(purpose)_\(UUID().uuidString).jpg"
        let url = designsDirectory.appendingPathComponent(filename)

        do {
            try data.write(to: url)
            return filename
        } catch {
            print("⚠️ Failed to save card design image: \(error)")
            return nil
        }
    }

    /// Returns the full URL for a stored image filename
    static func imageURL(for filename: String) -> URL {
        designsDirectory.appendingPathComponent(filename)
    }

    /// Removes a previously saved image
    static func removeImage(filename: String) {
        let url = imageURL(for: filename)
        try? FileManager.default.removeItem(at: url)
    }
}
