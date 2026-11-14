local ns = select(2, ...) ---@class MiniLootNS

local locale = GetLocale()

---@class MiniLootNSLocale
ns.Locale = setmetatable({}, {
	__index = function(self, key)
		return format("[%s] %s", locale, tostring(key))
	end,
})

---@class MiniLootNSLocale
local L = ns.Locale

L.PANEL_DESCRIPTION = "Customize how MiniLoot behaves by adjusting these settings."
L.PANEL_OPTION_ENABLE_REMIX_MODE = "Use Remix Profile"
L.PANEL_OPTION_ENABLE_REMIX_MODE_TOOLTIP = "|cffFFFFFFEnabled:|r You'll be customizing a separate profile exclusive for Remix characters.\n|cffFFFFFFDisabled:|r The standard profile is used for both regular and Remix characters."
L.PANEL_OPTION_ENABLED = "Enable MiniLoot"
L.PANEL_OPTION_ENABLED_TOOLTIP = "|cffFFFFFFEnabled:|r The addon functions as expected.\n|cffFFFFFFDisabled:|r The addon is turned off and will behave as if it's not installed."
L.PANEL_OPTION_ENABLE_TOOLTIPS = "Enable Hover Tooltips"
L.PANEL_OPTION_ENABLE_TOOLTIPS_TOOLTIP = "|cffFFFFFFEnabled:|r Hovering over icons will make them appear above the Chat Frame.\n|cffFFFFFFDisabled:|r Hovering functionality is turned off."
L.PANEL_OPTION_CHATFRAME = "Active Chat Frame"
L.PANEL_OPTION_CHATFRAME_TOOLTIP = "Select the Chat Frame that you wish to process loot related messages."
L.PANEL_OPTION_CHATFRAME_WINDOW_TAB = "Window %d Tab %d: %s"
L.PANEL_OPTION_DEBOUNCE = "Output Interval"
L.PANEL_OPTION_DEBOUNCE_TOOLTIP = "Output loot messages to the Chat Frame after this amount of seconds have passed."
L.PANEL_OPTION_DEBOUNCE_INCOMBAT = "Output during Combat"
L.PANEL_OPTION_DEBOUNCE_INCOMBAT_TOOLTIP = "|cffFFFFFFEnabled:|r The interval timer keeps counting even if in combat.\n|cffFFFFFFDisabled:|r The timer will pause and resume when combat ends."
L.PANEL_OPTION_SHORTEN_PLAYER_NAMES = "Short Player names"
L.PANEL_OPTION_SHORTEN_PLAYER_NAMES_TOOLTIP = "|cffFFFFFFEnabled:|r The realm part will be removed from player names.\n|cffFFFFFFDisabled:|r The full name will be displayed for cross-realm players."
L.PANEL_OPTION_SHORTEN_FACTION_NAMES = "Short Faction names"
L.PANEL_OPTION_SHORTEN_FACTION_NAMES_TOOLTIP = "|cffFFFFFFEnabled:|r The faction names will be shortened.\n|cffFFFFFFDisabled:|r The faction names will be kept unchanged."
L.PANEL_OPTION_SHORTEN_FACTION_NAMES_LENGTH = "Short Faction name length"
L.PANEL_OPTION_SHORTEN_FACTION_NAMES_LENGTH_TOOLTIP = "Specify a maximum length limit when shortening faction names."
L.PANEL_OPTION_ICON_TRIM = "Icon Trim"
L.PANEL_OPTION_ICON_TRIM_TOOLTIP = "Specify how many pixels to remove from the edges of icons."
L.PANEL_OPTION_ICON_SIZE = "Icon Size"
L.PANEL_OPTION_ICON_SIZE_TOOLTIP = "Specify the size of the icon."
L.PANEL_OPTION_ITEM_COUNT = "Show Item Count"
L.PANEL_OPTION_ITEM_COUNT_TOOLTIP = "|cffFFFFFFEnabled:|r Display item count behind icons.\n|cffFFFFFFDisabled:|r No counts will be added behind icons."
L.PANEL_OPTION_ITEM_COUNT_BANK = "Count Bank items"
L.PANEL_OPTION_ITEM_COUNT_BANK_TOOLTIP = "|cffFFFFFFEnabled:|r Items in your bank are included in the count.\n|cffFFFFFFDisabled:|r Only items in your bags are counted."
L.PANEL_OPTION_ITEM_COUNT_USES = "Count Charges on items"
L.PANEL_OPTION_ITEM_COUNT_USES_TOOLTIP = "|cffFFFFFFEnabled:|r Items with charges count their remaining charges.\n|cffFFFFFFDisabled:|r Items with charges count as one item each."
L.PANEL_OPTION_ITEM_COUNT_REAGENT_BANK = "Count Reagent Bank items"
L.PANEL_OPTION_ITEM_COUNT_REAGENT_BANK_TOOLTIP = "|cffFFFFFFEnabled:|r Items in your reagent bank are included in the count.\n|cffFFFFFFDisabled:|r The reagent bank is not counted."
L.PANEL_OPTION_ITEM_COUNT_CURRENCY = "Count Currency totals"
L.PANEL_OPTION_ITEM_COUNT_CURRENCY_TOOLTIP = "|cffFFFFFFEnabled:|r Display the total you own behind currencies.\n|cffFFFFFFDisabled:|r No totals will be added behind currencies."
L.PANEL_OPTION_ITEM_LEVEL = "Add Item Level"
L.PANEL_OPTION_ITEM_LEVEL_TOOLTIP = "|cffFFFFFFEnabled:|r Add item level after the icon.\n|cffFFFFFFDisabled:|r No item level will be added behind the icon."
L.PANEL_OPTION_ITEM_LEVEL_EQUIP_ONLY = "Show for equipment only"
L.PANEL_OPTION_ITEM_LEVEL_EQUIP_ONLY_TOOLTIP = "|cffFFFFFFEnabled:|r Only add item level for equipment.\n|cffFFFFFFDisabled:|r Adds item level to any kind of item."
L.PANEL_OPTION_ITEM_TIER = "Add Tier Indicator"
L.PANEL_OPTION_ITEM_TIER_TOOLTIP = "|cffFFFFFFEnabled:|r Add crafting tier indicator after the icon.\n|cffFFFFFFDisabled:|r No crafting tier indicator will be added behind the icon."
L.PANEL_OPTION_ITEM_TIER_AS_TEXT = "Show as text"
L.PANEL_OPTION_ITEM_TIER_AS_TEXT_TOOLTIP = "|cffFFFFFFEnabled:|r The indicator is shown as text.\n|cffFFFFFFDisabled:|r The indicator is shown as stars."
L.PANEL_OPTION_ENABLED_GROUPS = "Enabled groups"
L.PANEL_OPTION_ENABLED_GROUPS_TOOLTIP = "|cffFFFFFFChecked:|r Messages of this type are summarized by MiniLoot.\n|cffFFFFFFUnchecked:|r Messages of this type are left untouched."
L.PANEL_OPTION_IGNORED_GROUPS = "Ignored groups"
L.PANEL_OPTION_IGNORED_GROUPS_TOOLTIP = "|cffFFFFFFChecked:|r Messages of this type are hidden from the Chat Frame.\n|cffFFFFFFUnchecked:|r Messages of this type are shown."
L.PANEL_OPTION_DEBOUNCE_GROUPS = "Output Interval per group"
L.PANEL_OPTION_DEBOUNCE_GROUPS_TOOLTIP = "Use a different amount of seconds for messages of this type. Use 0 to output right away, or leave it empty to use the Output Interval."
L.PANEL_OPTION_ENABLED_TOOLTIPS = "Enabled tooltips"
L.PANEL_OPTION_ENABLED_TOOLTIPS_TOOLTIP = "|cffFFFFFFChecked:|r Hovering links of this type will show a tooltip.\n|cffFFFFFFUnchecked:|r No tooltip is shown for links of this type."
L.PANEL_OPTION_FILTERS = "Filters"
L.PANEL_OPTION_FILTERS_TOOLTIP = "A message is only shown if it passes every rule that applies to it.\n\nA group passes if all, or any, of its rules pass. The rules in a group should apply to the same kind of message."
L.PANEL_OPTION_FILTERS_ANY_GROUP = "Any message"
L.PANEL_OPTION_FILTERS_LOGIC_AND = "All of"
L.PANEL_OPTION_FILTERS_LOGIC_OR = "Any of"
L.PANEL_OPTION_FILTERS_ADD_RULE = "+ Rule"
L.PANEL_OPTION_FILTERS_ADD_GROUP = "+ Group"
L.PANEL_OPTION_FILTERS_RESET = "Defaults"
L.PANEL_OPTION_FILTERS_FIELD_QUALITY = "Item quality"
L.PANEL_OPTION_FILTERS_FIELD_QUEST = "Quest item"
L.PANEL_OPTION_FILTERS_FIELD_ITEM_CLASS = "Item type"
L.PANEL_OPTION_FILTERS_FIELD_VALUE = "Amount"
L.PANEL_OPTION_FILTERS_FIELD_NAME = "Name"
L.PANEL_OPTION_FILTERS_SCOPE_TOOLTIP = "The kind of message this rule applies to."
L.PANEL_OPTION_FILTERS_FIELD_TOOLTIP = "What the rule looks at."
L.PANEL_OPTION_FILTERS_COMPARATOR_TOOLTIP = "How it is compared to the value. The text comparisons other than = and not = ignore upper and lower case."
L.PANEL_OPTION_FILTERS_COMPARATOR_CONTAINS = "contains"
L.PANEL_OPTION_FILTERS_COMPARATOR_NOT_CONTAINS = "not contains"
L.PANEL_OPTION_FILTERS_COMPARATOR_STARTS_WITH = "starts with"
L.PANEL_OPTION_FILTERS_COMPARATOR_ENDS_WITH = "ends with"
L.PANEL_OPTION_FILTERS_VALUE_TOOLTIP = "The value to compare against."
L.PANEL_OPTION_FILTERS_LOGIC_TOOLTIP = "Click to switch between requiring all of the rules in this group, or any of them."
L.PANEL_OPTION_FILTERS_ADD_RULE_TOOLTIP = "Add a rule."
L.PANEL_OPTION_FILTERS_ADD_GROUP_TOOLTIP = "Add a group of rules."
L.PANEL_OPTION_FILTERS_RESET_TOOLTIP = "Replace all the filters with the defaults."
L.PANEL_OPTION_FILTERS_REMOVE_TOOLTIP = "Remove"
-- L.PANEL_CHAT_PREVIEW = "Chat Preview"

