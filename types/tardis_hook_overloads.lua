-- Generated custom global-hook overloads. Do not edit; regen: scripts/generate-hook-types.ps1.
-- Sync-GmodHookTypes (Initialize-GmodTools) splices these into .tools/glua-api/hook.lua so
-- hook.Add("<name>", ...) callbacks type their payload params. Inert on its own - the splice binds.

---@param eventName string
---@param identifier any
---@param func function
---@overload fun(eventName: "TARDIS_LanguageChanged", identifier: any, func: fun(langCode: any, oldLangCode: any, ...))
---@overload fun(eventName: "TARDIS_MetadataLoaded", identifier: any, func: fun(...))
---@overload fun(eventName: "TARDIS_PostMetadataLoaded", identifier: any, func: fun(...))
---@overload fun(eventName: "TARDIS_SettingChanged", identifier: any, func: fun(id: string, value: any, old_value: any, ply: Player, ...))
function hook.Add(eventName, identifier, func) end
