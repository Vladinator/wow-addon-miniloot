local addonName, ns = ...
ns.locale = {}

local locale = GetLocale()

setmetatable(ns.locale, {
	__index = function(self, key)
		return "[" .. locale .. "]" .. tostring(key)
	end
})

-- shorthand
local L = ns.locale

-- category groups
L.LABEL_GROUP_REPUTATION = "Reputation"
L.DESCRIPTION_GROUP_REPUTATION = "Reputation gain"
L.LABEL_GROUP_HONOR = "Honor"
L.DESCRIPTION_GROUP_HONOR = "Honor gain"
L.LABEL_GROUP_EXPERIENCE = "Experience"
L.DESCRIPTION_GROUP_EXPERIENCE = "Experience gain"
L.LABEL_GROUP_GUILD_EXPERIENCE = "Guild experience"
L.DESCRIPTION_GROUP_GUILD_EXPERIENCE = "Guild experience gain"
L.LABEL_GROUP_CURRENCY = "Currency"
L.DESCRIPTION_GROUP_CURRENCY = "Currency gain"
L.LABEL_GROUP_MONEY = "Money"
L.DESCRIPTION_GROUP_MONEY = "Money gain"
L.LABEL_GROUP_LOOT_ITEM = "Loot"
L.DESCRIPTION_GROUP_LOOT_ITEM = "Item related messages"
L.LABEL_GROUP_LOOT_ROLL_DECISION = "Roll decisions"
L.DESCRIPTION_GROUP_LOOT_ROLL_DECISION = "When someone selects to Need/Green/Disenchant/Pass on items being rolled for."
L.LABEL_GROUP_LOOT_ROLL_ROLLED = "Roll results"
L.DESCRIPTION_GROUP_LOOT_ROLL_ROLLED = "When the roll is finalized and everyone starts rolling."
L.LABEL_GROUP_LOOT_ROLL_RESULT = "Roll summary"
L.DESCRIPTION_GROUP_LOOT_ROLL_RESULT = "When the roll is finalized the winner roll is shown."
L.LABEL_GROUP_IGNORE = "Verbose quest rewards"
L.DESCRIPTION_GROUP_IGNORE = "Additional gold and experience messages when delivering quests."
L.LABEL_GROUP_TRANSMOGRIFICATION = "Transmogrification unlocks"
L.DESCRIPTION_GROUP_TRANSMOGRIFICATION = "The default message when looks are added to your collection."
L.LABEL_GROUP_ARTIFACT = "Artifact power"
L.DESCRIPTION_GROUP_ARTIFACT = "The default message when you add power to your artifact."
-- reputation
L.LABEL_REPUTATION = "Reputation"
L.DESCRIPTION_REPUTATION = "Shows reputation earned."
-- reputation (loss)
L.LABEL_REPUTATION_LOSS = "Reputation (loss)"
L.DESCRIPTION_REPUTATION_LOSS = "Shows reputation loss."
-- honor
L.LABEL_HONOR = "Honor"
L.DESCRIPTION_HONOR = "Shows honor earned."
-- experience
L.LABEL_EXPERIENCE = "Experience"
L.DESCRIPTION_EXPERIENCE = "Shows experience earned."
-- experience (loss)
L.LABEL_EXPERIENCE_LOSS = "Experience (loss)"
L.DESCRIPTION_EXPERIENCE_LOSS = "Shows experience loss."
-- experience (guild)
L.LABEL_EXPERIENCE_GUILD = "Experience (guild)"
L.DESCRIPTION_EXPERIENCE_GUILD = "Shows guild experience earned."
-- currency
L.LABEL_CURRENCY = "Currency"
L.DESCRIPTION_CURRENCY = "Shows currencies received."
-- money
L.LABEL_MONEY = "Money"
L.DESCRIPTION_MONEY = "Shows money earned."
-- loot
L.LABEL_LOOT = "Loot (player)"
L.DESCRIPTION_LOOT = "Shows player loot."
-- loot (target)
L.LABEL_LOOT_TARGET = "Loot (others)"
L.DESCRIPTION_LOOT_TARGET = "Shows others loot."
-- loot (roll, decision, pass, everyone)
L.LABEL_LOOT_ROLL_DECISION_EVERYONE_PASS = "Loot roll (everyone passes)"
L.DESCRIPTION_LOOT_ROLL_DECISION_EVERYONE_PASS = "Shows when everyone else passes."
-- loot (roll, decision, pass)
L.LABEL_LOOT_ROLL_DECISION_PASS = "Loot roll (selects to pass)"
L.DESCRIPTION_LOOT_ROLL_DECISION_PASS = "Shows when someone selects to pass."
-- loot (roll, decision, disenchant)
L.LABEL_LOOT_ROLL_DECISION_DE = "Loot roll (selects to disenchant)"
L.DESCRIPTION_LOOT_ROLL_DECISION_DE = "Shows when someone selects to disenchant."
-- loot (roll, decision, greed)
L.LABEL_LOOT_ROLL_DECISION_GREED = "Loot roll (selects to greed)"
L.DESCRIPTION_LOOT_ROLL_DECISION_GREED = "Shows when someone selects to greed."
-- loot (roll, decision, need)
L.LABEL_LOOT_ROLL_DECISION_NEED = "Loot roll (selects to need)"
L.DESCRIPTION_LOOT_ROLL_DECISION_NEED = "Shows when someone selects to need."
-- loot (roll, rolled, disenchant)
L.LABEL_LOOT_ROLLED_DE = "Loot roll (rolled disenchant)"
L.DESCRIPTION_LOOT_ROLLED_DE = "Shows the roll result for disenchant."
-- loot (roll, rolled, greed)
L.LABEL_LOOT_ROLLED_GREED = "Loot roll (rolled greed)"
L.DESCRIPTION_LOOT_ROLLED_GREED = "Shows the roll result for greed."
-- loot (roll, rolled, need)
L.LABEL_LOOT_ROLLED_NEED = "Loot roll (rolled need)"
L.DESCRIPTION_LOOT_ROLLED_NEED = "Shows the roll result for need."
-- loot (roll, result, lost, dynamic type disenchant/greed/need)
L.LABEL_LOOT_RESULT_DYNAMIC = "Loot roll (player lost the roll)"
L.DESCRIPTION_LOOT_RESULT_DYNAMIC = "Shows dynamic message of the players roll, even though they lost it."
-- loot (roll, result, started)
L.LABEL_LOOT_ROLL_STARTED = "Loot roll (roll started)"
L.DESCRIPTION_LOOT_ROLL_STARTED = "Shows what item we are rolling on."
-- loot (roll, result, disenchanted)
L.LABEL_LOOT_RESULT_DE_ENCHANTER = "Loot roll (who disenchanted)"
L.DESCRIPTION_LOOT_RESULT_DE_ENCHANTER = "Shows who disenchanted, and what item."
-- loot (roll, result, ineligible)
L.LABEL_LOOT_RESULT_INELIGIBLE = "Loot roll (player was ineligible)"
L.DESCRIPTION_LOOT_RESULT_INELIGIBLE = "Shows loot the player was ineligible to roll on."
-- loot (roll, result, disenchant)
L.LABEL_LOOT_RESULT_DE = "Loot roll (won the disenchant)"
L.DESCRIPTION_LOOT_RESULT_DE = "Shows the disenchant winner."
-- loot (roll, result, greed)
L.LABEL_LOOT_RESULT_GREED = "Loot roll (won the greed)"
L.DESCRIPTION_LOOT_RESULT_GREED = "Shows the greed winner."
-- loot (roll, result, need)
L.LABEL_LOOT_RESULT_NEED = "Loot roll (won the need)"
L.DESCRIPTION_LOOT_RESULT_NEED = "Shows the need winner."
-- loot (roll, result)
L.LABEL_LOOT_RESULT_WINNER = "Loot roll (winner)"
L.DESCRIPTION_LOOT_RESULT_WINNER = "Shows who received what item."
-- transmogrification
L.LABEL_TRANSMOGRIFICATION = "Transmogrification"
L.DESCRIPTION_TRANSMOGRIFICATION = "Check to disable filtering transmogrification messages."
-- ignore
L.LABEL_IGNORE = "Ignore"
L.DESCRIPTION_IGNORE = "Check to disable filtering handled messages."

-- German (Germany)
if locale == "deDE" then
-- Spanish (Spain)
elseif locale == "esES" then
-- Spanish (Mexico)
elseif locale == "esMX" then
-- French (France)
elseif locale == "frFR" then
-- Italian (Italy)
elseif locale == "itIT" then
-- Korean (Korea)
elseif locale == "koKR" then
-- Portuguese (Brazil)
elseif locale == "ptBR" then
-- Russian (Russia)
elseif locale == "ruRU" then
-- Chinese (China) (simplified)
elseif locale == "zhCN" then
-- Chinese (Taiwan) (traditional)
elseif locale == "zhTW" then
end
