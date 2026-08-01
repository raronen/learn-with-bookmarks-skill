[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $ManifestPath,

    [ValidateSet('Auto', 'Direct', 'Import')]
    [string] $Mode = 'Auto',

    [ValidateSet('Chrome', 'Edge', 'Both')]
    [string] $Browser = 'Both',

    [string] $ChromeProfilePath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default",

    [string] $EdgeProfilePath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default",

    [string] $OutputDirectory
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

function Get-ChromeTimestamp {
    $epoch = [DateTimeOffset]::new(1601, 1, 1, 0, 0, 0, [TimeSpan]::Zero)
    return [string][long](([DateTimeOffset]::UtcNow - $epoch).Ticks / 10)
}

function ConvertTo-FileUri([string] $Path) {
    return [Uri]::new([IO.Path]::GetFullPath($Path)).AbsoluteUri
}

function Add-OverviewTreeFolder(
    [Text.StringBuilder] $Builder,
    $Folder,
    [int] $Depth) {
    $name = [Net.WebUtility]::HtmlEncode([string]$Folder.name)
    $openAttribute = if ($Depth -eq 0) { ' open' } else { '' }
    [void]$Builder.AppendLine("<details class=`"learning-bookmark-folder`" style=`"--tree-depth: $Depth`"$openAttribute>")
    [void]$Builder.AppendLine("  <summary><span class=`"learning-bookmark-folder-icon`" aria-hidden=`"true`"></span><span>$name</span></summary>")
    [void]$Builder.AppendLine('  <div class="learning-bookmark-children">')

    foreach ($link in @(Get-PropertyValue $Folder 'links' @())) {
        $linkName = [Net.WebUtility]::HtmlEncode([string]$link.name)
        $url = [Net.WebUtility]::HtmlEncode([string]$link.url)
        [void]$Builder.AppendLine("    <a class=`"learning-bookmark-link`" href=`"$url`" target=`"_blank`" rel=`"noopener noreferrer`"><span class=`"learning-bookmark-link-icon`" aria-hidden=`"true`"></span><span>$linkName</span></a>")
    }

    foreach ($childFolder in @(Get-PropertyValue $Folder 'folders' @())) {
        Add-OverviewTreeFolder $Builder $childFolder ($Depth + 1)
    }

    [void]$Builder.AppendLine('  </div>')
    [void]$Builder.AppendLine('</details>')
}

function Update-OverviewBookmarkTree($Manifest) {
    $startMarker = '<!-- LEARNING-BOOKMARK-TREE:START -->'
    $endMarker = '<!-- LEARNING-BOOKMARK-TREE:END -->'
    $overviewPath = [IO.Path]::GetFullPath([string]$Manifest.overviewPath)
    $html = [IO.File]::ReadAllText($overviewPath)
    $startIndex = $html.IndexOf($startMarker, [StringComparison]::Ordinal)
    $endIndex = $html.IndexOf($endMarker, [StringComparison]::Ordinal)

    if ($startIndex -lt 0 -or $endIndex -lt 0 -or $endIndex -lt $startIndex) {
        throw "Overview HTML must contain '$startMarker' and '$endMarker' in that order."
    }

    $builder = [Text.StringBuilder]::new()
    [void]$builder.AppendLine($startMarker)
    [void]$builder.AppendLine('<style>')
    [void]$builder.AppendLine('.learning-bookmark-browser{margin:18px 0 26px;padding:16px 18px;background:#fff;border:1px solid #cbd5e1;border-radius:12px;box-shadow:0 2px 10px #0f172a12}')
    [void]$builder.AppendLine('.learning-bookmark-browser h2{margin:0 0 6px;font-size:1.2rem}')
    [void]$builder.AppendLine('.learning-bookmark-browser>p{margin:0 0 12px;color:#475569}')
    [void]$builder.AppendLine('.learning-bookmark-folder{margin:3px 0 3px calc(var(--tree-depth)*14px)}')
    [void]$builder.AppendLine('.learning-bookmark-folder>summary{display:flex;align-items:center;gap:8px;padding:7px 9px;cursor:pointer;border-radius:7px;font-weight:650;color:#172554;list-style:none;user-select:none}')
    [void]$builder.AppendLine('.learning-bookmark-folder>summary::-webkit-details-marker{display:none}')
    [void]$builder.AppendLine('.learning-bookmark-folder>summary:hover,.learning-bookmark-folder>summary:focus-visible{background:#dbeafe;outline:none}')
    [void]$builder.AppendLine('.learning-bookmark-folder-icon::before{content:"\25B6";display:inline-block;width:14px;color:#2563eb;transition:transform .12s ease}')
    [void]$builder.AppendLine('.learning-bookmark-folder[open]>summary .learning-bookmark-folder-icon::before{transform:rotate(90deg)}')
    [void]$builder.AppendLine('.learning-bookmark-children{margin-left:12px;padding-left:8px;border-left:1px solid #cbd5e1}')
    [void]$builder.AppendLine('.learning-bookmark-link{display:flex;align-items:center;gap:8px;margin:2px 0;padding:7px 9px;border-radius:7px;color:#1d4ed8;text-decoration:none}')
    [void]$builder.AppendLine('.learning-bookmark-link:hover,.learning-bookmark-link:focus-visible{background:#eff6ff;text-decoration:underline;outline:none}')
    [void]$builder.AppendLine('.learning-bookmark-link-icon::before{content:"\2197";display:inline-block;width:14px;color:#64748b;font-weight:700}')
    [void]$builder.AppendLine('@media print{.learning-bookmark-folder{display:block}.learning-bookmark-folder>.learning-bookmark-children{display:block!important}}')
    [void]$builder.AppendLine('</style>')
    [void]$builder.AppendLine('<section class="learning-bookmark-browser" aria-labelledby="learning-bookmarks-title">')
    [void]$builder.AppendLine('  <h2 id="learning-bookmarks-title">Source bookmark tree</h2>')
    [void]$builder.AppendLine('  <p>Folders start collapsed. Expand them here and open source links in new tabs without losing this page.</p>')

    $overviewName = Get-PropertyValue $Manifest 'overviewName' "00 - Open $($Manifest.title) Overview"
    $topicLinks = [Collections.Generic.List[object]]::new()
    $topicLinks.Add([pscustomobject]@{
        name = $overviewName
        url = ConvertTo-FileUri $overviewPath
    })
    foreach ($link in @(Get-PropertyValue $Manifest 'links' @())) {
        $topicLinks.Add($link)
    }

    $topicFolder = [pscustomobject]@{
        name = $Manifest.title
        links = @($topicLinks)
        folders = @(Get-PropertyValue $Manifest 'folders' @())
    }
    Add-OverviewTreeFolder $builder $topicFolder 0
    [void]$builder.AppendLine('</section>')
    [void]$builder.Append($endMarker)

    $replaceEnd = $endIndex + $endMarker.Length
    $updated = $html.Substring(0, $startIndex) + $builder.ToString() + $html.Substring($replaceEnd)
    [IO.File]::WriteAllText($overviewPath, $updated, [Text.UTF8Encoding]::new($false))

    $verification = [IO.File]::ReadAllText($overviewPath)
    if (-not $verification.Contains('class="learning-bookmark-browser"') -or
        -not $verification.Contains('target="_blank" rel="noopener noreferrer"')) {
        throw 'Overview bookmark tree verification failed.'
    }
}

function Get-MaxBookmarkId($Node) {
    $id = Get-PropertyValue $Node 'id'
    $maximum = if ($null -ne $id) { [long]$id } else { 0L }
    foreach ($child in @(Get-PropertyValue $Node 'children' @())) {
        $childMaximum = Get-MaxBookmarkId $child
        if ($childMaximum -gt $maximum) {
            $maximum = $childMaximum
        }
    }

    return $maximum
}

function New-ChromeUrlNode([string] $Name, [string] $Url, [ref] $NextId) {
    $id = $NextId.Value
    $NextId.Value++
    return [ordered]@{
        date_added = Get-ChromeTimestamp
        date_last_used = '0'
        guid = [Guid]::NewGuid().ToString()
        id = [string]$id
        name = $Name
        type = 'url'
        url = $Url
    }
}

function New-ChromeFolderNode($Folder, [ref] $NextId) {
    $id = $NextId.Value
    $NextId.Value++
    $children = [Collections.Generic.List[object]]::new()

    foreach ($link in @(Get-PropertyValue $Folder 'links' @())) {
        $children.Add((New-ChromeUrlNode $link.name $link.url $NextId))
    }

    foreach ($childFolder in @(Get-PropertyValue $Folder 'folders' @())) {
        $children.Add((New-ChromeFolderNode $childFolder $NextId))
    }

    return [ordered]@{
        children = @($children)
        date_added = Get-ChromeTimestamp
        date_last_used = '0'
        date_modified = Get-ChromeTimestamp
        guid = [Guid]::NewGuid().ToString()
        id = [string]$id
        name = $Folder.name
        type = 'folder'
    }
}

function New-TopicNode($Manifest, [ref] $NextId) {
    $configuredOverviewName = Get-PropertyValue $Manifest 'overviewName'
    $overviewName = if ($configuredOverviewName) {
        $configuredOverviewName
    } else {
        "00 - Open $($Manifest.title) Overview"
    }

    $children = [Collections.Generic.List[object]]::new()
    $children.Add((New-ChromeUrlNode $overviewName (ConvertTo-FileUri $Manifest.overviewPath) $NextId))

    foreach ($link in @(Get-PropertyValue $Manifest 'links' @())) {
        $children.Add((New-ChromeUrlNode $link.name $link.url $NextId))
    }

    foreach ($folder in @(Get-PropertyValue $Manifest 'folders' @())) {
        $children.Add((New-ChromeFolderNode $folder $NextId))
    }

    $id = $NextId.Value
    $NextId.Value++
    return [ordered]@{
        children = @($children)
        date_added = Get-ChromeTimestamp
        date_last_used = '0'
        date_modified = Get-ChromeTimestamp
        guid = [Guid]::NewGuid().ToString()
        id = [string]$id
        name = $Manifest.title
        type = 'folder'
    }
}

function Get-BookmarkChecksum($Bookmarks) {
    $stream = [IO.MemoryStream]::new()
    $md5 = [Security.Cryptography.MD5]::Create()

    try {
        function Write-ChecksumBytes([byte[]] $Bytes) {
            $stream.Write($Bytes, 0, $Bytes.Length)
        }

        function Add-ChecksumNode($Node) {
            Write-ChecksumBytes ([Text.Encoding]::UTF8.GetBytes([string]$Node.id))
            Write-ChecksumBytes ([Text.Encoding]::Unicode.GetBytes([string]$Node.name))

            if ($Node.type -eq 'url') {
                Write-ChecksumBytes ([Text.Encoding]::UTF8.GetBytes('url'))
                Write-ChecksumBytes ([Text.Encoding]::UTF8.GetBytes([string]$Node.url))
                return
            }

            Write-ChecksumBytes ([Text.Encoding]::UTF8.GetBytes('folder'))
            foreach ($child in @(Get-PropertyValue $Node 'children' @())) {
                Add-ChecksumNode $child
            }
        }

        foreach ($rootName in @('bookmark_bar', 'other', 'synced')) {
            $root = Get-PropertyValue $Bookmarks.roots $rootName
            if ($null -ne $root) {
                Add-ChecksumNode $root
            }
        }

        $stream.Position = 0
        return [Convert]::ToHexString($md5.ComputeHash($stream)).ToLowerInvariant()
    }
    finally {
        $stream.Dispose()
        $md5.Dispose()
    }
}

function Add-HtmlFolder([Text.StringBuilder] $Builder, $Folder, [int] $Indent) {
    $padding = ' ' * $Indent
    [void]$Builder.AppendLine("$padding<DT><H3>$([Net.WebUtility]::HtmlEncode($Folder.name))</H3>")
    [void]$Builder.AppendLine("$padding<DL><p>")

    foreach ($link in @(Get-PropertyValue $Folder 'links' @())) {
        $name = [Net.WebUtility]::HtmlEncode($link.name)
        $url = [Net.WebUtility]::HtmlEncode($link.url)
        [void]$Builder.AppendLine("$padding    <DT><A HREF=`"$url`">$name</A>")
    }

    foreach ($childFolder in @(Get-PropertyValue $Folder 'folders' @())) {
        Add-HtmlFolder $Builder $childFolder ($Indent + 4)
    }

    [void]$Builder.AppendLine("$padding</DL><p>")
}

function Write-ImportFile($Manifest, [string] $Directory) {
    [IO.Directory]::CreateDirectory($Directory) | Out-Null
    $safeName = ($Manifest.title -replace '[^A-Za-z0-9._-]+', '-').Trim('-').ToLowerInvariant()
    $path = Join-Path $Directory "import-$safeName-bookmarks.html"
    $builder = [Text.StringBuilder]::new()

    [void]$builder.AppendLine('<!DOCTYPE NETSCAPE-Bookmark-file-1>')
    [void]$builder.AppendLine('<!-- Generated by learn-with-bookmarks. -->')
    [void]$builder.AppendLine('<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">')
    [void]$builder.AppendLine("<TITLE>$([Net.WebUtility]::HtmlEncode($Manifest.title))</TITLE>")
    [void]$builder.AppendLine("<H1>$([Net.WebUtility]::HtmlEncode($Manifest.title))</H1>")
    [void]$builder.AppendLine('<DL><p>')

    $configuredOverviewName = Get-PropertyValue $Manifest 'overviewName'
    $topic = [pscustomobject]@{
        name = $Manifest.title
        links = @(
            [pscustomobject]@{
                name = if ($configuredOverviewName) { $configuredOverviewName } else { "00 - Open $($Manifest.title) Overview" }
                url = ConvertTo-FileUri $Manifest.overviewPath
            }
        ) + @(Get-PropertyValue $Manifest 'links' @())
        folders = @(Get-PropertyValue $Manifest 'folders' @())
    }

    Add-HtmlFolder $builder $topic 4
    [void]$builder.AppendLine('</DL><p>')
    [IO.File]::WriteAllText($path, $builder.ToString(), [Text.UTF8Encoding]::new($false))
    return $path
}

function Assert-BrowserReady(
    [string] $BrowserName,
    [string] $ProcessName,
    [string] $ProfilePath) {
    if (Get-Process $ProcessName -ErrorAction SilentlyContinue) {
        throw "$BrowserName is running. Close every $BrowserName window and background process before direct publication."
    }

    $bookmarksPath = Join-Path $ProfilePath 'Bookmarks'
    if (-not (Test-Path -LiteralPath $bookmarksPath)) {
        throw "$BrowserName bookmarks were not found at '$bookmarksPath'."
    }

    return $bookmarksPath
}

function Publish-Direct(
    $Manifest,
    [string] $BrowserName,
    [string] $BookmarksPath) {
    $bookmarksPath = $BookmarksPath
    $bookmarks = Get-Content -LiteralPath $bookmarksPath -Raw | ConvertFrom-Json
    $maximumId = 0L
    foreach ($rootName in @('bookmark_bar', 'other', 'synced')) {
        $root = Get-PropertyValue $bookmarks.roots $rootName
        if ($null -ne $root) {
            $rootMaximum = Get-MaxBookmarkId $root
            if ($rootMaximum -gt $maximumId) {
                $maximumId = $rootMaximum
            }
        }
    }

    [long]$nextIdValue = $maximumId + 1
    $nextId = [ref]$nextIdValue
    $bookmarkBar = $bookmarks.roots.bookmark_bar
    $imported = @($bookmarkBar.children) |
        Where-Object { $_.type -eq 'folder' -and $_.name -eq 'Imported' } |
        Select-Object -First 1

    if ($null -eq $imported) {
        $importedSeed = [pscustomobject]@{ name = 'Imported'; links = @(); folders = @() }
        $imported = New-ChromeFolderNode $importedSeed $nextId
        $bookmarkBar.children = @($bookmarkBar.children) + @($imported)
    }

    $remaining = @($imported.children) |
        Where-Object { -not ($_.type -eq 'folder' -and $_.name -eq $Manifest.title) }
    $topicNode = New-TopicNode $Manifest $nextId
    $imported.children = @($remaining) + @($topicNode)
    $imported.date_modified = Get-ChromeTimestamp
    $bookmarkBar.date_modified = Get-ChromeTimestamp
    # Normalize the mixed PSCustomObject/ordered-hashtable tree before calculating
    # the checksum. PowerShell can enumerate those representations differently.
    $bookmarks.checksum = ''

    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $backupPath = "$bookmarksPath.learning-bookmarks-$timestamp.bak"
    Copy-Item -LiteralPath $bookmarksPath -Destination $backupPath

    $temporaryPath = "$bookmarksPath.learning-bookmarks.tmp"
    $json = $bookmarks | ConvertTo-Json -Depth 100
    [IO.File]::WriteAllText($temporaryPath, $json, [Text.UTF8Encoding]::new($false))

    $verification = Get-Content -LiteralPath $temporaryPath -Raw | ConvertFrom-Json
    $verification.checksum = Get-BookmarkChecksum $verification
    $json = $verification | ConvertTo-Json -Depth 100
    [IO.File]::WriteAllText($temporaryPath, $json, [Text.UTF8Encoding]::new($false))

    $roundTripVerification = Get-Content -LiteralPath $temporaryPath -Raw | ConvertFrom-Json
    if ((Get-BookmarkChecksum $roundTripVerification) -ne $roundTripVerification.checksum) {
        Remove-Item -LiteralPath $temporaryPath -Force
        throw "Generated $BrowserName bookmark checksum verification failed."
    }

    Move-Item -LiteralPath $temporaryPath -Destination $bookmarksPath -Force
    return [pscustomobject]@{
        Mode = 'Direct'
        Browser = $BrowserName
        BookmarksPath = $bookmarksPath
        BackupPath = $backupPath
        Topic = $Manifest.title
    }
}

$resolvedManifestPath = [IO.Path]::GetFullPath($ManifestPath)
$manifest = Get-Content -LiteralPath $resolvedManifestPath -Raw | ConvertFrom-Json

if ([string]::IsNullOrWhiteSpace($manifest.title)) {
    throw "Manifest property 'title' is required."
}

$overviewPath = Get-PropertyValue $manifest 'overviewPath'
if ([string]::IsNullOrWhiteSpace($overviewPath) -or -not (Test-Path -LiteralPath $overviewPath)) {
    throw "Manifest property 'overviewPath' must reference an existing local HTML file."
}

Update-OverviewBookmarkTree $manifest

if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Split-Path -Parent $resolvedManifestPath
}

$targets = @()
if ($Browser -in @('Chrome', 'Both')) {
    $targets += [pscustomobject]@{
        Name = 'Chrome'
        ProcessName = 'chrome'
        ProfilePath = $ChromeProfilePath
    }
}
if ($Browser -in @('Edge', 'Both')) {
    $targets += [pscustomobject]@{
        Name = 'Edge'
        ProcessName = 'msedge'
        ProfilePath = $EdgeProfilePath
    }
}

if ($Mode -eq 'Import') {
    [pscustomobject]@{
        Mode = 'Import'
        Browser = $Browser
        ImportPath = Write-ImportFile $manifest $OutputDirectory
        Topic = $manifest.title
    }
    return
}

if ($Mode -eq 'Direct') {
    $readyTargets = foreach ($target in $targets) {
        [pscustomobject]@{
            Target = $target
            BookmarksPath = Assert-BrowserReady $target.Name $target.ProcessName $target.ProfilePath
        }
    }

    foreach ($readyTarget in $readyTargets) {
        Publish-Direct `
            $manifest `
            $readyTarget.Target.Name `
            $readyTarget.BookmarksPath
    }
    return
}

$failures = [Collections.Generic.List[string]]::new()
foreach ($target in $targets) {
    try {
        $bookmarksPath = Assert-BrowserReady $target.Name $target.ProcessName $target.ProfilePath
        Publish-Direct $manifest $target.Name $bookmarksPath
    }
    catch {
        $failures.Add("$($target.Name): $($_.Exception.Message)")
    }
}

if ($failures.Count -gt 0) {
    [pscustomobject]@{
        Mode = 'ImportFallback'
        Browser = $Browser
        Reason = $failures -join ' '
        ImportPath = Write-ImportFile $manifest $OutputDirectory
        Topic = $manifest.title
    }
}
