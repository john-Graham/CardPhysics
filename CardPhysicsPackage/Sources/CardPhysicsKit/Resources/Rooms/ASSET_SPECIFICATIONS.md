# Room Background Asset Specifications

## Panoramic Image Requirements

### Format
- **File Type**: JPEG or PNG
- **Projection**: Equirectangular (360° × 180°)
- **Aspect Ratio**: 2:1 (width:height)

### Resolution
- **Recommended**: 4096 × 2048 pixels
- **Minimum**: 2048 × 1024 pixels
- **Maximum**: 8192 × 4096 pixels (for high-end devices)

### Naming Convention
- Use descriptive, lowercase names with hyphens
- Format: `{environment-type}-{variant}.jpg`
- Examples:
  - `casino-luxury.jpg`
  - `study-victorian.jpg`
  - `garden-japanese.jpg`
  - `cyberpunk-neon.jpg`

### Thumbnail Requirements
- **File Type**: JPEG
- **Resolution**: 256 × 128 pixels
- **Location**: `Resources/Rooms/Thumbnails/`
- **Naming**: Same base name as source with `-thumb` suffix
  - Example: `casino-luxury-thumb.jpg`

### Quality Guidelines
- High dynamic range (HDR) preferred for realistic lighting
- Avoid visible seams at 0°/360° boundary
- Neutral white balance preferred (can be adjusted in app)
- Minimal distortion or compression artifacts

### Content Guidelines
- Focus on interior spaces suitable for card games
- Ensure horizontal surfaces visible for card table placement
- Avoid overly busy or distracting patterns
- Consider lighting that complements card visibility

## Supported Environment Types
1. **Casino/Gaming**: Luxury casino, poker room, gaming hall
2. **Classic/Traditional**: Victorian study, library, gentleman's club
3. **Modern**: Contemporary lounge, minimalist space, rooftop terrace
4. **Fantasy/Themed**: Cyberpunk, steampunk, space station, underwater
5. **Natural**: Garden, conservatory, outdoor patio

## File Organization
```
Resources/Rooms/
├── ASSET_SPECIFICATIONS.md (this file)
├── SOURCES.md (recommended image sources)
├── {environment-name}.jpg (panoramic images)
└── Thumbnails/
    └── {environment-name}-thumb.jpg (thumbnail previews)
```
