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
L.PANEL_OPTION_ENABLE_REMIX_MODE_TOOLTIP = "If Enabled, you'll be customizing a separate profile exclusive for Remix characters."
L.PANEL_OPTION_ENABLED = "Enable MiniLoot"
L.PANEL_OPTION_ENABLED_TOOLTIP = "If Disabled, the addon will be paused and your game will behave like it's not even installed."
L.PANEL_OPTION_ENABLE_TOOLTIPS = "Enable Hover Tooltips"
L.PANEL_OPTION_ENABLE_TOOLTIPS_TOOLTIP = "If Enabled, hovering over icons and supported links will make them appear above the Chat Frame."
L.PANEL_OPTION_CHATFRAME = "Active Chat Frame"
L.PANEL_OPTION_CHATFRAME_TOOLTIP = "Select the Chat Frame that you wish to process loot related messages."
L.PANEL_OPTION_DEBOUNCE = "Output Interval"
L.PANEL_OPTION_DEBOUNCE_TOOLTIP = "Output loot messages to the Chat Frame after this amount of seconds have passed."
L.PANEL_OPTION_DEBOUNCE_INCOMBAT = "Output during Combat"
L.PANEL_OPTION_DEBOUNCE_INCOMBAT_TOOLTIP = "If Enabled, the interval timer keeps counting even if in combat. If Disabled, the timer will pause and resume when combat ends."
L.PANEL_OPTION_SHORTEN_PLAYER_NAMES = "Short Player names"
L.PANEL_OPTION_SHORTEN_PLAYER_NAMES_TOOLTIP = "If Enabled, the realm part will be ommited from names. You can still click their name to initiate a whisper."
L.PANEL_OPTION_SHORTEN_FACTION_NAMES = "Short Faction names"
L.PANEL_OPTION_SHORTEN_FACTION_NAMES_TOOLTIP = "If Enabled, the faction names will be shortened down to take less space."
L.PANEL_OPTION_SHORTEN_FACTION_NAMES_LENGTH = "Short Faction name length"
L.PANEL_OPTION_SHORTEN_FACTION_NAMES_LENGTH_TOOLTIP = "Specify a maximum length limit when shortening faction names."
L.PANEL_OPTION_ICON_TRIM = "Icon Trim"
L.PANEL_OPTION_ICON_TRIM_TOOLTIP = "Specify how many pixels to remove from the edges of icons."
L.PANEL_OPTION_ICON_SIZE = "Icon Size"
L.PANEL_OPTION_ICON_SIZE_TOOLTIP = "Specify the size of the icon."
L.PANEL_OPTION_ITEM_COUNT = "Show Item Count"
L.PANEL_OPTION_ITEM_COUNT_TOOLTIP = "If Enabled, will display how many items you have in your inventory."
L.PANEL_OPTION_ITEM_COUNT_BANK = "Count Bank items"
L.PANEL_OPTION_ITEM_COUNT_BANK_TOOLTIP = ""
L.PANEL_OPTION_ITEM_COUNT_USES = "Count Charges on items"
L.PANEL_OPTION_ITEM_COUNT_USES_TOOLTIP = ""
L.PANEL_OPTION_ITEM_COUNT_REAGENT_BANK = "Count Reagent Bank items"
L.PANEL_OPTION_ITEM_COUNT_REAGENT_BANK_TOOLTIP = ""
L.PANEL_OPTION_ITEM_COUNT_CURRENCY = "Count Currency totals"
L.PANEL_OPTION_ITEM_COUNT_CURRENCY_TOOLTIP = ""
L.PANEL_OPTION_ITEM_LEVEL = "Add Item Level"
L.PANEL_OPTION_ITEM_LEVEL_TOOLTIP = "If Enabled, will add the item level after the item icon."
L.PANEL_OPTION_ITEM_LEVEL_EQUIP_ONLY = "Show for equipment only"
L.PANEL_OPTION_ITEM_LEVEL_EQUIP_ONLY_TOOLTIP = "If Enabled, will only add item level to equipment."
L.PANEL_OPTION_ITEM_TIER = "Add Tier Indicator"
L.PANEL_OPTION_ITEM_TIER_TOOLTIP = "If Enabled, adds the crafted tier indicator after the item icon."
L.PANEL_OPTION_ITEM_TIER_AS_TEXT = "Show as Stars"
L.PANEL_OPTION_ITEM_TIER_AS_TEXT_TOOLTIP = "If Enabled, displays the tier as stars instead of text."
-- L.PANEL_CHAT_PREVIEW_ORIGINAL = "Original Chat Frame"
-- L.PANEL_CHAT_PREVIEW_ORIGINAL_TOOLTIP = ""
-- L.PANEL_CHAT_PREVIEW_MINILOOT = "MiniLoot Chat Frame"
-- L.PANEL_CHAT_PREVIEW_MINILOOT_TOOLTIP = ""

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
