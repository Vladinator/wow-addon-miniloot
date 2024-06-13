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

---@alias MiniLootChatFramePolyfill MessageFrame

---@alias MiniLootNSEventCallback fun(self: MiniLootNSEventFrame, event: WowEvent, ...: any)

---@alias MiniLootNSEventCallbackResult fun(self: MiniLootNSEventFrame, event: WowEvent, ...: any): result: MiniLootMessageFormatSimpleParserResult?, message: MiniLootMessage?, hideChatIgnoreResult: boolean?

---@alias MiniLootNSEventChatEventCallback fun(chatFrame: MiniLootChatFramePolyfill, event: WowEvent, ...: any): filter: boolean?, ...

---@class MiniLootNSEventFrame : Frame
---@field public isLoaded boolean
---@field public isEnabled boolean
---@field public OnChatEvent MiniLootNSEventChatEventCallback

---@class MiniLootNSEventFrame
local frame = CreateFrame("Frame")

local output = CreateOutputHandler(frame)

---@type MiniLootNSEventChatEventCallback
local function OnChatEvent(chatFrame, event, ...)
    if chatFrame ~= GetChatFrame() then
        return false, ...
    end
    local result, message, hideChatIgnoreResult = ProcessChatEvent(frame, event, ...)
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
            self:UpdateState()
        end
    end
    if not self.isLoaded then
        return
    end
    local eventHandler = EventHandlers[event]
    if not eventHandler then
        return
    end
    local result, message, hideChatIgnoreResult = eventHandler(self, event, ...)
    if hideChatIgnoreResult then
        return
    end
    if result and message then
        output:Add({ result = result, message = message })
    end
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
    if not self.isEnabled then
        return
    end
    self.isEnabled = false
    UnregisterEvents(frame)
    UnregisterChatEvents(OnChatEvent)
end

function frame:UpdateState()
    if db.Enabled then
        self:Enable()
    else
        self:Disable()
    end
    for _, chatFrame in ipairs(GetChatFrames()) do
        if db.EnableTooltips then
            EnableHyperlinks(chatFrame)
        else
            DisableHyperlinks(chatFrame)
        end
    end
end

frame:SetScript("OnEvent", frame.OnEvent)
frame:RegisterEvent("ADDON_LOADED")
