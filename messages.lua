local ns = select(2, ...) ---@class MiniLootNS

local SimpleHexColors = ns.Utils.SimpleHexColors
local TableCopy = ns.Utils.TableCopy
local TableContains = ns.Utils.TableContains
local TableMerge = ns.Utils.TableMerge
local TableReverse = ns.Utils.TableReverse
local PatternToFormat = ns.Utils.PatternToFormat
local ConvertToNumber = ns.Utils.ConvertToNumber
local ConvertToMoney = ns.Utils.ConvertToMoney
local ValuesAreSameish = ns.Utils.ValuesAreSameish

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
    LootRoll = "LootRoll",
    LootRollYouDecide = "LootRollYouDecide",
    LootRollDecide = "LootRollDecide",
    -- LootRollYouRolled = "LootRollYouRolled",
    LootRollRolled = "LootRollRolled",
    LootRollYouResult = "LootRollYouResult",
    LootRollResult = "LootRollResult",
    LootRollInfo = "LootRollInfo",
    ItemChanged = "ItemChanged",
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
    Zone = "Zone",
    ZoneExtra = "ZoneExtra",
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

---@type table<MiniLootMessageFormatSimpleParserResultExperienceKeys, MiniLootMessageFormatToken>
local Tokens = {
    NameString = {
        field = MiniLootMessageFormatField.Name,
        type = MiniLootMessageFormatTokenType.String,
    },
    NameExtraString = {
        field = MiniLootMessageFormatField.NameExtra,
        type = MiniLootMessageFormatTokenType.String,
    },
    NameTarget = {
        field = MiniLootMessageFormatField.Name,
        type = MiniLootMessageFormatTokenType.Target,
    },
    NameExtraTarget = {
        field = MiniLootMessageFormatField.NameExtra,
        type = MiniLootMessageFormatTokenType.Target,
    },
    ValueNumber = {
        field = MiniLootMessageFormatField.Value,
        type = MiniLootMessageFormatTokenType.Number,
    },
    ValueExtraNumber = {
        field = MiniLootMessageFormatField.ValueExtra,
        type = MiniLootMessageFormatTokenType.Number,
    },
    ValueFloat = {
        field = MiniLootMessageFormatField.Value,
        type = MiniLootMessageFormatTokenType.Float,
    },
    ValueExtraFloat = {
        field = MiniLootMessageFormatField.ValueExtra,
        type = MiniLootMessageFormatTokenType.Float,
    },
    ValueString = {
        field = MiniLootMessageFormatField.Value,
        type = MiniLootMessageFormatTokenType.String,
    },
    ValueExtraString = {
        field = MiniLootMessageFormatField.ValueExtra,
        type = MiniLootMessageFormatTokenType.String,
    },
    ValueMoney = {
        field = MiniLootMessageFormatField.Value,
        type = MiniLootMessageFormatTokenType.Money,
    },
    ValueExtraMoney = {
        field = MiniLootMessageFormatField.ValueExtra,
        type = MiniLootMessageFormatTokenType.Money,
    },
    BonusNumber = {
        field = MiniLootMessageFormatField.Bonus,
        type = MiniLootMessageFormatTokenType.Number,
    },
    BonusExtraNumber = {
        field = MiniLootMessageFormatField.BonusExtra,
        type = MiniLootMessageFormatTokenType.Number,
    },
    BonusFloat = {
        field = MiniLootMessageFormatField.Bonus,
        type = MiniLootMessageFormatTokenType.Float,
    },
    BonusExtraFloat = {
        field = MiniLootMessageFormatField.BonusExtra,
        type = MiniLootMessageFormatTokenType.Float,
    },
    BonusString = {
        field = MiniLootMessageFormatField.Bonus,
        type = MiniLootMessageFormatTokenType.String,
    },
    BonusExtraString = {
        field = MiniLootMessageFormatField.BonusExtra,
        type = MiniLootMessageFormatTokenType.String,
    },
    Link = {
        field = MiniLootMessageFormatField.Link,
        type = MiniLootMessageFormatTokenType.Link,
    },
    LinkExtra = {
        field = MiniLootMessageFormatField.LinkExtra,
        type = MiniLootMessageFormatTokenType.Link,
    },
    ZoneString = {
        field = MiniLootMessageFormatField.Zone,
        type = MiniLootMessageFormatTokenType.String,
    },
    ZoneExtraString = {
        field = MiniLootMessageFormatField.ZoneExtra,
        type = MiniLootMessageFormatTokenType.String,
    },
}

---@alias MiniLootMessageFormatSimpleParserResultType
---|"Fallback"
---|MiniLootMessageFormatSimpleParserResultReputationTypes
---|MiniLootMessageFormatSimpleParserResultHonorTypes
---|MiniLootMessageFormatSimpleParserResultExperienceTypes
-- ---|MiniLootMessageFormatSimpleParserResultGuildExperienceTypes
---|MiniLootMessageFormatSimpleParserResultFollowerExperienceTypes
---|MiniLootMessageFormatSimpleParserResultCurrencyTypes
---|MiniLootMessageFormatSimpleParserResultMoneyTypes
---|MiniLootMessageFormatSimpleParserResultLootTypes
---|MiniLootMessageFormatSimpleParserResultLootRollTypes
---|MiniLootMessageFormatSimpleParserResultItemChangedTypes
---|MiniLootMessageFormatSimpleParserResultAnimaPowerTypes
---|MiniLootMessageFormatSimpleParserResultArtifactPowerTypes
---|MiniLootMessageFormatSimpleParserResultTransmogrificationTypes
---|MiniLootMessageFormatSimpleParserResultIgnoreTypes

