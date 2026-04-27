import RealityKit

@MainActor
enum CurvedCardMesh {
    private static var cache: [Float: MeshResource] = [:]

    static func mesh(curvature: Float) -> MeshResource {
        if let cached = cache[curvature] {
            return cached
        }
        let generated = generateMesh(curvature: curvature)
        cache[curvature] = generated
        return generated
    }

    // MARK: - Mesh Generation

    /// Generates a two-part mesh: descriptor 0 = +Y face (material index 0 = card back),
    /// descriptor 1 = -Y face + edges (material index 1 = card face).
    private static func generateMesh(curvature: Float) -> MeshResource {
        let width = CardEntity3D.cardWidth
        let height = CardEntity3D.cardHeight
        let depth = CardEntity3D.cardDepth
        let halfW = width / 2
        let halfH = height / 2
        let halfD = depth / 2

        let radius = min(CardEntity3D.cornerRadius, min(halfW, halfD) * 0.5)

        // Helper: parabolic displacement at normalized x (-1..1)
        func bow(_ nx: Float) -> Float {
            -curvature * (1.0 - nx * nx)
        }

        // Helper: normal from parabola derivative
        func frontNormal(_ nx: Float) -> SIMD3<Float> {
            let dydx = -curvature * (-2.0 * nx) * (2.0 / width)
            let tangentX = SIMD3<Float>(1, dydx, 0)
            let tangentZ = SIMD3<Float>(0, 0, 1)
            let n = simd_normalize(simd_cross(tangentZ, tangentX))
            return n
        }

        let perimeter = roundedPerimeter(halfW: halfW, halfD: halfD, radius: radius)

        // =====================================================================
        // DESCRIPTOR 0: +Y face (material index 0 = card back texture)
        // Visible from above when card has identity rotation (face-down)
        // =====================================================================
        let front = makeFace(
            perimeter: perimeter,
            halfH: halfH,
            width: width,
            depth: depth,
            bow: bow,
            normalForX: frontNormal,
            isFront: true
        )
        var frontDescriptor = MeshDescriptor(name: "cardFront")
        frontDescriptor.positions = MeshBuffers.Positions(front.positions)
        frontDescriptor.normals = MeshBuffers.Normals(front.normals)
        frontDescriptor.textureCoordinates = MeshBuffers.TextureCoordinates(front.uvs)
        frontDescriptor.primitives = .triangles(front.indices)
        frontDescriptor.materials = .allFaces(0)

        // =====================================================================
        // DESCRIPTOR 1: -Y face + edges (material index 1 = card face texture)
        // Visible from above when card is flipped face-up (pi rotation on X)
        // =====================================================================
        var back = makeFace(
            perimeter: perimeter,
            halfH: halfH,
            width: width,
            depth: depth,
            bow: bow,
            normalForX: frontNormal,
            isFront: false
        )
        addRoundedEdgeStrip(
            perimeter: perimeter,
            positions: &back.positions,
            normals: &back.normals,
            uvs: &back.uvs,
            indices: &back.indices,
            halfH: halfH,
            width: width,
            depth: depth,
            bow: bow
        )

        var backDescriptor = MeshDescriptor(name: "cardBackAndEdges")
        backDescriptor.positions = MeshBuffers.Positions(back.positions)
        backDescriptor.normals = MeshBuffers.Normals(back.normals)
        backDescriptor.textureCoordinates = MeshBuffers.TextureCoordinates(back.uvs)
        backDescriptor.primitives = .triangles(back.indices)
        backDescriptor.materials = .allFaces(1)

        // Generate mesh with two descriptors — material indices set explicitly per descriptor
        do {
            return try MeshResource.generate(from: [frontDescriptor, backDescriptor])
        } catch {
            print("⚠️ Failed to generate curved card mesh: \(error). Using fallback.")
            return MeshResource.generatePlane(width: width, depth: height)
        }
    }

    // MARK: - Mesh Helpers

