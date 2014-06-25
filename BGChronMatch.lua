
--------------------------------
-- BGChronMatch
--------------------------------

local BGChronMatch = {}
BGChronMatch.__index = BGChronMatch


setmetatable(BGChronMatch, {
  __call = function(cls, ...)
    local self = setmetatable({}, cls)
    return self
  end
})


local eResultTypes = {
  Win     = 0,
  Loss    = 1,
  Forfeit = 2
}

function BGChronMatch.new(o)
  o = o or {}   -- create object if user does not provide one
  setmetatable(o, self)
  self.__index = self
  return o
end


function BGChronMatch:_init()
  self.tDate      = nil
  self.nMatchType = nil
  self.nResult    = nil
  self.tRating    = nil
end

-- Return raw match data
function BGChronMatch:GetData()
  return {
    self.tDate,
    self.nMatchType,
    self.nResult,
    self.tRating
  }
end

function BGChronMatch:SetData(tData)
  self.tDate      = tData.tDate
  self.nMatchType = tData.nMatchType
  self.nResult    = tData.nResult
  self.tRating    = tData.tRating
end

-- Returns data formatted for a grid
function BGChronMatch:GetFormattedData()
  return {
    ["tDate"]      = self:GetDateString(),
    ["nMatchType"] = self:GetMatchTypeString(),
    ["nResult"]    = self:GetResultString(),
    ["tRating"]    = self:GetRatingString()
  }
end

-- Returns sort text for a grid
function BGChronMatch:GetFormattedSortData()
  return {
    ["tDate"]      = self:GetDateSortString(),
    ["nMatchType"] = self:GetMatchTypeString(),
    ["nResult"]    = self:GetResultString(),
    ["tRating"]    = self:GetRatingSortString()
  }
end

-----------------------------------------------------------------------------------------------
-- Data Formatting Functions
-----------------------------------------------------------------------------------------------

function BGChronMatch:GetDateString() 
  local result = "N/A"

  if self.tDate then
    result = string.format("%02d/%02d/%4d %s", self.tDate["nMonth"], self.tDate["nDay"], self.tDate["nYear"], self.tDate["strFormattedTime"])
  end

  return strDate
end

function BGChronMatch:GetMatchTypeString()
  result = "N/A"

  if self.nMatchType then
    result = ktMatchTypes[self.nMatchType]
  end

  return result
end

function BGChronMatch:GetResultString()
  local result = "N/A"
  -- local ktResultTypes = { 
  --   eResultTypes.Win     = "Win",
  --   eResultTypes.Loss    = "Loss",
  --   eResultTypes.Forfeit = "Forfeit"
  -- }

  -- if self.nResultType then
  --   result = ktResultTypes[self.nResultType]
  -- end

  return result
end

function BGChronMatch:GetRatingString()
  local result = "N/A"
  local nPreviousRating = self.tRating.nBeginRating
  local nCurrentRating  = self.tRating.nEndRating

  if nPreviousRating and nCurrentRating then
    if nPreviousRating < nCurrentRating then
      result = string.format("%d (+%d)", nCurrentRating, (nCurrentRating - nPreviousRating))
    elseif nPreviousRating > nCurrentRating then
      result = string.format("%d (-%d)", nCurrentRating, (nPreviousRating - nCurrentRating))
    end
  end

  return result
end

function BGChronMatch:GetDateSortString()
  local result = nil

  if self.tDate then
    result = self.tDate.nTickCount
  end

  return result
end

function BGChronMatch:GetRatingSortString()
  local result = nil

  if self.tRating then
    return self.tRating.nEndRating
  end

  return result
end