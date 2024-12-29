local ns = select(2, ...) ---@class MiniLootNS

local addOnName = ... ---@type string

local db = ns.Settings.db
local GetChatFrame = ns.Settings.GetChatFrame
local EventHandlers = ns.Reporting.EventHandlers
local ProcessChatEvent = ns.Reporting.ProcessChatEvent
local RegisterEvents = ns.Reporting.RegisterEvents
local UnregisterEvents = ns.Reporting.UnregisterEvents
local RegisterChatEvents = ns.Reporting.RegisterChatEvents
local UnregisterChatEvents = ns.Reporting.UnregisterChatEvents
local CreateOutputHandler = ns.Output.CreateOutputHandler
local GetChatFrames = ns.Utils.GetChatFrames
local EnableHyperlinks = ns.Tooltip.EnableHyperlinks
local DisableHyperlinks = ns.Tooltip.DisableHyperlinks
local SetupUI = ns.UI.SetupUI

---@class ScrollingMessageFrame

---@class ScrollingMessageFramePolyfill : MessageFrame, ScrollingMessageFrame
---@field public name string @The name of the chat frame as shown on its tab.
---@field public SetMaxLines fun(self: ScrollingMessageFramePolyfill, count: number)
---@field public SetInsertMode fun(self: ScrollingMessageFramePolyfill, mode: number)

---@class MiniLootChatFramePolyfill : ScrollingMessageFramePolyfill

---@alias MiniLootNSEventCallbackResult fun(event: WowEvent, ...: any): result: MiniLootMessageFormatSimpleParserResults?, message: MiniLootMessage?, hideChatIgnoreResult: boolean?

---@alias MiniLootNSEventChatEventCallback fun(chatFrame: MiniLootChatFramePolyfill, event: WowEvent, ...: any): filter: boolean?, ...

---@class MiniLootNSEventFrame : Frame
---@field public isLoaded boolean
---@field public isEnabled? boolean
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
    end
    if not self.isLoaded then
        return
    end
    local eventHandler = EventHandlers[event]
    if not eventHandler then
        return
    end
    local result, message, hideChatIgnoreResult = eventHandler(event, ...)
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
end

function frame:Enable()
    if self.isEnabled then
        return
    end
    self.isEnabled = true
    RegisterEvents(frame)
    RegisterChatEvents(OnChatEvent)
end

function frame:Disable()
    if self.isEnabled == false then
        return
    end
    self.isEnabled = false
    UnregisterEvents(frame)
    UnregisterChatEvents(OnChatEvent)
end

---@param forceUpdate? boolean
function frame:UpdateState(forceUpdate)
    if forceUpdate then
        self.isEnabled = nil
    end
    if db.Enabled then
        self:Enable()
    else
        self:Disable()
    end
    ---@diagnostic disable-next-line: assign-type-mismatch
    -- local previewChatFrame = self.Panel.PreviewChatFrame ---@type MiniLootChatFramePolyfill
    for _, chatFrame in ipairs(GetChatFrames()) do
        if db.Enabled and db.EnableTooltips then
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
