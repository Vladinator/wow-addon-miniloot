local GetCoinText = GetCoinText or C_CurrencyInfo.GetCoinText ---@diagnostic disable-line: deprecated

local addonName = ...
local ns = select(2, ...) ---@class MiniLootNS
ns.core = {}

-- log handling
do
	---@type MiniLootLoggerFrame
	local interval

	---@class MiniLootLoggerSummary
	local summary = {
		count = 0,
		reputation = {},
		honor = {},
		experience = {},
		guildexperience = {},
		followerexperience = {},
		currency = {},
		money = {},
		guildmoney = {},
		loot = {},
		roll = {},
		artifact = {},
	}

	local summaryOrder = {
		"guildexperience",
		"experience",
		"followerexperience",
		"reputation",
		"currency",
		"honor",
		"guildmoney",
		"money",
		"artifact",
		"loot",
		"roll",
	}

	local summarySort
	do
		local function tableIndex(t, v)
			for i = 1, #t do
				if t[i] == v then
					return i
				end
			end
			return math.huge
		end

		local function sortBy1stValue(a, b)
			return a[1] < b[1]
		end

		local function sortBy1stValueLink(a, b)
			return (a[1]:match("%[(.+)%]") or a[1]) < (b[1]:match("%[(.+)%]") or b[1])
		end

		local function sortByKeyOrder(a, b)
			return tableIndex(summaryOrder, a[1]) < tableIndex(summaryOrder, b[1])
		end

		local function sortData(data, func)
			local temp = {}
			for k, v in pairs(data) do
				table.insert(temp, {k, v})
			end
			table.sort(temp, func)
			return temp
		end

		summarySort = {
			firstValue = function(data)
				return sortData(data, sortBy1stValue)
			end,
			firstValueLink = function(data)
				return sortData(data, sortBy1stValueLink)
			end,
			keyOrder = function(data)
				return sortData(data, sortByKeyOrder)
			end
		}
	end

	local function chatOutput(report)
		local temp = type(report) == "table" and table.concat(report, " ") or report

		if type(temp) == "string" and temp ~= "" then
			ns.DEFAULT_CHAT_FRAME:AddMessage(temp, YELLOW_FONT_COLOR.r, YELLOW_FONT_COLOR.g, YELLOW_FONT_COLOR.b)
		end
	end

	local lastRollMessage -- HOTFIX: weird bug where the CHAT_MSG_LOOT fires twice for every message (but the default UI isn't affected by it...)

	local function outputRoll(data)
		local temp -- do we wish to return anything for later report use?

		if data.decision then
			if data.pass then
				if data.everyone then
					-- data.history
					-- data.item
					chatOutput(format(ns.locale.ITEM_ROLL_PASS_EVERYONE, ns.util:toLootIcon(data.item, true)))

				else
					-- data.history
					-- data.target
					-- data.item
					chatOutput(format(ns.locale.ITEM_ROLL_PASS, ns.util:toLootIcon(data.item, true), ns.util:toTarget(data.target or YOU)))
				end

			elseif data.disenchant then
				-- data.history
				-- data.target
				-- data.item
				chatOutput(format(ns.locale.ITEM_ROLL_DE, ns.util:toLootIcon(data.item, true), ns.util:toTarget(data.target or YOU)))

			elseif data.greed then
				-- data.history
				-- data.target
				-- data.item
				chatOutput(format(ns.locale.ITEM_ROLL_GREED, ns.util:toLootIcon(data.item, true), ns.util:toTarget(data.target or YOU)))

			elseif data.need then
				-- data.history
				-- data.target
				-- data.item
				chatOutput(format(ns.locale.ITEM_ROLL_NEED, ns.util:toLootIcon(data.item, true), ns.util:toTarget(data.target or YOU)))
			end

		elseif data.rolled then
			if data.disenchant then
				-- data.number
				-- data.item
				-- data.target
				-- print(format("%s: %s Disenchant rolling for %d", ns.util:toLootIcon(data.item, true), ns.util:toTarget(data.target or YOU), data.number))

			elseif data.greed then
				-- data.number
				-- data.item
				-- data.target
				-- print(format("%s: %s Greed rolling for %d", ns.util:toLootIcon(data.item, true), ns.util:toTarget(data.target or YOU), data.number))

			elseif data.need then
				-- data.number
				-- data.item
				-- data.target
				-- print(format("%s: %s Need rolling for %d", ns.util:toLootIcon(data.item, true), ns.util:toTarget(data.target or YOU), data.number))
			end

		elseif data.result then
			if data.lost then
				-- data.history
				-- data.type
				-- data.number
				-- data.item
				chatOutput(format(ns.locale.ITEM_ROLL_LOST, ns.util:toLootIcon(data.item, true), ns.util:toTarget(data.target or YOU), data.type, data.number))

			elseif data.ineligible then
				-- data.target
				-- data.item
				chatOutput(format(ns.locale.ITEM_ROLL_INELIGIBLE, ns.util:toLootIcon(data.item, true), ns.util:toTarget(data.target or YOU)))

			elseif data.disenchanted then
				-- data.item
				-- data.target
				chatOutput(format(ns.locale.ITEM_ROLL_DE_BY, ns.util:toLootIcon(data.item, true), ns.util:toTarget(data.target or YOU)))

			elseif data.disenchant then
				-- data.history
				-- data.number
				-- data.target
				-- data.item
				chatOutput(format(ns.locale.ITEM_ROLL_DE_RESULT, ns.util:toLootIcon(data.item, true), ns.util:toTarget(data.target or YOU), data.number))

			elseif data.greed then
				-- data.history
				-- data.number
				-- data.target
				-- data.item
				chatOutput(format(ns.locale.ITEM_ROLL_GREED_RESULT, ns.util:toLootIcon(data.item, true), ns.util:toTarget(data.target or YOU), data.number))

			elseif data.need then
				-- data.history
				-- data.number
				-- data.target
				-- data.item
				chatOutput(format(ns.locale.ITEM_ROLL_NEED_RESULT, ns.util:toLootIcon(data.item, true), ns.util:toTarget(data.target or YOU), data.number))

			elseif data.started then -- TODO: matches wrong string
				-- data.history
				-- data.item
				-- print(format("%s: |HlootHistory:%d|hRolling...|h", ns.util:toLootIcon(data.item, true), data.history))

			elseif data.winner then
				-- data.target
				-- data.item
				chatOutput(format(ns.locale.ITEM_ROLL_WON, ns.util:toLootIcon(data.item, true), ns.util:toTarget(data.target or YOU)))
			end
		end

		return temp
	end

	---@class MiniLootLoggerTemp
	---@field public value? any[]

	-- parse the various events
	function ns.core:PARSE_CHAT(event, text)
		if self ~= ns.DEFAULT_CHAT_FRAME then
			return false
		end

		local data, silenced = ns.util:parse(text, event)
		local temp ---@type MiniLootLoggerTemp?

		-- should we buypass the filter and do nothing?
		if not data and silenced then
			return false
		end

		-- should we filter and ignore the message?
		if data and data.ignore then
			return true
		end

		-- prepare the data
		if data then
			temp = {} ---@class MiniLootLoggerTemp

			if data.reputation then
				temp.key = "reputation"

				if data.value then
					if data.loss then
						temp.value = { data.value * -1, data.faction }
					else
						temp.value = { data.value, data.faction }
					end
				end

			elseif data.honor then
				temp.key = "honor"

				if data.value then
					temp.value = { data.value, data.target }
				end

			elseif data.experience then
				temp.key = "experience"

				if data.value then
					if data.guild then
						temp.key = "guildexperience"
						temp.value = { data.value }
					elseif data.follower then
						temp.key = "followerexperience"
						temp.value = { data.value, data.target }
					elseif data.loss then
						temp.value = { data.value * -1 }
					else
						temp.value = { data.value }
					end
				end

			elseif data.currency then
				temp.key = "currency"

				if data.item then
					temp.value = { data.item, data.count or 1 }
				end

			elseif data.money then
				temp.key = "money"

				if data.value then
					if data.guild then
						temp.key = "guildmoney"
						temp.value = { data.value }
					else
						temp.value = { data.value, data.target }
					end
				end

			elseif data.loot then
				temp.key = "loot"

				if data.roll then

					-- HOTFIX: weird bug where the CHAT_MSG_LOOT fires twice for every message (but the default UI isn't affected by it...)
					if lastRollMessage == text then return true else lastRollMessage = text end

					temp.key = "roll"
					temp.value = outputRoll(data)

					-- DEBUG
					-- local rolldebug = ns.config:read("rolldebug", {}, true)
					-- table.insert(rolldebug, { event = event, text = text, data = data })

				else

					if IsInRaid() and ns.config.bool:read("ITEM_PRINT_DEFAULT_RAID") then
						temp.value = nil
					else
						temp.value = { data.item, data.count or 1, data.target }
					end

				end

			elseif data.artifact then
				temp.key = "artifact"

				if data.item then
					temp.value = { data.item, data.power }
				end
			end
		end

		-- store in the report table
		if temp and temp.key and temp.value then
			summary.count = summary.count + 1
			local collection = summary[temp.key] ---@type any
			table.insert(collection, temp.value)
			interval:Check()
			return true

		--elseif event ~= "CHAT_MSG_SYSTEM" and (not temp or temp.key ~= "roll") then -- DEBUG: AVOID FLOOD!
		--	print("PARSE_CHAT", event, text, data, "") -- DEBUG
		end

		-- filter is ignored and default behavior ensues
		return false
	end

	-- need this to read how much money we received from a quest (not experience, otherwise we get duplicate values parsed from the PARSE_CHAT handler)
	function ns.core:QUEST_COMPLETE(event, questID, experience, money)
		if self ~= ns.DEFAULT_CHAT_FRAME then
			return false
		end

		if experience and experience > 0 then
			-- ns.core.PARSE_CHAT(self, "CHAT_MSG_COMBAT_XP_GAIN", format(COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED, experience))
		end

		if money and money > 0 then
			ns.core.PARSE_CHAT(self, "CHAT_MSG_MONEY", format(YOU_LOOT_MONEY, GetCoinText(money)))
		end
	end

	-- report intervals
	do
		local elapsed = 0
		interval = CreateFrame("Frame") ---@class MiniLootLoggerFrame : Frame

		function interval:Tick()
			local playerName = UnitName("player") or YOU or "You"
			local guildName = GetGuildInfo("player") or GUILD or "Guild"
			local playerKey, hasPlayerName, hasOtherPlayerNames = "_", nil, nil
			local playerNameSeparator = ":"
			local prefixWithPlayerNames = ns.config.bool:read("ITEM_SELF_PREFIX")

			local report = { sorted = {}, grouped = {} }

			local tempReport = {}
			local tempLine

			for i = 1, #summaryOrder do
				local key = summaryOrder[i]
				local entries = summary[key] ---@type any

				for j = 1, #entries do
					local entry = entries[j]

					if key == "reputation" then

						local rawFaction = entry[2]
						tempReport[key] = tempReport[key] or {}
						tempReport[key][rawFaction] = tempReport[key][rawFaction] or 0
						tempReport[key][rawFaction] = tempReport[key][rawFaction] + entry[1]

					elseif key == "honor" then

						local rawTarget = entry[2] or playerKey
						tempReport[key] = tempReport[key] or {}
						tempReport[key][rawTarget] = tempReport[key][rawTarget] or 0
						tempReport[key][rawTarget] = tempReport[key][rawTarget] + entry[1]

					elseif key == "experience" then

						tempReport[key] = tempReport[key] or 0
						tempReport[key] = tempReport[key] + entry[1]

					elseif key == "guildexperience" then

						tempReport[key] = tempReport[key] or 0
						tempReport[key] = tempReport[key] + entry[1]

					elseif key == "followerexperience" then

						local rawTarget = entry[2]
						tempReport[key] = tempReport[key] or {}
						tempReport[key][rawTarget] = tempReport[key][rawTarget] or 0
						tempReport[key][rawTarget] = tempReport[key][rawTarget] + entry[1]

					elseif key == "currency" then

						local rawItem = entry[1]
						tempReport[key] = tempReport[key] or {}
						tempReport[key][rawItem] = tempReport[key][rawItem] or 0
						tempReport[key][rawItem] = tempReport[key][rawItem] + entry[2]

					elseif key == "money" then

						local rawTarget = entry[2] or playerKey
						tempReport[key] = tempReport[key] or {}
						tempReport[key][rawTarget] = tempReport[key][rawTarget] or 0
						tempReport[key][rawTarget] = tempReport[key][rawTarget] + entry[1]

					elseif key == "guildmoney" then

						tempReport[key] = tempReport[key] or {}
						tempReport[key][guildName] = tempReport[key][guildName] or 0
						tempReport[key][guildName] = tempReport[key][guildName] + entry[1]

					elseif key == "loot" then

						local rawItem = entry[1]
						local rawTarget = entry[3] or playerKey
						tempReport[key] = tempReport[key] or {}
						tempReport[key][rawTarget] = tempReport[key][rawTarget] or {}
						tempReport[key][rawTarget][rawItem] = tempReport[key][rawTarget][rawItem] or 0
						tempReport[key][rawTarget][rawItem] = tempReport[key][rawTarget][rawItem] + entry[2]

					elseif key == "roll" then

						-- TODO: OBSCOLETE?

					elseif key == "artifact" then

						local rawItem = entry[1]
						tempReport[key] = tempReport[key] or {}
						tempReport[key][rawItem] = tempReport[key][rawItem] or 0
						tempReport[key][rawItem] = tempReport[key][rawItem] + entry[2]

					end

				end

				table.wipe(entries)
			end

			for i = 1, #summaryOrder do
				local key = summaryOrder[i]
				local tempData = tempReport[key]

				if tempData then
					if key == "reputation" then
						hasPlayerName = true -- this can only be the player
						local sorted = summarySort.firstValue(tempData)
						for j = 1, #sorted do
							local faction, value = sorted[j][1], sorted[j][2]
							if value ~= 0 then
								tempLine = ns.util:toFaction(faction) .. ns.util:toNumber(value, true, true)
								table.insert(report.sorted, tempLine)
							end
						end

					elseif key == "honor" then
						hasPlayerName = true -- this can only be the player
						local sorted = summarySort.firstValue(tempData)
						for j = 1, #sorted do
							local target, value = sorted[j][1], sorted[j][2]
							if value ~= 0 then
								-- local isPlayer = target == playerKey
								-- target = isPlayer and "" or ns.util:toTarget(target)
								tempLine = HONOR .. ns.util:toNumber(value, true, true) -- TODO: target names?
								table.insert(report.sorted, tempLine)
							end
						end

					elseif key == "experience" then
						if tempData ~= 0 then
							hasPlayerName = true -- this can only be the player
							tempLine = XP .. ns.util:toNumber(tempData, true, true)
							table.insert(report.sorted, tempLine)
						end

					elseif key == "guildexperience" then
						if tempData ~= 0 then
							hasPlayerName = true -- this can only be the player
							tempLine = GUILD .. XP .. ns.util:toNumber(tempData, true, true)
							table.insert(report.sorted, tempLine)
						end

					elseif key == "followerexperience" then
						hasPlayerName = true -- this can only be the player
						local sorted = summarySort.firstValue(tempData)
						for j = 1, #sorted do
							local target, value = sorted[j][1], sorted[j][2]
							if value ~= 0 then
								tempLine = ns.util:toLootIcon(target, true) .. ns.util:toNumber(value, true, true)
								table.insert(report.sorted, tempLine)
							end
						end

					elseif key == "currency" then
						hasPlayerName = true -- this can only be the player
						local sorted = summarySort.firstValueLink(tempData)
						for j = 1, #sorted do
							local item, count = sorted[j][1], sorted[j][2]
							tempLine = ns.util:toLootIcon(item, true) .. ns.util:toItemCount(count)
							-- add the item count if the user wishes to see that
							if ns.config.bool:read("ITEM_COUNT_BAGS") then
								local tempCount, atMax = ns.util:getNumCurrency(item)
								if tempCount > 1 then
									tempCount = FormatLargeNumber(tempCount) -- Util.lua:215
									tempLine = tempLine .. "|cff" .. (atMax and "FF6666" or "999999") .. "(" .. tempCount .. ")|r"
								end
							end
							table.insert(report.sorted, tempLine)
						end

					elseif key == "money" then
						local sorted = summarySort.firstValue(tempData)
						for j = 1, #sorted do
							local target, copper = sorted[j][1], sorted[j][2]
							local isPlayer = target == playerKey
							target = isPlayer and "" or ns.util:toTarget(target)
							tempLine = ns.util:toMoney(copper)
							if isPlayer then
								hasPlayerName = true
								table.insert(report.sorted, tempLine)
							else
								hasOtherPlayerNames = true
								table.insert(report.grouped, { target, key, tempLine })
							end
						end

					elseif key == "guildmoney" then
						hasPlayerName = true -- this can only be the player
						local sorted = summarySort.firstValue(tempData)
						for j = 1, #sorted do
							local guild, copper = sorted[j][1], sorted[j][2]
							tempLine = guild .. " " .. ns.util:toMoney(copper)
							table.insert(report.sorted, tempLine)
						end

					elseif key == "loot" then
						local sorted = summarySort.firstValue(tempData)
						for j = 1, #sorted do
							local target, items = sorted[j][1], sorted[j][2]
							local isPlayer = target == playerKey
							target = isPlayer and "" or ns.util:toTarget(target)
							local playerTemp = {}
							local subSorted = summarySort.firstValueLink(items)

							-- scan the items looted by the player
							for k = 1, #subSorted do
								local item, count = subSorted[k][1], subSorted[k][2]

								-- we need to do this so we don't go insane with errors
								if ns.util:isItemAnimaPower(item) then

									-- prepare the item link
									local tempItem

									-- default coloring
									tempItem = ns.util:toLootIcon(item, true, nil, nil, nil, isPlayer and "player" or sorted[j][1])

									-- insert into the item table for this player
									table.insert(playerTemp, tempItem)

								else

									-- stage one: if we don't wish to show junk items, drop parsing any further
									if not ns.config.bool:read("ITEM_HIDE_JUNK") or not ns.util:isItemJunk(item) then

										-- is this a quest related item?
										local questItem = ns.util:isItemQuest(item) or ns.util:isItemQuestStarting(item)

										-- does it have an uncollected appearance?
										local uncollectedItem = ns.config.bool:read("ITEM_ALERT_TRANSMOG") and (isPlayer or ns.config.bool:read("ITEM_ALERT_TRANSMOG_EVERYTHING")) and ns.util:isItemAppearanceUncollected(item)

										-- pick what quality threshold we should use for this item
										local withinQualityThreshold = true

										-- only if the previous checks fail
										if not questItem and not uncollectedItem then
											local quality = 0 -- Poor

											if IsInRaid() then
												quality = ns.config:read("ITEM_QUALITY_RAID", quality)
											elseif IsInGroup() then
												quality = ns.config:read("ITEM_QUALITY_GROUP", quality)
											else
												quality = ns.config:read("ITEM_QUALITY_PLAYER", quality)
											end

											withinQualityThreshold = ns.util:isItemQuality(item, quality, "ge", true)
										end

										-- stage two: is this item quality meeting our minimum criteria?
										if questItem or uncollectedItem or withinQualityThreshold then

											-- prepare the item link
											local tempItem

											if uncollectedItem then
												-- pink brackets and curly brackets to highlight the importance
												tempItem = "|cffFF80FF{|r" .. ns.util:toLootIcon(item, true, false, "ffFF80FF", true) .. "|cffFF80FF}|r" .. ns.util:toItemCount(count)

											elseif questItem then
												-- red brackets
												tempItem = ns.util:toLootIcon(item, true, false, "ffFF0000", true) .. ns.util:toItemCount(count)

											else
												-- default coloring
												tempItem = ns.util:toLootIcon(item, true, nil, nil, true) .. ns.util:toItemCount(count)
											end

											-- add item count to player items
											if isPlayer and ns.config.bool:read("ITEM_COUNT_BAGS") then
												local tempCount = ns.util:getNumItems(item, ns.config.bool:read("ITEM_COUNT_BAGS_INCLUDE_BANK"), ns.config.bool:read("ITEM_COUNT_BAGS_INCLUDE_CHARGES"))
												if tempCount > 1 then
													tempCount = FormatLargeNumber(tempCount) -- Util.lua:215
													tempItem = tempItem .. "|cff999999(" .. tempCount .. ")|r"
												end
											end

											-- insert into the item table for this player
											table.insert(playerTemp, tempItem)
										end

									end

								end

							end

							-- if we have data, concat and push into the report
							if playerTemp[1] then
								tempLine = table.concat(playerTemp, " ")
								if isPlayer then
									hasPlayerName = true
									table.insert(report.sorted, tempLine)
								else
									hasOtherPlayerNames = true
									table.insert(report.grouped, { target, key, tempLine })
								end
							end
						end

					elseif key == "artifact" then
						hasPlayerName = true -- this can only be the player
						local sorted = summarySort.firstValueLink(tempData)
						for j = 1, #sorted do
							local item, power = sorted[j][1], sorted[j][2]
							if power ~= 0 then
								local currentXP, maxXP, numPoints = ns.util:getArtifactInfo()
								tempLine = ns.util:toLootIcon(item, true) .. ns.util:toNumber(power, true, true)
								if numPoints and numPoints > 0 then
									tempLine = tempLine .. "|cff999999(" .. numPoints .. ")|r"
								end
								table.insert(report.sorted, tempLine)
							end
						end
					end
				end
			end

			local lines = {}

			-- sanity check: make sure there is something to report before populating the lines table
			if report.sorted[1] or report.grouped[1] then

				-- hides our own name if we are soloing content and there is no one else that can receive things
				if hasPlayerName and not hasOtherPlayerNames and GetNumGroupMembers() <= (IsInRaid() and 1 or 0) and ns.config.bool:read("ITEM_SELF_TRIM_SOLO") then
					hasPlayerName = nil
				end

				-- prepend our name in front of our own messages
				if hasPlayerName and prefixWithPlayerNames then
					local addPlayerName = ns.config.bool:read("ITEM_SELF_PREFIX_NAME") and playerName

					if not addPlayerName or addPlayerName == "" then
						addPlayerName = YOU
					end

					table.insert(lines, addPlayerName .. playerNameSeparator)
				end

				-- append the sorted lines
				for i = 1, #report.sorted do
					table.insert(lines, report.sorted[i])
				end

				-- append the grouped lines
				do
					local temp = {}

					for i = 1, #report.grouped do
						local entry = report.grouped[i]
						local name, key, line = entry[1], entry[2], entry[3]

						temp[name] = temp[name] or {}
						temp[name][key] = temp[name][key] or {}
						table.insert(temp[name][key], line)
					end

					local sorted = summarySort.firstValue(temp)

					for i = 1, #sorted do
						local name, entries = sorted[i][1], sorted[i][2]
						tempLine = { name }

						-- prepend the other players loot with their own name
						if prefixWithPlayerNames then
							tempLine[1] = tempLine[1] .. playerNameSeparator
						end

						entries = summarySort.keyOrder(entries)
						for j = 1, #entries do
							local subEntries = entries[j][2]

							for k = 1, #subEntries do
								table.insert(tempLine, subEntries[k])
							end
						end

						if tempLine[2] then
							table.insert(lines, table.concat(tempLine, " "))
						end
					end
				end
			end

			-- if not DevTools_Dump then LoadAddOn("Blizzard_DebugTools") end if DevTools_Dump then DevTools_Dump({report}) end -- DEBUG
			-- if not DevTools_Dump then LoadAddOn("Blizzard_DebugTools") end if DevTools_Dump then DevTools_Dump({lines}) end -- DEBUG

			summary.count = 0
			interval:Check()

			chatOutput(lines)
			table.wipe(lines)
		end

		function interval:SafeTick()
			local success, err = pcall(interval.Tick, interval)

			if not success then
				print(format(ns.locale.PARSER_FATAL_ERROR, addonName, err))

				for i = 1, #summaryOrder do
					local key = summaryOrder[i]
					local collection = summary[key] ---@type any
					table.wipe(collection)
				end

				summary.count = 0
			end
		end

		function interval:OnUpdate(e)
			elapsed = elapsed + e

			if elapsed > ns.config:read("REPORT_INTERVAL", 2) and (ns.config.bool:read("REPORT_IN_COMBAT") or not InCombatLockdown()) then
				elapsed = 0

				interval:SafeTick()
			end
		end

		function interval:Check()
			if summary.count > 0 then
				interval:SetScript("OnUpdate", interval.OnUpdate)
				interval:Show()
			else
				interval:Hide()
				elapsed = 0
			end
		end
	end
end

-- enable and disable the addon
do
	function ns.core:on()
		-- register events
		ns.events:on("QUEST_TURNED_IN", ns.core.QUEST_COMPLETE)

		-- register filters
		ns.events.filters:on("CHAT_MSG_COMBAT_XP_GAIN", ns.core.PARSE_CHAT)
		ns.events.filters:on("CHAT_MSG_COMBAT_GUILD_XP_GAIN", ns.core.PARSE_CHAT)
		ns.events.filters:on("CHAT_MSG_COMBAT_FACTION_CHANGE", ns.core.PARSE_CHAT)
		ns.events.filters:on("CHAT_MSG_COMBAT_HONOR_GAIN", ns.core.PARSE_CHAT)
		ns.events.filters:on("CHAT_MSG_MONEY", ns.core.PARSE_CHAT)
		ns.events.filters:on("CHAT_MSG_CURRENCY", ns.core.PARSE_CHAT)
		ns.events.filters:on("CHAT_MSG_LOOT", ns.core.PARSE_CHAT)
		ns.events.filters:on("CHAT_MSG_SYSTEM", ns.core.PARSE_CHAT)
	end

	function ns.core:off()
		-- unregister events
		ns.events:off("QUEST_TURNED_IN", ns.core.QUEST_COMPLETE)

		-- unregister filters
		ns.events.filters:off("CHAT_MSG_COMBAT_XP_GAIN", ns.core.PARSE_CHAT)
		ns.events.filters:off("CHAT_MSG_COMBAT_GUILD_XP_GAIN", ns.core.PARSE_CHAT)
		ns.events.filters:off("CHAT_MSG_COMBAT_FACTION_CHANGE", ns.core.PARSE_CHAT)
		ns.events.filters:off("CHAT_MSG_COMBAT_HONOR_GAIN", ns.core.PARSE_CHAT)
		ns.events.filters:off("CHAT_MSG_MONEY", ns.core.PARSE_CHAT)
		ns.events.filters:off("CHAT_MSG_CURRENCY", ns.core.PARSE_CHAT)
		ns.events.filters:off("CHAT_MSG_LOOT", ns.core.PARSE_CHAT)
		ns.events.filters:off("CHAT_MSG_SYSTEM", ns.core.PARSE_CHAT)
	end
end

-- addon load event
local function ADDON_LOADED(self, event, name)
	if addonName == name then
		-- assign default metatable to the saved variables (now that it is loaded)
		ns.config:metatableDefaults()

		-- create the options interface
		ns.options:create()

		-- enable the addon
		ns.core:on()

		-- check if the parser is functioning with the current patterns and locale
		local tests = ns.util:parseTests()
		if tests.failed > 0 then
			print(format(ns.locale.PARSER_OUTDATED_ERROR, addonName, tests.success, tests.total, tests.failed))
		end

		-- DEBUG:
		-- /dump MLTR
		-- /run print(MLTR.log[1]and"Locale: "..GetLocale().." - Failed tests:"or"")for _,t in ipairs(MLTR.log)do if not t.skipped and not t.success then print((t.input:gsub("\124","\124\124")))end end
		-- /run local M=MLTR for _,t in ipairs(M.log)do if not t.skipped and not t.success and t.expected then M.T={event=t.event,input=t.input,output=t.output[1],expected=t.expected}SlashCmdList.DUMP("MLTR.T")if false then break end M.T=nil end end
		-- _G.MLTR = tests
	end
end

-- load the addon and modules
ns.events:on("ADDON_LOADED", ADDON_LOADED)
