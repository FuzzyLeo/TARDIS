-- Time distortion generator by parar020100 and JEREDEK

---@class gmod_time_distortion_generator : Entity
---@field Radius number
---@field EntHealth number
---@field EntMaxHealth number
---@field Broken boolean?
---@field FlyTime number?
---@field On boolean?
---@field LastActivator Player?
ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "#TARDIS.TimeDistortionGenerator"
ENT.Spawnable = true

ENT.Instructions= "#TARDIS.TimeDistortionGenerator.Instructions"
ENT.AdminOnly = false
ENT.Category = "#TARDIS.Spawnmenu.CategoryTools"
ENT.IconOverride = "materials/entities/time_distortion_generator.png"


function ENT:SetupDataTables()
    self:NetworkVar( "Bool", 1, "Enabled" )
end