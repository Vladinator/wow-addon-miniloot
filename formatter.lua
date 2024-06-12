local ns = select(2, ...) ---@class MiniLootNS

local TableGroup = ns.Utils.TableGroup
local TableCombine = ns.Utils.TableCombine
local TableMap = ns.Utils.TableMap
local SumByKey = ns.Utils.SumByKey
local SumByKeyPretty = ns.Utils.SumByKeyPretty
local ConvertToMoneyString = ns.Utils.ConvertToMoneyString
local GetLootIcon = ns.Utils.GetLootIcon

local MiniLootMessageGroup = ns.Messages.MiniLootMessageGroup

---@alias MiniLootMessageFormatter fun(results: MiniLootMessageFormatSimpleParserResult[]): string|number|string[]|number[]?

---@generic T
---@param results MiniLootMessageFormatSimpleParserResult[]
---@param key string
---@param subKey string
---@param innerFunc fun(groupKey: string, groupResults: T[]): string|string[]?
---@param outerFunc fun(subKey: string, subResults: T[], lines: string[], groupResults: T[], groupKeys: string[]): string|string[]?
local function TableGroupFormatInnerOuter(results, key, subKey, innerFunc, outerFunc)
    local groups, groupKeys = TableGroup(results, key)
    local groupLines ---@type string[]?
    for i = 1, #groups do
        local subGroupLines ---@type string[]?
        local group = groups[i] ---@type MiniLootMessageFormatSimpleParserResult[]
        local groupKey = groupKeys[i]
        local subGroups, subGroupKeys = TableGroup(group, subKey)
        for j = 1, #subGroups do
            local subGroup = subGroups[j] ---@type MiniLootMessageFormatSimpleParserResult[]
            local subGroupKey = subGroupKeys[j]
            local subGroupData = innerFunc(subGroupKey, subGroup)
            if subGroupData then
                if not subGroupLines then
                    subGroupLines = {}
                end
                if type(subGroupData) == "table" then
                    TableCombine(subGroupLines, subGroupData)
                else
                    subGroupLines[#subGroupLines + 1] = subGroupData
                end
            end
        end
        if subGroupLines then
            local groupData = outerFunc(groupKey, group, subGroupLines, subGroups, subGroupKeys)
            if groupData then
                if not groupLines then
                    groupLines = {}
                end
                if type(groupData) == "table" then
                    TableCombine(groupLines, groupData)
                else
                    groupLines[#groupLines + 1] = groupData
                end
            end
        end
    end
    return groupLines
end

---@generic T
---@param results MiniLootMessageFormatSimpleParserResult[]
---@param key string
---@param outerFunc fun(groupKey: string, groupResults: T[]): string|string[]?
local function TableGroupFormatOuter(results, key, outerFunc)
    local groups, keys = TableGroup(results, key)
    local lines ---@type string[]?
    for i = 1, #groups do
        local group = groups[i] ---@type MiniLootMessageFormatSimpleParserResultMoney[]
        local groupKey = keys[i]
        local groupData = outerFunc(groupKey, group)
        if groupData then
            if not lines then
                lines = {}
            end
            if type(groupData) == "table" then
                TableCombine(lines, groupData)
            else
                lines[#lines + 1] = groupData
            end
        end
    end
    return lines
end

local Formats = {
    S = "%s",
    SxD = "%sx%d",
    ScS = "%s: %s",
    ScSxD = "%s: %sx%d",
}

---@param link string
local function GetLootIconFormatted(link)
    return GetLootIcon(link, true, false, nil, true, nil)
end

---@generic T
---@param prefix string
---@param results MiniLootMessageFormatSimpleParserResult[]
---@param key string
local function SumResultsTotalsByKeyFormatted(prefix, results, key)
    local firstResult = results[1]
    if not firstResult then
        return
    end
    local total = SumByKey(results, key)
    local resultType = firstResult.Type
    if resultType == "Money" then
        local money = ConvertToMoneyString(total)
        return format(Formats.ScS, prefix, money)
    end
    local link = GetLootIconFormatted(prefix)
    if total > 1 then
        return format(Formats.SxD, link, total)
    end
    return format(Formats.S, link)
end

---@param key string
---@param lines string[]
local function GetLooterStringFormatted(key, lines)
    local name = key == "" and YOU or key
    local line = table.concat(lines)
    return format(Formats.ScS, name, line)
end

---@class MiniLootMessageFormatPseudoResult_NameLinkValue
---@field public Type string
---@field public Name? string
---@field public Link string
---@field public Value? number

---@generic T
---@param results T[]
local function TableGroupFormat_NameLinkValue(results)
    return TableGroupFormatInnerOuter(
        results,
        "Name", "Link",
        ---@param groupResults MiniLootMessageFormatPseudoResult_NameLinkValue[]
        function(groupKey, groupResults)
            return SumResultsTotalsByKeyFormatted(groupKey, groupResults, "Value")
        end,
        ---@param subResults MiniLootMessageFormatPseudoResult_NameLinkValue[]
        ---@param groupResults MiniLootMessageFormatPseudoResult_NameLinkValue[]
        function(subKey, subResults, lines, groupResults, groupKeys)
            return GetLooterStringFormatted(subKey, lines)
        end
    )
end

---@class MiniLootMessageFormatPseudoResult_NameValue
---@field public Type string
---@field public Name string
---@field public Value? number

---@generic T
---@param results T[]
local function TableGroupFormat_NameValue(results)
    return TableGroupFormatOuter(
        results,
        "Name",
        ---@param groupResults MiniLootMessageFormatPseudoResult_NameValue[]
        function(groupKey, groupResults)
            return SumResultsTotalsByKeyFormatted(groupKey, groupResults, "Value")
        end
    )
end

---@type table<MiniLootMessageGroup, MiniLootMessageFormatter>
local Formatters = {}

---@param results MiniLootMessageFormatSimpleParserResultAnimaPower[]
Formatters[MiniLootMessageGroup.AnimaPower] = function(results)
    -- TODO
end

---@param results MiniLootMessageFormatSimpleParserResultArtifactPower[]
Formatters[MiniLootMessageGroup.ArtifactPower] = function(results)
    -- TODO
end

---@param results MiniLootMessageFormatSimpleParserResultCurrency[]
Formatters[MiniLootMessageGroup.Currency] = function(results)
    return TableGroupFormat_NameLinkValue(results)
end

---@param results MiniLootMessageFormatSimpleParserResultExperience[]
Formatters[MiniLootMessageGroup.Experience] = function(results)
    return format("%s: %s", XP, SumByKeyPretty(results, "Value"))
end

---@param results MiniLootMessageFormatSimpleParserResultFollowerExperience[]
Formatters[MiniLootMessageGroup.FollowerExperience] = function(results)
    return TableGroupFormat_NameValue(results)
end

---@param results MiniLootMessageFormatSimpleParserResultHonor[]
Formatters[MiniLootMessageGroup.Honor] = function(results)
    return format("%s: %s", HONOR, SumByKeyPretty(results, "Value"))
end

---@param results MiniLootMessageFormatSimpleParserResultLoot[]
Formatters[MiniLootMessageGroup.Loot] = function(results)
    return TableGroupFormat_NameLinkValue(results)
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
    return TableGroupFormat_NameValue(results)
end

---@param results MiniLootMessageFormatSimpleParserResultReputation[]
Formatters[MiniLootMessageGroup.Reputation] = function(results)
    return TableGroupFormat_NameValue(results)
end

---@param results MiniLootMessageFormatSimpleParserResultTransmogrification[]
Formatters[MiniLootMessageGroup.Transmogrification] = function(results)
    return TableGroupFormatOuter(
        results,
        "Type",
        ---@param groupKey MiniLootMessageFormatSimpleParserResultTransmogrificationTypes
        ---@param groupResults MiniLootMessageFormatSimpleParserResultTransmogrification[]
        function(groupKey, groupResults)
            local links = TableMap(
                groupResults,
                function(result)
                    return GetLootIconFormatted(result.Link)
                end
            )
            local suffix = table.concat(links)
            if groupKey == "Transmogrification" then
                return format(Formats.ScS, "Collected", suffix)
            end
            return format(Formats.ScS, "Lost", suffix)
        end
    )
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
