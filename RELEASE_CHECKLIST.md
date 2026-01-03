# Release Checklist for v0.1.0

Use this checklist when preparing to publish the Juno Leaderboard Plugin.

## Pre-Release Checklist

### Code Quality
- [x] All Rust code compiles without errors
- [x] All GDScript code has no syntax errors
- [x] Plugin loads successfully in Godot 4.3+
- [x] No critical bugs in core functionality
- [ ] Run `cargo clippy` and fix warnings
- [ ] Run `cargo fmt` to format Rust code

### Testing
- [x] Test on macOS (your platform)
- [ ] Test on Windows (or note as untested)
- [ ] Test on Linux (or note as untested)
- [x] Verify "Test Connection" works
- [x] Verify "Fetch & Display Leaderboard" works (with empty collection)
- [x] Verify "Insert Test Score" works (with Write: Public)
- [ ] Test example scene runs without errors
- [x] Verify plugin enables/disables cleanly

### Documentation
- [x] README.md complete with API reference
- [x] SETUP.md has step-by-step instructions
- [x] QUICKSTART.md for fast setup
- [x] CLAUDE.md for development context
- [x] BUILD.md with build instructions
- [x] CHANGELOG.md with v0.1.0 details
- [x] Known limitations documented
- [x] Authentication requirements explained
- [ ] Update author name in plugin.cfg if needed

### Build Artifacts
- [x] Build macOS library (libjuno_leaderboard.dylib)
- [ ] Build Windows library (juno_leaderboard.dll)
- [ ] Build Linux library (libjuno_leaderboard.so)
- [ ] OR: Include build instructions only (users build for their platform)

### Version Numbers
- [x] plugin.cfg version = "0.1.0"
- [x] Cargo.toml version = "0.1.0"
- [x] CHANGELOG.md has [0.1.0] entry

## Repository Setup

### Git
- [ ] Create GitHub repository (if not already done)
- [ ] Push all code to main/master branch
- [ ] Verify .gitignore excludes build artifacts
- [ ] Tag release: `git tag v0.1.0`
- [ ] Push tags: `git push --tags`

### GitHub Repository
- [ ] Add repository description: "Godot 4 plugin for global leaderboards using Juno.build on Internet Computer"
- [ ] Add topics/tags: `godot`, `godot-plugin`, `icp`, `juno`, `leaderboard`, `blockchain`, `rust`, `gdextension`
- [ ] Set repository visibility (public/private)
- [ ] Add LICENSE file if not using MIT

## Release Process

### GitHub Release
- [ ] Go to Releases → Draft a new release
- [ ] Tag version: `v0.1.0`
- [ ] Release title: `Juno Leaderboard Plugin v0.1.0 - Initial Release`
- [ ] Copy CHANGELOG.md content to release notes
- [ ] Add build instructions or attach pre-built libraries:
  - [ ] `juno-leaderboard-macos-v0.1.0.zip` (if providing builds)
  - [ ] `juno-leaderboard-windows-v0.1.0.zip`
  - [ ] `juno-leaderboard-linux-v0.1.0.zip`
  - [ ] OR: Note "Build from source - see BUILD.md"
- [ ] Mark as "Pre-release" (since it's v0.1.0)
- [ ] Publish release

### Godot Asset Library (Optional)
To publish to the official Godot Asset Library:

- [ ] Create asset library account at https://godotengine.org/asset-library/asset
- [ ] Prepare asset submission:
  - **Title**: Juno Leaderboard
  - **Category**: Misc (or Networking)
  - **Godot version**: 4.3
  - **License**: MIT
  - **Repository**: Your GitHub repo URL
  - **Issues URL**: Your GitHub issues URL
  - **Download link**: GitHub release zip
  - **Icon**: Create a plugin icon (256x256 PNG)
  - **Screenshots**: Add 2-3 screenshots showing the dock and example scene
- [ ] Submit for review
- [ ] Wait for approval (can take a few days)

### Alternative Distribution
If not using Asset Library yet:

- [ ] Share on Godot Discord/forums
- [ ] Post on r/godot subreddit
- [ ] Tweet about it with #godot #gamedev
- [ ] Share on ICP/Juno community channels

## Post-Release

### Announcement
- [ ] Write announcement post explaining:
  - What the plugin does
  - How to install
  - Link to documentation
  - Known limitations
  - Call for feedback/contributors

### Monitoring
- [ ] Watch for GitHub issues
- [ ] Monitor discussions/questions
- [ ] Note common pain points for v0.2.0

### Next Steps
- [ ] Create milestone for v0.2.0
- [ ] Add feature requests to issues
- [ ] Plan authentication improvements
- [ ] Consider pagination support

## Common Issues to Mention

When announcing, clarify:
1. ✅ This is v0.1.0 - expect rough edges
2. ✅ Authenticated writes need manual implementation (not fully automatic)
3. ✅ Best for desktop platforms (mobile/web experimental)
4. ✅ Designed for indie games with ~1000 or fewer scores
5. ✅ Requires Juno satellite setup (free on Internet Computer)

## Build Distribution Options

### Option A: Source Only (Recommended for v0.1.0)
- Users build the plugin for their platform
- Pros: No need to test all platforms, smaller repo
- Cons: Users need Rust toolchain

### Option B: Pre-built Libraries
- Include compiled `.so`, `.dll`, `.dylib` in releases
- Pros: Easy for users, no Rust required
- Cons: Need to build/test on all platforms, larger downloads

### Option C: Hybrid
- Include macOS build (your platform)
- Provide build instructions for others
- Most pragmatic for initial release

## Success Criteria

v0.1.0 is successful if:
- [ ] At least one other person successfully uses it
- [ ] No critical bugs reported in first week
- [ ] Documentation is clear enough for setup
- [ ] Works on at least 2 different platforms

---

**Good luck with the release! 🚀**
