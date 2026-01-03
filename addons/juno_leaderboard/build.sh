#!/bin/bash
# Build script for Juno Leaderboard GDExtension
# Builds the Rust library and copies it to the bin directory

set -e  # Exit on error

echo "🦀 Building Juno Leaderboard GDExtension..."

# Navigate to rust directory
cd "$(dirname "$0")/rust"

# Build in release mode
echo "📦 Compiling Rust code..."
cargo build --release

# Detect platform and copy appropriate library
echo "📋 Copying library to bin directory..."
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    cp target/release/libjuno_leaderboard.so ../bin/
    echo "✅ Linux build complete: libjuno_leaderboard.so"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    cp target/release/libjuno_leaderboard.dylib ../bin/
    echo "✅ macOS build complete: libjuno_leaderboard.dylib"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    cp target/release/juno_leaderboard.dll ../bin/
    echo "✅ Windows build complete: juno_leaderboard.dll"
else
    echo "⚠️  Unknown platform: $OSTYPE"
    echo "Please manually copy the library from target/release/ to ../bin/"
fi

echo ""
echo "🎉 Build complete!"
echo "You can now enable the plugin in Godot."
