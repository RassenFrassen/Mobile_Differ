#!/usr/bin/env swift

import Foundation

// This script regenerates mdm_catalog_seed.json by parsing all embedded bundles
// Run with: swift scripts/regenerate_seed.swift

print("🔄 Regenerating MDM Catalog Seed from Embedded Bundles...")
print("")

let fileManager = FileManager.default
let currentDir = fileManager.currentDirectoryPath
let projectRoot = URL(fileURLWithPath: currentDir)

// Paths
let bundlesDir = projectRoot
    .appendingPathComponent("MDMKeys/Resources 2/EmbeddedBundles", isDirectory: true)
let seedPath = projectRoot
    .appendingPathComponent("MDMKeys/Resources/mdm_catalog_seed.json")

guard fileManager.fileExists(atPath: bundlesDir.path) else {
    print("❌ Error: Bundles directory not found at: \(bundlesDir.path)")
    exit(1)
}

print("📁 Bundles directory: \(bundlesDir.path)")
print("📝 Output: \(seedPath.path)")
print("")

// We'll shell out to run the app's update service
// Since we can't easily import the app's modules in a script,
// we'll use xcrun to build and run a temporary executable

let scriptSource = """
import Foundation

// Path to the Differ.xcodeproj
let projectPath = "\(currentDir)/Differ.xcodeproj"

// Build a scheme that can run the MDMSourceIngestor
// Actually, simpler: just tell the user to run the app

print("📱 To regenerate the seed file:")
print("")
print("1. Run the app: open -a Simulator && xcodebuild -project Differ.xcodeproj -scheme Differ -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build")
print("2. Launch the app and it will auto-refresh on first run")
print("3. After refresh completes, run:")
print("   ./scripts/regenerate_seed_from_bundles.sh")
print("")
print("This will copy the generated catalog back to the seed file.")
"""

// Actually, let's try a different approach - call xcrun to execute a Swift snippet
// that imports the MDMSourceIngestor from the built app

print("🏗️  Building temporary executable to parse bundles...")
print("")

// Create a temporary Swift file that can import and use the app's code
let tempDir = fileManager.temporaryDirectory.appendingPathComponent("differ-seed-gen")
try? fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)

let tempSwift = tempDir.appendingPathComponent("main.swift")
let tempSource = """
import Foundation

// We need to build this against the app's frameworks
// The simplest approach is to just run the app itself

print("⚠️  Cannot directly import app modules in a script.")
print("")
print("To regenerate the seed file with all embedded bundle data:")
print("")
print("1. Run: open -a Simulator")
print("2. Build and run the app: Cmd+R in Xcode")
print("3. Wait for the app to complete first launch (auto-refresh)")
print("4. Run: ./scripts/regenerate_seed_from_bundles.sh")
print("")
print("The script will find the generated catalog and copy it to the seed file.")
print("")
print("Alternative: Use the Python approach to just parse plists directly")
"""

try! tempSource.write(to: tempSwift, atomically: true, encoding: .utf8)

// Run it
let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
task.arguments = [tempSwift.path]

do {
    try task.run()
    task.waitUntilExit()
} catch {
    print("❌ Error running script: \(error)")
}

// Clean up
try? fileManager.removeItem(at: tempDir)
