local addonName, addon = ...

local frame = CreateFrame("Frame", "JacuvToolsFrame")

local function OnAddonLoaded(self, event, loadedAddonName)
    if loadedAddonName ~= addonName then return end

    if addon.MainController then
        addon.MainController:Initialize()
    end
end

frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", OnAddonLoaded)

_G[addonName] = addon
