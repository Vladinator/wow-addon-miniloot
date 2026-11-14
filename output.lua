local ns = select(2, ...) ---@class MiniLootNS

local db = ns.Settings.db
local GetChatFrame = ns.Settings.GetChatFrame
local TableCopy = ns.Utils.TableCopy
local TableCombine = ns.Utils.TableCombine
local TableGroup = ns.Utils.TableGroup
local TableMap = ns.Utils.TableMap
local Format = ns.Formatter.Format

---@class MiniLootBufferItem
---@field public message MiniLootMessage
---@field public result MiniLootMessageFormatSimpleParserResults

---@class MiniLootBufferItemGroup
---@field public name MiniLootMessageGroup
---@field public results MiniLootMessageFormatSimpleParserResults[]

---@class MiniLootNSBuffer
local MiniLootNSBuffer = {}

function MiniLootNSBuffer:OnLoad()
    self.buffer = {} ---@type MiniLootBufferItem[]
    self.length = 0
end

function MiniLootNSBuffer:Length()
    return self.length
end

function MiniLootNSBuffer:IsEmpty()
    return self.length == 0
end

function MiniLootNSBuffer:Clear()
    table.wipe(self.buffer)
    self.length = 0
end

---@param group MiniLootMessageGroup
function MiniLootNSBuffer:ClearGroup(group)
    local length = self.length
    for i = #self.buffer, 1, -1 do
        local item = self.buffer[i]
        if item.message.group == group then
            length = length - 1
            table.remove(self.buffer, i)
        end
    end
    self.length = length
end

function MiniLootNSBuffer:GroupResults()
    local groups, keys = TableGroup(
        self.buffer,
        function(item)
            return item.message.group
        end
    )
    local results = {} ---@type MiniLootBufferItemGroup[]
    local index = 0
    ---@param item MiniLootBufferItem
    local function map(item)
        return item.result
    end
    for i = 1, #groups do
        local k = keys[i]
        local v = groups[i]
        v = TableMap(v, map)
        index = index + 1
        results[index] = { name = k, results = v }
    end
    return results
end

---@param index number
---@return MiniLootBufferItem item
function MiniLootNSBuffer:Get(index)
    return self.buffer[index]
end

---@param item MiniLootBufferItem
---@return number index
function MiniLootNSBuffer:Add(item)
    local index = self.length + 1
    self.length = index
    self.buffer[index] = item
    return index
end

function MiniLootNSBuffer:New()
    local buffer = TableCopy(MiniLootNSBuffer) ---@type MiniLootNSBuffer
    buffer:OnLoad()
    return buffer
end

local function CreateBuffer()
    return MiniLootNSBuffer:New()
end

---@class MiniLootNSOutputHandler
local MiniLootNSOutputHandler = {}

local SharedTimerKey = "*"
local CombatPollInterval = 0.5

---@param group MiniLootMessageGroup
---@return string timerKey, number debounce
local function GetGroupDebounce(group)
    local debounce = db.Debounce
    local groupDebounce = db.DebounceGroups[group]
    if groupDebounce ~= nil and groupDebounce ~= debounce then
        return group, groupDebounce
    end
    return SharedTimerKey, debounce
end

---@param group MiniLootMessageGroup
local function IsSharedDebounceGroup(group)
    return GetGroupDebounce(group) == SharedTimerKey
end

---@param chatFrame? MiniLootChatTarget
function MiniLootNSOutputHandler:OnLoad(chatFrame)
    self.chatFrame = chatFrame
    self.buffer = CreateBuffer()
    self.timers = {} ---@type table<string, FunctionContainer?>
    self.heldByCombat = {} ---@type table<string, boolean?>
end

---@param timerKey string
---@param delay number
function MiniLootNSOutputHandler:Schedule(timerKey, delay)
    local timer = self.timers[timerKey]
    if timer then
        timer:Cancel()
    end
    self.timers[timerKey] = C_Timer.NewTimer(delay, function() self:OnTimer(timerKey) end)
end

---@param timerKey string
function MiniLootNSOutputHandler:OnTimer(timerKey)
    self.timers[timerKey] = nil
    if not db.DebounceInCombat then
        if InCombatLockdown() then
            self.heldByCombat[timerKey] = true
            self:Schedule(timerKey, CombatPollInterval)
            return
        end
        if self.heldByCombat[timerKey] then
            -- combat has ended so the countdown starts over
            self.heldByCombat[timerKey] = nil
            local debounce = db.Debounce
            if timerKey ~= SharedTimerKey then
                debounce = db.DebounceGroups[timerKey] or debounce
            end
            if debounce > 0 then
                self:Schedule(timerKey, debounce)
                return
            end
        end
    end
    self.heldByCombat[timerKey] = nil
    self:FlushTimer(timerKey)
end

---@param timerKey string
function MiniLootNSOutputHandler:FlushTimer(timerKey)
    if timerKey == SharedTimerKey then
        self:Flush(nil, IsSharedDebounceGroup)
    else
        self:Flush(timerKey)
    end
end

---@param flushGroup? MiniLootMessageGroup Only output this group.
---@param predicate? fun(group: MiniLootMessageGroup): boolean? Only output the groups that pass.
function MiniLootNSOutputHandler:Flush(flushGroup, predicate)
    local buffer = self.buffer
    if buffer:IsEmpty() then
        return
    end
    local chatFrame = self.chatFrame or GetChatFrame()
    local lines = {} ---@type string[]
    local flushedGroups = {} ---@type MiniLootMessageGroup[]
    local groups = buffer:GroupResults()
    for _, group in ipairs(groups) do
        if (not flushGroup or group.name == flushGroup) and (not predicate or predicate(group.name)) then
            flushedGroups[#flushedGroups + 1] = group.name
            local itemLines = Format(group.name, group.results)
            if itemLines then
                local lineType = type(itemLines)
                if lineType == "table" then
                    TableCombine(lines, itemLines --[=[@as string[]]=])
                elseif lineType == "string" then
                    lines[#lines + 1] = itemLines --[=[@as string]=]
                else
                    lines[#lines + 1] = tostring(itemLines)
                end
            end
        end
    end
    for _, line in ipairs(lines) do
        chatFrame:AddMessage(line, 1, 1, 0)
    end
    if flushGroup or predicate then
        for _, group in ipairs(flushedGroups) do
            buffer:ClearGroup(group)
        end
    else
        buffer:Clear()
    end
end

---@param item MiniLootBufferItem
function MiniLootNSOutputHandler:Add(item)
    self.buffer:Add(item)
    local timerKey, debounce = GetGroupDebounce(item.message.group)
    if debounce <= 0 then
        self:FlushTimer(timerKey)
        return
    end
    self:Schedule(timerKey, debounce)
end

---@param chatFrame? MiniLootChatTarget
function MiniLootNSOutputHandler:New(chatFrame)
    local handler = TableCopy(MiniLootNSOutputHandler) ---@type MiniLootNSOutputHandler
    handler:OnLoad(chatFrame)
    return handler
end

---@param chatFrame? MiniLootChatTarget
local function CreateOutputHandler(chatFrame)
    return MiniLootNSOutputHandler:New(chatFrame)
end

---@class MiniLootNSOutput
ns.Output = {
    CreateBuffer = CreateBuffer,
    CreateOutputHandler = CreateOutputHandler,
}
