local addonName, addon = ...

local MainController = {}
addon.MainController = MainController

function MainController:Initialize()
    addon.Config:Initialize()
    
    if addon.ToolManager then
        self:RegisterTools()
        addon.ToolManager:InitializeEnabledTools()
    end
    
    C_Timer.After(0.5, function()
        if addon.MinimapButton then
            addon.MinimapButton:Initialize()
            
            if addon.Config:GetMinimapButtonSetting("hide") then
                addon.MinimapButton:Hide()
            end
        end
    end)
    
    if addon.MainWindow then
        addon.MainWindow:Initialize()
    end
end

function MainController:RegisterTools()
    if addon.ButtonMover then
        addon.ToolManager:RegisterTool("buttonMover", addon.ButtonMover)
    end
    
    if addon.TalentManager then
        addon.ToolManager:RegisterTool("talentManager", addon.TalentManager)
    end
end

function MainController:OnToolToggled(toolName, enabled)
    if addon.MainWindow then
        addon.MainWindow:UpdateToolStatus(toolName, enabled)
    end
end

function MainController:ShowMainWindow()
    if addon.MainWindow then
        addon.MainWindow:Show()
    end
end

function MainController:HideMainWindow()
    if addon.MainWindow then
        addon.MainWindow:Hide()
    end
end

function MainController:ToggleMainWindow()
    if addon.MainWindow then
        addon.MainWindow:Toggle()
    end
end

function MainController:EnableTool(toolName)
    if addon.ToolManager then
        return addon.ToolManager:ToggleTool(toolName)
    end
    return false
end

function MainController:DisableTool(toolName)
    if addon.ToolManager and addon.ToolManager:IsToolActivated(toolName) then
        return addon.ToolManager:ToggleTool(toolName)
    end
    return false
end

function MainController:GetToolsStatus()
    if addon.ToolManager then
        return addon.ToolManager:GetRegisteredToolsInfo()
    end
    return {}
end