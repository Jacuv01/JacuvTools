local addonName, addon = ...

local Config = {}
addon.Config = Config

Config.defaults = {
    enabled = true,
    minimapButton = {
        hide = false,
        minimapPos = 220,
        radius = 80
    },
    tools = {
        buttonMover = {
            enabled = true,
            name = "Button Mover",
            description = "Reposiciona automaticamente el boton Create"
        },
        talentManager = {
            enabled = true,
            name = "Talent Manager",
            description = "Botones personalizados para puntos de talento"
        },
        xpBarMover = {
            enabled = true,
            name = "XP Bar Mover",
            description = "Mueve las barras de experiencia y reputacion hacia arriba"
        },
        personalResourceEnforcer = {
            enabled = true,
            name = "Personal Resource Display",
            description = "Mantiene siempre activa la opcion Personal Resource Display"
        }
    }
}

function Config:Initialize()
    if not JacuvToolsDB then
        JacuvToolsDB = self:DeepCopy(self.defaults)
    else
        JacuvToolsDB = self:MergeDefaults(JacuvToolsDB, self.defaults)
    end
    addon.db = JacuvToolsDB
end

function Config:GetToolSetting(toolName, setting)
    if not addon.db or not addon.db.tools or not addon.db.tools[toolName] then
        return nil
    end
    return addon.db.tools[toolName][setting]
end

function Config:SetToolSetting(toolName, setting, value)
    if not addon.db then
        return false
    end
    
    if not addon.db.tools then
        addon.db.tools = {}
    end
    
    if not addon.db.tools[toolName] then
        addon.db.tools[toolName] = {}
    end
    
    addon.db.tools[toolName][setting] = value
    return true
end

function Config:IsToolEnabled(toolName)
    return self:GetToolSetting(toolName, "enabled") == true
end

function Config:ToggleTool(toolName)
    local currentState = self:IsToolEnabled(toolName)
    self:SetToolSetting(toolName, "enabled", not currentState)
    return not currentState
end

function Config:GetMinimapButtonSetting(setting)
    if not addon.db or not addon.db.minimapButton then
        return nil
    end
    return addon.db.minimapButton[setting]
end

function Config:SetMinimapButtonSetting(setting, value)
    if not addon.db then
        return false
    end
    
    if not addon.db.minimapButton then
        addon.db.minimapButton = {}
    end
    
    addon.db.minimapButton[setting] = value
    return true
end

function Config:DeepCopy(original)
    local copy
    if type(original) == "table" then
        copy = {}
        for key, value in next, original, nil do
            copy[self:DeepCopy(key)] = self:DeepCopy(value)
        end
        setmetatable(copy, self:DeepCopy(getmetatable(original)))
    else
        copy = original
    end
    return copy
end

function Config:MergeDefaults(saved, defaults)
    for key, value in pairs(defaults) do
        if saved[key] == nil then
            saved[key] = self:DeepCopy(value)
        elseif type(saved[key]) == "table" and type(value) == "table" then
            saved[key] = self:MergeDefaults(saved[key], value)
        end
    end
    return saved
end