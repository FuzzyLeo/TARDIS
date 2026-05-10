-- Temporary TARDIS predict-teleport debug HUD. Toggle with
-- `tardis_debug_predict 1`. Companion to the world-portals
-- worldportals_debug_predict overlay. Remove once the high-ping
-- entry artifacts are diagnosed.

CreateClientConVar("tardis_debug_predict", "0", true, false,
    "Show TARDIS predicted-teleport debug overlay", 0, 1)

TARDIS_PredictDebug = TARDIS_PredictDebug or { events = {}, max = 30 }

function TARDIS_PredictDebug:Log(label, data)
    if not GetConVar("tardis_debug_predict"):GetBool() then return end
    table.insert(self.events, 1, {
        frame = FrameNumber(),
        time  = SysTime(),
        label = label,
        data  = data,
    })
    while #self.events > self.max do table.remove(self.events) end
end

local function entStr(e)
    if not IsValid(e) then return tostring(e) end
    return string.format("%s[%d]", e:GetClass(), e:EntIndex())
end

local function fb(b)
    if b == nil then return "nil" end
    return tostring(b)
end

-- Log every client-side wp-teleport so we can see whether the world-portals
-- predicted SetupMove path is firing at all on TARDIS entry, regardless of
-- whether the per-entity PostTeleportPortal chain reaches our predict hook.
hook.Add("wp-teleport", "TARDIS_PredictDebugLog", function(portal, ent, newpos)
    if ent ~= LocalPlayer() then return end
    local parent = IsValid(portal) and portal:GetParent() or nil
    TARDIS_PredictDebug:Log("wp-teleport(client)",
        string.format("portal=%s parent=%s newpos=(%.0f,%.0f,%.0f)",
            tostring(portal), entStr(parent),
            newpos and newpos.x or 0, newpos and newpos.y or 0, newpos and newpos.z or 0))
end)

