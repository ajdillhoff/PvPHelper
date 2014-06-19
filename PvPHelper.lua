-----------------------------------------------------------------------------------------------
-- Client Lua Script for PvPHelper
-- by orbv - Bloodsworn - Dominion
-----------------------------------------------------------------------------------------------
 
require "Window"
require "Apollo"
 
-----------------------------------------------------------------------------------------------
-- PvPHelper Module Definition
-----------------------------------------------------------------------------------------------
local PvPHelper = {db} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
local glog
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function PvPHelper:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function PvPHelper:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		--"Gemini:Logging-1.2",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)

	self.db = Apollo.GetPackage("Gemini:DB-1.0").tPackage:New(self)
end
 

-----------------------------------------------------------------------------------------------
-- PvPHelper OnLoad
-----------------------------------------------------------------------------------------------
function PvPHelper:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("PvPHelper.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- PvPHelper OnDocLoaded
-----------------------------------------------------------------------------------------------
function PvPHelper:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "PvPHelperForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		
	    self.wndMain:Show(false, true)

		-- if the xmlDoc is no longer needed, you should set it to nil
		-- self.xmlDoc = nil
		
		-- Register handlers for events, slash commands and timer, etc.
		-- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
		Apollo.RegisterSlashCommand("pvphelper", "OnPvPHelperOn", self)
		Apollo.RegisterEventHandler("MatchEntered", "OnPVPMatchEntered", self)
		Apollo.RegisterEventHandler("MatchExited", "OnPVPMatchExited", self)
		Apollo.RegisterEventHandler("PvpRatingUpdated", "OnPVPRatingUpdated", self)
		Apollo.RegisterEventHandler("PVPMatchStateUpdated", "OnPVPMatchStateUpdated", self)	
		Apollo.RegisterEventHandler("PVPMatchFinished", "OnPVPMatchFinished", self)	

		-- Do additional Addon initialization here
		-- Maybe the UI reloaded so be sure to check if we are in a match already
		if MatchingGame:IsInMatchingGame() then
			local tMatchState = MatchingGame:GetPVPMatchState()
	
			if tMatchState ~= nil then
				self:OnPVPMatchEntered()
			end
		end
		
		--self.db.char.playerName = GameLib.GetPlayerUnit():GetName()
		Event_FireGenericEvent("SendVarToRover", "GeminiDB", self.db)
		Print(self.db.char.playerName)
	end
end

-----------------------------------------------------------------------------------------------
-- PvPHelper Events
-----------------------------------------------------------------------------------------------

function PvPHelper:OnPVPMatchEntered()
	local info = MatchingGame.GetPVPMatchState()
	Event_FireGenericEvent("SendVarToRover", "PVPMatchEntered", info)
	--glog:debug("PvPHelper OnPVPMatchEntered(): %s", info)
end

function PvPHelper:OnPVPMatchExited()
	--glog:debug("PvPHelper OnPVPMatchExited()")
end

function PvPHelper:OnPVPRatingUpdated()
	--glog:debug("PvPHelper OnPVPRatingUpdated()")
end

function PvPHelper:OnPVPMatchStateUpdated()
	local result = MatchingGame
	Event_FireGenericEvent("SendVarToRover", "PVPMatchStateUpdated", result)
end

function PvPHelper:OnPVPMatchFinished(eWinner, eReason)
	local result = {["Winner"] = eWinner, ["Reason"] = eReason, ["Team"] = MatchingGame.Team}
	if self.db.char.MatchHistory = nil then
		self.db.char.MatchHistory = {}
	end
	table.insert(self.db.char.MatchHistory, result)
	Event_FireGenericEvent("SendVarToRover", "PVPMatchFinished", self.db.char.MatchHistory)
	--glog:debug("PvPHelper OnPVPMatchFinished(): %s", result)
end

-----------------------------------------------------------------------------------------------
-- PvPHelper Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

-- on SlashCommand "/pvphelper"
function PvPHelper:OnPvPHelperOn()
	self.wndMain:Invoke() -- show the window
end


-----------------------------------------------------------------------------------------------
-- PvPHelperForm Functions
-----------------------------------------------------------------------------------------------
-- when the OK button is clicked
function PvPHelper:OnOK()
	self.wndMain:Close() -- hide the window
end

-- when the Cancel button is clicked
function PvPHelper:OnCancel()
	self.wndMain:Close() -- hide the window
end


-----------------------------------------------------------------------------------------------
-- PvPHelper Instance
-----------------------------------------------------------------------------------------------
local PvPHelperInst = PvPHelper:new()
PvPHelperInst:Init()
