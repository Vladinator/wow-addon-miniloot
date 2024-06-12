local ns = select(2, ...) ---@class MiniLootNS

---@generic T
---@param tbl T[]
---@param shallow? boolean
---@return T[]
local function TableCopy(tbl, shallow)
	local temp = {}
	for k, v in pairs(tbl) do
		if type(v) == "table" and not shallow then
			temp[k] = TableCopy(v)
		else
			temp[k] = v
		end
	end
	return temp
end

---@generic T
---@param tbl T[]
---@param item T
local function TableContains(tbl, item)
	for _, v in pairs(tbl) do
		if v == item then
			return true
		end
	end
	return false
end

---@generic T
---@param ... T[]
local function TableCombine(...)
    local tbls = {...}
    local first = tbls[1]
    local index = #first
    for i = 2, #tbls do
        local tbl = tbls[i]
        for _, v in ipairs(tbl) do
            if not TableContains(first, v) then
                index = index + 1
                first[index] = v
            end
        end
    end
    return first
end

---@generic T
---@param dst T[]
---@param src T[]
local function TableMerge(dst, src)
    for srck, srcv in pairs(src) do
        local srcvt = type(srcv)
        local srcva = srcvt == "table" and #srcv > 0
        local dstv = dst[srck]
        local dstvt = type(dstv)
        local dstva = dstvt == "table" and #dstv > 0
        if srcva and dstva then
            dst[srck] = TableCombine({}, dstv, srcv)
        elseif srcvt == "table" and dstvt == "table" then
            dst[srck] = TableMerge(TableMerge({}, dstv), srcv)
        else
            dst[srck] = srcv
        end
    end
    return dst
end

---@generic T
---@param tbl T[]
---@return T[]
local function TableReverse(tbl)
    local temp = {}
    local index = 0
    for i = #tbl, 1, -1 do
        index = index + 1
        temp[index] = tbl[i]
    end
    return temp
end

---@generic T
---@param tbl T[]
---@return boolean isArray
local function TableIsArray(tbl)
    local k = next(tbl)
    return type(k) == "number" and #tbl > 0
end

---@generic T
---@param tbl T[]
local function TableIter(tbl)
    return TableIsArray(tbl) and ipairs or pairs
end

---@generic T
---@param tbl T[]
---@param anyKeyType? boolean
local function TableKeys(tbl, anyKeyType)
    local keys = {} ---@type any[]
    local index = 0
    local iter = TableIter(tbl)
    for key, _ in iter(tbl) do
        if anyKeyType or type(key) == "string" then
            index = index + 1
            keys[index] = key
        end
    end
    return keys
end

---@generic T
---@param tbl T[]
---@param onlyUnique? boolean
local function TableValues(tbl, onlyUnique)
    local values = {} ---@type any[]
    local index = 0
    local iter = TableIter(tbl)
    for _, value in iter(tbl) do
        if type(value) ~= "userdata" then
            if not onlyUnique or not TableContains(values, value) then
                index = index + 1
                values[index] = value
            end
        end
    end
    return values
end

---@generic T, R
---@param tbl T[]
---@param func fun(v: T, k: number, tbl: T[]): R
---@return R[]
local function TableMap(tbl, func)
    local temp = {}
    local index = 0
    for k, v in ipairs(tbl) do
        index = index + 1
        temp[index] = func(v, k, tbl)
    end
    return temp
end

---@generic T, R
---@param tbl T[]
---@param func fun(acc: R, val: T): R
---@param init R
---@return R
local function TableReduce(tbl, func, init)
    local temp = init
    for _, v in ipairs(tbl) do
        temp = func(temp, v)
    end
    return temp
end

---@generic T
---@param tbl table<any, any>
local function TableSwap(tbl)
    local keys = TableKeys(tbl)
    local values = TableValues(tbl)
    local temp = {}
    for i = 1, #keys do
        local k = keys[i]
        local v = values[i]
        temp[v] = k
    end
    return temp
end

