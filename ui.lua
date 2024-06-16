local ns = select(2, ...) ---@class MiniLootNS

local addOnName = ... ---@type string

local L = ns.Locale
local db = ns.Settings.db
local GetTimerunningSeasonID = ns.Utils.GetTimerunningSeasonID

---@generic T
---@alias MiniLootInterfacePanelWidgetOnLoad fun(self: T, panel: MiniLootInterfacePanel, ...: any)

---@generic T
---@alias MiniLootInterfacePanelWidgetCreateWidget fun(self: T, panel: MiniLootInterfacePanel, ...: any): T

---@enum MiniLootInterfacePanelWidgetType
local WidgetType = {
    Generic = "Generic",
    CheckBox = "CheckBox",
    DropDown = "DropDown",
    Number = "Number",
    ChatFrame = "ChatFrame",
}

---@class MiniLootInterfacePanelOptionDropDown
---@field public Name string

---@class MiniLootInterfacePanelOptionNumber
---@field public Min? number
---@field public Max? number

---@class MiniLootInterfacePanelOption
---@field public Type MiniLootInterfacePanelWidgetType
---@field public Label string
---@field public Tooltip? string
---@field public Key? string
---@field public KeyDependant? string
---@field public Indent? number
---@field public Height? number
---@field public DropDown? MiniLootInterfacePanelOptionDropDown[]
---@field public Number? MiniLootInterfacePanelOptionNumber

local TIMERUNNING_MARKUP = CreateAtlasMarkup("timerunning-glues-icon-small", 9, 12)

