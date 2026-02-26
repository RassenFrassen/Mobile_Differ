#!/usr/bin/env python3
"""
Process Microsoft MDM sources and create formatted JSON payloads for MDM catalog seed.
"""

import json
import os
from typing import Dict, List, Any

# Base directory paths
BASE_DIR = "/Users/mike/Documents/Github/Mobile_Differ"
JSON_REF_DIR = f"{BASE_DIR}/microsoft_ios_apple_settings_json_reference"
PLIST_DIR = f"{BASE_DIR}/microsoft_apple_managed_prefs_plists"
OUTPUT_DIR = f"{BASE_DIR}/microsoft_formatted"
SEED_FILE = f"{BASE_DIR}/MDMKeys/Resources/mdm_catalog_seed.json"


def map_type_to_value_type(type_str: str) -> str:
    """Map Microsoft type strings to MDM catalog valueType format."""
    type_mapping = {
        "bool": "boolean",
        "boolean": "boolean",
        "string": "string",
        "int": "integer",
        "integer": "integer",
        "number": "integer",
        "array": "array",
        "array[string]": "array",
        "dict": "dictionary",
        "object": "dictionary",
    }

    for key, value in type_mapping.items():
        if key in type_str.lower():
            return value

    return "string"  # Default fallback


def create_payload_entry(payload_type: str, name: str, summary: str) -> Dict[str, Any]:
    """Create a payload entry for the application."""
    return {
        "id": payload_type,
        "payloadType": payload_type,
        "name": name,
        "category": "Other",
        "platforms": ["macOS"],
        "summary": summary,
        "discussion": "",
        "isDeprecated": False,
        "sources": ["Microsoft"]
    }


def create_key_entry(
    payload_type: str,
    payload_name: str,
    key_name: str,
    description: str,
    value_type: str,
    default_value: Any = None,
    enum_values: List[str] = None,
    min_value: Any = None,
    max_value: Any = None
) -> Dict[str, Any]:
    """Create a key entry for the MDM catalog."""
    entry = {
        "id": f"{payload_type}.{key_name}",
        "key": key_name,
        "keyPath": key_name,
        "payloadType": payload_type,
        "payloadName": payload_name,
        "keyDescription": description,
        "valueType": value_type,
        "platforms": ["macOS"],
        "sources": ["Microsoft"]
    }

    if default_value is not None:
        entry["defaultValue"] = default_value

    if enum_values:
        entry["allowedValues"] = enum_values

    if min_value is not None:
        entry["minValue"] = min_value

    if max_value is not None:
        entry["maxValue"] = max_value

    return entry


def process_wdav_schema() -> Dict[str, Any]:
    """Process com.microsoft.wdav schema.json file."""
    schema_file = f"{JSON_REF_DIR}/com.microsoft.wdav.schema.json"

    with open(schema_file, 'r') as f:
        schema = json.load(f)

    payload_type = "com.microsoft.wdav"
    payload_name = "Microsoft Defender for Endpoint"

    payload_entry = create_payload_entry(
        payload_type,
        payload_name,
        "Microsoft Defender for Endpoint (MDE) antivirus, EDR, and security settings"
    )

    keys = []

    # Process top-level properties
    if "properties" in schema:
        for section_name, section_data in schema["properties"].items():
            if "properties" in section_data:
                # Process nested properties
                for key_name, key_data in section_data["properties"].items():
                    full_key = f"{section_name}.{key_name}"
                    description = key_data.get("description", key_data.get("title", ""))

                    # Determine value type
                    json_type = key_data.get("type", "string")
                    value_type = map_type_to_value_type(json_type)

                    # Get default value
                    default_value = key_data.get("default")

                    # Get enum values
                    enum_values = key_data.get("enum")

                    # Get min/max for numbers
                    min_value = key_data.get("minimum")
                    max_value = key_data.get("maximum")

                    key_entry = create_key_entry(
                        payload_type,
                        payload_name,
                        full_key,
                        description,
                        value_type,
                        default_value,
                        enum_values,
                        min_value,
                        max_value
                    )

                    keys.append(key_entry)

    return {
        "payload": payload_entry,
        "keys": keys
    }


