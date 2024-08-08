local ns = select(2, ...) ---@class MiniLootNS

local db = ns.Settings.db

---@diagnostic disable-next-line: deprecated
local GetSpellInfo = GetSpellInfo or function(spell)
    local info = C_Spell.GetSpellInfo(spell)
    if not info then
        return
    end
    return info.name, "", info.iconID, info.castTime, info.minRange, info.maxRange, info.spellID, info.originalIconID
end

---@param tooltip GameTooltip
---@param chatFrame MiniLootChatFramePolyfill
---@param anchor? TooltipAnchor
---@param xOffset? number
---@param yOffset? number
local function AnchorTooltip(tooltip, chatFrame, anchor, xOffset, yOffset)
    if tooltip.SetOwner then
        tooltip:SetOwner(chatFrame, anchor or "ANCHOR_TOPLEFT", xOffset or 0, yOffset or 40)
    elseif tooltip.SetPoint then
        tooltip:ClearAllPoints()
        tooltip:SetPoint("BOTTOMLEFT", chatFrame, "TOPLEFT", xOffset or 0, yOffset or 40)
    end
end

---@param handler MiniLootTooltipHandler
---@param chatFrame MiniLootChatFramePolyfill
---@param linkData string
---@param link string
---@param anchor? TooltipAnchor
---@param xOffset? number
---@param yOffset? number
local function ShowTooltip(handler, chatFrame, linkData, link, anchor, xOffset, yOffset)
    AnchorTooltip(GameTooltip, chatFrame, anchor, xOffset, yOffset)
    if link then
        GameTooltip:SetHyperlink(link)
    end
    GameTooltip:Show()
end

---@enum MiniLootTooltipHandlerType
local HandlerTypes = {
    Item = "Item",
    Currency = "Currency",
    Spell = "Spell",
    Quest = "Quest",
    Achievement = "Achievement",
    Profession = "Profession",
    InstanceLockout = "InstanceLockout",
    BattlePet = "BattlePet",
    Garrison = "Garrison",
    DeathRecap = "DeathRecap",
    Unit = "Unit",
}

---@alias MiniLootTooltipHandlerIsEnabled fun(self: MiniLootTooltipHandler): boolean?

---@alias MiniLootTooltipHandlerShow fun(self: MiniLootTooltipHandler, chatFrame: MiniLootChatFramePolyfill, linkData: string, link: string)

---@alias MiniLootTooltipHandlerHide fun(self: MiniLootTooltipHandler)

---@class MiniLootTooltipHandler
---@field public Type MiniLootTooltipHandlerType
---@field public Pattern string|string[]
---@field public IsEnabled? MiniLootTooltipHandlerIsEnabled
---@field public Show? MiniLootTooltipHandlerShow
---@field public Hide? MiniLootTooltipHandlerHide

---@class DeathRecapEventPolyfill
---@field public timestamp number 1421121447.489
---@field public event string "SWING_DAMAGE"
---@field public hideCaster boolean false
---@field public sourceGUID string "Creature-0-3296-870-59-72280-0000347644"
---@field public sourceName string "Manifestation of Pride"
---@field public sourceFlags number 2632
---@field public sourceRaidFlags number 0
---@field public destGUID string "Player-3296-0084A447
---@field public destName string "Gethe"
---@field public destFlags number 1297
---@field public destRaidFlags number 0
---@field public amount number 1472
---@field public overkill number -1
---@field public school number 1
---@field public critical boolean false
---@field public glancing boolean false
---@field public crushing boolean false
---@field public isOffHand boolean false
---@field public multistrike boolean false
---@field public currentHP number 2185
---@field public spellName string
---@field public spellId number
---@field public environmentalType string
---@field public DamageInfo DeathRecapEventDamageInfoPolyfill
---@field public absorbed number
---@field public resisted number
---@field public blocked number
---@field public casterPrestige string
---@field public tombstone boolean

---@class DeathRecapEventDamageInfoPolyfill
---@field public amountStr string
---@field public amount string
---@field public dmgExtraStr string
---@field public timestamp number
---@field public hpPercent number
---@field public spellName string
---@field public caster string
---@field public casterPrestige string
---@field public school number

