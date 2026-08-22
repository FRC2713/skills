#!/usr/bin/env pwsh
<#
Read-only preflight for create-hawk-app on native Windows.
Installs nothing, changes nothing, prints no credentials.

The macOS/Linux/WSL twin is preflight.sh. The two are twins on purpose:
any check added to one belongs in the other, and $NodeMajor below must
stay equal to NODE_MAJOR there.

Runs on Windows PowerShell 5.1, which is present on every Windows 10 and
11 machine, as well as on PowerShell 7.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $Destination,

    [switch] $SkipNetwork
)

$NodeMajor = 24
$TemplateRepo = 'FRC2713/hawk-app-template'

try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

$results = New-Object System.Collections.ArrayList
$parent = $null

function Add-Result {
    param([string] $Level, [string] $Check, [string] $Detail)
    [void] $results.Add([pscustomobject]@{ Level = $Level; Check = $Check; Detail = $Detail })
}

function Get-ToolPath {
    param([string] $Name)
    $command = Get-Command $Name -CommandType Application -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($command) { return $command.Source }
    return $null
}

function Invoke-Tool {
    param([string] $Exe, [string[]] $Arguments)
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = (& $Exe @Arguments 2>&1 | Out-String).Trim()
        return [pscustomobject]@{ Ok = ($LASTEXITCODE -eq 0); Output = $output }
    } catch {
        return [pscustomobject]@{ Ok = $false; Output = '' }
    } finally {
        $ErrorActionPreference = $previous
    }
}

# --- destination path ----------------------------------------------------

if ($Destination.StartsWith('~')) { $Destination = $HOME + $Destination.Substring(1) }
if (-not [System.IO.Path]::IsPathRooted($Destination)) {
    $Destination = Join-Path (Get-Location).Path $Destination
}
$Destination = [System.IO.Path]::GetFullPath($Destination)

# --- computer ------------------------------------------------------------

$osCaption = $null
try { $osCaption = (Get-CimInstance Win32_OperatingSystem -ErrorAction Stop).Caption } catch { }
if (-not $osCaption) {
    try { $osCaption = (Get-WmiObject Win32_OperatingSystem -ErrorAction Stop).Caption } catch { }
}
if (-not $osCaption) { $osCaption = [System.Environment]::OSVersion.VersionString }

# Name the architecture the way Node names its downloads, so the label and
# the file to fetch cannot disagree.
$architecture = $env:PROCESSOR_ARCHITECTURE
if (-not $architecture) { $architecture = 'unknown' }
switch ($architecture) {
    'AMD64' { $archLabel = 'x64 (AMD64)' }
    'ARM64' { $archLabel = 'arm64 (ARM64)' }
    'x86'   { $archLabel = 'x86 (32-bit)' }
    default { $archLabel = $architecture }
}
Add-Result 'ready' 'Computer' "$($osCaption.Trim()), $archLabel, PowerShell $($PSVersionTable.PSVersion)"

# --- git -----------------------------------------------------------------

$gitPath = Get-ToolPath 'git'
if (-not $gitPath) {
    Add-Result 'attention' 'Git' 'Not installed'
} else {
    $git = Invoke-Tool $gitPath @('--version')
    if ($git.Ok) {
        Add-Result 'ready' 'Git' (($git.Output -split "`n")[0].Trim())
    } else {
        Add-Result 'attention' 'Git' "Found at $gitPath but it did not run"
    }
}

# --- node and npm --------------------------------------------------------

$nodePath = Get-ToolPath 'node'
if (-not $nodePath) {
    Add-Result 'attention' 'Node' "Not installed; Node $NodeMajor or newer is required"
} else {
    $node = Invoke-Tool $nodePath @('--version')
    $nodeVersion = ($node.Output -replace '^v', '').Trim()
    $nodeMajorFound = ($nodeVersion -split '\.')[0]
    if ($node.Ok -and $nodeMajorFound -match '^\d+$' -and [int] $nodeMajorFound -ge $NodeMajor) {
        Add-Result 'ready' 'Node' "$nodeVersion ($nodePath)"
    } elseif ($node.Ok -and $nodeMajorFound -match '^\d+$') {
        Add-Result 'attention' 'Node' "$nodeVersion is too old; Node $NodeMajor or newer is required"
    } else {
        Add-Result 'attention' 'Node' "Found at $nodePath but its version could not be read"
    }
}

