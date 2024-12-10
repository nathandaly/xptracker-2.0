local XPTracker = LibStub("AceAddon-3.0"):GetAddon("XPTracker")
local L = LibStub("AceLocale-3.0"):GetLocale("XPTracker")

local Events = XPTracker:GetModule("Events")
local TextInfo = XPTracker:GetModule("TextInfo")

function Events:COMBAT_LOG_EVENT(event)
  if event == "PARTY_KILL" then
    --PlaySound(72978) -- TODO: Add something here later?
  end
end

function Events:PLAYER_XP_UPDATE(event, ...)
  XPTracker:UpdateXPData()
  TextInfo:UpdateBasicInfoText()
  TextInfo:UpdateTextColor()
end

function Events:PLAYER_ENTERING_WORLD()
  XPTracker:UpdateRestingInfo()
end

function Events:PLAYER_LEAVING_WORLD()
  --XPTracker:CleanupTracking()
end

function Events:PLAYER_UPDATE_RESTING()
  print("PLAYER_UPDATE_RESTING")
  XPTracker:UpdateRestingInfo()
end
