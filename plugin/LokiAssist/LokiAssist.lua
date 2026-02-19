-- LokiAssist.lua
-- Main addon file

local addonName, addonTable = ...

-- Load core
local core = addonTable

-- Create main frame
local LokiAssist = CreateFrame("Frame", "LokiAssist", UIParent)

-- Variables
local playerGUID = nil
local playerName = nil
local playerClass = nil
local stateFilePath = nil

-- Default state
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

-- Event handler
function LokiAssist:OnEvent(event, ...)
    local handler = self[event]
    if handler then
        handler(self, ...)
    end
end

LokiAssist:SetScript("OnEvent", LokiAssist.OnEvent)

-- Register events
LokiAssist:RegisterEvent("PLAYER_LOGIN")
LokiAssist:RegisterEvent("PLAYER_LOGOUT")
LokiAssist:RegisterEvent("UNIT_POWERMAX")
LokiAssist:RegisterEvent("UNIT_POWER")
LokiAssist:RegisterEvent("UNIT_HEALTH")
LokiAssist:RegisterEvent("UNIT_HEALTHMAX")
LokiAssist:RegisterEvent("PLAYER_TARGET_CHANGED")
LokiAssist:RegisterEvent("UNIT_AURA")
LokiAssist:RegisterEvent("SPELL_COOLDOWN")
LokiAssist:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
LokiAssist:RegisterEvent("PLAYER_REGEN_ENABLED")
LokiAssist:RegisterEvent("PLAYER_REGEN_DISABLED")
LokiAssist:RegisterEvent("BAG_UPDATE")
LokiAssist:RegisterEvent("UNIT_INVENTORY_CHANGED")

-- Player login
function LokiAssist:PLAYER_LOGIN()
    playerGUID = UnitGUID("player")
    playerName = UnitName("player")
    playerClass = select(2, UnitClass("player"))

    gameState.playerName = playerName
    gameState.playerClass = playerClass

    -- Set up state file path
    self:SetupStateFile()

    -- Create slash commands
    self:SetupSlashCommands()

    print("|cFF00FF00LokiAssist|r 已加载")
    print("使用 |cFFFFFF00/loki help|r 查看帮助")

    -- Start state update timer
    self:StartStateUpdate()
end

function LokiAssist:PLAYER_LOGOUT()
    self:SaveState()
end

-- State file setup
function LokiAssist:SetupStateFile()
    local appData = os.getenv("LOCALAPPDATA") or (os.getenv("APPDATA") .. "/Local")
    local addonDir = appData .. "/LokiAssist"

    -- Create directory if not exists
    if not io.open(addonDir, "r") then
        os.execute('mkdir "' .. addonDir .. '"')
    end

    stateFilePath = addonDir .. "/game_state.json"
end

-- Slash commands
function LokiAssist:SetupSlashCommands()
    SlashCmdList["LOKIASSIST"] = function(msg)
        self:HandleSlashCommand(msg)
    end
    SLASH_LOKIASSIST1 = "/loki"
    SLASH_LOKIASSIST2 = "/lokiasist"
end

function LokiAssist:HandleSlashCommand(msg)
    local cmd = strlower(msg)

    if cmd == "help" then
        print("|cFFFFFF00LokiAssist 命令:")
        print("  /loki status - 显示当前状态")
        print("  /loki combat - 切换战斗状态")
        print("  /loki test - 测试文件写入")
    elseif cmd == "status" then
        print("|cFF00FFFF当前状态:")
        print("  职业: " .. (gameState.playerClass or "未知"))
        print("  生命: " .. gameState.healthPercent .. "%")
        print("  能量: " .. gameState.power .. "/" .. gameState.maxPower)
        print("  战斗: " .. (gameState.inCombat and "是" or "否"))
    elseif cmd == "combat" then
        gameState.inCombat = not gameState.inCombat
        print("战斗状态: " .. (gameState.inCombat and "进入战斗" or "脱离战斗"))
    elseif cmd == "test" then
        self:SaveState()
        print("状态已保存到: " .. (stateFilePath or "nil"))
    end
end

-- State update timer
local stateUpdateFrame = nil

function LokiAssist:StartStateUpdate()
    stateUpdateFrame = CreateFrame("Frame")
    stateUpdateFrame:SetScript("OnUpdate", function(self, elapsed)
        self.timer = (self.timer or 0) + elapsed
        if self.timer >= 0.5 then  -- Update every 0.5 seconds
            LokiAssist:UpdateState()
            self.timer = 0
        end
    end)
end

-- Main state update
function LokiAssist:UpdateState()
    -- Update player info
    self:UpdatePlayerInfo()

    -- Update target info
    self:UpdateTargetInfo()

    -- Update buffs and debuffs
    self:UpdateBuffs()

    -- Update cooldowns
    self:UpdateCooldowns()

    -- Update position
    self:UpdatePosition()

    -- Save state
    self:SaveState()
end

function LokiAssist:UpdatePlayerInfo()
    -- Health
    local health = UnitHealth("player")
    local maxHealth = UnitHealthMax("player")
    gameState.healthPercent = math.floor((health / maxHealth) * 100)

    -- Power
    local power = UnitPower("player")
    local maxPower = UnitPowerMax("player")
    gameState.power = power
    gameState.maxPower = maxPower
end

