local addonName, ns = ...
ns.options = {}

do
	local unique = 1
	local loaded

	local function PrintExampleIcon()
		ns.DEFAULT_CHAT_FRAME:AddMessage(format(ns.locale.OPTION_EXAMPLE, ns.util:toLootIcon("|cff00ccff|Hitem:122284:::::::::::::::|h[WoW Token]|h|r", true, false)), YELLOW_FONT_COLOR.r, YELLOW_FONT_COLOR.g, YELLOW_FONT_COLOR.b)
	end

	local function IsFrameInstanceOf(frame, name)
		return type(frame) == "table" and type(frame.GetObjectType) == "function" and frame:GetObjectType() == name
	end

	local function ValidateChatFrameSelection(option, noExample)
		local chatFrame = ns.config:read(option.key)

		if not IsFrameInstanceOf(_G[chatFrame], "Frame") then
			chatFrame = DEFAULT_CHAT_FRAME:GetName()
		end

		ns.config:write(option.key, chatFrame)
		ns.DEFAULT_CHAT_FRAME = _G[chatFrame]

		if noExample ~= true then
			PrintExampleIcon()
		end
	end

	local optionGroups = {
		{
			label = ns.locale.OPTION_COMMON_TITLE,
			description = ns.locale.OPTION_COMMON_DESC,
			options = {
				{
					checkbox = true,
					key = "NAME_SHORT"
				},
				{
					checkbox = true,
					key = "ITEM_SELF_PREFIX"
				},
				{
					checkbox = true,
					key = "ITEM_SELF_PREFIX_NAME",
					depends = "ITEM_SELF_PREFIX"
				},
				{
					checkbox = true,
					key = "ITEM_SELF_TRIM_SOLO",
					depends = "ITEM_SELF_PREFIX"
				},
				{
					number = true,
					min = 0,
					max = 50,
					key = "ICON_TRIM",
					onSave = PrintExampleIcon
				},
				{
					number = true,
					min = 0,
					max = 100,
					key = "ICON_SIZE",
					onSave = PrintExampleIcon
				},
				{
					dropdown = true,
					key = "CHAT_FRAME",
					onSave = ValidateChatFrameSelection,
					onSaveOnLoad = true
				},
			},
		},
		{
			label = ns.locale.OPTION_REPORT_TITLE,
			description = ns.locale.OPTION_REPORT_DESC,
			options = {
				{
					checkbox = true,
					key = "REPORT_IN_COMBAT",
				},
				{
					number = true,
					min = 0,
					max = 100,
					key = "REPORT_INTERVAL",
				},
			},
		},
		{
			label = ns.locale.OPTION_ITEMS_TITLE,
			description = ns.locale.OPTION_ITEMS_DESC,
			options = {
				{
					checkbox = true,
					key = "ITEM_COUNT_BAGS"
				},
				{
					checkbox = true,
					key = "ITEM_COUNT_BAGS_INCLUDE_BANK",
					depends = "ITEM_COUNT_BAGS"
				},
				{
					checkbox = true,
					key = "ITEM_COUNT_BAGS_INCLUDE_CHARGES",
					depends = "ITEM_COUNT_BAGS"
				},
				{
					checkbox = true,
					key = "ITEM_PRINT_DEFAULT_RAID"
				},
				{
					checkbox = true,
					key = "ITEM_SHOW_ITEM_LEVEL"
				},
				{
					checkbox = true,
					key = "ITEM_SHOW_ITEM_LEVEL_ONLY_EQUIPMENT",
					depends = "ITEM_SHOW_ITEM_LEVEL"
				},
			},
		},
		{
			label = ns.locale.OPTION_TRANSMOGRIFICATION_TITLE,
			description = ns.locale.OPTION_TRANSMOGRIFICATION_DESC,
			options = {
				{
					checkbox = true,
					key = "ITEM_ALERT_TRANSMOG"
				},
				{
					checkbox = true,
					key = "ITEM_ALERT_TRANSMOG_EVERYTHING",
					depends = "ITEM_ALERT_TRANSMOG"
				},
			},
		},
		{
			label = ns.locale.OPTION_QUALITY_TITLE,
			description = ns.locale.OPTION_QUALITY_DESC,
			options = {
				{
					checkbox = true,
					key = "ITEM_HIDE_JUNK"
				},
				{
					dropdown = true,
					key = "ITEM_QUALITY_PLAYER"
				},
				{
					dropdown = true,
					key = "ITEM_QUALITY_GROUP"
				},
				{
					dropdown = true,
					key = "ITEM_QUALITY_RAID"
				},
			},
		},
		{
			label = ns.locale.OPTION_ANIMA_POWER_COLLECTION_TITLE,
			description = ns.locale.OPTION_ANIMA_POWER_COLLECTION_DESC,
			options = {
				{
					checkbox = true,
					key = "ANIMA_POWER"
				},
			},
		},
		{
			label = ns.locale.OPTION_ARTIFACT_TITLE,
			description = ns.locale.OPTION_ARTIFACT_DESC,
			options = {
				{
					checkbox = true,
					key = "ARTIFACT_POWER"
				},
				{
					checkbox = true,
					key = "ARTIFACT_POWER_EXCLUDE_CURRENCY",
					-- depends = "ARTIFACT_POWER"
				},
			},
		},
		{
			label = ns.locale.OPTION_REPUTATION_TITLE,
			description = ns.locale.OPTION_REPUTATION_DESC,
			options = {
				{
					checkbox = true,
					key = "FACTION_NAME_MINIFY"
				},
				{
					number = true,
					key = "FACTION_NAME_MINIFY_LENGTH",
					depends = "FACTION_NAME_MINIFY",
				},
			},
		},
		{
			label = ns.locale.OPTION_TOOLTIPS_TITLE,
			description = ns.locale.OPTION_TOOLTIPS_DESC,
			options = {
				{
					checkbox = true,
					key = "CHAT_TOOLTIP_ITEM"
				},
				{
					checkbox = true,
					key = "CHAT_TOOLTIP_CURRENCY"
				},
				{
					checkbox = true,
					key = "CHAT_TOOLTIP_SPELL"
				},
				{
					checkbox = true,
					key = "CHAT_TOOLTIP_TALENT"
				},
				{
					checkbox = true,
					key = "CHAT_TOOLTIP_QUEST"
				},
				{
					checkbox = true,
					key = "CHAT_TOOLTIP_ACHIEVEMENT"
				},
				{
					checkbox = true,
					key = "CHAT_TOOLTIP_TRADE"
				},
				{
					checkbox = true,
					key = "CHAT_TOOLTIP_BATTLEPET"
				},
				{
					checkbox = true,
					key = "CHAT_TOOLTIP_GARRISON"
				},
				{
					checkbox = true,
					key = "CHAT_TOOLTIP_INSTANCELOCK"
				},
				{
					checkbox = true,
					key = "CHAT_TOOLTIP_DEATH"
				},
				{
					checkbox = true,
					key = "CHAT_TOOLTIP_GLYPH"
				},
				{
					checkbox = true,
					key = "CHAT_TOOLTIP_UNIT"
				},
				{
					checkbox = true,
					key = "CHAT_TOOLTIP_ARTIFACT"
				},
				{
					checkbox = true,
					key = "CHAT_TOOLTIP_KEYSTONE"
				},
				{
					checkbox = true,
					key = "CHAT_TOOLTIP_ANIMA_POWER"
				},
				{
					checkbox = true,
					key = "CHAT_TOOLTIP_COVENANT_CONDUIT"
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
			header:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", anchor.radios and 0 or -10, 0)
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
			local n = type(text) == "number" and text or tonumber(text)
			if n then editbox:SetNumber(n) end
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

		elseif key == "CHAT_FRAME" then
			for i = 1, NUM_CHAT_WINDOWS do
				table.insert(temp, { value = "ChatFrame" .. i, label = "ChatFrame" .. i })
			end
		end

		return temp
	end

	--[=[
	local function CreateDropdownInitializeSetValue(option)
		ns.config:write(option.arg2, option.value)
		option.arg1:SetValue(option.value)
		if option.arg1.option.onSave then
			option.arg1.option:onSave()
		end
		handlers.panel.refresh()
	end

	local function CreateDropdownInitialize(dropdown)
		local key = dropdown.option.key
		local selectedValue = UIDropDownMenu_GetSelectedValue(dropdown)
		local info = UIDropDownMenu_CreateInfo()
		info.func = CreateDropdownInitializeSetValue
		info.arg1 = dropdown
		info.arg2 = key

		for i = 1, #dropdown.option.options do
			local option = dropdown.option.options[i]
			info.colorCode = nil
			info.disabled = nil

			info.text = option.label
			info.value = option.value
			info.checked = info.value == selectedValue

			if option.hex then
				info.colorCode = "|c" .. option.hex
			end

			if key == "CHAT_FRAME" then
				local chatFrame = _G[option.value]
				info.disabled = not IsFrameInstanceOf(chatFrame, "Frame")

				if not info.disabled then
					local chatTab = _G[option.value .. "Tab"]

					if IsFrameInstanceOf(chatTab, "Button") then
						local chatTabText = chatTab:GetText()

						if chatTabText then
							info.text = info.text .. " (" .. chatTabText .. ")"
						end
					end
				end
			end

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
		container:SetSize(587, 50)

		local dropdown = CreateFrame("Frame", "$parentDropdown" .. unique, container, "UIDropDownMenuTemplate")
		container.dropdown = dropdown
		unique = unique + 1
		dropdown:SetPoint("TOPLEFT", -12, -20)

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

		UIDropDownMenu_SetWidth(dropdown, 150)
		UIDropDownMenu_Initialize(dropdown, CreateDropdownInitialize)
		UIDropDownMenu_SetSelectedValue(dropdown, dropdown.value)

		if anchor:GetObjectType() == "Frame" then
			container:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -10)
		else
			container:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", -10, 0)
		end

		return container
	end
	--]=]

	local function CreateDropdownRadio(anchor, option, text, tooltip)
		local container = CreateFrame("ScrollFrame", "$parentContainer" .. unique, anchor:GetParent() or anchor)
		unique = unique + 1
		container:SetSize(587, 32 * #option.options + 8)

		local radios = CreateFrame("Frame", "$parentRadios" .. unique, container)
		container.radios = radios
		unique = unique + 1
		radios:SetPoint("TOPLEFT", 0, -20)
		radios:SetSize(container:GetSize())

		radios.label = radios:CreateFontString(nil, "BACKGROUND", "GameFontHighlight")
		radios.label:SetPoint("BOTTOMLEFT", "$parent", "TOPLEFT", 16, 3)
		radios.label:SetText(text)

		radios.option = option
		radios.defaultValue = 0
		radios.value = ns.config:read(option.key, 0)
		radios.oldValue = radios.value
		radios.tooltip = tooltip
		radios.buttons = {}

		local function RadioRefresh(radio)
			if radio.options.hex then
				radio.text:SetText("|c" .. radio.options.hex .. radio.options.label .. "|r")
			else
				radio.text:SetText(radio.options.label)
			end

			if radio.option.key == "CHAT_FRAME" then
				local chatFrame = _G[radio.options.value]

				if IsFrameInstanceOf(chatFrame, "Frame") then
					local chatTab = _G[radio.options.value .. "Tab"]

					if IsFrameInstanceOf(chatTab, "Button") then
						local chatTabText = chatTab:GetText()

						if chatTabText then
							radio.text:SetText(radio.text:GetText() .. " (" .. chatTabText .. ")")
						end
					end
				end
			end

			radio:SetChecked(ns.config:read(radio.option.key, 0) == radio.parent.value and radio.parent.value == radio.options.value)
		end

		local function RadioClick(radio)
			radio.parent:SetValue(radio.options.value)
			if radio.option.onSave then
				radio.option:onSave()
			end
			handlers.panel.refresh()
		end

		for i = 1, #option.options do
			local radio = CreateFrame("CheckButton", "$parentRadio" .. unique, radios, "UICheckButtonTemplate")
			unique = unique + 1

			radio.parent = radios
			radio.index = i
			radio.option = option
			radio.options = option.options[i]

			if not radio.text then
				radio.text = radio:CreateFontString(nil, "ARTWORK", "GameFontNormal")
				radio.text:SetSize(150, 32)
				radio.text:SetPoint("LEFT", radio, "RIGHT", 5, 0)
				radio.text:SetJustifyH("LEFT")
			end

			radio.text:SetTextColor(1, 1, 1)
			radio.text:SetText(radio.options.label)
			radio:SetSize(32, 32)

			radio.RefreshValue = RadioRefresh
			radio:SetScript("OnClick", RadioClick)

			if radios.buttons[i - 1] then
				radio:SetPoint("BOTTOMLEFT", radios.buttons[i - 1] or radios, "BOTTOMLEFT", 0, -30)
			else
				radio:SetPoint("TOPLEFT", radios, "TOPLEFT", 16, -4)
			end

			table.insert(radios.buttons, radio)
		end

		-- border around the radio options
		do
			local first = radios.buttons[1]
			local last = radios.buttons[#radios.buttons]

			if first and last then
				local border = radios:CreateTexture(nil, "OVERLAY")
				border:SetColorTexture(1, 1, 1, .1)
				border:SetPoint("TOPLEFT", first, "TOPLEFT", 0, 0)
				border:SetPoint("BOTTOMRIGHT", last.text, "BOTTOMRIGHT", 32, -10)
			end
		end

		local function RadiosSet(radios, value)
			radios.value = value
			ns.config:write(radios.option.key, value)
		end

		local function RadiosGet(radios)
			return ns.config:read(radios.option.key, 0)
		end

		local function RadiosRefresh(radios)
			for i = 1, #radios.buttons do
				radios.buttons[i]:RefreshValue()
			end
		end

		radios.SetValue = RadiosSet
		radios.GetValue = RadiosGet
		radios.RefreshValue = RadiosRefresh

		if anchor:GetObjectType() == "Frame" then
			container:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -10)
		else
			container:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", anchor.radios and 0 or -10, 0)
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
			local PANEL_SCROLL_HEIGHT = 2500 -- TODO: dynamic max?

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

						option.label = option.label or (option.key and ns.locale["OPTION_" .. option.key .. "_TITLE"] or "")
						option.description = option.description or (option.key and ns.locale["OPTION_" .. option.key .. "_DESC"] or "")

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
							last = CreateDropdownRadio(last, option, option.label, option.description)
							last.option = option
							last.refresh = function(last) last.radios:RefreshValue() end
							table.insert(panel.widgets, last)
						end
					end
				end
			end

			-- add categories
			do
				last = CreateHeader(panel.content, last, ns.locale.OPTION_IGNORE_GROUP_TITLE)
				last = CreateParagraph(last, ns.locale.OPTION_IGNORE_GROUP_DESC)

				for i = 1, #categories do
					local group = categories[i]

					last = CreateCheckbox(last, group.label, group.description)
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

		for i = 1, #optionGroups do
			local optionGroup = optionGroups[i]

			for j = 1, #optionGroup.options do
				local option = optionGroup.options[j]

				if option.onSaveOnLoad and option.onSave then
					option:onSave(true)
				end
			end
		end

		return true
	end
end
