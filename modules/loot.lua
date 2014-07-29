local _G = _G
local ChatFrame_AddMessageEventFilter = ChatFrame_AddMessageEventFilter
local ChatFrame_RemoveMessageEventFilter = ChatFrame_RemoveMessageEventFilter
local format = format
local GetCoinTextureString = GetCoinTextureString
local GetCurrencyLink = GetCurrencyLink
local GetCVarBool = GetCVarBool
local GetGuildInfo = GetGuildInfo
local GetItemQualityColor = GetItemQualityColor
local GetTime = GetTime
local InCombatLockdown = InCombatLockdown
local ipairs = ipairs
local IsMasterLooter = IsMasterLooter
local IsModifiedClick = IsModifiedClick
local ItemRefTooltip = ItemRefTooltip
local math_abs = math.abs
local next = next
local pairs = pairs
local select = select
local SetItemRef = SetItemRef
local table_insert = table.insert
local table_sort = table.sort
local table_wipe = table.wipe
local tonumber = tonumber
local tostring = tostring
local type = type
local UnitName = UnitName

local addonName, addonData = ...
local L, print, module = addonData.L, addonData.print, addonData:NewModule("LOOT")
local matches, elapsed, report

local CURRENCY_COUNT = "C_C"
local CURRENCY_NAME = "C_N"
local HONOR_NAME = "H_N"
local HONOR_RANK = "H_R"
local HONOR_VALUE = "H_V"
local IS_INSTANT = "I_I"
local ITEM_COUNT = "I_C"
local ITEM_HISTORY = "I_H"
local ITEM_LINK = "I_L"
local ITEM_ROLL = "I_R"
local ITEM_TARGET = "I_T"
local NO_INSTANT = "N_I"
local REP_GAINED = "R_G"
local REP_LOST = "R_L"
local REP_NAME = "R_N"
local REP_VALUE = "R_V"
local ROLL_ALL_PASSED = "RO_A_P"
local ROLL_DE = "RO_D"
local ROLL_GREED = "RO_G"
local ROLL_LOST = "RO_L"
local ROLL_NEED = "RO_N"
local ROLL_PASSED = "RO_P"
local ROLL_START = "RO_S"
local ROLL_WON = "RO_W"
local XP_GAINED = "X_G"
local XP_LOST = "X_L"
local XP_NAME = "X_N"
local XP_VALUE = "X_V"

local function IsRollDecision(i)
  return i == ROLL_ALL_PASSED or i == ROLL_DE or i == ROLL_GREED or i == ROLL_NEED or i == ROLL_PASSED or i == ROLL_START or i == ROLL_WON
end

local function IsRollType(i)
  return i == ROLL_DE or i == ROLL_GREED or i == ROLL_NEED or i == ROLL_LOST
end

local function NewLine(raw)
  if raw:sub(raw:len()) ~= "\n" then
    return raw.."\n"
  end
  return raw
end