$npmPath = Get-ToolPath 'npm'
if (-not $npmPath) {
    Add-Result 'attention' 'npm' 'Not installed; it comes bundled with Node'
} else {
    $npm = Invoke-Tool $npmPath @('--version')
    if ($npm.Ok -and $npm.Output) {
        Add-Result 'ready' 'npm' "$(($npm.Output -split "`n")[0].Trim()) ($npmPath)"
    } else {
        Add-Result 'attention' 'npm' "Found at $npmPath but it did not run"
    }
}

# --- github cli ----------------------------------------------------------

$ghAuthenticated = $false
$ghPath = Get-ToolPath 'gh'
if (-not $ghPath) {
    Add-Result 'attention' 'GitHub CLI' 'Not installed; required, because the template is a private repository'
} else {
    $auth = Invoke-Tool $ghPath @('auth', 'status', '--hostname', 'github.com')
    if ($auth.Ok) {
        $ghAuthenticated = $true
        $ghVersion = Invoke-Tool $ghPath @('--version')
        Add-Result 'ready' 'GitHub' "Signed in ($(($ghVersion.Output -split "`n")[0].Trim()))"
    } else {
        Add-Result 'attention' 'GitHub' 'GitHub CLI is installed but not signed in'
    }
}

# --- template access -----------------------------------------------------

if ($SkipNetwork) {
    Add-Result 'ready' 'Template access' 'Skipped by request'
} elseif (-not $ghAuthenticated) {
    Add-Result 'attention' 'Template access' 'Cannot be checked until the GitHub CLI is signed in'
} else {
    $template = Invoke-Tool $ghPath @('api', "repos/$TemplateRepo", '--jq', '.is_template')
    $isTemplate = $template.Output.Trim()
    if ($template.Ok -and $isTemplate -eq 'true') {
        Add-Result 'ready' 'Template access' "$TemplateRepo is reachable and marked as a template"
    } elseif ($template.Ok -and $isTemplate -eq 'false') {
        Add-Result 'attention' 'Template access' "$TemplateRepo is reachable but is not marked as a template; tell a maintainer"
    } else {
        Add-Result 'attention' 'Template access' "This GitHub account cannot reach $TemplateRepo; access must be granted by a maintainer"
    }
}

# --- destination ---------------------------------------------------------

if (Test-Path -LiteralPath $Destination) {
    if (-not (Test-Path -LiteralPath $Destination -PathType Container)) {
        Add-Result 'attention' 'Destination' "$Destination already exists and is not a folder; choose another path"
    } elseif (Get-ChildItem -LiteralPath $Destination -Force -ErrorAction SilentlyContinue | Select-Object -First 1) {
        Add-Result 'attention' 'Destination' "$Destination already contains files; nothing will be changed there, so choose another path"
    } else {
        Add-Result 'ready' 'Destination' "$Destination exists and is empty; it can be used"
    }
} else {
    $parent = Split-Path -Parent $Destination
    while ($parent -and -not (Test-Path -LiteralPath $parent)) {
        $next = Split-Path -Parent $parent
        if ($next -eq $parent) { break }
        $parent = $next
    }
    if ($parent -and (Test-Path -LiteralPath $parent)) {
        # Windows offers no cheap read-only writability test; the create step
        # surfaces a permissions problem, so report location rather than guess.
        Add-Result 'ready' 'Destination' "$Destination is new; $parent exists"
    } else {
        Add-Result 'attention' 'Destination' "$Destination cannot be created; no existing parent folder was found"
        $parent = $null
    }
}

if ($parent) {
    $root = [System.IO.Path]::GetPathRoot($parent)
    $free = $null
    try { $free = (New-Object System.IO.DriveInfo $root).AvailableFreeSpace } catch { }
    if ($null -ne $free) {
        $freeGb = [math]::Round($free / 1GB, 1)
        if ($free -ge 1GB) {
            Add-Result 'ready' 'Disk space' "$freeGb GB available on $root"
        } else {
            Add-Result 'attention' 'Disk space' "Only $freeGb GB available on $root; about 1 GB is needed"
        }
    } else {
        Add-Result 'attention' 'Disk space' "Free space on $root could not be measured"
    }
}

foreach ($oneDrive in @($env:OneDrive, $env:OneDriveCommercial, $env:OneDriveConsumer)) {
    if ($oneDrive -and $Destination.StartsWith($oneDrive, [System.StringComparison]::OrdinalIgnoreCase)) {
        Add-Result 'attention' 'OneDrive' "$Destination is inside a synced OneDrive folder; syncing thousands of package files breaks installs. Choose a folder outside OneDrive."
        break
    }
}

# --- report --------------------------------------------------------------

Write-Output "Hawk app preflight for $Destination"
Write-Output ''
foreach ($level in @('ready', 'attention')) {
    $items = @($results | Where-Object { $_.Level -eq $level })
    if ($items.Count -eq 0) { continue }
    if ($level -eq 'ready') { Write-Output 'Ready:' } else { Write-Output 'Needs attention:' }
    foreach ($item in $items) {
        if ($level -eq 'ready') { $marker = [char] 0x2713 } else { $marker = '!' }
        Write-Output "  $marker $($item.Check): $($item.Detail)"
    }
    Write-Output ''
}

if (@($results | Where-Object { $_.Level -eq 'attention' }).Count -gt 0) { exit 1 }
exit 0
