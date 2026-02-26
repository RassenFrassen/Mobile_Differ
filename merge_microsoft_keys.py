#!/usr/bin/env python3
"""
Merge Microsoft MDM keys into the existing seed file.
This script:
1. Updates payload sources to include "Microsoft"
2. Removes container keys for Microsoft Defender
3. Adds specific Microsoft keys
4. Updates source metadata
"""

import json
from datetime import datetime, timezone
from typing import Dict, List, Set

def load_files():
    """Load all required JSON files"""
    print("Loading files...")

    with open('/Users/mike/Documents/Github/Mobile_Differ/MDMKeys/Resources/mdm_catalog_seed.json', 'r') as f:
        seed = json.load(f)

    with open('/Users/mike/Documents/Github/Mobile_Differ/microsoft_formatted/microsoft_all_combined.json', 'r') as f:
        microsoft_data = json.load(f)

    print(f"✓ Seed: {len(seed['payloads'])} payloads, {len(seed['keys'])} keys")
    print(f"✓ Microsoft: {len(microsoft_data['payloads'])} payloads, {len(microsoft_data['keys'])} keys")

    return seed, microsoft_data

def identify_new_keys(microsoft_data: dict, seed: dict) -> Dict[str, Set[str]]:
    """Identify which keys are new (not in seed)"""
    print("\nIdentifying new keys...")

    # Build a set of existing key IDs in seed
    seed_key_ids = {k['id'] for k in seed['keys']}

    # Find new keys by payload
    new_keys_by_payload = {}

    for ms_key in microsoft_data['keys']:
        payload_type = ms_key['payloadType']
        key_id = ms_key['id']

        if key_id not in seed_key_ids:
            if payload_type not in new_keys_by_payload:
                new_keys_by_payload[payload_type] = set()
            new_keys_by_payload[payload_type].add(ms_key['key'])

    # Print summary
    total_new = sum(len(keys) for keys in new_keys_by_payload.values())
    print(f"✓ Found {total_new} new keys across {len(new_keys_by_payload)} payloads")

    for payload_type, keys in new_keys_by_payload.items():
        print(f"  - {payload_type}: {len(keys)} new keys")

    return new_keys_by_payload

def update_payloads(seed: dict, microsoft_data: dict, new_keys_by_payload: Dict[str, Set[str]]):
    """Update payload metadata to include Microsoft source"""
    print("\nUpdating payload sources...")

    updated_count = 0

    # Get set of payloads that have new keys
    payloads_to_update = set(new_keys_by_payload.keys())

    for payload in seed['payloads']:
        payload_type = payload['id']

        if payload_type in payloads_to_update:
            if 'Microsoft' not in payload['sources']:
                payload['sources'].append('Microsoft')
                updated_count += 1

                # Update summary if Microsoft data has one
                ms_payload = next((p for p in microsoft_data['payloads'] if p['id'] == payload_type), None)
                if ms_payload:
                    # Keep the longer/better summary
                    if len(ms_payload.get('summary', '')) > len(payload.get('summary', '')):
                        payload['summary'] = ms_payload['summary']

                    # Add source documentation if present
                    if 'sourceDocumentation' in ms_payload:
                        payload['sourceDocumentation'] = ms_payload['sourceDocumentation']

    print(f"✓ Updated {updated_count} payloads to include Microsoft source")
    return updated_count

def remove_defender_containers(seed: dict) -> int:
    """Remove the 10 container keys for Microsoft Defender"""
    print("\nRemoving Microsoft Defender container keys...")

    container_keys = [
        'antivirusEngine', 'cloudService', 'userInterface', 'edr',
        'tamperProtection', 'deviceControl', 'features', 'networkProtection',
        'dlp', 'scheduledScan'
    ]

    original_count = len(seed['keys'])

    # Filter out container keys for Microsoft Defender
    seed['keys'] = [
        k for k in seed['keys']
        if not (k['payloadType'] == 'com.microsoft.wdav' and k['key'] in container_keys)
    ]

    removed = original_count - len(seed['keys'])
    print(f"✓ Removed {removed} container keys")

    return removed

def add_microsoft_keys(seed: dict, microsoft_data: dict, new_keys_by_payload: Dict[str, Set[str]]) -> int:
    """Add new Microsoft keys to the seed"""
    print("\nAdding new Microsoft keys...")

    added_count = 0
    added_by_payload = {}

    for ms_key in microsoft_data['keys']:
        payload_type = ms_key['payloadType']
        key_name = ms_key['key']
        key_id = ms_key['id']

        # Check if this is a new key
        if payload_type in new_keys_by_payload and key_name in new_keys_by_payload[payload_type]:
            # Add the key
            seed['keys'].append(ms_key)
            added_count += 1

            # Track by payload
            if payload_type not in added_by_payload:
                added_by_payload[payload_type] = 0
            added_by_payload[payload_type] += 1

    print(f"✓ Added {added_count} new keys")
    for payload_type, count in sorted(added_by_payload.items()):
        payload_name = next((p['name'] for p in seed['payloads'] if p['id'] == payload_type), payload_type)
        print(f"  - {payload_name}: {count} keys")

    return added_count, added_by_payload

