local addonName, addon = ...

local MinimapButton = {}
addon.MinimapButton = MinimapButton

local button = nil
local LibDBIcon = nil

local function OnClick(self, clickType)
    if clickType == "LeftButton" then
        if addon.MainWindow then
            addon.MainWindow:Toggle()
        end
    elseif clickType == "RightButton" then
        if addon.MainWindow then
            addon.MainWindow:Toggle()
        end
    end
end

local function OnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("JacuvTools")
    GameTooltip:AddLine("Click izquierdo: Abrir ventana principal")
    GameTooltip:AddLine("Click derecho: Abrir ventana principal")
    GameTooltip:Show()
end

local function OnLeave(self)
    GameTooltip:Hide()
end

function MinimapButton:Initialize()
    if button then
        return
    end
    
    if not Minimap then
        C_Timer.After(1, function()
            self:CreateButton()
        end)
    else
        self:CreateButton()
    end
end

function MinimapButton:CreateButton()
    if button or not Minimap then
        return
    end
    
    button = CreateFrame("Button", "JacuvToolsMinimapButton", Minimap)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetScript("OnClick", OnClick)
    button:SetScript("OnEnter", OnEnter)
    button:SetScript("OnLeave", OnLeave)
    
    local texture = button:CreateTexture(nil, "BACKGROUND")
    texture:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    texture:SetSize(53, 53)
    texture:SetPoint("TOPLEFT")
    
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\Icons\\Trade_Engineering")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", 0, 1)
    
    local overlay = button:CreateTexture(nil, "OVERLAY")
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    overlay:SetSize(53, 53)
    overlay:SetPoint("TOPLEFT")
    
    self:UpdatePosition()
    button:Show()
end

function MinimapButton:UpdatePosition()
    if not button then
        return
    end
    
    local angle = 220
    local radius = 80
    
    if addon.Config and addon.Config.GetMinimapButtonSetting then
        angle = addon.Config:GetMinimapButtonSetting("minimapPos") or 220
        radius = addon.Config:GetMinimapButtonSetting("radius") or 80
    end
    
    local radian = math.rad(angle)
    local x = math.cos(radian) * radius
    local y = math.sin(radian) * radius
    
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function MinimapButton:Hide()
    if button then
        button:Hide()
        if addon.Config and addon.Config.SetMinimapButtonSetting then
            addon.Config:SetMinimapButtonSetting("hide", true)
        end
    end
end

function MinimapButton:Show()
    if button then
        button:Show()
        if addon.Config and addon.Config.SetMinimapButtonSetting then
            addon.Config:SetMinimapButtonSetting("hide", false)
        end
    end
end

function MinimapButton:IsHidden()
    if button then
        return not button:IsVisible()
    end
    return true
end

function MinimapButton:Toggle()
    if self:IsHidden() then
        self:Show()
    else
        self:Hide()
    end
end