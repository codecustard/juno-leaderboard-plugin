# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Godot 4.3+ plugin that provides global leaderboard functionality using Juno.build datastores on the Internet Computer (ICP). The plugin uses GDExtension with Rust for ICP canister interactions and provides a Firebase-like API for GDScript developers.

## Architecture

### Plugin Structure
```
addons/juno_leaderboard/
├── plugin.cfg                      # Plugin metadata
├── juno_plugin.gd                  # EditorPlugin with custom dock
├── JunoLeaderboard.gd             # GDScript singleton wrapper (autoload)
├── juno_leaderboard.gdextension   # Multi-platform library config
└── rust/                          # Rust GDExtension implementation
    ├── Cargo.toml
    └── src/
        └── lib.rs                 # Godot classes & ICP agent
```

### Core Components

**Rust GDExtension Layer (`rust/src/lib.rs`)**
- Implements `JunoLeaderboard` class registered with Godot via gdext
- Uses `ic-agent` (~0.45) for ICP canister calls with Candid encoding
- Handles Internet Identity delegation for authenticated writes
- Provides methods: `login()`, `submit_score()`, `get_top_scores()`
- Exposes blocking methods for editor tools (Test Connection, Fetch Leaderboard)

**GDScript Singleton (`JunoLeaderboard.gd`)**
- Thin wrapper around Rust implementation
- Provides async/await-friendly Godot API
- Methods return signals or use Callable callbacks
- Initialized via ProjectSettings (satellite_id, collection_name)

**Editor Plugin (`juno_plugin.gd`)**
- Adds custom Dock with UI for:
  - Satellite ID & Collection name configuration (saved to ProjectSettings)
  - "Open Juno Console" button (opens console.juno.build)
  - "Test Connection" - validates satellite connectivity
  - "Insert Test Score" - adds dummy data for testing
  - "Fetch & Display Leaderboard" - shows ItemList/Tree of current scores
- Uses same Rust agent as runtime for consistency

### Data Model

**Datastore Collection: `highscores`**
- Document key: unique player ID (player_name or generated UUID)
- Document data:
  ```rust
  {
    "player_name": String,
    "score": i64,
    "timestamp": i64  // Unix timestamp
  }
  ```
- Permissions:
  - Public reads (anonymous query)
  - Authenticated writes (Internet Identity required)

### Authentication Flow

1. **Read operations**: Use anonymous agent (no auth required)
2. **Write operations**:
   - Call `login()` → opens browser to `https://identity.ic0.app`
   - User authenticates with Internet Identity
   - Delegation returned via callback URL or manual paste
   - Subsequent writes use authenticated agent

## Building the Plugin

### Prerequisites
- Rust toolchain (latest stable)
- Godot 4.3+
- Target platform development tools (Visual Studio for Windows, Xcode for macOS)

### Build Commands

**Build Rust GDExtension for current platform:**
```bash
cd addons/juno_leaderboard/rust
cargo build --release
```

**Cross-compile for other platforms:**
```bash
# Windows from Linux/macOS (requires mingw-w64)
cargo build --release --target x86_64-pc-windows-gnu

# macOS universal binary
cargo build --release --target x86_64-apple-darwin
cargo build --release --target aarch64-apple-darwin
lipo -create target/x86_64-apple-darwin/release/libjuno_leaderboard.dylib \
             target/aarch64-apple-darwin/release/libjuno_leaderboard.dylib \
             -output target/universal/libjuno_leaderboard.dylib

# Linux
cargo build --release --target x86_64-unknown-linux-gnu
```

**Run Rust tests:**
```bash
cd addons/juno_leaderboard/rust
cargo test
```

**Check Rust code:**
```bash
cargo clippy -- -D warnings
cargo fmt --check
```

### Library Output Locations
After building, copy libraries to:
- Windows: `addons/juno_leaderboard/bin/juno_leaderboard.dll`
- macOS: `addons/juno_leaderboard/bin/libjuno_leaderboard.dylib`
- Linux: `addons/juno_leaderboard/bin/libjuno_leaderboard.so`

The `.gdextension` file references these paths for automatic loading.

## Development Workflow

### Initial Setup
1. Create Juno satellite at console.juno.build or via CLI
2. Create datastore collection named `highscores` with public read permissions
3. Build the Rust GDExtension for your platform
4. Open project in Godot Editor
5. Enable plugin: Project → Project Settings → Plugins → "Juno Leaderboard"
6. Configure via custom dock: Set Satellite ID and Collection name

### Testing in Editor
- Use the custom dock's "Test Connection" to verify satellite accessibility
- "Insert Test Score" adds dummy data for development
- "Fetch & Display Leaderboard" shows current state
- All dock operations use the same Rust backend as runtime

### Example Usage in Game
```gdscript
# In any scene script
func _ready():
    # Singleton is auto-loaded when plugin enabled
    JunoLeaderboard.get_top_scores(10, _on_leaderboard_loaded)

func _on_leaderboard_loaded(scores: Array):
    for entry in scores:
        print("%s: %d" % [entry.player_name, entry.score])

func submit_player_score(player_name: String, score: int):
    # Requires prior login() call
    await JunoLeaderboard.submit_score(player_name, score)
    print("Score submitted!")
```

## Key Dependencies

**Rust (Cargo.toml):**
- `godot = "0.2"` (gdext crate, latest)
- `ic-agent = "~0.45"`
- `candid = "latest"`
- `junobuild-satellites = "latest"` (if available, else direct canister calls)
- `tokio = { version = "1", features = ["rt-multi-thread"] }`

**Godot:**
- Godot 4.3+ (uses new EditorPlugin APIs)

## Platform Support

**Primary Targets:**
- Windows (x86_64)
- macOS (Universal: x86_64 + ARM64)
- Linux (x86_64)

**Experimental:**
- WebAssembly/HTML5 export (gdext WASM support is experimental as of 2026)
- For web builds, consider fallback to pure GDScript with HTTP REST API if available

## Current Limitations

1. **Collection Size**: Efficient for ~1000 documents; larger collections need pagination
2. **Client-Side Sorting**: All documents fetched, then sorted locally (consider server-side query limits)
3. **Auth Flow**: Browser-based Internet Identity not ideal for consoles/mobile (future: delegation via deep links)
4. **No Server-Side Validation**: Scores submitted directly (future: add Juno functions for anti-cheat)
5. **Web Export**: GDExtension WASM support experimental; may need pure GDScript alternative

## Important Notes

- **Satellite Creation**: No programmatic satellite creation API; users must use console.juno.build or Juno CLI
- **ProjectSettings Keys**:
  - `juno_leaderboard/satellite_id`
  - `juno_leaderboard/collection_name`
- **Anonymous vs Authenticated**: Reads work immediately; writes require `login()` call first
- **Error Handling**: Rust methods should return Result types; GDScript wrapper emits error signals
- **Thread Safety**: ic-agent operations may block; use Godot's thread pool or async runtime carefully

## Future Enhancements

- Pagination for large leaderboards
- Multiple leaderboard categories (daily/weekly/all-time)
- Server-side score validation via Juno functions
- Automatic delegation renewal
- Mobile/console auth alternatives (delegation tokens via QR/code)
- Top N filtering on server-side (reduce data transfer)
