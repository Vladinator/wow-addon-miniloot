local ns = select(2, ...) ---@class MiniLootNS

local addOnName = ... ---@type string

local L = ns.Locale
local db = ns.Settings.db
local ResetSavedVariables = ns.Settings.ResetSavedVariables
local ProjectVariant = ns.Utils.ProjectVariant
local GetTimerunningSeasonID = ns.Utils.GetTimerunningSeasonID
local IsChatFrame = ns.Utils.IsChatFrame
local CreateChatMessageGenerator = ns.Messages.CreateChatMessageGenerator
local CreateOutputHandler = ns.Output.CreateOutputHandler
local ProcessChatEvent = ns.Reporting.ProcessChatEvent

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
    GroupCheckBox = "GroupCheckBox",
    GroupNumber = "GroupNumber",
    TooltipCheckBox = "TooltipCheckBox",
    Filters = "Filters",
}

---@alias MiniLootInterfacePanelOptionDropDownIsEnabled fun(self: MiniLootInterfacePanelOptionDropDown): boolean?

---@class MiniLootInterfacePanelOptionDropDown
---@field public Value string|number|boolean
---@field public Label? string
---@field public IsEnabled? MiniLootInterfacePanelOptionDropDownIsEnabled

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
---@field public CanShow? fun(): boolean|number?
---@field public DropDown? MiniLootInterfacePanelOptionDropDown[]
---@field public Number? MiniLootInterfacePanelOptionNumber

local TIMERUNNING_MARKUP = CreateAtlasMarkup("timerunning-glues-icon-small", 9, 12)

---@type MiniLootInterfacePanelOptionDropDownIsEnabled
local function IsChatFrameEnabled(option)
    local frame = _G[option.Value] ---@type MiniLootChatFramePolyfill?
    if not frame or not IsChatFrame(frame) then
        return
    end
    local tabName = format("%sTab", option.Value)
    local chatTab = _G[tabName] ---@type Frame?
    if not chatTab or not chatTab:IsShown() then
        return
    end
    return true
end

---@param chatName string
---@return string
local function GetChatFrameName(chatName)
    local frame = _G[chatName] ---@type MiniLootChatFramePolyfill
    return frame.name
end

