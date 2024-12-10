local XPTracker = LibStub("AceAddon-3.0"):NewAddon("XPTracker", "AceConsole-3.0", "AceEvent-3.0",  "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("XPTracker")
local db

local Widgets = XPTracker:NewModule("Widgets", "AceEvent-3.0")
local Events = XPTracker:NewModule("Events", "AceEvent-3.0")
local TextInfo = XPTracker:NewModule("TextInfo", "AceEvent-3.0")
local ConfigMenu = XPTracker:NewModule("ConfigMenu", "AceEvent-3.0")

local defaults = {
  profile = {
    MainWindow = {
      Position = {
        x = 330,
        y = -125,
        width = 150,
        height = 200,
      },
      opacity = 6,
      ShowingBasicInfo = true,
      ShowingXPPHInfo = true,
      IsLocked = false,
    },
  },
  char = {
    ShowingWindow = true,
    PlayerXP = 0,
    MaxXP = 0,
    PlayerLvl = 0,
    LevelPercent = 0,
    CurrentlyResting = false,
    RestedXP = 0,
    CurrentLevel = 0,
    LastEventXP = 0,
    TrackingXP = false,
    TrackingPaused = false,
    TrackingInfo = {
      CurrentXPPH = 0,
      TimeElapsed = 0,
      XPRecorded = 0,
      TimeToLevelAtRate = '...',
      ZoneStartedAt = '...',
      StartTime = '...',
      EndTime = '...',
    }
  },
}

function XPTracker:OnInitialize()
  self.db = LibStub("AceDB-3.0"):New("XPTrackerDB", defaults, true)
  db = self.db
end

function XPTracker:OnEnable()
  XPTracker:RegisterEvents()
  XPTracker:UpdateXPData()
  --Widgets:CreateReloadButton() -- for quick reload testing only
  Widgets:CreateMainWindow()
  ConfigMenu:RegisterConfigMenu()
  XPTracker:CleanupTracking()
end

function XPTracker:OnDisable()
  XPTracker:CleanupTracking()
end

function XPTracker:RegisterEvents()
  Events:RegisterEvent("COMBAT_LOG_EVENT")
  Events:RegisterEvent("PLAYER_XP_UPDATE")
  Events:RegisterEvent("PLAYER_ENTERING_WORLD")
  Events:RegisterEvent("PLAYER_LEAVING_WORLD")
  Events:RegisterEvent("PLAYER_UPDATE_RESTING")
end

function XPTracker:UpdateXPData()
  local levelXP = UnitXP("player")
  -- Events:PLAYER_XP_UPDATE fires twice on a single enemy kill
  if levelXP == db.char.PlayerXP then return end
  local playerLevel = UnitLevel("player")
  local dbInfo = db.char
  dbInfo.LastEventXP = levelXP - dbInfo.PlayerXP
  XPTracker:HandleLevelChange(playerLevel)
  dbInfo.CurrentLevel = playerLevel -- XPTracker:HandleLevelChange(playerLevel) must come before
  dbInfo.PlayerXP = levelXP
  dbInfo.MaxXP = UnitXPMax("player")
  dbInfo.CurrentlyResting = IsResting()
  dbInfo.RestedXP = GetXPExhaustion() or 0
  dbInfo.LevelPercent = math.floor((dbInfo.PlayerXP/dbInfo.MaxXP * 100) * 10) / 10
  if dbInfo.TrackingXP and not dbInfo.TrackingPaused then
    dbInfo.TrackingInfo.XPRecorded = dbInfo.TrackingInfo.XPRecorded + dbInfo.LastEventXP
  end
end

function XPTracker:RepeatToLevel()
  if db.char.LastEventXP ~= 0 then
    return math.floor((db.char.MaxXP - db.char.PlayerXP)
      / db.char.LastEventXP) .. 'x'
  end
  return 'N/A'
end

function XPTracker:RefreshXPPH()
  local trackingInfo = db.char.TrackingInfo
  trackingInfo.TimeElapsed = trackingInfo.TimeElapsed + 1
  local timeElapsed = trackingInfo.TimeElapsed
  local XPRecorded = trackingInfo.XPRecorded
  TextInfo:UpdateXPPHInfoText()
  if timeElapsed % 10 == 0 then -- Only update XPPH every 10 seconds
    trackingInfo.CurrentXPPH = XPTracker:GetXPPH(timeElapsed, XPRecorded)
    if XPTracker.XPPHText then
      XPTracker.XPPHText:SetText(L["XP Per Hour: "] .. trackingInfo.CurrentXPPH)
    end
  end
end

function XPTracker:GetXPPH(timeElapsed, XPRecorded)
  if timeElapsed < 3600 then
    return XPTracker:GetXPPHUnderOneHour(timeElapsed, XPRecorded)
  else
    return XPTracker:GetXPPHOverOneHour(timeElapsed, XPRecorded)
  end
end

function XPTracker:GetXPPHUnderOneHour(timeElapsed, XPRecorded)
  local hourMultiple = math.floor(timeElapsed / 3600) + 1
  local multiplier = (3600 * hourMultiple) / timeElapsed
  return math.floor(multiplier * XPRecorded)
end

function XPTracker:GetXPPHOverOneHour(timeElapsed, XPRecorded)
  local hours = math.floor(((timeElapsed / 60) / 60) * 100) / 100
  return math.floor(XPRecorded / hours)
end

function XPTracker:InitiateTracking()
  XPTracker:ResetTrackingData()
  local tracking = db.char.TrackingXP
  local trackingInfo = db.char.TrackingInfo
  if tracking then trackingInfo.ZoneStartedAt = GetZoneText() end
  trackingInfo.StartTime = TextInfo:GetDateTime()
  if XPTracker.ZoneStartedAtText then
    XPTracker.ZoneStartedAtText:SetText(L["Initial Zone: "] .. trackingInfo.ZoneStartedAt)
    XPTracker.StartTimeText:SetText(L["Start Time: "] .. trackingInfo.StartTime)    
  end
end

function XPTracker:EndTracking()
  local trackingInfo = db.char.TrackingInfo
  trackingInfo.EndTime = TextInfo:GetDateTime()
  XPTracker.EndTimeText:SetText(L["End Time: "] .. trackingInfo.EndTime)
end

function XPTracker:TogglePauseButton()
  local tracking = db.char.TrackingXP
  local clearYCoord = XPTracker:GetXandY(XPTracker.ClearButton).y
  if tracking then
    XPTracker.PauseButton:Show()
    XPTracker.ClearButton:SetPoint("TOPLEFT", 105, clearYCoord)
  else
    XPTracker.PauseButton:Hide()
    XPTracker.ClearButton:SetPoint("TOPLEFT", 55, clearYCoord)
  end
end

function XPTracker:ResetTrackingData()
  local trackingInfo = db.char.TrackingInfo
  if XPTracker.XPPHText ~= nil then
    XPTracker.XPPHText:SetText(L["XP Per Hour: "] .. 0)
    XPTracker.TimeElapsedText:SetText(L["Time Elapsed: "] .. L['0 seconds'])
    XPTracker.XPRecordedText:SetText(L["XP Recorded: "] .. 0)
    XPTracker.StartTimeText:SetText(L["Start Time: "] .. "...")
    XPTracker.EndTimeText:SetText(L["End Time: "] .. "...")
    XPTracker.LevelAtRateText:SetText(L["Time to Level: "] .. "...")
    XPTracker.ZoneStartedAtText:SetText(L["Initial Zone: "] .. "...")
    trackingInfo.CurrentXPPH = 0
    trackingInfo.TimeElapsed = 0
    trackingInfo.XPRecorded = 0
    trackingInfo.ZoneStartedAt = '...'
    trackingInfo.StartTime = '...'
    trackingInfo.EndTime = '...'
    trackingInfo.TimeToLevelAtRate = '...'
  end
end


function XPTracker:HandleHangingPauseOnStop()
  if db.char.TrackingPaused then
    XPTracker:CancelTimer(XPTracker.Tracker)
    db.char.TrackingPaused = not db.char.TrackingPaused
    Widgets:UpdatePauseButtonText(XPTracker.PauseButton.Text)
  end
end

function XPTracker:HandleLevelChange(playerLevel)
  local dbInfo = db.char
  local tracking = dbInfo.TrackingXP
  local levelChanged = playerLevel ~= dbInfo.CurrentLevel
  if levelChanged and tracking then
    XPTracker:CancelTimer(XPTracker.Tracker)
    XPTracker.Tracker = XPTracker:ScheduleRepeatingTimer("RefreshXPPH", 1)
    if XPTracker.StartTimeText then -- InitiateTracking makes text changes - make sure text exists
      XPTracker:InitiateTracking()
    end
    dbInfo.XPRecorded = 0
    dbInfo.LastEventXP = 0
  elseif levelChanged then
    dbInfo.XPRecorded = 0
    dbInfo.LastEventXP = 0
  end
end

function XPTracker:HideXPPHInfo(texture)
  local trackingXP = db.char.TrackingXP
  XPTracker.XPPHText:Hide()
  XPTracker.TimeElapsedText:Hide()
  XPTracker.XPRecordedText:Hide()
  XPTracker.LevelAtRateText:Hide()
  XPTracker.StartTimeText:Hide()
  XPTracker.EndTimeText:Hide()
  XPTracker.ZoneStartedAtText:Hide()
  XPTracker.TrackingButton:Hide()
  if trackingXP then XPTracker.PauseButton:Hide() end
  XPTracker.ClearButton:Hide()
  XPTracker.MainWindow:SetResizeBounds(200, 125)
  texture:SetTexture("Interface\\Buttons\\UI-Panel-ExpandButton-Up.blp")
  XPTracker:UpdateWindowHeight()
end

function XPTracker:ShowXPPHInfo(texture)
  local trackingXP = db.char.TrackingXP
  XPTracker.XPPHText:Show()
  XPTracker.TimeElapsedText:Show()
  XPTracker.XPRecordedText:Show()
  XPTracker.LevelAtRateText:Show()
  XPTracker.StartTimeText:Show()
  XPTracker.EndTimeText:Show()
  XPTracker.ZoneStartedAtText:Show()
  XPTracker.TrackingButton:Show()
  if trackingXP then XPTracker.PauseButton:Show() end
  XPTracker.ClearButton:Show()
  XPTracker.MainWindow:SetResizeBounds(200, 250)
  texture:SetTexture("Interface\\Buttons\\UI-Panel-CollapseButton-Up.blp")
  XPTracker:UpdateWindowHeight()
end

-- Should these text toggle/movement functions all be in TextInfo instead?
function XPTracker:HideBasicInfo(texture)
  XPTracker.LastEventXPText:Hide()
  XPTracker.RepeatEventText:Hide()
  XPTracker.XPToNextLevelText:Hide()
  XPTracker.CurrentlyRestingText:Hide()
  XPTracker.RestedXPText:Hide()
  XPTracker.MainWindow:SetResizeBounds(200, 125)
  texture:SetTexture("Interface\\Buttons\\UI-Panel-ExpandButton-Up.blp")
  XPTracker:MoveXPPHText(80)
  XPTracker:UpdateWindowHeight()
end

function XPTracker:ShowBasicInfo(texture)
  XPTracker.LastEventXPText:Show()
  XPTracker.RepeatEventText:Show()
  XPTracker.XPToNextLevelText:Show()
  XPTracker.CurrentlyRestingText:Show()
  XPTracker.RestedXPText:Show()
  XPTracker.MainWindow:SetResizeBounds(200, 250)
  texture:SetTexture("Interface\\Buttons\\UI-Panel-CollapseButton-Up.blp")
  XPTracker:MoveXPPHText(-80)
  XPTracker:UpdateWindowHeight()
end

function XPTracker:MoveXPPHText(yChange)
  XPTracker:MoveFrame(XPTracker.TrackingButton, yChange)
  XPTracker:MoveFrame(XPTracker.PauseButton, yChange)
  XPTracker:MoveFrame(XPTracker.ClearButton, yChange)
  XPTracker:MoveFrame(XPTracker.ToggleXPPHInfoButton, yChange)

  XPTracker:MoveFrame(XPTracker.XPPHText, yChange)
  XPTracker:MoveFrame(XPTracker.TimeElapsedText, yChange)
  XPTracker:MoveFrame(XPTracker.XPRecordedText, yChange)
  XPTracker:MoveFrame(XPTracker.LevelAtRateText, yChange)
  XPTracker:MoveFrame(XPTracker.StartTimeText, yChange)
  XPTracker:MoveFrame(XPTracker.EndTimeText, yChange)
  XPTracker:MoveFrame(XPTracker.ZoneStartedAtText, yChange)
end

function XPTracker:MoveFrame(frame, yChange)
  local coords = XPTracker:GetXandY(frame)
  frame:SetPoint("TOPLEFT", coords.x, coords.y + yChange)
end

function XPTracker:GetXandY(frame)
  local _point, _relativeTo, _relativePoint, xOfs, yOfs = frame:GetPoint()
  return { x = xOfs, y = yOfs }
end

function XPTracker:UpdateWindowHeight()
  local showingXPPHInfo = XPTracker.db.profile.MainWindow.ShowingXPPHInfo
  local showingBasicInfo = XPTracker.db.profile.MainWindow.ShowingBasicInfo
  local showingCount = 0
  local window = XPTracker.MainWindow
  local windowPosition = XPTracker.db.profile.MainWindow.Position
  if showingXPPHInfo then showingCount = showingCount + 1 end
  if showingBasicInfo then showingCount = showingCount + 1 end
  if showingCount == 0 then
    --window:SetPoint("CENTER", "UIParent", windowPosition.x, windowPosition.y + 55)
    window:SetHeight(40)
  elseif showingCount == 1 then
    window:SetHeight(150)
    --window:SetPoint("CENTER", "UIParent", windowPosition.x, windowPosition.y)
  else
    window:SetHeight(250)
    --window:SetPoint("CENTER", "UIParent", windowPosition.x, windowPosition.y)
  end
end

function XPTracker:UpdateTextPositionOnEnable()
  local showingXPPHInfo = XPTracker.db.profile.MainWindow.ShowingXPPHInfo
  local showingBasicInfo = XPTracker.db.profile.MainWindow.ShowingBasicInfo
  if not showingXPPHInfo then XPTracker:HideXPPHInfo(XPTracker.ToggleXPPHInfoButton.texture) end
  if not showingBasicInfo then XPTracker:HideBasicInfo(XPTracker.ToggleBasicInfoButton.texture) end
end

function XPTracker:CleanupTracking()
  XPTracker:CancelTimer(XPTracker.Tracker)
  if db.char.TrackingXP then XPTracker:EndTracking() end
  db.char.TrackingXP = false
  XPTracker:HandleHangingPauseOnStop()
  XPTracker:TogglePauseButton()
  Widgets:UpdateTrackingButtonText(XPTracker.TrackingButton.Text)
end

function XPTracker:UpdateRestingInfo()
  db.char.CurrentlyResting = IsResting()
  db.char.RestedXP = GetXPExhaustion()
  if db.char.RestedXP and XPTracker.RestedXPText then
    XPTracker.RestedXPText:SetText(L["Rested XP: "] .. db.char.RestedXP)
    TextInfo:UpdateTextColor()
  end
  if XPTracker.CurrentlyRestingText then
    XPTracker.CurrentlyRestingText:SetText(
      L["Currently Resting: "] .. tostring(db.char.CurrentlyResting))
    TextInfo:UpdateTextColor()
  end
end

-- TODOs
-- 1) Maybe add button to print out tracking data to chat window - do this for basic and XPPH separately
-- 2) Add actual languages for localization
-- 3) General cleanup - upvalues etc
-- 4) Show turn-in XP for quests on quest log
-- 5) Show total amount of XP from current quests
-- 6) Add config option to set how often you want the tracking timer to update
-- 7) Add config option to set whether the tracker should auto reset when entering dungeon
-- 8) Add more screenshots

-- BUGS
-- seems to reset to half size when you log out with both sections open - sometimes

-- Maybe:
-- 1) Use symbols for pause and play instead of words?
