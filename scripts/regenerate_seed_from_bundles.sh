#!/bin/bash

# Script to regenerate mdm_catalog_seed.json with full embedded bundle data
# This should be run after the app has extracted bundles and refreshed the catalog

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "🔄 Regenerating seed file from embedded bundles..."
echo ""

# Find the latest snapshot in Application Support
CONTAINER_PATH=$(find ~/Library/Developer/CoreSimulator/Devices -name "Application Support" -type d 2>/dev/null | \
    grep -E "MDMKeys$" | head -1)

if [ -z "$CONTAINER_PATH" ]; then
    echo "❌ Error: Could not find Application Support directory"
    echo "   Make sure you've run the app at least once in the simulator"
    exit 1
fi

SNAPSHOT_PATH="$CONTAINER_PATH/mdm_catalog_latest.json"

if [ ! -f "$SNAPSHOT_PATH" ]; then
    echo "❌ Error: Latest snapshot not found at: $SNAPSHOT_PATH"
    echo "   Run the app and tap 'Refresh Catalog' in Settings first"
    exit 1
fi

echo "📁 Found snapshot at: $SNAPSHOT_PATH"

# Validate the snapshot has more data than current seed
CURRENT_KEYS=$(jq '.keys | length' MDMKeys/Resources/mdm_catalog_seed.json)
NEW_KEYS=$(jq '.keys | length' "$SNAPSHOT_PATH")

echo "📊 Current seed: $CURRENT_KEYS keys"
echo "📊 New snapshot: $NEW_KEYS keys"

if [ "$NEW_KEYS" -le "$CURRENT_KEYS" ]; then
    echo "⚠️  Warning: New snapshot has fewer or equal keys than current seed"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Backup current seed
echo "💾 Backing up current seed..."
cp MDMKeys/Resources/mdm_catalog_seed.json MDMKeys/Resources/mdm_catalog_seed.json.backup

# Copy snapshot to seed
echo "📝 Copying snapshot to seed file..."
cp "$SNAPSHOT_PATH" MDMKeys/Resources/mdm_catalog_seed.json

# Validate the new seed
echo ""
echo "✅ Validating new seed file..."
python3 scripts/validate_seed.py

echo ""
echo "✅ Seed file regenerated successfully!"
echo "   Keys: $CURRENT_KEYS → $NEW_KEYS"
echo "   Backup saved to: MDMKeys/Resources/mdm_catalog_seed.json.backup"
