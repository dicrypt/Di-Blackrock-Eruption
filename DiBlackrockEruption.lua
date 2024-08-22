local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")

-- Create a saved variables table for the minimap button position and visibility
DiBRE_MinimapData = DiBRE_MinimapData or {}

-- Include the necessary libraries
local dataObject = LDB:NewDataObject("DiBlackrockEruption", {
    type = "data source",
    text = "DiBlackrockEruption",
    icon = "Interface\\AddOns\\DiBlackrockEruption\\icon",  -- Update with your icon path
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
        
        local timeData = timeUntilNextEventOrEnd()

        if timeData.isErupting then
            tooltip:AddLine(string.format("Event is active! Time remaining: %02d minutes", timeData.minutes))
        else
            tooltip:AddLine(string.format("Time until next event: %02d minutes", timeData.minutes))
        end
    end,
})
LDBIcon:Register("DiBlackrockEruption", dataObject, DiBRE_MinimapData)




-- Slash Command Handler
SLASH_DIBRE1 = "/dibre"
SlashCmdList["DIBRE"] = function(msg)
    local args = {}
    for word in string.gmatch(msg, "%S+") do
        table.insert(args, word)
    end
    
    if #args > 0 and args[1] == "share" then
        -- Share quests if 'share' argument is provided
        shareQuests()
    else
        -- Toggle the UI if no 'share' argument is provided
        if DiBREFrame:IsShown() then
            DiBREFrame:Hide()
        else
            DiBREFrame:Show()
        end
    end
end



-- List of Quest IDs
local questIDs = {
    84348, -- Priority Target: Duke Tectonis
    84349, -- Priority Target: Duke Searbrand
    84350, -- Grinding Them Down
    84351, -- Work Smarter, Not Harder
    84355, -- More Like Lame-bringers!
    84356, -- Oh, Shiny!
    84359, -- Sleepless Nights
    84360, -- Firefighting
    84372, -- Lava Diving
}
local currentQuestIndex = 1 -- To track the current quest to share

-- Create the main frame
local frame = CreateFrame("Frame", "DiBREFrame", UIParent, "BasicFrameTemplateWithInset")

frame:SetSize(285, 150)
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
frame.title:SetPoint("CENTER", frame.TitleBg, "CENTER", 10, 0)
frame.title:SetText("Di Blackrock Eruption")

-- Timer Text
frame.timerText = frame:CreateFontString(nil, "OVERLAY")
frame.timerText:SetFontObject("GameFontNormal")
frame.timerText:SetPoint("TOP", frame, "TOP", 0, -30)
frame.timerText:SetText("Time until next event: --:--")

-- Share All button
frame.shareAllButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
frame.shareAllButton:SetPoint("TOP", frame.timerText, "BOTTOM", -60, -10)
frame.shareAllButton:SetSize(120, 40)
frame.shareAllButton:SetText("Share All")
frame.shareAllButton:SetScript("OnClick", function()
    shareQuests()
end)

-- Share Next button
frame.shareNextButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
frame.shareNextButton:SetPoint("TOP", frame.timerText, "BOTTOM", 60, -10)
frame.shareNextButton:SetSize(120, 40)
frame.shareNextButton:SetText("Share Next")
frame.shareNextButton:SetScript("OnClick", function()
    shareNextQuestManually()
end)

-- Share Text
frame.shareText = frame:CreateFontString(nil, "OVERLAY")
frame.shareText:SetFontObject("GameFontNormal")
frame.shareText:SetPoint("TOP", frame.timerText, "BOTTOM", 0, -60)
frame.shareText:SetText("Shared Quest:\n--")
-- frame.shareText:Hide() -- Initially hidden

-- OnUpdate script to keep the timer ticking
frame:SetScript("OnUpdate", function(self, elapsed)
    local timeData = timeUntilNextEventOrEnd()

    if timeData.isErupting then
        frame.timerText:SetText(string.format("Event is active! Time remaining:\n%02d minutes %02d seconds", timeData.minutes, timeData.seconds))
    else
        frame.timerText:SetText(string.format("Time until next event:\n%02d hours %02d minutes %02d seconds", timeData.hours, timeData.minutes, timeData.seconds))
    end
end)

-- Function to calculate the time until the next event or end
function timeUntilNextEventOrEnd()
    -- Event occurs every 2 hours starting at midnight (00:00, 02:00, 04:00, ..., 22:00)
    local currentTime = GetServerTime()
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

    local timeLeft = nextEventTime - currentTime
    local hours = math.floor(timeLeft / 3600)
    local minutes = math.floor((timeLeft % 3600) / 60)
    local seconds = timeLeft % 60
    local isErupting = hours == 1

    return {
        hours = hours,
        minutes = minutes,
        seconds = seconds,
        isErupting = isErupting,
    }
end

-- Function to share quests
function shareQuests()

    -- Share each quest with a 5-second delay between each
    local index = 1
    local function shareNextQuest()
        if index <= #questIDs then
            local questID = questIDs[index]
            local questLogIndex = GetQuestLogIndexByID(questID)
            if questLogIndex then
                local questTitle = GetQuestLogTitle(questLogIndex)
                QuestLogPushQuest(questLogIndex)
                if questTitle then
                    frame.shareText:SetText(string.format("Shared ("..index.."/9):\n" .. questTitle))
                    frame.shareText:Show()
                    print("Shared quest ID: " .. questTitle)
                end
            end
            index = index + 1
            C_Timer.After(1, shareNextQuest) -- Schedule the next call in 1 second
        else
            currentQuestIndex = 1
            frame.shareNextButton:SetEnabled(true)
        end
    end

    shareNextQuest() -- Start the process
    frame.shareNextButton:SetEnabled(false)
end

-- Function to share quests manually
function shareNextQuestManually()
    local questID = questIDs[currentQuestIndex]
    if questID then
        local questLogIndex = GetQuestLogIndexByID(questID)
        if questLogIndex then
            local questTitle = GetQuestLogTitle(questLogIndex)
            QuestLogPushQuest(questLogIndex)
            frame.shareText:SetText(string.format("Shared ("..currentQuestIndex.."/9): " .. questTitle))
            frame.shareText:Show()
            print("Shared quest ID: " .. questTitle)
        end

        -- Move to the next quest
        currentQuestIndex = currentQuestIndex + 1
        if currentQuestIndex > #questIDs then
            currentQuestIndex = 1 -- Cycle back to the first quest if at the end
            print("Restarted")
        end
    else
        print("No more quests to share.")
    end
end