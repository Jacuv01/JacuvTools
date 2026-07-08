local addonName, addon = ...

local MainWindow = {}
addon.MainWindow = MainWindow

local frame = nil
local contentFrame = nil
local toolCheckboxes = {}
local collapsibleSections = {}

function MainWindow:Initialize()
    if frame then
        return
    end
    
    frame = CreateFrame("Frame", "JacuvToolsMainWindow", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(450, 400)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()
    
    frame.title = frame:CreateFontString(nil, "OVERLAY")
    frame.title:SetFontObject("GameFontHighlightLarge")
    frame.title:SetPoint("LEFT", frame.TitleBg, "LEFT", 5, 0)
    frame.title:SetText("JacuvTools")
    
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function()
        frame:Hide()
    end)
    
    contentFrame = CreateFrame("Frame", nil, frame)
    contentFrame:SetPoint("TOPLEFT", frame.InsetBorderTop, "BOTTOMLEFT", 10, -10)
    contentFrame:SetPoint("BOTTOMRIGHT", frame.InsetBorderBottom, "TOPRIGHT", -10, 10)
    
    self:CreateContent()
end

function MainWindow:CreateCollapsibleSection(parent, title, yOffset, isExpanded)
    local sectionFrame = CreateFrame("Frame", nil, parent)
    sectionFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, yOffset)
    sectionFrame:SetSize(parent:GetWidth() - 20, 30)
    
    -- Botón de expandir/colapsar
    local expandButton = CreateFrame("Button", nil, sectionFrame)
    expandButton:SetSize(16, 16)
    expandButton:SetPoint("TOPLEFT", sectionFrame, "TOPLEFT", 0, 0)
    
    -- Fondo del botón
    local buttonBg = expandButton:CreateTexture(nil, "BACKGROUND")
    buttonBg:SetAllPoints()
    buttonBg:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    
    -- Texto del botón (+ o -)
    local buttonText = expandButton:CreateFontString(nil, "OVERLAY")
    buttonText:SetFontObject("GameFontNormalSmall")
    buttonText:SetPoint("CENTER", expandButton, "CENTER", 0, 0)
    buttonText:SetText(isExpanded and "−" or "+")
    buttonText:SetTextColor(1, 1, 1)
    
    -- Título de la sección
    local sectionTitle = sectionFrame:CreateFontString(nil, "OVERLAY")
    sectionTitle:SetFontObject("GameFontNormalLarge")
    sectionTitle:SetPoint("LEFT", expandButton, "RIGHT", 5, 0)
    sectionTitle:SetText(title)
    
    -- Frame del contenido
    local contentFrame = CreateFrame("Frame", nil, sectionFrame)
    contentFrame:SetPoint("TOPLEFT", sectionFrame, "TOPLEFT", 20, -25)
    contentFrame:SetSize(sectionFrame:GetWidth() - 20, 200)
    
    -- Estado inicial de visibilidad
    contentFrame:SetShown(isExpanded)
    
    -- Función para alternar
    local function ToggleSection()
        local isVisible = contentFrame:IsShown()
        contentFrame:SetShown(not isVisible)
        buttonText:SetText(isVisible and "+" or "−")
        buttonBg:SetColorTexture(isVisible and 0.3 or 0.2, 0.3, isVisible and 0.3 or 0.2, 0.8)
        return not isVisible
    end
    
    -- Eventos de clic
    expandButton:SetScript("OnClick", ToggleSection)
    expandButton:SetScript("OnEnter", function(self)
        buttonBg:SetColorTexture(0.5, 0.5, 0.5, 0.8)
    end)
    expandButton:SetScript("OnLeave", function(self)
        local isVisible = contentFrame:IsShown()
        buttonBg:SetColorTexture(isVisible and 0.2 or 0.3, 0.3, isVisible and 0.2 or 0.3, 0.8)
    end)
    
    -- Hacer el título también clickeable
    local titleButton = CreateFrame("Button", nil, sectionFrame)
    titleButton:SetPoint("TOPLEFT", expandButton, "TOPLEFT", 0, 0)
    titleButton:SetPoint("BOTTOMRIGHT", sectionTitle, "BOTTOMRIGHT", 0, 0)
    titleButton:SetScript("OnClick", function()
        ToggleSection()
    end)
    
    return sectionFrame, contentFrame, ToggleSection
end