local function OutputReport()
  local eventOrder = {
    "CHAT_MSG_COMBAT_XP_GAIN",
    "CHAT_MSG_COMBAT_GUILD_XP_GAIN",
    "CHAT_MSG_COMBAT_FACTION_CHANGE",
    "CHAT_MSG_COMBAT_HONOR_GAIN",
    "CHAT_MSG_MONEY",
    "CHAT_MSG_CURRENCY",
    "CHAT_MSG_LOOT",
  }

  local eventReport, temp
  local str, lastName = ""

  for _, event in ipairs(eventOrder) do
    eventReport = report[event]

    if eventReport then
      if event == "CHAT_MSG_COMBAT_XP_GAIN" then
        temp = tonumber(eventReport[UnitName("player")])

        if temp then
          str = str .. format("|cffFFFF00%s: %d|r ", XP, temp)
        end

      elseif event == "CHAT_MSG_COMBAT_GUILD_XP_GAIN" then
        temp = tonumber(eventReport[GUILD] or eventReport[GetGuildInfo("player")])

        if temp then
          str = str .. format("|cffFFFF00%s%s: %d|r ", GUILD:sub(1, 1):len() > 0 and GUILD:sub(1, 1) or GUILD:sub(1, 2), XP, temp)
        end

      elseif event == "CHAT_MSG_COMBAT_FACTION_CHANGE" then
        for factionName, reputation in pairs(eventReport) do
          if reputation > 0 then
            str = str .. format("|cff9696FF%s|r|cff%s+%d|r ", addonData:Abbreviate(factionName), "00FF00", reputation)
          elseif reputation < 0 then
            str = str .. format("|cff9696FF%s|r|cff%s-%d|r ", addonData:Abbreviate(factionName), "FF0000", math_abs(reputation))
          end
        end

      elseif event == "CHAT_MSG_COMBAT_HONOR_GAIN" then
        temp = tonumber(eventReport[UnitName("player")])

        if temp then
          temp = format("%.2f", temp)

          if (tonumber(temp) or 0) > 0 then -- skip decimal honor values from being shown
            str = str .. format("|cff9696FF%s: %s|r ", HONOR, temp)
          end
        end

      elseif event == "CHAT_MSG_CURRENCY" then
        for playerName, currencies in pairs(eventReport) do
          if lastName ~= playerName then
            str = str .. format("|cff%s%s|r|cffFFFF00:|r ", addonData:ClassColor(playerName), playerName)
            lastName = playerName
          end
          temp = 0
          if type(currencies) == "table" then
            for currencyLink, currencyCount in pairs(currencies) do
              if type(currencyCount) == "table" then
                currencyLink = currencyCount[1]
                currencyCount = tonumber(currencyCount[2]) or 1
              else
                currencyCount = tonumber(currencyCount) or 1
              end
              if addonData:GetBoolOpt("SHOW_LOOT_COUNT") then
                str = str .. format("%s%s%s ", addonData:GetIconWithLink(currencyLink, 1), currencyCount > 1 and "x"..currencyCount or "", addonData:GetCurrencyCount(currencyCount, currencyLink))
              else
                str = str .. format("%s%s ", addonData:GetIconWithLink(currencyLink, 1), currencyCount > 1 and "x"..currencyCount or "")
              end
              temp = temp + 1
            end
          end
          if temp == 0 then
            str = str .. format("|cff999999(%s)|r ", L.CHAT_NO_LOOT)
          end
        end

      elseif event == "CHAT_MSG_LOOT" then
        local sorted = {}
        for playerName, items in pairs(eventReport) do
          table_insert(sorted, {tostring(playerName), items})
        end
        table_sort(sorted, function(a, b) return a[1] < b[1] end)
        for i, data in ipairs(sorted) do
          local playerName, items = data[1], data[2]
          if playerName == 1 or playerName == "1" then
            lastName = ""
            if type(items) == "table" then
              str = NewLine(str)
              for item, rollData in pairs(items) do
                if addonData:GetBoolOpt("SHOW_ROLL_ICONS") then
                  item = addonData:GetIconWithLink(item)
                end
                str = str .. format("|cff00AA00%s|r %s|cff00AA00:|r ", L.CHAT_ROLL, item) -- BUG: "Wurf un" but this string is used by options for the word "Roll"
                local sortedRolls = {}
                local needFlag, bonusFlag, hasBonus
                for rollPlayerName, roll in pairs(rollData) do
                  if roll[1] == 1 then
                    needFlag = 1
                  end
                  roll[3], hasBonus = addonData:PlayerName(rollPlayerName)
                  if hasBonus then
                    bonusFlag = 1
                  end
                  table_insert(sortedRolls, roll)
                end
                table_sort(sortedRolls, function(a, b) return tonumber(a[2]) > tonumber(b[2]) end)
                for _, roll in ipairs(sortedRolls) do
                  local rollType, rollNumber, rollPlayerName = roll[1], roll[2], roll[3]
                  local color, suffix, skip
                  if rollPlayerName == UnitName("player") or (not needFlag or (needFlag and rollType == 1)) and (not bonusFlag or (bonusFlag and rollNumber > 100)) then
                    if rollType == 1 then
                      color, suffix = "33EE33", L.CHAT_ROLL_N
                    elseif rollType == 2 then
                      color, suffix = "CCCC33", L.CHAT_ROLL_G
                    elseif rollType == 3 then
                      color, suffix = "EE3333", L.CHAT_ROLL_D
                    elseif rollType == 4 then
                      color, suffix = "CCCCCC", L.CHAT_ROLL_P
                    else
                      skip = 1 -- catches the "lost" rolls, do we really care when we lost? naah! oh well maybe I'll make it incorporate this later on, but right now it's not a priority.
                    end
                    if not skip then
                      if addonData:GetBoolOpt("SHOW_CLASS_COLORS") then
                        str = str .. format("|cff%s%s|r|cff%s:%s:%d|r ", addonData:ClassColor(rollPlayerName), rollPlayerName, color, suffix, rollNumber)
                      else
                        str = str .. format("|cff%s%s:%s:%d|r ", color, rollPlayerName, suffix, rollNumber)
                      end
                    end
                  end
                end
                str = NewLine(str)
              end
            end

          else
            if lastName ~= playerName then
              str = str .. format("|cff%s%s|r|cffFFFF00:|r ", addonData:ClassColor(playerName), playerName)
              lastName = playerName
            end
            temp = 0
            if type(items) == "table" then
              for _, item in pairs(items) do
                local itemLink, itemCount
                if type(item) == "table" then
                  itemLink = item[1]
                  itemCount = tonumber(item[2]) or 1
                else
                  itemLink = item
                  itemCount = 1
                end
                if playerName == UnitName("player") and addonData:GetBoolOpt("SHOW_LOOT_COUNT") then
                  str = str .. format("%s%s%s ", addonData:GetIconWithLink(itemLink), itemCount > 1 and "x"..itemCount or "", addonData:GetItemCount(itemCount, itemLink, true, true))
                else
                  str = str .. format("%s%s ", addonData:GetIconWithLink(itemLink), itemCount > 1 and "x"..itemCount or "")
                end
                temp = temp + 1
              end
            end
            if temp == 0 then
              str = str .. format("|cff999999(%s)|r ", L.CHAT_NO_LOOT)
            end
          end
        end

      elseif event == "CHAT_MSG_MONEY" then
        for playerName, copper in pairs(eventReport) do
          if (tonumber(copper) or 0) > 0 then
            if lastName ~= playerName then
              str = str .. format("|cff%s%s|r|cffFFFF00:|r ", addonData:ClassColor(playerName), playerName)
              lastName = playerName
            end
            str = str .. format("|cffFFFF00%s|r ", GetCoinTextureString(copper))
          end
        end
      end
    end
  end

  if str ~= "" then
    for _, line in ipairs({("\n"):split(str)}) do
      line = line:trim()
      if line ~= "" then
        print(line)
      end
    end
  end
end

local function OnUpdate(module, elapse)
  if InCombatLockdown() and addonData:GetOpt("SLEEP_AFTER_COMBAT") ~= -1 then
    return
  end
  if not module.lastEvent then
    return
  end
	if addonData:GetBoolOpt("SLEEP_DURING_TRADESKILL") and select(7, UnitCastingInfo("player")) then -- is casting a tradeskill
		module:BUMP_LAST_EVENT()
		return
	end
  elapsed = elapsed + elapse
  if GetTime() - module.lastEvent < addonData:GetOpt("SLEEP_BETWEEN_EVENTS") then
    return
  end
  if elapsed >= addonData:GetOpt("SLEEP_AFTER_COMBAT") then
    elapsed = 0
    module.lastEvent = nil
    module:SetScript("OnUpdate", nil)
    OutputReport()
    table_wipe(report)
  end
