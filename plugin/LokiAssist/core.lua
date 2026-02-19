-- core.lua
-- Core utility functions

local addonName, addonTable = ...

-- Core table
local Core = {}

-- Utility functions
function Core:Print(msg, r, g, b)
    r = r or 1
    g = g or 1
    b = b or 1
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00" .. addonName .. "|r: " .. msg, r, g, b)
end

function Core:Debug(msg)
    if Core.debugMode then
        Core:Print("[DEBUG] " .. msg, 0.7, 0.7, 0.7)
    end
end

function Core:ToggleDebug()
    Core.debugMode = not Core.debugMode
    Core:Print("调试模式: " .. (Core.debugMode and "开启" or "关闭"))
end

-- Unit utility functions
function Core:GetUnitInfo(unit)
    if not unit then return nil end

    return {
        name = UnitName(unit),
        guid = UnitGUID(unit),
        level = UnitLevel(unit),
        health = UnitHealth(unit),
        maxHealth = UnitHealthMax(unit),
        healthPercent = (UnitHealth(unit) / UnitHealthMax(unit)) * 100,
        power = UnitPower(unit),
        maxPower = UnitPowerMax(unit),
        powerType = UnitPowerType(unit),
        class = select(2, UnitClass(unit)),
        reaction = UnitReaction("player", unit)
    }
end

function Core:GetSpellInfo(spellName)
    local spellId = GetSpellBookItemInfo(spellName, "spell")
    if not spellId then return nil end

    local start, duration = GetSpellCooldown(spellId)
    local ready = (start == 0)

    return {
        id = spellId,
        name = spellName,
        ready = ready,
        cooldown = duration or 0,
        remaining = (start and start > 0) and (duration - (GetTime() - start)) or 0
    }
end

function Core:HasBuff(unit, buffName)
    if not unit or not buffName then return false end

    for i = 1, 40 do
        local name = UnitBuff(unit, i)
        if name == buffName then
            return true
        end
    end
    return false
end

function Core:HasDebuff(unit, debuffName)
    if not unit or not debuffName then return false end

    for i = 1, 40 do
        local name = UnitDebuff(unit, i)
        if name == debuffName then
            return true
        end
    end
    return false
end

function Core:UnitInRange(unit)
    if not unit then return false end

    local inRange = CheckInteractDistance(unit, 4)
    return inRange
end

-- Combat utility
function Core:IsInCombat()
    return UnitAffectingCombat("player")
end

function Core:TargetExists()
    return UnitExists("target")
end

function Core:TargetIsEnemy()
    if not Core:TargetExists() then return false end
    return UnitIsEnemy("player", "target")
end

function Core:TargetIsFriend()
    if not Core:TargetExists() then return false end
    return UnitIsFriend("player", "target")
end

-- Boss detection
function Core:IsBoss(unit)
    if not unit then
        unit = "target"
    end
    return UnitLevel(unit) == -1 or UnitIsBoss(unit)
end

function Core:GetBossInfo()
    local bossInfo = {}

    for i = 1, 4 do
        local unit = "boss" .. i
        if UnitExists(unit) then
            table.insert(bossInfo, {
                name = UnitName(unit),
                health = UnitHealth(unit),
                maxHealth = UnitHealthMax(unit),
                healthPercent = (UnitHealth(unit) / UnitHealthMax(unit)) * 100,
                guid = UnitGUID(unit)
            })
        end
    end

    return bossInfo
end

-- Item utility
function Core:GetItemCooldown(itemId)
    local start, duration = GetItemCooldown(itemId)
    if not start then return -1, 0 end

    return {
        start = start,
        duration = duration,
        remaining = (start > 0) and (duration - (GetTime() - start)) or 0,
        ready = (start == 0 or (GetTime() - start) >= duration)
    }
end

function Core:FindItemInBags(itemName)
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local itemLink = GetContainerItemLink(bag, slot)
            if itemLink then
                local name = GetItemInfo(itemLink)
                if name and string.find(name, itemName) then
                    return bag, slot, itemLink
                end
            end
        end
    end
    return nil, nil, nil
end

-- Position utility
function Core:GetPlayerPosition()
    local x, y = GetPlayerMapPosition("player")
    return x * 100, y * 100
end

function Core:GetTargetPosition()
    local x, y = GetPlayerMapPosition("target")
    return x * 100, y * 100
end

function Core:GetDistance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

-- Table utility
function Core:CopyTable(original)
    local copy = {}
    for k, v in pairs(original) do
        if type(v) == "table" then
            copy[k] = self:CopyTable(v)
        else
            copy[k] = v
        end
    end
    return copy
end

function Core:MergeTable(destination, source)
    for k, v in pairs(source) do
        if type(v) == "table" then
            destination[k] = destination[k] or {}
            self:MergeTable(destination[k], v)
        else
            destination[k] = v
        end
    end
    return destination
end

-- Export
addonTable.Core = Core
