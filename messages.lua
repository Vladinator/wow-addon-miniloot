local ns = select(2, ...) ---@class MiniLootNS

-- if enabled will generate and run tests and output the outcome in chat
local DebugTests = false

---@enum MiniLootMessageGroup
local MiniLootMessageGroup = {
    Reputation = "Reputation",
    Honor = "Honor",
    Experience = "Experience",
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
---@field public tests? any[]
---@field public skipAutoTests? boolean

---@class MiniLootMessagePartial : MiniLootMessage
---@field public group? MiniLootMessageGroup
---@field public events? WowEvent[]
---@field public formats? MiniLootMessageFormat[]
---@field public parser? MiniLootMessageFormatSimpleParser

---@type MiniLootMessage[]
local MessagesCollection = {}

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

---@generic T
---@param tbl T[]
---@return T[]
local function ReverseTable(tbl)
    local temp = {}
    local index = 0
    for i = #tbl, 1, -1 do
        index = index + 1
        temp[index] = tbl[i]
    end
    return temp
end

---@param message MiniLootMessage
local function FillMessageStruct(message)
    if not message.events then
        message.events = {}
    end
    if not message.formats then
        message.formats = {}
    end
    if not message.group then
        message.group = MiniLootMessageGroup.Ignore
    end
    return message
end

---@param ... MiniLootMessagePartial
local function AppendMessages(...)
    local data = {...}
    local first = FillMessageStruct(data[1])
    local index = #MessagesCollection
    if not DebugTests then
        first.skipAutoTests = true
    end
    for _, message in ipairs(data) do
        local temp = message
        if temp ~= first then
            temp = CopyTable(first)
            MergeTable(temp, message)
        end
        index = index + 1
        MessagesCollection[index] = temp
        if not DebugTests then
            temp.skipAutoTests = true
        end
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

---@param messageFormat MiniLootMessageFormat
---@return any[]
local function CreateMessageTests(messageFormat)
    local tests = {} ---@type any[]
    local testIndex = 0
    for i = 1, #messageFormat.formats do
        local msgFormat = messageFormat.formats[i]
        local args = {} ---@type any[]
        local argIndex = 0
        for j = 1, #messageFormat.tokens do
            local token = messageFormat.tokens[j]
            if token.type == MiniLootMessageFormatTokenType.Float then
                argIndex = argIndex + 1
                args[argIndex] = random(10000, 99999)/100
            elseif token.type == MiniLootMessageFormatTokenType.Link then
                argIndex = argIndex + 1
                args[argIndex] = "|cffffffff|Hitem:6948::::::::70:::::|h[Hearthstone]|h|r"
            elseif token.type == MiniLootMessageFormatTokenType.Money then
                argIndex = argIndex + 1
                args[argIndex] = C_CurrencyInfo.GetCoinText(random(12345, 67890))
            elseif token.type == MiniLootMessageFormatTokenType.Number then
                argIndex = argIndex + 1
                args[argIndex] = random(1, 99)
            elseif token.type == MiniLootMessageFormatTokenType.String then
                argIndex = argIndex + 1
                args[argIndex] = "MiniLootIsAwesome"
            elseif token.type == MiniLootMessageFormatTokenType.Target then
                argIndex = argIndex + 1
                args[argIndex] = "Vladinator-TarrenMill"
            end
        end
        if args[1] ~= nil then
            local tries = 10
            local success ---@type boolean?
            local text ---@type string?
            while tries > 0 and not success do
                success, text = pcall(format, msgFormat, unpack(args))
                if success then
                    break
                end
                tries = tries - 1
                argIndex = argIndex + 1
                args[argIndex] = "5"
            end
            if text then
                testIndex = testIndex + 1
                tests[testIndex] = {text, unpack(args)}
            end
        end
    end
    return tests
end

local function FinalizeMessages()
    local numMessages = #MessagesCollection

    for messageIndex = numMessages, 1, -1 do

        local message = MessagesCollection[messageIndex]
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
            table.remove(MessagesCollection, messageIndex)
        end

    end

    for messageIndex = numMessages, 1, -1 do

        local message = MessagesCollection[messageIndex]
        local messageResult = message.result
        local messageFormats = message.formats
        local numMessageFormats = #messageFormats

        for messageFormatIndex = numMessageFormats, 1, -1 do

            local messageFormat = messageFormats[messageFormatIndex]
            local messageFormatResult = messageFormat.result

            if not messageFormatResult then
                messageFormatResult = messageResult
                messageFormat.result = messageFormatResult
            end

            local messageSubFormats = messageFormat.formats
            local numMessageSubFormats = #messageSubFormats

            local messageSubPatterns = messageFormat.patterns
            local numMessageSubPatterns = messageSubPatterns and #messageSubPatterns
            local createdMessageSubPatterns ---@type boolean?

            if not messageSubPatterns then
                createdMessageSubPatterns = true
                messageSubPatterns = {}
                numMessageSubPatterns = #messageSubPatterns
                messageFormat.patterns = messageSubPatterns
            end

            for messageSubFormatIndex = numMessageSubFormats, 1, -1 do

                local messageSubFormat = messageSubFormats[messageSubFormatIndex]

                messageSubFormat = PatternToFormat(messageSubFormat)
                messageSubFormat = format("^%s$", messageSubFormat)

                if not TableContains(messageSubPatterns, messageSubFormat) then
                    numMessageSubPatterns = numMessageSubPatterns + 1
                    messageSubPatterns[numMessageSubPatterns] = messageSubFormat
                end

            end

            if createdMessageSubPatterns then
                messageSubPatterns = ReverseTable(messageSubPatterns)
                messageFormat.patterns = messageSubPatterns
            end

        end

        local runTests = not message.skipAutoTests
        local tests = message.tests

        if runTests and not tests then

            local index = 0
            tests = {}
            message.tests = tests

            for messageFormatIndex = 1, numMessageFormats do

                local messageFormat = messageFormats[messageFormatIndex]
                local messageFormatTests = CreateMessageTests(messageFormat)

                for messageFormatTestIndex = 1, #messageFormatTests do
                    index = index + 1
                    tests[index] = messageFormatTests[messageFormatTestIndex]
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

---@param value? string|number
---@return number?
local function ConvertToNumber(value)
    local type = type(value)
    if type == "number" then
        return value
    end
    if type ~= "string" then
        return
    end
    value = value
        :gsub(ConvertStringToNumberPattern1, "")
        :gsub(ConvertStringToNumberPattern2, ".")
        :gsub("[^%d%.]+", "")
    return tonumber(value)
end

local ConvertStringToMoneyPatterns = {
    Gold = PatternToFormat(GOLD_AMOUNT),
    Silver = PatternToFormat(SILVER_AMOUNT),
    Copper = PatternToFormat(COPPER_AMOUNT),
}

---@param value? string|number
---@return number?
local function ConvertToMoney(value)
    local type = type(value)
    if type == "number" then
        return value
    end
    if type ~= "string" then
        return
    end
    local goldText = value:match(ConvertStringToMoneyPatterns.Gold)
    local silverText = value:match(ConvertStringToMoneyPatterns.Silver)
    local copperText = value:match(ConvertStringToMoneyPatterns.Copper)
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

do

    -- Reputation
    do

        ---@alias MiniLootMessageFormatSimpleParserResultReputationKeys "Name"|"Value"|"Bonus"|"BonusExtra"

        ---@alias MiniLootMessageFormatSimpleParserResultReputationTypes "Reputation"|"ReputationLoss"

        ---@see MiniLootMessageFormatSimpleParserResult
        ---@class MiniLootMessageFormatSimpleParserResultReputation
        ---@field public Name string
        ---@field public Value number?
        ---@field public Bonus number?
        ---@field public BonusExtra number?

        ---@class MiniLootMessageFormatSimpleParserResultReputationArgs : MiniLootMessageFormatSimpleParserResultReputation
        ---@field public Name? string
        ---@field public Type MiniLootMessageFormatSimpleParserResultReputationTypes

        ---@class MiniLootMessageFormatReputation : MiniLootMessageFormat
        ---@field public result? MiniLootMessageFormatSimpleParserResultReputationArgs

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
                    Type = "Reputation",
                },
            },
            {
                ---@type MiniLootMessageFormatReputation[]
                formats = {
                    {
                        formats = {
                            "FACTION_STANDING_INCREASED_DOUBLE_BONUS",
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
                            "FACTION_STANDING_INCREASED_BONUS",
                        },
                        tokens = {
                            Tokens.Name,
                            Tokens.Value,
                            Tokens.Bonus,
                        },
                    },
                    {
                        formats = {
                            "FACTION_STANDING_INCREASED_ACH_BONUS",
                        },
                        tokens = {
                            Tokens.Name,
                            Tokens.Value,
                            Tokens.Bonus,
                        },
                    },
                    {
                        formats = {
                            "FACTION_STANDING_INCREASED",
                        },
                        tokens = {
                            Tokens.Name,
                            Tokens.Value,
                        },
                    },
                    {
                        formats = {
                            "FACTION_STANDING_INCREASED_GENERIC",
                        },
                        tokens = {
                            Tokens.Name,
                        },
                    },
                    {
                        formats = {
                            "FACTION_STANDING_DECREASED",
                        },
                        tokens = {
                            Tokens.Name,
                            Tokens.Value,
                        },
                        result = {
                            Type = "ReputationLoss"
                        },
                    },
                    {
                        formats = {
                            "FACTION_STANDING_DECREASED_GENERIC",
                        },
                        tokens = {
                            Tokens.Name,
                        },
                        result = {
                            Type = "ReputationLoss"
                        },
                    },
                },
            }
        )

    end

    -- Honor
    do

        ---@alias MiniLootMessageFormatSimpleParserResultHonorKeys "Name"|"NameExtra"|"Value"

        ---@alias MiniLootMessageFormatSimpleParserResultHonorTypes "Honor"

        ---@see MiniLootMessageFormatSimpleParserResult
        ---@class MiniLootMessageFormatSimpleParserResultHonor
        ---@field public Name? string
        ---@field public NameExtra? string
        ---@field public Value number

        ---@class MiniLootMessageFormatSimpleParserResultHonorArgs : MiniLootMessageFormatSimpleParserResultHonor
        ---@field public Value? number
        ---@field public Type MiniLootMessageFormatSimpleParserResultHonorTypes

        ---@class MiniLootMessageFormatHonor : MiniLootMessageFormat
        ---@field public result? MiniLootMessageFormatSimpleParserResultHonorArgs

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
                    Type = "Honor",
                },
            },
            {
                ---@type MiniLootMessageFormatHonor[]
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

        ---@alias MiniLootMessageFormatSimpleParserResultExperienceTypes
        ---|"Experience"
        ---|"ExperienceLoss"
        ---|"ExperienceBonusBonus"
        ---|"ExperienceBonusPenalty"
        ---|"ExperiencePenaltyBonus"
        ---|"ExperiencePenaltyPenalty"
        ---|"ExperienceBonus"
        ---|"ExperiencePenalty"

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

        ---@class MiniLootMessageFormatExperience : MiniLootMessageFormat
        ---@field public result? MiniLootMessageFormatSimpleParserResultExperienceArgs

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
                    Type = "Experience",
                },
            },
            {
                events = {
                    "CHAT_MSG_SYSTEM",
                },
                ---@type MiniLootMessageFormatExperience[]
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
                ---@type MiniLootMessageFormatExperience[]
                formats = {
                    {
                        formats = {
                            "COMBATLOG_XPGAIN_EXHAUSTION1_RAID",
                            "COMBATLOG_XPGAIN_EXHAUSTION2_RAID",
                        },
                        tokens = {
                            Tokens.Name,
                            Tokens.Value,
                            Tokens.Bonus,
                            Tokens.ValueExtra,
                            Tokens.BonusExtra,
                        },
                        result = {
                            Type = "ExperienceBonusPenalty",
                        },
                    },
                    {
                        formats = {
                            "COMBATLOG_XPGAIN_EXHAUSTION4_RAID",
                            "COMBATLOG_XPGAIN_EXHAUSTION5_RAID",
                        },
                        tokens = {
                            Tokens.Name,
                            Tokens.Value,
                            Tokens.Bonus,
                            Tokens.ValueExtra,
                            Tokens.BonusExtra,
                        },
                        result = {
                            Type = "ExperiencePenaltyPenalty",
                        },
                    },
                    {
                        formats = {
                            "COMBATLOG_XPGAIN_EXHAUSTION1_GROUP",
                            "COMBATLOG_XPGAIN_EXHAUSTION2_GROUP",
                        },
                        tokens = {
                            Tokens.Name,
                            Tokens.Value,
                            Tokens.Bonus,
                            Tokens.ValueExtra,
                            Tokens.BonusExtra,
                        },
                        result = {
                            Type = "ExperienceBonusBonus",
                        },
                    },
                    {
                        formats = {
                            "COMBATLOG_XPGAIN_EXHAUSTION4_GROUP",
                            "COMBATLOG_XPGAIN_EXHAUSTION5_GROUP",
                        },
                        tokens = {
                            Tokens.Name,
                            Tokens.Value,
                            Tokens.Bonus,
                            Tokens.ValueExtra,
                            Tokens.BonusExtra,
                        },
                        result = {
                            Type = "ExperiencePenaltyBonus",
                        },
                    },
                    {
                        formats = {
                            "COMBATLOG_XPGAIN_EXHAUSTION1",
                            "COMBATLOG_XPGAIN_EXHAUSTION2",
                        },
                        tokens = {
                            Tokens.Name,
                            Tokens.Value,
                            Tokens.Bonus,
                            Tokens.BonusExtra,
                        },
                        result =  {
                            Type = "ExperienceBonus",
                        },
                    },
                    {
                        formats = {
                            "COMBATLOG_XPGAIN_EXHAUSTION4",
                            "COMBATLOG_XPGAIN_EXHAUSTION5",
                        },
                        tokens = {
                            Tokens.Name,
                            Tokens.Value,
                            Tokens.Bonus,
                            Tokens.BonusExtra,
                        },
                        result =  {
                            Type = "ExperiencePenalty",
                        },
                    },
                    {
                        formats = {
                            "COMBATLOG_XPGAIN_FIRSTPERSON_RAID",
                        },
                        tokens = {
                            Tokens.Name,
                            Tokens.Value,
                            Tokens.ValueExtra,
                        },
                        result = {
                            Type = "ExperiencePenalty",
                        },
                    },
                    {
                        formats = {
                            "COMBATLOG_XPGAIN_FIRSTPERSON_GROUP",
                        },
                        tokens = {
                            Tokens.Name,
                            Tokens.Value,
                            Tokens.ValueExtra,
                        },
                        result = {
                            Type = "ExperienceBonus",
                        },
                    },
                    {
                        formats = {
                            "COMBATLOG_XPGAIN_FIRSTPERSON",
                        },
                        tokens = {
                            Tokens.Name,
                            Tokens.Value,
                        },
                    },
                    {
                        formats = {
                            "COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED_RAID",
                        },
                        tokens = {
                            Tokens.Value,
                            Tokens.ValueExtra,
                        },
                        result = {
                            Type = "ExperiencePenalty",
                        },
                    },
                    {
                        formats = {
                            "COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED_GROUP",
                        },
                        tokens = {
                            Tokens.Value,
                            Tokens.ValueExtra,
                        },
                        result = {
                            Type = "ExperienceBonus",
                        },
                    },
                    {
                        formats = {
                            "COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED",
                        },
                        tokens = {
                            Tokens.Value,
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
                        result = {
                            Type = "ExperienceBonus",
                        },
                    },
                    {
                        formats = {
                            "COMBATLOG_XPLOSS_FIRSTPERSON_UNNAMED",
                        },
                        tokens = {
                            Tokens.Value,
                        },
                        result = {
                            Type = "ExperienceLoss",
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

        ---@alias MiniLootMessageFormatSimpleParserResultGuildExperienceTypes "GuildExperience"

        ---@see MiniLootMessageFormatSimpleParserResult
        ---@class MiniLootMessageFormatSimpleParserResultGuildExperience
        ---@field public Value number

        ---@class MiniLootMessageFormatSimpleParserResultGuildExperienceArgs : MiniLootMessageFormatSimpleParserResultGuildExperience
        ---@field public Value? number
        ---@field public Type MiniLootMessageFormatSimpleParserResultGuildExperienceTypes

        ---@class MiniLootMessageFormatGuildExperience : MiniLootMessageFormat
        ---@field public result? MiniLootMessageFormatSimpleParserResultGuildExperienceArgs

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
                    Type = "GuildExperience",
                },
            },
            {
                ---@type MiniLootMessageFormatGuildExperience[]
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

        ---@alias MiniLootMessageFormatSimpleParserResultFollowerExperienceTypes "FollowerExperience"

        ---@see MiniLootMessageFormatSimpleParserResult
        ---@class MiniLootMessageFormatSimpleParserResultFollowerExperience
        ---@field public Name string
        ---@field public Value number

        ---@class MiniLootMessageFormatSimpleParserResultFollowerExperienceArgs : MiniLootMessageFormatSimpleParserResultFollowerExperience
        ---@field public Name? string
        ---@field public Value? number
        ---@field public Type MiniLootMessageFormatSimpleParserResultFollowerExperienceTypes

        ---@class MiniLootMessageFormatFollowerExperience : MiniLootMessageFormat
        ---@field public result? MiniLootMessageFormatSimpleParserResultFollowerExperienceArgs

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
                    Type = "FollowerExperience",
                },
            },
            {
                ---@type MiniLootMessageFormatFollowerExperience[]
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

        ---@alias MiniLootMessageFormatSimpleParserResultCurrencyTypes "Currency"

        ---@see MiniLootMessageFormatSimpleParserResult
        ---@class MiniLootMessageFormatSimpleParserResultCurrency
        ---@field public Link string
        ---@field public Value? number

        ---@class MiniLootMessageFormatSimpleParserResultCurrencyArgs : MiniLootMessageFormatSimpleParserResultCurrency
        ---@field public Link? string
        ---@field public Type MiniLootMessageFormatSimpleParserResultCurrencyTypes

        ---@class MiniLootMessageFormatCurrency : MiniLootMessageFormat
        ---@field public result? MiniLootMessageFormatSimpleParserResultCurrencyArgs

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
                    Type = "Currency",
                },
            },
            {
                ---@type MiniLootMessageFormatCurrency[]
                formats = {
                    {
                        formats = {
                            "CURRENCY_GAINED_MULTIPLE_BONUS",
                            "CURRENCY_GAINED_MULTIPLE",
                            "LOOT_CURRENCY_REFUND",
                        },
                        tokens = {
                            Tokens.Link,
                            Tokens.Value,
                        },
                    },
                    {
                        formats = {
                            "CURRENCY_GAINED",
                        },
                        tokens = {
                            Tokens.Link,
                        },
                    },
                },
            }
        )

    end

    -- Money
    do

        ---@alias MiniLootMessageFormatSimpleParserResultMoneyKeys "Name"|"Value"|"ValueExtra"

        ---@alias MiniLootMessageFormatSimpleParserResultMoneyTypes "Money"

        ---@see MiniLootMessageFormatSimpleParserResult
        ---@class MiniLootMessageFormatSimpleParserResultMoney
        ---@field public Name? string
        ---@field public Value number
        ---@field public ValueExtra? number

        ---@class MiniLootMessageFormatSimpleParserResultMoneyArgs : MiniLootMessageFormatSimpleParserResultMoney
        ---@field public Value? number
        ---@field public Type MiniLootMessageFormatSimpleParserResultMoneyTypes

        ---@class MiniLootMessageFormatMoney : MiniLootMessageFormat
        ---@field public result? MiniLootMessageFormatSimpleParserResultMoneyArgs

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
                    Type = "Money",
                },
            },
            {
                ---@type MiniLootMessageFormatMoney[]
                formats = {
                    {
                        formats = {
                            "YOU_LOOT_MONEY_GUILD",
                            "LOOT_MONEY_SPLIT_GUILD",
                        },
                        tokens = {
                            Tokens.Value,
                            Tokens.ValueExtra,
                        },
                    },
                    {
                        formats = {
                            "YOU_LOOT_MONEY",
                            "LOOT_MONEY_SPLIT",
                            "LOOT_MONEY_REFUND",
                        },
                        tokens = {
                            Tokens.Value,
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

        ---@alias MiniLootMessageFormatSimpleParserResultLootTypes "Loot"

        ---@see MiniLootMessageFormatSimpleParserResult
        ---@class MiniLootMessageFormatSimpleParserResultLoot
        ---@field public Name? string
        ---@field public Link string
        ---@field public Value? number

        ---@class MiniLootMessageFormatSimpleParserResultLootArgs : MiniLootMessageFormatSimpleParserResultLoot
        ---@field public Link? string
        ---@field public Type MiniLootMessageFormatSimpleParserResultLootTypes

        ---@class MiniLootMessageFormatLoot : MiniLootMessageFormat
        ---@field public result? MiniLootMessageFormatSimpleParserResultLootArgs

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
                    Type = "Loot",
                },
            },
            {
                ---@type MiniLootMessageFormatLoot[]
                formats = {
                    {
                        formats = {
                            "CREATED_ITEM_MULTIPLE",
                        },
                        tokens = {
                            Tokens.Name,
                            Tokens.Link,
                            Tokens.Value,
                        },
                    },
                    {
                        formats = {
                            "CREATED_ITEM",
                        },
                        tokens = {
                            Tokens.Name,
                            Tokens.Link,
                        },
                    },
                    {
                        formats = {
                            "LOOT_ITEM_BONUS_ROLL_SELF_MULTIPLE",
                            "LOOT_ITEM_SELF_MULTIPLE",
                            "LOOT_ITEM_PUSHED_SELF_MULTIPLE",
                            "LOOT_ITEM_CREATED_SELF_MULTIPLE",
                            "LOOT_ITEM_REFUND_MULTIPLE",
                        },
                        tokens = {
                            Tokens.Link,
                            Tokens.Value,
                        },
                    },
                    {
                        formats = {
                            "LOOT_ITEM_BONUS_ROLL_SELF",
                            "LOOT_ITEM_SELF",
                            "LOOT_ITEM_PUSHED_SELF",
                            "LOOT_ITEM_CREATED_SELF",
                            "LOOT_ITEM_REFUND",
                        },
                        tokens = {
                            Tokens.Link,
                        },
                    },
                    {
                        formats = {
                            "LOOT_ITEM_BONUS_ROLL_SELF_MULTIPLE",
                            "LOOT_ITEM_SELF_MULTIPLE",
                            "LOOT_ITEM_PUSHED_SELF_MULTIPLE",
                            "LOOT_ITEM_CREATED_SELF_MULTIPLE",
                            "LOOT_ITEM_REFUND_MULTIPLE",
                        },
                        tokens = {
                            Tokens.Link,
                            Tokens.Value,
                        },
                    },
                    {
                        formats = {
                            "LOOT_ITEM_BONUS_ROLL_SELF",
                            "LOOT_ITEM_SELF",
                            "LOOT_ITEM_PUSHED_SELF",
                            "LOOT_ITEM_CREATED_SELF",
                            "LOOT_ITEM_REFUND",
                        },
                        tokens = {
                            Tokens.Link,
                        },
                    },
                    {
                        formats = {
                            "LOOT_ITEM_BONUS_ROLL_MULTIPLE",
                            "LOOT_ITEM_MULTIPLE",
                            "LOOT_ITEM_PUSHED_MULTIPLE",
                        },
                        tokens = {
                            Tokens.Name,
                            Tokens.Link,
                            Tokens.Value,
                        },
                    },
                    {
                        formats = {
                            "LOOT_ITEM_BONUS_ROLL",
                            "LOOT_ITEM",
                            "LOOT_ITEM_PUSHED",
                        },
                        tokens = {
                            Tokens.Name,
                            Tokens.Link,
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
                            Tokens.Name,
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

        ---@alias MiniLootMessageFormatSimpleParserResultAnimaPowerTypes "AnimaPower"

        ---@see MiniLootMessageFormatSimpleParserResult
        ---@class MiniLootMessageFormatSimpleParserResultAnimaPower
        ---@field public Link string
        ---@field public Value? number

        ---@class MiniLootMessageFormatSimpleParserResultAnimaPowerArgs : MiniLootMessageFormatSimpleParserResultAnimaPower
        ---@field public Link? string
        ---@field public Type MiniLootMessageFormatSimpleParserResultAnimaPowerTypes

        ---@class MiniLootMessageFormatAnimaPower : MiniLootMessageFormat
        ---@field public result? MiniLootMessageFormatSimpleParserResultAnimaPowerArgs

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
                    Type = "AnimaPower",
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

        ---@alias MiniLootMessageFormatSimpleParserResultArtifactPowerTypes "ArtifactPower"

        ---@see MiniLootMessageFormatSimpleParserResult
        ---@class MiniLootMessageFormatSimpleParserResultArtifactPower
        ---@field public Link string
        ---@field public Value? number

        ---@class MiniLootMessageFormatSimpleParserResultArtifactPowerArgs : MiniLootMessageFormatSimpleParserResultArtifactPower
        ---@field public Link? string
        ---@field public Type MiniLootMessageFormatSimpleParserResultArtifactPowerTypes

        ---@class MiniLootMessageFormatArtifactPower : MiniLootMessageFormat
        ---@field public result? MiniLootMessageFormatSimpleParserResultArtifactPowerArgs

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
                    Type = "ArtifactPower",
                },
            },
            {
                ---@type MiniLootMessageFormatArtifactPower[]
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

        ---@alias MiniLootMessageFormatSimpleParserResultTransmogrificationTypes "Transmogrification"|"TransmogrificationLoss"

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
                    Type = "Transmogrification",
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
                    },
                    {
                        formats = {
                            "ERR_REVOKE_TRANSMOG_S",
                        },
                        tokens = {
                            Tokens.Link,
                        },
                        result = {
                            Type = "TransmogrificationLoss",
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

        ---@alias MiniLootMessageFormatSimpleParserResultIgnoreTypes "Ignore"

        ---@see MiniLootMessageFormatSimpleParserResult
        ---@class MiniLootMessageFormatSimpleParserResultIgnore
        ---@field public Value? number
        ---@field public Money? number

        ---@class MiniLootMessageFormatSimpleParserResultIgnoreArgs : MiniLootMessageFormatSimpleParserResultIgnore
        ---@field public Link? string
        ---@field public Type MiniLootMessageFormatSimpleParserResultIgnoreTypes

        ---@class MiniLootMessageFormatIgnore : MiniLootMessageFormat
        ---@field public result? MiniLootMessageFormatSimpleParserResultIgnoreArgs

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
                    Type = "Ignore",
                },
            },
            {
                ---@type MiniLootMessageFormatIgnore[]
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

local ProcessTokensLinkPattern = "^%s*|h"

---@param token MiniLootMessageFormatToken
---@param match? string
---@return string? key, any value
local function ProcessTokens(token, match)
    local tokenType = token.type

    if tokenType == MiniLootMessageFormatTokenType.Float
        or tokenType == MiniLootMessageFormatTokenType.Number then

        local value = ConvertToNumber(match)
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

        local value = ConvertToMoney(match)
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
    if messageFormat.result then
        result = CopyTable(messageFormat.result)
    end
    for i = 1, numTokens do
        local token = tokens[i]
        local match = matches[i] ---@type string?
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

---@param event WowEvent
---@param text string
---@param playerName? string
---@param languageName? string
---@param channelName? string
---@param playerName2? string
---@param specialFlags? string
---@param zoneChannelID? number
---@param channelIndex? number
---@param channelBaseName? string
---@param languageID? number
---@param lineID? number
---@param guid? string
---@param bnSenderID? number
---@param isMobile? boolean
---@param isSubtitle? boolean
---@param hideSenderInLetterbox? boolean
---@param supressRaidIcons? boolean
---@return MiniLootMessageFormatSimpleParserResult?
local function ProcessChatMessage(event, text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons)
    for _, message in ipairs(MessagesCollection) do
        if TableContains(message.events, event) then
            for _, messageFormat in ipairs(message.formats) do
                local messageFormatPatterns = messageFormat.patterns
                if messageFormatPatterns then
                    for _, messageFormatPattern in ipairs(messageFormatPatterns) do
                        local matches = {text:match(messageFormatPattern)} ---@type string[]
                        if matches[1] then
                            local result = ProcessMatchedToResult(messageFormat, matches)
                            if result then
                                return result
                            end
                        end
                    end
                end
            end
        end
    end
end

---@param val1 any
---@param val2 any
---@return boolean equal
local function ValuesAreSameish(val1, val2)
    if val1 == val2 then
        return true
    end
    local type1 = type(val1)
    local type2 = type(val2)
    if type1 == "string" and type2 == "number" then
        return tonumber(val1) == val2
    end
    if type1 == "number" and type2 == "string" then
        return val1 == tonumber(val2)
    end
    return true
end

---@param result MiniLootMessageFormatSimpleParserResult
---@param args any[]
---@param isMoney boolean
---@return boolean success
local function CompareTestResults(result, args, isMoney)
    if not result.Type then
        return false
    end
    local numArgs = #args
    local usedKeys = {}
    local count = 0
    for i = 1, numArgs do
        local arg = args[i]
        for k, v in pairs(result) do
            if k ~= "Type" then
                if not usedKeys[k] then
                    if ValuesAreSameish(v, arg) or (isMoney and ValuesAreSameish(C_CurrencyInfo.GetCoinText(v), arg)) then
                        usedKeys[k] = i
                        count = count + 1
                        break
                    end
                end
            end
        end
    end
    if numArgs ~= count then
        return false
    end
    return true
end

---@param message MiniLootMessage
---@param test any[]
---@return MiniLootMessageFormatSimpleParserResult? successResult, MiniLootMessageFormatSimpleParserResult[]? closeResults
local function RunAndEvaluateTest(message, test)
    local isMoney = message.group == MiniLootMessageGroup.Money
    local successResult ---@type MiniLootMessageFormatSimpleParserResult?
    local closeResults ---@type MiniLootMessageFormatSimpleParserResult[]?
    local closeIndex ---@type number?
    local args = CopyTable(test) ---@type any[]
    local text = table.remove(args, 1) ---@type string
    for _, event in ipairs(message.events) do
        local result = ProcessChatMessage(event, text)
        if result then
            local success = CompareTestResults(result, args, isMoney)
            if success then
                successResult = result
                break
            end
            if not closeResults then
                closeResults = {}
                closeIndex = 0
            end
            closeIndex = closeIndex + 1
            closeResults[closeIndex] = result
        end
    end
    return successResult, closeResults
end

---@param message MiniLootMessage
local function RunAndEvaluateTests(message)
    for _, test in ipairs(message.tests) do
        local testResult, closeResults = RunAndEvaluateTest(message, test)
        if not testResult then
            print(format("|cffFF5555%s|r failed |cffFF5555%s|r", message.group, test[1]))
            if closeResults then
                for _, closeResult in ipairs(closeResults) do
                    for k, v in pairs(closeResult) do
                        print(format("|cffFFFF55%s|r %s", tostringall(k, v)))
                    end
                end
            end
        end
    end
end

local function RunMessageTests()
    for _, message in ipairs(MessagesCollection) do
        if not message.skipAutoTests then
            local tests = message.tests
            if tests then
                RunAndEvaluateTests(message)
            end
        end
    end
end

FinalizeMessages()
RunMessageTests()

ns.MessagesCollection = MessagesCollection
ns.CreateEmptyResults = CreateEmptyResults
ns.ProcessChatMessage = ProcessChatMessage

_G.MiniLootNS = ns -- DEBUG
-- /tinspect MiniLootNS.MessagesCollection
-- /dump MiniLootNS.ProcessChatMessage("CHAT_MSG_CURRENCY", format("You receive currency: %sx10", C_CurrencyInfo.GetCurrencyLink(2778)))
