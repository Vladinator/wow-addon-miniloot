local ns = select(2, ...) ---@class MiniLootNS

---@type MiniLootNSSettingsOptions
local db = setmetatable({}, { __index = function(self, key) return ns.Settings.db[key] end })

---@class MiniLootProjectVariant
---@field public EditBoxNumberTemplate? string
---@field public DropDownTemplate? string
---@field public DropDownTemplateOnLoad? fun(self: MiniLootInterfacePanelWidgetDropDown)
---@field public DropDownTemplateCreateInitializer? fun(settings: any, options: fun(): SettingsControlDropDownOptionPolyfill[])
---@field public DropDownTemplateOnInitialized? fun(self: MiniLootInterfacePanelWidgetDropDown)

---@type table<number, MiniLootProjectVariant>|MiniLootProjectVariant
local ProjectVariant = {
    [0] = {
        EditBoxNumberTemplate = "NumericInputBoxTemplate",
        DropDownTemplate = "SettingsDropDownControlTemplate",
        DropDownTemplateCreateInitializer = Settings.CreateDropdownInitializer,
    },
    [WOW_PROJECT_CLASSIC] = {
        EditBoxNumberTemplate = "InputBoxTemplate",
        DropDownTemplate = "AutoLootDropDownControlTemplate",
        DropDownTemplateOnLoad = function(self)
            local element = self.Element
            element.Text:SetAlpha(0)
            element.Tooltip:SetAllPoints(self.Label)
        end,
        DropDownTemplateCreateInitializer = Settings.CreateDropDownInitializer,
        DropDownTemplateOnInitialized = function(self)
            local element = self.Element
            element.autoLootSetting = nil
            self:Refresh()
        end,
    },
}

if select(4, GetBuildInfo()) < 110000 then -- `pre-11.0`
    local ProjectVariantMainline = ProjectVariant[0]
    ProjectVariantMainline.DropDownTemplate = ProjectVariant[WOW_PROJECT_CLASSIC].DropDownTemplate
    ProjectVariantMainline.DropDownTemplateOnLoad = ProjectVariant[WOW_PROJECT_CLASSIC].DropDownTemplateOnLoad
    ProjectVariantMainline.DropDownTemplateCreateInitializer = ProjectVariant[WOW_PROJECT_CLASSIC].DropDownTemplateCreateInitializer
    ProjectVariantMainline.DropDownTemplateOnInitialized = ProjectVariant[WOW_PROJECT_CLASSIC].DropDownTemplateOnInitialized
end

do

    local DefaultProjectVariant = ProjectVariant[0]

    local DefaultProjectVariantMetatable = {
        __index = function(self, key)
            return DefaultProjectVariant[key]
        end,
    }

    for i = 1, 100 do
        local project = ProjectVariant[i]
        if project then
            setmetatable(project, DefaultProjectVariantMetatable)
        end
    end

    setmetatable(ProjectVariant, {
        __index = function(self, key)
            local project = rawget(self, WOW_PROJECT_ID) or DefaultProjectVariant
            return project[key]
        end,
    })

end

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

---@generic T
---@param tbl T[]
---@param sortType? "Ascending"|"Descending"
---@return T[] sorted
local function TableSort(tbl, sortType)
    if not sortType or sortType == "Ascending" then
        table.sort(tbl, function(a, b) return strcmputf8i(tostringall(a, b)) < 0 end)
    else
        table.sort(tbl, function(a, b) return strcmputf8i(tostringall(a, b)) > 0 end)
    end
    return tbl
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
    return GetMoneyString(money, true) -- C_CurrencyInfo.GetCoinTextureString
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

---@return number? seasonID
local function GetTimerunningSeasonID()
    local seasonID = PlayerGetTimerunningSeasonID and PlayerGetTimerunningSeasonID()
    return seasonID and seasonID > 0 and seasonID or nil
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
    DarkGray = "999999",
}

---@param text string|number
---@param delta number
---@return string
local function ColorByDelta(text, delta)
    local color = delta < 0 and SimpleHexColors.Red or delta > 0 and SimpleHexColors.Green or SimpleHexColors.White
    return format("|cff%s%s|r", color, text)
end

---@param value number
---@param delta number
---@param skipColor? boolean
---@return string
local function FormatNumberGainLoss(value, delta, skipColor)
    local text = FormatNumber(value)
    text = format("%s%s", value < 0 and "-" or "", text)
    if not skipColor then
        text = ColorByDelta(text, delta)
    end
    return text
