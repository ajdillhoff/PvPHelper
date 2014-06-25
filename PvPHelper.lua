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

local ktRatingTypeToMatchType = {
	MatchingGame.RatingType.Arena2v2          = MatchingGame.MatchType.Arena,
	MatchingGame.RatingType.Arena3v3          = MatchingGame.MatchType.Arena,
	MatchingGame.RatingType.Arena5v5          = MatchingGame.MatchType.Arena,
	MatchingGame.RatingType.RatedBattleground = MatchingGame.MatchType.RatedBattleground,
	MatchingGame.RatingType.Warplot           = MatchingGame.MatchType.Warplot,
}

local ktMatchTypes =
{
	MatchingGame.MatchType.Battleground      = "Battleground",
	MatchingGame.MatchType.Arena             = "Rated Arena",
	MatchingGame.MatchType.Warplot           = "Warplot",
	MatchingGame.MatchType.RatedBattleground = "Rated Battleground",
	MatchingGame.MatchType.OpenArena         = "Arena"
}

local eResultTypes = {
	Win     = 0,
	Loss    = 1,
	Forfeit = 2
}

-- TODO: This will be expanded to a table if more views are added
local kEventTypeToWindowName = "ResultGrid"

local tDataKeys = {
	"tDate",
	"nGameType",
	"nResult",
	"tRating",
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
		-- Apollo.RegisterEventHandler("PVPMatchStateUpdated", "OnPVPMatchStateUpdated", self)	
		Apollo.RegisterEventHandler("PVPMatchFinished",     "OnPVPMatchFinished", self)	
		--Apollo.RegisterEventHandler("PublicEventStart",     "OnPublicEventStart", self)

		-- TODO: I feel that this could be done in a more elegant way, clean it up later
		-- Maybe the UI reloaded so be sure to check if we are in a match already
		if MatchingGame:IsInMatchingGame() then
			local tMatchState = MatchingGame:GetPVPMatchState()

			if tMatchState ~= nil then
				--Print("Attempting to restore PVPMatchEntered()")
				self:OnPVPMatchEntered()
			end

			-- Do the same for public event
			-- local tActiveEvents = PublicEvent.GetActiveEvents()
			-- for idx, peEvent in pairs(tActiveEvents) do
			-- 	self:OnPublicEventStart(peEvent)
			-- end
		end
	end
end

-----------------------------------------------------------------------------------------------
-- PvPHelper Events
-----------------------------------------------------------------------------------------------

function PvPHelper:OnPVPMatchEntered()
	local tDate = GameLib:GetLocalTime()
	local nMatchType = self:GetMatchType()

	tDate["nTickCount"] = GameLib:GetTickCount()

	self.currentMatch = {
		["tDate"]      = tDate,
		["nMatchType"] = nMatchType,
		["nResult"]    = nil, 
		["tRating"]    = {
			["nBeginRating"] = self:GetCurrentRating(nMatchType),
			["nEndRating"]   = nil
		}
	}
end

function PvPHelper:OnPVPMatchExited()
	if self.currentMatch then
		-- User left before match finished.
		self.currentMatch["nResult"] = eResultTypes.Forfeit
		self:UpdateMatchHistory(self.currentMatch)
	end
end

function PvPHelper:OnPVPRatingUpdated(eRatingType)
	self:UpdateRating(eRatingType)
end

function PvPHelper:OnPVPMatchFinished(eWinner, eReason, nDeltaTeam1, nDeltaTeam2)
	local tMatchState = MatchingGame:GetPVPMatchState()
	local eMyTeam = nil
	local tRatingDeltas = {
		nDeltaTeam1,
		nDeltaTeam2
	}
	
	if tMatchState then
		eMyTeam = tMatchState.eMyTeam
	end	
	
	self.currentMatch["nResult"] = self:GetResult(eMyTeam, eWinner)
	-- TODO: This may not be necessary at all if using OnPVPRatingUpdated()
	--self.currentMatch["sRating"] = self:GetArenaRatingString(tMatchState, tRatingDeltas)

	self:UpdateMatchHistory(self.currentMatch)
end

-- DEPRECATED
function PvPHelper:OnPublicEventStart(peEvent)
	local eEventType = peEvent:GetEventType()
	local strType    = self:GetGameTypeString(eEventType)
	
	-- Only worry about PvP events
	if strType == "" then
		return
	end
	
	self.currentMatch["sGameType"] = strType
end

-----------------------------------------------------------------------------------------------
-- PvPHelper Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

-- on SlashCommand "/pvphelper"
function PvPHelper:OnPvPHelperOn()
	
	PvPHelper:HelperBuildGrid(self.wndMain:FindChild("GridContainer"), self.pvphelperdb.MatchHistory)
	self.wndMain:Invoke() -- show the window
end

-- on SlashCommand "/pvphelperclear"
function PvPHelper:OnPvPHelperClear()
	Print("PvPHelper: Match History cleared")
	self.pvphelperdb.MatchHistory = {}
end

function PvPHelper:UpdateRating( eRatingType )
	if not self.pvphelperdb.MatchHistory then
		return
	end

	local nLastEntry = #self.pvphelperdb.MatchHistory
	local tLastEntry = self.pvphelperdb.MatchHistory[nLastEntry]
	local nMatchType = tLastEntry["nMatchType"]
	local result     = nil

	if nMatchType == ktRatingTypeToMatchType[eRatingType] then
		result = self:GetCurrentRating(ktRatingTypeToMatchType[eRatingType])
	end

	tLastEntry.tRating.nEndRating = result
end

function PvPHelper:GetResult(eMyTeam, eWinner)
	if eMyTeam == eWinner then
		return eResultTypes.Win
	else
		return eResultTypes.Loss
	end
end

function PvPHelper:GetCurrentRating(eMatchType)
	return MatchingGame:GetPvpRating(eMatchType) or 0
end

function PvPHelper:GetMatchType()
	local nResult = nil
	local tAllTypes =
	{
		MatchingGame.MatchType.Battleground,
		MatchingGame.MatchType.Arena,
		MatchingGame.MatchType.Warplot,
		MatchingGame.MatchType.RatedBattleground,
		MatchingGame.MatchType.OpenArena
	}

	for key, nType in pairs(tAllTypes) do
		local tGames = MatchingGame.GetAvailableMatchingGames(nType)
		for key, matchGame in pairs(tGames) do
			if matchGame:IsInMatchingGame() == true then
				result = nType
			end
		end
	end

	return result
end

function PvPHelper:UpdateMatchHistory(tMatch)
	if self.pvphelperdb.MatchHistory == nil then
		self.pvphelperdb.MatchHistory = {}
	end
	table.insert(self.pvphelperdb.MatchHistory, tMatch)
	
	tMatch = nil
end

-----------------------------------------------------------------------------------------------
-- Data Formatting Functions
-----------------------------------------------------------------------------------------------

function PvPHelper:GetDateString(tDate)	
	local strDate = string.format("%02d/%02d/%4d %s", tDate["nMonth"], tDate["nDay"], tDate["nYear"], tDate["strFormattedTime"])
	return strDate
end

function PvPHelper:GetMatchTypeString(nMatchType)
	result = "N/A"

	if nMatchType then
		result = ktMatchTypes[nMatchType]
	end

	return result
end

function PvPHelper:GetResultString( nResultType )
	local result = "N/A"
	local ktResultTypes = {
		eResultTypes.Win     = "Win",
		eResultTypes.Loss    = "Loss",
		eResultTypes.Forfeit = "Forfeit"
	}

	if nResultType then
		result = ktResultTypes[nResultType]
	end

	return result
end

function PvPHelper:GetRatingString(tRating)
	local result = "N/A"
	local nPreviousRating = tRating.nBeginRating
	local nCurrentRating  = tRating.nEndRating

	if nPreviousRating and nCurrentRating then]
		if nPreviousRating < nCurrentRating then
			result = string.format("%d (+%d)", nCurrentRating, (nCurrentRating - nPreviousRating))
		elseif nPreviousRating > nCurrentRating then
			result = string.format("%d (-%d)", nCurrentRating, (nPreviousRating - nCurrentRating))
		end
	end

	return result