end

local function ChatEventFilter(chatFrame, event, ...)
  if chatFrame == addonData:GetChatFrame() then
    if not addonData:GetBoolOpt("PET_BATTLES") and event:match("PET_BATTLE") then
      return
    end
    return true
  end
end

local function SpecialChatEventFilter(chatFrame, event, message, ...)
  if chatFrame == addonData:GetChatFrame() then
    if message:match(addonData:FormatMatcher(ERR_QUEST_REWARD_MONEY_S)) then
      module:CHAT_MSG_MONEY("CHAT_MSG_MONEY", format(YOU_LOOT_MONEY, message), ...)
      return true
    elseif message:match(addonData:FormatMatcher(ERR_QUEST_REWARD_EXP_I)) then
      return true
    end
    local itemLink, byName = message:match(addonData:FormatMatcher(LOOT_DISENCHANT_CREDIT))
    if itemLink then
      return false, format(LOOT_DISENCHANT_CREDIT, addonData:GetIconWithLink(itemLink), byName), ...
    end
  end
end

function addonData:AddEventFilter(event)
  if not MiniLootDB.HIDE_EVENTS then
    MiniLootDB.HIDE_EVENTS = {}
  end
  MiniLootDB.HIDE_EVENTS[event] = 1
end

function addonData:RemoveEventFilter(event)
  if not MiniLootDB.HIDE_EVENTS then
    return
  end
  MiniLootDB.HIDE_EVENTS[event] = nil
end

function addonData:HasEventFilter(event)
  if not MiniLootDB.HIDE_EVENTS then
    return
  end
  return MiniLootDB.HIDE_EVENTS[event]
end

