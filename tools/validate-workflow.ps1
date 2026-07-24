[CmdletBinding()]
param(
    [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($RepositoryRoot)) {
    $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}

$RepositoryRoot = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$failures = New-Object 'System.Collections.Generic.List[string]'

function Add-Failure {
    param([string]$Message)
    $script:failures.Add($Message)
}

function Get-RepositoryPath {
    param([string]$RelativePath)
    return Join-Path $RepositoryRoot ($RelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
}

function Read-Utf8Text {
    param([string]$Path)
    return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
}

function Get-YamlScalar {
    param(
        [string]$RelativePath,
        [string]$Key
    )

    $path = Get-RepositoryPath $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Add-Failure "Missing required file: $RelativePath"
        return $null
    }

    $text = Read-Utf8Text $path
    $pattern = '(?m)^' + [regex]::Escape($Key) + ':\s*(?<value>[^\s#]+)\s*(?:#.*)?$'
    $match = [regex]::Match($text, $pattern)
    if (-not $match.Success) {
        Add-Failure "Missing or invalid '$Key' in $RelativePath"
        return $null
    }

    return $match.Groups['value'].Value.Trim('"', "'")
}

function Test-LocalReference {
    param(
        [string]$SourcePath,
        [string]$Reference,
        [string]$Kind
    )

    $target = $Reference.Trim()
    if ($target.StartsWith('<') -and $target.Contains('>')) {
        $target = $target.Substring(1, $target.IndexOf('>') - 1)
    }
    elseif ($target -match '\s') {
        $target = ($target -split '\s+', 2)[0]
    }

    if ([string]::IsNullOrWhiteSpace($target) -or
        $target.StartsWith('#') -or
        $target -match '^(?i:https?|mailto|tel|data):' -or
        $target -match '[<>*?]') {
        return
    }

    $target = ($target -split '#', 2)[0]
    if ([string]::IsNullOrWhiteSpace($target)) {
        return
    }

    if ($target.StartsWith('.ai/')) {
        $resolved = Get-RepositoryPath $target
    }
    else {
        $sourceDirectory = Split-Path -Parent $SourcePath
        $resolved = Join-Path $sourceDirectory ($target -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    }

    if (-not (Test-Path -LiteralPath $resolved)) {
        $displaySource = $SourcePath.Substring($RepositoryRoot.Length).TrimStart('\', '/')
        Add-Failure "Broken $Kind reference in ${displaySource}: $Reference"
    }
}

$requiredPaths = @(
    'README.md',
    '.ai/BOOTSTRAP.md',
    '.ai/WORKFLOW.md',
    '.ai/evals/README.md',
    '.ai/evals/SCORECARD.md',
    '.ai/maintenance/CHANGELOG.md',
    '.ai/maintenance/release.yaml',
    '.ai/maintenance/update-state.yaml',
    '.ai/maintenance/managed-paths.yaml',
    '.ai/shared/PROJECT.md',
    '.ai/shared/SYSTEM_ARCHITECTURE.md',
    '.ai/shared/knowledge/manifest.yaml',
    '.ai/integration/queue.yaml',
    '.gitignore',
    'tools/validate-workflow.ps1',
    '.github/workflows/validate.yml'
)

foreach ($relativePath in $requiredPaths) {
    if (-not (Test-Path -LiteralPath (Get-RepositoryPath $relativePath))) {
        Add-Failure "Missing required path: $relativePath"
    }
}

$releaseVersion = Get-YamlScalar '.ai/maintenance/release.yaml' 'workflow_version'
$installedVersion = Get-YamlScalar '.ai/maintenance/update-state.yaml' 'installed_version'
$scorecardVersion = Get-YamlScalar '.ai/evals/SCORECARD.md' 'workflow_version'

if ($null -ne $releaseVersion -and $releaseVersion -notmatch '^manual-v\d+\.\d+$') {
    Add-Failure "Invalid release version format: $releaseVersion"
}
if ($null -ne $releaseVersion -and $null -ne $installedVersion -and $releaseVersion -ne $installedVersion) {
    Add-Failure "Version mismatch: release=$releaseVersion installed=$installedVersion"
}
if ($null -ne $scorecardVersion -and $scorecardVersion -ne 'null') {
    Add-Failure "SCORECARD.md is a reusable template and must keep workflow_version: null"
}

$projectStatus = Get-YamlScalar '.ai/shared/PROJECT.md' 'status'
$architectureStatus = Get-YamlScalar '.ai/shared/SYSTEM_ARCHITECTURE.md' 'status'
$knowledgeStatus = Get-YamlScalar '.ai/shared/knowledge/manifest.yaml' 'status'
$integrationStatus = Get-YamlScalar '.ai/integration/queue.yaml' 'status'
$integrationItems = Get-YamlScalar '.ai/integration/queue.yaml' 'items'
$localUpdateSource = Get-YamlScalar '.ai/maintenance/update-state.yaml' 'source'

if ($null -ne $projectStatus -and $projectStatus -ne 'uninitialized') {
    Add-Failure "Canonical PROJECT.md must remain uninitialized, found: $projectStatus"
}
if ($null -ne $architectureStatus -and $architectureStatus -ne 'uninitialized') {
    Add-Failure "Canonical SYSTEM_ARCHITECTURE.md must remain uninitialized, found: $architectureStatus"
}
if ($null -ne $knowledgeStatus -and $knowledgeStatus -ne 'uninitialized') {
    Add-Failure "Canonical Knowledge manifest must remain uninitialized, found: $knowledgeStatus"
}
if ($null -ne $integrationStatus -and $integrationStatus -ne 'idle') {
    Add-Failure "Canonical Integration queue must remain idle, found: $integrationStatus"
}
if ($null -ne $integrationItems -and $integrationItems -ne '[]') {
    Add-Failure "Canonical Integration queue must contain no runtime items"
}
if ($null -ne $localUpdateSource -and $localUpdateSource -ne 'null') {
    Add-Failure "Canonical update-state source must remain null"
}

$laneRoot = Get-RepositoryPath '.ai/lanes'
if (Test-Path -LiteralPath $laneRoot -PathType Container) {
    $runtimeLanes = @(Get-ChildItem -LiteralPath $laneRoot -Directory | Where-Object { $_.Name -ne '_template' })
    foreach ($runtimeLane in $runtimeLanes) {
        Add-Failure "Canonical source contains runtime Lane: .ai/lanes/$($runtimeLane.Name)"
    }
}

foreach ($artifactDirectory in @('.ai/integration/requests', '.ai/integration/reviews')) {
    $artifactRoot = Get-RepositoryPath $artifactDirectory
    if (Test-Path -LiteralPath $artifactRoot -PathType Container) {
        $runtimeArtifacts = @(Get-ChildItem -LiteralPath $artifactRoot -File | Where-Object { $_.Name -ne 'README.md' })
        foreach ($runtimeArtifact in $runtimeArtifacts) {
            Add-Failure "Canonical source contains runtime Integration artifact: $artifactDirectory/$($runtimeArtifact.Name)"
        }
    }
}

$gitDirectory = Get-RepositoryPath '.git'
if (Test-Path -LiteralPath $gitDirectory) {
    $trackedObservations = @(& git -C $RepositoryRoot ls-files -- '.ai/maintenance/observations/OBS-*.yaml')
    if ($LASTEXITCODE -eq 0) {
        foreach ($trackedObservation in $trackedObservations) {
            if (-not [string]::IsNullOrWhiteSpace($trackedObservation)) {
                Add-Failure "Canonical Git distribution tracks installation-specific Observation: $trackedObservation"
            }
        }
    }
}

$changelogPath = Get-RepositoryPath '.ai/maintenance/CHANGELOG.md'
if (Test-Path -LiteralPath $changelogPath -PathType Leaf) {
    $changelog = Read-Utf8Text $changelogPath
    $latestHeading = [regex]::Match($changelog, '(?m)^##\s+(?<version>manual-v\d+\.\d+)\s+\u2014')
    if (-not $latestHeading.Success) {
        Add-Failure 'CHANGELOG.md has no valid release heading'
    }
    elseif ($null -ne $releaseVersion -and $latestHeading.Groups['version'].Value -ne $releaseVersion) {
        Add-Failure "Version mismatch: release=$releaseVersion changelog=$($latestHeading.Groups['version'].Value)"
    }
}

$markdownFiles = @(Get-ChildItem -LiteralPath $RepositoryRoot -Recurse -File -Filter '*.md' |
    Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' })
$referenceCount = 0

foreach ($file in $markdownFiles) {
    $text = Read-Utf8Text $file.FullName
    $fenceCount = [regex]::Matches($text, '(?m)^[ \t]*```').Count
    if (($fenceCount % 2) -ne 0) {
        $displayPath = $file.FullName.Substring($RepositoryRoot.Length).TrimStart('\', '/')
        Add-Failure "Unbalanced Markdown code fences: $displayPath"
    }

    foreach ($match in [regex]::Matches($text, '!?\[[^\]\r\n]*\]\((?<target>[^)\r\n]+)\)')) {
        $referenceCount++
        Test-LocalReference $file.FullName $match.Groups['target'].Value 'Markdown link'
    }

    foreach ($match in [regex]::Matches($text, '(?<![A-Za-z0-9_])(?<target>\.ai/[A-Za-z0-9_.\-/<*>]+)')) {
        $target = $match.Groups['target'].Value.TrimEnd('.', ',', ':', ';')
        if ($target -match '[<>*]') {
            continue
        }
        $referenceCount++
        Test-LocalReference $file.FullName $target 'repository path'
    }
}

if ($failures.Count -gt 0) {
    Write-Output "FAIL workflow validation ($($failures.Count) issue(s))"
    foreach ($failure in $failures) {
        Write-Output "- $failure"
    }
    exit 1
}

Write-Output "PASS workflow=$releaseVersion markdown=$($markdownFiles.Count) references=$referenceCount"
