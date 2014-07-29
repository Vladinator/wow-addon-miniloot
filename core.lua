local _G = _G
local C_PetJournal_GetPetInfoBySpeciesID = C_PetJournal.GetPetInfoBySpeciesID
local COPPER_AMOUNT = COPPER_AMOUNT
local CreateFrame = CreateFrame
local CUSTOM_RAID_CLASS_COLORS = CUSTOM_RAID_CLASS_COLORS
local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME
local FCF_GetChatWindowInfo = FCF_GetChatWindowInfo
local format = format
local GetAuctionItemClasses = GetAuctionItemClasses
local GetCurrencyInfo = GetCurrencyInfo
local GetCurrencyListInfo = GetCurrencyListInfo
local GetCurrencyListLink = GetCurrencyListLink
local GetCurrencyListSize = GetCurrencyListSize
local GetItemCount = GetItemCount
local GetItemIcon = GetItemIcon
local GetItemInfo = GetItemInfo
local GetItemQualityColor = GetItemQualityColor
local GetLFGMode = GetLFGMode
local GetLocale = GetLocale
local GOLD_AMOUNT = GOLD_AMOUNT
local ipairs = ipairs
local ITEM_BIND_QUEST = ITEM_BIND_QUEST
local ITEM_STARTS_QUEST = ITEM_STARTS_QUEST
local ITEM_UNIQUE = ITEM_UNIQUE
local LE_LFG_CATEGORY_LFR = LE_LFG_CATEGORY_LFR
local pairs = pairs
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local select = select
local SILVER_AMOUNT = SILVER_AMOUNT
local string_gsub = string.gsub
local table_concat = table.concat
local table_insert = table.insert
local table_wipe = table.wipe
local tonumber = tonumber
local tostring = tostring
local type = type
local UnitClass = UnitClass
local unpack = unpack

local addonName, addonData = ...
local L, addon = addonData.L, CreateFrame("Frame")
local tipScanner
addon.modules = {}
MiniLootDB = MiniLootDB or {}

addon:SetScript("OnEvent", function(addon, event, ...) addon[event](addon, event, ...) end)
addon:RegisterEvent("ADDON_LOADED")

function addon:ADDON_LOADED(event, name)
  if name == addonName then
    addon:UnregisterEvent(event)
    addon:RegisterEvent("CURRENCY_DISPLAY_UPDATE")

    tipScanner = CreateFrame("GameTooltip", "MiniLootTooltipScanner", UIParent, "GameTooltipTemplate")

    for _, module in ipairs(addon.modules) do
      module:OnLoad()
    end

    for _, module in ipairs(addon.modules) do
      if module.name == "LOOT" or module.name == "LOOT_ROLLS" or module.name == "EXTRA_LOOT" then
        module:Enable() -- these are modules enabled by default
      end
    end

    addonData:CheckModuleStates()
  end
end

function addon:CURRENCY_DISPLAY_UPDATE()
  addonData:CacheCurrency()
  addonData:CacheArchCurrency()
end

function addonData:GetModule(name)
  for _, module in ipairs(addon.modules) do
    if module.name == name then
      return module
    end
  end
end

function addonData:CheckModuleStates(name, isOptKey)
  for _, module in ipairs(addon.modules) do
    if isOptKey and module.optKey and name == module.optKey then
      if addonData:GetBoolOpt(module.optKey) then
        module:Enable()
      else
        module:Disable()
      end
      break

    elseif not isOptKey and module.optKey and (not name or name == module.name) then
      if addonData:GetBoolOpt(module.optKey) then
        module:Enable()
      else
        module:Disable()
      end
    end
  end
end

