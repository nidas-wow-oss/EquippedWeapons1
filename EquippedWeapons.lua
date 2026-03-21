-- EquippedWeapons.lua  v2.0
-- Dynamic gem/enchant detection via tooltip scanning + item link parsing.
-- No hardcoded data file required.

local _, ns = ...
-- Fallback: if localization files are missing, L[key] returns the key itself
if not ns.L then
    ns.L = setmetatable({}, { __index = function(_, k) return k end })
end
local L = ns.L

local config = {
    iconSize    = 35,
    iconSpacing = 3,
    textSize    = 9,
    borderPadding = 15,
}

-- ============================================================
-- SavedVariables defaults (overwritten at ADDON_LOADED)
-- ============================================================
local DB_DEFAULTS = {
    showClassBorders = false,
    point       = "BOTTOMRIGHT",
    xOfs        = -10,
    yOfs        = 10,
    scale       = 1.3,
    iconSpacing = 5,
    showEnchants  = true,
    showGems      = true,
    locked      = false,
    horizontalText = false,
    showSlot16  = true,
    showSlot17  = true,
    showSlot18  = true,
    verticalLayout  = false,
    layoutDirection = "down",
    textSize    = 9,
    abbreviateText = true,
    hideSlotLabels = false,
    showPoison = true,
    showFullPoisonName = false,
    showPoisonIcon = false,
}

-- Active profile pointer (starts as defaults, swapped at ADDON_LOADED)
ns.db = DB_DEFAULTS
ns.DB_DEFAULTS = DB_DEFAULTS

-- Silent helper (no chat prints except initial load)
local function EWPrint(msg)
    -- chat prints disabled
end

-- ============================================================
-- Profile system: global vs per-character
-- ============================================================
function ns.InitProfiles()
    -- Ensure both saved tables exist
    if not EquippedWeaponsDB then EquippedWeaponsDB = {} end
    if not EquippedWeaponsCharDB then EquippedWeaponsCharDB = {} end

    -- Merge defaults into global DB
    for k, v in pairs(DB_DEFAULTS) do
        if EquippedWeaponsDB[k] == nil then
            EquippedWeaponsDB[k] = v
        end
    end

    -- Check if this character uses its own profile
    if EquippedWeaponsCharDB.useCharProfile then
        -- Merge defaults into char DB
        for k, v in pairs(DB_DEFAULTS) do
            if EquippedWeaponsCharDB[k] == nil then
                EquippedWeaponsCharDB[k] = v
            end
        end
        ns.db = EquippedWeaponsCharDB
    else
        ns.db = EquippedWeaponsDB
    end
end

function ns.SetCharProfile(enable)
    if enable then
        -- Copy current global settings to char DB as starting point
        for k, v in pairs(EquippedWeaponsDB) do
            if EquippedWeaponsCharDB[k] == nil then
                EquippedWeaponsCharDB[k] = v
            end
        end
        EquippedWeaponsCharDB.useCharProfile = true
        ns.db = EquippedWeaponsCharDB
    else
        EquippedWeaponsCharDB.useCharProfile = false
        ns.db = EquippedWeaponsDB
    end
end

function ns.IsCharProfile()
    return EquippedWeaponsCharDB and EquippedWeaponsCharDB.useCharProfile or false
end

