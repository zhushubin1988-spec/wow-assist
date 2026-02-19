-- LokiAssist.lua
-- WoW Auto Rotation Assistant
-- Uses macros to communicate with Python backend

local frame = CreateFrame("Frame")
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
    buffs = {},
    debuffs = {},
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
        loaded = true

        print("|cFF00FF00LokiAssist|r loaded! Version 1.1.0")
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
        self:UpdateState()
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

-- Expose gameState globally for Python to read
_G.LokiAssistState = gameState
