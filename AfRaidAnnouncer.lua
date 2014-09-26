-----------------------------------------------------------------------------------------------
-- Client Lua Script for AfRaidAnnouncer
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- AfRaidAnnouncer Module Definition
-----------------------------------------------------------------------------------------------
local AfRaidAnnouncer = {} 
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
	self.words = {}
	self.active = false
	self.werbung = ""
	self.werbungreplaced = ""
	self.werbungtime = false
	self.werbungreply = true
	self.history = {}

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
		Apollo.RegisterEventHandler("Group_JoinRequest", "OnGroupJoinRequest", self)			-- ( name )	
		Apollo.RegisterEventHandler("Group_Referral", "OnGroupReferral", self)			-- ( nMemberIndex, name )
		Apollo.RegisterEventHandler("Group_Add", "OnGroupAdd", self)					-- ( name )
		self.timer = ApolloTimer.Create(1.0, true, "OnTimer", self)

		-- Do additional Addon initialization here
	end
end

-----------------------------------------------------------------------------------------------
-- AfRaidAnnouncer Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

function AfRaidAnnouncer:OnInterfaceMenuListHasLoaded()
	Event_FireGenericEvent("InterfaceMenuList_NewAddOn", "afRaidAnnouncer", {"AfRaidAnnouncerOn", "", "AfRaidAnnouncerSprites:MenuIcon"})
end


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
		self.wndMain:FindChild("werbung"):SetText(L["for"].." "..self.words[1].." /join [me].")
	else
		self.wndMain:FindChild("werbung"):SetText(self.werbung)
	end
end


-- on SlashCommand "/afraid"
function AfRaidAnnouncer:OnAfRaidAnnouncerOn()
	self.wndMain:Invoke() -- show the window
	self:refreshWords()
	self.wndMain:FindChild("werbungtime"):SetCheck(self.werbungtime)
	self.wndMain:FindChild("werbungreply"):SetCheck(self.werbungreply)
	
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
end

-- on timer
function AfRaidAnnouncer:OnTimer()
	-- count counter down to zero
	-- to avoid spamming wait at least 5 minutes
	if self.counter > 0 then
		self.counter = self.counter - 1
		if self.counter == 0 then
			if self.active and self.werbungtime and self.werbungreplaced ~= "" then
				if GroupLib.GetMemberCount() < 40 then
					for _,channel in pairs(ChatSystemLib.GetChannels()) do
			        	if channel:GetType() == ChatSystemLib.ChatChannel_Zone then
					        channel:Send(self.werbungreplaced)
							self.counter = 300
			    	    end
					end
				end
			end
		end
	end
end


