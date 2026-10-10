local Stub = {
    chat = {},
    frames = {},
    inCombat = false,
}

_G.UIParent = _G.UIParent or {}
_G.UISpecialFrames = _G.UISpecialFrames or {}
_G.SlashCmdList = _G.SlashCmdList or {}

_G.DEFAULT_CHAT_FRAME = {
    AddMessage = function(_, message)
        Stub.chat[#Stub.chat + 1] = message
    end,
}

function _G.GetBuildInfo()
    return "1.60.1", "69913", "Sep 17 2026", 16001
end

function _G.UnitLevel(unit)
    if unit == "player" then return 42 end
    return 0
end

function _G.UnitClass(unit)
    if unit == "player" then return "Warrior", "WARRIOR", 1 end
    return nil
end

function _G.GetRealZoneText()
    return "Stranglethorn Vale"
end

function _G.InCombatLockdown()
    return Stub.inCombat
end

local function makeFrame(frameType, name)
    local frame = {
        frameType = frameType,
        name = name,
        events = {},
        scripts = {},
        shown = false,
    }
    function frame:RegisterEvent(event) self.events[event] = true end
    function frame:SetScript(script, fn) self.scripts[script] = fn end
    function frame:GetScript(script) return self.scripts[script] end
    function frame:Show() self.shown = true end
    function frame:Hide() self.shown = false end
    function frame:IsShown() return self.shown end
    Stub.frames[#Stub.frames + 1] = frame
    return frame
end

function _G.CreateFrame(frameType, name)
    return makeFrame(frameType, name)
end

_G.C_AddOns = {
    LoadAddOn = function(name)
        if Stub.loaders and Stub.loaders[name] then
            Stub.loaders[name]()
            return true
        end
        return false, "MISSING"
    end,
}

function Stub.resetChat()
    Stub.chat = {}
end

function Stub.setCombat(value)
    Stub.inCombat = value and true or false
end

function Stub.setLoader(name, fn)
    Stub.loaders = Stub.loaders or {}
    Stub.loaders[name] = fn
end

return Stub
