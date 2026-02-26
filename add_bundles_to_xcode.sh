#!/bin/bash

echo "📦 Adding EmbeddedBundles to Xcode project..."

# The issue is that the Resources folder exists on disk but Xcode has it as "Resources 2"
# We need to add the EmbeddedBundles as a folder reference

# First, let's check the current state
echo ""
echo "Current state:"
ls -la "MDMKeys/Resources/"

echo ""
echo "⚠️  To add EmbeddedBundles to the Xcode project:"
echo ""
echo "1. In Xcode, right-click on 'MDMKeys' in the Project Navigator"
echo "2. Select 'Add Files to \"Differ\"...'"
echo "3. Navigate to: MDMKeys/Resources/EmbeddedBundles"
echo "4. IMPORTANT: Check 'Create folder references' (NOT 'Create groups')"
echo "5. Make sure 'MDMKeys' target is checked"
echo "6. Click 'Add'"
echo ""
echo "OR use this command to add via command line:"
echo ""

cat << 'SCRIPT'
# Add the EmbeddedBundles folder to the project
# This script will be automated in the next step
SCRIPT

echo ""
echo "Would you like me to create an automated script? (y/n)"