-- ============================================================
-- Dynamic stat pattern matching  (EN + ES)
-- ============================================================
-- Ordered so that longer / more-specific patterns are tried first.
local STAT_PATTERNS = {
    -- combined multi-stat (Accuracy, etc.)
    { pat = "%+(%d+) Hit Rating and %+(%d+) Critical Strike Rating", fmt2 = "%s Hit %s Crit" },
    { pat = "%+(%d+) índice de golpe y %+(%d+) índice de golpe crítico", fmt2 = "%s Hit %s Crit" },

    -- Spell Power
    { pat = "%+?(%d+) Spell Power",             fmt = "%s SP" },
    { pat = "%+?(%d+) poder con hechizos",      fmt = "%s SP" },

    -- Attack Power
    { pat = "%+?(%d+) Attack Power",             fmt = "%s AP" },
    { pat = "%+?(%d+) poder de ataque",          fmt = "%s AP" },

    -- Resilience
    { pat = "(%d+) Resilience Rating",           fmt = "%s Res" },
    { pat = "(%d+) Resilience",                  fmt = "%s Res" },
    { pat = "(%d+) índice de temple",            fmt = "%s Res" },
    { pat = "(%d+) temple",                      fmt = "%s Res" },

    -- Crit
    { pat = "(%d+) Critical Strike Rating",      fmt = "%s Crit" },
    { pat = "(%d+) Critical Strike",             fmt = "%s Crit" },
    { pat = "(%d+) Ranged Critical Strike",      fmt = "%s Crit" },
    { pat = "(%d+) golpe crítico a distancia",   fmt = "%s Crit" },
    { pat = "(%d+) índice de golpe crítico",     fmt = "%s Crit" },
    { pat = "(%d+) golpe crítico",               fmt = "%s Crit" },

    -- Hit
    { pat = "(%d+) Hit Rating",                  fmt = "%s Hit" },
    { pat = "(%d+) índice de golpe%s*$",      fmt = "%s Hit" },

    -- Haste
    { pat = "(%d+) Haste Rating",                fmt = "%s Haste" },
    { pat = "(%d+) Haste",                       fmt = "%s Haste" },
    { pat = "(%d+) índice de celeridad",         fmt = "%s Haste" },
    { pat = "(%d+) celeridad",                   fmt = "%s Haste" },

    -- Armor Penetration
    { pat = "(%d+) Armor Penetration Rating",    fmt = "%s ArPen" },
    { pat = "(%d+) Armor Penetration",           fmt = "%s ArPen" },
    { pat = "(%d+) penetración de armadura",     fmt = "%s ArPen" },

    -- Strength
    { pat = "%+?(%d+) Strength",                 fmt = "%s Str" },
    { pat = "%+?(%d+) fuerza",                   fmt = "%s Str" },

    -- Agility
    { pat = "%+?(%d+) Agility",                  fmt = "%s Agy" },
    { pat = "%+?(%d+) agilidad",                 fmt = "%s Agy" },

    -- Stamina
    { pat = "%+?(%d+) Stamina",                  fmt = "%s Sta" },
    { pat = "%+?(%d+) aguante",                  fmt = "%s Sta" },

    -- Intellect
    { pat = "%+?(%d+) Intellect",                fmt = "%s Int" },
    { pat = "%+?(%d+) intelecto",                fmt = "%s Int" },

    -- Spirit
    { pat = "%+?(%d+) Spirit",                   fmt = "%s Spi" },
    { pat = "%+?(%d+) espíritu",                 fmt = "%s Spi" },

    -- Spell Penetration
    { pat = "(%d+) Spell Penetration",           fmt = "%s SPen" },
    { pat = "(%d+) penetración de hechizos",     fmt = "%s SPen" },

    -- Defense
    { pat = "(%d+) Defense Rating",              fmt = "%s Def" },
    { pat = "(%d+) índice de defensa",           fmt = "%s Def" },

    -- Mana per 5
    { pat = "(%d+) [Mm]ana .-%f[%d]5",          fmt = "%s Mp5" },
    { pat = "(%d+) maná .-%f[%d]5",             fmt = "%s Mp5" },

    -- Fishing
    { pat = "%+?(%d+) Fishing",                  fmt = "%s Fish" },
    { pat = "%+?(%d+) pesca",                    fmt = "%s Fish" },
}

--- Try to match a tooltip line to a stat abbreviation.
--- Returns an abbreviated string like "63 SP" or "25 Hit 25 Crit", or nil.
local function MatchStatLine(text)
    if not text then return nil end
    for _, entry in ipairs(STAT_PATTERNS) do
        if entry.fmt2 then
            local v1, v2 = text:match(entry.pat)
            if v1 and v2 then
                return string.format(entry.fmt2, v1, v2)
            end
        else
            local v = text:match(entry.pat)
            if v then
                return string.format(entry.fmt, v)
            end
        end
    end
    return nil
end

-- Small table ONLY for proc-based / named enchants that have no numeric stat.
local NAMED_ENCHANTS = {
    -- EN
    ["Berserking"]              = "BERS",
    ["Mongoose"]                = "MON",
    ["Black Magic"]             = "BL MA",
    ["Executioner"]             = "EXE",
    ["Crusader"]                = "CRUS",
    ["Blood Draining"]          = "BD",
    ["Icy Weapon"]              = "ICY",
    ["Titanium Weapon Chain"]   = "Chain",
    ["Blade Ward"]              = "BW",
    ["Lifeward"]                = "LW",
    -- ES
    ["Rabiar"]                  = "BERS",
    ["Mangosta"]                = "MON",
    ["Magia negra"]             = "BL MA",
    ["Verdugo"]                 = "EXE",
    ["Cruzado"]                 = "CRUS",
    ["Cadena de titanio"]       = "Chain",
}

