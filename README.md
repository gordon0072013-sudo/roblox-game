# BRAINROT LAB — Mutation & Infection Tycoon

> A novel hybrid Roblox brainrot tycoon. Players capture Italian/sigma
> brainrots, watch them **visibly mutate** over real time, and engage in
> two-way PvP — **steal** rival mutations *or* **infect** their labs with
> debuff bombs. Built as a serious shot at the 30k R$ Year-1 revenue mark.

## What makes this different

Most viral brainrot games are *Steal a Brainrot* clones — a tycoon with a
single PvP direction. Brainrot Lab adds two original mechanics on top of
the proven loop:

1. **Live Mutation.** Every owned brainrot rolls a mutation tier-up on a
   ~90s timer. Color, scale, suffix, and FX layer cumulatively. Plots
   become ever-changing zoos — perfect TikTok/Shorts bait.
2. **Two-way PvP.** Steal a rival's brainrot (offensive item theft) *or*
   plant Infection Bombs that debuff their global income for 3 minutes
   (offensive sabotage). Most clones only do one; this game does both.

Plus the standard FOMO/retention toolbox: server-wide Outbreak events,
7-day daily reward cycle (Premium-only bonus tier), 30-tier Battle Pass,
server leaderboards.

## Tech stack

- **Rojo 7** for text-based project sync into Roblox Studio
- **Wally** for `ProfileService` (session-locked DataStore), Promise, Signal
- **Luau strict** mode
- 100% server-authoritative (no client-trust = no exploit revenue drain)

## Local build

```bash
# 1. Install tooling (one-time)
#    Rojo:  https://rojo.space         (cargo install rojo, or aftman add rojo-rbx/rojo)
#    Wally: https://wally.run          (cargo install wally, or aftman add UpliftGames/wally)

# 2. Install dependencies
wally install

# 3. Build the place file
bash build.sh
# -> produces BrainrotLab.rbxlx
```

Open `BrainrotLab.rbxlx` in Roblox Studio and hit **Play**.

## Live development with Rojo

```bash
rojo serve default.project.json   # in repo root
```

Then in Studio: install the **Rojo plugin** → Connect → 34872 → live
sync. Edit `.luau` files in your editor; Studio updates instantly.

## Project layout

```
default.project.json     # Rojo config — maps src/ into the DataModel
wally.toml               # Dependencies
.luaurc                  # Strict typing
build.sh                 # Convenience: wally install + rojo build
src/
  shared/                # Replicated to client & server (Config, types, data)
  server/                # Server-only services (data, economy, PvP, mon.)
  client/                # UI controllers (HUD, shop, inventory, etc.)
  assets/                # Procedural; see assets/README.md to swap meshes
```

The **single source of truth** for tuning + monetization IDs is
`src/shared/Config.luau`. Touch nothing else for normal balance tweaks.

## Publishing to Roblox + wiring monetization

This is the work that converts the game into revenue. Plan ~30 minutes.

### 1. Create the experience

1. In Studio, **File → Publish to Roblox As…** → pick a name (suggested:
   *Brainrot Lab: Mutation Tycoon* — keep "brainrot" + a noun for SEO).
