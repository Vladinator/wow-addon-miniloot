local addonName, ns = ...
ns.config = {}

-- global variable
local varName = addonName .. "DB"
_G[varName] = _G[varName] or {}

-- default chat frame assignment (for output)
ns.DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME

-- default settings
ns.config.defaults = {
	-- Common
	{ key = "NAME_SHORT", value = false, bool = true },
	{ key = "ITEM_SELF_PREFIX", value = false, bool = true },
	{ key = "ITEM_SELF_PREFIX_NAME", value = false, bool = true },
	{ key = "ITEM_SELF_TRIM_SOLO", value = false, bool = true },
	{ key = "ICON_TRIM", value = 8 },
	{ key = "ICON_SIZE", value = 0 },
	{ key = "CHAT_FRAME", value = ns.DEFAULT_CHAT_FRAME:GetName() },
	-- Timing
	{ key = "REPORT_IN_COMBAT", value = true, bool = true },
	{ key = "REPORT_INTERVAL", value = 2 },
	-- Items
	{ key = "ITEM_COUNT_BAGS", value = false, bool = true },
	{ key = "ITEM_COUNT_BAGS_INCLUDE_BANK", value = true, bool = true },
	{ key = "ITEM_COUNT_BAGS_INCLUDE_CHARGES", value = true, bool = true },
	{ key = "ITEM_PRINT_DEFAULT_RAID", value = false, bool = true },
	{ key = "ITEM_SHOW_ITEM_LEVEL", value = false, bool = true },
	{ key = "ITEM_SHOW_ITEM_LEVEL_ONLY_EQUIPMENT", value = false, bool = true },
	-- Transmogrification
	{ key = "ITEM_ALERT_TRANSMOG", value = false, bool = true },
	{ key = "ITEM_ALERT_TRANSMOG_EVERYTHING", value = false, bool = true },
	-- Quality
	{ key = "ITEM_HIDE_JUNK", value = false, bool = true },
	{ key = "ITEM_QUALITY_PLAYER", value = 0 },
	{ key = "ITEM_QUALITY_GROUP", value = 0 },
	{ key = "ITEM_QUALITY_RAID", value = 0 },
	-- Anima Power
	{ key = "ANIMA_POWER", value = false, bool = true },
	-- Artifact
	{ key = "ARTIFACT_POWER", value = false, bool = true },
	{ key = "ARTIFACT_POWER_EXCLUDE_CURRENCY", value = false, bool = true },
	-- Reputation
	{ key = "FACTION_NAME_MINIFY", value = false, bool = true },
	{ key = "FACTION_NAME_MINIFY_LENGTH", value = 10 },
	-- Tooltips
	{ key = "CHAT_TOOLTIP_ITEM", value = false, bool = true },
	{ key = "CHAT_TOOLTIP_CURRENCY", value = false, bool = true },
	{ key = "CHAT_TOOLTIP_SPELL", value = false, bool = true },
	{ key = "CHAT_TOOLTIP_TALENT", value = false, bool = true },
	{ key = "CHAT_TOOLTIP_QUEST", value = false, bool = true },
	{ key = "CHAT_TOOLTIP_ACHIEVEMENT", value = false, bool = true },
	{ key = "CHAT_TOOLTIP_BATTLEPET", value = false, bool = true },
	{ key = "CHAT_TOOLTIP_DEATH", value = false, bool = true },
	{ key = "CHAT_TOOLTIP_GARRISON", value = false, bool = true },
	{ key = "CHAT_TOOLTIP_INSTANCELOCK", value = false, bool = true },
	{ key = "CHAT_TOOLTIP_GLYPH", value = false, bool = true },
	{ key = "CHAT_TOOLTIP_UNIT", value = false, bool = true },
	{ key = "CHAT_TOOLTIP_ARTIFACT", value = false, bool = true },
	{ key = "CHAT_TOOLTIP_KEYSTONE", value = false, bool = true },
	{ key = "CHAT_TOOLTIP_ANIMA_POWER", value = false, bool = true },
	{ key = "CHAT_TOOLTIP_COVENANT_CONDUIT", value = false, bool = true },
	-- Categories
	{ key = "CATEGORY_FLAGS", value = {} },
}

-- assigns the default table to the global table
function ns.config:metatableDefaults()
	setmetatable(_G[varName], {
		__index = function(self, key)
			for i = 1, #ns.config.defaults do
				local kv = ns.config.defaults[i]

				if kv.key == key then
					return kv.value
				end
			end
		end
	})
end

-- load options
-- data must be a table containing items like { key = string, value = ?, bool = 1nil }
function ns.config:load(data)
	for i = 1, #data do
		local kv = data[i]

		if kv.bool or type(kv.value) == "boolean" then
			ns.config.bool:write(kv.key, kv.value)
		else
			ns.config:write(kv.key, kv.value)
		end
	end
end

-- reset options to default
function ns.config:reset()
	table.wipe(_G[varName])
end

-- standard variable operations
-- ns.config:read(key[, fallback[, writeFallback]])
-- ns.config:write(key, value)
-- ns.config:remove(key)
do
	function ns.config:read(key, fallback, writeFallback)
		local db = _G[varName]

		if db then
			assert(type(key) == "string" and key:len() > 0, "Option variables require the key to be a non-empty string.")

			local value = db[key]

			if writeFallback and value == nil and fallback ~= nil then
				value = fallback

				db[key] = fallback
			end

			return value or fallback
		end
	end

	function ns.config:write(key, value)
		local db = _G[varName]

		if db then
			assert(type(key) == "string" and key:len() > 0, "Option variables require the key to be a non-empty string.")

			db[key] = value
			return true
		end

		return false
	end

	function ns.config:remove(key)
		return ns.config:write(key, nil)
	end
end

-- boolean related operations
-- ns.config.bool:read(key[, fallback[, writeFallback]])
-- ns.config.bool:write(key, value)
-- ns.config.bool:remove(key)
do
	ns.config.bool = {}

	function ns.config.bool:read(key, fallback, writeFallback)
		return ns.config:read(key, fallback, writeFallback) == true
	end

	function ns.config.bool:write(key, value)
		return ns.config:write(key, value == true)
	end

	function ns.config.bool:remove(key)
		return ns.config:remove(key)
	end
end

-- load defaults on new installations
ns.config:load(ns.config.defaults)
