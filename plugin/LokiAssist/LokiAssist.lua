-- LokiAssist.lua
-- Version 5.2 - test print to chat
-- Uses DEFAULT_CHAT_FRAME to print directly

print("|cFF00FF00LokiAssist|r v5.2 loaded")

local f = CreateFrame("Frame")
local timer = 0

local function GetData()
    local hp = UnitHealth("player")
    local maxHp = UnitHealthMax("player")
    local hpPct = maxHp > 0 and floor(hp / maxHp * 100) or 100
    local pp = UnitPower("player")
    local maxPp = UnitPowerMax("player")
    local ic = InCombatLockdown() and 1 or 0
    return hpPct, pp, maxPp, ic
end

f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    print("LokiAssist: Ready! Timer started.")
end)

f:SetScript("OnUpdate", function(self, elapsed)
    timer = timer + elapsed
    if timer > 2 then
        local hp, pp, mp, ic = GetData()
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF00[LOKI]|r HP:" .. hp .. " PP:" .. pp .. " IC:" .. ic)
        timer = 0
    end
end)

SLASH_LOKI1 = "/loki"
SlashCmdList["LOKI"] = function()
    local hp, pp, mp, ic = GetData()
    print("HP: " .. hp .. "% | PP: " .. pp .. " | Combat: " .. ic)
end