function module:OnLoad()
  matches = {
    CHAT_MSG_COMBAT_FACTION_CHANGE = { -- factionName, repValue, flag(REP_GAINED|REP_LOST)
      [1] = {FACTION_STANDING_INCREASED_DOUBLE_BONUS,      {REP_NAME,  REP_VALUE},  {1, 2, REP_GAINED}}, -- "Reputation with %s increased by %d. (+%.1f Refer-A-Friend bonus) (+%.1f bonus)"
      [2] = {FACTION_STANDING_INCREASED_BONUS,             {REP_NAME,  REP_VALUE},  {1, 2, REP_GAINED}}, -- "Reputation with %s increased by %d. (+%.1f Refer-A-Friend bonus)"
      [3] = {FACTION_STANDING_INCREASED_ACH_BONUS,         {REP_NAME,  REP_VALUE},  {1, 2, REP_GAINED}}, -- "Reputation with %s increased by %d. (+%.1f bonus)"
      [4] = {FACTION_STANDING_INCREASED,                   {REP_NAME,  REP_VALUE},  {1, 2, REP_GAINED}}, -- "Reputation with %s increased by %d."
      [5] = {FACTION_STANDING_INCREASED_GENERIC,           {REP_NAME},              {1, 0, REP_GAINED}}, -- "Reputation with %s increased."
      [6] = {FACTION_STANDING_DECREASED,                   {REP_NAME,  REP_VALUE},  {1, 2, REP_LOST}},   -- "Reputation with %s decreased by %d."
      [7] = {FACTION_STANDING_DECREASED_GENERIC,           {REP_NAME},              {1, 0, REP_LOST}},   -- "Reputation with %s decreased."
    },
    CHAT_MSG_COMBAT_HONOR_GAIN = { -- honorPoints, sourceName, rankName
      [1] = {COMBATLOG_HONORAWARD,                         {HONOR_VALUE},                            {1, 0, 0}}, -- "You have been awarded %.2f honor points."
      [2] = {COMBATLOG_HONORGAIN,                          {HONOR_NAME,  HONOR_RANK,  HONOR_VALUE},  {3, 1, 2}}, -- "%s dies, honorable kill Rank: %s (%.2f Honor Points)"
      [3] = {COMBATLOG_HONORGAIN_NO_RANK,                  {HONOR_NAME,  HONOR_VALUE},               {2, 1, 0}}, -- "%s dies, honorable kill (%.2f Honor Points)"
    },
    CHAT_MSG_COMBAT_XP_GAIN = { -- xpPoints, sourceName, flag(XP_GAINED|XP_LOST)
      [1] = {COMBATLOG_XPGAIN_EXHAUSTION1,                 {XP_NAME,   XP_VALUE},  {2, 1, XP_GAINED}}, -- "%s dies, you gain %d experience. (%s exp %s bonus)"
      [2] = {COMBATLOG_XPGAIN_EXHAUSTION1_GROUP,           {XP_NAME,   XP_VALUE},  {2, 1, XP_GAINED}}, -- "%s dies, you gain %d experience. (%s exp %s bonus, +%d group bonus)"
      [3] = {COMBATLOG_XPGAIN_EXHAUSTION1_RAID,            {XP_NAME,   XP_VALUE},  {2, 1, XP_GAINED}}, -- "%s dies, you gain %d experience. (%s exp %s bonus, -%d raid penalty)"
      [4] = {COMBATLOG_XPGAIN_EXHAUSTION2,                 {XP_NAME,   XP_VALUE},  {2, 1, XP_GAINED}}, -- "%s dies, you gain %d experience. (%s exp %s bonus)"
      [5] = {COMBATLOG_XPGAIN_EXHAUSTION2_GROUP,           {XP_NAME,   XP_VALUE},  {2, 1, XP_GAINED}}, -- "%s dies, you gain %d experience. (%s exp %s bonus, +%d group bonus)"
      [6] = {COMBATLOG_XPGAIN_EXHAUSTION2_RAID,            {XP_NAME,   XP_VALUE},  {2, 1, XP_GAINED}}, -- "%s dies, you gain %d experience. (%s exp %s bonus, -%d raid penalty)"
      [7] = {COMBATLOG_XPGAIN_EXHAUSTION4,                 {XP_NAME,   XP_VALUE},  {2, 1, XP_GAINED}}, -- "%s dies, you gain %d experience. (%s exp %s penalty)"
      [8] = {COMBATLOG_XPGAIN_EXHAUSTION4_GROUP,           {XP_NAME,   XP_VALUE},  {2, 1, XP_GAINED}}, -- "%s dies, you gain %d experience. (%s exp %s penalty, +%d group bonus)"
      [9] = {COMBATLOG_XPGAIN_EXHAUSTION4_RAID,            {XP_NAME,   XP_VALUE},  {2, 1, XP_GAINED}}, -- "%s dies, you gain %d experience. (%s exp %s penalty, -%d raid penalty)"
      [10] = {COMBATLOG_XPGAIN_EXHAUSTION5,                {XP_NAME,   XP_VALUE},  {2, 1, XP_GAINED}}, -- "%s dies, you gain %d experience. (%s exp %s penalty)"
      [11] = {COMBATLOG_XPGAIN_EXHAUSTION5_GROUP,          {XP_NAME,   XP_VALUE},  {2, 1, XP_GAINED}}, -- "%s dies, you gain %d experience. (%s exp %s penalty, +%d group bonus)"
      [12] = {COMBATLOG_XPGAIN_EXHAUSTION5_RAID,           {XP_NAME,   XP_VALUE},  {2, 1, XP_GAINED}}, -- "%s dies, you gain %d experience. (%s exp %s penalty, -%d raid penalty)"
      [13] = {COMBATLOG_XPGAIN_FIRSTPERSON,                {XP_NAME,   XP_VALUE},  {2, 1, XP_GAINED}}, -- "%s dies, you gain %d experience."
      [14] = {COMBATLOG_XPGAIN_FIRSTPERSON_GROUP,          {XP_NAME,   XP_VALUE},  {2, 1, XP_GAINED}}, -- "%s dies, you gain %d experience. (+%d group bonus)"
      [15] = {COMBATLOG_XPGAIN_FIRSTPERSON_RAID,           {XP_NAME,   XP_VALUE},  {2, 1, XP_GAINED}}, -- "%s dies, you gain %d experience. (-%d raid penalty)"
      [16] = {COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED,        {XP_VALUE},             {1, 0, XP_GAINED}}, -- "You gain %d experience."
      [17] = {COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED_GROUP,  {XP_VALUE},             {1, 0, XP_GAINED}}, -- "You gain %d experience. (+%d group bonus)"
      [18] = {COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED_RAID,   {XP_VALUE},             {1, 0, XP_GAINED}}, -- "You gain %d experience. (-%d raid penalty)"
      [19] = {COMBATLOG_XPGAIN_QUEST,                      {XP_VALUE},             {1, 0, XP_GAINED}}, -- "You gain %d experience. (%s exp %s bonus)"
      [20] = {COMBATLOG_XPLOSS_FIRSTPERSON_UNNAMED,        {XP_VALUE},             {1, 0, XP_LOST}},   -- "You lose %d experience."
    },
    CHAT_MSG_CURRENCY = { -- itemName, itemCount, targetName
      [1] = {CURRENCY_GAINED_MULTIPLE_BONUS,               {CURRENCY_NAME,  CURRENCY_COUNT},  {1, 2, 0}}, -- "You receive currency: %s x%d. (Bonus Objective)"
      [2] = {CURRENCY_GAINED_MULTIPLE,                     {CURRENCY_NAME,  CURRENCY_COUNT},  {1, 2, 0}}, -- "You receive currency: %s x%d."
      [3] = {CURRENCY_GAINED,                              {CURRENCY_NAME},                   {1, 0, 0}}, -- "You receive currency: %s."
    },
    CHAT_MSG_LOOT = {
      -- itemName, itemCount, targetName
      [1] = {LOOT_ITEM_CREATED_SELF_MULTIPLE,              {ITEM_LINK,    ITEM_COUNT},              {1, 2, 0}}, -- "You create: %sx%d."
      [2] = {LOOT_ITEM_CREATED_SELF,                       {ITEM_LINK},                             {1, 0, 0}}, -- "You create: %s."
      [3] = {LOOT_ITEM_PUSHED_SELF_MULTIPLE,               {ITEM_LINK,    ITEM_COUNT},              {1, 2, 0}}, -- "You receive item: %sx%d."
      [4] = {LOOT_ITEM_PUSHED_SELF,                        {ITEM_LINK},                             {1, 0, 0}}, -- "You receive item: %s."
      [5] = {LOOT_ITEM_SELF_MULTIPLE,                      {ITEM_LINK,    ITEM_COUNT},              {1, 2, 0}}, -- "You receive loot: %sx%d."
      [6] = {LOOT_ITEM_SELF,                               {ITEM_LINK},                             {1, 0, 0}}, -- "You receive loot: %s."
      [7] = {LOOT_ITEM_MULTIPLE,                           {ITEM_TARGET,  ITEM_LINK,  ITEM_COUNT},  {2, 3, 1}}, -- "%s receives loot: %sx%d."
      [8] = {LOOT_ITEM,                                    {ITEM_TARGET,  ITEM_LINK},               {2, 0, 1}}, -- "%s receives loot: %s."
      [9] = {CREATED_ITEM_MULTIPLE,                        {ITEM_TARGET,  ITEM_LINK,  ITEM_COUNT},  {2, 3, 1}}, -- "%s creates: %sx%d."
      [10] = {CREATED_ITEM,                                {ITEM_TARGET,  ITEM_LINK},               {2, 0, 1}}, -- "%s creates: %s."
      -- itemName, targetName, roll, rollType
      [11] = {LOOT_ROLL_YOU_WON_NO_SPAM_NEED,              {ITEM_HISTORY,  ITEM_ROLL,    ITEM_LINK},                {3, 0, 2, ROLL_NEED}},  -- "|HlootHistory:%d|h[Loot]|h: You (Need - %d) Won: %s"
      [12] = {LOOT_ROLL_YOU_WON_NO_SPAM_GREED,             {ITEM_HISTORY,  ITEM_ROLL,    ITEM_LINK},                {3, 0, 2, ROLL_GREED}}, -- "|HlootHistory:%d|h[Loot]|h: You (Greed - %d) Won: %s"
      [13] = {LOOT_ROLL_YOU_WON_NO_SPAM_DE,                {ITEM_HISTORY,  ITEM_ROLL,    ITEM_LINK},                {3, 0, 2, ROLL_DE}},    -- "|HlootHistory:%d|h[Loot]|h: You (Disenchant - %d) Won: %s"
      [14] = {LOOT_ROLL_WON_NO_SPAM_NEED,                  {ITEM_HISTORY,  ITEM_TARGET,  ITEM_ROLL,    ITEM_LINK},  {4, 2, 3, ROLL_NEED}},  -- "|HlootHistory:%d|h[Loot]|h: %s (Need - %d) Won: %s"
      [15] = {LOOT_ROLL_WON_NO_SPAM_GREED,                 {ITEM_HISTORY,  ITEM_TARGET,  ITEM_ROLL,    ITEM_LINK},  {4, 2, 3, ROLL_GREED}}, -- "|HlootHistory:%d|h[Loot]|h: %s (Greed - %d) Won: %s"
      [16] = {LOOT_ROLL_WON_NO_SPAM_DE,                    {ITEM_HISTORY,  ITEM_TARGET,  ITEM_ROLL,    ITEM_LINK},  {4, 2, 3, ROLL_DE}},    -- "|HlootHistory:%d|h[Loot]|h: %s (Disenchant - %d) Won: %s"
      [17] = {LOOT_ROLL_ROLLED_NEED_ROLE_BONUS,            {ITEM_ROLL,     ITEM_LINK,    ITEM_TARGET},              {2, 3, 1, ROLL_NEED}},  -- "Need Roll - %d for %s by %s + Role Bonus"
      [18] = {LOOT_ROLL_ROLLED_NEED,                       {ITEM_ROLL,     ITEM_LINK,    ITEM_TARGET},              {2, 3, 1, ROLL_NEED}},  -- "Need Roll - %d for %s by %s"
      [19] = {LOOT_ROLL_ROLLED_GREED,                      {ITEM_ROLL,     ITEM_LINK,    ITEM_TARGET},              {2, 3, 1, ROLL_GREED}}, -- "Greed Roll - %d for %s by %s"
      [20] = {LOOT_ROLL_ROLLED_DE,                         {ITEM_ROLL,     ITEM_LINK,    ITEM_TARGET},              {2, 3, 1, ROLL_DE}},    -- "Disenchant Roll - %d for %s by %s"
      [21] = {LOOT_ROLL_LOST_ROLL,                         {ITEM_HISTORY,  ROLL_LOST,    ITEM_ROLL,    ITEM_LINK},  {4, 0, 3, ROLL_LOST}},  -- "|HlootHistory:%d|h[Loot]|h: You have rolled %s - %d for: %s"
      -- itemName, targetName, decisionType, historyId, isInstant(NO_INSTANT|IS_INSTANT)
      [22] = {LOOT_ROLL_YOU_WON,                           {ITEM_LINK},                 {1, 0, ROLL_WON,        0, IS_INSTANT}}, -- "You won: %s"
      [23] = {LOOT_ROLL_WON,                               {ITEM_TARGET,   ITEM_LINK},  {2, 1, ROLL_WON,        0, IS_INSTANT}}, -- "%s won: %s"
      [24] = {LOOT_ROLL_ALL_PASSED,                        {ITEM_HISTORY,  ITEM_LINK},  {2, 0, ROLL_ALL_PASSED, 1, IS_INSTANT}}, -- "|HlootHistory:%d|h[Loot]|h: Everyone passed on: %s"
      [25] = {LOOT_ROLL_PASSED_SELF_AUTO,                  {ITEM_HISTORY,  ITEM_LINK},  {2, 0, ROLL_PASSED,     1, IS_INSTANT}}, -- "|HlootHistory:%d|h[Loot]|h: You automatically passed on: %s because you cannot loot that item."
      [26] = {LOOT_ROLL_PASSED_SELF,                       {ITEM_HISTORY,  ITEM_LINK},  {2, 0, ROLL_PASSED,     1, IS_INSTANT}}, -- "|HlootHistory:%d|h[Loot]|h: You passed on: %s"
      [27] = {LOOT_ROLL_PASSED_AUTO_FEMALE,                {ITEM_TARGET,   ITEM_LINK},  {2, 1, ROLL_PASSED,     0, IS_INSTANT}}, -- "%s automatically passed on: %s because she cannot loot that item."
      [28] = {LOOT_ROLL_PASSED_AUTO,                       {ITEM_TARGET,   ITEM_LINK},  {2, 1, ROLL_PASSED,     0, IS_INSTANT}}, -- "%s automatically passed on: %s because he cannot loot that item."
      [29] = {LOOT_ROLL_PASSED,                            {ITEM_TARGET,   ITEM_LINK},  {2, 1, ROLL_PASSED,     0, IS_INSTANT}}, -- "%s passed on: %s"
      [30] = {LOOT_ROLL_NEED_SELF,                         {ITEM_HISTORY,  ITEM_LINK},  {2, 0, ROLL_NEED,       1, IS_INSTANT}}, -- "|HlootHistory:%d|h[Loot]|h: You have selected Need for: %s"
      [31] = {LOOT_ROLL_NEED,                              {ITEM_TARGET,   ITEM_LINK},  {2, 1, ROLL_NEED,       0, IS_INSTANT}}, -- "%s has selected Need for: %s"
      [32] = {LOOT_ROLL_GREED_SELF,                        {ITEM_HISTORY,  ITEM_LINK},  {2, 0, ROLL_GREED,      1, IS_INSTANT}}, -- "|HlootHistory:%d|h[Loot]|h: You have selected Greed for: %s"
      [33] = {LOOT_ROLL_GREED,                             {ITEM_TARGET,   ITEM_LINK},  {2, 1, ROLL_GREED,      0, IS_INSTANT}}, -- "%s has selected Greed for: %s"
      [34] = {LOOT_ROLL_DISENCHANT_SELF,                   {ITEM_HISTORY,  ITEM_LINK},  {2, 0, ROLL_DE,         1, IS_INSTANT}}, -- "|HlootHistory:%d|h[Loot]|h: You have selected Disenchant for: %s"
      [35] = {LOOT_ROLL_DISENCHANT,                        {ITEM_TARGET,   ITEM_LINK},  {2, 1, ROLL_DE,         0, IS_INSTANT}}, -- "%s has selected Disenchant for: %s"
      -- itemName, rollId, isRollStart, historyId, isInstant(NO_INSTANT|IS_INSTANT)
      [36] = {LOOT_ROLL_STARTED,                           {ITEM_HISTORY,  ITEM_LINK},  {2, 0, ROLL_START,      1, IS_INSTANT}}, -- "|HlootHistory:%d|h[Loot]|h: %s"
    },
    CHAT_MSG_MONEY = { -- money, targetName
      [1] = {YOU_LOOT_MONEY_GUILD,                         {MONEY_VALUE},              {1, 0}}, -- "You loot %s (%s deposited to guild bank)"
      [2] = {YOU_LOOT_MONEY,                               {MONEY_VALUE},              {1, 0}}, -- "You loot %s"
      [3] = {LOOT_MONEY_SPLIT_GUILD,                       {MONEY_VALUE},              {1, 0}}, -- "Your share of the loot is %s. (%s deposited to guild bank)"
      [4] = {LOOT_MONEY_SPLIT,                             {MONEY_VALUE},              {1, 0}}, -- "Your share of the loot is %s."
      [5] = {LOOT_MONEY,                                   {MONEY_NAME, MONEY_VALUE},  {2, 1}}, -- "%s loots %s."
    },
    CHAT_MSG_COMBAT_GUILD_XP_GAIN = { -- xpPoints
      [1] = {COMBATLOG_GUILD_XPGAIN,                       {GXP_VALUE},  {1}}, -- "You gain %d guild experience."
    },
  }

  report = {}

  do
    local tempMatches, tempIndex, tempPattern = {}

    for event, patterns in pairs(matches) do
      for i, patternData in ipairs(patterns) do
        local pattern, matchTypes, matchOrder = patternData[1], patternData[2], patternData[3]

        if not tempMatches[event] then
          tempMatches[event] = {}
        end

        tempIndex = #tempMatches[event] + 1
        if not tempMatches[event][tempIndex] then
          tempMatches[event][tempIndex] = {}
        end

        tempPattern = addonData:FormatMatcher(_G[pattern] or pattern, "(.-)")
        for j, flag in ipairs(matchTypes) do
          if flag == CURRENCY_COUNT or flag == ITEM_COUNT or flag == ITEM_HISTORY or flag == REP_VALUE or flag == XP_VALUE then -- %d
            matchTypes[j] = "number"
          elseif flag == CURRENCY_NAME or flag == ITEM_LINK or flag == REP_NAME then -- %s
            matchTypes[j] = ""
          elseif flag == HONOR_NAME or flag == ITEM_TARGET or flag == XP_NAME then -- %s
            matchTypes[j] = ""
          elseif flag == HONOR_RANK then -- %s
            matchTypes[j] = ""
          elseif flag == HONOR_VALUE then -- %.2f
            matchTypes[j] = "float"
          elseif flag == ITEM_ROLL then -- ?
            matchTypes[j] = ""
          end
        end

        tempPattern = "^" .. addonData:PatternFlags(tempPattern, "(.-)", matchTypes) .. "$"
        tempMatches[event][tempIndex][tempPattern] = matchOrder
      end
    end

    table_wipe(matches)
    matches = tempMatches
  end

  do
    local _SetHyperlink = ItemRefTooltip.SetHyperlink
    local _SetItemRef = SetItemRef

    function ItemRefTooltip:SetHyperlink(link, ...)
      if module.IsEnabled and link:find(addonName, 0, 1) then
        return
      end
      return _SetHyperlink(self, link, ...)
    end

    function SetItemRef(link, text, button, chatFrame, ...)
      local curID = tonumber(link:match("currency:(%d+)"))
      if module.IsEnabled and curID and curID > 0 and IsModifiedClick() then
        text = GetCurrencyLink(curID) or text
      end
      return _SetItemRef(link, text, button, chatFrame, ...)
    end
  end
