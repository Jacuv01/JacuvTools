local addonName, addon = ...

local XPBarMover = {}
addon.XPBarMover = XPBarMover

-- Offset Y desde el borde superior de la pantalla (valor negativo = baja desde arriba)
local BASE_Y     = 0
local BAR_HEIGHT = 12

local savedPoints  = {}
local isActive     = false
local isUpdating   = false
local eventFrame   = nil

local function GetMainManager() return MainStatusTrackingBarManager end
local function GetMain()        return MainStatusTrackingBarContainer end
local function GetSecondary() return SecondaryStatusTrackingBarContainer end

local function IsFrameShown(frame)
    return frame and frame.IsShown and frame:IsShown()
end

local function GetPrimaryFrame()
    -- Priorizar la barra principal visible; en nivel maximo usar BuffFrame como respaldo.
    local main = GetMain()
    if IsFrameShown(main) then
        return main
    end

    if BuffFrame then
        return BuffFrame
    end

    return main
end

local function IsManagerReputationProxy()
    local manager = GetMainManager()
    if not IsFrameShown(manager) then
        return false
    end

    -- En nivel maximo suele desaparecer/ocultarse MainStatusTrackingBarContainer
    -- y el manager queda mostrando la reputacion.
    return not IsFrameShown(GetMain())
end

-- Guarda los puntos de anclaje originales de un frame
local function SavePoints(frame, key)
    if not frame or savedPoints[key] then return end
    savedPoints[key] = {}
    for i = 1, frame:GetNumPoints() do
        savedPoints[key][i] = { frame:GetPoint(i) }
    end
end

-- Restaura los puntos de anclaje originales de un frame
local function RestorePoints(frame, key)
    if not frame or not savedPoints[key] then return end
    frame:ClearAllPoints()
    for _, p in ipairs(savedPoints[key]) do
        frame:SetPoint(unpack(p))
    end
    savedPoints[key] = nil
end

--[[
    SecondaryStatusTrackingBarContainer siempre existe pero no se oculta;
    se usa la API de reputación para saber si tiene contenido real.

    Diseño (de arriba hacia abajo, centrado en pantalla):
        Facción activa:
            BASE_Y               →  SecondaryStatusTrackingBarContainer (reputación)
            BASE_Y - BAR_HEIGHT  →  MainStatusTrackingBarContainer       (XP)
        Sin facción:
            BASE_Y               →  MainStatusTrackingBarContainer (sube)
]]
local function IsReputationActive()
    -- API moderna (Dragonflight / The War Within)
    if C_Reputation and C_Reputation.GetWatchedFactionData then
        return C_Reputation.GetWatchedFactionData() ~= nil
    end
    -- API heredada
    if GetWatchedFactionInfo then
        local name = GetWatchedFactionInfo()
        return name ~= nil
    end
    -- Fallback: comprobar hijos visibles del contenedor
    local secondary = GetSecondary()
    if secondary then
        for i = 1, secondary:GetNumChildren() do
            local child = select(i, secondary:GetChildren())
            if child and child:IsShown() then return true end
        end
    end
    return false
end

local function UpdatePositions()
    if isUpdating then return end
    local primary = GetPrimaryFrame()
    if not primary then return end

    isUpdating = true

    local secondary = GetSecondary()
    local manager   = GetMainManager()
    local main      = GetMain()
    local buff      = BuffFrame
    local repActive = IsReputationActive()
    local repFrame  = nil

    if repActive then
        if IsFrameShown(secondary) then
            repFrame = secondary
        elseif IsManagerReputationProxy() then
            repFrame = manager
        end
    end

    local mainY = nil

    if repFrame then
        -- Barra de reputacion/proxy arriba.
        repFrame:ClearAllPoints()
        repFrame:SetPoint("TOP", UIParent, "TOP", 0, BASE_Y)

        if IsFrameShown(main) and main ~= repFrame then
            -- Main queda debajo de reputacion.
            mainY = BASE_Y - BAR_HEIGHT - 5
            main:ClearAllPoints()
            main:SetPoint("TOP", UIParent, "TOP", 0, mainY)
        else
            -- Si no hay main visible, usar primary como respaldo.
            primary:ClearAllPoints()
            primary:SetPoint("TOP", UIParent, "TOP", 0, BASE_Y - BAR_HEIGHT - 5)
        end
    else
        if IsFrameShown(main) then
            -- Sin reputacion: main arriba.
            mainY = BASE_Y
            main:ClearAllPoints()
            main:SetPoint("TOP", UIParent, "TOP", 0, mainY)
        else
            -- Respaldo para nivel maximo sin main visible.
            primary:ClearAllPoints()
            primary:SetPoint("TOP", UIParent, "TOP", 0, BASE_Y)
        end
    end

    -- Regla solicitada: BuffFrame siempre va debajo de MainStatusTrackingBarContainer.
    if IsFrameShown(buff) and IsFrameShown(main) then
        local buffY = (mainY or BASE_Y) - BAR_HEIGHT - 5
        buff:ClearAllPoints()
        buff:SetPoint("TOP", UIParent, "TOP", 6.5, buffY)
    end

    isUpdating = false
