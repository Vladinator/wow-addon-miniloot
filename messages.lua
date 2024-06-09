local ns = select(2, ...) ---@class MiniLootNS

---@enum MiniLootMessageGroup
local MiniLootMessageGroup = {
    Reputation = "Reputation",
    Honor = "Honor",
    Experience = "Experience",
    ExperienceLoss = "ExperienceLoss",
    -- GuildExperience = "GuildExperience",
    FollowerExperience = "FollowerExperience",
    Currency = "Currency",
    Money = "Money",
    Loot = "Loot",
    LootRollDecision = "LootRollDecision",
    LootRollRolled = "LootRollRolled",
    LootRollResult = "LootRollResult",
    AnimaPower = "AnimaPower",
    ArtifactPower = "ArtifactPower",
    Transmogrification = "Transmogrification",
    Ignore = "Ignore",
}

---@enum MiniLootMessageFormatField
local MiniLootMessageFormatField = {
    Name = "Name",
    NameExtra = "NameExtra",
    Value = "Value",
    ValueExtra = "ValueExtra",
    Bonus = "Bonus",
    BonusExtra = "BonusExtra",
    Link = "Link",
    LinkExtra = "LinkExtra",
}

---@enum MiniLootMessageFormatTokenType
local MiniLootMessageFormatTokenType = {
    Float = "Float",
    Link = "Link",
    Money = "Money",
    Number = "Number",
    String = "String",
    Target = "Target",
}

---@class MiniLootMessageFormatSimpleParserResult : table
---@field public Type any

---@alias MiniLootMessageFormatSimpleParser fun(results: MiniLootMessageFormatTokenResult[]): MiniLootMessageFormatSimpleParserResult|false?

---@alias MiniLootMessageFormatSimpleMap fun(result: MiniLootMessageFormatSimpleParserResult): MiniLootMessageFormatSimpleParserResult|false?

---@alias MiniLootMessageFormatSimpleParserMap fun(results: MiniLootMessageFormatTokenResult[], mapper: MiniLootMessageFormatSimpleMap): MiniLootMessageFormatSimpleParserResult|false?

---@class MiniLootMessageFormatToken
---@field public field MiniLootMessageFormatField
---@field public type MiniLootMessageFormatTokenType
---@field public fallbackValue? any

---@class MiniLootMessageFormatTokenResult : MiniLootMessageFormatToken
---@field public value any

---@class MiniLootMessageFormatSimpleResult : table

---@class MiniLootMessageFormat
---@field public formats string[]
---@field public patterns? string[]
---@field public tokens MiniLootMessageFormatToken[]
---@field public result? MiniLootMessageFormatSimpleParserResult
---@field public parser? MiniLootMessageFormatSimpleParser

---@class MiniLootMessage
---@field public group MiniLootMessageGroup
---@field public events WowEvent[]
---@field public formats MiniLootMessageFormat[]
---@field public result? MiniLootMessageFormatSimpleParserResult
---@field public tests? table<number, any[]>
---@field public skipAutoTests? boolean

---@class MiniLootMessagePartial : MiniLootMessage
---@field public group? MiniLootMessageGroup
---@field public events? WowEvent[]
---@field public formats? MiniLootMessageFormat[]
---@field public parser? MiniLootMessageFormatSimpleParser

---@type MiniLootMessage[]
local messages = {}

---@generic T
---@param tbl T[]
---@param shallow? boolean
---@return T[]
local function CopyTable(tbl, shallow)
	local temp = {}
	for k, v in pairs(tbl) do
		if type(v) == "table" and not shallow then
			temp[k] = CopyTable(v)
		else
			temp[k] = v
		end
	end
	return temp
end

---@generic T
---@param tbl T[]
---@param item T
function TableContains(tbl, item)
	for _, v in pairs(tbl) do
		if v == item then
			return true
		end
	end
	return false
end

---@generic T
---@param ... T[]
local function CombineTables(...)
    local tbls = {...}
    local first = tbls[1]
    local index = #first
    for i = 2, #tbls do
        local tbl = tbls[i]
        for _, v in ipairs(tbl) do
            if not TableContains(first, v) then
                index = index + 1
                first[index] = v
            end
        end
    end
    return first
end

---@generic T
---@param dst T[]
---@param src T[]
local function MergeTable(dst, src)
    for srck, srcv in pairs(src) do
        local srcvt = type(srcv)
        local srcva = srcvt == "table" and #srcv > 0
        local dstv = dst[srck]
        local dstvt = type(dstv)
        local dstva = dstvt == "table" and #dstv > 0
        if srcva and dstva then
            dst[srck] = CombineTables({}, dstv, srcv)
        elseif srcvt == "table" and dstvt == "table" then
            dst[srck] = MergeTable(MergeTable({}, dstv), srcv)
        else
            dst[srck] = srcv
        end
    end
    return dst
end

---@param ... MiniLootMessagePartial
local function AppendMessages(...)
    local data = {...}
    local first = data[1]
    local index = #messages
    for _, message in ipairs(data) do
        local temp = message
        if temp ~= first then
            temp = CopyTable(first)
            MergeTable(temp, message)
        end
        index = index + 1
        messages[index] = temp
    end
end

