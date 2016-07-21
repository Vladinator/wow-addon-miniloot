local addonName, ns = ...
ns.tooltip = {}

-- legion check
local IS_LEGION = select(4, GetBuildInfo()) >= 70000

-- tooltip scanning
do
	-- tooltip frame
	local frame = CreateFrame("GameTooltip")
	local texts = {}

	-- tooltip lines
	for i = 1, 20 do
		local a = frame:CreateFontString("$parentTextLeft" .. i, nil, "GameTooltipText")
		local b = frame:CreateFontString("$parentTextRight" .. i, nil, "GameTooltipText")
		table.insert(texts, {a, b})
		frame:AddFontStrings(a, b)
	end

	-- scan tooltip lines
	local function ScanTooltip()
		local temp = {}

		for i = 1, frame:NumLines(), 1 do
			local text = texts[i]

			if text then
				local textLeft, textRight = text[1], text[2]

				table.insert(temp, {textLeft:GetText(), textRight:GetText()})
			end
		end

		if temp[1] and temp[1] ~= "" then
			return true, temp
		end

		return false
	end

	-- ns.tooltip:ScanItem(id) = bool[, textLines]
	do
		local cache = {}

		function ns.tooltip:ScanItem(id)
			local success, temp = nil, cache[id]

			if temp then
				return true, temp
			end

			frame:SetOwner(WorldFrame, "ANCHOR_NONE")
			frame:SetHyperlink(("item:%d"):format(id))

			if frame:IsShown() then
				success, temp = ScanTooltip()

				if success then
					cache[id] = temp
				end

				frame:Hide()
				return success, temp
			end

			return false
		end
	end

	-- ns.tooltip:ScanCreature(id) = bool[, textLines]
	do
		local cache = {}

		function ns.tooltip:ScanCreature(id)
			local success, temp = nil, cache[id]

			if temp then
				return true, temp
			end

			frame:SetOwner(WorldFrame, "ANCHOR_NONE")
			frame:SetHyperlink(("unit:0xF53%05X00000000"):format(id))

			if frame:IsShown() then
				success, temp = ScanTooltip()

				if success then
					cache[id] = temp
				end

				frame:Hide()
				return success, temp
			end

			return false
		end
	end
end