---@type MiniLootInterfacePanelOption[]
local Options = {
    {
        Type = WidgetType.CheckBox,
        Key = "EnableRemixMode",
        Label = format("%s %s", TIMERUNNING_MARKUP, L.PANEL_OPTION_ENABLE_REMIX_MODE),
        Tooltip = L.PANEL_OPTION_ENABLE_REMIX_MODE_TOOLTIP,
    },
    {
        Type = WidgetType.CheckBox,
        Key = "Enabled",
        Label = L.PANEL_OPTION_ENABLED,
        Tooltip = L.PANEL_OPTION_ENABLED_TOOLTIP,
    },
    {
        Type = WidgetType.CheckBox,
        Key = "EnableTooltips",
        KeyDependant = "Enabled",
        Label = L.PANEL_OPTION_ENABLE_TOOLTIPS,
        Tooltip = L.PANEL_OPTION_ENABLE_TOOLTIPS_TOOLTIP,
    },
    {
        Type = WidgetType.DropDown,
        Key = "ChatFrame",
        KeyDependant = "Enabled",
        Label = L.PANEL_OPTION_CHATFRAME,
        Tooltip = L.PANEL_OPTION_CHATFRAME_TOOLTIP,
        DropDown = {
            { Name = "ChatFrame1" },
            { Name = "ChatFrame2" },
            { Name = "ChatFrame3" },
            { Name = "ChatFrame4" },
            { Name = "ChatFrame5" },
            { Name = "ChatFrame6" },
            { Name = "ChatFrame7" },
            { Name = "ChatFrame8" },
            { Name = "ChatFrame9" },
        },
    },
    {
        Type = WidgetType.Number,
        Key = "Debounce",
        KeyDependant = "Enabled",
        Label = L.PANEL_OPTION_DEBOUNCE,
        Tooltip = L.PANEL_OPTION_DEBOUNCE_TOOLTIP,
    },
    {
        Type = WidgetType.CheckBox,
        Key = "DebounceInCombat",
        KeyDependant = "Enabled",
        Indent = 1,
        Label = L.PANEL_OPTION_DEBOUNCE_INCOMBAT,
        Tooltip = L.PANEL_OPTION_DEBOUNCE_INCOMBAT_TOOLTIP,
    },
    {
        Type = WidgetType.CheckBox,
        Key = "ShortenPlayerNames",
        KeyDependant = "Enabled",
        Label = L.PANEL_OPTION_SHORTEN_PLAYER_NAMES,
        Tooltip = L.PANEL_OPTION_SHORTEN_PLAYER_NAMES_TOOLTIP,
    },
    {
        Type = WidgetType.CheckBox,
        Key = "ShortenFactionNames",
        KeyDependant = "Enabled",
        Label = L.PANEL_OPTION_SHORTEN_FACTION_NAMES,
        Tooltip = L.PANEL_OPTION_SHORTEN_FACTION_NAMES_TOOLTIP,
    },
    {
        Type = WidgetType.Number,
        Key = "ShortenFactionNamesLength",
        KeyDependant = "ShortenFactionNames",
        Indent = 1,
        Label = L.PANEL_OPTION_SHORTEN_FACTION_NAMES_LENGTH,
        Tooltip = L.PANEL_OPTION_SHORTEN_FACTION_NAMES_LENGTH_TOOLTIP,
    },
    {
        Type = WidgetType.Number,
        Key = "IconTrim",
        KeyDependant = "Enabled",
        Label = L.PANEL_OPTION_ICON_TRIM,
        Tooltip = L.PANEL_OPTION_ICON_TRIM_TOOLTIP,
    },
    {
        Type = WidgetType.Number,
        Key = "IconSize",
        KeyDependant = "Enabled",
        Label = L.PANEL_OPTION_ICON_SIZE,
        Tooltip = L.PANEL_OPTION_ICON_SIZE_TOOLTIP,
    },
    {
        Type = WidgetType.CheckBox,
        Key = "ItemCount",
        KeyDependant = "Enabled",
        Label = L.PANEL_OPTION_ITEM_COUNT,
        Tooltip = L.PANEL_OPTION_ITEM_COUNT_TOOLTIP,
    },
    {
        Type = WidgetType.CheckBox,
        Key = "ItemCountBank",
        KeyDependant = "ItemCount",
        Indent = 1,
        Label = L.PANEL_OPTION_ITEM_COUNT_BANK,
        Tooltip = L.PANEL_OPTION_ITEM_COUNT_BANK_TOOLTIP,
    },
    {
        Type = WidgetType.CheckBox,
        Key = "ItemCountUses",
        KeyDependant = "ItemCount",
        Indent = 1,
        Label = L.PANEL_OPTION_ITEM_COUNT_USES,
        Tooltip = L.PANEL_OPTION_ITEM_COUNT_USES_TOOLTIP,
    },
    {
        Type = WidgetType.CheckBox,
        Key = "ItemCountReagentBank",
        KeyDependant = "ItemCount",
        Indent = 1,
        Label = L.PANEL_OPTION_ITEM_COUNT_REAGENT_BANK,
        Tooltip = L.PANEL_OPTION_ITEM_COUNT_REAGENT_BANK_TOOLTIP,
    },
    {
        Type = WidgetType.CheckBox,
        Key = "ItemCountCurrency",
        KeyDependant = "ItemCount",
        Indent = 1,
        Label = L.PANEL_OPTION_ITEM_COUNT_CURRENCY,
        Tooltip = L.PANEL_OPTION_ITEM_COUNT_CURRENCY_TOOLTIP,
    },
    {
        Type = WidgetType.CheckBox,
        Key = "ItemLevel",
        KeyDependant = "Enabled",
        Label = L.PANEL_OPTION_ITEM_LEVEL,
        Tooltip = L.PANEL_OPTION_ITEM_LEVEL_TOOLTIP,
    },
    {
        Type = WidgetType.CheckBox,
        Key = "ItemLevelEquipmentOnly",
        KeyDependant = "ItemLevel",
        Indent = 1,
        Label = L.PANEL_OPTION_ITEM_LEVEL_EQUIP_ONLY,
        Tooltip = L.PANEL_OPTION_ITEM_LEVEL_EQUIP_ONLY_TOOLTIP,
    },
    {
        Type = WidgetType.CheckBox,
        Key = "ItemTier",
        KeyDependant = "Enabled",
        Label = L.PANEL_OPTION_ITEM_TIER,
        Tooltip = L.PANEL_OPTION_ITEM_TIER_TOOLTIP,
    },
    {
        Type = WidgetType.CheckBox,
        Key = "ItemTierAsText",
        KeyDependant = "ItemTier",
        Indent = 1,
        Label = L.PANEL_OPTION_ITEM_TIER_AS_TEXT,
        Tooltip = L.PANEL_OPTION_ITEM_TIER_AS_TEXT_TOOLTIP,
    },
    -- {
    --     Type = WidgetType.ChatFrame,
    --     Label = L.PANEL_CHAT_PREVIEW_ORIGINAL,
    --     Tooltip = L.PANEL_CHAT_PREVIEW_ORIGINAL_TOOLTIP,
    --     Height = 200,
    -- },
    -- {
    --     Type = WidgetType.ChatFrame,
    --     Label = L.PANEL_CHAT_PREVIEW_MINILOOT,
    --     Tooltip = L.PANEL_CHAT_PREVIEW_MINILOOT_TOOLTIP,
    --     Height = 200,
    -- },
}

