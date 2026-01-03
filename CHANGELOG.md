# Changelog

All notable changes to the Juno Leaderboard Plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-01-03

### Added
- Initial release of Juno Leaderboard plugin for Godot 4.3+
- GDExtension implemented in Rust using gdext and ic-agent
- Integration with Juno.build datastores on Internet Computer (ICP)
- Global singleton `Juno` accessible from any GDScript
- Core methods:
  - `initialize(satellite_id, collection_name)` - Configure Juno connection
  - `get_top_scores(limit)` - Fetch leaderboard (public/anonymous)
  - `submit_score(player_name, score)` - Submit scores (requires auth)
  - `login()` - Open Internet Identity for authentication
  - `test_connection()` - Verify satellite connectivity
- Editor plugin with custom dock panel:
  - Satellite ID and Collection name configuration
  - "Open Juno Console" button
  - "Test Connection" button
  - "Insert Test Score" button (requires public write permissions)
  - "Fetch & Display Leaderboard" with live preview
- Multi-platform support:
  - macOS (Universal: Intel + Apple Silicon)
  - Windows (x86_64)
  - Linux (x86_64)
- Example scene demonstrating full usage
- Comprehensive documentation:
  - README.md with API reference and examples
  - SETUP.md with step-by-step installation guide
  - QUICKSTART.md for 5-minute setup
  - CLAUDE.md for development architecture
  - BUILD.md with build instructions
- Build scripts for all platforms (build.sh, build.bat, rebuild.sh, clean.sh)

### Known Limitations
- Authenticated writes (Internet Identity) require manual delegation flow
- Client-side sorting of scores (all documents fetched, then sorted locally)
- Efficient for ~1,000 documents; larger collections need pagination
- Editor "Insert Test Score" requires Write: Public permissions
- Web/WASM export is experimental (gdext WASM support limited)
- No server-side score validation (anti-cheat features planned for future)

### Technical Details
- Rust crates: gdext (master), ic-agent 0.37, candid 0.10, serde, tokio
- Proper Candid interface matching Juno satellite canister
- Blocking methods for editor tools, async methods for runtime
- Score data format: `{player_name: String, score: i64, timestamp: i64}`
- Supports Juno datastore collections with configurable permissions

[0.1.0]: https://github.com/codecustard/juno-leaderboard-plugin/releases/tag/v0.1.0
