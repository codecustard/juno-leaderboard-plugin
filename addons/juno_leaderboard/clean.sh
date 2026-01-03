#!/bin/bash
# Clean build artifacts to free disk space
# Keeps only the final library in bin/

set -e

echo "🧹 Cleaning Rust build artifacts..."

cd "$(dirname "$0")/rust"

# Show space before cleaning
if [ -d "target" ]; then
    BEFORE_SIZE=$(du -sh target | cut -f1)
    echo "   Current target/ size: $BEFORE_SIZE"
else
    echo "   No target/ directory found (already clean)"
    exit 0
fi

# Clean
cargo clean

echo "   ✓ Freed approximately $BEFORE_SIZE"
echo ""
echo "✨ Clean complete!"
echo ""
echo "Note: The compiled library in bin/ was preserved."
echo "      Run ./rebuild.sh if you need to rebuild."
