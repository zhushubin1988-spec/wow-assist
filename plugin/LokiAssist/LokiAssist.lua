-- LokiAssist.lua
-- WoW Auto Rotation Assistant

local frame = CreateFrame("Frame")
local stateFilePath = nil
local updateTimer = 0
local loaded = false

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

-- Register events
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")

frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        local name = UnitName("player")
        local class = select(2, UnitClass("player"))
        gameState.playerName = name
        gameState.playerClass = class

        -- Set up state file path
        local appData = os.getenv("LOCALAPPDATA")
        if appData then
            stateFilePath = appData .. "/LokiAssist/game_state.json"
        else
            stateFilePath = nil
        end

        loaded = true
    elseif event == "PLAYER_REGEN_ENABLED" then
        gameState.inCombat = false
    elseif event == "PLAYER_REGEN_DISABLED" then
        gameState.inCombat = true
    end
end)

-- Update loop
frame:SetScript("OnUpdate", function(self, elapsed)
    if not loaded then return end
    updateTimer = updateTimer + elapsed
    if updateTimer >= 0.5 then
        pcall(self.UpdateState, self)
        pcall(self.SaveState, self)
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

    local px, py = GetPlayerMapPosition("player")
    gameState.position = {x = px or 0, y = py or 0}

    if UnitExists("target") then
        local tx, ty = GetPlayerMapPosition("target")
        gameState.targetPosition = {x = tx or 0, y = ty or 0}
    end

    gameState.buffs = {}
    for i = 1, 40 do
        local name = UnitBuff("player", i)
        if name then gameState.buffs[name] = true end
    end

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

    local trinket1Slot = 13
    local start1, duration1 = GetInventoryItemCooldown("player", trinket1Slot)
    if start1 then
        gameState.trinketReady = (start1 == 0 or (GetTime() - start1) >= duration1)
    end

    gameState.potionReady = false

    local json = TableToJSON(gameState)
    local file = io.open(stateFilePath, "w")
    if file then
        file:write(json)
        file:close()
    end
end

function TableToJSON(t)
    local result = "{\n"
    local keys = {}
    for k in pairs(t) do table.insert(keys, k) end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)

    for i, k in ipairs(keys) do
        local v = t[k]
        local comma = i < #keys and "," or ""
        result = result .. '  "' .. tostring(k) .. '": '

        if type(v) == "string" then
            result = result .. '"' .. v .. '"' .. comma .. "\n"
        elseif type(v) == "number" then
            result = result .. tostring(v) .. comma .. "\n"
        elseif type(v) == "boolean" then
            result = result .. (v and "true" or "false") .. comma .. "\n"
        elseif type(v) == "table" then
            result = result .. TableToJSON(v) .. comma .. "\n"
        else
            result = result .. "null" .. comma .. "\n"
        end
    end
    result = result .. "}"
    return result
end