    private struct MeshData {
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>] = []
        var indices: [UInt32] = []
    }

    private static func roundedPerimeter(halfW: Float, halfD: Float, radius: Float) -> [SIMD2<Float>] {
        let segments = 8
        let centers: [(SIMD2<Float>, ClosedRange<Float>)] = [
            (SIMD2(-halfW + radius, -halfD + radius), Float.pi...(Float.pi * 1.5)),
            (SIMD2(halfW - radius, -halfD + radius), (Float.pi * 1.5)...(Float.pi * 2.0)),
            (SIMD2(halfW - radius, halfD - radius), 0...(Float.pi * 0.5)),
            (SIMD2(-halfW + radius, halfD - radius), (Float.pi * 0.5)...Float.pi),
        ]

        var points: [SIMD2<Float>] = []
        for (center, range) in centers {
            for step in 0...segments {
                if !points.isEmpty && step == 0 { continue }
                let t = Float(step) / Float(segments)
                let angle = range.lowerBound + (range.upperBound - range.lowerBound) * t
                points.append(SIMD2(
                    center.x + cos(angle) * radius,
                    center.y + sin(angle) * radius
                ))
            }
        }
        return points
    }

    private static func makeFace(
        perimeter: [SIMD2<Float>],
        halfH: Float,
        width: Float,
        depth: Float,
        bow: (Float) -> Float,
        normalForX: (Float) -> SIMD3<Float>,
        isFront: Bool
    ) -> MeshData {
        var data = MeshData()

        func appendVertex(x: Float, z: Float) {
            let u = (x / width) + 0.5
            let v = 1.0 - ((z / depth) + 0.5)
            let nxNorm = 2.0 * u - 1.0
            let faceOffset = isFront ? halfH : -halfH

            data.positions.append(SIMD3<Float>(x, faceOffset + bow(nxNorm), z))
            data.normals.append(isFront ? normalForX(nxNorm) : -normalForX(nxNorm))
            data.uvs.append(SIMD2<Float>(isFront ? u : 1.0 - u, v))
        }

        appendVertex(x: 0, z: 0)
        for point in perimeter {
            appendVertex(x: point.x, z: point.y)
        }

        let count = UInt32(perimeter.count)
        for i in 0..<count {
            let current = i + 1
            let next = ((i + 1) % count) + 1
            if isFront {
                data.indices.append(contentsOf: [0, next, current])
            } else {
                data.indices.append(contentsOf: [0, current, next])
            }
        }

        return data
    }

    private static func addRoundedEdgeStrip(
        perimeter: [SIMD2<Float>],
        positions: inout [SIMD3<Float>],
        normals: inout [SIMD3<Float>],
        uvs: inout [SIMD2<Float>],
        indices: inout [UInt32],
        halfH: Float,
        width: Float,
        depth: Float,
        bow: (Float) -> Float
    ) {
        let start = UInt32(positions.count)

        for i in 0..<perimeter.count {
            let point = perimeter[i]
            let prev = perimeter[(i - 1 + perimeter.count) % perimeter.count]
            let next = perimeter[(i + 1) % perimeter.count]
            let tangent = simd_normalize(next - prev)
            let outward = simd_normalize(SIMD2<Float>(tangent.y, -tangent.x))
            let u = (point.x / width) + 0.5
            let v = 1.0 - ((point.y / depth) + 0.5)
            let nxNorm = 2.0 * u - 1.0
            let bowY = bow(nxNorm)
            let normal = SIMD3<Float>(outward.x, 0, outward.y)

            positions.append(SIMD3<Float>(point.x, halfH + bowY, point.y))
            normals.append(normal)
            uvs.append(SIMD2<Float>(u, v))

            positions.append(SIMD3<Float>(point.x, -halfH + bowY, point.y))
            normals.append(normal)
            uvs.append(SIMD2<Float>(u, v))
        }

        for i in 0..<UInt32(perimeter.count) {
            let current = start + i * 2
            let next = start + ((i + 1) % UInt32(perimeter.count)) * 2
            let frontCurrent = current
            let backCurrent = current + 1
            let frontNext = next
            let backNext = next + 1
            indices.append(contentsOf: [frontCurrent, frontNext, backCurrent, backCurrent, frontNext, backNext])
        }
    }
}
