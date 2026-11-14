local ns = select(2, ...) ---@class MiniLootNS

local addOnName = ... ---@type string

local L = ns.Locale
local db = ns.Settings.db
local ResetSavedVariables = ns.Settings.ResetSavedVariables
local GetChatFrameValue = ns.Settings.GetChatFrameValue
local ProjectVariant = ns.Utils.ProjectVariant
local ChattynatorUtil = ns.Utils.ChattynatorUtil
local GetTimerunningSeasonID = ns.Utils.GetTimerunningSeasonID
local TableKeys = ns.Utils.TableKeys
local TableSort = ns.Utils.TableSort
local IsChatFrame = ns.Utils.IsChatFrame
local HandlerTypes = ns.Tooltip.HandlerTypes
local MiniLootMessageGroup = ns.Messages.MiniLootMessageGroup
local CreateChatMessageGenerator = ns.Messages.CreateChatMessageGenerator
local CreateOutputHandler = ns.Output.CreateOutputHandler
local ProcessChatEvent = ns.Reporting.ProcessChatEvent

local HandlerTypesAsKeys = TableSort(TableKeys(HandlerTypes)) ---@type string[]
local MiniLootMessageGroupAsKeys = TableSort(TableKeys(MiniLootMessageGroup)) ---@type string[]

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
---@field public GetValue? fun(): any
---@field public DropDown? MiniLootInterfacePanelOptionDropDown[]|fun(): MiniLootInterfacePanelOptionDropDown[]
---@field public Number? MiniLootInterfacePanelOptionNumber
---@field public Keys? string[]
---@field public KeyDefault? boolean

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

---@return MiniLootInterfacePanelOptionDropDown[]
local function GetChatFrameDropDownOptions()
    local options = {} ---@type MiniLootInterfacePanelOptionDropDown[]
    local index = 0
    if ChattynatorUtil:IsLoaded() then
        for _, target in ipairs(ChattynatorUtil:GetTargets()) do
            index = index + 1
            options[index] = {
                Value = target.Value,
                Label = format(L.PANEL_OPTION_CHATFRAME_WINDOW_TAB, target.WindowIndex, target.TabIndex, target.TabName),
            }
        end
        return options
    end
    for i = 1, NUM_CHAT_WINDOWS or 10 do
        local value = format("ChatFrame%d", i)
        local frame = _G[value] ---@type MiniLootChatFramePolyfill?
        if frame and IsChatFrame(frame) then
            index = index + 1
            options[index] = {
                Value = value,
                Label = format("%s (%s)", value, frame.name or value),
                IsEnabled = IsChatFrameEnabled,
            }
        end
    end
    return options
end

---@param owner Frame
---@param option MiniLootInterfacePanelOption
---@param title? string
local function ShowOptionTooltip(owner, option, title)
    local tooltip = option.Tooltip
    if not tooltip or tooltip == "" then
        return
    end
    GameTooltip:SetOwner(owner, "ANCHOR_TOPLEFT", 18, 0)
    GameTooltip:AddLine(title or option.Label, 1, 1, 1, false)
    GameTooltip:AddLine(tooltip, nil, nil, nil, true)
    GameTooltip:Show()
end

---@param owner Frame
local function HideOptionTooltip(owner)
    if GameTooltip:IsOwned(owner) then
        GameTooltip:Hide()
    end
end

---@param key string
---@return string
local function GetKeyLabel(key)
    return (key:gsub("(%l)(%u)", "%1 %2"))
end

local DefaultOptionHeight = 24
local DefaultOptionPadding = 8
local GroupColumns = 2

