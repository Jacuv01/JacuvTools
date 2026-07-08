local addonName, addon = ...

local TalentManager = {}
addon.TalentManager = TalentManager

local talentButtons = {}
local originalSpentPoints = 0
local checkTicker = nil
local stateUpdateTicker = nil
local waitTicker = nil

local UpdateButtonStates

local function GetTalentPoints()
    if ProfessionsFrame and 
       ProfessionsFrame.SpecPage and 
       ProfessionsFrame.SpecPage.DetailedView then
        
        local unspentFrame = ProfessionsFrame.SpecPage.DetailedView.UnspentPoints
        if unspentFrame then
            if unspentFrame.GetText then
                return unspentFrame:GetText() or "0"
            elseif unspentFrame.Count and unspentFrame.Count.GetText then
                return unspentFrame.Count:GetText() or "0"
            elseif unspentFrame.Text and unspentFrame.Text.GetText then
                return unspentFrame.Text:GetText() or "0"
            else
                return "0"
            end
        end
    end
    return "0"
end

local function GetSpendPointsButton()
    if ProfessionsFrame and 
       ProfessionsFrame.SpecPage and 
       ProfessionsFrame.SpecPage.DetailedView and
       ProfessionsFrame.SpecPage.DetailedView.SpendPointsButton then
        return ProfessionsFrame.SpecPage.DetailedView.SpendPointsButton
    end
    return nil
end

local function GetUndoButton()
    if ProfessionsFrame and 
       ProfessionsFrame.SpecPage and 
       ProfessionsFrame.SpecPage.UndoButton then
        return ProfessionsFrame.SpecPage.UndoButton
    end
    return nil
end

local function GetApplyButton()
    if ProfessionsFrame and 
       ProfessionsFrame.SpecPage and 
       ProfessionsFrame.SpecPage.ApplyButton then
        return ProfessionsFrame.SpecPage.ApplyButton
    end
    return nil
end

local function AddOnePoint()
    local spendButton = GetSpendPointsButton()
    if spendButton and spendButton:IsEnabled() then
        spendButton:Click()
        
        C_Timer.After(0.1, function()
            UpdateButtonStates()
        end)
    end
end

local function RemoveOnePoint()
    local undoButton = GetUndoButton()
    if not undoButton or not undoButton:IsEnabled() then
        return
    end
    
    local currentUnspentText = GetTalentPoints()
    local currentUnspent = tonumber(currentUnspentText) or 0
    
    undoButton:Click()
    
    C_Timer.After(0.2, function()
        local newUnspentText = GetTalentPoints()
        local newUnspent = tonumber(newUnspentText) or 0
        local pointsToRestore = newUnspent - currentUnspent - 1
        
        if pointsToRestore > 0 then
            local function restorePoints()
                for i = 1, pointsToRestore do
                    local spendButton = GetSpendPointsButton()
                    if spendButton and spendButton:IsEnabled() then
                        spendButton:Click()
                        if i < pointsToRestore then
                            C_Timer.After(0.05 * i, function() end)
                        end
                    else
                        break
                    end
                end
                
                C_Timer.After(0.1, function()
                    UpdateButtonStates()
                end)
            end
            
            restorePoints()
        else
            UpdateButtonStates()
        end
    end)
end

local function AddMaxPoints()
    local maxAttempts = 50
    local attempts = 0
    
    local function tryAddPoint()
        attempts = attempts + 1
        if attempts > maxAttempts then
            UpdateButtonStates()
            return
        end
        
        local spendButton = GetSpendPointsButton()
        if spendButton and spendButton:IsEnabled() then
            spendButton:Click()
            C_Timer.After(0.05, tryAddPoint)
        else
            UpdateButtonStates()
        end
    end
    
    tryAddPoint()
end

UpdateButtonStates = function()
    if not talentButtons or #talentButtons == 0 then
        return
    end
    
    local spendButton = GetSpendPointsButton()
    local undoButton = GetUndoButton()
    
    local canSpend = spendButton and spendButton:IsEnabled()
    local canUndo = undoButton and undoButton:IsEnabled()
    
    if talentButtons[2] then
        if canSpend then
            talentButtons[2]:Enable()
        else
            talentButtons[2]:Disable()
        end
    end

    if talentButtons[3] then
        if canSpend then
            talentButtons[3]:Enable()
        else
            talentButtons[3]:Disable()
        end
    end
    
    if talentButtons[1] then
        if canUndo then
            talentButtons[1]:Enable()
        else
            talentButtons[1]:Disable()
        end
    end
end

local function CreateTalentButton(text, onClick, position)
    local button = CreateFrame("Button", "JacuvTalentButton"..position, UIParent, "UIPanelButtonTemplate")
    button:SetSize(60, 25)
    button:SetText(text)
    button:SetScript("OnClick", onClick)
    
    local pointsText = ProfessionsFrame and ProfessionsFrame.SpecPage and 
                      ProfessionsFrame.SpecPage.DetailedView and
                      ProfessionsFrame.SpecPage.DetailedView.PointsText
    
    if pointsText then
        local xOffset, anchorPoint, relativePoint
        
        if position == 1 then
            anchorPoint = "CENTER"
            relativePoint = "CENTER"
            xOffset = -55
        elseif position == 2 then
            anchorPoint = "CENTER"
            relativePoint = "CENTER"
            xOffset = 60
        else
            anchorPoint = "CENTER"
            relativePoint = "CENTER"
            xOffset = 125
        end
        
        button:SetPoint(anchorPoint, pointsText, relativePoint, xOffset, 0)
        button:SetFrameStrata("HIGH")
        
        local parentFrame = pointsText:GetParent()
        if parentFrame and parentFrame.GetFrameLevel then
            button:SetFrameLevel(parentFrame:GetFrameLevel() + 1)
        else
            button:SetFrameLevel(100)
        end
    else
        local xOffset = (position - 2) * 65
        button:SetPoint("CENTER", UIParent, "CENTER", xOffset, 0)
        button:SetFrameStrata("FULLSCREEN_DIALOG")
        button:SetFrameLevel(9999)
    end
    
    button:Show()
    
    return button
