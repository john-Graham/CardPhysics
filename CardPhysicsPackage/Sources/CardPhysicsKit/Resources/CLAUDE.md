# CardPhysicsKit Resources

## Contents
- **`room_bg.exr`** -- HDRI environment map for image-based lighting (IBL)

## How Resources Are Used

### HDRI Environment (room_bg.exr)
Loaded in `CardPhysicsScene.setupLighting()` via:
```swift
EnvironmentResource.load(named: "room_bg", in: Bundle.module)
```
Applied as `ImageBasedLightComponent` on the root entity. Provides realistic ambient lighting and reflections on PBR materials (card clearcoat, wood varnish).

If loading fails, the scene falls back to a programmatic 3-point light setup (main spot, fill point, rim spot).

### Bundle Access
Resources are processed by SPM (declared in Package.swift as `.process("Resources")`) and accessed at runtime via `Bundle.module`. This is standard Swift Package resource bundling.

## Note on Procedural Textures
Most textures in the scene are NOT bundled resources. They are generated procedurally at runtime by `ProceduralTextureGenerator` (table felt, wood grain, normals, roughness maps) and `CardTextureGenerator` (card face/back textures rendered from SwiftUI views). Only the HDRI environment is a static asset.
