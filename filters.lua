local ns = select(2, ...) ---@class MiniLootNS

local GetLinkQuality = ns.Utils.GetLinkQuality

---@alias MiniLootFilterComparators
---|"eq"
---|"ne"
---|"gt"
---|"ge"
---|"lt"
---|"le"

---@alias MiniLootFilterConverters
---|"quality"

---@class MiniLootFilter
---@field public group? MiniLootMessageGroup
---@field public type? MiniLootMessageFormatSimpleParserResultType
---@field public key MiniLootMessageFormatSimpleParserResultKeys
---@field public convert? MiniLootFilterConverters
---@field public comparator MiniLootFilterComparators
---@field public value any

---@param src MiniLootFilter
---@param dst MiniLootFilter
---@return MiniLootFilter dst
local function CopyFilter(src, dst)
    dst.group = src.group
    dst.type = src.type
    dst.key = src.key
    dst.convert = src.convert
    dst.comparator = src.comparator
    dst.value = src.value
    return dst
end

---@param value any
---@param convert MiniLootFilterConverters
---@return any
local function ConvertValue(value, convert)
    local valueType = type(value)
    if convert == "quality" then
        local quality ---@type number?
        if valueType == "string" then
            quality = GetLinkQuality(valueType)
        end
        return quality
    end
    return value
end

---@param value1 any
---@param comparator MiniLootFilterComparators
---@param value2 any
---@return boolean
local function CompareValues(value1, comparator, value2)
    if comparator == "eq" then
        if value1 == value2 then
            return true
        end
    elseif comparator == "ne" then
        if value1 ~= value2 then
            return true
        end
    end
    local type1 = type(value1)
    local type2 = type(value2)
    local comparable = (type1 == "number" or type1 == "string") and (type2 == "number" or type2 == "string")
    if comparable then
        if comparator == "gt" then
            return value1 > value2
        elseif comparator == "ge" then
            return value1 >= value2
        elseif comparator == "lt" then
            return value1 < value2
        elseif comparator == "le" then
            return value1 <= value2
        end
    end
    comparable = (type1 == "boolean" or type1 == "nil") and (type2 == "boolean" or type2 == "nil")
    if comparable then
        value1 = not not value1
        value2 = not not value2
        if comparator == "eq" then
            return value1 and value2
        elseif comparator == "ne" then
            return not (value1 and value2)
        end
    end
    return false
end

---@param filter MiniLootFilter
---@param result MiniLootMessageFormatSimpleParserResult
---@param message MiniLootMessage
---@return boolean success
local function ProcessFilter(filter, result, message)
    if filter.group ~= message.group then
        return false
    end
    if filter.type ~= result.Type then
        return false
    end
    local resultValue = result[filter.key] ---@type any
    if filter.convert then
        resultValue = ConvertValue(resultValue, filter.convert)
    end
    return CompareValues(filter.value, filter.comparator, resultValue)
end

---@param filters MiniLootFilter[]
---@param result MiniLootMessageFormatSimpleParserResult
---@param message MiniLootMessage
---@return boolean success, MiniLootFilter filter
local function ProcessFilters(filters, result, message)
    for _, filter in ipairs(filters) do
        local success = ProcessFilter(filter, result, message)
        if success then
            return true, filter
        end
    end
    return false ---@diagnostic disable-line: missing-return-value
end

---@class MiniLootNSFilters
ns.Filters = {
    CopyFilter = CopyFilter,
    ProcessFilter = ProcessFilter,
    ProcessFilters = ProcessFilters,
}
