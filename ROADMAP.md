# Brainrot Lab — 4-Week Live-Ops Roadmap

Ten updates, paced for a sustainable shipping cadence (~2.5 / week) and
ordered by revenue impact × shipping risk. Each update is small enough
to ship in a single sitting and large enough to justify a Discord
announcement + a TikTok video clip.

| # | Week | Update | Why it matters | Status |
|---|------|--------|----------------|--------|
| 1 | 1 | Live-ops announcement bar + loading screen | First impression frame is highest-attention; in-game news bar gives a no-deploy live-ops dial | ✅ shipped |
| 2 | 1 | **PetService** — collectible pet companions w/ buffs + Pet Egg gamepass | Whale monetization slot; pets are the highest ARPU mechanic in the Roblox tycoon meta | ✅ shipped |
| 3 | 1 | **PlayerLevelService** — XP + persistent level, level-reward chest | Sticky progression separate from rebirth — keeps long-tail players engaged after they cap rebirths | ✅ shipped |
| 4 | 2 | **SeasonService** — limited-time seasonal brainrot rotates every 2 weeks | FOMO drives the strongest revenue spikes in Roblox. Limited brainrots are tradable, so resale value compounds | ✅ shipped |
| 5 | 2 | **PlotDecorationService** — placeable cosmetic items + decoration gamepass | Extra cosmetic monetization slot; deeply personal plots screenshot well | 🔜 planned |
| 6 | 2 | **PatchNotesUI** — in-game changelog panel with new-update badge | Pro polish; signals "actively developed" to players (retention) and to Roblox's algorithm | ✅ shipped |
| 7 | 3 | **InviteService** — referral codes + reward on friend's first session | Viral growth loop; cheaper than ads per new user | 🔜 planned |
| 8 | 3 | **WebhookService** — Discord webhook on milestones (big purchases, boss kills) | Builds community presence + serves as light analytics dashboard | 🔜 planned |
| 9 | 4 | **LocalizationService** — string keys + ES/PT/FR translation | ~40% of Roblox traffic is LATAM + EU mobile. Localizing the storefront copy alone boosts conversion 15–30% in those regions | ✅ shipped (framework + ES + PT stubs) |
| 10 | 4 | **TestHarness** — economy + monetization math unit tests | Catches balance regressions before they ship. Pro signal for collaborators | ✅ shipped |

## Cadence

- **Tue / Thu releases** (split the 10 across 4 weeks = ~3/week)
- Pin a `#announcements` Discord post for each ship
- Cut a 15s TikTok per update — the update itself is the hook
- Bump the version label in `Config.GAME_VERSION` so the new-update badge fires

## Items already shipped in this branch

This roadmap is partially complete — see commit log. Remaining items
(5, 7, 8) are scoped to fit in single sittings; they'll land as
discrete follow-up commits over the next 2 weeks of real-world time.

## Beyond the 10

Backlog for after week 4 (high impact, lower urgency):
- Photo mode with auto-watermark for share virality
- Daily quest variety expansion (15+ templates instead of 9)
- Brainrot fusion (combine 2 same-species → next rarity)
- Server browser / private VIP servers
- Custom emote/dance system (cosmetic gamepass slot)
- Holiday seasonal reskin (Halloween, Christmas events)
