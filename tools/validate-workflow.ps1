[CmdletBinding()]
param(
    [string]$RepositoryRoot,
    [switch]$RequireReleaseEvidence
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

function Get-RepositoryRelativePath {
    param([string]$Path)

    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $fullRoot = [System.IO.Path]::GetFullPath($RepositoryRoot)
    $comparison = if ([System.IO.Path]::DirectorySeparatorChar -eq [char]92) {
        [System.StringComparison]::OrdinalIgnoreCase
    }
    else {
        [System.StringComparison]::Ordinal
    }

    if ($fullPath.Equals($fullRoot, $comparison)) {
        return '.'
    }

    $rootPrefix = $fullRoot
    if (-not $rootPrefix.EndsWith([string][System.IO.Path]::DirectorySeparatorChar) -and
        -not $rootPrefix.EndsWith([string][System.IO.Path]::AltDirectorySeparatorChar)) {
        $rootPrefix += [System.IO.Path]::DirectorySeparatorChar
    }

    if (-not $fullPath.StartsWith($rootPrefix, $comparison)) {
        Add-Failure "Path is outside the repository root: $fullPath"
        return ($fullPath -replace '\\', '/')
    }

    return ($fullPath.Substring($rootPrefix.Length) -replace '\\', '/')
}

function Read-Utf8Text {
    param([string]$Path)
    return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
}

function Get-YamlScalarFromText {
    param(
        [string]$Text,
        [string]$Key,
        [switch]$AnyIndent
    )

    $prefix = if ($AnyIndent) { '^\s*' } else { '^' }
    $pattern = '(?m)' + $prefix + [regex]::Escape($Key) + ':\s*(?<value>[^\s#]+)\s*(?:#.*)?$'
    $match = [regex]::Match($Text, $pattern)
    if (-not $match.Success) {
        return $null
    }
    return $match.Groups['value'].Value.Trim('"', "'")
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

    $value = Get-YamlScalarFromText (Read-Utf8Text $path) $Key
    if ($null -eq $value) {
        Add-Failure "Missing or invalid '$Key' in $RelativePath"
        return $null
    }
    return $value
}

function Get-YamlScalarAnyIndent {
    param(
        [string]$RelativePath,
        [string]$Key
    )

    $path = Get-RepositoryPath $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Add-Failure "Missing required file: $RelativePath"
        return $null
    }
    $value = Get-YamlScalarFromText (Read-Utf8Text $path) $Key -AnyIndent
    if ($null -eq $value) {
        Add-Failure "Missing or invalid '$Key' in $RelativePath"
        return $null
    }
    return $value
}

function Get-GitText {
    param([string[]]$Arguments)

    $previousErrorAction = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $output = @()
    $exitCode = 1
    try {
        $output = @(& git -C $RepositoryRoot @Arguments 2>$null)
        $exitCode = $LASTEXITCODE
    }
    catch {
        $exitCode = 1
    }
    finally {
        $ErrorActionPreference = $previousErrorAction
    }
    if ($exitCode -ne 0) {
        return $null
    }
    return ($output -join "`n").Trim()
}

function Invoke-GitExitCode {
    param([string[]]$Arguments)

    $previousErrorAction = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $exitCode = 1
    try {
        $null = & git -C $RepositoryRoot @Arguments 2>$null
        $exitCode = $LASTEXITCODE
    }
    catch {
        $exitCode = 1
    }
    finally {
        $ErrorActionPreference = $previousErrorAction
    }
    return $exitCode
}

function Get-MarkdownTableRow {
    param(
        [string]$Text,
        [string]$Label
    )

    $pattern = '(?im)^\|\s*`?' + [regex]::Escape($Label) +
        '`?\s*\|\s*(?<value>[^|\r\n]*?)\s*\|\s*(?<evidence>[^|\r\n]*?)\s*\|\s*$'
    return [regex]::Match($Text, $pattern)
}

function Get-YamlListSection {
    param(
        [string]$RelativePath,
        [string]$Key
    )

    $path = Get-RepositoryPath $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Add-Failure "Missing required file: $RelativePath"
        return @()
    }

    $lines = (Read-Utf8Text $path) -split '\r?\n'
    $start = -1
    for ($index = 0; $index -lt $lines.Count; $index++) {
        if ($lines[$index] -match ('^' + [regex]::Escape($Key) + ':\s*$')) {
            $start = $index + 1
            break
        }
    }
    if ($start -lt 0) {
        Add-Failure "Missing YAML list '$Key' in $RelativePath"
        return @()
    }

    $values = @()
    for ($index = $start; $index -lt $lines.Count; $index++) {
        $line = $lines[$index]
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }
        $itemMatch = [regex]::Match($line, '^\s+-\s+(?<value>[^#]+?)(?:\s+#.*)?$')
        if ($itemMatch.Success) {
            $values += $itemMatch.Groups['value'].Value.Trim().Trim('"', "'")
            continue
        }
        if ($line -match '^\S') {
            break
        }
        Add-Failure "Invalid YAML list item in ${RelativePath}: $line"
    }
    return $values
}

function Test-PathPattern {
    param(
        [string]$Path,
        [string]$Pattern
    )

    $normalizedPath = $Path -replace '\\', '/'
    $normalizedPattern = $Pattern -replace '\\', '/'
    if ($normalizedPattern -match '<runtime-lane>' -and
        $normalizedPath.StartsWith('.ai/lanes/_template/', [System.StringComparison]::OrdinalIgnoreCase)) {
        return $false
    }
    if (($normalizedPattern -match '<request-artifact>|<review-artifact>') -and
        $normalizedPath.EndsWith('/README.md', [System.StringComparison]::OrdinalIgnoreCase)) {
        return $false
    }

    $regex = [regex]::Escape($normalizedPattern)
    $regex = $regex -replace '\\\*\\\*', '.*'
    $regex = $regex -replace '\\\*', '[^/]*'
    $regex = $regex -replace '<[^>]+>', '[^/]+'
    return $normalizedPath -match ('^' + $regex + '$')
}

