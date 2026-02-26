#!/usr/bin/env python3
"""
Generate a complete mdm_catalog_seed.json from embedded bundles.
This bypasses the need to run the app.
"""

import json
import plistlib
import yaml
from pathlib import Path
from datetime import datetime, timezone
from collections import defaultdict

def parse_profilemanifests(bundle_path):
    """Parse ProfileManifests plists"""
    keys = []
    payloads = []

    manifests_dir = bundle_path / "Manifests"
    if not manifests_dir.exists():
        return keys, payloads

    plist_files = list(manifests_dir.rglob("*.plist"))
    print(f"   Parsing {len(plist_files)} ProfileManifests files...")

    for plist_file in plist_files:
        try:
            with open(plist_file, 'rb') as f:
                data = plistlib.load(f)

            # Extract payload info
            payload_type = data.get('pfm_domain', '')
            if payload_type:
                payload = {
                    'id': payload_type,
                    'payloadType': payload_type,
                    'name': data.get('pfm_title', ''),
                    'category': data.get('pfm_category', 'Other'),
                    'platforms': data.get('pfm_platforms', []),
                    'summary': data.get('pfm_description', ''),
                    'discussion': data.get('pfm_note', ''),
                    'isDeprecated': data.get('pfm_deprecated', False),
                    'sources': ['ProfileCreator']
                }
                payloads.append(payload)

                # Extract keys
                if 'pfm_subkeys' in data:
                    for key_data in data['pfm_subkeys']:
                        key_name = key_data.get('pfm_name', '')
                        if key_name:
                            key = {
                                'id': f"{payload_type}.{key_name}",
                                'key': key_name,
                                'keyPath': key_name,
                                'payloadType': payload_type,
                                'payloadName': payload['name'],
                                'keyDescription': key_data.get('pfm_description', ''),
                                'valueType': key_data.get('pfm_type', 'string'),
                                'platforms': payload['platforms'],
                                'sources': ['ProfileCreator']
                            }
                            keys.append(key)
        except Exception as e:
            print(f"     ⚠️  Error parsing {plist_file.name}: {e}")
            continue

    return keys, payloads

def parse_apple_device_management(bundle_path):
    """Parse Apple device-management YAML files"""
    keys = []
    payloads = []

    mdm_dir = bundle_path / "mdm" / "profiles"
    if not mdm_dir.exists():
        return keys, payloads

    yaml_files = list(mdm_dir.rglob("*.yaml"))
    print(f"   Parsing {len(yaml_files)} Apple device-management files...")

    for yaml_file in yaml_files:
        try:
            with open(yaml_file, 'r') as f:
                data = yaml.safe_load(f)

            if not data or 'payload' not in data:
                continue

            payload_data = data['payload']
            payload_type = payload_data.get('payloadtype', '')

            if payload_type:
                # Extract platforms from supportedOS
                supported_os = payload_data.get('supportedOS', {})
                platforms = list(supported_os.keys()) if isinstance(supported_os, dict) else []

                payload = {
                    'id': payload_type,
                    'payloadType': payload_type,
                    'name': payload_data.get('payloadtype', ''),
                    'category': 'Apple',
                    'platforms': platforms,
                    'summary': payload_data.get('summary', ''),
                    'discussion': '',
                    'isDeprecated': False,
                    'sources': ['Apple device-management']
                }
                payloads.append(payload)

                # Extract keys
                if 'payloadkeys' in data:
                    for key_data in data['payloadkeys']:
                        key_name = key_data.get('key', '')
                        if key_name:
                            key = {
                                'id': f"{payload_type}.{key_name}",
                                'key': key_name,
                                'keyPath': key_name,
                                'payloadType': payload_type,
                                'payloadName': payload['name'],
                                'keyDescription': key_data.get('title', ''),
                                'valueType': key_data.get('type', 'string'),
                                'platforms': list(payload['platforms']),
                                'sources': ['Apple device-management']
                            }
                            keys.append(key)
        except Exception as e:
            print(f"     ⚠️  Error parsing {yaml_file.name}: {e}")
            continue

    return keys, payloads

def parse_rtrouton_profiles(bundle_path):
    """Parse rtrouton-profiles mobileconfig files"""
    keys = []
    payloads = []

    profile_dirs = list(bundle_path.glob("*"))
    mobileconfig_files = []
    for d in profile_dirs:
        if d.is_dir():
            mobileconfig_files.extend(d.glob("*.mobileconfig"))

    print(f"   Parsing {len(mobileconfig_files)} rtrouton-profiles files...")

    for profile_file in mobileconfig_files:
        try:
            with open(profile_file, 'rb') as f:
                data = plistlib.load(f)

            # Extract payload content
            if 'PayloadContent' in data and isinstance(data['PayloadContent'], list):
                for payload_data in data['PayloadContent']:
                    payload_type = payload_data.get('PayloadType', '')
                    if payload_type:
                        payload_id = f"{payload_type}.{profile_file.stem}"
                        payload = {
                            'id': payload_id,
                            'payloadType': payload_type,
                            'name': payload_data.get('PayloadDisplayName', payload_type),
                            'category': 'Configuration',
                            'platforms': ['macOS'],
                            'summary': data.get('PayloadDescription', ''),
                            'discussion': '',
                            'isDeprecated': False,
                            'sources': ['rtrouton/profiles']
                        }
                        payloads.append(payload)

                        # Extract keys from payload
                        for key_name in payload_data.keys():
                            if not key_name.startswith('Payload'):
                                key = {
                                    'id': f"{payload_id}.{key_name}",
                                    'key': key_name,
                                    'keyPath': key_name,
                                    'payloadType': payload_type,
                                    'payloadName': payload['name'],
                                    'keyDescription': '',
                                    'valueType': type(payload_data[key_name]).__name__,
                                    'platforms': ['macOS'],
                                    'sources': ['rtrouton/profiles']
                                }
                                keys.append(key)
        except Exception as e:
            print(f"     ⚠️  Error parsing {profile_file.name}: {e}")
            continue

    return keys, payloads

