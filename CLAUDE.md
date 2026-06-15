# CLAUDE.md — 2D Battle Simulator

TABS-meets-Melon-Playground browser battle sandbox. Repo: `VideoGameTips/2d-battle-simulator` (public).

## Files
- **`index.html`** — THE game. Side-view, gravity, IK limbs, semi-ragdoll, vehicles, strikes. ~everything lives here.
- **`battle-sim.html`** — original top-down version (circle fighters). Mostly frozen; only touch if asked.
- Each is a **single self-contained HTML file**: vanilla JS + Canvas 2D, **no build, no deps, no assets, no server**. Keep it that way.

## How it's built (index.html)

All logic is in one `<script>`. Rough map:

- **Data tables (top):** `SKINS` (8), `WEAPONS` (63: `cat:'melee'|'ranged'`, throwables use `lob:true`, flame uses `soft:true`), `ARMORS` (5 tiers: `dr`/`hp`/`spd`), `VEHICLES` (24), `STRIKES` (5 one-use), `MAPS` (11, each may have `sky` + `decor()`), `WSHAPE` (weapon→silhouette), `BLUE_C`/`RED_C` (countryball flag pools).
- **State:** `units[]` holds BOTH soldiers and vehicles — discriminated by `u.kind` (`'unit'` vs `'vehicle'`). Also `projs[]`, `fx[]`, `hazards[]`, `strikes[]` (markers), `brush`, `mode` (`setup|battle|over`), `bodyStyle` (`stickman|ball`), `screenFlash`.
- **Loop:** `loop()` → substepped `updateBattle(dt)` → `render()` via rAF.

### Key systems / where to look
- **Targeting AI:** `nearestEnemy()` + retaliation lock (`u.lock`, set in `damage()` when shot). `clearShot()` = line-of-fire; ranged units **march forward** if no LOS. Melee `reach` includes body size (so giants actually connect). Kiting at close range.
- **Movement/physics:** `physics(u,dt)` — gravity, land-on-platform-tops, **side-collision** vs walls, **wall-climb** (scale tall walls). Ledge hop for low steps is in the AI block; **ledge guard** stops units walking into deadly gaps. `legIK()` (two-bone, knee forward) + `arm2()` (elbow).
- **Damage:** `damage(t,dmg,kx,ky,src,soft)` — armour `dr` reduction, retaliation lock via `src`, knockback + semi-ragdoll jolt UNLESS `soft` (flame/fire/gas DoT pass soft so they don't ragdoll). `explode(x,y,team,dmg,rad,owner)`. `projDie(p)` handles aoe + hazard spawn + nuke flash.
- **Semi-ragdoll:** springy `u.lean` (torso tilt) + `u.hipKick` (recoil drives hips back). Tiny while walking, medium on shoot/hit.
- **Forms:** `drawHumanoid()` (stickman) vs `drawBall()` (countryball, paints `drawFlag()` clipped to a circle). `bodyStyle` switches which renders; gameplay identical (hitboxes via `centerY/halfW/halfH`).
- **Vehicles:** `makeVehicle`/`updateVehicle` (ground physics OR air flight w/ `alt`,`hover`), `drawVehicle` (shape chosen by `vt.gfx||vt.id`; turret barrel only for tank/apc/mech), `vehicleFire` (proj types `bullet|shell|arc|bomb|rocket`, supports `pellets`+`spread`, `pierce`).
- **Throwables/hazards:** lob weapons arc (ballistic) and detonate; molotov→fire pool, gas→slow cloud, C4→timed `det` charge. All in `hazards[]`, ticked each frame.
- **Strikes (one-use):** place a marker in setup; on Start it counts down then `launchStrike()` spawns a falling (air) or skimming (ground/torpedo) projectile. Nuke sets `screenFlash`. **Strike projectiles start at y<0 — the projectile bounds check excludes `p.strike` from the top-kill.**
- **Pierce:** capped at **3 targets** (per-bullet hit Set), no range limit (flies to map edge).
- **Death:** collapse to ground via `ragTarget`; corpses linger **10s** then fade; they don't block — living units walk over them.

## Gotchas
- `units[]` mixes units + vehicles. Always branch on `u.kind`. Use `centerY/halfW/halfH` for any hit math (works for both forms + vehicles).
- New vehicles should reuse a silhouette via `gfx:` rather than adding a draw branch, unless it needs a unique look.
- When adding a weapon: also add it to `WSHAPE` or it draws as a rifle.
- Canvas transforms must stay balanced (save/restore) — drawHumanoid/drawBall nest several.

## Verify / run
- Syntax: extract the `<script>` and `node --check` it (no HTML linter needed). E.g. `python3 -c "import re;open('/tmp/c.js','w').write(re.search(r'<script>(.*)</script>',open('index.html').read(),re.S).group(1))" && node --check /tmp/c.js`.
- Run: just open the file, or `python3 -m http.server`. A `.claude/launch.json` server named `tabs-game` serves the folder on :3456 → `/index.html`.
- Preview note: rAF throttles when the tab is backgrounded, so for screenshots drive it manually via eval: set up `units`, call `updateBattle(0.016)` in a loop, then `render()`, then screenshot.

## Conventions
- Keep everything in the single HTML file, vanilla JS, no dependencies.
- `node --check` before considering a change done. New weapons/vehicles: Andy playtests himself — don't over-verify, just confirm syntax + that it renders.
