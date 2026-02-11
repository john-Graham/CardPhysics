# Panoramic Image Sources

## Free/Open Sources

### Poly Haven (Recommended)
- **URL**: https://polyhaven.com/hdris
- **License**: CC0 (Public Domain)
- **Formats**: HDR, EXR, and JPG available
- **Resolution**: Up to 16K available
- **Quality**: Excellent, professionally captured
- **Categories**: Indoors, outdoors, studios
- **Notes**: Best source for high-quality, royalty-free HDRIs

### HDRI Haven (archived, now part of Poly Haven)
- **URL**: https://hdrihaven.com
- **License**: CC0 (Public Domain)
- **Notes**: Legacy collection, redirects to Poly Haven

### Hugging Face Datasets
- **URL**: https://huggingface.co/datasets
- **Search**: "equirectangular", "panorama", "360"
- **License**: Varies by dataset (check individual licenses)
- **Quality**: Varies
- **Notes**: Some AI-generated options available

## Commercial/Premium Sources

### Blockade Labs Skybox AI
- **URL**: https://skybox.blockadelabs.com
- **Type**: AI-generated panoramas
- **License**: Commercial use allowed (check current terms)
- **Quality**: Good for stylized/fantasy environments
- **Cost**: Free tier available, paid plans for commercial use
- **Notes**: Can generate custom scenes via text prompts

### HDRI Skies
- **URL**: https://hdri-skies.com
- **License**: Commercial license available
- **Quality**: Professional-grade
- **Cost**: Paid

### CGTrader
- **URL**: https://www.cgtrader.com
- **Search**: "HDRI" or "equirectangular"
- **License**: Royalty-free options available
- **Quality**: Varies
- **Cost**: Individual purchases

### TurboSquid
- **URL**: https://www.turbosquid.com
- **Search**: "360 panorama" or "HDRI"
- **License**: Royalty-free options available
- **Quality**: Professional-grade
- **Cost**: Individual purchases

## DIY/Custom Creation

### Capture Your Own
- **Tools**: Insta360, Ricoh Theta, or smartphone 360 apps
- **Processing**: PTGui, Hugin (free), or Adobe Lightroom
- **Pros**: Complete creative control, unique environments
- **Cons**: Requires equipment and post-processing skills

### AI Generation Tools
- **Blockade Labs Skybox** (see above)
- **MidJourney**: Can generate equirectangular with proper prompts
- **Stable Diffusion**: With panorama-specific models
- **Notes**: Verify licensing for commercial use

## Recommended Starting Collection

### Poly Haven Suggestions
1. **Indoor Studio** - Clean, neutral background
   - Search: "studio" or "photo studio"
2. **Library/Study** - Classic card game setting
   - Search: "library", "interior"
3. **Modern Interior** - Contemporary aesthetic
   - Search: "modern", "apartment"
4. **Outdoor Garden** - Natural lighting option
   - Search: "garden", "outdoor"

### Blockade Labs Prompts
1. **Luxury Casino**: "luxurious casino interior, poker tables, warm lighting"
2. **Cyberpunk Room**: "cyberpunk gaming room, neon lights, futuristic"
3. **Victorian Study**: "victorian library, dark wood, fireplace, leather chairs"
4. **Space Station**: "space station interior, panoramic windows, stars visible"

## Processing Workflow

1. **Download** source HDRI (highest resolution available)
2. **Convert** to JPEG if needed (using Photoshop, GIMP, or ImageMagick)
3. **Resize** to 4096×2048 if larger
4. **Create thumbnail** at 256×128 resolution
5. **Verify** seam quality at 0°/360° boundary
6. **Test** in RealityKit to ensure proper projection
7. **Optimize** file size while maintaining quality (JPEG quality 85-90)

## ImageMagick Commands

Convert HDR to JPEG:
```bash
magick input.hdr -resize 4096x2048 -quality 90 output.jpg
```

Create thumbnail:
```bash
magick output.jpg -resize 256x128 -quality 85 output-thumb.jpg
```

## License Compliance

- Always verify license terms before use
- For CC0 assets, attribution is not required but appreciated
- For commercial projects, ensure proper licensing
- Keep license documentation with asset files
- Update this file with specific licenses for each included asset