-- (Server-side WorldPortals_Teleport broadcast lands at the world-portals
-- net.Receive — see worldportals_debug_predict for the "Last net broadcast"
-- line. Don't override that net handler here, last-wins would break it.)

-- Client-side enter/exit tracking. Watch ply.door / ply.doori / tardis.interior
-- state transitions and log the instant they flip, so we can read off the
-- exact frame each piece of state landed and which path set it (predict vs
-- net broadcast vs nothing at all).
local prevDoor, prevDori, prevTI, prevTE, prevTO
hook.Add("Think", "TARDIS_PredictDebug_StateWatch", function()
    if not GetConVar("tardis_debug_predict"):GetBool() then return end
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local door, dori = ply.door, ply.doori
    local ti = ply:GetTardisData("interior")
    local te = ply:GetTardisData("exterior")
    local to = ply:GetTardisData("outside")
    if door ~= prevDoor then
        TARDIS_PredictDebug:Log("ply.door change",
            string.format("%s -> %s", entStr(prevDoor), entStr(door)))
        prevDoor = door
    end
    if dori ~= prevDori then
        TARDIS_PredictDebug:Log("ply.doori change",
            string.format("%s -> %s", entStr(prevDori), entStr(dori)))
        prevDori = dori
    end
    if ti ~= prevTI then
        TARDIS_PredictDebug:Log("tardis.interior change",
            string.format("%s -> %s", entStr(prevTI), entStr(ti)))
        prevTI = ti
    end
    if te ~= prevTE then
        TARDIS_PredictDebug:Log("tardis.exterior change",
            string.format("%s -> %s", entStr(prevTE), entStr(te)))
        prevTE = te
    end
    if to ~= prevTO then
        TARDIS_PredictDebug:Log("tardis.outside change",
            string.format("%s -> %s", fb(prevTO), fb(to)))
        prevTO = to
    end
end)

hook.Add("HUDPaint", "TARDIS_PredictDebugHUD", function()
    if not GetConVar("tardis_debug_predict"):GetBool() then return end
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local sw = ScrW()
    local x, y = sw - 560, 100
    local lh = 14
    local function line(text, col)
        draw.SimpleText(text, "DermaDefault", x, y, col or color_white,
            TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        y = y + lh
    end

    line(string.format("[TARDIS predict debug] frame=%d  SysTime=%.3f",
        FrameNumber(), SysTime()), Color(120, 220, 255))

    line(string.format("ply.door=%s  ply.doori=%s",
        entStr(ply.door), entStr(ply.doori)))
    line(string.format("tardis.exterior=%s",
        entStr(ply:GetTardisData("exterior"))))
    line(string.format("tardis.interior=%s",
        entStr(ply:GetTardisData("interior"))))
    line(string.format("tardis.outside=%s  tardis.intfallback=%s",
        fb(ply:GetTardisData("outside")), fb(ply:GetTardisData("intfallback"))))

    line("")
    line("Nearby TARDIS-parented portals (<800u):", Color(200, 200, 200))
    local plyEye = ply:EyePos()
    local vel = ply:GetVelocity()
    local frameTime = FrameTime()
    local count = 0
    for _, portal in ipairs(ents.FindByClass("linked_portal_door")) do
        local parent = portal:GetParent()
        if not (IsValid(parent) and (parent.TardisExterior or parent.TardisInterior)) then goto skip end
        local d = portal:GetPos():Distance(plyEye)
        if d > 800 then goto skip end
        count = count + 1
        local fwd = portal:GetForward()
        local pos = portal:GetPos()
        local distNow = (plyEye - pos):Dot(fwd)
        local nextEye = plyEye + vel * frameTime
        local distNext = (nextEye - pos):Dot(fwd)
        local localEye = portal:WorldToLocal(nextEye)
        local mins, maxs = portal:GetCollisionBounds()
        local inY = localEye.y >= mins.y and localEye.y <= maxs.y
        local inZ = localEye.z >= mins.z and localEye.z <= maxs.z
        local crossing = distNow > 0 and distNext <= 0
        local crossCol = crossing and Color(255, 200, 120) or color_white
        line(string.format("  [%d] parent=%s d=%.1f thick=%d inv=%s",
            portal:EntIndex(), entStr(parent), d,
            portal:GetThickness(), fb(portal:GetInverted())), crossCol)
        line(string.format("    distNow=%6.2f distNext=%6.2f velFwd=%6.2f open=%s tp=%s",
            distNow, distNext, vel:Dot(fwd),
            fb(portal:GetOpen()), fb(portal:GetEnableTeleport())), crossCol)
        line(string.format("    localEyeNext y=%6.2f z=%6.2f  inY=%s inZ=%s  CROSSING=%s",
            localEye.y, localEye.z, fb(inY), fb(inZ), fb(crossing)), crossCol)
        -- TARDIS veto evaluation (replicates predicates used by the
        -- ShouldTeleportPortal / CanPlayerEnter / CanPlayerExit chain).
        local ext = parent.TardisExterior and parent or parent.exterior
        local doorOpen = IsValid(ext) and ext.DoorOpen and ext:DoorOpen() or false
        local locked = IsValid(ext) and ext.Locked and ext:Locked() or false
        local demat = IsValid(ext) and ext:GetData("teleport") or false
        local vortex = IsValid(ext) and ext:GetData("vortex") or false
        local redec = IsValid(ext) and ext:GetData("redecorate") or false
        local tracking = IsValid(ext) and ext:GetTracking() or nil
        local trackingHits = IsValid(tracking) and tracking == ply
        line(string.format("    veto: doorOpen=%s locked=%s demat=%s vortex=%s redec=%s tracking=%s",
            fb(doorOpen), fb(locked), fb(demat), fb(vortex), fb(redec),
            fb(trackingHits)), crossCol)
        ::skip::
    end
    if count == 0 then line("  (none in range)", Color(160, 160, 160)) end

    line("")
    -- Pick the interior we care about: the one ply is "in" via TardisData,
    -- else the one whose exterior is ply.door, else the nearest tardis interior.
    local int = ply:GetTardisData("interior")
    if not IsValid(int) and IsValid(ply.door) and ply.door.TardisExterior then
        int = ply.door.interior
    end
    if not IsValid(int) then
        local nearestDist
        for _, e in ipairs(ents.FindByClass("gmod_tardis_interior")) do
            local d = e:GetPos():Distance(plyEye)
            if not nearestDist or d < nearestDist then int, nearestDist = e, d end
        end
        if IsValid(int) then
            line(string.format("(no current TARDIS interior; nearest = %s)",
                entStr(int)), Color(200, 200, 160))
        end
    end

    if IsValid(int) then
        local extKey = ply:GetTardisData("interior") == int
        local outside = ply:GetTardisData("outside")
        local propsExt = int.props and int.props[int.exterior] or nil
        local containsDoor = int.contains and int.contains[ply.door] or nil
        local drawing = wp and wp.drawing
        local hideA = not extKey
        local hideB = outside and (propsExt == nil)
        local hide = (hideA or hideB) and not drawing and not containsDoor
        local col = hide and Color(255, 130, 130) or Color(150, 230, 150)
        line(string.format("Interior %s ShouldDraw inputs:", entStr(int)), col)
        line(string.format("  GetTardisData(\"interior\") == self : %s", fb(extKey)), col)
        line(string.format("  GetTardisData(\"outside\")          : %s", fb(outside)), col)
        line(string.format("  props[exterior]==nil               : %s (props.ext=%s)",
            fb(propsExt == nil), tostring(propsExt)), col)
        line(string.format("  wp.drawing                         : %s", fb(drawing)), col)
        line(string.format("  contains[ply.door]                 : %s (door=%s)",
            fb(containsDoor), entStr(ply.door)), col)
        line(string.format("  -> ShouldDraw returns              : %s",
            hide and "FALSE (HIDE)" or "nil (SHOW)"), col)
    end

    line("")
    line("---- Events (newest first) ----", Color(200, 200, 200))
    local now = SysTime()
    for i, e in ipairs(TARDIS_PredictDebug.events) do
        if i > 22 then break end
        local age = now - e.time
        line(string.format("  [%d] %5.3fs ago  %s%s",
            e.frame, age, e.label, e.data and ("  " .. e.data) or ""),
            Color(220, 220, 220))
    end
end)
