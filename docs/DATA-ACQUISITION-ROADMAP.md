# Companion data acquisition roadmap

The addon becomes valuable only if its database is broad **and** trustworthy. This document defines the order in which data should be acquired and the quality gate before a record is shipped.

## Principle: facts once, many views

Do not build a separate “leveling database”, “profession database” and “item database” containing copies of the same facts. Normalize core entities (item, quest, NPC, zone, recipe, instance, faction, transport, etc.) and link them by stable IDs. Guides/routes are derived records that point at those entities.

This gives the player useful reverse lookup automatically:

- an item can show every quest/vendor/drop/recipe/reputation source;
- a quest can show its chain, zone, NPCs, rewards and instance;
- a recipe can show its materials, output item, trainer/vendor/drop source and skill range;
- a dungeon can show every related quest, boss, loot item and attunement step.

## Acquisition order

### P0 — current foundation

Already present or started:

- all class talent trees;
- current/upcoming class-change tracking;
- source/provenance metadata;
- build/interface versioning;
- addon data-pack compiler.

### P1 — class completeness

Add:

- abilities/spells learned by level;
- class trainers;
- class quests and rewards;
- resource/mechanic notes;
- class-specific leveling milestones;
- recommended talent builds as **derived/versioned guides**, never mixed into raw talent facts.

Why first: it immediately combines with the existing talent dataset and makes the Class + Leveling tabs useful on every character.

### P2 — world graph + quest graph

Add normalized:

- zones/subzones and level ranges;
- NPCs with coordinates/roles;
- quests, prerequisites, chains, objectives, rewards and follow-ups;
- transport/travel edges;
- flight masters and service NPCs.

Then create leveling routes as ordered references to those records.

The route should explain why a step is recommended and remain editable independently of the raw quest record.

### P3 — professions, gathering and item graph

Add:

- professions and skill thresholds;
- trainers;
- recipes;
- material inputs and outputs;
- vendor/drop/quest/reputation recipe sources;
- mining/herbalism/skinning/fishing sources;
- zone/skill distributions and route points;
- item records shared by every other domain.

Once the dependency graph exists, the addon can answer questions such as “where do I get all materials for this recipe?” and “what can I craft with this item?” without hand-written duplicate guides.

### P4 — dungeons/raids, reputation and world preparation

Add:

- instance entrances and recommended ranges;
- bosses/encounters;
- loot-source links;
- dungeon/raid quests;
- attunements;
- factions, repeatables/turn-ins and rewards;
- consumables and world buffs;
- preparation/checklist templates.

### P5 — gear + PvP + optimization

Build derived layers over the item/source graph:

- gear upgrades by level/class/role;
- pre-BiS/BiS lists with exact source and version;
- stat/role guidance with provenance;
- honor/rank/battleground/vendor/reward references;
- optional recommendation scoring that always exposes its inputs/method.

## Source strategy

`data/companion/sources.json` is the source registry and licensing guardrail.

Preferred order:

1. first-party/current-build client observations and identifiers;
2. official Blizzard announcements/patch notes;
3. secondary sources cross-checked against the current build;
4. community sources as leads only.

Do not automatically scrape proprietary third-party calculators/guides into the repository. Warcraft Wiki text is CC BY-SA 4.0 where lawfully licensable; copied/adapted text therefore needs attribution and ShareAlike handling. Prefer independently structured factual records so the project can keep licensing boundaries clear.

## Record promotion states

Every large imported domain should support these states:

- `candidate` — imported/discovered, not trusted by user-facing guides;
- `reviewed` — shape/source checked;
- `verified` — current-build fact confirmed;
- `derived` — computed/recommended from verified records;
- `deprecated` — retained for history but no longer current.

The website can expose review tooling. Only promoted records should enter release data packs unless a UI explicitly labels them experimental/unverified.

## Versioning

Facts that change must be snapshot-aware. Prefer validity fields such as:

- `firstBuild` / `lastBuild`;
- `snapshotId`;
- `sourceId` and source URL/reference;
- verification date/build.

Never rewrite history merely to make “latest” easy. The addon can compile only the current release snapshot while the repository and web app retain older snapshots for comparisons.

## Automation adapters

Acquisition code should eventually live under source-specific adapters, for example:

```text
pipeline/sources/
  blizzard_news/
  client_data/
  observed/
  licensed_imports/
```

Adapters write candidate normalized JSON, not directly to release data. Promotion/validation is a separate step.

## Quality gates before a domain ships

A new domain is release-ready when:

1. its schema/contract is documented;
2. IDs are stable and unique;
3. relationships resolve;
4. source/provenance is present;
5. current-build validity is known or visibly marked unknown;
6. generator output is deterministic;
7. Lua pack loads under the 5.1 harness;
8. universal search indexes it;
9. at least one UI module renders it;
10. an in-client smoke checklist exists.

This is intentionally stricter than “we found a dataset”: the goal is a knowledge backbone that remains maintainable after years of Forever changes.