local defaults = {
  FONT_SIZE =               {0, 0, 32},
  HIDE_EVENTS =             {},
  HIDE_JUNK =               {0, 0, 1},
  HIDE_SOLO_LOOT =          {0, 0, 1},
  HIDE_SOLO_LOOT_T =        {0, 0, 9},
  HIDE_PARTY_LOOT =         {0, 0, 1},
  HIDE_PARTY_LOOT_T =       {0, 0, 9},
  CHAT_FRAME =              "ChatFrame1",
  SHOW_ROLL_DECISIONS =     {1, 0, 1},
  HIDE_LFR_ROLL_DECISIONS = {0, 0, 1},
  SHOW_ROLL_SUMMARY =       {1, 0, 1},
  HIDE_LFR_ROLL_SUMMARY =   {0, 0, 1},
  SHOW_ROLL_ICONS =         {0, 0, 1},
  SLEEP_AFTER_COMBAT =      {2, -1, 999},
  SLEEP_BETWEEN_EVENTS =    {2, 0, 999},
	SLEEP_DURING_TRADESKILL = {1, 0, 1},
  SHOW_MOUSEOVER_LINKS =    {0, 0, 1},
  MOUSEOVER_LINKS_ANCHOR =  {0, 0, 1},
  MOUSEOVER_LINKS_ICON =    {0, 0, 1},
  SHOW_LOOT_COUNT =         {0, 0, 1},
  SHOW_CLASS_COLORS =       {0, 0, 1},
  PET_BATTLES =             {0, 0, 1},
  SHOW_MAILBOX_LOOT =       {0, 0, 1},
  SHOW_TRADE_LOOT =         {0, 0, 1},
}

function addonData.print(...)
  if not ... then
    return
  end
  local output = ""
  for i, part in ipairs({...}) do
    output = output .. tostring(part) .. " "
  end
  if output:len() > 1 then
    addonData:GetChatFrame():AddMessage(output:sub(1, -1), 1, 1, 0)
  end
end

function addonData:GetDefaultOpts()
  local temp = {}
  for opt, data in pairs(defaults) do
    if type(data) == "table" then
      if opt == "HIDE_EVENTS" then
        table_insert(temp, {opt = opt, val = {}})
      else
        table_insert(temp, {opt = opt, val = data[1], min = data[2], max = data[3]})
      end
    else
      table_insert(temp, {opt = opt, val = data})
    end
  end
  return temp
end

function addonData:GetOpt(key, isDefault)
  local data = defaults[key]
  local val, min, max
  if type(data) == "table" then
    val, min, max = data[1], data[2], data[3]
    if not isDefault then
      val = tonumber(MiniLootDB[key]) or val
      if not MiniLootDB[key] then
        MiniLootDB[key] = val
      end
      if min and max and (val < min or val > max) then
        val = data[1]
        MiniLootDB[key] = val
      end
    end
  else
    val = data
    if not isDefault then
      val = MiniLootDB[key] or val
    end
    if not MiniLootDB[key] then
      MiniLootDB[key] = val
    end
  end
  if key == "HIDE_EVENTS" then
    val = MiniLootDB[key] or data, nil
  elseif type(data) == "table" and type(val) ~= "number" then
    val = data[1]
  end
  return val, min, max
end

function addonData:GetBoolOpt(key)
  local val = addonData:GetOpt(key)
  val = type(val) == "number" and val or tonumber(val)
  if not val or val == 0 then return false end
  return true
end

function addonData:SetOpt(key, val)
  MiniLootDB[key] = val
  local data = defaults[key]
  if type(data) == "table" then
    local min, max = data[2], data[3]
    if min and max and (type(val) ~= "number" or val < min or val > max) then
      val = tonumber(val)
      if val then
        MiniLootDB[key] = val
      else
        val = data[1]
      end
    end
  end
  if key == "CHAT_FRAME" then
    local frame = _G[val]
    if type(frame) ~= "table" or type(frame.AddMessage) ~= "function" then
      val = DEFAULT_CHAT_FRAME:GetName()
      MiniLootDB[key] = val
    end
  end
end

function addonData:GetChatFrame()
  return _G[addonData:GetOpt("CHAT_FRAME") or "DEFAULT_CHAT_FRAME"] or DEFAULT_CHAT_FRAME
end

function addonData:GetFontSize()
  local size, _ = addonData:GetOpt("FONT_SIZE")
  if size <= 0 then
    _, size = FCF_GetChatWindowInfo(addonData:GetChatFrame():GetID())
    size = (size or 13) - 1
  end
  return size
