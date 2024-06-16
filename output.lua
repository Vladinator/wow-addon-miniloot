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

---@param frame MiniLootNSEventFrame
function MiniLootNSOutputHandler:OnLoad(frame)
    self.frame = frame
    self.buffer = CreateBuffer()
    self.lastAdd = 0
    self.lastOutput = 0
    self.prevInCombat = nil ---@type boolean?
    self.inCombat = nil ---@type boolean?
    self.timer = nil ---@type cbObject?
    self.timerOnTick = function()
        if not db.DebounceInCombat then
            self.prevInCombat = self.inCombat
            self.inCombat = InCombatLockdown()
            if self.inCombat then
                return
            end
            if self.prevInCombat then
                self:OnAdd()
                return
            end
        end
        if self.timer then
            self.timer:Cancel()
            self.timer = nil
        end
        self:Flush()
        self.lastOutput = GetTime()
    end
end

function MiniLootNSOutputHandler:OnAdd()
    self.lastAdd = GetTime()
    if self.timer then
        self.timer:Cancel()
    end
    self.timer = C_Timer.NewTimer(db.Debounce, self.timerOnTick)
end

---@param flushGroup? MiniLootMessageGroup
function MiniLootNSOutputHandler:Flush(flushGroup)
    local buffer = self.buffer
    if buffer:IsEmpty() then
        return
    end
    local chatFrame = GetChatFrame()
    local lines = {} ---@type string[]
    local groups = buffer:GroupResults()
    for _, group in ipairs(groups) do
        if not flushGroup or group.name == flushGroup then
            local itemLines = Format(group.name, group.results)
            if itemLines then
                local lineType = type(itemLines)
                if lineType == "table" then
                    TableCombine(lines, itemLines)
                elseif lineType == "string" then
                    lines[#lines + 1] = itemLines
                else
                    lines[#lines + 1] = tostring(itemLines)
                end
            end
        end
    end
    for _, line in ipairs(lines) do
        chatFrame:AddMessage(line, 1, 1, 0)
    end
    if flushGroup then
        buffer:ClearGroup(flushGroup)
    else
        buffer:Clear()
    end
end

---@param item MiniLootBufferItem
function MiniLootNSOutputHandler:Add(item)
    self.buffer:Add(item)
    if db.Debounce == 0 then
        self:Flush()
        return
    end
    local group = item.message.group
    local debounce = db.DebounceGroups[group]
    if debounce == 0 then
        self:Flush(group)
        return
    end
    self:OnAdd()
end

---@param frame MiniLootNSEventFrame
function MiniLootNSOutputHandler:New(frame)
    local handler = TableCopy(MiniLootNSOutputHandler) ---@type MiniLootNSOutputHandler
    handler:OnLoad(frame)
    return handler
end

---@param frame MiniLootNSEventFrame
local function CreateOutputHandler(frame)
    return MiniLootNSOutputHandler:New(frame)
end

---@class MiniLootNSOutput
ns.Output = {
    CreateBuffer = CreateBuffer,
    CreateOutputHandler = CreateOutputHandler,
}