---@type MiniLootTooltipHandler[]
local TooltipHandlers = {
    {
        Type = "Item",
        Pattern = "^item:",
    },
    {
        Type = "Item",
        Pattern = "^azessence:",
    },
    {
        Type = "Currency",
        Pattern = "^currency:",
    },
    {
        Type = "Spell",
        Pattern = "^spell:",
    },
    {
        Type = "Spell",
        Pattern = {"^talent:", "^pvptal:"},
    },
    {
        Type = "Spell",
        Pattern = "^glyph:",
    },
    {
        Type = "Quest",
        Pattern = "^quest:",
    },
    {
        Type = "Achievement",
        Pattern = "^achievement:",
    },
    {
        Type = "Profession",
        Pattern = "^enchant:",
    },
    {
        Type = "InstanceLockout",
        Pattern = "^instancelock:",
    },
    {
        Type = "BattlePet",
        Pattern = "^battlepet:",
        IsEnabled = function()
            return BattlePetTooltip and BattlePetToolTip_Show and true
        end,
        Show = function(self, chatFrame, linkData, link)
            local _, speciesID, level, breedQuality, maxHealth, power, speed = strsplit(":", linkData)
            local name = strmatch(link, "%[(.-)%]")
            AnchorTooltip(GameTooltip, chatFrame)
            BattlePetToolTip_Show(tonumber(speciesID), tonumber(level), tonumber(breedQuality), tonumber(maxHealth), tonumber(power), tonumber(speed), name)
            GameTooltip:Hide()
        end,
        Hide = function(self)
            BattlePetTooltip:Hide()
        end,
    },
    {
        Type = "BattlePet",
        Pattern = "^battlePetAbil:",
        IsEnabled = function()
            return FloatingPetBattleAbilityTooltip and FloatingPetBattleAbility_Show and true
        end,
        Show = function(self, chatFrame, linkData, link)
            local _, abilityID, maxHealth, power, speed = strsplit(":", linkData)
            FloatingPetBattleAbility_Show(tonumber(abilityID), tonumber(maxHealth), tonumber(power), tonumber(speed))
            AnchorTooltip(FloatingPetBattleAbilityTooltip, chatFrame)
        end,
        Hide = function(self)
            FloatingPetBattleAbilityTooltip:Hide()
        end,
    },
    {
        Type = "Garrison",
        Pattern = "^garrfollower:",
        IsEnabled = function()
            return FloatingGarrisonShipyardFollowerTooltip and FloatingGarrisonFollowerTooltip and FloatingGarrisonFollower_Toggle and true
        end,
        Show = function(self, chatFrame, linkData, link)
            local _, garrisonFollowerID, quality, level, itemLevel, ability1, ability2, ability3, ability4, trait1, trait2, trait3, trait4, spec1 = strsplit(":", linkData)
            FloatingGarrisonFollower_Toggle(tonumber(garrisonFollowerID), tonumber(quality), tonumber(level), tonumber(itemLevel), tonumber(spec1), tonumber(ability1), tonumber(ability2), tonumber(ability3), tonumber(ability4), tonumber(trait1), tonumber(trait2), tonumber(trait3), tonumber(trait4))
            local garrisonFollowerType = C_Garrison.GetFollowerTypeByID(garrisonFollowerID)
            if garrisonFollowerType == Enum.GarrisonFollowerType.FollowerType_6_0_Boat then
                AnchorTooltip(FloatingGarrisonShipyardFollowerTooltip, chatFrame)
            else
                AnchorTooltip(FloatingGarrisonFollowerTooltip, chatFrame)
            end
        end,
        Hide = function(self)
            FloatingGarrisonShipyardFollowerTooltip:Hide()
            FloatingGarrisonFollowerTooltip:Hide()
        end,
    },
    {
        Type = "Garrison",
        Pattern = "garrfollowerability",
        IsEnabled = function()
            return FloatingGarrisonFollowerAbilityTooltip and FloatingGarrisonFollowerAbility_Toggle and true
        end,
        Show = function(self, chatFrame, linkData, link)
            local _, garrFollowerAbilityID = strsplit(":", linkData)
            FloatingGarrisonFollowerAbility_Toggle(tonumber(garrFollowerAbilityID))
            AnchorTooltip(FloatingGarrisonFollowerAbilityTooltip, chatFrame)
        end,
        Hide = function(self)
            FloatingGarrisonFollowerAbilityTooltip:Hide()
        end,
    },
    {
        Type = "Garrison",
        Pattern = "^garrmission:",
        IsEnabled = function()
            return FloatingGarrisonMissionTooltip and FloatingGarrisonMission_Toggle and true
        end,
        Show = function(self, chatFrame, linkData, link)
            local _, garrMissionID = strsplit(":", linkData)
            garrMissionID = tonumber(garrMissionID)
            if garrMissionID then
                FloatingGarrisonMission_Toggle(garrMissionID)
                AnchorTooltip(FloatingGarrisonMissionTooltip, chatFrame)
            end
        end,
        Hide = function(self)
            FloatingGarrisonMissionTooltip:Hide()
        end,
    },
    {
        Type = "DeathRecap",
        Pattern = "^death:",
        IsEnabled = function()
            return DeathRecap_GetEvents and true
        end,
        Show = function(self, chatFrame, linkData, link)
            local _, id = strsplit(":", linkData)
            local events = DeathRecap_GetEvents(id) ---@type DeathRecapEventPolyfill[]
            if not events or not events[1] then
                AnchorTooltip(GameTooltip, chatFrame)
				GameTooltip:SetText(DEATH_RECAP_UNAVAILABLE)
				GameTooltip:Show()
                return
            end
            local recap = {} ---@type DeathRecapEventPolyfill[]
            local index = 0
            local maxHp = UnitHealthMax("player")
            local highestDmgIdx, highestDmgAmount = 1, 0
            for i = 1, #events do
                local evtData = events[i]
                local spellId, spellName, texture
                -- DeathRecapFrame_GetEventInfo
                do
                    spellName = evtData.spellName
                    local nameIsNotSpell = false
                    local event = evtData.event
                    spellId = evtData.spellId
                    if event == "SWING_DAMAGE" then
                        spellId = 88163
                        spellName = ACTION_SWING
                        nameIsNotSpell = true
                    elseif event == "RANGE_DAMAGE" then
                        nameIsNotSpell = true
                    -- elseif strsub(event, 1, 5) == "SPELL" then
                    -- elseif event == "DAMAGE_SHIELD" then
                    elseif event == "ENVIRONMENTAL_DAMAGE" then
                        local environmentalType = evtData.environmentalType:upper()
                        spellName = _G[format("ACTION_ENVIRONMENTAL_DAMAGE_%s", environmentalType)]
                        nameIsNotSpell = true
                        if environmentalType == "DROWNING" then
                            texture = "spell_shadow_demonbreath"
                        elseif environmentalType == "FALLING" then
                            texture = "ability_rogue_quickrecovery"
                        elseif environmentalType == "FIRE" or environmentalType == "LAVA" then
                            texture = "spell_fire_fire"
                        elseif environmentalType == "SLIME" then
                            texture = "inv_misc_slime_01"
                        elseif environmentalType == "FATIGUE" then
                            texture = "ability_creature_cursed_05"
                        else
                            texture = "ability_creature_cursed_05"
                        end
                        texture = format("Interface\\Icons\\%s", texture)
                    -- elseif event == "DAMAGE_SPLIT" then
                    end
                    local spellNameStr = spellName
                    local spellString
                    if spellName then
                        if nameIsNotSpell then
                            spellString = format(TEXT_MODE_A_STRING_ACTION, event, spellNameStr)
                        else
                            spellString = spellName
                        end
                    end
                    if spellId and not texture then
                        _, _, texture = GetSpellInfo(spellId)
                    end
                    spellName = spellString
                end
                local dmgInfo = evtData.DamageInfo
                if not dmgInfo then
                    dmgInfo = {} ---@diagnostic disable-line: missing-fields
                    evtData.DamageInfo = dmgInfo
                end
                if evtData.amount then
                    dmgInfo.amountStr = BreakUpLargeNumbers(-evtData.amount)
                    dmgInfo.amount = BreakUpLargeNumbers(evtData.amount)
                    dmgInfo.dmgExtraStr = ""
                    if evtData.overkill and evtData.overkill > 0 then
                        dmgInfo.dmgExtraStr = format(TEXT_MODE_A_STRING_RESULT_OVERKILLING, evtData.overkill)
                        dmgInfo.amount = BreakUpLargeNumbers(evtData.amount - evtData.overkill)
                    end
                    if evtData.absorbed and evtData.absorbed > 0 then
                        dmgInfo.dmgExtraStr = format("%s %s", dmgInfo.dmgExtraStr, format(TEXT_MODE_A_STRING_RESULT_ABSORB, evtData.absorbed))
                        dmgInfo.amount = BreakUpLargeNumbers(evtData.amount - evtData.absorbed)
                    end
                    if evtData.resisted and evtData.resisted > 0 then
                        dmgInfo.dmgExtraStr = format("%s %s", dmgInfo.dmgExtraStr, format(TEXT_MODE_A_STRING_RESULT_RESIST, evtData.resisted))
                        dmgInfo.amount = BreakUpLargeNumbers(evtData.amount - evtData.resisted)
                    end
                    if evtData.blocked and evtData.blocked > 0 then
                        dmgInfo.dmgExtraStr = format("%s %s", dmgInfo.dmgExtraStr, format(TEXT_MODE_A_STRING_RESULT_BLOCK, evtData.blocked))
                        dmgInfo.amount = BreakUpLargeNumbers(evtData.amount - evtData.blocked)
                    end
                    if evtData.amount > highestDmgAmount then
                        highestDmgIdx = i
                        highestDmgAmount = evtData.amount
                    end
                end
                dmgInfo.timestamp = evtData.timestamp
                dmgInfo.hpPercent = floor(evtData.currentHP/maxHp*100)
                dmgInfo.spellName = spellName
                if not evtData.hideCaster then
                    dmgInfo.caster = evtData.sourceName or COMBATLOG_UNKNOWN_UNIT
                    dmgInfo.casterPrestige = evtData.casterPrestige
                else
                    dmgInfo.caster = nil
                    dmgInfo.casterPrestige = nil
                end
                dmgInfo.school = evtData.school
                index = index + 1
                recap[index] = evtData
            end
            local lines = {} ---@type string[]
            for i = 1, index do
                local event = recap[i]
                lines[i] = format(
                    "%s%s%s%s |cffFFFFFF%s|r%s",
                    event.tombstone and "|TInterface\\Minimap\\Minimap_skull_normal:0:0|t " or "",
                    event.critical and "*" or "",
                    event.DamageInfo.amountStr or "",
                    event.critical and "*" or "",
                    event.DamageInfo.spellName or "",
                    event.hideCaster and "" or format(" |cffFF0000%s|r", event.DamageInfo.caster or "")
                )
            end
            local text = table.concat(lines, "\n")
            AnchorTooltip(GameTooltip, chatFrame)
            GameTooltip:SetText(text)
            GameTooltip:Show()
        end,
    },
    {
        Type = "Unit",
        Pattern = "^unit:",
    },
    {
        Type = "Item",
        Pattern = "^apower:",
    },
    {
        Type = "Item",
        Pattern = "^keystone:",
    },
    {
        Type = "Spell",
        Pattern = "^mawpower:",
    },
    {
        Type = "Spell",
        Pattern = "^conduit:",
    },
}