end

-- Difiere UpdatePositions un ciclo de render para ejecutar
-- después del layout propio de Blizzard (sin timers)
local function DeferredUpdate()
    if not eventFrame then return end
    eventFrame:SetScript("OnUpdate", function(self)
        self:SetScript("OnUpdate", nil)
        if isActive then UpdatePositions() end
    end)
end

-- Hookea funciones Lua globales que Blizzard usa para posicionar estas barras.
-- Así re-aplicamos nuestra posición cada vez que Blizzard reposiciona los frames.
local function HookBlizzardFunctions()
    local globalHooks = {
        "MainMenuBar_UpdateArtFrameElements",
        "UIParent_ManageFramePositions",
        "StatusTrackingBarManager_UpdateBarsShown",
        "MainMenuBarArtFrame_Update",
        "UpdateMicroButtons",
    }
    for _, name in ipairs(globalHooks) do
        if type(_G[name]) == "function" then
            hooksecurefunc(name, function()
                if isActive and not isUpdating then UpdatePositions() end
            end)
        end
    end

    -- Intentar hookear métodos Lua del manager (no C-level)
    local manager = GetMainManager()
    if manager then
        for _, methodName in ipairs({ "UpdateBarsShown", "Layout", "UpdateLayout", "SetBarLayout" }) do
            if type(manager[methodName]) == "function" then
                pcall(hooksecurefunc, manager, methodName, function()
                    if isActive and not isUpdating then UpdatePositions() end
                end)
            end
        end
    end
end

local function SetupEvents()
    if not eventFrame then
        eventFrame = CreateFrame("Frame")
    end
    -- UPDATE_FACTION    : el jugador cambia la facción observada
    -- PLAYER_XP_UPDATE  : cambio de XP (barra puede aparecer/desaparecer al nivel máx)
    -- PLAYER_LEVEL_UP   : subida de nivel
    -- ZONE_CHANGED_NEW_AREA: cambio de zona (barras de honor/PvP)
    -- PLAYER_ENTERING_WORLD: recarga o entrada al mundo
    eventFrame:RegisterEvent("UPDATE_FACTION")
    eventFrame:RegisterEvent("PLAYER_XP_UPDATE")
    eventFrame:RegisterEvent("PLAYER_LEVEL_UP")
    eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

    eventFrame:SetScript("OnEvent", function(self, event)
        if not isActive then return end
        if event == "PLAYER_ENTERING_WORLD" then
            DeferredUpdate()
        else
            UpdatePositions()
        end
    end)
end

local function Setup()
    local primary = GetPrimaryFrame()
    if not primary then return end

    SavePoints(GetMainManager(), "mainManager")
    SavePoints(GetMain(), "main")
    SavePoints(BuffFrame, "buffFrame")
    SavePoints(GetSecondary(), "secondary")
    HookBlizzardFunctions()
    SetupEvents()
    UpdatePositions()
end

function XPBarMover:Initialize()
    isActive = true

    if not GetPrimaryFrame() then
        if not eventFrame then
            eventFrame = CreateFrame("Frame")
            eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
            eventFrame:SetScript("OnEvent", function(self)
                self:UnregisterEvent("PLAYER_ENTERING_WORLD")
                Setup()
            end)
        end
        return
    end

    Setup()
end

function XPBarMover:Cleanup()
    isActive = false

    if eventFrame then
        eventFrame:UnregisterAllEvents()
        eventFrame:SetScript("OnUpdate", nil)
        eventFrame:SetScript("OnEvent", nil)
        eventFrame = nil
    end

    RestorePoints(GetMainManager(), "mainManager")
    RestorePoints(GetMain(), "main")
    RestorePoints(BuffFrame, "buffFrame")
    RestorePoints(GetSecondary(), "secondary")
end

