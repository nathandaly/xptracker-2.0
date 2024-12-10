local XPTracker = LibStub("AceAddon-3.0"):GetAddon("XPTracker")
local L = LibStub("AceLocale-3.0"):GetLocale("XPTracker")

local Widgets = XPTracker:GetModule("Widgets")
local TextInfo = XPTracker:GetModule("TextInfo")
local xIndent = 5
local textStep = 12

function TextInfo:CreateWindowText(window)
  TextInfo:AddBasicInfoText(window)
  TextInfo:AddXPPHInfoText(window)
  XPTracker.CurrentLevelText:SetTextColor(1, 1, 1, 1)
  TextInfo:UpdateTextColor()
end

function TextInfo:AddBasicInfoText(window)
  local dbInfo = XPTracker.db.char
  local topY = -5
  local initialListTopY = topY - 20
  local initialListBottomY = initialListTopY - textStep * 2
  local restListTopY = initialListBottomY - 20

  XPTracker.CurrentLevelText = TextInfo:CreateTextString(window, "TOPLEFT", xIndent, topY,
    L["XPTracker 2.0 - Level "], dbInfo.CurrentLevel .. ' - ' .. dbInfo.LevelPercent .. "%% ")

  XPTracker.LastEventXPText = TextInfo:CreateTextString(window, "TOPLEFT", xIndent, initialListTopY, L["Last Event XP: "],
    dbInfo.LastEventXP)

  XPTracker.RepeatEventText = TextInfo:CreateTextString(window, "TOPLEFT", xIndent, initialListTopY - textStep, L["Repeat to level: "],
    XPTracker:RepeatToLevel())

  XPTracker.XPToNextLevelText = TextInfo:CreateTextString(window, "TOPLEFT", xIndent, initialListBottomY, L["XP to Level: "],
    dbInfo.MaxXP - dbInfo.PlayerXP)

  XPTracker.CurrentlyRestingText = TextInfo:CreateTextString(window, "TOPLEFT", xIndent, restListTopY,
    L["Currently Resting"], "")

  XPTracker.RestedXPText = TextInfo:CreateTextString(window, "TOPLEFT", xIndent, restListTopY - textStep,
   L["Rested XP: "], dbInfo.RestedXP)
end

function TextInfo:AddXPPHInfoText(window)
  local topY = -130
  local sessionInfoTopY = topY - (textStep * 3) - 20
  local trackingInfo = XPTracker.db.char.TrackingInfo

  XPTracker.XPPHText = TextInfo:CreateTextString(window, "TOPLEFT", xIndent, topY,
    L["XP Per Hour: "], trackingInfo.CurrentXPPH)

  XPTracker.TimeElapsedText = TextInfo:CreateTextString(window, "TOPLEFT", xIndent, topY - textStep,
    L["Time Elapsed: "], TextInfo:DisplayElapsedTime(trackingInfo.TimeElapsed))

  XPTracker.XPRecordedText = TextInfo:CreateTextString(window, "TOPLEFT", xIndent, topY - textStep * 2,
    L["XP Recorded: "], trackingInfo.XPRecorded)

  XPTracker.LevelAtRateText = TextInfo:CreateTextString(window, "TOPLEFT", xIndent, topY - textStep * 3,
    L["Time to Level: "], trackingInfo.TimeToLevelAtRate)

  XPTracker.StartTimeText = TextInfo:CreateTextString(window, "TOPLEFT", xIndent, sessionInfoTopY,
    L["Start Time: "], trackingInfo.StartTime)

  XPTracker.EndTimeText = TextInfo:CreateTextString(window, "TOPLEFT", xIndent, sessionInfoTopY - textStep,
    L["End Time: "], trackingInfo.EndTime)

  XPTracker.ZoneStartedAtText = TextInfo:CreateTextString(window, "TOPLEFT", xIndent, sessionInfoTopY - textStep * 2,
    L["Initial Zone: "], trackingInfo.ZoneStartedAt)

  TextInfo:SetXPPHTextColor(XPTracker.XPPHText)
  TextInfo:SetXPPHTextColor(XPTracker.TimeElapsedText)
  TextInfo:SetXPPHTextColor(XPTracker.XPRecordedText)
  TextInfo:SetXPPHTextColor(XPTracker.LevelAtRateText)
