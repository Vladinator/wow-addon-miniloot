--
-- If you want to help translate the AddOn please go to the CurseForge project page:
-- http://wow.curseforge.com/addons/miniloot/localization/
--

local addonName, ns = ...
ns.locale = {}

-- the client locale
local locale = GetLocale()

-- untranslated phrases get flagged
setmetatable(ns.locale, {
	__index = function(self, key)
		return "[" .. locale .. "]" .. tostring(key)
	end
})

-- shorthand table reference
local L = ns.locale

-- English
L.PARSER_OUTDATED_ERROR = "%s: %d/%d parsing tests succeeded. %d failed. The addon needs an update to fix this issue."
L.PARSER_FATAL_ERROR = "%s: Unable to show recent loot report. Please report this error to the developer: %s"
L.ITEM_ROLL_PASS_EVERYONE = "%s: Everyone Passed"
L.ITEM_ROLL_PASS = "%s: %s Passed"
L.ITEM_ROLL_DE = "%s: %s rolling for Disenchant"
L.ITEM_ROLL_GREED = "%s: %s rolling for Greed"
L.ITEM_ROLL_NEED = "%s: %s rolling for Need"
L.ITEM_ROLL_LOST = "%s: %s %s rolled %d |cffFF4800and lost|r"
L.ITEM_ROLL_INELIGIBLE = "%s: %s is ineligible"
L.ITEM_ROLL_DE_BY = "%s: Disenchanted by %s"
L.ITEM_ROLL_DE_RESULT = "%s: %s Disenchant rolled %d"
L.ITEM_ROLL_GREED_RESULT = "%s: %s Greed rolled %d"
L.ITEM_ROLL_NEED_RESULT = "%s: %s Need rolled %d"
L.ITEM_ROLL_WON = "%s: |cff00FF00%s won!|r"
L.OPTION_EXAMPLE = "Example: %s"
L.OPTION_COMMON_TITLE = "Common"
L.OPTION_COMMON_DESC = "These options affect multiple type of messages."
L.OPTION_ITEMS_TITLE = "Items"
L.OPTION_ITEMS_DESC = "Customize how item related messages appear."
L.OPTION_TRANSMOGRIFICATION_TITLE = "Transmogrification"
L.OPTION_TRANSMOGRIFICATION_DESC = "Customize how items with appearances appear."
L.OPTION_QUALITY_TITLE = "Quality"
L.OPTION_QUALITY_DESC = "Customize what item qualities are included. Only items at or above the selected thresholds will appear."
L.OPTION_ARTIFACT_TITLE = "Artifact"
L.OPTION_ARTIFACT_DESC = "Customize how artifact related messages appear."
L.OPTION_REPUTATION_TITLE = "Reputation"
L.OPTION_REPUTATION_DESC = "Customize how faction names are reported."
L.OPTION_TOOLTIPS_TITLE = "Tooltips"
L.OPTION_TOOLTIPS_DESC = "Select what kind of hyperlinks you wish to automatically appear when you hover over them in the chat."
L.OPTION_NAME_SHORT_TITLE = "Remove realm names"
L.OPTION_NAME_SHORT_DESC = "Enable to hide the realm name on characters from other realms."
L.OPTION_ITEM_SELF_PREFIX_TITLE = "Prefix own messages"
L.OPTION_ITEM_SELF_PREFIX_DESC = "Enable to prepend \"You\" to your own messages."
L.OPTION_ITEM_SELF_PREFIX_NAME_TITLE = "Prefix using character name"
L.OPTION_ITEM_SELF_PREFIX_NAME_DESC = "Enable to use your character name in your own messages."
L.OPTION_ITEM_SELF_TRIM_SOLO_TITLE = "Remove prefix if solo"
L.OPTION_ITEM_SELF_TRIM_SOLO_DESC = "Enable to remove the \"You\" prefix to your own messages. This only affects you when playing solo."
L.OPTION_ICON_TRIM_TITLE = "Icon trim"
L.OPTION_ICON_TRIM_DESC = "The amount of trim around icon textures. Set to 8 for default and recommended value. Set to 0 to disable trim behavior."
L.OPTION_ICON_SIZE_TITLE = "Icon size"
L.OPTION_ICON_SIZE_DESC = "The size of icons used in the chat. Set to 0 for automatic height."
L.OPTION_CHAT_FRAME_TITLE = "Select output chat frame"
L.OPTION_CHAT_FRAME_DESC = "Select a valid chat frame from the dropdown."
L.OPTION_ITEM_COUNT_BAGS_TITLE = "Count items in bag"
L.OPTION_ITEM_COUNT_BAGS_DESC = "Enable to append the amount of items you have in your bags."
L.OPTION_ITEM_COUNT_BAGS_INCLUDE_BANK_TITLE = "Include bank"
L.OPTION_ITEM_COUNT_BAGS_INCLUDE_BANK_DESC = "Check to include items in bank."
L.OPTION_ITEM_COUNT_BAGS_INCLUDE_CHARGES_TITLE = "Include charges"
L.OPTION_ITEM_COUNT_BAGS_INCLUDE_CHARGES_DESC = "Check to include amount of charges."
L.OPTION_ITEM_ALERT_TRANSMOG_TITLE = "Color uncollected appearances"
L.OPTION_ITEM_ALERT_TRANSMOG_DESC = "Enable to color uncollected appearances you are eligible for to obtain."
L.OPTION_ITEM_ALERT_TRANSMOG_EVERYTHING_TITLE = "Include items looted by others"
L.OPTION_ITEM_ALERT_TRANSMOG_EVERYTHING_DESC = "Enable to color uncollected appearances on items looted by others."
L.OPTION_ITEM_HIDE_JUNK_TITLE = "Hide junk items"
L.OPTION_ITEM_HIDE_JUNK_DESC = "Check to hide junk loot regardless of the options below."
L.OPTION_ITEM_QUALITY_PLAYER_TITLE = "Player (Solo)"
L.OPTION_ITEM_QUALITY_PLAYER_DESC = "Select the minimum or greater quality of items you wish to display."
L.OPTION_ITEM_QUALITY_GROUP_TITLE = "Group (5-man)"
L.OPTION_ITEM_QUALITY_GROUP_DESC = "Select the minimum or greater quality of items you wish to display."
L.OPTION_ITEM_QUALITY_RAID_TITLE = "Raid"
L.OPTION_ITEM_QUALITY_RAID_DESC = "Select the minimum or greater quality of items you wish to display."
L.OPTION_ARTIFACT_POWER_TITLE = "Show artifact power as loot"
L.OPTION_ARTIFACT_POWER_DESC = "Enable to summarize the gained power."
L.OPTION_FACTION_NAME_MINIFY_TITLE = "Shorten faction name"
L.OPTION_FACTION_NAME_MINIFY_DESC = "Enable to shorten names like \"Court of Farondis\" into \"CouOfFar\", and longer names like \"Order of the Awakened\" into \"OrOfThAw\"."
L.OPTION_FACTION_NAME_MINIFY_LENGTH_TITLE = "Maximum length"
L.OPTION_FACTION_NAME_MINIFY_LENGTH_DESC = "Set the desired length before shortening. Setting this to 10 means that \"Dalaran\" is shown as it is because it is less than ten characters."
L.OPTION_CHAT_TOOLTIP_ITEM_TITLE = "Show item tooltips"
L.OPTION_CHAT_TOOLTIP_ITEM_DESC = "Hover items in chat and display their tooltip."
L.OPTION_CHAT_TOOLTIP_CURRENCY_TITLE = "Show currency tooltips"
L.OPTION_CHAT_TOOLTIP_CURRENCY_DESC = "Hover currency in chat and display their tooltip."
L.OPTION_CHAT_TOOLTIP_SPELL_TITLE = "Show spell tooltips"
L.OPTION_CHAT_TOOLTIP_SPELL_DESC = "Hover spells in chat and display their tooltip."
L.OPTION_CHAT_TOOLTIP_TALENT_TITLE = "Show talent tooltips"
L.OPTION_CHAT_TOOLTIP_TALENT_DESC = "Hover talents in chat and display their tooltip."
L.OPTION_CHAT_TOOLTIP_QUEST_TITLE = "Show quest tooltips"
L.OPTION_CHAT_TOOLTIP_QUEST_DESC = "Hover quests in chat and display their tooltip."
L.OPTION_CHAT_TOOLTIP_ACHIEVEMENT_TITLE = "Show achievement tooltips"
L.OPTION_CHAT_TOOLTIP_ACHIEVEMENT_DESC = "Hover achievements in chat and display their tooltip."
L.OPTION_CHAT_TOOLTIP_TRADE_TITLE = "Show trade tooltips"
L.OPTION_CHAT_TOOLTIP_TRADE_DESC = "Hover trade links in chat and display their tooltip."
L.OPTION_CHAT_TOOLTIP_BATTLEPET_TITLE = "Show Battle Pet tooltips"
L.OPTION_CHAT_TOOLTIP_BATTLEPET_DESC = "Hover battle pet links in chat and display their tooltip."
L.OPTION_CHAT_TOOLTIP_GARRISON_TITLE = "Show Garrison and Order Hall tooltips"
L.OPTION_CHAT_TOOLTIP_GARRISON_DESC = "Hover Garrison and Order Hall links in chat and display their tooltip."
L.OPTION_CHAT_TOOLTIP_INSTANCELOCK_TITLE = "Show instance lock tooltips"
L.OPTION_CHAT_TOOLTIP_INSTANCELOCK_DESC = "Hover instance lock links in chat and display their tooltip."
L.OPTION_CHAT_TOOLTIP_DEATH_TITLE = "Show death tooltips"
L.OPTION_CHAT_TOOLTIP_DEATH_DESC = "Hover death links in chat and display their tooltip."
L.OPTION_CHAT_TOOLTIP_GLYPH_TITLE = "Show glyph tooltips"
L.OPTION_CHAT_TOOLTIP_GLYPH_DESC = "Hover glyph links in chat and display their tooltip."
L.OPTION_IGNORE_GROUP_TITLE = "Ignore"
L.OPTION_IGNORE_GROUP_DESC = "Select the type of messages you do not wish the addon to intercept and modify. Ignored messages appear as default."
L.OPTION_IGNORE_GROUP_REPUTATION_TITLE = "Reputation"
L.OPTION_IGNORE_GROUP_REPUTATION_DESC = "Reputation gain"
L.OPTION_IGNORE_GROUP_HONOR_TITLE = "Honor"
L.OPTION_IGNORE_GROUP_HONOR_DESC = "Honor gain"
L.OPTION_IGNORE_GROUP_EXPERIENCE_TITLE = "Experience"
L.OPTION_IGNORE_GROUP_EXPERIENCE_DESC = "Experience gain"
L.OPTION_IGNORE_GROUP_GUILD_EXPERIENCE_TITLE = "Guild experience"
L.OPTION_IGNORE_GROUP_GUILD_EXPERIENCE_DESC = "Guild experience gain"
L.OPTION_IGNORE_GROUP_FOLLOWER_EXPERIENCE_TITLE = "Follower experience"
L.OPTION_IGNORE_GROUP_FOLLOWER_EXPERIENCE_DESC = "Follower experience gain"
L.OPTION_IGNORE_GROUP_CURRENCY_TITLE = "Currency"
L.OPTION_IGNORE_GROUP_CURRENCY_DESC = "Currency gain"
L.OPTION_IGNORE_GROUP_MONEY_TITLE = "Money"
L.OPTION_IGNORE_GROUP_MONEY_DESC = "Money gain"
L.OPTION_IGNORE_GROUP_LOOT_ITEM_TITLE = "Loot"
L.OPTION_IGNORE_GROUP_LOOT_ITEM_DESC = "Item related messages"
L.OPTION_IGNORE_GROUP_LOOT_ROLL_DECISION_TITLE = "Roll decisions"
L.OPTION_IGNORE_GROUP_LOOT_ROLL_DECISION_DESC = "When someone selects to Need/Green/Disenchant/Pass on items being rolled for."
L.OPTION_IGNORE_GROUP_LOOT_ROLL_ROLLED_TITLE = "Roll results"
L.OPTION_IGNORE_GROUP_LOOT_ROLL_ROLLED_DESC = "When the roll is finalized and everyone starts rolling."
L.OPTION_IGNORE_GROUP_LOOT_ROLL_RESULT_TITLE = "Roll summary"
L.OPTION_IGNORE_GROUP_LOOT_ROLL_RESULT_DESC = "When the roll is finalized the winner roll is shown."
L.OPTION_IGNORE_GROUP_ARTIFACT_TITLE = "Artifact power"
L.OPTION_IGNORE_GROUP_ARTIFACT_DESC = "The default message when you add power to your artifact."
L.OPTION_IGNORE_GROUP_TRANSMOGRIFICATION_TITLE = "Transmogrification unlocks"
L.OPTION_IGNORE_GROUP_TRANSMOGRIFICATION_DESC = "The default message when looks are added to your collection."
L.OPTION_IGNORE_GROUP_IGNORE_TITLE = "Verbose quest rewards"
L.OPTION_IGNORE_GROUP_IGNORE_DESC = "Additional gold and experience messages when delivering quests."