local showingHandler ---@type MiniLootTooltipHandler?

---@param chatFrame MiniLootChatFramePolyfill
---@param linkData string
---@param link string
local function OnHyperlinkEnter(chatFrame, linkData, link)
    if showingHandler then
        showingHandler:Hide()
        showingHandler = nil
    end
    for _, handler in ipairs(TooltipHandlers) do
        if db.EnabledTooltips[handler.Type] ~= false and (not handler.IsEnabled or handler:IsEnabled()) then
            local matched = false
            local pattern = handler.Pattern
            if type(pattern) == "table" then
                for _, p in ipairs(pattern) do
                    if p:find(linkData) then
                        matched = true
                        break
                    end
                end
            elseif linkData:find(pattern) then
                matched = true
            end
            if matched then
                showingHandler = handler
                if handler.Show then
                    handler:Show(chatFrame, linkData, link)
                else
                    ShowTooltip(handler, chatFrame, linkData, link)
                end
                break
            end
        end
    end
end

---@param chatFrame MiniLootChatFramePolyfill
local function OnHyperlinkLeave(chatFrame)
    if not showingHandler then
        return
    end
    if showingHandler.Hide then
        showingHandler:Hide()
    else
        GameTooltip:Hide()
    end
    showingHandler = nil
end

---@type table<MiniLootChatFramePolyfill, boolean?>
local hookedChatFrames = {}