function Assert-YamlScalar {
    param(
        [string]$RelativePath,
        [string]$Key,
        [string]$Expected,
        [switch]$AnyIndent
    )

    $actual = if ($AnyIndent) {
        Get-YamlScalarAnyIndent $RelativePath $Key
    }
    else {
        Get-YamlScalar $RelativePath $Key
    }
    if ($null -ne $actual -and $actual -ne $Expected) {
        Add-Failure "Unexpected '$Key' in ${RelativePath}: expected=$Expected actual=$actual"
    }
}

function Get-MarkdownFrontMatterScalar {
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
    $frontMatterMatch = [regex]::Match(
        $text,
        '\A---[ \t]*\r?\n(?<body>.*?)\r?\n---[ \t]*(?:\r?\n|\z)',
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )
    if (-not $frontMatterMatch.Success) {
        Add-Failure "Missing or invalid Markdown front matter in $RelativePath"
        return $null
    }

    $pattern = '(?m)^' + [regex]::Escape($Key) + ':\s*(?<value>[^\s#]+)\s*(?:#.*)?$'
    $match = [regex]::Match($frontMatterMatch.Groups['body'].Value, $pattern)
    if (-not $match.Success) {
        Add-Failure "Missing or invalid front-matter '$Key' in $RelativePath"
        return $null
    }

    return $match.Groups['value'].Value.Trim('"', "'")
}

function Get-MarkdownFrontMatterList {
    param(
        [string]$RelativePath,
        [string]$Key
    )

    $path = Get-RepositoryPath $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Add-Failure "Missing required file: $RelativePath"
        return @()
    }

    $text = Read-Utf8Text $path
    $frontMatterMatch = [regex]::Match(
        $text,
        '\A---[ \t]*\r?\n(?<body>.*?)\r?\n---[ \t]*(?:\r?\n|\z)',
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )
    if (-not $frontMatterMatch.Success) {
        Add-Failure "Missing or invalid Markdown front matter in $RelativePath"
        return @()
    }

    $lines = $frontMatterMatch.Groups['body'].Value -split '\r?\n'
    $keyPattern = '^' + [regex]::Escape($Key) + ':\s*(?<empty>\[\])?\s*$'
    for ($index = 0; $index -lt $lines.Count; $index++) {
        $keyMatch = [regex]::Match($lines[$index], $keyPattern)
        if (-not $keyMatch.Success) {
            continue
        }
        if ($keyMatch.Groups['empty'].Success) {
            return @()
        }

        $values = @()
        for ($itemIndex = $index + 1; $itemIndex -lt $lines.Count; $itemIndex++) {
            $itemMatch = [regex]::Match(
                $lines[$itemIndex],
                '^[ \t]+-\s*(?<value>[^\s#]+)\s*(?:#.*)?$'
            )
            if (-not $itemMatch.Success) {
                break
            }
            $values += $itemMatch.Groups['value'].Value.Trim('"', "'")
        }

        if ($values.Count -eq 0) {
            Add-Failure "Missing or invalid front-matter list '$Key' in $RelativePath"
        }
        return $values
    }

    Add-Failure "Missing front-matter list '$Key' in $RelativePath"
    return @()
}

function Test-ManualVersionAtLeast {
    param(
        [string]$Version,
        [string]$MinimumVersion
    )

    $versionMatch = [regex]::Match($Version, '^manual-v(?<major>\d+)\.(?<minor>\d+)$')
    $minimumMatch = [regex]::Match($MinimumVersion, '^manual-v(?<major>\d+)\.(?<minor>\d+)$')
    if (-not $versionMatch.Success -or -not $minimumMatch.Success) {
        return $false
    }

    $major = [int]$versionMatch.Groups['major'].Value
    $minor = [int]$versionMatch.Groups['minor'].Value
    $minimumMajor = [int]$minimumMatch.Groups['major'].Value
    $minimumMinor = [int]$minimumMatch.Groups['minor'].Value
    return $major -gt $minimumMajor -or
        ($major -eq $minimumMajor -and $minor -ge $minimumMinor)
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
        $displaySource = Get-RepositoryRelativePath $SourcePath
        Add-Failure "Broken $Kind reference in ${displaySource}: $Reference"
    }
}

$sourceRequiredPaths = @(
    'README.md',
    'LICENSE',
    '.gitignore',
    '.gitattributes',
    'tools/validate-workflow.ps1',
    'tools/test-validation.ps1',
    '.github/workflows/validate.yml',
    '.github/workflows/release-evidence.yml',
    'maintenance/RELEASE.md',
    'evals/README.md',
    'evals/runs/.gitkeep'
)

foreach ($relativePath in $sourceRequiredPaths) {
    if (-not (Test-Path -LiteralPath (Get-RepositoryPath $relativePath))) {
        Add-Failure "Missing source-only repository path: $relativePath"
    }
}

$ciWorkflowContracts = @(
    @{
        Path = '.github/workflows/validate.yml'
        Required = @('fetch-depth: 0')
        Forbidden = @('-RequireReleaseEvidence')
    },
    @{
        Path = '.github/workflows/release-evidence.yml'
        Required = @('fetch-depth: 0', '-RequireReleaseEvidence')
        Forbidden = @()
    }
)

foreach ($contract in $ciWorkflowContracts) {
    $workflowPath = Get-RepositoryPath $contract.Path
    if (-not (Test-Path -LiteralPath $workflowPath -PathType Leaf)) {
        continue
    }

    $workflowText = Read-Utf8Text $workflowPath
    foreach ($token in $contract.Required) {
        if (-not $workflowText.Contains($token)) {
            Add-Failure "CI workflow is missing required token: path=$($contract.Path) token=$token"
        }
    }
    foreach ($token in $contract.Forbidden) {
        if ($workflowText.Contains($token)) {
            Add-Failure "CI workflow contains forbidden token: path=$($contract.Path) token=$token"
        }
    }
}