local DefaultOptionHeight = 24
local DefaultOptionPadding = 8

local function GetOptionsEstimatedHeight()
    local total = 0
    for _, option in pairs(Options) do
        local height = option.Height or DefaultOptionHeight
        total = total + height + DefaultOptionPadding
    end
    return total
end

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
        self.Panel = panel
        self.width = nil ---@type number?
        self.height = nil ---@type number?
        self.Label = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightLeft")
        self.Label:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
        self.Label:SetPoint("BOTTOMRIGHT", self, "BOTTOMLEFT", panel.labelWidth, 0)
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
        element:SetPoint("TOPLEFT", self.Label, "TOPRIGHT", 2, 0)
        element:SetPoint("BOTTOMRIGHT", self.Background, "BOTTOMRIGHT", -4, 2)
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

    function MiniLootInterfacePanelWidget:GetValue()
        local option = self.Option
        if not option.Key then
            return
        end
        return db[option.Key]
    end

    ---@param newValue any
    ---@param forceSave? boolean
    function MiniLootInterfacePanelWidget:SaveValue(newValue, forceSave)
        if newValue == nil and not forceSave then
            return
        end
        local option = self.Option
        local key = option.Key
        if not key then
            return
        end
        if not forceSave and not self:CanEdit() then
            return false
        end
        local currentValue = db[key]
        if currentValue == newValue then
            return true
        end
        if type(currentValue) ~= type(newValue) and not forceSave then
            return false
        end
        db[key] = newValue
        self.Panel.eventFrame:OnSettingsChanged(key, newValue, currentValue)
        return true
    end

    function MiniLootInterfacePanelWidget:IsValueSet()
        local value = self:GetValue()
        return value ~= nil and value ~= 0 and value ~= false
    end

    function MiniLootInterfacePanelWidget:CanEdit()
        local option = self.Option
        if not option.Key then
            return
        end
        local keyDependant = option.KeyDependant
        if keyDependant then
            for _, widget in pairs(self.Panel.Widgets) do
                if self ~= widget then
                    local widgetOption = widget.Option
                    if widgetOption and widgetOption.Key == keyDependant then
                        return widget:IsValueSet() and widget:CanEdit()
                    end
                end
            end
        end
        return true
    end

    function MiniLootInterfacePanelWidget:Refresh()
        local width, height = self:GetPreferredSize()
        self:SetSize(width, height)
        local option = self.Option
        local indent = option.Indent
        if indent then
            local padding = strrep("  ", indent)
            self.Label:SetText(format("%s%s", padding, option.Label))
        else
            self.Label:SetText(option.Label)
        end
        self.Label:SetAlpha(self:CanEdit() and 1 or 0.5)
        local element = self.Element
        if element then
            element:SetHeight(height)
        end
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
        if option.Height then
            self:SetPreferredSize(nil, option.Height)
        end
        self:Refresh()
    end

end

---@class MiniLootInterfacePanelWidgetCheckBox : MiniLootInterfacePanelWidget
local MiniLootInterfacePanelWidgetCheckBox = Mixin({}, MiniLootInterfacePanelWidget)

