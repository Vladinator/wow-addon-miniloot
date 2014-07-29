local _G = _G
local BATTLE_PET_ABILITY_MULTIROUND = BATTLE_PET_ABILITY_MULTIROUND
local BATTLE_PET_CAGE_TOOLTIP_LEVEL = BATTLE_PET_CAGE_TOOLTIP_LEVEL
local BattlePetTooltipTemplate_SetBattlePet = BattlePetTooltipTemplate_SetBattlePet
local C_PetBattles_GetAbilityInfoByID = C_PetBattles.GetAbilityInfoByID
local C_PetJournal_GetPetInfoBySpeciesID = C_PetJournal.GetPetInfoBySpeciesID
local CreateFrame = CreateFrame
local format = format
local GetAchievementInfo = GetAchievementInfo
local GetCurrencyInfo = GetCurrencyInfo
local GetItemCount = GetItemCount
local GetItemInfo = GetItemInfo
local GetItemQualityColor = GetItemQualityColor
local GetMouseFocus = GetMouseFocus
local GetSpellInfo = GetSpellInfo
local ITEM_QUALITY_COLORS = ITEM_QUALITY_COLORS
local MAJOR_GLYPH = MAJOR_GLYPH
local math_random = math.random
local MAX_COOLDOWN = MAX_COOLDOWN
local MINOR_GLYPH = MINOR_GLYPH
local NAME = NAME
local pairs = pairs
local PET_BATTLE_EFFECTIVENESS_VS = PET_BATTLE_EFFECTIVENESS_VS
local PRIME_GLYPH = PRIME_GLYPH
local select = select
local SharedPetBattleAbilityTooltip_SetAbility = SharedPetBattleAbilityTooltip_SetAbility
local string_gsub = string.gsub
local tonumber = tonumber
local TOOLTIP_BATTLE_PET = TOOLTIP_BATTLE_PET
local type = type
local UIParent = UIParent
local unpack = unpack

local addonName, addonData = ...
local L, print, module = addonData.L, addonData.print, addonData:NewModule("EXTRA_TOOLTIP", "SHOW_MOUSEOVER_LINKS")
local tip

