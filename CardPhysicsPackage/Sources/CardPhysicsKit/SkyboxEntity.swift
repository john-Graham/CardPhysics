import RealityKit
import SwiftUI
import UIKit

/// Factory for creating skybox entities with panoramic room backgrounds.
/// Generates inverted sphere meshes textured with equirectangular panoramas.
@MainActor
enum SkyboxEntity {
    /// Creates a skybox sphere with the specified room environment texture.
    ///
    /// - Parameters:
    ///   - environment: The room environment to display
    ///   - customImageFilename: Required when environment is `.customImage`
    ///   - rotation: Rotation in degrees to orient the panorama (0-360)
    /// - Returns: A ModelEntity with the skybox mesh, or nil if texture loading fails
    static func makeSkybox(
        environment: RoomEnvironment,
        customImageFilename: String = "",
        rotation: Double = 0.0
    ) -> ModelEntity? {
        // Skip for .none environment
        guard environment != .none else { return nil }

        // Load the appropriate texture
        guard let texture = loadTexture(
            environment: environment,
            customImageFilename: customImageFilename
        ) else {
            print("⚠️ Failed to load texture for room environment: \(environment)")
            return nil
        }

        // Create inverted sphere mesh
        guard let mesh = createInvertedSphereMesh() else {
            print("⚠️ Failed to create skybox sphere mesh")
            return nil
        }

        // Create unlit material with the panoramic texture
        var material = UnlitMaterial()
        material.color = .init(texture: .init(texture))

        // Create the model entity
        let entity = ModelEntity(mesh: mesh, materials: [material])

        // CRITICAL: Invert the sphere so texture is visible from inside
        // Negative X scale flips the normals inward
        entity.scale = [-1, 1, 1]

        // Apply rotation around Y axis (vertical)
        let rotationRadians = Float(rotation * .pi / 180.0)
        entity.transform.rotation = simd_quatf(angle: rotationRadians, axis: [0, 1, 0])

        return entity
    }

    /// Creates an inverted sphere mesh suitable for skybox rendering.
    /// Radius: 15m, scale: [-1, 1, 1] to invert normals for inside viewing.
    private static func createInvertedSphereMesh() -> MeshResource? {
        let radius: Float = 15.0

        // Generate a standard sphere mesh
        let mesh = MeshResource.generateSphere(radius: radius)

        // Create a new mesh descriptor with inverted scale
        // Negative X scale inverts the sphere so normals point inward
        var transform = Transform()
        transform.scale = [-1, 1, 1]

        // Apply the transform by creating a new entity temporarily
        // Note: RealityKit's sphere is already correctly UV-mapped for equirectangular
        return mesh
    }

    /// Loads a texture resource for the specified room environment.
    private static func loadTexture(
        environment: RoomEnvironment,
        customImageFilename: String
    ) -> TextureResource? {
        switch environment {
        case .none:
            return nil

        case .customImage:
            // Load from RoomImageStorage
            guard !customImageFilename.isEmpty else {
                print("⚠️ customImageFilename is required for .customImage environment")
                return nil
            }

            let imageURL = RoomImageStorage.imageURL(for: customImageFilename)

            // Load UIImage and convert to TextureResource
            guard let uiImage = UIImage(contentsOfFile: imageURL.path) else {
                print("⚠️ Failed to load custom image at path: \(imageURL.path)")
                return nil
            }

            guard let cgImage = uiImage.cgImage else {
                print("⚠️ Failed to get CGImage from UIImage")
                return nil
            }

            return try? TextureResource.generate(from: cgImage, options: .init(semantic: .color))

        case .pokerRoom, .modernOffice, .classicLibrary, .woodCabin:
            // Load from Bundle.module Resources (flattened at bundle root)
            guard let filename = environment.panoramaFilename else {
                print("⚠️ No panorama filename for environment: \(environment)")
                return nil
            }

            // Try to load from Bundle.module (resources are flattened, not in subdirectory)
            guard let url = Bundle.module.url(
                forResource: filename.replacingOccurrences(of: ".jpg", with: ""),
                withExtension: "jpg"
            ) else {
                print("⚠️ Resource not found in Bundle.module: \(filename)")
                return nil
            }

            // Load UIImage and convert to TextureResource (same as custom images)
            guard let uiImage = UIImage(contentsOfFile: url.path) else {
                print("⚠️ Failed to load image at path: \(url.path)")
                return nil
            }

            guard let cgImage = uiImage.cgImage else {
                print("⚠️ Failed to get CGImage from UIImage")
                return nil
            }

            return try? TextureResource.generate(from: cgImage, options: .init(semantic: .color))
        }
    }
}
