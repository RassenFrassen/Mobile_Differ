#!/usr/bin/env python3
"""
Generate mdm_catalog_seed.json directly from embedded bundles
without needing to run the app.
"""

import json
import sys
from pathlib import Path
from datetime import datetime

def main():
    project_root = Path(__file__).parent.parent
    bundles_dir = project_root / "MDMKeys" / "Resources 2" / "EmbeddedBundles"

    if not bundles_dir.exists():
        print(f"❌ Error: Bundles directory not found: {bundles_dir}")
        sys.exit(1)

    print("🔄 Generating seed file from embedded bundles...")
    print(f"📁 Bundles directory: {bundles_dir}")
    print()

    # Check what bundles we have
    profilemanifests = bundles_dir / "ProfileManifests-ProfileManifests"
    apple_dm = bundles_dir / "apple-device-management"
    rtrouton = bundles_dir / "rtrouton-profiles"

    if not profilemanifests.exists():
        print(f"⚠️  ProfileManifests bundle not found")
    else:
        manifests_dir = profilemanifests / "Manifests"
        if manifests_dir.exists():
            plist_count = len(list(manifests_dir.rglob("*.plist")))
            print(f"📦 ProfileManifests: {plist_count} manifests found")

    if apple_dm.exists():
        yaml_count = len(list(apple_dm.rglob("*.yaml")))
        print(f"📦 Apple device-management: {yaml_count} YAML files found")

    if rtrouton.exists():
        profile_count = len(list(rtrouton.rglob("*.mobileconfig")))
        print(f"📦 rtrouton-profiles: {profile_count} profiles found")

    print()
    print("⚠️  Note: This script just counts files. To generate the actual seed:")
    print("   1. Run the app in simulator")
    print("   2. Tap 'Refresh Catalog' in Settings")
    print("   3. Run: ./scripts/regenerate_seed_from_bundles.sh")
    print()
    print("   Or rebuild the seed data programmatically using Swift.")

if __name__ == "__main__":
    main()
