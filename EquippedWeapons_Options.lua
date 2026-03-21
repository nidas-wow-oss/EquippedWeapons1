-- EquippedWeapons_Options.lua  v2.0
local _, ns = ...
if not ns.L then
    ns.L = setmetatable({}, { __index = function(_, k) return k end })
end
local L = ns.L

local C_HDR   = "|cff4fc3f7"
local C_WHITE = "|cffffffff"
local C_GREEN = "|cff00ff99"
local C_GOLD  = "|cffFFD700"
local C_GRAY  = "|cffaaaaaa"
local C_RESET = "|r"

local function Header(parent, x, y, text)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    fs:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    fs:SetText(C_HDR .. text .. C_RESET)
    return fs
end

local function Checkbox(name, parent, x, y, label, fn)
    local cb = CreateFrame("CheckButton", name, parent, "InterfaceOptionsCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    local fs = _G[name .. "Text"]
    if fs then
        fs:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
        fs:SetText(C_WHITE .. label .. C_RESET)
    end
    cb:SetScript("OnClick", function(self) fn(self) end)
    return cb
end

local function SetSliderLbl(sl, labelKey, val)
    _G[sl:GetName() .. "Text"]:SetText(C_GREEN .. L[labelKey] .. ": " .. C_GOLD .. val .. C_RESET)
end

local function Slider(name, parent, x, y, labelKey, initVal, minV, maxV, step, w, fn)
    local sl = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    sl:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    sl:SetMinMaxValues(minV, maxV)
    sl:SetValueStep(step)
    sl:SetWidth(w)
    _G[name .. "Low"]:SetText(C_GRAY .. tostring(minV) .. C_RESET)
    _G[name .. "High"]:SetText(C_GRAY .. tostring(maxV) .. C_RESET)
    SetSliderLbl(sl, labelKey, initVal)
    sl:SetScript("OnValueChanged", function(self, v) fn(self, v) end)
    return sl
end

-- ============================================================
-- Panel
-- ============================================================
local panel = CreateFrame("Frame", "EquippedWeaponsOptionsPanel")
panel.name = "EquippedWeapons"

panel:SetBackdrop({
    bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
panel:SetBackdropColor(0.00, 0.03, 0.11, 0.96)
panel:SetBackdropBorderColor(0.22, 0.48, 0.90, 1.0)

local titleBar = CreateFrame("Frame", nil, panel)
titleBar:SetPoint("TOPLEFT",  panel, "TOPLEFT",  14, -14)
titleBar:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -14, -14)
titleBar:SetHeight(32)
titleBar:SetBackdrop({
    bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
})
titleBar:SetBackdropColor(0.02, 0.07, 0.20, 0.97)
titleBar:SetBackdropBorderColor(0.28, 0.52, 0.92, 0.95)

local titleFS = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
titleFS:SetPoint("LEFT", titleBar, "LEFT", 10, 0)
titleFS:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
titleFS:SetText(C_GOLD .. "EquippedWeapons" .. C_RESET)

local subFS = titleBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
subFS:SetPoint("LEFT", titleFS, "RIGHT", 8, 0)
subFS:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
subFS:SetText(C_GRAY .. "v2.0   Shift+Alt+Drag  |  /ew" .. C_RESET)

-- ============================================================
-- Layout: two clean columns, same depth for both
-- C1 = left, C2 = right
-- R0 = first content row
-- ============================================================
local C1 = 8
local C2 = 252
local R0 = -56

-- ── LEFT COLUMN ──────────────────────────────────────────────
Header(panel, C1, R0, "Display")

local chkEnchants = Checkbox("EWOptEnchants", panel, C1, R0 - 20,
    L["Show enchants text"], function(self)
        ns.db.showEnchants = self:GetChecked() and true or false
        if _G.UpdateAllWeapons then _G.UpdateAllWeapons() end
    end)

local chkGems = Checkbox("EWOptGems", panel, C1, R0 - 46,
    L["Show gems text"], function(self)
        ns.db.showGems = self:GetChecked() and true or false
        if _G.UpdateAllWeapons then _G.UpdateAllWeapons() end
    end)

local chkBorders = Checkbox("EWOptBorders", panel, C1, R0 - 72,
    L["Show quality borders"], function(self)
        ns.db.showClassBorders = self:GetChecked() and true or false
        if _G.UpdateAllWeapons then _G.UpdateAllWeapons() end
    end)

local chkHideLabels = Checkbox("EWOptHideLabels", panel, C1, R0 - 98,
    L["Hide slot labels"], function(self)
        ns.db.hideSlotLabels = self:GetChecked() and true or false
        if _G.UpdateAllWeapons then _G.UpdateAllWeapons() end
    end)

-- gap before Layout section
Header(panel, C1, R0 - 128, "Layout & Text")

local chkHorizontal = Checkbox("EWOptHorizontal", panel, C1, R0 - 148,
    L["Show text horizontally"], function(self)
        ns.db.horizontalText = self:GetChecked() and true or false
        if _G.UpdateAllWeapons then _G.UpdateAllWeapons() end
    end)

local chkVertical = Checkbox("EWOptVertical", panel, C1, R0 - 174,
    L["Vertical icon layout"], function(self)
        ns.db.verticalLayout = self:GetChecked() and true or false
        if ns.db.verticalLayout and not ns.db.horizontalText then
            ns.db.horizontalText = true
            chkHorizontal:SetChecked(true)
        end
        if _G.UpdateIconPositions then _G.UpdateIconPositions() end
        if _G.UpdateAllWeapons    then _G.UpdateAllWeapons()    end
    end)

local chkDirection = Checkbox("EWOptDirection", panel, C1, R0 - 200,
    L["Grow upwards"], function(self)
        ns.db.layoutDirection = self:GetChecked() and "up" or "down"
        if _G.UpdateIconPositions then _G.UpdateIconPositions() end
        if _G.UpdateAllWeapons    then _G.UpdateAllWeapons()    end
    end)

local chkAbbreviate = Checkbox("EWOptAbbreviate", panel, C1, R0 - 226,
    L["Abbreviate text (short mode)"], function(self)
        ns.db.abbreviateText = self:GetChecked() and true or false
        if _G.UpdateAllWeapons then _G.UpdateAllWeapons() end
    end)

-- Lock frame: styled red box instead of Position header
-- Lock frame: manual border (WotLK Button doesn't support SetBackdrop)
local lockBox = CreateFrame("Frame", "EWLockBox", panel)
lockBox:SetPoint("TOPLEFT", panel, "TOPLEFT", C1 + 6, R0 - 258)
lockBox:SetSize(174, 32)
lockBox:SetFrameLevel(panel:GetFrameLevel() + 3)
lockBox:EnableMouse(true)

-- Background
local lbBg = lockBox:CreateTexture(nil, "ARTWORK")
lbBg:SetTexture("Interface\\Buttons\\WHITE8X8")
lbBg:SetAllPoints(lockBox)
lbBg:SetVertexColor(0.03, 0.08, 0.20, 0.95)

-- Border edges (4 textures)
local BW = 1
local function LBEdge(layer)
    local t = lockBox:CreateTexture(nil, layer or "OVERLAY")
    t:SetTexture("Interface\\Buttons\\WHITE8X8")
    t:SetVertexColor(0.25, 0.55, 0.90, 0.80)
    return t
end
local lbTop    = LBEdge(); lbTop:SetPoint("TOPLEFT",     lockBox,"TOPLEFT",    0,  0); lbTop:SetPoint("TOPRIGHT",    lockBox,"TOPRIGHT",   0, 0); lbTop:SetHeight(BW)
local lbBot    = LBEdge(); lbBot:SetPoint("BOTTOMLEFT",  lockBox,"BOTTOMLEFT", 0,  0); lbBot:SetPoint("BOTTOMRIGHT", lockBox,"BOTTOMRIGHT",0, 0); lbBot:SetHeight(BW)
local lbLeft   = LBEdge(); lbLeft:SetPoint("TOPLEFT",    lockBox,"TOPLEFT",    0,  0); lbLeft:SetPoint("BOTTOMLEFT", lockBox,"BOTTOMLEFT", 0, 0); lbLeft:SetWidth(BW)
local lbRight  = LBEdge(); lbRight:SetPoint("TOPRIGHT",  lockBox,"TOPRIGHT",   0,  0); lbRight:SetPoint("BOTTOMRIGHT",lockBox,"BOTTOMRIGHT",0,0); lbRight:SetWidth(BW)

local lockLabel = lockBox:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
lockLabel:SetPoint("CENTER", lockBox, "CENTER", 0, 0)

local function UpdateLockBoxVisual()
    if ns.db.locked then
        lockLabel:SetText("|cffff4444" .. (L["Frame locked"] or "Frame locked") .. "|r")
        lbBg:SetVertexColor(0.20, 0.02, 0.02, 0.95)
        lbTop:SetVertexColor(0.90, 0.20, 0.20, 1.00)
        lbBot:SetVertexColor(0.90, 0.20, 0.20, 1.00)
        lbLeft:SetVertexColor(0.90, 0.20, 0.20, 1.00)
        lbRight:SetVertexColor(0.90, 0.20, 0.20, 1.00)
    else
        lockLabel:SetText("|cff4fc3f7" .. L["Lock frame"] .. "|r")
        lbBg:SetVertexColor(0.03, 0.08, 0.20, 0.95)
        lbTop:SetVertexColor(0.30, 0.65, 1.00, 1.00)
        lbBot:SetVertexColor(0.25, 0.55, 0.90, 0.80)
        lbLeft:SetVertexColor(0.25, 0.55, 0.90, 0.80)
        lbRight:SetVertexColor(0.25, 0.55, 0.90, 0.80)
    end
end
UpdateLockBoxVisual()

lockBox:SetScript("OnMouseUp", function()
    local newState = not ns.db.locked
    if _G.SetLocked then _G.SetLocked(newState) end
    UpdateLockBoxVisual()
end)
lockBox:SetScript("OnEnter", function()
    lbTop:SetVertexColor(0.60, 0.85, 1.00, 1.00)
    lbBot:SetVertexColor(0.60, 0.85, 1.00, 1.00)
    lbLeft:SetVertexColor(0.60, 0.85, 1.00, 1.00)
    lbRight:SetVertexColor(0.60, 0.85, 1.00, 1.00)
end)
lockBox:SetScript("OnLeave", function() UpdateLockBoxVisual() end)

local chkLock = { SetChecked = function(self, val) UpdateLockBoxVisual() end }

-- ── RIGHT COLUMN ─────────────────────────────────────────────
Header(panel, C2 - 2, R0, "Weapon Slots")

local chkSlot16 = Checkbox("EWOptSlot16", panel, C2 - 2, R0 - 20,
    L["Main Hand"], function(self)
        ns.db.showSlot16 = self:GetChecked() and true or false
        if _G.UpdateAllWeapons    then _G.UpdateAllWeapons()    end
        if _G.UpdateIconPositions then _G.UpdateIconPositions() end
    end)

local chkSlot17 = Checkbox("EWOptSlot17", panel, C2 - 2, R0 - 46,
    L["Off Hand"], function(self)
        ns.db.showSlot17 = self:GetChecked() and true or false
        if _G.UpdateAllWeapons    then _G.UpdateAllWeapons()    end
        if _G.UpdateIconPositions then _G.UpdateIconPositions() end
    end)

local chkSlot18 = Checkbox("EWOptSlot18", panel, C2 - 2, R0 - 72,
    L["Ranged / Relic"], function(self)
        ns.db.showSlot18 = self:GetChecked() and true or false
        if _G.UpdateAllWeapons    then _G.UpdateAllWeapons()    end
        if _G.UpdateIconPositions then _G.UpdateIconPositions() end
    end)

Header(panel, C2 - 2, R0 - 102, "Profile")

local chkCharProfile = Checkbox("EWOptCharProfile", panel, C2 - 2, R0 - 122,
    L["Per-character settings"], function(self)
        local enable = self:GetChecked() and true or false
        ns.SetCharProfile(enable)
        if _G.UpdateTextSize      then _G.UpdateTextSize()      end
        if _G.UpdateAllWeapons    then _G.UpdateAllWeapons()    end
        if _G.UpdateIconPositions then _G.UpdateIconPositions() end
        if EquippedWeaponsFrame   then EquippedWeaponsFrame:SetScale(ns.db.scale or 1) end
        panel.refresh()
        -- silent
    end)

-- ── ROGUE OPTIONS (right column, below Profile) ───────────────
-- These frames are created at fixed positions but shown/hidden in refresh()
local rogueHeader   = Header(panel, C2 - 2, R0 - 152, "Rogue Options")

local chkShowPoison = Checkbox("EWOptShowPoison", panel, C2 - 2, R0 - 172,
    L["Show poison text"], function(self)
        ns.db.showPoison = self:GetChecked() and true or false
        if _G.UpdateAllWeapons then _G.UpdateAllWeapons() end
    end)

local chkFullPoison = Checkbox("EWOptFullPoison", panel, C2 - 2, R0 - 198,
    L["Show full poison name"], function(self)
        ns.db.showFullPoisonName = self:GetChecked() and true or false
        if _G.UpdateAllWeapons then _G.UpdateAllWeapons() end
    end)

local chkPoisonIcon = Checkbox("EWOptPoisonIcon", panel, C2 - 2, R0 - 224,
    L["Show poison icon"], function(self)
        ns.db.showPoisonIcon = self:GetChecked() and true or false
        if _G.UpdateAllWeapons then _G.UpdateAllWeapons() end
    end)

-- ── SLIDERS ────────────────────────────────────────────────────
local SW = 180

-- Row 1: Scale (left) | Icon spacing (right, shifted left)
-- Icon spacing: right column, higher up
local SY_SP   = R0 - 278
local slSpacing = Slider("EWOptSpacing", panel, 212, SY_SP,
    "Icon spacing", "5", 0, 20, 1, SW,
    function(self, v)
        v = math.floor(v + 0.5)
        ns.db.iconSpacing = v
        SetSliderLbl(self, "Icon spacing", v)
        if _G.UpdateIconPositions then _G.UpdateIconPositions() end
    end)

-- Scale (left) and Text size (right) on same row, below icon spacing
local SY_MAIN = R0 - 328
local slScale = Slider("EWOptScale", panel, C1 + 2, SY_MAIN,
    "Scale", "1.3", 0.5, 2.0, 0.1, SW,
    function(self, v)
        v = tonumber(string.format("%.1f", v))
        ns.db.scale = v
        SetSliderLbl(self, "Scale", v)
        if EquippedWeaponsFrame then EquippedWeaponsFrame:SetScale(v) end
    end)

local slTextSize = Slider("EWOptTextSize", panel, 212, SY_MAIN,
    "Text size", "9", 6, 16, 1, SW,
    function(self, v)
        v = math.floor(v + 0.5)
        ns.db.textSize = v
        SetSliderLbl(self, "Text size", v)
        if _G.UpdateTextSize   then _G.UpdateTextSize()   end
        if _G.UpdateAllWeapons then _G.UpdateAllWeapons() end
    end)

-- ============================================================
-- REFRESH / DEFAULTS
-- ============================================================
panel.refresh = function()
    if not ns.db then return end
    chkEnchants:SetChecked(ns.db.showEnchants)
    chkGems:SetChecked(ns.db.showGems)
    chkBorders:SetChecked(ns.db.showClassBorders)
    chkHideLabels:SetChecked(ns.db.hideSlotLabels)
    chkSlot16:SetChecked(ns.db.showSlot16)
    chkSlot17:SetChecked(ns.db.showSlot17)
    chkSlot18:SetChecked(ns.db.showSlot18)
    chkHorizontal:SetChecked(ns.db.horizontalText)
    chkVertical:SetChecked(ns.db.verticalLayout)
    chkDirection:SetChecked(ns.db.layoutDirection == "up")
    chkAbbreviate:SetChecked(ns.db.abbreviateText)
    chkLock:SetChecked(ns.db.locked)
    chkCharProfile:SetChecked(ns.IsCharProfile())
    slScale:SetValue(ns.db.scale or 1)
    slSpacing:SetValue(ns.db.iconSpacing or 5)
    slTextSize:SetValue(ns.db.textSize or 9)
    SetSliderLbl(slScale,    "Scale",        string.format("%.1f", ns.db.scale or 1))
    SetSliderLbl(slSpacing,  "Icon spacing", ns.db.iconSpacing or 5)
    SetSliderLbl(slTextSize, "Text size",    ns.db.textSize or 9)
    -- Rogue section: show only for Rogues
    local _, pClass = UnitClass("player")
    local isRogue = (pClass == "ROGUE")
    if isRogue then
        rogueHeader:Show()
        chkShowPoison:Show();  chkShowPoison:SetChecked(ns.db.showPoison)
        chkFullPoison:Show();  chkFullPoison:SetChecked(ns.db.showFullPoisonName)
        chkPoisonIcon:Show();  chkPoisonIcon:SetChecked(ns.db.showPoisonIcon)
    else
        rogueHeader:Hide()
        chkShowPoison:Hide()
        chkFullPoison:Hide()
        chkPoisonIcon:Hide()
    end
end

panel.default = function()
    ns.db.showEnchants     = true
    ns.db.showGems         = true
    ns.db.showClassBorders = false
    ns.db.hideSlotLabels   = false
    ns.db.showSlot16       = true
    ns.db.showSlot17       = true
    ns.db.showSlot18       = true
    ns.db.horizontalText   = false
    ns.db.verticalLayout   = false
    ns.db.layoutDirection  = "down"
    ns.db.abbreviateText   = true
    ns.db.locked           = false
    ns.db.scale            = 1.3
    ns.db.iconSpacing      = 5
    ns.db.textSize         = 9
    ns.db.showPoison         = true
    ns.db.showFullPoisonName = false
    ns.db.showPoisonIcon     = false
    panel.refresh()
end

InterfaceOptions_AddCategory(panel)