$inventoryRelativePath = '.ai/maintenance/distribution-inventory.txt'
$inventoryPath = Get-RepositoryPath $inventoryRelativePath
$distributionInventory = @()
if (Test-Path -LiteralPath $inventoryPath -PathType Leaf) {
    $inventorySeen = @{}
    foreach ($line in (Read-Utf8Text $inventoryPath) -split '\r?\n') {
        $entry = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($entry) -or $entry.StartsWith('#')) {
            continue
        }
        if ($entry -notmatch '^\.ai/[A-Za-z0-9_.\-/]+$') {
            Add-Failure "Invalid distribution inventory path: $entry"
            continue
        }
        if ($inventorySeen.ContainsKey($entry)) {
            Add-Failure "Duplicate distribution inventory path: $entry"
            continue
        }
        $inventorySeen[$entry] = $true
        $distributionInventory += $entry
        if (-not (Test-Path -LiteralPath (Get-RepositoryPath $entry) -PathType Leaf)) {
            Add-Failure "Missing distribution inventory file: $entry"
        }
    }
    if ($distributionInventory.Count -eq 0) {
        Add-Failure 'Distribution inventory contains no required files'
    }
}
else {
    Add-Failure "Missing distribution inventory: $inventoryRelativePath"
}

$workflowPath = Get-RepositoryPath '.ai/WORKFLOW.md'
$artifactAuthorityPath = Get-RepositoryPath '.ai/contracts/ARTIFACT_AUTHORITY.md'
$authorityTablePattern = '(?m)^\| Fact \| Authority \|\s*$'
$conflictActionsPattern = '(?m)^## Conflict actions\s*$'
if (Test-Path -LiteralPath $workflowPath -PathType Leaf) {
    $workflowText = Read-Utf8Text $workflowPath
    if ([regex]::IsMatch($workflowText, $authorityTablePattern) -or
        [regex]::IsMatch($workflowText, $conflictActionsPattern)) {
        Add-Failure 'WORKFLOW.md must point to ARTIFACT_AUTHORITY.md instead of restating authority or conflict actions'
    }
}
if (Test-Path -LiteralPath $artifactAuthorityPath -PathType Leaf) {
    $artifactAuthorityText = Read-Utf8Text $artifactAuthorityPath
    $artifactAuthorityTableCount = [regex]::Matches($artifactAuthorityText, $authorityTablePattern).Count
    if ($artifactAuthorityTableCount -ne 1) {
        Add-Failure "ARTIFACT_AUTHORITY.md must contain exactly one authority table, found: $artifactAuthorityTableCount"
    }
    $conflictActionsCount = [regex]::Matches($artifactAuthorityText, $conflictActionsPattern).Count
    if ($conflictActionsCount -ne 1) {
        Add-Failure "ARTIFACT_AUTHORITY.md must contain exactly one Conflict actions section, found: $conflictActionsCount"
    }
}

$stateContractPath = Get-RepositoryPath '.ai/contracts/STATE.md'
if (Test-Path -LiteralPath $stateContractPath -PathType Leaf) {
    $stateContractText = Read-Utf8Text $stateContractPath
    $expectedPhases = @(
        'uninitialized',
        'discovery',
        'synced',
        'design',
        'ready_to_build',
        'building',
        'ready_to_review',
        'reviewing',
        'accepted',
        'integration'
    )
    $declaredPhases = @([regex]::Matches(
            $stateContractText,
            '(?m)^\| `(?<phase>[a-z_]+)` \| `(?:idle|active)`'
        ) | ForEach-Object { $_.Groups['phase'].Value })
    foreach ($phase in $expectedPhases) {
        if ($declaredPhases -notcontains $phase) {
            Add-Failure "STATE.md is missing a normal phase/status declaration: $phase"
        }
    }
    foreach ($phase in $declaredPhases) {
        if ($expectedPhases -notcontains $phase) {
            Add-Failure "STATE.md declares an unsupported Lane phase: $phase"
        }
    }
}

$roleTransitionRequirements = @{
    '.ai/roles/KNOWLEDGE_MAINTAINER.md' = @('uninitialized/idle', 'discovery/active')
    '.ai/roles/ARCHITECT.md' = @('synced|accepted', 'design/active')
    '.ai/roles/BUILDER.md' = @('ready_to_build/active', 'building/active')
    '.ai/roles/REVIEWER.md' = @('ready_to_review/active', 'reviewing/active')
}
foreach ($rolePath in $roleTransitionRequirements.Keys) {
    $absoluteRolePath = Get-RepositoryPath $rolePath
    if (Test-Path -LiteralPath $absoluteRolePath -PathType Leaf) {
        $roleText = Read-Utf8Text $absoluteRolePath
        foreach ($transitionToken in $roleTransitionRequirements[$rolePath]) {
            if (-not $roleText.Contains($transitionToken)) {
                Add-Failure "Role contract is missing a lifecycle entry token: role=$rolePath token=$transitionToken"
            }
        }
    }
}