def process_simple_app(
    domain: str,
    name: str,
    summary: str,
    keys_data: List[Dict[str, str]],
    source_docs: List[str] = None
) -> Dict[str, Any]:
    """Process a simple app with key reference list."""
    payload_entry = create_payload_entry(domain, name, summary)

    if source_docs:
        payload_entry["sourceDocumentation"] = source_docs

    keys = []

    for key_info in keys_data:
        key_name = key_info["key"]
        key_type = key_info.get("type", "string")
        value_type = map_type_to_value_type(key_type)

        # Generate description from key name if not provided
        description = key_info.get("description", f"Configure {key_name} setting")

        key_entry = create_key_entry(
            domain,
            name,
            key_name,
            description,
            value_type
        )

        keys.append(key_entry)

    return {
        "payload": payload_entry,
        "keys": keys
    }


def process_onedrive() -> Dict[str, Any]:
    """Process com.microsoft.OneDrive."""
    ref_file = f"{JSON_REF_DIR}/com.microsoft.OneDrive.keys.reference.json"

    with open(ref_file, 'r') as f:
        ref_data = json.load(f)

    # Add descriptions from documentation
    key_descriptions = {
        "DisablePersonalSync": "Prevents users from adding or syncing personal OneDrive accounts",
        "AllowTenantList": "List of allowed tenant IDs (GUIDs) for OneDrive sync",
        "BlockTenantList": "List of blocked tenant IDs (GUIDs) for OneDrive sync",
        "BlockExternalSync": "Prevent sync of external SharePoint libraries from other organizations",
        "DefaultFolder": "Default OneDrive folder location and tenant configuration",
        "DisableAutoConfig": "Disable automatic sign-in using existing Azure AD credentials (set to 1 to disable)",
        "KFMOptInWithWizard": "Tenant ID to enable Known Folder Move with user wizard",
        "KFMSilentOptIn": "Tenant ID to silently enable Known Folder Move without user interaction",
        "KFMSilentOptInWithNotification": "Show notification when silently enabling Known Folder Move",
        "KFMSilentOptInDesktop": "Include Desktop folder in Known Folder Move",
        "KFMSilentOptInDocuments": "Include Documents folder in Known Folder Move",
        "KFMBlockOptOut": "Prevent users from opting out of Known Folder Move",
        "MinDiskSpaceLimitInMB": "Minimum free disk space in MB before blocking downloads"
    }

    keys_with_desc = []
    for key_info in ref_data["keys"]:
        key_name = key_info["key"]
        key_info["description"] = key_descriptions.get(key_name, f"Configure {key_name} setting")
        keys_with_desc.append(key_info)

    return process_simple_app(
        "com.microsoft.OneDrive",
        "Microsoft OneDrive",
        "Microsoft OneDrive sync client settings for macOS including Known Folder Move",
        keys_with_desc,
        ref_data.get("source_docs", [])
    )


def process_outlook() -> Dict[str, Any]:
    """Process com.microsoft.Outlook."""
    ref_file = f"{JSON_REF_DIR}/com.microsoft.Outlook.keys.reference.json"

    with open(ref_file, 'r') as f:
        ref_data = json.load(f)

    # Add descriptions from documentation
    key_descriptions = {
        "DefaultEmailAddressOrDomain": "Pre-fill default email address or domain for account setup",
        "AllowedEmailDomains": "List of allowed email domains for adding accounts",
        "DisallowedEmailDomains": "List of disallowed email domains for adding accounts",
        "DisableImport": "Prevent users from importing data into Outlook",
        "DisableExport": "Prevent users from exporting data from Outlook",
        "DisableTeamsMeeting": "Disable Teams meeting integration in Outlook",
        "DisableBasic": "Disable Basic authentication for Exchange accounts"
    }

    keys_with_desc = []
    for key_info in ref_data["keys"]:
        key_name = key_info["key"]
        key_info["description"] = key_descriptions.get(key_name, f"Configure {key_name} setting")
        keys_with_desc.append(key_info)

    return process_simple_app(
        "com.microsoft.Outlook",
        "Microsoft Outlook",
        "Microsoft Outlook for Mac email client settings",
        keys_with_desc,
        ref_data.get("source_docs", [])
    )


