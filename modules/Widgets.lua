local XPTracker = LibStub("AceAddon-3.0"):GetAddon("XPTracker")
local L = LibStub("AceLocale-3.0"):GetLocale("XPTracker")

local Widgets = XPTracker:GetModule("Widgets")
local TextInfo = XPTracker:GetModule("TextInfo")
local ConfigMenu = XPTracker:GetModule("ConfigMenu")

function Widgets:CreateMainWindow()
  XPTracker.MainWindow = CreateFrame("Frame", nil, UIParent, BackdropTemplateMixin and "BackdropTemplate")
  local window = XPTracker.MainWindow
  local windowPosition = XPTracker.db.profile.MainWindow.Position
  Widgets:ConfigureMainWindow(window, windowPosition)
  Widgets:SetMainWindowHandlers(window)
end

function Widgets:ConfigureMainWindow(window, windowPosition)
  ConfigMenu:HandleMainWindowMovement()
  window:EnableMouse(true)
  window:SetWidth(210)
  window:SetHeight(windowPosition.height)
  window:SetClampedToScreen(true)

  window.backdropInfo = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    tile = true,
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tileSize = 16,
    edgeSize = 10,
  }

  window:ApplyBackdrop()

  local windowOpacity = XPTracker.Settings.General.OpacityOptions[XPTracker.db.profile.MainWindow.opacity]
  window:SetBackdropColor(0, 0, 0, windowOpacity)

  TextInfo:CreateWindowText(window)

  Widgets:CreateTrackingButton(window)
  Widgets:CreatePauseButton(window)
  Widgets:CreateBasicInfoToggleButton(window)
  Widgets:CreateXPPHInfoToggleButton(window)
  Widgets:CreateClearButton(window)
  --Widgets:CreateReportButton(window)

  XPTracker:UpdateTextPositionOnEnable()

  window:SetPoint("CENTER", windowPosition.x, windowPosition.y)

  local showingWindow = XPTracker.db.char.ShowingWindow
  if showingWindow then
    window:Show()
  else
    window:Hide()
  end
end

function Widgets:SetMainWindowHandlers(window)
  window:SetScript("OnDragStart", window.StartMoving)

  window:SetScript("OnDragStop", function(window)
    window:StopMovingOrSizing()
    Widgets:UpdateWindowPosition(window)
  end)
end

function Widgets:CreateTrackingButton(window)
  XPTracker.TrackingButton = Widgets:CreatePrimaryButton(window, 5, -98, L["Track"])
  Widgets:UpdateTrackingButtonText(XPTracker.TrackingButton.Text)
  Widgets:SetTrackingButtonHandlers(XPTracker.TrackingButton)
end

function Widgets:SetTrackingButtonHandlers(trackingButton)
  trackingButton:SetScript("OnClick", function(self)
    XPTracker.db.char.TrackingXP = not XPTracker.db.char.TrackingXP
    local tracking = XPTracker.db.char.TrackingXP
    Widgets:UpdateTrackingButtonText(trackingButton.Text)
    if tracking then
      XPTracker.Tracker = XPTracker:ScheduleRepeatingTimer("RefreshXPPH", 1)
      XPTracker:InitiateTracking()
    else
      XPTracker:CancelTimer(XPTracker.Tracker)
      XPTracker:EndTracking()
      XPTracker:HandleHangingPauseOnStop()
    end
    XPTracker:TogglePauseButton()
  end)
end

function Widgets:UpdateTrackingButtonText(textFrame)
  local tracking = XPTracker.db.char.TrackingXP
  local buttonText = ""

  if tracking then buttonText = L["Stop"] else buttonText = L["Track"] end
  textFrame:SetText(buttonText)
end

function Widgets:CreatePauseButton(window)
  XPTracker.PauseButton = Widgets:CreatePrimaryButton(window, 55, -98, L["Pause"])
  XPTracker.PauseButton:Hide()
  Widgets:SetPauseButtonHandlers(XPTracker.PauseButton)
end

