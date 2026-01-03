#!/bin/bash
# Clean and rebuild script for Juno Leaderboard GDExtension
# This script cleans all build artifacts and rebuilds from scratch

set -e  # Exit on error

echo "🧹 Cleaning previous build artifacts..."

# Navigate to rust directory
cd "$(dirname "$0")/rust"

# Show space before cleaning
BEFORE_SIZE=$(du -sh target 2>/dev/null | cut -f1 || echo "0B")
echo "   Current target/ size: $BEFORE_SIZE"

# Clean build artifacts
cargo clean

echo "   ✓ Cleaned successfully"
echo ""

# Build in release mode
echo "🦀 Building Juno Leaderboard GDExtension (release)..."
cargo build --release

# Detect platform and copy appropriate library
echo ""
echo "📋 Copying library to bin directory..."
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    cp target/release/libjuno_leaderboard.so ../bin/
    LIBRARY_SIZE=$(du -sh ../bin/libjuno_leaderboard.so | cut -f1)
    echo "   ✅ Linux build complete: libjuno_leaderboard.so ($LIBRARY_SIZE)"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    cp target/release/libjuno_leaderboard.dylib ../bin/
    LIBRARY_SIZE=$(du -sh ../bin/libjuno_leaderboard.dylib | cut -f1)
    echo "   ✅ macOS build complete: libjuno_leaderboard.dylib ($LIBRARY_SIZE)"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    cp target/release/juno_leaderboard.dll ../bin/
    LIBRARY_SIZE=$(du -sh ../bin/juno_leaderboard.dll | cut -f1)
    echo "   ✅ Windows build complete: juno_leaderboard.dll ($LIBRARY_SIZE)"
else
    echo "   ⚠️  Unknown platform: $OSTYPE"
    echo "   Please manually copy the library from target/release/ to ../bin/"
fi

# Show final sizes
echo ""
echo "📊 Disk usage:"
TARGET_SIZE=$(du -sh target 2>/dev/null | cut -f1 || echo "0B")
echo "   target/ directory: $TARGET_SIZE"
echo "   Final library: $LIBRARY_SIZE"
echo ""
echo "💡 Tip: Run 'cargo clean' to free up ~500MB of disk space"
echo "   (You only need the library in bin/, not the target/ directory)"
echo ""
echo "🎉 Rebuild complete! Restart Godot to load the new library."
