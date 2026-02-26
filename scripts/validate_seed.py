#!/usr/bin/env python3
"""
Validate mdm_catalog_seed.json schema and content.

Checks:
- Valid JSON structure
- Required fields present
- Source licenses present
- No unlicensed sources
- Schema version matches expected
- Data integrity
"""

import json
import sys
from pathlib import Path

# Approved licensed sources
APPROVED_SOURCES = {
    "Apple device-management",
    "Apple Developer Documentation",
    "ProfileManifests",
    "ProfileCreator",
    "rtrouton/profiles"
}

# Required root-level fields
REQUIRED_ROOT_FIELDS = {
    "schemaVersion",
    "generatedAt",
    "sources",
    "payloads",
    "keys"
}

# Required source snapshot fields
REQUIRED_SOURCE_FIELDS = {
    "source",
    "repoURL",
    "fetchedAt",
    "itemCount"
}

# Required payload fields
REQUIRED_PAYLOAD_FIELDS = {
    "id",
    "name",
    "payloadType",
    "platforms",
    "sources"
}

# Required key fields
REQUIRED_KEY_FIELDS = {
    "id",
    "key",
    "keyPath",
    "payloadType",
    "platforms",
    "sources"
}

def validate_seed(seed_path: Path) -> bool:
    """Validate the seed file. Returns True if valid, False otherwise."""

    errors = []
    warnings = []

    print(f"📦 Validating seed file: {seed_path}")
    print()

    # Load and parse JSON
    try:
        with open(seed_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except json.JSONDecodeError as e:
        errors.append(f"Invalid JSON: {e}")
        print_results(errors, warnings)
        return False
    except FileNotFoundError:
        errors.append(f"Seed file not found: {seed_path}")
        print_results(errors, warnings)
        return False

    # Check root structure
    missing_root = REQUIRED_ROOT_FIELDS - set(data.keys())
    if missing_root:
        errors.append(f"Missing required root fields: {missing_root}")

    # Validate schema version
    schema_version = data.get("schemaVersion")
    if schema_version != 1:
        warnings.append(f"Unexpected schema version: {schema_version} (expected 1)")

    # Validate sources
    sources = data.get("sources", [])
    if not sources:
        errors.append("No sources found in seed file")

    for idx, source in enumerate(sources):
        source_name = source.get("source", f"<unknown-{idx}>")

        # Check required fields
        missing_fields = REQUIRED_SOURCE_FIELDS - set(source.keys())
        if missing_fields:
            errors.append(f"Source '{source_name}' missing fields: {missing_fields}")

        # Check if source is approved
        if source_name not in APPROVED_SOURCES:
            errors.append(f"Unapproved source found: '{source_name}'")

        # Check for license (Apple Developer Documentation can be null)
        license_name = source.get("licenseName")
        if license_name is None and source_name != "Apple Developer Documentation":
            errors.append(f"Source '{source_name}' has no license")
        elif license_name:
            print(f"  ✅ {source_name}: {license_name}")
        else:
            print(f"  ℹ️  {source_name}: Apple Terms of Service")

    # Validate payloads
    payloads = data.get("payloads", [])
    print(f"\n📄 Found {len(payloads)} payloads")

    for payload in payloads[:5]:  # Sample first 5
        missing_fields = REQUIRED_PAYLOAD_FIELDS - set(payload.keys())
        if missing_fields:
            errors.append(f"Payload '{payload.get('id', 'unknown')}' missing fields: {missing_fields}")

        # Check payload sources are approved
        payload_sources = payload.get("sources", [])
        for src in payload_sources:
            if src not in APPROVED_SOURCES:
                errors.append(f"Payload '{payload['id']}' references unapproved source: '{src}'")

    # Validate keys
    keys = data.get("keys", [])
    print(f"🔑 Found {len(keys)} keys")

    for key in keys[:5]:  # Sample first 5
        missing_fields = REQUIRED_KEY_FIELDS - set(key.keys())
        if missing_fields:
            errors.append(f"Key '{key.get('id', 'unknown')}' missing fields: {missing_fields}")

        # Check key sources are approved
        key_sources = key.get("sources", [])
        for src in key_sources:
            if src not in APPROVED_SOURCES:
                errors.append(f"Key '{key['id']}' references unapproved source: '{src}'")

    # Check for any unapproved source references
    print(f"\n🔍 Scanning for unlicensed sources...")
    all_source_refs = set()
    for payload in payloads:
        all_source_refs.update(payload.get("sources", []))
    for key in keys:
        all_source_refs.update(key.get("sources", []))

    unlicensed = all_source_refs - APPROVED_SOURCES
    if unlicensed:
        errors.append(f"Found unlicensed sources in data: {unlicensed}")

    # Print summary
    print_results(errors, warnings)

    return len(errors) == 0

def print_results(errors: list, warnings: list):
    """Print validation results."""
    print()
    print("=" * 60)

    if errors:
        print("❌ VALIDATION FAILED")
        print()
        for error in errors:
            print(f"  ❌ {error}")

    if warnings:
        print()
        for warning in warnings:
            print(f"  ⚠️  {warning}")

    if not errors and not warnings:
        print("✅ VALIDATION PASSED")
        print()
        print("  All checks passed!")

    print("=" * 60)

if __name__ == '__main__':
    # Find seed file
    repo_root = Path(__file__).parent.parent
    seed_path = repo_root / "MDMKeys" / "Resources" / "mdm_catalog_seed.json"

    if not validate_seed(seed_path):
        sys.exit(1)

    sys.exit(0)
