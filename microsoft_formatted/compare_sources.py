#!/usr/bin/env python3
"""
Compare Microsoft source data with existing MDM catalog seed to determine
if Microsoft sources add value or can be discarded.
"""

import json
from collections import defaultdict
from typing import Dict, List, Set, Tuple

# Microsoft payloads to analyze
MICROSOFT_PAYLOADS = [
    "com.microsoft.wdav",
    "com.microsoft.OneDrive",
    "com.microsoft.Outlook",
    "com.microsoft.office",
    "com.microsoft.autoupdate2",
    "com.microsoft.Edge"
]

def load_json(filepath: str) -> dict:
    """Load JSON file."""
    with open(filepath, 'r') as f:
        return json.load(f)

def extract_keys_by_payload(data: dict) -> Dict[str, List[dict]]:
    """Extract all keys grouped by payload type."""
    keys_by_payload = defaultdict(list)

    for key in data.get("keys", []):
        payload_type = key.get("payloadType")
        if payload_type:
            keys_by_payload[payload_type].append(key)

    return keys_by_payload

def get_key_names(keys: List[dict]) -> Set[str]:
    """Extract set of key names from key list."""
    return {k.get("key") or k.get("keyPath") for k in keys}

def compare_metadata(seed_key: dict, ms_key: dict) -> dict:
    """Compare metadata quality between seed and Microsoft keys."""
    differences = {
        "has_default_in_ms": False,
        "has_allowed_values_in_ms": False,
        "has_better_description_in_ms": False,
        "has_min_max_in_ms": False,
        "ms_has_more_metadata": False
    }

    # Check for default value
    seed_has_default = "defaultValue" in seed_key
    ms_has_default = "defaultValue" in ms_key
    differences["has_default_in_ms"] = ms_has_default and not seed_has_default

    # Check for allowed values / enums
    seed_has_allowed = "allowedValues" in seed_key
    ms_has_allowed = "allowedValues" in ms_key
    differences["has_allowed_values_in_ms"] = ms_has_allowed and not seed_has_allowed

    # Check for min/max values
    seed_has_minmax = "minValue" in seed_key or "maxValue" in seed_key
    ms_has_minmax = "minValue" in ms_key or "maxValue" in ms_key
    differences["has_min_max_in_ms"] = ms_has_minmax and not seed_has_minmax

    # Check description quality (longer is generally better)
    seed_desc = seed_key.get("keyDescription", "")
    ms_desc = ms_key.get("keyDescription", "")
    differences["has_better_description_in_ms"] = len(ms_desc) > len(seed_desc) + 20

    # Overall check: does MS have more metadata fields?
    seed_metadata_count = sum([
        "defaultValue" in seed_key,
        "allowedValues" in seed_key,
        "minValue" in seed_key,
        "maxValue" in seed_key,
        len(seed_key.get("keyDescription", "")) > 0
    ])

    ms_metadata_count = sum([
        "defaultValue" in ms_key,
        "allowedValues" in ms_key,
        "minValue" in ms_key,
        "maxValue" in ms_key,
        len(ms_key.get("keyDescription", "")) > 0
    ])

    differences["ms_has_more_metadata"] = ms_metadata_count > seed_metadata_count

    return differences

def analyze_payload(payload_type: str, seed_keys: List[dict], ms_keys: List[dict]) -> dict:
    """Perform detailed analysis for a single payload type."""

    # Get key names
    seed_key_names = get_key_names(seed_keys)
    ms_key_names = get_key_names(ms_keys)

    # Find differences
    keys_only_in_ms = ms_key_names - seed_key_names
    keys_only_in_seed = seed_key_names - seed_key_names
    keys_in_both = seed_key_names & ms_key_names

    # Create lookup dictionaries
    seed_lookup = {(k.get("key") or k.get("keyPath")): k for k in seed_keys}
    ms_lookup = {(k.get("key") or k.get("keyPath")): k for k in ms_keys}

    # Analyze metadata quality for keys in both
    enhanced_keys = []
    for key_name in keys_in_both:
        if key_name and key_name in seed_lookup and key_name in ms_lookup:
            seed_key = seed_lookup[key_name]
            ms_key = ms_lookup[key_name]

            metadata_diff = compare_metadata(seed_key, ms_key)
            if any(metadata_diff.values()):
                enhanced_keys.append({
                    "key": key_name,
                    "improvements": metadata_diff,
                    "seed_key": seed_key,
                    "ms_key": ms_key
                })

    # Get examples of new keys
    new_key_examples = []
    for key_name in list(keys_only_in_ms)[:5]:  # Get up to 5 examples
        if key_name in ms_lookup:
            new_key_examples.append(ms_lookup[key_name])

    return {
        "payload_type": payload_type,
        "seed_key_count": len(seed_keys),
        "ms_key_count": len(ms_keys),
        "keys_only_in_ms": list(keys_only_in_ms),
        "keys_only_in_seed": list(keys_only_in_seed),
        "keys_in_both": list(keys_in_both),
        "enhanced_keys": enhanced_keys,
        "new_key_examples": new_key_examples
    }