end

---@param results MiniLootMessageFormatSimpleParserResults[]
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

---@param results MiniLootMessageFormatSimpleParserResults[]
---@param key string
---@param skipColor? boolean
---@return string prettyTotal, number total
local function SumByKeyPretty(results, key, skipColor)
    local total = SumByKey(results, key)
    local text = FormatNumberGainLoss(total, total, skipColor)
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

local LinkMarkupPattern1 = "|c[fF][fF]([0-9a-fA-F]+)|H(.-)|h%[(.-)%]|h|r"
local LinkMarkupPattern2 = "|cnIQ(%d+):|H(.-)|h%[(.-)%]|h|r"
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
        local spellLink = C_Spell.GetMawPowerLinkBySpellID(spellID) ---@type string?
        if spellLink then
            if query == spellID or query == spellLink then
                return spellTexture, spellID, spellLink
            end
            local _, spellName = spellLink:match(LinkMarkupPattern1)
            if query == spellName then
                return spellTexture, spellID, spellLink
            end
            _, spellName = spellLink:match(LinkMarkupPattern2)
            if query == spellName then
                return spellTexture, spellID, spellLink
            end
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
    -- TODO: db.IconSize
    return tierAtlas, tierAtlasName, tier, tierAtlasSuffix
end

---@param atlas string
---@param fileWidth number
---@param fileHeight number
---@param width? number
---@param height? number
---@param offsetX? number
---@param offsetY? number
---@return string?
local function CreateTextureMarkupFromAtlas(atlas, fileWidth, fileHeight, width, height, offsetX, offsetY)
    local info = C_Texture.GetAtlasInfo(atlas)
    if not info then
        return
    end
    return CreateTextureMarkup(info.file, fileWidth, fileHeight, width or 0, height or 0, info.leftTexCoord, info.rightTexCoord, info.topTexCoord, info.bottomTexCoord, offsetX or 0, offsetY or 0)
end

local NonEquippableSlots = {
    [""] = true,
    ["INVTYPE_NON_EQUIP"] = true,
    ["INVTYPE_NON_EQUIP_IGNORE"] = true,
}

---@param itemLink string
---@return number? itemLevel, string? equipSlot
local function GetItemLevelAndEquipSlot(itemLink)
    local _, _, _, equipSlot = C_Item.GetItemInfoInstant(itemLink)
    local _, _, _, baseItemLevel, _, _, _, _, tempEquipSlot = C_Item.GetItemInfo(itemLink)
    local actualItemLevel, previewLevel, sparseItemLevel = C_Item.GetDetailedItemLevelInfo(itemLink)
    equipSlot = equipSlot or tempEquipSlot
    if equipSlot and NonEquippableSlots[equipSlot] then
        equipSlot = nil ---@diagnostic disable-line: cast-local-type
    end
    return actualItemLevel or baseItemLevel, equipSlot
end

---@param texture number|string
---@param trim? number
---@param size? number
local function GetChatIconMarkup(texture, trim, size)
    trim = trim or db.IconTrim
    size = size or db.IconSize
    local temp = ":0:0"
    if trim and size and trim > 0 and size > 0 then
        local ratio = size/100
        local minPX = floor(ratio * trim + 0.5)
        local maxPX = floor(ratio * (100 - trim) + 0.5)
        temp = format(":%d:%d:0:0:%d:%d:%d:%d:%d:%d", size, size, size, size, minPX, maxPX, minPX, maxPX)
    end
    return format("|T%s%s|t", texture, temp)
end

---@param color? string `RRGGBB`
---@param data? string
---@param texture number|string
---@param hyperlink? boolean
---@param simple? boolean
---@param customColor? string `RRGGBB`
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
    return format("|cff%s%s|r", color, temp)
end

