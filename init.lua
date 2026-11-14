local ns = select(2, ...) ---@class MiniLootNS

local addOnName = ... ---@type string

local issecretvalue = ns.Utils.issecretvalue
local db = ns.Settings.db
local GetChatFrame = ns.Settings.GetChatFrame
local EventHandlers = ns.Reporting.EventHandlers
local IsChatEventRelevant = ns.Messages.IsChatEventRelevant
local ProcessChatEvent = ns.Reporting.ProcessChatEvent
local RegisterEvents = ns.Reporting.RegisterEvents
local UnregisterEvents = ns.Reporting.UnregisterEvents
local RegisterChatEvents = ns.Reporting.RegisterChatEvents
local UnregisterChatEvents = ns.Reporting.UnregisterChatEvents
local RegisterFrameChatEvents = ns.Reporting.RegisterFrameChatEvents
local UnregisterFrameChatEvents = ns.Reporting.UnregisterFrameChatEvents
local CreateOutputHandler = ns.Output.CreateOutputHandler
local ChattynatorUtil = ns.Utils.ChattynatorUtil
local GetChatFrames = ns.Utils.GetChatFrames
local EnableHyperlinks = ns.Tooltip.EnableHyperlinks
local DisableHyperlinks = ns.Tooltip.DisableHyperlinks
local SetupUI = ns.UI.SetupUI

---@class ScrollingMessageFrame

---@class ScrollingMessageFramePolyfill : MessageFrame, ScrollingMessageFrame
---@field public name string @The name of the chat frame as shown on its tab.
---@field public SetMaxLines fun(self: ScrollingMessageFramePolyfill, count: number)
---@field public SetInsertMode fun(self: ScrollingMessageFramePolyfill, mode: number)

-- The target frame must support the following method for us to be able to add messages to it.
---@class MiniLootChatTarget
---@field public AddMessage fun(self: any, text: string, r?: number, g?: number, b?: number, ...: any)

---@class MiniLootChatFramePolyfill : ScrollingMessageFramePolyfill, MiniLootChatTarget, ChattynatorChatFrame

---@alias MiniLootNSEventCallbackResult fun(event: WowEvent, ...: any): result: MiniLootMessageFormatSimpleParserResults?, message: MiniLootMessage?, hideChatIgnoreResult: boolean?

---@alias MiniLootNSEventChatEventCallback fun(chatFrame: MiniLootChatFramePolyfill, event: WowEvent, ...: any): filter: boolean?, ...

---@class MiniLootNSEventFrame : Frame
---@field public isLoaded boolean
---@field public isEnabled? boolean
---@field public useFrameChatEvents? boolean
---@field public OnChatEvent MiniLootNSEventChatEventCallback

---@class MiniLootNSEventFrame
local frame = CreateFrame("Frame")

local output = CreateOutputHandler()

---@type MiniLootNSEventChatEventCallback
local function OnChatEvent(chatFrame, event, ...)
    if chatFrame ~= GetChatFrame() then
        return false, ...
    end
    local result, message, hideChatIgnoreResult = ProcessChatEvent(event, ...)
    if hideChatIgnoreResult then
        return true
    end
    if result and message then
        output:Add({ result = result, message = message })
        return true
    end
    return false, ...
end

-- This updates the filters when Chattynator renders its tabs.
---@type table<WowEvent, table<string, boolean>|false>
local chattynatorFilterCache = {}
local chattynatorFilterCacheSize = 0
local chattynatorFilterCacheMaxSize = 4096

local function ResetChattynatorFilterCache()
    table.wipe(chattynatorFilterCache)
    chattynatorFilterCacheSize = 0
end

-- Similar to regular chat event filters, just adapted for Chattynator.
---@type ChattynatorChatFilter
local function OnChattynatorChatEventFilter(data)
    local typeInfo = data.typeInfo
    local event = typeInfo and typeInfo.event
    local text = data.text
    if type(event) ~= "string" or type(text) ~= "string" or issecretvalue(text) then
        return true
    end
    local cache = chattynatorFilterCache[event]
    if cache == nil then
        cache = IsChatEventRelevant(event) and {} or false
        chattynatorFilterCache[event] = cache
    end
    if not cache then
        return true
    end
    local showMessage = cache[text]
    if showMessage == nil then
        if chattynatorFilterCacheSize >= chattynatorFilterCacheMaxSize then
            ResetChattynatorFilterCache()
            cache = {}
            chattynatorFilterCache[event] = cache
        end
        local result = ProcessChatEvent(event, text)
        showMessage = not result
        cache[text] = showMessage
        chattynatorFilterCacheSize = chattynatorFilterCacheSize + 1
    end
    return showMessage