def merge_duplicates(items, id_key='id'):
    """Merge duplicate items and combine sources"""
    merged = {}
    for item in items:
        item_id = item[id_key]
        if item_id in merged:
            # Merge sources
            existing_sources = set(merged[item_id]['sources'])
            new_sources = set(item['sources'])
            merged[item_id]['sources'] = sorted(list(existing_sources | new_sources))
        else:
            merged[item_id] = item
    return list(merged.values())

def main():
    project_root = Path(__file__).parent.parent
    bundles_dir = project_root / "MDMKeys" / "Resources 2" / "EmbeddedBundles"
    seed_path = project_root / "MDMKeys" / "Resources" / "mdm_catalog_seed.json"

    print("")
    print("=" * 60)
    print("🔄 Generating Complete Seed File from Embedded Bundles")
    print("=" * 60)
    print("")

    if not bundles_dir.exists():
        print(f"❌ Error: Bundles directory not found: {bundles_dir}")
        return 1

    all_keys = []
    all_payloads = []
    sources_info = []

    # Parse ProfileManifests
    pm_path = bundles_dir / "ProfileManifests-ProfileManifests"
    if pm_path.exists():
        print("📦 Processing ProfileManifests-ProfileManifests...")
        keys, payloads = parse_profilemanifests(pm_path)
        all_keys.extend(keys)
        all_payloads.extend(payloads)
        sources_info.append({
            'source': 'ProfileCreator',
            'itemCount': len(keys),
            'repoURL': 'https://github.com/ProfileCreator/ProfileCreator',
            'licenseName': 'MIT',
            'licenseURL': 'https://github.com/ProfileCreator/ProfileCreator/blob/master/LICENSE',
            'revision': datetime.now(timezone.utc).isoformat(),
            'fetchedAt': datetime.now(timezone.utc).isoformat()
        })
        print(f"   ✅ {len(payloads)} payloads, {len(keys)} keys")
        print("")

    # Parse Apple device-management
    apple_path = bundles_dir / "apple-device-management"
    if apple_path.exists():
        print("📦 Processing apple-device-management...")
        keys, payloads = parse_apple_device_management(apple_path)
        all_keys.extend(keys)
        all_payloads.extend(payloads)
        sources_info.append({
            'source': 'Apple device-management',
            'itemCount': len(keys),
            'repoURL': 'https://github.com/apple/device-management',
            'licenseName': 'MIT',
            'licenseURL': 'https://github.com/apple/device-management/blob/release/LICENSE',
            'revision': datetime.now(timezone.utc).isoformat(),
            'fetchedAt': datetime.now(timezone.utc).isoformat()
        })
        print(f"   ✅ {len(payloads)} payloads, {len(keys)} keys")
        print("")

    # Parse rtrouton-profiles
    rtrouton_path = bundles_dir / "rtrouton-profiles"
    if rtrouton_path.exists():
        print("📦 Processing rtrouton-profiles...")
        keys, payloads = parse_rtrouton_profiles(rtrouton_path)
        all_keys.extend(keys)
        all_payloads.extend(payloads)
        sources_info.append({
            'source': 'rtrouton/profiles',
            'itemCount': len(keys),
            'repoURL': 'https://github.com/rtrouton/profiles',
            'licenseName': 'MIT',
            'licenseURL': 'https://github.com/rtrouton/profiles/blob/main/LICENSE',
            'revision': datetime.now(timezone.utc).isoformat(),
            'fetchedAt': datetime.now(timezone.utc).isoformat()
        })
        print(f"   ✅ {len(payloads)} payloads, {len(keys)} keys")
        print("")

    # Merge duplicates
    print("🔗 Merging duplicates and combining sources...")
    all_keys = merge_duplicates(all_keys, 'id')
    all_payloads = merge_duplicates(all_payloads, 'id')
    print(f"   ✅ {len(all_payloads)} unique payloads, {len(all_keys)} unique keys")
    print("")

    # Generate seed file
    seed_data = {
        'schemaVersion': 1,
        'generatedAt': datetime.now(timezone.utc).isoformat(),
        'sources': sources_info,
        'payloads': all_payloads,
        'keys': all_keys
    }

    # Backup existing seed
    if seed_path.exists():
        backup_path = seed_path.with_suffix('.json.backup')
        print(f"💾 Backing up existing seed to: {backup_path.name}")
        import shutil
        shutil.copy(seed_path, backup_path)

    # Write new seed
    print(f"📝 Writing new seed file to: {seed_path}")
    with open(seed_path, 'w') as f:
        json.dump(seed_data, f, indent=2, ensure_ascii=False)

    print("")
    print("=" * 60)
    print("✅ Seed file generated successfully!")
    print("=" * 60)
    print(f"📊 Total payloads: {len(all_payloads)}")
    print(f"📊 Total keys: {len(all_keys)}")
    print(f"📊 Sources: {len(sources_info)}")
    print("")

    return 0

if __name__ == '__main__':
    try:
        import yaml
    except ImportError:
        print("❌ Error: PyYAML is required")
        print("   Install with: pip3 install pyyaml")
        exit(1)

    exit(main())
