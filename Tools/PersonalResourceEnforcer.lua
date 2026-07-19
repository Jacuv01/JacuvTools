local addonName, addon = ...

local PersonalResourceEnforcer = {}
addon.PersonalResourceEnforcer = PersonalResourceEnforcer

local EVENT_FRAME = nil
local IS_ACTIVE = false
local HOOKS_REGISTERED = false

local PRIMARY_CVAR = "nameplateShowSelf"
local LEGACY_CVAR = "PersonalResourceDisplay"

local CHECKBOX_GLOBALS = {
    "InterfaceOptionsNamesPanelPersonalResourceDisplay",
    "NamesPanelPersonalResourceDisplay",
    "NamesPanelPersonalResourceDisplayFrame",
}

local function ForceCheckboxUI()
    for _, globalName in ipairs(CHECKBOX_GLOBALS) do
        local checkbox = _G[globalName]
        if checkbox and checkbox.SetChecked then
            checkbox:SetChecked(true)
            -- No se deshabilita el control para evitar conflictos con otras UIs.
        end
    end
end

local function IsTrackedCVar(name)
    if type(name) ~= "string" then
        return false
    end

    local lowered = string.lower(name)
    return lowered == string.lower(PRIMARY_CVAR) or lowered == string.lower(LEGACY_CVAR)
end

local function ForceEnabled()
    if GetCVar and SetCVar then
        if GetCVar(PRIMARY_CVAR) ~= "1" then
            SetCVar(PRIMARY_CVAR, "1")
        end

        -- Compatibilidad con versiones antiguas que usen este cvar.
        if GetCVar(LEGACY_CVAR) ~= nil and GetCVar(LEGACY_CVAR) ~= "1" then
            SetCVar(LEGACY_CVAR, "1")
        end
    end

    ForceCheckboxUI()
end

local function SetupHooks()
    if HOOKS_REGISTERED then
        return
    end

    if type(SetCVar) == "function" then
        hooksecurefunc("SetCVar", function(name, value)
            if not IS_ACTIVE then
                return
            end

            if IsTrackedCVar(name) and tostring(value) ~= "1" then
                ForceEnabled()
            end
        end)
    end

    HOOKS_REGISTERED = true
end

local function SetupEvents()
    if EVENT_FRAME then
        return
    end

    EVENT_FRAME = CreateFrame("Frame")
    EVENT_FRAME:RegisterEvent("PLAYER_ENTERING_WORLD")
    EVENT_FRAME:RegisterEvent("CVAR_UPDATE")

    EVENT_FRAME:SetScript("OnEvent", function(_, event, cvarName)
        if not IS_ACTIVE then
            return
        end

        if event == "CVAR_UPDATE" then
            if IsTrackedCVar(cvarName) then
                ForceEnabled()
            end
            return
        end

        ForceEnabled()
    end)
end

function PersonalResourceEnforcer:Initialize()
    IS_ACTIVE = true
    SetupHooks()
    SetupEvents()
    ForceEnabled()
end

function PersonalResourceEnforcer:Cleanup()
    IS_ACTIVE = false

    if EVENT_FRAME then
        EVENT_FRAME:UnregisterAllEvents()
        EVENT_FRAME:SetScript("OnEvent", nil)
        EVENT_FRAME = nil
    end
end