function module:OnLoad()
  tip = CreateFrame("GameTooltip", "MiniLootTooltip", UIParent, "GameTooltipTemplate")

  local safeHyperlinks = {
    achievement = {1, 1, 0}, -- yellow
    currency = {0, .67, 0}, -- dark green
    enchant = {1, 1, 0}, -- yellow
    glyph = {.44, .84, 1}, -- light blue
    instancelock = {1, .5, 0}, -- orange
    item = {1, 1, 1}, -- white (dynamic)
    --journal = {.44, .84, 1}, -- light blue
    quest = {1, 1, 0}, -- yellow
    spell = {.44, .84, 1}, -- light blue
    talent = {.31, .59, .97}, -- dark blue
    unit = {.8, .8, .8}, -- gray
    --urlIndex = {1, 1, 1}, -- white
    --lootHistory = {0, .67, 0}, -- dark green
    --battlePetAbil = {.31, .59, .97}, -- ocean blue
    --battlepet = {.91, .87, .67}, -- marsipan colored
  }

  local glyphClassFilenames = {
    "DeathKnight",
    "Druid",
    "Hunter",
    "Mage",
    "Monk",
    "Paladin",
    "Priest",
    "Rogue",
    "Shaman",
    "Warlock",
    "Warrior",
  }

  local PET_BATTLE_FLOATING_ABILITY_TOOLTIP = {
    EnsureTarget = function(self, target) if target == "default" then target = "self" end end,
    GetAbilityID = function(self) return self.abilityID end,
    GetAttackStat = function(self, target) self:EnsureTarget(target) return self.power end,
    GetCooldown = function(self) return 0 end,
    GetHealth = function(self, target) self:EnsureTarget(target) return self.maxHealth end,
    GetMaxHealth = function(self, target) self:EnsureTarget(target) return self.maxHealth end,
    GetRemainingDuration = function(self) return 0 end,
    GetSpeedStat = function(self, target) self:EnsureTarget(target) return self.speed end,
    GetState = function(self, stateID, target) return 0 end,
    IsInBattle = function(self) return false end,
  }

  local BATTLE_PET_FLOATING_TOOLTIP = {}

  function tip:InstallPetTooltip()
    tip.AbilityPetType = tip:CreateTexture(nil, "ARTWORK")
    tip.AbilityPetType:SetSize(33, 33)
    tip.AbilityPetType:SetPoint("TOPLEFT", 11, -10)
    tip.AbilityPetType:SetTexCoord(.79687500, .49218750, .50390625, .65625000)

    tip.Name = tip:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
    tip.Name:SetJustifyH("LEFT")
    tip.Name:SetJustifyV("MIDDLE")
    tip.Name:SetSize(190, 32)
    tip.Name:SetPoint("LEFT", tip.AbilityPetType, "RIGHT", 5, 0)
    tip.Name:SetText(NAME)

    tip.Duration = tip:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    tip.Duration:SetPoint("TOPLEFT", tip.AbilityPetType, "BOTTOMLEFT", 0, -5)
    tip.Duration:SetText(BATTLE_PET_ABILITY_MULTIROUND)

    tip.MaxCooldown = tip:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    tip.MaxCooldown:SetPoint("TOPLEFT", tip.Duration, "BOTTOMLEFT", 0, -5)
    tip.MaxCooldown:SetText(MAX_COOLDOWN)

    tip.CurrentCooldown = tip:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    tip.CurrentCooldown:SetPoint("TOPLEFT", tip.MaxCooldown, "BOTTOMLEFT", 0, -5)

    tip.AdditionalText = tip:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    tip.AdditionalText:SetJustifyH("LEFT")
    tip.AdditionalText:SetSize(239, 0)
    tip.AdditionalText:SetPoint("TOPLEFT", tip.CurrentCooldown, "BOTTOMLEFT", 5, -5)

    tip.Description = tip:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    tip.Description:SetJustifyH("LEFT")
    tip.Description:SetSize(239, 0)
    tip.Description:SetPoint("TOPLEFT", tip.CurrentCooldown, "BOTTOMLEFT", 5, -5) -- why? the lua reanchors it anyway...
    tip.Delimiter1 = tip:CreateTexture(nil, "ARTWORK")
    tip.Delimiter1:SetSize(251, 2)
    tip.Delimiter1:SetPoint("TOP", tip.Description, "BOTTOM", 0, -7)
    tip.Delimiter1:SetTexture(.2, .2, .2)
    tip.StrongAgainstIcon = tip:CreateTexture(nil, "ARTWORK")
    tip.StrongAgainstIcon:SetTexture("Interface\\PetBattles\\BattleBar-AbilityBadge-Strong")
    tip.StrongAgainstIcon:SetSize(32, 32)
    tip.StrongAgainstIcon:SetPoint("TOPLEFT", tip.Delimiter1, "BOTTOMLEFT", 5, -2)
    tip.StrongAgainstLabel = tip:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    tip.StrongAgainstLabel:SetPoint("LEFT", tip.StrongAgainstIcon, "RIGHT", 5, 0)
    tip.StrongAgainstLabel:SetText(PET_BATTLE_EFFECTIVENESS_VS)
    tip.StrongAgainstType1 = tip:CreateTexture(nil, "ARTWORK") -- we must copy "SharedPetBattleStrengthPetTypeTemplate" into this lua code, inheriting this will mess up the tooltip
    tip.StrongAgainstType1:SetTexCoord(.79687500, .49218750, .50390625, .65625000)
    tip.StrongAgainstType1:SetSize(32, 32)
    tip.StrongAgainstType1:SetPoint("LEFT", tip.StrongAgainstLabel, "RIGHT", 5, -2)
    tip.StrongAgainstType1Label = tip:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    tip.StrongAgainstType1Label:SetJustifyH("LEFT")
    tip.StrongAgainstType1Label:SetPoint("LEFT", tip.StrongAgainstType1, "RIGHT", 5, 0)
    tip.Delimiter2 = tip:CreateTexture(nil, "ARTWORK")
    tip.Delimiter2:SetSize(251, 2)
    tip.Delimiter2:SetPoint("TOPLEFT", tip.StrongAgainstIcon, "BOTTOMLEFT", -5, -5)
    tip.Delimiter2:SetTexture(.2, .2, .2)
    tip.WeakAgainstIcon = tip:CreateTexture(nil, "ARTWORK")
    tip.WeakAgainstIcon:SetTexture("Interface\\PetBattles\\BattleBar-AbilityBadge-Weak")
    tip.WeakAgainstIcon:SetSize(32, 32)
    tip.WeakAgainstIcon:SetPoint("TOPLEFT", tip.Delimiter2, "BOTTOMLEFT", 5, -2)
    tip.WeakAgainstLabel = tip:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    tip.WeakAgainstLabel:SetPoint("LEFT", tip.WeakAgainstIcon, "RIGHT", 5, 0)
    tip.WeakAgainstLabel:SetText(PET_BATTLE_EFFECTIVENESS_VS)
    tip.WeakAgainstType1 = tip:CreateTexture(nil, "ARTWORK") -- we must copy "SharedPetBattleStrengthPetTypeTemplate" into this lua code, inheriting this will mess up the tooltip
    tip.WeakAgainstType1:SetTexCoord(.79687500, .49218750, .50390625, .65625000)
    tip.WeakAgainstType1:SetSize(32, 32)
    tip.WeakAgainstType1:SetPoint("LEFT", tip.WeakAgainstLabel, "RIGHT", 5, -2)
    tip.WeakAgainstType1Label = tip:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    tip.WeakAgainstType1Label:SetJustifyH("LEFT")
    tip.WeakAgainstType1Label:SetPoint("LEFT", tip.WeakAgainstType1, "RIGHT", 5, 0)
    tip.strongAgainstTextures = {tip.StrongAgainstType1}
    tip.weakAgainstTextures = {tip.WeakAgainstType1}

    -- pet tooltip related
    tip.Name2 = tip:CreateFontString(nil, "ARTWORK", "GameFontNormalLargeLeft")
    tip.Name2:SetJustifyH("LEFT")
    tip.Name2:SetJustifyV("MIDDLE")
    tip.Name2:SetIndentedWordWrap(false)
    tip.Name2:SetSize(238, 0) -- 238, 32
    tip.Name2:SetPoint("TOP", 0, -10)
    tip.Name2:SetText("")

    tip.BattlePet = tip:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    tip.BattlePet:SetJustifyH("LEFT")
    tip.BattlePet:SetJustifyV("MIDDLE")
    tip.BattlePet:SetSize(238, 0)
    tip.BattlePet:SetPoint("TOP", tip.Name2, "BOTTOM", 0, -5)
    tip.BattlePet:SetText(TOOLTIP_BATTLE_PET)

    tip.PetType = tip:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    tip.PetType:SetJustifyH("RIGHT")
    tip.PetType:SetJustifyV("MIDDLE")
    tip.PetType:SetSize(238, 0)
    tip.PetType:SetPoint("TOP", tip.Name, "BOTTOM", -8, -5) -- ..., 0, -5
    tip.PetType:SetText(TOOLTIP_BATTLE_PET)

    tip.PetTypeTexture = tip:CreateTexture(nil, "ARTWORK")
    tip.PetTypeTexture:SetTexture("")
    tip.PetTypeTexture:SetTexCoord(.79687500, .49218750, .50390625, .65625000)
    tip.PetTypeTexture:SetSize(33, 33)
    tip.PetTypeTexture:SetPoint("TOPRIGHT", tip.PetType, "BOTTOMRIGHT", 0, -5)

    tip.Level = tip:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    tip.Level:SetJustifyH("LEFT")
    tip.Level:SetJustifyV("MIDDLE")
    tip.Level:SetSize(238, 0)
    tip.Level:SetPoint("TOP", tip.BattlePet, "BOTTOM", 0, -2)
    tip.Level:SetText(BATTLE_PET_CAGE_TOOLTIP_LEVEL)

    tip.HealthTexture = tip:CreateTexture(nil, "ARTWORK")
    tip.HealthTexture:SetTexture("Interface\\PetBattles\\PetBattle-StatIcons")
    tip.HealthTexture:SetTexCoord(.5, 1, .5, 1)
    tip.HealthTexture:SetSize(16, 16)
    tip.HealthTexture:SetPoint("TOPLEFT", tip.Level, "BOTTOMLEFT", 0, -2)

    tip.Health = tip:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    tip.Health:SetJustifyH("LEFT")
    tip.Health:SetJustifyV("MIDDLE")
    tip.Health:SetSize(0, 0)
    tip.Health:SetPoint("LEFT", tip.HealthTexture, "RIGHT", 2, 0)
    tip.Health:SetText("100")

    tip.PowerTexture = tip:CreateTexture(nil, "ARTWORK")
    tip.PowerTexture:SetTexture("Interface\\PetBattles\\PetBattle-StatIcons")
    tip.PowerTexture:SetTexCoord(0, .5, 0, .5)
    tip.PowerTexture:SetSize(16, 16)
    tip.PowerTexture:SetPoint("TOPLEFT", tip.HealthTexture, "BOTTOMLEFT", 0, -2)

    tip.Power = tip:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    tip.Power:SetJustifyH("LEFT")
    tip.Power:SetJustifyV("MIDDLE")
    tip.Power:SetSize(0, 0)
    tip.Power:SetPoint("LEFT", tip.PowerTexture, "RIGHT", 2, 0)
    tip.Power:SetText("100")

    tip.SpeedTexture = tip:CreateTexture(nil, "ARTWORK")
    tip.SpeedTexture:SetTexture("Interface\\PetBattles\\PetBattle-StatIcons")
    tip.SpeedTexture:SetTexCoord(0, .5, .5, 1)
    tip.SpeedTexture:SetSize(16, 16)
    tip.SpeedTexture:SetPoint("TOPLEFT", tip.PowerTexture, "BOTTOMLEFT", 0, -2)

    tip.Speed = tip:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    tip.Speed:SetJustifyH("LEFT")
    tip.Speed:SetJustifyV("MIDDLE")
    tip.Speed:SetSize(0, 0)
    tip.Speed:SetPoint("LEFT", tip.SpeedTexture, "RIGHT", 2, 0)
    tip.Speed:SetText("100")

    tip.Delimiter = tip:CreateTexture(nil, "ARTWORK")
    tip.Delimiter:SetSize(0, 0)
    tip.Delimiter:Hide()
    --tip.Delimiter:SetSize(251, 2)
    --tip.Delimiter:SetPoint("TOPLEFT", tip.SpeedTexture, "BOTTOMLEFT", -6, -5)
    --tip.Delimiter:SetTexture(.2, .2, .2)

    tip.PetTooltipsInstalled = {
      tip.AbilityPetType,
      tip.AdditionalText,
      tip.CurrentCooldown,
      tip.Delimiter1,
      tip.Delimiter2,
      tip.Description,
      tip.Duration,
      tip.MaxCooldown,
      tip.Name,
      tip.StrongAgainstIcon,
      tip.StrongAgainstLabel,
      tip.StrongAgainstType1,
      tip.StrongAgainstType1Label,
      tip.WeakAgainstIcon,
      tip.WeakAgainstLabel,
      tip.WeakAgainstType1,
      tip.WeakAgainstType1Label,
    }

    tip.PetTooltipsInstalled2 = {
      tip.Name2,
      tip.BattlePet,
      tip.PetType,
      tip.PetTypeTexture,
      tip.Level,
      tip.HealthTexture,
      tip.Health,
      tip.PowerTexture,
      tip.Power,
      tip.SpeedTexture,
      tip.Speed,
      --tip.Delimiter,
    }

    local NameSetText = tip.Name.SetText
    function tip.Name:SetText(...)
      if (tonumber(self:GetParent().speciesID) or 0) > 0 then
        tip.Name2:SetText(...)
      else
        NameSetText(tip.Name, ...)
      end
    end

    local NameSetTextColor = tip.Name.SetTextColor
    function tip.Name:SetTextColor(...)
      if (tonumber(self:GetParent().speciesID) or 0) > 0 then
        tip.Name2:SetTextColor(...)
      else
        NameSetTextColor(tip.Name, ...)
      end
    end
  end

  function tip:GetGlyphType()
    local obj, txt
    for i = 1, 10 do
      obj = _G[tip:GetName().."TextLeft"..i]
      if obj then
        txt = obj:GetText()
        if txt:find(PRIME_GLYPH) then
          return 1
        elseif txt:find(MAJOR_GLYPH) then
          return 2
        elseif txt:find(MINOR_GLYPH) then
          return 3
        end
      end
    end
  end

  function tip:SetIconTexture(texture, count)
    if not addonData:GetBoolOpt("MOUSEOVER_LINKS_ICON") then
      if tip.icon then
        tip.icon:Hide()
      end
      return
    end

    if type(texture) ~= "string" or texture:len() == 0 then
      --texture = "Interface\\Icons\\INV_Misc_QuestionMark"
      --texture = "Interface\\Icons\\TEMP"
      texture = ""
    end

    if not tip.icon then
      tip.icon = tip:CreateTexture(nil, "BACKGROUND")
      tip.icon:SetSize(42, 42)
      --tip.icon.count = tip:CreateFontString(nil, "ARTWORK", "GameFontNormal")
      --tip.icon.count:SetTextColor(1, 1, 1)
      --tip.icon.count:SetPoint("BOTTOMRIGHT", tip.icon, "BOTTOMRIGHT", -3, 3)
    end

    tip.icon:ClearAllPoints()

    if ((tip:GetLeft() or 46)-42-4) < 0 then -- show on the right side if it will be out of the screen (:GetLeft() is nil when ANCHOR_CURSOR -when cursored show always on left side no mater what)
      tip.icon:SetPoint("TOPLEFT", tip, "TOPRIGHT", 0, -2.5)
    else
      tip.icon:SetPoint("TOPRIGHT", tip, "TOPLEFT", 0, -2.5)
    end

    tip.icon:SetTexture(texture)
    --tip.icon.count:SetText(count or "")
    tip.icon:Show()
  end

  function tip:Set(linkData, link)
    if linkData then
      if tip.icon then
        tip.icon:Hide()
      end

      local chat = addonData:GetChatFrame()
      tip.elem = GetMouseFocus()
      if chat.buttonFrame and (addonData:GetBoolOpt("MOUSEOVER_LINKS_ANCHOR") or linkData:match("battlePetAbil")) then -- BUG: exception for pet abilities, those always anchor (to avoid nil bug for GetTop/Bottom)
        tip:SetOwner(chat.buttonFrame, "ANCHOR_TOPLEFT", 1, 40)
      else
        tip:SetOwner(UIParent, "ANCHOR_CURSOR")
      end

      if tip.PetTooltipsInstalled then
        for _, object in pairs(tip.PetTooltipsInstalled) do
          object:Hide()
        end
      end

      if tip.PetTooltipsInstalled2 then
        for _, object in pairs(tip.PetTooltipsInstalled2) do
          object:Hide()
        end
      end

      tip:ClearLines()

      local newSize
      local href, arg1, arg2, arg3, arg4, arg5, arg6, arg7 = (":"):split(linkData, 7 + 1)
      local bcol = safeHyperlinks[href]

      if bcol then -- it's nil if the hyperlink is not supported by the widget API
        tip:SetHyperlink(linkData)

        if href == "item" then
          local count, _, _, quality, _, _, class, subclass, maxstack, _, texture = GetItemCount(link or 0) or 1, GetItemInfo(link or 0)
          tip:SetIconTexture(texture, count > 1 and count or "")

          if addonData:ItemClassQuest(class) or addonData:ItemClassQuest(subclass) then
            if addonData:ItemStartsQuest(linkData) then
              bcol = {1, .2, .2} -- it starts a quest so instead of heirloom color it's now red!
            else
              bcol = {.9, .8, .5}
            end
          else
            if addonData:ItemStartsQuest(linkData, 1) then
              bcol = {.9, .8, .5}
            else
              bcol = {GetItemQualityColor(quality or 1)} -- fallback to white color
              bcol[4] = nil -- remove hex color -it's not alpha after all
            end
          end

        elseif href == "enchant" or href == "spell" or href == "talent" then
          local spellID = tonumber(select(3, tip:GetSpell()) or 0) or 0
          local _, _, texture = GetSpellInfo(spellID)
          tip:SetIconTexture(texture or "", "")

        elseif href == "glyph" then
          local gtype = tip:GetGlyphType() or 3
          local cname = glyphClassFilenames[math_random(1, #glyphClassFilenames)]
          local file = format("INV_Glyph_%s%s", gtype == 1 and "Prime" or gtype == 2 and "Major" or "Minor", cname)
          tip:SetIconTexture("Interface\\Icons\\"..file, "") -- we don't know what class the glyph belongs to so we pick one at random

        elseif href == "achievement" then
          local achID = tonumber(linkData:match("^"..href..":(%d+)") or 0) or 0
          local _, _, _, _, _, _, _, _, _, texture = GetAchievementInfo(achID)
          tip:SetIconTexture(texture or "", "")

        elseif href == "currency" then
          local curID = tonumber(linkData:match("^"..href..":(%d+)") or 0) or 0
          local name, amount, texture, weekAmount, weekMax, totalMax, isHeader = GetCurrencyInfo(curID)
          tip:SetIconTexture(texture, "")

        end

        if not tip.backdropmod then
          tip.backdropmod = 1 -- only apply the backdrop once per tip creation (without this block the background insets are wrong)
          local bd, bdc = tip:GetBackdrop(), {tip:GetBackdropColor()}
          bd.insets = {left=2, right=2, top=2, bottom=2}
          tip:SetBackdrop(bd)
          tip:SetBackdropColor(unpack(bdc))
        end

        tip:SetBackdropBorderColor(unpack(bcol))

      --[[
      elseif href == "urlIndex" then
        --LoadURLIndex(tonumber(arg1))

      elseif href == "lootHistory" then
        --LootHistoryFrame_ToggleWithRoll(LootHistoryFrame, tonumber(arg1), chat)
      ]]

      elseif href == "battlePetAbil" then
        --FloatingPetBattleAbility_Show(tonumber(arg1), tonumber(arg2), tonumber(arg3), tonumber(arg4))
        arg1 = tonumber(arg1) or 0
        if arg1 > 0 then
          if not tip.PetTooltipsInstalled then
            tip:InstallPetTooltip()
          end

          for _, object in pairs(tip.PetTooltipsInstalled) do
            object:Show()
          end

          for _, object in pairs(tip.PetTooltipsInstalled2) do
            object:Hide()
          end

          tip.speciesID = 0 -- reset value to avoid problem with the name labels (ability vs. pet name)
          PET_BATTLE_FLOATING_ABILITY_TOOLTIP.abilityID = arg1
          PET_BATTLE_FLOATING_ABILITY_TOOLTIP.maxHealth = arg2
          PET_BATTLE_FLOATING_ABILITY_TOOLTIP.power = arg3
          PET_BATTLE_FLOATING_ABILITY_TOOLTIP.speed = arg4

          SharedPetBattleAbilityTooltip_SetAbility(tip, PET_BATTLE_FLOATING_ABILITY_TOOLTIP)

          if not tip.backdropmod then
            tip.backdropmod = 1 -- only apply the backdrop once per tip creation (without this block the background insets are wrong)
            local bd, bdc = tip:GetBackdrop(), {tip:GetBackdropColor()}
            bd.insets = {left=2, right=2, top=2, bottom=2}
            tip:SetBackdrop(bd)
            tip:SetBackdropColor(unpack(bdc))
          end

          tip:SetBackdropBorderColor(.31, .59, .97)
          tip:SetIconTexture(select(3, C_PetBattles_GetAbilityInfoByID(arg1)) or "", "")
          tip:AddLine(" ") -- otherwise the tooltip will be invisible
          newSize = {260, 90+35}
        end

      elseif href == "battlepet" then
        --FloatingBattlePet_Toggle(tonumber(speciesID), tonumber(level), tonumber(breedQuality), tonumber(maxHealth), tonumber(power), tonumber(speed), string_gsub(string_gsub(text, "^(.*)%[", ""), "%](.*)$", ""), tonumber(battlePetID))
        arg1 = tonumber(arg1) or 0
        if arg1 > 0 then
          if not tip.PetTooltipsInstalled then
            tip:InstallPetTooltip()
          end

          for _, object in pairs(tip.PetTooltipsInstalled) do
            object:Hide()
          end

          for _, object in pairs(tip.PetTooltipsInstalled2) do
            object:Show()
          end

          arg3 = tonumber(arg3) or -1
          local customName = string_gsub(string_gsub(link, "^(.*)%[", ""), "%](.*)$", "")
          local name, icon, petType = C_PetJournal_GetPetInfoBySpeciesID(arg1)
          BATTLE_PET_FLOATING_TOOLTIP.speciesID = arg1
          BATTLE_PET_FLOATING_TOOLTIP.name = name
          BATTLE_PET_FLOATING_TOOLTIP.level = tonumber(arg2)
          BATTLE_PET_FLOATING_TOOLTIP.breedQuality = arg3
          BATTLE_PET_FLOATING_TOOLTIP.petType = petType
          BATTLE_PET_FLOATING_TOOLTIP.maxHealth = tonumber(arg4)
          BATTLE_PET_FLOATING_TOOLTIP.power = tonumber(arg5)
          BATTLE_PET_FLOATING_TOOLTIP.speed = tonumber(arg6)
          BATTLE_PET_FLOATING_TOOLTIP.battlePetID = tonumber(arg7)
          BATTLE_PET_FLOATING_TOOLTIP.customName = customName ~= BATTLE_PET_FLOATING_TOOLTIP.name and customName or nil
          BattlePetTooltipTemplate_SetBattlePet(tip, BATTLE_PET_FLOATING_TOOLTIP)

          if not tip.backdropmod then
            tip.backdropmod = 1 -- only apply the backdrop once per tip creation (without this block the background insets are wrong)
            local bd, bdc = tip:GetBackdrop(), {tip:GetBackdropColor()}
            bd.insets = {left=2, right=2, top=2, bottom=2}
            tip:SetBackdrop(bd)
            tip:SetBackdropColor(unpack(bdc))
          end

          if arg3 ~= -1 then
            tip:SetBackdropBorderColor(ITEM_QUALITY_COLORS[arg3].r, ITEM_QUALITY_COLORS[arg3].g, ITEM_QUALITY_COLORS[arg3].b)
          else
            tip:SetBackdropBorderColor(1, .82, 0)
          end

          tip:SetIconTexture(icon or "", BATTLE_PET_FLOATING_TOOLTIP.level or "")
          tip:AddLine(" ") -- otherwise the tooltip will be invisible
          newSize = {260+10, 120+5}
        end
      end

      if tip:NumLines() > 0 then
        tip:Show()
        if newSize then
          tip:SetSize(unpack(newSize))
        end
      end

    else
      if tip.icon then
        tip.icon:Hide()
      end
      tip.elem = nil
      tip:Hide()
    end
  end

  function tip:Enable()
    local chat = addonData:GetChatFrame()

    if not tip.oH then
      tip.oH = 1
      tip.oHEnter = chat:GetScript("OnHyperlinkEnter")
      tip.oHLeave = chat:GetScript("OnHyperlinkLeave")
      tip.oUpdate = chat:GetScript("OnUpdate")
    end

    chat:SetScript("OnHyperlinkEnter", function(chat, linkData, link, ...)
      tip:Set(linkData, link)
      if tip.oHEnter then
        tip:oHEnter(linkData, link, ...)
      end
    end)

    chat:SetScript("OnHyperlinkLeave", function(chat, linkData, link, ...)
      tip:Set(nil)
      if tip.oHLeave then
        tip:oHLeave(linkData, link, ...)
      end
    end)

    chat:SetScript("OnUpdate", function(chat, elapsed, ...)
      tip.oUS = (tip.oUS or 0) + elapsed
      if tip.oUS > .1 then
        if tip.elem ~= GetMouseFocus() then
          tip:Set(nil)
        end
        tip.oUS = 0
      end
      if tip.oUpdate then
        tip:oUpdate(chat, elapsed, ...)
      end
    end)
  end

  function tip:Disable()
    local chat = addonData:GetChatFrame()

    if tip.oH then
      chat:SetScript("OnHyperlinkEnter", tip.oHEnter)
      chat:SetScript("OnHyperlinkLeave", tip.oHLeave)
      chat:SetScript("OnUpdate", tip.oUpdate)
    end
  end
end

function module:Enable()
  if not module.IsEnabled then
    module.IsEnabled = 1
  else
    return
  end
  tip:Enable()
end

function module:Disable()
  if module.IsEnabled then
    module.IsEnabled = nil
  else
    return
  end
  tip:Disable()
end
