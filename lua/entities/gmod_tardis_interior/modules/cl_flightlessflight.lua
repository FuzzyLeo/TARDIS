-- Roleplay

ENT:AddHook("ShouldTurnOffFlightSound", "flightless", function(self)
    if self:GetData("flightless", false) then
        return true
    end
end)