-- ============================================================
-- Poison detection (Rogue)
-- ============================================================
local POISON_DATA = {
    -- pat=tooltip pattern, sEN/fEN=short/full EN, sES/fES=short/full ES, icon=item texture ID
    { pat = "Deadly Poison",        sEN = "DP",  fEN = "Deadly Poison",       sES = "VM",  fES = "Veneno Mortal",      icon = "Interface\\Icons\\ability_rogue_deadlypoison"    },
    { pat = "Instant Poison",       sEN = "IP",  fEN = "Instant Poison",      sES = "VI",  fES = "Veneno Instantaneo", icon = "Interface\\Icons\\ability_rogue_instantpoison"   },
    { pat = "Wound Poison",         sEN = "WP",  fEN = "Wound Poison",        sES = "VH",  fES = "Veneno de Herida",   icon = "Interface\\Icons\\ability_rogue_woundpoison"     },
    { pat = "Crippling Poison",     sEN = "CP",  fEN = "Crippling Poison",    sES = "VP",  fES = "Veneno Paralizante", icon = "Interface\\Icons\\ability_rogue_cripplingpoison"  },
    { pat = "Mind%-Numbing Poison", sEN = "MNP", fEN = "Mind-Numbing Poison", sES = "VE",  fES = "Veneno Entumecedor", icon = "Interface\\Icons\\ability_rogue_mindnumbing"      },
    { pat = "Mind Numbing Poison",  sEN = "MNP", fEN = "Mind-Numbing Poison", sES = "VE",  fES = "Veneno Entumecedor", icon = "Interface\\Icons\\ability_rogue_mindnumbing"      },
    { pat = "Anesthetic Poison",    sEN = "ANP", fEN = "Anesthetic Poison",   sES = "VA",  fES = "Veneno Anestesico",  icon = "Interface\\Icons\\ability_rogue_anestheticpoison" },
    -- ES patterns
    { pat = "Veneno Mortal",        sEN = "DP",  fEN = "Deadly Poison",       sES = "VM",  fES = "Veneno Mortal",      icon = "Interface\\Icons\\ability_rogue_deadlypoison"    },
    { pat = "Veneno Instant",       sEN = "IP",  fEN = "Instant Poison",      sES = "VI",  fES = "Veneno Instantaneo", icon = "Interface\\Icons\\ability_rogue_instantpoison"   },
    { pat = "Veneno de Herida",     sEN = "WP",  fEN = "Wound Poison",        sES = "VH",  fES = "Veneno de Herida",   icon = "Interface\\Icons\\ability_rogue_woundpoison"     },
    { pat = "Veneno Paralizante",   sEN = "CP",  fEN = "Crippling Poison",    sES = "VP",  fES = "Veneno Paralizante", icon = "Interface\\Icons\\ability_rogue_cripplingpoison"  },
    { pat = "Veneno Entumecedor",   sEN = "MNP", fEN = "Mind-Numbing Poison", sES = "VE",  fES = "Veneno Entumecedor", icon = "Interface\\Icons\\ability_rogue_mindnumbing"      },
    { pat = "Veneno Anest",         sEN = "ANP", fEN = "Anesthetic Poison",   sES = "VA",  fES = "Veneno Anestesico",  icon = "Interface\\Icons\\ability_rogue_anestheticpoison" },
}

-- Find poison icon by scanning player bags for matching poison item
local function GetPoisonIconFromBags(poisonPat)
    if not poisonPat then return nil end
    for bag = 0, 4 do
        local numSlots = GetContainerNumSlots(bag)
        if numSlots then
            for slot = 1, numSlots do
                local link = GetContainerItemLink(bag, slot)
                if link then
                    local itemName = GetItemInfo(link)
                    if itemName then
                        -- Check if item name matches poison pattern
                        for _, p in ipairs(POISON_DATA) do
                            if p.pat == poisonPat and itemName:find(p.pat:gsub("%%%-", "-")) then
                                local itemID = tonumber(link:match("item:(%d+):"))
                                if itemID then
                                    return GetItemIcon(itemID)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return nil
end

-- Returns poison pattern for a tooltip line (used to find bag icon)
local function GetPoisonPatternFromText(text)
    if not text then return nil end
    for _, p in ipairs(POISON_DATA) do
        if text:find(p.pat) then
            return p.pat
        end
    end
    return nil
end

local function GetPoisonDisplay(text)
    if not text then return nil end
    for _, p in ipairs(POISON_DATA) do
        if text:find(p.pat) then
            local locale = GetLocale()
            local isES = (locale == "esES" or locale == "esMX")
            local useFull = ns.db.showFullPoisonName and not ns.db.abbreviateText
            if useFull then
                return isES and p.fES or p.fEN
            else
                return isES and p.sES or p.sEN
            end
        end
    end
    return nil
end

-- ============================================================
-- Hidden scan tooltip (reuse original name that worked in v1.2)
-- ============================================================
local scanTip = CreateFrame("GameTooltip", "TempEnchantTooltip", nil, "GameTooltipTemplate")
scanTip:SetOwner(UIParent, "ANCHOR_NONE")

-- GREEN lines that are NOT enchants
local SKIP_GREENS = {
    "Heroic", "Heroico",
    "Equip:", "Equipar:",
    "Use:", "Uso:",
    "Chance on hit:", "Probabilidad",
    "<Shift Right Click to Socket>",
    "Socket Bonus", "Bonus de ranura",
    "Set:", "Conjunto:",
}

