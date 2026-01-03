# Quick Start Guide

Get up and running with Juno Leaderboard in 5 minutes!

## 1. Create Juno Satellite (2 min)

Visit [console.juno.build](https://console.juno.build):
1. Login with Internet Identity
2. Create a new satellite
3. Create a datastore collection named `highscores`
4. Set permissions: Read = Public, Write = Managed
5. Copy your Satellite ID

## 2. Build the Plugin (1 min)

**Linux/macOS:**
```bash
cd addons/juno_leaderboard
./build.sh
```

**Windows:**
```cmd
cd addons\juno_leaderboard
build.bat
```

## 3. Enable in Godot (30 sec)

1. Open your project in Godot
2. Project > Project Settings > Plugins
3. Enable "Juno Leaderboard"
4. Paste your Satellite ID in the dock (right panel)
5. Click "Test Connection"

## 4. Use in Your Game (1 min)

```gdscript
extends Node

func _ready():
    # Fetch leaderboard
    JunoLeaderboard.scores_fetched.connect(_on_scores_loaded)
    JunoLeaderboard.get_top_scores(10)

func _on_scores_loaded(scores: Array):
    for entry in scores:
        print("%s: %d" % [entry.player_name, entry.score])

# To submit scores (requires login first):
# JunoLeaderboard.login()  # Opens browser
# JunoLeaderboard.submit_score("Player", 100)
```

## 5. Test It! (30 sec)

Run the example scene: `examples/leaderboard_example.tscn`

---

For full documentation, see [README.md](README.md) and [SETUP.md](SETUP.md).
