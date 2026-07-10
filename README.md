# Iron Tide

Browser naval battle sandbox with campaign theaters, ship upgrades, aircraft, ground assaults, and an optional WebSocket relay server for multiplayer room experiments.

The main game is self-contained in `index.html` and runs directly in a modern browser. The relay server lives in `server/` for local or Railway deployment.

## Project Layout

- `index.html` - main Iron Tide game.
- `battle-sim.html` - older top-down battle simulator prototype.
- `mech-battles.html` - mech battle prototype.
- `campaign-map-viewer.html` - campaign map gallery/viewer.
- `campaign-map-atlas.svg` - combined campaign map atlas.
- `campaign-maps/` - individual SVG campaign theater maps.
- `server/` - Node.js WebSocket relay server and deploy notes.

## Play Locally

Open `index.html` in any modern desktop browser.

For the relay server:

```bash
cd server
npm install
npm start
```

Then check:

- `http://localhost:3000/health`
- `http://localhost:3000/servers`
- `ws://localhost:3000/play`

## Features

- Ship selection with different hull classes and combat roles.
- Naval combat with shells, aircraft, submarines, upgrades, harbor building, and campaign progression.
- Tactical map view and unlockable campaign theaters.
- Land assault flow with ground units, swimming, foot combat, and beachhead pressure.
- Optional multiplayer relay primitives for rooms, teams, spawn points, state packets, firing, and events.

## Notes

This repository is intentionally lightweight: the playable client is vanilla JavaScript and Canvas 2D with no build step. The server requires Node.js 20+.
