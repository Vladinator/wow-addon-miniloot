local addonName, ns = ...
ns.events = {}

-- events storage
local events = {}

-- create event frame
local frame = CreateFrame("Frame")
frame:SetScript("OnEvent", function(self, event, ...) ns.events.fire(self, event, ...) end)

-- register event with widget
function ns.events:on(event, func, env)
	local temp = true

	if func then
		temp = ns.events:register(event, func, env)
	end

	if temp then
		frame:RegisterEvent(event)
	end

	return temp
end

-- unregister event with widget
function ns.events:off(event, func, env)
	local temp, count = true, 0

	if func then
		temp, count = ns.events:unregister(event, func, env)
	end

	if temp and count == 0 then
		frame:UnregisterEvent(event)

		return true
	end

	return false
end

-- register for event
function ns.events:register(event, func, env)
	local temp = events[event]

	if not temp then
		temp = {}
		events[event] = temp
	end

	if type(func) == "function" then
		table.insert(temp, {env, func})

		return true
	end

	return false
end

-- unregister for event
function ns.events:unregister(event, func, env)
	local temp = events[event]

	if temp then
		for i = 1, #temp do
			if (not env or temp[i][1] == env) and temp[i][2] == func then
				table.remove(temp, i)

				return true, #temp
			end
		end
	end

	return false
end

-- fire specific event
function ns.events.fire(self, event, ...)
	local temp = events[event]

	if temp then
		for i = 1, #temp do
			temp[i][2](temp[i][1] or self, event, ...)
		end

		return true
	end

	return false
end

-- chat filters
do
	ns.events.filters =  {}

	function ns.events.filters:on(event, func)
		ChatFrame_AddMessageEventFilter(event, func)
	end

	function ns.events.filters:off(event, func)
		ChatFrame_RemoveMessageEventFilter(event, func)
	end
end
