-- Alpha

-- Cache rendering decision at Think level rather than checking on every draw call
local use_experimental_cache = {}

function ENT:GetAlpha()
    local alpha = self:GetData("alpha",255)/255
    if self:GetData("vortexalpha",0)>alpha and TARDIS:GetExteriorEnt()==self then
        return self:GetData("vortexalpha",0),true
    end
    if self:GetData("vortex") then
        return 0
    elseif self:GetData("teleport") then
        return alpha
    elseif self:GetData("teleport-trace") or self:GetData("tracking-trace") then
        return 20/255
    end
    return 1
end

local function shouldapply(self,part)
    local target,override = self:GetAlpha()
    if (target ~= 1 or override) and ((not part) or (part and (not part.CustomAlpha))) then
        return target
    end
end

local function shouldUseExperimentalRendering(self)
    -- Check if experimental alpha rendering is enabled
    if not TARDIS:GetSetting("experimental-alpha-rendering") then
        return false
    end
    
    -- Check if currently redecorating
    if self:GetData("redecorate_child") or self:GetData("is_redecorate_child") then
        return false
    end

    return true
end

local function dopredraw(self,part)
    local target = shouldapply(self,part)
    if target~=nil then
        -- Use cached decision for experimental rendering
        local useExperimental = use_experimental_cache[self:EntIndex()] or false
        
        -- Use experimental rendering method only when allowed
        if useExperimental then
            render.OverrideColorWriteEnable(true, false)
            self:DrawModel()
            render.OverrideColorWriteEnable(false, false)

            render.OverrideColorWriteEnable(true, false)
            for k,v in pairs(self.parts) do
                if v.ExteriorPart then
                    v:DrawModel()
                end
            end
            render.OverrideColorWriteEnable(false, false)
        end
        
        render.SetBlend(target)
        if self:CallHook("ShouldVortexIgnoreZ") then
            -- cam.IgnoreZ(true)
        end
    end
end

local function dopostdraw(self,part)
    if shouldapply(self,part)~=nil then
        cam.IgnoreZ(false)
    end
end

-- Think hook to update rendering decisions less frequently
ENT:AddHook("Think", "experimental_render_cache", function(self)
    local alpha = self:GetAlpha()
    if alpha > 0 and alpha < 1 then
        use_experimental_cache[self:EntIndex()] = shouldUseExperimentalRendering(self)
    end
end)

-- Clean up the cache when entity is removed
ENT:AddHook("OnRemove", "experimental_render_cache", function(self)
    use_experimental_cache[self:EntIndex()] = nil
end)

ENT:AddHook("PreDraw","teleport",dopredraw)
ENT:AddHook("PreDrawPart","teleport",dopredraw)
ENT:AddHook("Draw","teleport",dopostdraw)
ENT:AddHook("PostDrawPart","teleport",dopostdraw)
ENT:AddHook("PreDrawPortal","vortex",dopredraw)
ENT:AddHook("PostDrawPortal","vortex",dopostdraw)