---@generic T
---@param tbl T[]
---@param key string|fun(item: T): string
---@param keyIfNil? string
---@return table<number, T[]> groups, table<number, string> keys
local function TableGroup(tbl, key, keyIfNil)
    local keyMap = {} ---@type table<any, number?>
    local groups = {} ---@type table<number, any[]>
    local iter = TableIter(tbl)
    for _, item in iter(tbl) do
        local groupKey = item[key]
        if type(key) == "function" then
            groupKey = key(item)
        end
        if groupKey == nil then
            if keyIfNil ~= nil then
                groupKey = keyIfNil
            else
                groupKey = ""
            end
        end
        local index = keyMap[groupKey]
        if not index then
            index = #groups + 1
            keyMap[groupKey] = index
            groups[index] = {}
        end
        local group = groups[index]
        group[#group + 1] = item
    end
    local keys = TableSwap(keyMap)
    return groups, keys
end

---@param pattern string
---@return string format
local function PatternToFormat(pattern)
    -- grammar from hell ( http://wow.gamepedia.com/UI_escape_sequences#Grammar )
    -- pattern = pattern
    --     :gsub("|4[^:]-:[^:]-:[^;]-;", "") -- "|4singular:plural1:plural2;"
    --     :gsub("|4[^:]-:[^;]-;", "") -- "number |4singular:plural;"
    --     :gsub("|1[^;]-;[^;]-;", "") -- "number |1singular;plural;"
    --     :gsub("|3-%d+%([^%)]-%)", "") -- "|3-formid(text)"
    --     :gsub("|2%S-?", "") -- "|2text"
    -- argument ordering
    for i = 1, 20 do
        pattern = pattern
            :gsub("%%" .. i .. "$s", "%%s")
            :gsub("%%" .. i .. "$d", "%%d")
            :gsub("%%" .. i .. "$f", "%%f")
    end
    -- standard tokens
    pattern = pattern
        :gsub("%%", "%%%%")
        :gsub("%.", "%%%.")
        :gsub("%?", "%%%?")
        :gsub("%+", "%%%+")
        :gsub("%-", "%%%-")
        :gsub("%(", "%%%(")
        :gsub("%)", "%%%)")
        :gsub("%[", "%%%[")
        :gsub("%]", "%%%]")
        :gsub("%%%%s", "(.-)")
        :gsub("%%%%d", "(%%d+)")
        :gsub("%%%%%%[%d%.%,]+f", "([%%d%%.%%,]+)")
    return pattern
end

local ConvertToNumberPattern1 = format("[\\%s]+", LARGE_NUMBER_SEPERATOR)
local ConvertToNumberPattern2 = format("[\\%s]", DECIMAL_SEPERATOR)

---@param value? string|number
---@return number?
local function ConvertToNumber(value)
    local type = type(value)
    if type == "number" then
        return value
    end
    if type ~= "string" then
        return
    end
    value = value
        :gsub(ConvertToNumberPattern1, "")
        :gsub(ConvertToNumberPattern2, ".")
        :gsub("[^%d%.]+", "")
    return tonumber(value)
end

local ConvertToMoneyPatterns = {
    Gold = PatternToFormat(GOLD_AMOUNT),
    Silver = PatternToFormat(SILVER_AMOUNT),
    Copper = PatternToFormat(COPPER_AMOUNT),
}

---@param value? string|number
---@return number?
local function ConvertToMoney(value)
    local type = type(value)
    if type == "number" then
        return value
    end
    if type ~= "string" then
        return
    end
    local goldText = value:match(ConvertToMoneyPatterns.Gold)
    local silverText = value:match(ConvertToMoneyPatterns.Silver)
    local copperText = value:match(ConvertToMoneyPatterns.Copper)
    local money ---@type number?
    if goldText then
        money = (money or 0) + (tonumber(goldText) or 0)*COPPER_PER_GOLD
    end
    if silverText then
        money = (money or 0) + (tonumber(silverText) or 0)*COPPER_PER_SILVER
    end
    if copperText then
        money = (money or 0) + (tonumber(copperText) or 0)
    end
    return money
end

---@param money number
local function ConvertToMoneyString(money)
    return GetMoneyString(money) -- C_CurrencyInfo.GetCoinTextureString
end

---@param val1 any
---@param val2 any
---@return boolean equal
local function ValuesAreSameish(val1, val2)
    if val1 == val2 then
        return true
    end
    local type1 = type(val1)
    local type2 = type(val2)
    if type1 == "string" and type2 == "number" then
        return tonumber(val1) == val2
    end
    if type1 == "number" and type2 == "string" then
        return val1 == tonumber(val2)
    end
    if type1 == "boolean" or type2 == "boolean" then
        return (not not val1) == (not not val2)
    end
    return true
end

---@param number number
---@return string
local function FormatNumber(number)
    return FormatLargeNumber(number)
end

---@class MiniLootSimpleHexColors
local SimpleHexColors = {
    FactionPurple = "9696FF",
    SystemYellow = "FFFF00",
    Yellow = "FFFF33",
    Red = "FF3333",
    Green = "33FF33",
    Blue = "3333FF",
    White = "FFFFFF",
    Gray = "CCCCCC",
}

---@param text string|number
---@param delta number
---@return string
local function ColorByDelta(text, delta)
    local color = delta < 0 and SimpleHexColors.Red or delta > 0 and SimpleHexColors.Green or SimpleHexColors.White
    return format("|cff%s%s|r", color, text)
end

---@param results MiniLootMessageFormatSimpleParserResult[]
---@param key string
---@return number total
local function SumByKey(results, key)
    return TableReduce(
        results,
        ---@param acc number
        function(acc, val)
            local v = val[key]
            if type(v) == "number" then
                return acc + v
            end
            return acc
        end,
        0
    )
end

---@param results MiniLootMessageFormatSimpleParserResult[]
---@param key string
---@param skipColor? boolean
---@return string prettyTotal, number total
local function SumByKeyPretty(results, key, skipColor)
    local total = SumByKey(results, key)
    local text = FormatNumber(total)
    text = format("%s%s", total < 0 and "-" or "", text)
    if not skipColor then
        text = ColorByDelta(text, total)
    end
    return text, total
end

---@param unit UnitToken
---@return string? name, string realm, boolean sameRealm
local function GetUnitName(unit)
    local name, realm ---@type string?, string?
    if UnitExists(unit) then
        name, realm = UnitFullName(unit)
    else
        name, realm = strsplit("-", unit, 2)
    end
    if not name or name == "" then
        return ---@diagnostic disable-line: missing-return-value
    end
    if not realm or realm == "" then
        realm = GetNormalizedRealmName()
    end
    local sameRealm = realm == GetNormalizedRealmName()
    return name, realm, sameRealm
end

---@param fullName string
local function GetShortUnitName(fullName)
    return Ambiguate(fullName, "short")
end

local UnicodeLetterPattern = "([%z\1-\127\194-\244][\128-\191]*)"
local UnicodeFirstLetterPattern = format("%s(.+)", UnicodeLetterPattern)

---@param text string
---@param length number
---@return string? leftString
local function GetLeftString(text, length)
    local patternParts = {} ---@type string[]
    for i = 1, length do
        patternParts[i] = UnicodeLetterPattern
    end
    local pattern = table.concat(patternParts)
    local matches = table.concat({text:match(pattern)})
    if matches ~= "" then
        return matches
    end
    if length > 1 then
        return GetLeftString(text, length - 1)
    end
end

---@param firstLetter string
---@param remainingLetters string
local function UpperCaseWord(firstLetter, remainingLetters)
    return format("%s%s", firstLetter:upper(), remainingLetters:lower())
end

---@param text string
local function UpperCaseWords(text)
    text = text:gsub(UnicodeFirstLetterPattern, UpperCaseWord)
    return text
end

---@param text string
---@param length number
local function AbbreviateString(text, length)
    local parts = {strsplit(" ", text)}
    if not parts[2] then
        return GetLeftString(text, length)
    end
    local words = {} ---@type string[]
    for i = 1, #parts do
        local part = parts[i]
        local leftPart = GetLeftString(part, 3)
        words[i] = leftPart and UpperCaseWords(leftPart) or ""
    end
    text = table.concat(words)
    local _, replaced = text:gsub("[^\128-\193]", "")
    replaced = replaced or text:len()
    if length < replaced then
        words = {}
        for i = 1, #parts do
            local part = parts[i]
            local leftPart = GetLeftString(part, 2)
            words[i] = leftPart and UpperCaseWords(leftPart) or ""
        end
        text = table.concat(words)
    end
    return text
end

---@param name string
---@param maxLength? number
local function GetShortFactionName(name, maxLength)
    if maxLength then
        name = AbbreviateString(name, maxLength)
    end
    return format("|cff%s%s|r", SimpleHexColors.FactionPurple, name)
end

local LinkMarkupPattern = "|c([0-9a-fA-F]+)|H(.-)|h%[(.-)%]|h|r"
local AtlasMarkupPattern = "(|A:(.-[Tt][Ii][Ee][Rr](%d+)):(.-)|a)"

---@param unit UnitToken
---@param query number|string
---@param fallback? boolean
---@return number? spellTexture, number spellID, string spellLink
local function GetUnitMawPowerInfo(unit, query, fallback)
    if not unit or not query then
        if fallback then
            return 538040 ---@diagnostic disable-line: missing-return-value
        end
        return ---@diagnostic disable-line: missing-return-value
    end
    for i = 1, 100 do
        local aura = C_UnitAuras.GetAuraDataByIndex(unit, i, "MAW")
        if not aura then
            break
        end
        local spellTexture = aura.icon
        local spellID = aura.spellId
        local spellLink = C_Spell.GetMawPowerLinkBySpellID(spellID)
        if query == spellID or query == spellLink then
            return spellTexture, spellID, spellLink
        end
        local _, spellName = spellLink:match(LinkMarkupPattern)
        if query == spellName then
            return spellTexture, spellID, spellLink
        end
    end
    return ---@diagnostic disable-line: missing-return-value
end

---@param link? string
---@param data? string
---@param text? string
---@param mawPowerUnit? UnitToken
---@return number|string? texture
local function GetLinkTexture(link, data, text, mawPowerUnit)
    if not link then
        return
    end
    local prefix, id = link:match("|H(%D+):(%d+)")
    if prefix == "item" then
        return C_Item.GetItemIconByID(link)
    end
    if prefix == "currency" then
        local currencyInfo = C_CurrencyInfo.GetCurrencyInfoFromLink(link)
        return currencyInfo.iconFileID
    end
    if prefix == "garrfollower" then
        local texture = C_Garrison.GetFollowerPortraitIconIDByID(id)
        return texture and texture ~= 0 and texture ~= "" and texture or 1066622
    end
    if prefix == "battlepet" then
        local _, texture = C_PetJournal.GetPetInfoBySpeciesID(id)
        return texture
    end
    if prefix == "mawpower" and data and mawPowerUnit then
        local texture = GetUnitMawPowerInfo(mawPowerUnit, data, true)
        return texture
    end
end

---@param text? string
---@return string? tierAtlas, string tierAtlasName, string tier, string tierAtlasSuffix
local function GetAtlasTierInfo(text)
    if not text then
        return ---@diagnostic disable-line: missing-return-value
    end
    local tierAtlas, tierAtlasName, tier, tierAtlasSuffix = text:match(AtlasMarkupPattern)
    return tierAtlas, tierAtlasName, tier, tierAtlasSuffix
end

---@param itemLink string
---@return number? itemLevel, string? equipSlot
local function GetItemLevelAndEquipSlot(itemLink)
    local _, _, _, equipSlot = C_Item.GetItemInfoInstant(itemLink)
    local _, _, _, baseItemLevel, _, _, _, _, tempEquipSlot = C_Item.GetItemInfo(itemLink)
    local actualItemLevel, previewLevel, sparseItemLevel = C_Item.GetDetailedItemLevelInfo(itemLink)
    return actualItemLevel or baseItemLevel, equipSlot or tempEquipSlot
end

---@param texture number|string
---@param trim? number
---@param size? number
local function GetChatIconMarkup(texture, trim, size)
    local temp = ":0:0"
    if trim and size and trim > 1 and size > 0 then
        local ratio = size/100
        local minPX = floor(ratio * trim)
        local maxPX = floor(ratio * (100 - trim))
        temp = format(":%d:%d:0:0:%d:%d:%d:%d:%d:%d", size, size, size, size, minPX, maxPX, minPX, maxPX)
    end
    return format("|T%s%s|t", texture, temp)
end

---@param color? string
---@param data? string
---@param texture number|string
---@param hyperlink? boolean
---@param simple? boolean
---@param customColor? string
---@param appendText? string
---@return string chatItemLink
local function GetChatLootIcon(color, data, texture, hyperlink, simple, customColor, appendText)
    local temp = GetChatIconMarkup(texture)
    if appendText then
        temp = format("%s%s", temp, appendText)
    end
    if data and hyperlink then
        temp = format("|H%s|h%s|h", data, temp)
    end
    if not simple then
        temp = format("[%s]", temp)
    end
    if customColor then
        color = customColor
    end
    return format("|c%s%s|r", color, temp)
end

---@param link string
---@param hyperlink? boolean
---@param simple? boolean
---@param customColor? string
---@param appendItemLevel? boolean
---@param mawPowerUnit? UnitToken
---@return string itemLink
local function GetLootIcon(link, hyperlink, simple, customColor, appendItemLevel, mawPowerUnit)
    local color, data, text = link:match(LinkMarkupPattern) ---@type string?, string?, string?
    local texture = GetLinkTexture(link, data, text, mawPowerUnit)
    if not texture then
        return link
    end
    local tierAtlas, tierAtlasName, tier, tierAtlasSuffix = GetAtlasTierInfo(text)
    local appendText ---@type string?
    if tier then
        appendText = format(":Q%s", tier)
    end
    if appendItemLevel then
        local itemLevel = GetItemLevelAndEquipSlot(link)
        if itemLevel and itemLevel > 1 then
            appendText = format("%s:%s", appendText or "", itemLevel)
        end
    end
    return GetChatLootIcon(color, data, texture, hyperlink, simple, customColor, appendText)
end

---@class MiniLootNSUtils
ns.Utils = {
    SimpleHexColors = SimpleHexColors,
    TableCopy = TableCopy,
    TableContains = TableContains,
    TableCombine = TableCombine,
    TableMerge = TableMerge,
    TableReverse = TableReverse,
    TableIsArray = TableIsArray,
    TableKeys = TableKeys,
    TableValues = TableValues,
    TableMap = TableMap,
    TableReduce = TableReduce,
    TableSwap = TableSwap,
    TableGroup = TableGroup,
    PatternToFormat = PatternToFormat,
    ConvertToNumber = ConvertToNumber,
    ConvertToMoney = ConvertToMoney,
    ConvertToMoneyString = ConvertToMoneyString,
    ValuesAreSameish = ValuesAreSameish,
    FormatNumber = FormatNumber,
    ColorByDelta = ColorByDelta,
    SumByKey = SumByKey,
    SumByKeyPretty = SumByKeyPretty,
    GetUnitName = GetUnitName,
    GetShortUnitName = GetShortUnitName,
    GetLeftString = GetLeftString,
    UpperCaseWords = UpperCaseWords,
    AbbreviateString = AbbreviateString,
    GetShortFactionName = GetShortFactionName,
    GetUnitMawPowerInfo = GetUnitMawPowerInfo,
    GetLinkTexture = GetLinkTexture,
    GetItemLevelAndEquipSlot = GetItemLevelAndEquipSlot,
    GetChatIconMarkup = GetChatIconMarkup,
    GetChatLootIcon = GetChatLootIcon,
    GetLootIcon = GetLootIcon,
}
