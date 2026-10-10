-- Placeholder generated payload. `node scripts/build-addon-data.mjs` replaces
-- this file in CI/release builds from `data/talents/*.json`.
local pack = {
    id = "WoWForeverCompanion_Data_Talents",
    version = "2026-10-10-v1",
    gameVersion = "1.60.1",
    interface = 16001,
    datasets = { talents = { classes = {} } },
    search = {},
}

if type(WoWForeverCompanion_RegisterDataPack) == "function" then
    WoWForeverCompanion_RegisterDataPack(pack)
else
    WoWForeverCompanionPendingPacks = WoWForeverCompanionPendingPacks or {}
    table.insert(WoWForeverCompanionPendingPacks, pack)
end
