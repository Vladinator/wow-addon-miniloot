local ns = select(2, ...) ---@class MiniLootNS

local MiniLootMessageGroup = ns.Messages.MiniLootMessageGroup
local TableCopy = ns.Utils.TableCopy

---@enum MiniLootChatFrame
local MiniLootChatFrame = {
    DEFAULT_CHAT_FRAME = "DEFAULT_CHAT_FRAME",
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
---@field Filters table<MiniLootMessageGroup, MiniLootFilterSV[]>

---@class MiniLootNSSettingsOptions
local DefaultOptions = {
    Enabled = true,
    EnableTooltips = true,
    EnableRemixMode = true,
    ChatFrame = MiniLootChatFrame.DEFAULT_CHAT_FRAME,
    Debounce = 2,
    EnabledGroups = {},
    IgnoredGroups = {},
    DebounceGroups = {},
    EnabledTooltips = {},
    Filters = {},
}

for k, v in pairs(MiniLootMessageGroup) do
    DefaultOptions.EnabledGroups[k] = nil
    DefaultOptions.IgnoredGroups[k] = nil
    if k:find("^LootRoll") then
        DefaultOptions.DebounceGroups[k] = 0
    end
    DefaultOptions.Filters[k] = {}
end

---@class MiniLootNSSettingsOptions
local DefaultRemixOptions = TableCopy(DefaultOptions)

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

---@type MiniLootNSSettingsOptions
local dbProxy = setmetatable({}, {
    __index = function(self, key)
        local db = ProcessSavedVariables()
        return db[key]
    end,
})

---@type MiniLootNSSettingsOptions
local remixDbProxy = setmetatable({}, {
    __index = function(self, key)
        local _, remixDb = ProcessSavedVariables()
        return remixDb[key]
    end,
})

---@param db MiniLootNSSettingsOptions
---@param key string
local function CanUseRemixDB(db, key)
    if key == "EnableRemixMode" or db.EnableRemixMode == false then
        return false
    end
    local timerunningSeasonID = PlayerGetTimerunningSeasonID and PlayerGetTimerunningSeasonID()
    return timerunningSeasonID and timerunningSeasonID > 0
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

local function GetChatFrame()
    local chatName = flexDbProxy.ChatFrame
    local chatFrame = _G[chatName] ---@type MiniLootChatFramePolyfill
    return chatFrame
end

---@class MiniLootNSSettings
ns.Settings = {
    db = flexDbProxy,
    DefaultOptions = DefaultOptions,
    GetChatFrame = GetChatFrame,
}
