# Publish Checklist — copy IDs into the codebase as you create them

This is the minimum to ship. Run through top-to-bottom, copy each ID
into the indicated file, and re-publish at the end.

---

## A. Experience setup

| Step | Where | Notes |
|---|---|---|
| Create experience | Studio → File → Publish to Roblox As… | Name: "Brainrot Lab: Mutation Tycoon" |
| Set genre | Creator Dashboard → Configure → Basic Info | Simulator |
| Set max players | Creator Dashboard → Places → Configure | **8** (must match `PLOT_COUNT` in `src/server/LabService.luau`) |
| Upload icon | Creator Dashboard → Thumbnails | 512×512 PNG |
| Upload 3 thumbnails | Creator Dashboard → Thumbnails | 1280×720 PNG each |
| Set 15 tags | Creator Dashboard → Configure → Tags | See launch/MARKETING.md §1 |
| Enable Premium Payouts | Creator Dashboard → Monetization → Premium Payouts | Toggle on |

## B. Gamepasses (8 total)

Create each at Creator Dashboard → Monetization → Passes → Create.
Copy the numeric pass ID into `src/shared/Config.luau` → `Config.GAMEPASSES`.

| Key | Suggested price | Pasted? |
|---|---|---|
| MutationSpeed2x | 199 R$ | [ ] |
| Cash2x | 249 R$ | [ ] |
| VIPLab | 499 R$ | [ ] |
| InfectionShield | 299 R$ | [ ] |
| LuckyMutations | 349 R$ | [ ] |
| TripleCapture | 399 R$ | [ ] |
| RainbowTrail | 149 R$ | [ ] |
| GoldenPlot | 199 R$ | [ ] |

## C. Developer Products (10 total)

Create each at Creator Dashboard → Monetization → Developer Products.
Copy the product ID into `src/shared/Config.luau` → `Config.DEV_PRODUCTS`.

| Key | Suggested price | Pasted? |
|---|---|---|
| CashSmall | 49 R$ | [ ] |
| CashMedium | 99 R$ | [ ] |
| CashLarge | 199 R$ | [ ] |
| CashHuge | 499 R$ | [ ] |
| CashTycoon | 999 R$ | [ ] |
| InstantMutation | 75 R$ | [ ] |
| SkipRebirth | 99 R$ | [ ] |
| RareBrainrotEgg | 149 R$ | [ ] |
| InfectionBomb5 | 89 R$ | [ ] |
| BattlePassPremium | 999 R$ | [ ] |

## D. Badges (11 total — optional but big for virality)

Create each at Creator Dashboard → Badges → Create.
Copy the badge ID into `src/server/BadgeService.luau` → `BADGES`.

| Key | Awarded for | Pasted? |
|---|---|---|
| FirstSteps | First join | [ ] |
| FirstCapture | First brainrot captured | [ ] |
| FirstMutation | First mutation triggered | [ ] |
| FirstSteal | First successful steal | [ ] |
| FirstInfect | First infection bomb landed | [ ] |
| FirstRebirth | First rebirth | [ ] |
| OutbreakHero | First Outbreak capture | [ ] |
| ApexAchieved | Mutated any brainrot to T6 | [ ] |
| Tycoon100K | Earned 100k cash total | [ ] |
| Tycoon1M | Earned 1M cash total | [ ] |
| Founder | Joined in launch week (14 days) | [ ] |

After creating Founder badge, set `LAUNCH_TS = os.time()` in `BadgeService.luau`.

## E. Group

| Step | Where | Notes |
|---|---|---|
| Create Roblox Group | roblox.com → Groups → Create | 100 R$ if not Premium |
| Set group name | "BRAINROT LAB" | |
| Set description | See launch/MARKETING.md §5 | |
| Copy group ID | URL contains `/groups/12345678/` | |
| Paste into Config | `src/shared/Config.luau` → `Config.GROUP_ID = 12345678` | |

## F. Final re-publish

After pasting all IDs:

```bash
bash build.sh                            # rebuild .rbxlx
# Open BrainrotLab.rbxlx in Studio → File → Publish to Roblox (overwrites)
```

## G. First playtest after publishing

- [ ] Join as a real player from your phone (not Studio)
- [ ] Walk on capture pad → captures, deducts cash
- [ ] Wait 90s → see a mutation pop-up, brainrot visually changes
- [ ] Open the shop → all 8 gamepasses + 10 dev products show real prices
- [ ] Click a gamepass → real purchase prompt appears
- [ ] Enter code LAUNCH → 2,500 cash awarded
- [ ] Verify your profile got the "First Steps" badge after ~10s

If any of these fail, the most common cause is a typo in a pasted ID
or a price mismatch (Dashboard price overrides the code default). Open
the server console (F9) — `MonetizationService` logs warnings for
unconfigured IDs.

---

Ship it.
