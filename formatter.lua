local ns = select(2, ...) ---@class MiniLootNS

local SimpleHexColors = ns.Utils.SimpleHexColors
local TableGroup = ns.Utils.TableGroup
local TableCombine = ns.Utils.TableCombine
local TableMap = ns.Utils.TableMap
local SumByKey = ns.Utils.SumByKey
local SumByKeyPretty = ns.Utils.SumByKeyPretty
local ConvertToMoneyString = ns.Utils.ConvertToMoneyString
local FormatNumber = ns.Utils.FormatNumber
local GetLootIcon = ns.Utils.GetLootIcon
local GetShortUnitName = ns.Utils.GetShortUnitName
local GetShortFactionName = ns.Utils.GetShortFactionName
local IsQuestItem = ns.Utils.IsQuestItem

local MiniLootMessageGroup = ns.Messages.MiniLootMessageGroup

---@enum MiniLootMessageFormats
local Formats = {
    S = "%s",
    SxD = "%sx%d",
    SxS = "%sx%s",
    ScS = "%s: %s",
    ScSxD = "%s: %sx%d",
    ScSS = "%s: %s %s",
}

---@alias MiniLootMessageFormatterOutputData string|number|string[]|number[]

---@enum MiniLootMessageFormatterOutputType
local MiniLootMessageFormatterOutputType = {
    PassThru = "PassThru",
    GroupOnPrefix = "GroupOnPrefix",
}

---@class MiniLootMessageFormatterOutput
---@field public Type MiniLootMessageFormatterOutputType
---@field public Prefix string
---@field public Format MiniLootMessageFormats
---@field public Data MiniLootMessageFormatterOutputData

---@alias MiniLootMessageFormatter fun(results: MiniLootMessageFormatSimpleParserResult[]): MiniLootMessageFormatterOutput|MiniLootMessageFormatterOutputData?

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

---@param link string
---@param isMawPower? boolean
local function GetLootIconFormatted(link, isMawPower)
    local customColor = IsQuestItem(link) and SimpleHexColors.Red or nil
    local isMawPowerUnit = isMawPower and "player" or nil
    return GetLootIcon(link, true, false, customColor, true, isMawPowerUnit)
end

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
        return format(Formats.SxS, link, FormatNumber(total))
    end
    return format(Formats.S, link)
end

---@param name string
---@param results MiniLootMessageFormatSimpleParserResult[]
local function SumReputationTotalsByKeyFormatted(name, results)
    local firstResult = results[1]
    if not firstResult then
        return
    end
    local total = SumByKeyPretty(results, "Value")
    return format(Formats.ScSS, YOU, name, total)
end

---@param key string
---@param lines string[]
local function GetLooterStringFormatted(key, lines)
    local name = key == "" and YOU or GetShortUnitName(key)
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

---@alias LootGroupHandler fun(key: MiniLootMessageFormatSimpleParserResultLootRollTypes, results: MiniLootMessageFormatSimpleParserResultLootRoll[]): string|string[]?

local LootHistoryText = format("[%s]", LOOT)

---@param id number
---@param text? string
local function GetLootHistoryLink(id, text)
    return format("|HlootHistory:%d|h%s|h", id, text or LootHistoryText)
end

---@type table<string, LootGroupHandler>
local LootGrouphandlers = {
    ---@param results MiniLootMessageFormatSimpleParserResultLootRoll_LootRollInfo[]
    LootRollInfo = function(key, results)
        local prefix = GetLootHistoryLink(results[1].Value)
        return TableMap(results, function(result)
            local link = GetLootIconFormatted(result.Link)
            return format("%s Everyone passed on %s", prefix, link)
        end)
    end,
    ---@param results MiniLootMessageFormatSimpleParserResultLootRoll_LootRollYouDecide[]
    LootRollYouDecide = function(key, results)
        local prefix = GetLootHistoryLink(results[1].Value)
        return TableMap(results, function(result)
            local action = result.Type == "YouPass" and "Pass" or result.Type == "YouDisenchant" and "Disenchant" or result.Type == "YouGreed" and "Greed" or result.Type == "YouNeed" and "Need" or "?"
            local link = GetLootIconFormatted(result.Link)
            return format("%s %s rolled %s on %s", prefix, YOU, action, link)
        end)
    end,
    ---@param results MiniLootMessageFormatSimpleParserResultLootRoll_LootRollDecide[]
    LootRollDecide = function(key, results)
        return TableMap(results, function(result)
            local name = GetShortUnitName(result.Name)
            local link = GetLootIconFormatted(result.Link)
            return format("%s rolled %s on %s", name, result.Type, link)
        end)
    end,
    ---@param results MiniLootMessageFormatSimpleParserResultLootRoll_LootRollRolled[]
    LootRollRolled = function(key, results)
        return TableMap(results, function(result)
            local name = GetShortUnitName(result.Name)
            local action = result.Type == "DisenchantRoll" and "Disenchant" or result.Type == "GreedRoll" and "Greed" or result.Type == "NeedRoll" and "Need" or "?"
            local link = GetLootIconFormatted(result.Link)
            return format("%s rolled %s (%d) on %s", name, action, result.Value, link)
        end)
    end,
    ---@param results MiniLootMessageFormatSimpleParserResultLootRoll_LootRollYouResult[]
    LootRollYouResult = function(key, results)
        local prefix = GetLootHistoryLink(results[1].Value)
        return TableMap(results, function(result)
            local link = GetLootIconFormatted(result.Link)
            return format("%s %s rolled %s (%d) on %s", prefix, YOU, key, result.ValueExtra, link)
        end)
    end,
    ---@param results MiniLootMessageFormatSimpleParserResultLootRoll_LootRollResult[]
    LootRollResult = function(key, results)
        local isWinner = key == "WinnerResult" or key == "YouWinnerResult"
        local prefix = not isWinner and GetLootHistoryLink(results[1].Value)
        return TableMap(results, function(result)
            local name = result.Name and GetShortUnitName(result.Name) or YOU
            local link = GetLootIconFormatted(result.Link)
            if isWinner then
                return format("%s won %s", name, link)
            end
            return format("%s %s rolled %s (%d) on %s", prefix, name, result.NameExtraString or "?", result.ValueExtra, link)
        end)
    end,
}