---@alias MiniLootMessageFormatSimpleParserResultKeys
---|MiniLootMessageFormatSimpleParserResultReputationKeys
---|MiniLootMessageFormatSimpleParserResultHonorKeys
---|MiniLootMessageFormatSimpleParserResultExperienceKeys
-- ---|MiniLootMessageFormatSimpleParserResultGuildExperienceKeys
---|MiniLootMessageFormatSimpleParserResultFollowerExperienceKeys
---|MiniLootMessageFormatSimpleParserResultCurrencyKeys
---|MiniLootMessageFormatSimpleParserResultMoneyKeys
---|MiniLootMessageFormatSimpleParserResultLootKeys
---|MiniLootMessageFormatSimpleParserResultLootRollKeys
---|MiniLootMessageFormatSimpleParserResultItemChangedKeys
---|MiniLootMessageFormatSimpleParserResultAnimaPowerKeys
---|MiniLootMessageFormatSimpleParserResultArtifactPowerKeys
---|MiniLootMessageFormatSimpleParserResultTransmogrificationKeys
---|MiniLootMessageFormatSimpleParserResultIgnoreKeys

---@alias MiniLootMessageFormatSimpleParserResults
---|MiniLootMessageFormatSimpleParserResultFallback
---|MiniLootMessageFormatSimpleParserResultReputation
---|MiniLootMessageFormatSimpleParserResultHonor
---|MiniLootMessageFormatSimpleParserResultExperience
-- ---|MiniLootMessageFormatSimpleParserResultGuildExperience
---|MiniLootMessageFormatSimpleParserResultFollowerExperience
---|MiniLootMessageFormatSimpleParserResultCurrency
---|MiniLootMessageFormatSimpleParserResultMoney
---|MiniLootMessageFormatSimpleParserResultLoot
---|MiniLootMessageFormatSimpleParserResultLootRoll
---|MiniLootMessageFormatSimpleParserResultItemChanged
---|MiniLootMessageFormatSimpleParserResultAnimaPower
---|MiniLootMessageFormatSimpleParserResultArtifactPower
---|MiniLootMessageFormatSimpleParserResultTransmogrification
---|MiniLootMessageFormatSimpleParserResultIgnore

---@class MiniLootMessageFormatSimpleParserResultFallback
---@field public Type MiniLootMessageFormatSimpleParserResultType

---@alias MiniLootMessageFormatSimpleParser fun(result: MiniLootMessageFormatSimpleParserResults): MiniLootMessageFormatSimpleParserResults|false?

---@alias MiniLootMessageFormatSimpleMap fun(result: MiniLootMessageFormatSimpleParserResults): MiniLootMessageFormatSimpleParserResults|false?

---@alias MiniLootMessageFormatSimpleParserMap fun(results: MiniLootMessageFormatTokenResult[], mapper: MiniLootMessageFormatSimpleMap): MiniLootMessageFormatSimpleParserResults|false?

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
---@field public result? MiniLootMessageFormatSimpleParserResults
---@field public parser? MiniLootMessageFormatSimpleParser

---@class MiniLootMessage
---@field public group MiniLootMessageGroup
---@field public events WowEvent[]
---@field public formats MiniLootMessageFormat[]
---@field public result? MiniLootMessageFormatSimpleParserResults
---@field public parser? MiniLootMessageFormatSimpleParser
---@field public tests? any[]
---@field public skipTests? boolean
---@field public defaultDebounce? number

---@class MiniLootMessagePartial : MiniLootMessage
---@field public group? MiniLootMessageGroup
---@field public events? WowEvent[]
---@field public formats? MiniLootMessageFormat[]

---@type MiniLootMessage[]
local MessagesCollection = {}

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
    for _, message in ipairs(data) do
        local temp = message
        if temp ~= first then
            temp = TableCopy(first)
            TableMerge(temp, message)
        end
        index = index + 1
        MessagesCollection[index] = temp
    end
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
                args[argIndex] = "SampleText"
            elseif token.type == MiniLootMessageFormatTokenType.Target then
                argIndex = argIndex + 1
                args[argIndex] = "SampleName-SampleRealm"
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

local MessageMetaTableTests = {
    ---@param self MiniLootMessage
    __index = function(self, key)
        if key ~= "tests" then
            return
        end
        if self.skipTests then
            return
        end
        if self.group == MiniLootMessageGroup.Ignore then
            return
        end
        local messageFormats = self.formats
        local numMessageFormats = #messageFormats
        local index = 0
        local tests = {}
        for messageFormatIndex = 1, numMessageFormats do
            local messageFormat = messageFormats[messageFormatIndex]
            local messageFormatTests = CreateMessageTests(messageFormat)
            for messageFormatTestIndex = 1, #messageFormatTests do
                index = index + 1
                tests[index] = messageFormatTests[messageFormatTestIndex]
            end
        end
        rawset(self, key, tests)
        return tests
    end,
}

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
        local messageParser = message.parser
        local messageFormats = message.formats
        local numMessageFormats = #messageFormats

        for messageFormatIndex = numMessageFormats, 1, -1 do

            local messageFormat = messageFormats[messageFormatIndex]
            local messageFormatResult = messageFormat.result
            local messageFormatParser = messageFormat.parser

            if not messageFormatResult then
                messageFormatResult = messageResult
                messageFormat.result = messageFormatResult
            end

            if not messageFormatParser then
                messageFormatParser = messageParser
                messageFormat.parser = messageFormatParser
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
                messageSubPatterns = TableReverse(messageSubPatterns)
                messageFormat.patterns = messageSubPatterns
            end

        end

        setmetatable(message, MessageMetaTableTests)

    end
end

