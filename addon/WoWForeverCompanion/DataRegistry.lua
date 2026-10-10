local addonName, ns = ...

ns.Data = ns.Data or {}
local Data = ns.Data

Data.packs = Data.packs or {}
Data.datasets = Data.datasets or {}
Data.searchEntries = Data.searchEntries or {}

local function assertType(value, expected, label)
    if type(value) ~= expected then
        error((label or "value") .. " must be " .. expected, 3)
    end
end

local function normalizePack(pack)
    assertType(pack, "table", "pack")
    assertType(pack.id, "string", "pack.id")
    assertType(pack.version, "string", "pack.version")
    pack.datasets = pack.datasets or {}
    pack.search = pack.search or {}
    assertType(pack.datasets, "table", "pack.datasets")
    assertType(pack.search, "table", "pack.search")
    return pack
end

function Data:RegisterPack(pack)
    pack = normalizePack(pack)
    if self.packs[pack.id] then
        error("data pack already registered: " .. pack.id, 2)
    end

    self.packs[pack.id] = pack

    for datasetId, dataset in pairs(pack.datasets) do
        if self.datasets[datasetId] then
            error("dataset already registered: " .. datasetId, 2)
        end
        self.datasets[datasetId] = dataset
    end

    for i = 1, #pack.search do
        local entry = pack.search[i]
        if type(entry) == "table" and type(entry.id) == "string" and type(entry.title) == "string" then
            entry.pack = entry.pack or pack.id
            self.searchEntries[#self.searchEntries + 1] = entry
        end
    end

    if ns.Events and ns.Events.Emit then
        ns.Events:Emit("DATA_PACK_REGISTERED", pack.id)
    end

    return pack
end

function Data:GetPack(id)
    return self.packs[id]
end

function Data:GetDataset(id)
    return self.datasets[id]
end

function Data:GetSearchEntries()
    return self.searchEntries
end

function Data:HasPack(id)
    return self.packs[id] ~= nil
end

function Data:PackCount()
    local count = 0
    for _ in pairs(self.packs) do
        count = count + 1
    end
    return count
end

function Data:DatasetCount()
    local count = 0
    for _ in pairs(self.datasets) do
        count = count + 1
    end
    return count
end

function Data:ResetForTests()
    self.packs = {}
    self.datasets = {}
    self.searchEntries = {}
end

-- Data packs are separate addons and do not share this addon's namespace table.
-- This one deliberately unique global is their registration bridge.
_G.WoWForeverCompanion_RegisterDataPack = function(pack)
    return Data:RegisterPack(pack)
end

-- Packs can load before the core in unusual test/dev scenarios. Consume any
-- queued payloads once the registry exists.
if type(_G.WoWForeverCompanionPendingPacks) == "table" then
    for i = 1, #_G.WoWForeverCompanionPendingPacks do
        Data:RegisterPack(_G.WoWForeverCompanionPendingPacks[i])
    end
    _G.WoWForeverCompanionPendingPacks = nil
end