def generate_markdown_report(analysis_results: List[dict], seed_data: dict, ms_data: dict) -> str:
    """Generate detailed markdown comparison report."""

    report = []
    report.append("# Microsoft Source vs MDM Catalog Seed Comparison Report")
    report.append("")
    report.append(f"**Analysis Date:** {__import__('datetime').datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    report.append("")
    report.append("## Executive Summary")
    report.append("")

    # Calculate totals
    total_new_keys = 0
    total_enhanced_keys = 0
    total_seed_keys = 0
    total_ms_keys = 0

    for result in analysis_results:
        total_new_keys += len(result["keys_only_in_ms"])
        total_enhanced_keys += len(result["enhanced_keys"])
        total_seed_keys += result["seed_key_count"]
        total_ms_keys += result["ms_key_count"]

    report.append(f"- **Total keys in seed:** {total_seed_keys}")
    report.append(f"- **Total keys in Microsoft source:** {total_ms_keys}")
    report.append(f"- **NEW keys in Microsoft (not in seed):** {total_new_keys}")
    report.append(f"- **Keys with ENHANCED metadata:** {total_enhanced_keys}")
    report.append("")

    # Recommendation
    report.append("## Recommendation")
    report.append("")

    if total_new_keys == 0 and total_enhanced_keys == 0:
        report.append("**DISCARD** - The Microsoft source adds no new keys or enhanced metadata. All data is already present in the seed.")
        recommendation = "DISCARD"
    elif total_new_keys > 0 or total_enhanced_keys > 10:
        report.append(f"**KEEP** - The Microsoft source adds {total_new_keys} new keys and enhances metadata for {total_enhanced_keys} existing keys. This represents valuable additional information.")
        recommendation = "KEEP"
    else:
        report.append(f"**MARGINAL** - The Microsoft source adds {total_new_keys} new keys and enhances {total_enhanced_keys} keys. Review the details below to make a final decision.")
        recommendation = "MARGINAL"

    report.append("")
    report.append("---")
    report.append("")

    # Detailed payload-by-payload analysis
    report.append("## Detailed Payload Analysis")
    report.append("")

    for result in analysis_results:
        payload = result["payload_type"]
        report.append(f"### {payload}")
        report.append("")
        report.append(f"- **Keys in seed:** {result['seed_key_count']}")
        report.append(f"- **Keys in Microsoft:** {result['ms_key_count']}")
        report.append(f"- **NEW keys in Microsoft:** {len(result['keys_only_in_ms'])}")
        report.append(f"- **Enhanced keys:** {len(result['enhanced_keys'])}")
        report.append("")

        # List new keys
        if result["keys_only_in_ms"]:
            report.append("#### New Keys (in Microsoft, not in seed)")
            report.append("")
            for key in result["keys_only_in_ms"]:
                report.append(f"- `{key}`")
            report.append("")

            # Show examples with details
            if result["new_key_examples"]:
                report.append("**Example new keys with details:**")
                report.append("")
                for key_obj in result["new_key_examples"][:3]:  # Show up to 3
                    report.append(f"**`{key_obj.get('key', 'N/A')}`**")
                    report.append(f"- Type: `{key_obj.get('valueType', 'N/A')}`")
                    report.append(f"- Description: {key_obj.get('keyDescription', 'N/A')}")
                    if "defaultValue" in key_obj:
                        report.append(f"- Default: `{key_obj['defaultValue']}`")
                    if "allowedValues" in key_obj:
                        report.append(f"- Allowed: {key_obj['allowedValues']}")
                    report.append("")

        # Show enhanced keys
        if result["enhanced_keys"]:
            report.append("#### Enhanced Keys (better metadata in Microsoft)")
            report.append("")

            # Count types of enhancements
            default_improvements = sum(1 for k in result["enhanced_keys"] if k["improvements"]["has_default_in_ms"])
            allowed_improvements = sum(1 for k in result["enhanced_keys"] if k["improvements"]["has_allowed_values_in_ms"])
            minmax_improvements = sum(1 for k in result["enhanced_keys"] if k["improvements"]["has_min_max_in_ms"])
            desc_improvements = sum(1 for k in result["enhanced_keys"] if k["improvements"]["has_better_description_in_ms"])

            report.append(f"- Keys with new default values: {default_improvements}")
            report.append(f"- Keys with new allowed values: {allowed_improvements}")
            report.append(f"- Keys with new min/max constraints: {minmax_improvements}")
            report.append(f"- Keys with better descriptions: {desc_improvements}")
            report.append("")

            # Show examples
            report.append("**Examples of enhanced keys:**")
            report.append("")
            for enhanced in result["enhanced_keys"][:5]:  # Show up to 5 examples
                key_name = enhanced["key"]
                improvements = enhanced["improvements"]
                ms_key = enhanced["ms_key"]

                report.append(f"**`{key_name}`**")

                if improvements["has_default_in_ms"]:
                    report.append(f"- Microsoft adds default value: `{ms_key.get('defaultValue')}`")

                if improvements["has_allowed_values_in_ms"]:
                    report.append(f"- Microsoft adds allowed values: {ms_key.get('allowedValues')}")

                if improvements["has_min_max_in_ms"]:
                    min_val = ms_key.get('minValue', 'N/A')
                    max_val = ms_key.get('maxValue', 'N/A')
                    report.append(f"- Microsoft adds constraints: min={min_val}, max={max_val}")

                if improvements["has_better_description_in_ms"]:
                    report.append(f"- Microsoft has more detailed description ({len(ms_key.get('keyDescription', ''))} chars vs {len(enhanced['seed_key'].get('keyDescription', ''))} chars)")

                report.append("")

        report.append("---")
        report.append("")

    # Final summary
    report.append("## Conclusion")
    report.append("")

    if recommendation == "DISCARD":
        report.append("The Microsoft source data is **redundant**. All keys and metadata present in the Microsoft source are already available in the ProfileCreator seed. The Microsoft sources can be safely discarded without any loss of information.")
    elif recommendation == "KEEP":
        report.append("The Microsoft source data provides **significant value** beyond what's in the ProfileCreator seed. It includes:")
        report.append(f"1. {total_new_keys} completely new keys not present in the seed")
        report.append(f"2. Enhanced metadata (defaults, constraints, enums) for {total_enhanced_keys} existing keys")
        report.append("")
        report.append("**Recommendation: KEEP the Microsoft sources** and merge them with the ProfileCreator data to create a more comprehensive catalog.")
    else:
        report.append(f"The Microsoft source adds some value with {total_new_keys} new keys and {total_enhanced_keys} enhancements, but the benefit is marginal. Review the specific additions above to determine if they justify keeping the Microsoft source data.")

    return "\n".join(report)

def main():
    """Main comparison function."""

    print("Loading data files...")
    seed_path = "/Users/mike/Documents/Github/Mobile_Differ/MDMKeys/Resources/mdm_catalog_seed.json"
    ms_path = "/Users/mike/Documents/Github/Mobile_Differ/microsoft_formatted/microsoft_all_combined.json"

    seed_data = load_json(seed_path)
    ms_data = load_json(ms_path)

    print("Extracting keys by payload...")
    seed_keys_by_payload = extract_keys_by_payload(seed_data)
    ms_keys_by_payload = extract_keys_by_payload(ms_data)

    print("\nAnalyzing each Microsoft payload...")
    analysis_results = []

    for payload in MICROSOFT_PAYLOADS:
        print(f"  Analyzing {payload}...")
        seed_keys = seed_keys_by_payload.get(payload, [])
        ms_keys = ms_keys_by_payload.get(payload, [])

        result = analyze_payload(payload, seed_keys, ms_keys)
        analysis_results.append(result)

        # Print quick summary
        print(f"    Seed: {result['seed_key_count']} keys, MS: {result['ms_key_count']} keys")
        print(f"    New in MS: {len(result['keys_only_in_ms'])}, Enhanced: {len(result['enhanced_keys'])}")

    print("\nGenerating markdown report...")
    report = generate_markdown_report(analysis_results, seed_data, ms_data)

    output_path = "/Users/mike/Documents/Github/Mobile_Differ/microsoft_formatted/COMPARISON_REPORT.md"
    with open(output_path, 'w') as f:
        f.write(report)

    print(f"\nReport saved to: {output_path}")
    print("\nDone!")

if __name__ == "__main__":
    main()