end

local chattynatorFilterWindowIndex ---@type number?
local chattynatorFilterTabIndex ---@type number?

---Makes sure the filter is only applied to the window and tab that is the active chat frame.
---@param forceUpdate? boolean Re-applies the filter so that Chattynator evaluates the messages again.
function frame:UpdateChattynatorFilter(forceUpdate)
    local windowIndex ---@type number?
    local tabIndex ---@type number?
    if self.isEnabled and ChattynatorUtil:IsLoaded() then
        windowIndex, tabIndex = ChattynatorUtil:ResolveTarget(db.ChatFrame)
    end
    if not forceUpdate and chattynatorFilterWindowIndex == windowIndex and chattynatorFilterTabIndex == tabIndex then
        return
    end
    ResetChattynatorFilterCache()
    if chattynatorFilterWindowIndex and chattynatorFilterTabIndex then
        ChattynatorUtil:RemoveFilter(OnChattynatorChatEventFilter, chattynatorFilterWindowIndex, chattynatorFilterTabIndex)
    end
    chattynatorFilterWindowIndex, chattynatorFilterTabIndex = windowIndex, tabIndex
    if windowIndex and tabIndex then
        ChattynatorUtil:AddFilter(OnChattynatorChatEventFilter, windowIndex, tabIndex)
    end
end

---@param event WowEvent
---@param ... any
function frame:OnEvent(event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == addOnName then
            self.isLoaded = true
            self.Panel = SetupUI(self)
            self:UpdateState()
            ns.Links:Init()
        end
    elseif event == "PLAYER_LOGIN" then
        if self.isLoaded then
            self:UpdateState()
        end
        return
    end
    if not self.isLoaded then
        return
    end
    local result, message, hideChatIgnoreResult ---@type MiniLootMessageFormatSimpleParserResults?, MiniLootMessage?, boolean?
    local eventHandler = EventHandlers[event]
    if eventHandler then
        result, message, hideChatIgnoreResult = eventHandler(event, ...)
    elseif self.useFrameChatEvents and IsChatEventRelevant(event) then
        result, message, hideChatIgnoreResult = ProcessChatEvent(event, ...)
    end
    if hideChatIgnoreResult then
        return
    end
    if result and message then
        output:Add({ result = result, message = message })
    end
end

---@param key string
---@param value any
---@param oldValue any
function frame:OnSettingsChanged(key, value, oldValue)
    frame:UpdateState()
    frame:UpdateChattynatorFilter(true)
end

function frame:Enable()
    if self.isEnabled then
        return
    end
    self.isEnabled = true
    RegisterEvents(frame)
    if ChattynatorUtil:IsLoaded() then
        self.useFrameChatEvents = true
        RegisterFrameChatEvents(frame)
    else
        RegisterChatEvents(OnChatEvent)
    end
end

function frame:Disable()
    if self.isEnabled == false then
        return
    end
    self.isEnabled = false
    UnregisterEvents(frame)
    if self.useFrameChatEvents then
        self.useFrameChatEvents = false
        UnregisterFrameChatEvents(frame)
    else
        UnregisterChatEvents(OnChatEvent)
    end
end

---@param forceUpdate? boolean
function frame:UpdateState(forceUpdate)
    if forceUpdate then
        self:Disable()
    end
    if db.Enabled then
        self:Enable()
    else
        self:Disable()
    end
    self:UpdateChattynatorFilter(forceUpdate)
    local enableHyperlinks = db.Enabled and db.EnableTooltips
    local chatFrames = GetChatFrames()
    chatFrames[#chatFrames + 1] = ChattynatorUtil:GetChattynatorHandler()
    -- ---@diagnostic expect-next-line: assign-type-mismatch
    -- local previewChatFrame = self.Panel.PreviewChatFrame ---@type MiniLootChatFramePolyfill
    for _, chatFrame in ipairs(chatFrames) do
        if enableHyperlinks then
            EnableHyperlinks(chatFrame)
            -- EnableHyperlinks(previewChatFrame)
        else
            DisableHyperlinks(chatFrame)
            -- DisableHyperlinks(previewChatFrame)
        end
    end
end

frame:SetScript("OnEvent", frame.OnEvent)
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