if locale == "deDE" then

--@localization(locale="deDE", format="lua_additive_table", handle-unlocalized="blank", escape-non-ascii=false, table-name="L")@

elseif locale == "esES" then

--@localization(locale="esES", format="lua_additive_table", handle-unlocalized="blank", escape-non-ascii=false, table-name="L")@

elseif locale == "esMX" then

--@localization(locale="esMX", format="lua_additive_table", handle-unlocalized="blank", escape-non-ascii=false, table-name="L")@

elseif locale == "frFR" then

--@localization(locale="frFR", format="lua_additive_table", handle-unlocalized="blank", escape-non-ascii=false, table-name="L")@

elseif locale == "itIT" then

--@localization(locale="itIT", format="lua_additive_table", handle-unlocalized="blank", escape-non-ascii=false, table-name="L")@

elseif locale == "koKR" then

--@localization(locale="koKR", format="lua_additive_table", handle-unlocalized="blank", escape-non-ascii=false, table-name="L")@

elseif locale == "ptBR" then

--@localization(locale="ptBR", format="lua_additive_table", handle-unlocalized="blank", escape-non-ascii=false, table-name="L")@

elseif locale == "ruRU" then

--@localization(locale="ruRU", format="lua_additive_table", handle-unlocalized="blank", escape-non-ascii=false, table-name="L")@

elseif locale == "zhCN" then

--@localization(locale="zhCN", format="lua_additive_table", handle-unlocalized="blank", escape-non-ascii=false, table-name="L")@

elseif locale == "zhTW" then

--@localization(locale="zhTW", format="lua_additive_table", handle-unlocalized="blank", escape-non-ascii=false, table-name="L")@

end
