local ns = select(2, ...) ---@class MiniLootNS

local db = ns.Settings.db
local MiniLootMessageGroup = ns.Messages.MiniLootMessageGroup
local MessagesCollection = ns.Messages.MessagesCollection
local ProcessChatMessage = ns.Messages.ProcessChatMessage
local EvaluateFilters = ns.Filters.EvaluateFilters
local TableContains = ns.Utils.TableContains

---@type MiniLootNSEventCallbackResult
local ProcessChatEvent

---@type table<WowEvent, MiniLootNSEventCallbackResult>
local EventHandlers = {
    QUEST_TURNED_IN = function(event, ...)
        ---@type number?, number?, number?
        local questID, xp, money = ...
        if xp and xp > 0 then
            return ProcessChatEvent("CHAT_MSG_COMBAT_XP_GAIN", format(COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED, xp))
        end
        if money and money > 0 then
            return ProcessChatEvent("CHAT_MSG_MONEY", format(YOU_LOOT_MONEY, C_CurrencyInfo.GetCoinText(money)))
        end
    end,
}

local function GetMessageEvents()
    local events = {} ---@type WowEvent[]
    local numEvents = #events
    for _, message in ipairs(MessagesCollection) do
        for _, event in ipairs(message.events) do
            if not TableContains(events, event) then
                numEvents = numEvents +  1
                events[numEvents] = event
            end
        end
    end
    return events
end

local MessageEvents = GetMessageEvents()

---@param frame MiniLootNSEventFrame
local function RegisterEvents(frame)
    for event, _ in pairs(EventHandlers) do
        pcall(frame.RegisterEvent, frame, event)
    end
end

---@param frame MiniLootNSEventFrame
local function UnregisterEvents(frame)
    for event, _ in pairs(EventHandlers) do
        pcall(frame.UnregisterEvent, frame, event)
    end
end

---@param onChatEvent MiniLootNSEventChatEventCallback
local function RegisterChatEvents(onChatEvent)
    local numEvents = #MessageEvents
    for i = numEvents, 1, -1 do
        local event = MessageEvents[i]
        local success = pcall(ChatFrame_AddMessageEventFilter, event, onChatEvent)
        if not success then
            table.remove(MessageEvents, i)
        end
    end
end

---@param onChatEvent MiniLootNSEventChatEventCallback
local function UnregisterChatEvents(onChatEvent)
    local numEvents = #MessageEvents
    for i = numEvents, 1, -1 do
        local event = MessageEvents[i]
        local success = pcall(ChatFrame_RemoveMessageEventFilter, event, onChatEvent)
        if not success then
            table.remove(MessageEvents, i)
        end
    end
end

---@type MiniLootNSEventCallbackResult
function ProcessChatEvent(event, ...)
    local result, message = ProcessChatMessage(event, ...)
    if not result then
        return
    end
    local group = message.group
    if db.EnabledGroups[group] == false then
        return
    end
    if db.IgnoredGroups[group] or message.group == MiniLootMessageGroup.Ignore then
        return result, message, true
    end
    local isFiltered = EvaluateFilters(db.Filters, result, message)
    if isFiltered then
        return result, message, true
    end
    return result, message
end

---@class MiniLootNSReporting
ns.Reporting = {
    EventHandlers = EventHandlers,
    MessageEvents = MessageEvents,
    RegisterEvents = RegisterEvents,
    UnregisterEvents = UnregisterEvents,
    RegisterChatEvents = RegisterChatEvents,
    UnregisterChatEvents = UnregisterChatEvents,
    ProcessChatEvent = ProcessChatEvent,
}