2. In the [Creator Dashboard](https://create.roblox.com/dashboard/creations),
   open the new experience → Configure:
   - **Genre:** Simulator
   - **Tags:** brainrot, italian, tycoon, simulator, pvp, sigma, skibidi
   - **Avatar:** R6 or R15 — your call. R15 is the safer default.
   - **Server size:** 8 (matches our 8 plots in `LabService.luau`).
3. Upload an icon (512×512) and at least 3 thumbnails. Icon should have a
   loud color contrast and 1–2 brainrot characters; thumbnails should show
   *labs with mutated brainrots* (the differentiator).

### 2. Enable Premium Payouts

Creator Dashboard → Monetization → **Premium Payouts** → Enable. This
gives you a passive cut every time a Roblox Premium subscriber plays.
With aggressive daily-login design, this alone can carry the 30k target
on modest CCU.

### 3. Create Gamepasses

For each entry in `Config.GAMEPASSES` (6 total), open Monetization →
Passes → Create → upload a 512×512 icon → set the price. Then copy the
numeric Pass ID into `Config.luau`:

```lua
Config.GAMEPASSES = {
  MutationSpeed2x = { id = 12345678, price = 199, ... },
  ...
}
```

### 4. Create Developer Products

Same flow under Monetization → Developer Products. There are 10 entries
in `Config.DEV_PRODUCTS`. **The robux price you set in the Dashboard
overrides the `price` field in code** — keep them in sync so the shop UI
shows the truth.

### 5. Re-publish

In Studio → File → Publish to Roblox (overwrites the existing place).
Now gamepass and dev product prompts will actually open.

## Revenue model — how 30k R$ in Year 1 is realistic

After Roblox's 30% storefront cut, you keep 70% of every R$ spent.

| Lever | Conversion math | R$ to you |
|---|---|---|
| Sell **152** *2x Cash* gamepasses (249 R$) | 152 × 249 × 0.7 | ~26,500 |
| OR Sell **60** *VIP Lab* gamepasses (499 R$) | 60 × 499 × 0.7 | ~21,000 |
| OR Sell **31** *Premium Battle Pass* (999 R$) | 31 × 999 × 0.7 | ~21,700 |
| OR Premium Payouts on **~100k Premium minutes/yr** | varies | ~5–15k |

In practice a healthy game mixes all four. Hitting any single line above
clears the target. One viral TikTok in the launch month covers the year.

### Launch playbook (the marketing side)

1. **Day -7 → Day 0**: Post 3 short-form videos (TikTok, Shorts, Reels)
   showing the mutation-time-lapse hook. *"Watched my brainrot mutate 6
   times in 9 minutes — Apex form is INSANE."* The visible evolution
   IS the hook; lean on it.
2. **Day 0**: Public release. Set the experience as Public, enable
   Sponsored Experiences ads with ~100 R$ budget to seed CCU (so social
   visitors land on a non-empty server).
3. **Day 1–14**: Post 1 video per day. Cycle hooks: mutation reveals,
   epic steal moments, Outbreak captures.
4. **Week 2 → ongoing**: Run a **Battle Pass season** every 14 days
   (`Config.BATTLE_PASS_DURATION_DAYS`). The season change resets
   progress and re-engages lapsed players.
5. **Always**: respond to top comments / discord pings. Engaged
   communities multiply organic reach.

### Anti-revenue-loss safeguards already in code

- **ProfileService session lock** (`src/server/DataService.luau`) —
  prevents same-account-two-servers dupe exploits that trigger refund
  storms.
- **`ProcessReceipt` returns `PurchaseGranted` only after delivery** —
  no robux is taken without the player getting their item, and an
  idempotency log prevents double-grant on retries.
- **BindToClose flush** — purchases survive server shutdowns.
- **Grace period + cooldown + tier-delta** on Steal — keeps new players
  from getting farmed and quitting in their first session (huge for D1
  retention).

## Verification checklist

After `build.sh`:

- [ ] Open `BrainrotLab.rbxlx` in Studio → Play Solo.
- [ ] HUD shows starting cash (100). Starter brainrot appears on your plot.
- [ ] Cash ticks up steadily.
- [ ] After ~90s, a mutation pop-up appears and the brainrot visibly
      changes color/scale and gets a suffix. (Set
      `Config.FAST_TEST_MODE = true` to see it in 8s during testing.)
- [ ] Shop UI opens. Clicking a gamepass shows the "not configured"
      toast until you paste real IDs.
- [ ] Capture button on the plot consumes cash and spawns a brainrot.
- [ ] Studio → Test → 2 player local session:
  - Walk to the other player's plot, hit `E` near one of their brainrots
    → it transfers to you (after grace period — bypass by setting
    `Config.STEAL_GRACE_PERIOD_AFTER_JOIN = 0` for testing).
  - Press `Q` near them → infection toast fires + green smoke over their plot.
- [ ] Wait for Outbreak (set `FAST_TEST_MODE` for fast test) → rare
      brainrots spawn at the purple plaza, touch one to capture.
- [ ] Rebirth at the HUD button (cheat cash with `SkipRebirth` product or
      `EconomyService.AwardCash` in command bar) → next tier unlocks.
- [ ] Leaderboard panel populates with you + bots.

## Tuning knobs — fastest paths to revenue

Open `src/shared/Config.luau` and adjust:

- **Lower `STARTING_CAPACITY`** to push players toward the rebirth loop
  (and the Skip Rebirth product) faster.
- **Raise `CAPTURE_COST`** to make Cash Pack purchases feel useful.
- **Lower `MUTATION_INTERVAL`** to make the 2x Mutation Speed gamepass
  feel more visibly impactful (currently 90s → 45s with the pass).
- **Raise daily-reward cash on day 7** to push 7-day Premium retention.

## Credits / mechanics inspiration

- Mutation cadence inspired by *Pet Simulator 99* enchantments and
  *Plants vs. Zombies* family evolution patterns.
- PvP design inspired by *Steal a Brainrot*'s heist loop, extended with
  Outbreak / Infection sabotage to give defensive-style players a
  counter-loop.

Have fun. Go viral. Print Robux.
