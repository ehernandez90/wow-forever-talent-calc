local addonName, ns = ...

local function safePlayerContext()
    local level = type(UnitLevel) == "function" and UnitLevel("player") or nil
    local className, classFile
    if type(UnitClass) == "function" then
        className, classFile = UnitClass("player")
    end
    local zone = type(GetRealZoneText) == "function" and GetRealZoneText() or nil
    return {
        level = level or "?",
        className = className or "Unknown class",
        classFile = classFile and string.lower(classFile) or nil,
        zone = zone or "Unknown zone",
    }
end

local function datasetState(id)
    local dataset = ns.Data:GetDataset(id)
    return dataset and "loaded" or "not loaded"
end

local function placeholder(title, datasets, extra)
    local lines = {
        title,
        "",
        "This module is part of the platform backbone and will populate as its canonical datasets are added.",
    }
    if datasets and #datasets > 0 then
        lines[#lines + 1] = ""
        lines[#lines + 1] = "Datasets:"
        for i = 1, #datasets do
            lines[#lines + 1] = "  • " .. datasets[i] .. " — " .. datasetState(datasets[i])
        end
    end
    if extra then
        lines[#lines + 1] = ""
        lines[#lines + 1] = extra
    end
    return lines
end

ns:RegisterModule("dashboard", {
    title = "Dashboard",
    order = 10,
    Render = function()
        local p = safePlayerContext()
        local info = ns:GetRuntimeInfo()
        return {
            "WoW Forever Companion",
            "",
            "Character: Level " .. tostring(p.level) .. " " .. p.className,
            "Zone: " .. p.zone,
            "",
            "Loaded data packs: " .. tostring(info.packCount),
            "Loaded datasets: " .. tostring(info.datasetCount),
            "Data revision: " .. tostring(info.dataRevision),
            "Client: " .. tostring(info.gameVersion) .. " / interface " .. tostring(info.interface),
            "",
            "Goal: this page becomes your 'what should I do now?' view as leveling, quest, profession and world datasets arrive.",
        }
    end,
})

ns:RegisterModule("leveling", {
    title = "Leveling",
    order = 20,
    Render = function()
        local p = safePlayerContext()
        return placeholder("Leveling", { "leveling-routes", "quests", "zones" },
            "Current context: level " .. tostring(p.level) .. " in " .. p.zone .. ". Future recommendations will filter routes and quests around this state.")
    end,
})

ns:RegisterModule("class", {
    title = "Class",
    order = 30,
    requiredPacks = { "WoWForeverCompanion_Data_Talents" },
    Render = function()
        local p = safePlayerContext()
        local dataset = ns.Data:GetDataset("talents")
        if not dataset or not dataset.classes then
            return placeholder("Class", { "talents", "abilities", "class-quests" }, "Talent data pack is installed but no class records were registered.")
        end

        local classData = p.classFile and dataset.classes[p.classFile] or nil
        if not classData then
            return {
                "Class",
                "",
                "No compiled talent record matches your current class yet.",
                "Use Search or inspect another class on the web while the addon class selector is added.",
            }
        end

        local lines = {
            classData.className or p.className,
            "",
            "Talent data version: " .. tostring(classData.dataVersion or "?"),
            "Trees: " .. tostring(classData.treeCount or 0) .. " | Talents: " .. tostring(classData.talentCount or 0),
        }
        if classData.trees then
            lines[#lines + 1] = ""
            for i = 1, #classData.trees do
                local tree = classData.trees[i]
                lines[#lines + 1] = "• " .. tostring(tree.name) .. " — " .. tostring(tree.talentCount or 0) .. " talents"
            end
        end
        lines[#lines + 1] = ""
        lines[#lines + 1] = "Full clickable talent-tree rendering is the next class-parity slice; the complete records are already compiled into the data pack."
        return lines
    end,
})

ns:RegisterModule("quests", {
    title = "Quests",
    order = 40,
    Render = function() return placeholder("Quests", { "quests", "npcs", "zones", "items" }, "Planned: chains, prerequisites, objectives, coordinates, rewards, follow-ups and dungeon/class quest filters.") end,
})

ns:RegisterModule("professions", {
    title = "Professions",
    order = 50,
    Render = function() return placeholder("Professions", { "professions", "recipes", "items", "npcs" }, "Planned: trainers, skill bands, recipes, materials, sources and efficient skill-up plans.") end,
})

ns:RegisterModule("gathering", {
    title = "Gathering",
    order = 60,
    Render = function() return placeholder("Gathering", { "gathering", "zones", "items" }, "Planned: mining, herbalism, skinning, fishing and Forever-specific gathering sources/routes.") end,
})

ns:RegisterModule("instances", {
    title = "Instances",
    order = 70,
    Render = function() return placeholder("Instances", { "instances", "quests", "items" }, "Planned: dungeon/raid level ranges, entrances, quests, bosses, loot, attunements and preparation checklists.") end,
})

ns:RegisterModule("reputation", {
    title = "Reputation",
    order = 80,
    Render = function() return placeholder("Reputation", { "reputations", "quests", "items" }, "Planned: factions, turn-ins, grind sources, standing thresholds and rewards.") end,
})

ns:RegisterModule("travel", {
    title = "Travel",
    order = 90,
    Render = function() return placeholder("Travel", { "travel", "zones", "npcs" }, "Planned: flight masters, transports, portals, zone connections and route instructions.") end,
})

ns:RegisterModule("items", {
    title = "Items",
    order = 100,
    Render = function() return placeholder("Items", { "items", "quests", "recipes", "instances", "npcs" }, "Planned: reverse source lookup across vendors, quests, drops, crafting and reputation.") end,
})

ns:RegisterModule("updates", {
    title = "Updates",
    order = 110,
    requiredPacks = { "WoWForeverCompanion_Data_Core" },
    Render = function()
        local updates = ns.Data:GetDataset("updates")
        if not updates then
            return placeholder("Updates", { "updates" }, "The core data pack did not provide update records.")
        end
        local lines = {
            "Forever Updates",
            "",
            "Last reviewed: " .. tostring(updates.lastReviewed or "unknown"),
            "Tracked classes: " .. tostring(updates.classCount or 0),
            "",
            "The website provides the rich current/upcoming comparison. This tab is the in-game quick reference and will gain per-class diff views next.",
        }
        if updates.recent then
            lines[#lines + 1] = ""
            lines[#lines + 1] = "Recent official sources:"
            for i = 1, math.min(#updates.recent, 6) do
                lines[#lines + 1] = "• " .. tostring(updates.recent[i])
            end
        end
        return lines
    end,
})

ns:RegisterModule("search", {
    title = "Search",
    order = 120,
    Render = function()
        return {
            "Universal Search",
            "",
            "Use the search box at the top of the window or type:",
            "  /wfc search <words>",
            "",
            "Search runs across every loaded data pack using one normalized index.",
            "Opening data-heavy tabs can load their packs on demand, expanding what Search knows without bloating login memory.",
        }
    end,
})
