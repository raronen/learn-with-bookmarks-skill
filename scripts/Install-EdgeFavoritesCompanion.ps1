[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ExtensionId = 'bcnnjcbahmgdcieaelpellgemkkgjgcg'
$extensionDirectory = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\edge-companion'))
if (-not (Test-Path -LiteralPath (Join-Path $extensionDirectory 'manifest.json'))) {
    throw "Extension manifest was not found at '$extensionDirectory'."
}

function Get-EdgeExecutable {
    $command = Get-Command msedge.exe -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }
    foreach ($root in @(${env:ProgramFiles(x86)}, $env:ProgramFiles, $env:LOCALAPPDATA)) {
        if ($root) {
            $candidate = Join-Path $root 'Microsoft\Edge\Application\msedge.exe'
            if (Test-Path -LiteralPath $candidate) {
                return $candidate
            }
        }
    }
    throw 'Microsoft Edge was not found.'
}

Start-Process explorer.exe -ArgumentList @($extensionDirectory) | Out-Null
Start-Process -FilePath (Get-EdgeExecutable) -ArgumentList @('edge://extensions/') | Out-Null

Write-Host 'One-time installation:'
Write-Host '1. Turn on Developer mode in edge://extensions.'
Write-Host '2. Select Load unpacked.'
Write-Host "3. Choose: $extensionDirectory"
Write-Host "4. Verify extension ID: $ExtensionId"
Write-Host 'Keep the extension enabled for future EdgeApi publications.'
