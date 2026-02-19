-- LokiAssist.lua
-- Simple version - minimal APIs that definitely work
-- Version 4.0

local frame = CreateFrame("Frame")
local updateTimer = 0
local loaded = false

-- Game state
local gameState = {
    playerName = "",
    playerClass = "",
    healthPercent = 100,
    health = 100,
    maxHealth = 100,
    power = 0,
    maxPower = 100,
    inCombat = false,
    targetName = "",
    targetHealthPercent = 100
}

-- Register events
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")

frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        gameState.playerName = UnitName("player")
        gameState.playerClass = select(2, UnitClass("player"))
        loaded = true

        print("|cFF00FF00LokiAssist|r v4.0 loaded")

    elseif event == "PLAYER_REGEN_DISABLED" then
        gameState.inCombat = true

    elseif event == "PLAYER_REGEN_ENABLED" then
        gameState.inCombat = false
    end
end)

-- Update loop
frame:SetScript("OnUpdate", function(self, elapsed)
    if not loaded then return end

    updateTimer = updateTimer + elapsed

    if updateTimer >= 0.2 then
        -- Get player health
        local hp = UnitHealth("player")
        local maxHp = UnitHealthMax("player")
        if maxHp > 0 then
            gameState.health = hp
            gameState.maxHealth = maxHp
            gameState.healthPercent = math.floor((hp / maxHp) * 100)
        end

        -- Get power
        gameState.power = UnitPower("player")
        gameState.maxPower = UnitPowerMax("player")

        -- Get combat status
        gameState.inCombat = InCombatLockdown()

        -- Get target
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

        -- Send data
        self:SendState()

        updateTimer = 0
    end
end)

function frame:SendState()
    local msg = string.format(
        "@LOKI@HP:%d,PP:%d,MP:%d,IC:%d,TN:%s,THP:%d",
        gameState.healthPercent,
        gameState.power,
        gameState.maxPower,
        gameState.inCombat and 1 or 0,
        gameState.targetName,
        gameState.targetHealthPercent
    )

    SendChatMessage(msg, "WHISPER", nil, gameState.playerName)
end

-- Slash command
SLASH_LOKI1 = "/loki"
SlashCmdList["LOKI"] = function(msg)
    msg = strlower(msg or "")
    if msg == "status" or msg == "" then
        print("HP: " .. gameState.healthPercent .. "%")
        print("Power: " .. gameState.power .. "/" .. gameState.maxPower)
        print("Combat: " .. (gameState.inCombat and "Yes" or "No"))
        print("Target: " .. gameState.targetName .. " (" .. gameState.targetHealthPercent .. "%)")
    end
end
