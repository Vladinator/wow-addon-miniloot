local ns = select(2, ...) ---@class MiniLootNS

local addOnName = ... ---@type string

local ProcessSavedVariables = ns.Settings.ProcessSavedVariables
local ProcessChatEvent = ns.Reporting.ProcessChatEvent
local EventHandler = ns.Reporting.EventHandler
local RegisterChatEvents = ns.Reporting.RegisterChatEvents
local UnregisterChatEvents = ns.Reporting.UnregisterChatEvents
local CreateOutputHandler = ns.Output.CreateOutputHandler

---@alias MiniLootChatFramePolyfill MessageFrame

---@alias MiniLootNSEventCallback fun(self: MiniLootNSEventFrame, event: WowEvent, ...: any)

---@alias MiniLootNSEventCallbackResult fun(self: MiniLootNSEventFrame, event: WowEvent, ...: any): result: MiniLootMessageFormatSimpleParserResult?, message: MiniLootMessage?, hideChatIgnoreResult: boolean?

---@alias MiniLootNSEventChatEventCallback fun(chatFrame: MiniLootChatFramePolyfill, event: WowEvent, ...: any): filter: boolean?, ...

---@class MiniLootNSEventFrame : Frame
---@field public db MiniLootNSSettingsOptions
---@field public isEnabled boolean
---@field public OnChatEvent MiniLootNSEventChatEventCallback

---@class MiniLootNSEventFrame
local frame = CreateFrame("Frame")

local output = CreateOutputHandler(frame)

---@type MiniLootNSEventChatEventCallback
local function OnChatEvent(chatFrame, event, ...)
    if not frame:IsChatFrame(chatFrame) then
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

function frame:GetChatFrame()
    local chatName = self.db.ChatFrame
    local chatFrame = _G[chatName] ---@type MiniLootChatFramePolyfill
    return chatFrame
end

---@param otherFrame MiniLootChatFramePolyfill
function frame:IsChatFrame(otherFrame)
    return self:GetChatFrame() == otherFrame
end

---@param event WowEvent
---@param ... any
function frame:OnEvent(event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == addOnName then
            self:Init()
        end
    end
    if not self.db then
        return
    end
    EventHandler(self, event, ...)
end

function frame:Enable()
    if self.isEnabled then
        return
    end
    self.isEnabled = true
    RegisterChatEvents(OnChatEvent)
end

function frame:Disable()
    if not self.isEnabled then
        return
    end
    self.isEnabled = false
    UnregisterChatEvents(OnChatEvent)
end

function frame:Init()
    if not self.db then
        self.db = ProcessSavedVariables()
    end
    if self.db.Enabled then
        self:Enable()
    end
end

frame:SetScript("OnEvent", frame.OnEvent)
frame:RegisterEvent("ADDON_LOADED")