end

-- Return a string which shows the current rating after difference
-- TODO: Determine if this is needed anymore
function PvPHelper:GetArenaRatingString(tMatchState, tRatingDeltas)
	local eMyTeam = tMatchState.eMyTeam	
	local result  = "N/A (N/A)"

	if tMatchState.arTeams then
		for idx, tCurr in pairs(tMatchState.arTeams) do
			if eMyTeam == tCurr.nTeam then
				result = string.format("%d (%d)", tCurr.nRating, tRatingDeltas[idx])
			end
		end
	end
	
	return result
end

function PvPHelper:GetDateSortString( tDate )
	local result = nil

	if tDate then
		result = tDate.nTickCount
	end

	return result
end

function PvPHelper:GetRatingSortString( tRating )
	local result = nil

	if tRating then
		return tRating.nEndRating
	end

	return result
end

-----------------------------------------------------------------------------------------------
-- PvPHelperForm Functions
-----------------------------------------------------------------------------------------------

function PvPHelper:HelperBuildGrid(wndParent, tData)
	if not tData then
		-- Print("No data found")
		return
	end
	
	-- Print("Data found: building grid")

	local wndGrid = wndParent:FindChild("ResultGrid")

	local nVScrollPos 	= wndGrid:GetVScrollPos()
	local nSortedColumn	= wndGrid:GetSortColumn() or 1
	local bAscending 	  = wndGrid:IsSortAscending()
	
	wndGrid:DeleteAll()
	
	for row, tMatch in pairs(tData) do
		local wndResultGrid = wndGrid
		self:HelperBuildRow(wndResultGrid, tMatch)
	end

	wndGrid:SetVScrollPos(nVScrollPos)
	wndGrid:SetSortColumn(nSortedColumn, bAscending)

end

function PvPHelper:HelperBuildRow(wndGrid, tMatchData)
	row = wndGrid:AddRow("")

	local ktFormatFunctions = {
		["tDate"]      = self:GetDateString( n ),
		["nMatchType"] = self:GetMatchTypeString( n ),
		["nResult"]    = self:GetResultString( n ),
		["tRating"]    = self:GetRatingString( n )
	}

	local ktSortFormatFunctions = {
		["tDate"]      = self:GetDateSortString( n ),
		["nMatchType"] = self:GetMatchTypeString( n ), -- No special sorting rules
		["nResult"]    = self:GetResultString( n ),    -- No special sorting rules
		["tRating"]    = self:GetRatingSortString( n )
	}

	for col, sDataKey in pairs(tDataKeys) do
		local value = tMatchData[sDataKey]
		wndResultGrid:SetCellText(row, col, ktFormatFunctions[sDataKey]( value ))
		wndResultGrid:SetCellSortText(row, col, ktSortFormatFunctions[sDataKey]( value ))
	end
end

function PvPHelper:OnClose( wndHandler, wndControl )
	self.wndMain:Close()
end

-----------------------------------------------------------------------------------------------
-- PvPHelper Instance
-----------------------------------------------------------------------------------------------
local PvPHelperInst = PvPHelper:new()
PvPHelperInst:Init()
