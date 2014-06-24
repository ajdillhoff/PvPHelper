-----------------------------------------------------------------------------------------------
-- Client Lua Script for PvPHelper
-- by orbv - Bloodsworn - Dominion
-----------------------------------------------------------------------------------------------
 
require "Window"
require "Apollo"
 
-----------------------------------------------------------------------------------------------
-- PvPHelper Module Definition
-----------------------------------------------------------------------------------------------
local PvPHelper = { 
	db, 
	pvphelperdb, 
	currentMatch
} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999

local ktPvPEvents =
{
	[PublicEvent.PublicEventType_PVP_Arena] 					= true,
	[PublicEvent.PublicEventType_PVP_Warplot] 					= true,
	[PublicEvent.PublicEventType_PVP_Battleground_Vortex] 		= true,
	[PublicEvent.PublicEventType_PVP_Battleground_Cannon] 		= true,
	[PublicEvent.PublicEventType_PVP_Battleground_Sabotage]		= true,
	[PublicEvent.PublicEventType_PVP_Battleground_HoldTheLine] 	= true,
}

local kEventTypeToWindowName = "ResultGrid"

local tDataKeys = {
	"sDate",
	"sGameType",
	"sResult",
	"sRating",
}
 
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
	
	if self.db.char.PvPHelper == nil then
		self.db.char.PvPHelper = {}
	end
	
	self.pvphelperdb = self.db.char.PvPHelper
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
		Apollo.RegisterSlashCommand("pvphelperclear",       "OnPvPHelperClear", self)
		Apollo.RegisterSlashCommand("pvphelper",            "OnPvPHelperOn", self)
		Apollo.RegisterEventHandler("MatchEntered",         "OnPVPMatchEntered", self)
		Apollo.RegisterEventHandler("MatchExited",          "OnPVPMatchExited", self)
		Apollo.RegisterEventHandler("PvpRatingUpdated",     "OnPVPRatingUpdated", self)
		Apollo.RegisterEventHandler("PVPMatchStateUpdated", "OnPVPMatchStateUpdated", self)	
		Apollo.RegisterEventHandler("PVPMatchFinished",     "OnPVPMatchFinished", self)	
		Apollo.RegisterEventHandler("PublicEventStart",     "OnPublicEventStart", self)

		-- Do additional Addon initialization here
		-- Maybe the UI reloaded so be sure to check if we are in a match already
		if MatchingGame:IsInMatchingGame() then
			local tMatchState = MatchingGame:GetPVPMatchState()
	
			if tMatchState ~= nil then
				self:OnPVPMatchEntered()
			end
		end
		
		-- Do the same for public event
		local tActiveEvents = PublicEvent.GetActiveEvents()
		for idx, peEvent in pairs(tActiveEvents) do
			self:OnPublicEventStart(peEvent)
		end
	end
end

-----------------------------------------------------------------------------------------------
-- PvPHelper Events
-----------------------------------------------------------------------------------------------

function PvPHelper:OnPVPMatchEntered()
	self.currentMatch = {
		["sDate"]     = PvPHelper:GetDateString(),
		["sGameType"] = "N/A",
		["sResult"]   = "N/A", 
		["sRating"]   = "N/A"
	}
	
	Event_FireGenericEvent("SendVarToRover", "OnPVPMatchEntered", self.currentMatch)
end

function PvPHelper:OnPVPMatchExited()
end

function PvPHelper:OnPVPRatingUpdated()
end

function PvPHelper:OnPVPMatchStateUpdated()
	local result = MatchingGame
end

function PvPHelper:OnPVPMatchFinished(eWinner, eReason, nDeltaTeam1, nDeltaTeam2)
	local tMatchState = MatchingGame:GetPVPMatchState()
	local eMyTeam = nil
	if tMatchState then
		eMyTeam = tMatchState.eMyTeam
	end	

	--[[local result = {
		["sDate"]     = PvPHelper:GetDateString(),
		["sGameType"] = PvPHelper:GetGameTypeString(),
		["sResult"]   = PvPHelper:GetResultString(eMyTeam, eWinner), 
		["sRating"]   = PvPHelper:GetRatingString(tMatchState, { nDeltaTeam1, nDeltaTeam2 })
	}]]--
	
	self.currentMatch["sResult"] = PvPHelper:GetResultString(eMyTeam, eWinner)
	self.currentMatch["sRating"] = PvPHelper:GetRatingString(tMatchState, { nDeltaTeam1, nDeltaTeam2 })

	if self.pvphelperdb.MatchHistory == nil then
		self.pvphelperdb.MatchHistory = {}
	end
	table.insert(self.pvphelperdb.MatchHistory, self.currentMatch)
	
	self.currentMatch = nil
end