do

    -- Reputation
    do

        ---@alias MiniLootMessageFormatSimpleParserResultReputationKeys "Name"|"Value"|"Bonus"|"BonusExtra"

        ---@alias MiniLootMessageFormatSimpleParserResultReputationTypes "Reputation"|"ReputationLoss"|"ReputationWarband"|"ReputationLossWarband"

        ---@class MiniLootMessageFormatSimpleParserResultReputation
        ---@field public Type MiniLootMessageFormatSimpleParserResultReputationTypes
        ---@field public Name string The name of the faction.
        ---@field public Value number? If provided, the amount of reputation earned.
        ---@field public Bonus number? If provided, the amount of bonus reputation earned.
        ---@field public BonusExtra number? If provided, the amount of bonus reputation earned.

        ---@class MiniLootMessageFormatSimpleParserResultReputationArgs : MiniLootMessageFormatSimpleParserResultReputation
        ---@field public Name? string

        ---@class MiniLootMessageFormatReputation : MiniLootMessageFormat
        ---@field public result? MiniLootMessageFormatSimpleParserResultReputationArgs

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
                            Tokens.NameString,
                            Tokens.ValueNumber,
                            Tokens.BonusFloat,
                            Tokens.BonusExtraFloat,
                        },
                    },
                    {
                        formats = {
                            "FACTION_STANDING_INCREASED_BONUS",
                        },
                        tokens = {
                            Tokens.NameString,
                            Tokens.ValueNumber,
                            Tokens.BonusFloat,
                        },
                    },
                    {
                        formats = {
                            "FACTION_STANDING_INCREASED_ACH_BONUS",
                        },
                        tokens = {
                            Tokens.NameString,
                            Tokens.ValueNumber,
                            Tokens.BonusFloat,
                        },
                    },
                    {
                        formats = {
                            "FACTION_STANDING_INCREASED_ACCOUNT_WIDE",
                        },
                        tokens = {
                            Tokens.NameString,
                            Tokens.ValueNumber,
                        },
                        result = {
                            Type = "ReputationWarband",
                        },
                    },
                    {
                        formats = {
                            "FACTION_STANDING_INCREASED",
                        },
                        tokens = {
                            Tokens.NameString,
                            Tokens.ValueNumber,
                        },
                    },
                    {
                        formats = {
                            "FACTION_STANDING_INCREASED_GENERIC_ACCOUNT_WIDE",
                        },
                        tokens = {
                            Tokens.NameString,
                        },
                        result = {
                            Type = "ReputationWarband",
                        },
                    },
                    {
                        formats = {
                            "FACTION_STANDING_INCREASED_GENERIC",
                        },
                        tokens = {
                            Tokens.NameString,
                        },
                    },
                    {
                        formats = {
                            "FACTION_STANDING_DECREASED_ACCOUNT_WIDE",
                        },
                        tokens = {
                            Tokens.NameString,
                            Tokens.ValueNumber,
                        },
                        result = {
                            Type = "ReputationLossWarband",
                        },
                    },
                    {
                        formats = {
                            "FACTION_STANDING_DECREASED",
                        },
                        tokens = {
                            Tokens.NameString,
                            Tokens.ValueNumber,
                        },
                        result = {
                            Type = "ReputationLoss",
                        },
                    },
                    {
                        formats = {
                            "FACTION_STANDING_DECREASED_GENERIC_ACCOUNT_WIDE",
                        },
                        tokens = {
                            Tokens.NameString,
                        },
                        result = {
                            Type = "ReputationLossWarband",
                        },
                    },
                    {
                        formats = {
                            "FACTION_STANDING_DECREASED_GENERIC",
                        },
                        tokens = {
                            Tokens.NameString,
                        },
                        result = {
                            Type = "ReputationLoss",
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

        ---@class MiniLootMessageFormatSimpleParserResultHonor
        ---@field public Type MiniLootMessageFormatSimpleParserResultHonorTypes
        ---@field public Name? string If provided, this is the name of the player that granted us Honor.
        ---@field public NameExtra? string If provided, this is the rank of the player that granted us Honor.
        ---@field public Value number The amount of Honor earned.

        ---@class MiniLootMessageFormatSimpleParserResultHonorArgs : MiniLootMessageFormatSimpleParserResultHonor
        ---@field public Value? number

        ---@class MiniLootMessageFormatHonor : MiniLootMessageFormat
        ---@field public result? MiniLootMessageFormatSimpleParserResultHonorArgs

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
                            Tokens.NameString,
                            Tokens.NameExtraString,
                            Tokens.ValueNumber,
                        },
                    },
                    {
                        formats = {
                            "COMBATLOG_HONORGAIN_NO_RANK",
                        },
                        tokens = {
                            Tokens.NameString,
                            Tokens.ValueNumber,
                        },
                    },
                    {
                        formats = {
                            "COMBATLOG_HONORAWARD",
                        },
                        tokens = {
                            Tokens.ValueNumber,
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

        ---@class MiniLootMessageFormatSimpleParserResultExperience
        ---@field public Type MiniLootMessageFormatSimpleParserResultExperienceTypes
        ---@field public Name? string If provided, the name of the NPC that died and granted XP.
        ---@field public Value number The amount of XP.
        ---@field public ValueExtra? number If provided, this is bonus XP.
        ---@field public Bonus? string If provided, this is bonus XP.
        ---@field public BonusExtra? string If provided, this is bonus XP.

        ---@class MiniLootMessageFormatSimpleParserResultExperienceArgs : MiniLootMessageFormatSimpleParserResultExperience
        ---@field public Value? number

        ---@class MiniLootMessageFormatExperience : MiniLootMessageFormat
        ---@field public result? MiniLootMessageFormatSimpleParserResultExperienceArgs

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
                            Tokens.ZoneString,
                            Tokens.ValueNumber,
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
                            Tokens.NameString,
                            Tokens.ValueNumber,
                            Tokens.BonusString,
                            Tokens.ValueExtraString,
                            Tokens.BonusExtraNumber,
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
                            Tokens.NameString,
                            Tokens.ValueNumber,
                            Tokens.BonusString,
                            Tokens.ValueExtraString,
                            Tokens.BonusExtraNumber,
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
                            Tokens.NameString,
                            Tokens.ValueNumber,
                            Tokens.BonusString,
                            Tokens.ValueExtraString,
                            Tokens.BonusExtraNumber,
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
                            Tokens.NameString,
                            Tokens.ValueNumber,
                            Tokens.BonusString,
                            Tokens.ValueExtraString,
                            Tokens.BonusExtraNumber,
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
                            Tokens.NameString,
                            Tokens.ValueNumber,
                            Tokens.BonusString,
                            Tokens.BonusExtraString,
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
                            Tokens.NameString,
                            Tokens.ValueNumber,
                            Tokens.BonusString,
                            Tokens.BonusExtraString,
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
                            Tokens.NameString,
                            Tokens.ValueNumber,
                            Tokens.ValueExtraNumber,
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
                            Tokens.NameString,
                            Tokens.ValueNumber,
                            Tokens.ValueExtraNumber,
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
                            Tokens.NameString,
                            Tokens.ValueNumber,
                        },
                    },
                    {
                        formats = {
                            "COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED_RAID",
                        },
                        tokens = {
                            Tokens.ValueNumber,
                            Tokens.ValueExtraNumber,
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
                            Tokens.ValueNumber,
                            Tokens.ValueExtraNumber,
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
                            Tokens.ValueNumber,
                        },
                    },
                    {
                        formats = {
                            "COMBATLOG_XPGAIN_QUEST",
                        },
                        tokens = {
                            Tokens.ValueNumber,
                            Tokens.BonusString,
                            Tokens.BonusExtraString,
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
                            Tokens.ValueNumber,
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

        ---@class MiniLootMessageFormatSimpleParserResultGuildExperience
        ---@field public Type MiniLootMessageFormatSimpleParserResultGuildExperienceTypes
        ---@field public Value number The amount of guild XP earned.

        ---@class MiniLootMessageFormatSimpleParserResultGuildExperienceArgs : MiniLootMessageFormatSimpleParserResultGuildExperience
        ---@field public Value? number

        ---@class MiniLootMessageFormatGuildExperience : MiniLootMessageFormat
        ---@field public result? MiniLootMessageFormatSimpleParserResultGuildExperienceArgs

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
                            Tokens.ValueNumber,
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

        ---@class MiniLootMessageFormatSimpleParserResultFollowerExperience
        ---@field public Type MiniLootMessageFormatSimpleParserResultFollowerExperienceTypes
        ---@field public Name string The name of the follower earning the XP.
        ---@field public Value number The amount of XP earned.

        ---@class MiniLootMessageFormatSimpleParserResultFollowerExperienceArgs : MiniLootMessageFormatSimpleParserResultFollowerExperience
        ---@field public Name? string
        ---@field public Value? number

        ---@class MiniLootMessageFormatFollowerExperience : MiniLootMessageFormat
        ---@field public result? MiniLootMessageFormatSimpleParserResultFollowerExperienceArgs

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
                            Tokens.NameString,
                            Tokens.ValueNumber,
                        },
                    },
                },
            }
        )

        -- TODO: globalstrings doesn't contain this particular format
        -- this hack won't work for all locales so this will be an issue
        _G.MINILOOT_DELVE_EXPERIENCE_GAIN_POLYFILL = "%s has gained %d experience."

        AppendMessages(
            {
                group = MiniLootMessageGroup.FollowerExperience,
                events = {
                    "CHAT_MSG_COMBAT_FACTION_CHANGE",
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
                            "MINILOOT_DELVE_EXPERIENCE_GAIN_POLYFILL",
                        },
                        tokens = {
                            Tokens.NameString,
                            Tokens.ValueNumber,
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

        ---@class MiniLootMessageFormatSimpleParserResultCurrency
        ---@field public Type MiniLootMessageFormatSimpleParserResultCurrencyTypes
        ---@field public Link string The currency link.
        ---@field public Value? number If provided, the number of items received.

        ---@class MiniLootMessageFormatSimpleParserResultCurrencyArgs : MiniLootMessageFormatSimpleParserResultCurrency
        ---@field public Link? string

        ---@class MiniLootMessageFormatCurrency : MiniLootMessageFormat
        ---@field public result? MiniLootMessageFormatSimpleParserResultCurrencyArgs

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
                            Tokens.ValueNumber,
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

        ---@class MiniLootMessageFormatSimpleParserResultMoney
        ---@field public Type MiniLootMessageFormatSimpleParserResultMoneyTypes
        ---@field public Name? string If provided, this player earned the gold.
        ---@field public Value number The amount of money in copper.
        ---@field public ValueExtra? number If provided, the gold sent to the guild bank.

        ---@class MiniLootMessageFormatSimpleParserResultMoneyArgs : MiniLootMessageFormatSimpleParserResultMoney
        ---@field public Value? number

        ---@class MiniLootMessageFormatMoney : MiniLootMessageFormat
        ---@field public result? MiniLootMessageFormatSimpleParserResultMoneyArgs

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
                            Tokens.ValueMoney,
                            Tokens.ValueExtraMoney,
                        },
                    },
                    {
                        formats = {
                            "YOU_LOOT_MONEY",
                            "LOOT_MONEY_SPLIT",
                            "LOOT_MONEY_REFUND",
                        },
                        tokens = {
                            Tokens.ValueMoney,
                        },
                    },
                    {
                        formats = {
                            "LOOT_MONEY",
                        },
                        tokens = {
                            Tokens.NameString,
                            Tokens.ValueMoney,
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

        ---@class MiniLootMessageFormatSimpleParserResultLoot
        ---@field public Type MiniLootMessageFormatSimpleParserResultLootTypes
        ---@field public Name? string If provided, the name of the player looting.
        ---@field public Link string The item link.
        ---@field public Value? number If provided, the number of items looted.

        ---@class MiniLootMessageFormatSimpleParserResultLootArgs : MiniLootMessageFormatSimpleParserResultLoot
        ---@field public Link? string

        ---@class MiniLootMessageFormatLoot : MiniLootMessageFormat
        ---@field public result? MiniLootMessageFormatSimpleParserResultLootArgs

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
                            Tokens.NameTarget,
                            Tokens.Link,
                            Tokens.ValueNumber,
                        },
                    },
                    {
                        formats = {
                            "CREATED_ITEM",
                        },
                        tokens = {
                            Tokens.NameTarget,
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
                            Tokens.ValueNumber,
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
                            Tokens.ValueNumber,
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
                            Tokens.NameTarget,
                            Tokens.Link,
                            Tokens.ValueNumber,
                        },
                    },
                    {
                        formats = {
                            "LOOT_ITEM_BONUS_ROLL",
                            "LOOT_ITEM",
                            "LOOT_ITEM_PUSHED",
                        },
                        tokens = {
                            Tokens.NameTarget,
                            Tokens.Link,
                        },
                    },
                },
            }
        )

    end

    -- Loot Roll
    do

        ---@alias MiniLootMessageFormatSimpleParserResultLootRollKeys "Name"|"Link"|"Value"|"ValueExtra"

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
        ---|"LostResult"
        ---|"YouWinnerResult"
        ---|"WinnerResult"
        ---|"StartRoll"

        ---@class MiniLootMessageFormatSimpleParserResultLootRoll
        ---@field public Type MiniLootMessageFormatSimpleParserResultLootRollTypes
        ---@field public Name? string If provided, the name of the player looting.
        ---@field public Link string The item link.
        ---@field public Value? number If provided, the loot history ID.
        ---@field public ValueExtra? number If provided, the loot history ID.

        ---@class MiniLootMessageFormatSimpleParserResultLootRollArgs : MiniLootMessageFormatSimpleParserResultLootRoll
        ---@field public Link? string

        ---@class MiniLootMessageFormatSimpleParserResultLootRoll_LootRollInfo
        ---@field public Type "AllPass"
        ---@field public Link string The item link.
        ---@field public Value number Loot history ID.
        ---@field public Name? string The name of the player. Relevant for `DisenchantCredit` and `IneligibleResult`.

        ---@class MiniLootMessageFormatSimpleParserResultLootRoll_LootRollYouDecide
        ---@field public Type "YouPass"|"YouDisenchant"|"YouGreed"|"YouNeed"
        ---@field public Link string The item link.
        ---@field public Value number Loot history ID.
        ---@field public ValueExtra? number Loot history ID.

        ---@class MiniLootMessageFormatSimpleParserResultLootRoll_LootRollDecide
        ---@field public Type "Pass"|"Disenchant"|"Greed"|"Need"
        ---@field public Link string The item link.
        ---@field public Name string The name of the player.

        ---@class MiniLootMessageFormatSimpleParserResultLootRoll_LootRollRolled
        ---@field public Type "DisenchantRoll"|"GreedRoll"|"NeedRoll"
        ---@field public Link string The item link.
        ---@field public Name string The name of the player.
        ---@field public Value number The number rolled.

        ---@class MiniLootMessageFormatSimpleParserResultLootRoll_LootRollYouResult
        ---@field public Type "YouDisenchantResult"|"YouGreedResult"|"YouNeedResult"
        ---@field public Link string The item link.
        ---@field public Value number Loot history ID.
        ---@field public ValueExtra number The number rolled.

        -- Note that `YouWinnerResult` and `WinnerResult` only have `Link` and `Name` assigned.
        ---@class MiniLootMessageFormatSimpleParserResultLootRoll_LootRollResult
        ---@field public Type "DisenchantResult"|"GreedResult"|"NeedResult"|"LostResult"|"YouWinnerResult"|"WinnerResult"
        ---@field public Link string The item link.
        ---@field public Name string The name of the player.
        ---@field public Value number Loot history ID.
        ---@field public ValueExtra number The number rolled.
        ---@field public NameExtraString? string The roll type like `Need` or `Greed`, etc.

        ---@class MiniLootMessageFormatLootRoll : MiniLootMessageFormat
        ---@field public result? MiniLootMessageFormatSimpleParserResultLootRollArgs

        AppendMessages(
            {
                group = MiniLootMessageGroup.LootRoll,
                events = {
                    "CHAT_MSG_LOOT",
                },
                ---@type MiniLootMessageFormatSimpleParserResultLootRollArgs
                result = {
                    Type = "FallbackRoll",
                },
                defaultDebounce = 0,
            },
            {
                group = MiniLootMessageGroup.LootRollInfo,
                ---@type MiniLootMessageFormatLootRoll[]
                formats = {
                    {
                        formats = {
                            "LOOT_ROLL_ALL_PASSED",
                        },
                        tokens = {
                            Tokens.ValueNumber,
                            Tokens.Link,
                        },
                        result = {
                            Type = "AllPass",
                        },
                    },
                },
            },
            {
                group = MiniLootMessageGroup.LootRollYouDecide,
                ---@type MiniLootMessageFormatLootRoll[]
                formats = {
                    {
                        formats = {
                            "LOOT_ROLL_PASSED_SELF_AUTO",
                            "LOOT_ROLL_PASSED_SELF",
                        },
                        tokens = {
                            Tokens.ValueNumber,
                            Tokens.Link,
                            Tokens.ValueExtraNumber,
                        },
                        result = {
                            Type = "YouPass",
                        },
                    },
                    {
                        formats = {
                            "LOOT_ROLL_DISENCHANT_SELF",
                        },
                        tokens = {
                            Tokens.ValueNumber,
                            Tokens.Link,
                        },
                        result = {
                            Type = "YouDisenchant",
                        },
                    },
                    {
                        formats = {
                            "LOOT_ROLL_GREED_SELF",
                        },
                        tokens = {
                            Tokens.ValueNumber,
                            Tokens.Link,
                            Tokens.ValueExtraNumber,
                        },
                        result = {
                            Type = "YouGreed",
                        },
                    },
                    {
                        formats = {
                            "LOOT_ROLL_NEED_SELF",
                        },
                        tokens = {
                            Tokens.ValueNumber,
                            Tokens.Link,
                            Tokens.ValueExtraNumber,
                        },
                        result = {
                            Type = "YouNeed",
                        },
                    },
                },
            },
            {
                group = MiniLootMessageGroup.LootRollDecide,
                ---@type MiniLootMessageFormatLootRoll[]
                formats = {
                    {
                        formats = {
                            "LOOT_ROLL_PASSED_AUTO",
                            "LOOT_ROLL_PASSED_AUTO_FEMALE",
                            "LOOT_ROLL_PASSED",
                        },
                        tokens = {
                            Tokens.NameTarget,
                            Tokens.Link,
                        },
                        result = {
                            Type = "Pass",
                        },
                    },
                    {
                        formats = {
                            "LOOT_ROLL_DISENCHANT",
                        },
                        tokens = {
                            Tokens.NameTarget,
                            Tokens.Link,
                        },
                        result = {
                            Type = "Disenchant",
                        },
                    },
                    {
                        formats = {
                            "LOOT_ROLL_GREED",
                        },
                        tokens = {
                            Tokens.NameTarget,
                            Tokens.Link,
                        },
                        result = {
                            Type = "Greed",
                        },
                    },
                    {
                        formats = {
                            "LOOT_ROLL_NEED",
                        },
                        tokens = {
                            Tokens.NameTarget,
                            Tokens.Link,
                        },
                        result = {
                            Type = "Need",
                        },
                    },
                },
            },
            {
                group = MiniLootMessageGroup.LootRollRolled,
                ---@type MiniLootMessageFormatLootRoll[]
                formats = {
                    {
                        formats = {
                            "LOOT_ROLL_ROLLED_DE",
                        },
                        tokens = {
                            Tokens.ValueNumber,
                            Tokens.Link,
                            Tokens.NameTarget,
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
                            Tokens.ValueNumber,
                            Tokens.Link,
                            Tokens.NameTarget,
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
                            Tokens.ValueNumber,
                            Tokens.Link,
                            Tokens.NameTarget,
                        },
                        result = {
                            Type = "NeedRoll",
                        },
                    },
                },
            },
            {
                group = MiniLootMessageGroup.LootRollYouResult,
                ---@type MiniLootMessageFormatLootRoll[]
                formats = {
                    {
                        formats = {
                            "LOOT_ROLL_YOU_WON_NO_SPAM_DE",
                        },
                        tokens = {
                            Tokens.ValueNumber,
                            Tokens.ValueExtraNumber,
                            Tokens.Link,
                        },
                        result = {
                            Type = "YouDisenchantResult",
                        },
                    },
                    {
                        formats = {
                            "LOOT_ROLL_YOU_WON_NO_SPAM_GREED",
                        },
                        tokens = {
                            Tokens.ValueNumber,
                            Tokens.ValueExtraNumber,
                            Tokens.Link,
                        },
                        result = {
                            Type = "YouGreedResult",
                        },
                    },
                    {
                        formats = {
                            "LOOT_ROLL_YOU_WON_NO_SPAM_NEED",
                        },
                        tokens = {
                            Tokens.ValueNumber,
                            Tokens.ValueExtraNumber,
                            Tokens.Link,
                        },
                        result = {
                            Type = "YouNeedResult",
                        },
                    },
                },
            },
            {
                group = MiniLootMessageGroup.LootRollResult,
                ---@type MiniLootMessageFormatLootRoll[]
                formats = {
                    {
                        formats = {
                            "LOOT_ROLL_WON_NO_SPAM_DE",
                        },
                        tokens = {
                            Tokens.ValueNumber,
                            Tokens.NameTarget,
                            Tokens.ValueExtraNumber,
                            Tokens.Link,
                        },
                        result = {
                            Type = "DisenchantResult",
                        },
                    },
                    {
                        formats = {
                            "LOOT_ROLL_WON_NO_SPAM_GREED",
                        },
                        tokens = {
                            Tokens.ValueNumber,
                            Tokens.NameTarget,
                            Tokens.ValueExtraNumber,
                            Tokens.Link,
                        },
                        result = {
                            Type = "GreedResult",
                        },
                    },
                    {
                        formats = {
                            "LOOT_ROLL_WON_NO_SPAM_NEED",
                        },
                        tokens = {
                            Tokens.ValueNumber,
                            Tokens.NameTarget,
                            Tokens.ValueExtraNumber,
                            Tokens.Link,
                        },
                        result = {
                            Type = "NeedResult",
                        },
                    },
                },
            },
            {
                group = MiniLootMessageGroup.LootRollResult,
                ---@type MiniLootMessageFormatLootRoll[]
                formats = {
                    {
                        formats = {
                            "LOOT_ROLL_LOST_ROLL",
                        },
                        tokens = {
                            Tokens.ValueNumber,
                            Tokens.NameExtraString,
                            Tokens.ValueExtraNumber,
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
                            Tokens.NameTarget,
                            Tokens.Link,
                        },
                        result = {
                            Type = "WinnerResult",
                        },
                    },
                },
            },
            {
                group = MiniLootMessageGroup.LootRollInfo,
                ---@type MiniLootMessageFormatLootRoll[]
                formats = {
                    {
                        formats = {
                            "LOOT_ROLL_STARTED",
                        },
                        tokens = {
                            Tokens.ValueNumber,
                            Tokens.Link,
                        },
                        result = {
                            Type = "StartRoll",
                        },
                    },
                    {
                        formats = {
                            "LOOT_DISENCHANT_CREDIT",
                        },
                        tokens = {
                            Tokens.Link,
                            Tokens.NameTarget,
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
                            Tokens.NameTarget,
                            Tokens.Link,
                        },
                        result = {
                            Type = "IneligibleResult",
                        },
                    },
                },
            }
        )

    end

    -- Item Changed
    do

        ---@alias MiniLootMessageFormatSimpleParserResultItemChangedKeys "Link"|"LinkExtra"

        ---@alias MiniLootMessageFormatSimpleParserResultItemChangedTypes "ItemChanged"|"YouItemChanged"

        ---@class MiniLootMessageFormatSimpleParserResultItemChanged
        ---@field public Type MiniLootMessageFormatSimpleParserResultItemChangedTypes
        ---@field public Name? string The player name changing their item.
        ---@field public Link string The original item link.
        ---@field public LinkExtra string The new item link.

        ---@class MiniLootMessageFormatSimpleParserResultItemChangedArgs : MiniLootMessageFormatSimpleParserResultItemChanged
        ---@field public Link? string
        ---@field public LinkExtra? string

        ---@class MiniLootMessageFormatItemChanged : MiniLootMessageFormat
        ---@field public result? MiniLootMessageFormatSimpleParserResultItemChangedArgs

        AppendMessages(
            {
                group = MiniLootMessageGroup.ItemChanged,
                events = {
                    "CHAT_MSG_LOOT",
                },
                ---@type MiniLootMessageFormatSimpleParserResultItemChangedArgs
                result = {
                    Type = "ItemChanged",
                },
            },
            {
                ---@type MiniLootMessageFormatItemChanged[]
                formats = {
                    {
                        formats = {
                            "CHANGED_OWN_ITEM",
                        },
                        tokens = {
                            Tokens.Link,
                            Tokens.LinkExtra,
                        },
                        result = {
                            Type = "YouItemChanged",
                        },
                    },
                },
            },
            {
                ---@type MiniLootMessageFormatItemChanged[]
                formats = {
                    {
                        formats = {
                            "CHANGED_ITEM",
                        },
                        tokens = {
                            Tokens.NameTarget,
                            Tokens.Link,
                            Tokens.LinkExtra,
                        },
                        result = {
                            Type = "ItemChanged",
                        },
                    },
                },
            }
        )

    end

    -- Anima Power
    do

        ---@alias MiniLootMessageFormatSimpleParserResultAnimaPowerKeys "Link"

        ---@alias MiniLootMessageFormatSimpleParserResultAnimaPowerTypes "AnimaPower"

        ---@class MiniLootMessageFormatSimpleParserResultAnimaPower
        ---@field public Type MiniLootMessageFormatSimpleParserResultAnimaPowerTypes
        ---@field public Name string? The person gaining the power.
        ---@field public Link string The anima power link.

        ---@class MiniLootMessageFormatSimpleParserResultAnimaPowerArgs : MiniLootMessageFormatSimpleParserResultAnimaPower
        ---@field public Name? string
        ---@field public Link? string

        ---@class MiniLootMessageFormatAnimaPower : MiniLootMessageFormat
        ---@field public result? MiniLootMessageFormatSimpleParserResultAnimaPowerArgs

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
            },
            {
                formats = {
                    {
                        formats = {
                            "GAIN_MAW_POWER",
                        },
                        tokens = {
                            Tokens.NameTarget,
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

        ---@class MiniLootMessageFormatSimpleParserResultArtifactPower
        ---@field public Type MiniLootMessageFormatSimpleParserResultArtifactPowerTypes
        ---@field public Link string The artifact item link.
        ---@field public Value number The amount of power gained.

        ---@class MiniLootMessageFormatSimpleParserResultArtifactPowerArgs : MiniLootMessageFormatSimpleParserResultArtifactPower
        ---@field public Link? string
        ---@field public Value? number

        ---@class MiniLootMessageFormatArtifactPower : MiniLootMessageFormat
        ---@field public result? MiniLootMessageFormatSimpleParserResultArtifactPowerArgs

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
                            "AZERITE_XP_GAIN",
                        },
                        tokens = {
                            Tokens.Link,
                            Tokens.ValueNumber,
                        },
                    },
                },
            }
        )

    end

    -- Transmogrification
    do

        ---@alias MiniLootMessageFormatSimpleParserResultTransmogrificationKeys "Link"|"Value"

        ---@alias MiniLootMessageFormatSimpleParserResultTransmogrificationTypes "Transmogrification"|"TransmogrificationLoss"

        ---@class MiniLootMessageFormatSimpleParserResultTransmogrification
        ---@field public Type MiniLootMessageFormatSimpleParserResultTransmogrificationTypes
        ---@field public Link string

        ---@class MiniLootMessageFormatSimpleParserResultTransmogrificationArgs : MiniLootMessageFormatSimpleParserResultTransmogrification
        ---@field public Link? string

        ---@class MiniLootMessageFormatTransmogrification : MiniLootMessageFormat
        ---@field public result? MiniLootMessageFormatSimpleParserResultTransmogrificationArgs

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
                defaultDebounce = 0,
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
    do

        ---@alias MiniLootMessageFormatSimpleParserResultIgnoreKeys "Value"|"Link"

        ---@alias MiniLootMessageFormatSimpleParserResultIgnoreTypes "Ignore"|"IgnoreExperience"|"IgnoreMoney"|"IgnoreArtifactPower"

        ---@class MiniLootMessageFormatSimpleParserResultIgnore
        ---@field public Type MiniLootMessageFormatSimpleParserResultIgnoreTypes
        ---@field public Value? number
        ---@field public Link? string

        ---@class MiniLootMessageFormatSimpleParserResultIgnoreArgs : MiniLootMessageFormatSimpleParserResultIgnore

        ---@class MiniLootMessageFormatIgnore : MiniLootMessageFormat
        ---@field public result? MiniLootMessageFormatSimpleParserResultIgnoreArgs

        ---@type MiniLootMessageFormatSimpleParser
        ---@param result MiniLootMessageFormatSimpleParserResultIgnore
        local function CustomItemParser(result)
            if not result.Link then
                return
            end
            local currencyInfo = C_CurrencyInfo.GetCurrencyInfoFromLink(result.Link)
            if not currencyInfo then
                return
            end
            if currencyInfo.quantity == 0 and currencyInfo.maxQuantity == 0 then
                result.Type = "IgnoreArtifactPower"
            end
        end

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
                            "LOOT_ITEM_PUSHED_SELF_MULTIPLE",
                        },
                        tokens = {
                            Tokens.Link,
                            Tokens.ValueNumber,
                        },
                        parser = CustomItemParser,
                    },
                    {
                        formats = {
                            "LOOT_ITEM_PUSHED_SELF",
                        },
                        tokens = {
                            Tokens.Link,
                        },
                        parser = CustomItemParser,
                    },
                    {
                        formats = {
                            "ERR_QUEST_REWARD_EXP_I",
                        },
                        tokens = {
                            Tokens.ValueNumber,
                        },
                        result = {
                            Type = "IgnoreExperience",
                        },
                    },
                    {
                        formats = {
                            "ERR_QUEST_REWARD_MONEY_S",
                        },
                        tokens = {
                            Tokens.ValueMoney,
                        },
                        result = {
                            Type = "IgnoreMoney",
                        },
                    },
                },
            }
        )

    end

