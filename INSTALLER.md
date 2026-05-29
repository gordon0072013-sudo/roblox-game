# BrainrotLab — One-File Installer

`BrainrotLab_Installer.luau` is a single self-contained Luau script that
constructs every Folder, Script, ModuleScript, and LocalScript for the
entire project into the correct Roblox services. No Rojo, no Wally, no
external tooling — only Roblox Studio.

There are now **three** ways to install. Pick whichever fits your
workflow:

| Method | File | Effort | Re-install |
|---|---|---|---|
| Studio Plugin (recommended) | `BrainrotLab_Plugin.rbxmx` | one-time drop into Plugins folder, then a toolbar click | one click |
| Command Bar paste | `BrainrotLab_Installer.luau` | paste a 425 KB script into Command Bar | re-paste |
| Manual Rojo sync | `default.project.json` | install Rojo + Wally | live sync |

## Method 1: Studio Plugin (recommended — closest to zero-button)

1. Download `BrainrotLab_Plugin.rbxmx` from the repo root.
2. Drop the file into your Roblox Studio plugins folder:
   - **Windows:** `%LOCALAPPDATA%\Roblox\Plugins\`
   - **Mac:** `~/Documents/Roblox/Plugins/`
3. Restart Roblox Studio.
4. Open any place (Baseplate, blank, etc.).
5. The toolbar shows a new **Brainrot Lab** button. Click **Install / Update**.
6. The Output panel prints `[BrainrotLab Plugin] install / update complete`.
7. **File → Save** (or **Publish to Roblox**).

Re-installing later (after I push a code update): regenerate the plugin
file (`python3 tools/build_plugin.py`), drop it into the same Plugins
folder (overwrite), reload Studio, click the button again.

## Method 2: Command Bar paste

1. **Open Roblox Studio.** Any place (Baseplate, blank, etc.) works.
2. **View → Command Bar.**
3. **Paste the entire contents of `BrainrotLab_Installer.luau`** into the
   Command Bar and press Enter.
4. The Output window prints:
   ```
   [BrainrotLab Installer] Beginning install...
   [BrainrotLab Installer] Install complete. Save the place or press Play to test.
   ```
5. **File → Save** (or **Publish to Roblox** to ship it).

The installer is idempotent: re-running on a place that's already been
installed replaces existing scripts with the new versions. Safe to re-run
each time you take a new copy from the repo.

## What the installer creates

| Service | Contents |
|---|---|
| `ReplicatedStorage/Shared` | Config, BrainrotData, MutationData, PetData, DecorationData, AchievementData, PatchNotes, Types, Remotes, Util, Log, LocalizationService |
| `ReplicatedStorage/Assets` | Placeholder docs for swappable mesh/audio IDs |
| `ServerScriptService/Server` | 33 service modules + the boot Script (AntiCheat, DataService, Economy, Lab, Mutation, Steal, Infection, Outbreak, Monetization, BattlePass, Trade, Quests, Achievements, Badges, GlobalLeaderboard, Pets, PlayerLevel, Season, Decoration, Invite, Webhook, Afk, BossEvent, Announcement, Analytics, …) |
| `StarterPlayer.StarterPlayerScripts.Client` | UI controllers + LocalScripts (HUD, Shop, Inventory, Trade, Pets, Levels, Quests, Achievements, GlobalLeaderboard, Outbreak, BossUI, PatchNotes, Loading Screen, …) |
| `Workspace` | Baseplate + `Plots` + `Brainrots` folders |
| `Lighting` | Sensible defaults |
| `HttpService` | Enabled (required for the optional Discord webhook) |

## Verifying the install

After running the installer, paste `BrainrotLab_Verify.luau` (also at
repo root) into the Command Bar and press Enter. It walks the
DataModel and prints PASS/FAIL for every expected Folder, Script,
ModuleScript and LocalScript. Catches paste truncation, partial
re-installs, and Studio reverting state. 93 checks run; a clean
install reports all green plus a single Remotes-folder presence check.

```
[BrainrotLab Verifier] starting…
  PASS  ReplicatedStorage
  PASS  ReplicatedStorage/Shared
  ...
[BrainrotLab Verifier] 93 / 93 checks passed (0 failures)
```

If any FAIL lines appear, re-paste the installer and re-verify.

## Regenerating the installer

After editing any source file in `src/`, regenerate the installer:

```bash
python3 tools/build_installer.py
```

The script walks `src/`, embeds every Luau file as a long-bracket literal
in the installer, and writes the result to `BrainrotLab_Installer.luau`
at the repo root. The build is hermetic — no external dependencies beyond
the Python 3 standard library.

## How it works (skim)

`tools/build_installer.py` reads the same directory layout
`default.project.json` expects, then emits one `ensurePath` call per
source file. Files named `init.server.luau` and `init.client.luau` use
Rojo's container-promotion convention: the parent folder becomes a Script
or LocalScript with the `init` source attached, so internal
`require(script.X)` lookups continue to resolve correctly.

Each embedded source uses a long-bracket level chosen to be safe against
the contents of that specific source (the generator scans for the
minimum `=` count not present in the source as a closing bracket).

## Why this exists

Rojo + Wally are best-in-class for Roblox dev environments — but they
need a desktop installation, a CLI, and (for Wally) a network round
trip. The installer trades all of that for a single 320 KB Luau script
the user pastes once. Trade-off: you can't `rojo serve` for live-sync
edits. Use Rojo when developing locally; use this installer to ship a
build to anyone who only has Studio open.
