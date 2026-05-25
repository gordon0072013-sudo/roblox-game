# Changelog

All notable changes per commit on `claude/roblox-brainrot-game-1Z9MH`.

## v0.1.0 — current

### Core game
- 33+ brainrot species across 7 rarity tiers (Common → Outbreak)
- 9 mutation suffixes × 6 visible tiers per brainrot, live evolution every ~90s
- Two-way PvP: steal a rival brainrot (E) and infect rivals (Q)
- Server-wide Outbreak event every 20 min in the plaza
- Server-wide cooperative Mega Boss every 45 min
- Top-of-hour 5-min events (Golden Hour / Mutation Rush / Spin Hour)
- Two-week seasonal limited-time brainrot rotation
- Limited-time launch event (48h 2x cash from server boot)
- Lucky Wheel (free spin every 12h + paid spin packs)
- Daily Deal — 30% rotating gamepass promo

### Player progression
- Rebirth loop with exponential cost curve + permanent multiplier
- 30-tier Battle Pass (free + Premium) every 14 days
- 7-day daily reward streak (Premium bonus day 7)
- 9-template daily quest rotation (deterministic per player+day)
- 20-achievement system with claim rewards
- 11 Roblox profile badges (auto-fired on milestones)
- Persistent player Level + XP (separate from rebirth)
- Brainrot Fusion (3 same-species → next rarity tier)
- Pet companions with rarity rolls + buff effects
- Auto-sell with rarity threshold + mutated-protection

### Social / virality
- Cross-server leaderboard with weekly reset (top-25, OrderedDataStore)
- Per-server top-cash / mutations / thieves leaderboard
- Milestone announcements (per-server: Rebirth tiers, capture tiers)
- Cross-server shout (Rebirth 25+, 10M+ cash) via MessagingService
- Group reward (+25% cash for group members)
- Friend invite via Roblox SocialService.PromptGameInvite
- Personal referral codes with both-side cash bonus
- Marketing redemption codes (LAUNCH / BRAINROT / SIGMA / OUTBREAK / MUTATE)
- Hot Streak server-population cash multiplier (1.0x → 1.75x)
- Server announcement ticker with static + runtime push

### Retention
- Offline cash on return (up to 8h at 40% live rate)
- Welcome offer modal (one-time 50%-off framing at 90s)
- Cinematic overlays on Rebirth + Apex Mutation
- AFK kick after 20 min idle (free seats for engaged players)
- Tutorial overlay first-session only (6 steps)
- Loading screen with active codes + group CTA

### Monetization
- 13 gamepasses (199–499 R$)
- 14 dev products (49–999 R$)
- Premium Battle Pass dev product
- Pet Eggs (basic 99 R$ + golden 399 R$)
- Wheel Spin Packs (5-pack 79 R$, 25-pack 299 R$)
- Decoration Pack (premium cosmetic tier)
- Premium Payouts hook (+10% cash mult for Premium)
- VIP Server bonus (+50% cash in private servers)
- Daily Deal 5,000 cash bonus on featured pass purchase

### Income formula (11 multipliers)
```
base × tier × rebirth × Cash2x × Group × Premium × Pet × HotStreak
     × Event × VipServer × Hour × infection-penalty
```

### Admin tools
- Owner-only Admin Panel (Right Shift to open)
- Auto-detected via game.CreatorId; group co-owner support
- Commands: give, rebirths, give-brainrot, mutate-all, tp, kick, ban,
  unban, flags, stats, skip-outbreak, spawn-boss, help
- DataStore-backed bans (persist across servers)
- Quick-action buttons per player row (Give 10k / Mutate / Kick)
- TextChatService bridge for /commands on modern Roblox chat
- AntiCheat dashboard integration (per-player violation counts)

### Anti-cheat
- 30+ per-remote rate limits with sliding-window buckets
- Input sanitization (NaN/inf rejection, range caps, uid regex)
- Position-delta speed/teleport/out-of-bounds checks at 2 Hz
- Character WalkSpeed/JumpPower lock-back
- Escalating violation score with 60s decay, auto-kick at 6 pts
- ProfileService session-locked DataStore (dupe-exploit prevention)
- Idempotent ProcessReceipt (lost-purchase prevention)
- Per-player flag log with reason + timestamp

### Polish
- Mobile-aware touch control sizing (60%+ of Roblox = mobile)
- Responsive UI scaling on small viewports
- leaderstats integration (Cash + Rebirths in default player list)
- Owner/Admin chat tags ([OWNER] gold, [ADMIN] green)
- Notification rate-limiting (suppress duplicate toasts < 750ms)
- Rebirth confirmation (tap-twice within 4s) — prevents misclicks
- Structured logging (Log.Debug/Info/Warn/Error with scope prefix)
- Cinematic vignette overlays on big moments
- Performance monitor (heartbeat-time + plot-budget warnings)

### Infrastructure
- 48 server services, 30+ client UI panels
- Rojo 7 project (default.project.json)
- Wally for ProfileService, Promise, Signal
- Luau strict mode (`.luaurc`)
- 100% server-authoritative game logic
- Test harness in tests/init.luau (12 economy/scoring assertions)
- Python installer generator (tools/build_installer.py)
- Open Cloud publish script (tools/publish_opencloud.py) for zero-PC deploy
- ROADMAP.md — 4-week post-launch shipping plan

### Audits run after every change
- Boot list ↔ services with `.Init()`: 48/48, 0 orphans
- Used remotes ↔ declared remotes: 58/59, 0 missing
- Unused requires: 0
- `luac -p` syntax check on installer: passes
- Rojo build: clean
