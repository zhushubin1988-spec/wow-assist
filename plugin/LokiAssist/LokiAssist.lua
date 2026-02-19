-- LokiAssist.lua
-- WoW Auto Rotation Assistant v2.0
-- Uses chat channel to send state to Python

local frame = CreateFrame("Frame")
local updateTimer = 0
local loaded = false

-- Keybind configuration
local spellKeybinds = {}

-- Game state
local gameState = {
    playerName = "",
    playerClass = "",
    healthPercent = 100,
    power = 0,
    maxPower = 100,
    inCombat = false,
    targetName = "",
    targetHealthPercent = 100,
    buffs = {},
    debuffs = {}
}

-- Spells list by class
local spellsList = {
    DEATHKNIGHT = {"暗影打击", "心脏打击", "灵界打击", "符文打击", "枯萎凋零", "传染", "血液沸腾"},
    HUNTER = {"杀戮命令", "奥术射击", "多重射击", "稳固射击", "钉刺", "狂野怒火"},
    WARRIOR = {"致死打击", "巨人打击", "压制", "顺劈斩", "英勇打击", "撕裂", "冲锋"},
    MONK = {"猛虎掌", "幻灭踢", "碎玉闪电", "连击", "腿击", "旭日东升踢", "轮回之触"},
    SHAMAN = {"闪电箭", "大地震击", "风暴打击", "烈焰震击", "冰霜震击", "元素冲击"},
    DRUID = {"凶猛撕咬", "斜掠", "割裂", "爪击", "裂伤", "猫的攻击", "狂暴"},
}

-- Create configuration UI
local function CreateConfigUI()
    local f = CreateFrame("Frame", "LokiAssistConfig", UIParent, "UIPanelDialogTemplate")
    f:SetSize(450, 350)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:Hide()

    -- Title
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", f, "TOP", 0, -10)
    title:SetText("LokiAssist - Keybind Configuration")

    -- Instructions
    local desc = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    desc:SetPoint("TOP", title, "BOTTOM", 0, -10)
    desc:SetText("Enter the key bound to each spell.\nExample: 1, 2, Q, W, E, R")

    -- Create spell rows
    local currentClass = gameState.playerClass
    local spells = spellsList[currentClass] or {}
    local yOffset = 0

    for i, spellName in ipairs(spells) do
        local row = CreateFrame("Frame", nil, f)
        row:SetSize(400, 25)
        row:SetPoint("TOPLEFT", 20, -60 - yOffset)

        local spellLabel = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        spellLabel:SetPoint("LEFT")
        spellLabel:SetText(spellName)

        local keyInput = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
        keyInput:SetSize(50, 25)
        keyInput:SetPoint("RIGHT")
        keyInput:SetMaxLetters(3)
        keyInput:SetText(spellKeybinds[spellName] or "")
        keyInput:SetScript("OnTextChanged", function(self)
            local key = strupper(self:GetText())
            if key == "" then
                spellKeybinds[spellName] = nil
            else
                spellKeybinds[spellName] = key
            end
        end)

        yOffset = yOffset + 30
    end

    -- Toggle button
    local toggleBtn = CreateFrame("Button", "LokiAssistToggle", UIParent, "UIPanelButtonTemplate")
    toggleBtn:SetSize(120, 25)
    toggleBtn:SetPoint("TOPRIGHT", -50, -100)
    toggleBtn:SetText("LokiAssist")
    toggleBtn:SetScript("OnClick", function()
        if f:IsShown() then f:Hide() else f:Show() end
    end)
end

-- Register events
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")

frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        gameState.playerName = UnitName("player")
        gameState.playerClass = select(2, UnitClass("player"))
        loaded = true
        CreateConfigUI()
        print("|cFF00FF00LokiAssist|r v2.0 loaded!")
        print("Click |cFFFF00LokiAssist|r button to configure keybinds")
    elseif event == "PLAYER_REGEN_ENABLED" then
        gameState.inCombat = false
    elseif event == "PLAYER_REGEN_DISABLED" then
        gameState.inCombat = true
    end
end)

-- Update loop - runs every 0.1 seconds
frame:SetScript("OnUpdate", function(self, elapsed)
    if not loaded then return end
    updateTimer = updateTimer + elapsed
    if updateTimer >= 0.2 then
        self:UpdateState()
        self:SendState()
        updateTimer = 0
    end
end)

function frame:UpdateState()
    local health = UnitHealth("player")
    local maxHealth = UnitHealthMax("player")
    if maxHealth > 0 then
        gameState.healthPercent = math.floor((health / maxHealth) * 100)
    end

    gameState.power = UnitPower("player")
    gameState.maxPower = UnitPowerMax("player")

    if UnitExists("target") then
        gameState.targetName = UnitName("target")
        local thp = UnitHealth("target")
        local maxThp = UnitHealthMax("target")
        if maxThp > 0 then
            gameState.targetHealthPercent = math.floor((thp / maxThp) * 100)
        end
    else
        gameState.targetName = ""
        gameState.targetHealthPercent = 100
    end

    -- Buffs
    gameState.buffs = {}
    for i = 1, 40 do
        local name = UnitBuff("player", i)
        if name then gameState.buffs[name] = true end
    end

    -- Debuffs
    gameState.debuffs = {}
    if UnitExists("target") then
        for i = 1, 40 do
            local name = UnitDebuff("target", i)
            if name then gameState.debuffs[name] = true end
        end
    end
end

function frame:SendState()
    -- Build state data
    local data = {
        p = gameState.playerName,
        c = gameState.playerClass,
        hp = gameState.healthPercent,
        pp = gameState.power,
        mp = gameState.maxPower,
        ic = gameState.inCombat and 1 or 0,
        tn = gameState.targetName,
        thp = gameState.targetHealthPercent,
        kb = spellKeybinds,
        bf = gameState.buffs,
        df = gameState.debuffs
    }

    -- Convert to compact string format (to avoid chat message limits)
    -- Format: @LOKI@Data
    local msg = "@LOKI@Data|" .. TableToString(data)

    -- Send to self via whisper (doesn't actually send, just processes)
    -- Use a hidden channel approach
    SendChatMessage(msg, "WHISPER", nil, gameState.playerName)
end

function TableToString(t)
    local parts = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            -- For buffs/debuffs, just send count
            local count = 0
            for _ in pairs(v) do count = count + 1 end
            table.insert(parts, k .. ":" .. count)
        elseif type(v) == "string" then
            table.insert(parts, k .. ":" .. v)
        else
            table.insert(parts, k .. ":" .. tostring(v))
        end
    end
    return table.concat(parts, ",")
end

-- Slash command
SLASH_LOKI1 = "/loki"
SlashCmdList["LOKI"] = function(msg)
    msg = strlower(msg or "")
    if msg == "config" or msg == "" then
        if _G.LokiAssistConfig then
            if _G.LokiAssistConfig:IsShown() then
                _G.LokiAssistConfig:Hide()
            else
                _G.LokiAssistConfig:Show()
            end
        end
    elseif msg == "status" then
        print("HP: " .. gameState.healthPercent .. "% | Power: " .. gameState.power)
        print("Combat: " .. (gameState.inCombat and "Yes" or "No"))
    end
end
