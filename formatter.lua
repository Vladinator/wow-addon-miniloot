local ns = select(2, ...) ---@class MiniLootNS

local db = ns.Settings.db
local SimpleHexColors = ns.Utils.SimpleHexColors
local TableGroup = ns.Utils.TableGroup
local TableCombine = ns.Utils.TableCombine
local TableMap = ns.Utils.TableMap
local SumByKey = ns.Utils.SumByKey
local SumByKeyPretty = ns.Utils.SumByKeyPretty
local FormatNumberGainLoss = ns.Utils.FormatNumberGainLoss
local ConvertToMoneyString = ns.Utils.ConvertToMoneyString
local FormatNumber = ns.Utils.FormatNumber
local GetLootIcon = ns.Utils.GetLootIcon
local GetItemCount = ns.Utils.GetItemCount
local GetCurrencyCount = ns.Utils.GetCurrencyCount
local GetShortUnitName = ns.Utils.GetShortUnitName
local GetShortFactionName = ns.Utils.GetShortFactionName
local IsQuestItem = ns.Utils.IsQuestItem

local MiniLootMessageGroup = ns.Messages.MiniLootMessageGroup

---@enum MiniLootMessageFormats
local Formats = {
    S = "%s",
    SxD = "%sx%d",
    SxS = "%sx%s",
    SxSCC = "%sx%s|cff%s(%s)|r",
    SCC = "%s|cff%s(%s)|r",
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

---@alias MiniLootMessageFormatter fun(results: MiniLootMessageFormatSimpleParserResults[]): MiniLootMessageFormatterOutput|MiniLootMessageFormatterOutputData?

---@generic T
---@param results MiniLootMessageFormatSimpleParserResults[]
---@param key string
---@param subKey string
---@param innerFunc fun(groupKey: string, groupResults: T[]): string|string[]?
---@param outerFunc fun(subKey: string, subResults: T[], lines: string[], groupResults: T[], groupKeys: string[]): string|string[]?
local function TableGroupFormatInnerOuter(results, key, subKey, innerFunc, outerFunc)
    local groups, groupKeys = TableGroup(results, key)
    local groupLines ---@type string[]?
    for i = 1, #groups do
        local subGroupLines ---@type string[]?
        local group = groups[i] ---@type MiniLootMessageFormatSimpleParserResults[]
        local groupKey = groupKeys[i] ---@type MiniLootMessageFormatSimpleParserResultKeys
        local subGroups, subGroupKeys = TableGroup(group, subKey)
        for j = 1, #subGroups do
            local subGroup = subGroups[j] ---@type MiniLootMessageFormatSimpleParserResults[]
            local subGroupKey = subGroupKeys[j] ---@type MiniLootMessageFormatSimpleParserResultKeys
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
---@param results MiniLootMessageFormatSimpleParserResults[]
---@param key string
---@param outerFunc fun(groupKey: string, groupResults: T[]): string|string[]?
local function TableGroupFormatOuter(results, key, outerFunc)
    local groups, keys = TableGroup(results, key)
    local lines ---@type string[]?
    for i = 1, #groups do
        local group = groups[i] ---@type MiniLootMessageFormatSimpleParserResultMoney[]
        local groupKey = keys[i] ---@type MiniLootMessageFormatSimpleParserResultKeys
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

---@param name? string
---@return string name, string unit The name will be set to `You` or player name with link support.
local function ConvertNameToUnitNameFormatted(name)
    if not name or name == "" then
        return YOU, "player"
    end
    local shortName = name
    if db.ShortenPlayerNames then
        shortName = GetShortUnitName(name)
    end
    return format("|Hplayer:%s|h%s|h", name, shortName), name
end

---@param name string
---@return string
local function ConvertNameToFactionNameFormatted(name)
    if db.ShortenFactionNames then
        return GetShortFactionName(name, db.ShortenFactionNamesLength)
    end
    return GetShortFactionName(name)
end

---@param link string
---@param mawPowerUnit? UnitToken
local function GetLootIconFormatted(link, mawPowerUnit)
    local customColor = IsQuestItem(link) and SimpleHexColors.Red or nil
    return GetLootIcon(link, true, false, customColor, mawPowerUnit)
end

---@param link string
---@param count? number
---@param canCountBags? boolean
---@param mawPowerUnit? UnitToken
local function GetLootIconCountFormatted(link, count, canCountBags, mawPowerUnit)
    local iconLink = GetLootIconFormatted(link, mawPowerUnit)
    count = count and count > 0 and count or 1
    if not canCountBags or not db.ItemCount then
        if count > 1 then
            return format(Formats.SxS, iconLink, FormatNumber(count))
        end
        return format(Formats.S, iconLink)
    end
    local bagCount = GetItemCount(link, db.ItemCountBank, db.ItemCountUses, db.ItemCountReagentBank)
    if bagCount == 0 and db.ItemCountCurrency then
        bagCount = GetCurrencyCount(link)
    end
    if count > 1 and bagCount > 1 and count ~= bagCount then
        return format(Formats.SxSCC, iconLink, FormatNumber(count), SimpleHexColors.DarkGray, FormatNumber(bagCount))
    elseif count > 1 then
        return format(Formats.SxS, iconLink, FormatNumber(count))
    elseif bagCount > 1 then
        return format(Formats.SCC, iconLink, SimpleHexColors.DarkGray, FormatNumber(bagCount))
    end
    return format(Formats.S, iconLink)
end

local FollowerMarkup = CreateTextureMarkup(1033590, 64, 64, 0, 0, 0, 1, 0, 1, 1, 0)

---@param prefix string
---@param results MiniLootMessageFormatSimpleParserResults[]
---@param key string
---@param skipIfValueZero? boolean
local function SumResultsTotalsByKeyFormatted(prefix, results, key, skipIfValueZero)
    local firstResult = results[1]
    if not firstResult then
        return
    end
    local total = SumByKey(results, key)
    if skipIfValueZero and total == 0 then
        return
    end
    local resultType = firstResult.Type
    if resultType == "Money" then
        local money = ConvertToMoneyString(total)
        return format(Formats.ScS, prefix, money)
    elseif resultType == "FollowerExperience" then
        local xp = FormatNumberGainLoss(total, total)
        return format("%s %s %s", FollowerMarkup, prefix, xp)
    end
    local canCountBags = not firstResult.Name or firstResult.Name == ""
    return GetLootIconCountFormatted(prefix, total, canCountBags)
end

local WarbandMarkup = "|A:warbands-icon:0:0|a"

---@param name string
---@param results MiniLootMessageFormatSimpleParserResults[]
local function SumReputationTotalsByKeyFormatted(name, results)
    local firstResult = results[1]
    if not firstResult then
        return
    end
    local isWarband = firstResult.Type == "ReputationWarband" or firstResult.Type == "ReputationLossWarband"
    if isWarband then
        name = format("%s%s", WarbandMarkup, name)
    end
    local total = SumByKeyPretty(results, "Value")
    return format(Formats.ScSS, YOU, name, total)
end

---@param key string
---@param lines string[]
local function GetLooterStringFormatted(key, lines)
    local name = ConvertNameToUnitNameFormatted(key)
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
---@param skipIfValueZero? boolean
local function TableGroupFormat_NameValue(results, skipIfValueZero)
    return TableGroupFormatOuter(
        results,
        "Name",
        ---@param groupResults MiniLootMessageFormatPseudoResult_NameValue[]
        function(groupKey, groupResults)
            return SumResultsTotalsByKeyFormatted(groupKey, groupResults, "Value", skipIfValueZero)
        end
    )
end

---@class MiniLootMessageFormatPseudoResult_NameLinkLink
---@field public Name? string
---@field public Link string
---@field public LinkExtra string

---@alias LootGroupHandler fun(key: MiniLootMessageFormatSimpleParserResultLootRollTypes, results: MiniLootMessageFormatSimpleParserResultLootRoll[]): string|string[]?

local LootHistoryText = format("[%s]", LOOT)

local RightArrowMarkup = "|A:perks-forwardarrow:8:8:2:0|a"
local DotSeparatorMarkup = "|A:perks-radio-dot:8:8:0:-2|a"
local RightArrowMarkupSpaced = format(" %s ", RightArrowMarkup)
local DotSeparatorMarkupSpaced = format(" %s ", DotSeparatorMarkup)

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
        _G.C = results print("C", key, results, prefix, "") -- DEBUG C
        return TableMap(results, function(result)
            local link = GetLootIconFormatted(result.Link)
            return format("%s Everyone passed on %s", prefix, link)
        end)
    end,
    ---@param results MiniLootMessageFormatSimpleParserResultLootRoll_LootRollYouDecide[]
    LootRollYouDecide = function(key, results)
        local prefix = GetLootHistoryLink(results[1].Value)
        _G.D = results print("D", key, results, prefix, "") -- DEBUG D
        return TableMap(results, function(result)
            local action = result.Type == "YouPass" and "Pass" or result.Type == "YouDisenchant" and "Disenchant" or result.Type == "YouGreed" and "Greed" or result.Type == "YouNeed" and "Need" or "?"
            local link = GetLootIconFormatted(result.Link)
            return format("%s %s rolled %s on %s", prefix, YOU, action, link)
        end)
    end,
    ---@param results MiniLootMessageFormatSimpleParserResultLootRoll_LootRollDecide[]
    LootRollDecide = function(key, results)
        _G.E = results print("E", key, results, "") -- DEBUG E
        return TableMap(results, function(result)
            local name = ConvertNameToUnitNameFormatted(result.Name)
            local link = GetLootIconFormatted(result.Link)
            return format("%s rolled %s on %s", name, result.Type, link)
        end)
    end,
    ---@param results MiniLootMessageFormatSimpleParserResultLootRoll_LootRollRolled[]
    LootRollRolled = function(key, results)
        _G.F = results print("F", key, results, "") -- DEBUG F
        return TableMap(results, function(result)
            local name = ConvertNameToUnitNameFormatted(result.Name)
            local action = result.Type == "DisenchantRoll" and "Disenchant" or result.Type == "GreedRoll" and "Greed" or result.Type == "NeedRoll" and "Need" or "?"
            local link = GetLootIconFormatted(result.Link)
            return format("%s rolled %s (%d) on %s", name, action, result.Value, link)
        end)
    end,
    ---@param results MiniLootMessageFormatSimpleParserResultLootRoll_LootRollYouResult[]
    LootRollYouResult = function(key, results)
        local prefix = GetLootHistoryLink(results[1].Value)
        _G.G = results print("G", key, results, prefix, "") -- DEBUG G
        return TableMap(results, function(result)
            local link = GetLootIconFormatted(result.Link)
            return format("%s %s rolled %s (%d) on %s", prefix, YOU, key, result.ValueExtra, link)
        end)
    end,
    ---@param results MiniLootMessageFormatSimpleParserResultLootRoll_LootRollResult[]
    LootRollResult = function(key, results)
        local isWinner = key == "WinnerResult" or key == "YouWinnerResult"
        local prefix = not isWinner and GetLootHistoryLink(results[1].Value)
        _G.H = results print("H", key, results, isWinner, prefix, "") -- DEBUG H
        return TableMap(results, function(result)
            local name = ConvertNameToUnitNameFormatted(result.Name)
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
    return TableGroupFormatOuter(
        results,
        "Name",
        ---@param groupResults MiniLootMessageFormatPseudoResult_NameLinkValue[]
        function(groupKey, groupResults)
            local name, unit = ConvertNameToUnitNameFormatted(groupKey)
            local links = TableMap(groupResults, function(result) return GetLootIconFormatted(result.Link, unit) end)
            local suffix = table.concat(links)
            return format(Formats.ScS, name, suffix)
        end
    )
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
    return TableGroupFormat_NameValue(results, true)
end

---@param results MiniLootMessageFormatSimpleParserResultHonor[]
Formatters[MiniLootMessageGroup.Honor] = function(results)
    return format(Formats.ScS, HONOR, SumByKeyPretty(results, "Value"))
end

---@param results MiniLootMessageFormatSimpleParserResultItemChanged[]
Formatters[MiniLootMessageGroup.ItemChanged] = function(results)
    return TableGroupFormatOuter(
        results,
        "Name",
        ---@param groupResults MiniLootMessageFormatPseudoResult_NameLinkLink[]
        function(groupKey, groupResults)
            local name = ConvertNameToUnitNameFormatted(groupKey)
            return TableMap(groupResults, function(result)
                local suffix = format("%s%s%s", GetLootIconFormatted(result.Link), RightArrowMarkupSpaced, GetLootIconFormatted(result.LinkExtra))
                return format(Formats.ScS, name, suffix)
            end)
        end
    )
end

---@param results MiniLootMessageFormatSimpleParserResultLoot[]
Formatters[MiniLootMessageGroup.Loot] = function(results)
    return TableGroupFormat_NameLinkValue(results)
end

---@param results MiniLootMessageFormatSimpleParserResultLootRoll[]
Formatters[MiniLootMessageGroup.LootRoll] = function(results)
    _G.A = results print("A", A, "") -- DEBUG A
    return TableGroupFormatOuter(
        results,
        "Type",
        ---@param groupKey MiniLootMessageFormatSimpleParserResultLootRollTypes
        ---@param groupResults MiniLootMessageFormatSimpleParserResultLootRoll[]
        function(groupKey, groupResults)
            local handler = LootGroupMap[groupKey]
            _G.B = results print("B", groupKey, handler, "") -- DEBUG B
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
            local name = ConvertNameToUnitNameFormatted(groupKey)
            return SumResultsTotalsByKeyFormatted(name, groupResults, "Value")
        end
    )
end

---@param results MiniLootMessageFormatSimpleParserResultReputation[]
Formatters[MiniLootMessageGroup.Reputation] = function(results)
    return TableGroupFormatOuter(
        results,
        "Name",
        ---@param groupResults MiniLootMessageFormatSimpleParserResultReputation[]
        function(groupKey, groupResults)
            local name = ConvertNameToFactionNameFormatted(groupKey)
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
---@param results MiniLootMessageFormatSimpleParserResults[]
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
