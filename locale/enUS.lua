local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:NewLocale("AfRaidAnnouncer", "enUS", true)
if not L then return end
L["exWords"] = "On which keywords should the addon react? Separate multiple keywords by comma. As soon as one of these keywords is found in the zone chat the player will be invited." 
L["exWerbung"] = "Enter a concise slogan which is used to promote your raid in the zone chat (\"[me]\" will be replaced with the name of your current toon). You must have joined regional channels (/chjoin zg, /chjoin zf) to be able to post there."
L["lblActive"] = "activate addon"
L["lblWerbungtime"] = "post slogan every five minutes in the zone chat"
L["lblWerbungreply"] = "post slogan after finding a keyword (5 minutes max)"
L["lblSanitize"] = "kick offline players"
L["ttSanitize"] = "kick players that are offline for over five minutes"
L["lblCancel"] = "cancel"
L["for"] = "For"
L["usedTerm"] = "User [USER] used a keyword."
L["notInGroup"] = "You are not in a group. Inviting:"
L["invited"] = "invited."
L["noGroupRights"] = "You are in a group instead of a raid and you don't have any rights."
L["converting"] = "Converting group to raid."
L["noLead"] = "You are not the leader of this raid."
L["full"] = "Raid full."
L["YouNoLeader"] = "You're not the leader. Only he should use this addon."
L["left"] = "You've left the group."
L["offline"] = "Kicking [USER]: offline for five minutes"
L["onlyGroup"] = "You have to be in a group already for that."
L["blocked"] = "Player is on blacklist."
L["lblLeech"] = "The right place for leechers. Click on a player's name to add him to the blacklist:"
L["lblRemoveBlacklist"] = "Click on a player's name to remove him from the blacklist:"
L["lblManualBlacklist"] = "manually add player to blacklist:"
L["lblAdd"] = "add"
L["lblUseBlacklist"] = "use blacklist"
L["lblPromote"] = "don't promote"
L["ttPromote"] = "The addon promotes itself once a raid in the party channel."
L["ttChannellist"] = "Comma separated list of chat channel names, to also post to"