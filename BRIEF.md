# Brainrot Lab — Project Brief

**Goal:** Ship a Roblox brainrot tycoon that hits **30,000 Robux per day**
and **blows up on day 1** of launch.

## Game concept

Build something that **doesn't exist yet** in the brainrot meta — not
another *Steal a Brainrot* clone. The novelty:

- **Live Mutation**: every owned brainrot visibly evolves over real time
  (color shift, scale, suffix, FX layered cumulatively). Plots become
  ever-changing zoos — natural TikTok/Shorts bait.
- **Two-way PvP**: players can both **steal** a rival's brainrot *and*
  plant **infection bombs** that debuff their whole income. Most clones
  do one direction; this game does both.

## Monetization

**Aggressive.** Gamepasses + dev products + battle pass + welcome offers
+ daily deals + lucky wheel + tip-the-dev tier. Hit every conversion
surface that doesn't break the experience.

## Anti-cheat

**Best-in-class, production grade.**

- Per-remote rate limits with sliding-window buckets
- Input sanitization (NaN/inf rejection, range caps, uid regex)
- Position-delta speed/teleport/out-of-bounds checks
- Character WalkSpeed/JumpPower lock-back
- Escalating violation score with auto-kick threshold
- ProfileService session-locked DataStore (dupe-exploit prevention)
- Idempotent `ProcessReceipt` (lost-purchase prevention)

## Admin / abuse panel

**Owner-only**, auto-detected via `game.CreatorId` (no UserId hardcoding
required). Group-owned experiences treat rank 254+ as admin. Owner-only
commands stay gated even from additional admins. Panel accessible by
Right Shift / shield icon. Live player list with give-cash / mutate /
kick / ban / unban / spawn-boss / skip-outbreak quick actions.
DataStore-backed bans persist across servers. Doubles as an anti-cheat
dashboard.

## Installer — zero manual setup

The user only needs **Roblox Studio open**. No Rojo install, no Wally
install, no PC required for setup decisions. Provide a Studio Plugin
(`.rbxmx`) that drops once into the plugins folder; one toolbar click
installs/updates the entire game in any open place. Fallback: a single
Luau script that pastes into the Studio Command Bar and builds
everything on Enter.

## Code quality

**Senior-grade. No AI-slop look.** Concise comments only where the
*why* is non-obvious. No multi-paragraph docstrings. Strict Luau types.
Server-authoritative throughout. One source of truth (`Config.luau`)
for tuning + monetization IDs.

## Bug discipline

After **every change**, run the audit:

- Boot list ↔ services-with-`.Init()`: 0 orphans
- Used remotes ↔ declared remotes: 0 missing
- 0 unused requires
- Rojo build clean
- Installer parses with `luac -p`

Fix anything that drifts immediately, in the same commit.

## Delivery artifacts

Each push to the branch should refresh:

- `BrainrotLab.rbxlx` — the built place file
- `BrainrotLab_Installer.luau` — Command Bar paste-and-run
- `BrainrotLab_Verify.luau` — post-install PASS/FAIL validator
- `BrainrotLab_Plugin.rbxmx` — Studio Plugin (one-click toolbar install)
- `tools/publish_opencloud.py` — Python script to publish via Roblox
  Open Cloud from any device (incl. mobile via Termux/Pythonista)

## Branch / workflow

Develop on `claude/roblox-brainrot-game-1Z9MH`. Commit logically. Push
after every meaningful change. Don't open a PR unless asked.

## What I can't do from this container

These two require external execution:

- Actually generate Robux. The game has to be published to Roblox first,
  monetization IDs pasted into `Config.luau`, and real players have to
  spend.
- Actually go viral on day 1. Marketing (TikTok hooks, Sponsored
  Experience ads, group seeding) happens on the user's side.

The published-from-container path is `tools/publish_opencloud.py` once
the user creates an Open Cloud API key (one-time, free, takes 2 min).