---@param link string
---@param hyperlink? boolean
---@param simple? boolean
---@param customColor? string `RRGGBB`
---@param mawPowerUnit? UnitToken
---@return string itemLink
local function GetLootIcon(link, hyperlink, simple, customColor, mawPowerUnit)
    local color, data, text = link:match(LinkMarkupPattern1) ---@type string?, string?, string?
    if not color then
        color, data, text = link:match(LinkMarkupPattern2) ---@type string?, string?, string?
        color = C_ColorOverrides.GetColorForQuality(color) ---@type ColorMixin
        color = color:GenerateHexColor():sub(3)
    end
    local texture = GetLinkTexture(link, data, text, mawPowerUnit)
    if not texture then
        return link
    end
    local appendText ---@type string?
    if db.ItemTier then
        local tierAtlas, tierAtlasName, tier, tierAtlasSuffix = GetAtlasTierInfo(text)
        if tier then
            if db.ItemTierAsText then
                appendText = tier
            else
                appendText = CreateTextureMarkupFromAtlas(tierAtlasName, 2048, 1024)
            end
        end
    end
    if db.ItemLevel then
        local itemLevel, equipSlot = GetItemLevelAndEquipSlot(link)
        if itemLevel and itemLevel > 1 and (not db.ItemLevelEquipmentOnly or equipSlot) then
            appendText = format("%s:%s", appendText or "", itemLevel)
        end
    end
    local temp = GetChatLootIcon(color, data, texture, hyperlink, simple, customColor, appendText)
    if hyperlink then
        temp = ns.Links.Wrap(temp, link)
    end
    return temp
end

local function GetChatFrames()
    local chatFrames = {} ---@type MiniLootChatFramePolyfill[]
    local index = 0
    for i = 1, 100 do
        local name = format("ChatFrame%d", i)
        local chatFrame = _G[name] ---@type MiniLootChatFramePolyfill?
        if chatFrame then
            index = index + 1
            chatFrames[index] = chatFrame
        end
    end
    return chatFrames
end

---@param chatFrame MiniLootChatFramePolyfill
local function IsChatFrame(chatFrame)
    return chatFrame and type(chatFrame) == "table" and
        chatFrame.IsShown and type(chatFrame.IsShown) == "function" and
        chatFrame.AddMessage and type(chatFrame.AddMessage) == "function" and
        true or false
end

local QualityColorPattern = "|cnIQ(%d+):"
local HexColorPattern = "|c[fF][fF]([0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])"

local HexColorToQuality = {
    ["9d9d9d"] = Enum.ItemQuality.Poor,
    ["ffffff"] = Enum.ItemQuality.Common,
    ["1eff00"] = Enum.ItemQuality.Uncommon,
    ["0070dd"] = Enum.ItemQuality.Rare,
    ["a335ee"] = Enum.ItemQuality.Epic,
    ["ff8000"] = Enum.ItemQuality.Legendary,
    ["e6cc80"] = Enum.ItemQuality.Artifact,
    ["00ccff"] = Enum.ItemQuality.Heirloom,
}

---@param link string
---@return number? qualityID
local function GetLinkQuality(link)
    local id = link:match(QualityColorPattern)
    if id then
        return tonumber(id)
    end
    local hex = link:match(HexColorPattern)
    if not hex then
        return
    end
    return HexColorToQuality[hex] or HexColorToQuality[hex:lower()]
end

---@param link string
---@return boolean
local function IsQuestItem(link)
    local _, _, _, _, _, classID = C_Item.GetItemInfoInstant(link)
    return classID == Enum.ItemClass.Questitem
end

---@param link string
---@param arg1? number
---@param arg2? number
---@param hideVendorPrice? boolean
---@return TooltipDataLine[]? lines
local function GetHyperlinkTooltipLines(link, arg1, arg2, hideVendorPrice)
    local data = C_TooltipInfo.GetHyperlink(link, arg1, arg2, hideVendorPrice)
    if not data then
        return
    end
    return data.lines
end

---@param link string
---@param leftText? string
---@param rightText? string
---@return TooltipDataLine? line, number lineIndex
local function GetHyperlinkLineInTooltip(link, leftText, rightText)
    local lines = GetHyperlinkTooltipLines(link)
    if not lines then
        return ---@diagnostic disable-line: missing-return-value
    end
    for i = 2, #lines do
        local line = lines[i]
        if leftText and leftText == line.leftText then
            return line, i
        end
        if rightText and rightText == line.rightText then
            return line, i
        end
    end
    return ---@diagnostic disable-line: missing-return-value
end

---@param link string
---@return boolean isUnique, boolean isUniqueEquipped
local function IsUniqueItem(link)
    local isUnique = not not GetHyperlinkLineInTooltip(link, ITEM_UNIQUE)
    local isUniqueEquipped = not not GetHyperlinkLineInTooltip(link, ITEM_UNIQUE_EQUIPPABLE)
    return isUnique, isUniqueEquipped
end

