-- Events

function ENT:IsAprilFoolsEvent()
    return self:GetData("events-aprilfools", false)
end

function ENT:IsHalloweenEvent()
    return self:GetData("events-halloween", false)
end

function ENT:IsChristmasEvent()
    return self:GetData("events-christmas", false)
end

function ENT:GetEvent()
    return self:GetData("event")
end

if SERVER then
    ENT:AddHook("Initialize", "halloween", function(self)
        local event = TARDIS:GetCurrentEvent(self)
        self:SetData("event", event, true)
        if event == TARDIS_EVENTS_APRIL_FOOLS then
            self:SetData("events-aprilfools", true, true)
        elseif event == TARDIS_EVENTS_HALLOWEEN then
            self:SetData("events-halloween", true, true)
        elseif event == TARDIS_EVENTS_CHRISTMAS then
            self:SetData("events-christmas", true, true)
        end
        print("Set event data to", event)
    end)
end
