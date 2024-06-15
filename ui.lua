local ns = select(2, ...) ---@class MiniLootNS

local addOnName = ... ---@type string

local L = ns.Locale

---@generic T
---@alias MiniLootInterfacePanelWidgetOnLoad fun(self: T, panel: MiniLootInterfacePanel, ...: any)

---@generic T
---@alias MiniLootInterfacePanelWidgetCreateWidget fun(self: T, panel: MiniLootInterfacePanel, ...: any): T

---@alias MiniLootInterfacePanelWidgetType
---|"None"
---|"CheckBox"

---@class MiniLootInterfacePanelOption
---@field public Type MiniLootInterfacePanelWidgetType
---@field public Label string

---@type MiniLootInterfacePanelOption[]
local Options = {
    -- {
    --     Type = "None",
    --     Label = "Test 1",
    -- },
    -- {
    --     Type = "CheckBox",
    --     Label = "Test 2",
    -- },
}

---@class MiniLootInterfacePanelWidget : Frame
---@field public Option MiniLootInterfacePanelOption
---@field public Type MiniLootInterfacePanelWidgetType
---@field public OnLoad MiniLootInterfacePanelWidgetOnLoad

---@class MiniLootInterfacePanelWidget
local MiniLootInterfacePanelWidget = {}

do

    MiniLootInterfacePanelWidget.Type = "None"

    ---@type MiniLootInterfacePanelWidgetOnLoad
    function MiniLootInterfacePanelWidget:OnLoad(panel, ...)
        panel.Widgets[#panel.Widgets + 1] = self
        self.Label = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightLeft")
        self.Label:SetAllPoints()
        self.Background = self:CreateTexture(nil, "BACKGROUND")
        self.Background:SetAllPoints()
        self.Background:SetColorTexture(random(50, 100)/100, random(50, 100)/100, random(50, 100)/100)
    end

    ---@type MiniLootInterfacePanelWidgetCreateWidget
    function MiniLootInterfacePanelWidget:CreateWidget(panel, ...)
        local widget = CreateFrame("Frame", nil, panel) ---@class MiniLootInterfacePanelWidget
        Mixin(widget, self)
        widget:OnLoad(panel, ...)
        return widget
    end

    function MiniLootInterfacePanelWidget:ReleaseWidget()
        self:Hide()
    end

    function MiniLootInterfacePanelWidget:Refresh()
        local option = self.Option
        self.Label:SetText(option.Label)
        self:Show()
    end

    ---@param option MiniLootInterfacePanelOption
    function MiniLootInterfacePanelWidget:SetOption(option)
        self.Option = option
        self:Refresh()
    end

end

---@class MiniLootInterfacePanelWidgetCheckBox : MiniLootInterfacePanelWidget, CheckButton
local MiniLootInterfacePanelWidgetCheckBox = Mixin({}, MiniLootInterfacePanelWidget)

do

    MiniLootInterfacePanelWidgetCheckBox.Type = "CheckBox"

    ---@type MiniLootInterfacePanelWidgetCreateWidget
    function MiniLootInterfacePanelWidgetCheckBox:CreateWidget(panel, ...)
        local widget = CreateFrame("CheckButton", nil, panel) ---@class MiniLootInterfacePanelWidgetCheckBox
        Mixin(widget, self)
        widget:OnLoad(panel, ...)
        return widget
    end

end

---@alias ObjectPoolPolyfillObj MiniLootInterfacePanelWidget

---@alias ObjectPoolPolyfillCreationFunc fun(pool: ObjectPoolPolyfill): ObjectPoolPolyfillObj

---@alias ObjectPoolPolyfillResetterFunc fun(pool: ObjectPoolPolyfill, obj: ObjectPoolPolyfillObj)

---@class ObjectPoolPolyfill
---@field public OnLoad fun(self: ObjectPoolPolyfill, creationFunc: ObjectPoolPolyfillCreationFunc, resetterFunc: ObjectPoolPolyfillResetterFunc)
---@field public Acquire fun(self: ObjectPoolPolyfill): obj: ObjectPoolPolyfillObj, isNew: boolean
---@field public Release fun(self: ObjectPoolPolyfill, obj: ObjectPoolPolyfillObj): boolean
---@field public ReleaseAll fun(self: ObjectPoolPolyfill)
---@field public SetResetDisallowedIfNew fun(self: ObjectPoolPolyfill, disallowed: boolean)
---@field public EnumerateActive fun(self: ObjectPoolPolyfill): fun(): ObjectPoolPolyfillObj
---@field public GetNextActive fun(self: ObjectPoolPolyfill, obj: ObjectPoolPolyfillObj): ObjectPoolPolyfillObj, true
---@field public GetNextInactive fun(self: ObjectPoolPolyfill, obj: ObjectPoolPolyfillObj): ObjectPoolPolyfillObj, false
---@field public IsActive fun(self: ObjectPoolPolyfill, obj: ObjectPoolPolyfillObj): boolean
---@field public GetNumActive fun(self: ObjectPoolPolyfill): number
---@field public EnumerateInactive fun(self: ObjectPoolPolyfill): fun(): number, ObjectPoolPolyfillObj

local CreateObjectPool = CreateObjectPool ---@type fun(creationFunc: ObjectPoolPolyfillCreationFunc, resetterFunc: ObjectPoolPolyfillResetterFunc): ObjectPoolPolyfill

---@class MiniLootInterfacePanel : Frame
---@field public name string
---@field public parent? Frame
---@field public OnCommit? fun() `okay`
---@field public OnDefault? fun() `default`
---@field public OnRefresh? fun() `refresh`
---@field public Widgets MiniLootInterfacePanelWidget[]
---@field public Options MiniLootInterfacePanelOption[]

---@class MiniLootInterfacePanel
local Panel

---@param self MiniLootInterfacePanel
local function PanelRefresh(self)
    self.WidgetPool:ReleaseAll()
    self.WidgetCheckBoxPool:ReleaseAll()
    local widget ---@type MiniLootInterfacePanelWidget?
    local prevWidget ---@type MiniLootInterfacePanelWidget?
    local maxWidth, maxHeight = self:GetSize()
    local widgetWidth = maxWidth - self.offsetX*2 -- 665-16*2 = 633
    local widgetHeight = maxHeight/20 -- 601/20 ~= 30
    for _, option in ipairs(Panel.Options) do
        if option.Type == "CheckBox" then
            ---@type MiniLootInterfacePanelWidgetCheckBox
            widget = self.WidgetCheckBoxPool:Acquire() ---@diagnostic disable-line: assign-type-mismatch
            widget:SetOption(option)
        else
            widget = self.WidgetPool:Acquire()
            widget:SetOption(option)
        end
        widget:SetSize(widgetWidth, widgetHeight)
        widget:SetPoint("TOPLEFT", prevWidget or self.Description, "BOTTOMLEFT", 0, -8)
        prevWidget = widget
    end
end

local function CreateInterfacePanel()
    Panel = CreateFrame("Frame", nil, InterfaceOptionsFramePanelContainer) ---@class MiniLootInterfacePanel
    Panel:Hide()
    Panel:SetAllPoints()
    Panel.name = addOnName
    Panel.offsetX = 16
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
    Panel.Widgets = {}
    Panel.Options = Options
    local poolReleaseWidget = function(_, obj) obj:ReleaseWidget() end
    Panel.WidgetPool = CreateObjectPool(function() return MiniLootInterfacePanelWidget:CreateWidget(Panel) end, poolReleaseWidget)
    Panel.WidgetCheckBoxPool = CreateObjectPool(function() return MiniLootInterfacePanelWidgetCheckBox:CreateWidget(Panel) end, poolReleaseWidget)
    Panel.Refresh = PanelRefresh
    Panel:HookScript("OnShow", Panel.Refresh)
    return Panel
end

local function GetInterfacePanel()
    if Panel then
        return Panel
    end
    Panel = CreateInterfacePanel()
    return Panel
end

---@param panel MiniLootInterfacePanel
local function AddInterfacePanel(panel)
    if panel.parent then
        local category = Settings.GetCategory(panel.parent)
		local subcategory, layout = Settings.RegisterCanvasLayoutSubcategory(category, panel, panel.name, panel.name)
		subcategory.ID = panel.name
		return
    end
    local category, layout = Settings.RegisterCanvasLayoutCategory(panel, panel.name, panel.name)
    category.ID = panel.name
    Settings.RegisterAddOnCategory(category)
end

local function SetupUI()
    local panel = GetInterfacePanel()
    AddInterfacePanel(panel)
end

---@class MiniLootNSUI
ns.UI = {
    SetupUI = SetupUI,
}