function LokiAssist:UpdateTargetInfo()
    if UnitExists("target") then
        gameState.targetName = UnitName("target")

        local health = UnitHealth("target")
        local maxHealth = UnitHealthMax("target")
        gameState.targetHealthPercent = math.floor((health / maxHealth) * 100)
    else
        gameState.targetName = ""
        gameState.targetHealthPercent = 100
    end
end

function LokiAssist:UpdateBuffs()
    gameState.buffs = {}
    gameState.debuffs = {}

    -- Player buffs
    for i = 1, 40 do
        local name = UnitBuff("player", i)
        if name then
            gameState.buffs[name] = true
        end
    end

    -- Target debuffs
    if UnitExists("target") then
        for i = 1, 40 do
            local name = UnitDebuff("target", i)
            if name then
                gameState.debuffs[name] = true
            end
        end
    end
end

function LokiAssist:UpdateCooldowns()
    gameState.cooldowns = {}

    -- Check important spells
    local importantSpells = {
        -- Blood DK
        "枯萎凋零", "暗影打击", "传染", "心脏打击", "灵界打击", "符文打击",
        -- Hunter
        "狂野怒火", "杀戮命令", "奥术射击", "多重射击",
        -- Warrior
        "鲁莽", "致死打击", "巨人打击", "压制",
        -- Monk
        "轮回之触", "猛虎掌", "幻灭踢", "碎玉闪电",
        -- Shaman
        "元素冲击", "烈焰震击", "闪电箭", "风暴打击",
        -- Druid
        "狂暴", "斜掠", "割裂", "凶猛撕咬"
    }

    for _, spellName in ipairs(importantSpells) do
        local spellId = GetSpellBookItemInfo(spellName, "spell")
        if spellId then
            local start, duration = GetSpellCooldown(spellId)
            if start and start > 0 then
                local remaining = duration - (GetTime() - start)
                if remaining > 0 then
                    gameState.cooldowns[spellName] = remaining
                else
                    gameState.cooldowns[spellName] = 0
                end
            else
                gameState.cooldowns[spellName] = 0
            end
        end
    end
end

function LokiAssist:UpdatePosition()
    local x, y = GetPlayerMapPosition("player")
    gameState.position = {x = x * 100, y = y * 100}

    if UnitExists("target") then
        local tx, ty = GetPlayerMapPosition("target")
        gameState.targetPosition = {x = tx * 100, y = ty * 100}
    else
        gameState.targetPosition = {x = 0, y = 0}
    end
end

-- Combat events
function LokiAssist:PLAYER_REGEN_ENABLED()
    gameState.inCombat = false
end

function LokiAssist:PLAYER_REGEN_DISABLED()
    gameState.inCombat = true
end

-- Save state to file
function LokiAssist:SaveState()
    if not stateFilePath then
        return
    end

    -- Check trinket and potion
    self:CheckItems()

    -- Serialize to JSON (simple implementation)
    local json = self:TableToJSON(gameState)

    -- Write to file
    local file = io.open(stateFilePath, "w")
    if file then
        file:write(json)
        file:close()
    end
end

function LokiAssist:CheckItems()
    -- Check if trinket is ready (on cooldown = not ready)
    local trinket1Slot = 13
    local start1, duration1 = GetInventoryItemCooldown("player", trinket1Slot)
    gameState.trinketReady = (start1 == 0 or (start1 and (GetTime() - start1) >= duration1))

    -- Check for potion in bags
    gameState.potionReady = false
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local itemLink = GetContainerItemLink(bag, slot)
            if itemLink then
                local itemName = GetItemInfo(itemLink)
                if itemName and string.find(itemName, "药水") then
                    local start, duration = GetContainerItemCooldown(bag, slot)
                    if start == 0 or (GetTime() - start) >= duration then
                        gameState.potionReady = true
                    end
                    break
                end
            end
        end
    end
end

-- Simple JSON serialization
function LokiAssist:TableToJSON(t, indent)
    indent = indent or ""
    local result = "{\n"

    local keys = {}
    for k in pairs(t) do
        table.insert(keys, k)
    end
    table.sort(keys, function(a, b)
        if type(a) == "number" and type(b) == "number" then
            return a < b
        elseif type(a) == "string" and type(b) == "string" then
            return a < b
        else
            return tostring(a) < tostring(b)
        end
    end)

    for i, k in ipairs(keys) do
        local v = t[k]
        local comma = i < #keys and "," or ""

        if type(k) == "string" then
            result = result .. indent .. '  "' .. k .. '": '
        else
            result = result .. indent .. '  "' .. tostring(k) .. '": '
        end

        if type(v) == "string" then
            result = result .. '"' .. v .. '"' .. comma .. "\n"
        elseif type(v) == "number" then
            result = result .. tostring(v) .. comma .. "\n"
        elseif type(v) == "boolean" then
            result = result .. (v and "true" or "false") .. comma .. "\n"
        elseif type(v) == "table" then
            result = result .. self:TableToJSON(v, indent .. "  ") .. comma .. "\n"
        else
            result = result .. "null" .. comma .. "\n"
        end
    end

    result = result .. indent .. "}"
    return result
end

-- Print helper
local function print(msg)
    DEFAULT_CHAT_FRAME:AddMessage(msg)
end

-- Export for use in other files
_G.LokiAssist = LokiAssist
