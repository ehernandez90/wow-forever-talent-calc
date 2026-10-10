local Stub = dofile("addon/tests/wow_stubs.lua")

local ns = {}
local failures = 0
local tests = 0

local function loadAddon(path, name, namespace)
    local chunk, err = loadfile(path)
    if not chunk then error(err) end
    return chunk(name or "WoWForeverCompanion", namespace or ns)
end

local function test(name, fn)
    tests = tests + 1
    local ok, err = pcall(fn)
    if ok then
        print("ok - " .. name)
    else
        failures = failures + 1
        print("not ok - " .. name .. ": " .. tostring(err))
    end
end

local function equal(actual, expected, message)
    if actual ~= expected then
        error((message or "values differ") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

local function truthy(value, message)
    if not value then error(message or "expected truthy value", 2) end
end

local function countKeys(tbl)
    local count = 0
    for _ in pairs(tbl or {}) do count = count + 1 end
    return count
end

-- Match the TOC load order. UI.lua only defines functions; no real frame is
-- constructed until ns:Initialize is called, so the minimal frame stub is enough.
loadAddon("addon/WoWForeverCompanion/DataRegistry.lua")
loadAddon("addon/WoWForeverCompanion/Search.lua")
loadAddon("addon/WoWForeverCompanion/Core.lua")
loadAddon("addon/WoWForeverCompanion/Modules.lua")
loadAddon("addon/WoWForeverCompanion/UI.lua")

-- Generated packs are produced by scripts/build-addon-data.mjs before this test
-- in CI. Loading them proves the JSON -> Lua -> registry boundary.
loadAddon("addon/WoWForeverCompanion_Data_Core/Generated.lua", "WoWForeverCompanion_Data_Core", {})
loadAddon("addon/WoWForeverCompanion_Data_Talents/Generated.lua", "WoWForeverCompanion_Data_Talents", {})

test("registers all navigation modules in stable order", function()
    local modules = ns:GetModules()
    equal(#modules, 15, "module count")
    equal(modules[1].id, "dashboard")
    equal(modules[#modules].id, "search")
end)

test("initializes SavedVariables defaults without losing existing values", function()
    local db = ns:InitializeDatabase({ favorites = { warrior = true } })
    equal(db.schemaVersion, 1)
    equal(db.selectedModule, "dashboard")
    truthy(db.favorites.warrior)
    truthy(type(db.window) == "table")
end)

test("generated core and talent packs register", function()
    truthy(ns.Data:HasPack("WoWForeverCompanion_Data_Core"), "core pack missing")
    truthy(ns.Data:HasPack("WoWForeverCompanion_Data_Talents"), "talent pack missing")
    truthy(ns.Data:GetDataset("updates"), "updates dataset missing")
    truthy(ns.Data:GetDataset("talents"), "talents dataset missing")
end)

test("compiled talent pack contains all nine classes", function()
    local talents = ns.Data:GetDataset("talents")
    equal(countKeys(talents.classes), 9, "compiled class count")
    truthy(talents.classes.warrior, "warrior class missing")
    truthy((talents.classes.warrior.talentCount or 0) > 0, "warrior talent count should be positive")
end)

test("universal search ranks exact or title matches", function()
    local results = ns.Search:Find("warrior", { limit = 10 })
    truthy(#results > 0, "warrior search returned no results")
    local foundClass = false
    for i = 1, #results do
        if results[i].id == "class:warrior" then foundClass = true end
    end
    truthy(foundClass, "warrior class record not in results")
end)

test("universal search filters by type", function()
    local results = ns.Search:Find("warrior", { limit = 50, type = "talent" })
    for i = 1, #results do
        equal(results[i].type, "talent")
    end
end)

test("duplicate data packs are rejected", function()
    local ok = pcall(function()
        ns.Data:RegisterPack({ id = "WoWForeverCompanion_Data_Core", version = "duplicate", datasets = {}, search = {} })
    end)
    equal(ok, false, "duplicate pack should error")
end)

test("status reports Forever interface and data revision", function()
    local info = ns:GetRuntimeInfo()
    equal(info.gameVersion, "1.60.1")
    equal(info.interface, 16001)
    equal(info.dataRevision, "2026-10-10-v1")
end)

test("slash status command is pure enough to test and writes chat", function()
    Stub.resetChat()
    local result = ns:HandleSlashCommand("status")
    equal(result, "status")
    truthy(#Stub.chat >= 4, "status should write multiple chat lines")
end)

test("combat prevents loading an unloaded data pack", function()
    Stub.setCombat(true)
    local ok, err = ns:LoadDataPack("WoWForeverCompanion_Data_Future")
    Stub.setCombat(false)
    equal(ok, false)
    truthy(string.find(err, "combat", 1, true), "expected combat error")
end)

test("class module renders compiled player class summary", function()
    local module = ns:GetModule("class")
    local lines = module:Render()
    local text = table.concat(lines, "\n")
    truthy(string.find(text, "Warrior", 1, true), "class render should mention Warrior")
    truthy(string.find(text, "Talents:", 1, true), "class render should include talent count")
end)

test("update module reads generated update dataset", function()
    local module = ns:GetModule("updates")
    local lines = module:Render()
    local text = table.concat(lines, "\n")
    truthy(string.find(text, "Last reviewed", 1, true), "update render missing review date")
end)

print(string.format("\n%d tests, %d failure(s)", tests, failures))
if failures > 0 then os.exit(1) end
