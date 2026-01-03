# Juno Leaderboard Plugin - Setup Guide

This guide will walk you through setting up the Juno Leaderboard plugin for your Godot 4.3+ game.

## Prerequisites

Before you begin, ensure you have:

- **Godot 4.3 or later** installed
- **Rust toolchain** (latest stable) - [Install from rustup.rs](https://rustup.rs/)
- **Platform-specific build tools**:
  - **Windows**: Visual Studio 2019+ with C++ development tools
  - **macOS**: Xcode Command Line Tools (`xcode-select --install`)
  - **Linux**: GCC/Clang and development libraries (`build-essential` on Ubuntu/Debian)

## Step 1: Create a Juno Satellite

Juno satellites are your backend on the Internet Computer. You'll need to create one and set up a datastore collection.

### Option A: Using Juno Console (Recommended for beginners)

1. Visit [console.juno.build](https://console.juno.build)
2. Log in with your Internet Identity (create one if you don't have it)
3. Click **"Create a new satellite"**
4. Give your satellite a name (e.g., "my-game-leaderboard")
5. Copy your **Satellite ID** (looks like: `xxxxx-xxxxx-xxxxx-xxxxx-xxx`)

### Option B: Using Juno CLI

```bash
# Install Juno CLI
npm install -g @junobuild/cli

# Create a new satellite
juno init

# Follow the prompts to create your satellite
```

## Step 2: Configure Datastore Collection

In the Juno Console:

1. Navigate to your satellite
2. Go to **Datastore** section
3. Click **"Create Collection"**
4. Set the collection name to: **`highscores`**
5. Configure permissions:
   - **Read**: `Public` (allow anonymous reads)
   - **Write**: `Managed` (require authentication)
   - **Memory**: `Heap` (for small datasets)
6. Click **Create**

Your datastore is now ready to store leaderboard scores!

## Step 3: Build the GDExtension

The plugin uses Rust for ICP/Juno integration. You need to compile the native library for your platform.

### Build for your current platform

```bash
cd addons/juno_leaderboard/rust
cargo build --release
```

This will create the compiled library in `target/release/`:
- **Linux**: `libjuno_leaderboard.so`
- **Windows**: `juno_leaderboard.dll`
- **macOS**: `libjuno_leaderboard.dylib`

### Copy library to plugin bin folder

```bash
# Linux
cp target/release/libjuno_leaderboard.so ../bin/

# Windows (PowerShell)
copy target\release\juno_leaderboard.dll ..\bin\

# macOS
cp target/release/libjuno_leaderboard.dylib ../bin/
```

### Cross-compilation (Advanced)

**For Windows from Linux/macOS:**
```bash
# Install MinGW-w64
# Ubuntu/Debian: sudo apt-get install mingw-w64
# macOS: brew install mingw-w64

rustup target add x86_64-pc-windows-gnu
cargo build --release --target x86_64-pc-windows-gnu
cp target/x86_64-pc-windows-gnu/release/juno_leaderboard.dll ../bin/
```

**For macOS Universal Binary:**
```bash
rustup target add x86_64-apple-darwin aarch64-apple-darwin

cargo build --release --target x86_64-apple-darwin
cargo build --release --target aarch64-apple-darwin

# Create universal binary
lipo -create \
  target/x86_64-apple-darwin/release/libjuno_leaderboard.dylib \
  target/aarch64-apple-darwin/release/libjuno_leaderboard.dylib \
  -output ../bin/libjuno_leaderboard.dylib
```

## Step 4: Enable Plugin in Godot

1. Open your Godot project
2. Go to **Project > Project Settings > Plugins**
3. Find **"Juno Leaderboard"** in the list
4. Check the **Enable** checkbox
5. The plugin will activate and add a new dock panel on the right

## Step 5: Configure Satellite ID

1. In the **Juno Leaderboard dock** (right panel), you'll see configuration fields
2. Paste your **Satellite ID** from Step 1
3. Verify the **Collection Name** is set to `highscores`
4. Click **"Test Connection"** to verify everything works

You should see "✓ Connection successful!" if configured correctly.

## Step 6: Test the Plugin

### Using the Editor Dock

1. Click **"Insert Test Score"** to add dummy data
2. Click **"Fetch & Display Leaderboard"** to see the results
3. The leaderboard list should show your test scores

### Using the Example Scene

1. Open `res://examples/leaderboard_example.tscn`
2. Run the scene (F6)
3. Try the following:
   - Click **"Refresh Leaderboard"** to fetch scores (works anonymously)
   - Click **"Login with Internet Identity"** to authenticate
   - After login, enter a name and score, then click **"Submit Score"**

## Step 7: Use in Your Game

Add this to any script:

```gdscript
extends Node

func _ready():
    # The singleton is automatically available
    JunoLeaderboard.scores_fetched.connect(_on_scores_loaded)
    JunoLeaderboard.get_top_scores(10)

func _on_scores_loaded(scores: Array):
    for entry in scores:
        print("%s scored %d points" % [entry.player_name, entry.score])

func submit_player_score(player_name: String, score: int):
    # Note: Requires prior login
    JunoLeaderboard.submit_score(player_name, score)
```

## Troubleshooting

### "Agent not initialized" error
- Make sure you called `JunoLeaderboard.initialize(satellite_id, collection_name)` first
- Or configure via the editor dock (saved to ProjectSettings)

### Connection test fails
- Verify your Satellite ID is correct (copy-paste from Juno Console)
- Check your internet connection
- Make sure the satellite exists and is accessible

### Build errors
- Ensure you have Rust installed: `rustc --version`
- Update Rust: `rustup update`
- Check that you're in the correct directory: `addons/juno_leaderboard/rust/`

### Library not found in Godot
- Verify the `.so`/`.dll`/`.dylib` file is in `addons/juno_leaderboard/bin/`
- Check the `.gdextension` file paths match your library locations
- Restart Godot after copying libraries

### Scores not appearing
- Verify the collection name matches exactly: `highscores`
- Check datastore permissions (Read: Public, Write: Managed)
- Try inserting a test score via the editor dock first

## Platform-Specific Notes

### Windows
- You may need to install Visual Studio C++ Redistributables for end users
- The DLL should be ~5-10 MB after compilation

### macOS
- On first run, macOS may block the library. Go to System Preferences > Security & Privacy to allow it
- Universal binaries work on both Intel and Apple Silicon Macs

### Linux
- Different distributions may require different system libraries
- If you encounter linking errors, install: `libssl-dev pkg-config`

### HTML5/Web Export (Experimental)
- GDExtension support for WASM is experimental as of 2026
- For web builds, consider implementing a pure GDScript fallback using HTTP requests
- Or export for desktop platforms only

## Next Steps

- Read the [README.md](README.md) for usage examples
- Check [CLAUDE.md](CLAUDE.md) for development architecture
- Visit [Juno documentation](https://juno.build/docs) for advanced features
- Explore the example scene in `examples/leaderboard_example.tscn`

## Security Considerations

- **Never commit** your Satellite ID to public repositories if you want to keep it private
- Implement **rate limiting** in your game to prevent spam submissions
- Consider adding **server-side validation** using Juno Functions for anti-cheat
- For production games, implement **proper error handling** for network failures

## Getting Help

- **Juno Discord**: [discord.gg/wHZ57Z2RAG](https://discord.gg/wHZ57Z2RAG)
- **Juno Docs**: [juno.build/docs](https://juno.build/docs)
- **Internet Computer Forum**: [forum.dfinity.org](https://forum.dfinity.org)
- **Godot Rust Discord**: [discord.gg/godot-rust](https://discord.gg/FNudpBD)

Happy building! 🚀
