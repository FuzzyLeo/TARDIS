[CmdletBinding()]
param(
    [string] $WikiPath,
    [switch] $Check
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/bootstrap.ps1"

$RepoRoot = Split-Path -Parent $PSScriptRoot
if (-not $WikiPath) { $WikiPath = Join-Path (Split-Path -Parent $RepoRoot) 'TARDIS.wiki' }

$WikiConfig = & "$PSScriptRoot/wiki-api.config.ps1"

# Identity/plumbing fields whose base value is not an inherited default.
$IdentityFields = @{
    'tardis_metadata'  = @('ID', 'Name', 'Base', 'BaseMerged')
    'tardis_gui_theme' = @('id', 'name', 'folder')
}

# Base defaults, read straight from the headless-loaded registries. The engine
# hands us a loaded harness ($lua) + its metatable map ($meta).
$DefaultsProvider = {
    param($lua, $meta)
    $Table  = [MoonSharp.Interpreter.DataType]::Table
    $tardis = $lua.Globals.Get('TARDIS').Table

    $base = $tardis.Get('MetadataRaw').Table.Get('base')
    if ($base.Type -ne $Table) { throw 'base interior metadata not found' }

    $guiBase = $tardis.Get('gui_themes').Table.Get('base')

    return @{
        tardis_metadata          = ConvertFrom-LuaValue $base $meta
        tardis_exterior_metadata = ConvertFrom-LuaValue ($base.Table.Get('Exterior')) $meta
        tardis_gui_theme         = if ($guiBase.Type -eq $Table) { ConvertFrom-LuaValue $guiBase $meta } else { $null }
    }
}

Invoke-WikiGen `
    -Root $RepoRoot `
    -WikiPath $WikiPath `
    -Categories $WikiConfig['Categories'] `
    -OwnedPrefix $WikiConfig['OwnedPrefix'] `
    -DefaultsProvider $DefaultsProvider `
    -IdentityFields $IdentityFields `
    -Check:$Check