function MainWindow:CreateContent()
    if not contentFrame then
        return
    end
    
    -- Limpiar contenido anterior
    for i = 1, contentFrame:GetNumChildren() do
        local child = select(i, contentFrame:GetChildren())
        if child then
            child:Hide()
            child:SetParent(nil)
        end
    end
    
    -- Limpiar referencias anteriores
    collapsibleSections = {}
    toolCheckboxes = {}
    
    local currentY = -10
    
    -- Sección de Herramientas
    local toolsSection, toolsContent, toolsToggle = self:CreateCollapsibleSection(
        contentFrame, 
        "Herramientas Disponibles", 
        currentY, 
        true  -- Expandida por defecto
    )
    collapsibleSections["tools"] = {section = toolsSection, content = toolsContent, toggle = toolsToggle}
    
    -- Contenido de la sección de herramientas
    local toolYOffset = -10
    local tools = addon.ToolManager:GetRegisteredToolsInfo()
    
    for toolName, toolInfo in pairs(tools) do
        local checkbox = CreateFrame("CheckButton", "JacuvTools_" .. toolName .. "_Checkbox", toolsContent, "ChatConfigCheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", toolsContent, "TOPLEFT", 0, toolYOffset)
        checkbox:SetChecked(toolInfo.enabled)
        
        local label = toolsContent:CreateFontString(nil, "OVERLAY")
        label:SetFontObject("GameFontNormal")
        label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
        label:SetText(toolInfo.name)
        
        local description = toolsContent:CreateFontString(nil, "OVERLAY")
        description:SetFontObject("GameFontNormalSmall")
        description:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -5)
        description:SetText(toolInfo.description)
        description:SetTextColor(0.7, 0.7, 0.7)
        
        checkbox:SetScript("OnClick", function(self)
            local newState = addon.ToolManager:ToggleTool(toolName)
            self:SetChecked(newState)
            
            if addon.MainController then
                addon.MainController:OnToolToggled(toolName, newState)
            end
        end)
        
        toolCheckboxes[toolName] = checkbox
        toolYOffset = toolYOffset - 50
    end
    
    -- Ajustar altura del contenido de herramientas
    toolsContent:SetHeight(math.abs(toolYOffset) + 10)
    currentY = currentY - 60 - toolsContent:GetHeight()
    
    -- Sección de Configuración
    local configSection, configContent, configToggle = self:CreateCollapsibleSection(
        contentFrame, 
        "Configuración", 
        currentY, 
        true  -- Expandida por defecto
    )
    collapsibleSections["config"] = {section = configSection, content = configContent, toggle = configToggle}
    
    -- Contenido de la sección de configuración
    local minimapCheckbox = CreateFrame("CheckButton", "JacuvTools_Minimap_Checkbox", configContent, "ChatConfigCheckButtonTemplate")
    minimapCheckbox:SetPoint("TOPLEFT", configContent, "TOPLEFT", 0, -10)
    minimapCheckbox:SetChecked(not addon.MinimapButton:IsHidden())
    
    local minimapLabel = configContent:CreateFontString(nil, "OVERLAY")
    minimapLabel:SetFontObject("GameFontNormal")
    minimapLabel:SetPoint("LEFT", minimapCheckbox, "RIGHT", 5, 0)
    minimapLabel:SetText("Mostrar botón en minimapa")
    
    minimapCheckbox:SetScript("OnClick", function(self)
        addon.MinimapButton:Toggle()
        self:SetChecked(not addon.MinimapButton:IsHidden())
    end)
    
    -- Ajustar altura del contenido de configuración
    configContent:SetHeight(40)
end

function MainWindow:Show()
    if not frame then
        self:Initialize()
    end
    frame:Show()
end

function MainWindow:Hide()
    if frame then
        frame:Hide()
    end
end

function MainWindow:Toggle()
    if not frame then
        self:Show()
        return
    end
    
    if frame:IsVisible() then
        self:Hide()
    else
        self:Show()
    end
end

function MainWindow:IsVisible()
    return frame and frame:IsVisible()
end

function MainWindow:UpdateToolStatus(toolName, enabled)
    if toolCheckboxes[toolName] then
        toolCheckboxes[toolName]:SetChecked(enabled)
    end
end

function MainWindow:ToggleSection(sectionName)
    if collapsibleSections[sectionName] and collapsibleSections[sectionName].toggle then
        return collapsibleSections[sectionName].toggle()
    end
    return false
end

function MainWindow:IsSectionExpanded(sectionName)
    if collapsibleSections[sectionName] and collapsibleSections[sectionName].content then
        return collapsibleSections[sectionName].content:IsShown()
    end
    return false
end

function MainWindow:SetSectionExpanded(sectionName, expanded)
    if collapsibleSections[sectionName] then
        local currentState = self:IsSectionExpanded(sectionName)
        if currentState ~= expanded then
            self:ToggleSection(sectionName)
        end
    end
end

-- Función para colapsar todas las secciones
function MainWindow:CollapseAllSections()
    for sectionName, _ in pairs(collapsibleSections) do
        self:SetSectionExpanded(sectionName, false)
    end
end

-- Función para expandir todas las secciones
function MainWindow:ExpandAllSections()
    for sectionName, _ in pairs(collapsibleSections) do
        self:SetSectionExpanded(sectionName, true)
    end
end