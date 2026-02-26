#!/bin/bash

echo "🔄 Building and refreshing MDM catalog..."
echo ""
echo "This will:"
echo "1. Build the app"
echo "2. Run it"
echo "3. You'll need to manually tap 'Refresh Catalog' in Settings"
echo ""
echo "Press Enter to continue, or Ctrl+C to cancel..."
read

# Build the app
xcodebuild -project Differ.xcodeproj -scheme MDMKeys -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build

# Run the app (you'll need to manually refresh in settings)
echo ""
echo "✅ Build complete!"
echo ""
echo "📱 Now run the app and:"
echo "   1. Open Settings (gear icon)"
echo "   2. Tap 'Refresh Catalog'"
echo "   3. Wait for completion"
echo ""
