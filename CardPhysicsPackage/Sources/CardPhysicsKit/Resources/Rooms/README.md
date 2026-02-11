# Room Backgrounds Directory

This directory contains 360° panoramic images used as immersive backgrounds for the card table environment.

## Current Status

**3 Starter Environments Included** - Downloaded from Poly Haven, CC0 licensed.

## Available Environments

### 1. poker_room.jpg
- **Source**: Poly Haven - brown_photostudio_02
- **Description**: Warm brown photography studio with natural daylight from window and fluorescent fixtures
- **Lighting**: Mixed natural and artificial, medium contrast, soft shadows
- **Color Temperature**: 5800K
- **Best for**: Traditional card game atmosphere, warm inviting setting

### 2. modern_office.jpg
- **Source**: Poly Haven - photo_studio_01
- **Description**: Cool fluorescent studio lighting with white surroundings
- **Lighting**: Professional studio setup, soft indirect lighting
- **Color Temperature**: 5622K
- **Best for**: Clean modern aesthetic, neutral background

### 3. classic_library.jpg
- **Source**: Poly Haven - studio_small_03
- **Description**: Bright umbrella softbox and ceiling lamp setup
- **Lighting**: High-contrast artificial lighting, crisp whites and deep blacks
- **Color Temperature**: Professional studio lighting
- **Best for**: High-contrast environments, photography-style lighting

All images are 4096×2048 equirectangular JPEGs with matching 256×128 thumbnails.

## Directory Structure

```
Resources/Rooms/
├── README.md (this file)
├── ASSET_SPECIFICATIONS.md
├── SOURCES.md
├── poker_room.jpg
├── modern_office.jpg
├── classic_library.jpg
└── Thumbnails/
    ├── poker_room_thumb.jpg
    ├── modern_office_thumb.jpg
    └── classic_library_thumb.jpg
```

## Next Steps

1. **Test** these environments in CardPhysics app with SkyboxComponent
2. **Add more** themed environments as needed (casino, garden, Victorian study, etc.)
3. **Consider** AI-generated custom environments via Blockade Labs for fantasy/themed rooms

## Integration Notes

Once images are added:
- Update `RoomEnvironmentLoader.swift` to reference new assets
- Add asset names to `RoomEnvironment` enum
- Update thumbnail paths in room selection UI
- Test SkyboxComponent rendering with each new environment
