local ns = select(2, ...) ---@class MiniLootNS

local addOnName = ... ---@type string

local L = ns.Locale

---@generic T
---@alias MiniLootInterfacePanelWidgetOnLoad fun(self: T, panel: MiniLootInterfacePanel, ...: any)

---@generic T
---@alias MiniLootInterfacePanelWidgetCreateWidget fun(self: T, panel: MiniLootInterfacePanel, ...: any): T

---@enum MiniLootInterfacePanelWidgetType
local WidgetType = {
    Generic = "Generic",
    CheckBox = "CheckBox",
    ChatFrame = "ChatFrame",
}

---@class MiniLootInterfacePanelOption
---@field public Type MiniLootInterfacePanelWidgetType
---@field public Label string

---@type MiniLootInterfacePanelOption[]
local Options = {
    -- {
    --     Type = WidgetType.Generic,
    --     Label = "Test 1",
    -- },
    -- {
    --     Type = WidgetType.CheckBox,
    --     Label = "Test 2",
    -- },
    -- {
    --     Type = WidgetType.ChatFrame,
    --     Label = "Test 3",
    -- },
    -- {
    --     Type = WidgetType.ChatFrame,
    --     Label = "Test 4",
    -- },
}

---@enum MiniLootInterfacePanelUIColor
local UIColor = {
    Transparent = CreateColor(0, 0, 0, 0),
    Black = CreateColor(0, 0, 0),
    White = CreateColor(1, 1, 1),
    White10 = CreateColor(1, 1, 1, 0.1),
}

---@class MiniLootInterfacePanelWidget : Frame
---@field public Option MiniLootInterfacePanelOption
---@field public Type MiniLootInterfacePanelWidgetType
---@field public OnLoad MiniLootInterfacePanelWidgetOnLoad
---@field public Element? Region

---@class MiniLootInterfacePanelWidget
local MiniLootInterfacePanelWidget = {}

