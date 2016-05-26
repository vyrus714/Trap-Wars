LinkLuaModifier("modifier_hide_healthbar_when_damaged", "modifier_scripts/modifier_hide_healthbar_when_damaged.lua", LUA_MODIFIER_MOTION_NONE)
modifier_hide_healthbar_when_damaged = class({})

function modifier_hide_healthbar_when_damaged:CheckState()
    if not IsServer() then return end

    local state = { [MODIFIER_STATE_NO_HEALTH_BAR] = true }

    if 0 < self:GetParent():GetHealthDeficit() then
        state = { [MODIFIER_STATE_NO_HEALTH_BAR] = false }
    end

    return state
end

function modifier_hide_healthbar_when_damaged:IsHidden()
    return true
end