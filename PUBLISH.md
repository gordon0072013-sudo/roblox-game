# Publishing without a PC

Three options, ordered by effort.

## 1. Open Cloud API — true zero-PC path (~15 min, mobile-friendly)

If you can run Python (Termux on Android, Pythonista on iOS, any laptop,
a free GitHub Codespace, etc.), you can publish directly to Roblox.

### One-time setup

1. On your phone browser go to **https://create.roblox.com**. Sign in.
2. Tap **Create New Experience** → name it → Create.
3. Open the experience, note the **Universe ID** (in the URL) and the
   default place's **Place ID** (Configure Place → ID).
4. Go to **https://create.roblox.com/dashboard/credentials**.
5. Create an API key:
   - Name: `Brainrot Publisher`
   - Scope: **Place Publishing**
   - Add your experience to the "allowed experiences" list
   - Save the key string — you only see it once.
6. Optional: enable Premium Payouts on the experience (Monetization tab).

### Publish

From the repo root, on any Python 3.8+ environment:

```bash
python3 tools/publish_opencloud.py \
    --universe 1234567890 \
    --place    9876543210 \
    --api-key  YOUR_API_KEY \
    --file     BrainrotLab.rbxlx \
    --publish
```

`--publish` makes it the live version. Without it the upload becomes
a draft you can promote later. The script uses only the Python standard
library — no `pip install` needed.

### Updating after a code change

When I push a new commit, just rebuild the .rbxlx (`bash build.sh` from
a machine with Rojo) and rerun the script. New version goes live in
seconds.

## 2. Studio Command Bar — the installer path (~5 min, needs Studio)

On any device that can run Roblox Studio:

1. Open Studio. Any place works.
2. **View → Command Bar.**
3. Paste the entire contents of `BrainrotLab_Installer.luau` and press
   Enter.
4. **File → Publish to Roblox.**

Documented in `INSTALLER.md`.

## 3. Mobile browser file upload — needs Desktop-mode browser (~10 min)

Walked through in `BETA.md`. Slower than (1) but no Python needed.

---

## After publishing

The game is live but gamepasses/badges/etc. don't exist yet. Follow
`launch/PUBLISH_CHECKLIST.md` — that doc enumerates every ID you need
to paste into `src/shared/Config.luau` after creating them on the
Creator Dashboard. Most of the ~90 minutes there can be done on a
phone via Desktop-mode browser.