def process_autoupdate2() -> Dict[str, Any]:
    """Process com.microsoft.autoupdate2 (MAU)."""
    ref_file = f"{JSON_REF_DIR}/com.microsoft.autoupdate2.keys.reference.json"

    with open(ref_file, 'r') as f:
        ref_data = json.load(f)

    # Add descriptions from documentation
    key_descriptions = {
        "ChannelName": "Update channel (Current, Preview, Beta) for Microsoft apps",
        "HowToCheck": "Update check behavior (Manual, AutomaticDownload, AutomaticDownloadAndInstall)",
        "UpdateDeadline.DaysBeforeForcedQuit": "Number of days before forcing app quit to install updates",
        "AcknowledgedDataCollectionPolicy": "User acknowledgment of data collection policy"
    }

    keys_with_desc = []
    for key_info in ref_data["keys"]:
        key_name = key_info["key"]
        key_info["description"] = key_descriptions.get(key_name, f"Configure {key_name} setting")
        keys_with_desc.append(key_info)

    return process_simple_app(
        "com.microsoft.autoupdate2",
        "Microsoft AutoUpdate (MAU)",
        "Microsoft AutoUpdate settings for managing Office app updates",
        keys_with_desc,
        ref_data.get("source_docs", [])
    )


def process_office() -> Dict[str, Any]:
    """Process com.microsoft.office."""
    ref_file = f"{JSON_REF_DIR}/com.microsoft.office.keys.reference.json"

    with open(ref_file, 'r') as f:
        ref_data = json.load(f)

    # Add descriptions from documentation
    key_descriptions = {
        "OfficeAutoSignIn": "Automatically sign in users to Office apps using system credentials",
        "OfficeActivationEmailAddress": "Pre-fill email address for Office activation",
        "ShowWhatsNewOnLaunch": "Show What's New dialog when launching Office apps",
        "ShowDocStageOnLaunch": "Show template gallery when launching Word, Excel, or PowerPoint",
        "DefaultsToLocalOpenSave": "Default to local file system in Open/Save dialogs",
        "DisableCloudFonts": "Disable cloud-based fonts in Office applications"
    }

    keys_with_desc = []
    for key_info in ref_data["keys"]:
        key_name = key_info["key"]
        key_info["description"] = key_descriptions.get(key_name, f"Configure {key_name} setting")
        keys_with_desc.append(key_info)

    return process_simple_app(
        "com.microsoft.office",
        "Microsoft Office",
        "Microsoft Office suite-wide settings for Mac",
        keys_with_desc,
        ref_data.get("source_docs", [])
    )


def process_edge() -> Dict[str, Any]:
    """Process com.microsoft.Edge."""
    # Edge doesn't have a key reference, so we'll use common keys from plist
    edge_keys = [
        {"key": "RestoreOnStartup", "type": "int", "description": "Action on startup (1=Restore last session, 4=Open list of URLs, 5=Open New Tab)"},
        {"key": "RestoreOnStartupURLs", "type": "array[string]", "description": "URLs to open on startup when RestoreOnStartup is set to 4"},
        {"key": "HomepageLocation", "type": "string", "description": "Home button URL"},
        {"key": "ExtensionInstallForcelist", "type": "array[string]", "description": "Force-install Edge extensions (format: extension_id;update_url)"}
    ]

    source_docs = [
        "https://learn.microsoft.com/en-us/deployedge/configure-microsoft-edge-on-mac",
        "https://learn.microsoft.com/en-us/deployedge/microsoft-edge-policies"
    ]

    return process_simple_app(
        "com.microsoft.Edge",
        "Microsoft Edge",
        "Microsoft Edge browser settings for macOS",
        edge_keys,
        source_docs
    )