end

function addonData:GetIconWithLink(raw, isCurrency)
  if type(raw) ~= "string" then
    return ""
  end
  local petColor, petSpeciesID, petData, petName = raw:match("|cff(.-)|Hbattlepet:(%d-):(.-)|h%[(.-)%]|h|r")
  if petColor then
    local petName, petIcon = C_PetJournal_GetPetInfoBySpeciesID(petSpeciesID)
    return format("|cff%s|Hbattlepet:%d:%s|h[|T%s:%d|t]|h|r", petColor, petSpeciesID, petData, petIcon or "Interface\\Icons\\INV_Box_PetCarrier_01", addonData:GetFontSize())
  elseif isCurrency then
    raw = raw:match("|h%[(.+)%]|h")
    local currency = addonData:GetCurrencyByName(raw)
    if type(currency) == "table" then
      return format("|cff00AA00|Hcurrency:%d|h[|T%s:%d|t]|h|r", currency[1], currency[2], addonData:GetFontSize())
    end
  else
    local color, itemString, name = raw:match("|cff(.+)|Hitem:(.+)|h%[(.+)%]|h|r")
    if color then
      local _, _, _, _, _, class, subClass = GetItemInfo(raw)
      if addonData:ItemClassQuest(class) or addonData:ItemClassQuest(subClass) then
        if addonData:ItemStartsQuest(raw) then
          color = "FF3333"
        else
          color = "E6CC80"
        end
      elseif addonData:ItemStartsQuest(raw, 1) then
        color = "E6CC80"
      end
      return format("|cff%s|Hitem:%s|h[|T%s:%d|t]|h|r", color, itemString, GetItemIcon(raw), addonData:GetFontSize())
    end
  end
  return raw
end

function addonData:GetItemCount(count, ...)
  local total = GetItemCount(...)
  if count == total then
    return ""
  end
  return total > 1 and format("|cff999999(%d)|r", total) or ""
end

function addonData:PlayerName(name)
  if GetLocale() == "ruRU" then
    if name and name:match(" ") and not name:match("%+") then
      name = nil
    end
  end
  if name then
    if name:match("%+") then
      local new = name:gsub("%+.+$", ""):trim()
      return new ~= "" and new or name, 1
    end
  end
  return name
end

function addonData:ClassColor(name, forceColor)
  if not forceColor and not addonData:GetBoolOpt("SHOW_CLASS_COLORS") then
    name = nil
  end
  local _, class
  if type(name) == "string" then
    _, class = UnitClass(name)
  end
  local color = class and (type(CUSTOM_RAID_CLASS_COLORS) == "table" and CUSTOM_RAID_CLASS_COLORS or RAID_CLASS_COLORS)[class]
  return type(color) == "table" and format("%02x%02x%02x", color.r*255, color.g*255, color.b*255) or "FFFF00"
end

function addonData:CacheItemQualities()
  if not addon.itemQualities then
    addon.itemQualities = {}
  else
    table_wipe(addon.itemQualities)
  end
  for i = 0, 7 do
    local r, g, b, hex = GetItemQualityColor(i)
    hex = hex:sub(3)
    addon.itemQualities[i] = {r, g, b, hex, _G["ITEM_QUALITY"..i.."_DESC"]}
  end
  addon.itemQualities[8] = {1, .2, 0, "FF3300", L.INT_LOOT_HIDE_ALL}
end

function addonData:GetQualityInfo(raw)
  if not addon.itemQualities then
    addonData:CacheItemQualities()
  end
  for i = #addon.itemQualities, 0, -1 do
    local r, g, b, hex, name = unpack(addon.itemQualities[i])
    if i == raw or (type(raw) == "string" and raw:match(hex)) or (type(raw) == "string" and name:find(raw, nil, 1)) or (type(raw) == "string" and raw:match(hex)) then
      return i, r, g, b, hex, name
    end
  end
  return 0, unpack(addon.itemQualities[0])
end