---@type MiniLootInterfacePanelOption[]
local Options = {
    {
        CanShow = GetTimerunningSeasonID,
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
            { Value = "ChatFrame1", IsEnabled = IsChatFrameEnabled },
            { Value = "ChatFrame2", IsEnabled = IsChatFrameEnabled },
            { Value = "ChatFrame3", IsEnabled = IsChatFrameEnabled },
            { Value = "ChatFrame4", IsEnabled = IsChatFrameEnabled },
            { Value = "ChatFrame5", IsEnabled = IsChatFrameEnabled },
            { Value = "ChatFrame6", IsEnabled = IsChatFrameEnabled },
            { Value = "ChatFrame7", IsEnabled = IsChatFrameEnabled },
            { Value = "ChatFrame8", IsEnabled = IsChatFrameEnabled },
            { Value = "ChatFrame9", IsEnabled = IsChatFrameEnabled },
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
    -- TODO: db.EnabledGroups (table<MiniLootMessageGroup, boolean?>) GroupCheckBox
    -- TODO: db.IgnoredGroups (table<MiniLootMessageGroup, boolean?>) GroupCheckBox
    -- TODO: db.DebounceGroups (table<MiniLootMessageGroup, number?>) GroupNumber
    -- TODO: db.EnabledTooltips (table<MiniLootTooltipHandlerType, boolean?>) TooltipCheckBox
    -- TODO: db.Filters (MiniLootFilterRuleGroup[]|MiniLootFilterRule[]) Filters
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
---@field public Element? SettingsControlPolyfill

---@class SettingsControlPolyfill : Frame
---@field public HoverBackground Texture
---@field public Init fun(self: any, initializer: any)
---@field public SetTooltipFunc fun(self: any, callback: fun()?)
---@field public SetEnabled? fun(self: any, state: boolean?)
---@field public SetEnabled_? fun(self: any, state: boolean?) `pre-11.0`

---@class SettingsControlDropDownOptionPolyfill
---@field public label string
---@field public text string
---@field public value any
---@field public tooltip? string
---@field public disabled? boolean
---@field public warning? boolean
---@field public recommended? boolean
---@field public onEnter? fun()

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
        local element = self.Element
        if not element then
            return
        end
        if element.SetTooltipFunc then
            element:SetTooltipFunc()
        end
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
        if not element then
            self:Show()
            return
        end
        element:SetHeight(height)
        if element.SetTooltipFunc then
            local tooltip = option.Tooltip
            if tooltip and tooltip ~= "" then
                element:SetTooltipFunc(function() Settings.InitTooltip(option.Label, tooltip) end)
            end
        end
        if element.SetEnabled then
            element:SetEnabled(self:CanEdit())
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

    ---@class MiniLootInterfacePanelWidgetCheckBoxElement : CheckButton, SettingsControlPolyfill

    ---@type MiniLootInterfacePanelWidgetOnLoad
    function MiniLootInterfacePanelWidgetCheckBox:OnLoad(panel, ...)
        MiniLootInterfacePanelWidget.OnLoad(self, panel)
        local element = self.Element ---@class MiniLootInterfacePanelWidgetCheckBoxElement
        element:ClearPoint("BOTTOMRIGHT")
        element.HoverBackground:SetAllPoints(self.Background)
        element.HoverBackground:SetAlpha(0)
        element:HookScript("OnClick", function() self:SaveValue(not not element:GetChecked()) self.Panel:Refresh() end)
    end

    function MiniLootInterfacePanelWidgetCheckBox:Refresh()
        MiniLootInterfacePanelWidget.Refresh(self)
        local element = self.Element
        element:SetWidth(element:GetHeight())
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

    ---@class MiniLootInterfacePanelWidgetDropDownElement : Frame, SettingsControlPolyfill
    ---@field public Control? SettingsControlPolyfill `11.0`
    ---@field public DropDown? SettingsControlPolyfill `pre-11.0`
    ---@field public Tooltip SettingsControlPolyfill
    ---@field public Text SettingsControlPolyfill
    ---@field public data? any
    ---@field public GetElementData? fun(): any
    ---@field public autoLootSetting? any `pre-11.0`

    ---@type MiniLootInterfacePanelWidgetOnLoad
    function MiniLootInterfacePanelWidgetDropDown:OnLoad(panel, ...)
        MiniLootInterfacePanelWidget.OnLoad(self, panel)
        local element = self.Element ---@class MiniLootInterfacePanelWidgetDropDownElement
        element:SetPoint("TOPLEFT", self.Label, "TOPRIGHT", -214, -6)
        element.Tooltip.HoverBackground:SetAllPoints(self.Background)
        element.Tooltip.HoverBackground:SetAlpha(0)
        local onLoad = ProjectVariant.DropDownTemplateOnLoad
        if onLoad then
            onLoad(self)
        end
    end

    function MiniLootInterfacePanelWidgetDropDown:Refresh()
        MiniLootInterfacePanelWidget.Refresh(self)
        local element = self.Element
        local option = self.Option
        local initializer
        if option.DropDown and not element.data then
            local options = {} ---@type SettingsControlDropDownOptionPolyfill[]
            for i, data in ipairs(option.DropDown) do
                local text = data.Label or data.Value
                local value = data.Value or data.Label
                text = text == nil and "" or tostring(text)
                options[i] = {
                    label = text,
                    text = text,
                    value = value,
                }
            end
            local validOptions = {} ---@type SettingsControlDropDownOptionPolyfill[]
            local function getValue()
                return self:GetValue()
            end
            local function setValue(value)
                self:SaveValue(value)
            end
            local function getOptions()
                local currentValue = getValue()
                table.wipe(validOptions)
                local index = 0
                for i, dropdownOption in ipairs(options) do
                    local data = option.DropDown[i]
                    local disabled ---@type boolean?
                    local isEnabled = data.IsEnabled
                    if isEnabled then
                        disabled = not isEnabled(data)
                    end
                    dropdownOption.disabled = disabled
                    if not dropdownOption.disabled or dropdownOption.value == currentValue then
                        dropdownOption.label = format("%s (%s)", dropdownOption.text, GetChatFrameName(dropdownOption.value))
                        index = index + 1
                        validOptions[index] = dropdownOption
                    end
                end
                return validOptions
            end
            local key = option.Key
            local variableTbl = { [key] = getValue() } ---@type table<string, string>
            local defaultValue = ns.Settings.DefaultOptions[key]
            local setting = CreateAndInitFromMixin(ProxySettingMixin, "", key, variableTbl, type(defaultValue), defaultValue, getValue, setValue)
            initializer = ProjectVariant.DropDownTemplateCreateInitializer(setting, getOptions)
            element.GetElementData = function() return initializer end
        end
        if initializer then
            element:Init(initializer)
            local onInitialized = ProjectVariant.DropDownTemplateOnInitialized
            if onInitialized then
                onInitialized(self)
            end
        end
        local control = element.Control or element.DropDown
        local setEnabled = control and (control.SetEnabled or control.SetEnabled_)
        if setEnabled then
            setEnabled(control, self:CanEdit())
        end
    end

    ---@type MiniLootInterfacePanelWidgetCreateWidget
    function MiniLootInterfacePanelWidgetDropDown:CreateWidget(panel, ...)
        local widget = CreateFrame("Frame", nil, panel) ---@class MiniLootInterfacePanelWidgetDropDown
        Mixin(widget, self)
        widget.Type = WidgetType.DropDown
        widget.Element = CreateFrame("Frame", nil, widget, ProjectVariant.DropDownTemplate) ---@class MiniLootInterfacePanelWidgetDropDownElement
        widget:OnLoad(panel, ...)
        return widget
    end

end

---@class MiniLootInterfacePanelWidgetNumber : MiniLootInterfacePanelWidget
local MiniLootInterfacePanelWidgetNumber = Mixin({}, MiniLootInterfacePanelWidget)

do

    ---@class MiniLootInterfacePanelWidgetNumberElement : EditBox
    ---@field public Left Texture
    ---@field public Middle Texture
    ---@field public Right Texture

    ---@type MiniLootInterfacePanelWidgetOnLoad
    function MiniLootInterfacePanelWidgetNumber:OnLoad(panel, ...)
        MiniLootInterfacePanelWidget.OnLoad(self, panel)
        local element = self.Element ---@class MiniLootInterfacePanelWidgetNumberElement
        element:SetPoint("TOPLEFT", self.Label, "TOPRIGHT", 8, 0)
        element:ClearPoint("BOTTOMRIGHT")
        element:SetWidth(48)
        element:SetAutoFocus(false)
        element:SetNumeric(true)
        element:SetNumericFullRange(true)
        element:SetMaxLetters(6)
        function element.OnEnable()
            element:SetTextColor(1, 1, 1, 1)
        end
        function element.OnDisable()
            element:SetTextColor(1, 1, 1, 0.5)
        end
        function element.OnEditFocusGained()
            element.Left:Show()
            element.Middle:Show()
            element.Right:Show()
        end
        function element.OnEditFocusLost()
            element.Left:Hide()
            element.Middle:Hide()
            element.Right:Hide()
            C_Timer.After(0.05, function() self:Refresh() end)
        end
        function element.OnEnterPressed()
            self:SaveValue(element:GetNumber())
            element:ClearFocus()
        end
        function element.OnEnter()
            local option = self.Option
            local tooltip = option.Tooltip
            if not tooltip or tooltip == "" then
                return
            end
            GameTooltip:SetOwner(element, "ANCHOR_TOPLEFT", 18, 0)
            GameTooltip:AddLine(option.Label, 1, 1, 1, false)
            GameTooltip:AddLine(tooltip)
            GameTooltip:Show()
        end
        function element.OnLeave()
            local option = self.Option
            local tooltip = option.Tooltip
            if not tooltip or tooltip == "" then
                return
            end
            GameTooltip:Hide()
        end
        element:OnEditFocusLost()
        element:HookScript("OnEnable", element.OnEnable)
        element:HookScript("OnDisable", element.OnDisable)
        element:HookScript("OnEditFocusGained", element.OnEditFocusGained)
        element:HookScript("OnEditFocusLost", element.OnEditFocusLost)
        element:HookScript("OnEnterPressed", element.OnEnterPressed)
        element:HookScript("OnEnter", element.OnEnter)
        element:HookScript("OnLeave", element.OnLeave)
    end

    ---@type MiniLootInterfacePanelWidgetCreateWidget
    function MiniLootInterfacePanelWidgetNumber:CreateWidget(panel, ...)
        local widget = CreateFrame("Frame", nil, panel) ---@class MiniLootInterfacePanelWidgetNumber
        Mixin(widget, self)
        widget.Type = WidgetType.Number
        widget.Element = CreateFrame("EditBox", nil, widget, ProjectVariant.EditBoxNumberTemplate) ---@class MiniLootInterfacePanelWidgetNumberElement
        widget:OnLoad(panel, ...)
        return widget
    end

    ---@return number
    function MiniLootInterfacePanelWidgetNumber:GetValue()
        return MiniLootInterfacePanelWidget.GetValue(self) ---@diagnostic disable-line: return-type-mismatch
    end

    function MiniLootInterfacePanelWidgetNumber:Refresh()
        MiniLootInterfacePanelWidget.Refresh(self)
        local element = self.Element
        element:SetNumber(self:GetValue())
    end

end

---@class MiniLootInterfacePanelWidgetChatFrame : MiniLootInterfacePanelWidget
local MiniLootInterfacePanelWidgetChatFrame = Mixin({}, MiniLootInterfacePanelWidget)

do

    ---@type MiniLootInterfacePanelWidgetOnLoad
    function MiniLootInterfacePanelWidgetChatFrame:OnLoad(panel, ...)
        MiniLootInterfacePanelWidget.OnLoad(self, panel)
        self.Background:SetVertexColor(1, 1, 1)
        self.Background:SetColorTexture(1, 1, 1, 0.05)
        local element = self.Element ---@class MiniLootInterfacePanelWidgetChatFrameElement
        element:ClearAllPoints()
        element:SetAllPoints(self)
        element:SetClipsChildren(true)
        element:SetFading(true)
        element:SetFontObject("GameFontWhite")
        element:SetJustifyH("LEFT")
        element:SetMaxLines(32)
        element:SetInsertMode(SCROLLING_MESSAGE_FRAME_INSERT_MODE_BOTTOM)
        local output = CreateOutputHandler(element)
        local generator = CreateChatMessageGenerator(false)
        ---@param previewMessage MiniLootMessage
        ---@param previewText string
        local function addPreviewMessage(previewMessage, previewText)
            local event = previewMessage.events[1]
            local result, message, hideChatIgnoreResult = ProcessChatEvent(event, previewText)
            if result and message and not hideChatIgnoreResult then
                output:Add({ result = result, message = message })
                output:Flush()
            end
        end
        local elapsed = 0
        local tries = 0
        local function OnUpdate(_, e)
            elapsed = elapsed + e
            if elapsed < 1 then
                return
            end
            elapsed = 0
            tries = 0
            local message ---@type MiniLootMessage?
            local text ---@type string?
            while not message or not text or tries < 3 do
                message, text = generator()
                if not message or not text then
                    tries = tries + 1
                else
                    break
                end
            end
            if message and text then
                addPreviewMessage(message, text)
            end
        end
        element:HookScript("OnUpdate", OnUpdate)
        self.Label:ClearAllPoints()
        self.Label:SetPoint("BOTTOMLEFT", element, "TOPLEFT", 0, 4)
    end

    ---@type MiniLootInterfacePanelWidgetCreateWidget
    function MiniLootInterfacePanelWidgetChatFrame:CreateWidget(panel, ...)
        local widget = CreateFrame("Frame", nil, panel) ---@class MiniLootInterfacePanelWidgetChatFrame
        Mixin(widget, self)
        widget.Type = WidgetType.ChatFrame
        widget.Element = CreateFrame("ScrollingMessageFrame", nil, widget) ---@class MiniLootInterfacePanelWidgetChatFrameElement : MiniLootChatFramePolyfill
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
        local canShow = option.CanShow
        if not canShow or canShow() then
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
    -- Panel.PreviewChatFrame = MiniLootInterfacePanelWidgetChatFrame:CreateWidget(Panel)
    -- Panel.PreviewChatFrame.Label:SetText(L.PANEL_CHAT_PREVIEW)
    -- Panel.PreviewChatFrame:ClearAllPoints()
    -- Panel.PreviewChatFrame:SetPoint("BOTTOMRIGHT", scrollBar, "BOTTOMLEFT", -16, 8)
    -- Panel.PreviewChatFrame:SetSize(300, 150)
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
    panel.OnDefault = function()
        ResetSavedVariables()
        eventFrame:UpdateState(true)
    end
    AddInterfacePanel(panel)
    return panel
end

---@class MiniLootNSUI
ns.UI = {
    SetupUI = SetupUI,
}
