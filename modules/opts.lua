local _G = _G
local COMBAT_XP_GAIN = COMBAT_XP_GAIN
local CreateFrame = CreateFrame
local CURRENCY = CURRENCY
local ERR_GUILD_PLAYER_NOT_IN_GUILD = ERR_GUILD_PLAYER_NOT_IN_GUILD
local format = format
local GUILD_EXPERIENCE = GUILD_EXPERIENCE
local HONOR = HONOR
local InterfaceOptions_AddCategory = InterfaceOptions_AddCategory
local InterfaceOptionsFramePanelContainer = InterfaceOptionsFramePanelContainer
local ipairs = ipairs
local IsInGuild = IsInGuild
local LOOT = LOOT
local MONEY = MONEY
local PROFESSIONS_ARCHAEOLOGY = PROFESSIONS_ARCHAEOLOGY
local REPUTATION = REPUTATION
local STANDARD_TEXT_FONT = STANDARD_TEXT_FONT
local table_insert = table.insert
local tonumber = tonumber
local tostring = tostring
local type = type
local UnitName = UnitName
local UNKNOWN = UNKNOWN

local addonName, addonData = ...
local L, print, module = addonData.L, addonData.print, addonData:NewModule("OPTS")
local AceGUI, tip

local function ShowHelpTooltip(self, text)
  tip:SetOwner(self, "ANCHOR_TOPLEFT")
  tip:AddLine(tostring(text):trim(), 1, 1, 1, true)
  tip:Show()
end

local function CreateNewPanel(title, desc, parent, name, default)
  local panel = CreateFrame("Frame", nil, InterfaceOptionsFramePanelContainer)
  panel:Hide()

  local t, d
  if title then
    t = panel:CreateFontString()
    t:SetFont(STANDARD_TEXT_FONT, 16, "")
    t:SetTextColor(1, .82, 0, 1)
    t:SetShadowColor(0, 0, 0, 1)
    t:SetShadowOffset(1, -1)
    t:SetJustifyH("LEFT")
    t:SetJustifyV("TOP")
    t:SetPoint("TOPLEFT", 16, -16)
    t:SetHeight(16)
    t:SetText(title)

    if desc then
      d = panel:CreateFontString()
      d:SetFont(STANDARD_TEXT_FONT, 10, "")
      d:SetTextColor(1, 1, 1, 1)
      d:SetShadowColor(0, 0, 0, 1)
      d:SetShadowOffset(1, -1)
      d:SetJustifyH("LEFT")
      d:SetJustifyV("TOP")
      d:SetPoint("TOPLEFT", t, 0, t:GetText() and -24 or -16)
      d:SetHeight(32)
      d:SetText(desc)
    end
  end

  panel.parent = parent
  panel.name = name or title or UNKNOWN
  panel.title = t
  panel.desc = d
  panel.default = default
  InterfaceOptions_AddCategory(panel)
  return panel
end