---@param link string
---@return boolean isQuestStartingItem
local function IsQuestStartingItem(link)
    local isQuestStartingItem = not not GetHyperlinkLineInTooltip(link, ITEM_STARTS_QUEST)
    return isQuestStartingItem
end

---@param link string
---@return boolean isUncollected
local function IsAppearanceUncollected(link)
    local isUncollected = not not GetHyperlinkLineInTooltip(link, TRANSMOGRIFY_TOOLTIP_APPEARANCE_UNKNOWN)
    return isUncollected
end

---@param link string
---@param includeBank? boolean
---@param includeUses? boolean
---@param includeReagentBank? boolean
---@return number count
local function GetItemCount(link, includeBank, includeUses, includeReagentBank)
    if includeBank == nil then
        includeBank = true
    end
    if includeUses == nil then
        includeUses = true
    end
    if includeReagentBank == nil then
        includeReagentBank = true
    end
    return C_Item.GetItemCount(link, includeBank, includeUses, includeReagentBank)
end

---@param link number|string
---@return CurrencyInfo? info
local function GetCurrencyInfo(link)
    local id = link
    if type(id) == "string" then
        id = C_CurrencyInfo.GetCurrencyIDFromLink(id)
    end
    return C_CurrencyInfo.GetCurrencyInfo(id)
end

---@param link number|string
---@param amount? number
---@return string? link
local function GetCurrencyLink(link, amount)
    local id = link
    if type(id) == "string" then
        id = C_CurrencyInfo.GetCurrencyIDFromLink(id)
    end
    return C_CurrencyInfo.GetCurrencyLink(id, amount)
end

-- older flavors don't have currencies so if this API is missing we replace our functions to return nothing
if not C_CurrencyInfo.GetCurrencyIDFromLink or not C_CurrencyInfo.GetCurrencyInfo or not C_CurrencyInfo.GetCurrencyLink then
    GetCurrencyInfo = function() end
    GetCurrencyLink = function() end
end

---@param link number|string
---@return number count, number maxCount, number weeklyRemainingCount
local function GetCurrencyCount(link)
    local info = GetCurrencyInfo(link)
    if not info then
        return 0, 0, 0
    end
    return info.quantity, info.maxQuantity, info.maxWeeklyQuantity - info.quantityEarnedThisWeek
end

---@param link string
local function IsItemAnimaPower(link)
    return type(link) == "string" and link:find("mawpower:") and true or false
end

---@param rank number
---@param xp number
---@param tier number
---@return number nextRank, number currentXP, number nextRankXP
local function GetArtifactInfo(rank, xp, tier)
    local origRank = rank
    local rankXP
    repeat
        rankXP = C_ArtifactUI.GetCostForPointAtRank(rank, tier)
        if rankXP > 0 and xp >= rankXP then
            xp = xp - rankXP
            rank = rank + 1
        end
    until rankXP <= 0 or xp < rankXP
    local nextRank = rank - origRank
    return nextRank, xp, rankXP
end

---@class MiniLootNSUtils
ns.Utils = {
    ProjectVariant = ProjectVariant,
    SimpleHexColors = SimpleHexColors,
    TableCopy = TableCopy,
    TableContains = TableContains,
    TableCombine = TableCombine,
    TableMerge = TableMerge,
    TableReverse = TableReverse,
    TableIsArray = TableIsArray,
    TableKeys = TableKeys,
    TableValues = TableValues,
    TableSort = TableSort,
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
    GetTimerunningSeasonID = GetTimerunningSeasonID,
    ColorByDelta = ColorByDelta,
    FormatNumberGainLoss = FormatNumberGainLoss,
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
    GetLootIcon = GetLootIcon,
    GetChatFrames = GetChatFrames,
    IsChatFrame = IsChatFrame,
    GetLinkQuality = GetLinkQuality,
    IsQuestItem = IsQuestItem,
    GetHyperlinkTooltipLines = GetHyperlinkTooltipLines,
    GetHyperlinkLineInTooltip = GetHyperlinkLineInTooltip,
    IsUniqueItem = IsUniqueItem,
    IsQuestStartingItem = IsQuestStartingItem,
    IsAppearanceUncollected = IsAppearanceUncollected,
    GetItemCount = GetItemCount,
    GetCurrencyInfo = GetCurrencyInfo,
    GetCurrencyLink = GetCurrencyLink,
    GetCurrencyCount = GetCurrencyCount,
    IsItemAnimaPower = IsItemAnimaPower,
    GetArtifactInfo = GetArtifactInfo,
}