local function IsSkippableLine(text)
    if not text then return true end
    for _, s in ipairs(SKIP_GREENS) do
        if text == s or text:sub(1, #s) == s then return true end
    end
    if text:match("^%(") then return true end
    if text:match("^<")  then return true end
    return false
end

-- ============================================================
-- Abbreviate a stat line or return raw text
-- ============================================================
local function AbbreviateText(text, abbrev)
    if not abbrev then return text end
    -- Named enchant?
    if NAMED_ENCHANTS[text] then return NAMED_ENCHANTS[text] end
    -- Pattern match?
    local abbrText = MatchStatLine(text)
    if abbrText then return abbrText end
    -- Truncate
    if #text > 14 then return text:sub(1, 12) .. ".." end
    return text
end

-- ============================================================
-- Single-pass scan: returns enchantText, gemText
--
-- Strategy: scan all tooltip lines sequentially.
--   - Enchant = first GREEN line that isn't in SKIP_GREENS
--   - Gems = lines that start with "+" and appear AFTER the enchant
--            line, stopping at "Socket Bonus:" or "Durability" or
--            any non-"+" line.
-- This avoids relying on color for gems entirely.
-- ============================================================
local function ScanSlotTooltip(slot)
    scanTip:SetOwner(UIParent, "ANCHOR_NONE")
    scanTip:ClearLines()
    scanTip:SetInventoryItem("player", slot)

    local abbrev = ns.db.abbreviateText
    local enchantResult = nil
    local gemParts = {}
    local enchantLineFound = false
    local collectingGems = false

    -- Strip WoW texture/color escape sequences: |T...|t |c........|r
    local function StripEscapes(str)
        str = str:gsub("|T.-|t", "")    -- texture escapes (gem icons)
        str = str:gsub("|c%x%x%x%x%x%x%x%x", "")  -- color codes
        str = str:gsub("|r", "")         -- color reset
        return str:match("^%s*(.-)%s*$") -- trim spaces
    end

    -- Check if cleaned text is a gem stat line (starts with "+digit")
    local function IsGemLine(rawText)
        local clean = StripEscapes(rawText)
        return clean:match("^%+%d+") ~= nil
    end

    local numLines = scanTip:NumLines()
    local poisonResult = nil

    -- Pass 1: find enchant (skip poison lines) + find poison
    for i = 2, numLines do
        local fs = _G["TempEnchantTooltipTextLeft" .. i]
        if not fs then break end
        local text = fs:GetText()
        if not text or text == "" then break end
        local r, g, b = fs:GetTextColor()
        local isGreen = (g > 0.5 and r < 0.3 and b < 0.3)
        if isGreen and not IsSkippableLine(text) then
            local pd = GetPoisonDisplay(text)
            if pd then
                poisonResult = pd
            elseif not enchantLineFound then
                enchantResult = AbbreviateText(text, abbrev)
                enchantLineFound = true
            end
        end
    end

    -- Pass 2: collect gems — must be gold/orange colored AND start with +digit
    -- White stat lines (+99 Stamina) are excluded by color check
    for i = 2, numLines do
        local fs = _G["TempEnchantTooltipTextLeft" .. i]
        if not fs then break end
        local text = fs:GetText()
        if not text or text == "" then break end
        if text:match("Socket Bonus") or text:match("Bonus de ranura") then break end
        if text:match("^Set:") or text:match("^Conjunto:") then break end
        if IsGemLine(text) then
            local gr, gg, gb = fs:GetTextColor()
            -- Gold/orange gem color: r>0.75, g 0.55-0.90, b<0.25
            local isGemColor = (gr > 0.75 and gg > 0.55 and gg < 0.90 and gb < 0.25)
            if isGemColor then
                local clean = StripEscapes(text)
                table.insert(gemParts, AbbreviateText(clean, abbrev))
            end
        end
    end

    local gemResult = nil
    if #gemParts > 0 then
        gemResult = table.concat(gemParts, "\n")
    end
    -- Find which poison pattern was detected (for bag icon lookup)
    local poisonPat = nil
    for i = 2, numLines do
        local fs = _G["TempEnchantTooltipTextLeft" .. i]
        if not fs then break end
        local t = fs:GetText()
        if not t or t == "" then break end
        local r, g, b = fs:GetTextColor()
        if g > 0.5 and r < 0.3 and b < 0.3 then
            local pp = GetPoisonPatternFromText(t)
            if pp then poisonPat = pp; break end
        end
    end
    return enchantResult, gemResult, poisonResult, poisonPat
end

-- ============================================================
-- Utility: reusable timer pool (no frame leaks)
-- ============================================================
local timerFrame = CreateFrame("Frame")
local pendingTimers = {}   -- [key] = { remaining, callback }

timerFrame:SetScript("OnUpdate", function(self, elapsed)
    local any = false
    for key, t in pairs(pendingTimers) do
        t.remaining = t.remaining - elapsed
        if t.remaining <= 0 then
            pendingTimers[key] = nil
            t.callback()
        else
            any = true
        end
    end
    if not any then self:Hide() end
end)
timerFrame:Hide()

--- Schedule a callback with debounce: same key cancels previous timer.
-- @param key    string identifier (reuse = debounce)
-- @param delay  seconds
-- @param func   callback
local function RunAfterDelay(key, delay, func)
    pendingTimers[key] = { remaining = delay, callback = func }
    timerFrame:Show()
end

-- ============================================================
-- Main frame
-- ============================================================
local frame = EquippedWeaponsFrame
if not frame then
    frame = CreateFrame("Frame", "EquippedWeaponsFrame", UIParent)
end
EquippedWeaponsFrame = frame

frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")

frame:SetScript("OnDragStart", function(self)
    if not ns.db.locked and IsShiftKeyDown() and IsAltKeyDown() then
        self:StartMoving()
    end
end)

frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, _, xOfs, yOfs = self:GetPoint()
    ns.db.point = point
    ns.db.xOfs  = xOfs
    ns.db.yOfs  = yOfs
end)

