local addonName, addonData = ...

addonData.L = setmetatable({}, {__index=function(_, key)
  return "|TInterface\\PVPFrame\\Icons\\PVP-Banner-Emblem-85:0:0:0:0|t"..tostring(key)
end})

local L = addonData.L

L["CHAT_NO_LOOT"] = "no loot"
L["CHAT_ROLL"] = "Roll"
L["CHAT_ROLL_D"] = "D"
L["CHAT_ROLL_G"] = "G"
L["CHAT_ROLL_N"] = "N"
L["CHAT_ROLL_P"] = "P"
L["CHAT_SETTINGS_RESET"] = "Note that %s had to reset %d setting(s) due to various reasons. This may happen when you update the addon, in that case please check the addon configurations as some may have been reset to default value."
L["CHAT_WON"] = "won!"
L["INT_EXTRA"] = "Extra"
L["INT_EXTRA_CLASSCOLORS_LABEL"] = "Color names by class"
L["INT_EXTRA_CLASSCOLORS_TOOLTIP"] = "Color player names by their class."
L["INT_EXTRA_DESC"] = "Not perhaps a major aspect of the addon, but may be helpful."
L["INT_EXTRA_LOOTCOUNT_LABEL"] = "Show loot-count"
L["INT_EXTRA_LOOTCOUNT_TOOLTIP"] = "Append number of items owned behind each looted item."
L["INT_EXTRA_MAILBOX_LABEL"] = "Mailbox loot"
L["INT_EXTRA_MAILBOX_TOOLTIP"] = "Mailbox looting will be shown in the chat."
L["INT_EXTRA_MOUSEOVER_ANCHOR_LABEL"] = "Anchor to the chat"
L["INT_EXTRA_MOUSEOVER_ANCHOR_TOOLTIP"] = "Anchor the mouseover tooltip to the top of the chat frame."
L["INT_EXTRA_MOUSEOVER_ICON_LABEL"] = "Show tooltip icon"
L["INT_EXTRA_MOUSEOVER_ICON_TOOLTIP"] = "Shows an icon on the side of the tooltip."
L["INT_EXTRA_MOUSEOVER_LINKS_LABEL"] = "Show mouseover links"
L["INT_EXTRA_MOUSEOVER_LINKS_TOOLTIP"] = "When you mouseover an item, spell or any other link in chat, the tooltip will appear without having to click it."
L["INT_EXTRA_ORIGINAL_LOOT_BUTTON"] = "Create this window!"
L["INT_EXTRA_ORIGINAL_LOOT_LABEL"] = "Original loot chat"
L["INT_EXTRA_ORIGINAL_LOOT_TOOLTIP"] = "This will create an additional chat frame that will contain the original messages that are otherwise handled by MiniLoot and hidden from the chat."
L["INT_EXTRA_PETBATTLE_LABEL"] = "Pet Battle combat"
L["INT_EXTRA_PETBATTLE_TOOLTIP"] = "Pet Battle combat messages are printed in a more minimalistic fashion."
L["INT_EXTRA_TITLE"] = "Extras"
L["INT_EXTRA_TRADE_LABEL"] = "Trade loot"
L["INT_EXTRA_TRADE_TOOLTIP"] = "Trading money will make it show in the chat."
L["INT_FILTER"] = "Filter"
L["INT_FILTER_DESC"] = "Decide what you see and what is hidden and ignored."
L["INT_FILTER_HIDE_EVENTS_LABEL"] = "Hide these events"
L["INT_FILTER_HIDE_JUNK_LABEL"] = "Hide all junk loot"
L["INT_FILTER_HIDE_JUNK_TOOLTIP"] = "Items of poor quality will not be shown."
L["INT_FILTER_HIDE_PARTY_LABEL"] = "Hide party loot"
L["INT_FILTER_HIDE_QUALITY_LABEL"] = "Quality threshold"
L["INT_FILTER_HIDE_QUALITY_TOOLTIP"] = "Hide items below specific quality."
L["INT_FILTER_HIDE_SELF_LABEL"] = "Hide own loot"
L["INT_FILTER_LABEL"] = "Filters"
L["INT_LOOT_HIDE_ALL"] = "Hide all"
L["INT_MINILOOT_DESC"] = "Set custom font-size if you wish, or change what chat frame the loot is written to."
L["INT_MINILOOT_FONTSIZE_DEMO"] = "Did the new size fit?"
L["INT_MINILOOT_FONTSIZE_LABEL"] = "Font size"
L["INT_MINILOOT_FONTSIZE_TOOLTIP"] = "Select \"0\" to inherit the output frame font size."
L["INT_MINILOOT_LABEL"] = "MiniLoot"
L["INT_MINILOOT_OUTPUT_DEMO"] = "This message should have been shown in %s."
L["INT_MINILOOT_OUTPUT_LABEL"] = "Output chat frame"
L["INT_MINILOOT_OUTPUT_TOOLTIP"] = [=[The reports will be printed in this chat. If what you enter is not valid the value will reset to default.

"ChatFrame2" would print in the Combat Log, "ChatFrame3" would print in a custom chat you made that is next to the Combat log, and so forth.

Use "/fstack" to find the name of a frame you are hover over with your mouse.]=]
L["INT_ROLL"] = "Roll"
L["INT_ROLL_DECISIONS_LABEL"] = "Show roll decisions"
L["INT_ROLL_DECISIONS_LFR_LABEL"] = "Hide roll decisions in the Raid Finder"
L["INT_ROLL_DECISIONS_LFR_TOOLTIP"] = "Overrides above option and hides roll decisions in the Raid Finder."
L["INT_ROLL_DECISIONS_TOOLTIP"] = "Decisions to need/greed and so forth, are instantly shown."
L["INT_ROLL_DESC"] = "Change the roll handling behavior."
L["INT_ROLL_ICONS_LABEL"] = "Show rolls as icons"
L["INT_ROLL_ICONS_TOOLTIP"] = "Instead of links the items will appear as icons on all roll related messages."
L["INT_ROLL_LABEL"] = "Rolls"
L["INT_ROLL_SUMMARY_LABEL"] = "Show roll summary"
L["INT_ROLL_SUMMARY_LFR_LABEL"] = "Hide roll summary in the Raid Finder"
L["INT_ROLL_SUMMARY_LFR_TOOLTIP"] = "Overrides above option and hides the roll results in the Raid Finder."
L["INT_ROLL_SUMMARY_TOOLTIP"] = "Prints the roll results in one line together with the rest of the report."
L["INT_SLEEP_DURING_TRADESKILL_LABEL"] = "Sleep during tradeskill"
L["INT_SLEEP_DURING_TRADESKILL_TOOLTIP"] = [=[Wait for the tradeskill to stop crafting.
Otherwise, if the timer is too fast, the
report will output lines between crafts.]=]
L["INT_TIMER"] = "Timer"
L["INT_TIMER_DESC"] = "Change how quickly the summary is shown and interval that data is gathered."
L["INT_TIMER_LABEL"] = "Timers"
L["INT_TIMER_SLEEP_COMBAT_LABEL"] = "Sleep after combat"
L["INT_TIMER_SLEEP_COMBAT_TOOLTIP"] = [=[After combat ends the addon will wait for a specific period letting you get to corpses and start looting.

For instance 1.5 would give you 1.5 seconds time to loot the corpse before printing the report.

Use -1 to skip combat checking and only care about the sleep events timer. Using 0 will only instantly report after combat ends without waiting.]=]
L["INT_TIMER_SLEEP_EVENTS_LABEL"] = "Sleep between events"
L["INT_TIMER_SLEEP_EVENTS_TOOLTIP"] = "Each time there is an event like item loot, experience gain, honor gain and such, the addon waits for a moment to make sure you have time to go trough looting before it prints a report of what has happened. Each new loot event delays the report by this amount of seconds."
L["POPUP_CHAT_FRAME_OVERWRITE"] = [=[The chat window "%s" already exists. Are you sure you wish to overwrite it?

By overwriting it will reset the messages it shows to default. (Messages like experience, honor, money, reputation, and many others.)]=]
