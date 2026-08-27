[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $CommandPath,

    [ValidateRange(5, 600)]
    [int] $TimeoutSeconds = 60
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ExtensionId = 'bcnnjcbahmgdcieaelpellgemkkgjgcg'
$ExtensionPageOrigin = "chrome-extension://$ExtensionId"
$AllowedExtensionOrigins = @(
    $ExtensionPageOrigin,
    "extension://$ExtensionId",
    # Edge serializes unpacked extension:// pages as an opaque origin.
    # The 256-bit one-shot token remains mandatory on command and result requests.
    'null'
)
$listener = $null
$observedRequests = [Collections.Generic.List[string]]::new()

function Get-EdgeExecutable {
    $command = Get-Command msedge.exe -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    foreach ($candidate in @(
        (Join-Path ${env:ProgramFiles(x86)} 'Microsoft\Edge\Application\msedge.exe'),
        (Join-Path $env:ProgramFiles 'Microsoft\Edge\Application\msedge.exe'),
        (Join-Path $env:LOCALAPPDATA 'Microsoft\Edge\Application\msedge.exe')
    )) {
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }

    throw 'Microsoft Edge was not found.'
}

function New-Base64UrlToken {
    $bytes = [byte[]]::new(32)
    $rng = [Security.Cryptography.RandomNumberGenerator]::Create()
    try {
        $rng.GetBytes($bytes)
    }
    finally {
        $rng.Dispose()
    }
    return [Convert]::ToBase64String($bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')
}

function Get-RandomLoopbackPort {
    $probe = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, 0)
    try {
        $probe.Start()
        return ([Net.IPEndPoint]$probe.LocalEndpoint).Port
    }
    finally {
        $probe.Stop()
    }
}

function Set-CorsHeaders(
    [Net.HttpListenerResponse] $Response,
    [string] $Origin) {
    if ($Origin -in $AllowedExtensionOrigins) {
        $Response.Headers['Access-Control-Allow-Origin'] = $Origin
    }
    $Response.Headers['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
    $Response.Headers['Access-Control-Allow-Headers'] = 'Content-Type, X-Companion-Token'
    $Response.Headers['Cache-Control'] = 'no-store'
    $Response.Headers['Vary'] = 'Origin'
}

function Send-Response(
    [Net.HttpListenerContext] $Context,
    [int] $StatusCode,
    [string] $Body = '',
    [string] $ContentType = 'text/plain; charset=utf-8') {
    $bytes = [Text.Encoding]::UTF8.GetBytes($Body)
    $Context.Response.StatusCode = $StatusCode
    $Context.Response.ContentType = $ContentType
    Set-CorsHeaders $Context.Response $Context.Request.Headers['Origin']
    $Context.Response.ContentLength64 = $bytes.Length
    if ($bytes.Length -gt 0) {
        $Context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    }
    $Context.Response.Close()
}

function Get-ContextBeforeDeadline(
    [Net.HttpListener] $HttpListener,
    [DateTimeOffset] $Deadline) {
    $remaining = $Deadline - [DateTimeOffset]::UtcNow
    if ($remaining.TotalMilliseconds -le 0) {
        throw 'Timed out waiting for the Edge companion.'
    }
    $pending = $HttpListener.GetContextAsync()
    $delay = [Threading.Tasks.Task]::Delay([int][Math]::Ceiling($remaining.TotalMilliseconds))
    $completed = [Threading.Tasks.Task]::WhenAny($pending, $delay).GetAwaiter().GetResult()
    if (-not [object]::ReferenceEquals($completed, $pending)) {
        throw 'Timed out waiting for the Edge companion.'
    }
    return $pending.GetAwaiter().GetResult()
}

$resolvedCommandPath = [IO.Path]::GetFullPath($CommandPath)
if (-not (Test-Path -LiteralPath $resolvedCommandPath -PathType Leaf)) {
    throw "Command JSON was not found at '$resolvedCommandPath'."
}
$commandJson = [IO.File]::ReadAllText($resolvedCommandPath)
if ([Text.Encoding]::UTF8.GetByteCount($commandJson) -gt 10MB) {
    throw 'Command JSON exceeds the 10 MB bridge limit.'
}
$command = $commandJson | ConvertFrom-Json
if ($command.version -ne 1 -or
    $command.type -notin @('upsertManifestTopic', 'replaceFolderChildren', 'removeNamedFolders')) {
    throw 'Command JSON must have version 1 and a supported companion command type.'
}

$token = New-Base64UrlToken
$port = Get-RandomLoopbackPort
$prefix = "http://127.0.0.1:$port/"
$endpoint = "${prefix}command"
$applyUrl = "$ExtensionPageOrigin/apply.html?endpoint=$([Uri]::EscapeDataString($endpoint))&token=$([Uri]::EscapeDataString($token))"
$deadline = [DateTimeOffset]::UtcNow.AddSeconds($TimeoutSeconds)
$commandServed = $false
$result = $null

try {
    $listener = [Net.HttpListener]::new()
    $listener.Prefixes.Add($prefix)
    $listener.Start()
    Start-Process -FilePath (Get-EdgeExecutable) -ArgumentList @($applyUrl) | Out-Null

    while ($null -eq $result) {
        $context = Get-ContextBeforeDeadline $listener $deadline
        $request = $context.Request
        $origin = $request.Headers['Origin']
        if ($observedRequests.Count -lt 10) {
            $observedOrigin = if ([string]::IsNullOrEmpty($origin)) { '<missing>' } else { $origin }
            $observedRequests.Add("$($request.HttpMethod) $($request.Url.AbsolutePath) origin=$observedOrigin")
        }
        if (-not [string]::IsNullOrEmpty($origin) -and $origin -notin $AllowedExtensionOrigins) {
            Send-Response $context 403 'Forbidden origin.'
            continue
        }
        if ($request.HttpMethod -eq 'OPTIONS') {
            Send-Response $context 204
            continue
        }
        if ($request.Headers['X-Companion-Token'] -cne $token) {
            Send-Response $context 403 'Invalid token.'
            continue
        }

        if ($request.HttpMethod -eq 'GET' -and $request.Url.AbsolutePath -eq '/command') {
            if ($commandServed) {
                Send-Response $context 410 'Command already consumed.'
            }
            else {
                $commandServed = $true
                Send-Response $context 200 $commandJson 'application/json; charset=utf-8'
            }
            continue
        }

        if ($request.HttpMethod -eq 'POST' -and $request.Url.AbsolutePath -eq '/result') {
            $reader = [IO.StreamReader]::new($request.InputStream, $request.ContentEncoding)
            try {
                $body = $reader.ReadToEnd()
            }
            finally {
                $reader.Dispose()
            }
            if ([Text.Encoding]::UTF8.GetByteCount($body) -gt 1MB) {
                Send-Response $context 413 'Result too large.'
                continue
            }
            try {
                $candidate = $body | ConvertFrom-Json
                $propertyNames = @($candidate.PSObject.Properties.Name)
                $unsupported = @($propertyNames | Where-Object {
                    $_ -notin @('version', 'ok', 'commandType', 'details', 'error')
                })
                if ($candidate.version -ne 1 -or $candidate.ok -isnot [bool] -or
                    [string]$candidate.commandType -cne [string]$command.type -or
                    $unsupported.Count -gt 0) {
                    throw 'Invalid result schema.'
                }
                if ($candidate.ok) {
                    if ('details' -notin $propertyNames -or 'error' -in $propertyNames) {
                        throw 'A successful result must contain details and no error.'
                    }
                }
                elseif ('error' -notin $propertyNames -or
                    [string]::IsNullOrWhiteSpace([string]$candidate.error) -or
                    'details' -in $propertyNames) {
                    throw 'A failed result must contain a non-empty error and no details.'
                }
                $result = $candidate
                Send-Response $context 200 '{"accepted":true}' 'application/json; charset=utf-8'
            }
            catch {
                if ($observedRequests.Count -lt 10) {
                    $observedRequests.Add("result rejected: $($_.Exception.Message) body=$body")
                }
                Send-Response $context 400 'Invalid result JSON.'
            }
            continue
        }

        Send-Response $context 404 'Not found.'
    }
}
catch {
    if ($_.Exception.Message -like 'Timed out*') {
        $observed = if ($observedRequests.Count) {
            " Observed requests: $($observedRequests -join '; ')."
        }
        else {
            ' No localhost requests were observed.'
        }
        throw "Timed out waiting for Edge companion extension $ExtensionId.$observed Install or enable it with scripts\Install-EdgeFavoritesCompanion.ps1, then retry."
    }
    throw
}
finally {
    if ($null -ne $listener) {
        $listener.Close()
    }
    $token = $null
    $applyUrl = $null
}

if (-not $result.ok) {
    throw "Edge companion reported failure: $($result.error)"
}

$result