function Widgets:UpdatePauseButtonText(textFrame)
  local paused = XPTracker.db.char.TrackingPaused
  local buttonText = ""
  local clearYCoord = XPTracker:GetXandY(XPTracker.ClearButton).y
  if paused then
    buttonText = L["Unpause"]
    XPTracker.PauseButton:SetWidth(85)
    XPTracker.ClearButton:SetPoint("TOPLEFT", 130, clearYCoord)
  else
    buttonText = L["Pause"]
    XPTracker.PauseButton:SetWidth(60)
    XPTracker.ClearButton:SetPoint("TOPLEFT", 105, clearYCoord)
  end
  textFrame:SetText(buttonText)
end

function Widgets:SetPauseButtonHandlers(pauseButton)
  pauseButton:SetScript("OnClick", function(self)
    local tracking = XPTracker.db.char.TrackingXP
    if not tracking then return end -- Do nothing if we're not tracking

    if XPTracker.db.char.TrackingPaused then
      XPTracker.Tracker = XPTracker:ScheduleRepeatingTimer("RefreshXPPH", 1)
    else
      XPTracker:CancelTimer(XPTracker.Tracker)
    end
    XPTracker.db.char.TrackingPaused = not XPTracker.db.char.TrackingPaused
    Widgets:UpdatePauseButtonText(pauseButton.Text)
  end)
end

function Widgets:CreateClearButton(window)
  XPTracker.ClearButton = Widgets:CreatePrimaryButton(window, 55, -98, L["Clear"])
  Widgets:SetClearButtonHandlers(XPTracker.ClearButton)
end

function Widgets:SetClearButtonHandlers(clearButton)
  clearButton:SetScript("OnClick", function(self)
    local tracking = XPTracker.db.char.TrackingXP
    if tracking then
      XPTracker:InitiateTracking()
    else
      XPTracker:ResetTrackingData()
    end
  end)
end

function Widgets:CreateReportButton(window)
  button = CreateFrame("Button", nil, window)
  button:SetWidth(17)
  button:SetHeight(17)

  local t = button:CreateTexture(nil,"BACKGROUND")
  t:SetTexture("Interface\\Buttons\\UI-GuildButton-MOTD-Up")
  t:SetAllPoints(button)
  button.texture = t

  button:SetPoint("TOPLEFT", 145, -2)

  button.Text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  button.Text:SetPoint("CENTER", 0, 0)

  button:Show()
  Widgets:SetReportButtonHandlers(button)
end

function Widgets:SetReportButtonHandlers(reportButton)
  reportButton:SetScript("OnClick", function(self)

  end)
end

function Widgets:UpdateWindowPosition(window)
  local xOfs, yOfs = window:GetCenter()
  local s = window:GetEffectiveScale()
  local uis = UIParent:GetScale()
  xOfs = xOfs * s - GetScreenWidth() * uis / 2
  yOfs = yOfs * s - GetScreenHeight() * uis / 2

  local position = XPTracker.db.profile.MainWindow.Position
  position.x = xOfs / uis
  position.y = yOfs / uis
  position.width = window:GetWidth()
  position.height = window:GetHeight()
end

function Widgets:CreatePrimaryButton(window, xOrigin, yOrigin, title)
  local button = CreateFrame("Button", nil, window)
  button:SetWidth(60)
  button:SetHeight(30)

  local t = button:CreateTexture(nil,"BACKGROUND")
  t:SetTexture("Interface\\Buttons\\UI-SquareButton-Up.blp")
  t:SetAllPoints(button)
  button.texture = t

  button:SetPoint("TOPLEFT", xOrigin, yOrigin)

  button.Text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  button.Text:SetPoint("CENTER", 0, 0)
  button.Text:SetText(title)

  Widgets:AddButtonHighlight(button, 10)

  button:SetScript("OnEnter", function(self)
    button.highlight:Show()
  end)

  button:SetScript("OnLeave", function(self)
    button.highlight:Hide()
  end)

  button:SetScript("OnMouseDown", function(self)
    button.texture:SetTexture("Interface\\Buttons\\UI-SquareButton-Down.blp")
  end)

  button:SetScript("OnMouseUp", function(self)
    button.texture:SetTexture("Interface\\Buttons\\UI-SquareButton-Up.blp")
  end)

  button:Show()
  return button
