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

---@alias MiniLootFilterEntry MiniLootFilter|MiniLootFilterCollection

---@class MiniLootFilterCollection
---@field public logic "and"|"or"
---@field public children MiniLootFilterEntry

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
---@return boolean isRelevant
local function IsFilterRelevant(filter, result, message)
    if filter.group and filter.group ~= message.group then
        return false
    end
    if filter.type and filter.type ~= result.Type then
        return false
    end
    return true
end

---@param filter MiniLootFilter
---@param result MiniLootMessageFormatSimpleParserResult
---@return boolean satisfiesFilter
local function ProcessFilterValues(filter, result)
    local resultValue = result[filter.key] ---@type any
    if filter.convert then
        resultValue = ConvertValue(resultValue, filter.convert)
    end
    return CompareValues(filter.value, filter.comparator, resultValue)
end

---@param filters MiniLootFilter[]
---@param result MiniLootMessageFormatSimpleParserResult
---@param message MiniLootMessage
---@return boolean? isFiltered, MiniLootFilter? filteredBy
local function ProcessFilters(filters, result, message)
    local numRelevant = 0
    for _, filter in ipairs(filters) do
        if IsFilterRelevant(filter, result, message) then
            numRelevant = numRelevant + 1
            local satisfiesFilter = ProcessFilterValues(filter, result)
            if not satisfiesFilter then
                return true, filter
            end
        end
    end
    if numRelevant > 0 then
        return false
    end
end

---@param filtersCollections MiniLootFilterEntry[]
---@param result MiniLootMessageFormatSimpleParserResult
---@param message MiniLootMessage
---@return boolean? isFiltered, MiniLootFilterEntry? filteredBy
local function ProcessRequirements(filtersCollections, result, message)
    local numRelevant = 0
    ---@param filterCollection MiniLootFilterEntry
    ---@return boolean? isFiltered, MiniLootFilterEntry? filteredBy, number count, number total
    local function processFilterCollection(filterCollection)
        local count = 0
        local total = 0
        if filterCollection.logic then
            local isAndLogic = filterCollection.logic == "and"
            ---@type MiniLootFilterEntry[]
            local subFilterCollection = filterCollection.children ---@diagnostic disable-line: assign-type-mismatch
            for _, subChild in ipairs(subFilterCollection) do
                local subIsFiltered, subFilteredBy, subCount, subTotal = processFilterCollection(subChild)
                total = total + subTotal
                if subIsFiltered then
                    count = count + subCount
                    if not isAndLogic then
                        return true, subFilteredBy, count, total
                    end
                end
            end
            if isAndLogic then
                return count ~= total, nil, count, total
            end
            return count > 0, nil, count, total
        end
        ---@type MiniLootFilter
        local filter = filterCollection ---@diagnostic disable-line: assign-type-mismatch
        if IsFilterRelevant(filter, result, message) then
            total = total + 1
            local satisfiesFilter = ProcessFilterValues(filter, result)
            if not satisfiesFilter then
                count = count + 1
                return true, filter, count, total
            end
        end
        return nil, nil, count, total
    end
    for _, filterCollection in ipairs(filtersCollections) do
        local isFiltered, filteredBy, count, total = processFilterCollection(filterCollection)
        if isFiltered then
            return true, filteredBy
        end
    end
    if numRelevant > 0 then
        return false
    end
end

---@class MiniLootNSFilters
ns.Filters = {
    ProcessRequirements = ProcessRequirements,
}
