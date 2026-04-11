local addonName, addon = ...

addon.defaults = {
    enabled = true,
    swapButtonsInstantly = true
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
    addon.db = JacuvsProfessionPanelDB

    addon:InitializeProfessionHooks()
end

frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", OnAddonLoaded)

_G[addonName] = addon

SLASH_JACUVTEST1 = "/jacuvtest"
function SlashCmdList.JACUVTEST(msg)
    msg = string.lower(msg or "")
    
    if msg == "" then
        if addon.TalentManager then
            addon.TalentManager:Initialize()
        end
    elseif msg == "reset" then
        if addon.TalentManager then
            addon.TalentManager:ResetState()
        end
    end
end
