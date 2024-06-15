local ns = select(2, ...) ---@class MiniLootNS

local locale = GetLocale()

---@class MiniLootNSLocale
ns.Locale = setmetatable({}, {
	__index = function(self, key)
		return format("[%s] %s", locale, tostring(key))
	end,
})

---@class MiniLootNSLocale
local L = ns.Locale

L.PANEL_DESCRIPTION = "This will contain customizations."

-- English

if locale == "deDE" then

--@localization(locale="deDE", format="lua_additive_table", handle-unlocalized="blank", escape-non-ascii=false, table-name="L")@

elseif locale == "esES" then

--@localization(locale="esES", format="lua_additive_table", handle-unlocalized="blank", escape-non-ascii=false, table-name="L")@

elseif locale == "esMX" then

--@localization(locale="esMX", format="lua_additive_table", handle-unlocalized="blank", escape-non-ascii=false, table-name="L")@

elseif locale == "frFR" then

--@localization(locale="frFR", format="lua_additive_table", handle-unlocalized="blank", escape-non-ascii=false, table-name="L")@

elseif locale == "itIT" then

--@localization(locale="itIT", format="lua_additive_table", handle-unlocalized="blank", escape-non-ascii=false, table-name="L")@

elseif locale == "koKR" then

--@localization(locale="koKR", format="lua_additive_table", handle-unlocalized="blank", escape-non-ascii=false, table-name="L")@

elseif locale == "ptBR" then

--@localization(locale="ptBR", format="lua_additive_table", handle-unlocalized="blank", escape-non-ascii=false, table-name="L")@

elseif locale == "ruRU" then

--@localization(locale="ruRU", format="lua_additive_table", handle-unlocalized="blank", escape-non-ascii=false, table-name="L")@

elseif locale == "zhCN" then

--@localization(locale="zhCN", format="lua_additive_table", handle-unlocalized="blank", escape-non-ascii=false, table-name="L")@

elseif locale == "zhTW" then

--@localization(locale="zhTW", format="lua_additive_table", handle-unlocalized="blank", escape-non-ascii=false, table-name="L")@

end
