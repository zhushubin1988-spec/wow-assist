-- LokiAssist.lua
-- WoW Auto Rotation Assistant

local frame = CreateFrame("Frame")
local stateFilePath = nil
local updateTimer = 0

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
    bossName = "",
    bossHealthPercent = 100,
    cooldowns = {},
    buffs = {},
    debuffs = {},
    trinketReady = true,
    potionReady = true,
    position = {x = 0, y = 0},
    targetPosition = {x = 0, y = 0}
}

-- Events
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("UNIT_POWER")
frame:RegisterEvent("UNIT_HEALTH")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("UNIT_AURA")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        local name = UnitName("player")
        local class = select(2, UnitClass("player"))
        gameState.playerName = name
        gameState.playerClass = class

        -- Set up state file path
        local appData = os.getenv("LOCALAPPDATA") or (os.getenv("APPDATA") .. "/Local")
        local addonDir = appData .. "/LokiAssist"
        os.execute('mkdir "' .. addonDir .. '" 2>nul')
        stateFilePath = addonDir .. "/game_state.json"

        print("|cFF00FF00LokiAssist|r loaded! Version 1.0.4")
        print("State file: " .. stateFilePath)
    elseif event == "PLAYER_REGEN_ENABLED" then
        gameState.inCombat = false
    elseif event == "PLAYER_REGEN_DISABLED" then
        gameState.inCombat = true
    end
end)

-- Update loop
frame:SetScript("OnUpdate", function(self, elapsed)
    updateTimer = updateTimer + elapsed
    if updateTimer >= 0.5 then
        self:UpdateState()
        self:SaveState()
        updateTimer = 0
    end
end)

function frame:UpdateState()
    -- Player info
    local health = UnitHealth("player")
    local maxHealth = UnitHealthMax("player")
    gameState.healthPercent = math.floor((health / maxHealth) * 100)

    gameState.power = UnitPower("player")
    gameState.maxPower = UnitPowerMax("player")

    -- Target info
    if UnitExists("target") then
        gameState.targetName = UnitName("target")
        local thp = UnitHealth("target")
        local maxThp = UnitHealthMax("target")
        gameState.targetHealthPercent = math.floor((thp / maxThp) * 100)
    else
        gameState.targetName = ""
        gameState.targetHealthPercent = 100
    end

    -- Position
    local px, py = GetPlayerMapPosition("player")
    gameState.position = {x = px * 100, y = py * 100}

    if UnitExists("target") then
        local tx, ty = GetPlayerMapPosition("target")
        gameState.targetPosition = {x = tx * 100, y = ty * 100}
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

function frame:SaveState()
    if not stateFilePath then return end

    -- Check items
    local trinket1Slot = 13
    local start1, duration1 = GetInventoryItemCooldown("player", trinket1Slot)
    gameState.trinketReady = (start1 == 0 or (GetTime() - start1) >= duration1)

    -- Check potion
    gameState.potionReady = false
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local itemLink = GetContainerItemLink(bag, slot)
            if itemLink then
                local name = GetItemInfo(itemLink)
                if name and string.find(name, "Potion") then
                    local start = GetContainerItemCooldown(bag, slot)
                    if start == 0 or (GetTime() - start) >= 60 then
                        gameState.potionReady = true
                    end
                end
            end
        end
    end

    -- Simple JSON
    local json = self:TableToJSON(gameState)
    local file = io.open(stateFilePath, "w")
    if file then
        file:write(json)
        file:close()
    end
end

function frame:TableToJSON(t)
    local result = "{\n"
    local keys = {}
    for k in pairs(t) do table.insert(keys, k) end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)

    for i, k in ipairs(keys) do
        local v = t[k]
        local comma = i < #keys and "," or ""

        if type(k) == "string" then
            result = result .. '  "' .. k .. '": '
        else
            result = result .. '  "' .. tostring(k) .. '": '
        end

        if type(v) == "string" then
            result = result .. '"' .. v .. '"' .. comma .. "\n"
        elseif type(v) == "number" then
            result = result .. tostring(v) .. comma .. "\n"
        elseif type(v) == "boolean" then
            result = result .. (v and "true" or "false") .. comma .. "\n"
        elseif type(v) == "table" then
            result = result .. self:TableToJSON(v) .. comma .. "\n"
        else
            result = result .. "null" .. comma .. "\n"
        end
    end
    result = result .. "}"
    return result
end

-- Slash commands
SLASH_LOKI1 = "/loki"
SLASH_LOKI2 = "/lokiasist"

SlashCmdList["LOKI"] = function(msg)
    local cmd = strlower(msg or "")
    if cmd == "test" then
        print("LokiAssist: Test command works!")
        print("State file: " .. (stateFilePath or "nil"))
    elseif cmd == "status" then
        print("HP: " .. gameState.healthPercent .. "% | Power: " .. gameState.power)
        print("Combat: " .. (gameState.inCombat and "Yes" or "No"))
        print("Target: " .. gameState.targetName .. " (" .. gameState.targetHealthPercent .. "%)")
    elseif cmd == "save" then
        frame:UpdateState()
        frame:SaveState()
        print("State saved!")
    else
        print("Commands: /loki test, /loki status, /loki save")
    end
end
