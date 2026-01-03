# Juno Leaderboard Plugin for Godot

A simple, easy-to-use global leaderboard system for Godot 4.3+ games using [Juno.build](https://juno.build) datastores on the Internet Computer (ICP).

## Features

- **Global Leaderboards**: Store and retrieve high scores from anywhere in the world
- **Internet Computer Powered**: Leverages ICP's decentralized infrastructure via Juno
- **Easy Integration**: Firebase-like API with simple `submit_score()` and `get_top_scores()` methods
- **Editor Tools**: Custom dock with test connection, insert test data, and preview leaderboard
- **Authenticated Writes**: Uses Internet Identity for secure score submissions
- **Public Reads**: Anonymous leaderboard fetching (no auth required)
- **Cross-Platform**: Works on Windows, macOS, and Linux (desktop)
- **GDExtension**: Native Rust implementation for proper ICP canister calls

## Quick Start

### Installation

1. **Create a Juno Satellite**: Visit [console.juno.build](https://console.juno.build) and create a satellite with a `highscores` datastore collection
2. **Build the Plugin**: Compile the Rust GDExtension for your platform (see [SETUP.md](SETUP.md))
3. **Enable in Godot**: Project > Project Settings > Plugins > Enable "Juno Leaderboard"
4. **Configure**: Enter your Satellite ID in the Juno Leaderboard dock

For detailed setup instructions, see [SETUP.md](SETUP.md).

### Basic Usage

```gdscript
extends Node

func _ready():
    # Connect to signals
    Juno.scores_fetched.connect(_on_scores_fetched)
    Juno.score_submitted.connect(_on_score_submitted)

    # Fetch top 10 scores (no auth required)
    Juno.get_top_scores(10)

func _on_scores_fetched(scores: Array):
    for i in scores.size():
        var entry = scores[i]
        print("%d. %s - %d pts" % [i + 1, entry.player_name, entry.score])

func submit_score(player_name: String, score: int):
    # Submit score (requires prior login)
    Juno.submit_score(player_name, score)

func _on_score_submitted(success: bool):
    if success:
        print("Score submitted!")
        Juno.get_top_scores(10)  # Refresh
```

## Authentication Flow

For score submissions, users need to authenticate via Internet Identity:

```gdscript
func authenticate():
    # Connect login signals
    Juno.login_completed.connect(_on_login_completed)

    # Opens browser for Internet Identity login
    Juno.login()

func _on_login_completed(success: bool):
    if success:
        print("Authenticated! Can now submit scores.")
    else:
        print("Login failed")
```

After `login()` is called, a browser window opens to `identity.ic0.app`. Users authenticate there and the delegation is passed back to your game.

## API Reference

### Initialization

```gdscript
Juno.initialize(satellite_id: String, collection_name: String = "highscores")
```

Initialize the plugin with your Juno satellite configuration. Usually called automatically from ProjectSettings.

### Authentication

```gdscript
Juno.login()
```

Opens browser for Internet Identity authentication. Required before submitting scores.

```gdscript
Juno.set_delegation(delegation_base64: String) -> bool
```

Manually set delegation identity (for advanced use cases).

### Leaderboard Operations

```gdscript
Juno.submit_score(player_name: String, score: int)
```

Submit a score to the leaderboard. Requires prior authentication.

```gdscript
Juno.get_top_scores(limit: int = 10)
```

Fetch top N scores from the leaderboard. Works anonymously, no auth required.

### Utility Methods

```gdscript
Juno.test_connection() -> bool
```

Test connection to the satellite (blocking). Useful for debugging.

```gdscript
Juno.get_satellite_id() -> String
Juno.get_collection_name() -> String
```

Get current configuration values.

## Signals

The plugin uses signals for async operations:

```gdscript
signal login_initiated
signal login_completed(success: bool)
signal score_submitted(success: bool)
signal scores_fetched(scores: Array)
```

**Score Entry Format:**
```gdscript
{
    "player_name": "Alice",
    "score": 1000,
    "timestamp": 1234567890
}
```

## Editor Tools

When enabled, the plugin adds a custom dock (right panel) with:

- **Satellite ID / Collection Name**: Configure your Juno backend
- **Open Juno Console**: Quick link to console.juno.build
- **Test Connection**: Verify satellite accessibility
- **Insert Test Score**: Add dummy data for development
- **Fetch & Display Leaderboard**: Preview current scores in ItemList

All settings are saved to `ProjectSettings` and persist across sessions.

## Architecture

```
┌─────────────────────────────────────────────┐
│           Your GDScript Game                │
│  (submit_score, get_top_scores, etc.)       │
└───────────────┬─────────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────────┐
│     Juno.gd (Singleton)          │
│   (GDScript wrapper with signals)           │
└───────────────┬─────────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────────┐
│  JunoLeaderboard (Rust GDExtension)         │
│  - ic-agent for ICP calls                   │
│  - Candid encoding/decoding                 │
│  - Internet Identity delegation             │
└───────────────┬─────────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────────┐
│       Internet Computer (ICP)               │
│         Juno Satellite Canister             │
│      (Datastore: highscores)                │
└─────────────────────────────────────────────┘
```

## Example Project

Check out `examples/leaderboard_example.tscn` for a complete working example with:
- Login flow
- Score submission form
- Leaderboard display with ranks
- Error handling

Run it with F6 after enabling the plugin!

## Limitations

### Current Limitations

1. **Authentication (v0.1.0)**:
   - Internet Identity integration requires manual delegation flow (not fully automated)
   - Editor "Insert Test Score" requires **Write: Public** permissions (anonymous agent used)
   - For production with **Managed** permissions, implement auth in your game code
   - Reads work anonymously, writes require authentication

2. **Collection Size**: Efficient for ~1,000 documents. Larger datasets need pagination

3. **Client-Side Sorting**: All scores fetched and sorted locally (not server-side query)

4. **Auth Flow**: Browser-based Internet Identity not ideal for consoles/mobile

5. **No Server Validation**: Scores submitted directly (no anti-cheat built-in)

6. **Web Export**: GDExtension WASM support is experimental (desktop recommended)

### Recommended Limits

- **Max scores per collection**: ~1,000 for good performance
- **Leaderboard fetch limit**: 10-50 entries
- **Score submission rate**: Implement client-side debouncing

### Datastore Permissions

For testing/development:
- Set **Write: Public** to allow editor tools to insert test scores
- Fetching works with any permissions (uses anonymous query)

For production:
- Set **Write: Managed** for authenticated-only writes
- Users must implement Internet Identity authentication in their game
- See example scene for auth flow structure

## Future Improvements

Planned features for future versions:

- **Pagination**: Server-side query limits for large datasets
- **Categories**: Multiple leaderboards (daily/weekly/all-time, per-level, etc.)
- **Server-Side Validation**: Use Juno Functions for score verification
- **Anti-Cheat**: Cryptographic signatures, rate limiting, anomaly detection
- **Offline Queue**: Submit scores when connection restored
- **Social Features**: Friend leaderboards, player profiles
- **Web Export**: Pure GDScript fallback for HTML5 builds

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| **Windows** | ✅ Supported | x86_64, requires VC++ redistributables |
| **macOS** | ✅ Supported | Universal binary (Intel + Apple Silicon) |
| **Linux** | ✅ Supported | x86_64, tested on Ubuntu 22.04+ |
| **HTML5/WASM** | ⚠️ Experimental | GDExtension WASM support limited |
| **Mobile** | ❓ Untested | May work, auth flow needs adjustment |
| **Consoles** | ❓ Untested | Platform-specific auth required |

## Technical Details

### Dependencies

**Rust (Cargo.toml):**
- `godot` - gdext for Godot bindings
- `ic-agent ~0.45` - Internet Computer agent
- `candid` - Candid encoding/decoding
- `serde` / `serde_json` - Serialization
- `tokio` - Async runtime

**Godot:**
- Godot 4.3+ (uses latest EditorPlugin APIs)

### Data Flow

**Fetching Leaderboard (Read):**
1. Anonymous agent queries satellite canister
2. Calls `list_docs` method on `highscores` collection
3. Decodes CBOR/JSON documents
4. Sorts by score descending (client-side)
5. Returns top N via signal

**Submitting Score (Write):**
1. User authenticates via Internet Identity
2. Authenticated agent calls `set_doc` on satellite
3. Document key = player name (or UUID)
4. Data = `{player_name, score, timestamp}`
5. Success/failure returned via signal

## Development

### Building from Source

```bash
cd addons/juno_leaderboard/rust
cargo build --release
cp target/release/libjuno_leaderboard.* ../bin/
```

### Running Tests

```bash
cd addons/juno_leaderboard/rust
cargo test
```

### Code Quality

```bash
cargo clippy -- -D warnings
cargo fmt --check
```

## Contributing

Contributions are welcome! Areas for improvement:

- Better error messages and recovery
- More comprehensive tests
- Documentation improvements
- Platform-specific builds (CI/CD)
- Web export support

## License

MIT License - see LICENSE file for details

## Resources

- **Juno Documentation**: [juno.build/docs](https://juno.build/docs)
- **Internet Computer**: [internetcomputer.org](https://internetcomputer.org)
- **Godot-Rust (gdext)**: [github.com/godot-rust/gdext](https://github.com/godot-rust/gdext)
- **Setup Guide**: [SETUP.md](SETUP.md)
- **Architecture**: [CLAUDE.md](CLAUDE.md)

## Support

- **Issues**: Report bugs via GitHub Issues
- **Juno Discord**: [discord.gg/wHZ57Z2RAG](https://discord.gg/wHZ57Z2RAG)
- **Godot Rust**: [discord.gg/FNudpBD](https://discord.gg/FNudpBD)

---

Made with ❤️ for the Godot and Internet Computer communities
