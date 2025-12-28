#!/usr/bin/env python3
"""
Script to automatically add Design System files to Xcode project
"""

import subprocess
import os
import sys

# Get the directory of this script
script_dir = os.path.dirname(os.path.abspath(__file__))
project_dir = script_dir

# Files to add
files_to_add = [
    # Tokens
    "CurrencyConverter/DesignSystem/Tokens/OceanColors.swift",
    "CurrencyConverter/DesignSystem/Tokens/OceanSpacing.swift",
    "CurrencyConverter/DesignSystem/Tokens/OceanRadius.swift",
    "CurrencyConverter/DesignSystem/Tokens/OceanShadows.swift",
    "CurrencyConverter/DesignSystem/Tokens/OceanBlur.swift",
    # Extensions
    "CurrencyConverter/DesignSystem/Extensions/Color+Ocean.swift",
    # View Modifiers
    "CurrencyConverter/DesignSystem/ViewModifiers/GlassmorphismModifier.swift",
    "CurrencyConverter/DesignSystem/ViewModifiers/OceanGradientModifier.swift",
    "CurrencyConverter/DesignSystem/ViewModifiers/GlassCardModifier.swift",
    "CurrencyConverter/DesignSystem/ViewModifiers/FloatingAnimationModifier.swift",
    # Components
    "CurrencyConverter/DesignSystem/Components/OceanButton.swift",
    "CurrencyConverter/DesignSystem/Components/GlassCard.swift",
]

def run_command(cmd):
    """Run a shell command and return output"""
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    return result.returncode, result.stdout, result.stderr

def add_files_using_applescript():
    """Add files to Xcode project using AppleScript"""

    print("Adding files to Xcode project using AppleScript...")

    # Create AppleScript to add files
    applescript = '''
tell application "Xcode"
    activate
    set theProject to active workspace document
end tell

tell application "System Events"
    tell process "Xcode"
        -- Wait for Xcode to be ready
        delay 1

        -- Select the project navigator
        keystroke "1" using command down
        delay 0.5

        -- Right click on CurrencyConverter group and add files
        -- This is a simplified version - you may need to adjust
    end tell
end tell
'''

    # This approach is complex, let's try a different method
    return False

def add_files_manually_to_pbxproj():
    """Manually add file references to project.pbxproj"""
    print("Attempting to add files to project.pbxproj...")

    try:
        # Install pbxproj Python library
        print("Checking for pbxproj library...")
        import pbxproj

        project_path = os.path.join(project_dir, "CurrencyConverter.xcodeproj/project.pbxproj")
        project = pbxproj.XcodeProject.load(project_path)

        # Add files to the project
        for file_path in files_to_add:
            full_path = os.path.join(project_dir, file_path)
            if os.path.exists(full_path):
                print(f"Adding {file_path}...")
                project.add_file(file_path, parent=project.get_or_create_group('CurrencyConverter'))

        # Save the project
        project.save()
        print("✅ Successfully added all files to the project!")
        return True

    except ImportError:
        print("pbxproj library not found. Installing...")
        install_code, _, _ = run_command("pip3 install pbxproj")

        if install_code == 0:
            print("✅ Installed pbxproj. Please run this script again.")
            return False
        else:
            print("❌ Could not install pbxproj library.")
            return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def main():
    print("=" * 60)
    print("Adding Design System files to CurrencyConverter Xcode project")
    print("=" * 60)
    print()

    # Check if all files exist
    missing_files = []
    for file_path in files_to_add:
        full_path = os.path.join(project_dir, file_path)
        if not os.path.exists(full_path):
            missing_files.append(file_path)

    if missing_files:
        print("❌ Missing files:")
        for f in missing_files:
            print(f"  - {f}")
        return 1

    print(f"✅ All {len(files_to_add)} files found")
    print()

    # Try to add files using pbxproj library
    if add_files_manually_to_pbxproj():
        print()
        print("=" * 60)
        print("✅ Files successfully added to Xcode project!")
        print("=" * 60)
        print()
        print("Next steps:")
        print("1. Close and reopen Xcode")
        print("2. Clean build folder: Cmd+Shift+K")
        print("3. Build the project: Cmd+B")
        return 0
    else:
        print()
        print("=" * 60)
        print("⚠️  Automatic file addition failed")
        print("=" * 60)
        print()
        print("Please add files manually in Xcode:")
        print("1. Right-click on 'CurrencyConverter' folder")
        print("2. Select 'Add Files to CurrencyConverter...'")
        print("3. Select the 'DesignSystem' folder")
        print("4. Check 'Copy items if needed' and 'Create groups'")
        print("5. Make sure 'CurrencyConverter' target is selected")
        print("6. Click 'Add'")
        return 1

if __name__ == "__main__":
    sys.exit(main())
