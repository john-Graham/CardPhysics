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

    /// Generates a two-part mesh: descriptor 0 = front face (material index 0),
    /// descriptor 1 = back face + edges (material index 1).
    private static func generateMesh(curvature: Float) -> MeshResource {
        let width = CardEntity3D.cardWidth
        let height = CardEntity3D.cardHeight
        let depth = CardEntity3D.cardDepth
        let halfW = width / 2
        let halfH = height / 2
        let halfD = depth / 2

        let xSegs = 16
        let zSegs = 1

        let xCount = xSegs + 1  // 17
        // let zCount = zSegs + 1  // 2 (unused but kept for reference)

        // Helper: parabolic displacement at normalized x (-1..1)
        func bow(_ nx: Float) -> Float {
            -curvature * (1.0 - nx * nx)
        }

        // Helper: normal from parabola derivative
        func frontNormal(_ nx: Float) -> SIMD3<Float> {
            let dydx = -curvature * (-2.0 * nx) * (2.0 / width)
            let tangentX = SIMD3<Float>(1, dydx, 0)
            let tangentZ = SIMD3<Float>(0, 0, -1)
            let n = simd_normalize(simd_cross(tangentZ, tangentX))
            return n
        }

        // =====================================================================
        // DESCRIPTOR 0: Front face only (material index 0 = card face texture)
        // =====================================================================
        var frontPositions: [SIMD3<Float>] = []
        var frontNormals: [SIMD3<Float>] = []
        var frontUVs: [SIMD2<Float>] = []
        var frontIndices: [UInt32] = []

        for zi in 0...zSegs {
            let nz = Float(zi) / Float(zSegs)
            let z = -halfD + nz * depth
            for xi in 0...xSegs {
                let nx = Float(xi) / Float(xSegs)
                let x = -halfW + nx * width
                let nxNorm = (2.0 * nx - 1.0)
                let y = halfH + bow(nxNorm)

                frontPositions.append(SIMD3<Float>(x, y, z))
                frontNormals.append(frontNormal(nxNorm))
                frontUVs.append(SIMD2<Float>(nx, 1.0 - nz))
            }
        }

        // Front face triangles (counter-clockwise when viewed from +Y)
        for zi in 0..<zSegs {
            for xi in 0..<xSegs {
                let tl = UInt32(zi * xCount + xi)
                let tr = tl + 1
                let bl = UInt32((zi + 1) * xCount + xi)
                let br = bl + 1
                frontIndices.append(contentsOf: [tl, bl, tr, tr, bl, br])
            }
        }

        var frontDescriptor = MeshDescriptor(name: "cardFront")
        frontDescriptor.positions = MeshBuffers.Positions(frontPositions)
        frontDescriptor.normals = MeshBuffers.Normals(frontNormals)
        frontDescriptor.textureCoordinates = MeshBuffers.TextureCoordinates(frontUVs)
        frontDescriptor.primitives = .triangles(frontIndices)

        // =====================================================================
        // DESCRIPTOR 1: Back face + edges (material index 1 = card back texture)
        // =====================================================================
        var backPositions: [SIMD3<Float>] = []
        var backNormals: [SIMD3<Float>] = []
        var backUVs: [SIMD2<Float>] = []
        var backIndices: [UInt32] = []

        // --- Back face (-Y side) ---
        let backFaceStart = UInt32(backPositions.count)
        for zi in 0...zSegs {
            let nz = Float(zi) / Float(zSegs)
            let z = -halfD + nz * depth
            for xi in 0...xSegs {
                let nx = Float(xi) / Float(xSegs)
                let x = -halfW + nx * width
                let nxNorm = (2.0 * nx - 1.0)
                let y = -halfH + bow(nxNorm)

                backPositions.append(SIMD3<Float>(x, y, z))
                let n = frontNormal(nxNorm)
                backNormals.append(-n) // flipped for back face
                // Mirror UVs horizontally for back face
                backUVs.append(SIMD2<Float>(1.0 - nx, 1.0 - nz))
            }
        }

        // Back face triangles (reversed winding)
        for zi in 0..<zSegs {
            for xi in 0..<xSegs {
                let tl = backFaceStart + UInt32(zi * xCount + xi)
                let tr = tl + 1
                let bl = backFaceStart + UInt32((zi + 1) * xCount + xi)
                let br = bl + 1
                backIndices.append(contentsOf: [tl, tr, bl, bl, tr, br])
            }
        }

        // --- Edge strips (connect front and back along the 4 perimeter edges) ---

        // Top edge (zi=0, z = -halfD) — curved along X
        addCurvedEdgeStrip(
            positions: &backPositions, normals: &backNormals, uvs: &backUVs, indices: &backIndices,
            xSegs: xSegs, width: width, halfW: halfW, halfH: halfH,
            z: -halfD, edgeNormalZ: -1.0, curvature: curvature
        )

        // Bottom edge (zi=zSegs, z = +halfD) — curved along X
        addCurvedEdgeStrip(
            positions: &backPositions, normals: &backNormals, uvs: &backUVs, indices: &backIndices,
            xSegs: xSegs, width: width, halfW: halfW, halfH: halfH,
            z: halfD, edgeNormalZ: 1.0, curvature: curvature
        )

        // Left edge (xi=0, x = -halfW) — simple quad (no bow at edges)
        addSideEdgeQuad(
            positions: &backPositions, normals: &backNormals, uvs: &backUVs, indices: &backIndices,
            x: -halfW, halfH: halfH, halfD: halfD, edgeNormalX: -1.0,
            bowDisplacement: 0.0
        )

        // Right edge (xi=xSegs, x = +halfW) — simple quad
        addSideEdgeQuad(
            positions: &backPositions, normals: &backNormals, uvs: &backUVs, indices: &backIndices,
            x: halfW, halfH: halfH, halfD: halfD, edgeNormalX: 1.0,
            bowDisplacement: 0.0
        )

        var backDescriptor = MeshDescriptor(name: "cardBackAndEdges")
        backDescriptor.positions = MeshBuffers.Positions(backPositions)
        backDescriptor.normals = MeshBuffers.Normals(backNormals)
        backDescriptor.textureCoordinates = MeshBuffers.TextureCoordinates(backUVs)
        backDescriptor.primitives = .triangles(backIndices)

        // Generate mesh with two descriptors — RealityKit maps descriptor order to material indices
        do {
            return try MeshResource.generate(from: [frontDescriptor, backDescriptor])
        } catch {
            print("⚠️ Failed to generate curved card mesh: \(error). Using fallback.")
            return MeshResource.generatePlane(width: width, depth: height)
        }
    }

    // MARK: - Edge Helpers

    /// Curved edge strip connecting front and back faces along a Z-boundary (top or bottom edge)
    private static func addCurvedEdgeStrip(
        positions: inout [SIMD3<Float>],
        normals: inout [SIMD3<Float>],
        uvs: inout [SIMD2<Float>],
        indices: inout [UInt32],
        xSegs: Int,
        width: Float,
        halfW: Float,
        halfH: Float,
        z: Float,
        edgeNormalZ: Float,
        curvature: Float
    ) {
        let start = UInt32(positions.count)
        let normal = SIMD3<Float>(0, 0, edgeNormalZ)
        let edgeUVy: Float = edgeNormalZ < 0 ? 1.0 : 0.0

        for xi in 0...(xSegs) {
            let nx = Float(xi) / Float(xSegs)
            let x = -halfW + nx * width
            let nxNorm = 2.0 * nx - 1.0
            let bowY = -curvature * (1.0 - nxNorm * nxNorm)

            // Top vertex (front face edge)
            positions.append(SIMD3<Float>(x, halfH + bowY, z))
            normals.append(normal)
            uvs.append(SIMD2<Float>(nx, edgeUVy))

            // Bottom vertex (back face edge)
            positions.append(SIMD3<Float>(x, -halfH + bowY, z))
            normals.append(normal)
            uvs.append(SIMD2<Float>(nx, edgeUVy))
        }

        let vertsPerCol: UInt32 = 2
        for xi in 0..<UInt32(xSegs) {
            let col = start + xi * vertsPerCol
            let nextCol = col + vertsPerCol
            let t0 = col       // top-left
            let b0 = col + 1   // bottom-left
            let t1 = nextCol   // top-right
            let b1 = nextCol + 1 // bottom-right

            if edgeNormalZ < 0 {
                indices.append(contentsOf: [t0, t1, b0, b0, t1, b1])
            } else {
                indices.append(contentsOf: [t0, b0, t1, t1, b0, b1])
            }
        }
    }

    /// Simple quad for left/right edges (no curvature since bow is zero at x extremes)
    private static func addSideEdgeQuad(
        positions: inout [SIMD3<Float>],
        normals: inout [SIMD3<Float>],
        uvs: inout [SIMD2<Float>],
        indices: inout [UInt32],
        x: Float,
        halfH: Float,
        halfD: Float,
        edgeNormalX: Float,
        bowDisplacement: Float
    ) {
        let start = UInt32(positions.count)
        let normal = SIMD3<Float>(edgeNormalX, 0, 0)

        let topY = halfH + bowDisplacement
        let botY = -halfH + bowDisplacement

        positions.append(SIMD3<Float>(x, topY, -halfD))  // 0: front-top
        positions.append(SIMD3<Float>(x, botY, -halfD))  // 1: front-bottom
        positions.append(SIMD3<Float>(x, topY, halfD))   // 2: back-top
        positions.append(SIMD3<Float>(x, botY, halfD))   // 3: back-bottom

        for _ in 0..<4 { normals.append(normal) }
        let u: Float = edgeNormalX < 0 ? 0 : 1
        uvs.append(contentsOf: [
            SIMD2<Float>(u, 1), SIMD2<Float>(u, 1),
            SIMD2<Float>(u, 0), SIMD2<Float>(u, 0),
        ])

        if edgeNormalX < 0 {
            indices.append(contentsOf: [start, start + 2, start + 1, start + 1, start + 2, start + 3])
        } else {
            indices.append(contentsOf: [start, start + 1, start + 2, start + 2, start + 1, start + 3])
        }
    }
}