function addonData:ItemStartsQuest(raw, questInGeneral)
  local itemId = tonumber(raw) or tonumber(raw:match("item:(%d+)"))
  if itemId then
    tipScanner:SetOwner(UIParent, "ANCHOR_NONE")
    tipScanner:SetHyperlink("item:"..itemId)
    local tipLine = tipScanner:GetName() .. "TextLeft"
    local line
    for i = 1, tipScanner:NumLines() do
      if _G[tipLine..i]:GetText():match(ITEM_STARTS_QUEST) then
        tipScanner:Hide()
        return 1
      elseif questInGeneral and _G[tipLine..i]:GetText():match(ITEM_BIND_QUEST) then
        tipScanner:Hide()
        return 1
      end
    end
    tipScanner:Hide()
  end
end

function addonData:ItemIsUnique(link)
  tipScanner:SetOwner(UIParent, "ANCHOR_NONE")
  tipScanner:SetHyperlink(link)
  local tipLine = tipScanner:GetName() .. "TextLeft"
  local line
  for i = 1, tipScanner:NumLines() do
    if _G[tipLine..i]:GetText() == ITEM_UNIQUE then
      tipScanner:Hide()
      return 1
    end
  end
  tipScanner:Hide()
end

function addonData:ItemClassQuest(class)
  return class == select(10, GetAuctionItemClasses())
end

function addonData:MoneyToCopper(raw)
  if type(raw) ~= "string" then
    return 0
  end
  raw = raw:lower()
  local copper = 0
  local gp = addonData:FormatMatcher(GOLD_AMOUNT, "(%%d+)"):lower()
  local sp = addonData:FormatMatcher(SILVER_AMOUNT, "(%%d+)"):lower()
  local cp = addonData:FormatMatcher(COPPER_AMOUNT, "(%%d+)"):lower()
  local g, s, c = raw:match(gp), raw:match(sp), raw:match(cp)
  g, s, c = tonumber(g), tonumber(s), tonumber(c)
  if g then
    copper = copper + g * 10000
  end
  if s then
    copper = copper + s * 100
  end
  if c then
    copper = copper + c
  end
  return copper
end

function addonData:CacheCurrency()
  if not addon.currencyCache then
    addon.currencyCache = {}
  else
    table_wipe(addon.currencyCache)
  end
  for i = 1, GetCurrencyListSize() do
    local name, header, _, _, _, _, icon = GetCurrencyListInfo(i)
    if name and not header and icon then
      addon.currencyCache[name] = {tonumber((GetCurrencyListLink(i) or ""):match(":(%d+)")) or i, icon}
    end
  end
end

function addonData:CacheArchCurrency()
  if not addon.archCurrencyCache then
    addon.archCurrencyCache = {}
  else
    table_wipe(addon.archCurrencyCache)
  end
  for _, i in ipairs({384, 385, 393, 394, 397, 398, 399, 400, 401, 676, 677, 754}) do -- CurrencyTypes.dbc
    local name, _, icon = GetCurrencyInfo(i)
    if name and icon then
      addon.archCurrencyCache[name] = {tonumber((GetCurrencyListLink(i) or ""):match(":(%d+)")) or i, icon}
    end
  end
end

function addonData:GetCurrencyByName(name)
  if not addon.currencyCache then
    addonData:CacheCurrency()
  end
  if not addon.archCurrencyCache then
    addonData:CacheArchCurrency()
  end
  return addon.currencyCache[name] or addon.archCurrencyCache[name]
end

function addonData:GetCurrencyCount(count, currencyLink)
  currencyLink = tostring(currencyLink):match("|h%[(.+)%]|h") or currencyLink
  local total = 0
  if currencyLink then
    local currencyId, _ = addonData:GetCurrencyByName(currencyLink)
    if currencyId then
      _, total = GetCurrencyInfo(currencyId[1])
      if count == total then
        return ""
      end
    end
  end
  return total > 1 and format("|cff999999(%d)|r", total) or ""
end

