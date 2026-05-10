-- Handles players inside the tardis interior

if SERVER then
    hook.Add("PlayerSpawn", "tardis-handleplayers", function(ply)
        local int=ply:GetTardisData("interior")
        if IsValid(int) and int.TardisInterior and ply == int:GetCreator() then
            local fallback=int.metadata.Interior.Fallback
            if fallback then
                ply:SetPos(int:LocalToWorld(fallback.pos))
                ply:SetEyeAngles(int:LocalToWorldAngles(fallback.ang))
            end
        end
    end)
else
    ENT:AddHook("ShouldDraw", "players", function(self)
        if ((not (LocalPlayer():GetTardisData("interior")==self)) or (LocalPlayer():GetTardisData("outside") and (self.props[self.exterior]==nil))) and not wp.drawing and not self.contains[LocalPlayer().door] then
            return false
        end
    end)
    ENT:AddHook("ShouldThink", "players", function(self)
        if not (LocalPlayer():GetTardisData("interior")==self) then
            return false
        end
    end)
    ENT:AddHook("ShouldDrawPlayer", "players", function(self, ply, localply)
        if localply:GetTardisData("outside") then
            return false
        end
    end)

    -- Predict tardis data clear on exit (mirror of the entry-side hook on
    -- gmod_tardis). Gated on the main interior portal so customportals
    -- and false-world windows don't drop the player out of the TARDIS.
    -- Server's TARDIS-PlayerDataClear broadcast still arrives shortly
    -- after and re-clears.
    ENT:AddHook("PostTeleportPortal", "predict-tardisdata", function(self, portal, ent)
        if ent ~= LocalPlayer() then return end
        if not (self.portals and portal == self.portals.interior) then return end
        ent:ClearTardisData()
        if TARDIS_PredictDebug then
            TARDIS_PredictDebug:Log("predict-tardisdata int clear",
                string.format("portal=%s", tostring(portal)))
        end
    end)
end
