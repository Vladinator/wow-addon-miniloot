local ns = select(2, ...) ---@class MiniLootNS

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
---@field public group MiniLootMessageGroup
---@field public type MiniLootMessageFormatSimpleParserResultType
---@field public key MiniLootMessageFormatSimpleParserResultKeys
---@field public convert? MiniLootFilterConverters
---@field public comparator MiniLootFilterComparators
---@field public value any

---@class MiniLootFilterSV : MiniLootFilter
---@field public group? nil

---@class MiniLootNSFilters
ns.Filters = {
}
