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
L.PANEL_OPTION_DEBOUNCE = "Output Interval"
L.PANEL_OPTION_DEBOUNCE_TOOLTIP = "Output loot messages to the Chat Frame after this amount of seconds have passed."
L.PANEL_OPTION_DEBOUNCE_INCOMBAT = "Output during Combat"
L.PANEL_OPTION_DEBOUNCE_INCOMBAT_TOOLTIP = "|cffFFFFFFEnabled:|r The interval timer keeps counting even if in combat.\n|cffFFFFFFDisabled:|r The timer will pause and resume when combat ends."
L.PANEL_OPTION_SHORTEN_PLAYER_NAMES = "Short Player names"
L.PANEL_OPTION_SHORTEN_PLAYER_NAMES_TOOLTIP = "|cffFFFFFFEnabled:|r The realm part will be removed from player names.\n|cffFFFFFFDisabled:|r The full name will be displaed for cross-realm players."
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
L.PANEL_OPTION_ITEM_COUNT_BANK_TOOLTIP = ""
L.PANEL_OPTION_ITEM_COUNT_USES = "Count Charges on items"
L.PANEL_OPTION_ITEM_COUNT_USES_TOOLTIP = ""
L.PANEL_OPTION_ITEM_COUNT_REAGENT_BANK = "Count Reagent Bank items"
L.PANEL_OPTION_ITEM_COUNT_REAGENT_BANK_TOOLTIP = ""
L.PANEL_OPTION_ITEM_COUNT_CURRENCY = "Count Currency totals"
L.PANEL_OPTION_ITEM_COUNT_CURRENCY_TOOLTIP = ""
L.PANEL_OPTION_ITEM_LEVEL = "Add Item Level"
L.PANEL_OPTION_ITEM_LEVEL_TOOLTIP = "|cffFFFFFFEnabled:|r Add item level after the icon.\n|cffFFFFFFDisabled:|r No item level will be added behind the icon."
L.PANEL_OPTION_ITEM_LEVEL_EQUIP_ONLY = "Show for equipment only"
L.PANEL_OPTION_ITEM_LEVEL_EQUIP_ONLY_TOOLTIP = "|cffFFFFFFEnabled:|r Only add item level for equipment.\n|cffFFFFFFDisabled:|r Adds item level to any kind of item."
L.PANEL_OPTION_ITEM_TIER = "Add Tier Indicator"
L.PANEL_OPTION_ITEM_TIER_TOOLTIP = "|cffFFFFFFEnabled:|r Add crafting tier indicator after the icon.\n|cffFFFFFFDisabled:|r No crafting tier indicator will added behind the icon."
L.PANEL_OPTION_ITEM_TIER_AS_TEXT = "Show as text"
L.PANEL_OPTION_ITEM_TIER_AS_TEXT_TOOLTIP = "|cffFFFFFFEnabled:|r The indicator is shown as text.\n|cffFFFFFFDisabled:|r The indicator is shown as stars."
L.PANEL_CHAT_PREVIEW = "Chat Preview"

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
