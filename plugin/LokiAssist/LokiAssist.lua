-- LokiAssist.lua
-- Simple test addon

local frame = CreateFrame("Frame")

frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_LOGOUT")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        print("|cFF00FF00LokiAssist|r loaded! Version 1.0.3")
        print("Type |cFFFF00/loki test|r to test")
    end
end)

-- Slash command
SLASH_LOKI1 = "/loki"
SLASH_LOKI2 = "/lokiasist"

SlashCmdList["LOKI"] = function(msg)
    local cmd = strlower(msg or "")
    if cmd == "test" then
        print("LokiAssist: Test command works!")
    elseif cmd == "status" then
        local health = UnitHealth("player")
        local maxHealth = UnitHealthMax("player")
        local hp = math.floor((health / maxHealth) * 100)
        print("Player HP: " .. hp .. "%")
    else
        print("LokiAssist commands: /loki test, /loki status")
    end
end

print("LokiAssist.lua loaded")
