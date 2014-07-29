local addonName, addonData = ...

local L = addonData.L

if GetLocale() == "deDE" then
L["CHAT_NO_LOOT"] = "keine Beute"
L["CHAT_ROLL"] = "Wurf um"
L["CHAT_ROLL_D"] = "E"
L["CHAT_ROLL_G"] = "G"
L["CHAT_ROLL_N"] = "B"
L["CHAT_ROLL_P"] = "P"
L["CHAT_WON"] = " gewonnen!"
L["INT_EXTRA"] = "Extra"
L["INT_EXTRA_CLASSCOLORS_LABEL"] = "Färbe die Namen nach der Klasse"
L["INT_EXTRA_CLASSCOLORS_TOOLTIP"] = "Färbe Spielernamen nach ihrer Klasse."
L["INT_EXTRA_DESC"] = "Nicht eine Hauptaufgabe des Addons, aber vielleicht hilfreich."
L["INT_EXTRA_LOOTCOUNT_LABEL"] = "Zeige Beutezähler"
L["INT_EXTRA_LOOTCOUNT_TOOLTIP"] = "Hänge die Anzahl der eigenen Items hinter jedem gelootetem Item an."
L["INT_EXTRA_MAILBOX_LABEL"] = "Postfachbeute"
L["INT_EXTRA_MAILBOX_TOOLTIP"] = "Postfachlooting wird im Chat angezeigt."
L["INT_EXTRA_MOUSEOVER_ANCHOR_LABEL"] = "Am Chat verankern"
L["INT_EXTRA_MOUSEOVER_ANCHOR_TOOLTIP"] = "Den mouseover tooltip oben am Chat verankern." -- Needs review
L["INT_EXTRA_MOUSEOVER_ICON_LABEL"] = "Zeige Icon am Tooltip"
L["INT_EXTRA_MOUSEOVER_ICON_TOOLTIP"] = "Zeige ein Icon an der Seite des Tooltip."
L["INT_EXTRA_MOUSEOVER_LINKS_LABEL"] = "Zeige mouseover links"
L["INT_EXTRA_ORIGINAL_LOOT_BUTTON"] = "Erstelle das Fenster!"
L["INT_EXTRA_ORIGINAL_LOOT_LABEL"] = "Original Beutechat"
L["INT_EXTRA_ORIGINAL_LOOT_TOOLTIP"] = "Dies erstellt einen weiteren Chat."
L["INT_EXTRA_PETBATTLE_LABEL"] = "Haustierkampfeinstellungen"
L["INT_EXTRA_TRADE_LABEL"] = "Handelsbeute"
L["INT_FILTER"] = "Filter"
L["INT_FILTER_DESC"] = "Entscheide was angezeigt und was versteckt bzw. ignoriert wird."
L["INT_FILTER_HIDE_EVENTS_LABEL"] = "Verstecke diese Ereignisse"
L["INT_FILTER_HIDE_JUNK_LABEL"] = "Verstecke Graue Beute"
L["INT_FILTER_HIDE_JUNK_TOOLTIP"] = "Alle Items von schlechter Qualität werden nicht angezeigt."
L["INT_FILTER_HIDE_PARTY_LABEL"] = "Verstecke Beute der Gruppe"
L["INT_FILTER_HIDE_QUALITY_LABEL"] = "Qualitäts Grenze"
L["INT_FILTER_HIDE_QUALITY_TOOLTIP"] = "Verstecke Items unter einer bestimmten Qualität."
L["INT_FILTER_HIDE_SELF_LABEL"] = "Verstecke eigene Beute"
L["INT_FILTER_LABEL"] = "Filtereinstellungen"
L["INT_LOOT_HIDE_ALL"] = "Alle verstecken"
L["INT_MINILOOT_DESC"] = "Eigene Schriftgröße festlegen und einstellen in welchem Chatfenster der Loot angezeigt wird."
L["INT_MINILOOT_FONTSIZE_DEMO"] = "Passt die neue Schritfgröße?"
L["INT_MINILOOT_FONTSIZE_LABEL"] = "Schriftgröße"
L["INT_MINILOOT_FONTSIZE_TOOLTIP"] = "Gebe \"0\" ein um das Spiel entscheiden zu lassen."
L["INT_MINILOOT_LABEL"] = "MiniLoot Einstellungen"
L["INT_MINILOOT_OUTPUT_DEMO"] = "Diese Meldung sollte in %s dargestellt worden sein."
L["INT_MINILOOT_OUTPUT_LABEL"] = "Ausgabe Chat"
L["INT_ROLL"] = "Wurf"
L["INT_ROLL_DECISIONS_LABEL"] = "Wurf Entscheidungen"
L["INT_ROLL_DECISIONS_LFR_LABEL"] = "Verstecke Wurfentscheidungen im LFR"
L["INT_ROLL_DECISIONS_TOOLTIP"] = "Die Bedarf/Gier Entscheidungen werden sofort gezeigt."
L["INT_ROLL_DESC"] = "Verändere das Wurf Handhabungsverhalten."
L["INT_ROLL_ICONS_LABEL"] = "Zeige Würfe als Icon"
L["INT_ROLL_LABEL"] = "Würfeleinstellungen"
L["INT_ROLL_SUMMARY_LABEL"] = "Wurfzusammenfassung"
L["INT_ROLL_SUMMARY_LFR_LABEL"] = "Verstecke Wurfzusammenfassung im LFR"
L["INT_ROLL_SUMMARY_TOOLTIP"] = [=[Zeige Würfelergebnisse in einer Zeile zusammen
mit dem Rest des Berichtes.]=] -- Needs review
L["INT_TIMER"] = "Zeitnehmer"
L["INT_TIMER_LABEL"] = "Zeitnehmereinstellungen"
L["INT_TIMER_SLEEP_COMBAT_LABEL"] = "Warten nach Kampf"
L["INT_TIMER_SLEEP_EVENTS_LABEL"] = "Warte zwischen Ereignissen"
L["POPUP_CHAT_FRAME_OVERWRITE"] = [=[Das Chatfenster "%s" existiert bereits.
Bist du dir sicher das du es überschreiben möchtest?

Durch das Überschreiben werden die Nachrichten auf Standart zurück gestellt. (Nachrichten wie Erfahrung, Ehre, Gold, Ruf und viele mehr.)]=] -- Needs review

end
