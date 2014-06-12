-----------------------------------------------------------------------------------------------
-- Client Lua Script for PvPHelper
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- PvPHelper Module Definition
-----------------------------------------------------------------------------------------------
local PvPHelper = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
 
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
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
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
		Apollo.RegisterEventHandler("MatchEntered", "OnPVPMatchEntered" self)
		Apollo.RegisterEventHandler("MatchExited", "OnPVPMatchExited", self)
		Apollo.RegisterEventHandler("PvpRatingUpdated", "OnPVPRatingUpdated", self)

		-- Do additional Addon initialization here
		-- Maybe the UI reloaded so be sure to check if we are in a match already
		if MatchingGame:IsInMatchingGame() then
			local tMatchState = MatchingGame:GetPVPMatchState()
	
			if tMatchState ~= nil then
				self:OnPVPMatchEntered()
			end
		end
	end
end

-----------------------------------------------------------------------------------------------
-- PvPHelper Events
-----------------------------------------------------------------------------------------------

function PvPHelper:OnPVPMatchEntered(tEventArgs)

end

function PvPHelper:OnPVPMatchExited(tEventArgs)

end

function PvPHelper:OnPVPRatingUpdated(tEventArgs)

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
