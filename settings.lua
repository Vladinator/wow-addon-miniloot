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
---@field EnabledGroups table<MiniLootMessageGroup, boolean?>
---@field IgnoredGroups table<MiniLootMessageGroup, boolean?>
---@field ChatFrame MiniLootChatFrame

---@class MiniLootNSSettingsOptions
local DefaultOptions = {
    Enabled = true,
    EnabledGroups = {},
    IgnoredGroups = {},
    Debounce = 2,
    ChatFrame = MiniLootChatFrame.DEFAULT_CHAT_FRAME,
}

for _, v in pairs(MiniLootMessageGroup) do
    DefaultOptions.EnabledGroups[v] = true
    DefaultOptions.IgnoredGroups[v] = nil
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

---@return MiniLootNSSettingsOptions
local function ProcessSavedVariables()
    local db = _G.MiniLootDB2
    if type(db) ~= "table" then
        db = {}
        _G.MiniLootDB2 = db
    end
    if not getmetatable(db) then
        setmetatable(db, OptionsMetatable)
    end
    return db
end

ProcessSavedVariables()

---@class MiniLootNSSettings
ns.Settings = {
    DefaultOptions = DefaultOptions,
    ProcessSavedVariables = ProcessSavedVariables,
}