def add_source_metadata(seed: dict, total_new_keys: int):
    """Add Microsoft source metadata"""
    print("\nAdding Microsoft source metadata...")

    # Check if Microsoft source already exists
    existing_source = next((s for s in seed['sources'] if s['source'] == 'Microsoft'), None)

    if existing_source:
        # Update existing
        existing_source['itemCount'] = total_new_keys
        existing_source['revision'] = datetime.now(timezone.utc).isoformat()
        existing_source['fetchedAt'] = datetime.now(timezone.utc).isoformat()
        print("✓ Updated existing Microsoft source metadata")
    else:
        # Add new source
        microsoft_source = {
            "source": "Microsoft",
            "itemCount": total_new_keys,
            "repoURL": "https://learn.microsoft.com/en-us/mem/intune/",
            "licenseName": "Microsoft Documentation",
            "revision": datetime.now(timezone.utc).isoformat(),
            "fetchedAt": datetime.now(timezone.utc).isoformat()
        }
        seed['sources'].append(microsoft_source)
        print("✓ Added Microsoft source metadata")

def update_metadata(seed: dict):
    """Update schema version and generatedAt timestamp"""
    print("\nUpdating metadata...")

    seed['generatedAt'] = datetime.now(timezone.utc).isoformat()
    print(f"✓ Updated generatedAt: {seed['generatedAt']}")

def save_seed(seed: dict, output_path: str):
    """Save the merged seed file"""
    print(f"\nSaving to {output_path}...")

    with open(output_path, 'w') as f:
        json.dump(seed, f, indent=2)

    print("✓ File saved successfully")

def validate_json(file_path: str) -> bool:
    """Validate that the JSON is well-formed"""
    print("\nValidating JSON...")

    try:
        with open(file_path, 'r') as f:
            json.load(f)
        print("✓ JSON is well-formed")
        return True
    except json.JSONDecodeError as e:
        print(f"✗ JSON validation failed: {e}")
        return False

def generate_summary(seed: dict, added_by_payload: dict, total_new_keys: int):
    """Generate summary report"""
    print("\n" + "="*80)
    print("MERGE SUMMARY")
    print("="*80)

    print(f"\nTotal Keys Added: {total_new_keys}")
    print(f"\nKeys Added by Payload:")

    for payload_type, count in sorted(added_by_payload.items()):
        payload_name = next((p['name'] for p in seed['payloads'] if p['id'] == payload_type), payload_type)
        print(f"  • {payload_name}: {count} keys")

    print(f"\nTotal Payloads in Seed: {len(seed['payloads'])}")
    print(f"Total Keys in Seed: {len(seed['keys'])}")

    print(f"\nSource Metadata:")
    for source in seed['sources']:
        print(f"  • {source['source']}: {source['itemCount']} items")

    print("\n" + "="*80)

def main():
    """Main execution"""
    print("="*80)
    print("Microsoft MDM Keys Merge Script")
    print("="*80)

    # Step 1: Load files
    seed, microsoft_data = load_files()

    # Step 2: Identify new keys
    new_keys_by_payload = identify_new_keys(microsoft_data, seed)

    # Step 3: Update payloads
    update_payloads(seed, microsoft_data, new_keys_by_payload)

    # Step 4: Remove Microsoft Defender container keys
    remove_defender_containers(seed)

    # Step 5: Add new Microsoft keys
    total_new_keys, added_by_payload = add_microsoft_keys(seed, microsoft_data, new_keys_by_payload)

    # Step 6: Add source metadata
    add_source_metadata(seed, total_new_keys)

    # Step 7: Update metadata
    update_metadata(seed)

    # Step 8: Save file
    output_path = '/Users/mike/Documents/Github/Mobile_Differ/MDMKeys/Resources/mdm_catalog_seed.json'
    save_seed(seed, output_path)

    # Step 9: Validate
    if validate_json(output_path):
        # Step 10: Generate summary
        generate_summary(seed, added_by_payload, total_new_keys)
    else:
        print("\n⚠️  JSON validation failed! Please check the output file.")
        return 1

    print("\n✓ Merge completed successfully!")
    return 0

if __name__ == '__main__':
    exit(main())
