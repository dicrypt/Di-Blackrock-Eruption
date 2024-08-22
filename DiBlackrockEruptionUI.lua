-- Include the necessary libraries
local LDB = LibStub("LibDataBroker-1.1"):NewDataObject("DiBlackrockEruption", {
    type = "data source",
    text = "DiBlackrockEruption",
    icon = "Interface\\AddOns\\DiBlackrockEruption\\icon",
    OnClick = function(_, button)
        if button == "LeftButton" then
            if DiBREFrame:IsShown() then
                DiBREFrame:Hide()
            else
                DiBREFrame:Show()
            end
        end
    end,
    OnTooltipShow = function(tooltip)
        tooltip:AddLine("DiBlackrock Eruption")
        tooltip:AddLine("Click to toggle the quest sharer UI.")
        
        -- Add the timer to the tooltip
        local currentTime = GetServerTime()
        local nextEventTime = getNextEventTime(currentTime)
        local timeLeft = nextEventTime - currentTime

        if timeLeft > 0 then
            local hours = math.floor(timeLeft / 3600)
            local minutes = math.floor((timeLeft % 3600) / 60)
            local seconds = timeLeft % 60
            tooltip:AddLine(string.format("Time until next event: %02d:%02d:%02d", hours, minutes, seconds))
        else
            tooltip:AddLine("Event is active!")
        end
    end,
})

local icon = LibStub("LibDBIcon-1.0")

-- Create a saved variables table for the minimap button position and visibility
DiBRE_MinimapData = DiBRE_MinimapData or {}
icon:Register("DiBlackrockEruption", LDB, DiBRE_MinimapData)

-- Create the main frame
local frame = CreateFrame("Frame", "DiBREFrame", UIParent, "BasicFrameTemplateWithInset")
frame:SetSize(200, 150)
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:Hide() -- Initially hidden

-- Title text
frame.title = frame:CreateFontString(nil, "OVERLAY")
frame.title:SetFontObject("GameFontHighlight")
frame.title:SetPoint("CENTER", frame.TitleBg, "CENTER", 0, 0)
frame.title:SetText("Quest Sharer")

-- Share Button
local shareButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
shareButton:SetPoint("CENTER", frame, "CENTER", 0, 20)
shareButton:SetSize(140, 40)
shareButton:SetText("Share Quests")
shareButton:SetNormalFontObject("GameFontNormalLarge")
shareButton:SetHighlightFontObject("GameFontHighlightLarge")
shareButton:SetScript("OnClick", function()
    shareQuests()
end)

-- Timer Text
frame.timerText = frame:CreateFontString(nil, "OVERLAY")
frame.timerText:SetFontObject("GameFontNormal")
frame.timerText:SetPoint("CENTER", frame, "CENTER", 0, -30)
frame.timerText:SetText("Time until next event: --:--")

-- Update the timer every second
local function updateTimer()
    local currentTime = GetServerTime()
    local nextEventTime = getNextEventTime(currentTime)
    local timeLeft = nextEventTime - currentTime

    if timeLeft > 0 then
        local hours = math.floor(timeLeft / 3600)
        local minutes = math.floor((timeLeft % 3600) / 60)
        local seconds = timeLeft % 60
        frame.timerText:SetText(string.format("Time until next event: %02d:%02d:%02d", hours, minutes, seconds))
    else
        frame.timerText:SetText("Event is active!")
    end
end

-- OnUpdate script to keep the timer ticking
frame:SetScript("OnUpdate", function(self, elapsed)
    updateTimer()
end)

-- Function to calculate the next event time
function getNextEventTime(currentTime)
    -- Event occurs every 2 hours starting at midnight (00:00, 02:00, 04:00, ..., 22:00)
    local eventInterval = 2 * 3600 -- 2 hours in seconds
    local secondsSinceMidnight = currentTime % 86400 -- Seconds since 00:00 of the current day

    -- Find the next event time
    local nextEventTime
    if secondsSinceMidnight % eventInterval == 0 then
        nextEventTime = currentTime
    else
        local secondsToNextEvent = eventInterval - (secondsSinceMidnight % eventInterval)
        nextEventTime = currentTime + secondsToNextEvent
    end

    return nextEventTime
end