function addonData:NewModule(name, optKey)
  local module = CreateFrame("Frame", name, addon)
  module.name = name
  module.optKey = optKey
  module:SetScript("OnEvent", function(module, event, ...)
    if type(module[event]) == "function" then
      module[event](module, event, ...)
    else
      _G.print("FATAL ERROR: MiniLoot module \"" .. module.name .. "\" triggered on \"" .. event .. "\" but has no handler. Please report this, and any other error messages that may have appeared, to the developers - thank you!") -- DEBUG: until this error is fixed, this helps users report more helpful comments!
    end
  end)
  table_insert(addon.modules, module)
  return module
end

function addonData:FormatMatcher(pattern, catcher)
  pattern = tostring(pattern)
  -- escape the reserved characters
  pattern = pattern:gsub("[%+%-%*%?%[%]%(%)%.%%]", "%%%1")
  -- escape what is left of patterns (account for extra %% from above replacement)
  pattern = pattern:gsub("%%%%(%d?)%%%.(%d?)%S", "\1") -- %3.4f
  pattern = pattern:gsub("%%%%(%d?)%%%.($?)%S", "\1") -- %2.f
  pattern = pattern:gsub("%%%%%.(%d?)($?)%S", "\1") -- %.1f
  pattern = pattern:gsub("%%%%(%d?)($?)%S", "\1") -- %s %d %5$f e.g.
  -- escape back to matcher pattern
  pattern = pattern:gsub("\1", catcher or "(.-)") -- TODO: issues when item contains "x" in the name and we match for "[link]x5" strings :(
  return pattern
end

function addonData:ReplacePatternAtIndex(pattern, find, index, replacement)
  local count = 0
  return pattern:gsub(addonData:FormatMatcher(find), function(match)
    count = count + 1
    if count == index then
      return replacement
    end
  end)
end

function addonData:PatternFlags(pattern, find, flags)
  pattern, find, flags = tostring(pattern), find or "(.-)", type(flags) == "table" and flags or {}
  local skip, replaced = 0
  for i, flag in ipairs(flags) do
    local replace
    if flag == "number" then
      replace = "(%d+)"
    elseif flag == "float" then
      replace = "(%d+%.%d+)"
    elseif flag == "team" then
      replace = "(%S+)"
    elseif flag == "csw" then
      replace = "%s-(%S-)"
    end
    if replace then
      pattern, replaced = addonData:ReplacePatternAtIndex(pattern, find, i - skip, replace)
      if replaced then
        skip = skip + 1
      end
    end
  end
  return pattern
end

function addonData:InLFR(expect, fallback)
  if GetLFGMode(LE_LFG_CATEGORY_LFR) then
    return expect
  end
  if type(fallback) ~= "nil" then
    return fallback and true or false
  end
  return true
end

function addonData:Abbreviate(name)
  name = tostring(name)
  local words = {(" "):split(name)}
  if words[2] then
    local temp = ""
    for _, word in ipairs(words) do
      temp = temp .. addonData:UpperCaseFirst(addonData:GetNumLetters(word, 3))
    end
    if (select(2, string_gsub(temp, "[^\128-\193]", "")) or temp:len()) > 12 then
      temp = ""
      for _, word in ipairs(words) do
        temp = temp .. addonData:UpperCaseFirst(addonData:GetNumLetters(word, 2))
      end
    end
    return temp
  else
    name = addonData:GetNumLetters(name, 10) -- Tonyleila will hate me for this, but it must be shorter than 10 characters!
  end
  return name
end

function addonData:GetNumLetters(raw, numLetters)
  numLetters = tonumber(numLetters) or 1
  local matchLetter = "([%z\1-\127\194-\244][\128-\191]*)"
  local matcher = ""
  for i = 1, (numLetters < 1 and 1 or numLetters) do
    matcher = matcher .. matchLetter
  end
  local matched = table_concat({raw:match(matcher)})
  if matched ~= "" then
    return matched
  elseif numLetters > 1 then
    return addonData:GetNumLetters(raw, numLetters - 1)
  end
  return ""
end

function addonData:UpperCaseFirst(raw)
  return tostring(raw):gsub("([%z\1-\127\194-\244][\128-\191]*)(.+)", function(a, b) return a:upper() .. b:lower() end)
end
