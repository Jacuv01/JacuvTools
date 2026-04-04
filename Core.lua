local addonName, addon = ...

addon.defaults = {
    enabled = true,
    swapButtonsInstantly = true,
    debugMode = true
}

addon.db = {}
addon.hooks = {}

local frame = CreateFrame("Frame", "JacuvsProfessionPanelFrame")

local function OnAddonLoaded(self, event, loadedAddonName)
    if loadedAddonName ~= addonName then return end

    if not JacuvsProfessionPanelDB then
        JacuvsProfessionPanelDB = CopyTable(addon.defaults)
    end

    JacuvsProfessionPanelDB.enabled = true
    JacuvsProfessionPanelDB.debugMode = true
    addon.db = JacuvsProfessionPanelDB

    addon:InitializeProfessionHooks()
end

frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", OnAddonLoaded)

_G[addonName] = addon

addon.defaults = {
    enabled = true,
    swapButtonsInstantly = true,
    debugMode = true
}

addon.db = {}
addon.hooks = {}

local frame = CreateFrame("Frame", "JacuvsProfessionPanelFrame")

local function OnAddonLoaded(self, event, loadedAddonName)
    if loadedAddonName ~= addonName then return end

    if not JacuvsProfessionPanelDB then
        JacuvsProfessionPanelDB = CopyTable(addon.defaults)
    end

    JacuvsProfessionPanelDB.enabled = true
    JacuvsProfessionPanelDB.debugMode = true
    addon.db = JacuvsProfessionPanelDB

    addon:InitializeProfessionHooks()
end

frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", OnAddonLoaded)

_G[addonName] = addon
