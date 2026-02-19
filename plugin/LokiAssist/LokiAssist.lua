-- LokiAssist.lua
-- Minimal version - uses only available APIs
-- Version 3.0

local frame = CreateFrame("Frame")
local updateTimer = 0
local loaded = false
local lastUpdate = 0

-- Game state (basic info only - APIs that still work)
local gameState = {
    playerName = "",
    playerClass = "",
    healthPercent = 100,
    health = 0,
    maxHealth = 0,
    power = 0,
    maxPower = 0,
    inCombat = false,
    targetName = "",
    targetExists = false,
    targetHealthPercent = 100,
    combatTime = 0
}

-- Register events
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")  -- Enter combat
frame:RegisterEvent("PLAYER_REGEN_ENABLED")    -- Leave combat
frame:RegisterEvent("UNIT_POWER")
frame:RegisterEvent("UNIT_HEALTH")

frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        gameState.playerName = UnitName("player")
        gameState.playerClass = select(2, UnitClass("player"))
        loaded = true

        -- Initial update
        self:UpdateBasicInfo()

        print("|cFF00FF00LokiAssist|r v3.0 loaded (Minimal)")
        print("APIs available: UnitHealth, UnitPower, InCombatLockdown")

    elseif event == "PLAYER_REGEN_DISABLED" then
        gameState.inCombat = true
        gameState.combatTime = GetTime()

    elseif event == "PLAYER_REGEN_ENABLED" then
        gameState.inCombat = false

    elseif event == "UNIT_POWER" or event == "UNIT_HEALTH" then
        -- Handled in UpdateBasicInfo
    end
end)

-- Update loop
frame:SetScript("OnUpdate", function(self, elapsed)
    if not loaded then return end

    updateTimer = updateTimer + elapsed

    -- Update every 0.1 seconds
    if updateTimer >= 0.1 then
        self:UpdateBasicInfo()
        self:SendState()
        updateTimer = 0
    end
end)

function frame:UpdateBasicInfo()
    -- Player health
    local health = UnitHealth("player")
    local maxHealth = UnitHealthMax("player")
    gameState.health = health
    gameState.maxHealth = maxHealth
    if maxHealth > 0 then
        gameState.healthPercent = math.floor((health / maxHealth) * 100)
    end

    -- Player power
    gameState.power = UnitPower("player")
    gameState.maxPower = UnitPowerMax("player")

    -- Combat status (alternative method)
    gameState.inCombat = InCombatLockdown()

    -- Target info
    if UnitExists("target") then
        gameState.targetExists = true
        gameState.targetName = UnitName("target")

        local targetHealth = UnitHealth("target")
        local targetMaxHealth = UnitHealthMax("target")
        if targetMaxHealth > 0 then
            gameState.targetHealthPercent = math.floor((targetHealth / targetMaxHealth) * 100)
        end
    else
        gameState.targetExists = false
        gameState.targetName = ""
        gameState.targetHealthPercent = 100
    end
end

function frame:SendState()
    -- Build minimal data string
    -- Format: @LOKI@HP:85,PP:80,MP:100,IC:1,TE:1,THP:50
    local data = string.format(
        "@LOKI@HP:%d,PP:%d,MP:%d,IC:%d,TE:%d,TN:%s,THP:%d",
        gameState.healthPercent,
        gameState.power,
        gameState.maxPower,
        gameState.inCombat and 1 or 0,
        gameState.targetExists and 1 or 0,
        gameState.targetName,
        gameState.targetHealthPercent
    )

    -- Send to chat (whisper to self)
    SendChatMessage(data, "WHISPER", nil, gameState.playerName)
end

-- Slash command
SLASH_LOKI1 = "/loki"
SlashCmdList["LOKI"] = function(msg)
    msg = strlower(msg or "")
    if msg == "status" or msg == "" then
        print("=== LokiAssist Status ===")
        print("HP: " .. gameState.healthPercent .. "% (" .. gameState.health .. "/" .. gameState.maxHealth .. ")")
        print("Power: " .. gameState.power .. "/" .. gameState.maxPower)
        print("In Combat: " .. (gameState.inCombat and "Yes" or "No"))
        print("Target: " .. gameState.targetName .. " (" .. gameState.targetHealthPercent .. "%)")
    elseif msg == "test" then
        print("LokiAssist test - sending data")
        frame:SendState()
    end
end