local function SetLocked(state)
    ns.db.locked = state
    frame:EnableMouse(not state)
end

-- ============================================================
-- Slot icons
-- ============================================================
if not MainHandIcon  then MainHandIcon  = CreateFrame("Frame", "MainHandIcon",  frame) end
if not OffHandIcon   then OffHandIcon   = CreateFrame("Frame", "OffHandIcon",   frame) end
if not RangedIcon    then RangedIcon    = CreateFrame("Frame", "RangedIcon",    frame) end

local slots = {
    [16] = MainHandIcon,
    [17] = OffHandIcon,
    [18] = RangedIcon,
}

local function CreateQualityBorder(parent)
    local border = parent:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    border:SetBlendMode("ADD")
    border:SetPoint("TOPLEFT",     parent, "TOPLEFT",     -15,  15)
    border:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT",  15, -15)
    border:Hide()
    return border
end

for slot, icon in pairs(slots) do
    icon:SetSize(config.iconSize, config.iconSize)
    icon.texture = icon.texture or icon:CreateTexture(nil, "ARTWORK")
    icon.texture:SetAllPoints()

    icon.qualityBorder = icon.qualityBorder or CreateQualityBorder(icon)

    -- Vertical layout stacking (bottom to top): icon -> enchantText -> poisonText -> gemText
    if not icon.enchantText then
        icon.enchantText = icon:CreateFontString(nil, "OVERLAY")
        icon.enchantText:SetFont("Fonts\\FRIZQT__.TTF", ns.db and ns.db.textSize or config.textSize, "OUTLINE")
        icon.enchantText:SetTextColor(1.0, 0.82, 0.0, 1)
        icon.enchantText:SetJustifyH("CENTER")
        icon.enchantText:SetWidth(150)
        icon.enchantText:SetPoint("BOTTOM", icon, "TOP", 0, 2)
    end

    if not icon.poisonText then
        icon.poisonText = icon:CreateFontString(nil, "OVERLAY")
        icon.poisonText:SetFont("Fonts\\FRIZQT__.TTF", ns.db and ns.db.textSize or config.textSize, "OUTLINE")
        icon.poisonText:SetTextColor(0.0, 1.0, 0.27, 1)  -- green
        icon.poisonText:SetJustifyH("CENTER")
        icon.poisonText:SetWidth(150)
        icon.poisonText:SetPoint("BOTTOM", icon.enchantText, "TOP", 0, 2)
        icon.poisonText:Hide()
    end

    if not icon.gemText then
        icon.gemText = icon:CreateFontString(nil, "OVERLAY")
        icon.gemText:SetFont("Fonts\\FRIZQT__.TTF", ns.db and ns.db.textSize or config.textSize, "OUTLINE")
        icon.gemText:SetTextColor(1.0, 1.0, 1.0, 1)
        icon.gemText:SetJustifyH("CENTER")
        icon.gemText:SetWidth(150)
        icon.gemText:SetPoint("BOTTOM", icon.poisonText, "TOP", 0, 2)
        icon.gemText:Hide()
    end

    -- Horizontal combined text (to the right)
    if not icon.horizontalText then
        icon.horizontalText = icon:CreateFontString(nil, "OVERLAY")
        icon.horizontalText:SetFont("Fonts\\FRIZQT__.TTF", ns.db and ns.db.textSize or config.textSize, "OUTLINE")
        icon.horizontalText:SetTextColor(1, 1, 1, 1)
        icon.horizontalText:SetJustifyH("LEFT")
        icon.horizontalText:SetWidth(200)
        icon.horizontalText:SetPoint("LEFT", icon, "RIGHT", 5, 0)
        icon.horizontalText:Hide()
    end

    icon:SetScript("OnEnter", function()
        GameTooltip:SetOwner(icon, "ANCHOR_RIGHT")
        GameTooltip:SetInventoryItem("player", slot)
    end)
    icon:SetScript("OnLeave", GameTooltip_Hide)
end

-- ============================================================
-- Border helper
-- ============================================================
local function SetBorderVisibility(icon, visible, rarity)
    if visible and rarity and rarity > 1 then
        local r, g, b = GetItemQualityColor(rarity)
        icon.qualityBorder:SetVertexColor(r, g, b)
        icon.qualityBorder:Show()
    else
        icon.qualityBorder:Hide()
    end
end

-- ============================================================
-- Slot label fallback
-- ============================================================
local _, playerClass = UnitClass("player")

local function GetSlotLabel(slot)
    if slot == 16 then return "MH"
    elseif slot == 17 then return "OH"
    elseif slot == 18 then
        if playerClass == "PALADIN" or playerClass == "SHAMAN"
           or playerClass == "DRUID" or playerClass == "DEATHKNIGHT" then
            return "RELIC"
        end
        return "RG"
    end
    return ""
end

