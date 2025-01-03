local ns = select(2, ...) ---@class MiniLootNS

local MiniLootMessageGroup = ns.Messages.MiniLootMessageGroup
local MessagesCollection = ns.Messages.MessagesCollection
local TableCopy = ns.Utils.TableCopy
local GetTimerunningSeasonID = ns.Utils.GetTimerunningSeasonID

---@enum MiniLootChatFrame
local MiniLootChatFrame = {
    ChatFrame1 = "ChatFrame1",
    ChatFrame2 = "ChatFrame2",
    ChatFrame3 = "ChatFrame3",
    ChatFrame4 = "ChatFrame4",
    ChatFrame5 = "ChatFrame5",
    ChatFrame6 = "ChatFrame6",
    ChatFrame7 = "ChatFrame7",
    ChatFrame8 = "ChatFrame8",
    ChatFrame9 = "ChatFrame9",
}

---@class MiniLootNSSettingsOptions
---@field ChatFrame MiniLootChatFrame
---@field EnabledGroups table<MiniLootMessageGroup, boolean?>
---@field IgnoredGroups table<MiniLootMessageGroup, boolean?>
---@field DebounceGroups table<MiniLootMessageGroup, number?>
---@field EnabledTooltips table<MiniLootTooltipHandlerType, boolean?>
---@field Filters MiniLootFilters

---@class MiniLootNSSettingsOptions
local DefaultOptions = {
    Enabled = true, --- actively monitor loot messages and apply transformations
    EnableTooltips = true, --- show tooltips above chat frame when hovering links
    EnableRemixMode = true, --- enable separate profile with settings when on a remix character
    ChatFrame = MiniLootChatFrame.ChatFrame1, --- the default output chat frame
    Debounce = 2, --- gather loot messages and when it settles this many seconds later we print the summary
    DebounceInCombat = true, --- if debounce should wait until combat ends before counting down
    ShortenPlayerNames = true, --- enable to remove the realm name
    ShortenFactionNames = true, --- enable to reduce the length of faction names
    ShortenFactionNamesLength = 10, --- specify the length before reduction activates
    IconTrim = 8, --- the px we want to trim from the texture icons
    IconSize = 12, --- the px size we want the texture icon to be shown at
    ItemCount = false, --- enable to add item count behind icons
    ItemCountBank = true, --- enable to also include items in the bank
    ItemCountUses = true, --- enable to count uses/charges as "one item"
    ItemCountReagentBank = true, --- enable to also include items in the reagent bank
    ItemCountCurrency = true, --- enable to count currency items
    ItemLevel = true, --- enable to add item level behind icons
    ItemLevelEquipmentOnly = true, --- enable to only show item level on equippable items
    ItemTier = true, --- enable to add quality tier behind icons (DF crafting tier system)
    ItemTierAsText = true, --- enable to convert the texture indicator into text
    EnabledGroups = {}, --- these groups are enabled for processing
    IgnoredGroups = {}, --- these groups are ignored and will be filtered from the chat
    DebounceGroups = {}, --- these groups use a custom `Debounce` value
    EnabledTooltips = {}, --- only used if `EnableTooltips` is enabled, only tooltips of this type will be shown when hovering links
    Filters = {}, --- list of filters (rules or rule groups) to better specify what we wish to see printed to the chat frame
}

do

    for _, message in ipairs(MessagesCollection) do
        local defaultDebounce = message.defaultDebounce
        if defaultDebounce then
            DefaultOptions.DebounceGroups[message.group] = defaultDebounce
        end
    end

end

---@class MiniLootNSSettingsOptions
local DefaultRemixOptions = TableCopy(DefaultOptions)