function PvPHelper:OnPublicEventStart(peEvent)
	local eEventType = peEvent:GetEventType()
	local strType    = self:GetGameTypeString(eEventType)
	
	-- Only worry about PvP events
	if strType == "N/A" then
		return
	end
	
	self.currentMatch["sGameType"] = strType
	
	Event_FireGenericEvent("SendVarToRover", "OnPublicEventStart", self.currentMatch)
end

-----------------------------------------------------------------------------------------------
-- PvPHelper Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

-- on SlashCommand "/pvphelper"
function PvPHelper:OnPvPHelperOn()
	--[[local dummyData = {
		{
			["sDate"]     = "01/01/2001",
			["sGameType"] = "Battleground",
			["sResult"]   = "Win",
			["sRating"]   = "+4 (1404)"
		},
		{
			["sDate"]     = "01/01/2001",
			["sGameType"] = "Battleground",
			["sResult"]   = "Win",
			["sRating"]   = "+4 (1404)"
		},
	}--]]

	--Event_FireGenericEvent("SendVarToRover", "DummyData", dummyData)
	
	PvPHelper:HelperBuildGrid(self.wndMain:FindChild("GridContainer"), self.pvphelperdb.MatchHistory)
	self.wndMain:Invoke() -- show the window
end

-- on SlashCommand "/pvphelperclear"
function PvPHelper:OnPvPHelperClear()
	Print("PvPHelper: Match History cleared")
	self.pvphelperdb.MatchHistory = {}
	return
end

-- DEPRECATED
function PvPHelper:GetReasonString(eReason)
	if eReason == 0 then
		return "Complete"
	elseif eReason == 1 then
		return "Forfeit"
	else 
		return "Time Out"
	end
end

-- DEPRECATED
function PvPHelper:GetWinnerString(eWinner)
	if eWinner == 0 then
		return "Exile"
	else
		return "Dominion"
	end
end

function PvPHelper:GetDateString()
	local tDate = GameLib:GetLocalTime()
	
	local strDate = string.format("%d/%d/%d - %s", tDate["nMonth"], tDate["nMonth"], tDate["nYear"], tDate["strFormattedTime"])
	return strDate
end

function PvPHelper:GetResultString(eMyTeam, eWinner)
	if eMyTeam == eWinner then
		return "Win"
	else
		return "Loss"
	end
end

-- Return a string which shows the current rating after difference
function PvPHelper:GetRatingString(tMatchState, tRatingDeltas)
	local result = "N/A (N/A)"
	
	if tMatchState.arTeams and nDeltaTeam1 and nDeltaTeam2 then
		local eMyTeam = tMatchState.eMyTeam	

		for idx, tCurr in pairs(tMatchState.arTeams) do
			if eMyTeam == tCurr.nTeam then
				result = string.format("%d (%d)", tCurr.nRating, tRatingDeltas[idx])
			end
		end
	end
	
	return result
end

function PvPHelper:GetGameTypeString(eEventType)
	local result = "N/A"
	
	-- Leave these as if/elseif in case you want to add more specifics in the future
	if eEventType == PublicEvent.PublicEventType_PVP_Battleground_HoldTheLine then
		result = "Battleground"
	elseif eEventType == PublicEvent.PublicEventType_PVP_Battleground_Vortex then
		result = "Battleground"		
	elseif eEventType == PublicEvent.PublicEventType_PVP_Warplot then
		result = "Warplot"
	elseif eEventType == PublicEvent.PublicEventType_PVP_Arena then
		result = "Arena"
	elseif eEventType == PublicEvent.PublicEventType_PVP_Battleground_Sabotage then
		result = "Battleground"
	end
	
	return result
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

function PvPHelper:HelperBuildGrid(wndParent, tData)
	if not tData then
		Print("No data found")
		return
	end
	
	Print("Data found: building grid")

	local wndGrid = wndParent:FindChild("ResultGrid")

	local nVScrollPos 	= wndGrid:GetVScrollPos()
	local nSortedColumn	= wndGrid:GetSortColumn() or 1
	local bAscending 	= wndGrid:IsSortAscending()
	
	wndGrid:DeleteAll()

	--local tMatchState 	= MatchingGame:GetPVPMatchState()
	
	for row, tMatch in pairs(tData) do
		local wndResultGrid = wndGrid
		--Event_FireGenericEvent("SendVarToRover", "Grid", wndResultGrid)
		row = wndResultGrid:AddRow("")
		for col, sDataKey in pairs(tDataKeys) do
			local value = tMatch[sDataKey]
			Print(string.format("setting %d, %d: %s", row, col, value))
			wndResultGrid:SetCellText(row, col, value)
		end
	end

	wndGrid:SetVScrollPos(nVScrollPos)
	--wndGrid:SetSortColumn(nSortedColumn, bAscending)

end

-----------------------------------------------------------------------------------------------
-- PvPHelper Instance
-----------------------------------------------------------------------------------------------
local PvPHelperInst = PvPHelper:new()
PvPHelperInst:Init()
