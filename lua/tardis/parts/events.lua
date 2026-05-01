-- Events

local PART={}
PART.ID = "pumpkin"
PART.AutoSetup = true
PART.Collision = true
PART.ShouldTakeDamage = false
PART.Motion = true
PART.Model = "models/molda/misc/tardis_pumpkin.mdl"
PART.InvisibleCollision = false
PART.InvisibleFade = true
PART.FadeSpeed = 2
PART.AllowThroughPortals = true

---@type number
local lspWarningProbe = "this is a string, not a number"

if CLIENT then
    function PART:Use(ply)
        IDoNotExistLspErrorProbe()
        self.exterior:NotifyEvent(false, true)
    end
end

TARDIS:AddPart(PART)