do

    ---@class MiniLootInterfacePanelWidgetCheckBoxElement : CheckButton
    ---@field public HoverBackground Texture
    ---@field public SetTooltipFunc fun(self: MiniLootInterfacePanelWidgetCheckBoxElement, callback: fun()?)

    ---@type MiniLootInterfacePanelWidgetOnLoad
    function MiniLootInterfacePanelWidgetCheckBox:OnLoad(panel, ...)
        MiniLootInterfacePanelWidget.OnLoad(self, panel)
        local element = self.Element ---@class MiniLootInterfacePanelWidgetCheckBoxElement
        element:ClearPoint("BOTTOMRIGHT")
        element.HoverBackground:SetAllPoints(self.Background)
        element.HoverBackground:SetAlpha(0)
        element:HookScript("OnClick", function() self:SaveValue(not not element:GetChecked()) self.Panel:Refresh() end)
    end

    function MiniLootInterfacePanelWidgetCheckBox:ReleaseWidget()
        MiniLootInterfacePanelWidget.ReleaseWidget(self)
        local element = self.Element
        element:SetTooltipFunc()
    end

    function MiniLootInterfacePanelWidgetCheckBox:Refresh()
        MiniLootInterfacePanelWidget.Refresh(self)
        local option = self.Option
        local tooltip = option.Tooltip
        local element = self.Element
        element:SetWidth(element:GetHeight())
        if tooltip and tooltip ~= "" then
            element:SetTooltipFunc(function() Settings.InitTooltip(option.Label, tooltip) end)
        end
        element:SetEnabled(self:CanEdit())
        element:SetChecked(self:GetValue())
    end

    ---@type MiniLootInterfacePanelWidgetCreateWidget
    function MiniLootInterfacePanelWidgetCheckBox:CreateWidget(panel, ...)
        local widget = CreateFrame("Frame", nil, panel) ---@class MiniLootInterfacePanelWidgetCheckBox
        Mixin(widget, self)
        widget.Type = WidgetType.CheckBox
        widget.Element = CreateFrame("CheckButton", nil, widget, "SettingsCheckBoxTemplate") ---@class MiniLootInterfacePanelWidgetCheckBoxElement
        widget:OnLoad(panel, ...)
        return widget
    end

end

---@class MiniLootInterfacePanelWidgetDropDown : MiniLootInterfacePanelWidget
local MiniLootInterfacePanelWidgetDropDown = Mixin({}, MiniLootInterfacePanelWidget)

do

    ---@type MiniLootInterfacePanelWidgetOnLoad
    function MiniLootInterfacePanelWidgetDropDown:OnLoad(panel, ...)
        MiniLootInterfacePanelWidget.OnLoad(self, panel)
        -- local element = self.Element ---@class MiniLootInterfacePanelWidgetDropDownElement
    end

    ---@type MiniLootInterfacePanelWidgetCreateWidget
    function MiniLootInterfacePanelWidgetDropDown:CreateWidget(panel, ...)
        local widget = CreateFrame("Frame", nil, panel) ---@class MiniLootInterfacePanelWidgetDropDown
        Mixin(widget, self)
        widget.Type = WidgetType.DropDown
        -- widget.Element = CreateFrame("Frame", nil, widget, "SettingsDropDownTemplate") ---@class MiniLootInterfacePanelWidgetDropDownElement
        widget:OnLoad(panel, ...)
        return widget
    end

end

---@class MiniLootInterfacePanelWidgetNumber : MiniLootInterfacePanelWidget
local MiniLootInterfacePanelWidgetNumber = Mixin({}, MiniLootInterfacePanelWidget)

