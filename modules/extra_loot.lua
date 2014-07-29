local _G = _G
local ChatFrame_AddMessageGroup = ChatFrame_AddMessageGroup
local ChatFrame_RemoveAllChannels = ChatFrame_RemoveAllChannels
local ChatFrame_RemoveAllMessageGroups = ChatFrame_RemoveAllMessageGroups
local FCF_Close = FCF_Close
local FCF_GetChatWindowInfo = FCF_GetChatWindowInfo
local FCF_OpenNewWindow = FCF_OpenNewWindow
local format = format
local NO = NO
local NUM_CHAT_WINDOWS = NUM_CHAT_WINDOWS
local pairs = pairs
local StaticPopup_Show = StaticPopup_Show
local StaticPopupDialogs = StaticPopupDialogs
local YES = YES

local addonName, addonData = ...
local L, print, module = addonData.L, addonData.print, addonData:NewModule("EXTRA_LOOT")

function module:OnLoad()
  local lootEvents = {
    "COMBAT_FACTION_CHANGE",
    "COMBAT_GUILD_XP_GAIN",
    "COMBAT_HONOR_GAIN",
    "COMBAT_MISC_INFO",
    "COMBAT_XP_GAIN",
    "CURRENCY",
    "LOOT",
    "MONEY",
    --"OPENING",
    --"PET_INFO",
    --"SKILL",
    --"TRADESKILLS",
  }

  StaticPopupDialogs["MINILOOT_LOOT_WINDOW_OVERWRITE"] = {
    preferredIndex = STATICPOPUP_NUMDIALOGS,
    text = format(L.POPUP_CHAT_FRAME_OVERWRITE, "<INSERT TAB NAME HERE>"),
    button1 = YES,
    button2 = NO,
    OnAccept = function(self)
      addonData:LootWindowCreate(self.data, 1)
    end,
    exclusive = 1,
    whileDead = 1,
    hideOnEscape = 1,
    showAlert = 1,
    timeout = 0,
  }

  function addonData:LootWindowExists(name)
    for i = 1, NUM_CHAT_WINDOWS do
      local frame = _G["ChatFrame"..i]
      local tab = _G["ChatFrame"..i.."Tab"]
      if frame and tab and (tab:IsVisible() or frame.minimized) and FCF_GetChatWindowInfo(i) == name then
        return frame
      end
    end
  end

  function addonData:LootWindowRemove(name)
    for i = 1, NUM_CHAT_WINDOWS do
      if FCF_GetChatWindowInfo(i) == name then
        FCF_Close(_G["ChatFrame"..i])
      end
    end
  end

  function addonData:LootWindowCreate(name, confirmed)
    local window = addonData:LootWindowExists(name)
    if window and not confirmed then
      local popup = StaticPopup_Show("MINILOOT_LOOT_WINDOW_OVERWRITE", nil, nil, name)
      local text = _G[popup:GetName() .. "Text"]
      text:SetText(format(L.POPUP_CHAT_FRAME_OVERWRITE, name))
    else
      addonData:LootWindowRemove(name)
      FCF_OpenNewWindow(name)
      window = addonData:LootWindowExists(name)
      ChatFrame_RemoveAllMessageGroups(window)
      ChatFrame_RemoveAllChannels(window)
      for _, event in pairs(lootEvents) do
        ChatFrame_AddMessageGroup(window, event)
      end
    end
  end
end

function module:Enable()
end

function module:Disable()
end