if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then

    ---@type MiniLootFilterRule
    local ItemIsQuest = {
        group = MiniLootMessageGroup.Loot,
        type = "Loot",
        key = "Link",
        convert = "quest",
        comparator = "eq",
        value = true,
    }

    ---@type MiniLootFilterRule
    local ItemIsGem = {
        group = MiniLootMessageGroup.Loot,
        type = "Loot",
        key = "Link",
        convert = "itemClass",
        comparator = "eq",
        value = Enum.ItemClass.Gem,
    }

    ---@type MiniLootFilterRule
    local ItemQualityCommonOrHigher = {
        group = MiniLootMessageGroup.Loot,
        type = "Loot",
        key = "Link",
        convert = "quality",
        comparator = "ge",
        value = Enum.ItemQuality.Common,
    }

    ---@type MiniLootFilterRule
    local ItemQualityRareOrHigher = {
        group = MiniLootMessageGroup.Loot,
        type = "Loot",
        key = "Link",
        convert = "quality",
        comparator = "ge",
        value = Enum.ItemQuality.Rare,
    }

    DefaultOptions.Filters[#DefaultOptions.Filters + 1] = {
        logic = "or",
        children = {
            ItemIsQuest,
            ItemQualityCommonOrHigher,
        },
    }

    DefaultRemixOptions.Filters[#DefaultRemixOptions.Filters + 1] = {
        logic = "or",
        children = {
            ItemIsQuest,
            ItemIsGem,
            ItemQualityRareOrHigher,
        },
    }

end

---@class MiniLootNSSettingsMetatable
local OptionsMetatable = {
    __index = function(self, key)
        local value = DefaultOptions[key]
        if type(value) == "table" then
            value = TableCopy(value)
            rawset(self, key, value)
        end
        return value
    end,
}

---@class MiniLootNSSettingsMetatable
local RemixOptionsMetatable = {
    __index = function(self, key)
        local value = DefaultRemixOptions[key]
        if type(value) == "table" then
            value = TableCopy(value)
            rawset(self, key, value)
        end
        return value
    end,
}

---@return MiniLootNSSettingsOptions db, MiniLootNSSettingsOptions remixDb
local function ProcessSavedVariables()
    local db = _G.MiniLootDB2
    local remixDb = _G.MiniLootRemixDB2
    if type(db) ~= "table" then
        db = {}
        _G.MiniLootDB2 = db
    end
    if type(remixDb) ~= "table" then
        remixDb = {}
        _G.MiniLootRemixDB2 = remixDb
    end
    if not getmetatable(db) then
        setmetatable(db, OptionsMetatable)
    end
    if not getmetatable(remixDb) then
        setmetatable(remixDb, RemixOptionsMetatable)
    end
    return db, remixDb
end

---@class MiniLootNSSettings
---@field public db MiniLootNSSettingsOptions

---@param db MiniLootNSSettingsOptions
---@param key string
local function CanUseRemixDB(db, key)
    if key == "EnableRemixMode" or db.EnableRemixMode == false then
        return false
    end
    local seasonID = GetTimerunningSeasonID()
    return not not seasonID
end

---@type MiniLootNSSettingsOptions
local flexDbProxy = setmetatable({}, {
    __index = function(self, key)
        local db, remixDb = ProcessSavedVariables()
        if CanUseRemixDB(db, key) then
            return remixDb[key]
        end
        return db[key]
    end,
    __newindex = function (self, key, value)
        local db, remixDb = ProcessSavedVariables()
        if CanUseRemixDB(db, key) then
            remixDb[key] = value
        else
            db[key] = value
        end
    end,
})

local function ResetSavedVariables()
    table.wipe(_G.MiniLootDB2)
    table.wipe(_G.MiniLootRemixDB2)
end

local function GetChatFrame()
    local chatName = flexDbProxy.ChatFrame
    local chatFrame = _G[chatName] ---@type MiniLootChatFramePolyfill
    return chatFrame
end

---@class MiniLootNSSettings
ns.Settings = {
    db = flexDbProxy,
    DefaultOptions = DefaultOptions,
    ResetSavedVariables = ResetSavedVariables,
    GetChatFrame = GetChatFrame,
}
