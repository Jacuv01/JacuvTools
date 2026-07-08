local addonName, addon = ...

local ButtonMover = {}
addon.ButtonMover = ButtonMover

local persistentTicker = nil
local setupTicker = nil
local waitTicker = nil

local function MoveCreateButton()
    if not ProfessionsFrame or 
       not ProfessionsFrame.OrdersPage or 
       not ProfessionsFrame.OrdersPage.OrderView then
        return false
    end
    
    local createButton = ProfessionsFrame.OrdersPage.OrderView.CreateButton
    local releaseButton = ProfessionsFrame.OrdersPage.OrderView.OrderInfo.ReleaseOrderButton
    
    if not createButton or not releaseButton or 
       not createButton:IsVisible() or not releaseButton:IsVisible() then
        return false
    end
    
    local releasePoint, releaseRelativeTo, releaseRelativePoint, releaseX, releaseY = releaseButton:GetPoint(1)
    
    if releasePoint then
        createButton:SetFrameStrata("TOOLTIP")
        createButton:SetFrameLevel(1000)
        
        createButton:ClearAllPoints()
        createButton:SetPoint("BOTTOM", releaseButton, "TOP", 0, 10)
        
        local regions = {createButton:GetRegions()}
        for i, region in ipairs(regions) do
            if region:GetObjectType() == "Texture" then
                local textureName = region:GetName() or ""
                local isStateTexture = textureName:find("Highlight") or 
                                      textureName:find("Pushed") or 
                                      textureName:find("Disabled") or
                                      region == createButton:GetHighlightTexture() or
                                      region == createButton:GetPushedTexture() or
                                      region == createButton:GetDisabledTexture()
                
                if not isStateTexture then
                    local numPoints = region:GetNumPoints()
                    local originalPoints = {}
                    
                    for p = 1, numPoints do
                        local point, relativeTo, relativePoint, x, y = region:GetPoint(p)
                        if relativeTo == createButton then
                            originalPoints[p] = {point, relativeTo, relativePoint, x, y}
                        end
                    end
                    
                    if #originalPoints > 0 then
                        region:ClearAllPoints()
                        for p, pointData in ipairs(originalPoints) do
                            region:SetPoint(pointData[1], pointData[2], pointData[3], pointData[4], pointData[5])
                        end
                    end
                    
                    if region.SetDrawLayer then
                        region:SetDrawLayer("OVERLAY", 7)
                    end
                end
            elseif region:GetObjectType() == "FontString" then
                region:SetDrawLayer("OVERLAY", 7)
            end
        end
        
        local children = {createButton:GetChildren()}
        for i, child in ipairs(children) do
            if child:GetObjectType() == "Frame" or child:GetObjectType() == "Button" then
                child:SetFrameStrata("TOOLTIP")
                child:SetFrameLevel(1001)
                
                local point, relativeTo, relativePoint, x, y = child:GetPoint(1)
                if relativeTo == createButton then
                else
                    child:ClearAllPoints()
                    child:SetAllPoints(createButton)
                end
            end
        end
        
        return true
    end
    
    return false
end

local function StartPersistentPositioning()
    if persistentTicker then
        persistentTicker:Cancel()
    end
    
    local consecutiveSuccesses = 0
    local maxConsecutive = 3
    
    persistentTicker = C_Timer.NewTicker(1, function()
        if MoveCreateButton() then
            consecutiveSuccesses = consecutiveSuccesses + 1
            if consecutiveSuccesses >= maxConsecutive then
                persistentTicker:Cancel()
                
                persistentTicker = C_Timer.NewTicker(5, function()
                    if not MoveCreateButton() then
                        persistentTicker:Cancel()
                        StartPersistentPositioning()
                    end
                end)
            end
        else
            consecutiveSuccesses = 0
        end
    end)
end

local function CheckAndStartPositioning()
    if ProfessionsFrame and 
       ProfessionsFrame.OrdersPage and 
       ProfessionsFrame.OrdersPage.OrderView and
       ProfessionsFrame.OrdersPage.OrderView:IsVisible() and
       ProfessionsFrame.OrdersPage.OrderView.CreateButton and
       ProfessionsFrame.OrdersPage.OrderView.OrderInfo and
       ProfessionsFrame.OrdersPage.OrderView.OrderInfo.ReleaseOrderButton then
        
        StartPersistentPositioning()
        return true
    end
    return false
end

local function OnProfessionsFrameShow()
    if setupTicker then
        setupTicker:Cancel()
    end
    
    local attempts = 0
    local maxAttempts = 20
    
    setupTicker = C_Timer.NewTicker(0.5, function()
        attempts = attempts + 1
        
        if CheckAndStartPositioning() then
            setupTicker:Cancel()
            setupTicker = nil
        elseif attempts >= maxAttempts then
            setupTicker:Cancel()
            setupTicker = nil
        end
    end)
end

local function OnProfessionsFrameHide()
    if persistentTicker then
        persistentTicker:Cancel()
        persistentTicker = nil
    end
    
    if setupTicker then
        setupTicker:Cancel()
        setupTicker = nil
    end
end

local function SetupProfessionsFrameHooks()
    if ProfessionsFrame then
        ProfessionsFrame:HookScript("OnShow", OnProfessionsFrameShow)
        ProfessionsFrame:HookScript("OnHide", OnProfessionsFrameHide)
        
        if ProfessionsFrame:IsVisible() then
            OnProfessionsFrameShow()
        end
        
        return true
    end
    return false
end

function ButtonMover:Initialize()
    if not SetupProfessionsFrameHooks() then
        local attempts = 0
        local maxAttempts = 30
        
        if waitTicker then
            waitTicker:Cancel()
        end

        waitTicker = C_Timer.NewTicker(1, function()
            attempts = attempts + 1
            
            if SetupProfessionsFrameHooks() then
                waitTicker:Cancel()
                waitTicker = nil
            elseif attempts >= maxAttempts then
                waitTicker:Cancel()
                waitTicker = nil
            end
        end)
    end
end

function ButtonMover:Cleanup()
    if persistentTicker then
        persistentTicker:Cancel()
        persistentTicker = nil
    end
    if setupTicker then
        setupTicker:Cancel()
        setupTicker = nil
    end
    if waitTicker then
        waitTicker:Cancel()
        waitTicker = nil
    end
end

function ButtonMover:StopAllTimers()
    self:Cleanup()
end