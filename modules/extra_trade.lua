local format = format
local GetDenominationsFromCopper = GetDenominationsFromCopper
local GetTargetTradeMoney = GetTargetTradeMoney
local GetTradeTargetItemInfo = GetTradeTargetItemInfo
local GetTradeTargetItemLink = GetTradeTargetItemLink
local LOOT_ITEM_PUSHED_SELF_MULTIPLE = LOOT_ITEM_PUSHED_SELF_MULTIPLE
local MAX_TRADE_ITEMS = MAX_TRADE_ITEMS
local select = select
local YOU_LOOT_MONEY = YOU_LOOT_MONEY

local addonName, addonData = ...
local L, print, module = addonData.L, addonData.print, addonData:NewModule("EXTRA_TRADE", "SHOW_TRADE_LOOT")
local loot

function module:OnLoad()
  loot = addonData:GetModule("LOOT")
  module:RegisterEvent("TRADE_SHOW")
end

function module:TRADE_SHOW()
  module.TradeAccepted = nil
  if not module.IsEnabled then
    return
  end
  module:RegisterEvent("TRADE_ACCEPT_UPDATE")
  module:RegisterEvent("TRADE_REQUEST_CANCEL")
  module:RegisterEvent("TRADE_CLOSED")
end

function module:TRADE_ACCEPT_UPDATE(_, accept1, accept2)
  module.TradeAccepted = (accept1 == 1 or accept2 == 1) and 1 or nil -- both will be accepted simulatenously (because both flags can never be set to 1 at once)
end

function module:TRADE_REQUEST_CANCEL()
  module.TradeAccepted = nil
end

function module:TRADE_CLOSED()
  if module.TradeAccepted then
    local copper = GetTargetTradeMoney() or 0
    if copper > 0 then
      loot:CHAT_MSG_MONEY("CHAT_MSG_MONEY", format(YOU_LOOT_MONEY, GetDenominationsFromCopper(copper)))
    end
		-- natively supported by the game - but just in case it breaks in the future I shall keep this legacy code commented
    --for i = 1, MAX_TRADE_ITEMS - 1 do -- skip "won't be traded" slot
    --  local link, count = GetTradeTargetItemLink(i), select(3, GetTradeTargetItemInfo(i))
    --  if link then
    --    loot:CHAT_MSG_LOOT("CHAT_MSG_LOOT", format(LOOT_ITEM_PUSHED_SELF_MULTIPLE, link, count or 1))
    --  end
    --end
  end
  module.TradeAccepted = nil
  module:UnregisterEvent("TRADE_ACCEPT_UPDATE")
  module:UnregisterEvent("TRADE_REQUEST_CANCEL")
  module:UnregisterEvent("TRADE_CLOSED")
end

function module:Enable()
  module.IsEnabled = 1
end

function module:Disable()
  module.IsEnabled = nil
end
