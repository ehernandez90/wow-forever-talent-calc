# WoW Forever Companion addon

Current target: WoW: Forever beta 1.60.1, interface `16001`.

The addon is split into a lightweight core plus data packs. CI generates the packs from canonical repository JSON and publishes an installable ZIP artifact.

## Folders

- `WoWForeverCompanion/` — core, UI, modules, SavedVariables, search and data-pack registry.
- `WoWForeverCompanion_Data_Core/` — generated version/update/catalog data.
- `WoWForeverCompanion_Data_Talents/` — generated full class/talent data.
- `tests/` — Lua 5.1 test harness and WoW API stubs; do not install this folder in-game.

## Build locally

From the repository root:

```bash
node scripts/validate-companion-data.mjs
node scripts/build-addon-data.mjs
lua5.1 addon/tests/run.lua
```

The committed `Generated.lua` files are lightweight bootstraps. Release/CI builds overwrite them with generated data from the repository before packaging.

## Install a CI artifact

Extract the artifact so these folders sit directly under Forever's AddOns directory:

```text
Interface/AddOns/WoWForeverCompanion/
Interface/AddOns/WoWForeverCompanion_Data_Core/
Interface/AddOns/WoWForeverCompanion_Data_Talents/
```

Enable the three entries in the addon list. The two data packs are load-on-demand.

## Commands

- `/wfc` — toggle the main window.
- `/wfc tab <id>` — open a module (`dashboard`, `leveling`, `class`, `quests`, `professions`, `gathering`, `instances`, `reputation`, `travel`, `items`, `updates`, `search`).
- `/wfc search <words>` — universal search across loaded/generated data.
- `/wfc status` — addon version, data revision, game build/interface and loaded pack counts.
- `/wfc help` — command summary.

## In-client smoke test

1. On the character screen, confirm the addon is not marked out of date.
2. Log in and run `/wfc status`; interface should report `16001` on the current Forever beta.
3. Run `/wfc`; confirm the window opens and all tabs can be clicked without Lua errors.
4. Open **Class**; the talent pack should load on demand and show the current character's class/tree/talent counts.
5. Run `/wfc search warrior` (or a known talent name); confirm generated data is found.
6. Open **Updates**; the core data pack should load and show the current data review date/source list.
7. Move the window, run `/reload`, and confirm its position/settings persist.
8. Enter combat and use informational tabs only; the addon must not attempt protected gameplay actions. Loading a not-yet-loaded data pack during combat should fail safely and tell the player to retry after combat.

## Development rule

Do not put canonical game facts directly into UI modules. Add them to the repository data layer and compile them into a pack. This is what keeps the website and addon synchronized as the project grows.
