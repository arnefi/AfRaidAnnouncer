-----------------------------------------------------------------------------------------------
-- Client Lua Script for AfRaidAnnouncer
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- AfRaidAnnouncer Module Definition
-----------------------------------------------------------------------------------------------
-- local AfRaidAnnouncer = {} 
AfRaidAnnouncer = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:NewAddon("AfRaidAnnouncer", false, {}, "Gemini:Hook-1.0")
local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:GetLocale("AfRaidAnnouncer", true)
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
local strVersion = "@project-version@"
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function AfRaidAnnouncer:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here
	self.counter = 0
	self.sanitizeCounter = 0
	self.words = {}
	self.active = false
	self.werbung = ""
	self.werbungGerman = ""
	self.werbungFrench = ""
	self.sanitize = false
	self.werbungreplaced = ""
	self.werbungreplacedGerman = ""
	self.werbungreplacedFrench = ""
	self.werbungtime = false
	self.werbungreply = true
	self.history = {}
	self.beenInGroup = false
	self.offline = {}
	self.blacklist = {}
	self.useBlacklist = true
	self.english = true
	self.german = false
	self.french = false
    return o
end

function AfRaidAnnouncer:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = "afRaidAnnouncer"
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- AfRaidAnnouncer OnLoad
-----------------------------------------------------------------------------------------------
function AfRaidAnnouncer:OnLoad()

    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("AfRaidAnnouncer.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
	Apollo.LoadSprites("AfRaidAnnouncerSprites.xml", "AfRaidAnnounserSprites")
end

-----------------------------------------------------------------------------------------------
-- AfRaidAnnouncer OnDocLoaded
-----------------------------------------------------------------------------------------------
function AfRaidAnnouncer:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "AfRaidAnnouncerForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		
	    self.wndMain:Show(false, true)

		-- if the xmlDoc is no longer needed, you should set it to nil
		-- self.xmlDoc = nil
		
		-- Register handlers for events, slash commands and timer, etc.
		-- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
		Apollo.RegisterSlashCommand("afraid", "OnAfRaidAnnouncerOn", self)
		Apollo.RegisterEventHandler("AfRaidAnnouncerOn", "OnAfRaidAnnouncerOn", self)
		Apollo.RegisterEventHandler("ChatMessage", "OnChatMessage", self)
		Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", "OnInterfaceMenuListHasLoaded", self)
		--Apollo.RegisterEventHandler("Group_JoinRequest", "OnGroupJoinRequest", self)
		--Apollo.RegisterEventHandler("Group_Referral", "OnGroupReferral", self)
		Apollo.RegisterEventHandler("Group_Add", "OnGroupAdd", self)
		Apollo.RegisterEventHandler("Group_Left", "OnGroupLeft", self)
		self.timer = ApolloTimer.Create(1.0, true, "OnTimer", self)

		local otto = Apollo.GetAddon("GroupDisplay")
		if otto then
			self:RawHook(Apollo.GetAddon("GroupDisplay"), "OnGroupJoinRequest")
			self:RawHook(Apollo.GetAddon("GroupDisplay"), "OnGroupReferral")
		end
		
		-- Do additional Addon initialization here
		self:Activate(false)
	end
end

-----------------------------------------------------------------------------------------------
-- AfRaidAnnouncer Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here


-----------------------------------------------------------------------------------------------
-- AfRaidAnnouncer OnInterfaceMenuListHasLoaded: create start menu entry
-----------------------------------------------------------------------------------------------

function AfRaidAnnouncer:OnInterfaceMenuListHasLoaded()
	Event_FireGenericEvent("InterfaceMenuList_NewAddOn", "afRaidAnnouncer", {"AfRaidAnnouncerOn", "", "AfRaidAnnouncerSprites:MenuIcon"})
end


-----------------------------------------------------------------------------------------------
-- AfRaidAnnouncer refreshWords: fill GUI field with comma separated list of our words table
-----------------------------------------------------------------------------------------------

function AfRaidAnnouncer:refreshWords()
	local words = ""
	for _,wort in pairs(self.words) do
		words = words .. wort .. ", "
	end
	if words == nil or #words == 0 then
		words = "R-12, R12"
	else
		words = words:sub(1,-3)
	end
	self.wndMain:FindChild("ReizWort"):SetText(words)
	if self.werbung == "" then
		if self.words[1] then
			self.wndMain:FindChild("werbung"):SetText(L["for"].." "..self.words[1].." /join [me].")
		else
			self.wndMain:FindChild("werbung"):SetText("/join [me].")
		end
	else
		self.wndMain:FindChild("werbung"):SetText(self.werbung)
	end
	self.wndMain:FindChild("werbungGerman"):SetText(self.werbungGerman)
	self.wndMain:FindChild("werbungFrench"):SetText(self.werbungFrench)
end


-----------------------------------------------------------------------------------------------
-- AfRaidAddouncer OnAfRaidAnnouncerOn: Slash command, refresh and show dialog
-----------------------------------------------------------------------------------------------

function AfRaidAnnouncer:OnAfRaidAnnouncerOn()
	if self.wndMain:IsShown() then 
		self.location = self.wndMain:GetLocation()
		self.wndMain:Close() 
		return
	end

	self.wndMain:Invoke() -- show the window
	self.wndMain:FindChild("Blacklist"):Show(false)
	
	if self.location then self.wndMain:MoveToLocation(self.location) end
	
	self:refreshWords()
	self.wndMain:FindChild("werbungtime"):SetCheck(self.werbungtime)
	self.wndMain:FindChild("werbungreply"):SetCheck(self.werbungreply)
	self.wndMain:FindChild("chkSanitize"):SetCheck(self.sanitize)
	self.wndMain:FindChild("active"):SetCheck(self.active)
	self.wndMain:FindChild("UseBlacklist"):SetCheck(self.useBlacklist)
	
	self.wndMain:FindChild("chk_english"):SetCheck(self.english)
	self.wndMain:FindChild("chk_german"):SetCheck(self.german)
	self.wndMain:FindChild("chk_french"):SetCheck(self.french)
	
	-- History
	local container = self.wndMain:FindChild("container")
	
	container:DestroyChildren()

	for idxHistory, entry in pairs(self.history) do
		local wndCurr = Apollo.LoadForm(self.xmlDoc, "HistoryItem", container, self)
		wndCurr:SetData(idxHistory)
		wndCurr:FindChild("Button"):SetText(entry["words"][1])
	end
	container:ArrangeChildrenVert()

	
	self.wndMain:FindChild("version"):SetText(strVersion)
	
	-- loca	
	self.wndMain:FindChild("exWords"):SetText(L["exWords"])
	self.wndMain:FindChild("exWerbung"):SetText(L["exWerbung"])
	self.wndMain:FindChild("active"):SetText(L["lblActive"])
	self.wndMain:FindChild("werbungtime"):SetText(L["lblWerbungtime"])
	self.wndMain:FindChild("werbungreply"):SetText(L["lblWerbungreply"])
	self.wndMain:FindChild("CancelButton"):SetText(L["lblCancel"])
	self.wndMain:FindChild("chkSanitize"):SetText(L["lblSanitize"])

	self.wndMain:FindChild("lblLeech"):SetText(L["lblLeech"])
	self.wndMain:FindChild("lblRemoveBlacklist"):SetText(L["lblRemoveBlacklist"])
	self.wndMain:FindChild("lblManualBlacklist"):SetText(L["lblManualBlacklist"])
	self.wndMain:FindChild("lblAdd"):SetText(L["lblAdd"])
	self.wndMain:FindChild("UseBlacklist"):SetText(L["lblUseBlacklist"])
	
	self.wndMain:FindChild("chkSanitize"):SetTooltip(L["ttSanitize"])
	self.wndMain:FindChild("werbungtime"):SetTooltip(L["onlyGroup"])
	self.wndMain:FindChild("werbungreply"):SetTooltip(L["onlyGroup"])
end


-----------------------------------------------------------------------------------------------
-- AfRaidAnnouncer OnTimer: timer for posting to chat, kicking offline players
-----------------------------------------------------------------------------------------------

function AfRaidAnnouncer:OnTimer()
	-- count counter down to zero
	-- to avoid spamming wait at least 5 minutes
	if self.counter > 0 then
		self.counter = self.counter - 1
		if self.counter == 0 then
			if self.active and self.werbungtime then
				if GroupLib.GetMemberCount() < 40 then
					if GroupLib.InGroup() then
						self:PostTeaser()
					else
						-- don't post if not in group already
						-- otherwise the joining player will be lead
						self.counter = 30
					end
				end
			end
		end
	end

	-- check for offline players every 10 seconds
	if self.active then
		if self.sanitizeCounter > 0 then
			self.sanitizeCounter = self.sanitizeCounter - 1
			if self.sanitizeCounter == 0 then
				self:SanitizeRaid()
				self.sanitizeCounter = 10
			end
		else
			self.sanitizeCounter = 10
		end
	end
end


-----------------------------------------------------------------------------------------------
-- AfRaidAnnouncer OnGroupJoinRequest: someone wants to join our group. 
--       Hide confirmation window
-----------------------------------------------------------------------------------------------

function AfRaidAnnouncer:OnGroupJoinRequest(strInviterName)
	-- someone asks to join our group: auto-accept
	-- necessary only one time
	if self.active and (not GroupLib.InGroup() or GroupLib.AmILeader()) then
		self.beenInGroup = true
		if self:IsOnBlacklist(strInviterName) then
			GroupLib.DenyRequest()
		else
			GroupLib.AcceptRequest()
			self:ChangeSettings()
		end
	else
		self.hooks[Apollo.GetAddon("GroupFrame")].OnGroupJoinRequest(strInviterName)
	end
end


-----------------------------------------------------------------------------------------------
-- AfRaidAnnouncer OnGroupReferral: a group member invites another player. 
--       Hide confirmation window
-----------------------------------------------------------------------------------------------

function AfRaidAnnouncer:OnGroupReferral(nMemberIndex, strTarget)
	-- nMemberIndex invites strTarget to join our group: auto-accept
	-- shouldn't be necessary if settings are correct
	if self.active and GroupLib.InGroup() and GroupLib.AmILeader() then
		self.beenInGroup = true
		GroupLib.AcceptRequest()
		self:ChangeSettings()
	else
		self.hooks[Apollo.GetAddon("GroupFrame")].OnGroupReferral(nMemberIndex, strTarget)
	end
end


-----------------------------------------------------------------------------------------------
-- AfRaidAnnouncer OnGroupAdd: someone joined (by using /join too)
-----------------------------------------------------------------------------------------------

function AfRaidAnnouncer:OnGroupAdd(strMemberName)
	self:ChangeSettings()
	if self:IsOnBlacklist(strMemberName) then
		self:Kick(strMemberName)
	end
end


-----------------------------------------------------------------------------------------------
-- AfRaidAnnouncer OnSave: save settings
-----------------------------------------------------------------------------------------------

function AfRaidAnnouncer:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Account then
		return
	end
	local tSavedData = {}
	tSavedData.words = self.words
	tSavedData.werbung = self.werbung
	tSavedData.werbungGerman = self.werbungGerman
	tSavedData.werbungFrench = self.werbungFrench
	tSavedData.werbungtime = self.werbungtime
	tSavedData.werbungreply = self.werbungreply
	tSavedData.history = self.history
	tSavedData.sanitize = self.sanitize
	tSavedData.blacklist = self.blacklist
	tSavedData.useBlacklist = self.useBlacklist
	tSavedData.english = self.english
	tSavedData.german = self.german
	tSavedData.french = self.french
	tSavedData.location = self.location and self.location:ToTable() or nil
	return tSavedData
end


-----------------------------------------------------------------------------------------------
-- AfRaidAnnouner OnRestore: load settings
-----------------------------------------------------------------------------------------------

function AfRaidAnnouncer:OnRestore(eType, tSavedData)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Account then
		return
	end
	if tSavedData.words ~= nil then self.words = tSavedData.words end
	if tSavedData.werbung ~= nil then self.werbung = tSavedData.werbung end
	if tSavedData.werbungGerman ~= nil then self.werbungGerman = tSavedData.werbungGerman end
	if tSavedData.werbungFrench ~= nil then self.werbungFrench = tSavedData.werbungFrench end
	if tSavedData.werbungtime ~= nil then self.werbungtime = tSavedData.werbungtime end
	if tSavedData.werbungreply ~= nil then self.werbungreply = tSavedData.werbungreply end
	if tSavedData.history ~= nil then self.history = tSavedData.history end
	if tSavedData.sanitize ~= nil then self.sanitize = tSavedData.sanitize end
	if tSavedData.Blacklist ~= nil then self.blacklist = tSavedData.blacklist end
	if tSavedData.useBlacklist ~= nil then self.useBlacklist = tSavedData.useBlacklist end
	if tSavedData.english ~= nil then self.english = tSavedData.english end
	if tSavedData.german ~= nil then self.german = tSavedData.german end
	if tSavedData.french ~= nil then self.french = tSavedData.french end
	if tSavedData.location ~= nil then self.location = WindowLocation.new(tSavedData.location) end
end


-----------------------------------------------------------------------------------------------
-- AfRaidAnnouncer OnChatMessage: search chat for keywords
-----------------------------------------------------------------------------------------------

function AfRaidAnnouncer:OnChatMessage(channelCurrent, tMessage)
	-- tMessage has bAutoResponse, bGM, bSelf, strSender, strRealmName, nPresenceState, arMessageSegments, unitSource, bShowChatBubble, bCrossFaction, nReportId

	-- arMessageSegments is an array of tables.  Each table representsa part of the message + the formatting for that segment.
	-- This allows us to signal font (alien text for example) changes mid stream.
	-- local example = arMessageSegments[1]
	-- example.strText is the text
	-- example.bAlien == true if alien font set
	-- example.bRolePlay == true if this is rolePlay Text.  RolePlay text should only show up for people in roleplay mode, and non roleplay text should only show up for people outside it.

	-- to use: 	{#}toggles alien on {*}toggles rp on. Alien is still on {!}resets all format codes.

	-- don't react if not active
	if not self.active then return end
	
	-- don't react on own messages
	if tMessage.bSelf then return end
	
	-- system message
	if tMessage.strSender == "" then return end
	
	-- There will be a lot of chat messages, particularly for combat log.  If you make your own chat log module, you will want to batch
	-- up several at a time and only process lines you expect to see.
	local eChannelType = channelCurrent:GetType()

	local sMessage = ""
	

	if eChannelType == ChatSystemLib.ChatChannel_Whisper or eChannelType == ChatSystemLib.ChatChannel_AccountWhisper or eChannelType == ChatSystemLib.ChatChannel_Say or eChannelType == ChatSystemLib.ChatChannel_Zone or eChannelType == ChatSystemLib.ChatChannel_ZoneGerman or eChannelType == ChatSystemLib.ChatChannel_ZoneFrench or eChannelType == ChatSystemLib.ChatChannel_Guild then
		local bFound = false
		for idx, tSegment in ipairs(tMessage.arMessageSegments) do
			sMessage = string.lower(tSegment.strText)
			for _,reiz in pairs(self.words) do
				reiz = reiz:lower()
				if string.find(sMessage, reiz, 1, true) then 
					bFound = true
				end			
			end
		end
		if bFound then
			-- found one of the keywords in the message
			self:ChangeSettings()
		
			local announce = true
			local message = L["usedTerm"]
			message = string.gsub(message,"%[USER%]",tMessage.strSender)
			self:log(message)
			
			if not self.werbungreply then announce = false end

			if self.counter > 0 then
				announce = false
			end
			if not GroupLib.InGroup() then
				local wen = ""
				if tMessage.strSender == nil or tMessage.strSender == "" then
					wen = "nil"
				else
					wen = tMessage.strSender
				end
				self:log(L["notInGroup"] .. " " .. wen)
				self:Invite(tMessage.strSender)
			else
				if not GroupLib.InRaid() then 
					if not GroupLib.AmILeader() then
						announce = false
					else
						self:Invite(tMessage.strSender)
					end
				else
					if not GroupLib.AmILeader() then
						announce = false
					else
						if GroupLib.GetMemberCount() < 40 then
							self:Invite(tMessage.strSender)
						else
							self:log(L["full"])
							announce = false
						end
					end
				end
			end
	
			if announce then
				if GroupLib.InGroup() then
					self:PostTeaser()
				end
			end
		end
	end
end


-----------------------------------------------------------------------------------------------
-- AfRaidAnnouncer PostTeaser: post teaser on selected channels
-----------------------------------------------------------------------------------------------

function AfRaidAnnouncer:PostTeaser()
    for _,channel in pairs(ChatSystemLib.GetChannels()) do
    	if channel:GetType() == ChatSystemLib.ChatChannel_Zone then
			if self.english and self.werbungreplaced ~= "" then
		        channel:Send(self.werbungreplaced)
				self.counter = 300
			end
	    end
    	if channel:GetType() == ChatSystemLib.ChatChannel_ZoneGerman then
			if self.german then
				if self.werbungreplacedGerman ~= "" then
			        channel:Send(self.werbungreplacedGerman)
					self.counter = 300
				elseif self.werbungreplaced ~= "" then
			        channel:Send(self.werbungreplaced)
					self.counter = 300
				end
			end
	    end
    	if channel:GetType() == ChatSystemLib.ChatChannel_ZoneFrench then
			if self.french then
				if self.werbungreplacedFrench ~= "" then
			        channel:Send(self.werbungreplacedFrench)
					self.counter = 300
				elseif self.werbungreplaced ~= "" then
			        channel:Send(self.werbungreplaced)
					self.counter = 300
				end
			end
		end
	end
end


-----------------------------------------------------------------------------------------------
-- AfRaidAnnouncer ChangeSettings: converting group to raid, setting invitation and referral
--       settings regularly
-----------------------------------------------------------------------------------------------

function AfRaidAnnouncer:ChangeSettings()
	if not self.active then return end
	if GroupLib.InGroup() then
		self.beenInGroup = true
		if GroupLib.AmILeader() then
			GroupLib.SetJoinRequestMethod(GroupLib.InvitationMethod.Open)
			GroupLib.SetReferralMethod(GroupLib.InvitationMethod.Open)
		end
		if not GroupLib.InRaid() then 
			if not GroupLib.AmILeader() then
				self:log(L["noGroupRights"])
				self:Activate(false)
			else
				self:log(L["converting"])
				GroupLib.ConvertToRaid()
			end
		else
			if not GroupLib.AmILeader() then
				self:log(L["noLead"])
				self:Activate(false)
			end
		end
	end
end


-----------------------------------------------------------------------------------------------
-- AfRaidAnnouncer OnGroupLeft: I have left the group
-----------------------------------------------------------------------------------------------

function AfRaidAnnouncer:OnGroupLeft(eReason)
	local unitMe = GameLib.GetPlayerUnit()
	if unitMe == nil then
		return
    end
	if self.active then
		self:log(L["left"])
		self:Activate(false)
	end
end


-----------------------------------------------------------------------------------------------
-- AfRaidAnnouncer SanitizeRaid: kick players offline for over 5 minutes
-----------------------------------------------------------------------------------------------

function AfRaidAnnouncer:SanitizeRaid()
	local nMembers = GroupLib.GetMemberCount()
	local nCount = 0
	local nNow = os.time()
	if nMembers > 0 then
		for idx = nMembers, 1, -1 do
			local tMemberInfo = GroupLib.GetGroupMember(idx)
			if tMemberInfo ~= nil then
				local sCharname = tMemberInfo.strCharacterName
				if self:IsOnBlacklist(sCharname) then
					GroupLib.Kick(idx, "")
					self:log(L["blocked"])
				else
					if tMemberInfo.bIsOnline then
						self.offline[sCharname] = nil
					else
						if self.offline[sCharname] == nil then
							self.offline[sCharname] = os.time()
						else
							if self.sanitize then
								if nNow > (self.offline[sCharname] + 300) then
									local message = L["offline"]
									message = string.gsub(message,"%[USER%]",sCharname)
									self:log(message)
									GroupLib.Kick(idx, "")
								end
							end
						end
					end
				end
			end
		end	
	end
end


-----------------------------------------------------------------------------------------------
-- AfRaidAnnouncer log: display message in system log
-----------------------------------------------------------------------------------------------

function AfRaidAnnouncer:log (strMeldung)
	if strMeldung == nil then strMeldung = "nil" end
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_System, strMeldung, "afRaidAnnouncer")
end


-----------------------------------------------------------------------------------------------
-- AfRaidAnnouncer Invite: invite to group by playername if not already in our group
-----------------------------------------------------------------------------------------------

function AfRaidAnnouncer:Invite(strPlayername)
	local bFound = false
	if GroupLib.InGroup() then
		local nMembers = GroupLib.GetMemberCount()
		if nMembers > 0 then
			for idx = nMembers, 1, -1 do
				local tMemberInfo = GroupLib.GetGroupMember(idx)
				if tMemberInfo ~= nil then
					local sCharname = tMemberInfo.strCharacterName
					if sCharname == strPlayername then
						bFound = true
					end
				end
			end	
		end
	end
	if not bFound then
		if self:IsOnBlacklist(strPlayername) then
			self:log(L["blocked"])
		else
			self:log(L["invited"])					
			GroupLib.Invite(strPlayername)
		end
	end
end


-----------------------------------------------------------------------------------------------
-- AfRaidAnnouncer Kick: Kick player from group by name
-----------------------------------------------------------------------------------------------

function AfRaidAnnouncer:Kick(strPlayer)
	local nMembers = GroupLib.GetMemberCount()
	local strLower = strPlayer:lower()
	if nMembers > 0 then
		for idx = nMembers, 1, -1 do
			local tMemberInfo = GroupLib.GetGroupMember(idx)
			if tMemberInfo ~= nil then
				local sCharname = tMemberInfo.strCharacterName
				if sCharname:lower() == strLower then
					GroupLib.Kick(idx, "")
					return
				end
			end
		end	
	end
end


-----------------------------------------------------------------------------------------------
-- AfRaidAnnouncer RefreshBlacklist: refreshes GUI Lists
-----------------------------------------------------------------------------------------------

function AfRaidAnnouncer:RefreshBlacklist()
	local nMembers = GroupLib.GetMemberCount()
	local wndPlayerlist = self.wndMain:FindChild("Playerlist")
	local wndBlacklist = self.wndMain:FindChild("Blacklistlist")
	local drPlayer = GameLib.GetPlayerUnit()
	local strName = drPlayer and drPlayer:GetName() or ""
	local bFound = false

	wndPlayerlist:DestroyChildren()
	wndBlacklist:DestroyChildren()
	
	if nMembers > 0 then
		for idx = 1, nMembers do
			local tMemberInfo = GroupLib.GetGroupMember(idx)
			if tMemberInfo ~= nil then
				local sCharname = tMemberInfo.strCharacterName
				if sCharname ~= strName then
				
					bFound = false
					for idx, strName in pairs(self.blacklist) do
						if self.blacklist[idx] == sCharname then
							bFound = true
						end
					end

					if not bFound then
						local wndCurr = Apollo.LoadForm(self.xmlDoc, "PlayerlistItem", wndPlayerlist, self)
						wndCurr:SetData(sCharname)
						wndCurr:FindChild("Button"):SetText(sCharname)
					end
				end
			end
		end	
	end
	wndPlayerlist:ArrangeChildrenVert()
	
	for idx, strBlackname in pairs(self.blacklist) do
		local wndCurr = Apollo.LoadForm(self.xmlDoc, "BlacklistItem", wndBlacklist, self)
		wndCurr:SetData(strBlackname)
		wndCurr:FindChild("Button"):SetText(strBlackname)
	end		
	wndBlacklist:ArrangeChildrenVert()
	
end

-----------------------------------------------------------------------------------------------
-- AfRaidAnnouncer IsOnBlacklist: check if playername is found on our blacklist
-----------------------------------------------------------------------------------------------

function AfRaidAnnouncer:IsOnBlacklist(strPlayername)
	if not self.useBlacklist then
		return false
	end
	if strPlayerName == nil then return false end
	local strLower = strPlayername:lower()
	for idx, strName in pairs(self.blacklist) do
		if strName:lower() == strLower then
			return true
		end
	end
	return false
end


-----------------------------------------------------------------------------------------------
-- AfRaidAnnouncer Activate: enable/disable addon
-----------------------------------------------------------------------------------------------

function AfRaidAnnouncer:Activate(bState)
	self.active = bState
	if bState then
		self.timer:Start()
	else
		self.timer:Stop()
	end
end


-----------------------------------------------------------------------------------------------
-- AfRaidAnnouncer CheckChecks: check the state of the checkboxes
-----------------------------------------------------------------------------------------------

function AfRaidAnnouncer:CheckChecks()
	local english = self.wndMain:FindChild("chk_english"):IsChecked()
	local german = self.wndMain:FindChild("chk_german"):IsChecked()
	local french = self.wndMain:FindChild("chk_french"):IsChecked()
	
	if (not english) and (not german) and (not french) then
		self.wndMain:FindChild("chk_english"):SetCheck(true)
	end
end


-----------------------------------------------------------------------------------------------
-- AfRaidAnnouncerForm Functions
-----------------------------------------------------------------------------------------------
-- when the OK button is clicked
function AfRaidAnnouncer:OnOK()
	self.location = self.wndMain:GetLocation()

	-- user wants to activate it, sanity check
	if self.wndMain:FindChild("active"):IsChecked() then
		if GroupLib.InGroup() and not GroupLib.AmILeader() then
			self.wndMain:FindChild("active"):SetCheck(false);
			self:log(L["YouNoLeader"])
			return
		end
	end
	
	-- empty offline table
	for k,v in pairs(self.offline) do self.offline[k] = nil end

	-- divide string into table of keywords
	local words = self.wndMain:FindChild("ReizWort"):GetText()
	self.words = {}
	for wort in string.gmatch(words, '([^,]+)') do
		wort = wort:gsub("^%s*(.-)%s*$", "%1")
		table.insert(self.words, wort)
	end
	
	if not self.active and self.wndMain:FindChild("active"):IsChecked() then
		self.beenInGroup = false
		self.counter = 2
	end

	self:Activate(self.wndMain:FindChild("active"):IsChecked())
	self.sanitize = self.wndMain:FindChild("chkSanitize"):IsChecked()
	
	if self.wndMain:FindChild("active"):IsChecked() and self.counter == 0 then
		self.counter = 2
	end
	self.werbung  = self.wndMain:FindChild("werbung"):GetText()
	self.werbungGerman  = self.wndMain:FindChild("werbungGerman"):GetText()
	self.werbungFrench  = self.wndMain:FindChild("werbungFrench"):GetText()
	
	self.werbungtime = self.wndMain:FindChild("werbungtime"):IsChecked()
	self.werbungreply = self.wndMain:FindChild("werbungreply"):IsChecked()
	self.useBlacklist = self.wndMain:FindChild("UseBlacklist"):IsChecked()
	
	self.english = self.wndMain:FindChild("chk_english"):IsChecked()
	self.german = self.wndMain:FindChild("chk_german"):IsChecked()
	self.french = self.wndMain:FindChild("chk_french"):IsChecked()

	local drPlayer = GameLib.GetPlayerUnit()
	local strName = drPlayer and drPlayer:GetName() or "me"
	self.werbungreplaced = string.gsub(self.werbung, "%[me%]", strName)
	self.werbungreplacedGerman = string.gsub(self.werbungGerman, "%[me%]", strName)
	self.werbungreplacedFrench = string.gsub(self.werbungFrench, "%[me%]", strName)

	
	local entry = {["werbung"] = self.werbung, ["words"] = self.words, ["werbungGerman"] = self.werbungGerman, ["werbungFrench"] = self.werbungFrench}
	
	-- update or insert history table entry
	local found = false
	for idx, hentry in pairs(self.history) do
		if hentry["words"][1] == self.words[1] then
			self.history[idx] = entry
			found = true
		end
	end
	if not found then
		table.insert(self.history, entry)
	end
	
	self.wndMain:Close() -- hide the window
end


-- when the Cancel button is clicked
function AfRaidAnnouncer:OnCancel()
	self.location = self.wndMain:GetLocation()
	self.wndMain:Close() -- hide the window
end


-- delete items from history list
function AfRaidAnnouncer:OnDeleteHistoryItem(wndHandler, wndControl)
	local idx = wndHandler:GetParent():GetData()
	table.remove(self.history, idx)
	wndHandler:GetParent():Destroy()
	local container = self.wndMain:FindChild("container")
	container:ArrangeChildrenVert()
end


-- load saved settings from history
function AfRaidAnnouncer:OnHistoryItem(wndHandler, wndControl)
	local idx = wndHandler:GetParent():GetData()
	self.words = self.history[idx]["words"]
	self.werbung = self.history[idx]["werbung"]
	if self.history[idx]["werbungGerman"] ~= nil then
		self.werbungGerman = self.history[idx]["werbungGerman"]
	else
		self.werbungGerman = ""
	end
	if self.history[idx]["werbungFrench"] ~= nil then
		self.werbungFrench = self.history[idx]["werbungFrench"]
	else
		self.werbungFrench = ""
	end
	self:refreshWords()
end


-- toggle blacklist
function AfRaidAnnouncer:ToggleBlacklist()
	local wBlacklist = self.wndMain:FindChild("Blacklist")
	if wBlacklist:IsShown() then
		wBlacklist:Show(false)
	else
		wBlacklist:Show(true)
		self:RefreshBlacklist()
	end
end


-- get playername for blacklist from user entry
function AfRaidAnnouncer:OnManuallAddPlayer(wndHandler, wndControl, eMouseButton)
	local wndName = self.wndMain:FindChild("BlacklistName")
	local sPlayer = wndName:GetText()
	self:AddPlayerToBlacklist(sPlayer)
	wndName:SetText("")
	self:RefreshBlacklist()
end


-- remove player from blacklist
function AfRaidAnnouncer:OnBlacklistItem(wndHandler, wndControl, eMouseButton)
	local sPlayer = wndHandler:GetParent():GetData()
	for idx, strName in pairs(self.blacklist) do
		if self.blacklist[idx] == sPlayer then
			self.blacklist[idx] = nil
		end
	end
	self:RefreshBlacklist()
end


-- add selected player to blacklist
function AfRaidAnnouncer:AddPlayerToBlacklist(strPlayername)
	local bFound = false
	local strLower = strPlayername:lower()
	for idx, strName in pairs(self.blacklist) do
		if self.blacklist[idx]:lower() == strLower then
			bFound = true
		end
	end
	if not bFound then
		self:RefreshBlacklist()	table.insert(self.blacklist, strPlayername)
	end
end



-- toggle posting destination checkboxes.
function AfRaidAnnouncer:PostToZone(wndHandler, wndControl, eMouseButton)
	self.wndMain:FindChild("werbungreply"):SetCheck(false)
end

function AfRaidAnnouncer:PostOnWord(wndHandler, wndControl, eMouseButton)
	self.wndMain:FindChild("werbungtime"):SetCheck(false)
end

---------------------------------------------------------------------------------------------------
-- PlayerlistItem Functions
---------------------------------------------------------------------------------------------------

function AfRaidAnnouncer:OnPlayerlistItem(wndHandler, wndControl, eMouseButton)
	local sPlayer = wndHandler:GetParent():GetData()
	self:AddPlayerToBlacklist(sPlayer)
	self:RefreshBlacklist()
end

-----------------------------------------------------------------------------------------------
-- AfRaidAnnouncer Instance
-----------------------------------------------------------------------------------------------
local AfRaidAnnouncerInst = AfRaidAnnouncer:new()
AfRaidAnnouncerInst:Init()