do

    ---@type MiniLootInterfacePanelWidgetOnLoad
    function MiniLootInterfacePanelWidget:OnLoad(panel, ...)
        panel.Widgets[#panel.Widgets + 1] = self
        self.width = nil ---@type number?
        self.height = nil ---@type number?
        self.Label = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightLeft")
        self.Label:SetAllPoints()
        self.Background = self:CreateTexture(nil, "BACKGROUND")
        self.Background:SetPoint("TOPLEFT", -4, 2)
        self.Background:SetPoint("BOTTOMRIGHT", 4, -2)
        self.Background:SetColorTexture(1, 1, 1)
        self.Background:SetTexture(166265)
        self.Background:SetGradient("HORIZONTAL", UIColor.White10, UIColor.Transparent)
        local element = self.Element
        if not element then
            return
        end
        element:SetPoint("TOPLEFT", self.Label, "TOPLEFT", 128, 0)
        element:SetPoint("BOTTOMRIGHT", self.Label, "BOTTOMRIGHT", 0, 0)
    end

    ---@type MiniLootInterfacePanelWidgetCreateWidget
    function MiniLootInterfacePanelWidget:CreateWidget(panel, ...)
        local widget = CreateFrame("Frame", nil, panel) ---@class MiniLootInterfacePanelWidget
        Mixin(widget, self)
        widget.Type = WidgetType.Generic
        widget:OnLoad(panel, ...)
        return widget
    end

    function MiniLootInterfacePanelWidget:ReleaseWidget()
        self:Hide()
    end

    function MiniLootInterfacePanelWidget:Refresh()
        local width, height = self:GetPreferredSize()
        self:SetSize(width, height)
        local option = self.Option
        self.Label:SetText(option.Label)
        self:Show()
    end

    ---@param defaultWidth? number
    ---@param defaultHeight? number
    function MiniLootInterfacePanelWidget:SetDefaultSize(defaultWidth, defaultHeight)
        self.defaultWidth = defaultWidth or self.defaultWidth
        self.defaultHeight = defaultHeight or self.defaultHeight
    end

    ---@return number? defaultWidth, number? defaultHeight
    function MiniLootInterfacePanelWidget:GetDefaultSize()
        return self.defaultWidth, self.defaultHeight
    end

    ---@param width? number
    ---@param height? number
    function MiniLootInterfacePanelWidget:SetPreferredSize(width, height)
        self.width = width or self.width
        self.height = height or self.height
    end

    ---@return number width, number height
    function MiniLootInterfacePanelWidget:GetPreferredSize()
        return self.width or self.defaultWidth or 0, self.height or self.defaultHeight or 0
    end

    ---@param option MiniLootInterfacePanelOption
    function MiniLootInterfacePanelWidget:SetOption(option)
        self.Option = option
        self:Refresh()
    end

end

---@class MiniLootInterfacePanelWidgetCheckBox : MiniLootInterfacePanelWidget
local MiniLootInterfacePanelWidgetCheckBox = Mixin({}, MiniLootInterfacePanelWidget)

do

    ---@type MiniLootInterfacePanelWidgetOnLoad
    function MiniLootInterfacePanelWidgetCheckBox:OnLoad(panel, ...)
        MiniLootInterfacePanelWidget.OnLoad(self, panel)
        local element = self.Element ---@class MiniLootInterfacePanelWidgetCheckBoxElement
        element.Background = element:CreateTexture(nil, "BACKGROUND")
        element.Background:SetAllPoints()
        element.Background:SetColorTexture(1, 0, 0)
    end

    ---@type MiniLootInterfacePanelWidgetCreateWidget
    function MiniLootInterfacePanelWidgetCheckBox:CreateWidget(panel, ...)
        local widget = CreateFrame("Frame", nil, panel) ---@class MiniLootInterfacePanelWidgetCheckBox
        Mixin(widget, self)
        widget.Type = WidgetType.CheckBox
        widget.Element = CreateFrame("CheckButton", nil, widget) ---@class MiniLootInterfacePanelWidgetCheckBoxElement : CheckButton
        widget:OnLoad(panel, ...)
        return widget
    end

end

---@class MiniLootInterfacePanelWidgetChatFrame : MiniLootInterfacePanelWidget
local MiniLootInterfacePanelWidgetChatFrame = Mixin({}, MiniLootInterfacePanelWidget)

do

    ---@type MiniLootInterfacePanelWidgetOnLoad
    function MiniLootInterfacePanelWidgetChatFrame:OnLoad(panel, ...)
        MiniLootInterfacePanelWidget.OnLoad(self, panel)
        local element = self.Element ---@class MiniLootInterfacePanelWidgetChatFrameElement
        element.Background = element:CreateTexture(nil, "BACKGROUND")
        element.Background:SetAllPoints()
        element.Background:SetColorTexture(0, 1, 0)
    end

    ---@type MiniLootInterfacePanelWidgetCreateWidget
    function MiniLootInterfacePanelWidgetChatFrame:CreateWidget(panel, ...)
        local widget = CreateFrame("Frame", nil, panel) ---@class MiniLootInterfacePanelWidgetChatFrame
        Mixin(widget, self)
        widget.Type = WidgetType.ChatFrame
        widget.Element = CreateFrame("MessageFrame", nil, widget) ---@class MiniLootInterfacePanelWidgetChatFrameElement : MiniLootChatFramePolyfill
        widget:OnLoad(panel, ...)
        return widget
    end

end

---@class MiniLootInterfacePanelWidgetMap
---@field public Type MiniLootInterfacePanelWidgetType
---@field public Widget MiniLootInterfacePanelWidget

---@type MiniLootInterfacePanelWidgetMap[]
local WidgetMap = {
    {
        Type = WidgetType.Generic,
        Widget = MiniLootInterfacePanelWidget,
    },
    {
        Type = WidgetType.CheckBox,
        Widget = MiniLootInterfacePanelWidgetCheckBox,
    },
    {
        Type = WidgetType.ChatFrame,
        Widget = MiniLootInterfacePanelWidgetChatFrame,
    },
}

---@param panel MiniLootInterfacePanel
---@param type MiniLootInterfacePanelWidgetType
local function GetPanelPool(panel, type)
    for _, map in ipairs(WidgetMap) do
        if map.Type == type then
            local name = format("%sPool", map.Type)
            local pool = panel[name] ---@type ObjectPoolPolyfill
            return pool or false, map.Widget, name, map.Type
        end
    end
end

---@param panel MiniLootInterfacePanel
---@return fun(): pool: ObjectPoolPolyfill, widget: MiniLootInterfacePanelWidget, name: string, type: MiniLootInterfacePanelWidgetType
local function EnumeratePanelPools(panel)
    local index = 0
    return function()
        index = index + 1
        local map = WidgetMap[index]
        if not map then return end ---@diagnostic disable-line: missing-return-value
        return GetPanelPool(panel, map.Type) ---@diagnostic disable-line: return-type-mismatch
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
    for pool in EnumeratePanelPools(self) do
        pool:ReleaseAll()
    end
    local widget ---@type MiniLootInterfacePanelWidget?
    local prevWidget ---@type MiniLootInterfacePanelWidget?
    local scrollBox = self.ScrollBox
    local scrollContent = self.ScrollContent
    local maxWidth, maxHeight = scrollBox:GetSize()
    local widgetWidth = maxWidth - self.offsetX*2
    local widgetHeight = maxHeight/20
    local totalHeight = self.minHeight
    for _, option in ipairs(Panel.Options) do
        local pool = GetPanelPool(self, option.Type)
        if pool then
            widget = pool:Acquire()
            widget:SetDefaultSize(widgetWidth, widgetHeight)
            widget:SetOption(option)
            widget:SetPoint("TOPLEFT", prevWidget or scrollContent.Description, "BOTTOMLEFT", 0, -8)
            totalHeight = totalHeight + widget:GetHeight()
            prevWidget = widget
        end
    end
    scrollContent:SetHeight(totalHeight)
end

---@class MiniLootInterfacePanelScrollPolyfill
---@field public SetInterpolateScroll fun(self: MiniLootInterfacePanelScrollPolyfill, state: boolean)
---@field public SetPanExtent fun(self: MiniLootInterfacePanelScrollPolyfill, size: number)

---@class MiniLootInterfacePanelScrollBox : Frame

local function CreateInterfacePanel()
    Panel = CreateFrame("Frame", nil, InterfaceOptionsFramePanelContainer) ---@class MiniLootInterfacePanel
    Panel:Hide()
    Panel:SetAllPoints()
    Panel.name = addOnName
    Panel.Widgets = {}
    Panel.Options = Options
    Panel.offsetX = 16
    Panel.minHeight = 64
    local scrollBox = CreateFrame("Frame", nil, Panel, "WowScrollBox") ---@class MiniLootInterfacePanelScrollBox : MiniLootInterfacePanelScrollPolyfill
    Panel.ScrollBox = scrollBox
    scrollBox:SetPoint("TOPLEFT", 16, -16)
    scrollBox:SetPoint("BOTTOMRIGHT", -16, 16)
    scrollBox:SetInterpolateScroll(true)
    local scrollBar = CreateFrame("EventFrame", nil, Panel, "MinimalScrollBar") ---@class MiniLootInterfacePanelScrollBar : EventFrame, MiniLootInterfacePanelScrollPolyfill
    Panel.ScrollBar = scrollBar
    scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT")
    scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT")
    scrollBar:SetInterpolateScroll(true)
    -- scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 4, -3)
    -- scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 4, 2)
    local scrollContent = CreateFrame("Frame", nil, scrollBox) ---@class MiniLootInterfacePanelScrollBoxContent : Frame
    Panel.ScrollContent = scrollContent
    scrollContent:SetAllPoints()
    scrollContent.scrollable = true
    scrollContent.Title = scrollContent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    scrollContent.Title:SetPoint("TOPLEFT", 16, -16)
    scrollContent.Title:SetText(addOnName)
    local description = scrollContent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall") ---@class MiniLootInterfacePanelScrollBoxDescription : FontString
    scrollContent.Description = description
    description:SetPoint("TOPLEFT", scrollContent.Title, "BOTTOMLEFT", 0, -8)
    description:SetPoint("RIGHT", -32, 0)
    description:SetText(L.PANEL_DESCRIPTION)
    description:SetMaxLines(3)
    description:SetNonSpaceWrap(true)
    description:SetJustifyH("LEFT")
    description:SetJustifyV("TOP")
    local scrollView = CreateScrollBoxLinearView() ---@class MiniLootInterfacePanelScrollView : MiniLootInterfacePanelScrollPolyfill
    Panel.ScrollView = scrollView
    scrollView:SetPanExtent(100)
    scrollContent:SetHeight(Panel.minHeight + #Options*32)
    ScrollUtil.InitScrollBoxWithScrollBar(scrollBox, scrollBar, scrollView)
    local function poolReleaseWidget(_, obj)
        obj:ReleaseWidget()
    end
    for _, widget, name in EnumeratePanelPools(Panel) do
        Panel[name] = CreateObjectPool(
            function()
                local obj = widget:CreateWidget(Panel)
                obj:SetParent(scrollBox)
                return obj
            end,
            poolReleaseWidget
        )
    end
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
    _G.T = panel -- DEBUG
end

---@class MiniLootNSUI
ns.UI = {
    SetupUI = SetupUI,
}
