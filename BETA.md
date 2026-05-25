# BRAINROT LAB — Mobile Beta Test Guide

> You don't have a PC right now. That's fine. The built place file
> `BrainrotLab.rbxlx` (288 KB) is committed at the repo root — you can
> publish it from your phone in ~10 minutes using Roblox's mobile
> creator portal.

---

## Quickest path (mobile browser, ~10 min)

### Step 1 — Download the place file to your phone

On your phone, open the GitHub repo:
**https://github.com/gordon0072013-sudo/roblox-game**

Switch to the branch `claude/roblox-brainrot-game-1Z9MH` (the branch
dropdown is at the top of the file list).

Tap on `BrainrotLab.rbxlx`. On the file page, tap the **Download**
button (or three-dot menu → "Download raw file"). The file saves to
your phone's Downloads folder.

### Step 2 — Create an experience on Roblox

In your phone browser, go to **https://create.roblox.com**.

1. Sign in to your Roblox account.
2. Tap **Create New Experience** (or the **+** button).
3. Pick **Baseplate** (any template, we're about to overwrite it).
4. Name it: *Brainrot Lab Beta* (or anything).
5. Tap **Create Experience**.

### Step 3 — Replace the default place with our build

This is the only slightly awkward step on mobile. Two options:

**Option A — Save Place To File (works on mobile site):**
1. On your new experience page, find the place (default "Baseplate").
2. Tap on the place's three-dot menu → **Configure Place**.
3. Scroll to **Current Version → Upload New Version**.
4. Tap **Choose File** → select the `BrainrotLab.rbxlx` you downloaded.
5. Save.

**Option B — If the mobile UI doesn't show that option:**
Use a desktop-mode browser (Chrome/Safari → Request Desktop Site).
The full creator portal becomes available and uploading a place file
works exactly as it does on desktop.

### Step 4 — Test in the Roblox app

1. Open the **Roblox mobile app** on your phone.
2. Search for the experience name you used.
3. Tap **Play**.
4. You should land in your lab with a starter brainrot generating cash.

### Step 5 — (Optional) Make it public

By default the experience is private. While iterating, leave it
private. When you're happy:
- create.roblox.com (desktop site) → experience → Configure → Permissions
- Set to **Public**.

---

## What you'll see in the beta

A complete game with:
- Your private lab plot, a starter brainrot
- Cash ticking up
- Mutations every ~90s (sped up to ~8s if `FAST_TEST_MODE = true`)
- All UI tabs at the bottom (Shop, Inventory, Trade, Pets, Levels, etc.)
- Capture pad (green) on your plot
- Outbreak Plaza (purple, ~200 studs south of spawn)
- Mega Boss arena (red, east of plaza)

**Note:** Gamepasses and dev products won't trigger real purchases until
you create them on the Creator Dashboard and paste IDs into
`src/shared/Config.luau` — see `launch/PUBLISH_CHECKLIST.md`. For beta
testing the gameplay loop works without any IDs configured.

---

## If you want a fast-iteration test loop

Set `FAST_TEST_MODE = true` in `src/shared/Config.luau` before building:
- Mutations happen every 8 seconds instead of 90
- Outbreak event fires every 60 seconds instead of every 20 minutes

After editing, run `bash build.sh` (on PC) — or just push the change
to the branch and I can rebuild it for you in the cloud.

---

## Reporting bugs / requesting changes from your phone

Push notes to me as chat messages — I can rebuild and re-upload the
`BrainrotLab.rbxlx` whenever you want. You re-upload to your Roblox
experience via the same Step 3 flow.

---

## Why the .rbxlx is in the repo

Normally `.rbxlx` is a build artifact and lives in `.gitignore`. We've
intentionally un-ignored *only* this specific filename
(`!BrainrotLab.rbxlx`) so the mobile beta workflow works without any
local tooling. The file is text XML so git diffs cleanly between
builds.
