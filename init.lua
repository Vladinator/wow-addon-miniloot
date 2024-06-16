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
local GetCurrencyLink = ns.Utils.GetCurrencyLink
local GetUnitMawPowerInfo = ns.Utils.GetUnitMawPowerInfo
local GetHyperlinkTooltipLines = ns.Utils.GetHyperlinkTooltipLines
local EnableHyperlinks = ns.Tooltip.EnableHyperlinks
local DisableHyperlinks = ns.Tooltip.DisableHyperlinks
local SetupUI = ns.UI.SetupUI

---@class MiniLootChatFramePolyfill : MessageFrame

---@alias MiniLootNSEventCallback fun(self: MiniLootNSEventFrame, event: WowEvent, ...: any)

---@alias MiniLootNSEventCallbackResult fun(self: MiniLootNSEventFrame, event: WowEvent, ...: any): result: MiniLootMessageFormatSimpleParserResults?, message: MiniLootMessage?, hideChatIgnoreResult: boolean?

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

---@type fun()
local HookSetItemRef do

    ---@alias SetItemRefPolyfill fun(link: string, text: string, button: MouseButton, chatFrame: MiniLootChatFramePolyfill, ...: any)

    ---@param ... any
    local function tonumberall(...)
        local temp = {...} ---@type number[]
        for i = 1, #temp do
            local v = temp[i]
            local t = type(v)
            if t ~= "number" then
                temp[i] = tonumber(v)
            end
        end
        return unpack(temp)
    end

    local QualityColorPattern = "|cff([a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9])|H"
    local LinkNamePattern = "|h(.-)|h"

    ---@param link string
    ---@param oldText? string
    ---@param newText? string
    ---@param quality? string `ffRRGGBB` or `RRGGBB`
    ---@return string fixedLink
    local function FixHyperlink(link, oldText, newText, quality)
        oldText = oldText or newText or ""
        newText = newText or oldText or ""
        local color = quality or oldText:match(QualityColorPattern) or newText:match(QualityColorPattern)
        local colorPrefix = color:len() == 6 and "ff" or ""
        local text = newText:match(LinkNamePattern) or oldText:match(LinkNamePattern)
        return format("|c%s%s|H%s|h%s|h|r", colorPrefix, color, link, text)
    end

    ---@param link string
    ---@return string? link
    local function GetHyperlinkByLink(link)
        for i = Enum.BagIndex.Backpack, Constants.InventoryConstants.NumBagSlots do
            local count = C_Container.GetContainerNumSlots(i)
            for j = 1, count do
                local itemLink = C_Container.GetContainerItemLink(i, j)
                if itemLink and itemLink:find(link, nil, true) then
                    return itemLink
                end
            end
        end
    end

    local origSetItemRef ---@type SetItemRefPolyfill

    ---@type SetItemRefPolyfill
    local function customSetItemRef(link, text, button, chatFrame, ...)
        if not IsModifiedClick("CHATLINK") then
            return origSetItemRef(link, text, button, chatFrame, ...)
        end
        ---@type string, string
        local linkType, linkData = LinkUtil.SplitLinkData(link)
        ---@type string, string
        local arg1, arg2 = strsplit(":", linkData)
        if linkType == "garrfollower" then
            local num1, num2 = tonumberall(arg1, arg2)
            local realLink = C_Garrison.GetFollowerLinkByID(num1)
            local _, _, _, quality = C_Item.GetItemQualityColor(num2)
            text = FixHyperlink(link, text, realLink, quality)
        elseif linkType == "currency" then
            local num1, num2 = tonumberall(arg1, arg2)
            local realLink = GetCurrencyLink(num1, num2)
            if realLink then
                text = FixHyperlink(link, text, realLink)
            end
        elseif linkType == "battlepet" then
            local realLink = GetHyperlinkByLink(link)
            if realLink then
                text = FixHyperlink(link, text, realLink)
            end
        elseif linkType == "azessence" then
            link = text
        elseif linkType == "mawpower" then
            local _, _, realLink = GetUnitMawPowerInfo("player", link, true)
            if not realLink then
                local lines = GetHyperlinkTooltipLines(link)
                if lines and lines[1] then
                    local firstLine = lines[1]
                    realLink = format("|cff71d5ff|H%s|h[%s]|h|r", link, firstLine.leftText)
                end
            end
            if not realLink then
                return
            end
            text = FixHyperlink(link, text, realLink)
        end
        return origSetItemRef(link, text, button, chatFrame, ...)
    end

    function HookSetItemRef()
        if origSetItemRef then
            return
        end
        origSetItemRef = SetItemRef
        SetItemRef = customSetItemRef
    end

end

---@param event WowEvent
---@param ... any
function frame:OnEvent(event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == addOnName then
            self.isLoaded = true
            self:UpdateState()
            HookSetItemRef()
            SetupUI()
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
