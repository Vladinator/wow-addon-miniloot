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
    return true
end

---@param number number
---@return string
local function FormatNumber(number)
    return BreakUpLargeNumbers(number)
end

---@class MiniLootSimpleHexColors
local SimpleHexColors = {
    SystemYellow = "FFFF00",
    Yellow = "FFFF33",
    Red = "FF3333",
    Green = "33FF33",
    Blue = "3333FF",
    Gray = "CCCCCC",
}

---@param text string|number
---@param delta number
---@return string
local function ColorByDelta(text, delta)
    local color = delta < 0 and SimpleHexColors.Red or delta > 0 and SimpleHexColors.Green or SimpleHexColors.Gray
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
    ValuesAreSameish = ValuesAreSameish,
    FormatNumber = FormatNumber,
    ColorByDelta = ColorByDelta,
    SumByKey = SumByKey,
    SumByKeyPretty = SumByKeyPretty,
}
