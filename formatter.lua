local ns = select(2, ...) ---@class MiniLootNS

local TableGroup = ns.Utils.TableGroup
local SumByKey = ns.Utils.SumByKey
local SumByKeyPretty = ns.Utils.SumByKeyPretty
local ConvertToMoneyString = ns.Utils.ConvertToMoneyString

local MiniLootMessageGroup = ns.Messages.MiniLootMessageGroup

---@alias MiniLootMessageFormatter fun(results: MiniLootMessageFormatSimpleParserResult[]): string|number|string[]|number[]?

---@type table<MiniLootMessageGroup, MiniLootMessageFormatter>
local Formatters = {}

---@param results MiniLootMessageFormatSimpleParserResultAnimaPower[]
Formatters[MiniLootMessageGroup.AnimaPower] = function(results)
end

---@param results MiniLootMessageFormatSimpleParserResultArtifactPower[]
Formatters[MiniLootMessageGroup.ArtifactPower] = function(results)
end

---@param results MiniLootMessageFormatSimpleParserResultCurrency[]
Formatters[MiniLootMessageGroup.Currency] = function(results)
    local groups, keys = TableGroup(results, "Link")
    local lines ---@type string[]?
    for i = 1, #groups do
        if not lines then
            lines = {}
        end
        local group = groups[i] ---@type MiniLootMessageFormatSimpleParserResultCurrency[]
        local key = keys[i]
        local total = SumByKey(group, "Value")
        if total > 1 then
            lines[#lines + 1] = format("%s: %sx%d", YOU, key, total)
        else
            lines[#lines + 1] = format("%s: %s", YOU, key)
        end
    end
    return lines
end

---@param results MiniLootMessageFormatSimpleParserResultExperience[]
Formatters[MiniLootMessageGroup.Experience] = function(results)
    return format("%s: %s", XP, SumByKeyPretty(results, "Value"))
end

---@param results MiniLootMessageFormatSimpleParserResultFollowerExperience[]
Formatters[MiniLootMessageGroup.FollowerExperience] = function(results)
    local groups, keys = TableGroup(results, "Name")
    local lines ---@type string[]?
    for i = 1, #groups do
        if not lines then
            lines = {}
        end
        local group = groups[i] ---@type MiniLootMessageFormatSimpleParserResultFollowerExperience[]
        local key = keys[i]
        local line = SumByKeyPretty(group, "Value")
        lines[#lines + 1] = format("%s: %s", key, line)
    end
    return lines
end

---@param results MiniLootMessageFormatSimpleParserResultHonor[]
Formatters[MiniLootMessageGroup.Honor] = function(results)
    return format("%s: %s", HONOR, SumByKeyPretty(results, "Value"))
end

---@param results MiniLootMessageFormatSimpleParserResultLoot[]
Formatters[MiniLootMessageGroup.Loot] = function(results)
    local groups, keys = TableGroup(results, "Name")
    local lines ---@type string[]?
    for i = 1, #groups do
        local playerLines ---@type string[]?
        local group = groups[i] ---@type MiniLootMessageFormatSimpleParserResultLoot[]
        local key = keys[i]
        local itemGroups, itemKeys = TableGroup(group, "Link")
        for j = 1, #itemGroups do
            if not playerLines then
                playerLines = {}
            end
            local itemGroup = itemGroups[j] ---@type MiniLootMessageFormatSimpleParserResultLoot[]
            local itemKey = itemKeys[j]
            local total = SumByKey(itemGroup, "Value")
            if total > 1 then
                playerLines[#playerLines + 1] = format("%sx%d", itemKey, total)
            else
                playerLines[#playerLines + 1] = itemKey
            end
        end
        if playerLines then
            if not lines then
                lines = {}
            end
            lines[#lines + 1] = format("%s: %s", key == "" and YOU or key, table.concat(playerLines))
        end
    end
    return lines
end

---@param results MiniLootMessageFormatSimpleParserResultLootRoll[]
Formatters[MiniLootMessageGroup.LootRollDecision] = function(results)
end

-- ---@param results MiniLootMessageFormatSimpleParserResultLootRoll[]
-- Formatters[MiniLootMessageGroup.LootRollResult] = function(results)
-- end

-- ---@param results MiniLootMessageFormatSimpleParserResultLootRoll[]
-- Formatters[MiniLootMessageGroup.LootRollRolled] = function(results)
-- end

---@param results MiniLootMessageFormatSimpleParserResultMoney[]
Formatters[MiniLootMessageGroup.Money] = function(results)
    local groups, keys = TableGroup(results, "Name")
    local lines ---@type string[]?
    for i = 1, #groups do
        if not lines then
            lines = {}
        end
        local group = groups[i] ---@type MiniLootMessageFormatSimpleParserResultMoney[]
        local key = keys[i]
        local total = SumByKey(group, "Value")
        local money = ConvertToMoneyString(total)
        lines[#lines + 1] = format("%s: %s", key == "" and YOU or key, money)
    end
    return lines
end

---@param results MiniLootMessageFormatSimpleParserResultReputation[]
Formatters[MiniLootMessageGroup.Reputation] = function(results)
    local groups, keys = TableGroup(results, "Name")
    local lines ---@type string[]?
    for i = 1, #groups do
        if not lines then
            lines = {}
        end
        local group = groups[i] ---@type MiniLootMessageFormatSimpleParserResultReputation[]
        local key = keys[i]
        local line = SumByKeyPretty(group, "Value")
        lines[#lines + 1] = format("%s: %s", key, line)
    end
    return lines
end

---@param results MiniLootMessageFormatSimpleParserResultTransmogrification[]
Formatters[MiniLootMessageGroup.Transmogrification] = function(results)
    local groups, keys = TableGroup(results, "Type")
    local lines ---@type string[]?
    for i = 1, #groups do
        if not lines then
            lines = {}
        end
        local group = groups[i] ---@type MiniLootMessageFormatSimpleParserResultTransmogrification[]
        local key = keys[i] ---@type MiniLootMessageFormatSimpleParserResultTransmogrificationTypes
        for _, result in ipairs(group) do
            lines[#lines + 1] = format("%s: %s", key == "Transmogrification" and "Added" or "Removed", result.Link)
        end
    end
    return lines
end

---@param group MiniLootMessageGroup
---@param results MiniLootMessageFormatSimpleParserResult[]
local function Format(group, results)
    local formatter = Formatters[group]
    if not formatter then
        return
    end
    return formatter(results)
end

---@class MiniLootNSFormatter
ns.Formatter = {
    Format = Format,
}
