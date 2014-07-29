local format = format
local GetDenominationsFromCopper = GetDenominationsFromCopper
local GetInboxHeaderInfo = GetInboxHeaderInfo
local GetInboxItem = GetInboxItem
local GetInboxItemLink = GetInboxItemLink
local hooksecurefunc = hooksecurefunc
local IsAddOnLoaded = IsAddOnLoaded
local LOOT_ITEM_PUSHED_SELF_MULTIPLE = LOOT_ITEM_PUSHED_SELF_MULTIPLE
local select = select
local YOU_LOOT_MONEY = YOU_LOOT_MONEY

local addonName, addonData = ...
local L, print, module = addonData.L, addonData.print, addonData:NewModule("EXTRA_MAILBOX", "SHOW_MAILBOX_LOOT")

function module:OnLoad()
  local loot = addonData:GetModule("LOOT")

  local function CanLootUnique(link)
    if addonData:ItemIsUnique(link) and GetItemCount(link, true, false) > 0 then
      return -- item is unique and we already got one in our bags/bank
    end
    return 1
  end

  function module.AutoLootMailItem(mailId)
    if not module.IsEnabled or not module.IsHooked then
      return
    end
    local copper, _, _, items = select(5, GetInboxHeaderInfo(mailId))
    module.TakeInboxMoney(mailId)
    --for attachId = 1, items or 0 do
    --  module.TakeInboxItem(mailId, attachId)
    --end
  end

  --function module.TakeInboxItem(mailId, attachId)
  --  if not module.IsEnabled or not module.IsHooked then
  --    return
  --  end
  --  local link, count = GetInboxItemLink(mailId, attachId), select(3, GetInboxItem(mailId, attachId))
  --  if link and count and CanLootUnique(link) then
  --    count = count < 1 and 1 or count
  --    loot:CHAT_MSG_LOOT("CHAT_MSG_LOOT", format(LOOT_ITEM_PUSHED_SELF_MULTIPLE, link, count or 1))
  --  end
  --end

  function module.TakeInboxMoney(mailId)
    if not module.IsEnabled or not module.IsHooked then
      return
    end
    local copper = select(5, GetInboxHeaderInfo(mailId))
    if not IsAddOnLoaded("EasyMail") and copper and copper > 0 then -- avoid EasyMail until it breaks completely (considering it's outdated :P)
      loot:CHAT_MSG_MONEY("CHAT_MSG_MONEY", format(YOU_LOOT_MONEY, GetDenominationsFromCopper(copper)))
    end
  end

  module:RegisterEvent("MAIL_SHOW")
  module:RegisterEvent("MAIL_CLOSED")

  hooksecurefunc("AutoLootMailItem", module.AutoLootMailItem)
  --hooksecurefunc("TakeInboxItem", module.TakeInboxItem)
  hooksecurefunc("TakeInboxMoney", module.TakeInboxMoney)
end

function module:MAIL_SHOW()
  if addonData:GetBoolOpt("SHOW_MAILBOX_LOOT") then
    module.IsHooked = 1
  end
end

function module:MAIL_CLOSED()
  module.IsHooked = nil
end

function module:Enable()
  module.IsEnabled = 1
end

function module:Disable()
  module.IsEnabled = nil
end
