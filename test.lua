require "BGChronMatch"

local t = {
    ["tDate"]      = {
      ["nHour"] = 1,
      ["nSecond"] = 51,
      ["nMonth"] = 6,
      ["nHour"] = 16,
      ["strFormattedTime"] = "1:15:51 AM",
      ["nYear"] = 2014,
      ["nTickCount"] = 885763218,
      ["nDay"] = 25,
      ["nDayOfWeek"] = 4,
    },
    ["nMatchType"] = 3,
    ["nResult"]    = 0,
    ["tRating"]    = {
      ["nBeginRating"] = 1000,
      ["nEndRating"]   = 1040
    }
  }

local test = BGChronMatch:new()
test:SetData(t)
print(test:GetDateString())

