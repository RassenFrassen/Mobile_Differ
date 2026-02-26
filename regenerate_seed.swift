#!/usr/bin/env swift

import Foundation

// This script regenerates the MDM catalog seed by running the data ingestion
// To use: swift regenerate_seed.swift

print("🔄 Regenerating MDM Catalog Seed...")
print("📁 Working directory: \(FileManager.default.currentDirectoryPath)")

let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
task.arguments = [
    "simctl", "spawn", "booted",
    "open", "-a", "Differ"
]

do {
    try task.run()
    print("✅ App launched - please tap 'Refresh Catalog' in Settings")
} catch {
    print("❌ Failed to launch app: \(error)")
    print("\nAlternative: Run the app in Xcode and manually refresh")
}
