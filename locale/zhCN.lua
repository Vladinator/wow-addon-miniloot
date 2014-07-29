local addonName, addonData = ...

local L = addonData.L

if GetLocale() == "zhCN" then
L["CHAT_NO_LOOT"] = "无拾取" -- Needs review
L["CHAT_ROLL"] = "掷骰" -- Needs review
L["CHAT_ROLL_D"] = "分解" -- Needs review
L["CHAT_ROLL_G"] = "贪婪" -- Needs review
L["CHAT_ROLL_N"] = "需求" -- Needs review
L["CHAT_ROLL_P"] = "放弃" -- Needs review
L["CHAT_SETTINGS_RESET"] = "这个 %s 已重设为 %d 的设置值，这可能发生在插件更新後，请查看插件设置，有些可能已被重设为默认值。" -- Needs review
L["INT_EXTRA"] = "额外" -- Needs review
L["INT_EXTRA_DESC"] = "这或许不是插件的主要功能，但可能会有所帮助。" -- Needs review
L["INT_EXTRA_MOUSEOVER_ANCHOR_LABEL"] = "提示位置定位" -- Needs review
L["INT_EXTRA_MOUSEOVER_ANCHOR_TOOLTIP"] = "定位工具提示在聊天窗口的顶端。" -- Needs review
L["INT_EXTRA_MOUSEOVER_ICON_LABEL"] = "显示工具提示图标" -- Needs review
L["INT_EXTRA_MOUSEOVER_ICON_TOOLTIP"] = "在工具提示信息中显示图标。" -- Needs review
L["INT_EXTRA_MOUSEOVER_LINKS_LABEL"] = "显示鼠标悬停连结" -- Needs review
L["INT_EXTRA_MOUSEOVER_LINKS_TOOLTIP"] = "当你鼠标悬停於一个物品\\n无须点击即可显示物品的工具提示。" -- Needs review
L["INT_EXTRA_ORIGINAL_LOOT_BUTTON"] = "创建聊天窗口！" -- Needs review
L["INT_EXTRA_ORIGINAL_LOOT_LABEL"] = "独立拾取聊天窗口" -- Needs review
L["INT_FILTER"] = "过滤" -- Needs review
L["INT_FILTER_DESC"] = "过滤你想看见的以及要隐藏和忽略的。" -- Needs review
L["INT_FILTER_HIDE_EVENTS_LABEL"] = "隐藏这些事件" -- Needs review
L["INT_FILTER_HIDE_JUNK_LABEL"] = "隐藏全部垃圾拾取" -- Needs review
L["INT_FILTER_HIDE_JUNK_TOOLTIP"] = "所有灰色质量的物品将不会显示。" -- Needs review
L["INT_FILTER_HIDE_PARTY_LABEL"] = "隐藏队伍拾取" -- Needs review
L["INT_FILTER_HIDE_QUALITY_LABEL"] = "质量临界值" -- Needs review
L["INT_FILTER_HIDE_QUALITY_TOOLTIP"] = "隐藏低於指定质量的物品。" -- Needs review
L["INT_FILTER_HIDE_SELF_LABEL"] = "隐藏自身拾取" -- Needs review
L["INT_LOOT_HIDE_ALL"] = "隐藏全部" -- Needs review
L["INT_MINILOOT_DESC"] = "设置文本字体大小以及变更信息输出的聊天窗口。" -- Needs review
L["INT_MINILOOT_FONTSIZE_DEMO"] = "新的文本大小合适吗？" -- Needs review
L["INT_MINILOOT_FONTSIZE_LABEL"] = "文本字体大小" -- Needs review
L["INT_MINILOOT_FONTSIZE_TOOLTIP"] = "设置 0 将自动调整大小。" -- Needs review
L["INT_MINILOOT_OUTPUT_DEMO"] = "信息将显示在 %s。" -- Needs review
L["INT_MINILOOT_OUTPUT_LABEL"] = "输出聊天窗口" -- Needs review
L["INT_MINILOOT_OUTPUT_TOOLTIP"] = [=[报告将会发送到你设置聊天窗口。
如果您输入无效的值将会重设为插件默认值。

"ChatFrame2"将会发送到战斗记录窗口中，
"ChatFrame3"将会发送到你自订的窗口中。

使用"/fstack"指令可开启窗口侦测工具。]=] -- Needs review
L["INT_ROLL"] = "掷骰" -- Needs review
L["INT_ROLL_DECISIONS_LABEL"] = "显示掷骰动作" -- Needs review
L["INT_ROLL_DECISIONS_TOOLTIP"] = "需求/贪婪的动作将立即显示。" -- Needs review
L["INT_ROLL_DESC"] = "变更掷骰处理方式。" -- Needs review
L["INT_ROLL_ICONS_LABEL"] = "显示掷骰图标" -- Needs review
L["INT_ROLL_ICONS_TOOLTIP"] = "将掷骰相关事件的物品连结显示为图标。" -- Needs review
L["INT_ROLL_SUMMARY_LABEL"] = "显示掷骰细节" -- Needs review
L["INT_ROLL_SUMMARY_TOOLTIP"] = [=[将掷骰结果发送独立的一行
不与其他的报告合并。]=] -- Needs review
L["INT_TIMER"] = "延迟" -- Needs review
L["INT_TIMER_DESC"] = "变更细节显示和收集资料的间隔速度。" -- Needs review
L["INT_TIMER_SLEEP_COMBAT_LABEL"] = "战斗之後延迟" -- Needs review
L["INT_TIMER_SLEEP_COMBAT_TOOLTIP"] = [=[如果设置为"1.5"将使插件在发送报告到聊天窗口前等待1.5秒。
这让你在战斗之後有时间来完成拾取动作，如果还在时间范围内，
它会将战斗中的拾取和战斗结束後的拾取合并。

如果设置为"-1"忽略战斗查看只使用事件之间的延迟时间。
如果设置为"0"将只会在战斗後才显示。]=] -- Needs review
L["INT_TIMER_SLEEP_EVENTS_LABEL"] = "事件之间延迟" -- Needs review
L["INT_TIMER_SLEEP_EVENTS_TOOLTIP"] = [=[每次有一个类似的物品拾取事件，
该插件将会等待一段时间，以确保没有更多的动作，
当它"超过时间范围"时将会发送报告，并等待新的信息。

此时间决定两个事件之间等待的时间，
如果没有下一个事件那麽它将会发送报告，并继续正常运作。]=] -- Needs review
L["POPUP_CHAT_FRAME_OVERWRITE"] = [=[聊天窗口"%s"已经存在.
你确定要覆盖它吗?

覆盖它会重设显示在默认聊天窗口的信息. (经验、荣誉、金钱、声望、等。)]=] -- Needs review

end
