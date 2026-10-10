# WoW Forever Companion platform architecture

Status: v1 backbone, October 2026.

This repository is no longer treated as only a talent calculator. The target is a single, versioned knowledge platform that produces two user surfaces from the same reviewed data:

1. the web application, for deep browsing, comparison, editing/review and shareable links; and
2. an in-game WoW: Forever addon, for fast offline access without leaving the client.

The repository is the source of truth. The addon is a compiled consumer of repository data, not a web client.

## Product goal

The in-game experience should answer the common question **“what do I need to know or do right now?”** without making the player alt-tab.

The long-term navigation model is:

- **Dashboard** — character-aware summary: level, class, zone, professions, recent/favorite guides, and “do next” recommendations.
- **Leveling** — zone bands, quest routes, kill/collect objectives, travel transitions, class-specific leveling notes and optional checklists.
- **Class** — class overview, abilities by level, talent trees, talent revisions, rotations/priorities, stat guidance and class quests.
- **Quests** — searchable quest database, chains, prerequisites, objectives, coordinates, rewards, follow-ups, breadcrumbs and dungeon/raid quests.
- **Professions** — trainers, skill breakpoints, recipes, material requirements, source/vendor/drop information, specialization notes and skill-up paths.
- **Gathering** — mining/herbalism/skinning/fishing and any Forever-specific gathering system; skill requirements, zones, node/fish tables and route data.
- **Instances** — dungeons and raids: level ranges, entrances, quests, bosses, loot, lockouts, attunements and preparation checklists.
- **Reputation** — factions, repeatables, turn-ins, rewards and efficient reputation paths.
- **Travel** — flight masters, boats/zeppelins/portals, hearth suggestions, zone connections and travel instructions.
- **Items** — “where does this come from?” lookup across vendors, quests, drops, crafting, reputation and world sources.
- **Updates** — current vs upcoming snapshots, Blizzard announcements, build/version history and class/talent diffs.
- **Search** — universal search over every registered dataset.

Planned/high-value extensions that fit the same platform:

- gear upgrade/source browser and pre-BiS/BiS lists with provenance;
- vendors, trainers and services;
- consumables, world buffs and preparation lists;
- attunement tracker;
- PvP/honor/rank/reward reference;
- zone encyclopaedia and rare/elite reference;
- loot tables and drop-source reverse lookup;
- recipe/material dependency trees;
- favorites, pinned records, personal notes and checklists;
- route presets and “what should I do next?” recommendations;
- character-specific completion state stored in SavedVariables;
- data-version/changelog viewer so a player can see what changed after an addon update.

The project should prefer **information and decision support** over automation. Protected gameplay actions, combat decisions, or anything requiring secure execution remain the game’s responsibility.

## Important WoW addon constraint: offline data

WoW addon Lua runs in a sandbox. It cannot perform arbitrary HTTP requests to GitHub or the website while the game is running. Therefore the architecture is:

```
public/official sources
        |
        v
 acquisition + review + validation
        |
        v
 canonical JSON in this repository
        |                    |
        |                    +--> web build
        |
        +--> compiler --> Lua data packs --> addon ZIP
```

The addon should display its embedded data revision and supported game build. Updating information means shipping a new addon/data-pack release, not querying the website live.

## Forever runtime target

Current beta target:

- game version: `1.60.1`
- addon interface: `16001`
- Lua: 5.1-compatible code only
- UI family: modern/Mainline-derived APIs, with Forever’s secure/secret-value restrictions

Never assume Classic Era’s old API surface just because the gameplay is Classic-like. The runtime compatibility layer should stay small and explicit.

## Repository layout

Existing folders remain valid. New platform folders are additive:

```
data/                         canonical reviewed game data
  talents/                    existing talent source of truth
  companion/                  platform catalog/manifests and future domains
  schema/                     machine validation schemas

pipeline/                     extraction/import/review/promote tooling
scripts/                      cross-domain compilers and validators
web/                          React/Vite web application

addon/
  WoWForeverCompanion/        lightweight core addon and UI shell
  WoWForeverCompanion_Data_*/ generated/loadable data packs
  tests/                      Lua test harness + WoW API stubs

docs/
  COMPANION-ARCHITECTURE.md   this document
```

## Canonical data rules

Every long-lived record should eventually have:

- a stable ID that is not derived from screen position;
- a domain/type;
- a game build or validity range where relevant;
- source/provenance;
- verification status;
- structured relationships to other records by ID;
- update/revision metadata;
- enough text fields to build a universal search index.

Website presentation fields should not become the canonical model. The addon and website should be generated from the same domain records.

### Source trust

Use a visible trust tier rather than treating all sources as equivalent:

1. **Official/observed** — Blizzard client data, Blizzard announcements, observed in-game values.
2. **Verified secondary** — high-quality references confirmed against the current Forever build.
3. **Community signal** — useful lead, but not promoted automatically into canonical game facts.
4. **Derived** — recommendations/calculations produced from verified facts; always label the methodology/version.

For changing systems, never silently overwrite history. Create a new snapshot and keep the previous one addressable.

## Data domains

The catalog is designed to grow into these domains:

| Domain | Core records / relationships |
|---|---|
| classes | class, specialization/tree, talent, ability, class quest, trainer |
| leveling | route, step, level band, zone transition, recommendation |
| quests | quest, chain, objective, NPC, location, reward, prerequisite |
| professions | profession, trainer, recipe, material, skill range, source |
| gathering | node/fish/creature source, skill threshold, zone/location, route |
| world | zone, subzone, NPC, vendor, service, coordinate |
| items | item, source, vendor price, reward, drop, recipe output/input |
| instances | dungeon/raid, entrance, boss, encounter note, loot, lockout |
| reputation | faction, standing, source, turn-in, reward |
| travel | node, edge/connection, transport type, requirements |
| pvp | honor/rank, objective, vendor, reward |
| updates | build, announcement, snapshot, diff, verification state |
| guides | recommendation set derived from other domains, with provenance |

## Addon architecture

The addon is intentionally split into **core + data packs**. A massive static database should not all initialize into Lua tables at login.

### Core addon

`WoWForeverCompanion` owns:

- SavedVariables and character preferences;
- module registry;
- data-pack registry;
- universal search API;
- main window/tab navigation;
- diagnostics/version screen;
- favorites/checklist state;
- compatibility wrappers for Forever API differences.

It should stay small enough to load on every character.

### Data packs

Generated packs register data with the core. As the database grows, packs can be `LoadOnDemand` and grouped by use case, for example:

- `WoWForeverCompanion_Data_Core`
- `WoWForeverCompanion_Data_Talents`
- `WoWForeverCompanion_Data_Quests`
- `WoWForeverCompanion_Data_Professions`
- `WoWForeverCompanion_Data_World`
- `WoWForeverCompanion_Data_Instances`

A release can ship all folders in one ZIP while still allowing WoW to load heavy packs only when a tab/search requires them.

### Module contract

A UI module has a stable ID, title, order, optional required packs, and a renderer/controller. Modules do not own canonical data. They query the data registry.

That separation allows the same quest database to power Leveling, Quests, Professions, Items and Search without duplicating records.

## Search as a first-class feature

Universal search is not an afterthought. Every generated pack should include compact normalized search records:

- record type/domain;
- stable record ID;
- title;
- subtitle/context;
- normalized keywords;
- pointer back to the owning dataset.

This enables searches such as:

- `windfury`
- `blacksmith 225 trainer`
- `scarlet monastery quests`
- `mithril where`
- `warrior level 40`

without scanning giant nested Lua structures on every keystroke.

## Character-aware recommendations

The addon may safely use available player state such as level/class/zone/profession information to filter the knowledge base. Recommendation logic must be deterministic and explainable.

Examples:

- show leveling zones that overlap the current level;
- show newly available class abilities/quests;
- show nearby profession trainers;
- show dungeon quests before entering an instance;
- show recipes appropriate to the current profession skill;
- show an upcoming talent/class rebalance badge for the player’s class.

The initial backbone exposes the module and data APIs; increasingly smart recommendations can be added as datasets arrive.

## Versioning and updates

Track three separate versions:

1. **addon version** — code/UI release;
2. **data revision** — repository knowledge snapshot;
3. **game build/interface** — Forever client version the data/code was verified against.

A record can be valid for one or more game builds. The Updates module should surface mismatches instead of pretending stale data is current.

## Build pipeline

The build pipeline should be deterministic:

1. validate canonical data;
2. generate compact Lua packs;
3. generate search indexes;
4. run Lua unit tests under 5.1-compatible syntax;
5. run web type/unit tests;
6. stage an installable addon directory tree;
7. create a CI artifact ZIP;
8. later: publish tagged GitHub releases and distribution-platform packages.

No secrets or web credentials belong in the addon.

## Testing strategy

### Static/data tests

- manifest/schema validation;
- unique IDs and relationship integrity;
- supported-build metadata present;
- source/provenance required for promoted records;
- deterministic generator output;
- no unsupported Lua syntax in generated code.

### Lua unit tests

A tiny WoW API stub environment exercises the pure application layer:

- module registration/order;
- data-pack registration;
- duplicate protection;
- search ranking/filtering;
- SavedVariables defaults/migrations;
- slash-command routing;
- data-pack compatibility checks.

### In-client smoke test

For every supported Forever build:

1. addon appears without “out of date” warning;
2. `/wfc` opens/closes the window;
3. each tab opens without a Lua error;
4. search finds a known class/talent record;
5. `/reload` preserves settings/favorites;
6. data revision/build is visible;
7. combat does not trigger forbidden/protected operations.

## Delivery phases

### Phase 0 — backbone (this branch)

- platform architecture and catalog;
- core addon shell;
- module/data/search registries;
- initial tab UI;
- talent-data compiler hook;
- Lua/Node validation harness;
- CI artifact build.

### Phase 1 — talent/class parity

- compile the existing full talent dataset into the addon;
- actual Current/Upcoming talent snapshots;
- abilities-by-level and class quests;
- class-specific search and change badges.

### Phase 2 — quests + leveling

- quest/zone/NPC/location schemas and imports;
- leveling routes/checklists;
- quest chain browser and “near my level” recommendations.

### Phase 3 — professions + gathering + items

- recipes/trainers/material dependency graph;
- gathering source/zone/skill tables;
- reverse item-source lookup.

### Phase 4 — instances/world/reputation/travel

- dungeon/raid quests, bosses and loot;
- reputations and rewards;
- transport graph, vendors and services.

### Phase 5 — optimization layer

- gear planning;
- build/route presets;
- character-aware recommendations;
- favorites/notes/checklists and export/import codes.

The project should be useful at the end of every phase; no phase requires the entire database to be complete before shipping.