end

function module:Enable()
  if not module.IsEnabled then
    module.IsEnabled = 1
  else
    return
  end

  for event, _ in pairs(matches) do
    ChatFrame_AddMessageEventFilter(event, ChatEventFilter)
    module:RegisterEvent(event)
  end

  ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", SpecialChatEventFilter)

  module:RegisterEvent("LOOT_OPENED")
  module:RegisterEvent("LOOT_CLOSED")

  elapsed = 0
  --module:SetScript("OnUpdate", OnUpdate)
end

function module:Disable()
  if module.IsEnabled then
    module.IsEnabled = nil
  else
    return
  end

  for event, _ in pairs(matches) do
    ChatFrame_RemoveMessageEventFilter(event, ChatEventFilter)
    module:UnregisterEvent(event)
  end

  ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SYSTEM", SpecialChatEventFilter)

  module:UnregisterEvent("LOOT_OPENED")
  module:UnregisterEvent("LOOT_CLOSED")

  module:SetScript("OnUpdate", nil)
  elapsed = nil

  module.lastEvent = nil
  table_wipe(report)
end

function module:BUMP_LAST_EVENT()
  module.lastEvent = GetTime()
end

module.LOOT_OPENED = module.BUMP_LAST_EVENT
module.LOOT_CLOSED = module.BUMP_LAST_EVENT

