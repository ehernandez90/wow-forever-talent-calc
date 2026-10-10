-- Placeholder generated payload. `node scripts/build-addon-data.mjs` replaces
-- this file in CI/release builds from canonical repository data.
local pack = {
    id = "WoWForeverCompanion_Data_Core",
    version = "2026-10-10-v1",
    gameVersion = "1.60.1",
    interface = 16001,
    datasets = {
        updates = {
            lastReviewed = "2026-10-10",
            classCount = 9,
            recent = {
                "Forever Class Deep Dive — Mage and Shaman",
                "Forever Class Deep Dive — Rogue and Warlock",
                "Forever Class Deep Dive — Priest and Warrior",
                "Forever Class Deep Dive — Hunter and Druid",
            },
        },
    },
    search = {
        { id = "updates:forever", type = "update", title = "WoW Forever Updates", subtitle = "Current vs upcoming changes", keywords = "class talent patch beta rebalance", dataset = "updates", recordId = "forever" },
    },
}

if type(WoWForeverCompanion_RegisterDataPack) == "function" then
    WoWForeverCompanion_RegisterDataPack(pack)
else
    WoWForeverCompanionPendingPacks = WoWForeverCompanionPendingPacks or {}
    table.insert(WoWForeverCompanionPendingPacks, pack)
end