function AfRaidAnnouncer:OnGroupJoinRequest(strInviterName)
	-- someone asks to join our group: auto-accept
	-- (shouldn't be neccessary if settings are correct, except for the first one!
	-- if (not in group) or (ingroup and leader)
	if self.active and ((not GroupLib.InGroup() and not GroupLib.InRaid()) or (GroupLib.AmILeader() and (GroupLib.InGroup() or GroupLib.InRaid()))) then
		GroupLib.AcceptRequest()
		self:ChangeSettings()
	end
end


function AfRaidAnnouncer:OnGroupReferral(nMemberIndex, strTarget)
	-- nMemberIndex invites strTarget to join our group: auto-accept
	-- shouldn't be necessary if settings are correct
	if self.active and (GroupLib.AmILeader() and (GroupLib.InGroup() or GroupLib.InRaid())) then
		GroupLib.AcceptRequest()
		self:ChangeSettings()
	end
end


function AfRaidAnnouncer:OnGroupAdd(strMemberName)
	-- Someone else joined my group
	self:ChangeSettings()
end


function AfRaidAnnouncer:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Account then
		return
	end
	local tSavedData = {}
	tSavedData.words = self.words
	tSavedData.werbung = self.werbung
	tSavedData.werbungtime = self.werbungtime
	tSavedData.werbungreply = self.werbungreply
	tSavedData.history = self.history
	return tSavedData
end


function AfRaidAnnouncer:OnRestore(eType, tSavedData)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Account then
		return
	end
	self.words = tSavedData.words
	self.werbung = tSavedData.werbung
	self.werbungtime = tSavedData.werbungtime
	self.werbungreply = tSavedData.werbungreply
	self.history = tSavedData.history
end


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
	
	
	if eChannelType == ChatSystemLib.ChatChannel_Whisper or eChannelType == ChatSystemLib.ChatChannel_AccountWhisper or eChannelType == ChatSystemLib.ChatChannel_Say or eChannelType == ChatSystemLib.ChatChannel_Zone or eChannelType == ChatSystemLib.ChatChannel_Guild then
		local bFound = false
		for idx, tSegment in ipairs( tMessage.arMessageSegments ) do
			sMessage = string.lower(tSegment.strText)
			for _,reiz in pairs(self.words) do
				reiz = reiz:lower()
				if string.find(sMessage, reiz, 1, true) then 
					bFound = true
				end			
			end
		end
		if bFound then
		
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
				GroupLib.Invite(tMessage.strSender)
			else
				if not GroupLib.InRaid() then 
					if not GroupLib.AmILeader() then
						announce = false
					else
						self:log(L["invited"])					
						GroupLib.Invite(tMessage.strSender)
					end
				else
					if not GroupLib.AmILeader() then
						announce = false
					else
						if GroupLib.GetMemberCount() < 40 then
							self:log(L["invited"])
							GroupLib.Invite(tMessage.strSender)
						else
							self:log(L["full"])
							announce = false
						end
					end
				end
			end
	
			if announce and self.werbungreplaced ~= "" then		
		        for _,channel in pairs(ChatSystemLib.GetChannels()) do
		        	if channel:GetType() == ChatSystemLib.ChatChannel_Zone then
				        channel:Send(self.werbungreplaced)
						self.counter = 300
		    	    end
				end
			end
		end
	end
end


function AfRaidAnnouncer:ChangeSettings()
	if GroupLib.InGroup() then
		if GroupLib.AmILeader() then
			GroupLib.SetJoinRequestMethod(GroupLib.InvitationMethod.Open)
			GroupLib.SetReferralMethod(GroupLib.InvitationMethod.Open)
		end
		if not GroupLib.InRaid() then 
			if not GroupLib.AmILeader() then
				self:log(L["noGroupRights"])
				self.active = false
			else
				self:log(L["converting"])
				GroupLib.ConvertToRaid()
			end
		else
			if not GroupLib.AmILeader() then
				self:log(L["noLead"])
				self.active = false
			end
		end
	end
end


function AfRaidAnnouncer:log (strMeldung)
	if strMeldung == nil then strMeldung = "nil" end
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_System, "[afRaidAnnouncer]: "..strMeldung)
end


-----------------------------------------------------------------------------------------------
-- AfRaidAnnouncerForm Functions
-----------------------------------------------------------------------------------------------
-- when the OK button is clicked
function AfRaidAnnouncer:OnOK()

	-- user wants to activate it, sanity check
	if self.wndMain:FindChild("active"):IsChecked() then
		if GroupLib.InGroup() and not GroupLib.AmILeader() then
			self.wndMain:FindChild("active"):SetCheck(false);
			self.log = L["YouNoLeader"]
			return
		end
	end

	local words = self.wndMain:FindChild("ReizWort"):GetText()
	self.words = {}
	for wort in string.gmatch(words, '([^,]+)') do
		wort = wort:gsub("^%s*(.-)%s*$", "%1")
		table.insert(self.words, wort)
	end
	if not self.active and self.wndMain:FindChild("active"):IsChecked() then
		self.counter = 2
	end

	self.active = self.wndMain:FindChild("active"):IsChecked()
	
	if self.active and self.counter == 0 then
		self.counter = 2
	end
	self.werbung  = self.wndMain:FindChild("werbung"):GetText()
	self.werbungtime = self.wndMain:FindChild("werbungtime"):IsChecked()
	self.werbungreply = self.wndMain:FindChild("werbungreply"):IsChecked()
	local drPlayer = GameLib.GetPlayerUnit()
	local strName = drPlayer and drPlayer:GetName() or "me"
	self.werbungreplaced = string.gsub(self.werbung, "%[me%]", strName)
	
	local entry = {["werbung"] = self.werbung, ["words"] = self.words}
	
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
	self.wndMain:Close() -- hide the window
end


function AfRaidAnnouncer:OnDeleteHistoryItem(wndHandler, wndControl)
	local idx = wndHandler:GetParent():GetData()
	table.remove(self.history, idx)
	wndHandler:GetParent():Destroy()
	local container = self.wndMain:FindChild("container")
	container:ArrangeChildrenVert()
end


function AfRaidAnnouncer:OnHistoryItem(wndHandler, wndControl)
	local idx = wndHandler:GetParent():GetData()
	self.words = self.history[idx]["words"]
	self.werbung = self.history[idx]["werbung"]
	self:refreshWords()
end


-----------------------------------------------------------------------------------------------
-- AfRaidAnnouncer Instance
-----------------------------------------------------------------------------------------------
local AfRaidAnnouncerInst = AfRaidAnnouncer:new()
AfRaidAnnouncerInst:Init()