---@param keys string[]
---@return number height
local function GetGroupHeight(keys)
    return ceil(#keys / GroupColumns) * DefaultOptionHeight
end

---@type string[]
local MiniLootMessageGroupAsKeysWithoutIgnore = {}

for _, key in ipairs(MiniLootMessageGroupAsKeys) do
    if key ~= MiniLootMessageGroup.Ignore then
        MiniLootMessageGroupAsKeysWithoutIgnore[#MiniLootMessageGroupAsKeysWithoutIgnore + 1] = key
    end
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
        GetValue = GetChatFrameValue,
        DropDown = GetChatFrameDropDownOptions,
    },
    {
        Type = WidgetType.Number,
        Key = "Debounce",
        KeyDependant = "Enabled",
        Label = L.PANEL_OPTION_DEBOUNCE,
        Tooltip = L.PANEL_OPTION_DEBOUNCE_TOOLTIP,
        Number = { Min = 0, Max = 600 },
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
        Number = { Min = 1 },
    },
    {
        Type = WidgetType.Number,
        Key = "IconTrim",
        KeyDependant = "Enabled",
        Label = L.PANEL_OPTION_ICON_TRIM,
        Tooltip = L.PANEL_OPTION_ICON_TRIM_TOOLTIP,
        Number = { Min = 0, Max = 49 },
    },
    {
        Type = WidgetType.Number,
        Key = "IconSize",
        KeyDependant = "Enabled",
        Label = L.PANEL_OPTION_ICON_SIZE,
        Tooltip = L.PANEL_OPTION_ICON_SIZE_TOOLTIP,
        Number = { Min = 0, Max = 64 },
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
    {
        Type = WidgetType.GroupCheckBox,
        Key = "EnabledGroups",
        KeyDependant = "Enabled",
        Label = L.PANEL_OPTION_ENABLED_GROUPS,
        Tooltip = L.PANEL_OPTION_ENABLED_GROUPS_TOOLTIP,
        Keys = MiniLootMessageGroupAsKeys,
        KeyDefault = true,
        Height = GetGroupHeight(MiniLootMessageGroupAsKeys),
    },
    {
        Type = WidgetType.GroupCheckBox,
        Key = "IgnoredGroups",
        KeyDependant = "Enabled",
        Label = L.PANEL_OPTION_IGNORED_GROUPS,
        Tooltip = L.PANEL_OPTION_IGNORED_GROUPS_TOOLTIP,
        Keys = MiniLootMessageGroupAsKeysWithoutIgnore,
        KeyDefault = false,
        Height = GetGroupHeight(MiniLootMessageGroupAsKeysWithoutIgnore),
    },
    {
        Type = WidgetType.GroupNumber,
        Key = "DebounceGroups",
        KeyDependant = "Enabled",
        Label = L.PANEL_OPTION_DEBOUNCE_GROUPS,
        Tooltip = L.PANEL_OPTION_DEBOUNCE_GROUPS_TOOLTIP,
        Keys = MiniLootMessageGroupAsKeysWithoutIgnore,
        Number = { Min = 0, Max = 600 },
        Height = GetGroupHeight(MiniLootMessageGroupAsKeysWithoutIgnore),
    },
    {
        Type = WidgetType.TooltipCheckBox,
        Key = "EnabledTooltips",
        KeyDependant = "EnableTooltips",
        Label = L.PANEL_OPTION_ENABLED_TOOLTIPS,
        Tooltip = L.PANEL_OPTION_ENABLED_TOOLTIPS_TOOLTIP,
        Keys = HandlerTypesAsKeys,
        KeyDefault = true,
        Height = GetGroupHeight(HandlerTypesAsKeys),
    },
    {
        Type = WidgetType.Filters,
        Key = "Filters",
        KeyDependant = "Enabled",
        Label = L.PANEL_OPTION_FILTERS,
        Tooltip = L.PANEL_OPTION_FILTERS_TOOLTIP,
    },
}

---@type table<string, MiniLootInterfacePanelOption>
local OptionsByKey = {}

for _, option in ipairs(Options) do
    if option.Key then
        OptionsByKey[option.Key] = option
    end
end

---@param key string
---@return boolean
local function IsOptionKeyActive(key)
    local value = db[key]
    if value == nil or value == false or value == 0 then
        return false
    end
    local option = OptionsByKey[key]
    local keyDependant = option and option.KeyDependant
    if keyDependant then
        return IsOptionKeyActive(keyDependant)
    end
    return true
end

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
---@field public controlType 1|2 `1` is Radio, `2` is Checkbox
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

    ---@param ... any
    ---@return any
    function MiniLootInterfacePanelWidget:GetValue(...)
        local option = self.Option
        if not option.Key then
            return
        end
        if option.GetValue then
            return option.GetValue()
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

    function MiniLootInterfacePanelWidget:CanEdit()
        local option = self.Option
        if not option.Key then
            return
        end
        local keyDependant = option.KeyDependant
        if keyDependant then
            return IsOptionKeyActive(keyDependant)
        end
        return true
    end

    function MiniLootInterfacePanelWidget:OnTableValueChanged()
        local key = self.Option.Key
        if not key then
            return
        end
        local value = db[key]
        self.Panel.eventFrame:OnSettingsChanged(key, value, value)
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

    ---@return number defaultWidth, number defaultHeight
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

    function MiniLootInterfacePanelWidget:IsSizeDirty()
        local currentWidth, currentHeight = self:GetSize()
        local width, height = self:GetPreferredSize()
        return currentWidth ~= width or currentHeight ~= height
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
                local dropDown = option.DropDown
                if type(dropDown) == "function" then
                    dropDown = dropDown()
                end
                local index = 0
                for _, data in ipairs(dropDown) do
                    local value = data.Value
                    local disabled ---@type boolean?
                    local isEnabled = data.IsEnabled
                    if isEnabled then
                        disabled = not isEnabled(data)
                    end
                    if not disabled or value == currentValue then
                        local text = data.Label or tostring(value)
                        index = index + 1
                        validOptions[index] = {
                            controlType = 1,
                            label = text,
                            text = text,
                            value = value,
                            disabled = disabled,
                        }
                    end
                end
                return validOptions
            end
            local key = option.Key
            if key and ProjectVariant.DropDownTemplateCreateInitializer then
                local defaultValue = ns.Settings.DefaultOptions[key]
                local setting = CreateAndInitFromMixin(ProxySettingMixin, "", key, type(defaultValue), defaultValue, getValue, setValue)
                initializer = ProjectVariant.DropDownTemplateCreateInitializer(setting, getOptions)
                element.GetElementData = function() return initializer end
            end
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

---@class MiniLootInterfacePanelNumberEditBox : EditBox
---@field public Left? Texture
---@field public Middle? Texture
---@field public Right? Texture

---@param editBox MiniLootInterfacePanelNumberEditBox
---@param commit fun(text: string)
---@param refresh fun()
---@param showTooltip? fun()
---@param hideTooltip? fun()
local function SetupNumberEditBox(editBox, commit, refresh, showTooltip, hideTooltip)
    local discard = false
    local function setBorderShown(shown)
        if editBox.Left then editBox.Left:SetShown(shown) end
        if editBox.Middle then editBox.Middle:SetShown(shown) end
        if editBox.Right then editBox.Right:SetShown(shown) end
    end
    editBox:SetAutoFocus(false)
    editBox:SetNumeric(true)
    editBox:SetNumericFullRange(true)
    editBox:SetMaxLetters(6)
    setBorderShown(false)
    editBox:HookScript("OnEnable", function() editBox:SetTextColor(1, 1, 1, 1) end)
    editBox:HookScript("OnDisable", function() editBox:SetTextColor(1, 1, 1, 0.5) end)
    editBox:HookScript("OnEditFocusGained", function()
        discard = false
        setBorderShown(true)
    end)
    editBox:HookScript("OnEditFocusLost", function()
        setBorderShown(false)
        if discard then
            discard = false
        else
            commit(editBox:GetText())
        end
        C_Timer.After(0.05, refresh)
    end)
    editBox:SetScript("OnEnterPressed", function()
        editBox:ClearFocus()
    end)
    editBox:SetScript("OnEscapePressed", function()
        discard = true
        editBox:ClearFocus()
    end)
    if showTooltip then
        editBox:HookScript("OnEnter", showTooltip)
    end
    if hideTooltip then
        editBox:HookScript("OnLeave", hideTooltip)
    end
end

---@param value number
---@param limits? MiniLootInterfacePanelOptionNumber
---@return number
local function ClampNumber(value, limits)
    if limits then
        if limits.Min and value < limits.Min then
            value = limits.Min
        end
        if limits.Max and value > limits.Max then
            value = limits.Max
        end
    end
    return value
end

---@class MiniLootInterfacePanelWidgetNumber : MiniLootInterfacePanelWidget
local MiniLootInterfacePanelWidgetNumber = Mixin({}, MiniLootInterfacePanelWidget)

do

    ---@class MiniLootInterfacePanelWidgetNumberElement : MiniLootInterfacePanelNumberEditBox

    ---@type MiniLootInterfacePanelWidgetOnLoad
    function MiniLootInterfacePanelWidgetNumber:OnLoad(panel, ...)
        MiniLootInterfacePanelWidget.OnLoad(self, panel)
        local element = self.Element ---@class MiniLootInterfacePanelWidgetNumberElement
        element:SetPoint("TOPLEFT", self.Label, "TOPRIGHT", 8, 0)
        element:ClearPoint("BOTTOMRIGHT")
        element:SetWidth(48)
        SetupNumberEditBox(
            element,
            function(text)
                local value = tonumber(text)
                if not value then
                    return
                end
                self:SaveValue(ClampNumber(value, self.Option.Number))
            end,
            function()
                if self.Option and self:IsShown() and not element:HasFocus() then
                    self:Refresh()
                end
            end,
            function() ShowOptionTooltip(element, self.Option) end,
            function() HideOptionTooltip(element) end
        )
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
        return MiniLootInterfacePanelWidget.GetValue(self)
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

---Shared setup of the widgets that list multiple values. The label is kept at the top and shows the tooltip of the option.
---@param widget MiniLootInterfacePanelWidget
---@param panel MiniLootInterfacePanel
local function SetupGroupWidget(widget, panel)
    MiniLootInterfacePanelWidget.OnLoad(widget, panel)
    widget.Label:ClearAllPoints()
    widget.Label:SetPoint("TOPLEFT", widget, "TOPLEFT", 0, 0)
    widget.Label:SetSize(panel.labelWidth, DefaultOptionHeight)
    local labelHover = CreateFrame("Frame", nil, widget)
    labelHover:SetAllPoints(widget.Label)
    labelHover:SetScript("OnEnter", function() ShowOptionTooltip(labelHover, widget.Option) end)
    labelHover:SetScript("OnLeave", function() HideOptionTooltip(labelHover) end)
end

---@param widget MiniLootInterfacePanelWidget
---@param count number
---@return number columnWidth, number rows
local function GetGroupLayout(widget, count)
    local width = widget:GetPreferredSize()
    local columnWidth = max(120, floor((width - widget.Panel.labelWidth) / GroupColumns))
    local rows = max(1, ceil(count / GroupColumns))
    return columnWidth, rows
end

---Places the frame in the grid. The columns are filled from top to bottom.
---@param frame Frame
---@param element Frame
---@param index number
---@param columnWidth number
---@param rows number
---@param offsetX? number
local function SetGroupPoint(frame, element, index, columnWidth, rows, offsetX)
    local column = floor((index - 1) / rows)
    local row = (index - 1) % rows
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", element, "TOPLEFT", column * columnWidth + (offsetX or 0), -row * DefaultOptionHeight)
end

---@class MiniLootInterfacePanelWidgetGroupCheckBox : MiniLootInterfacePanelWidget
local MiniLootInterfacePanelWidgetGroupCheckBox = Mixin({}, MiniLootInterfacePanelWidget)

do

    ---@type MiniLootInterfacePanelWidgetOnLoad
    function MiniLootInterfacePanelWidgetGroupCheckBox:OnLoad(panel, ...)
        SetupGroupWidget(self, panel)
        ---@class MiniLootInterfacePanelWidgetGroupCheckBoxElement
        local element = self.Element
        element.Buttons = element.Buttons or {} ---@type MiniLootInterfacePanelWidgetGroupCheckBoxButton[]
    end

    ---@type MiniLootInterfacePanelWidgetCreateWidget
    function MiniLootInterfacePanelWidgetGroupCheckBox:CreateWidget(panel, ...)
        local widget = CreateFrame("Frame", nil, panel) ---@class MiniLootInterfacePanelWidgetGroupCheckBox
        Mixin(widget, self)
        widget.Type = WidgetType.GroupCheckBox
        widget.Element = CreateFrame("Frame", nil, widget) ---@class MiniLootInterfacePanelWidgetGroupCheckBoxElement : Frame
        widget:OnLoad(panel, ...)
        return widget
    end

    ---The keys that are not stored in the table use the `KeyDefault` of the option.
    ---@param key string
    ---@return boolean checked
    function MiniLootInterfacePanelWidgetGroupCheckBox:GetValue(key)
        local value = MiniLootInterfacePanelWidget.GetValue(self) ---@type table<string, boolean?>|nil
        local checked = value and value[key]
        if checked == nil then
            checked = self.Option.KeyDefault
        end
        return checked and true or false
    end

    ---@param key string
    ---@param checked boolean
    function MiniLootInterfacePanelWidgetGroupCheckBox:SaveValue(key, checked)
        if not self:CanEdit() then
            return
        end
        local value = MiniLootInterfacePanelWidget.GetValue(self) ---@type table<string, boolean?>|nil
        if not value then
            return
        end
        local default = self.Option.KeyDefault and true or false
        if checked == default then
            value[key] = nil
        else
            value[key] = checked
        end
        self:OnTableValueChanged()
    end

    function MiniLootInterfacePanelWidgetGroupCheckBox:Refresh()
        MiniLootInterfacePanelWidget.Refresh(self)
        local element = self.Element ---@type MiniLootInterfacePanelWidgetGroupCheckBoxElement
        local buttons = element.Buttons
        local option = self.Option
        local keys = option.Keys or {}
        local count = #keys
        local canEdit = self:CanEdit()
        local columnWidth, rows = GetGroupLayout(self, count)
        for i = 1, count do
            local key = keys[i]
            local button = buttons[i] ---@type MiniLootInterfacePanelWidgetGroupCheckBoxButton
            if not button then
                button = CreateFrame("CheckButton", nil, element, "UICheckButtonTemplate") ---@class MiniLootInterfacePanelWidgetGroupCheckBoxButton : CheckButton
                buttons[i] = button
                button:SetSize(DefaultOptionHeight, DefaultOptionHeight)
                button.Label = button:CreateFontString(nil, "ARTWORK", "GameFontHighlightLeft")
                button.Label:SetPoint("LEFT", button, "RIGHT", 0, 0)
                button.Label:SetWordWrap(false)
                local newButton = button
                button:HookScript("OnClick", function() self:SaveValue(newButton.key, not not newButton:GetChecked()) end)
                button:HookScript("OnEnter", function() ShowOptionTooltip(newButton, self.Option) end)
                button:HookScript("OnLeave", function() HideOptionTooltip(newButton) end)
            end
            button.key = key
            button.Label:SetWidth(columnWidth - DefaultOptionHeight - 4)
            button.Label:SetText(GetKeyLabel(key))
            button.Label:SetAlpha(canEdit and 1 or 0.5)
            SetGroupPoint(button, element, i, columnWidth, rows)
            button:SetChecked(self:GetValue(key))
            button:SetEnabled(canEdit and true or false)
            button:Show()
        end
        for i = count + 1, #buttons do
            buttons[i]:Hide()
        end
    end

end

---@class MiniLootInterfacePanelWidgetGroupNumber : MiniLootInterfacePanelWidget
local MiniLootInterfacePanelWidgetGroupNumber = Mixin({}, MiniLootInterfacePanelWidget)

do

    ---@type MiniLootInterfacePanelWidgetOnLoad
    function MiniLootInterfacePanelWidgetGroupNumber:OnLoad(panel, ...)
        SetupGroupWidget(self, panel)
        ---@class MiniLootInterfacePanelWidgetGroupNumberElement
        local element = self.Element
        element.EditBoxes = element.EditBoxes or {} ---@type MiniLootInterfacePanelWidgetGroupNumberEditBox[]
    end

    ---@type MiniLootInterfacePanelWidgetCreateWidget
    function MiniLootInterfacePanelWidgetGroupNumber:CreateWidget(panel, ...)
        local widget = CreateFrame("Frame", nil, panel) ---@class MiniLootInterfacePanelWidgetGroupNumber
        Mixin(widget, self)
        widget.Type = WidgetType.GroupNumber
        widget.Element = CreateFrame("Frame", nil, widget) ---@class MiniLootInterfacePanelWidgetGroupNumberElement : Frame
        widget:OnLoad(panel, ...)
        return widget
    end

    ---@param key string
    ---@return number? value `nil` if the key has no custom value.
    function MiniLootInterfacePanelWidgetGroupNumber:GetValue(key)
        local value = MiniLootInterfacePanelWidget.GetValue(self) ---@type table<string, number?>|nil
        local number = value and value[key]
        if type(number) ~= "number" then
            return
        end
        return number
    end

    ---@param newValue number? `nil` removes the custom value.
    ---@param forceSave? boolean
    ---@param key string
    function MiniLootInterfacePanelWidgetGroupNumber:SaveValue(newValue, forceSave, key)
        if not self:CanEdit() then
            return
        end
        local value = MiniLootInterfacePanelWidget.GetValue(self) ---@type table<string, number?>|nil
        if not value or value[key] == newValue then
            return
        end
        value[key] = newValue
        self:OnTableValueChanged()
    end

    ---@param editBox MiniLootInterfacePanelWidgetGroupNumberEditBox
    function MiniLootInterfacePanelWidgetGroupNumber:RefreshEditBox(editBox)
        local number = self:GetValue(editBox.key)
        if number then
            editBox:SetNumber(number)
        else
            editBox:SetText("")
        end
    end

    function MiniLootInterfacePanelWidgetGroupNumber:Refresh()
        MiniLootInterfacePanelWidget.Refresh(self)
        local element = self.Element ---@type MiniLootInterfacePanelWidgetGroupNumberElement
        local editBoxes = element.EditBoxes
        local option = self.Option
        local keys = option.Keys or {}
        local count = #keys
        local canEdit = self:CanEdit()
        local columnWidth, rows = GetGroupLayout(self, count)
        local editBoxWidth = 36
        for i = 1, count do
            local key = keys[i]
            local editBox = editBoxes[i] ---@type MiniLootInterfacePanelWidgetGroupNumberEditBox
            if not editBox then
                editBox = CreateFrame("EditBox", nil, element, ProjectVariant.EditBoxNumberTemplate) ---@class MiniLootInterfacePanelWidgetGroupNumberEditBox : MiniLootInterfacePanelNumberEditBox
                editBoxes[i] = editBox
                editBox:SetSize(editBoxWidth, DefaultOptionHeight)
                editBox.Label = editBox:CreateFontString(nil, "ARTWORK", "GameFontHighlightLeft")
                editBox.Label:SetPoint("LEFT", editBox, "RIGHT", 6, 0)
                editBox.Label:SetWordWrap(false)
                local newEditBox = editBox
                SetupNumberEditBox(
                    newEditBox,
                    function(text)
                        local number = tonumber(text)
                        if number then
                            number = ClampNumber(number, self.Option.Number)
                        end
                        self:SaveValue(number, nil, newEditBox.key)
                    end,
                    function()
                        if self.Option and self:IsShown() and not newEditBox:HasFocus() then
                            self:RefreshEditBox(newEditBox)
                        end
                    end,
                    function() ShowOptionTooltip(newEditBox, self.Option) end,
                    function() HideOptionTooltip(newEditBox) end
                )
            end
            editBox.key = key
            editBox.Label:SetWidth(columnWidth - editBoxWidth - 20)
            editBox.Label:SetText(GetKeyLabel(key))
            editBox.Label:SetAlpha(canEdit and 1 or 0.5)
            SetGroupPoint(editBox, element, i, columnWidth, rows, 8)
            editBox:SetEnabled(canEdit and true or false)
            if not editBox:HasFocus() then
                self:RefreshEditBox(editBox)
            end
            editBox:Show()
        end
        for i = count + 1, #editBoxes do
            editBoxes[i]:Hide()
        end
    end

end

---@class MiniLootInterfacePanelWidgetTooltipCheckBox : MiniLootInterfacePanelWidgetGroupCheckBox
local MiniLootInterfacePanelWidgetTooltipCheckBox = Mixin({}, MiniLootInterfacePanelWidgetGroupCheckBox)

do

    ---@type MiniLootInterfacePanelWidgetCreateWidget
    function MiniLootInterfacePanelWidgetTooltipCheckBox:CreateWidget(panel, ...)
        local widget = CreateFrame("Frame", nil, panel) ---@class MiniLootInterfacePanelWidgetTooltipCheckBox
        Mixin(widget, self)
        widget.Type = WidgetType.TooltipCheckBox
        widget.Element = CreateFrame("Frame", nil, widget) ---@class MiniLootInterfacePanelWidgetTooltipCheckBoxElement : MiniLootInterfacePanelWidgetGroupCheckBoxElement
        widget:OnLoad(panel, ...)
        return widget
    end

end

---@class MiniLootInterfacePanelWidgetFilters : MiniLootInterfacePanelWidget
local MiniLootInterfacePanelWidgetFilters = Mixin({}, MiniLootInterfacePanelWidget)

do

    local RowHeight = DefaultOptionHeight
    local RowSpacing = 2
    local RowIndent = 16
    local ControlSpacing = 4
    local MaxGroupDepth = 2

    ---@alias MiniLootFilterEditorValueKind "quality"|"boolean"|"itemClass"|"number"|"text"

    ---@class MiniLootFilterEditorChoice
    ---@field public Value any
    ---@field public Label string

    ---@class MiniLootFilterEditorField
    ---@field public Label string
    ---@field public key MiniLootMessageFormatSimpleParserResultKeys
    ---@field public convert? MiniLootFilterConverters
    ---@field public kind MiniLootFilterEditorValueKind
    ---@field public comparator MiniLootFilterComparators
    ---@field public value any

    ---@alias MiniLootFilterEditorRowKind "rule"|"group"|"footer"

    ---@class MiniLootFilterEditorRowInfo
    ---@field public kind MiniLootFilterEditorRowKind
    ---@field public depth number
    ---@field public list MiniLootFilters
    ---@field public index? number
    ---@field public entry? MiniLootFilter
    ---@field public parent? MiniLootFilterEditorRowInfo

    ---@type table<MiniLootFilterComparators, string>
    local ComparatorLabels = {
        eq = "=",
        ne = "not =",
        gt = ">",
        ge = ">=",
        lt = "<",
        le = "<=",
        contains = L.PANEL_OPTION_FILTERS_COMPARATOR_CONTAINS,
        notcontains = L.PANEL_OPTION_FILTERS_COMPARATOR_NOT_CONTAINS,
        startswith = L.PANEL_OPTION_FILTERS_COMPARATOR_STARTS_WITH,
        endswith = L.PANEL_OPTION_FILTERS_COMPARATOR_ENDS_WITH,
    }

    ---@param comparators MiniLootFilterComparators[]
    ---@return MiniLootFilterEditorChoice[]
    local function CreateComparatorChoices(comparators)
        local choices = {} ---@type MiniLootFilterEditorChoice[]
        for i, comparator in ipairs(comparators) do
            choices[i] = { Value = comparator, Label = ComparatorLabels[comparator] }
        end
        return choices
    end

    local OrderedComparatorChoices = CreateComparatorChoices({ "eq", "ne", "gt", "ge", "lt", "le" })
    local EqualityComparatorChoices = CreateComparatorChoices({ "eq", "ne" })
    local TextComparatorChoices = CreateComparatorChoices({ "eq", "ne", "contains", "notcontains", "startswith", "endswith" })

    ---@type MiniLootFilterEditorField[]
    local Fields = {
        {
            Label = L.PANEL_OPTION_FILTERS_FIELD_QUALITY,
            key = "Link",
            convert = "quality",
            kind = "quality",
            comparator = "ge",
            value = 1,
        },
        {
            Label = L.PANEL_OPTION_FILTERS_FIELD_QUEST,
            key = "Link",
            convert = "quest",
            kind = "boolean",
            comparator = "eq",
            value = true,
        },
        {
            Label = L.PANEL_OPTION_FILTERS_FIELD_ITEM_CLASS,
            key = "Link",
            convert = "itemClass",
            kind = "itemClass",
            comparator = "eq",
            value = 0,
        },
        {
            Label = L.PANEL_OPTION_FILTERS_FIELD_VALUE,
            key = "Value",
            kind = "number",
            comparator = "ge",
            value = 1,
        },
        {
            Label = L.PANEL_OPTION_FILTERS_FIELD_NAME,
            key = "Name",
            kind = "text",
            comparator = "eq",
            value = "",
        },
    }

    ---@type MiniLootFilterEditorChoice[]
    local FieldChoices = {}

    for i, field in ipairs(Fields) do
        FieldChoices[i] = { Value = field, Label = field.Label }
    end

    ---@type MiniLootFilterEditorChoice[]
    local ScopeChoices = {
        { Value = nil, Label = L.PANEL_OPTION_FILTERS_ANY_GROUP },
    }

    for _, key in ipairs(MiniLootMessageGroupAsKeysWithoutIgnore) do
        ScopeChoices[#ScopeChoices + 1] = { Value = key, Label = GetKeyLabel(key) }
    end

    ---@type MiniLootFilterEditorChoice[]
    local BooleanChoices = {
        { Value = true, Label = YES },
        { Value = false, Label = NO },
    }

    local qualityChoices ---@type MiniLootFilterEditorChoice[]?
    local itemClassChoices ---@type MiniLootFilterEditorChoice[]?

    local function GetQualityChoices()
        if qualityChoices then
            return qualityChoices
        end
        qualityChoices = {}
        for quality = 0, 8 do
            local name = _G[format("ITEM_QUALITY%d_DESC", quality)]
            if type(name) ~= "string" then
                break
            end
            local color = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
            if color and color.hex then
                name = format("%s%s|r", color.hex, name)
            end
            qualityChoices[#qualityChoices + 1] = { Value = quality, Label = name }
        end
        return qualityChoices
    end

    local function GetItemClassChoices()
        if itemClassChoices then
            return itemClassChoices
        end
        itemClassChoices = {}
        local getItemClassInfo = C_Item.GetItemClassInfo
        if getItemClassInfo then
            for classID = 0, 19 do
                local name = getItemClassInfo(classID)
                if name and name ~= "" then
                    itemClassChoices[#itemClassChoices + 1] = { Value = classID, Label = name }
                end
            end
        end
        return itemClassChoices
    end

    ---@param kind? MiniLootFilterEditorValueKind
    ---@return MiniLootFilterEditorChoice[]? choices `nil` if the value is typed in.
    local function GetValueChoices(kind)
        if kind == "quality" then
            return GetQualityChoices()
        elseif kind == "boolean" then
            return BooleanChoices
        elseif kind == "itemClass" then
            return GetItemClassChoices()
        end
    end

    ---@param kind? MiniLootFilterEditorValueKind
    local function GetComparatorChoices(kind)
        if kind == "text" then
            return TextComparatorChoices
        elseif kind == "boolean" or kind == "itemClass" then
            return EqualityComparatorChoices
        end
        return OrderedComparatorChoices
    end

    ---@param choices MiniLootFilterEditorChoice[]
    ---@param value any
    ---@return string
    local function GetChoiceLabel(choices, value)
        for _, choice in ipairs(choices) do
            if choice.Value == value then
                return choice.Label
            end
        end
        return tostring(value)
    end

    ---@param rule MiniLootFilterRule
    ---@return MiniLootFilterEditorField? field `nil` if the rule was not made using the editor.
    local function GetField(rule)
        for _, field in ipairs(Fields) do
            if field.key == rule.key and field.convert == rule.convert then
                return field
            end
        end
    end

    ---@param rule MiniLootFilterRule
    ---@param field MiniLootFilterEditorField
    local function ApplyField(rule, field)
        rule.key = field.key
        rule.convert = field.convert
        rule.comparator = field.comparator
        rule.value = field.value
    end

    ---@return MiniLootFilterRule
    local function CreateRule()
        local field = Fields[1]
        ---@type MiniLootFilterRule
        local rule = {
            group = MiniLootMessageGroup.Loot,
            key = field.key,
            convert = field.convert,
            comparator = field.comparator,
            value = field.value,
        }
        return rule
    end

    ---@return MiniLootFilterRuleGroup
    local function CreateRuleGroup()
        return { logic = "or", children = { CreateRule() } }
    end

    -- Opens a menu to pick from, or picks the next choice on clients without the menu system.
    ---@param owner Frame
    ---@param choices MiniLootFilterEditorChoice[]
    ---@param current any
    ---@param onSelect fun(value: any)
    local function OpenChoiceMenu(owner, choices, current, onSelect)
        if not choices[1] then
            return
        end
        if MenuUtil and MenuUtil.CreateContextMenu then
            local selected = current
            MenuUtil.CreateContextMenu(owner, function(_, rootDescription)
                for _, choice in ipairs(choices) do
                    rootDescription:CreateRadio(
                        choice.Label,
                        function() return choice.Value == selected end,
                        function()
                            selected = choice.Value
                            onSelect(choice.Value)
                        end
                    )
                end
            end)
            return
        end
        local index = 0
        for i, choice in ipairs(choices) do
            if choice.Value == current then
                index = i
                break
            end
        end
        onSelect(choices[index % #choices + 1].Value)
    end

    ---@class MiniLootInterfacePanelWidgetFiltersButton : Button
    ---@field public width number
    ---@field public tooltip string

    ---@class MiniLootInterfacePanelWidgetFiltersEditBox : EditBox
    ---@field public width number
    ---@field public tooltip string
    ---@field public discard? boolean

    ---@class MiniLootInterfacePanelWidgetFiltersRow : Frame
    ---@field public info MiniLootFilterEditorRowInfo
    ---@field public Scope MiniLootInterfacePanelWidgetFiltersButton
    ---@field public Field MiniLootInterfacePanelWidgetFiltersButton
    ---@field public Comparator MiniLootInterfacePanelWidgetFiltersButton
    ---@field public Value MiniLootInterfacePanelWidgetFiltersButton
    ---@field public ValueEdit MiniLootInterfacePanelWidgetFiltersEditBox
    ---@field public Logic MiniLootInterfacePanelWidgetFiltersButton
    ---@field public AddRule MiniLootInterfacePanelWidgetFiltersButton
    ---@field public AddGroup MiniLootInterfacePanelWidgetFiltersButton
    ---@field public Reset MiniLootInterfacePanelWidgetFiltersButton
    ---@field public Remove MiniLootInterfacePanelWidgetFiltersButton
    ---@field public Controls (MiniLootInterfacePanelWidgetFiltersButton|MiniLootInterfacePanelWidgetFiltersEditBox)[]

    ---@param row MiniLootInterfacePanelWidgetFiltersRow
    ---@param width number
    ---@param text? string
    ---@param onClick fun(button: MiniLootInterfacePanelWidgetFiltersButton)
    local function CreateRowButton(row, width, text, onClick)
        local button = CreateFrame("Button", nil, row, "UIPanelButtonTemplate") ---@class MiniLootInterfacePanelWidgetFiltersButton
        button.width = width
        button:SetSize(width, RowHeight - 2)
        button:SetNormalFontObject("GameFontHighlightSmall")
        button:SetHighlightFontObject("GameFontHighlightSmall")
        button:SetDisabledFontObject("GameFontDisableSmall")
        if text then
            button:SetText(text)
        end
        button:SetScript("OnClick", onClick)
        row.Controls[#row.Controls + 1] = button
        return button
    end

    ---@type MiniLootInterfacePanelWidgetOnLoad
    function MiniLootInterfacePanelWidgetFilters:OnLoad(panel, ...)
        SetupGroupWidget(self, panel)
        ---@class MiniLootInterfacePanelWidgetFiltersElement
        local element = self.Element
        element:ClearAllPoints()
        element:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -DefaultOptionHeight)
        element:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0)
        element.Rows = element.Rows or {} ---@type MiniLootInterfacePanelWidgetFiltersRow[]
    end

    ---@type MiniLootInterfacePanelWidgetCreateWidget
    function MiniLootInterfacePanelWidgetFilters:CreateWidget(panel, ...)
        local widget = CreateFrame("Frame", nil, panel) ---@class MiniLootInterfacePanelWidgetFilters
        Mixin(widget, self)
        widget.Type = WidgetType.Filters
        widget.Element = CreateFrame("Frame", nil, widget) ---@class MiniLootInterfacePanelWidgetFiltersElement : Frame
        widget:OnLoad(panel, ...)
        return widget
    end

    ---@return MiniLootFilters
    function MiniLootInterfacePanelWidgetFilters:GetFilters()
        return MiniLootInterfacePanelWidget.GetValue(self)
    end

    -- Flattens the filters into the rows of the editor.
    ---@return MiniLootFilterEditorRowInfo[]
    function MiniLootInterfacePanelWidgetFilters:GetRowInfos()
        local infos = {} ---@type MiniLootFilterEditorRowInfo[]
        ---@param list MiniLootFilters
        ---@param depth number
        ---@param parent? MiniLootFilterEditorRowInfo
        local function append(list, depth, parent)
            for index, entry in ipairs(list) do
                ---@type MiniLootFilterEditorRowInfo
                local info = {
                    kind = entry.logic and "group" or "rule",
                    depth = depth,
                    list = list,
                    index = index,
                    entry = entry,
                    parent = parent,
                }
                infos[#infos + 1] = info
                if entry.logic and type(entry.children) == "table" then
                    append(entry.children, depth + 1, info)
                end
            end
        end
        local filters = self:GetFilters()
        if type(filters) == "table" then
            append(filters, 0)
            infos[#infos + 1] = { kind = "footer", depth = 0, list = filters }
        end
        return infos
    end

    ---@param structureChanged? boolean
    function MiniLootInterfacePanelWidgetFilters:OnFiltersChanged(structureChanged)
        self:OnTableValueChanged()
        if structureChanged then
            self.Panel:Refresh()
        else
            self:Refresh()
        end
    end

    -- Removes the entry, and the groups that are left empty as these would hide everything.
    ---@param info MiniLootFilterEditorRowInfo
    function MiniLootInterfacePanelWidgetFilters:RemoveEntry(info)
        local current = info ---@type MiniLootFilterEditorRowInfo?
        while current and current.index do
            table.remove(current.list, current.index)
            if current.parent and not current.list[1] then
                current = current.parent
            else
                current = nil
            end
        end
        self:OnFiltersChanged(true)
    end

    ---@param info MiniLootFilterEditorRowInfo
    ---@param entry MiniLootFilter
    function MiniLootInterfacePanelWidgetFilters:AddEntry(info, entry)
        local list = info.list
        if info.kind == "group" then
            list = (info.entry --[[@as MiniLootFilterRuleGroup]]).children
        end
        list[#list + 1] = entry
        self:OnFiltersChanged(true)
    end

    function MiniLootInterfacePanelWidgetFilters:ResetFilters()
        db.Filters = nil ---@diagnostic disable-line: assign-type-mismatch
        self:OnFiltersChanged(true)
    end

    ---@param row MiniLootInterfacePanelWidgetFiltersRow
    function MiniLootInterfacePanelWidgetFilters:SaveValueEdit(row)
        local info = row.info
        if info.kind ~= "rule" then
            return
        end
        local rule = info.entry --[[@as MiniLootFilterRule]]
        local field = GetField(rule)
        local text = row.ValueEdit:GetText()
        local value = text ---@type string|number?
        if (field and field.kind == "number") or (not field and type(rule.value) == "number") then
            value = tonumber(text)
        end
        if value == nil or value == rule.value then
            return
        end
        rule.value = value
        self:OnTableValueChanged()
    end

    ---@param index number
    ---@return MiniLootInterfacePanelWidgetFiltersRow
    function MiniLootInterfacePanelWidgetFilters:CreateRow(index)
        local element = self.Element ---@type MiniLootInterfacePanelWidgetFiltersElement
        local row = CreateFrame("Frame", nil, element) ---@class MiniLootInterfacePanelWidgetFiltersRow
        row:SetHeight(RowHeight)
        row:SetPoint("TOPLEFT", element, "TOPLEFT", 0, -(index - 1) * (RowHeight + RowSpacing))
        row:SetPoint("RIGHT", element, "RIGHT", 0, 0)
        row.Controls = {}
        row.Scope = CreateRowButton(row, 130, nil, function(button)
            local rule = row.info.entry --[[@as MiniLootFilterRule]]
            OpenChoiceMenu(button, ScopeChoices, rule.group, function(value)
                rule.group = value
                rule.type = nil
                self:OnFiltersChanged()
            end)
        end)
        row.Field = CreateRowButton(row, 100, nil, function(button)
            local rule = row.info.entry --[[@as MiniLootFilterRule]]
            OpenChoiceMenu(button, FieldChoices, GetField(rule), function(value)
                ApplyField(rule, value)
                self:OnFiltersChanged()
            end)
        end)
        row.Comparator = CreateRowButton(row, 92, nil, function(button)
            local rule = row.info.entry --[[@as MiniLootFilterRule]]
            local field = GetField(rule)
            OpenChoiceMenu(button, GetComparatorChoices(field and field.kind), rule.comparator, function(value)
                rule.comparator = value
                self:OnFiltersChanged()
            end)
        end)
        row.Value = CreateRowButton(row, 120, nil, function(button)
            local rule = row.info.entry --[[@as MiniLootFilterRule]]
            local field = GetField(rule)
            local choices = GetValueChoices(field and field.kind)
            if not choices then
                return
            end
            OpenChoiceMenu(button, choices, rule.value, function(value)
                rule.value = value
                self:OnFiltersChanged()
            end)
        end)
        local valueEdit = CreateFrame("EditBox", nil, row, "InputBoxTemplate") ---@class MiniLootInterfacePanelWidgetFiltersEditBox
        row.ValueEdit = valueEdit
        row.Controls[#row.Controls + 1] = valueEdit
        valueEdit.width = 112
        valueEdit:SetSize(valueEdit.width, RowHeight - 4)
        valueEdit:SetAutoFocus(false)
        valueEdit:SetMaxLetters(64)
        valueEdit:SetFontObject("GameFontHighlightSmall")
        valueEdit:SetScript("OnEnterPressed", function()
            valueEdit:ClearFocus()
        end)
        valueEdit:SetScript("OnEscapePressed", function()
            valueEdit.discard = true
            valueEdit:ClearFocus()
        end)
        valueEdit:HookScript("OnEditFocusLost", function()
            if valueEdit.discard then
                valueEdit.discard = nil
            else
                self:SaveValueEdit(row)
            end
            if row:IsShown() and row.info.kind == "rule" then
                valueEdit:SetText(tostring((row.info.entry --[[@as MiniLootFilterRule]]).value))
            end
        end)
        row.Logic = CreateRowButton(row, 70, nil, function()
            local ruleGroup = row.info.entry --[[@as MiniLootFilterRuleGroup]]
            ruleGroup.logic = ruleGroup.logic == "and" and "or" or "and"
            self:OnFiltersChanged()
        end)
        row.AddRule = CreateRowButton(row, 70, L.PANEL_OPTION_FILTERS_ADD_RULE, function()
            self:AddEntry(row.info, CreateRule())
        end)
        row.AddGroup = CreateRowButton(row, 70, L.PANEL_OPTION_FILTERS_ADD_GROUP, function()
            self:AddEntry(row.info, CreateRuleGroup())
        end)
        row.Reset = CreateRowButton(row, 70, L.PANEL_OPTION_FILTERS_RESET, function()
            self:ResetFilters()
        end)
        row.Remove = CreateRowButton(row, 24, "x", function()
            self:RemoveEntry(row.info)
        end)
        row.Scope.tooltip = L.PANEL_OPTION_FILTERS_SCOPE_TOOLTIP
        row.Field.tooltip = L.PANEL_OPTION_FILTERS_FIELD_TOOLTIP
        row.Comparator.tooltip = L.PANEL_OPTION_FILTERS_COMPARATOR_TOOLTIP
        row.Value.tooltip = L.PANEL_OPTION_FILTERS_VALUE_TOOLTIP
        row.ValueEdit.tooltip = L.PANEL_OPTION_FILTERS_VALUE_TOOLTIP
        row.Logic.tooltip = L.PANEL_OPTION_FILTERS_LOGIC_TOOLTIP
        row.AddRule.tooltip = L.PANEL_OPTION_FILTERS_ADD_RULE_TOOLTIP
        row.AddGroup.tooltip = L.PANEL_OPTION_FILTERS_ADD_GROUP_TOOLTIP
        row.Reset.tooltip = L.PANEL_OPTION_FILTERS_RESET_TOOLTIP
        row.Remove.tooltip = L.PANEL_OPTION_FILTERS_REMOVE_TOOLTIP
        for _, control in ipairs(row.Controls) do
            control:HookScript("OnEnter", function()
                GameTooltip:SetOwner(control, "ANCHOR_TOPLEFT", 18, 0)
                GameTooltip:SetText(control.tooltip, 1, 1, 1, 1, true)
                GameTooltip:Show()
            end)
            control:HookScript("OnLeave", function() HideOptionTooltip(control) end)
        end
        element.Rows[index] = row
        return row
    end

    ---@param row MiniLootInterfacePanelWidgetFiltersRow
    ---@param canEdit boolean
    function MiniLootInterfacePanelWidgetFilters:UpdateRow(row, canEdit)
        local info = row.info
        local offsetX = info.depth * RowIndent
        for _, control in ipairs(row.Controls) do
            control:Hide()
        end
        ---@param control MiniLootInterfacePanelWidgetFiltersButton|MiniLootInterfacePanelWidgetFiltersEditBox
        ---@param text? string
        ---@param padding? number
        local function show(control, text, padding)
            offsetX = offsetX + (padding or 0)
            control:ClearAllPoints()
            control:SetPoint("LEFT", row, "LEFT", offsetX, 0)
            offsetX = offsetX + control.width + ControlSpacing
            if text then
                control:SetText(text)
            end
            control:SetEnabled(canEdit)
            control:Show()
        end
        if info.kind == "rule" then
            local rule = info.entry --[[@as MiniLootFilterRule]]
            local field = GetField(rule)
            local kind = field and field.kind
            local choices = GetValueChoices(kind)
            show(row.Scope, GetChoiceLabel(ScopeChoices, rule.group))
            if field then
                show(row.Field, field.Label)
            else
                show(row.Field, rule.convert and format("%s(%s)", rule.convert, tostring(rule.key)) or tostring(rule.key))
            end
            show(row.Comparator, ComparatorLabels[rule.comparator] or tostring(rule.comparator))
            if choices then
                show(row.Value, GetChoiceLabel(choices, rule.value))
            else
                show(row.ValueEdit, not row.ValueEdit:HasFocus() and tostring(rule.value) or nil, 6)
            end
            show(row.Remove)
        elseif info.kind == "group" then
            local ruleGroup = info.entry --[[@as MiniLootFilterRuleGroup]]
            show(row.Logic, ruleGroup.logic == "and" and L.PANEL_OPTION_FILTERS_LOGIC_AND or L.PANEL_OPTION_FILTERS_LOGIC_OR)
            show(row.AddRule)
            if info.depth + 1 < MaxGroupDepth then
                show(row.AddGroup)
            end
            show(row.Remove)
        else
            show(row.AddRule)
            show(row.AddGroup)
            show(row.Reset)
        end
    end

    function MiniLootInterfacePanelWidgetFilters:Refresh()
        local element = self.Element ---@type MiniLootInterfacePanelWidgetFiltersElement
        local rows = element.Rows
        local infos = self:GetRowInfos()
        local count = #infos
        local canEdit = self:CanEdit() and true or false
        for i = 1, count do
            local row = rows[i] or self:CreateRow(i)
            row.info = infos[i]
            self:UpdateRow(row, canEdit)
            row:Show()
        end
        for i = count + 1, #rows do
            rows[i]:Hide()
        end
        self:SetPreferredSize(nil, DefaultOptionHeight + count * (RowHeight + RowSpacing))
        MiniLootInterfacePanelWidget.Refresh(self)
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
    {
        Type = WidgetType.GroupCheckBox,
        Widget = MiniLootInterfacePanelWidgetGroupCheckBox,
    },
    {
        Type = WidgetType.GroupNumber,
        Widget = MiniLootInterfacePanelWidgetGroupNumber,
    },
    {
        Type = WidgetType.TooltipCheckBox,
        Widget = MiniLootInterfacePanelWidgetTooltipCheckBox,
    },
    {
        Type = WidgetType.Filters,
        Widget = MiniLootInterfacePanelWidgetFilters,
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
        if not map then return end ---@diagnostic expect-line: missing-return-value
        return GetPanelPool(panel, map.Type)
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
    scrollBox:FullUpdate(true)
end

---@class MiniLootInterfacePanelScrollPolyfill
---@field public SetInterpolateScroll fun(self: MiniLootInterfacePanelScrollPolyfill, state: boolean)
---@field public SetPanExtent fun(self: MiniLootInterfacePanelScrollPolyfill, size: number)

---@class MiniLootInterfacePanelScrollBox : Frame
---@field public FullUpdate fun(self: MiniLootInterfacePanelScrollBox, immediately?: boolean)

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
        if panel:IsVisible() then
            panel:Refresh()
        end
    end
    AddInterfacePanel(panel)
    return panel
end

---@class MiniLootNSUI
ns.UI = {
    SetupUI = SetupUI,
}
