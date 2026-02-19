-- LokiAssist.lua
-- Basic version - sends minimal data
-- Version 5.1

print("|cFF00FF00LokiAssist|r v5.1 loaded - type /loki status")

local f = CreateFrame("Frame")
local timer = 0
local ready = false

local function GetData()
    local hp = UnitHealth("player")
    local maxHp = UnitHealthMax("player")
    local hpPct = maxHp > 0 and math.floor(hp / maxHp * 100) or 100

    local pp = UnitPower("player")
    local maxPp = UnitPowerMax("player")

    local inCombat = InCombatLockdown() and 1 or 0

    local hasTarget = UnitExists("target") and 1 or 0
    local targetName = hasTarget == 1 and UnitName("target") or ""
    local targetHp = 100
    if hasTarget == 1 then
        local thp = UnitHealth("target")
        local maxThp = UnitHealthMax("target")
        targetHp = maxThp > 0 and math.floor(thp / maxThp * 100) or 100
    end

    return hpPct, pp, maxPp, inCombat, hasTarget, targetName, targetHp
end

f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    ready = true
end)

f:SetScript("OnUpdate", function(self, elapsed)
    if not ready then return end
    timer = timer + elapsed
    if timer > 0.5 then
        local hpPct, pp, maxPp, inCombat, hasTarget, targetName, targetHp = GetData()
        local msg = string.format("@LOKI@HP:%d,PP:%d,MP:%d,IC:%d,TE:%d,TN:%s,THP:%d",
            hpPct, pp, maxPp, inCombat, hasTarget, targetName, targetHp)
        SendChatMessage(msg, "WHISPER", nil, UnitName("player"))
        timer = 0
    end
end)

SLASH_LOKI1 = "/loki"
SlashCmdList["LOKI"] = function()
    local hpPct, pp, maxPp, inCombat, hasTarget, targetName, targetHp = GetData()
    print("HP: " .. hpPct .. "% | PP: " .. pp .. "/" .. maxPp)
    print("Combat: " .. inCombat)
    print("Target: " .. targetName .. " (" .. targetHp .. "%)")
end
