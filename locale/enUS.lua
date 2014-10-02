local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:NewLocale("AfRaidAnnouncer", "enUS", true)
if not L then return end
L["exWords"] = "On which terms should the addon react? Separate multiple terms by comma. As soon as one of these terms is found in the zone chat the player will be invited." 
L["exWerbung"] = "Enter a concise slogan which is used to promote your raid in the zone chat (\"[me]\" will be replaced with the name of your current toon):"
L["lblActive"] = "activate addon"
L["lblWerbungtime"] = "post slogan every five minutes in the zone chat"
L["lblWerbungreply"] = "post slogan after finding a term (5 minutes max)"
L["lblSanitize"] = "kick offline players"
L["ttSanitize"] = "kick players that are offline for over five minutes"
L["lblCancel"] = "cancel"
L["for"] = "For"
L["usedTerm"] = "User [USER] used a term."
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