-- German (Germany)
if locale == "deDE" then

--@localization(locale="deDE", format="lua_additive_table", handle-unlocalized="blank", escape-non-ascii=false, table-name="L")@

-- Spanish (Spain)
elseif locale == "esES" then

--@localization(locale="esES", format="lua_additive_table", handle-unlocalized="blank", escape-non-ascii=false, table-name="L")@

-- Spanish (Mexico)
elseif locale == "esMX" then

--@localization(locale="esMX", format="lua_additive_table", handle-unlocalized="blank", escape-non-ascii=false, table-name="L")@

-- French (France)
elseif locale == "frFR" then

--@localization(locale="frFR", format="lua_additive_table", handle-unlocalized="blank", escape-non-ascii=false, table-name="L")@

-- Italian (Italy)
elseif locale == "itIT" then

--@localization(locale="itIT", format="lua_additive_table", handle-unlocalized="blank", escape-non-ascii=false, table-name="L")@

-- Korean (Korea)
elseif locale == "koKR" then

--@localization(locale="koKR", format="lua_additive_table", handle-unlocalized="blank", escape-non-ascii=false, table-name="L")@

-- Portuguese (Brazil)
elseif locale == "ptBR" then

--@localization(locale="ptBR", format="lua_additive_table", handle-unlocalized="blank", escape-non-ascii=false, table-name="L")@

-- Russian (Russia)
elseif locale == "ruRU" then

--@localization(locale="ruRU", format="lua_additive_table", handle-unlocalized="blank", escape-non-ascii=false, table-name="L")@

-- Chinese (China) (simplified)
elseif locale == "zhCN" then

--@localization(locale="zhCN", format="lua_additive_table", handle-unlocalized="blank", escape-non-ascii=false, table-name="L")@

-- Chinese (Taiwan) (traditional)
elseif locale == "zhTW" then

--@localization(locale="zhTW", format="lua_additive_table", handle-unlocalized="blank", escape-non-ascii=false, table-name="L")@

end
