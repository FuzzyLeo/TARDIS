---@meta

-- glua-api-snippets declares enum aliases (MASK, COLLISION_GROUP, _USE, etc.) as
-- string-literal unions for autocomplete, but the corresponding MASK_*, COLLISION_GROUP_*,
-- *_USE constants are plain integers at runtime. Re-declare the aliases as `integer` so
-- assignments like `Trace.mask = MASK_NPCWORLDSTATIC` type-check.

---@alias MASK integer
---@alias COLLISION_GROUP integer
---@alias _USE integer
---@alias DMG integer
---@alias RT_SIZE integer
---@alias MATERIAL_RT_DEPTH integer
---@alias CREATERENDERTARGETFLAGS integer
---@alias BOX integer