-- chat hyperlink hover
do
	local showingHandler

	local function AnchorTooltip(tooltip, chatFrame, anchor, xOffset, yOffset)
		if tooltip.SetOwner then
			tooltip:SetOwner(chatFrame, anchor or "ANCHOR_TOPLEFT", xOffset or 0, yOffset or 40)

		elseif tooltip.SetPoint then
			tooltip:ClearAllPoints()
			tooltip:SetPoint("BOTTOMLEFT", chatFrame, "TOPLEFT", xOffset or 0, yOffset or 40)
		end
	end

	local function ShowTooltip(handler, chatFrame, linkData, link, anchor, xOffset, yOffset)
		AnchorTooltip(GameTooltip, chatFrame, anchor, xOffset, yOffset)

		if link then
			GameTooltip:SetHyperlink(link)
		end

		GameTooltip:Show()
	end

	local handlers = {
		{
			pattern = {"^item:"},
			key = "CHAT_TOOLTIP_ITEM"
		},
		{
			pattern = {"^currency:"},
			key = "CHAT_TOOLTIP_CURRENCY"
		},
		{
			pattern = {"^spell:"},
			key = "CHAT_TOOLTIP_SPELL"
		},
		{
			pattern = {"^talent:", "^pvptal:"},
			key = "CHAT_TOOLTIP_TALENT"
		},
		{
			pattern = {"^quest:"},
			key = "CHAT_TOOLTIP_QUEST"
		},
		{
			pattern = {"^achievement:"},
			key = "CHAT_TOOLTIP_ACHIEVEMENT"
		},
		{
			pattern = {"^enchant:"},
			key = "CHAT_TOOLTIP_TRADE"
		},
		{
			pattern = {"^instancelock:"},
			key = "CHAT_TOOLTIP_INSTANCELOCK"
		},
		{
			pattern = {"^glyph:"},
			key = "CHAT_TOOLTIP_GLYPH"
		},
		{
			pattern = {"^battlepet:"},
			key = "CHAT_TOOLTIP_BATTLEPET",
			show = function(handler, chatFrame, linkData, link)
				local _, speciesID, level, breedQuality, maxHealth, power, speed = strsplit(":", linkData)
				local name = strmatch(link, "%[(.-)%]")
				AnchorTooltip(GameTooltip, chatFrame)
				BattlePetToolTip_Show(tonumber(speciesID), tonumber(level), tonumber(breedQuality), tonumber(maxHealth), tonumber(power), tonumber(speed), name)
				GameTooltip:Hide()
			end,
			hide = function()
				BattlePetTooltip:Hide()
			end
		},
		{
			pattern = {"^battlePetAbil:"},
			key = "CHAT_TOOLTIP_BATTLEPET",
			show = function(handler, chatFrame, linkData, link)
				local _, abilityID, maxHealth, power, speed = strsplit(":", linkData)
				FloatingPetBattleAbility_Show(tonumber(abilityID), tonumber(maxHealth), tonumber(power), tonumber(speed))
				AnchorTooltip(FloatingPetBattleAbilityTooltip, chatFrame)
			end,
			hide = function()
				FloatingPetBattleAbilityTooltip:Hide()
			end
		},
		{
			pattern = {"^garrfollower:"},
			key = "CHAT_TOOLTIP_GARRISON",
			show = function(handler, chatFrame, linkData, link)
				local _, garrisonFollowerID, quality, level, itemLevel, ability1, ability2, ability3, ability4, trait1, trait2, trait3, trait4, spec1 = strsplit(":", linkData)
				if IS_LEGION then
					FloatingGarrisonFollower_Toggle(tonumber(garrisonFollowerID), tonumber(quality), tonumber(level), tonumber(itemLevel), tonumber(spec1), tonumber(ability1), tonumber(ability2), tonumber(ability3), tonumber(ability4), tonumber(trait1), tonumber(trait2), tonumber(trait3), tonumber(trait4))
				else
					FloatingGarrisonFollower_Toggle(tonumber(garrisonFollowerID), tonumber(quality), tonumber(level), tonumber(itemLevel), tonumber(ability1), tonumber(ability2), tonumber(ability3), tonumber(ability4), tonumber(trait1), tonumber(trait2), tonumber(trait3), tonumber(trait4))
				end
				if C_Garrison.GetFollowerTypeByID(garrisonFollowerID) == LE_FOLLOWER_TYPE_SHIPYARD_6_2 then
					AnchorTooltip(FloatingGarrisonShipyardFollowerTooltip, chatFrame)
				else
					AnchorTooltip(FloatingGarrisonFollowerTooltip, chatFrame)
				end
			end,
			hide = function()
				FloatingGarrisonShipyardFollowerTooltip:Hide()
				FloatingGarrisonFollowerTooltip:Hide()
			end
		},
		{
			pattern = {"^garrfollowerability:"},
			key = "CHAT_TOOLTIP_GARRISON",
			show = function(handler, chatFrame, linkData, link)
				local _, garrFollowerAbilityID = strsplit(":", linkData)
				FloatingGarrisonFollowerAbility_Toggle(tonumber(garrFollowerAbilityID))
				AnchorTooltip(FloatingGarrisonFollowerAbilityTooltip, chatFrame)
			end,
			hide = function()
				FloatingGarrisonFollowerAbilityTooltip:Hide()
			end
		},
		{
			pattern = {"^garrmission:"},
			key = "CHAT_TOOLTIP_GARRISON",
			show = function(handler, chatFrame, linkData, link)
				local _, garrMissionID = strsplit(":", linkData)
				FloatingGarrisonMission_Toggle(tonumber(garrMissionID))
				AnchorTooltip(FloatingGarrisonMissionTooltip, chatFrame)
			end,
			hide = function()
				FloatingGarrisonMissionTooltip:Hide()
			end
		},
		{
			pattern = {"^death:"},
			key = "CHAT_TOOLTIP_DEATH",
			show = function(handler, chatFrame, linkData, link)
				local _, id = strsplit(":", linkData)
				local events = DeathRecap_GetEvents(id)
				local text = {}

				if not events or #events <= 0 then
					table.insert(text, DEATH_RECAP_UNAVAILABLE)

				else
					local maxHp = UnitHealthMax("player")
					local highestDmgIdx, highestDmgAmount = 1, 0

					-- iterate events
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
								local environmentalType = evtData.environmentalType
								environmentalType = string.upper(environmentalType)
								spellName = _G["ACTION_ENVIRONMENTAL_DAMAGE_"..environmentalType]
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
								texture = "Interface\\Icons\\"..texture
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
								texture = select(3, GetSpellInfo(spellId))
							end

							spellName = spellString
						end

						local dmgInfo = evtData.DamageInfo

						if not dmgInfo then
							dmgInfo = {}
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
								dmgInfo.dmgExtraStr = dmgInfo.dmgExtraStr.." "..format(TEXT_MODE_A_STRING_RESULT_ABSORB, evtData.absorbed)
								dmgInfo.amount = BreakUpLargeNumbers(evtData.amount - evtData.absorbed)
							end

							if evtData.resisted and evtData.resisted > 0 then
								dmgInfo.dmgExtraStr = dmgInfo.dmgExtraStr.." "..format(TEXT_MODE_A_STRING_RESULT_RESIST, evtData.resisted)
								dmgInfo.amount = BreakUpLargeNumbers(evtData.amount - evtData.resisted)
							end

							if evtData.blocked and evtData.blocked > 0 then
								dmgInfo.dmgExtraStr = dmgInfo.dmgExtraStr.." "..format(TEXT_MODE_A_STRING_RESULT_BLOCK, evtData.blocked)
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

						table.insert(text, evtData)
					end

					-- local evtData = text[highestDmgIdx]
					-- if evtData then
					-- 	evtData.tombstone = true -- evtData == text[1]
					-- end
				end

				-- convert to string
				do
					local temp = ""

					for i = #text, 1, -1 do
						local evtData = text[i]

						temp = temp .. (evtData.tombstone and "|TInterface\\Minimap\\Minimap_skull_normal:0:0|t " or "") .. (evtData.critical and "*" or "") .. evtData.DamageInfo.amountStr .. (evtData.critical and "*" or "") .. " |cffFFFFFF" .. evtData.DamageInfo.spellName .. "|r" .. (evtData.hideCaster and "" or (" |cffFF0000" .. evtData.DamageInfo.caster .. "|r")) .. "\n"
					end

					text = strsub(temp, 0, -2)
				end

				AnchorTooltip(GameTooltip, chatFrame)
				GameTooltip:SetText(text)
				GameTooltip:Show()
			end
		},
		{
			pattern = {"^unit:"},
			-- key = "",
			show = function(handler, chatFrame, linkData, link)
				-- local _, guid, name = strsplit(":", linkData)
				-- local unitType, _, serverID, instanceID, zoneID, npcID, spawnID = strsplit("-", guid)

				AnchorTooltip(GameTooltip, chatFrame)
				GameTooltip:SetHyperlink(link)
				GameTooltip:Show()
			end
		},
		{
			-- TODO:
			---- battlepet
			---- battlePetAbil
			-- BNplayer
			-- channel
			---- death
			---- garrfollower
			---- garrfollowerability
			---- garrmission
			-- GM
			-- GMChat
			---- instancelock
			-- journal
			-- levelup
			-- lfd
			-- lootHistory
			-- player
			-- pvpbgs
			-- shareachieve
			-- shareitem
			-- sharess
			-- talentpane
			-- trade
			-- transmogappearance
			-- transmogillusion
			---- unit
			-- urlIndex
			show = function(handler, chatFrame, linkData, link)
				-- print("HYPERLINK_ENTER", linkData, link:gsub("|", "||"), link, "") -- DEBUG
			end
		},
	}

	function ns.tooltip.HYPERLINK_ENTER(chatFrame, linkData, link)
		for i = 1, #handlers do
			local handler, matched = handlers[i], true

			if handler.pattern then
				matched = false

				for j = 1, #handler.pattern do
					if linkData:match(handler.pattern[j]) then
						matched = true
						break
					end
				end
			end

			if matched then
				if not handler.key or ns.config.bool:read(handler.key) then
					showingHandler = handler

					local show = handler.show or ShowTooltip
					show(handler, chatFrame, linkData, link)
				end

				break
			end
		end
	end

	function ns.tooltip.HYPERLINK_LEAVE(chatFrame)
		if showingHandler then
			if showingHandler.hide then
				showingHandler.hide()
			else
				GameTooltip:Hide()
			end
			showingHandler = nil
		end
	end

	-- hook the frames
	for i = 1, NUM_CHAT_WINDOWS do
		_G["ChatFrame" .. i]:HookScript("OnHyperlinkEnter", ns.tooltip.HYPERLINK_ENTER)
		_G["ChatFrame" .. i]:HookScript("OnHyperlinkLeave", ns.tooltip.HYPERLINK_LEAVE)
	end
