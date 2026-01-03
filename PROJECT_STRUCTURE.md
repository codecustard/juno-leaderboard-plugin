# Project Structure

Complete folder and file layout for the Juno Leaderboard Plugin.

```
juno-leaderboard-plugin/
├── README.md                          # Main documentation and usage guide
├── SETUP.md                           # Detailed setup instructions
├── QUICKSTART.md                      # 5-minute quick start guide
├── CLAUDE.md                          # Developer guide for Claude Code
├── LICENSE                            # MIT License
├── project.godot                      # Godot project configuration
│
├── addons/juno_leaderboard/           # Plugin directory
│   ├── plugin.cfg                     # Plugin metadata for Godot
│   ├── juno_plugin.gd                 # EditorPlugin implementation
│   ├── JunoLeaderboard.gd             # GDScript singleton wrapper
│   ├── juno_leaderboard.gdextension   # GDExtension configuration
│   ├── build.sh                       # Build script (Linux/macOS)
│   ├── build.bat                      # Build script (Windows)
│   │
│   ├── bin/                           # Compiled native libraries (gitignored)
│   │   ├── libjuno_leaderboard.so     # Linux library
│   │   ├── juno_leaderboard.dll       # Windows library
│   │   └── libjuno_leaderboard.dylib  # macOS library
│   │
│   ├── dock_ui/                       # Editor dock UI
│   │   ├── juno_dock.tscn             # Dock scene
│   │   └── juno_dock.gd               # Dock script
│   │
│   └── rust/                          # Rust GDExtension source
│       ├── Cargo.toml                 # Rust dependencies
│       ├── .gitignore                 # Rust-specific ignores
│       └── src/
│           └── lib.rs                 # Main Rust implementation
│
└── examples/                          # Example usage
    ├── leaderboard_example.tscn       # Example scene
    └── leaderboard_example.gd         # Example script
```

## Key Files Explained

### Plugin Core

- **plugin.cfg**: Godot plugin metadata (name, description, entry point)
- **juno_plugin.gd**: EditorPlugin that adds the custom dock and autoload singleton
- **JunoLeaderboard.gd**: GDScript wrapper providing the public API
- **juno_leaderboard.gdextension**: Configuration for multi-platform native libraries

### Native Implementation (Rust)

- **rust/src/lib.rs**: Core implementation using:
  - `gdext` for Godot bindings
  - `ic-agent` for Internet Computer communication
  - `candid` for encoding/decoding canister calls
  - Handles authentication, queries, and updates

### Editor Tools

- **dock_ui/juno_dock.tscn**: Custom dock UI with configuration and testing tools
- **dock_ui/juno_dock.gd**: Dock logic (buttons, signals, status display)

### Build System

- **build.sh**: Unix build script (compiles Rust, copies library)
- **build.bat**: Windows build script

## Build Artifacts

After building, the following files are created (gitignored):

```
addons/juno_leaderboard/
├── bin/
│   └── [platform-specific library]
└── rust/
    ├── Cargo.lock
    └── target/
        └── release/
            └── [compiled artifacts]
```

## Usage Flow

1. **Setup**: User creates Juno satellite and datastore collection
2. **Build**: Run `build.sh` or `build.bat` to compile Rust → native library
3. **Enable**: Activate plugin in Godot (loads .gdextension → Rust library)
4. **Configure**: Enter Satellite ID via editor dock (saved to ProjectSettings)
5. **Use**: Call `JunoLeaderboard.submit_score()` / `get_top_scores()` from game

## Dependencies

### Godot
- Godot 4.3+
- No additional addons required

### Rust (Cargo.toml)
- godot (gdext)
- ic-agent ~0.37
- candid ~0.10
- serde, serde_json
- tokio (async runtime)

### External Services
- Juno.build satellite (Internet Computer)
- Internet Identity (for authentication)

## Platform Targets

Compiled libraries for:
- **Linux**: x86_64 (`.so`)
- **Windows**: x86_64 (`.dll`)
- **macOS**: Universal (Intel + ARM) (`.dylib`)

Web/mobile support experimental.

## Documentation Map

- **README.md**: Overview, features, API reference
- **SETUP.md**: Step-by-step installation guide
- **QUICKSTART.md**: 5-minute getting started
- **CLAUDE.md**: Architecture for AI assistants
- **PROJECT_STRUCTURE.md**: This file (project layout)

## Development Workflow

```bash
# 1. Make changes to rust/src/lib.rs
# 2. Build
./addons/juno_leaderboard/build.sh

# 3. Restart Godot to reload library
# 4. Test via editor dock or example scene
```

For detailed development instructions, see [CLAUDE.md](CLAUDE.md).