def check_existing_in_seed(payload_type: str) -> bool:
    """Check if a payload type already exists in the seed file."""
    try:
        # For large files, we'll use grep instead of loading the whole file
        import subprocess
        result = subprocess.run(
            ["grep", "-c", f'"payloadType": "{payload_type}"', SEED_FILE],
            capture_output=True,
            text=True
        )
        count = int(result.stdout.strip()) if result.stdout.strip() else 0
        return count > 0
    except:
        return False


def main():
    """Main processing function."""
    print("Processing Microsoft MDM sources...\n")

    processors = {
        "com.microsoft.wdav": ("Microsoft Defender for Endpoint", process_wdav_schema),
        "com.microsoft.OneDrive": ("Microsoft OneDrive", process_onedrive),
        "com.microsoft.Outlook": ("Microsoft Outlook", process_outlook),
        "com.microsoft.autoupdate2": ("Microsoft AutoUpdate", process_autoupdate2),
        "com.microsoft.office": ("Microsoft Office", process_office),
        "com.microsoft.Edge": ("Microsoft Edge", process_edge)
    }

    results = {}
    summary = {
        "total_apps": len(processors),
        "total_keys": 0,
        "existing_apps": [],
        "new_apps": [],
        "apps": {}
    }

    for payload_type, (app_name, processor_func) in processors.items():
        print(f"Processing {app_name} ({payload_type})...")

        # Check if exists in seed
        exists_in_seed = check_existing_in_seed(payload_type)

        # Process the app
        result = processor_func()
        results[payload_type] = result

        num_keys = len(result["keys"])
        summary["total_keys"] += num_keys

        app_info = {
            "name": app_name,
            "payload_type": payload_type,
            "num_keys": num_keys,
            "exists_in_seed": exists_in_seed
        }

        summary["apps"][payload_type] = app_info

        if exists_in_seed:
            summary["existing_apps"].append(payload_type)
            print(f"  ✓ Found in seed - {num_keys} keys extracted")
        else:
            summary["new_apps"].append(payload_type)
            print(f"  ★ NEW - {num_keys} keys extracted")

        # Write individual app file
        output_file = f"{OUTPUT_DIR}/{payload_type}.json"
        output_data = {
            "payload": result["payload"],
            "keys": result["keys"]
        }

        with open(output_file, 'w') as f:
            json.dump(output_data, f, indent=2)

        print(f"  → Saved to {output_file}\n")

    # Write summary file
    summary_file = f"{OUTPUT_DIR}/SUMMARY.json"
    with open(summary_file, 'w') as f:
        json.dump(summary, f, indent=2)

    # Write combined file
    combined_file = f"{OUTPUT_DIR}/microsoft_all_combined.json"
    combined_data = {
        "payloads": [],
        "keys": []
    }

    for payload_type, result in results.items():
        combined_data["payloads"].append(result["payload"])
        combined_data["keys"].extend(result["keys"])

    with open(combined_file, 'w') as f:
        json.dump(combined_data, f, indent=2)

    print("\n" + "="*70)
    print("SUMMARY")
    print("="*70)
    print(f"Total applications processed: {summary['total_apps']}")
    print(f"Total keys extracted: {summary['total_keys']}")
    print(f"\nExisting in seed ({len(summary['existing_apps'])}):")
    for app in summary["existing_apps"]:
        info = summary["apps"][app]
        print(f"  - {info['name']} ({app}): {info['num_keys']} keys")

    print(f"\nNEW applications ({len(summary['new_apps'])}):")
    for app in summary["new_apps"]:
        info = summary["apps"][app]
        print(f"  ★ {info['name']} ({app}): {info['num_keys']} keys")

    print(f"\nOutput files:")
    print(f"  - Individual app files: {OUTPUT_DIR}/com.microsoft.*.json")
    print(f"  - Combined file: {combined_file}")
    print(f"  - Summary: {summary_file}")
    print("\n" + "="*70)


if __name__ == "__main__":
    main()
