local ns = select(2, ...) ---@class MiniLootNS

local addOnName = ... ---@type string

local L = ns.Locale

---@class MiniLootInterfacePanelWidget : Frame
local WidgetMixin = {}

function WidgetMixin:CreateWidget()
    local widget = CreateFrame("Frame") ---@class MiniLootInterfacePanelWidget
    Mixin(widget, WidgetMixin)
    return widget
end

---@class MiniLootInterfacePanel : Frame
---@field public name string
---@field public widgets MiniLootInterfacePanelWidget[]

---@class MiniLootInterfacePanel
local Panel

local function CreateInterfacePanel()
    Panel = CreateFrame("Frame", nil, InterfaceOptionsFramePanelContainer) ---@class MiniLootInterfacePanel
    Panel:Hide()
    Panel:SetAllPoints()
    Panel.name = addOnName
    Panel.Title = Panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    Panel.Title:SetPoint("TOPLEFT", 16, -16)
    Panel.Title:SetText(addOnName)
    Panel.Description = Panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    Panel.Description:SetPoint("TOPLEFT", Panel.Title, "BOTTOMLEFT", 0, -8)
    Panel.Description:SetPoint("RIGHT", -32, 0)
    Panel.Description:SetText(L.PANEL_DESCRIPTION)
    Panel.Description:SetMaxLines(3)
    Panel.Description:SetNonSpaceWrap(true)
    Panel.Description:SetJustifyH("LEFT")
    Panel.Description:SetJustifyV("TOP")
    return Panel
end

local function GetInterfacePanel()
    if Panel then
        return Panel
    end
    Panel = CreateInterfacePanel()
    return Panel
end

---@class MiniLootNSUI
ns.UI = {
    GetInterfacePanel = GetInterfacePanel,
}
