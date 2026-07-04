---@type table<string, tardis_tip>
local tip_styles={}

---@api
function TARDIS:AddTipStyle(style)
    if CLIENT then
        tip_styles[style.style_id]=table.Copy(style)
    end
end

---@api
function TARDIS:RemoveTipStyle(id)
    tip_styles[id]=nil
end

---@api
function TARDIS:GetTipStyles()
    return tip_styles
end

---@api
---@return tardis_tip
function TARDIS:GetTipStyle(id)
    if tip_styles[id] then
        return tip_styles[id]
    end
    return tip_styles["white_on_grey"]
end

TARDIS:LoadFolder("themes/tips", nil, true)