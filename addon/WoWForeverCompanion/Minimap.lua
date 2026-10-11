local addonName, ns = ...

-- Forever beta uses a larger minimap than the original fixed-radius launcher
-- assumed. This file deliberately loads after UI.lua and replaces the minimap
-- launcher implementation with geometry based on the live minimap dimensions.
-- Keeping this isolated also makes it easy to adjust for future beta UI builds.

local UI = ns.UI
if not UI then return end

ns.version = "0.1.4"

local DEFAULT_ANGLE = 38
local OUTSIDE_GAP = 6
local BUTTON_SIZE = 31

local function atan2(y, x)
    if math.atan2 then return math.atan2(y, x) end
    if x > 0 then return math.atan(y / x) end
    if x < 0 and y >= 0 then return math.atan(y / x) + math.pi end
    if x < 0 and y < 0 then return math.atan(y / x) - math.pi end
    if x == 0 and y > 0 then return math.pi / 2 end
    if x == 0 and y < 0 then return -math.pi / 2 end
    return 0
end

local function ensureMinimapSettings()
    if not ns.db then return nil end
    ns.db.minimap = ns.db.minimap or {}
    if ns.db.minimap.angle == nil then ns.db.minimap.angle = DEFAULT_ANGLE end
    if ns.db.minimap.hidden == nil then ns.db.minimap.hidden = false end
    return ns.db.minimap
end

local function minimapRadius()
    if not Minimap then return 76 end
    local width = (Minimap.GetWidth and Minimap:GetWidth()) or 140
    return width / 2 + OUTSIDE_GAP
end

function UI:UpdateMinimapButtonPosition()
    local button = self.minimapButton
    if not button or not Minimap then return end

    local settings = ensureMinimapSettings()
    local angle = tonumber(settings and settings.angle) or DEFAULT_ANGLE
    local radians = math.rad(angle)
    local radius = minimapRadius()

    button:ClearAllPoints()
    button:SetPoint(
        "CENTER",
        Minimap,
        "CENTER",
        math.cos(radians) * radius,
        math.sin(radians) * radius
    )
end

function UI:UpdateMinimapButtonFromCursor()
    if not self.minimapButton or not Minimap or type(GetCursorPosition) ~= "function" then return end

    local mx, my = Minimap:GetCenter()
    if not mx or not my then return end

    local cx, cy = GetCursorPosition()
    local scale = (Minimap.GetEffectiveScale and Minimap:GetEffectiveScale()) or 1
    if not scale or scale == 0 then scale = 1 end
    cx, cy = cx / scale, cy / scale

    local angle = math.deg(atan2(cy - my, cx - mx))
    if angle < 0 then angle = angle + 360 end

    local settings = ensureMinimapSettings()
    if settings then settings.angle = angle end
    self:UpdateMinimapButtonPosition()
end

local function createFallbackBadge(button)
    -- Always-visible badge so the launcher never becomes an empty circle even
    -- if Blizzard changes an icon texture path during the beta.
    local badge = button:CreateTexture(nil, "BACKGROUND")
    badge:SetSize(25, 25)
    badge:SetPoint("CENTER")
    if badge.SetColorTexture then
        badge:SetColorTexture(0.035, 0.16, 0.34, 1)
    end

    local mark = button:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    mark:SetPoint("CENTER", 0, 0)
    mark:SetText("W")
    mark:SetTextColor(1.0, 0.72, 0.12, 1)
    button.fallbackMark = mark
end

function UI:CreateMinimapButton()
    if self.minimapButton or type(CreateFrame) ~= "function" or not Minimap then return self.minimapButton end

    -- Do NOT parent directly to Minimap. Forever can clip children to the map
    -- footprint, which prevents a true external-ring launcher.
    local parent = _G.MinimapCluster or UIParent or Minimap
    local button = CreateFrame("Button", "WoWForeverCompanionMinimapButton", parent)
    button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    button:SetFrameStrata("HIGH")
    local mapLevel = (Minimap.GetFrameLevel and Minimap:GetFrameLevel()) or 1
    button:SetFrameLevel(mapLevel + 20)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetClampedToScreen(true)

    createFallbackBadge(button)

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(23, 23)
    icon:SetPoint("CENTER")
    -- HolyBolt is present in Classic-era clients and gives the launcher a
    -- bright gold/blue compass-like visual. The W badge remains underneath as
    -- a guaranteed fallback if the texture is unavailable in a beta build.
    icon:SetTexture("Interface\\Icons\\Spell_Holy_HolyBolt")
    if icon.SetTexCoord then icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
    button.icon = icon

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetSize(54, 54)
    border:SetPoint("CENTER")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    button.border = border

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetSize(32, 32)
    highlight:SetPoint("CENTER")
    highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    highlight:SetBlendMode("ADD")

    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "RightButton" then
            local settings = ensureMinimapSettings()
            if settings then
                settings.angle = DEFAULT_ANGLE
                settings.hidden = false
            end
            UI:UpdateMinimapButtonPosition()
            return
        end
        ns:Toggle()
    end)

    button:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            UI:UpdateMinimapButtonFromCursor()
        end)
    end)

    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        UI:UpdateMinimapButtonFromCursor()
    end)

    button:SetScript("OnEnter", function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("WoW Forever Companion", 0.94, 0.72, 0.30)
        GameTooltip:AddLine("Left-click: Open / close", 1, 1, 1)
        GameTooltip:AddLine("Drag: Move around outside of minimap", 0.75, 0.78, 0.82)
        GameTooltip:AddLine("Right-click: Reset to top-right", 0.75, 0.78, 0.82)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)

    self.minimapButton = button
    self:UpdateMinimapButtonPosition()

    local settings = ensureMinimapSettings()
    if settings and settings.hidden then button:Hide() else button:Show() end

    return button
end