-- ============================================================
-- UpdateWeaponSlot
-- ============================================================
local function UpdateWeaponSlot(slot)
    local icon = slots[slot]
    if not icon then return end

    local shouldShow = false
    if     slot == 16 then shouldShow = ns.db.showSlot16
    elseif slot == 17 then shouldShow = ns.db.showSlot17
    elseif slot == 18 then shouldShow = ns.db.showSlot18
    end

    if not shouldShow then
        icon:Hide()
        return
    end

    local link = GetInventoryItemLink("player", slot)
    local texture
    if link then
        local itemID = tonumber(link:match("item:(%d+):"))
        if itemID then texture = GetItemIcon(itemID) end
    end

    if not (texture and link) then
        icon:Hide()
        return
    end

    icon.texture:SetTexture(texture)
    icon:Show()

    local name, _, rarity = GetItemInfo(link)
    if not name then
        RunAfterDelay("cache_" .. slot, 0.1, function() UpdateWeaponSlot(slot) end)
        return
    end

    SetBorderVisibility(icon, ns.db.showClassBorders, rarity)

    -- Gather info
    local enchantText, gemText, poisonText
    local isHorizontal = ns.db.horizontalText
    local itemID = GetInventoryItemID("player", slot)

    -- Special: Paladin libram/shield with resilience (known PvP librams)
    if slot == 17 and playerClass == "PALADIN"
       and (itemID == 51533 or itemID == 42561) then
        enchantText = "RESIL"
        gemText = nil
    else
        -- Single tooltip pass: get both enchant and gems at once
        local scanEnch, scanGems, scanPoison, scanPoisonPat = ScanSlotTooltip(slot)
        if ns.db.showEnchants then enchantText = scanEnch end
        if ns.db.showGems     then gemText     = scanGems end
        if ns.db.showPoison and scanPoison then poisonText = scanPoison end
        -- Swap weapon icon to poison icon (found in bags)
        if ns.db.showPoisonIcon and scanPoisonPat then
            local poisonIcon = GetPoisonIconFromBags(scanPoisonPat)
            if poisonIcon then
                icon.texture:SetTexture(poisonIcon)
            end
        end
    end

    -- ---- Render text ----
    local GOLD  = "|cFFFFD100"  -- enchant color
    local WHITE = "|cFFFFFFFF"  -- gem color
    local GREEN = "|cFF00FF44"  -- poison color
    local RESET = "|r"

    if isHorizontal then
        local lines = {}
        if poisonText and poisonText ~= "" then
            table.insert(lines, GREEN .. poisonText .. RESET)
        end
        if enchantText and enchantText ~= "" then
            table.insert(lines, GOLD .. enchantText .. RESET)
        end
        if gemText and gemText ~= "" then
            for gem in gemText:gmatch("([^\n]+)") do
                table.insert(lines, WHITE .. gem .. RESET)
            end
        end
        if #lines > 0 then
            icon.horizontalText:SetText(table.concat(lines, "\n"))
        else
            if not ns.db.hideSlotLabels then
                icon.horizontalText:SetText(GetSlotLabel(slot))
            else
                icon.horizontalText:SetText("")
            end
        end
        icon.horizontalText:Show()
        icon.enchantText:Hide()
        icon.gemText:Hide()
        icon.poisonText:Hide()
    else
        -- Vertical mode (colors set on FontString directly)
        icon.horizontalText:Hide()

        if gemText and gemText ~= "" then
            icon.gemText:SetText(gemText)
            icon.gemText:Show()
        else
            icon.gemText:Hide()
        end

        -- Enchant (gold, just above icon)
        if enchantText and enchantText ~= "" then
            icon.enchantText:SetTextColor(1.0, 0.82, 0.0, 1)
            icon.enchantText:SetText(enchantText)
            icon.enchantText:Show()
        else
            if not ns.db.hideSlotLabels then
                icon.enchantText:SetTextColor(1.0, 1.0, 1.0, 1)
                icon.enchantText:SetText(GetSlotLabel(slot))
                icon.enchantText:Show()
            else
                icon.enchantText:Hide()
            end
        end

        -- Poison (green, above enchant)
        if poisonText and poisonText ~= "" then
            icon.poisonText:SetText(poisonText)
            icon.poisonText:Show()
        else
            icon.poisonText:SetText("")
            icon.poisonText:Hide()
        end

        -- Gems (white, above poison)
        -- Reanchor gemText above poisonText if poison visible, else above enchantText
        icon.gemText:ClearAllPoints()
        if poisonText and poisonText ~= "" then
            icon.gemText:SetPoint("BOTTOM", icon.poisonText, "TOP", 0, 2)
        else
            icon.gemText:SetPoint("BOTTOM", icon.enchantText, "TOP", 0, 2)
        end
    end
end