---@param pattern string
local function PatternToFormat(pattern)
    -- grammar from hell ( http://wow.gamepedia.com/UI_escape_sequences#Grammar )
    -- pattern = pattern
    --     :gsub("|4[^:]-:[^:]-:[^;]-;", "") -- "|4singular:plural1:plural2;"
    --     :gsub("|4[^:]-:[^;]-;", "") -- "number |4singular:plural;"
    --     :gsub("|1[^;]-;[^;]-;", "") -- "number |1singular;plural;"
    --     :gsub("|3-%d+%([^%)]-%)", "") -- "|3-formid(text)"
    --     :gsub("|2%S-?", "") -- "|2text"
    -- argument ordering
    for i = 1, 20 do
        pattern = pattern
            :gsub("%%" .. i .. "$s", "%%s")
            :gsub("%%" .. i .. "$d", "%%d")
            :gsub("%%" .. i .. "$f", "%%f")
    end
    -- standard tokens
    pattern = pattern
        :gsub("%%", "%%%%")
        :gsub("%.", "%%%.")
        :gsub("%?", "%%%?")
        :gsub("%+", "%%%+")
        :gsub("%-", "%%%-")
        :gsub("%(", "%%%(")
        :gsub("%)", "%%%)")
        :gsub("%[", "%%%[")
        :gsub("%]", "%%%]")
        :gsub("%%%%s", "(.-)")
        :gsub("%%%%d", "(%%d+)")
        :gsub("%%%%%%[%d%.%,]+f", "([%%d%%.%%,]+)")
    return pattern
end

local function FinalizeMessages()
    local numMessages = #messages

    for messageIndex = numMessages, 1, -1 do

        local message = messages[messageIndex]
        local messageFormats = message.formats
        local numMessageFormats = #messageFormats

        for messageFormatIndex = numMessageFormats, 1, -1 do

            local messageFormat = messageFormats[messageFormatIndex]
            local messageSubFormats = messageFormat.formats
            local numMessageSubFormats = #messageSubFormats

            for messageSubFormatIndex = numMessageSubFormats, 1, -1 do

                local messageSubFormat = messageSubFormats[messageSubFormatIndex]
                local messageSubFormatGlobal = _G[messageSubFormat]

                if type(messageSubFormatGlobal) ~= "string" then
                    numMessageSubFormats = numMessageSubFormats - 1
                    table.remove(messageSubFormats, messageSubFormatIndex)
                else
                    messageSubFormats[messageSubFormatIndex] = messageSubFormatGlobal
                end

            end

            if numMessageSubFormats == 0 then
                numMessageFormats = numMessageFormats - 1
                table.remove(messageFormats, messageFormatIndex)
            end

        end

        if numMessageFormats == 0 then
            numMessages = numMessages - 1
            table.remove(messages, messageIndex)
        end

    end

    for messageIndex = numMessages, 1, -1 do

        local message = messages[messageIndex]
        local messageFormats = message.formats
        local numMessageFormats = #messageFormats

        for messageFormatIndex = numMessageFormats, 1, -1 do

            local messageFormat = messageFormats[messageFormatIndex]
            local messageSubFormats = messageFormat.formats
            local numMessageSubFormats = #messageSubFormats

            local messageSubPatterns = messageFormat.patterns
            local numMessageSubPatterns = messageSubPatterns and #messageSubPatterns

            if not messageSubPatterns then
                messageSubPatterns = {}
                numMessageSubPatterns = #messageSubPatterns
                messageFormat.patterns = messageSubPatterns
            end

            for messageSubFormatIndex = numMessageSubFormats, 1, -1 do

                local messageSubFormat = messageSubFormats[messageSubFormatIndex]

                messageSubFormat = PatternToFormat(messageSubFormat)

                if not TableContains(messageSubPatterns, messageSubFormat) then
                    numMessageSubPatterns = numMessageSubPatterns + 1
                    messageSubPatterns[numMessageSubPatterns] = messageSubFormat
                end

            end

        end

    end
end

---@type MiniLootMessageFormatSimpleParser
local function SimpleParser(results)
    if not results or not results[1] then
        return
    end
    local temp = {}
    for _, item in ipairs(results) do
        temp[item.field] = item.value
    end
    return temp
end

---@type MiniLootMessageFormatSimpleParserMap
local function SimpleParserMap(results, map)
    local temp = SimpleParser(results)
    if not temp then
        return
    end
    if temp == false then
        return
    end
    local temp2 = map(temp)
    if temp2 ~= nil then
        return temp2
    end
    return temp
end

---@return MiniLootMessageFormatSimpleParserResult[]
local function CreateEmptyResults()
    local temp = {} ---@type MiniLootMessageFormatSimpleParserResult[]
    return temp
end

local ConvertStringToNumberPattern1 = "[\\" .. LARGE_NUMBER_SEPERATOR .. "]+"
local ConvertStringToNumberPattern2 = "[\\" .. DECIMAL_SEPERATOR .. "]"

---@param text string
---@return number?
local function ConvertStringToNumber(text)
    text = text
        :gsub(ConvertStringToNumberPattern1, "")
        :gsub(ConvertStringToNumberPattern2, ".")
        :gsub("[^%d%.]+", "")
    return tonumber(text)
end

local ConvertStringToMoneyPatterns = {
    Gold = PatternToFormat(GOLD_AMOUNT),
    Silver = PatternToFormat(SILVER_AMOUNT),
    Copper = PatternToFormat(COPPER_AMOUNT),
}

---@param text string
---@return number?
local function ConvertStringToMoney(text)
    local goldText = text:match(ConvertStringToMoneyPatterns.Gold)
    local silverText = text:match(ConvertStringToMoneyPatterns.Silver)
    local copperText = text:match(ConvertStringToMoneyPatterns.Copper)
    local money ---@type number?
    if goldText then
        money = (money or 0) + (tonumber(goldText) or 0)*COPPER_PER_GOLD
    end
    if silverText then
        money = (money or 0) + (tonumber(silverText) or 0)*COPPER_PER_SILVER
    end
    if copperText then
        money = (money or 0) + (tonumber(copperText) or 0)
    end
    return money
end

local ProcessTokensLinkPattern = "^%s*|h"

---@param token MiniLootMessageFormatToken
---@param match string
---@return string? key, any value
local function ProcessTokens(token, match)
    local tokenType = token.type

    if tokenType == MiniLootMessageFormatTokenType.Float
        or tokenType == MiniLootMessageFormatTokenType.Number then

        local value = ConvertStringToNumber(match)
        return token.field, value or token.fallbackValue

    elseif tokenType == MiniLootMessageFormatTokenType.Link
        or tokenType == MiniLootMessageFormatTokenType.String
        or tokenType == MiniLootMessageFormatTokenType.Target then

        local value ---@type string?

        if type(match) == "string" and match:len() > 0 then
            value = match
        end

        -- if value then
        --     if tokenType == MiniLootMessageFormatTokenType.Link then
        --         if not value:find(ProcessTokensLinkPattern) then
        --             value = nil
        --         end
        --     elseif tokenType == MiniLootMessageFormatTokenType.Target then
        --         if not UnitExists(value) then
        --             value = nil
        --         end
        --     end
        -- end

        return token.field, value or token.fallbackValue

    elseif tokenType == MiniLootMessageFormatTokenType.Money then

        local value = ConvertStringToMoney(match)
        return token.field, value or token.fallbackValue

    end
end

---@param messageFormat MiniLootMessageFormat
---@param matches string[]
---@return MiniLootMessageFormatSimpleParserResult?
local function ProcessMatchedToResult(messageFormat, matches)
    local tokens = messageFormat.tokens
    local numTokens = #tokens
    local result ---@type MiniLootMessageFormatSimpleParserResult?
    for i = 1, numTokens do
        local token = tokens[i]
        local match = matches[i]
        local key, value = ProcessTokens(token, match)
        if key then
            if not result then
                result = {}
            end
            result[key] = value
        end
    end
    return result
end

---@param results MiniLootMessageFormatSimpleParserResult[]
---@param event WowEvent
---@param text string
---@param playerName string
---@param languageName string
---@param channelName string
---@param playerName2 string
---@param specialFlags string
---@param zoneChannelID number
---@param channelIndex number
---@param channelBaseName string
---@param languageID number
---@param lineID number
---@param guid string
---@param bnSenderID number
---@param isMobile boolean
---@param isSubtitle boolean
---@param hideSenderInLetterbox boolean
---@param supressRaidIcons boolean
---@return number? numProcessed
local function ProcessChatMessage(results, event, text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons)
    local numResults = #results
    local numProcessed
    for _, message in ipairs(messages) do
        if TableContains(message.events, event) then
            for _, messageFormat in ipairs(message.formats) do
                local messageFormatPatterns = messageFormat.patterns
                if messageFormatPatterns then
                    for _, messageFormatPattern in ipairs(messageFormatPatterns) do
                        local temp = {text:match(messageFormatPattern)} ---@type string[]
                        if temp[1] then
                            local result = ProcessMatchedToResult(messageFormat, temp)
                            if result then
                                numProcessed = (numProcessed or 0) + 1
                                numResults = numResults + 1
                                results[numResults] = result
                            end
                        end
                    end
                end
            end
        end
    end
    return numProcessed
end

do

    -- Reputation
    do

        ---@alias MiniLootMessageFormatSimpleParserResultReputationKeys "Name"|"Value"|"Bonus"|"BonusExtra"

        ---@alias MiniLootMessageFormatSimpleParserResultReputationTypes "FallbackReputation"

        ---@see MiniLootMessageFormatSimpleParserResult
        ---@class MiniLootMessageFormatSimpleParserResultReputation
        ---@field public Name string
        ---@field public Value number?
        ---@field public Bonus number?
        ---@field public BonusExtra number?

        ---@class MiniLootMessageFormatSimpleParserResultReputationArgs : MiniLootMessageFormatSimpleParserResultReputation
        ---@field public Name? string
        ---@field public Type MiniLootMessageFormatSimpleParserResultReputationTypes

        ---@type table<MiniLootMessageFormatSimpleParserResultReputationKeys, MiniLootMessageFormatToken>
        local Tokens = {
            Name = {
                field = MiniLootMessageFormatField.Name,
                type = MiniLootMessageFormatTokenType.String,
            },
            Value = {
                field = MiniLootMessageFormatField.Value,
                type = MiniLootMessageFormatTokenType.Number,
            },
            Bonus = {
                field = MiniLootMessageFormatField.Bonus,
                type = MiniLootMessageFormatTokenType.Float,
            },
            BonusExtra = {
                field = MiniLootMessageFormatField.BonusExtra,
                type = MiniLootMessageFormatTokenType.Float,
            },
        }

        AppendMessages(
            {
                group = MiniLootMessageGroup.Reputation,
                events = {
                    "CHAT_MSG_COMBAT_FACTION_CHANGE",
                },
                ---@type MiniLootMessageFormatSimpleParserResultReputationArgs
                result = {
                    Type = "FallbackReputation",
                },
            },
            {
                formats = {
                    {
                        formats = {
                            "FACTION_STANDING_INCREASED_DOUBLE_BONUS",
                            "FACTION_STANDING_INCREASED_BONUS",
                        },
                        tokens = {
                            Tokens.Name,
                            Tokens.Value,
                            Tokens.Bonus,
                            Tokens.BonusExtra,
                        },
                    },
                    {
                        formats = {
                            "FACTION_STANDING_INCREASED_ACH_BONUS",
                            "FACTION_STANDING_INCREASED",
                            "FACTION_STANDING_INCREASED_GENERIC",
                        },
                        tokens = {
                            Tokens.Name,
                            Tokens.Value,
                            Tokens.Bonus,
                        },
                    },
                    {
                        formats = {
                            "FACTION_STANDING_DECREASED",
                            "FACTION_STANDING_DECREASED_GENERIC",
                        },
                        tokens = {
                            Tokens.Name,
                            Tokens.Value,
                        },
                    },
                },
            }
        )

    end

    -- Honor
    do

        ---@alias MiniLootMessageFormatSimpleParserResultHonorKeys "Name"|"NameExtra"|"Value"

        ---@alias MiniLootMessageFormatSimpleParserResultHonorTypes "FallbackHonor"

        ---@see MiniLootMessageFormatSimpleParserResult
        ---@class MiniLootMessageFormatSimpleParserResultHonor
        ---@field public Name? string
        ---@field public NameExtra? string
        ---@field public Value number

        ---@class MiniLootMessageFormatSimpleParserResultHonorArgs : MiniLootMessageFormatSimpleParserResultHonor
        ---@field public Value? number
        ---@field public Type MiniLootMessageFormatSimpleParserResultHonorTypes

        ---@type table<MiniLootMessageFormatSimpleParserResultHonorKeys, MiniLootMessageFormatToken>
        local Tokens = {
            Name = {
                field = MiniLootMessageFormatField.Name,
                type = MiniLootMessageFormatTokenType.String,
            },
            NameExtra = {
                field = MiniLootMessageFormatField.NameExtra,
                type = MiniLootMessageFormatTokenType.String,
            },
            Value = {
                field = MiniLootMessageFormatField.Value,
                type = MiniLootMessageFormatTokenType.Number,
            },
        }

        AppendMessages(
            {
                group = MiniLootMessageGroup.Honor,
                events = {
                    "CHAT_MSG_COMBAT_HONOR_GAIN",
                },
                ---@type MiniLootMessageFormatSimpleParserResultHonorArgs
                result = {
                    Type = "FallbackHonor",
                },
            },
            {
                formats = {
                    {
                        formats = {
                            "COMBATLOG_HONORGAIN",
                        },
                        tokens = {
                            Tokens.Name,
                            Tokens.NameExtra,
                            Tokens.Value,
                        },
                    },
                    {
                        formats = {
                            "COMBATLOG_HONORGAIN_NO_RANK",
                        },
                        tokens = {
                            Tokens.Name,
                            Tokens.Value,
                        },
                    },
                    {
                        formats = {
                            "COMBATLOG_HONORAWARD",
                        },
                        tokens = {
                            Tokens.Value,
                        },
                    },
                },
            }
        )

    end

    -- Experience
    do

        ---@alias MiniLootMessageFormatSimpleParserResultExperienceKeys "Name"|"Value"|"ValueExtra"|"Bonus"|"BonusExtra"

        ---@alias MiniLootMessageFormatSimpleParserResultExperienceTypes "FallbackExperience"

        ---@see MiniLootMessageFormatSimpleParserResult
        ---@class MiniLootMessageFormatSimpleParserResultExperience
        ---@field public Name? string
        ---@field public Value number
        ---@field public ValueExtra? number
        ---@field public Bonus? string
        ---@field public BonusExtra? string

        ---@class MiniLootMessageFormatSimpleParserResultExperienceArgs : MiniLootMessageFormatSimpleParserResultExperience
        ---@field public Value? number
        ---@field public Type MiniLootMessageFormatSimpleParserResultExperienceTypes

        ---@type table<MiniLootMessageFormatSimpleParserResultExperienceKeys, MiniLootMessageFormatToken>
        local Tokens = {
            Name = {
                field = MiniLootMessageFormatField.Name,
                type = MiniLootMessageFormatTokenType.String,
            },
            Value = {
                field = MiniLootMessageFormatField.Value,
                type = MiniLootMessageFormatTokenType.Number,
            },
            ValueExtra = {
                field = MiniLootMessageFormatField.ValueExtra,
                type = MiniLootMessageFormatTokenType.Number,
            },
            Bonus = {
                field = MiniLootMessageFormatField.Bonus,
                type = MiniLootMessageFormatTokenType.String,
            },
            BonusExtra = {
                field = MiniLootMessageFormatField.BonusExtra,
                type = MiniLootMessageFormatTokenType.String,
            },
        }

        AppendMessages(
            {
                group = MiniLootMessageGroup.Experience,
                ---@type MiniLootMessageFormatSimpleParserResultExperienceArgs
                result = {
                    Type = "FallbackExperience",
                },
            },
            {
                events = {
                    "CHAT_MSG_SYSTEM",
                },
                formats = {
                    {
                        formats = {
                            "ERR_ZONE_EXPLORED_XP",
                        },
                        tokens = {
                            Tokens.Name,
                            Tokens.Value,
                        },
                    },
                },
            },
            {
                events = {
                    "CHAT_MSG_COMBAT_XP_GAIN",
                },
                formats = {
                    {
                        formats = {
                            "COMBATLOG_XPGAIN_EXHAUSTION1_RAID",
                            "COMBATLOG_XPGAIN_EXHAUSTION1_GROUP",
                            "COMBATLOG_XPGAIN_EXHAUSTION1",
                            "COMBATLOG_XPGAIN_EXHAUSTION2_RAID",
                            "COMBATLOG_XPGAIN_EXHAUSTION2_GROUP",
                            "COMBATLOG_XPGAIN_EXHAUSTION2",
                            "COMBATLOG_XPGAIN_EXHAUSTION4_RAID",
                            "COMBATLOG_XPGAIN_EXHAUSTION4_GROUP",
                            "COMBATLOG_XPGAIN_EXHAUSTION4",
                            "COMBATLOG_XPGAIN_EXHAUSTION5_RAID",
                            "COMBATLOG_XPGAIN_EXHAUSTION5_GROUP",
                            "COMBATLOG_XPGAIN_EXHAUSTION5",
                        },
                        tokens = {
                            Tokens.Name,
                            Tokens.Value,
                            Tokens.Bonus,
                            Tokens.BonusExtra,
                        },
                    },
                    {
                        formats = {
                            "COMBATLOG_XPGAIN_FIRSTPERSON_RAID",
                            "COMBATLOG_XPGAIN_FIRSTPERSON_GROUP",
                            "COMBATLOG_XPGAIN_FIRSTPERSON",
                        },
                        tokens = {
                            Tokens.Name,
                            Tokens.Value,
                            Tokens.ValueExtra,
                        },
                    },
                    {
                        formats = {
                            "COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED_RAID",
                            "COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED_GROUP",
                            "COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED",
                        },
                        tokens = {
                            Tokens.Value,
                            Tokens.ValueExtra,
                        },
                    },
                    {
                        formats = {
                            "COMBATLOG_XPGAIN_QUEST",
                        },
                        tokens = {
                            Tokens.Value,
                            Tokens.Bonus,
                            Tokens.BonusExtra,
                        },
                    },
                },
            },
            {
                group = MiniLootMessageGroup.ExperienceLoss,
                events = {
                    "CHAT_MSG_COMBAT_XP_GAIN",
                },
                parser = function(results)
                    return SimpleParserMap(
                        results,
                        ---@param result MiniLootMessageFormatSimpleParserResultExperience
                        function(result)
                            result.Value = -result.Value
                        end
                    )
                end,
                formats = {
                    {
                        formats = {
                            "COMBATLOG_XPLOSS_FIRSTPERSON_UNNAMED",
                        },
                        tokens = {
                            Tokens.Value,
                        },
                    },
                },
            }
        )

    end

    -- Guild Experience
    --[[
    do

        ---@alias MiniLootMessageFormatSimpleParserResultGuildExperienceKeys "Value"

        ---@alias MiniLootMessageFormatSimpleParserResultGuildExperienceTypes "FallbackGuildExperience"

        ---@see MiniLootMessageFormatSimpleParserResult
        ---@class MiniLootMessageFormatSimpleParserResultGuildExperience
        ---@field public Value number

        ---@class MiniLootMessageFormatSimpleParserResultGuildExperienceArgs : MiniLootMessageFormatSimpleParserResultGuildExperience
        ---@field public Value? number
        ---@field public Type MiniLootMessageFormatSimpleParserResultGuildExperienceTypes

        ---@type table<MiniLootMessageFormatSimpleParserResultGuildExperienceKeys, MiniLootMessageFormatToken>
        local Tokens = {
            Value = {
                field = MiniLootMessageFormatField.Value,
                type = MiniLootMessageFormatTokenType.Number,
            },
        }

        AppendMessages(
            {
                group = MiniLootMessageGroup.GuildExperience,
                events = {
                    "CHAT_MSG_COMBAT_GUILD_XP_GAIN",
                },
                ---@type MiniLootMessageFormatSimpleParserResultGuildExperienceArgs
                result = {
                    Type = "FallbackGuildExperience",
                },
            },
            {
                formats = {
                    {
                        formats = {
                            "COMBATLOG_GUILD_XPGAIN",
                        },
                        tokens = {
                            Tokens.Value,
                        },
                    },
                },
            }
        )

    end
    --]]

    -- Follower Experience
    do

        ---@alias MiniLootMessageFormatSimpleParserResultFollowerExperienceKeys "Name"|"Value"

        ---@alias MiniLootMessageFormatSimpleParserResultFollowerExperienceTypes "FallbackFollowerExperience"

        ---@see MiniLootMessageFormatSimpleParserResult
        ---@class MiniLootMessageFormatSimpleParserResultFollowerExperience
        ---@field public Name string
        ---@field public Value number

        ---@class MiniLootMessageFormatSimpleParserResultFollowerExperienceArgs : MiniLootMessageFormatSimpleParserResultFollowerExperience
        ---@field public Name? string
        ---@field public Value? number
        ---@field public Type MiniLootMessageFormatSimpleParserResultFollowerExperienceTypes

        ---@type table<MiniLootMessageFormatSimpleParserResultFollowerExperienceKeys, MiniLootMessageFormatToken>
        local Tokens = {
            Name = {
                field = MiniLootMessageFormatField.Name,
                type = MiniLootMessageFormatTokenType.String,
            },
            Value = {
                field = MiniLootMessageFormatField.Value,
                type = MiniLootMessageFormatTokenType.Number,
            },
        }

        AppendMessages(
            {
                group = MiniLootMessageGroup.FollowerExperience,
                events = {
                    "CHAT_MSG_SYSTEM",
                    "CHAT_MSG_COMBAT_XP_GAIN",
                },
                ---@type MiniLootMessageFormatSimpleParserResultFollowerExperienceArgs
                result = {
                    Type = "FallbackFollowerExperience",
                },
            },
            {
                formats = {
                    {
                        formats = {
                            "GARRISON_FOLLOWER_XP_ADDED_ZONE_SUPPORT",
                        },
                        tokens = {
                            Tokens.Name,
                            Tokens.Value,
                        },
                    },
                },
            }
        )

    end

    -- Currency
    do

        ---@alias MiniLootMessageFormatSimpleParserResultCurrencyKeys "Link"|"Value"

        ---@alias MiniLootMessageFormatSimpleParserResultCurrencyTypes "FallbackCurrency"

        ---@see MiniLootMessageFormatSimpleParserResult
        ---@class MiniLootMessageFormatSimpleParserResultCurrency
        ---@field public Link string
        ---@field public Value? number

        ---@class MiniLootMessageFormatSimpleParserResultCurrencyArgs : MiniLootMessageFormatSimpleParserResultCurrency
        ---@field public Link? string
        ---@field public Type MiniLootMessageFormatSimpleParserResultCurrencyTypes

        ---@type table<MiniLootMessageFormatSimpleParserResultCurrencyKeys, MiniLootMessageFormatToken>
        local Tokens = {
            Link = {
                field = MiniLootMessageFormatField.Link,
                type = MiniLootMessageFormatTokenType.Link,
            },
            Value = {
                field = MiniLootMessageFormatField.Value,
                type = MiniLootMessageFormatTokenType.Number,
            },
        }

        AppendMessages(
            {
                group = MiniLootMessageGroup.Currency,
                events = {
                    "CHAT_MSG_CURRENCY",
                },
                ---@type MiniLootMessageFormatSimpleParserResultCurrencyArgs
                result = {
                    Type = "FallbackCurrency",
                },
            },
            {
                formats = {
                    {
                        formats = {
                            "CURRENCY_GAINED_MULTIPLE_BONUS",
                            "CURRENCY_GAINED_MULTIPLE",
                            "CURRENCY_GAINED",
                            "LOOT_CURRENCY_REFUND",
                        },
                        tokens = {
                            Tokens.Link,
                            Tokens.Value,
                        },
                    },
                },
            }
        )

    end

    -- Money
    do

        ---@alias MiniLootMessageFormatSimpleParserResultMoneyKeys "Name"|"Value"|"ValueExtra"

        ---@alias MiniLootMessageFormatSimpleParserResultMoneyTypes "FallbackMoney"

        ---@see MiniLootMessageFormatSimpleParserResult
        ---@class MiniLootMessageFormatSimpleParserResultMoney
        ---@field public Name? string
        ---@field public Value number
        ---@field public ValueExtra? number

        ---@class MiniLootMessageFormatSimpleParserResultMoneyArgs : MiniLootMessageFormatSimpleParserResultMoney
        ---@field public Value? number
        ---@field public Type MiniLootMessageFormatSimpleParserResultMoneyTypes

        ---@type table<MiniLootMessageFormatSimpleParserResultMoneyKeys, MiniLootMessageFormatToken>
        local Tokens = {
            Name = {
                field = MiniLootMessageFormatField.Name,
                type = MiniLootMessageFormatTokenType.Target,
            },
            Value = {
                field = MiniLootMessageFormatField.Bonus,
                type = MiniLootMessageFormatTokenType.Money,
            },
            ValueExtra = {
                field = MiniLootMessageFormatField.BonusExtra,
                type = MiniLootMessageFormatTokenType.Money,
            },
        }

        AppendMessages(
            {
                group = MiniLootMessageGroup.Money,
                events = {
                    "CHAT_MSG_MONEY",
                },
                ---@type MiniLootMessageFormatSimpleParserResultMoneyArgs
                result = {
                    Type = "FallbackMoney",
                },
            },
            {
                formats = {
                    {
                        formats = {
                            "YOU_LOOT_MONEY_GUILD",
                            "YOU_LOOT_MONEY",
                            "LOOT_MONEY_SPLIT_GUILD",
                            "LOOT_MONEY_SPLIT",
                            "LOOT_MONEY_REFUND",
                        },
                        tokens = {
                            Tokens.Value,
                            Tokens.ValueExtra,
                        },
                    },
                    {
                        formats = {
                            "LOOT_MONEY",
                        },
                        tokens = {
                            Tokens.Name,
                            Tokens.Value,
                        },
                    },
                },
            }
        )

    end

    -- Loot
    do

        ---@alias MiniLootMessageFormatSimpleParserResultLootKeys "Name"|"Link"|"Value"

        ---@alias MiniLootMessageFormatSimpleParserResultLootTypes "FallbackLoot"

        ---@see MiniLootMessageFormatSimpleParserResult
        ---@class MiniLootMessageFormatSimpleParserResultLoot
        ---@field public Name? string
        ---@field public Link string
        ---@field public Value? number

        ---@class MiniLootMessageFormatSimpleParserResultLootArgs : MiniLootMessageFormatSimpleParserResultLoot
        ---@field public Link? string
        ---@field public Type MiniLootMessageFormatSimpleParserResultLootTypes

        ---@type table<MiniLootMessageFormatSimpleParserResultLootKeys, MiniLootMessageFormatToken>
        local Tokens = {
            Name = {
                field = MiniLootMessageFormatField.Name,
                type = MiniLootMessageFormatTokenType.Target,
            },
            Link = {
                field = MiniLootMessageFormatField.Link,
                type = MiniLootMessageFormatTokenType.Link,
            },
            Value = {
                field = MiniLootMessageFormatField.Value,
                type = MiniLootMessageFormatTokenType.Number,
            },
        }

        AppendMessages(
            {
                group = MiniLootMessageGroup.Loot,
                events = {
                    "CHAT_MSG_LOOT",
                },
                ---@type MiniLootMessageFormatSimpleParserResultLootArgs
                result = {
                    Type = "FallbackLoot",
                },
            },
            {
                formats = {
                    {
                        formats = {
                            "CREATED_ITEM_MULTIPLE",
                            "CREATED_ITEM",
                        },
                        tokens = {
                            Tokens.Name,
                            Tokens.Link,
                            Tokens.Value,
                        },
                    },
                    {
                        formats = {
                            "LOOT_ITEM_BONUS_ROLL_SELF_MULTIPLE",
                            "LOOT_ITEM_BONUS_ROLL_SELF",
                            "LOOT_ITEM_SELF_MULTIPLE",
                            "LOOT_ITEM_SELF",
                            "LOOT_ITEM_PUSHED_SELF_MULTIPLE",
                            "LOOT_ITEM_PUSHED_SELF",
                            "LOOT_ITEM_CREATED_SELF_MULTIPLE",
                            "LOOT_ITEM_CREATED_SELF",
                            "LOOT_ITEM_REFUND_MULTIPLE",
                            "LOOT_ITEM_REFUND",
                        },
                        tokens = {
                            Tokens.Link,
                            Tokens.Value,
                        },
                    },
                    {
                        formats = {
                            "LOOT_ITEM_BONUS_ROLL_MULTIPLE",
                            "LOOT_ITEM_BONUS_ROLL",
                            "LOOT_ITEM_MULTIPLE",
                            "LOOT_ITEM",
                            "LOOT_ITEM_PUSHED_MULTIPLE",
                            "LOOT_ITEM_PUSHED",
                        },
                        tokens = {
                            Tokens.Name,
                            Tokens.Link,
                            Tokens.Value,
                        },
                    },
                },
            }
        )

    end

    -- Loot Roll
    do

        ---@alias MiniLootMessageFormatSimpleParserResultLootRollKeys "Name"|"Link"|"Value"|"ValueExtra"|"NameExtra"

        ---@alias MiniLootMessageFormatSimpleParserResultLootRollTypes
        ---|"FallbackRoll"
        ---|"AllPass"
        ---|"YouPass"
        ---|"Pass"
        ---|"YouDisenchant"
        ---|"Disenchant"
        ---|"YouGreed"
        ---|"Greed"
        ---|"YouNeed"
        ---|"Need"
        ---|"DisenchantRoll"
        ---|"GreedRoll"
        ---|"NeedRoll"
        ---|"DisenchantCredit"
        ---|"YouDisenchantResult"
        ---|"DisenchantResult"
        ---|"YouGreedResult"
        ---|"GreedResult"
        ---|"YouNeedResult"
        ---|"NeedResult"
        ---|"IneligibleResult"
        ---|"YouLostResult"
        ---|"LostResult"
        ---|"YouWinnerResult"
        ---|"WinnerResult"
        ---|"StartRoll"

        ---@see MiniLootMessageFormatSimpleParserResult
        ---@class MiniLootMessageFormatSimpleParserResultLootRoll
        ---@field public Name? string
        ---@field public Link number
        ---@field public Value? number
        ---@field public ValueExtra? number

        ---@class MiniLootMessageFormatSimpleParserResultLootRollArgs : MiniLootMessageFormatSimpleParserResultLootRoll
        ---@field public Link? number
        ---@field public Type MiniLootMessageFormatSimpleParserResultLootRollTypes

        ---@class MiniLootMessageFormatLootRoll : MiniLootMessageFormat
        ---@field public result? MiniLootMessageFormatSimpleParserResultLootRollArgs

        ---@type table<MiniLootMessageFormatSimpleParserResultLootRollKeys, MiniLootMessageFormatToken>
        local Tokens = {
            Name = {
                field = MiniLootMessageFormatField.Name,
                type = MiniLootMessageFormatTokenType.Target,
            },
            Link = {
                field = MiniLootMessageFormatField.Link,
                type = MiniLootMessageFormatTokenType.Link,
            },
            Value = {
                field = MiniLootMessageFormatField.Value,
                type = MiniLootMessageFormatTokenType.Number,
            },
            ValueExtra = {
                field = MiniLootMessageFormatField.ValueExtra,
                type = MiniLootMessageFormatTokenType.Number,
            },
            NameExtra = {
                field = MiniLootMessageFormatField.NameExtra,
                type = MiniLootMessageFormatTokenType.String,
            },
        }

        AppendMessages(
            {
                group = MiniLootMessageGroup.LootRollDecision,
                events = {
                    "CHAT_MSG_LOOT",
                },
                ---@type MiniLootMessageFormatSimpleParserResultLootRollArgs
                result = {
                    Type = "FallbackRoll",
                },
            },
            {
                ---@type MiniLootMessageFormatLootRoll[]
                formats = {
                    {
                        formats = {
                            "LOOT_ROLL_ALL_PASSED",
                        },
                        tokens = {
                            Tokens.Value,
                            Tokens.Link,
                        },
                        result = {
                            Type = "AllPass",
                        },
                    },
                    {
                        formats = {
                            "LOOT_ROLL_PASSED_SELF_AUTO",
                            "LOOT_ROLL_PASSED_SELF",
                        },
                        tokens = {
                            Tokens.Value,
                            Tokens.Link,
                            Tokens.ValueExtra,
                        },
                        result = {
                            Type = "YouPass",
                        },
                    },
                    {
                        formats = {
                            "LOOT_ROLL_PASSED_AUTO",
                            "LOOT_ROLL_PASSED_AUTO_FEMALE",
                            "LOOT_ROLL_PASSED",
                        },
                        tokens = {
                            Tokens.Name,
                            Tokens.Link,
                        },
                        result = {
                            Type = "Pass",
                        },
                    },
                    {
                        formats = {
                            "LOOT_ROLL_DISENCHANT_SELF",
                        },
                        tokens = {
                            Tokens.Value,
                            Tokens.Link,
                        },
                        result = {
                            Type = "YouDisenchant",
                        },
                    },
                    {
                        formats = {
                            "LOOT_ROLL_DISENCHANT",
                        },
                        tokens = {
                            Tokens.Name,
                            Tokens.Link,
                        },
                        result = {
                            Type = "Disenchant",
                        },
                    },
                    {
                        formats = {
                            "LOOT_ROLL_GREED_SELF",
                        },
                        tokens = {
                            Tokens.Value,
                            Tokens.Link,
                            Tokens.ValueExtra,
                        },
                        result = {
                            Type = "YouGreed",
                        },
                    },
                    {
                        formats = {
                            "LOOT_ROLL_GREED",
                        },
                        tokens = {
                            Tokens.Name,
                            Tokens.Link,
                        },
                        result = {
                            Type = "Greed",
                        },
                    },
                    {
                        formats = {
                            "LOOT_ROLL_NEED_SELF",
                        },
                        tokens = {
                            Tokens.Value,
                            Tokens.Link,
                            Tokens.ValueExtra,
                        },
                        result = {
                            Type = "YouNeed",
                        },
                    },
                    {
                        formats = {
                            "LOOT_ROLL_NEED",
                        },
                        tokens = {
                            Tokens.Name,
                            Tokens.Link,
                        },
                        result = {
                            Type = "Need",
                        },
                    },
                    {
                        formats = {
                            "LOOT_ROLL_ROLLED_DE",
                        },
                        tokens = {
                            Tokens.Value,
                            Tokens.Link,
                            Tokens.Name,
                        },
                        result = {
                            Type = "DisenchantRoll",
                        },
                    },
                    {
                        formats = {
                            "LOOT_ROLL_ROLLED_GREED",
                        },
                        tokens = {
                            Tokens.Value,
                            Tokens.Link,
                            Tokens.Name,
                        },
                        result = {
                            Type = "GreedRoll",
                        },
                    },
                    {
                        formats = {
                            "LOOT_ROLL_ROLLED_NEED_ROLE_BONUS",
                            "LOOT_ROLL_ROLLED_NEED",
                        },
                        tokens = {
                            Tokens.Value,
                            Tokens.Link,
                            Tokens.Name,
                        },
                        result = {
                            Type = "NeedRoll",
                        },
                    },
                    {
                        formats = {
                            "LOOT_DISENCHANT_CREDIT",
                        },
                        tokens = {
                            Tokens.Link,
                            Tokens.Name,
                        },
                        result = {
                            Type = "DisenchantCredit",
                        },
                    },
                    {
                        formats = {
                            "LOOT_ITEM_WHILE_PLAYER_INELIGIBLE",
                        },
                        tokens = {
                            Tokens.Name,
                            Tokens.Link,
                        },
                        result = {
                            Type = "IneligibleResult",
                        },
                    },
                    {
                        formats = {
                            "LOOT_ROLL_YOU_WON_NO_SPAM_DE",
                        },
                        tokens = {
                            Tokens.Value,
                            Tokens.ValueExtra,
                            Tokens.Link,
                        },
                        result = {
                            Type = "YouDisenchantResult",
                        },
                    },
                    {
                        formats = {
                            "LOOT_ROLL_WON_NO_SPAM_DE",
                        },
                        tokens = {
                            Tokens.Value,
                            Tokens.Name,
                            Tokens.ValueExtra,
                            Tokens.Link,
                        },
                        result = {
                            Type = "DisenchantResult",
                        },
                    },
                    {
                        formats = {
                            "LOOT_ROLL_YOU_WON_NO_SPAM_GREED",
                        },
                        tokens = {
                            Tokens.Value,
                            Tokens.ValueExtra,
                            Tokens.Link,
                        },
                        result = {
                            Type = "YouGreedResult",
                        },
                    },
                    {
                        formats = {
                            "LOOT_ROLL_WON_NO_SPAM_GREED",
                        },
                        tokens = {
                            Tokens.Value,
                            Tokens.Name,
                            Tokens.ValueExtra,
                            Tokens.Link,
                        },
                        result = {
                            Type = "GreedResult",
                        },
                    },
                    {
                        formats = {
                            "LOOT_ROLL_YOU_WON_NO_SPAM_NEED",
                        },
                        tokens = {
                            Tokens.Value,
                            Tokens.ValueExtra,
                            Tokens.Link,
                        },
                        result = {
                            Type = "YouNeedResult",
                        },
                    },
                    {
                        formats = {
                            "LOOT_ROLL_WON_NO_SPAM_NEED",
                        },
                        tokens = {
                            Tokens.Value,
                            Tokens.Name,
                            Tokens.ValueExtra,
                            Tokens.Link,
                        },
                        result = {
                            Type = "NeedResult",
                        },
                    },
                    {
                        formats = {
                            "LOOT_ROLL_LOST_ROLL",
                        },
                        tokens = {
                            Tokens.Value,
                            Tokens.NameExtra,
                            Tokens.ValueExtra,
                            Tokens.Link,
                        },
                        result = {
                            Type = "LostResult",
                        },
                    },
                    {
                        formats = {
                            "LOOT_ROLL_YOU_WON",
                        },
                        tokens = {
                            Tokens.Link,
                        },
                        result = {
                            Type = "YouWinnerResult",
                        },
                    },
                    {
                        formats = {
                            "LOOT_ROLL_WON",
                        },
                        tokens = {
                            Tokens.Link,
                        },
                        result = {
                            Type = "WinnerResult",
                        },
                    },
                    {
                        formats = {
                            "LOOT_ROLL_STARTED",
                        },
                        tokens = {
                            Tokens.Value,
                            Tokens.Link,
                        },
                        result = {
                            Type = "StartRoll",
                        },
                    },
                },
            }
        )

    end

    -- Anima Power
    do

        ---@alias MiniLootMessageFormatSimpleParserResultAnimaPowerKeys "Link"|"Value"

        ---@alias MiniLootMessageFormatSimpleParserResultAnimaPowerTypes "FallbackAnimaPower"

        ---@see MiniLootMessageFormatSimpleParserResult
        ---@class MiniLootMessageFormatSimpleParserResultAnimaPower
        ---@field public Link string
        ---@field public Value? number

        ---@class MiniLootMessageFormatSimpleParserResultAnimaPowerArgs : MiniLootMessageFormatSimpleParserResultAnimaPower
        ---@field public Link? string
        ---@field public Type MiniLootMessageFormatSimpleParserResultAnimaPowerTypes

        ---@type table<MiniLootMessageFormatSimpleParserResultCurrencyKeys, MiniLootMessageFormatToken>
        local Tokens = {
            Link = {
                field = MiniLootMessageFormatField.Link,
                type = MiniLootMessageFormatTokenType.Link,
            },
            Value = {
                field = MiniLootMessageFormatField.Value,
                type = MiniLootMessageFormatTokenType.Number,
            },
        }

        AppendMessages(
            {
                group = MiniLootMessageGroup.AnimaPower,
                events = {
                    "CHAT_MSG_LOOT",
                },
                ---@type MiniLootMessageFormatSimpleParserResultAnimaPowerArgs
                result = {
                    Type = "FallbackAnimaPower",
                },
            },
            {
                formats = {
                    {
                        formats = {
                            "GAIN_MAW_POWER_SELF",
                        },
                        tokens = {
                            Tokens.Link,
                        },
                    },
                },
            }
        )

    end

    -- Artifact Power
    do

        ---@alias MiniLootMessageFormatSimpleParserResultArtifactPowerKeys "Link"|"Value"

        ---@alias MiniLootMessageFormatSimpleParserResultArtifactPowerTypes "FallbackArtifactPower"

        ---@see MiniLootMessageFormatSimpleParserResult
        ---@class MiniLootMessageFormatSimpleParserResultArtifactPower
        ---@field public Link string
        ---@field public Value? number

        ---@class MiniLootMessageFormatSimpleParserResultArtifactPowerArgs : MiniLootMessageFormatSimpleParserResultArtifactPower
        ---@field public Link? string
        ---@field public Type MiniLootMessageFormatSimpleParserResultArtifactPowerTypes

        ---@type table<MiniLootMessageFormatSimpleParserResultCurrencyKeys, MiniLootMessageFormatToken>
        local Tokens = {
            Link = {
                field = MiniLootMessageFormatField.Link,
                type = MiniLootMessageFormatTokenType.Link,
            },
            Value = {
                field = MiniLootMessageFormatField.Value,
                type = MiniLootMessageFormatTokenType.Number,
            },
        }

        AppendMessages(
            {
                group = MiniLootMessageGroup.ArtifactPower,
                events = {
                    "CHAT_MSG_SYSTEM",
                },
                ---@type MiniLootMessageFormatSimpleParserResultArtifactPowerArgs
                result = {
                    Type = "FallbackArtifactPower",
                },
            },
            {
                formats = {
                    {
                        formats = {
                            "ARTIFACT_XP_GAIN",
                        },
                        tokens = {
                            Tokens.Link,
                            Tokens.Value,
                        },
                    },
                    -- {
                    --     formats = {
                    --         "LOOT_ITEM_PUSHED_SELF",
                    --     },
                    --     tokens = {
                    --         Tokens.Link,
                    --     },
                    --     parser = function(results)
                    --         ---@type MiniLootMessageFormatSimpleParserResultArtifactPower|false?
                    --         local temp = SimpleParser(results)
                    --         if not temp then
                    --             return temp
                    --         end
                    --         if temp.Link then -- TODO: is item realted to artifact power? then we ignore/hide processing it like loot - this should be in the main handler for item looting?
                    --             return false
                    --         end
                    --         return temp
                    --     end,
                    -- },
                },
            }
        )

    end

    -- Transmogrification
    do

        ---@alias MiniLootMessageFormatSimpleParserResultTransmogrificationKeys "Link"|"Value"

        ---@alias MiniLootMessageFormatSimpleParserResultTransmogrificationTypes "FallbackTransmogrification"|"AddedTransmogrification"|"RemovedTransmogrification"

        ---@see MiniLootMessageFormatSimpleParserResult
        ---@class MiniLootMessageFormatSimpleParserResultTransmogrification
        ---@field public Link string
        ---@field public Value? number

        ---@class MiniLootMessageFormatSimpleParserResultTransmogrificationArgs : MiniLootMessageFormatSimpleParserResultTransmogrification
        ---@field public Link? string
        ---@field public Type MiniLootMessageFormatSimpleParserResultTransmogrificationTypes

        ---@class MiniLootMessageFormatTransmogrification : MiniLootMessageFormat
        ---@field public result? MiniLootMessageFormatSimpleParserResultTransmogrificationArgs

        ---@type table<MiniLootMessageFormatSimpleParserResultCurrencyKeys, MiniLootMessageFormatToken>
        local Tokens = {
            Link = {
                field = MiniLootMessageFormatField.Link,
                type = MiniLootMessageFormatTokenType.Link,
            },
            Value = {
                field = MiniLootMessageFormatField.Value,
                type = MiniLootMessageFormatTokenType.Number,
            },
        }

        AppendMessages(
            {
                group = MiniLootMessageGroup.Transmogrification,
                events = {
                    "CHAT_MSG_SYSTEM",
                },
                ---@type MiniLootMessageFormatSimpleParserResultTransmogrificationArgs
                result = {
                    Type = "FallbackTransmogrification",
                },
            },
            {
                ---@type MiniLootMessageFormatTransmogrification[]
                formats = {
                    {
                        formats = {
                            "ERR_LEARN_TRANSMOG_S",
                        },
                        tokens = {
                            Tokens.Link,
                        },
                        result = {
                            Type = "AddedTransmogrification",
                        },
                    },
                    {
                        formats = {
                            "ERR_REVOKE_TRANSMOG_S",
                        },
                        tokens = {
                            Tokens.Link,
                        },
                        result = {
                            Type = "RemovedTransmogrification",
                        },
                    },
                },
            }
        )

    end

    -- Ignore
    --[[
    do

        ---@alias MiniLootMessageFormatSimpleParserResultIgnoreKeys "Value"|"Money"

        ---@alias MiniLootMessageFormatSimpleParserResultIgnoreTypes "FallbackIgnore"

        ---@see MiniLootMessageFormatSimpleParserResult
        ---@class MiniLootMessageFormatSimpleParserResultIgnore
        ---@field public Value? number
        ---@field public Money? number

        ---@class MiniLootMessageFormatSimpleParserResultIgnoreArgs : MiniLootMessageFormatSimpleParserResultIgnore
        ---@field public Link? string
        ---@field public Type MiniLootMessageFormatSimpleParserResultIgnoreTypes

        ---@type table<MiniLootMessageFormatSimpleParserResultCurrencyKeys, MiniLootMessageFormatToken>
        local Tokens = {
            Value = {
                field = MiniLootMessageFormatField.Value,
                type = MiniLootMessageFormatTokenType.Number,
            },
            Money = {
                field = MiniLootMessageFormatField.Value,
                type = MiniLootMessageFormatTokenType.Money,
            },
        }

        AppendMessages(
            {
                group = MiniLootMessageGroup.Ignore,
                events = {
                    "CHAT_MSG_SYSTEM",
                },
                ---@type MiniLootMessageFormatSimpleParserResultIgnoreArgs
                result = {
                    Type = "FallbackIgnore",
                },
            },
            {
                formats = {
                    {
                        formats = {
                            "ERR_QUEST_REWARD_EXP_I",
                        },
                        tokens = {
                            Tokens.Value,
                        },
                    },
                    {
                        formats = {
                            "ERR_QUEST_REWARD_MONEY_S",
                        },
                        tokens = {
                            Tokens.Money,
                        },
                    },
                },
            }
        )

    end
    --]]

end

FinalizeMessages()

ns.CreateEmptyResults = CreateEmptyResults
ns.ProcessChatMessage = ProcessChatMessage
