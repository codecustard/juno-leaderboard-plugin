# Build Scripts Guide

Quick reference for building the Juno Leaderboard GDExtension.

## Available Scripts

### 🔨 `build.sh` / `build.bat`
**First-time build** - Compiles the Rust library and copies to bin/

```bash
./build.sh      # Linux/macOS
build.bat       # Windows
```

### 🔄 `rebuild.sh` / `rebuild.bat`
**Clean rebuild** - Cleans artifacts, rebuilds from scratch, shows disk usage

```bash
./rebuild.sh    # Linux/macOS
rebuild.bat     # Windows
```

**Use this when:**
- Build errors occur
- You want to ensure a clean build
- Updating dependencies
- Ran out of disk space and cleared it

### 🧹 `clean.sh` / `clean.bat`
**Clean only** - Removes build artifacts to free ~500MB disk space

```bash
./clean.sh      # Linux/macOS
clean.bat       # Windows
```

**Use this when:**
- Need to free disk space
- Don't need to rebuild immediately
- Already have working library in bin/

## Quick Commands

**From project root:**
```bash
# First build
cd addons/juno_leaderboard
./build.sh

# Clean rebuild
./rebuild.sh

# Free space only
./clean.sh
```

**From rust directory:**
```bash
cd addons/juno_leaderboard/rust

# Build
cargo build --release

# Clean
cargo clean

# Clean and build
cargo clean && cargo build --release
```

## Disk Space Management

### What Takes Up Space?

- `target/` directory: **~500MB** (build artifacts)
- Final library: **~5-10MB** (the .so/.dll/.dylib)

### After Building

You can safely delete `target/` to free space:

```bash
cd rust
cargo clean    # Frees ~500MB
```

The compiled library in `bin/` is all Godot needs!

### When to Clean

**Keep target/ if:**
- Actively developing (faster rebuilds)
- Making frequent changes

**Clean target/ if:**
- Low on disk space
- Done building
- Committing to git

## Troubleshooting

### "cargo: command not found"
Install Rust: https://rustup.rs/

### "linker 'cc' not found" (Linux)
```bash
sudo apt-get install build-essential
```

### "MSVC not found" (Windows)
Install Visual Studio Build Tools with C++ support

### "Library not found in Godot"
1. Check that `bin/` contains the library
2. Verify `.gdextension` file paths match
3. Restart Godot after building

### Build takes too long
First builds download dependencies (~2-5 min). Subsequent builds are faster with incremental compilation.

### Out of memory during build
Try building without optimizations first:
```bash
cargo build  # Debug build (faster, larger)
```

## Platform-Specific Notes

### Linux
Output: `libjuno_leaderboard.so`
Location: `bin/libjuno_leaderboard.so`

### macOS
Output: `libjuno_leaderboard.dylib`
Location: `bin/libjuno_leaderboard.dylib`

**First run:** macOS may block the library. Go to System Preferences > Security & Privacy to allow it.

### Windows
Output: `juno_leaderboard.dll`
Location: `bin\juno_leaderboard.dll`

**First run:** Windows may require VC++ Redistributables for end users.

## Cross-Compilation

See [SETUP.md](../../SETUP.md#cross-compilation-advanced) for cross-platform build instructions.

## After Building

1. ✅ Library copied to `bin/`
2. 🔄 Restart Godot
3. ⚙️ Enable plugin in Project Settings
4. 🎮 Ready to use!