end

local function CreateTalentButtons()
    if talentButtons and #talentButtons > 0 then
        for i, button in ipairs(talentButtons) do
            if button then
                button:Hide()
                button:SetParent(nil)
            end
        end
    end
    talentButtons = {}
    
    talentButtons[1] = CreateTalentButton("-1", RemoveOnePoint, 1)
    talentButtons[2] = CreateTalentButton("+1", AddOnePoint, 2)
    talentButtons[3] = CreateTalentButton("Max", AddMaxPoints, 3)
    
    local originalSpendButton = GetSpendPointsButton()
    if originalSpendButton then
        originalSpendButton:Hide()
    end
    
    UpdateButtonStates()
    
    if stateUpdateTicker then
        stateUpdateTicker:Cancel()
    end
    
    stateUpdateTicker = C_Timer.NewTicker(0.2, function()
        if ProfessionsFrame and ProfessionsFrame.SpecPage and ProfessionsFrame.SpecPage:IsVisible() then
            UpdateButtonStates()
            
            local spendBtn = GetSpendPointsButton()
            if spendBtn and spendBtn:IsVisible() then
                spendBtn:Hide()
            end
        else
            stateUpdateTicker:Cancel()
            stateUpdateTicker = nil
        end
    end)
    
    return true
end

local function CheckAndCreateButtons()
    if ProfessionsFrame and 
       ProfessionsFrame.SpecPage and 
       ProfessionsFrame.SpecPage:IsVisible() then
        
        if CreateTalentButtons() then
            UpdateButtonStates()
            return true
        end
    end
    return false
end

local function StartButtonCreation()
    if checkTicker then
        checkTicker:Cancel()
        checkTicker = nil
    end
    
    if CheckAndCreateButtons() then
        return
    end
    
    local attempts = 0
    local maxAttempts = 20
    
    checkTicker = C_Timer.NewTicker(0.5, function()
        attempts = attempts + 1
        
        if CheckAndCreateButtons() then
            checkTicker:Cancel()
            checkTicker = nil
        elseif attempts >= maxAttempts then
            checkTicker:Cancel()
            checkTicker = nil
        end
    end)
end

local function OnSpecPageShow()
    C_Timer.After(0.1, StartButtonCreation)
end

local function OnSpecPageHide()
    if checkTicker then
        checkTicker:Cancel()
        checkTicker = nil
    end
    
    if stateUpdateTicker then
        stateUpdateTicker:Cancel()
        stateUpdateTicker = nil
    end
    
    local originalSpendButton = GetSpendPointsButton()
    if originalSpendButton then
        originalSpendButton:Show()
    end
    
    if talentButtons then
        for i, button in ipairs(talentButtons) do
            if button then
                button:Hide()
                button:SetParent(nil)
                button:ClearAllPoints()
            end
        end
        talentButtons = {}
    end
end

local function SetupSpecPageHooks()
    if ProfessionsFrame and ProfessionsFrame.SpecPage then
        if not ProfessionsFrame.SpecPage.JacuvHooksAdded then
            ProfessionsFrame.SpecPage:HookScript("OnShow", OnSpecPageShow)
            ProfessionsFrame.SpecPage:HookScript("OnHide", OnSpecPageHide)
            ProfessionsFrame.SpecPage.JacuvHooksAdded = true
        end
        
        if ProfessionsFrame.SpecPage:IsVisible() then
            OnSpecPageShow()
        end
        
        return true
    end
    return false
end

function TalentManager:Initialize()
    if ProfessionsFrame then
        SetupSpecPageHooks()
        return
    end
    
    local waitAttempts = 0
    local maxWaitAttempts = 30
    
    if waitTicker then
        waitTicker:Cancel()
    end

    waitTicker = C_Timer.NewTicker(1, function()
        waitAttempts = waitAttempts + 1
        
        if ProfessionsFrame then
            SetupSpecPageHooks()
            waitTicker:Cancel()
            waitTicker = nil
        elseif waitAttempts >= maxWaitAttempts then
            waitTicker:Cancel()
            waitTicker = nil
        end
    end)
end

function TalentManager:Cleanup()
    if checkTicker then
        checkTicker:Cancel()
        checkTicker = nil
    end
    
    if stateUpdateTicker then
        stateUpdateTicker:Cancel()
        stateUpdateTicker = nil
    end

    if waitTicker then
        waitTicker:Cancel()
        waitTicker = nil
    end
    
    local originalSpendButton = GetSpendPointsButton()
    if originalSpendButton then
        originalSpendButton:Show()
    end
    
    if talentButtons then
        for i, button in ipairs(talentButtons) do
            if button then
                button:Hide()
                button:SetParent(nil)
                button:ClearAllPoints()
            end
        end
        talentButtons = {}
    end
end

function TalentManager:GetStatus()
    local undoButton = GetUndoButton()
    local spendButton = GetSpendPointsButton()
    return {
        undoAvailable = undoButton and undoButton:IsEnabled() and "SÍ" or "NO",
        spendAvailable = spendButton and spendButton:IsEnabled() and "SÍ" or "NO"
    }
end

function TalentManager:ResetState()
    originalSpentPoints = 0
end