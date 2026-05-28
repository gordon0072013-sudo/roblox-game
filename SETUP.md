# Setup — publish & turn on the income (~15 min, one time)

Do these once. After this, the game sells on autopilot.

## 0. Prerequisites
- A Roblox account (free).
- Roblox Studio installed (free): https://create.roblox.com/
- [Rokit](https://github.com/rojo-rbx/rokit) (toolchain manager).

## 1. Get the code into Studio
1. In this folder, run `rokit install` (installs Rojo).
2. Run `rojo serve`.
3. In Roblox Studio: install the **Rojo** plugin (Toolbox → search "Rojo"),
   open a new **Baseplate**, click the Rojo plugin → **Connect**.
4. The game's scripts and folders sync in automatically.

## 2. Publish the place
1. Studio → **File → Publish to Roblox As…** → Create new.
2. Give it a name + thumbnail. Set it to **Public** so people can join.
3. On the Creator Dashboard (https://create.roblox.com/dashboard/creations),
   open the game → **Configure** → make sure it's public.

## 3. Enable saving (DataStores)
Creator Dashboard → your game → **Configure → Security** →
turn ON **Enable Studio Access to API Services** and make sure DataStores are
enabled. (Without this, player progress won't save in live servers.)

## 4. Create the things you'll sell
This is the part only you can do (Roblox requires the account owner).

### Game Passes (one-time perks)
Creator Dashboard → your game → **Monetization → Passes → Create a Pass**.
Create three (names are up to you), and set a Robux price for each:
| Pass         | Suggested price | Config key    |
|--------------|-----------------|---------------|
| 2x Coins     | 99 Robux        | `DoubleCoins` |
| Auto Clicker | 199 Robux       | `AutoClicker` |
| VIP          | 499 Robux       | `VIP`         |

Copy each pass's **ID** (in its URL / details page).

### Developer Products (repeatable coin packs)
Creator Dashboard → **Monetization → Developer Products → Create**.
| Product       | Suggested price | Config key  |
|---------------|-----------------|-------------|
| 1,000 Coins   | 25 Robux        | `Coins1k`   |
| 10,000 Coins  | 99 Robux        | `Coins10k`  |
| 100,000 Coins | 499 Robux       | `Coins100k` |

Copy each product's **ID**.

## 5. Paste the IDs
Open `src/shared/Config.lua`. Replace every `id = 0` with the real numbers:

```lua
Config.GamePasses = {
    DoubleCoins = { id = 1234567, ... },
    AutoClicker = { id = 2345678, ... },
    VIP         = { id = 3456789, ... },
}
Config.DeveloperProducts = {
    Coins1k   = { id = 4567890, ... },
    Coins10k  = { id = 5678901, ... },
    Coins100k = { id = 6789012, ... },
}
```

Save → Rojo re-syncs → **Publish to Roblox** again to push the update.
The shop's "Soon" buttons now become "Buy" and start selling.

## 6. Cash out (DevEx)
Robux you earn can be converted to real money via **DevEx**:
https://create.roblox.com/dashboard/devex
- You need a verified account and to meet the minimum Robux threshold.
- Payout is via PayPal/bank in your local currency (EUR works).

That's it — the game now sells 24/7. The only ongoing lever is **getting
players**, covered in `INCOME-PLAN.md`.
