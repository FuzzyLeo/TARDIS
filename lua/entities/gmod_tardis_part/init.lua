AddCSLuaFile('cl_init.lua')
AddCSLuaFile('shared.lua')
include('shared.lua')

---@param dmginfo CTakeDamageInfo
function ENT:OnTakeDamage(dmginfo)
    if not self.ShouldTakeDamage then return end
    if self.parent:CallHook("ShouldTakeDamage",dmginfo)==false then return end
    self.parent:CallHook("OnTakeDamage", dmginfo)
end

---@param collide boolean
---@param notrace boolean?
function ENT:SetCollide(collide, notrace)
    if collide then
        self:SetCollisionGroup(COLLISION_GROUP_NONE)
    elseif notrace then
        self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
    else
        self:SetCollisionGroup(COLLISION_GROUP_WORLD)
    end
end

-- Deprecated: Use ENT:SetInvisible() instead
---@param visible boolean
function ENT:SetVisible(visible)
    return not self:SetInvisible(not visible)
end
