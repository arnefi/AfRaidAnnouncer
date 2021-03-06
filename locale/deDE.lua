local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:NewLocale("AfRaidAnnouncer", "deDE")
if not L then return end
L["exWords"] = "Auf welche Begriffe soll das Addon reagieren? Mehrere Begriffe werden durch Kommata getrennt. Sobald ein Begriff im Zonenchat auftaucht, wird der Spieler eingeladen." 
L["exWerbung"] = "Gib einen prägnanten Spruch ein, mit dem dein Raid im Chat beworben werden soll (\"[me]\" wird durch deinen aktuellen Charnamen ersetzt). Du musst den regionalen Channels begetreten sein (/chjoin de, /chjoin fr), um dort posten zu können."
L["lblActive"] = "Addon aktivieren"
L["lblWerbungtime"] = "Spruch alle fünf Minuten im Map-Chat posten"
L["lblWerbungreply"] = "Spruch posten, wenn ein Begriff im Chat gefunden (max. 5 Min.)"
L["lblSanitize"] = "kick offline"
L["ttSanitize"] = "Spieler kicken, die länger als fünf Minuten offline sind"
L["lblCancel"] = "abbrechen"
L["for"] = "Für"
L["usedTerm"] = "Der User [USER] benutzt ein Stichwort."
L["notInGroup"] = "Du bist nicht in einer Gruppe. Ich lade ein:"
L["invited"] = "eingeladen."
L["noGroupRights"] = "Du bist in einer Gruppe, nicht in einem Raid und hast keinerlei Rechte."
L["converting"] = "Konvertiere Gruppe in Raid."
L["noLead"] = "Du bist nicht der Raid-Leiter."
L["full"] = "Raid voll."
L["YouNoLeader"] = "Du bist nicht der Lead. Nur er sollte dieses Addon nutzen."
L["left"] = "Du hast die Gruppe verlassen."
L["offline"] = "Kicking [USER]: seit fünf Minuten offline"
L["onlyGroup"] = "Dafür musst du bereits in einer Gruppe sein."
L["blocked"] = "Spieler befindet sich auf der Blacklist."
L["lblLeech"] = "Der richtiger Platz für Leecher. Auf einen Spielernamen klicken, um ihn zur Blacklist hinzuzufügen:"
L["lblRemoveBlacklist"] = "Auf einen Spilernamen klicken, um ihn von der Blacklist zu entfernen:"
L["lblManualBlacklist"] = "Manuell zur Blacklist hinzufügen:"
L["lblAdd"] = "hinzufügen"
L["lblUseBlacklist"] = "Blacklist nutzen"
L["lblPromote"] = "nicht bewerben"
L["ttPromote"] = "Das Addon wirbt einmal pro Raid für sich selbst im Gruppenchat."
L["ttChannellist"] = "Kommagetrennte Liste weiter Chat-Channel-Namen, in denen gepostet werden soll"