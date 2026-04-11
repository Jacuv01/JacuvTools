local addonName, addon = ...

function addon:InitializeProfessionHooks()
    if addon.ButtonMover then
        addon.ButtonMover:Initialize()
    end
    
    if addon.TalentManager then
        addon.TalentManager:Initialize()
    end
end

function addon:RemoveHooks()
    if addon.ButtonMover then
        addon.ButtonMover:StopAllTimers()
    end
    
    if addon.TalentManager then
        addon.TalentManager:Cleanup()
    end
end
