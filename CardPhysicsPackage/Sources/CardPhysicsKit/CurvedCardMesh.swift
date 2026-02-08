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

    private static func generateMesh(curvature: Float) -> MeshResource {
        let width = CardEntity3D.cardWidth
        let height = CardEntity3D.cardHeight
        let depth = CardEntity3D.cardDepth
        let halfW = width / 2
        let halfH = height / 2
        let halfD = depth / 2

        let xSegs = 16
        let zSegs = 1

        // Front and back grids
        let xCount = xSegs + 1  // 17
        let zCount = zSegs + 1  // 2
        let gridVerts = xCount * zCount  // 34 per face

        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>] = []
        var indices: [UInt32] = []

        // Helper: parabolic displacement at normalized x (-1..1)
        func bow(_ nx: Float) -> Float {
            -curvature * (1.0 - nx * nx)
        }

        // Helper: normal from parabola derivative
        // dy/dx = curvature * -2 * nx * (2/width)
        // Tangent along X at this point: (1, dy/dx_world, 0)
        // Normal = cross(tangentX, tangentZ) for front face
        func frontNormal(_ nx: Float) -> SIMD3<Float> {
            let dydx = -curvature * (-2.0 * nx) * (2.0 / width)
            let tangentX = SIMD3<Float>(1, dydx, 0)
            let tangentZ = SIMD3<Float>(0, 0, -1) // along -Z for front face
            let n = simd_normalize(simd_cross(tangentZ, tangentX))
            return n
        }

        // --- Front face (+Y side) ---
        let frontStart = UInt32(positions.count)
        for zi in 0...zSegs {
            let nz = Float(zi) / Float(zSegs)
            let z = -halfD + nz * depth
            for xi in 0...xSegs {
                let nx = Float(xi) / Float(xSegs)
                let x = -halfW + nx * width
                let nxNorm = (2.0 * nx - 1.0) // -1..1
                let y = halfH + bow(nxNorm)

                positions.append(SIMD3<Float>(x, y, z))
                normals.append(frontNormal(nxNorm))
                uvs.append(SIMD2<Float>(nx, 1.0 - nz))
            }
        }

        // Front face triangles (counter-clockwise when viewed from +Y)
        for zi in 0..<zSegs {
            for xi in 0..<xSegs {
                let tl = frontStart + UInt32(zi * xCount + xi)
                let tr = tl + 1
                let bl = frontStart + UInt32((zi + 1) * xCount + xi)
                let br = bl + 1
                // Two triangles per quad — CCW winding for outward +Y normal
                indices.append(contentsOf: [tl, bl, tr, tr, bl, br])
            }
        }

        // --- Back face (-Y side) ---
        let backStart = UInt32(positions.count)
        for zi in 0...zSegs {
            let nz = Float(zi) / Float(zSegs)
            let z = -halfD + nz * depth
            for xi in 0...xSegs {
                let nx = Float(xi) / Float(xSegs)
                let x = -halfW + nx * width
                let nxNorm = (2.0 * nx - 1.0)
                let y = -halfH + bow(nxNorm)

                positions.append(SIMD3<Float>(x, y, z))
                let n = frontNormal(nxNorm)
                normals.append(-n) // flipped for back face
                // Mirror UVs horizontally for back face
                uvs.append(SIMD2<Float>(1.0 - nx, 1.0 - nz))
            }
        }

        // Back face triangles (reversed winding)
        for zi in 0..<zSegs {
            for xi in 0..<xSegs {
                let tl = backStart + UInt32(zi * xCount + xi)
                let tr = tl + 1
                let bl = backStart + UInt32((zi + 1) * xCount + xi)
                let br = bl + 1
                indices.append(contentsOf: [tl, tr, bl, bl, tr, br])
            }
        }

        // --- Edge strips (connect front and back along the 4 perimeter edges) ---

        // Top edge (zi=0, z = -halfD) — curved along X
        addCurvedEdgeStrip(
            positions: &positions, normals: &normals, uvs: &uvs, indices: &indices,
            xSegs: xSegs, width: width, halfW: halfW, halfH: halfH,
            z: -halfD, edgeNormalZ: -1.0, curvature: curvature
        )

        // Bottom edge (zi=zSegs, z = +halfD) — curved along X
        addCurvedEdgeStrip(
            positions: &positions, normals: &normals, uvs: &uvs, indices: &indices,
            xSegs: xSegs, width: width, halfW: halfW, halfH: halfH,
            z: halfD, edgeNormalZ: 1.0, curvature: curvature
        )

        // Left edge (xi=0, x = -halfW) — simple quad (no bow at edges)
        addSideEdgeQuad(
            positions: &positions, normals: &normals, uvs: &uvs, indices: &indices,
            x: -halfW, halfH: halfH, halfD: halfD, edgeNormalX: -1.0,
            bowDisplacement: 0.0 // edges have zero bow
        )

        // Right edge (xi=xSegs, x = +halfW) — simple quad
        addSideEdgeQuad(
            positions: &positions, normals: &normals, uvs: &uvs, indices: &indices,
            x: halfW, halfH: halfH, halfD: halfD, edgeNormalX: 1.0,
            bowDisplacement: 0.0
        )

        var descriptor = MeshDescriptor(name: "curvedCard")
        descriptor.positions = MeshBuffers.Positions(positions)
        descriptor.normals = MeshBuffers.Normals(normals)
        descriptor.textureCoordinates = MeshBuffers.TextureCoordinates(uvs)
        descriptor.primitives = .triangles(indices)

        do {
            return try MeshResource.generate(from: [descriptor])
        } catch {
            // If mesh generation fails, log error and create a simple fallback mesh
            print("⚠️ Failed to generate curved card mesh: \(error). Using fallback.")
            // Generate a simple flat quad as fallback
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
        // Match front face UV y: at z=-halfD (edgeNormalZ<0) → UV y=1.0, at z=+halfD → UV y=0.0
        // Both vertices share the same UV y so the rounded-corner alpha mask clips edges at corners
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
                // -Z edge: face outward
                indices.append(contentsOf: [t0, t1, b0, b0, t1, b1])
            } else {
                // +Z edge: face outward
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

        // Four corners of the side edge quad
        // Front-top, front-bottom, back-top, back-bottom
        let topY = halfH + bowDisplacement
        let botY = -halfH + bowDisplacement

        positions.append(SIMD3<Float>(x, topY, -halfD))  // 0: front-top
        positions.append(SIMD3<Float>(x, botY, -halfD))  // 1: front-bottom
        positions.append(SIMD3<Float>(x, topY, halfD))   // 2: back-top
        positions.append(SIMD3<Float>(x, botY, halfD))   // 3: back-bottom

        for _ in 0..<4 { normals.append(normal) }
        // UV x = edge column of texture (0 for left edge, 1 for right edge)
        // UV y maps along Z to match front face mapping (1.0 at z=-halfD, 0.0 at z=+halfD)
        // This ensures the rounded-corner alpha mask clips the edge at corners
        let u: Float = edgeNormalX < 0 ? 0 : 1
        uvs.append(contentsOf: [
            SIMD2<Float>(u, 1), SIMD2<Float>(u, 1),  // front (z=-halfD)
            SIMD2<Float>(u, 0), SIMD2<Float>(u, 0),  // back  (z=+halfD)
        ])

        if edgeNormalX < 0 {
            // Left edge: outward winding
            indices.append(contentsOf: [start, start + 2, start + 1, start + 1, start + 2, start + 3])
        } else {
            // Right edge: outward winding
            indices.append(contentsOf: [start, start + 1, start + 2, start + 2, start + 1, start + 3])
        }
    }
}