end

-- chat hyperlink fix links
do
	local oSetItemRef = SetItemRef

	local function FixHyperlink(link, oldText, newText, quality)
		-- the "link" is always the proper
		-- the "oldText" contains corrupted hyperlink from our addon
		-- the "newText" is a freshly generated link, but it ignores the "link" attributes
		-- the "quality" is an override in case the quality is different than the API generating "newText"

		-- use provided quality color, or from old/new text
		local color = quality or oldText:match("|c([a-fA-F0-9]+)|H") or newText:match("|c([a-fA-F0-9]+)|H")

		-- get content from new/old text
		local text = newText:match("|h(.+)|h") or oldText:match("|h(.+)|h")

		-- create the link
		return "|c" .. color .. "|H" .. link .. "|h" .. text .. "|h|r"
	end

	function SetItemRef(link, text, button, chatFrame, ...)
		if IsModifiedClick("CHATLINK") then
			local linkType, arg1, arg2 = strsplit(":", link)

			if linkType == "garrfollower" then
				text = FixHyperlink(link, text, C_Garrison.GetFollowerLinkByID(arg1), select(4, GetItemQualityColor(arg2)))
			elseif linkType == "currency" then
				text = FixHyperlink(link, text, GetCurrencyLink(arg1))
			end
		end

		return oSetItemRef(link, text, button, chatFrame, ...)
	end
end
