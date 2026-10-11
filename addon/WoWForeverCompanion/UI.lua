local addonName, ns = ...

ns.UI = ns.UI or {}
local UI = ns.UI

UI.frame = nil
UI.navButtons = {}
UI.selectedModule = nil
UI.minimapButton = nil

local function setColor(texture, r, g, b, a)
    if texture and texture.SetColorTexture then texture:SetColorTexture(r, g, b, a) end
end

local function joinLines(lines)
    if type(lines) == "string" then return lines end
    if type(lines) ~= "table" then return tostring(lines or "") end
    return table.concat(lines, "\n")
end

local function makeText(parent, font, size)
    local fs = parent:CreateFontString(nil, "OVERLAY", font or "GameFontNormal")
    if size and fs.SetFont then
        local path = select(1, fs:GetFont())
        if path then fs:SetFont(path, size) end
    end
    return fs
end

local function makeNavButton(parent, module, y)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(136, 28)
    button:SetPoint("TOPLEFT", 12, y)

    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    setColor(bg, 0.08, 0.10, 0.14, 0.95)
    button.bg = bg

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    setColor(highlight, 0.75, 0.52, 0.16, 0.18)

    local label = makeText(button, "GameFontNormal")
    label:SetPoint("LEFT", 10, 0)
    label:SetText(module.title)
    label:SetTextColor(0.82, 0.85, 0.91)
    button.label = label

    button:SetScript("OnClick", function()
        UI:ShowModule(module.id)
    end)
    return button
end

local function atan2(y, x)
    if math.atan2 then return math.atan2(y, x) end
    if x > 0 then return math.atan(y / x) end
    if x < 0 and y >= 0 then return math.atan(y / x) + math.pi end
    if x < 0 and y < 0 then return math.atan(y / x) - math.pi end
    if x == 0 and y > 0 then return math.pi / 2 end
    if x == 0 and y < 0 then return -math.pi / 2 end
    return 0
end

function UI:UpdateMinimapButtonPosition()
    local button = self.minimapButton
    if not button or not Minimap then return end

    local angle = tonumber(ns.db and ns.db.minimap and ns.db.minimap.angle) or 220
    local radians = math.rad(angle)
    local radius = 78
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(radians) * radius, math.sin(radians) * radius)
end

function UI:UpdateMinimapButtonFromCursor()
    if not self.minimapButton or not Minimap or type(GetCursorPosition) ~= "function" then return end

    local mx, my = Minimap:GetCenter()
    if not mx or not my then return end

    local cx, cy = GetCursorPosition()
    local scale = Minimap.GetEffectiveScale and Minimap:GetEffectiveScale() or 1
    if not scale or scale == 0 then scale = 1 end
    cx, cy = cx / scale, cy / scale

    local angle = math.deg(atan2(cy - my, cx - mx))
    if angle < 0 then angle = angle + 360 end
    if ns.db and ns.db.minimap then ns.db.minimap.angle = angle end
    self:UpdateMinimapButtonPosition()
end

function UI:CreateMinimapButton()
    if self.minimapButton or type(CreateFrame) ~= "function" or not Minimap then return self.minimapButton end

    local button = CreateFrame("Button", "WoWForeverCompanionMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel((Minimap.GetFrameLevel and Minimap:GetFrameLevel() or 1) + 8)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", 0, 0)
    icon:SetTexture("Interface\\Icons\\INV_Misc_Map_01")
    button.icon = icon

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetSize(54, 54)
    border:SetPoint("CENTER", 0, 0)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetSize(32, 32)
    highlight:SetPoint("CENTER", 0, 0)
    highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    highlight:SetBlendMode("ADD")

    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "RightButton" then
            if ns.db and ns.db.minimap then
                ns.db.minimap.angle = 220
                ns.db.minimap.hidden = false
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
        GameTooltip:AddLine("Drag: Move around minimap", 0.75, 0.78, 0.82)
        GameTooltip:AddLine("Right-click: Reset position", 0.75, 0.78, 0.82)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)

    self.minimapButton = button
    self:UpdateMinimapButtonPosition()

    if ns.db and ns.db.minimap and ns.db.minimap.hidden then
        button:Hide()
    else
        button:Show()
    end

    return button
end

