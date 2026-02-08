#!/bin/bash

# CardPhysics Project Setup Script
# This script creates the Xcode project structure

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "📦 Creating CardPhysics Xcode project in: $PROJECT_DIR"

# Create necessary directories
mkdir -p "$PROJECT_DIR/CardPhysicsApp.xcodeproj/project.xcworkspace"
mkdir -p "$PROJECT_DIR/CardPhysicsApp.xcodeproj/xcshareddata"
mkdir -p "$PROJECT_DIR/CardPhysicsApp"
mkdir -p "$PROJECT_DIR/CardPhysicsApp/Assets.xcassets"

# Create a minimal Info.plist
cat > "$PROJECT_DIR/CardPhysicsApp/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>UIApplicationSceneManifest</key>
    <dict>
        <key>UIApplicationSupportsMultipleScenes</key>
        <false/>
    </dict>
    <key>UILaunchScreen</key>
    <dict/>
    <key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>armv7</string>
    </array>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
</dict>
</plist>
EOF

# Create workspace contents
cat > "$PROJECT_DIR/CardPhysicsApp.xcodeproj/project.xcworkspace/contents.xcworkspacedata" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<Workspace
   version = "1.0">
   <FileRef
      location = "self:">
   </FileRef>
</Workspace>
EOF

echo "✅ Project structure created!"
echo ""
echo "Next steps:"
echo "1. Open Xcode"
echo "2. File > New > Project"
echo "3. Choose iOS > App"
echo "4. Name it 'CardPhysicsApp'"
echo "5. Set Organization Identifier to 'com.yourname'"
echo "6. Choose SwiftUI interface and Swift language"
echo "7. Save it in: $PROJECT_DIR"
echo "8. In Xcode project settings:"
echo "   - Go to 'Frameworks, Libraries, and Embedded Content'"
echo "   - Click '+' and add the CardPhysicsKit package"
echo "   - File > Add Package Dependencies > Add Local..."
echo "   - Select: $PROJECT_DIR/CardPhysicsPackage"
echo ""
echo "📝 Then replace the generated ContentView with the CardPhysicsView from the package!"