---@type table<MiniLootMessageFormatSimpleParserResultLootRollTypes, LootGroupHandler>
local LootGroupMap = {
    AllPass = LootGrouphandlers.LootRollInfo,
    YouPass = LootGrouphandlers.LootRollYouDecide,
    YouDisenchant = LootGrouphandlers.LootRollYouDecide,
    YouGreed = LootGrouphandlers.LootRollYouDecide,
    YouNeed = LootGrouphandlers.LootRollYouDecide,
    Pass = LootGrouphandlers.LootRollDecide,
    Disenchant = LootGrouphandlers.LootRollDecide,
    Greed = LootGrouphandlers.LootRollDecide,
    Need = LootGrouphandlers.LootRollDecide,
    DisenchantRoll = LootGrouphandlers.LootRollRolled,
    GreedRoll = LootGrouphandlers.LootRollRolled,
    NeedRoll = LootGrouphandlers.LootRollRolled,
    YouDisenchantResult = LootGrouphandlers.LootRollYouResult,
    YouGreedResult = LootGrouphandlers.LootRollYouResult,
    YouNeedResult = LootGrouphandlers.LootRollYouResult,
    DisenchantResult = LootGrouphandlers.LootRollResult,
    GreedResult = LootGrouphandlers.LootRollResult,
    NeedResult = LootGrouphandlers.LootRollResult,
    LostResult = LootGrouphandlers.LootRollResult,
    YouWinnerResult = LootGrouphandlers.LootRollResult,
    WinnerResult = LootGrouphandlers.LootRollResult,
}

---@type table<MiniLootMessageGroup, MiniLootMessageFormatter>
local Formatters = {}

---@param results MiniLootMessageFormatSimpleParserResultAnimaPower[]
Formatters[MiniLootMessageGroup.AnimaPower] = function(results)
    local links = TableMap(results, function(result) return GetLootIconFormatted(result.Link, true) end)
    local suffix = table.concat(links)
    return format(Formats.ScS, YOU, suffix)
end

---@param results MiniLootMessageFormatSimpleParserResultArtifactPower[]
Formatters[MiniLootMessageGroup.ArtifactPower] = function(results)
    local link = GetLootIconFormatted(results[1].Link)
    return format(Formats.ScS, link, SumByKeyPretty(results, "Value"))
end

---@param results MiniLootMessageFormatSimpleParserResultCurrency[]
Formatters[MiniLootMessageGroup.Currency] = function(results)
    return TableGroupFormat_NameLinkValue(results)
end

---@param results MiniLootMessageFormatSimpleParserResultExperience[]
Formatters[MiniLootMessageGroup.Experience] = function(results)
    return format(Formats.ScS, XP, SumByKeyPretty(results, "Value"))
end

---@param results MiniLootMessageFormatSimpleParserResultFollowerExperience[]
Formatters[MiniLootMessageGroup.FollowerExperience] = function(results)
    return TableGroupFormat_NameValue(results)
end

---@param results MiniLootMessageFormatSimpleParserResultHonor[]
Formatters[MiniLootMessageGroup.Honor] = function(results)
    return format(Formats.ScS, HONOR, SumByKeyPretty(results, "Value"))
end

---@param results MiniLootMessageFormatSimpleParserResultLoot[]
Formatters[MiniLootMessageGroup.Loot] = function(results)
    return TableGroupFormat_NameLinkValue(results)
end

---@param results MiniLootMessageFormatSimpleParserResultLootRoll[]
Formatters[MiniLootMessageGroup.LootRoll] = function(results)
    return TableGroupFormatOuter(
        results,
        "Type",
        ---@param groupKey MiniLootMessageFormatSimpleParserResultLootRollTypes
        ---@param groupResults MiniLootMessageFormatSimpleParserResultLootRoll[]
        function(groupKey, groupResults)
            local handler = LootGroupMap[groupKey]
            if handler then
                return handler(groupKey, groupResults)
            end
        end
    )
end

---@param results MiniLootMessageFormatSimpleParserResultMoney[]
Formatters[MiniLootMessageGroup.Money] = function(results)
    return TableGroupFormatOuter(
        results,
        "Name",
        ---@param groupResults MiniLootMessageFormatSimpleParserResultMoney[]
        function(groupKey, groupResults)
            local name = groupKey == "" and YOU or GetShortUnitName(groupKey)
            return SumResultsTotalsByKeyFormatted(name, groupResults, "Value")
        end
    )
end

---@param results MiniLootMessageFormatSimpleParserResultReputation[]
Formatters[MiniLootMessageGroup.Reputation] = function(results)
    TableGroupFormatOuter(
        results,
        "Name",
        ---@param groupResults MiniLootMessageFormatSimpleParserResultReputation[]
        function(groupKey, groupResults)
            local name = GetShortFactionName(groupKey)
            return SumReputationTotalsByKeyFormatted(name, groupResults)
        end
    )
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
    local output = formatter(results)
    if type(output) == "table" and output.Type then
        return output.Data
    end
    return output
end

---@class MiniLootNSFormatter
ns.Formatter = {
    Format = Format,
}