-- ============================================================
-- UpdateIconPositions
-- ============================================================
local function UpdateIconPositions()
    if not slots[16] or not slots[17] or not slots[18] then return end

    local visibleSlots = {}
    for _, sid in ipairs({16, 17, 18}) do
        local show = (sid == 16 and ns.db.showSlot16)
                  or (sid == 17 and ns.db.showSlot17)
                  or (sid == 18 and ns.db.showSlot18)
        if show then
            table.insert(visibleSlots, slots[sid])
        else
            slots[sid]:Hide()
        end
    end

    if #visibleSlots == 0 then return end

    visibleSlots[1]:ClearAllPoints()

    if ns.db.verticalLayout then
        if ns.db.layoutDirection == "down" then
            visibleSlots[1]:SetPoint("TOP", frame, "TOP", 0, 0)
            for i = 2, #visibleSlots do
                visibleSlots[i]:ClearAllPoints()
                visibleSlots[i]:SetPoint("TOP", visibleSlots[i-1], "BOTTOM", 0, -(ns.db.iconSpacing * 5))
            end
        else
            visibleSlots[1]:SetPoint("BOTTOM", frame, "BOTTOM", 0, 0)
            for i = 2, #visibleSlots do
                visibleSlots[i]:ClearAllPoints()
                visibleSlots[i]:SetPoint("BOTTOM", visibleSlots[i-1], "TOP", 0, ns.db.iconSpacing * 5)
            end
        end
    else
        visibleSlots[1]:SetPoint("LEFT", frame, "LEFT", 0, 0)
        for i = 2, #visibleSlots do
            visibleSlots[i]:ClearAllPoints()
            visibleSlots[i]:SetPoint("LEFT", visibleSlots[i-1], "RIGHT", ns.db.iconSpacing * 5, 0)
        end
    end

    -- Refresh content
    if ns.db.showSlot16 then UpdateWeaponSlot(16) end
    if ns.db.showSlot17 then UpdateWeaponSlot(17) end
    if ns.db.showSlot18 then UpdateWeaponSlot(18) end

    -- Fix #8: Resize parent frame to fit visible children (drag zone match)
    local n = #visibleSlots
    local iSize = config.iconSize
    local gap   = ns.db.iconSpacing * 5
    if ns.db.verticalLayout then
        frame:SetSize(iSize, n * iSize + (n - 1) * gap)
    else
        frame:SetSize(n * iSize + (n - 1) * gap, iSize)
    end
end

-- ============================================================
-- UpdateAllWeapons / UpdateTextSize
-- ============================================================
local function UpdateAllWeapons()
    for slot in pairs(slots) do
        UpdateWeaponSlot(slot)
    end
end

local function UpdateTextSize()
    local size = ns.db.textSize or config.textSize
    for _, icon in pairs(slots) do
        icon.gemText:SetFont("Fonts\\FRIZQT__.TTF", size, "OUTLINE")
        icon.enchantText:SetFont("Fonts\\FRIZQT__.TTF", size, "OUTLINE")
        icon.poisonText:SetFont("Fonts\\FRIZQT__.TTF", size, "OUTLINE")
        icon.horizontalText:SetFont("Fonts\\FRIZQT__.TTF", size, "OUTLINE")
    end
end

-- ============================================================
-- Expose globals for Options panel
-- ============================================================
_G.UpdateAllWeapons                  = UpdateAllWeapons
_G.EquippedWeapons_UpdateAllWeapons  = UpdateAllWeapons
_G.UpdateIconPositions               = UpdateIconPositions
_G.EquippedWeapons_UpdateIconPositions = UpdateIconPositions
_G.UpdateTextSize                    = UpdateTextSize
_G.SetLocked                         = SetLocked

-- ============================================================
-- Events
-- ============================================================
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("BAG_UPDATE")
frame:RegisterEvent("UNIT_AURA")

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "EquippedWeapons" then
        -- Initialize profile system (global vs per-character)
        ns.InitProfiles()

        if not ns.db.classDefaultsApplied then
            ns.db.classDefaultsApplied = true
            local _, pClass = UnitClass("player")
            if pClass == "HUNTER" then
                ns.SetCharProfile(true)
                ns.db.showEnchants=true; ns.db.showGems=true; ns.db.horizontalText=true
                ns.db.showSlot16=true; ns.db.showSlot17=false; ns.db.showSlot18=false
                ns.db.showClassBorders=false; ns.db.hideSlotLabels=false
                ns.db.verticalLayout=false; ns.db.layoutDirection="down"
                ns.db.abbreviateText=false; ns.db.locked=false
                ns.db.showFullPoisonName=false; ns.db.showPoison=false
            elseif pClass == "ROGUE" then
                ns.SetCharProfile(true)
                ns.db.showEnchants=true; ns.db.showGems=true; ns.db.horizontalText=true
                ns.db.showSlot16=true; ns.db.showSlot17=true; ns.db.showSlot18=false
                ns.db.showClassBorders=false; ns.db.hideSlotLabels=false
                ns.db.verticalLayout=false; ns.db.layoutDirection="down"
                ns.db.abbreviateText=false; ns.db.locked=false
                ns.db.showFullPoisonName=false; ns.db.showPoison=true; ns.db.showPoisonIcon=false
            end
        end

        frame:ClearAllPoints()
        if ns.db.point == "BOTTOMRIGHT" and ns.db.xOfs == -10 and ns.db.yOfs == 10 then
            local bar = MultiBarBottomRight or MultiBarBottomLeft or MainMenuBar
            if bar then
                frame:SetPoint("BOTTOMRIGHT", bar, "TOPRIGHT", 0, 4)
            else
                frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -10, 220)
            end
        else
            frame:SetPoint(ns.db.point, UIParent, ns.db.point, ns.db.xOfs, ns.db.yOfs)
        end
        frame:SetScale(ns.db.scale or 1)

        SetLocked(ns.db.locked)
        UpdateTextSize()
        UpdateIconPositions()
        -- Delay first full update so item cache is warm
        RunAfterDelay("init", 0.3, UpdateAllWeapons)
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        -- Longer delay on world enter for cache
        RunAfterDelay("world", 0.5, function()
            UpdateAllWeapons()
            UpdateIconPositions()
        end)
        return
    end

    if event == "PLAYER_EQUIPMENT_CHANGED" then
        RunAfterDelay("equip", 0.1, function()
            UpdateAllWeapons()
            UpdateIconPositions()
        end)
    end

    -- Real-time poison update when bags change or auras change
    if event == "BAG_UPDATE" then
        RunAfterDelay("refresh", 0.3, UpdateAllWeapons)
    end

    if event == "UNIT_AURA" and arg1 == "player" then
        RunAfterDelay("refresh", 0.2, UpdateAllWeapons)
    end
