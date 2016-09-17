local addonName, ns = ...
ns.util = {}

-- parse system messages
do
	local token = {
		NONE = 0,
		PLAYER = 1,
		TARGET = 2,
		STRING = 3,
		NUMBER = 4,
		FLOAT = 5,
		MONEY = 6
	}

	local categories = {
		-- reputation
		-- { reputation[, faction[, value]] }
		{
			group = "REPUTATION",
			events = {
				"CHAT_MSG_COMBAT_FACTION_CHANGE",
			},
			formats = {
				{ FACTION_STANDING_INCREASED_DOUBLE_BONUS,     token.STRING,    token.NUMBER,    token.FLOAT,     token.FLOAT                   }, -- "Reputation with %s increased by %d. (+%.1f Recruit A Friend bonus) (+%.1f bonus)"
				{ FACTION_STANDING_INCREASED_BONUS,            token.STRING,    token.NUMBER,    token.FLOAT                                    }, -- "Reputation with %s increased by %d. (+%.1f Recruit A Friend bonus)"
				{ FACTION_STANDING_INCREASED_ACH_BONUS,        token.STRING,    token.NUMBER,    token.FLOAT                                    }, -- "Reputation with %s increased by %d. (+%.1f bonus)"
				{ FACTION_STANDING_INCREASED,                  token.STRING,    token.NUMBER                                                    }, -- "Reputation with %s increased by %d."
				{ FACTION_STANDING_INCREASED_GENERIC,          token.STRING                                                                     }, -- "Reputation with %s increased."
			},
			parse = function(self, tokens, matches)
				local data = { reputation = true }

				if tokens[2] == token.STRING then
					data.faction = matches[2]

					if tokens[3] == token.NUMBER then
						data.value = matches[3]
					end
				end

				return data
			end,
			tests = {
				{ format(FACTION_STANDING_INCREASED_DOUBLE_BONUS, "Factionname", 500, 1.234, 5.678), { reputation = true, faction = "Factionname", value = 500 } },
				{ format(FACTION_STANDING_INCREASED_BONUS, "Factionname", 600, 9.1011), { reputation = true, faction = "Factionname", value = 600 } },
				{ format(FACTION_STANDING_INCREASED_ACH_BONUS, "Factionname", 700, 12.1314), { reputation = true, faction = "Factionname", value = 700 } },
				{ format(FACTION_STANDING_INCREASED, "Factionname", 800), { reputation = true, faction = "Factionname", value = 800 } },
				{ format(FACTION_STANDING_INCREASED_GENERIC, "Factionname"), { reputation = true, faction = "Factionname" } },
			}
		},
		-- reputation (loss)
		-- { reputation, loss[, faction[, value]] }
		{
			group = "REPUTATION",
			events = {
				"CHAT_MSG_COMBAT_FACTION_CHANGE",
			},
			formats = {
				{ FACTION_STANDING_DECREASED,                  token.STRING,    token.NUMBER                                                    }, -- "Reputation with %s decreased by %d."
				{ FACTION_STANDING_DECREASED_GENERIC,          token.STRING                                                                     }, -- "Reputation with %s decreased."
			},
			parse = function(self, tokens, matches)
				local data = { reputation = true, loss = true }

				if tokens[2] == token.STRING then
					data.faction = matches[2]

					if tokens[3] == token.NUMBER then
						data.value = matches[3]
					end
				end

				return data
			end,
			tests = {
				{ format(FACTION_STANDING_DECREASED, "Factionname", 5000), { reputation = true, loss = true, faction = "Factionname", value = 5000 } },
				{ format(FACTION_STANDING_DECREASED_GENERIC, "Factionname"), { reputation = true, loss = true, faction = "Factionname" } },
			}
		},
		-- honor
		-- { honor[, target[, rank[, value]]] }
		{
			group = "HONOR",
			events = {
				"CHAT_MSG_COMBAT_HONOR_GAIN",
			},
			formats = {
				{ COMBATLOG_HONORGAIN,                         token.TARGET,    token.STRING,    token.FLOAT                                    }, -- "%s dies, honorable kill Rank: %s (%.2f Honor Points)"
				{ COMBATLOG_HONORGAIN_NO_RANK,                 token.TARGET,    token.FLOAT                                                     }, -- "%s dies, honorable kill (%.2f Honor Points)"
				{ COMBATLOG_HONORAWARD,                        token.FLOAT                                                                      }, -- "You have been awarded %.2f honor points."
			},
			parse = function(self, tokens, matches)
				local data = { honor = true }

				if tokens[2] == token.TARGET then
					data.target = matches[2]

					if tokens[3] == token.STRING then
						data.rank = matches[3]

						if tokens[4] == token.FLOAT then
							data.value = matches[4]
						end

					elseif tokens[3] == token.FLOAT then
						data.value = matches[3]
					end

				elseif tokens[2] == token.FLOAT then
					data.value = matches[2]
				end

				return data
			end,
			tests = {
				{ format(COMBATLOG_HONORGAIN, "Targetname", "Grand Marshal", 1.234), { honor = true, target = "Targetname", rank = "Grand Marshal", value = 1 } },
				{ format(COMBATLOG_HONORGAIN_NO_RANK, "Targetname", 5.678), { honor = true, target = "Targetname", value = 5 } },
				{ format(COMBATLOG_HONORAWARD, 9.1011), { honor = true, value = 9 } },
			}
		},
		-- experience
		-- { experience[, value[, target[, zone]]] }
		{
			group = "EXPERIENCE",
			events = {
				"CHAT_MSG_SYSTEM",
				"CHAT_MSG_COMBAT_XP_GAIN",
			},
			formats = {
				{ ERR_ZONE_EXPLORED_XP,                        token.STRING,    token.NUMBER                                                    }, -- "Discovered %s: %d experience gained"
				{ COMBATLOG_XPGAIN_EXHAUSTION1_RAID,           token.TARGET,    token.NUMBER,    token.STRING,    token.STRING,    token.NUMBER }, -- "%s dies, you gain %d experience. (%s exp %s bonus, -%d raid penalty)"
				{ COMBATLOG_XPGAIN_EXHAUSTION1_GROUP,          token.TARGET,    token.NUMBER,    token.STRING,    token.STRING,    token.NUMBER }, -- "%s dies, you gain %d experience. (%s exp %s bonus, +%d group bonus)"
				{ COMBATLOG_XPGAIN_EXHAUSTION1,                token.TARGET,    token.NUMBER,    token.STRING,    token.STRING                  }, -- "%s dies, you gain %d experience. (%s exp %s bonus)"
				{ COMBATLOG_XPGAIN_EXHAUSTION2_RAID,           token.TARGET,    token.NUMBER,    token.STRING,    token.STRING,    token.NUMBER }, -- "%s dies, you gain %d experience. (%s exp %s bonus, -%d raid penalty)"
				{ COMBATLOG_XPGAIN_EXHAUSTION2_GROUP,          token.TARGET,    token.NUMBER,    token.STRING,    token.STRING,    token.NUMBER }, -- "%s dies, you gain %d experience. (%s exp %s bonus, +%d group bonus)"
				{ COMBATLOG_XPGAIN_EXHAUSTION2,                token.TARGET,    token.NUMBER,    token.STRING,    token.STRING                  }, -- "%s dies, you gain %d experience. (%s exp %s bonus)"
				{ COMBATLOG_XPGAIN_EXHAUSTION4_RAID,           token.TARGET,    token.NUMBER,    token.STRING,    token.STRING,    token.NUMBER }, -- "%s dies, you gain %d experience. (%s exp %s penalty, -%d raid penalty)"
				{ COMBATLOG_XPGAIN_EXHAUSTION4_GROUP,          token.TARGET,    token.NUMBER,    token.STRING,    token.STRING,    token.NUMBER }, -- "%s dies, you gain %d experience. (%s exp %s penalty, +%d group bonus)"
				{ COMBATLOG_XPGAIN_EXHAUSTION4,                token.TARGET,    token.NUMBER,    token.STRING,    token.STRING                  }, -- "%s dies, you gain %d experience. (%s exp %s penalty)"
				{ COMBATLOG_XPGAIN_EXHAUSTION5_RAID,           token.TARGET,    token.NUMBER,    token.STRING,    token.STRING,    token.NUMBER }, -- "%s dies, you gain %d experience. (%s exp %s penalty, -%d raid penalty)"
				{ COMBATLOG_XPGAIN_EXHAUSTION5_GROUP,          token.TARGET,    token.NUMBER,    token.STRING,    token.STRING,    token.NUMBER }, -- "%s dies, you gain %d experience. (%s exp %s penalty, +%d group bonus)"
				{ COMBATLOG_XPGAIN_EXHAUSTION5,                token.TARGET,    token.NUMBER,    token.STRING,    token.STRING                  }, -- "%s dies, you gain %d experience. (%s exp %s penalty)"
				{ COMBATLOG_XPGAIN_FIRSTPERSON_RAID,           token.TARGET,    token.NUMBER,    token.NUMBER                                   }, -- "%s dies, you gain %d experience. (-%d raid penalty)"
				{ COMBATLOG_XPGAIN_FIRSTPERSON_GROUP,          token.TARGET,    token.NUMBER,    token.NUMBER                                   }, -- "%s dies, you gain %d experience. (+%d group bonus)"
				{ COMBATLOG_XPGAIN_FIRSTPERSON,                token.TARGET,    token.NUMBER                                                    }, -- "%s dies, you gain %d experience."
				{ COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED_RAID,   token.NUMBER,    token.NUMBER                                                    }, -- "You gain %d experience. (-%d raid penalty)"
				{ COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED_GROUP,  token.NUMBER,    token.NUMBER                                                    }, -- "You gain %d experience. (+%d group bonus)"
				{ COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED,        token.NUMBER                                                                     }, -- "You gain %d experience."
				{ COMBATLOG_XPGAIN_QUEST,                      token.NUMBER,    token.STRING,    token.STRING                                   }, -- "You gain %d experience. (%s exp %s bonus)"
			},
			parse = function(self, tokens, matches)
				local data = { experience = true }

				if tokens[2] == token.STRING then
					data.zone = matches[2]

					if tokens[3] == token.NUMBER then
						data.value = matches[3]
					end

				elseif tokens[2] == token.TARGET then
					data.target = matches[2]

					if tokens[3] == token.NUMBER then
						data.value = matches[3]
					end

				elseif tokens[2] == token.NUMBER then
					data.value = matches[2]
				end

				return data
			end,
			tests = {
				{ format(ERR_ZONE_EXPLORED_XP, "Zonename", 10001), { experience = true, zone = "Zonename", value = 10001 } },
				{ format(COMBATLOG_XPGAIN_EXHAUSTION1_RAID, "Targetname", 10002, "EXP?", "BONUS?", 0), { experience = true, target = "Targetname", value = 10002 } },
				{ format(COMBATLOG_XPGAIN_EXHAUSTION1_GROUP, "Targetname", 10003, "EXP?", "BONUS?", 0), { experience = true, target = "Targetname", value = 10003 } },
				{ format(COMBATLOG_XPGAIN_EXHAUSTION1, "Targetname", 10004, "EXP?", "BONUS?"), { experience = true, target = "Targetname", value = 10004 } },
				{ format(COMBATLOG_XPGAIN_EXHAUSTION2_RAID, "Targetname", 10005, "EXP?", "BONUS?", 0), { experience = true, target = "Targetname", value = 10005 } },
				{ format(COMBATLOG_XPGAIN_EXHAUSTION2_GROUP, "Targetname", 10006, "EXP?", "BONUS?", 0), { experience = true, target = "Targetname", value = 10006 } },
				{ format(COMBATLOG_XPGAIN_EXHAUSTION2, "Targetname", 10007, "EXP?", "BONUS?"), { experience = true, target = "Targetname", value = 10007 } },
				{ format(COMBATLOG_XPGAIN_EXHAUSTION4_RAID, "Targetname", 10008, "EXP?", "BONUS?", 0), { experience = true, target = "Targetname", value = 10008 } },
				{ format(COMBATLOG_XPGAIN_EXHAUSTION4_GROUP, "Targetname", 10009, "EXP?", "BONUS?", 0), { experience = true, target = "Targetname", value = 10009 } },
				{ format(COMBATLOG_XPGAIN_EXHAUSTION4, "Targetname", 10010, "EXP?", "BONUS?"), { experience = true, target = "Targetname", value = 10010 } },
				{ format(COMBATLOG_XPGAIN_EXHAUSTION5_RAID, "Targetname", 10011, "EXP?", "BONUS?", 0), { experience = true, target = "Targetname", value = 10011 } },
				{ format(COMBATLOG_XPGAIN_EXHAUSTION5_GROUP, "Targetname", 10012, "EXP?", "BONUS?", 0), { experience = true, target = "Targetname", value = 10012 } },
				{ format(COMBATLOG_XPGAIN_EXHAUSTION5, "Targetname", 10013, "EXP?", "BONUS?"), { experience = true, target = "Targetname", value = 10013 } },
				{ format(COMBATLOG_XPGAIN_FIRSTPERSON_RAID, "Targetname", 10014, 0), { experience = true, target = "Targetname", value = 10014 } },
				{ format(COMBATLOG_XPGAIN_FIRSTPERSON_GROUP, "Targetname", 10015, 0), { experience = true, target = "Targetname", value = 10015 } },
				{ format(COMBATLOG_XPGAIN_FIRSTPERSON, "Targetname", 10016), { experience = true, target = "Targetname", value = 10016 } },
				{ format(COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED_RAID, 10017, 0), { experience = true, value = 10017 } },
				{ format(COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED_GROUP, 10018, 0), { experience = true, value = 10018 } },
				{ format(COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED, 10019), { experience = true, value = 10019 } },
				{ format(COMBATLOG_XPGAIN_QUEST, 10020, "EXP?", "BONUS?"), { experience = true, value = 10020 } },
			}
		},
		-- experience (loss)
		-- { experience, loss[, value] }
		{
			group = "EXPERIENCE",
			events = {
				"CHAT_MSG_SYSTEM",
				"CHAT_MSG_COMBAT_XP_GAIN",
			},
			formats = {
				{ COMBATLOG_XPLOSS_FIRSTPERSON_UNNAMED,        token.NUMBER                                                                     }, -- "You lose %d experience."
			},
			parse = function(self, tokens, matches)
				local data = { experience = true, loss = true }

				if tokens[2] == token.NUMBER then
					data.value = matches[2]
				end

				return data
			end,
			tests = {
				{ format(COMBATLOG_XPLOSS_FIRSTPERSON_UNNAMED, 10000), { experience = true, loss = true, value = 10000 } },
			}
		},
		-- experience (guild)
		-- { experience, guild[, value] }
		{
			group = "GUILD_EXPERIENCE",
			events = {
				"CHAT_MSG_COMBAT_GUILD_XP_GAIN",
			},
			formats = {
				{ COMBATLOG_GUILD_XPGAIN,                      token.NUMBER                                                                     }, -- "You gain %d guild experience."
			},
			parse = function(self, tokens, matches)
				local data = { experience = true, guild = true }

				if tokens[2] == token.NUMBER then
					data.value = matches[2]
				end

				return data
			end,
			tests = {
				{ format(COMBATLOG_GUILD_XPGAIN, 10000), { experience = true, guild = true, value = 10000 } },
			}
		},
		-- experience (followers)
		-- { experience, follower[, target[, value]] }
		{
			group = "FOLLOWER_EXPERIENCE",
			events = {
				"CHAT_MSG_SYSTEM",
				"CHAT_MSG_COMBAT_XP_GAIN",
			},
			formats = {
				{ GARRISON_FOLLOWER_XP_ADDED_ZONE_SUPPORT,     token.TARGET,    token.NUMBER                                                    }, -- "%s has earned %d xp."
			},
			parse = function(self, tokens, matches)
				local data = { experience = true, follower = true }

				if tokens[2] == token.TARGET then
					data.target = matches[2]

					if tokens[3] == token.NUMBER then
						data.value = matches[3]
					end
				end

				return data
			end,
			tests = {
				{ format(GARRISON_FOLLOWER_XP_ADDED_ZONE_SUPPORT, "Follower", 500), { experience = true, follower = true, target = "Follower", value = 500 } },
			}
		},
		-- currency
		-- { currency[, item[, count]] }
		{
			group = "CURRENCY",
			events = {
				"CHAT_MSG_CURRENCY",
			},
			formats = {
				{ CURRENCY_GAINED_MULTIPLE_BONUS,              token.STRING,    token.NUMBER                                                    }, -- "You receive currency: %s x%d. (Bonus Objective)"
				{ CURRENCY_GAINED_MULTIPLE,                    token.STRING,    token.NUMBER                                                    }, -- "You receive currency: %s x%d."
				{ CURRENCY_GAINED,                             token.STRING                                                                     }, -- "You receive currency: %s."
				{ LOOT_CURRENCY_REFUND,                        token.STRING,    token.NUMBER                                                    }, -- "You are refunded: %sx%d."
			},
			parse = function(self, tokens, matches)
				local data = { currency = true }

				if tokens[2] == token.STRING then
					data.item = matches[2]

					if tokens[3] == token.NUMBER then
						data.count = matches[3]
					end
				end

				return data
			end,
			tests = {
				{ format(CURRENCY_GAINED_MULTIPLE_BONUS, "Currencylink", 10), { currency = true, item = "Currencylink", count = 10 } },
				{ format(CURRENCY_GAINED_MULTIPLE, "Currencylink", 20), { currency = true, item = "Currencylink", count = 20 } },
				{ format(CURRENCY_GAINED, "Currencylink"), { currency = true, item = "Currencylink" } },
				{ format(LOOT_CURRENCY_REFUND, "Currencylink", 30), { currency = true, item = "Currencylink", count = 30 } },
			}
		},
		-- money
		-- { money[, value[, guild[, target]]] }
		{
			group = "MONEY",
			events = {
				"CHAT_MSG_MONEY",
			},
			formats = {
				{ YOU_LOOT_MONEY_GUILD,                        token.MONEY,     token.MONEY                                                     }, -- "You loot %s (%s deposited to guild bank)"
				{ YOU_LOOT_MONEY,                              token.MONEY                                                                      }, -- "You loot %s"
				{ LOOT_MONEY_SPLIT_GUILD,                      token.MONEY,     token.MONEY                                                     }, -- "Your share of the loot is %s. (%s deposited to guild bank)"
				{ LOOT_MONEY_SPLIT,                            token.MONEY                                                                      }, -- "Your share of the loot is %s."
				{ LOOT_MONEY_REFUND,                           token.MONEY                                                                      }, -- "You are refunded %s."
				{ LOOT_MONEY,                                  token.TARGET,    token.MONEY                                                     }, -- "%s loots %s."
			},
			parse = function(self, tokens, matches)
				local data = { money = true }

				if tokens[2] == token.MONEY then
					data.value = matches[2]

					if tokens[3] == token.MONEY then
						data.guild = matches[3]
					end

				elseif tokens[2] == token.TARGET then
					data.target = matches[2]

					if tokens[3] == token.MONEY then
						data.value = matches[3]
					end
				end

				return data
			end,
			tests = {
				{ format(YOU_LOOT_MONEY_GUILD, GetCoinText(1234567), GetCoinText(102030)), { money = true, value = 1234567, guild = 102030 } },
				{ format(YOU_LOOT_MONEY, GetCoinText(450607)), { money = true, value = 450607 } },
				{ format(LOOT_MONEY_SPLIT_GUILD, GetCoinText(12345), GetCoinText(1234)), { money = true, value = 12345, guild = 1234 } },
				{ format(LOOT_MONEY_SPLIT, GetCoinText(123)), { money = true, value = 123 } },
				{ format(LOOT_MONEY_REFUND, GetCoinText(5000000)), { money = true, value = 5000000 } },
				{ format(LOOT_MONEY, "Targetname", GetCoinText(9000000)), { money = true, value = 9000000, target = "Targetname" } },
			}
		},
		-- loot (target)
		-- { loot[, target[, item[, count]]] }
		-- NB: koKR prefers these before the next category
		{
			group = "LOOT_ITEM",
			events = {
				"CHAT_MSG_LOOT",
			},
			formats = {
				{ CREATED_ITEM_MULTIPLE,                       token.TARGET,    token.STRING,    token.NUMBER                                   }, -- "%s creates: %sx%d."
				{ CREATED_ITEM,                                token.TARGET,    token.STRING                                                    }, -- "%s creates: %s."
			},
			parse = function(self, tokens, matches)
				local data = { loot = true }

				if tokens[2] == token.TARGET then
					data.target = matches[2]

					if tokens[3] == token.STRING then
						data.item = matches[3]

						if tokens[4] == token.NUMBER then
							data.count = matches[4]
						end
					end
				end

				return data
			end,
			tests = {
				{ format(CREATED_ITEM_MULTIPLE, "Targetname", "Itemlink", 70), { loot = true, target = "Targetname", item = "Itemlink", count = 70 } },
				{ format(CREATED_ITEM, "Targetname", "Itemlink"), { loot = true, target = "Targetname", item = "Itemlink" } },
			}
		},
		-- loot
		-- { loot[, item[, count]] }
		{
			group = "LOOT_ITEM",
			events = {
				"CHAT_MSG_LOOT",
			},
			formats = {
				{ LOOT_ITEM_BONUS_ROLL_SELF_MULTIPLE,          token.STRING,    token.NUMBER                                                    }, -- "You receive bonus loot: %sx%d."
				{ LOOT_ITEM_BONUS_ROLL_SELF,                   token.STRING                                                                     }, -- "You receive bonus loot: %s."
				{ LOOT_ITEM_SELF_MULTIPLE,                     token.STRING,    token.NUMBER                                                    }, -- "You receive loot: %sx%d."
				{ LOOT_ITEM_SELF,                              token.STRING                                                                     }, -- "You receive loot: %s."
				{ LOOT_ITEM_PUSHED_SELF_MULTIPLE,              token.STRING,    token.NUMBER                                                    }, -- "You receive item: %sx%d."
				{ LOOT_ITEM_PUSHED_SELF,                       token.STRING                                                                     }, -- "You receive item: %s."
				{ LOOT_ITEM_CREATED_SELF_MULTIPLE,             token.STRING,    token.NUMBER                                                    }, -- "You create: %sx%d."
				{ LOOT_ITEM_CREATED_SELF,                      token.STRING                                                                     }, -- "You create: %s."
				{ LOOT_ITEM_REFUND_MULTIPLE,                   token.STRING,    token.NUMBER                                                    }, -- "You are refunded: %sx%d."
				{ LOOT_ITEM_REFUND,                            token.STRING                                                                     }, -- "You are refunded: %s."
				-- { ERR_QUEST_REWARD_ITEM_MULT_IS,               token.NUMBER,    token.STRING                                                    }, -- "Received %d of item: %s."
				-- { ERR_QUEST_REWARD_ITEM_S,                     token.STRING                                                                     }, -- "Received item: %s."
			},
			parse = function(self, tokens, matches)
				local data = { loot = true }

				if tokens[2] == token.STRING then
					data.item = matches[2]

					if tokens[3] == token.NUMBER then
						data.count = matches[3]
					end

				elseif tokens[2] == token.NUMBER then
					data.count = matches[2]

					if tokens[3] == token.STRING then
						data.item = matches[3]
					end
				end

				return data
			end,
			tests = {
				{ format(LOOT_ITEM_BONUS_ROLL_SELF_MULTIPLE, "Itemlink", 90), { loot = true, item = "Itemlink", count = 90 } },
				{ format(LOOT_ITEM_BONUS_ROLL_SELF, "Itemlink"), { loot = true, item = "Itemlink" } },
				{ format(LOOT_ITEM_SELF_MULTIPLE, "Itemlink", 80), { loot = true, item = "Itemlink", count = 80 } },
				{ format(LOOT_ITEM_SELF, "Itemlink"), { loot = true, item = "Itemlink" } },
				{ format(LOOT_ITEM_PUSHED_SELF_MULTIPLE, "Itemlink", 70), { loot = true, item = "Itemlink", count = 70 } },
				{ format(LOOT_ITEM_PUSHED_SELF, "Itemlink"), { loot = true, item = "Itemlink" } },
				{ format(LOOT_ITEM_CREATED_SELF_MULTIPLE, "Itemlink", 60), { loot = true, item = "Itemlink", count = 60 } },
				{ format(LOOT_ITEM_CREATED_SELF, "Itemlink"), { loot = true, item = "Itemlink" } },
				{ format(LOOT_ITEM_REFUND_MULTIPLE, "Itemlink", 50), { loot = true, item = "Itemlink", count = 50 } },
				{ format(LOOT_ITEM_REFUND, "Itemlink"), { loot = true, item = "Itemlink" } },
				-- format(ERR_QUEST_REWARD_ITEM_MULT_IS, 40, "Itemlink"), -- DEPRECATED: LEGION
				-- format(ERR_QUEST_REWARD_ITEM_S, "Itemlink"), -- DEPRECATED: LEGION
			}
		},
		-- loot (target)
		-- { loot[, target[, item[, count]]] }
		{
			group = "LOOT_ITEM",
			events = {
				"CHAT_MSG_LOOT",
			},
			formats = {
				{ LOOT_ITEM_BONUS_ROLL_MULTIPLE,               token.TARGET,    token.STRING,    token.NUMBER                                   }, -- "%s receives bonus loot: %sx%d."
				{ LOOT_ITEM_BONUS_ROLL,                        token.TARGET,    token.STRING                                                    }, -- "%s receives bonus loot: %s."
				{ LOOT_ITEM_MULTIPLE,                          token.TARGET,    token.STRING,    token.NUMBER                                   }, -- "%s receives loot: %sx%d."
				{ LOOT_ITEM,                                   token.TARGET,    token.STRING                                                    }, -- "%s receives loot: %s."
				{ LOOT_ITEM_PUSHED_MULTIPLE,                   token.TARGET,    token.STRING,    token.NUMBER                                   }, -- "%s receives item: %sx%d."
				{ LOOT_ITEM_PUSHED,                            token.TARGET,    token.STRING                                                    }, -- "%s receives item: %s."
			},
			parse = function(self, tokens, matches)
				local data = { loot = true }

				if tokens[2] == token.TARGET then
					data.target = matches[2]

					if tokens[3] == token.STRING then
						data.item = matches[3]

						if tokens[4] == token.NUMBER then
							data.count = matches[4]
						end
					end
				end

				return data
			end,
			tests = {
				{ format(LOOT_ITEM_BONUS_ROLL_MULTIPLE, "Targetname", "Itemlink", 90), { loot = true, target = "Targetname", item = "Itemlink", count = 90 } },
				{ format(LOOT_ITEM_BONUS_ROLL, "Targetname", "Itemlink"), { loot = true, target = "Targetname", item = "Itemlink" } },
				{ format(LOOT_ITEM_MULTIPLE, "Targetname", "Itemlink", 80), { loot = true, target = "Targetname", item = "Itemlink", count = 80 } },
				{ format(LOOT_ITEM, "Targetname", "Itemlink"), { loot = true, target = "Targetname", item = "Itemlink" } },
				{ format(LOOT_ITEM_PUSHED_MULTIPLE, "Targetname", "Itemlink", 70), { loot = true, target = "Targetname", item = "Itemlink", count = 70 } },
				{ format(LOOT_ITEM_PUSHED, "Targetname", "Itemlink"), { loot = true, target = "Targetname", item = "Itemlink" } },
			}
		},
		-- loot (roll, decision, pass, everyone)
		-- { loot, roll, decision, pass, everyone[, history[, item]] }
		{
			group = "LOOT_ROLL_DECISION",
			events = {
				"CHAT_MSG_LOOT",
			},
			formats = {
				{ LOOT_ROLL_ALL_PASSED,                        token.NUMBER,    token.STRING                                                    }, -- "|HlootHistory:%d|h[Loot]|h: Everyone passed on: %s"
			},
			parse = function(self, tokens, matches)
				local data = { loot = true, roll = true, decision = true, pass = true, everyone = true }

				if tokens[2] == token.NUMBER then
					data.history = matches[2]

					if tokens[3] == token.STRING then
						data.item = matches[3]
					end
				end

				return data
			end,
			tests = {
				format(LOOT_ROLL_ALL_PASSED, 1, "Itemlink"),
			}
		},
		-- loot (roll, decision, pass)
		-- { loot, roll, decision, pass[, history[, target[, item]]] }
		{
			group = "LOOT_ROLL_DECISION",
			events = {
				"CHAT_MSG_LOOT",
			},
			formats = {
				{ LOOT_ROLL_PASSED_SELF_AUTO,                  token.NUMBER,    token.STRING                                                    }, -- "|HlootHistory:%d|h[Loot]|h: You automatically passed on: %s because you cannot loot that item."
				{ LOOT_ROLL_PASSED_SELF,                       token.NUMBER,    token.STRING                                                    }, -- "|HlootHistory:%d|h[Loot]|h: You passed on: %s"
				{ LOOT_ROLL_PASSED_AUTO,                       token.TARGET,    token.STRING                                                    }, -- "%s automatically passed on: %s because he cannot loot that item."
				{ LOOT_ROLL_PASSED_AUTO_FEMALE,                token.TARGET,    token.STRING                                                    }, -- "%s automatically passed on: %s because she cannot loot that item."
				{ LOOT_ROLL_PASSED,                            token.TARGET,    token.STRING                                                    }, -- "%s passed on: %s"
			},
			parse = function(self, tokens, matches)
				local data = { loot = true, roll = true, decision = true, pass = true }

				if tokens[2] == token.NUMBER then
					data.history = matches[2]

					if tokens[3] == token.STRING then
						data.item = matches[3]
					end

				elseif tokens[2] == token.TARGET then
					data.target = matches[2]

					if tokens[3] == token.STRING then
						data.item = matches[3]
					end
				end

				return data
			end,
			tests = {
				format(LOOT_ROLL_PASSED_SELF_AUTO, 1, "Itemlink"),
				format(LOOT_ROLL_PASSED_SELF, 1, "Itemlink"),
				format(LOOT_ROLL_PASSED_AUTO, "Targetname", "Itemlink"),
				format(LOOT_ROLL_PASSED_AUTO_FEMALE, "Targetname", "Itemlink"),
				format(LOOT_ROLL_PASSED, "Targetname", "Itemlink"),
			}
		},
		-- loot (roll, decision, disenchant)
		-- { loot, roll, decision, disenchant[, history[, target[, item]]] }
		{
			group = "LOOT_ROLL_DECISION",
			events = {
				"CHAT_MSG_LOOT",
			},
			formats = {
				{ LOOT_ROLL_DISENCHANT_SELF,                   token.NUMBER,    token.STRING                                                    }, -- "|HlootHistory:%d|h[Loot]|h: You have selected Disenchant for: %s"
				{ LOOT_ROLL_DISENCHANT,                        token.TARGET,    token.STRING                                                    }, -- "%s has selected Disenchant for: %s"
			},
			parse = function(self, tokens, matches)
				local data = { loot = true, roll = true, decision = true, disenchant = true }

				if tokens[2] == token.NUMBER then
					data.history = matches[2]

					if tokens[3] == token.STRING then
						data.item = matches[3]
					end

				elseif tokens[2] == token.TARGET then
					data.target = matches[2]

					if tokens[3] == token.STRING then
						data.item = matches[3]
					end
				end

				return data
			end,
			tests = {
				format(LOOT_ROLL_DISENCHANT_SELF, 1, "Itemlink"),
				format(LOOT_ROLL_DISENCHANT, "Targetname", "Itemlink"),
			}
		},
		-- loot (roll, decision, greed)
		-- { loot, roll, decision, greed[, history[, target[, item]]] }
		{
			group = "LOOT_ROLL_DECISION",
			events = {
				"CHAT_MSG_LOOT",
			},
			formats = {
				{ LOOT_ROLL_GREED_SELF,                        token.NUMBER,    token.STRING                                                    }, -- "|HlootHistory:%d|h[Loot]|h: You have selected Greed for: %s"
				{ LOOT_ROLL_GREED,                             token.TARGET,    token.STRING                                                    }, -- "%s has selected Greed for: %s"
			},
			parse = function(self, tokens, matches)
				local data = { loot = true, roll = true, decision = true, greed = true }

				if tokens[2] == token.NUMBER then
					data.history = matches[2]

					if tokens[3] == token.STRING then
						data.item = matches[3]
					end

				elseif tokens[2] == token.TARGET then
					data.target = matches[2]

					if tokens[3] == token.STRING then
						data.item = matches[3]
					end
				end

				return data
			end,
			tests = {
				format(LOOT_ROLL_GREED_SELF, 1, "Itemlink"),
				format(LOOT_ROLL_GREED, "Targetname", "Itemlink"),
			}
		},
		-- loot (roll, decision, need)
		-- { loot, roll, decision, need[, history[, target[, item]]] }
		{
			group = "LOOT_ROLL_DECISION",
			events = {
				"CHAT_MSG_LOOT",
			},
			formats = {
				{ LOOT_ROLL_NEED_SELF,                         token.NUMBER,    token.STRING                                                    }, -- "|HlootHistory:%d|h[Loot]|h: You have selected Need for: %s"
				{ LOOT_ROLL_NEED,                              token.TARGET,    token.STRING                                                    }, -- "%s has selected Need for: %s"
			},
			parse = function(self, tokens, matches)
				local data = { loot = true, roll = true, decision = true, need = true }

				if tokens[2] == token.NUMBER then
					data.history = matches[2]

					if tokens[3] == token.STRING then
						data.item = matches[3]
					end

				elseif tokens[2] == token.TARGET then
					data.target = matches[2]

					if tokens[3] == token.STRING then
						data.item = matches[3]
					end
				end

				return data
			end,
			tests = {
				format(LOOT_ROLL_NEED_SELF, 1, "Itemlink"),
				format(LOOT_ROLL_NEED, "Targetname", "Itemlink"),
			}
		},
		-- loot (roll, rolled, disenchant)
		-- { loot, roll, rolled, disenchant[, number[, item[, target]]] }
		{
			group = "LOOT_ROLL_ROLLED",
			events = {
				"CHAT_MSG_LOOT",
			},
			formats = {
				{ LOOT_ROLL_ROLLED_DE,                         token.NUMBER,    token.STRING,    token.TARGET                                   }, -- "Disenchant Roll - %d for %s by %s"
			},
			parse = function(self, tokens, matches)
				local data = { loot = true, roll = true, rolled = true, disenchant = true }

				if tokens[2] == token.NUMBER then
					data.number = matches[2]

					if tokens[3] == token.STRING then
						data.item = matches[3]

						if tokens[4] == token.TARGET then
							data.target = matches[4]
						end
					end
				end

				return data
			end,
			tests = {
				format(LOOT_ROLL_ROLLED_DE, 100, "Itemlink", "Targetname"),
			}
		},
		-- loot (roll, rolled, greed)
		-- { loot, roll, rolled, greed[, number[, item[, target]]] }
		{
			group = "LOOT_ROLL_ROLLED",
			events = {
				"CHAT_MSG_LOOT",
			},
			formats = {
				{ LOOT_ROLL_ROLLED_GREED,                      token.NUMBER,    token.STRING,    token.TARGET                                   }, -- "Greed Roll - %d for %s by %s"
			},
			parse = function(self, tokens, matches)
				local data = { loot = true, roll = true, rolled = true, greed = true }

				if tokens[2] == token.NUMBER then
					data.number = matches[2]

					if tokens[3] == token.STRING then
						data.item = matches[3]

						if tokens[4] == token.TARGET then
							data.target = matches[4]
						end
					end
				end

				return data
			end,
			tests = {
				format(LOOT_ROLL_ROLLED_GREED, 100, "Itemlink", "Targetname"),
			}
		},
		-- loot (roll, rolled, need)
		-- { loot, roll, rolled, need[, number[, item[, target]]] }
		{
			group = "LOOT_ROLL_ROLLED",
			events = {
				"CHAT_MSG_LOOT",
			},
			formats = {
				{ LOOT_ROLL_ROLLED_NEED_ROLE_BONUS,            token.NUMBER,    token.STRING,    token.TARGET                                   }, -- "Need Roll - %d for %s by %s + Role Bonus"
				{ LOOT_ROLL_ROLLED_NEED,                       token.NUMBER,    token.STRING,    token.TARGET                                   }, -- "Need Roll - %d for %s by %s"
			},
			parse = function(self, tokens, matches)
				local data = { loot = true, roll = true, rolled = true, need = true }

				if tokens[2] == token.NUMBER then
					data.number = matches[2]

					if tokens[3] == token.STRING then
						data.item = matches[3]

						if tokens[4] == token.TARGET then
							data.target = matches[4]
						end
					end
				end

				return data
			end,
			tests = {
				format(LOOT_ROLL_ROLLED_NEED_ROLE_BONUS, 200, "Itemlink", "Targetname"),
				format(LOOT_ROLL_ROLLED_NEED, 100, "Itemlink", "Targetname"),
			}
		},
		-- loot (roll, result, disenchanted)
		-- { loot, roll, result, disenchanted[, item[, target]] }
		{
			group = "LOOT_ROLL_RESULT",
			events = {
				"CHAT_MSG_LOOT",
			},
			formats = {
				{ LOOT_DISENCHANT_CREDIT,                      token.STRING,    token.TARGET                                                    }, -- "%s was disenchanted for loot by %s."
			},
			parse = function(self, tokens, matches)
				local data = { loot = true, roll = true, result = true, disenchanted = true }

				if tokens[2] == token.STRING then
					data.item = matches[2]

					if tokens[3] == token.TARGET then
						data.target = matches[3]
					end
				end

				return data
			end,
			tests = {
				format(LOOT_DISENCHANT_CREDIT, "Itemlink", "Targetname"),
			}
		},
		-- loot (roll, result, ineligible)
		-- { loot, roll, result, ineligible[, target[, item]] }
		{
			group = "LOOT_ROLL_RESULT",
			events = {
				"CHAT_MSG_LOOT",
			},
			formats = {
				{ LOOT_ITEM_WHILE_PLAYER_INELIGIBLE,           token.TARGET,    token.STRING                                                    }, -- "%s receives loot: |TInterface\\Common\\Icon-NoLoot:13:13:0:0|t%s"
			},
			parse = function(self, tokens, matches)
				local data = { loot = true, roll = true, result = true, ineligible = true }

				if tokens[2] == token.TARGET then
					data.target = matches[2]

					if tokens[3] == token.STRING then
						data.item = matches[3]
					end
				end

				return data
			end,
			tests = {
				format(LOOT_ITEM_WHILE_PLAYER_INELIGIBLE, "Targetname", "Itemlink?"),
			}
		},
		-- loot (roll, result, disenchant)
		-- { loot, roll, result, disenchant[, history[, number[, target[, item]]]] }
		{
			group = "LOOT_ROLL_RESULT",
			events = {
				"CHAT_MSG_LOOT",
			},
			formats = {
				{ LOOT_ROLL_YOU_WON_NO_SPAM_DE,                token.NUMBER,    token.NUMBER,    token.STRING                                   }, -- "|HlootHistory:%d|h[Loot]|h: You (Disenchant - %d) Won: %s"
				{ LOOT_ROLL_WON_NO_SPAM_DE,                    token.NUMBER,    token.TARGET,    token.NUMBER,    token.STRING                  }, -- "|HlootHistory:%d|h[Loot]|h: %s (Disenchant - %d) Won: %s"
			},
			parse = function(self, tokens, matches)
				local data = { loot = true, roll = true, result = true, disenchant = true }

				if tokens[2] == token.NUMBER then
					data.history = matches[2]

					if tokens[3] == token.NUMBER then
						data.number = matches[3]

						if tokens[4] == token.STRING then
							data.item = matches[4]
						end

					elseif tokens[3] == token.TARGET then
						data.target = matches[3]

						if tokens[4] == token.NUMBER then
							data.number = matches[4]

							if tokens[5] == token.STRING then
								data.item = matches[5]
							end
						end
					end
				end

				return data
			end,
			tests = {
				format(LOOT_ROLL_YOU_WON_NO_SPAM_DE, 1, 100, "Itemlink"),
				format(LOOT_ROLL_WON_NO_SPAM_DE, 1, "Targetname", 100, "Itemlink"),
			}
		},
		-- loot (roll, result, greed)
		-- { loot, roll, result, greed[, history[, number[, target[, item]]]] }
		{
			group = "LOOT_ROLL_RESULT",
			events = {
				"CHAT_MSG_LOOT",
			},
			formats = {
				{ LOOT_ROLL_YOU_WON_NO_SPAM_GREED,             token.NUMBER,    token.NUMBER,    token.STRING                                   }, -- "|HlootHistory:%d|h[Loot]|h: You (Greed - %d) Won: %s"
				{ LOOT_ROLL_WON_NO_SPAM_GREED,                 token.NUMBER,    token.TARGET,    token.NUMBER,    token.STRING                  }, -- "|HlootHistory:%d|h[Loot]|h: %s (Greed - %d) Won: %s"
			},
			parse = function(self, tokens, matches)
				local data = { loot = true, roll = true, result = true, greed = true }

				if tokens[2] == token.NUMBER then
					data.history = matches[2]

					if tokens[3] == token.NUMBER then
						data.number = matches[3]

						if tokens[4] == token.STRING then
							data.item = matches[4]
						end

					elseif tokens[3] == token.TARGET then
						data.target = matches[3]

						if tokens[4] == token.NUMBER then
							data.number = matches[4]

							if tokens[5] == token.STRING then
								data.item = matches[5]
							end
						end
					end
				end

				return data
			end,
			tests = {
				format(LOOT_ROLL_YOU_WON_NO_SPAM_GREED, 1, 100, "Itemlink"),
				format(LOOT_ROLL_WON_NO_SPAM_GREED, 1, "Targetname", 100, "Itemlink"),
			}
		},
		-- loot (roll, result, need)
		-- { loot, roll, result, need[, history[, number[, target[, item]]]] }
		{
			group = "LOOT_ROLL_RESULT",
			events = {
				"CHAT_MSG_LOOT",
			},
			formats = {
				{ LOOT_ROLL_YOU_WON_NO_SPAM_NEED,              token.NUMBER,    token.NUMBER,    token.STRING                                   }, -- "|HlootHistory:%d|h[Loot]|h: You (Need - %d) Won: %s"
				{ LOOT_ROLL_WON_NO_SPAM_NEED,                  token.NUMBER,    token.TARGET,    token.NUMBER,    token.STRING                  }, -- "|HlootHistory:%d|h[Loot]|h: %s (Need - %d) Won: %s"
			},
			parse = function(self, tokens, matches)
				local data = { loot = true, roll = true, result = true, need = true }

				if tokens[2] == token.NUMBER then
					data.history = matches[2]

					if tokens[3] == token.NUMBER then
						data.number = matches[3]

						if tokens[4] == token.STRING then
							data.item = matches[4]
						end

					elseif tokens[3] == token.TARGET then
						data.target = matches[3]

						if tokens[4] == token.NUMBER then
							data.number = matches[4]

							if tokens[5] == token.STRING then
								data.item = matches[5]
							end
						end
					end
				end

				return data
			end,
			tests = {
				format(LOOT_ROLL_YOU_WON_NO_SPAM_NEED, 1, 100, "Itemlink"),
				format(LOOT_ROLL_WON_NO_SPAM_NEED, 1, "Targetname", 100, "Itemlink"),
			}
		},
		-- loot (roll, result, lost, dynamic type disenchant/greed/need)
		-- { loot, roll, result, lost[, history[, type[, number[, item]]]] }
		{
			group = "LOOT_ROLL_RESULT",
			events = {
				"CHAT_MSG_LOOT",
			},
			formats = {
				{ LOOT_ROLL_LOST_ROLL,                         token.NUMBER,    token.STRING,    token.NUMBER,    token.STRING                  }, -- "|HlootHistory:%d|h[Loot]|h: You have rolled %s - %d for: %s"
			},
			parse = function(self, tokens, matches)
				local data = { loot = true, roll = true, result = true, lost = true }

				if tokens[2] == token.NUMBER then
					data.history = matches[2]

					if tokens[3] == token.STRING then
						data.type = matches[3]

						if tokens[4] == token.NUMBER then
							data.number = matches[4]

							if tokens[5] == token.STRING then
								data.item = matches[5]
							end
						end
					end
				end

				return data
			end,
			tests = {
				format(LOOT_ROLL_LOST_ROLL, 1, "ROLLTYPE", 50, "Itemlink"),
			}
		},
		-- loot (roll, result)
		-- { loot, roll, result, winner[, target[, item]] }
		{
			group = "LOOT_ROLL_RESULT",
			events = {
				"CHAT_MSG_LOOT",
			},
			formats = {
				{ LOOT_ROLL_YOU_WON,                           token.STRING                                                                     }, -- "You won: %s"
				{ LOOT_ROLL_WON,                               token.TARGET,    token.STRING                                                    }, -- "%s won: %s"
			},
			parse = function(self, tokens, matches)
				local data = { loot = true, roll = true, result = true, winner = true }

				if tokens[2] == token.STRING then
					data.item = matches[2]

				elseif tokens[2] == token.TARGET then
					data.target = matches[2]

					if tokens[3] == token.STRING then
						data.item = matches[3]
					end
				end

				return data
			end,
			tests = {
				format(LOOT_ROLL_YOU_WON, "Itemlink"),
				format(LOOT_ROLL_WON, "Targetname", "Itemlink"),
			}
		},
		-- loot (roll, result, started)
		-- { loot, roll, result, started[, history[, item]] }
		{
			group = "LOOT_ROLL_RESULT",
			events = {
				"CHAT_MSG_LOOT",
			},
			formats = {
				{ LOOT_ROLL_STARTED,                      token.NUMBER,    token.STRING                                                    }, -- "|HlootHistory:%d|h[Loot]|h: %s"
			},
			parse = function(self, tokens, matches)
				local data = { loot = true, roll = true, result = true, started = true }

				if tokens[2] == token.NUMBER then
					data.history = matches[2]

					if tokens[3] == token.STRING then
						data.item = matches[3]
					end
				end

				return data
			end,
			tests = {
				format(LOOT_ROLL_STARTED, 1, "Itemlink"),
			}
		},
		-- artifact
		-- { artifact, item, power }
		{
			skipTests = true, -- because it depends on the config if the pattern matches something or not
			group = "ARTIFACT",
			events = {
				"CHAT_MSG_SYSTEM",
			},
			formats = {
				{ ARTIFACT_XP_GAIN,                            token.STRING,    token.NUMBER                                                    }, -- "%s gains %s Artifact Power."
			},
			parse = function(self, tokens, matches)
				if not ns.config.bool:read("ARTIFACT_POWER") then
					return { ignore = true }
				end

				local data = { artifact = true }

				if tokens[2] == token.STRING then
					data.item = matches[2]

					if tokens[3] == token.NUMBER then
						data.power = matches[3]
					end
				end

				return data
			end,
			tests = {
				{ format(ARTIFACT_XP_GAIN, "Itemlink", 1337), { artifact = true, item = "Itemlink", power = 1337 } },
				{ format(ARTIFACT_XP_GAIN, "Itemlink", "123" .. LARGE_NUMBER_SEPERATOR .. "456"), { artifact = true, item = "Itemlink", power = 123456 } },
				{ format(ARTIFACT_XP_GAIN, "Itemlink", "123" .. LARGE_NUMBER_SEPERATOR .. "456" .. DECIMAL_SEPERATOR .. "99"), { artifact = true, item = "Itemlink", power = 123456.99 } },
				{ format(ARTIFACT_XP_GAIN, "Itemlink", "123" .. LARGE_NUMBER_SEPERATOR .. "456" .. LARGE_NUMBER_SEPERATOR .. "789"), { artifact = true, item = "Itemlink", power = 123456789 } },
				{ format(ARTIFACT_XP_GAIN, "Itemlink", "123" .. LARGE_NUMBER_SEPERATOR .. "456" .. LARGE_NUMBER_SEPERATOR .. "789" .. DECIMAL_SEPERATOR .. "99"), { artifact = true, item = "Itemlink", power = 123456789.99 } },
			}
		},
		-- transmogrification
		-- { ignore }
		{
			skipTests = true, -- because it depends on the config if the pattern matches something or not
			group = "TRANSMOGRIFICATION",
			events = {
				"CHAT_MSG_SYSTEM",
			},
			formats = {
				{ ERR_LEARN_TRANSMOG_S,                        token.STRING                                                                     }, -- "%s has been added to your appearance collection."
				{ ERR_REVOKE_TRANSMOG_S,                       token.STRING                                                                     }, -- "%s has been removed from your appearance collection."
			},
			parse = function(self, tokens, matches)
				if matches[2] and ns.config.bool:read("ITEM_ALERT_TRANSMOG") then -- TODO: REDUNDANT?
					return { ignore = true }
				end
			end,
			tests = {
				format(ERR_LEARN_TRANSMOG_S, "Itemlink"),
				format(ERR_REVOKE_TRANSMOG_S, "Itemlink"),
			}
		},
		-- ignore
		-- { ignore }
		{
			skipTests = false, -- because it depends on the config if the pattern matches something or not
			group = "IGNORE",
			events = {
				"CHAT_MSG_SYSTEM",
			},
			formats = {
				{ ERR_QUEST_REWARD_EXP_I,                      token.NUMBER                                                                     }, -- "Experience gained: %d."
				{ ERR_QUEST_REWARD_MONEY_S,                    token.MONEY                                                                     }, -- "Received %s."
			},
			parse = function(self, tokens, matches)
				local data = { ignore = true } -- TODO: REDUNDANT?

				if tokens[2] == token.NUMBER then
					data.value = matches[2]
				elseif tokens[2] == token.MONEY then
					data.value = matches[2]
				end

				return data
			end,
			tests = {
				{ format(ERR_QUEST_REWARD_EXP_I, 10000), { ignore = true, value = 10000 } },
				{ format(ERR_QUEST_REWARD_MONEY_S, GetCoinText(1234567)), { ignore = true, value = 1234567 } },
			}
		},
	}

	local categoriesOptions = { groups = {}, sorted = {} }

	do
		for i = 1, #categories do
			local category = categories[i]
			category.id = i

			if category.group then
				if not categoriesOptions.groups[category.group] then
					categoriesOptions.groups[category.group] = {
						id = i,
						group = category.group,
						label = ns.locale["OPTION_IGNORE_GROUP_"  .. category.group .. "_TITLE"],
						description = ns.locale["OPTION_IGNORE_GROUP_"  .. category.group .. "_DESC"],
						categories = {}
					}
				end

				table.insert(categoriesOptions.groups[category.group].categories, {
					group = category.group,
					id = category.id,
					object = category
				})
			end
		end

		for key, group in pairs(categoriesOptions.groups) do
			table.insert(categoriesOptions.sorted, group)
		end

		table.sort(categoriesOptions.sorted, function(a, b)
			return a.id < b.id
		end)
	end

	function ns.util:categories()
		return categoriesOptions.sorted
	end

	local function convert(pattern)
		-- grammar from hell ( http://wow.gamepedia.com/UI_escape_sequences#Grammar )
		-- pattern = pattern:gsub("|4[^:]-:[^:]-:[^;]-;", "") -- "|4singular:plural1:plural2;"
		-- pattern = pattern:gsub("|4[^:]-:[^;]-;", "") -- "number |4singular:plural;"
		-- pattern = pattern:gsub("|1[^;]-;[^;]-;", "") -- "number |1singular;plural;"
		-- pattern = pattern:gsub("|3-%d+%([^%)]-%)", "") -- "|3-formid(text)"
		-- pattern = pattern:gsub("|2%S-?", "") -- "|2text"
		-- argument ordering
		for i = 1, 20 do
			pattern = pattern:gsub("%%" .. i .. "$s", "%%s")
			pattern = pattern:gsub("%%" .. i .. "$d", "%%d")
			pattern = pattern:gsub("%%" .. i .. "$f", "%%f")
		end
		-- standard tokens
		pattern = pattern:gsub("%%", "%%%%")
		pattern = pattern:gsub("%.", "%%%.")
		pattern = pattern:gsub("%?", "%%%?")
		pattern = pattern:gsub("%+", "%%%+")
		pattern = pattern:gsub("%-", "%%%-")
		pattern = pattern:gsub("%(", "%%%(")
		pattern = pattern:gsub("%)", "%%%)")
		pattern = pattern:gsub("%[", "%%%[")
		pattern = pattern:gsub("%]", "%%%]")
		pattern = pattern:gsub("%%%%s", "(.-)")
		pattern = pattern:gsub("%%%%d", "(%%d+)")
		pattern = pattern:gsub("%%%%%%[%d%.%,]+f", "([%%d%%.%%,]+)")
		return pattern
	end

	local moneyPatterns = {
		GOLD = convert(GOLD_AMOUNT),
		SILVER = convert(SILVER_AMOUNT),
		COPPER = convert(COPPER_AMOUNT)
	}

	local function parse(id, value)
		if id == token.PLAYER or
				id == token.TARGET or
				id == token.STRING then

			-- nil if string is invalid or empty
			if type(value) ~= "string" or value:len() == 0 then
				value = nil
			end

			-- TODO: NYI
			if value then
				if id == token.PLAYER then
					-- TODO: is this our own name?
				elseif id == token.TARGET then
					-- TODO: is this name a part of our raid, group, guild, e.g.? can people outside show messages in our chat?
				end
			end

		elseif id == token.NUMBER or
					id == token.FLOAT then

			-- strip non-digits from strings (try to properly hande number separator/decimal)
			if type(value) == "string" then
				value = value:gsub("[\\" .. LARGE_NUMBER_SEPERATOR .. "]+", "")
				value = value:gsub("[\\" .. DECIMAL_SEPERATOR .. "]", ".")
				value = value:gsub("[^%d\.]+", "")
			end

			-- convert what ever it is into a number
			value = tonumber(value)

		elseif id == token.MONEY then

			-- convert the string into copper value
			local g = tonumber(value:match(moneyPatterns.GOLD)) or 0
			local s = tonumber(value:match(moneyPatterns.SILVER)) or 0
			local c = tonumber(value:match(moneyPatterns.COPPER)) or 0
			value = (g * COPPER_PER_GOLD) + (s * COPPER_PER_SILVER) + c

		end

		return value
	end

	local function tokenize(text, category, tokens, matches)
		for i = 2, #tokens do
			matches[i - 1] = parse(tokens[i], matches[i - 1])
		end

		table.insert(matches, 1, text)
		local data = category:parse(tokens, matches)
		matches[1] = data

		return matches
	end

	for i = 1, #categories do
		local category = categories[i]

		for j = 1, #category.formats do
			local format = category.formats[j]

			format[1] = "^" .. convert(format[1]) .. "$"
		end
	end

	local function table_contains(items, item)
		for _, v in pairs(items) do
			if v == item then
				return true
			end
		end
		return false
	end

	function ns.util:parse(text, event)
		if type(text) ~= "string" then
			return
		end

		local flags = ns.config:read("CATEGORY_FLAGS", {})
		local hasSilenced = nil
		local matched = {}

		-- iterate each category and try to match the text
		for i = 1, #categories do
			local category = categories[i]
			local events = category.events

			-- track if we purposefully silence something
			local silenced = category.ignore or (category.group and flags[category.group])

			-- update the overall flag that we encountered a silenced category
			hasSilenced = hasSilenced or silenced

			-- ignore if we don't want these shown, or if the user has selected to ignore this particular category, otherwise make sure the event is valid in the current category
			if (not silenced) and (type(events) ~= "table" or table_contains(events, event)) then
				for j = 1, #category.formats do
					local format = category.formats[j]
					local temp = {text:match(format[1])}

					if temp[1] and #temp > 0 then
						temp = tokenize(text, category, format, temp)

						if temp then
							table.insert(matched, temp)
						end
					end
				end
			end

			-- if we have matched in this category, we exit the loop
			if matched[1] then
				break
			end
		end

		-- pick the result we wish to return (most of the time, more matches means more accurate results)
		if matched[2] then
			local highest = matched[1]
			for i = 1, #matched do
				if #matched[i] > #highest then
					highest = matched[i]
				end
			end
			return unpack(highest)
		elseif matched[1] then
			return unpack(matched[1])
		end

		-- if we have been silenced (either by category.ignore, or by ignoring certain category in the options)
		if hasSilenced then
			return nil, true
		end
	end

	function ns.util:parseTests()
		local temp = { success = 0, failed = 0, total = 0, log = {} }

		for i = 1, #categories do
			local category = categories[i]
			local skipCategoryTests = not not category.skipTests

			for j = 1, #category.tests do
				local test = category.tests[j]
				local event, expected

				if type(category.events) == "table" then
					event = category.events[1]
				end

				if type(test) == "table" then
					test, expected = test[1], test[2]
				end

				local results = { ns.util:parse(test, event) }
				local success = not not (results and results[1])
				-- local hasSilenced = not not (results and not results[1] and results[2])

				if success and expected then
					for x, y in pairs(expected) do
						if results[1][x] ~= y then
							success = false

							break
						end
					end
				end

				table.insert(temp.log, { event = event, input = test, output = results, success = success, expected = expected, skipped = skipCategoryTests })

				if skipCategoryTests or success then
					temp.success = temp.success + 1
				else
					temp.failed = temp.failed + 1
				end

				temp.total = temp.total + 1
			end
		end

		return temp
	end
end

-- convert parsed category data into formatted strings
do
	function ns.util:toNumber(i, prefix)
		i = floor(i * 10) / 10 -- round to one decimal at the most
		return "|cff" .. (i < 0 and "FF0000" or "00FF00") .. (prefix and (i < 0 and "-" or "+") or "") .. abs(i) .. "|r"
	end

	function ns.util:toTarget(name, fallback)
		if ns.config.bool:read("NAME_SHORT") then
			name = ns.util:getUnitName(name, true) or name
		end

		return type(name) == "string" and name:len() > 0 and name or fallback or UNKNOWN -- TODO: class color option?
	end

	function ns.util:toFaction(name, length)
		name = type(name) == "string" and name:len() > 0 and name or UNKNOWN

		if length or ns.config.bool:read("FACTION_NAME_MINIFY") then
			length = length or ns.config:read("FACTION_NAME_MINIFY_LENGTH")

			if type(length) ~= "number" or length < 1 then
				length = 10 -- fallback
			end

			name = ns.util:abbreviate(name, length)
		end

		return "|cff9696FF" .. name .. "|r"
	end

	function ns.util:toMoney(copper, fontSize)
		return GetCoinTextureString(copper, fontSize) or ""
	end

	function ns.util:toLootIcon(link, hyperlink, simple, customColor)
		local color, data, text = link:match("|c([0-9a-f]+)|H(.-)|h%[(.-)%]|h|r")
		local icon

		if data then
			local prefix, id = data:match("^(.-):(%d+)")

			if prefix == "item" then
				icon = GetItemIcon(link)
			elseif prefix == "currency" then
				icon = select(3, GetCurrencyInfo(id))
			elseif prefix == "garrfollower" then
				icon = C_Garrison.GetFollowerPortraitIconIDByID(id)
				if not icon or icon == 0 then icon = "Interface\\Garrison\\Portraits\\FollowerPortrait_NoPortrait" end
			elseif prefix == "battlepet" then
				icon = select(2, C_PetJournal.GetPetInfoBySpeciesID(id))
			end
		end

		if icon then
			return ns.util:getChatIconOutput(color, data, icon, hyperlink, simple, customColor)
		end

		return link
	end

	function ns.util:toItemCount(i, singles)
		if type(i) == "number" and i > 0 and (i > 1 or singles) then
			return "x" .. i
		end
		return ""
	end

	function ns.util:getChatIconOutput(color, data, icon, hyperlink, simple, customColor)
		local temp = ns.util:getChatIconTextureString(icon)

		if hyperlink then
			temp = "|H" .. data .. "|h" .. temp .. "|h"
		end

		if not simple then
			temp = "[" .. temp .. "]"
		end

		if customColor then
			color = customColor
		end

		return "|c" .. color .. temp .. "|r"
	end

	function ns.util:getChatIconTextureString(icon, ignoreOptions)
		local temp = ":0:0"

		if not ignoreOptions then
			local trim = ns.config:read("ICON_TRIM", 0)
			local size = ns.config:read("ICON_SIZE", 0)

			if trim > 0 then
				local base = size > 0 and size or (select(2, ns.DEFAULT_CHAT_FRAME:GetFont()) or 14) -- fallback to 14
				local ratio = base / 100 -- convert to percent ratio
				local minPX, maxPX = math.floor(ratio * trim), math.floor(ratio * (100 - trim))

				temp = ":" .. size .. ":" .. size .. ":0:0:" .. base .. ":" .. base .. ":" .. minPX .. ":" .. maxPX .. ":" .. minPX .. ":" .. maxPX
			end
		end

		return "|T" .. icon .. temp .. "|t"
	end
end

-- string functions
do
	local LETTER_PATTERN = "([%z\1-\127\194-\244][\128-\191]*)"

	function ns.util:abbreviate(raw, length)
		local parts = {strsplit(" ", raw)}
		if parts[2] then
			local temp = ""

			for i = 1, #parts do
				temp = temp .. ns.util:ucWord(ns.util:getLeft(parts[i], 3))
			end

			local _, replaced = temp:gsub("[^\128-\193]", "")
			if length < (replaced or temp:len()) then
				temp = ""

				for i = 1, #parts do
					temp = temp .. ns.util:ucWord(ns.util:getLeft(parts[i], 2))
				end
			end

			return temp

		else
			raw = ns.util:getLeft(raw, length)
		end

		return raw
	end

	function ns.util:getLeft(raw, length)
		assert(type(length) == "number" and length > 0, "The getLeft utility function requires a positive integer as length in the secondary parameter.")

		local pattern = ""
		for i = 1, length do
			pattern = pattern .. LETTER_PATTERN
		end

		local matches = table.concat({raw:match(pattern)})
		if matches ~= "" then
			return matches
		elseif length > 1 then
			return ns.util:getLeft(raw, length - 1)
		end

		return ""
	end

	function ns.util:ucWord(raw)
		return tostring(raw):gsub(LETTER_PATTERN .. "(.+)", function(a, b) return a:upper() .. b:lower() end)
	end
end

-- game functions
do
	local function ItemTooltipContains(link, raw, rowIndex)
		local query = link:match("item:(%d+)") or link
		local success, text = ns.tooltip:ScanItem(query)

		if success then
			rowIndex = tonumber(rowIndex, 10) or 2

			for i = rowIndex, #text do
				if text[i][1] == raw then
					return true
				end
			end
		end

		return false
	end

	-- MainMenuBar_GetNumArtifactTraitsPurchasableFromXP
	local function ArtifactCalculatePoints(pointsSpent, totalXP)
		local nextPointXP = C_ArtifactUI.GetCostForPointAtRank(pointsSpent)
		local numPoints = 0

		while totalXP >= nextPointXP do
			totalXP = totalXP - nextPointXP

			pointsSpent = pointsSpent + 1
			numPoints = numPoints + 1

			nextPointXP = C_ArtifactUI.GetCostForPointAtRank(pointsSpent)
		end

		return numPoints, totalXP, nextPointXP
	end

	function ns.util:isItemUnique(link)
		return ItemTooltipContains(link, ITEM_UNIQUE)
	end

	function ns.util:isItemQuest(link)
		return ItemTooltipContains(link, ITEM_BIND_QUEST)
	end

	function ns.util:isItemQuestStarting(link)
		return ItemTooltipContains(link, ITEM_STARTS_QUEST)
	end

	function ns.util:isItemAppearanceUncollected(link)
		return ItemTooltipContains(link, TRANSMOGRIFY_TOOLTIP_APPEARANCE_UNKNOWN)
	end

	function ns.util:getNumItems(item, includeBank, includeCharges)
		return GetItemCount(item, includeBank == nil and true or includeBank, includeCharges == nil and true or includeCharges)
	end

	function ns.util:isItemQuality(link, quality, comparison, fallback)
		if not link or not quality then return fallback end

		local _, _, itemQuality = GetItemInfo(link)
		if not itemQuality then return fallback end

		if not comparison or comparison == "eq" then
			return itemQuality == quality

		elseif comparison == "le" then
			return itemQuality <= quality

		elseif comparison == "ge" then
			return itemQuality >= quality

		elseif comparison == "lt" then
			return itemQuality < quality

		elseif comparison == "gt" then
			return itemQuality > quality
		end

		return fallback
	end

	function ns.util:isItemJunk(link)
		return ns.util:isItemQuality(link, 0)
	end

	function ns.util:getUnitName(unit, isName)
		local name, realm

		if isName then
			name, realm = strsplit("-", unit)
		else
			name, realm = UnitFullName(unit)
		end

		if name and name ~= "" then
			local _, playerRealm = UnitFullName("player")

			if not realm or realm == "" then
				realm = playerRealm

				if realm == "" then
					realm = nil
				end
			end

			local sameRealm = realm == playerRealm
			local connectedRealm = sameRealm or UnitRealmRelationship(unit) == LE_REALM_RELATION_VIRTUAL
			if not sameRealm and isName then connectedRealm = nil end

			return name, realm, sameRealm, connectedRealm
		end
	end

	function ns.util:getArtifactInfo()
		local currentXP, maxXP, numPoints

		if HasArtifactEquipped() then
			local _, _, _, _, totalXP, pointsSpent = C_ArtifactUI.GetEquippedArtifactInfo()
			local numPointsAvailableToSpend, xp, xpForNextPoint = ArtifactCalculatePoints(pointsSpent, totalXP)

			currentXP, maxXP, numPoints = xp, xpForNextPoint, numPointsAvailableToSpend
		end

		return currentXP, maxXP, numPoints
	end
end
