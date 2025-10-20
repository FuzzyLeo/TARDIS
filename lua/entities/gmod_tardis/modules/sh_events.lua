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

function ENT:NotifyEvent(event)
    if not event then event = self:GetEvent() end
    if not event then return end
    local ply = self:GetCreator()
    if CLIENT and LocalPlayer() ~= ply then return end
    if SERVER then
        self:SendMessage("events-notify", {event}, ply)
    elseif CLIENT and LocalPlayer() == ply then
        TARDIS:NotifyEvent(event)
    end
end

if SERVER then
    ENT:AddHook("PreMetadataInitialize", "halloween", function(self)
        local event = TARDIS:GetCurrentEvent(self)
        self:SetData("event", event, true)
        if event == TARDIS_EVENTS_APRIL_FOOLS then
            self:SetData("events-aprilfools", true, true)
        elseif event == TARDIS_EVENTS_HALLOWEEN then
            self:SetData("events-halloween", true, true)
        elseif event == TARDIS_EVENTS_CHRISTMAS then
            self:SetData("events-christmas", true, true)
        end
    end)
else
    ENT:OnMessage("events-notify", function(self, data, ply)
        if self:GetData("events-notified", false) then return end
        self:NotifyEvent(data[1])
        self:SetData("events-notified", true)
    end)
end
