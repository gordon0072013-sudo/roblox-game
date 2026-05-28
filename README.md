# Coin Clicker Tycoon — a monetized Roblox game

A complete, ready-to-publish Roblox clicker/tycoon game built to **earn passive
income** through Robux (Game Passes + Developer Products), which convert to real
money (EUR/USD) via Roblox's **DevEx** program.

The whole game is generated from code — no manual Studio building required. You
sync it once with Rojo, paste in your monetization IDs, and publish.

---

## ⚠️ Honest expectations (read this first)

I built you a real, working product. But nobody — no tool, no AI — can promise
"€20/day with zero effort." Here is the truth:

- **The code is done.** Selling, saving, multipliers, auto-clicker, shop UI —
  all working.
- **You do a one-time ~15-minute setup** that *only you can do*, because it
  requires *your* Roblox account: publish the game and create the paid items.
  (Roblox doesn't let a script create paid items on your behalf — that's their
  anti-fraud rule, not a limitation of this code.)
- **Income is not guaranteed.** It depends on getting players. A game with 0
  players earns €0. A game that catches on can earn far more than €20/day.
  Most of the "passive" part is real once players arrive; the work is in
  attracting them.

So: this gets you a genuine, monetizable asset and removes ~95% of the effort.
The remaining 5% (publish + promote) is on you and can't be automated away.
See [`INCOME-PLAN.md`](INCOME-PLAN.md) for the realistic math and a promotion
checklist.

---

## What's inside

```
default.project.json   Rojo project mapping (sync target)
rokit.toml             Toolchain (Rojo) pinned version
src/shared/            Config + shared remotes (edit Config.lua only)
src/server/            Data saving, monetization, game logic
src/client/            Auto-generated UI (click button + shop)
SETUP.md               Step-by-step publish + monetize guide
INCOME-PLAN.md         Realistic earnings math + promotion checklist
```

## Quick start

1. Install [Rokit](https://github.com/rojo-rbx/rokit) and run `rokit install`.
2. Open Roblox Studio → install the Rojo plugin → connect to this folder
   (`rojo serve`). The full game appears in your place.
3. Follow [`SETUP.md`](SETUP.md) to publish and create your paid items, then
   paste the IDs into `src/shared/Config.lua`.
4. Publish. You're live and selling.

The game runs perfectly fine **before** you add monetization IDs — paid items
just show as "Soon" until configured, so you can test the loop immediately.
