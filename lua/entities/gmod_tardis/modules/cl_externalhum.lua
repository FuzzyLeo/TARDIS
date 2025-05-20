-- This module handles two separate audio features:
-- 1. ExternalHum: The humming sound from the exterior shell when powered (using external_hum setting)
-- 2. LeakedInteriorHums: Interior hum sounds leaking through when doors are open (using interior_hum_leakage setting)

local function CalculateInteriorToExteriorRatio(self)
    -- Use the interior door portal position if available
    local portal = self.metadata.Interior and self.metadata.Interior.Portal
    if not portal or not portal.pos then
        return 1.0
    end

    -- distance from interior origin to door portal
    local dist = portal.pos:Length()
    if dist < 1 then
        -- engine treats anything <1 as 1 to avoid infinities
        return 1.0
    end

    local attenuation = 0.8 -- default for sound level 75
    local maxDistance = attenuation * 1000

    local gain = math.Clamp(1 - (dist / maxDistance), 0, 1)
    return gain
end

ENT:AddHook("Initialize", "externalhum", function(self)
    self.LeakedInteriorHums    = {}
    self.InteriorToExteriorRatio = 1.0
end)

ENT:AddHook("PostInitialize", "externalhum", function(self)
    if self.interior and IsValid(self.interior) then
        self.InteriorToExteriorRatio = CalculateInteriorToExteriorRatio(self)
    end
end)

ENT:AddHook("OnRemove", "externalhum", function(self)
    if self.ExternalHum then
        self.ExternalHum:Stop()
        self.ExternalHum = nil
    end
    if self.LeakedInteriorHums then
        for k, v in pairs(self.LeakedInteriorHums) do
            v:Stop()
            self.LeakedInteriorHums[k] = nil
        end
    end
end)

ENT:AddHook("ExteriorChanged", "externalhum", function(self)
    if self.ExternalHum then
        self.ExternalHum:Stop()
        self.ExternalHum = nil
    end
    if self.LeakedInteriorHums then
        for k, v in pairs(self.LeakedInteriorHums) do
            v:Stop()
            self.LeakedInteriorHums[k] = nil
        end
    end
end)

-- Function to update the interior hum leakage based on door state
-- This is separate from the ExternalHum feature and controlled by the interior_hum_leakage setting
local function UpdateInteriorHumLeakage(self)
    if not IsValid(self.interior) then
        for k, v in pairs(self.LeakedInteriorHums) do v:Stop() end
        self.LeakedInteriorHums = {}
        return
    end

    local sounds = {}
    if     self.metadata.Interior.Sounds
       and self.metadata.Interior.Sounds.Idle
    then
        sounds = self.metadata.Interior.Sounds.Idle
    elseif self.metadata.Interior.IdleSound then
        sounds = self.metadata.Interior.IdleSound
    end

    local vol_setting = TARDIS:GetSetting("interior_hum_leakage_volume") / 100
    local ratio = self.InteriorToExteriorRatio or 1.0

    -- Use the exterior portal entity as the sound emitter if available
    local ext_portal = self.portals and self.portals.exterior
    local emitter = (IsValid(ext_portal) and ext_portal) or self

    if #sounds > 0
       and TARDIS:GetSetting("interior_hum_leakage")
       and TARDIS:GetSetting("sound")
       and self:GetData("power-state")
       and not self:GetData("vortex")
       and self:DoorOpen(true)
    then
        for k, snd in pairs(sounds) do
            if not snd.path then continue end
            local final_vol = (snd.volume or 1) * vol_setting * ratio

            if not self.LeakedInteriorHums[k] then
                local chan = CreateSound(emitter, snd.path)
                chan:Play()
                chan:ChangeVolume(final_vol, 0)
                self.LeakedInteriorHums[k] = chan
            else
                self.LeakedInteriorHums[k]:ChangeVolume(final_vol, 0)
            end
        end
        
        for k, v in pairs(self.LeakedInteriorHums) do
            if not sounds[k] then
                v:Stop()
                self.LeakedInteriorHums[k] = nil
            end
        end
    else
        for k, v in pairs(self.LeakedInteriorHums) do v:Stop() end
        self.LeakedInteriorHums = {}
    end
end

-- This Think hook handles two separate audio features:
-- 1. ExternalHum: The humming sound from the exterior shell when powered (using external_hum setting)
-- 2. LeakedInteriorHums: Interior hum sounds leaking through when doors are open (using interior_hum_leakage setting)
ENT:AddHook("Think", "externalhum", function(self)
    -- Part 1: Handle exterior hum sound
    local hum_sound = self.metadata.Exterior.Sounds.Hum
    if hum_sound then
        if TARDIS:GetSetting("external_hum")
            and TARDIS:GetSetting("sound")
            and self:GetData("power-state")
            and not self:GetData("vortex")
        then
            if not self.ExternalHum then
                self.ExternalHum = CreateSound(self, hum_sound.path)
                self.ExternalHum:Play()
                self.ExternalHum:ChangeVolume(hum_sound.volume or 1,0)
            end
        elseif self.ExternalHum then
            self.ExternalHum:Stop()
            self.ExternalHum=nil
        end
    end
    
    -- Part 2: Regularly update the interior hum leakage status for when doors open/close
    UpdateInteriorHumLeakage(self)
end)