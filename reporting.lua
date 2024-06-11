local ns = select(2, ...) ---@class MiniLootNS

local MessagesCollection = ns.Messages.MessagesCollection
local ProcessChatMessage = ns.Messages.ProcessChatMessage
local TableContains = ns.Utils.TableContains
local TableCombine = ns.Utils.TableCombine
local TableKeys = ns.Utils.TableKeys

---@type MiniLootNSEventCallbackResult
local ProcessChatEvent

---@type table<WowEvent, MiniLootNSEventCallbackResult>
local EventHandlers = {
    QUEST_TURNED_IN = function(frame, _, ...)
        ---@type _, number, number?
        local _, xp, money = ...
        if xp and xp > 0 then
            return ProcessChatEvent(frame, "CHAT_MSG_COMBAT_XP_GAIN", format(COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED, xp))
        end
        if money and money > 0 then
            return ProcessChatEvent(frame, "CHAT_MSG_MONEY", format(YOU_LOOT_MONEY, C_CurrencyInfo.GetCoinText(money)))
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
TableCombine(MessageEvents, TableKeys(EventHandlers))

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

---@param frame MiniLootNSEventFrame
---@param event WowEvent
---@param ... any
local function EventHandler(frame, event, ...)
    if not frame.isEnabled then
        return
    end
    local eventHandler = EventHandlers[event]
    if eventHandler then
        eventHandler(frame, event, ...)
    end
end

---@type MiniLootNSEventCallbackResult
function ProcessChatEvent(frame, event, ...)
    local result, message = ProcessChatMessage(event, ...)
    if not result then
        return
    end
    local group = message.group
    local db = frame.db
    if not db.EnabledGroups[group] then
        return
    end
    if db.IgnoredGroups[group] then
        return result, message, true
    end
    return result, message
end

---@class MiniLootNSReporting
ns.Reporting = {
    ExtraEvents = EventHandlers,
    MessageEvents = MessageEvents,
    RegisterChatEvents = RegisterChatEvents,
    UnregisterChatEvents = UnregisterChatEvents,
    EventHandler = EventHandler,
    ProcessChatEvent = ProcessChatEvent,
}
