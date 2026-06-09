include('shared.lua')

ENT:AddHook("PlayerInitialize", "interior", function(self)
    local id = net.ReadString()
    if net.ReadBool() then
        self.templates = TARDIS.von.deserialize(net.ReadString())
        if self.interior then
            self.interior.templates = self.templates
        end
    end

    self.metadata=TARDIS:CreateInteriorMetadata(id, self)

    -- Mirror the exterior Fallback client-side so the predicted unstick can read
    -- it: Doors' ResolveFallbackPos uses self.Fallback for the exit direction, and
    -- the client only has it via the metadata rebuilt just above.
    if self.metadata and self.metadata.Exterior then
        self.Fallback = self.metadata.Exterior.Fallback
    end
end)