end

-- local ProcessTokensLinkPattern = "^%s*|h"

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
---@return MiniLootMessageFormatSimpleParserResults?
local function ProcessMatchedToResult(messageFormat, matches)
    local tokens = messageFormat.tokens
    local numTokens = #tokens
    local result ---@type MiniLootMessageFormatSimpleParserResults?
    if messageFormat.result then
        result = TableCopy(messageFormat.result)
    end
    for i = 1, numTokens do
        local token = tokens[i]
        local match = matches[i] ---@type string?
        local key, value = ProcessTokens(token, match)
        if key then
            if not result then
                result = { Type = "Fallback" }
            end
            result[key] = value
        end
    end
    local parser = messageFormat.parser
    if parser and result then
        local parserResult = parser(result)
        if parserResult ~= nil then
            if parserResult == false then
                result = nil
            else
                result = parserResult
            end
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
---@return MiniLootMessageFormatSimpleParserResults?, MiniLootMessage
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
                                return result, message
                            end
                        end
                    end
                end
            end
        end
    end
    return ---@diagnostic disable-line: missing-return-value
end

---@param message MiniLootMessage
---@param includeResult? boolean
---@return string? text, MiniLootMessageFormatSimpleParserResults? result
local function GenerateChatMessage(message, includeResult)
    local tests = message.tests
    if not tests then
        return
    end
    local testIndex = random(1, #message.tests)
    local test = message.tests[testIndex]
    if not includeResult then
        return test[1]
    end
    local args = TableCopy(test) ---@type any[]
    local text = table.remove(args, 1) ---@type string
    local eventIndex = random(1, #message.events)
    local event = message.events[eventIndex]
    local result = ProcessChatMessage(event, text)
    return text, result
end

---@param includeResult? boolean
---@param predicate (fun(message: MiniLootMessage): boolean?)?
---@return fun(): MiniLootMessage?, string?, MiniLootMessageFormatSimpleParserResults?
local function CreateChatMessageGenerator(includeResult, predicate)
    local count = #MessagesCollection
    local index = 0
    return function()
        index = index + 1
        if index > count then
            index = 1
        end
        for i = index, count do
            local message = MessagesCollection[i]
            if not predicate or predicate(message) then
                index = i
                return message, GenerateChatMessage(message, includeResult)
            end
        end
        local message = MessagesCollection[index]
        return message, GenerateChatMessage(message, includeResult)
    end
end

---@param result MiniLootMessageFormatSimpleParserResults
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
---@return MiniLootMessageFormatSimpleParserResults? successResult, MiniLootMessageFormatSimpleParserResults[]? closeResults
local function RunAndEvaluateTest(message, test)
    local isMoney = message.group == MiniLootMessageGroup.Money
    local successResult ---@type MiniLootMessageFormatSimpleParserResults?
    local closeResults ---@type MiniLootMessageFormatSimpleParserResults[]?
    local closeIndex ---@type number?
    local args = TableCopy(test) ---@type any[]
    local text = table.remove(args, 1) ---@type string
    for _, event in ipairs(message.events) do
        local result = ProcessChatMessage(event, text)
        if result then
            local isMoneyResult = result.Type == "IgnoreMoney"
            local success = CompareTestResults(result, args, isMoney or isMoneyResult)
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
            print(format("%s |cff%sfailed|r %s", message.group, SimpleHexColors.Red, test[1]))
            if closeResults then
                for _, closeResult in ipairs(closeResults) do
                    for k, v in pairs(closeResult) do
                        print(format(" - |cff%s%s|r %s", SimpleHexColors.Yellow, tostringall(k, v)))
                    end
                end
            end
        end
    end
end

local function RunMessageTests()
    if not ns.DebugRunTests then
        return
    end
    for _, message in ipairs(MessagesCollection) do
        if not message.skipTests then
            RunAndEvaluateTests(message)
        end
    end
end

FinalizeMessages()
RunMessageTests()

---@class MiniLootNSMessages
ns.Messages = {
    MiniLootMessageGroup = MiniLootMessageGroup,
    MessagesCollection = MessagesCollection,
    ProcessChatMessage = ProcessChatMessage,
    CreateChatMessageGenerator = CreateChatMessageGenerator,
}
