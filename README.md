# 2D Battle Simulator

A TABS-meets-Melon-Playground sandbox battle simulator that runs entirely in the browser — no build, no dependencies. Open the HTML file and play.

Two versions:

- **`index.html`** — the main game. Side view with gravity, jointed (two-bone IK) limbs, semi-ragdoll physics, climbing, and a huge roster.
- **`battle-sim.html`** — the original top-down version (circle fighters).

## How to play

1. Open `index.html` in any modern browser.
2. Pick a **team** (Red / Blue), a **skin**, a **weapon**, and optionally **armour**, then **click the battlefield** to place fighters (drag to place many, right-click to delete).
3. Place **vehicles** from the panel, choose a **map**, then hit **Start** — last team standing wins.
4. **Random Army** fills both sides instantly. **Reset** revives everyone to their setup positions.

## Features

- **63 weapons** — melee (swords, axes, hammers, spears, chainsaw, whips…), guns (pistols, rifles, snipers, miniguns, LMGs…), launchers (RPG, bazooka, mortars), energy weapons, bows, and **throwables** (grenade, molotov with a fire pool, dynamite, gas grenade, C4 with a timed fuse).
- **8 skins** with distinct HP/speed/size (Soldier, Scout, Ninja, Knight, Tank, Zombie, Robot, Giant).
- **5 armour tiers** that reduce damage, add HP, and trade off speed.
- **24 combat vehicles** — tanks, APCs, mechs, artillery, rocket trucks (Katyusha), static rocket turrets (Nebelwerfer), Flak guns, plus aircraft: fighters, **stealth bomber (flying wing)**, gunships, bombers, drones, and helicopters.
- **11 themed maps** — Flat Field, Platforms, The Pit, Twin Towers, Staircase, Sky Bridge, Hill, Gang Base, Torture Chamber, Rooftops, Canyon (with per-map skies and decorations).
- **Smart AI** — units retaliate against whoever shoots them, advance for a clear line of fire, climb walls/ledges, avoid walking into deadly gaps, and kite at range.
- **Juicy physics** — muzzle blasts, recoil (gun kick + hip brace), glowing-hot flashes, afterburn smoke/embers, knockback, and collapse-to-the-ground death (corpses linger then fade; you can walk over them).
- **Two soldier forms** — classic **Stickman**, or **Countryball** mode where every fighter is a wobbly flag-ball (14 nations).

## Tech

Single self-contained HTML file each: vanilla JavaScript + Canvas 2D. No frameworks, no assets, no server.

🤖 Built with [Claude Code](https://claude.com/claude-code)
