# Companion data

This directory is the expansion point for knowledge used by both the web application and the in-game WoW Forever Companion addon.

`manifest.json` is the platform catalog. It declares supported game/interface versions, user-facing modules, canonical dataset locations and the addon data pack that will eventually carry each dataset.

Do not copy the same fact into several feature-specific files. Prefer normalized records and relationships. For example, one recipe record should link to its profession, output item, material items, trainer/vendor/drop source and skill range; Leveling, Professions, Items and Search can all render that same record differently.

Every promoted record should eventually include stable IDs, provenance, verification state and build validity. Community sources can seed research but must not silently become verified facts.

The addon cannot fetch these files from GitHub at runtime. Build scripts compile canonical JSON into Lua data packs that are shipped with the addon release.
