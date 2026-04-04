local addonName, addon = ...

function addon:InitializeProfessionHooks()
    if addon.ButtonMover then
        addon.ButtonMover:Initialize()
    end
end

function addon:RemoveHooks()
    if addon.ButtonMover then
        addon.ButtonMover:StopAllTimers()
    end
end

function addon:InitializeProfessionHooks()
    if addon.ButtonMover then
        addon.ButtonMover:Initialize()
    end
end

function addon:RemoveHooks()
    if addon.ButtonMover then
        addon.ButtonMover:StopAllTimers()
    end
end