local function CreatePanelOption(container, meta)
  local group = AceGUI:Create("SimpleGroup")
  group:SetFullWidth(true)
  group:SetLayout("Flow")

  if meta.title and meta.desc then
    local title = AceGUI:Create("Label")
    title:SetFullWidth(true)
    title:SetFont(STANDARD_TEXT_FONT, 16, "")
    title:SetColor(1, .82, 0, 1)
    title:SetText(meta.title)
    title.frame.obj.label:SetShadowColor(0, 0, 0, 1)
    title.frame.obj.label:SetShadowOffset(1, -1)
    title.frame.obj.label:SetJustifyH("LEFT")
    title.frame.obj.label:SetJustifyV("CENTER")
    title.frame.obj.label:SetHeight(32)

    local desc = AceGUI:Create("Label")
    desc:SetFullWidth(true)
    desc:SetFont(STANDARD_TEXT_FONT, 10, "")
    desc:SetColor(1, 1, 1, 1)
    desc:SetText(meta.desc)
    desc.frame.obj.label:SetShadowColor(0, 0, 0, 1)
    desc.frame.obj.label:SetShadowOffset(1, -1)
    desc.frame.obj.label:SetJustifyH("LEFT")
    desc.frame.obj.label:SetJustifyV("TOP")
    desc.frame.obj.label:SetHeight(20)

    group:SetLayout("List")

    if not meta.noHR then
      local hr = AceGUI:Create("Heading")
      hr:SetText("")
      group:AddChild(hr)
    end

    group:AddChild(title)
    group:AddChild(desc)

  else
    local icon = AceGUI:Create("Icon")
    icon.frame:SetMotionScriptsWhileDisabled(true)
    icon.frame:SetEnabled(false)
    icon:SetWidth(meta.iconWidth or 18)
    icon:SetImage(meta.icon or "Interface\\HelpFrame\\HelpIcon-KnowledgeBase") -- "Interface\\OptionsFrame\\UI-OptionsFrame-NewFeatureIcon"
    icon:SetImageSize(meta.iconSize or 16, meta.iconSize or 16)
    if meta.helpText then
      icon:SetCallback("OnEnter", function(self) ShowHelpTooltip(self.frame, meta.helpText) end)
      icon:SetCallback("OnLeave", function() tip:Hide() end)
    end

    local label = AceGUI:Create("InteractiveLabel")
    label:SetWidth(250)
    label:SetFont(STANDARD_TEXT_FONT, 12, "")
    label:SetText(meta.label)

    local option = meta.createOption(meta, icon, label)

    group:AddChild(label)
    group:AddChild(option)
    if meta.helpText then
      group:AddChild(icon)
    end

    local line = group.frame:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("BOTTOMLEFT", 0, -4)
    line:SetPoint("BOTTOMRIGHT", 0, -4)
    line:SetTexture(1, 1, 1, .2)
    group.frame.underline = line
  end

  container:AddChild(group)
end

local function CreatePanelCheckbox(container, optKey, checkLabel, checkHelpText)
  CreatePanelOption(container, {
    label = checkLabel,

    createOption = function(meta, icon, label)
      local option = AceGUI:Create("CheckBox")
      option:SetHeight(18)
      option:SetWidth(18)
      option.helpText = checkHelpText

      option:SetCallback("OnEnter", function(option)
        ShowHelpTooltip(option.frame, option.helpText)
      end)

      option:SetCallback("OnLeave", function() tip:Hide() end)

      option:SetCallback("OnValueChanged", function(option)
        addonData:SetOpt(optKey, option:GetValue() and 1 or 0)
        addonData:CheckModuleStates(optKey, 1)
      end)

      option.frame:HookScript("OnShow", function()
        option:SetValue(addonData:GetBoolOpt(optKey) and true or false)
      end)

      return option
    end,
  })
end

