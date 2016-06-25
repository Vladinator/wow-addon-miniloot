local addonName, ns = ...
ns.options = {}

do
	local unique = 1
	local loaded

	local function PrintExampleIcon()
		DEFAULT_CHAT_FRAME:AddMessage("Example: " .. ns.util:toLootIcon("|cff00ccff|Hitem:122284:::::::::::::::|h[WoW Token]|h|r", true, false), YELLOW_FONT_COLOR.r, YELLOW_FONT_COLOR.g, YELLOW_FONT_COLOR.b)
	end

	local optionGroups = {
		{
			label = "Common",
			description = "These options affect multiple type of messages.",
			options = {
				{
					checkbox = true,
					label = "Remove realm names",
					description = "Enable to hide the realm name on characters from other realms.",
					key = "NAME_SHORT"
				},
				{
					checkbox = true,
					label = "Prefix own messages",
					description = "Enable to prepend \"" .. YOU .. "\" to your own messages.",
					key = "ITEM_SELF_PREFIX"
				},
				{
					checkbox = true,
					label = "Prefix using character name",
					description = "Enable to use your character name in your own messages.",
					key = "ITEM_SELF_PREFIX_NAME",
					depends = "ITEM_SELF_PREFIX"
				},
				{
					checkbox = true,
					label = "Remove prefix if solo",
					description = "Enable to remove the \"" .. YOU .. "\" prefix to your own messages. This only affects you when playing solo.",
					key = "ITEM_SELF_TRIM_SOLO",
					depends = "ITEM_SELF_PREFIX"
				},
				{
					number = true,
					min = 0,
					max = 50,
					label = "Icon trim",
					description = "The amount of trim around icon textures. Set to 8 for default and recommended value. Set to 0 to disable trim behavior.",
					key = "ICON_TRIM",
					onSave = PrintExampleIcon
				},
				{
					number = true,
					min = 0,
					max = 100,
					label = "Icon size",
					description = "The size of icons used in the chat. Set to 0 for automatic height.",
					key = "ICON_SIZE",
					onSave = PrintExampleIcon
				},
			},
		},
		{
			label = "Items",
			description = "Customize how item related messages appear.",
			options = {
				{
					checkbox = true,
					label = "Count items in bag",
					description = "Enable to append the amount of items you have in your bags.",
					key = "ITEM_COUNT_BAGS"
				},
				{
					checkbox = true,
					label = "Include bank",
					description = "Check to include items in bank.",
					key = "ITEM_COUNT_BAGS_INCLUDE_BANK",
					depends = "ITEM_COUNT_BAGS"
				},
				{
					checkbox = true,
					label = "Include charges",
					description = "Check to include amount of charges.",
					key = "ITEM_COUNT_BAGS_INCLUDE_CHARGES",
					depends = "ITEM_COUNT_BAGS"
				},
			},
		},
		{
			label = "Transmogrification",
			description = "Customize how items with appearances appear.",
			options = {
				{
					checkbox = true,
					label = "Color uncollected appearances",
					description = "Enable to color uncollected appearances you are eligible for to obtain.",
					key = "ITEM_ALERT_TRANSMOG"
				},
				-- {
				-- 	checkbox = true,
				-- 	label = "Include items I am not eligible to obtain",
				-- 	description = "Enable to color uncollected appearances across all classes.",
				-- 	key = "ITEM_ALERT_TRANSMOG_UNCOLLECTED",
				-- 	depends = "ITEM_ALERT_TRANSMOG"
				-- },
				{
					checkbox = true,
					label = "Include items looted by others",
					description = "Enable to color uncollected appearances on items looted by others.",
					key = "ITEM_ALERT_TRANSMOG_EVERYTHING",
					depends = "ITEM_ALERT_TRANSMOG"
				},
			},
		},
		{
			label = "Quality",
			description = "Customize what item qualities are included. Only items at or above the selected thresholds will appear.",
			options = {
				{
					checkbox = true,
					label = "Hide junk items",
					description = "Check to hide junk loot regardless of the options below.",
					key = "ITEM_HIDE_JUNK"
				},
				{
					dropdown = true,
					label = "Player (Solo)",
					description = "Select the minimum or greater quality of items you wish to display.",
					key = "ITEM_QUALITY_PLAYER"
				},
				{
					dropdown = true,
					label = "Group (5-man)",
					description = "Select the minimum or greater quality of items you wish to display.",
					key = "ITEM_QUALITY_GROUP"
				},
				{
					dropdown = true,
					label = "Raid",
					description = "Select the minimum or greater quality of items you wish to display.",
					key = "ITEM_QUALITY_RAID"
				},
			},
		},
		{
			label = "Artifact",
			description = "Customize how artifact related messages appear.",
			options = {
				{
					checkbox = true,
					label = "Show artifact power as loot",
					description = "Enable to summarize the gained power.",
					key = "ARTIFACT_POWER"
				},
			},
		},
		{
			label = "Reputation",
			-- description = "Customize how faction names are reported.",
			options = {
				{
					checkbox = true,
					label = "Shorten faction name",
					description = "Enable to shorten names like \"Court of Farondis\" into \"CouOfFar\", and longer names like \"Order of the Awakened\" into \"OrOfThAw\".",
					key = "FACTION_NAME_MINIFY"
				},
				{
					number = true,
					label = "Maximum length",
					description = "Set the desired length before shortening. Setting this to 10 means that \"Dalaran\" is shown as it is because it is less than ten characters.",
					key = "FACTION_NAME_MINIFY_LENGTH",
					depends = "FACTION_NAME_MINIFY",
				},
			},
		},
		{
			label = "Tooltips",
			description = "Select what kind of hyperlinks you wish to automatically appear when you hover over them in the chat.",
			options = {
				{
					checkbox = true,
					label = "Show item tooltips",
					description = "Hover items in chat and display their tooltip.",
					key = "CHAT_TOOLTIP_ITEM"
				},
				{
					checkbox = true,
					label = "Show currency tooltips",
					description = "Hover currency in chat and display their tooltip.",
					key = "CHAT_TOOLTIP_CURRENCY"
				},
				{
					checkbox = true,
					label = "Show spell tooltips",
					description = "Hover spells in chat and display their tooltip.",
					key = "CHAT_TOOLTIP_SPELL"
				},
				{
					checkbox = true,
					label = "Show talent tooltips",
					description = "Hover talents in chat and display their tooltip.",
					key = "CHAT_TOOLTIP_TALENT"
				},
				{
					checkbox = true,
					label = "Show quest tooltips",
					description = "Hover quests in chat and display their tooltip.",
					key = "CHAT_TOOLTIP_QUEST"
				},
				{
					checkbox = true,
					label = "Show achievement tooltips",
					description = "Hover achievements in chat and display their tooltip.",
					key = "CHAT_TOOLTIP_ACHIEVEMENT"
				},
				{
					checkbox = true,
					label = "Show trade tooltips",
					description = "Hover trade links in chat and display their tooltip.",
					key = "CHAT_TOOLTIP_TRADE"
				},
				{
					checkbox = true,
					label = "Show Battle Pet tooltips",
					description = "Hover battle pet links in chat and display their tooltip.",
					key = "CHAT_TOOLTIP_BATTLEPET"
				},
				{
					checkbox = true,
					label = "Show Garrison and Order Hall tooltips",
					description = "Hover Garrison and Order Hall links in chat and display their tooltip.",
					key = "CHAT_TOOLTIP_GARRISON"
				},
				{
					checkbox = true,
					label = "Show instance lock tooltips",
					description = "Hover instance lock links in chat and display their tooltip.",
					key = "CHAT_TOOLTIP_INSTANCELOCK"
				},
				{
					checkbox = true,
					label = "Show death tooltips",
					description = "Hover death links in chat and display their tooltip.",
					key = "CHAT_TOOLTIP_DEATH"
				},
				{
					checkbox = true,
					label = "Show glyph tooltips",
					description = "Hover glyph links in chat and display their tooltip.",
					key = "CHAT_TOOLTIP_GLYPH"
				},
			},
		},
	}

	local handlers
	handlers = {
		panel = {
			okay = function()
			end,
			cancel = function()
			end,
			default = function()
				ns.config:reset()
			end,
			refresh = function()
				for i = 1, #loaded.widgets do
					local widget = loaded.widgets[i]

					if type(widget.dropdown) == "table" then
						local value = ns.config:read(widget.dropdown.option.key, 0)

						widget.dropdown.defaultValue = value
						widget.dropdown.value = value
						widget.dropdown.oldValue = value
					end

					if type(widget.refresh) == "function" then
						widget.refresh(widget)
					end
				end
			end
		},
		option = {
			default = {
				update = function(self)
					if self.option.depends then
						self:SetEnabled(ns.config.bool:read(self.option.depends))
					end
					self:SetChecked(ns.config.bool:read(self.option.key))
				end,
				click = function(self)
					ns.config.bool:write(self.option.key, self:GetChecked())
					if self.option.onSave then
						self.option:onSave()
					end
					handlers.panel.refresh()
				end,
			},
			number = {
				update = function(self)
					if self.option.depends then
						self:SetEnabled(ns.config.bool:read(self.option.depends))
					end
					if self:HasFocus() then
						return
					end
					if self.option.number then
						self:SetNumber(ns.config:read(self.option.key))
					else
						self:SetText(ns.config:read(self.option.key))
					end
					self:SetCursorPosition(0)
				end,
				save = function(self)
					if self.option.number then
						local value = self:GetNumber()
						if self.option.min then
							value = math.max(self.option.min, value)
						end
						if self.option.max then
							value = math.min(self.option.max, value)
						end
						ns.config:write(self.option.key, value)
					else
						ns.config:write(self.option.key, self:GetText())
					end
					if self.option.onSave then
						self.option:onSave()
					end
					handlers.panel.refresh()
				end
			},
		},
		category = {
			update = function(self)
				local flags = ns.config:read("CATEGORY_FLAGS", {})
				self:SetChecked(flags[self.category.id])
			end,
			click = function(self)
				local flags = ns.config:read("CATEGORY_FLAGS", {})
				flags[self.category.id] = self:GetChecked() and true or nil
				ns.config:write("CATEGORY_FLAGS", flags)
				handlers.panel.refresh()
			end
		},
		group = {
			update = function(self)
				local flags = ns.config:read("CATEGORY_FLAGS", {})
				self:SetChecked(flags[self.group.group])
			end,
			click = function(self)
				local flags = ns.config:read("CATEGORY_FLAGS", {})
				flags[self.group.group] = self:GetChecked() and true or nil
				ns.config:write("CATEGORY_FLAGS", flags)
				handlers.panel.refresh()
			end
		},
	}

	local function CreateTitle(panel, name, version)
		local title = CreateFrame("Frame", "$parentTitle" .. unique, panel)
		unique = unique + 1
		title:SetPoint("TOPLEFT", panel, "TOPLEFT")
		title:SetPoint("TOPRIGHT", panel, "TOPRIGHT")
		title:SetHeight(70)

		title.text = title:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		title.text:SetJustifyH("CENTER")
		title.text:SetPoint("TOP", title, "TOP", 0, -20)
		title.text:SetText(name)

		title.version = title:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		title.version:SetJustifyH("CENTER");
		title.version:SetPoint("TOP", title, "TOP", 0, -46)
		title.version:SetText(version)

		return title
	end

	local function CreateHeader(panel, anchor, text)
		local header = CreateFrame("Frame", "$parentHeader" .. unique, anchor:GetParent() or anchor)
		unique = unique + 1
		header:SetHeight(18)

		if anchor:GetObjectType() == "Frame" then
			header:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT")
			header:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT")
		else
			header:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", -10, 0)
			header:SetPoint("TOPRIGHT", panel, "BOTTOMRIGHT")
		end

		header.label = header:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
		header.label:SetPoint("TOP")
		header.label:SetPoint("BOTTOM")
		header.label:SetJustifyH("CENTER")
		header.label:SetText(text)

		header.left = header:CreateTexture(nil, "BACKGROUND")
		header.left:SetHeight(8)
		header.left:SetPoint("LEFT", 10, 0)
		header.left:SetPoint("RIGHT", header.label, "LEFT", -5, 0) -- TODO: repeat at the end?
		header.left:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
		header.left:SetTexCoord(.81, .94, .5, 1)

		header.right = header:CreateTexture(nil, "BACKGROUND")
		header.right:SetHeight(8)
		header.right:SetPoint("RIGHT", -10, 0)
		header.right:SetPoint("LEFT", header.label, "RIGHT", 5, 0)
		header.right:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
		header.right:SetTexCoord(.81, .94, .5, 1)

		return header
	end

	local function CreateParagraph(anchor, text)
		local MAX_HEIGHT = 255

		local header = CreateFrame("Frame", "$parentParagraph" .. unique, anchor:GetParent() or anchor)
		unique = unique + 1
		header:SetHeight(MAX_HEIGHT)

		header:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT")
		header:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT")

		header.label = header:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
		header.label:SetPoint("TOPLEFT", 10, -5)
		header.label:SetPoint("BOTTOMRIGHT", -10, 5)
		header.label:SetJustifyH("LEFT")
		header.label:SetJustifyV("TOP")
		header.label:SetText(text)
		header.label:SetHeight(MAX_HEIGHT)
		
		header.label:SetWordWrap(true)
		header.label:SetNonSpaceWrap(true)
		header.label:SetMaxLines(10)

		header:SetScript("OnUpdate", function()
			if header:GetHeight() < MAX_HEIGHT and header.label:GetHeight() == header:GetHeight() then
				header:SetScript("OnUpdate", nil)
			end

			local height = header.label:GetStringHeight() + 5
			header.label:SetHeight(height)
			header:SetHeight(height)
		end)

		-- TODO: OBSCOLETE?
		header:SetScript("OnSizeChanged", function()
			local height = header.label:GetStringHeight() + 5
			header.label:SetHeight(height)
			header:SetHeight(height)
		end)

		-- header:SetScript("OnHide", function()
		-- 	header:SetHeight(MAX_HEIGHT)
		-- 	header.label:SetHeight(MAX_HEIGHT)
		-- end)

		return header
	end

	local function CreateCheckbox(anchor, text, tooltip)
		local checkbox = CreateFrame("CheckButton", "$parentCheckbox" .. unique, anchor:GetParent() or anchor, "InterfaceOptionsCheckButtonTemplate")
		unique = unique + 1
		checkbox.Text:SetText(text)
		checkbox.tooltipText = tooltip

		if anchor:GetObjectType() == "Frame" then
			checkbox:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 10, -10)
		else
			checkbox:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, 0)
		end

		return checkbox
	end

	local function CreateInput(anchor, kind, text, tooltip)
		local editbox = CreateFrame("EditBox", "$parentEditBox" .. unique, anchor:GetParent() or anchor, "InputBoxTemplate")
		unique = unique + 1
		editbox:SetFontObject("GameFontHighlight")
		editbox:SetSize(160, 22)
		editbox:SetAutoFocus(false)
		editbox:SetHyperlinksEnabled(false)
		editbox:SetMultiLine(false)
		editbox:SetIndentedWordWrap(false)
		editbox:SetMaxLetters(255)
		editbox.tooltipText = tooltip

		if kind == "number" then
			editbox:SetMaxLetters(4)
			editbox:SetNumeric(true)
			editbox:SetNumber(text)
		else
			editbox:SetText(text)
		end

		editbox:SetScript("OnEscapePressed", function() editbox:ClearFocus() end)
		editbox:SetScript("OnEnterPressed", function() editbox:ClearFocus() end)
		editbox:SetScript("OnEditFocusLost", handlers.panel.refresh)

		editbox:SetScript("OnEnter", function() if editbox.tooltipText then GameTooltip:SetOwner(editbox, "ANCHOR_RIGHT") GameTooltip:SetText(editbox.tooltipText, nil, nil, nil, nil, true) GameTooltip:Show() end end)
		editbox:SetScript("OnLeave", function() GameTooltip:Hide() end)

		if anchor:GetObjectType() == "Frame" then
			editbox:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 10, -10)
		else
			editbox:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, 0)
		end

		return editbox
	end

	local function CreateButton(anchor, text, tooltip)
		local button = CreateFrame("Button", "$parentButton" .. unique, anchor:GetParent() or anchor, "UIPanelButtonTemplate")
		unique = unique + 1
		button:SetSize(80, 22)
		button:SetText(text)
		button.tooltipText = "|cffffd100" .. tooltip .. "|r"

		if anchor:GetObjectType() == "Frame" then
			button:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 10, -10)
		else
			button:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, 0)
		end

		return button
	end

	local function CreateDropdownOptions(key)
		local temp = {}

		if key == "ITEM_QUALITY_PLAYER" or key == "ITEM_QUALITY_GROUP" or key == "ITEM_QUALITY_RAID" then
			-- table.insert(temp, { value = -1, label = NONE, r = 1, g = 1, b = 1, hex = "ffffffff" })

			for i = 0, 7 do -- Poor to Artifact (8 is WoW Token)
				local r, g, b, hex = GetItemQualityColor(i)

				table.insert(temp, { value = i, label = _G["ITEM_QUALITY" .. i .. "_DESC"], r = r, g = g, b = b, hex = hex })
			end
		end

		return temp
	end

	local function CreateDropdownSetValue(option)
		ns.config:write(option.arg2, option.value)
		option.arg1:SetValue(option.value)
		handlers.panel.refresh()
	end

	local function CreateDropdownInitialize(dropdown)
		local key = dropdown.option.key
		local selectedValue = UIDropDownMenu_GetSelectedValue(dropdown)
		local info = UIDropDownMenu_CreateInfo()
		info.func = CreateDropdownSetValue
		info.arg1 = dropdown
		info.arg2 = key

		for i = 1, #dropdown.option.options do
			local option = dropdown.option.options[i]

			info.colorCode = "|c" .. option.hex
			info.text = option.label
			info.value = option.value
			info.checked = info.value == selectedValue

			UIDropDownMenu_AddButton(info)
		end
	end

	local function CreateDropdownSetValue(dropdown, value)
		dropdown.value = value
		UIDropDownMenu_SetSelectedValue(dropdown, value)
	end

	local function CreateDropdownGetValue(dropdown)
		return UIDropDownMenu_GetSelectedValue(dropdown)
	end

	local function CreateDropdownRefreshValue(dropdown)
		UIDropDownMenu_Initialize(dropdown, CreateDropdownInitialize)
		UIDropDownMenu_SetSelectedValue(dropdown, dropdown.value)
	end

	local function CreateDropdown(anchor, option, text, tooltip)
		local container = CreateFrame("ScrollFrame", "$parentContainer" .. unique, anchor:GetParent() or anchor)
		unique = unique + 1

		local dropdown = CreateFrame("Frame", "$parentDropdown" .. unique, container, "UIDropDownMenuTemplate")
		container.dropdown = dropdown
		unique = unique + 1
		dropdown:SetPoint("TOPLEFT", -12, -20)

		local w, h = dropdown:GetSize()
		container:SetSize(w, h + 18)

		dropdown.label = dropdown:CreateFontString(nil, "BACKGROUND", "GameFontHighlight")
		dropdown.label:SetPoint("BOTTOMLEFT", "$parent", "TOPLEFT", 16, 3)
		dropdown.label:SetText(text)

		dropdown.option = option
		dropdown.defaultValue = 0
		dropdown.value = ns.config:read(option.key, 0)
		dropdown.oldValue = dropdown.value
		dropdown.tooltip = tooltip

		dropdown.SetValue = CreateDropdownSetValue
		dropdown.GetValue = CreateDropdownGetValue
		dropdown.RefreshValue = CreateDropdownRefreshValue

		UIDropDownMenu_SetWidth(dropdown, 90)
		UIDropDownMenu_Initialize(dropdown, CreateDropdownInitialize)
		UIDropDownMenu_SetSelectedValue(dropdown, dropdown.value)

		if anchor:GetObjectType() == "Frame" then
			container:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 10, -10)
		else
			container:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, 0)
		end

		return container
	end

	local function CreatePanel(categories)
		local panel = CreateFrame("Frame", addonName .. "Panel" .. unique, InterfaceOptionsFramePanelContainer)
		unique = unique + 1
		panel.widgets = {}
		panel.name = addonName

		-- add the standard interface buttons
		for key, func in pairs(handlers.panel) do
			panel[key] = func
		end

		-- create scroll, bar, and content frame
		do
			local PANEL_SCROLL_HEIGHT = 1100 -- TODO: dynamic max?

			panel.scroll = CreateFrame("ScrollFrame", nil, panel)
			panel.scroll:SetPoint("TOPLEFT", 10, -10)
			panel.scroll:SetPoint("BOTTOMRIGHT", -26, 10)

			panel.scroll.bar = CreateFrame("Slider", nil, panel.scroll, "UIPanelScrollBarTemplate")
			panel.scroll.bar.scrollStep = 50
			panel.scroll.bar:SetPoint("TOPLEFT", panel, "TOPRIGHT", -22, -26)
			panel.scroll.bar:SetPoint("BOTTOMLEFT", panel, "BOTTOMRIGHT", 22, 26)
			panel.scroll.bar:SetMinMaxValues(0, PANEL_SCROLL_HEIGHT)
			panel.scroll.bar:SetValueStep(panel.scroll.bar.scrollStep)
			panel.scroll.bar:SetValue(0)
			panel.scroll.bar:SetWidth(16)
			panel.scroll.bar:SetScript("OnValueChanged", function(_, value) panel.scroll:SetVerticalScroll(value) end)

			panel.scroll:EnableMouse(true)
			panel.scroll:EnableMouseWheel(true)
			panel.scroll:SetScript("OnMouseWheel", function(_, delta) local a, b = panel.scroll.bar:GetMinMaxValues() local value = min(b, max(a, panel.scroll:GetVerticalScroll() - (delta * panel.scroll.bar.scrollStep))) panel.scroll:SetVerticalScroll(value) panel.scroll.bar:SetValue(value) end)

			panel.content = CreateFrame("Frame", nil, panel.scroll)
			panel.scroll:SetScript("OnSizeChanged", function(_, width, height) panel.content:SetSize(width, height) end)

			panel.scroll:SetScrollChild(panel.content)
		end

		-- add widgets to the content frame
		do
			local last = CreateTitle(panel.content, addonName, GetAddOnMetadata(addonName, "Version"))

			-- add options
			do
				for i = 1, #optionGroups do
					local optionGroup = optionGroups[i]

					last = CreateHeader(panel.content, last, optionGroup.label)

					if optionGroup.description then
						last = CreateParagraph(last, optionGroup.description)
					end

					for j = 1, #optionGroup.options do
						local option = optionGroup.options[j]

						if option.checkbox then
							last = CreateCheckbox(last, option.label, option.description)
							last.option = option
							last.refresh = handlers.option.default.update
							last:SetScript("OnClick", handlers.option.default.click)
							table.insert(panel.widgets, last)

						elseif option.number then
							last = CreateInput(last, "number", option.label, option.description)
							last.option = option
							last.refresh = handlers.option.number.update
							last:SetScript("OnEnterPressed", function(self, ...) handlers.option.number.save(self, ...) self:ClearFocus() end)
							table.insert(panel.widgets, last)

						elseif option.dropdown then
							option.options = CreateDropdownOptions(option.key)
							last = CreateDropdown(last, option, option.label, option.description)
							last.option = option
							last.refresh = function(last) last.dropdown:RefreshValue() end
							table.insert(panel.widgets, last)
						end
					end
				end
			end

			-- add categories
			do
				last = CreateHeader(panel.content, last, "Ignore")
				last = CreateParagraph(last, "Select the type of messages you do not wish the addon to intercept and modify. Ignored messages appear as default.")

				for i = 1, #categories do
					local group = categories[i]
					local temp = ns.locale["DESCRIPTION_GROUP_" .. group.group]

					if not temp then
						for j = 1, #group.categories do
							local category = group.categories[j]

							temp = (temp and (temp .. "\n") or "") .. " • " .. category.label .. ": " .. category.description
						end
					end

					last = CreateCheckbox(last, group.label, temp)
					last.group = group
					last.refresh = handlers.group.update
					last:SetScript("OnClick", handlers.group.click)
					table.insert(panel.widgets, last)
				end
			end
		end

		-- refresh when panel is shown
		panel:SetScript("OnShow", handlers.panel.refresh)

		return panel
	end

	function ns.options:create()
		if loaded then
			return true
		end

		loaded = CreatePanel(ns.util:categories())
		InterfaceOptions_AddCategory(loaded)

		return true
	end
end
