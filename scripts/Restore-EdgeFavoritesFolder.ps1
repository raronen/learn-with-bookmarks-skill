[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $BackupPath,

    [Parameter(Mandatory)]
    [string[]] $FolderPath,

    [Parameter(Mandatory)]
    [string] $OutputCommandPath,

    [switch] $Apply,

    [ValidateRange(5, 600)]
    [int] $TimeoutSeconds = 60
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-PropertyValue($Object, [string] $Name, $DefaultValue = $null) {
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $DefaultValue
    }
    return $property.Value
}

function Convert-BackupNode($Node) {
    $type = [string](Get-PropertyValue $Node 'type')
    $name = [string](Get-PropertyValue $Node 'name')
    if ([string]::IsNullOrWhiteSpace($name)) {
        throw 'Backup contains a bookmark node without a name.'
    }
    if ($type -eq 'url') {
        $url = [string](Get-PropertyValue $Node 'url')
        if ([string]::IsNullOrWhiteSpace($url)) {
            throw "Backup bookmark '$name' has no URL."
        }
        return [ordered]@{ type = 'bookmark'; name = $name; url = $url }
    }
    if ($type -eq 'folder') {
        return [ordered]@{
            type = 'folder'
            name = $name
            children = @(@(Get-PropertyValue $Node 'children' @()) | ForEach-Object { Convert-BackupNode $_ })
        }
    }
    throw "Backup node '$name' has unsupported type '$type'."
}

$resolvedBackupPath = [IO.Path]::GetFullPath($BackupPath)
if (-not (Test-Path -LiteralPath $resolvedBackupPath -PathType Leaf)) {
    throw "Bookmark backup was not found at '$resolvedBackupPath'."
}
if ($FolderPath.Count -eq 0) {
    throw 'FolderPath must contain at least one segment.'
}
$path = @($FolderPath)
if ($path[0] -ne 'Favorites bar') {
    $path = @('Favorites bar') + $path
}

$backup = [IO.File]::ReadAllText($resolvedBackupPath) | ConvertFrom-Json
$current = Get-PropertyValue (Get-PropertyValue $backup 'roots') 'bookmark_bar'
if ($null -eq $current) {
    throw "Backup does not contain roots.bookmark_bar for 'Favorites bar'."
}

if ($path.Count -gt 1) {
    foreach ($segment in $path[1..($path.Count - 1)]) {
        $matches = @(@(Get-PropertyValue $current 'children' @()) | Where-Object {
            (Get-PropertyValue $_ 'type') -eq 'folder' -and (Get-PropertyValue $_ 'name') -ceq $segment
        })
        if ($matches.Count -ne 1) {
            $state = if ($matches.Count -eq 0) { 'missing' } else { 'ambiguous' }
            throw "Folder segment '$segment' is $state in the backup."
        }
        $current = $matches[0]
    }
}

$command = [ordered]@{
    version = 1
    type = 'replaceFolderChildren'
    destinationPath = $path
    children = @(@(Get-PropertyValue $current 'children' @()) | ForEach-Object { Convert-BackupNode $_ })
}
$resolvedOutputPath = [IO.Path]::GetFullPath($OutputCommandPath)
$outputParent = Split-Path -Parent $resolvedOutputPath
if ($outputParent) {
    [IO.Directory]::CreateDirectory($outputParent) | Out-Null
}
[IO.File]::WriteAllText(
    $resolvedOutputPath,
    ($command | ConvertTo-Json -Depth 100),
    [Text.UTF8Encoding]::new($false))

if ($Apply) {
    & (Join-Path $PSScriptRoot 'Invoke-EdgeFavoritesCompanion.ps1') `
        -CommandPath $resolvedOutputPath `
        -TimeoutSeconds $TimeoutSeconds
}
else {
    [pscustomobject]@{
        Mode = 'CommandOnly'
        CommandPath = $resolvedOutputPath
        DestinationPath = $path
        ChildCount = $command.children.Count
    }
}