function module:OnLoad()
  AceGUI = LibStub("AceGUI-3.0")
  tip = CreateFrame("GameTooltip", "MiniLootOptionsTooltip", UIParent, "GameTooltipTemplate")
  _G[tip:GetName().."TextLeft1"]:SetFontObject("GameTooltipText")
  _G[tip:GetName().."TextRight1"]:SetFontObject("GameTooltipText")

  local panel = CreateNewPanel(nil, nil, nil, "MiniLoot", function()
    table.wipe(MiniLootDB)
    addonData:CheckModuleStates()
    InterfaceOptionsFrame_OpenToCategory("MiniLoot")
  end)

  local scroll = AceGUI:Create("ScrollFrame")
  scroll:SetLayout("List")

  local group = AceGUI:Create("SimpleGroup")
  group:SetFullWidth(true)
  group:SetFullHeight(true)
  group:SetLayout("Fill")
  if panel.desc or panel.title then
    group:SetPoint("TOPLEFT", panel.desc or panel.title, "TOPLEFT", 0, -16)
  else
    group:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -16)
  end
  group:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -16, 16)
  group:AddChild(scroll)

  panel:HookScript("OnShow", function() group.frame:Show() end)
  panel:HookScript("OnHide", function() group.frame:Hide() end)

  CreatePanelOption(scroll, {title = L.INT_MINILOOT_LABEL, desc = L.INT_MINILOOT_DESC, noHR = 1})

  CreatePanelOption(scroll, {
    label = L.INT_MINILOOT_FONTSIZE_LABEL,
    helpText = L.INT_MINILOOT_FONTSIZE_TOOLTIP,

    createOption = function(meta, icon, label)
      local values, selected = {}, 1

      for i = 0, 32 do
        if i == 0 or i >= 6 then
          if i == 0 or i < 16 or (i >= 16 and i % 2 == 0) then
            if i == addonData:GetFontSize() then
              selected = #values + 1
            end
            table_insert(values, i)
          end
        end
      end

      local option = AceGUI:Create("Dropdown")
      option:SetWidth(128)
      option:SetList(values)
      option:SetValue(selected)

      option:SetCallback("OnValueChanged", function(option, _, value)
        addonData:SetOpt("FONT_SIZE", values[value])
        for i, sizeValue in ipairs(values) do
          if sizeValue == addonData:GetFontSize() then
            option:SetValue(i)
            break
          end
        end
        print(format("|cff%s%s|r: %sx1337 (%s)", addonData:ClassColor(UnitName("player")), UnitName("player"), addonData:GetIconWithLink("|cffffffff|Hitem:6948:0:0:0:0:0:0:0:0|h[Hearthstone]|h|r"), L.INT_MINILOOT_FONTSIZE_DEMO))
      end)

      option.frame:HookScript("OnShow", function()
        for i, sizeValue in ipairs(values) do
          if sizeValue == addonData:GetFontSize() then
            option:SetValue(i)
            break
          end
        end
      end)

      return option
    end,
  })

  CreatePanelOption(scroll, {
    label = L.INT_MINILOOT_OUTPUT_LABEL,
    helpText = L.INT_MINILOOT_OUTPUT_TOOLTIP,

    createOption = function(meta, icon, label)
      local option = AceGUI:Create("EditBox")
      option:SetWidth(128)
      option:SetText(addonData:GetChatFrame():GetName())
      option:SetMaxLetters(64)

      option:SetCallback("OnTextChanged", function(option, _, value)
        if addonData:GetChatFrame():GetName() == value then
          option.frame.obj.editbox:SetTextColor(1, 1, 1)
        else
          option.frame.obj.editbox:SetTextColor(1, 0, 0)
        end
      end)

      option:SetCallback("OnEnterPressed", function(option, _, value)
        option.frame.obj.editbox:ClearFocus()
        option.frame.obj.editbox:SetTextColor(1, 1, 1)
        local expected, results = value
        addonData:SetOpt("CHAT_FRAME", value)
        results = addonData:GetChatFrame():GetName()
        option:SetText(results)
        print(format(L.INT_MINILOOT_OUTPUT_DEMO, expected))
      end)

      option.frame:HookScript("OnShow", function()
        option:SetText(addonData:GetChatFrame():GetName())
      end)

      return option
    end,
  })

  CreatePanelOption(scroll, {
    title = L.INT_FILTER_LABEL,
    desc = L.INT_FILTER_DESC,
  })

  CreatePanelOption(scroll, {
    label = L.INT_FILTER_HIDE_EVENTS_LABEL,

    createOption = function(meta, icon, label)
      local options = AceGUI:Create("SimpleGroup")
      options:SetLayout("Flow")

      local hideEvents = {
        {"CHAT_MSG_CURRENCY", format("%s + %s", CURRENCY, PROFESSIONS_ARCHAEOLOGY)}, -- Currency + Archaeology
        {"CHAT_MSG_COMBAT_XP_GAIN", COMBAT_XP_GAIN}, -- Experience
        {"CHAT_MSG_COMBAT_GUILD_XP_GAIN", GUILD_EXPERIENCE}, -- Guild Experience
        {"CHAT_MSG_COMBAT_HONOR_GAIN", HONOR}, -- Honor
        {"CHAT_MSG_LOOT", LOOT}, -- Loot
        {"CHAT_MSG_MONEY", MONEY}, -- Money
        {"CHAT_MSG_COMBAT_FACTION_CHANGE", REPUTATION}, -- Reputation
      }

      for i, data in ipairs(hideEvents) do
        local event, helpText = data[1], data[2]

        local option = AceGUI:Create("CheckBox")
        option:SetValue(addonData:HasEventFilter(event))
        option:SetHeight(18)
        option:SetWidth(18)
        option.event = event
        option.helpText = helpText

        option:SetCallback("OnEnter", function(option)
          if option.event == "CHAT_MSG_COMBAT_GUILD_XP_GAIN" then
            if IsInGuild() then
              option.helpText2 = nil
            else
              option.helpText2 = option.helpText .. "\n|cffFF9999" .. ERR_GUILD_PLAYER_NOT_IN_GUILD .. "|r"
            end
          end
          ShowHelpTooltip(option.frame, option.helpText2 or option.helpText)
        end)

        option:SetCallback("OnLeave", function() tip:Hide() end)

        option:SetCallback("OnValueChanged", function(option)
          if option:GetValue() then
            addonData:AddEventFilter(option.event)
          else
            addonData:RemoveEventFilter(option.event)
          end
        end)

        option.frame:HookScript("OnShow", function()
          option:SetValue(addonData:HasEventFilter(option.event))
        end)

        options:AddChild(option)
      end

      return options
    end,
  })

  CreatePanelCheckbox(scroll, "HIDE_JUNK", L.INT_FILTER_HIDE_JUNK_LABEL, L.INT_FILTER_HIDE_JUNK_TOOLTIP)

  CreatePanelOption(scroll, {
    label = L.INT_FILTER_HIDE_SELF_LABEL,

    createOption = function(meta, icon, label)
      local options = AceGUI:Create("SimpleGroup")
      options:SetLayout("List")
      options.options = {}

      local function UpdateSelections(self, _, checked)
        local selected

        if type(checked) == "boolean" then
          if checked then
            selected = self.index
            addonData:SetOpt("HIDE_SOLO_LOOT", 1)
            addonData:SetOpt("HIDE_SOLO_LOOT_T", selected)
          else
            addonData:SetOpt("HIDE_SOLO_LOOT", 0)
            addonData:SetOpt("HIDE_SOLO_LOOT_T", 0)
          end
        else
          selected = addonData:GetOpt("HIDE_SOLO_LOOT_T")
        end

        for i, option in ipairs(options.options) do
          if addonData:GetBoolOpt("HIDE_SOLO_LOOT") then
            option:SetValue(selected == i - 1)
          else
            option:SetValue(false)
          end
        end
      end

      for i = 0, 8 do
        local index, r, g, b, hex, name = addonData:GetQualityInfo(i)

        local option = AceGUI:Create("CheckBox")
        option.index = index
        option:SetHeight(18)
        option:SetLabel(name)
        option.frame.obj.text:SetTextColor(r, g, b)
        option.frame.obj.text.SetTextColor = function() end
        option:SetCallback("OnValueChanged", UpdateSelections)

        table_insert(options.options, option)
        options:AddChild(option)
      end

      options.frame:HookScript("OnShow", function()
        UpdateSelections()
      end)

      return options
    end,
  })

  CreatePanelOption(scroll, {
    label = L.INT_FILTER_HIDE_PARTY_LABEL,

    createOption = function(meta, icon, label)
      local options = AceGUI:Create("SimpleGroup")
      options:SetLayout("List")
      options.options = {}

      local function UpdateSelections(self, _, checked)
        local selected

        if type(checked) == "boolean" then
          if checked then
            selected = self.index
            addonData:SetOpt("HIDE_PARTY_LOOT", 1)
            addonData:SetOpt("HIDE_PARTY_LOOT_T", selected)
          else
            addonData:SetOpt("HIDE_PARTY_LOOT", 0)
            addonData:SetOpt("HIDE_PARTY_LOOT_T", 0)
          end
        else
          selected = addonData:GetOpt("HIDE_PARTY_LOOT_T")
        end

        for i, option in ipairs(options.options) do
          if addonData:GetBoolOpt("HIDE_PARTY_LOOT") then
            option:SetValue(selected == i - 1)
          else
            option:SetValue(false)
          end
        end
      end

      for i = 0, 8 do
        local index, r, g, b, hex, name = addonData:GetQualityInfo(i)

        local option = AceGUI:Create("CheckBox")
        option.index = index
        option:SetHeight(18)
        option:SetLabel(name)
        option.frame.obj.text:SetTextColor(r, g, b)
        option.frame.obj.text.SetTextColor = function() end
        option:SetCallback("OnValueChanged", UpdateSelections)

        table_insert(options.options, option)
        options:AddChild(option)
      end

      options.frame:HookScript("OnShow", function()
        UpdateSelections()
      end)

      return options
    end,
  })

  CreatePanelOption(scroll, {title = L.INT_ROLL_LABEL, desc = L.INT_ROLL_DESC})

  CreatePanelCheckbox(scroll, "SHOW_ROLL_DECISIONS", L.INT_ROLL_DECISIONS_LABEL, L.INT_ROLL_DECISIONS_TOOLTIP)

  CreatePanelCheckbox(scroll, "HIDE_LFR_ROLL_DECISIONS", L.INT_ROLL_DECISIONS_LFR_LABEL, L.INT_ROLL_DECISIONS_LFR_TOOLTIP)

  CreatePanelCheckbox(scroll, "SHOW_ROLL_SUMMARY", L.INT_ROLL_SUMMARY_LABEL, L.INT_ROLL_SUMMARY_TOOLTIP)

  CreatePanelCheckbox(scroll, "HIDE_LFR_ROLL_SUMMARY", L.INT_ROLL_SUMMARY_LFR_LABEL, L.INT_ROLL_SUMMARY_LFR_TOOLTIP)

  CreatePanelCheckbox(scroll, "SHOW_ROLL_ICONS", L.INT_ROLL_ICONS_LABEL, L.INT_ROLL_ICONS_TOOLTIP)

  CreatePanelOption(scroll, {title = L.INT_TIMER_LABEL, desc = L.INT_TIMER_DESC})

  CreatePanelOption(scroll, {
    label = L.INT_TIMER_SLEEP_COMBAT_LABEL,
    helpText = L.INT_TIMER_SLEEP_COMBAT_TOOLTIP,

    createOption = function(meta, icon, label)
      local option = AceGUI:Create("EditBox")
      option:SetWidth(128)
      option:SetText(addonData:GetOpt("SLEEP_AFTER_COMBAT"))
      option:SetMaxLetters(4)

      option:SetCallback("OnTextChanged", function(option, _, value)
        if addonData:GetOpt("SLEEP_AFTER_COMBAT") == tonumber(value) then
          option.frame.obj.editbox:SetTextColor(1, 1, 1)
        else
          option.frame.obj.editbox:SetTextColor(1, 0, 0)
        end
      end)

      option:SetCallback("OnEnterPressed", function(option, _, value)
        option.frame.obj.editbox:ClearFocus()
        option.frame.obj.editbox:SetTextColor(1, 1, 1)
        addonData:SetOpt("SLEEP_AFTER_COMBAT", value)
        option:SetText(addonData:GetOpt("SLEEP_AFTER_COMBAT"))
      end)

      option.frame:HookScript("OnShow", function()
        option:SetText(addonData:GetOpt("SLEEP_AFTER_COMBAT"))
      end)

      return option
    end,
  })

  CreatePanelOption(scroll, {
    label = L.INT_TIMER_SLEEP_EVENTS_LABEL,
    helpText = L.INT_TIMER_SLEEP_EVENTS_TOOLTIP,

    createOption = function(meta, icon, label)
      local option = AceGUI:Create("EditBox")
      option:SetWidth(128)
      option:SetText(addonData:GetOpt("SLEEP_BETWEEN_EVENTS"))
      option:SetMaxLetters(4)

      option:SetCallback("OnTextChanged", function(option, _, value)
        if addonData:GetOpt("SLEEP_BETWEEN_EVENTS") == tonumber(value) then
          option.frame.obj.editbox:SetTextColor(1, 1, 1)
        else
          option.frame.obj.editbox:SetTextColor(1, 0, 0)
        end
      end)

      option:SetCallback("OnEnterPressed", function(option, _, value)
        option.frame.obj.editbox:ClearFocus()
        option.frame.obj.editbox:SetTextColor(1, 1, 1)
        addonData:SetOpt("SLEEP_BETWEEN_EVENTS", value)
        option:SetText(addonData:GetOpt("SLEEP_BETWEEN_EVENTS"))
      end)

      option.frame:HookScript("OnShow", function()
        option:SetText(addonData:GetOpt("SLEEP_BETWEEN_EVENTS"))
      end)

      return option
    end,
  })

	CreatePanelCheckbox(scroll, "SLEEP_DURING_TRADESKILL", L.INT_SLEEP_DURING_TRADESKILL_LABEL, L.INT_SLEEP_DURING_TRADESKILL_TOOLTIP)

  CreatePanelOption(scroll, {title = L.INT_EXTRA_TITLE, desc = L.INT_EXTRA_DESC})

  CreatePanelOption(scroll, {
    label = L.INT_EXTRA_ORIGINAL_LOOT_LABEL,

    createOption = function(meta, icon, label)
      local option = AceGUI:Create("Button")
      option:SetText(L.INT_EXTRA_ORIGINAL_LOOT_BUTTON)
      option.helpText = L.INT_EXTRA_ORIGINAL_LOOT_TOOLTIP

      option:SetCallback("OnEnter", function(option)
        ShowHelpTooltip(option.frame, option.helpText)
      end)

      option:SetCallback("OnLeave", function() tip:Hide() end)

      option:SetCallback("OnClick", function()
        addonData:LootWindowCreate(LOOT)
      end)

      return option
    end,
  })

  CreatePanelCheckbox(scroll, "SHOW_MOUSEOVER_LINKS", L.INT_EXTRA_MOUSEOVER_LINKS_LABEL, L.INT_EXTRA_MOUSEOVER_LINKS_TOOLTIP)

  CreatePanelCheckbox(scroll, "MOUSEOVER_LINKS_ICON", L.INT_EXTRA_MOUSEOVER_ICON_LABEL, L.INT_EXTRA_MOUSEOVER_ICON_TOOLTIP)

  CreatePanelCheckbox(scroll, "MOUSEOVER_LINKS_ANCHOR", L.INT_EXTRA_MOUSEOVER_ANCHOR_LABEL, L.INT_EXTRA_MOUSEOVER_ANCHOR_TOOLTIP)

  CreatePanelCheckbox(scroll, "SHOW_LOOT_COUNT", L.INT_EXTRA_LOOTCOUNT_LABEL, L.INT_EXTRA_LOOTCOUNT_TOOLTIP)

  CreatePanelCheckbox(scroll, "SHOW_CLASS_COLORS", L.INT_EXTRA_CLASSCOLORS_LABEL, L.INT_EXTRA_CLASSCOLORS_TOOLTIP)

  CreatePanelCheckbox(scroll, "PET_BATTLES", L.INT_EXTRA_PETBATTLE_LABEL, L.INT_EXTRA_PETBATTLE_TOOLTIP)

  CreatePanelCheckbox(scroll, "SHOW_MAILBOX_LOOT", L.INT_EXTRA_MAILBOX_LABEL, L.INT_EXTRA_MAILBOX_TOOLTIP)

  CreatePanelCheckbox(scroll, "SHOW_TRADE_LOOT", L.INT_EXTRA_TRADE_LABEL, L.INT_EXTRA_TRADE_TOOLTIP)

  scroll:AddChild(AceGUI:Create("Label")) -- for the sake of a little padding on the bottom
end

function module:Enable()
end

function module:Disable()
end