function module:ON_MATCHER_EVENT(event, message, ...)
  module:BUMP_LAST_EVENT()

  local temp, found, ptable

  for i, patternData in ipairs(matches[event]) do
    for pattern, data in pairs(patternData) do
      temp = {message:match(pattern)}
      if #temp > 0 then
        found = temp
        ptable = data
        temp = pattern
        break
      end
    end
    if found then
      break
    end
  end

  if not found or not ptable then
    return
  end

  if addonData:HasEventFilter(event) then
    return
  end

  if not report[event] then
    report[event] = {}
  end

  --UIParentLoadAddOn("Blizzard_DebugTools") DevTools_Dump(temp) DevTools_Dump(found) DevTools_Dump(ptable) -- DEBUG

  if event == "CHAT_MSG_COMBAT_FACTION_CHANGE" then
    local factionName, repValue, flag =
      ptable[1] and found[ptable[1]],
      ptable[2] and tonumber(found[ptable[2]]),
      ptable[3]

    if factionName then
      flag = flag == REP_GAINED and 1 or -1

      report[event][factionName] = (report[event][factionName] or 0) + (math_abs(repValue or 0) * flag)
    end

  elseif event == "CHAT_MSG_COMBAT_HONOR_GAIN" then
    local honorPoints, sourceName, rankName =
      ptable[1] and tonumber(found[ptable[1]]),
      ptable[2] and addonData:PlayerName(found[ptable[2]]) or UnitName("player"),
      ptable[3] and found[ptable[3]]

    if honorPoints then
      sourceName = UnitName("player") -- this type of event is limited only to the player anyway

      report[event][sourceName] = (report[event][sourceName] or 0) + honorPoints
    end

  elseif event == "CHAT_MSG_COMBAT_XP_GAIN" then
    local xpPoints, sourceName, flag =
      ptable[1] and tonumber(found[ptable[1]]),
      ptable[2] and addonData:PlayerName(found[ptable[2]]) or UnitName("player"),
      ptable[3]

    if xpPoints then
      sourceName = UnitName("player") -- this type of event is limited only to the player anyway
      flag = flag == XP_GAINED and 1 or -1

      report[event][sourceName] = (report[event][sourceName] or 0) + (math_abs(xpPoints) * flag)
    end

  elseif event == "CHAT_MSG_CURRENCY" then
    local itemName, itemCount, targetName =
      ptable[1] and found[ptable[1]],
      ptable[2] and tonumber(found[ptable[2]]) or 1,
      ptable[3] and addonData:PlayerName(found[ptable[3]]) or UnitName("player")

    if itemName then
      if not report[event][targetName] then
        report[event][targetName] = {}
      end

      report[event][targetName][itemName] = (report[event][targetName][itemName] or 0) + itemCount
    end

  elseif event == "CHAT_MSG_LOOT" then
    local itemName = ptable[1] and found[ptable[1]]
    local isRollDecision = ptable[5] == IS_INSTANT and IsRollDecision(ptable[3])
    local isRollType = IsRollType(ptable[4])

    if itemName and isRollDecision then
      if addonData:GetBoolOpt("SHOW_ROLL_DECISIONS") and addonData:InLFR(not addonData:GetBoolOpt("HIDE_LFR_ROLL_DECISIONS")) then
        local itemName, targetName, decisionType, historyId =
          addonData:GetBoolOpt("SHOW_ROLL_ICONS") and addonData:GetIconWithLink(itemName) or itemName,
          ptable[2] and addonData:PlayerName(found[ptable[2]]) or UnitName("player"),
          ptable[3],
          ptable[4] and tonumber(found[ptable[4]]) or 0

        -- itemName, targetName, decisionType, historyId, isInstant(NO_INSTANT|IS_INSTANT)
        -- itemName, rollId, isRollStart, historyId, isInstant(NO_INSTANT|IS_INSTANT)

        if decisionType == ROLL_ALL_PASSED then
          print(format("%s |cff%s%s: %s|r ", itemName, "CCCCCC", FRIENDS_FRIENDS_CHOICE_EVERYONE, PASS))
        elseif decisionType == ROLL_START then
          if not (GetCVarBool("autoOpenLootHistory") or IsMasterLooter()) then
            print(format("%s |cff%s|HlootHistory:%d|h[%s...]|h|r ", itemName, "CCCCCC", historyId, BONUS_ROLL_ROLLING))
          end
        elseif decisionType == ROLL_WON then
          print(format("%s |cff%s%s %s|r ", itemName, "CCCCCC", targetName, L.CHAT_WON))
        else
          if addonData:GetBoolOpt("SHOW_CLASS_COLORS") then
            print(format("%s |cff%s%s|r|cff%s: %s|r ", itemName, addonData:ClassColor(targetName), targetName, (decisionType == ROLL_DE and "EE3333") or (decisionType == ROLL_GREED and "CCCC33") or (decisionType == ROLL_NEED and "33EE33") or "CCCCCC", (decisionType == ROLL_DE and ROLL_DISENCHANT) or (decisionType == ROLL_GREED and GREED) or (decisionType == ROLL_NEED and NEED) or PASS))
          else
            print(format("%s |cff%s%s: %s|r ", itemName, (decisionType == ROLL_DE and "EE3333") or (decisionType == ROLL_GREED and "CCCC33") or (decisionType == ROLL_NEED and "33EE33") or "CCCCCC", targetName, (decisionType == ROLL_DE and ROLL_DISENCHANT) or (decisionType == ROLL_GREED and GREED) or (decisionType == ROLL_NEED and NEED) or PASS))
          end
        end
      end

    elseif itemName and isRollType then
      if addonData:GetBoolOpt("SHOW_ROLL_SUMMARY") and addonData:InLFR(not addonData:GetBoolOpt("HIDE_LFR_ROLL_SUMMARY")) then
        local itemName, targetName, roll, rollType =
          addonData:GetBoolOpt("SHOW_ROLL_ICONS") and addonData:GetIconWithLink(itemName) or itemName,
          ptable[2] and addonData:PlayerName(found[ptable[2]]) or UnitName("player"),
          ptable[3] and tonumber(found[ptable[3]]),
          ptable[4]

        if not report[event][1] then
          report[event][1] = {}
        end

        if not report[event][1][itemName] then
          report[event][1][itemName] = {}
        end

        if rollType == ROLL_DE then
          report[event][1][itemName][targetName] = {3, roll}
        elseif rollType == ROLL_GREED then
          report[event][1][itemName][targetName] = {2, roll}
        elseif rollType == ROLL_NEED then
          report[event][1][itemName][targetName] = {1, roll}
        else
          report[event][1][itemName][targetName] = {0, 0}
        end
      end

    elseif itemName then
      if not addonData:GetBoolOpt("HIDE_JUNK") or not itemName:find(select(4, GetItemQualityColor(0)), nil, 1) then
        local itemName, itemCount, targetName =
          itemName, -- addonData:GetBoolOpt("SHOW_ROLL_ICONS") and addonData:GetIconWithLink(itemName) or itemName,
          ptable[2] and tonumber(found[ptable[2]]) or 1,
          ptable[3] and addonData:PlayerName(found[ptable[3]]) or UnitName("player")

        local threshold, skip

        if addonData:GetBoolOpt("HIDE_PARTY_LOOT") and targetName ~= UnitName("player") then
          threshold = addonData:GetOpt("HIDE_PARTY_LOOT_T")
        elseif addonData:GetBoolOpt("HIDE_SOLO_LOOT") and targetName == UnitName("player") then
          threshold = addonData:GetOpt("HIDE_SOLO_LOOT_T")
        end

        if threshold and (threshold == 8 or threshold > addonData:GetQualityInfo(itemName)) then
          if not addonData:ItemStartsQuest(itemName, 1) then
            skip = 1
          end
        end

        if not skip then
          local itemID = tonumber(tostring(itemName):match("item:(%d+)") or tostring(itemName):match("battlepet:(%d+)") or itemName)

          if itemID then
            if not report[event][targetName] then
              report[event][targetName] = {}
            end

            if not report[event][targetName][itemID] then
              report[event][targetName][itemID] = {itemName, itemCount, targetName}
            else
              report[event][targetName][itemID][2] = report[event][targetName][itemID][2] + itemCount
            end

          else
            _G.print("ERROR: MiniLoot could not log regular item loot event with the following parameters: {"..event..", "..message..", "..tostring(itemName)..", "..tostring(itemCount)..", "..tostring(targetName).."} Please report this, and any other error messages that may have appeared, to the developers - thank you!") -- DEBUG: until this error is fixed, this helps users report more helpful comments!
          end
        end
      end
    end

  elseif event == "CHAT_MSG_MONEY" then
    local money, targetName =
      ptable[1] and found[ptable[1]],
      ptable[2] and addonData:PlayerName(found[ptable[2]]) or UnitName("player")

    if money then
      report[event][targetName] = (report[event][targetName] or 0) + addonData:MoneyToCopper(money)
    end

  elseif event == "CHAT_MSG_COMBAT_GUILD_XP_GAIN" then
    local xpPoints =
      ptable[1] and tonumber(found[ptable[1]])

    if xpPoints then
      local index = GetGuildInfo("player") or GUILD

      report[event][index] = (report[event][index] or 0) + math_abs(xpPoints)
    end
  end

  module:SetScript("OnUpdate", OnUpdate)
end

module.CHAT_MSG_COMBAT_FACTION_CHANGE = module.ON_MATCHER_EVENT
module.CHAT_MSG_COMBAT_HONOR_GAIN = module.ON_MATCHER_EVENT
module.CHAT_MSG_COMBAT_XP_GAIN = module.ON_MATCHER_EVENT
module.CHAT_MSG_CURRENCY = module.ON_MATCHER_EVENT
module.CHAT_MSG_LOOT = module.ON_MATCHER_EVENT
module.CHAT_MSG_MONEY = module.ON_MATCHER_EVENT
module.CHAT_MSG_COMBAT_GUILD_XP_GAIN = module.ON_MATCHER_EVENT
