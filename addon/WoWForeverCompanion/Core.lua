local addonName, ns = ...

ns.name = addonName or "WoWForeverCompanion"
ns.version = "0.1.2"
ns.dataRevision = "2026-10-10-v1"
ns.modules = ns.modules or {}
ns.moduleOrder = ns.moduleOrder or {}
ns.initialized = false

ns.Events = ns.Events or { listeners = {} }

function ns.Events:On(eventName, callback)
    if type(callback) ~= "function" then return end
    self.listeners[eventName] = self.listeners[eventName] or {}
    self.listeners[eventName][#self.listeners[eventName] + 1] = callback
end

function ns.Events:Emit(eventName, ...)
    local listeners = self.listeners[eventName]
    if not listeners then return end
    for i = 1, #listeners do
        local ok, err = pcall(listeners[i], ...)
        if not ok and ns.Print then
            ns:Print("event error (" .. eventName .. "): " .. tostring(err))
        end
    end
end

local DEFAULT_DB = {
    schemaVersion = 1,
    selectedModule = "dashboard",
    favorites = {},
    checklists = {},
    notes = {},
    window = { point = "CENTER", x = 0, y = 0 },
    minimap = { angle = 220, hidden = false },
}

local function copyDefaults(target, defaults)
    for key, value in pairs(defaults) do
        if target[key] == nil then
            if type(value) == "table" then
                target[key] = {}
                copyDefaults(target[key], value)
            else
                target[key] = value
            end
        elseif type(value) == "table" and type(target[key]) == "table" then
            copyDefaults(target[key], value)
        end
    end
end

function ns:InitializeDatabase(existing)
    local db = type(existing) == "table" and existing or {}
    copyDefaults(db, DEFAULT_DB)
    if db.schemaVersion ~= 1 then
        -- v1 has no legacy migrations yet. Preserve user-owned collections and
        -- normalize only the schema marker/default fields.
        db.schemaVersion = 1
        copyDefaults(db, DEFAULT_DB)
    end
    self.db = db
    return db
end

function ns:RegisterModule(id, module)
    if type(id) ~= "string" or id == "" then error("module id is required", 2) end
    if type(module) ~= "table" then error("module must be a table", 2) end
    if self.modules[id] then error("module already registered: " .. id, 2) end

    module.id = id
    module.title = module.title or id
    module.order = tonumber(module.order) or 1000
    module.requiredPacks = module.requiredPacks or {}
    self.modules[id] = module
    self.moduleOrder[#self.moduleOrder + 1] = id

    table.sort(self.moduleOrder, function(a, b)
        local ma, mb = self.modules[a], self.modules[b]
        if ma.order ~= mb.order then return ma.order < mb.order end
        return ma.title < mb.title
    end)
    return module
end

function ns:GetModule(id)
    return self.modules[id]
end

function ns:GetModules()
    local result = {}
    for i = 1, #self.moduleOrder do
        result[#result + 1] = self.modules[self.moduleOrder[i]]
    end
    return result
end

function ns:Print(message)
    local prefix = "|cffd9a441WFC|r"
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage(prefix .. ": " .. tostring(message))
    elseif print then
        print("WFC: " .. tostring(message))
    end
end

local function isInCombat()
    return type(InCombatLockdown) == "function" and InCombatLockdown() or false
end

function ns:LoadDataPack(packName)
    if not packName or packName == "" then return true end
    if self.Data:HasPack(packName) then return true end
    if isInCombat() then
        return false, "Cannot load a data pack during combat. Try again after combat."
    end

    local ok, result, reason
    if C_AddOns and type(C_AddOns.LoadAddOn) == "function" then
        ok, result, reason = pcall(C_AddOns.LoadAddOn, packName)
    elseif type(LoadAddOn) == "function" then
        ok, result, reason = pcall(LoadAddOn, packName)
    else
        return false, "Addon loading API unavailable"
    end

    if not ok then return false, tostring(result) end
    if result == false or result == nil then
        return false, tostring(reason or "pack not installed or could not be loaded")
    end
    return self.Data:HasPack(packName), self.Data:HasPack(packName) and nil or "pack loaded without registering data"
end

function ns:EnsureModulePacks(module)
    if not module then return true end
    for i = 1, #module.requiredPacks do
        local packName = module.requiredPacks[i]
        local ok, err = self:LoadDataPack(packName)
        if not ok then return false, err end
    end
    return true
end

function ns:GetRuntimeInfo()
    local version, build, date, interface
    if type(GetBuildInfo) == "function" then
        version, build, date, interface = GetBuildInfo()
    end
    return {
        addonVersion = self.version,
        dataRevision = self.dataRevision,
        gameVersion = version or "unknown",
        build = build or "unknown",
        buildDate = date or "unknown",
        interface = interface or "unknown",
        packCount = self.Data:PackCount(),
        datasetCount = self.Data:DatasetCount(),
    }
end

function ns:StatusLines()
    local info = self:GetRuntimeInfo()
    return {
        "WoW Forever Companion " .. info.addonVersion,
        "Data revision: " .. info.dataRevision,
        "Client: " .. tostring(info.gameVersion) .. " build " .. tostring(info.build) .. " (interface " .. tostring(info.interface) .. ")",
        "Loaded data packs: " .. tostring(info.packCount) .. " | datasets: " .. tostring(info.datasetCount),
    }
end

function ns:Open(moduleId)
    if self.UI and self.UI.Show then
        self.UI:Show(moduleId or (self.db and self.db.selectedModule) or "dashboard")
    end
end

function ns:Toggle()
    if self.UI and self.UI.Toggle then self.UI:Toggle() end
end

function ns:HandleSlashCommand(message)
    local text = tostring(message or "")
    local command, rest = string.match(text, "^%s*(%S*)%s*(.-)%s*$")
    command = string.lower(command or "")

    if command == "" or command == "toggle" then
        self:Toggle()
        return "toggle"
    elseif command == "open" then
        self:Open(rest ~= "" and rest or nil)
        return "open"
    elseif command == "tab" then
        if rest ~= "" and self:GetModule(rest) then
            self:Open(rest)
            return "tab"
        end
        self:Print("Unknown tab. Try /wfc status to see loaded modules.")
        return "error"
    elseif command == "search" then
        if rest == "" then
            self:Print("Usage: /wfc search <words>")
            return "error"
        end
        local lines = self.Search:FormatResults(rest, { limit = 10 })
        if #lines == 0 then
            self:Print("No results for '" .. rest .. "'.")
        else
            self:Print("Search results for '" .. rest .. "':")
            for i = 1, #lines do self:Print(lines[i]) end
        end
        return "search"
    elseif command == "minimap" then
        local action = string.lower(rest or "")
        if action == "hide" then
            self.db.minimap.hidden = true
            if self.UI and self.UI.minimapButton then self.UI.minimapButton:Hide() end
            self:Print("Minimap button hidden. Use /wfc minimap show to restore it.")
        elseif action == "reset" then
            self.db.minimap.angle = 220
            self.db.minimap.hidden = false
            if self.UI and self.UI.UpdateMinimapButtonPosition then self.UI:UpdateMinimapButtonPosition() end
            if self.UI and self.UI.minimapButton then self.UI.minimapButton:Show() end
            self:Print("Minimap button position reset.")
        else
            self.db.minimap.hidden = false
            if self.UI and self.UI.minimapButton then self.UI.minimapButton:Show() end
            self:Print("Minimap button shown. Drag it around the minimap ring to reposition it.")
        end
        return "minimap"
    elseif command == "status" or command == "version" then
        local lines = self:StatusLines()
        for i = 1, #lines do self:Print(lines[i]) end
        self:Print("Modules: " .. table.concat(self.moduleOrder, ", "))
        return "status"
    elseif command == "help" then
        self:Print("/wfc — open/close")
        self:Print("/wfc tab <id> — open a tab")
        self:Print("/wfc search <words> — universal search")
        self:Print("/wfc minimap [show|hide|reset] — minimap launcher")
        self:Print("/wfc status — addon/data/client versions")
        return "help"
    end

    self:Print("Unknown command. Use /wfc help.")
    return "error"
end

function ns:Initialize()
    if self.initialized then return end
    self.initialized = true
    _G.WoWForeverCompanionDB = self:InitializeDatabase(_G.WoWForeverCompanionDB)
    if self.UI and self.UI.Initialize then self.UI:Initialize() end
    self.Events:Emit("INITIALIZED")
end

_G.SlashCmdList = _G.SlashCmdList or {}
_G.SLASH_WOWFOREVERCOMPANION1 = "/wfc"
_G.SLASH_WOWFOREVERCOMPANION2 = "/wowforevercompanion"
_G.SlashCmdList.WOWFOREVERCOMPANION = function(message)
    ns:HandleSlashCommand(message)
end

if type(CreateFrame) == "function" then
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("ADDON_LOADED")
    eventFrame:SetScript("OnEvent", function(_, event, loadedName)
        if event == "ADDON_LOADED" and loadedName == ns.name then
            ns:Initialize()
        end
    end)
    ns.eventFrame = eventFrame
end