end

function TextInfo:UpdateBasicInfoText()
  XPTracker.CurrentLevelText:SetText(L['XPTracker - Level '] .. XPTracker.db.char.CurrentLevel
    .. ' - ' .. XPTracker.db.char.LevelPercent .. "%"
  )
  XPTracker.LastEventXPText:SetText(L['Last Event XP: '] .. XPTracker.db.char.LastEventXP)
  XPTracker.XPToNextLevelText:SetText(
    L['XP to Level: '] .. XPTracker.db.char.MaxXP - XPTracker.db.char.PlayerXP
  )
  XPTracker.CurrentlyRestingText:SetText(L['Currently Resting'])
  XPTracker.RestedXPText:SetText(L['Rested XP: '] .. XPTracker.db.char.RestedXP)
  XPTracker.RepeatEventText:SetText(L['Repeat to level: '] .. XPTracker:RepeatToLevel())
end

function TextInfo:UpdateXPPHInfoText()
  local trackingInfo = XPTracker.db.char.TrackingInfo
  local displayTime = TextInfo:DisplayElapsedTime(trackingInfo.TimeElapsed)
  if XPTracker.TimeElapsedText and XPTracker.XPRecordedText and XPTracker.LevelAtRateText then
    XPTracker.TimeElapsedText:SetText(L["Time Elapsed: "] .. displayTime)
    TextInfo:DisplayLevelAtRateText()
    XPTracker.XPRecordedText:SetText(L["XP Recorded: "] .. trackingInfo.XPRecorded)
  end
end

function TextInfo:DisplayLevelAtRateText()
  local dbInfo = XPTracker.db.char
  local trackingInfo = dbInfo.TrackingInfo
  if trackingInfo.CurrentXPPH ~= 0 then
    TextInfo:GetLevelAtRateTime(dbInfo, trackingInfo)
  else
    trackingInfo.TimeToLevelAtRate = '...'
  end
  XPTracker.LevelAtRateText:SetText(L["Time to Level: "] .. trackingInfo.TimeToLevelAtRate)
end

function TextInfo:GetLevelAtRateTime(dbInfo, trackingInfo)
  local hourPercent = math.floor((dbInfo.MaxXP - dbInfo.PlayerXP) / trackingInfo.CurrentXPPH * 100) / 100
  if hourPercent < 1 then
    trackingInfo.TimeToLevelAtRate = hourPercent * 60 .. L[" minutes"]
  elseif hourPercent >= 1 then
    trackingInfo.TimeToLevelAtRate = hourPercent .. L[" hours"]
  end
end

function TextInfo:DisplayElapsedTime(timeElapsed)
  local displayTime = L["0 seconds"]
  if timeElapsed < 60 then
    displayTime = timeElapsed .. L[" seconds"]
  elseif timeElapsed >= 60 and timeElapsed < 3600 then
    displayTime = math.floor(timeElapsed / 60) .. L[" minutes"]
  elseif timeElapsed >= 3600 then
    local hours = math.floor(((timeElapsed / 60) / 60) * 100) / 100
    displayTime = hours .. L[" hours"]
  end
  return displayTime
end

function TextInfo:CreateTextString(frame, orientation, x, y, label, dynamicText)
  frame.Text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  frame.Text:SetPoint(orientation, x, y)
  frame.Text:SetFormattedText(label .. dynamicText)
  return frame.Text
end

function TextInfo:SetRestedColor(textFrame)
  local dbInfo = XPTracker.db.char
  if dbInfo.CurrentlyResting or (dbInfo.RestedXP and dbInfo.RestedXP > 0) then
    textFrame:SetTextColor(0, 0.5, 1, 1)
  else
    textFrame:SetTextColor(0.6, 0, 0.6, 1)
  end
end

function TextInfo:SetXPPHTextColor(frame)
  frame:SetTextColor(0.05, 0.7, 0.2, 1)
end

function TextInfo:UpdateTextColor()
  TextInfo:SetRestedColor(XPTracker.CurrentlyRestingText)
  TextInfo:SetRestedColor(XPTracker.RestedXPText)
end

function TextInfo:GetDateTime()
  local hour, minute = GetGameTime()
  if minute < 10 then minute = '0' .. minute end
  return hour .. ':' .. minute
end
