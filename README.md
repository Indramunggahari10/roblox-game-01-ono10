# Crystal Caverns — a Roblox game for make.fun `roblox-game-01`

**The game:** a 3D collect-a-thon across three caverns. Collect every glowing
crystal, dodge lava and red spikes, ride jump pads, mind the crumbling
platforms, and step into the portal once it opens. Three lives, a timer, and
a win screen with your clear time. Lose all three lives and the caverns win.

- **Level 1 — Emerald Hollow:** 5 crystals, learn the jumps.
- **Level 2 — Spike Ridge:** 7 crystals, spikes, jump pads, narrower jumps.
- **Level 3 — Crumble Deep:** 9 crystals, crumbling platforms, spikes, pads.

**Controls:** WASD or arrow keys to move, SPACE to jump. R or P starts the
game and restarts it from an end screen. The HUD (top-centre, clear of
Roblox's top-left menu buttons) shows crystals, lives, time, and level.

## How it is built

Rojo-first project. Every script is a `.luau` file under `src/`; `rojo build`
writes `game.rbxl` from them.

| Script | Job |
|---|---|
| `src/shared/GameConfig.luau` | All tunables + the palette, in one place |
| `src/shared/LevelData.luau` | The three levels as pure data |
| `src/server/WorldBuilder.luau` | Turns level data into parts (lava, platforms, crystals, spikes, pads, portal, spawn) |
| `src/server/GameServer.server.luau` | Owns ALL game state; touch rules, lives, timer, level flow |
| `src/client/GameClient.client.luau` | HUD, start/win/lose screens, Play button, R/P restart |

The server owns state; the client only mirrors it over `StateUpdate` /
`Feedback` RemoteEvents and asks to play over `PlayRequest`. No assets are
downloaded and no external service is called.

## Rebuilding

```sh
rojo build default.project.json --output game.rbxl
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

## What the owner still has to do (Roblox Studio, Windows/macOS)

The game was built on Linux, where there is no Roblox Studio and no Roblox
account, so these steps need the owner's computer and Roblox account (one
that can already publish — at least 2 days old and past Roblox's age check).

1. **Open the place:** in Roblox Studio, open `game.rbxl`.
2. **Playtest:** press Play. Check the start screen, collect crystals, fall
   in lava once (lose a life, respawn), reach the portal, finish all three
   levels, and see the win screen. Fix anything that looks wrong in `src/`,
   then rebuild with `rojo build` (never edit the place in Studio and rebuild
   over it — Rojo-first only).
3. **Screenshots (3–4, while the game is running):** start screen, mid-game,
   win screen. Each at most 256 KiB, long side at most 1280 px, short side at
   least 480 px. Save them as `screenshots/1-start.png`, `2-play.png`,
   `3-end.png` (and optionally `4-....png`). Delete
   `screenshots/.screenshots-pending.md` once the real shots are in.
4. **Publish:** in Studio / Creator Dashboard, give the experience a
   description and genre, answer Roblox's content questions, and set it
   **Public**.
5. **Fill in `PLAY.json`:** `place_id` is the number in the play link
   (`https://www.roblox.com/games/<placeId>`), `universe_id` is the
   experience's id (after `experiences/` in the Creator Dashboard address,
   or `game.GameId` in Studio). Leave no zeros.
6. **Re-run the entry program** and check the output:
   ```sh
   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
   ```
   It copies `game.rbxl`, `src/`, `screenshots/`, `PLAY.json` to `out/` and
   writes `out/dossier.json`.
7. **Submit** with the kit CLI (bundle transcripts, then submit) — the parent
   agent handles this step after 1–6 are done.

## Status

- [x] Game built (5 scripts, all compile under Luau)
- [x] `game.rbxl` built by Rojo 7.7.0
- [x] Place + scripts verified locally with the kit's own library:
      16 instances, 5 scripts, 100.0% of script bytes matched to `src/`
      (full `dossier.json` is blocked until step 3: `buildDossier` refuses
      a `screenshots/` with no image, by design — no screenshot was faked)
- [ ] Real screenshots from Studio playtest
- [ ] Published as Public + `PLAY.json` filled in
- [ ] Submitted