---@param chatFrame MiniLootChatFramePolyfill
---@param ... any
local function OnHyperlinkEnterIfEnabled(chatFrame, ...)
    local status = hookedChatFrames[chatFrame]
    if status == true then
        OnHyperlinkEnter(chatFrame, ...)
    end
end

---@param chatFrame MiniLootChatFramePolyfill
local function OnHyperlinkLeaveIfEnabled(chatFrame)
    local status = hookedChatFrames[chatFrame]
    if status == true then
        OnHyperlinkLeave(chatFrame)
    end
end

---@param chatFrame MiniLootChatFramePolyfill
local function HookChatFrame(chatFrame)
    chatFrame:HookScript("OnHyperlinkEnter", OnHyperlinkEnterIfEnabled)
    chatFrame:HookScript("OnHyperlinkLeave", OnHyperlinkLeaveIfEnabled)
end

---@param chatFrame MiniLootChatFramePolyfill
local function EnableHyperlinks(chatFrame)
    local status = hookedChatFrames[chatFrame]
    if status == nil then
        HookChatFrame(chatFrame)
    end
    hookedChatFrames[chatFrame] = true
end

---@param chatFrame MiniLootChatFramePolyfill
local function DisableHyperlinks(chatFrame)
    local status = hookedChatFrames[chatFrame]
    if status == nil then
        HookChatFrame(chatFrame)
    end
    hookedChatFrames[chatFrame] = false
end

---@class MiniLootNSTooltip
ns.Tooltip = {
    HandlerTypes = HandlerTypes,
    EnableHyperlinks = EnableHyperlinks,
    DisableHyperlinks = DisableHyperlinks,
}
