-- LokiAssist.lua
-- Robust version - handles both outdoor and instanced content
-- Version 3.1

local frame = CreateFrame("Frame")
local updateTimer = 0
local loaded = false

-- Detect if we're in an instance
local function IsInInstance()
    local inInstance, instanceType = IsInInstance()
    return inInstance, instanceType  -- instanceType: "party", "raid", "pvp", "arena", nil
end

-- Game state
local gameState = {
    playerName = "",
    playerClass = "",
    instanceType = "",  -- outdoor/party/raid/pvp
    healthPercent = 100,
    health = 0,
    maxHealth = 0,
    power = 0,
    maxPower = 0,
    powerType = 0,  -- 0=mana, 1=rage, 2=focus, 3=energy, 4=runic
    inCombat = false,
    targetName = "",
    targetExists = false,
    targetHealthPercent = 100,
    targetLevel = 0,
    inInstance = false,
    zoneName = "",
    uiRestricted = false  -- API restriction level
}

-- Try different methods to get data
local function TryGetUnitInfo()
    local data = {}

    -- Method 1: Basic player info (always works)
    data.health = UnitHealth("player") or 0
    data.maxHealth = UnitHealthMax("player") or 1
    if data.maxHealth > 0 then
        data.healthPercent = math.floor((data.health / data.maxHealth) * 100)
    else
        data.healthPercent = 100
    end

    -- Method 2: Power (always works)
    data.power = UnitPower("player") or 0
    data.maxPower = UnitPowerMax("player") or 0
    data.powerType = UnitPowerType("player") or 0

    -- Method 3: Combat status
    data.inCombat = InCombatLockdown() or false

    -- Method 4: Target info
    data.targetExists = UnitExists("target") or false
    if data.targetExists then
        pcall(function()
            data.targetName = UnitName("target") or ""
            local thp = UnitHealth("target") or 0
            local maxThp = UnitHealthMax("target") or 1
            if maxThp > 0 then
                data.targetHealthPercent = math.floor((thp / maxThp) * 100)
            end
            data.targetLevel = UnitLevel("target") or 0
        end)
    else
        data.targetName = ""
        data.targetHealthPercent = 100
        data.targetLevel = 0
    end

    -- Method 5: Instance info
    local inInstance, instanceType = IsInInstance()
    data.inInstance = inInstance or false
    data.instanceType = instanceType or "outdoor"

    -- Method 6: Zone (might be restricted in instance)
    pcall(function()
        data.zoneName = GetZoneText() or ""
    end)

    -- Method 7: Map position (restricted in instances)
    pcall(function()
        local x, y = GetPlayerMapPosition("player")
        data.posX = x or 0
        data.posY = y or 0
    end)

    return data
end

-- Register events
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("UNIT_POWER")
frame:RegisterEvent("UNIT_HEALTH")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        gameState.playerName = UnitName("player") or ""
        gameState.playerClass = select(2, UnitClass("player")) or ""

        local inInstance, instanceType = IsInInstance()
        gameState.inInstance = inInstance
        gameState.instanceType = instanceType or "outdoor"

        loaded = true

        print("|cFF00FF00LokiAssist|r v3.1 loaded")
        print("Instance: " .. (inInstance and instanceType or "outdoor"))

    elseif event == "PLAYER_REGEN_DISABLED" then
        gameState.inCombat = true

    elseif event == "PLAYER_REGEN_ENABLED" then
        gameState.inCombat = false

    elseif event == "ZONE_CHANGED_NEW_AREA" then
        local inInstance, instanceType = IsInInstance()
        gameState.inInstance = inInstance
        gameState.instanceType = instanceType or "outdoor"
        pcall(function()
            gameState.zoneName = GetZoneText() or ""
        end)
    end
end)

-- Update loop - more frequent for outdoor, less for instance
frame:SetScript("OnUpdate", function(self, elapsed)
    if not loaded then return end

    updateTimer = updateTimer + elapsed

    -- Different update rates for instance vs outdoor
    local updateInterval = gameState.inInstance and 0.2 or 0.1

    if updateTimer >= updateInterval then
        local data = TryGetUnitInfo()

        -- Update global state
        gameState.health = data.health
        gameState.maxHealth = data.maxHealth
        gameState.healthPercent = data.healthPercent
        gameState.power = data.power
        gameState.maxPower = data.maxPower
        gameState.powerType = data.powerType
        gameState.inCombat = data.inCombat
        gameState.targetExists = data.targetExists
        gameState.targetName = data.targetName
        gameState.targetHealthPercent = data.targetHealthPercent
        gameState.targetLevel = data.targetLevel

        -- Send to Python
        self:SendState(data)

        updateTimer = 0
    end
end)

function frame:SendState(data)
    -- Build compact data string
    -- Format: @LOKI@P:name,C:class,I:0/1,T:type,HP:85,PP:80,MP:100,PT:0,IC:0/1,TE:0/1,TN:xxx,THP:50,TL:72,Z:zone
    local msg = string.format(
        "@LOKI@P:%s,C:%s,I:%d,T:%s,HP:%d,PP:%d,MP:%d,PT:%d,IC:%d,TE:%d,TN:%s,THP:%d,TL:%d",
        gameState.playerName,
        gameState.playerClass,
        gameState.inInstance and 1 or 0,
        gameState.instanceType,
        data.healthPercent,
        data.power,
        data.maxPower,
        data.powerType,
        data.inCombat and 1 or 0,
        data.targetExists and 1 or 0,
        data.targetName,
        data.targetHealthPercent,
        data.targetLevel
    )

    -- Add zone if available
    if data.zoneName and data.zoneName ~= "" then
        msg = msg .. ",Z:" .. data.zoneName
    end

    -- Send whisper to self
    SendChatMessage(msg, "WHISPER", nil, gameState.playerName)
end

-- Slash commands
SLASH_LOKI1 = "/loki"
SLASH_LOKI2 = "/lokiassist"

SlashCmdList["LOKI"] = function(msg)
    msg = strlower(msg or "")
    if msg == "status" or msg == "" then
        print("=== LokiAssist Status ===")
        print("Zone: " .. (gameState.inInstance and gameState.instanceType or "outdoor"))
        print("HP: " .. gameState.healthPercent .. "% (" .. gameState.health .. "/" .. gameState.maxHealth .. ")")
        print("Power: " .. gameState.power .. "/" .. gameState.maxPower .. " (type:" .. gameState.powerType .. ")")
        print("In Combat: " .. (gameState.inCombat and "|cFF00FF00Yes|r" or "|cFFFFFF00No|r"))
        print("Target: " .. (gameState.targetExists and gameState.targetName or "|c88888888None|r") .. " (" .. gameState.targetHealthPercent .. "%)")
    elseif msg == "test" then
        print("Testing data send...")
        frame:SendState(TryGetUnitInfo())
    elseif msg == "instance" then
        local inInstance, instanceType = IsInInstance()
        print("In Instance: " .. (inInstance and "Yes" or "No"))
        print("Instance Type: " .. (instanceType or "N/A"))
    end
end