end

function Widgets:CreateBasicInfoToggleButton(window)
  XPTracker.ToggleBasicInfoButton = Widgets:CreateToggleButton(window, 190, 0)
  local button = XPTracker.ToggleBasicInfoButton
  Widgets:SetBasicInfoToggleButtonHandlers(button, button.texture)
end

function Widgets:SetBasicInfoToggleButtonHandlers(button, texture)
  button:SetScript("OnClick", function(self)
    local showingBasicInfo = XPTracker.db.profile.MainWindow.ShowingBasicInfo
    XPTracker.db.profile.MainWindow.ShowingBasicInfo = not showingBasicInfo
    if showingBasicInfo then
      XPTracker:HideBasicInfo(texture)
    else
      XPTracker:ShowBasicInfo(texture)
    end
  end)
end

function Widgets:CreateXPPHInfoToggleButton(window)
  XPTracker.ToggleXPPHInfoButton = Widgets:CreateToggleButton(window, 190, -98)
  local button = XPTracker.ToggleXPPHInfoButton
  Widgets:SetXPPHInfoToggleButtonHandlers(button, button.texture)
end

function Widgets:SetXPPHInfoToggleButtonHandlers(button, texture)
  button:SetScript("OnClick", function(self)
    local showingXPPHInfo = XPTracker.db.profile.MainWindow.ShowingXPPHInfo
    XPTracker.db.profile.MainWindow.ShowingXPPHInfo = not showingXPPHInfo
    if showingXPPHInfo then
      XPTracker:HideXPPHInfo(texture)
    else
      XPTracker:ShowXPPHInfo(texture)
    end
  end)
end

function Widgets:CreateToggleButton(window, xOrigin, yOrigin, title)
  button = CreateFrame("Button", nil, window)
  button:SetWidth(20)
  button:SetHeight(20)

  local t = button:CreateTexture(nil,"BACKGROUND")
  t:SetTexture("Interface\\Buttons\\UI-Panel-CollapseButton-Up.blp")
  t:SetAllPoints(button)
  button.texture = t

  button:SetPoint("TOPLEFT", xOrigin, yOrigin)

  button.Text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  button.Text:SetPoint("CENTER", 0, 0)

  button:Show()
  return button
end

function Widgets:AddButtonHighlight(frame, width)
  local highlight = frame:CreateTexture(nil, "OVERLAY")
  highlight:SetTexture(136810) -- Interface\\QuestFrame\\UI-QuestTitleHighlight
  highlight:SetBlendMode("ADD")
  highlight:SetHeight(18)
  highlight:ClearAllPoints()
  highlight:SetPoint("RIGHT", frame, "RIGHT", -width, 2)
  highlight:SetPoint("LEFT", frame, "LEFT", width, 2)
  frame.highlight = highlight
  highlight:Hide()
end

function Widgets:CreateReloadButton()
  local reloadButton = CreateFrame("Button", nil, UIParent)
  reloadButton:SetMovable(true)
  reloadButton:EnableMouse(true)
  reloadButton:RegisterForDrag("LeftButton")
  reloadButton:SetScript("OnDragStart", reloadButton.StartMoving)
  reloadButton:SetScript("OnDragStop", reloadButton.StopMovingOrSizing)
  reloadButton:SetFrameStrata("BACKGROUND")
  reloadButton:SetWidth(64)
  reloadButton:SetHeight(64)

  local t = reloadButton:CreateTexture(nil,"BACKGROUND")
  t:SetTexture("Interface\\ICONS\\Ability_Racial_BearForm.blp")
  t:SetAllPoints(reloadButton)
  reloadButton.texture = t

  reloadButton:SetScript("OnClick", function(self)
    DEFAULT_CHAT_FRAME.editBox:SetText("/reload")
    ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)
  end)

  reloadButton:SetPoint("CENTER", 330, -230)
  reloadButton:Show()
end