function UI:Create()
    if self.frame or type(CreateFrame) ~= "function" then return self.frame end

    local frame = CreateFrame("Frame", "WoWForeverCompanionFrame", UIParent)
    frame:SetSize(960, 640)
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")

    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    setColor(bg, 0.025, 0.035, 0.055, 0.98)

    local header = frame:CreateTexture(nil, "BORDER")
    header:SetPoint("TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", 0, 0)
    header:SetHeight(48)
    setColor(header, 0.07, 0.08, 0.11, 1)

    local sidebar = frame:CreateTexture(nil, "BORDER")
    sidebar:SetPoint("TOPLEFT", 0, -48)
    sidebar:SetPoint("BOTTOMLEFT", 0, 0)
    sidebar:SetWidth(160)
    setColor(sidebar, 0.045, 0.055, 0.075, 1)

    local title = makeText(frame, "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 18, -15)
    title:SetText("WoW Forever Companion")
    title:SetTextColor(0.94, 0.72, 0.30)

    local status = makeText(frame, "GameFontHighlightSmall")
    status:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
    status:SetText("v" .. tostring(ns.version) .. " • data " .. tostring(ns.dataRevision))
    status:SetTextColor(0.55, 0.61, 0.70)

    local close = CreateFrame("Button", nil, frame)
    close:SetSize(32, 32)
    close:SetPoint("TOPRIGHT", -8, -8)
    local closeText = makeText(close, "GameFontNormalLarge")
    closeText:SetPoint("CENTER")
    closeText:SetText("×")
    closeText:SetTextColor(0.8, 0.82, 0.86)
    close:SetScript("OnClick", function() frame:Hide() end)

    frame:SetScript("OnDragStart", function(self)
        if not ns.db then return end
        self:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if ns.db then
            local point, _, _, x, y = self:GetPoint(1)
            ns.db.window.point = point or "CENTER"
            ns.db.window.x = x or 0
            ns.db.window.y = y or 0
        end
    end)

    local search = CreateFrame("EditBox", nil, frame)
    search:SetSize(300, 26)
    search:SetPoint("TOPRIGHT", -55, -11)
    search:SetAutoFocus(false)
    search:SetFontObject("ChatFontNormal")
    search:SetTextInsets(8, 8, 0, 0)
    local searchBg = search:CreateTexture(nil, "BACKGROUND")
    searchBg:SetAllPoints()
    setColor(searchBg, 0.02, 0.025, 0.04, 1)
    search:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    search:SetScript("OnEnterPressed", function(self)
        local query = self:GetText() or ""
        self:ClearFocus()
        if query ~= "" then UI:ShowSearch(query) end
    end)
    self.searchBox = search

    local hint = makeText(frame, "GameFontHighlightSmall")
    hint:SetPoint("RIGHT", search, "LEFT", -8, 0)
    hint:SetText("Search")
    hint:SetTextColor(0.55, 0.61, 0.70)

    local moduleTitle = makeText(frame, "GameFontNormalLarge")
    moduleTitle:SetPoint("TOPLEFT", 182, -69)
    moduleTitle:SetText("Dashboard")
    moduleTitle:SetTextColor(0.95, 0.95, 0.97)
    self.moduleTitle = moduleTitle

    local content = makeText(frame, "GameFontHighlight")
    content:SetPoint("TOPLEFT", 182, -105)
    content:SetPoint("BOTTOMRIGHT", -24, 24)
    content:SetJustifyH("LEFT")
    content:SetJustifyV("TOP")
    content:SetTextColor(0.82, 0.85, 0.90)
    content:SetText("")
    self.content = content

    local modules = ns:GetModules()
    local y = -62
    for i = 1, #modules do
        local module = modules[i]
        local button = makeNavButton(frame, module, y)
        self.navButtons[module.id] = button
        y = y - 32
    end

    local saved = ns.db and ns.db.window
    frame:ClearAllPoints()
    if saved and saved.point then
        frame:SetPoint(saved.point, UIParent, saved.point, saved.x or 0, saved.y or 0)
    else
        frame:SetPoint("CENTER")
    end

    _G.UISpecialFrames = _G.UISpecialFrames or {}
    _G.UISpecialFrames[#_G.UISpecialFrames + 1] = "WoWForeverCompanionFrame"

    frame:Hide()
    self.frame = frame
    return frame
end

function UI:SetSelectedButton(moduleId)
    for id, button in pairs(self.navButtons) do
        if id == moduleId then
            setColor(button.bg, 0.20, 0.14, 0.06, 1)
            button.label:SetTextColor(0.96, 0.76, 0.35)
        else
            setColor(button.bg, 0.08, 0.10, 0.14, 0.95)
            button.label:SetTextColor(0.82, 0.85, 0.91)
        end
    end
end

function UI:ShowModule(moduleId)
    self:Create()
    local module = ns:GetModule(moduleId) or ns:GetModule("dashboard")
    if not module then return end

    local ok, err = ns:EnsureModulePacks(module)
    self.selectedModule = module.id
    if ns.db then ns.db.selectedModule = module.id end
    self:SetSelectedButton(module.id)
    self.moduleTitle:SetText(module.title)

    if not ok then
        self.content:SetText("Unable to load required data pack.\n\n" .. tostring(err) .. "\n\nThe core addon remains usable; install/build the matching data pack to populate this module.")
        return
    end

    local renderOk, rendered = pcall(function()
        if type(module.Render) == "function" then return module:Render() end
        return { module.title, "", "No renderer has been registered for this module." }
    end)

    if not renderOk then
        self.content:SetText("Module error:\n" .. tostring(rendered))
        return
    end
    self.content:SetText(joinLines(rendered))
end

function UI:ShowSearch(query)
    self:Create()
    -- Load the two high-value v1 packs when available so Search is useful even
    -- before the player has opened Class or Updates. Failures are intentionally
    -- ignored; search still works over every currently registered pack.
    pcall(function() ns:LoadDataPack("WoWForeverCompanion_Data_Core") end)
    pcall(function() ns:LoadDataPack("WoWForeverCompanion_Data_Talents") end)

    local lines, results = ns.Search:FormatResults(query, { limit = 30 })
    self.selectedModule = "search"
    self:SetSelectedButton("search")
    self.moduleTitle:SetText("Search — " .. query)
    if #lines == 0 then
        self.content:SetText("No loaded record matched '" .. query .. "'.\n\nAs additional data packs are added, the same search box will cover quests, recipes, items, NPCs, instances, travel and more.")
    else
        self.content:SetText(table.concat(lines, "\n"))
    end
    self.searchResults = results
end

function UI:Show(moduleId)
    self:Create()
    if not self.frame then return end
    self:ShowModule(moduleId or "dashboard")
    self.frame:Show()
end

function UI:Toggle()
    self:Create()
    if not self.frame then return end
    if self.frame:IsShown() then
        self.frame:Hide()
    else
        self:Show((ns.db and ns.db.selectedModule) or "dashboard")
    end
end

function UI:Initialize()
    self:Create()
    self:CreateMinimapButton()
end
