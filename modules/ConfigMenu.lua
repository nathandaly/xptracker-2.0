local XPTracker = LibStub("AceAddon-3.0"):GetAddon("XPTracker")
local L = LibStub("AceLocale-3.0"):GetLocale("XPTracker")

local ConfigMenu = XPTracker:GetModule("ConfigMenu")
local Widgets = XPTracker:GetModule("Widgets")

XPTracker.Settings = {
  General = {
    OpacityOptions = {0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1},
  },
  Tracking = {
    intervalOptions = {1, 5, 10, 15, 30},
  },
}


local function getOptions()
    local profile = XPTracker.db.profile
    local char = XPTracker.db.char
    options = {
        name = "XPTracker",
        type = "group",
        args = {
            general = {
                type = "group",
                inline = true,
                name = "General Settings",
                order = 1,
                args = {
                    lockWindow = {
                        name = "Lock window",
                        desc = "Lock the GUI window in place",
                        type = "toggle",
                        order = 1,
                        set = function(info, val)
                            profile.MainWindow.IsLocked = val
                            ConfigMenu:HandleMainWindowMovement()
                        end,
                        get = function(info)
                            return profile.MainWindow.IsLocked
                        end,
                    },
                    hideWindow = {
                        name = "Toggle visibility",
                        desc = "Toggle hiding the GUI window",
                        type = "toggle",
                        order = 2,
                        set = function(info, val)
                            char.ShowingWindow = val
                            ConfigMenu:ToggleWindowVisibility()
                        end,
                        get = function(info, val)
                            return char.ShowingWindow
                        end,
                    },
                    moveToCenter = {
                        name = "Center GUI window",
                        desc = "Move window to center in case you lost track of it",
                        type = "execute",
                        func = function()
                            ConfigMenu:BringWindowToCenter()
                        end,
                        order = 3,
                    },
                    windowOpacity = {
                        type = "select",
                        name = "Window Opacity",
                        desc = "Set the window opacity",
                        values = XPTracker.Settings.General.OpacityOptions,
                        set = function(info, val)
                            profile.MainWindow.opacity = val
                            ConfigMenu:UpdateWindowOpacity(info, val)
                        end,
                        get = function(info, val)
                            return profile.MainWindow.opacity
                        end,
                    },
                },
            },
            tracking = {
              type = "group",
              inline = true,
              name = "XP Tracking",
              order = 2,
              args = {
                  xpPerHourRefreshInterval = {
                      type = "select",
                      name = "XP Per Hour Interval",
                      desc = "How often XP Tracker should refresh the XP per hour value",
                      values = function()
                          local options = {}
                          local selectedInterval = profile.Settings.Tracking.Interval or 10
                          for k,v in pairs(XPTracker.Settings.Tracking.intervalOptions) do
                              if k == selectedInterval then
                                  options[v] = v .. " seconds (selected)"
                              else
                                  options[v] = v .. " seconds"
                              end
                          end
                          return options
                      end,
                      set = function(info, val)
                        XPTracker:DebugPrint("Setting interval to: " .. val)
                        profile.Settings.Tracking.Interval = val
                      end,
                      get = function(info, val)
                          return profile.Settings.Tracking.Interval
                      end,
                  },
              },
            },
            dev = {
              type = "group",
              inline = true,
              name = "Developer Settings",
              order = 3,
              args = {
                debug = {
                  name = "Debug mode",
                  desc = "Toggle debug mode",
                  type = "toggle",
                  set = function(info, val) 
                  char.Debug = val
                end,
                get = function(info, val)
                  return char.Debug
                  end,
                },
              },
            },
        },
    }
    return options
end

function ConfigMenu:HandleMainWindowMovement()
    local isLocked = XPTracker.db.profile.MainWindow.IsLocked
    XPTracker.MainWindow:SetMovable(not isLocked)
    if isLocked then
        XPTracker.MainWindow:RegisterForDrag()
    else
        XPTracker.MainWindow:RegisterForDrag("LeftButton")
    end
end

function ConfigMenu:BringWindowToCenter()
    local windowPosition = XPTracker.db.profile.MainWindow.Position
    local window = XPTracker.MainWindow
    local halfScreenWidth = window:GetParent():GetWidth() / 2
    local halfScreenHeight = window:GetParent():GetHeight() / 2
    window:SetPoint("TOPLEFT", window:GetParent(), "TOPLEFT", halfScreenWidth, -halfScreenHeight)
    Widgets:UpdateWindowPosition(window)
end

function ConfigMenu:ToggleWindowVisibility()
    local showingWindow = XPTracker.db.char.ShowingWindow
    local window = XPTracker.MainWindow
    if showingWindow then
        window:Show()
    else
        window:Hide()
    end
end

function ConfigMenu:UpdateWindowOpacity(info, val)
    local opacity = XPTracker.OpacityOptions[XPTracker.db.profile.MainWindow.opacity]
    if XPTracker.MainWindow.bg then
        XPTracker.MainWindow.bg:SetColorTexture(0, 0, 0, opacity)
    end
end

-- Initialize the MainWindow's background and border
function Widgets:InitializeMainWindow(window)
    -- Background
    if not window.bg then
        window.bg = window:CreateTexture(nil, "BACKGROUND")
        window.bg:SetAllPoints(true)
        window.bg:SetColorTexture(0, 0, 0, XPTracker.db.profile.MainWindow.opacity or 1)
    end

    -- Border
    if not window.border then
        window.border = window:CreateTexture(nil, "BORDER")
        window.border:SetPoint("TOPLEFT", -8, 8)
        window.border:SetPoint("BOTTOMRIGHT", 8, -8)
        window.border:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Border")
    end
end

function ConfigMenu:RegisterConfigMenu()
    LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("XPTracker", getOptions())
    -- Register slash command to show/hide options
    SLASH_XPTRACKER1 = "/xpt"
    SLASH_XPTRACKER2 = "/xptracker"
    SlashCmdList["XPTRACKER"] = function()
        if self.optionsFrame and self.optionsFrame:IsShown() then
            self.optionsFrame:Hide()
        else
            self.optionsFrame = LibStub("AceConfigDialog-3.0"):Open("XPTracker")
        end
    end
end