end)

-- ============================================================
-- Slash commands
-- ============================================================
SLASH_EQUIPPEDWEAPONS1 = "/equippedweapons"
SLASH_EQUIPPEDWEAPONS2 = "/ew"

SlashCmdList["EQUIPPEDWEAPONS"] = function(msg)
    msg = (msg or ""):lower():gsub("^%s+",""):gsub("%s+$","")
    if msg == "" then
        InterfaceOptionsFrame_OpenToCategory("EquippedWeapons")
        InterfaceOptionsFrame_OpenToCategory("EquippedWeapons")
        return
    end

    if msg == "reset" then
        for k, v in pairs(DB_DEFAULTS) do ns.db[k] = v end
        ns.db.classDefaultsApplied = nil   -- allow class defaults on next reload
        local _, pClass = UnitClass("player")
        if pClass == "HUNTER" then
            ns.SetCharProfile(true)
            ns.db.showEnchants=true; ns.db.showGems=true; ns.db.horizontalText=true
            ns.db.showSlot16=true; ns.db.showSlot17=false; ns.db.showSlot18=false
            ns.db.showClassBorders=false; ns.db.hideSlotLabels=false
            ns.db.verticalLayout=false; ns.db.layoutDirection="down"
            ns.db.abbreviateText=false; ns.db.locked=false
            ns.db.showFullPoisonName=false; ns.db.showPoison=false
        elseif pClass == "ROGUE" then
            ns.SetCharProfile(true)
            ns.db.showEnchants=true; ns.db.showGems=true; ns.db.horizontalText=true
            ns.db.showSlot16=true; ns.db.showSlot17=true; ns.db.showSlot18=false
            ns.db.showClassBorders=false; ns.db.hideSlotLabels=false
            ns.db.verticalLayout=false; ns.db.layoutDirection="down"
            ns.db.abbreviateText=false; ns.db.locked=false
            ns.db.showFullPoisonName=false; ns.db.showPoison=true; ns.db.showPoisonIcon=false
        end
        frame:ClearAllPoints()
        local bar = MultiBarBottomRight or MultiBarBottomLeft or MainMenuBar
        if bar then
            frame:SetPoint("BOTTOMRIGHT", bar, "TOPRIGHT", 0, 4)
        else
            frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -10, 220)
        end
        ns.db.point="BOTTOMRIGHT"; ns.db.xOfs=-10; ns.db.yOfs=10
        frame:SetScale(1.3); frame:EnableMouse(true)
        UpdateTextSize(); UpdateAllWeapons(); UpdateIconPositions()
        if EquippedWeaponsOptionsPanel and EquippedWeaponsOptionsPanel.refresh then
            EquippedWeaponsOptionsPanel.refresh()
        end
        EWPrint("|cFF00FF00EquippedWeapons|r: Configuration reset.")
        return
    end

    if msg:match("^scale%s+([%d%.]+)$") then
        local s = tonumber(msg:match("^scale%s+([%d%.]+)$"))
        if s and s > 0 then
            ns.db.scale = s
            frame:SetScale(s)
            EWPrint("|cFF00FF00EquippedWeapons|r: Scale " .. s)
        end
        return
    end

    if msg:match("^iconspacing%s+(%d+)$") then
        local n = tonumber(msg:match("^iconspacing%s+(%d+)$"))
        if n then
            ns.db.iconSpacing = n
            UpdateIconPositions()
            EWPrint("|cFF00FF00EquippedWeapons|r: Icon spacing " .. n)
        end
        return
    end

    if msg == "lock"   then SetLocked(true);  return end
    if msg == "unlock" then SetLocked(false); return end
    EWPrint("|cFFFF0000EquippedWeapons|r: Unknown command. Use /ew  /ew lock  /ew unlock  /ew scale <n>  /ew reset")
end