do

    ---@type MiniLootInterfacePanelWidgetOnLoad
    function MiniLootInterfacePanelWidgetNumber:OnLoad(panel, ...)
        MiniLootInterfacePanelWidget.OnLoad(self, panel)
        -- local element = self.Element ---@class MiniLootInterfacePanelWidgetNumberElement
    end

    ---@type MiniLootInterfacePanelWidgetCreateWidget
    function MiniLootInterfacePanelWidgetNumber:CreateWidget(panel, ...)
        local widget = CreateFrame("Frame", nil, panel) ---@class MiniLootInterfacePanelWidgetNumber
        Mixin(widget, self)
        widget.Type = WidgetType.Number
        -- widget.Element = CreateFrame("EditBox", nil, widget, "SettingsEditBoxTemplate") ---@class MiniLootInterfacePanelWidgetNumberElement
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
        Type = WidgetType.DropDown,
        Widget = MiniLootInterfacePanelWidgetDropDown,
    },
    {
        Type = WidgetType.Number,
        Widget = MiniLootInterfacePanelWidgetNumber,
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
---@field public eventFrame MiniLootNSEventFrame
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
    local widgetHeight = DefaultOptionHeight -- maxHeight/20
    local totalHeight = self.minHeight
    for _, option in ipairs(Panel.Options) do
        local isRemixOption = option.Key == "EnableRemixMode"
        local showOption = not isRemixOption or GetTimerunningSeasonID()
        if showOption then
            local pool = GetPanelPool(self, option.Type)
            if pool then
                widget = pool:Acquire()
                widget:SetDefaultSize(widgetWidth, widgetHeight)
                widget:SetOption(option)
                widget:SetPoint("TOPLEFT", prevWidget or scrollContent.Description, "BOTTOMLEFT", 0, -8)
                prevWidget = widget
                local _, height = widget:GetPreferredSize()
                totalHeight = totalHeight + height + DefaultOptionPadding
            end
        end
    end
    scrollContent:SetHeight(totalHeight)
end

---@class MiniLootInterfacePanelScrollPolyfill
---@field public SetInterpolateScroll fun(self: MiniLootInterfacePanelScrollPolyfill, state: boolean)
---@field public SetPanExtent fun(self: MiniLootInterfacePanelScrollPolyfill, size: number)

---@class MiniLootInterfacePanelScrollBox : Frame

---@param eventFrame MiniLootNSEventFrame
local function CreateInterfacePanel(eventFrame)
    Panel = CreateFrame("Frame", nil, InterfaceOptionsFramePanelContainer) ---@class MiniLootInterfacePanel
    Panel:Hide()
    Panel:SetAllPoints()
    Panel.eventFrame = eventFrame
    Panel.name = addOnName
    Panel.Widgets = {}
    Panel.Options = Options
    Panel.offsetX = 16
    Panel.minHeight = 64
    Panel.labelWidth = 224
    local scrollBox = CreateFrame("Frame", nil, Panel, "WowScrollBox") ---@class MiniLootInterfacePanelScrollBox : MiniLootInterfacePanelScrollPolyfill
    Panel.ScrollBox = scrollBox
    scrollBox:SetPoint("TOPLEFT", 16, -16)
    scrollBox:SetPoint("BOTTOMRIGHT", -16, 16)
    scrollBox:SetInterpolateScroll(true)
    local scrollBar = CreateFrame("EventFrame", nil, Panel, "MinimalScrollBar") ---@class MiniLootInterfacePanelScrollBar : EventFrame, MiniLootInterfacePanelScrollPolyfill
    Panel.ScrollBar = scrollBar
    scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", -4, 0)
    scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", -4, 0)
    scrollBar:SetInterpolateScroll(true)
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
    scrollContent:SetHeight(Panel.minHeight + GetOptionsEstimatedHeight())
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

---@param eventFrame MiniLootNSEventFrame
local function GetInterfacePanel(eventFrame)
    if Panel then
        return Panel
    end
    Panel = CreateInterfacePanel(eventFrame)
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

---@param eventFrame MiniLootNSEventFrame
local function SetupUI(eventFrame)
    local panel = GetInterfacePanel(eventFrame)
    AddInterfacePanel(panel)
    return panel
end

---@class MiniLootNSUI
ns.UI = {
    SetupUI = SetupUI,
}