# These string checks are only lightweight smoke tests. Prefer structured
# schema/FSM validation whenever a contract can be parsed deterministically.
$contractTokenRequirements = @{
    '.ai/reference/OPERATIONS.md' = @('Knowledge required/checkpoint', 'single-main defer/none', 'non-main')
    '.ai/contracts/BUILD_RESULT.md' = @('candidate_fingerprint', 'canonical UTF-8/LF manifest')
    '.ai/contracts/REVIEW_RESULT.md' = @('reviewed_fingerprint', 'immediately before PASS')
    '.ai/contracts/STATE.md' = @('Integration queue', 'reviewed_fingerprint')
}
foreach ($contractPath in $contractTokenRequirements.Keys) {
    $absoluteContractPath = Get-RepositoryPath $contractPath
    if (Test-Path -LiteralPath $absoluteContractPath -PathType Leaf) {
        $contractText = Read-Utf8Text $absoluteContractPath
        foreach ($requiredToken in $contractTokenRequirements[$contractPath]) {
            if (-not $contractText.Contains($requiredToken)) {
                Add-Failure "Contract is missing a required invariant token: path=$contractPath token=$requiredToken"
            }
        }
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

Assert-YamlScalar '.ai/maintenance/release.yaml' 'schema_version' '1'
Assert-YamlScalar '.ai/maintenance/update-state.yaml' 'schema_version' '1'
Assert-YamlScalar '.ai/maintenance/managed-paths.yaml' 'schema_version' '1'
Assert-YamlScalar '.ai/integration/queue.yaml' 'schema_version' '1'
Assert-YamlScalar '.ai/lanes/_template/lane.yaml' 'schema_version' '3'
Assert-YamlScalar '.ai/lanes/_template/state.yaml' 'schema_version' '3'
foreach ($knowledgeFile in @(
        '.ai/shared/knowledge/manifest.yaml',
        '.ai/shared/knowledge/project.yaml',
        '.ai/shared/knowledge/glossary.yaml'
    )) {
    Assert-YamlScalar $knowledgeFile 'schema_version' '2'
    Assert-YamlScalar $knowledgeFile 'status' 'uninitialized'
}
Assert-YamlScalar '.ai/maintenance/release.yaml' 'lane_schema' '[3]' -AnyIndent
Assert-YamlScalar '.ai/maintenance/release.yaml' 'lane_state_schema' '[3]' -AnyIndent
Assert-YamlScalar '.ai/maintenance/release.yaml' 'knowledge_schema' '[2]' -AnyIndent
Assert-YamlScalar '.ai/maintenance/release.yaml' 'maintenance_schema' '[1]' -AnyIndent
Assert-YamlScalar '.ai/maintenance/release.yaml' 'eval_schema' '[2]' -AnyIndent
Assert-YamlScalar '.ai/lanes/_template/lane.yaml' 'status' 'uninitialized'
Assert-YamlScalar '.ai/lanes/_template/state.yaml' 'phase' 'uninitialized'
Assert-YamlScalar '.ai/lanes/_template/state.yaml' 'status' 'idle'
Assert-YamlScalar '.ai/lanes/_template/state.yaml' 'action' 'initialize_lane' -AnyIndent
Assert-YamlScalar '.ai/shared/knowledge/project.yaml' 'entrypoints' '[]'
Assert-YamlScalar '.ai/shared/knowledge/glossary.yaml' 'terms' '[]'

$templateStatePath = Get-RepositoryPath '.ai/lanes/_template/state.yaml'
if (Test-Path -LiteralPath $templateStatePath -PathType Leaf) {
    $templateStateText = Read-Utf8Text $templateStatePath
    foreach ($legacyStateKey in @('active_feature', 'active_task', 'open_risks')) {
        if ([regex]::IsMatch($templateStateText, '(?m)^' + [regex]::Escape($legacyStateKey) + ':')) {
            Add-Failure "Canonical template state contains removed schema-2 key: $legacyStateKey"
        }
    }
    foreach ($requiredStatePattern in @(
            '(?ms)^next:\s*\r?\n\s+role:\s*knowledge_maintainer\b',
            '(?ms)^knowledge_sync:\s*\r?\n\s+status:\s*clean\b\s*(?:#.*)?\r?\n\s+pending_reviews:\s*\[\]'
        )) {
        if (-not [regex]::IsMatch($templateStateText, $requiredStatePattern)) {
            Add-Failure "Canonical template state is missing required initial structure: $requiredStatePattern"
        }
    }
}

$templateLanePath = Get-RepositoryPath '.ai/lanes/_template/lane.yaml'
if (Test-Path -LiteralPath $templateLanePath -PathType Leaf) {
    $templateLaneText = Read-Utf8Text $templateLanePath
    foreach ($legacyLaneKey in @('downstream_lanes', 'verification', 'last_validated')) {
        if ([regex]::IsMatch($templateLaneText, '(?m)^\s*' + [regex]::Escape($legacyLaneKey) + ':')) {
            Add-Failure "Canonical template Lane contains removed schema-2 key: $legacyLaneKey"
        }
    }
}

$scorecardSchema = Get-MarkdownFrontMatterScalar '.ai/evals/SCORECARD.md' 'schema_version'
$scorecardStatus = Get-MarkdownFrontMatterScalar '.ai/evals/SCORECARD.md' 'status'
$scorecardResult = Get-MarkdownFrontMatterScalar '.ai/evals/SCORECARD.md' 'result'
if ($scorecardSchema -ne '2' -or $scorecardStatus -ne 'draft' -or $scorecardResult -ne 'pending') {
    Add-Failure "SCORECARD.md must remain a schema-2 draft/pending reusable template"
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

$managedPatterns = @(Get-YamlListSection '.ai/maintenance/managed-paths.yaml' 'managed')
$preservedPatterns = @(Get-YamlListSection '.ai/maintenance/managed-paths.yaml' 'preserved')
if ($managedPatterns.Count -eq 0 -or $preservedPatterns.Count -eq 0) {
    Add-Failure 'managed-paths.yaml must declare non-empty managed and preserved lists'
}
else {
    $aiRoot = Get-RepositoryPath '.ai'
    foreach ($sourceFile in @(Get-ChildItem -LiteralPath $aiRoot -Recurse -File -Force)) {
        $relativeSourceFile = Get-RepositoryRelativePath $sourceFile.FullName
        $managedMatch = $false
        foreach ($pattern in $managedPatterns) {
            if (Test-PathPattern $relativeSourceFile $pattern) {
                $managedMatch = $true
                break
            }
        }
        $preservedMatch = $false
        foreach ($pattern in $preservedPatterns) {
            if (Test-PathPattern $relativeSourceFile $pattern) {
                $preservedMatch = $true
                break
            }
        }

        if ($managedMatch -and $preservedMatch) {
            Add-Failure "Distribution file matches both managed and preserved paths: $relativeSourceFile"
        }
        elseif (-not $managedMatch -and -not $preservedMatch) {
            Add-Failure "Distribution file is unclassified by managed-paths.yaml: $relativeSourceFile"
        }
    }
}

foreach ($runtimeKnowledgeDirectory in @(
        '.ai/shared/knowledge/modules',
        '.ai/shared/knowledge/features',
        '.ai/shared/knowledge/interfaces',
        '.ai/shared/knowledge/rules',
        '.ai/shared/knowledge/documents'
    )) {
    $runtimeKnowledgeRoot = Get-RepositoryPath $runtimeKnowledgeDirectory
    if (Test-Path -LiteralPath $runtimeKnowledgeRoot -PathType Container) {
        foreach ($runtimeKnowledgeFile in @(Get-ChildItem -LiteralPath $runtimeKnowledgeRoot -Recurse -File -Force)) {
            $relativeRuntimeKnowledge = Get-RepositoryRelativePath $runtimeKnowledgeFile.FullName
            Add-Failure "Canonical distribution contains project Knowledge content: $relativeRuntimeKnowledge"
        }
    }
}

$installedEvalRoot = Get-RepositoryPath '.ai/evals/runs'
if (Test-Path -LiteralPath $installedEvalRoot -PathType Container) {
    foreach ($installedEval in @(Get-ChildItem -LiteralPath $installedEvalRoot -File -Filter '*.md')) {
        Add-Failure "Installable .ai contains a canonical/source Eval record: .ai/evals/runs/$($installedEval.Name)"
    }
}

$installedMaintainPath = Get-RepositoryPath '.ai/maintenance/MAINTAIN.md'
if (Test-Path -LiteralPath $installedMaintainPath -PathType Leaf) {
    $installedMaintainText = Read-Utf8Text $installedMaintainPath
    foreach ($sourceOnlyHeading in @(
            '## Collect from installed copies',
            '## BUILD_RELEASE_COPY',
            '## FINALIZE_RELEASE_EVAL',
            '## Triage and release'
        )) {
        if ($installedMaintainText.Contains($sourceOnlyHeading)) {
            Add-Failure "Installable MAINTAIN.md contains source-only release procedure: $sourceOnlyHeading"
        }
    }
}

$releasePath = Get-RepositoryPath '.ai/maintenance/release.yaml'
if (Test-Path -LiteralPath $releasePath -PathType Leaf) {
    $releaseText = Read-Utf8Text $releasePath
    $migrationEntryCount = [regex]::Matches($releaseText, '(?m)^\s+-\s+from:\s*[^\s#]+\s*$').Count
    $migrationMatches = [regex]::Matches(
        $releaseText,
        '(?ms)^\s+-\s+from:\s*(?<from>[^\s#]+)\s*\r?\n\s+to:\s*(?<to>[^\s#]+)\s*\r?\n\s+required:\s*(?<required>true|false)\s*\r?\n\s+path:\s*(?<path>\.ai/[^\s#]+)\s*$'
    )
    if ($migrationEntryCount -ne $migrationMatches.Count) {
        Add-Failure 'release.yaml migration entries must declare from, to, required, and path in that order'
    }

    $declaredMigrationPaths = @{}
    foreach ($migrationMatch in $migrationMatches) {
        $migrationPath = $migrationMatch.Groups['path'].Value
        if ($declaredMigrationPaths.ContainsKey($migrationPath)) {
            Add-Failure "release.yaml declares a duplicate migration path: $migrationPath"
        }
        else {
            $declaredMigrationPaths[$migrationPath] = $true
        }
        if (-not (Test-Path -LiteralPath (Get-RepositoryPath $migrationPath) -PathType Leaf)) {
            Add-Failure "Declared migration file is missing: $migrationPath"
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
$changelogVersions = @{}
if (Test-Path -LiteralPath $changelogPath -PathType Leaf) {
    $changelog = Read-Utf8Text $changelogPath
    $releaseHeadingLines = [regex]::Matches($changelog, '(?m)^##\s+manual-v[^\r\n]*$')
    $releaseHeadings = [regex]::Matches(
        $changelog,
        '(?m)^##\s+(?<version>manual-v(?<major>\d+)\.(?<minor>\d+))\s+\u2014\s+\d{4}-\d{2}-\d{2}\s*$'
    )

    if ($releaseHeadings.Count -eq 0) {
        Add-Failure 'CHANGELOG.md has no valid release heading'
    }
    else {
        $latestChangelogVersion = $releaseHeadings[0].Groups['version'].Value
        if ($null -ne $releaseVersion -and $latestChangelogVersion -ne $releaseVersion) {
            Add-Failure "Latest CHANGELOG release must match release.yaml: release=$releaseVersion changelog=$latestChangelogVersion"
        }

        $previousMajor = $null
        $previousMinor = $null
        $previousVersion = $null

        foreach ($heading in $releaseHeadings) {
            $headingVersion = $heading.Groups['version'].Value
            $headingMajor = [int]$heading.Groups['major'].Value
            $headingMinor = [int]$heading.Groups['minor'].Value

            if ($changelogVersions.ContainsKey($headingVersion)) {
                Add-Failure "Duplicate CHANGELOG release: $headingVersion"
            }
            else {
                $changelogVersions[$headingVersion] = $true
            }

            if ($null -ne $previousMajor -and
                ($headingMajor -gt $previousMajor -or
                    ($headingMajor -eq $previousMajor -and $headingMinor -ge $previousMinor))) {
                Add-Failure "CHANGELOG releases must be strictly newest-first: $headingVersion appears after $previousVersion"
            }

            $previousMajor = $headingMajor
            $previousMinor = $headingMinor
            $previousVersion = $headingVersion
        }
    }

    if ($releaseHeadingLines.Count -ne $releaseHeadings.Count) {
        Add-Failure 'CHANGELOG.md contains a malformed manual release heading; expected: ## manual-vX.Y — YYYY-MM-DD'
    }
}

$caseCatalog = @{}
$legacyCaseAliases = @{}
$evalReadmePath = Get-RepositoryPath '.ai/evals/README.md'
if (Test-Path -LiteralPath $evalReadmePath -PathType Leaf) {
    $evalReadme = Read-Utf8Text $evalReadmePath
    $catalogSection = [regex]::Match(
        $evalReadme,
        '(?ms)^## Regression catalog[ \t]*\r?\n(?<body>.*?)(?=^## Legacy case aliases[ \t]*$)'
    )
    $aliasSection = [regex]::Match(
        $evalReadme,
        '(?ms)^## Legacy case aliases[ \t]*\r?\n(?<body>.*?)(?=^## Quality floor[ \t]*$)'
    )

    if (-not $catalogSection.Success) {
        Add-Failure 'Evals README is missing the Regression catalog section'
    }
    else {
        $catalogBody = $catalogSection.Groups['body'].Value
        $catalogEntries = [regex]::Matches(
            $catalogBody,
            '(?m)^- `(?<id>[a-z0-9]+(?:-[a-z0-9]+)*)`:\s+.+$'
        )
        $catalogBulletCount = [regex]::Matches($catalogBody, '(?m)^- `').Count
        if ($catalogEntries.Count -eq 0 -or $catalogEntries.Count -ne $catalogBulletCount) {
            Add-Failure 'Regression catalog entries must use: - `lowercase-hyphen-id`: description'
        }
        foreach ($entry in $catalogEntries) {
            $caseId = $entry.Groups['id'].Value
            if ($caseCatalog.ContainsKey($caseId)) {
                Add-Failure "Duplicate Eval catalog case ID: $caseId"
            }
            else {
                $caseCatalog[$caseId] = $true
            }
        }
    }

    if (-not $aliasSection.Success) {
        Add-Failure 'Evals README is missing the Legacy case aliases section'
    }
    else {
        $aliasBody = $aliasSection.Groups['body'].Value
        $aliasEntries = [regex]::Matches(
            $aliasBody,
            '(?m)^- `(?<alias>[a-z0-9]+(?:-[a-z0-9]+)*)` -> `(?<target>[a-z0-9]+(?:-[a-z0-9]+)*)`\s*$'
        )
        $aliasBulletCount = [regex]::Matches($aliasBody, '(?m)^- `').Count
        if ($aliasEntries.Count -ne $aliasBulletCount) {
            Add-Failure 'Legacy case aliases must use: - `old-id` -> `canonical-id`'
        }
        foreach ($entry in $aliasEntries) {
            $aliasId = $entry.Groups['alias'].Value
            $targetId = $entry.Groups['target'].Value
            if ($legacyCaseAliases.ContainsKey($aliasId)) {
                Add-Failure "Duplicate legacy Eval case alias: $aliasId"
            }
            elseif ($caseCatalog.ContainsKey($aliasId)) {
                Add-Failure "Legacy Eval case alias duplicates a canonical ID: $aliasId"
            }
            else {
                $legacyCaseAliases[$aliasId] = $targetId
            }
        }
    }

    foreach ($aliasId in $legacyCaseAliases.Keys) {
        $targetId = $legacyCaseAliases[$aliasId]
        if (-not $caseCatalog.ContainsKey($targetId)) {
            Add-Failure "Legacy Eval case alias has no canonical target: alias=$aliasId target=$targetId"
        }
    }
}

$currentReleaseEligibleEvalCount = 0
$evalRunsRoot = Get-RepositoryPath 'evals/runs'
if (-not (Test-Path -LiteralPath $evalRunsRoot -PathType Container)) {
    Add-Failure 'Missing source-only Eval run directory: evals/runs'
}
else {
    $evalRunFiles = @(Get-ChildItem -LiteralPath $evalRunsRoot -File -Filter '*.md')
    $timestampEvalPattern = '^(?<id>EVAL-\d{8}T\d{9}Z-[a-z0-9]+(?:-[a-z0-9]+)*-(?<version>manual-v\d+\.\d+)-[a-z0-9]+(?:-[a-z0-9]+)*)$'
    $legacyEvalPattern = '^(?<id>EVAL-\d+)-(?<version>manual-v\d+\.\d+)-[a-z0-9]+(?:-[a-z0-9]+)*$'

    foreach ($evalRunFile in $evalRunFiles) {
        $relativeEvalPath = Get-RepositoryRelativePath $evalRunFile.FullName
        $evalText = Read-Utf8Text $evalRunFile.FullName
        $evalStem = [System.IO.Path]::GetFileNameWithoutExtension($evalRunFile.Name)
        $filenameMatch = [regex]::Match($evalStem, $timestampEvalPattern)
        if (-not $filenameMatch.Success) {
            $filenameMatch = [regex]::Match($evalStem, $legacyEvalPattern)
        }

        $runId = Get-MarkdownFrontMatterScalar $relativeEvalPath 'id'
        $runVersion = Get-MarkdownFrontMatterScalar $relativeEvalPath 'workflow_version'
        $runCases = @(Get-MarkdownFrontMatterList $relativeEvalPath 'regression_cases')
        $recordValid = $true

        if (-not $filenameMatch.Success) {
            Add-Failure "Invalid Eval run filename: $relativeEvalPath"
            continue
        }

        $expectedRunId = $filenameMatch.Groups['id'].Value
        $filenameVersion = $filenameMatch.Groups['version'].Value
        if ($null -ne $runId -and $runId -ne $expectedRunId) {
            Add-Failure "Eval ID does not match filename: path=$relativeEvalPath id=$runId expected=$expectedRunId"
            $recordValid = $false
        }
        if ($null -ne $runVersion -and $runVersion -notmatch '^manual-v\d+\.\d+$') {
            Add-Failure "Invalid Eval workflow_version: path=$relativeEvalPath version=$runVersion"
            $recordValid = $false
        }
        elseif ($null -ne $runVersion -and $runVersion -ne $filenameVersion) {
            Add-Failure "Eval version does not match filename: path=$relativeEvalPath version=$runVersion expected=$filenameVersion"
            $recordValid = $false
        }
        elseif ($null -ne $runVersion -and $changelogVersions.Count -gt 0 -and
            -not $changelogVersions.ContainsKey($runVersion)) {
            Add-Failure "Eval references a release absent from CHANGELOG.md: path=$relativeEvalPath version=$runVersion"
            $recordValid = $false
        }

        $catalogRequired = $null -ne $runVersion -and
            (Test-ManualVersionAtLeast $runVersion 'manual-v1.0')
        $seenRunCases = @{}
        foreach ($runCase in $runCases) {
            if ($runCase -notmatch '^[a-z0-9]+(?:-[a-z0-9]+)*$') {
                Add-Failure "Invalid Eval regression case ID: path=$relativeEvalPath case=$runCase"
                $recordValid = $false
                continue
            }
            if ($seenRunCases.ContainsKey($runCase)) {
                Add-Failure "Duplicate Eval regression case ID: path=$relativeEvalPath case=$runCase"
                $recordValid = $false
                continue
            }
            $seenRunCases[$runCase] = $true

            if (-not $catalogRequired -or $caseCatalog.ContainsKey($runCase)) {
                continue
            }
            if ($legacyCaseAliases.ContainsKey($runCase)) {
                Add-Failure "Current Eval uses legacy case alias: path=$relativeEvalPath case=$runCase canonical=$($legacyCaseAliases[$runCase])"
            }
            else {
                Add-Failure "Current Eval case is absent from the Regression catalog: path=$relativeEvalPath case=$runCase"
            }
            $recordValid = $false
        }

        $releaseEligible = $false
        if ($catalogRequired) {
            $runSchemaVersion = Get-MarkdownFrontMatterScalar $relativeEvalPath 'schema_version'
            $runStatus = Get-MarkdownFrontMatterScalar $relativeEvalPath 'status'
            $runResult = Get-MarkdownFrontMatterScalar $relativeEvalPath 'result'
            $completedAt = Get-MarkdownFrontMatterScalar $relativeEvalPath 'completed_at'
            $sourceRevision = Get-MarkdownFrontMatterScalar $relativeEvalPath 'source_revision'
            $sourceTree = Get-MarkdownFrontMatterScalar $relativeEvalPath 'source_tree'
            $qualityFloor = Get-MarkdownFrontMatterScalar $relativeEvalPath 'quality_floor'
            $sourceSnapshotCurrent = $true

            if ($runSchemaVersion -ne '2') {
                Add-Failure "Modern Eval must use schema_version 2: path=$relativeEvalPath schema=$runSchemaVersion"
                $recordValid = $false
            }
            if ($runStatus -ne 'completed') {
                Add-Failure "Eval run records must be completed: path=$relativeEvalPath status=$runStatus"
                $recordValid = $false
            }
            if ($runResult -notmatch '^(pass|fail)$') {
                Add-Failure "Invalid Eval result: path=$relativeEvalPath result=$runResult"
                $recordValid = $false
            }
            if ($qualityFloor -notmatch '^(pass|fail)$') {
                Add-Failure "Invalid Eval quality_floor: path=$relativeEvalPath quality_floor=$qualityFloor"
                $recordValid = $false
            }
            if ($completedAt -notmatch '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{3})?Z$') {
                Add-Failure "Invalid Eval completed_at UTC timestamp: path=$relativeEvalPath completed_at=$completedAt"
                $recordValid = $false
            }
            if ($runCases.Count -eq 0) {
                Add-Failure "Completed Eval must name at least one regression case: $relativeEvalPath"
                $recordValid = $false
            }

            $gitBackedSource = $true
            if (-not (Test-Path -LiteralPath $gitDirectory)) {
                Add-Failure "Modern Eval requires a Git-backed source repository: $relativeEvalPath"
                $gitBackedSource = $false
                $recordValid = $false
            }
            elseif ($sourceRevision -notmatch '^[0-9a-f]{40}$') {
                Add-Failure "Eval source_revision must be a full commit ID: path=$relativeEvalPath revision=$sourceRevision"
                $gitBackedSource = $false
                $recordValid = $false
            }
            elseif ($sourceTree -notmatch '^[0-9a-f]{40}$') {
                Add-Failure "Eval source_tree must be a full Git tree ID: path=$relativeEvalPath tree=$sourceTree"
                $gitBackedSource = $false
                $recordValid = $false
            }

            if ($gitBackedSource) {
                $objectType = Get-GitText @('cat-file', '-t', $sourceRevision)
                if ($objectType -ne 'commit') {
                    Add-Failure "Eval source_revision is not an available commit: path=$relativeEvalPath revision=$sourceRevision"
                    $recordValid = $false
                }
                else {
                    $expectedSourceTree = Get-GitText @('rev-parse', "${sourceRevision}^{tree}")
                    if ($sourceTree -ne $expectedSourceTree) {
                        Add-Failure "Eval source_tree mismatch: path=$relativeEvalPath tree=$sourceTree expected=$expectedSourceTree"
                        $recordValid = $false
                    }

                    $sourceReleaseText = Get-GitText @('show', "${sourceRevision}:.ai/maintenance/release.yaml")
                    $sourceReleaseVersion = if ($null -eq $sourceReleaseText) {
                        $null
                    }
                    else {
                        Get-YamlScalarFromText $sourceReleaseText 'workflow_version'
                    }
                    if ($sourceReleaseVersion -ne $runVersion) {
                        Add-Failure "Eval source commit carries a different Workflow version: path=$relativeEvalPath eval=$runVersion source=$sourceReleaseVersion"
                        $recordValid = $false
                    }

                    $ancestorExitCode = Invoke-GitExitCode @('merge-base', '--is-ancestor', $sourceRevision, 'HEAD')
                    if ($ancestorExitCode -ne 0) {
                        Add-Failure "Eval source_revision is not an ancestor of HEAD: path=$relativeEvalPath revision=$sourceRevision"
                        $recordValid = $false
                    }

                    $allowedPostSourcePattern = '^evals/runs/[^/]+\.md$'
                    $committedAfterSource = Get-GitText @('diff', '--name-only', "${sourceRevision}..HEAD", '--')
                    $stagedAfterSource = Get-GitText @('diff', '--cached', '--name-only', '--')
                    foreach ($changedPathSet in @($committedAfterSource, $stagedAfterSource)) {
                        if ($null -eq $changedPathSet) {
                            $sourceSnapshotCurrent = $false
                            continue
                        }
                        foreach ($changedPath in @($changedPathSet -split "`n")) {
                            if (-not [string]::IsNullOrWhiteSpace($changedPath) -and
                                $changedPath -notmatch $allowedPostSourcePattern) {
                                $sourceSnapshotCurrent = $false
                            }
                        }
                    }

                    $unstagedPaths = Get-GitText @('diff', '--name-only', '--')
                    if ($null -eq $unstagedPaths -or -not [string]::IsNullOrWhiteSpace($unstagedPaths)) {
                        $sourceSnapshotCurrent = $false
                    }

                    $untrackedPaths = Get-GitText @('ls-files', '--others', '--exclude-standard')
                    if ($null -eq $untrackedPaths) {
                        $sourceSnapshotCurrent = $false
                    }
                    else {
                        foreach ($untrackedPath in @($untrackedPaths -split "`n")) {
                            if (-not [string]::IsNullOrWhiteSpace($untrackedPath) -and
                                $untrackedPath -notmatch $allowedPostSourcePattern) {
                                $sourceSnapshotCurrent = $false
                            }
                        }
                    }
                }

                $trackedEval = Get-GitText @('ls-files', '--error-unmatch', '--', $relativeEvalPath)
                if ($trackedEval -ne $relativeEvalPath) {
                    Add-Failure "Eval record must be tracked or staged before it can be release evidence: $relativeEvalPath"
                    $recordValid = $false
                }
                elseif ((Invoke-GitExitCode @('diff', '--quiet', '--', $relativeEvalPath)) -ne 0) {
                    Add-Failure "Eval record has unstaged changes and cannot be release evidence: $relativeEvalPath"
                    $recordValid = $false
                }
            }

            foreach ($heading in @('Core Result', 'Targeted Regressions', 'Decision')) {
                if (-not [regex]::IsMatch($evalText, '(?m)^## ' + [regex]::Escape($heading) + '\s*$')) {
                    Add-Failure "Completed Eval is missing section '$heading': $relativeEvalPath"
                    $recordValid = $false
                }
            }

            $acceptedRow = Get-MarkdownTableRow $evalText 'accepted'
            $qualityRow = Get-MarkdownTableRow $evalText 'quality floor passed'
            if (-not $acceptedRow.Success -or
                [string]::IsNullOrWhiteSpace($acceptedRow.Groups['evidence'].Value) -or
                $acceptedRow.Groups['value'].Value.Trim() -notmatch '^(?i:yes|no)$') {
                Add-Failure "Completed Eval needs a non-empty accepted result/evidence row: $relativeEvalPath"
                $recordValid = $false
            }
            if (-not $qualityRow.Success -or
                [string]::IsNullOrWhiteSpace($qualityRow.Groups['evidence'].Value) -or
                $qualityRow.Groups['value'].Value.Trim() -notmatch '^(?i:pass|fail)$') {
                Add-Failure "Completed Eval needs a non-empty quality-floor result/evidence row: $relativeEvalPath"
                $recordValid = $false
            }

            $caseFailureFound = $false
            foreach ($runCase in $runCases) {
                $caseRow = Get-MarkdownTableRow $evalText $runCase
                if (-not $caseRow.Success -or
                    [string]::IsNullOrWhiteSpace($caseRow.Groups['evidence'].Value) -or
                    $caseRow.Groups['value'].Value.Trim() -notmatch '^(?i:pass|fail|not_applicable)$') {
                    Add-Failure "Completed Eval needs a result/evidence row for case '$runCase': $relativeEvalPath"
                    $recordValid = $false
                    continue
                }
                if ($caseRow.Groups['value'].Value.Trim() -match '^(?i:fail)$') {
                    $caseFailureFound = $true
                }
            }

            if ($runResult -eq 'pass' -and
                ($qualityFloor -ne 'pass' -or
                    ($acceptedRow.Success -and $acceptedRow.Groups['value'].Value.Trim() -notmatch '^(?i:yes)$') -or
                    ($qualityRow.Success -and $qualityRow.Groups['value'].Value.Trim() -notmatch '^(?i:pass)$') -or
                    $caseFailureFound)) {
                Add-Failure "Eval result=pass conflicts with its quality/core/case results: $relativeEvalPath"
                $recordValid = $false
            }

            $releaseEligible = $recordValid -and
                $runStatus -eq 'completed' -and
                $runResult -eq 'pass' -and
                $qualityFloor -eq 'pass' -and
                $sourceSnapshotCurrent
        }

        if ($null -ne $releaseVersion -and $runVersion -eq $releaseVersion -and $releaseEligible) {
            $currentReleaseEligibleEvalCount++
        }
    }

    if ($RequireReleaseEvidence -and $null -ne $releaseVersion -and
        $currentReleaseEligibleEvalCount -eq 0) {
        Add-Failure "No completed PASS Eval with valid Git evidence records the current release: $releaseVersion"
    }
}

$markdownFiles = @(Get-ChildItem -LiteralPath $RepositoryRoot -Recurse -File -Filter '*.md' |
    Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' })
$referenceCount = 0

foreach ($file in $markdownFiles) {
    $text = Read-Utf8Text $file.FullName
    $fenceCount = [regex]::Matches($text, '(?m)^[ \t]*```').Count
    if (($fenceCount % 2) -ne 0) {
        $displayPath = Get-RepositoryRelativePath $file.FullName
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

$releaseEvidenceMode = if ($RequireReleaseEvidence) { 'required' } else { 'not_required' }
Write-Output "PASS workflow=$releaseVersion markdown=$($markdownFiles.Count) references=$referenceCount release_evidence=$releaseEvidenceMode eligible_current_evals=$currentReleaseEligibleEvalCount"
