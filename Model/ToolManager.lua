local addonName, addon = ...

local ToolManager = {}
addon.ToolManager = ToolManager

ToolManager.registeredTools = {}
ToolManager.activatedTools = {}

function ToolManager:RegisterTool(toolName, toolObject)
    if not toolName or not toolObject then
        return false
    end
    
    self.registeredTools[toolName] = toolObject
    return true
end

function ToolManager:GetTool(toolName)
    return self.registeredTools[toolName]
end

function ToolManager:IsToolActivated(toolName)
    return self.activatedTools[toolName] == true
end

function ToolManager:ActivateTool(toolName)
    local tool = self.registeredTools[toolName]
    if not tool then
        return false
    end
    
    if self:IsToolActivated(toolName) then
        return true
    end
    
    if tool.Initialize and type(tool.Initialize) == "function" then
        tool:Initialize()
    end
    
    self.activatedTools[toolName] = true
    return true
end

function ToolManager:DeactivateTool(toolName)
    local tool = self.registeredTools[toolName]
    if not tool then
        return false
    end
    
    if not self:IsToolActivated(toolName) then
        return true
    end
    
    if tool.Cleanup and type(tool.Cleanup) == "function" then
        tool:Cleanup()
    end
    
    self.activatedTools[toolName] = false
    return true
end

function ToolManager:ToggleTool(toolName)
    if not addon.Config then
        return false
    end
    
    local newState = addon.Config:ToggleTool(toolName)
    
    if newState then
        self:ActivateTool(toolName)
    else
        self:DeactivateTool(toolName)
    end
    
    return newState
end

function ToolManager:InitializeEnabledTools()
    if not addon.Config then
        return
    end
    
    for toolName, toolObject in pairs(self.registeredTools) do
        if addon.Config:IsToolEnabled(toolName) then
            self:ActivateTool(toolName)
        end
    end
end

function ToolManager:GetRegisteredToolsInfo()
    local toolsInfo = {}
    
    for toolName, toolObject in pairs(self.registeredTools) do
        toolsInfo[toolName] = {
            name = addon.Config:GetToolSetting(toolName, "name") or toolName,
            description = addon.Config:GetToolSetting(toolName, "description") or "",
            enabled = addon.Config:IsToolEnabled(toolName),
            activated = self:IsToolActivated(toolName)
        }
    end
    
    return toolsInfo
end