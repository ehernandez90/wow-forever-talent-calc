# WoW Forever Companion

This fork expands the MIT-licensed **WoW Forever Talent Calculator** into a shared data backbone for a much larger **World of Warcraft: Forever** web application and in-game companion addon.

The design goal is simple: keep reviewed game knowledge in this repository once, then compile it into the website and an offline WoW addon so common questions can be answered in-game without constantly opening external sites.

## Platform direction

The long-term companion covers:

- Dashboard / “what should I do now?” recommendations;
- leveling routes and milestones;
- class abilities, talents, builds and class quests;
- quests and quest chains;
- professions, recipes and trainers;
- gathering (mining, herbalism, skinning, fishing and future Forever systems);
- world/zone/NPC/vendor/rare/world-buff reference;
- dungeons, raids, bosses, quests, loot and attunements;
- reputations and rewards;
- travel/transport connections;
- items and reverse source lookup;
- gear upgrade/source planning;
- PvP/honor/rank/reward reference;
- current vs upcoming game/class/talent updates;
- universal search across every loaded data pack;
- favorites, notes and checklists as cross-cutting character state.

See `docs/COMPANION-ARCHITECTURE.md` for the architecture and `docs/DATA-ACQUISITION-ROADMAP.md` for the acquisition order/source policy.

## What exists in the companion backbone now

- The original React/Vite talent calculator and its reviewed talent data/pipeline.
- A new **Updates** page tracking official class-change sources and Current/Upcoming intent.
- A source/trust policy that keeps community signals separate from promoted facts.
- `data/companion/manifest.json`, the cross-surface module/dataset catalog.
- A WoW: Forever addon core under `addon/WoWForeverCompanion` targeting interface `16001`.
- Clickable addon modules for Dashboard, Leveling, Class, Quests, Professions, Gathering, World, Instances, Reputation, Travel, Items, Gear, PvP, Updates and Search.
- SavedVariables, slash commands, universal-search and load-on-demand data-pack registries.
- Generated Core and Talent data packs; CI compiles the existing JSON talent database into Lua rather than maintaining a second copy by hand.
- Lua 5.1 tests with WoW API stubs plus data/source validation.
- GitHub Actions that build an installable addon ZIP artifact and run the existing web tests/build.

### Addon commands

```text
/wfc
/wfc tab <id>
/wfc search <words>
/wfc status
/wfc help
```

See `addon/README.md` for build/install/smoke-test instructions.

## Offline-first addon model

WoW addon Lua is sandboxed and cannot query this website/GitHub in realtime. The repository is therefore the source of truth and releases carry compiled data:

```text
sources -> review/validation -> canonical JSON -> web app
                                      |
                                      +-> Lua data-pack compiler -> addon ZIP
```

As the database grows, large packs can remain load-on-demand so the player does not pay the memory/startup cost for every quest, recipe and item at login.

---

# Original WoW Forever Talent Calculator foundation

The project began as a fan-made talent calculator for **World of Warcraft: Forever** (Classic+), announced at BlizzCon 2026. The talent trees were on stream months before anyone could log in, so the original site was built from that footage: spend points, share a build as a link, and see what changed against Classic Era.

Upstream/original project: **https://github.com/Deradon/wow-forever-talent-calc**

## Talent calculator features inherited from upstream

- **All nine classes**, 469 of 470 talents, with the Classic-style rules: 51 points, five per row, prerequisite arrows and tier gating.
- **Shareable builds.** `#/warrior?v=1&t=...` is the whole build; also a short build code, Discord-ready summary, print view and `embed=1`.
- **Honest tooltips.** Records preserve confidence/provenance instead of presenting uncertain readings as official facts.
- **What changed vs Classic Era** with moved/new/reworded/rank-count/removal comparisons.
- **Races** and race/class matrix.
- **Spellbook** coverage from the original stream capture.
- **Keyboard and touch** controls, undo/redo and tooltip controls.

## Where the original talent data came from

A local vision model read talent tooltips from the BlizzCon 2026 demo stream, OpenCV placed readings in grid cells, matched icons and traced prerequisite arrows. Only rank 1 was visible in the footage, so higher ranks in the original dataset may be extrapolated from matching Classic patterns. Every record preserves provenance and the project does not claim uncertain data is official.

Important inherited caveats include:

- numbers/ranks derived from early footage can be less reliable than talent identity/position;
- many records still need human/current-client verification;
- one original Mage talent was not visible in the source footage;
- some point-system rules began as Classic assumptions;
- the Classic Era comparison is reference data, not a database dump.

The Companion direction is specifically designed to improve this over time with build-aware snapshots and verified current-client data rather than silently overwriting history.

## Development

Requires Node 22+ for the web/data-pack tooling and Python/`uv` for the inherited extraction pipeline. `ffmpeg` and `yt-dlp` are only needed to re-run video extraction.

```bash
# site
cd web
npm install
npm run dev
npm test
npm run e2e
npm run build

# inherited talent pipeline
cd pipeline
uv run pytest
uv run python validate.py --check ../data/talents/*.json

# companion validation / addon data generation (from repo root)
node scripts/validate-companion-data.mjs
node scripts/validate-source-registry.mjs
node scripts/build-addon-data.mjs
lua5.1 addon/tests/run.lua
```

`data/talents/<class>.json` remains the current talent source of truth. The broader companion catalog lives under `data/companion/` and will grow domain by domain.

## License, sources and affiliation

Project code remains MIT (`LICENSE`) subject to retained upstream attribution. Blizzard game content (including talent names/descriptions/icons/screenshots) is property of Blizzard Entertainment and is not made MIT by this repository.

Third-party source material is not automatically copied into the project. `data/companion/sources.json` documents trust and reuse boundaries; for example, Warcraft Wiki text is subject to its CC BY-SA terms, while proprietary calculators/guides are reference signals unless reuse permission/licensing is established.

**Not affiliated with, endorsed by, or connected to Blizzard Entertainment.** World of Warcraft is a trademark of Blizzard Entertainment, Inc. This is an unofficial fan project.
