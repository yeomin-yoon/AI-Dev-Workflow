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

function Get-Sha256Hex {
    param([string]$Text)

    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.UTF8Encoding]::new($false).GetBytes($Text)
        return ([System.BitConverter]::ToString($sha256.ComputeHash($bytes))).Replace('-', '').ToLowerInvariant()
    }
    finally {
        $sha256.Dispose()
    }
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
    'maintenance/WORKFLOW_REVIEW.md',
    'maintenance/RELEASE.md',
    'evals/README.md',
    'evals/runs/.gitkeep'
)

foreach ($relativePath in $sourceRequiredPaths) {
    if (-not (Test-Path -LiteralPath (Get-RepositoryPath $relativePath))) {
        Add-Failure "Missing source-only repository path: $relativePath"
    }
}

# Windows PowerShell 5.1 may decode BOM-less script source with the active ANSI
# code page. Keep validator sources ASCII so the default Windows command and
# PowerShell 7/CI parse the same bytes.
$powerShellSourceRoot = Get-RepositoryPath 'tools'
if (Test-Path -LiteralPath $powerShellSourceRoot -PathType Container) {
    foreach ($powerShellSource in @(Get-ChildItem -LiteralPath $powerShellSourceRoot -File -Filter '*.ps1')) {
        $hasNonAsciiByte = $false
        foreach ($sourceByte in [System.IO.File]::ReadAllBytes($powerShellSource.FullName)) {
            if ($sourceByte -gt 127) {
                $hasNonAsciiByte = $true
                break
            }
        }
        if ($hasNonAsciiByte) {
            $relativePowerShellPath = Get-RepositoryRelativePath $powerShellSource.FullName
            Add-Failure "PowerShell validation source must remain ASCII for Windows PowerShell 5.1 compatibility: $relativePowerShellPath"
        }
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
    'README.md' = @(
        'philosophy-core: human-judgment-over-automation',
        'tacit-seed-diagnostic: evidence-before-clarification',
        'install-boundary: fresh-copy-vs-managed-update-vs-unrelated-ai',
        'workflow-review-summary: canonical-lenses-1-through-10',
        'release-finalizer-session: fresh-non-authoring',
        '| Change Brief |',
        '| Code Walkthrough |',
        '`DEV_STATUS`',
        '`CODE_WALKTHROUGH`',
        '`COMMIT_READY`',
        'readable-choice: recommendation-and-alternatives-together',
        'checkpoint-repin: mandatory-not-choice',
        'collaborative-design-altitude: bounded-pass-needed-now',
        'informed-assent: concise-not-surrender',
        'intent-gap-brief: current-intent-gap-ai-user',
        'planning-gap-classification: specified-implementation-product-authority',
        'diagnostic-discipline: intent-evidence-one-action-delivery-focus',
        'manual-authoring-guide: whole-flow-first-use-terms-finished-shape',
        'planned-editor-authoring: builder-before-review',
        'bounded-expert-note: core-first-one-by-default',
        'code-walkthrough-default: no-pause-do-next-visible',
        '`RESUME_SAME_LANE`',
        '`FRONT_DESK_RECOVERY`'
    )
    '.ai/WORKFLOW.md' = @(
        'Evaluative or tacit seeds are valid problem signals, not failed requirements',
        'For broad collaborative planning, orient one bounded pass by its current design altitude',
        'A concise assent is valid after one decision-ready semantic choice',
        'distinguishes complete from user-approved deferred work',
        'A historical Architecture without a slice map is reconstructed only from already-approved evidence',
        'the smallest discriminating probe or proposed improvement',
        'A green check is evidence, not proof that its oracle, architecture, or long-term maintainability remained sound',
        'Independent AI Review reduces review burden but never transfers code ownership',
        'Decision authority and learning visibility are separate',
        'A user Gate exists only when the user has a real choice',
        'Run a Gate necessity check before every approval request',
        'independent Review PASS is the default authorization for one exact local logical checkpoint',
        'When four or more remain, preserve them all but first ask one bounded discriminator with at most three exhaustive groups',
        'Required deterministic bookkeeping, metadata repinning, and role-owned repair are executed and reported rather than presented as user choices',
        'evidence-grounded intent-gap trace',
        'specified | implementation_open | product_open | authority_unknown',
        'The user should not need a second request for the core problem',
        'Independent Review removes authoring-session memory and self-confirmation, not approved project context',
        'add a bounded expert note only when one non-obvious principle',
        'This is a presentation/default behavior, never a new artifact',
        'A cross-session handoff is transport, not approval',
        'configured code-inspection pause when applicable',
        'mechanical/non-code changes never gain a ceremonial pause',
        'at a natural boundary, continue silently when the current session can likely finish the next bounded action and durable checkpoint',
        'Session age, turn count, or an invented token estimate is not evidence',
        'missing and new-scaffold interaction preferences use `auto_after_pass + one_task + no_pause`',
        'no-Git/unsealed Review never waits there',
        'The user never needs prerequisite external study merely to understand the current decision',
        'Keep the current Task''s approved observable outcome as the active delivery anchor',
        'Distinguish `observed | inferred | confirmed` evidence',
        'Never call a root cause confirmed until',
        'without naming the baseline and the concrete observable invariants that remain true',
        'every repeated check or handoff must add distinct evidence',
        'Candidate manifests, managed files, migration sources, and resolved read links must remain inside the pinned read-only candidate source root',
        'Passing one boundary never implies passing the other',
        'validates the installed-project profile with itemized evidence',
        'last Task PASS is necessary evidence but never sufficient proof that the whole Feature intent landed'
    )
    '.ai/reference/OPERATIONS.md' = @(
        '## Bounded diagnosis during active delivery',
        'Reconstruct the delivery anchor from the current Task''s exact observable ACs',
        '`observed | inferred | confirmed`',
        '`current_blocker`',
        '`follow_up`',
        '`not_actionable`',
        'Build one bounded evidence batch before requesting user help',
        'Architecture, Task, state, and Knowledge contain only confirmed/approved facts',
        'Only `current_blocker` enters the Exception procedure below',
        'Knowledge required/checkpoint',
        'Git-backed single-main',
        'non-main',
        'Known Task-scoped user/editor authoring that saves candidate bytes is implementation',
        'A newly discovered candidate-mutating action after handoff invalidates candidate identity',
        'leave `ready_to_build/blocked`, `building/blocked`, `reviewing/blocked`, or `integration/blocked` without a return path'
    )
    '.ai/contracts/BUILD_RESULT.md' = @(
        'candidate_fingerprint',
        'canonical UTF-8/LF manifest',
        'fixed first header',
        'For an untracked regular file, use the literal `regular`',
        'unrelated_pre_existing | inherited_task | unknown',
        'Historical Build Results with the older Baseline bullets remain readable',
        '`Unverified / Risks` may record an `observed` fact or explicitly `inferred` hypothesis',
        'correct the current Build Result before handoff',
        'Known user/editor authoring that saves Task-attributed bytes is implementation and must finish inside the active Build attempt',
        '| Path | Change | AC/reason | Source role / key symbol |',
        '## Source Map',
        'primary read: <three-to-five path#symbol anchors in runtime order|none>',
        'For every Task-touched hand-written production source path in `Changes`',
        'Builder owns this revision-scoped Source Map while implementing',
        'Historical completed Build Results with the three-column `Changes` table and no `Source Map` remain readable'
    )
    '.ai/contracts/TASK_RECORD.md' = @(
        '## Task Quality Gate',
        'Split only when reduced context, risk, or review ambiguity repays another handoff',
        'Prefer a narrow end-to-end/vertical slice',
        'Do not prescribe full code, copy source, or create a separate Program Design artifact',
        'Do not add a separate Task-quality artifact, session, numeric score, or bare `task_quality=pass`',
        'exact requirement ID/section and pinned revision',
        'A replacement Task after an interrupted/superseded single-main attempt classifies every inherited Task path',
        'It never authorizes deleting unrelated pre-existing or `unknown` work',
        'Task creation also requires a current delivery reason',
        'A discovered `follow_up` is not independently READY',
        'do not knowingly design a Build -> Review -> save -> Build loop',
        'proportional cross-artifact consistency check over only this Task''s exact lineage',
        'intent -> Architecture -> Task lineage has no material gap or contradiction'
    )
    '.ai/contracts/ARCHITECTURE.md' = @(
        'requirement_refs: []',
        'Front-matter `requirement_refs` is the canonical machine-readable list',
        'A mismatch is a `contract` blocker',
        'Implementation discovery may propose a requirement change but never rewrites the requirement baseline silently',
        'current approved `Scope` and `Delivery Slices` are the intent-coverage baseline',
        'Task PASS alone is not whole-Feature coverage',
        'A historical approved Architecture without `Delivery Slices` remains readable',
        'Backfill the living Architecture without a new Gate only when that map is lossless'
    )
    '.ai/shared/SYSTEM_ARCHITECTURE.md' = @(
        'requirement_refs: []',
        'Front-matter `requirement_refs` is the canonical optional list',
        'A historical System Architecture without this field remains readable as `requirement_refs: []`',
        'supersession of every affected Lane Task before Integration'
    )
    '.ai/contracts/KNOWLEDGE.md' = @(
        'A requirement-bearing `document` source records approval separately from source freshness',
        '`approval.status` is `approved | candidate | rejected | superseded | unknown`',
        '`verification.status` describes source accuracy/freshness; it never substitutes for requirement approval',
        'Historical schema-v2 document entries without `approval` remain readable as `approval.status: unknown`',
        'Search hints identify candidates, not applicability',
        'interaction:',
        'checkpoint: auto_after_pass # auto_after_pass | ask',
        'routine_continuation: one_task # one_task | stop',
        'code_inspection: no_pause # no_pause | before_next_task',
        'Missing `interaction` and a new scaffold both read as `auto_after_pass + one_task + no_pause`',
        '`before_next_task` is an explicit project opt-in',
        'It is a pace preference, not a correctness approval or durable claim of understanding',
        'including a required single-main revision-repin closure'
    )
    '.ai/lanes/_template/architecture.md' = @(
        'requirement_refs: []',
        '## Requirement Baseline',
        'explain only the applicability/approval basis of front-matter requirement_refs'
    )
    '.ai/contracts/REVIEW_RESULT.md' = @(
        'reviewed_fingerprint',
        'immediately before PASS',
        'PASS requires all mandatory ACs passed',
        'no unresolved requirement-ref drift',
        'credible verification evidence whose oracle was not materially weakened',
        'no unresolved material maintainability finding',
        'an unchanged candidate identity from Review start through verdict',
        '## Reduced-assurance exception',
        '<Knowledge Maintainer | Work | Architect | Builder | responsible role/user gate | Integration Gate>',
        'ACTION_CARDS.md#editorruntime-check',
        'Earlier evidence may be reused only after an explicit impact check against that fresh candidate',
        'A generic request such as "review this" or a convenience-driven same-session role switch is not consent',
        'proceed only after the user explicitly accepts that limitation after the disclosure',
        'Reduced-assurance Review is never canonical release evidence, Integration Gate evidence',
        'reviewed diff: <exact base/range/fingerprint and scoped diff command | no-git/unsealed + reviewed changed-file manifest and path/symbol open sequence>',
        'reviewed source map: <Build Result#source-map validated against exact Diff + corrections|omit for none>',
        'records that validated pointer plus corrections instead of rewriting the inventory',
        'Historical completed Review Results that store `source roles`, `read order`, and `new source files` inline remain readable',
        'ACTION_CARDS.md#code-walkthrough',
        'it never invents a Git revision, fingerprint, or Diff command',
        'Apply `OPERATIONS.md#bounded-diagnosis-during-active-delivery` before a discovery changes verdict or route',
        'an inference never becomes PASS evidence'
    )
    '.ai/contracts/STATE.md' = @(
        'Integration queue',
        'reviewed_fingerprint',
        'continue_architecture_repair',
        'owning role repairs only the malformed artifact/contract',
        'authoritative context is restored without changing candidate/intent',
        'requested `observe_only` evidence arrives and candidate bytes/identity are unchanged',
        'an authorized `candidate_mutating` Editor/runtime action changes Task-attributed bytes',
        'the action changes an unowned/unknown path, exceeds the authorized mutation set',
        'final Task PASS has `knowledge_sync: none`',
        '`integration/blocked` with `verification` or `context`',
        '`integration/blocked` with non-material `contract`',
        '`ready_to_build/blocked` with `architecture`',
        '`building/blocked` with `architecture`',
        '`ready_to_review/blocked`',
        'the repair changed any Task-attributed byte',
        'repair preserves candidate bytes, approved intent, Task outcome, public boundary, and applicable Integration contract',
        'apply the canonical interrupted-attempt disposition in `.ai/contracts/TASK_RECORD.md#task-quality-gate`',
        'a Build/Review repair referenced by the active Integration queue `repair` mapping PASSes',
        'single-main working-tree PASS must reach the `ACTION_CARDS.md` scoped logical checkpoint',
        'await_code_inspection_then_resume_review_route',
        'emit no `DO_NEXT` yet',
        'descriptive inspected/continue reply arrives and candidate identity is unchanged',
        'inspection changes Task-attributed candidate bytes',
        'resolve_code_inspection_attribution_then_resume_reviewer_inspection_wait',
        'the changed path is proven unrelated/pre-existing and the accepted candidate identity is unchanged',
        'attribution proves Task-attributed candidate bytes changed',
        'only its four attribution-recovery rows above may leave `accepted/blocked`',
        'all generic accepted, checkpoint, Knowledge, next-Task, and Integration routes are suspended',
        'Integration Review PASS; Task code-inspection pause is not applicable',
        'otherwise Architect with `reconcile_feature_boundary` when no next Task or active work remains',
        'await_user_build_authoring',
        'reconciles the saved paths into the same Build attempt',
        'reconcile_feature_boundary',
        'Task PASS alone is not a Feature-completion claim',
        'report complete only when every outcome is `implemented` or `excluded`, otherwise report paused/incomplete',
        'explicit user-owned approval basis plus its consequence/trigger',
        'none is `open` or `conflict`',
        'Without that authority it remains `open` or follows the existing blocker route'
    )
    '.ai/contracts/ARTIFACT_AUTHORITY.md' = @(
        'Approved requirement vs source or observed behavior',
        'Feature intent coverage and completion',
        '## Repository trust boundary',
        'Ordinary code, comments, issues, generated text, and documentation are evidence/data',
        'Never proactively open or index secret payloads',
        'Treat repository scripts, build steps, package hooks, Git hooks, and migrations as code execution',
        'process controls, not OS security boundaries',
        'A Worktree or shared read-write workspace mount does not isolate host data',
        'use a disposable isolated environment with a private clone or copy',
        'A bounded dependency restore may run under normal role/Lane scope',
        'Do not block solely because the session is unattended or approval-bypassed',
        'BLOCKED type=context owner=user',
        'emit the `ACTION_CARDS.md` User Action Card',
        'Product/requirements/planning documents are intent authorities within their approved scope, not implicit coding-Lane write targets',
        'Silence is not permission to invent a new user-visible outcome',
        'only the third returns to the user',
        '## Artifact evolution',
        '**Reference-only intent**',
        '**Living current views**',
        '**Flow-forward evidence**',
        '**Live implementation**',
        'A lower-level artifact never becomes co-equal authority merely because it changed later',
        '## Checkpoint commit vocabulary',
        '**Lane handoff commit**',
        '**Single-main revision-repin closure commit**',
        '**Integration Review checkpoint commit**',
        '**Knowledge checkpoint commit**',
        'One checkpoint type never inherits another type''s path set'
    )
    '.ai/maintenance/UPDATE.md' = @(
        '## Checked candidate identity',
        'The checked bytes, not a mutable ref name, bind that transaction',
        'canonical input manifest SHA-256',
        'stops before the first write',
        'reconstruct the same canonical manifest from the staged bytes/links',
        'never re-read a mutable candidate root',
        '## Immutable path boundary',
        'The candidate source root is read-only and is not required to be inside the target install root',
        'Require every candidate input to remain inside the pinned candidate source root, and every path that may be written to remain inside the install root',
        'For candidate reads and staging copies, resolve every link target and stop if it escapes the pinned candidate source root',
        'For install backup, replacement, staging destination, migration write, restore, or final destination, stop if the target escapes the install root',
        'not the install root itself or a descendant of `<project>/.ai/`',
        'requires an explicit user approval',
        'Record each path as `present | absent`',
        'with the checked source identity and an immutable pre-state section',
        'transaction manifest''s completed mutation record proves this Apply created it',
        '## Installed validation evidence',
        '`managed_inventory`',
        '`preserved_schema_enums`',
        '`path_containment_classification`',
        '`reference_integrity`',
        '`markdown_language_policy`',
        '`runtime_state_preservation`',
        '`bootstrap_readiness`',
        'A missing or duplicate row, `not_applicable`, `not_run`',
        'validation=<pass|fail|not_run; evidence-path|none>',
        '## Interrupted transaction recovery',
        'active_transaction_manifest',
        'only as an untrusted source candidate and require explicit user confirmation before Check',
        'all seven required evidence rows are present and `pass`',
        'never skip it as `not_applicable`',
        'mark the transaction manifest outcome `committed`',
        'restore verification'
    )
    '.ai/maintenance/update-state.template.yaml' = @(
        'last_checked_revision: null',
        'last_checked_tree: null',
        'last_checked_manifest_sha256: null',
        'last_checked_new_managed: []',
        'approved_new_managed: []',
        'active_transaction_manifest: null'
    )
    '.ai/maintenance/update-state.yaml' = @(
        'last_checked_revision: null',
        'last_checked_tree: null',
        'last_checked_manifest_sha256: null',
        'last_checked_new_managed: []',
        'approved_new_managed: []',
        'active_transaction_manifest: null'
    )
    '.ai/contracts/ACTION_CARDS.md' = @(
        '## Working summary',
        'WORKING_SUMMARY',
        'A human-readable label precedes its internal ID',
        '## Developer Status',
        'DEV_STATUS',
        'content_committed_repin_pending',
        'blocked` reports only an `OPERATIONS.md#bounded-diagnosis-during-active-delivery` `current_blocker`',
        '## Readable atomic decisions',
        'show the recommendation and every viable alternative together',
        'four or more genuinely viable user-owned outcomes remain',
        'mutually exclusive, collectively exhaustive groups',
        'groups=<none|up to three discriminator groups, each followed by every included semantic outcome>',
        'exclude an outcome only with evidence that it is not currently viable',
        'Each choice authorizes one atomic user-owned action',
        'A concise assent to one decision-ready semantic outcome remains valid',
        'An explicit surrender signal never becomes product authority',
        'Required deterministic bookkeeping, exact metadata repinning, and role-owned repair are not choices',
        'A general decision begins directly with `DECISION`',
        '### Intent-gap preface',
        '## Code walkthrough',
        'CODE_WALKTHROUGH',
        'current_behavior=<what the user/system does now + strongest evidence>',
        'user_decision=<the remaining user-visible/product behavior the user can truly choose|none>',
        'A rejected or previously failed approach belongs under evidence/rejected direction, not under `choices`',
        '## Bounded expert note',
        'Default to one; a `deep` explanation may use at most two or three',
        'When the user says the explanation is unclear or tiring',
        'The Build Result `Changes` and `Source Map` are the one cumulative revision-scoped inventory',
        'The chat walkthrough selects only three-to-five anchors',
        'A summary, raw directory list, Review link, or selected hunk alone never substitutes for opening the actual changed source',
        'primary_read=',
        'full_map=<Build Result#changes + #source-map, validated by Review Result>',
        'R1. <path>#<symbol>',
        'snapshot=no-git/unsealed',
        'provide the exact `R#` path+symbol open sequence instead of inventing a revision, Diff command, or sealed identity',
        'Internal enums may be stored in state/result fields but never replace the displayed meaning',
        'code_inspection=awaiting_user',
        'purely mechanical/non-code PASS sets `not_applicable`',
        'a `CODE_WALKTHROUGH` with `code_inspection=awaiting_user` stays in Reviewer',
        'This pause applies only to an ordinary Task Review whose Git tree or canonical working-tree fingerprint can be revalidated',
        'Integration Review always sets `code_inspection=not_applicable`',
        '## Single-main commit checkpoint',
        'COMMIT_READY',
        '## Editor/runtime check',
        'effect=<observe_only|candidate_mutating>',
        'do_now=<one plain action sentence; include save/do-not-save when relevant>',
        'do_now=<one plain action sentence + explicit save/do-not-save instruction>',
        'flow=<for graph/state/lifecycle/data-flow authoring: plain before -> this step -> resulting behavior|none>',
        'terms=<only first-use visible labels needed in the steps: label = plain behavioral meaning|none>',
        'for authoring include the exact finished surface/shape before save or report',
        'batch them into this one card in inspection order',
        'show the whole behavior flow and the expected finished shape before numbered mechanics',
        'do not rely on "same as last time"',
        'Never claim an insertion or wiring position is safe from surrounding references that were not inspected',
        'When the user reports completion, lead with acknowledgement and the next verification step',
        '`fallback` defaults to stopping without changing candidate bytes',
        'Never describe a new save, configuration edit, or source/asset mutation as a safe way to stop',
        'independent Review PASS is the default authorization for one exact local logical checkpoint',
        'content_revision=<commit> metadata_revision=<commit|none>',
        'never offers compound `commit and continue` choices',
        'at most one next routine Task already covered by unchanged approved Architecture',
        'A planned pre-candidate `candidate_mutating` action returns to the same active Builder attempt',
        'any later `candidate_mutating` result invalidates the handed-off Build/Review identity',
        'Before another Task starts, the accepted single-main change must have a verified logical checkpoint when Git is usable',
        'Canonical replies are descriptive semantic actions',
        'This never authorizes Push, tag, history rewrite'
    )
    '.ai/contracts/MAIN_DESK.md' = @(
        '## Worker delivery procedure',
        '## Front Desk recovery',
        'FRONT_DESK_RECOVERY',
        'Recovery does not depend on the exhausted chat',
        'Read .ai/BOOTSTRAP.md. role=work, lane=main, session_mode=compact',
        'A Front Desk is event-driven',
        '## Post-integration Lane disposition',
        'it routes Architect through `STATE.md`''s `reconcile_feature_boundary` before choosing a disposition',
        'only after Feature convergence reaches `synced/idle`',
        'Feature convergence returns `design/active` with a specified open outcome materialized for delivery'
    )
    '.ai/contracts/SESSION_CLOSE.md' = @(
        '## Replacement timing',
        'Assess viability only at a natural boundary',
        'One corrected mistake, a long transcript, or turn count alone is not enough',
        'If the next action and checkpoint remain likely achievable, continue silently',
        'RESUME_SAME_LANE',
        'role, topology, candidate, Lane, checkout, new-worktree, Integration, or return-intent change is not a same-Lane replacement',
        'MAIN_DESK.md#front-desk-recovery'
    )
    '.ai/contracts/PARALLEL_START.md' = @(
        'Treat tool/account availability and Front Desk handoff cost as real partition costs'
    )
    '.ai/integration/README.md' = @(
        'An Integration blocker must retain the queue item',
        'Evidence/context or non-material Integration contract repair',
        'full range from the retained original `main_before`',
        'queue `repair` mapping, not chat',
        '`CODE_WALKTHROUGH` inspection pause is not applicable to this Integration Review',
        'Integration Review checkpoint commit',
        'After the last candidate, when no next Task or active work remains, route Architect through `reconcile_feature_boundary`',
        'Feature-converged complete/paused rest'
    )
    '.ai/integration/queue.yaml' = @(
        'repair: # optional; absent means no Integration repair is active',
        'original_main_before: null',
        'ready_for_integration_review'
    )
    '.ai/evals/GOLDEN_WORKTREE_LIFECYCLE.md' = @(
        'Integration blocker repair and resume',
        'Cross-lane requirement revision',
        'pins `Docs/SharedPRD.md#REQ-SHARED-1@R2` once in its canonical `requirement_refs`',
        'An eligible non-`main` ordinary Task Review may use the configured `CODE_WALKTHROUGH` pause',
        'the later main Integration Review never creates that pause',
        'the last Integration PASS and required Knowledge checkpoint still route Architect through `reconcile_feature_boundary`',
        'An open-only or mixed open plus user-approved-deferred outcome returns `design/active`',
        'All ten cases must agree across:'
    )
    '.ai/evals/README.md' = @(
        '`source_regression`: the default canonical release Eval',
        "exactly A's provider/host tool/model/reasoning/configuration",
        "Never use a model's conversational self-identification as evidence",
        '`directional-failure-rescope`',
        'repository trust/execution containment',
        'Workflow update containment',
        'external candidate inputs remain inside their pinned read-only source root',
        'process controls are not mistaken for OS isolation',
        'high-risk execution either proves effective filesystem/credential/network containment',
        'an inspected deterministic search/build/test with effects proven inside the approved project/worktree is not forced into disposable isolation',
        'a bounded dependency restore from approved project-declared sources',
        'batching related constraints or evidence never crosses a pending consequential approval',
        'names, keywords, similarity, or nearby examples alone remain candidate refs',
        'Apply revalidates the exact checked revision/tree/input manifest before its first write',
        'records exactly seven mandatory `pass|fail` installed-profile rows with concrete observations and evidence paths/outputs',
        '`ready_to_build/blocked`, `building/blocked`, `ready_to_review/blocked`, `reviewing/blocked`, code-inspection `accepted/blocked`, and `integration/blocked` have explicit identity-sensitive repair/resume paths',
        'terminal Task or Integration PASS without remaining Knowledge work reaches Architect Feature convergence before any `synced/idle` disposition',
        'replacement single-main Task explicitly disposes every inherited Task path',
        'System Architecture owns cross-lane requirement refs',
        'a tacit signal triggers one bounded evidence-based diagnosis before questions or Task creation',
        'broad planning first fixes the current design altitude, bounded deliverable, deferred depth, and stop condition',
        'confusion/surrender never becomes product authority',
        'a narrow end-to-end/vertical outcome is preferred over a horizontal scaffold without standalone approved value',
        'green checks never excuse a weakened oracle',
        'AI Review supports rather than replaces human ownership',
        'Every named case in a passing canonical `source_regression` is exactly `pass`',
        'non-`none` deferred-P2 entry with follow-up proof',
        '`ready_to_review/blocked`',
        'mandatory `pass|fail` installed-profile rows',
        'unrelated-pre-existing/inherited-task/unknown attribution',
        'developer status and commit readiness classify Task/workflow/unrelated/untracked paths',
        'product/requirements/planning documents are exact reference-only intent inputs by default',
        'an exact same-Lane replacement restores directly only when checkout, Lane, role/topology, route, and candidate identity are unchanged',
        'Editor/runtime user checks provide exact executable and reply guidance',
        'project interaction preference defaults to automatic exact local checkpoint plus one routine next Task under unchanged approved Architecture',
        'cross-session `DO_NEXT` is transport rather than approval',
        'a foregone, unreadable, or effectively unavoidable confirmation earns no quality credit',
        'a returning or confused user receives a one-screen chat-only `WORKING_SUMMARY`',
        '`intent-gap-first-brief`',
        'incomplete planning is decision-ready on the first response',
        'non-obvious reversible technical choices do not create a user Gate but remain learnable',
        'non-trivial explanations may add one bounded expert note after the core result/action by default',
        'independent Reviewer freshness removes authoring memory, not approved user/project context',
        'name the compared baseline and concrete observable invariants',
        '`diff-first-code-ownership`',
        '`readable-atomic-decision`',
        '`intent-anchored-bounded-diagnosis`',
        '`proportional-verification-cadence`',
        'active diagnosis starts from exact approved intent and ACs',
        'iterative verification adds distinct evidence rather than ceremony',
        'makes structural authoring self-contained with whole-flow/first-use-term/finished-shape guidance',
        'manual structural authoring shows the whole behavior flow',
        'every non-trivial hand-written production change exposes current source entry points during Build',
        'keeps one complete per-path Source Map in its Build Result',
        'three-to-five verified primary runtime anchors directly inspectable',
        'a last Task PASS never substitutes for Feature intent coverage',
        '`artifact-authority-single-source`',
        '`terminal-no-knowledge-transition`',
        'Reviewer replacement restores that wait',
        'new and historical projects default to `no_pause`',
        'no-Git/unsealed or mechanical/non-code PASS never receives an identity-dependent or ceremonial pause',
        'four-or-more uses at most three exhaustive discriminator groups and no outcome silently disappears',
        'required deterministic closure is not an option'
    )
    '.ai/evals/SCORECARD.md' = @(
        'eval_type: <source_regression|end_to_end|fixed_contract>',
        'Use `source_regression` for canonical release evidence',
        '| intent-gap + decision clarity / current-design-altitude fit / unnecessary questions or gates / informed assent vs surrender |',
        '| intent/scope convergence + contract equivalent |',
        '| Change Brief / bounded expert-note grounding and fatigue |',
        '| Progressive source orientation / compact verified Diff walkthrough / durable-pause usefulness |',
        '| verification cadence / distinct evidence per repeated check |'
    )
    '.ai/maintenance/MAINTAIN.md' = @(
        'contract_or_route: <owning contract/path or route name|unknown>',
        'stage | symptom_class | provider_scope | contract_or_route',
        'Ordinary roles do not open it or create records automatically',
        'WORKFLOW_OBSERVATION=<path> source=manual'
    )
    '.ai/BOOTSTRAP.md' = @(
        'the one contract for an artifact the role will create or change',
        'never combine unrelated outcomes or widen an approved Task merely to reduce messages',
        '## Active delivery kernel',
        'Do not reread unchanged inputs or rerun a check whose relevant inputs and oracle are unchanged',
        'one successful final affected suite is enough',
        'readable-decision rules in `ACTION_CARDS.md`',
        'At a natural boundary before a new Architecture decision, Task/Build attempt, Review attempt, or Integration candidate',
        'Never invent an exact token/quota value, interrupt every turn, or replace solely because the chat is old',
        'Do not require external study for the active decision',
        'CODE_WALKTHROUGH',
        'three-to-five primary reading anchors',
        'complete per-path Source Map',
        'never silently drop an outcome to satisfy the cap',
        'Separate AI-owned implementation gaps from user-owned product gaps'
    )
    '.ai/roles/ARCHITECT.md' = @(
        '.ai/contracts/TASK_RECORD.md#task-quality-gate',
        '.ai/contracts/INTEGRATION_REQUEST.md',
        'Only `READY` reaches Builder',
        'implementation never silently rewrites product intent',
        'pin it once in `.ai/shared/SYSTEM_ARCHITECTURE.md`',
        'supersede every affected Lane Task before Integration',
        'Treat filename, symbol, keyword, and similarity matches as candidate context rather than proof',
        'Treat evaluative or tacit seeds as valid problem signals, not failed requirements',
        'one compact collaboration frame',
        'the current design altitude',
        '`needed now`',
        'Repeated concise replies alone are not evidence of fatigue',
        'Explicit delegation never transfers product authority',
        'Before asking the user to diagnose the system',
        'This is inline Architect work, not a new artifact, session, approval gate',
        'make only the needed program shape explicit',
        'Prefer the smallest end-to-end/vertical slice',
        'Define an unfamiliar technical term at first user-facing use',
        'Decision burden and learning are independent',
        '`gate necessity`',
        '`decision readiness`',
        'An affirmative reply to a brief that fails a check',
        'ACTION_CARDS.md#readable-atomic-decisions',
        'ACTION_CARDS.md#intent-gap-preface',
        '`implementation_open`',
        '`product_open`',
        'Planning silence never invents visible behavior',
        'Before a Decision Brief, prove approved requirements/Architecture/Task/user intent do not already determine the outcome',
        'Build the viable set only from paths consistent with approved observable intent, ownership, responsibility, and dependency direction',
        'Implementation or test convenience cannot make a boundary-violating workaround viable',
        'Only a requested outcome, approved order, dependency of the next observable result, or diagnosed `current_blocker` becomes a Task now',
        'ACTION_CARDS.md#bounded-expert-note',
        'perform one bounded convergence pass before `synced/idle` or a completion claim',
        'Only all-`implemented|excluded` coverage supports a Feature-complete claim',
        'Only a user-approved deferral may rest at `synced/idle`',
        'This convergence does not write production source',
        'It may update only the existing role-owned Architecture, next Task, and state artifacts required by the result'
    )
    '.ai/roles/BUILDER.md' = @(
        '.ai/contracts/TASK_RECORD.md#task-quality-gate',
        '.ai/contracts/BUILD_RESULT.md',
        'Do not silently split, merge, enlarge, or reinterpret a Task that fails the Gate',
        'applicable Task-linked requirement refs that still resolve to their approved pinned revisions',
        'unrelated_pre_existing | inherited_task | unknown',
        'never relabel interrupted Workflow bytes as pre-existing user work',
        'When implementation or user evidence contradicts the current hypothesis',
        'Use `.ai/BOOTSTRAP.md#active-delivery-kernel` for cadence and evidence invalidation',
        'a save is not a new attempt and does not by itself require the whole final matrix',
        'no later than the first coherent non-trivial production-source edit',
        'report only the delta, not the accumulated inventory',
        'source_map=<artifact#source-map|none>',
        'RESULT=<ready_to_review|awaiting_user_authoring|implementation_blocked|architecture_issue|context_issue|integration_issue>',
        'this is pending implementation, not a blocker or Review handoff'
    )
    '.ai/roles/REVIEWER.md' = @(
        '.ai/contracts/REVIEW_RESULT.md',
        'single authority for PASS conditions',
        'apply the exact-range and immutable-candidate rules in `.ai/contracts/REVIEW_RESULT.md`',
        'For requirement drift, use existing finding types instead of silently synchronizing documents and code',
        'Evidence that the approved approach or Task boundary itself is directionally wrong is an `architecture` finding',
        'A green test is evidence, not acceptance by itself',
        'three-way attribution',
        'never accept a new attempt ID as evidence that inherited Workflow bytes became user work',
        '.ai/contracts/REVIEW_RESULT.md#reduced-assurance-exception',
        'Independence removes the authoring session''s hidden reasoning and self-confirmation',
        '.ai/contracts/ACTION_CARDS.md#editorruntime-check',
        'a user action that saved a Task-attributed asset/config/source routes Builder for a fresh Build/Review identity',
        'they do not claim to prove long-term maintainability or transfer that ownership',
        'Never write `unchanged` or `the same` without naming the compared baseline',
        '.ai/contracts/ACTION_CARDS.md#working-summary',
        'checkpoint=commit_ready',
        'route=<knowledge_maintainer|work|builder|architect|integration|user>',
        'Work owns the exact policy-controlled local checkpoint and the optional `COMMIT_READY` projection',
        'independently verify the Build Result''s complete per-path roles and Source Map against the exact candidate',
        'it does not rewrite or dump the complete inventory',
        'change_brief=<none|brief|deep>',
        'code_inspection=<awaiting_user|shown_no_pause|not_applicable>',
        'Set `code_inspection=awaiting_user` only for an identity-revalidatable ordinary Task PASS with non-trivial hand-written production source under `before_next_task`',
        'Use `shown_no_pause` for that same eligible Task PASS under `no_pause`, a missing preference, or no-Git/unsealed assurance',
        'Use `not_applicable` for Integration Review, `fail`/`blocked`, or a purely mechanical/non-code PASS',
        'documented no-Git/unsealed changed-file manifest and path/symbol open sequence',
        'only when `code_inspection` is not `awaiting_user`',
        'direct Diff/source inspection support human code ownership',
        'Only `current_blocker` changes the current verdict/route',
        'distinguish `observed`, `inferred`, and `confirmed`',
        'Use the Action Cards terminology, bounded-expert-note, semantic-label',
        'Do not repeat the entire Builder suite merely for independence'
    )
    '.ai/roles/WORK.md' = @(
        'explicit current-status, Task-diff, source-reading, commit-readiness, or interaction-preference question',
        'without a user-visible Architect handoff or repeated approval',
        'stops at `ready_to_review`',
        'A terse token resumes only the semantic non-mutating action just displayed',
        'Use the exact executable `DO_NEXT` from `ACTION_CARDS.md` for cross-session transport',
        'preferences never authorize Push/tag, another content checkpoint, or an unreviewed candidate',
        'a feature boundary is only a safe checkpoint, not replacement evidence by itself',
        'if that threshold is not met, continue silently',
        '`before_next_task` uses the durable Reviewer-owned code-inspection wait only for revalidatable identity',
        'no-Git/unsealed shows without pausing',
        'deterministic revision repinning is closure, not another choice',
        'apply `OPERATIONS.md#bounded-diagnosis-during-active-delivery`',
        'User-facing status distinguishes the Work shell from the active project role',
        'run Architect''s bounded Feature convergence in the same compact Work session when possible',
        'Do not declare completion from the last Task PASS'
    )
    '.ai/roles/KNOWLEDGE_MAINTAINER.md' = @(
        '.ai/contracts/KNOWLEDGE.md',
        'A changed requirements document does not automatically rewrite Architecture or Tasks',
        'Mark only owned Knowledge entries that point to affected requirement refs `stale/conflict`; never edit the Architecture/Task artifacts',
        'Treat index/search/name matches as candidate refs',
        'Approved product/requirements/specification or planning documents are reference-only by default',
        'Do not infer document-authoring permission from a broad `Docs/**` directory',
        'An accepted single-main working-tree checkpoint returns to Work for the exact policy-controlled local checkpoint',
        'updates only `.ai/shared/knowledge/project.yaml#interaction`'
    )
    'maintenance/WORKFLOW_REVIEW.md' = @(
        'It is not the project `Reviewer`, a fifth runtime role, an installed `.ai` document',
        'Workflow Review is read-only',
        '`automated`',
        '`contract_trace`',
        '`human_judgment`',
        '`unverified`',
        '## README quality gate',
        'Judge the README as the Workflow''s first user interface',
        'Fold the result into lenses 1, 2, and 9',
        '## Bounded self-check',
        '`inverse`: for every finding, test the strongest non-defect explanation',
        '## Self-check evolution',
        'Self-check criteria are stable by default',
        '`no_change`: no candidate meets `adopted`',
        'The Reviewer cannot modify its criteria during the Review it is currently judging',
        'invariant | gate | default | presentation',
        'One personal observation is discovery evidence, not universal authority',
        'concise informed assent bound to one displayed outcome',
        'broad collaborative planning stay at one current design altitude',
        'Feature-boundary intent-to-code convergence',
        'living views, reference-only intent, and flow-forward evidence',
        'WORKFLOW_REVIEW RESULT=<pass|changes_required|blocked>',
        'independence=<independent_session|reduced_assurance>',
        'self_check=<pass|corrected|blocked> corrections=<n>',
        'must not have authored the candidate source changes',
        'release_recommendation=<ready|not_ready|not_assessed>',
        'include one detailed `[P2]...` finding per count'
    )
    'maintenance/RELEASE.md' = @(
        'workflow_review=<required_after_source_commit|not_run>',
        'workflow_review_independence: independent_session',
        'workflow_review_self_check: pass | corrected',
        'Copy the complete ten-lens review',
        'Set `eval_type: source_regression`',
        'Every counted P2 must have a detailed finding',
        'apply its mode-selection rule',
        'workflow_review_mode: <selected changed|full>',
        'A canonical PASS record requires every named case to be `pass`',
        'Before promoting an accepted candidate, classify its enforcement level',
        'A single personal observation normally remains a project preference'
    )
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

$installedUpdatePath = Get-RepositoryPath '.ai/maintenance/UPDATE.md'
if (Test-Path -LiteralPath $installedUpdatePath -PathType Leaf) {
    $installedUpdateText = Read-Utf8Text $installedUpdatePath
    $installedValidationSection = [regex]::Match(
        $installedUpdateText,
        '(?ms)^## Installed validation evidence\s*\r?\n(?<body>.*?)(?=^##\s|\z)'
    )
    $expectedInstalledValidationChecks = @(
        'managed_inventory',
        'preserved_schema_enums',
        'path_containment_classification',
        'reference_integrity',
        'markdown_language_policy',
        'runtime_state_preservation',
        'bootstrap_readiness'
    )

    if ($installedValidationSection.Success) {
        $installedValidationBody = $installedValidationSection.Groups['body'].Value
        $installedValidationRowCount = [regex]::Matches(
            $installedValidationBody,
            '(?m)^\|\s+`[^`]+`\s+\|'
        ).Count
        if ($installedValidationRowCount -ne $expectedInstalledValidationChecks.Count) {
            Add-Failure "UPDATE.md installed validation evidence must define exactly seven check rows, found: $installedValidationRowCount"
        }

        foreach ($installedValidationCheck in $expectedInstalledValidationChecks) {
            $rowPattern = '(?m)^\|\s+`' + [regex]::Escape($installedValidationCheck) + '`\s+\|'
            $rowCount = [regex]::Matches($installedValidationBody, $rowPattern).Count
            if ($rowCount -ne 1) {
                Add-Failure "UPDATE.md installed validation evidence must define exactly one row: check=$installedValidationCheck found=$rowCount"
            }
        }
    }
}

$canonicalPrinciplePath = Get-RepositoryPath '.ai/WORKFLOW.md'
$publicPrinciplePath = Get-RepositoryPath 'README.md'
if ((Test-Path -LiteralPath $canonicalPrinciplePath -PathType Leaf) -and
    (Test-Path -LiteralPath $publicPrinciplePath -PathType Leaf)) {
    $canonicalPrincipleText = Read-Utf8Text $canonicalPrinciplePath
    $publicPrincipleText = Read-Utf8Text $publicPrinciplePath
    $canonicalPrincipleSection = [regex]::Match(
        $canonicalPrincipleText,
        '(?ms)^## Design principles\s*\r?\n(?<body>.*?)(?=^##\s)'
    )
    $publicPrincipleSection = [regex]::Match(
        $publicPrincipleText,
        '(?ms)^<!-- public-philosophy-summary:[^\r\n]*-->\s*\r?\n(?<body>.*?)(?=^###\s)'
    )

    if (-not $canonicalPrincipleSection.Success) {
        Add-Failure 'WORKFLOW.md is missing the canonical Design principles section'
    }
    if (-not $publicPrincipleSection.Success) {
        Add-Failure 'README.md is missing the public philosophy summary section'
    }

    if ($canonicalPrincipleSection.Success -and $publicPrincipleSection.Success) {
        $canonicalPrincipleNumbers = New-Object 'System.Collections.Generic.List[int]'
        $canonicalPrincipleItems = New-Object 'System.Collections.Generic.List[string]'
        foreach ($principleMatch in [regex]::Matches(
                $canonicalPrincipleSection.Groups['body'].Value,
                '(?ms)^(?<item>(?<number>[0-9]+)\.[ \t]+\*\*.*?)(?=^[0-9]+\.[ \t]+\*\*|^[ \t]*\r?$)'
            )) {
            $canonicalPrincipleNumbers.Add([int]$principleMatch.Groups['number'].Value)
            $normalizedItem = ($principleMatch.Groups['item'].Value -replace "\r\n?", "`n").TrimEnd()
            $canonicalPrincipleItems.Add($normalizedItem)
        }

        $publicPrincipleNumbers = New-Object 'System.Collections.Generic.List[int]'
        foreach ($principleMatch in [regex]::Matches(
                $publicPrincipleSection.Groups['body'].Value,
                '(?m)^(?<number>[0-9]+)\.\s+\*\*'
            )) {
            $publicPrincipleNumbers.Add([int]$principleMatch.Groups['number'].Value)
        }

        for ($index = 0; $index -lt $canonicalPrincipleNumbers.Count; $index++) {
            if ($canonicalPrincipleNumbers[$index] -ne ($index + 1)) {
                Add-Failure "WORKFLOW.md Design principles must use a continuous 1-based sequence: index=$($index + 1) found=$($canonicalPrincipleNumbers[$index])"
                break
            }
        }
        for ($index = 0; $index -lt $publicPrincipleNumbers.Count; $index++) {
            if ($publicPrincipleNumbers[$index] -ne ($index + 1)) {
                Add-Failure "README public philosophy principles must use a continuous 1-based sequence: index=$($index + 1) found=$($publicPrincipleNumbers[$index])"
                break
            }
        }

        if ($canonicalPrincipleNumbers.Count -ne $publicPrincipleNumbers.Count) {
            Add-Failure "README public philosophy principle count does not match canonical Design principles: canonical=$($canonicalPrincipleNumbers.Count) public=$($publicPrincipleNumbers.Count)"
        }

        $expectedPublicMarker = "public-philosophy-summary: canonical-design-principles-1-through-$($canonicalPrincipleNumbers.Count)"
        if (-not $publicPrincipleText.Contains($expectedPublicMarker)) {
            Add-Failure "README public philosophy marker does not match canonical principle count: expected=$expectedPublicMarker"
        }

        $normalizedCanonicalPrinciples = (($canonicalPrincipleItems.ToArray() -join "`n") + "`n")
        $expectedPrincipleFingerprint = Get-Sha256Hex $normalizedCanonicalPrinciples
        $fingerprintMatch = [regex]::Match(
            $publicPrincipleText,
            '(?m)^<!-- public-philosophy-source-sha256:\s*(?<hash>[0-9a-f]{64})\s*-->$'
        )
        if (-not $fingerprintMatch.Success) {
            Add-Failure 'README public philosophy source fingerprint marker is missing or invalid'
        }
        elseif ($fingerprintMatch.Groups['hash'].Value -ne $expectedPrincipleFingerprint) {
            Add-Failure "README public philosophy source fingerprint does not match canonical Design principles: expected=$expectedPrincipleFingerprint found=$($fingerprintMatch.Groups['hash'].Value)"
        }
    }
}

$reviewerRolePath = Get-RepositoryPath '.ai/roles/REVIEWER.md'
if (Test-Path -LiteralPath $reviewerRolePath -PathType Leaf) {
    $reviewerRoleText = Read-Utf8Text $reviewerRolePath
    if ($reviewerRoleText -match '(?m)^PASS requires\b') {
        Add-Failure 'Reviewer role restates PASS conditions; .ai/contracts/REVIEW_RESULT.md is the single authority'
    }
}

$workflowReviewPath = Get-RepositoryPath 'maintenance/WORKFLOW_REVIEW.md'
if (Test-Path -LiteralPath $workflowReviewPath -PathType Leaf) {
    $workflowReviewText = Read-Utf8Text $workflowReviewPath
    $workflowReviewLensCount = [regex]::Matches(
        $workflowReviewText,
        '(?m)^\| (?:[1-9]|10)\. [^|]+ \|'
    ).Count
    if ($workflowReviewLensCount -ne 10) {
        Add-Failure "Workflow Review must define exactly 10 review lenses, found: $workflowReviewLensCount"
    }

    $workflowReviewSummaryPath = Get-RepositoryPath 'README.md'
    if (Test-Path -LiteralPath $workflowReviewSummaryPath -PathType Leaf) {
        $workflowReviewSummaryText = Read-Utf8Text $workflowReviewSummaryPath
        $expectedWorkflowReviewSummary = "workflow-review-summary: canonical-lenses-1-through-$workflowReviewLensCount"
        if (-not $workflowReviewSummaryText.Contains($expectedWorkflowReviewSummary)) {
            Add-Failure "README Workflow Review marker does not match canonical lens count: expected=$expectedWorkflowReviewSummary"
        }
    }
}

$releaseVersion = Get-YamlScalar '.ai/maintenance/release.yaml' 'workflow_version'
$releaseDate = Get-YamlScalar '.ai/maintenance/release.yaml' 'released_at'
$installedVersion = Get-YamlScalar '.ai/maintenance/update-state.yaml' 'installed_version'
$updateTemplateVersion = Get-YamlScalar '.ai/maintenance/update-state.template.yaml' 'installed_version'
$scorecardVersion = Get-YamlScalar '.ai/evals/SCORECARD.md' 'workflow_version'

if ($null -ne $releaseVersion -and $releaseVersion -notmatch '^manual-v\d+\.\d+$') {
    Add-Failure "Invalid release version format: $releaseVersion"
}
if ($null -ne $releaseDate -and $releaseDate -notmatch '^\d{4}-\d{2}-\d{2}$') {
    Add-Failure "Invalid released_at date format: $releaseDate"
}
if ($null -ne $releaseVersion -and $null -ne $installedVersion -and $releaseVersion -ne $installedVersion) {
    Add-Failure "Version mismatch: release=$releaseVersion installed=$installedVersion"
}
if ($null -ne $releaseVersion -and $null -ne $updateTemplateVersion -and $releaseVersion -ne $updateTemplateVersion) {
    Add-Failure "Version mismatch: release=$releaseVersion update_template=$updateTemplateVersion"
}
if ($null -ne $scorecardVersion -and $scorecardVersion -ne 'null') {
    Add-Failure "SCORECARD.md is a reusable template and must keep workflow_version: null"
}

Assert-YamlScalar '.ai/maintenance/release.yaml' 'schema_version' '1'
Assert-YamlScalar '.ai/maintenance/update-state.yaml' 'schema_version' '1'
Assert-YamlScalar '.ai/maintenance/update-state.template.yaml' 'schema_version' '1'
Assert-YamlScalar '.ai/maintenance/managed-paths.yaml' 'schema_version' '1'
Assert-YamlScalar '.ai/maintenance/managed-paths.yaml' 'install_root' '.ai'
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

$releaseRepository = Get-YamlScalarAnyIndent '.ai/maintenance/release.yaml' 'repository'
if ($null -ne $releaseRepository -and ($releaseRepository -eq 'null' -or $releaseRepository -notmatch '^https://[^/]+/.+')) {
    Add-Failure 'release.yaml source.repository must be a non-null HTTPS repository URL'
}
$releaseRef = Get-YamlScalarAnyIndent '.ai/maintenance/release.yaml' 'release_ref'
if ($null -ne $releaseRef -and ($releaseRef -eq 'null' -or $releaseRef -notmatch '^[A-Za-z0-9][A-Za-z0-9._/-]*$')) {
    Add-Failure 'release.yaml source.release_ref must be a non-null immutable ref label'
}
Assert-YamlScalar '.ai/lanes/_template/lane.yaml' 'status' 'uninitialized'
Assert-YamlScalar '.ai/lanes/_template/state.yaml' 'phase' 'uninitialized'
Assert-YamlScalar '.ai/lanes/_template/state.yaml' 'status' 'idle'
Assert-YamlScalar '.ai/lanes/_template/state.yaml' 'action' 'initialize_lane' -AnyIndent
Assert-YamlScalar '.ai/shared/SYSTEM_ARCHITECTURE.md' 'requirement_refs' '[]'
Assert-YamlScalar '.ai/shared/knowledge/project.yaml' 'entrypoints' '[]'
Assert-YamlScalar '.ai/shared/knowledge/project.yaml' 'checkpoint' 'auto_after_pass' -AnyIndent
Assert-YamlScalar '.ai/shared/knowledge/project.yaml' 'routine_continuation' 'one_task' -AnyIndent
Assert-YamlScalar '.ai/shared/knowledge/project.yaml' 'code_inspection' 'no_pause' -AnyIndent
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
    foreach ($classifiedPattern in @($managedPatterns + $preservedPatterns)) {
        $normalizedClassifiedPattern = $classifiedPattern -replace '\\', '/'
        if ($classifiedPattern.Contains('\') -or
            $normalizedClassifiedPattern -notmatch '^\.ai(?:/|$)' -or
            $normalizedClassifiedPattern -match '(^|/)\.\.(?:/|$)' -or
            $normalizedClassifiedPattern -match '^[A-Za-z]:' -or
            $normalizedClassifiedPattern.StartsWith('/') -or
            $normalizedClassifiedPattern.StartsWith('//')) {
            Add-Failure "Managed/preserved pattern escapes the .ai install root: $classifiedPattern"
        }
    }

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

$maintenanceIgnorePath = Get-RepositoryPath '.ai/maintenance/.gitignore'
if (Test-Path -LiteralPath $maintenanceIgnorePath -PathType Leaf) {
    $maintenanceIgnoreLines = @((Read-Utf8Text $maintenanceIgnorePath) -split '\r?\n')
    foreach ($requiredIgnore in @('backups/', 'staging/', 'observations/OBS-*.yaml', 'update-state.yaml')) {
        if ($maintenanceIgnoreLines -notcontains $requiredIgnore) {
            Add-Failure "Installed maintenance .gitignore is missing local-state rule: $requiredIgnore"
        }
    }
}

$rootLicensePath = Get-RepositoryPath 'LICENSE'
$installedLicensePath = Get-RepositoryPath '.ai/LICENSE'
if ((Test-Path -LiteralPath $rootLicensePath -PathType Leaf) -and
    (Test-Path -LiteralPath $installedLicensePath -PathType Leaf)) {
    $rootLicenseText = (Read-Utf8Text $rootLicensePath) -replace '\r\n', "`n"
    $installedLicenseText = (Read-Utf8Text $installedLicensePath) -replace '\r\n', "`n"
    if ($rootLicenseText -ne $installedLicenseText) {
        Add-Failure 'Installable .ai/LICENSE must match the distribution root LICENSE'
    }
}

$goldenCorePath = Get-RepositoryPath '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
if (Test-Path -LiteralPath $goldenCorePath -PathType Leaf) {
    $goldenCoreText = Read-Utf8Text $goldenCorePath
    foreach ($goldenToken in @(
            '## Fixture 1',
            '## Fixture 2',
            '## Fixture 3',
            '## Fixture 4',
            '## Fixture 5',
            '## Fixture 6',
            '## Fixture 7',
            '## Fixture 8',
            '## Fixture 9',
            '## Fixture 10',
            '## Fixture 11',
            '## Fixture 12',
            '## Fixture 13',
            '## Fixture 14',
            '## Fixture 15',
            '## Fixture 16',
            '## Fixture 17',
            '## Fixture 18',
            '## Fixture 19',
            '## Fixture 20',
            '## Fixture 21',
            '## Fixture 22',
            '## Fixture 23',
            '## Fixture 24',
            'The canonical trigger list and case routing live there; do not maintain a second list in this file',
            'the Task PASS first routes Architect''s bounded Feature convergence, then state transitions to `synced/idle` without an empty Knowledge handoff or user confirmation',
            'A Task PASS is not by itself a Feature-completion claim',
            'The historical variant reconstructs a candidate outcome map from approved Scope, intent/requirement refs, Tasks, and accepted Reviews',
            'Only a user-approved deferral may rest at `synced/idle`',
            'An `open` outcome always wins over a terminal path',
            '`synced/idle` requires every current-scope outcome to be `implemented`, `excluded`, or `deferred`',
            'Convergence reads production source but writes only its existing role-owned Architecture, next Task, and state artifacts',
            '`base` is the fixed first manifest line',
            'untracked regular file uses literal `regular`',
            'C returns `READY` and is the only proposed slice that may reach Builder',
            'approved intent/requirement ref -> current Architecture delivery slice -> Task Goal/ACs -> verification',
            'Related constraints and evidence may be batched while evaluating the same slice, but batching never crosses a pending consequential approval',
            'state becomes `ready_to_build/blocked`',
            'state becomes `building/blocked`',
            'Knowledge marks only its owned document/feature entries `stale/conflict`; it never edits Architecture/Task artifacts',
            'A changed requirement revision never silently authorizes Build or rewrites product intent from code',
            'Artifact lifetime remains distinct from fact authority',
            'A Worktree or shared read-write workspace mount is not accepted as execution isolation',
            'BLOCKED type=context owner=user',
            'emits a complete User Action Card',
            'a `sandbox` label alone is not accepted as evidence of effective filesystem, credential, and network containment',
            'The bounded inverse control may proceed under normal role/Lane scope and available approval controls',
            'The bounded dependency restore may proceed under normal role/Lane scope',
            'Reviewer classifies the problem as `architecture`, not repeated `implementation`',
            'the replacement Task classifies every Task-attributed dirty path as `retain`, `adapt`, or `remove`',
            'destructive rollback is never automatic',
            'The candidate source root is not required to be inside the target project or `P/.ai`',
            'Every backup, staging, migration-write, restore, and destination remains inside `P/.ai`',
            'candidate symlink/reparse escape',
            'before any escaping source is read or copied',
            'Passing one containment check cannot satisfy or weaken the other',
            'Apply is bound to the checked revision/tree and canonical input manifest, not the locator name',
            'The transaction manifest records an immutable present/absent pre-state and a completed mutation record with output identity',
            'Installed validation evidence contains exactly the seven named profile rows with a concrete observed result and evidence path/output',
            'rollback removes only the transaction-created path',
            'verifies byte-identical present/absent/type/hash/link state',
            'Knowledge Maintainer and Architect treat every name, keyword, similarity, or nearby-example hit as a candidate rather than evidence',
            'Only the confirmed live source may support the answer or design',
            'only as an untrusted source candidate and does not begin Check until the user explicitly confirms it',
            'An existing managed installation uses Check/Apply rather than a folder overlay',
            'The same session does not interpret the generic request as reduced-assurance consent',
            'The resulting verdict is never used as canonical release evidence, Integration Gate evidence',
            'The evaluative seed is a valid problem signal',
            'No Task reaches Builder until evidence or the user''s response resolves the diagnosis into observable acceptance criteria',
            'The green checks do not authorize PASS for the second candidate',
            'repeated edits across unrelated owners for the same small behavior are concrete change-pressure evidence',
            'E is reframed into narrow end-to-end/vertical outcomes',
            'No separate Program Design artifact, session, score, or user gate is created',
            'changed Task bytes with an unchanged approved boundary return to `ready_to_build/active`',
            'Every already-dirty Build baseline path is classified as `unrelated_pre_existing`, `inherited_task`, or `unknown`',
            'If Reviewer rejects preflight, state becomes `ready_to_review/blocked`',
            '`update-state.yaml.active_transaction_manifest` durably points inside the backup root',
            'each result is `pass | fail`',
            'No next Task is materialized over the uncommitted accepted candidate',
            'The unchanged-identity scenario emits `RESUME_SAME_LANE`',
            'without depending on the exhausted chat',
            'Knowledge indexes only applicable planning sections/revisions',
            'Reviewer returns an `EDITOR_CHECK` that names effect, purpose, exact app/project/target/surface',
            'the saved bytes invalidate the old Build/Review identity and route a fresh Build attempt',
            'there is no user-visible Architect handoff or repeated approval',
            'Missing preferences read as `auto_after_pass + one_task`',
            'The Reviewer `DO_NEXT` is transport rather than approval',
            'No preference or short continuation ever authorizes hidden paths, a new Architecture Gate, external effects, Push/tag, history rewrite, or another commit',
            'The role returns one terminal-screen `WORKING_SUMMARY` derived from durable evidence',
            'external prerequisite study is optional, never required for approval or continuation',
            'Scenario C does not accept an uninformed affirmative reply',
            'The broad collaborative seed first receives one compact collaboration frame',
            '`needed now` filters every question, detail expansion, and planning write',
            'A concise assent to one decision-ready outcome remains valid, but an explicit surrender signal never becomes product authority',
            '`request and retry behavior is unchanged` is not accepted alone',
            'The same explanation contract applies across service/API, CLI/library, and editor/runtime work',
            'Viability is assessed only at the natural boundary, not reported every turn',
            'Scenario C also continues because chat age or turn count alone is not evidence',
            'Scenarios B and D do not start the next substantial action',
            'never claims completion or weakens candidate/Review identity to squeeze in another step',
            'Builder gives one non-blocking source orientation no later than the first coherent non-trivial production edit',
            'The Build Result `Changes`/`Source Map` is the one complete revision-scoped inventory',
            'Reviewer independently reconciles that map with the exact candidate',
            'The chat `primary_read` contains only three-to-five `R#` anchors',
            'internal tokens such as `inspected_continue` or an unqualified `explain_2` never replace their meaning',
            'A Change Brief, Review artifact link, directory list, or selected hunk alone does not satisfy the walkthrough',
            '`accepted/active + next.role: reviewer + next.action: await_code_inspection_then_resume_review_route`',
            'A replacement Reviewer reconstructs the same walkthrough and route from state',
            'A mechanical/generated-only or non-code PASS returns `not_applicable`',
            'The no-Git variant records `snapshot=no-git/unsealed`',
            'It returns `shown_no_pause` even when the project opted in',
            'New-scaffold `no_pause` and historical missing `code_inspection` both return `shown_no_pause`',
            'The pause applies to ordinary Task Review on `main` or non-`main`; Integration Review returns `not_applicable`',
            'Matching path names, timestamps, a Changes-table inventory, or a later commit do not upgrade an earlier unsealed candidate or transfer its evidence',
            'The reply controls pace only: it does not approve correctness, certify permanent understanding',
            'If the user edits/saves candidate bytes, the old PASS is not reused',
            'state enters `accepted/blocked` with `resolve_code_inspection_attribution_then_resume_reviewer_inspection_wait`',
            'Proven unrelated/pre-existing bytes with unchanged candidate identity restore the same Reviewer inspection wait',
            'No second inventory, exhaustive permanent catalog, new role/session/card, quiz, score, or approval Gate is created',
            'Completed historical Build/Review Results with inline Review source roles or no Build Source Map remain readable without migration',
            'The first decision screen leads with one plain question, marks the recommendation, and shows every currently viable alternative together',
            'This general checkpoint decision begins directly with `DECISION`',
            'The four-outcome decision first asks one discriminator with no more than three mutually exclusive, collectively exhaustive groups',
            'records every outcome under exactly one group in the explicit `groups` field',
            'A number or letter may be accepted only as a short alias after the readable atomic choices are displayed',
            'The untested partial commit is not offered as a selectable strategy',
            'Required metadata repinning is deterministic checkpoint closure, not another user option',
            '`DEV_STATUS` reports `checkpoint=content_committed_repin_pending`',
            '`COMMIT_READY` asks only whether to create the displayed checkpoint',
            'If only one materially safe path remains, the role reports or executes that predetermined action under existing authority',
            'The first Architect response begins with `current_behavior`, `intended_behavior`, and `confirmed_gap`',
            'The unspecified internal mechanism is `implementation_open`',
            'The unspecified later user-visible behavior is `product_open`',
            'already disproven technical approach is shown only as rejected evidence',
            'A fresh independent Reviewer still reconstructs the approved user need from exact requirement refs',
            'a non-trivial change may add one bounded expert note by default',
            'The expert note never precedes or obscures the action',
            'When confusion or fatigue is signaled, the role simplifies the core before adding depth',
            'Before proposing a cause, choice, or new Task, the role reconstructs and states the exact approved observable outcome',
            'The viable repair set is filtered by approved observable intent, ownership, responsibility, and dependency direction before implementation or test convenience is compared',
            'The boundary-violating workaround is rejected evidence rather than a user choice',
            'Claims are labeled `observed | inferred | confirmed`',
            'all observations available in the same surface are batched in inspection order',
            'A structural authoring card shows the plain whole behavior flow and exact finished screen/graph shape before mechanics',
            'remains understandable without prior-chat memory or "same as last time"',
            'It never calls an uninspected insertion/wiring position safe',
            'A user-facing status distinguishes the Work shell from the active project role',
            'a mutation is never disguised as the safe-stop fallback',
            'An evidenced non-blocking issue is `follow_up` behind the current result without a Task, Gate, handoff, or broader Review',
            'Delivery focus never hides a current blocker merely to reach a checkpoint faster',
            'Architecture, Task, state, and Knowledge record only confirmed or approved facts',
            'All planned implementation and authoring stays in one Build attempt until one coherent candidate exists',
            'the documentation-only correction does not trigger an unchanged build/test suite',
            'obtains one successful final affected-suite result',
            'Known Task-scoped user/editor saves return `awaiting_user_authoring`',
            'Reviewer verifies evidence scope/oracle and candidate identity, then reruns the smallest decisive affordable subset',
            'Saving tokens never removes a mandatory AC, safety check, release gate, or final evidence'
        )) {
        if (-not $goldenCoreText.Contains($goldenToken)) {
            Add-Failure "Golden Core Behavior is missing oracle token: $goldenToken"
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

    $localUpdateStateScaffold = '.ai/maintenance/update-state.yaml'
    if ($distributionInventory -contains $localUpdateStateScaffold -and
        (Invoke-GitExitCode @('ls-files', '--error-unmatch', '--', $localUpdateStateScaffold)) -ne 0) {
        Add-Failure "Canonical distribution must force-track ignored local scaffold: $localUpdateStateScaffold (installed projects ignore it and Bootstrap can regenerate it from update-state.template.yaml)"
    }
}

$changelogPath = Get-RepositoryPath '.ai/maintenance/CHANGELOG.md'
$changelogVersions = @{}
if (Test-Path -LiteralPath $changelogPath -PathType Leaf) {
    $changelog = Read-Utf8Text $changelogPath
    $releaseHeadingLines = [regex]::Matches($changelog, '(?m)^##\s+manual-v[^\r\n]*$')
    $releaseHeadings = [regex]::Matches(
        $changelog,
        '(?m)^##\s+(?<version>manual-v(?<major>\d+)\.(?<minor>\d+))\s+\u2014\s+(?<date>\d{4}-\d{2}-\d{2})\s*$'
    )

    if ($releaseHeadings.Count -eq 0) {
        Add-Failure 'CHANGELOG.md has no valid release heading'
    }
    else {
        $latestChangelogVersion = $releaseHeadings[0].Groups['version'].Value
        if ($null -ne $releaseVersion -and $latestChangelogVersion -ne $releaseVersion) {
            Add-Failure "Latest CHANGELOG release must match release.yaml: release=$releaseVersion changelog=$latestChangelogVersion"
        }
        $latestChangelogDate = $releaseHeadings[0].Groups['date'].Value
        if ($null -ne $releaseDate -and $latestChangelogDate -ne $releaseDate) {
            Add-Failure "Latest CHANGELOG release date must match release.yaml: release=$releaseDate changelog=$latestChangelogDate"
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
        Add-Failure 'CHANGELOG.md contains a malformed manual release heading; expected: ## manual-vX.Y - YYYY-MM-DD'
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
$sourceCommitPathCache = @{}
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
            $evalType = Get-MarkdownFrontMatterScalar $relativeEvalPath 'eval_type'
            $sourceSnapshotCurrent = $true
            $workflowReviewRequired = Test-ManualVersionAtLeast $runVersion 'manual-v1.1'
            $workflowReviewEligible = -not $workflowReviewRequired
            $releaseTypeEligible = if ($workflowReviewRequired) {
                $evalType -eq 'source_regression'
            }
            else {
                $evalType -match '^(source_regression|fixed_contract)$'
            }

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
            if ($evalType -notmatch '^(source_regression|end_to_end|fixed_contract)$') {
                Add-Failure "Invalid Eval eval_type: path=$relativeEvalPath eval_type=$evalType"
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

            if ($workflowReviewRequired) {
                $workflowReviewResult = Get-MarkdownFrontMatterScalar $relativeEvalPath 'workflow_review_result'
                $workflowReviewMode = Get-MarkdownFrontMatterScalar $relativeEvalPath 'workflow_review_mode'
                $workflowReviewIndependence = Get-MarkdownFrontMatterScalar $relativeEvalPath 'workflow_review_independence'
                $workflowReviewSelfCheck = Get-MarkdownFrontMatterScalar $relativeEvalPath 'workflow_review_self_check'
                $workflowReviewSection = [regex]::Match(
                    $evalText,
                    '(?ms)^## Workflow Review\s*\r?\n(?<body>.*?)(?=^## |\z)'
                )
                $workflowReviewLensFailure = $false
                $workflowReviewLensComplete = $workflowReviewSection.Success

                if ($workflowReviewResult -notmatch '^(pass|changes_required|blocked)$') {
                    Add-Failure "Invalid release Workflow Review result: path=$relativeEvalPath result=$workflowReviewResult"
                    $recordValid = $false
                }
                if ($workflowReviewMode -notmatch '^(changed|full)$') {
                    Add-Failure "Invalid release Workflow Review mode: path=$relativeEvalPath mode=$workflowReviewMode"
                    $recordValid = $false
                }
                if ($workflowReviewIndependence -notmatch '^(independent_session|reduced_assurance)$') {
                    Add-Failure "Invalid release Workflow Review independence: path=$relativeEvalPath independence=$workflowReviewIndependence"
                    $recordValid = $false
                }
                if ($workflowReviewSelfCheck -notmatch '^(pass|corrected|blocked)$') {
                    Add-Failure "Invalid release Workflow Review self-check: path=$relativeEvalPath self_check=$workflowReviewSelfCheck"
                    $recordValid = $false
                }
                if (-not $workflowReviewSection.Success) {
                    Add-Failure "Release Eval is missing section 'Workflow Review': $relativeEvalPath"
                    $recordValid = $false
                }
                else {
                    $workflowReviewBody = $workflowReviewSection.Groups['body'].Value
                    foreach ($lensNumber in 1..10) {
                        $lensRow = Get-MarkdownTableRow $workflowReviewBody ([string]$lensNumber)
                        if (-not $lensRow.Success -or
                            [string]::IsNullOrWhiteSpace($lensRow.Groups['evidence'].Value) -or
                            $lensRow.Groups['value'].Value.Trim() -notmatch '^(?i:pass|partial|fail|n/a)$') {
                            Add-Failure "Release Workflow Review needs result/evidence for lens '$lensNumber': $relativeEvalPath"
                            $workflowReviewLensComplete = $false
                            $recordValid = $false
                            continue
                        }
                        if ($lensRow.Groups['value'].Value.Trim() -match '^(?i:fail)$') {
                            $workflowReviewLensFailure = $true
                        }
                    }

                    $findingsMatch = [regex]::Match(
                        $workflowReviewBody,
                        '(?im)^- findings:\s*P1:(?<p1>\d+),\s*P2:(?<p2>\d+),\s*P3:(?<p3>\d+)\s*$'
                    )
                    $p2Count = $null
                    if (-not $findingsMatch.Success) {
                        Add-Failure "Release Workflow Review needs canonical findings counts: $relativeEvalPath"
                        $recordValid = $false
                    }
                    else {
                        $p2Count = [int]$findingsMatch.Groups['p2'].Value
                        if ($workflowReviewResult -eq 'pass' -and $findingsMatch.Groups['p1'].Value -ne '0') {
                            Add-Failure "Workflow Review result=pass conflicts with P1 findings: $relativeEvalPath"
                            $recordValid = $false
                        }
                        $p2DetailCount = [regex]::Matches(
                            $workflowReviewBody,
                            '(?im)^\s*\[P2\](?:\[[^\r\n]+\])*\s+.+$'
                        ).Count
                        if ($p2DetailCount -lt $p2Count) {
                            Add-Failure "Workflow Review P2 findings require matching detailed entries: path=$relativeEvalPath count=$p2Count detailed=$p2DetailCount"
                            $recordValid = $false
                        }
                    }

                    $deferredP2Match = [regex]::Match(
                        $workflowReviewBody,
                        '(?im)^- deferred P2:\s*(?<value>\S.+)$'
                    )
                    if (-not $deferredP2Match.Success) {
                        Add-Failure "Release Workflow Review must record deferred P2 evidence or none: $relativeEvalPath"
                        $recordValid = $false
                    }
                    elseif ($null -ne $p2Count) {
                        $deferredP2Value = $deferredP2Match.Groups['value'].Value.Trim()
                        if ($p2Count -eq 0 -and $deferredP2Value -ne 'none') {
                            Add-Failure "Workflow Review with P2:0 must record deferred P2: none: $relativeEvalPath"
                            $recordValid = $false
                        }
                        elseif ($p2Count -gt 0 -and $deferredP2Value -eq 'none') {
                            Add-Failure "Workflow Review with P2 findings cannot record deferred P2: none: $relativeEvalPath"
                            $recordValid = $false
                        }
                        elseif ($p2Count -gt 0 -and $deferredP2Value -notmatch '(?i)(evidence|proof)') {
                            Add-Failure "Workflow Review deferred P2 needs follow-up evidence/proof: $relativeEvalPath"
                            $recordValid = $false
                        }
                    }
                    $selfCheckMatch = [regex]::Match(
                        $workflowReviewBody,
                        '(?im)^- self-check:\s*(?<value>pass|corrected|blocked)\s*$'
                    )
                    $correctionsMatch = [regex]::Match(
                        $workflowReviewBody,
                        '(?im)^- corrections:\s*(?<value>\S.+)\s*$'
                    )
                    if (-not $selfCheckMatch.Success) {
                        Add-Failure "Release Workflow Review must record its bounded self-check: $relativeEvalPath"
                        $recordValid = $false
                    }
                    elseif ($selfCheckMatch.Groups['value'].Value.ToLowerInvariant() -ne $workflowReviewSelfCheck) {
                        Add-Failure "Workflow Review self-check front matter/body mismatch: $relativeEvalPath"
                        $recordValid = $false
                    }
                    if (-not $correctionsMatch.Success) {
                        Add-Failure "Release Workflow Review must record corrections or none: $relativeEvalPath"
                        $recordValid = $false
                    }
                    elseif ($workflowReviewSelfCheck -eq 'pass' -and
                        $correctionsMatch.Groups['value'].Value.Trim() -ne 'none') {
                        Add-Failure "Workflow Review self_check=pass requires corrections=none: $relativeEvalPath"
                        $recordValid = $false
                    }
                    elseif ($workflowReviewSelfCheck -eq 'corrected' -and
                        $correctionsMatch.Groups['value'].Value.Trim() -eq 'none') {
                        Add-Failure "Workflow Review self_check=corrected requires a correction reason: $relativeEvalPath"
                        $recordValid = $false
                    }
                    if (-not [regex]::IsMatch($workflowReviewBody, '(?im)^- release recommendation:\s*(ready|not_ready|not_assessed)\s*$')) {
                        Add-Failure "Release Workflow Review needs a valid release recommendation: $relativeEvalPath"
                        $recordValid = $false
                    }
                }

                $workflowReviewEligible = $workflowReviewResult -eq 'pass' -and
                    $workflowReviewIndependence -eq 'independent_session' -and
                    $workflowReviewSelfCheck -match '^(pass|corrected)$' -and
                    $workflowReviewLensComplete -and
                    -not $workflowReviewLensFailure

                if ($runResult -eq 'pass' -and -not $workflowReviewEligible) {
                    Add-Failure "Eval result=pass requires an independent passing Workflow Review: $relativeEvalPath"
                    $recordValid = $false
                }
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

                    if ($RequireReleaseEvidence -and
                        $null -ne $releaseVersion -and
                        $runVersion -eq $releaseVersion) {
                        if (-not $sourceCommitPathCache.ContainsKey($sourceRevision)) {
                            $sourceCommitPathText = Get-GitText @('ls-tree', '-r', '--name-only', $sourceRevision, '--')
                            if ($null -eq $sourceCommitPathText) {
                                Add-Failure "Cannot inspect Eval source commit inventory: path=$relativeEvalPath source=$sourceRevision"
                                $recordValid = $false
                            }
                            else {
                                $sourceCommitPaths = @{}
                                foreach ($sourceCommitPath in @($sourceCommitPathText -split "`n")) {
                                    $normalizedSourceCommitPath = $sourceCommitPath.Trim() -replace '\\', '/'
                                    if (-not [string]::IsNullOrWhiteSpace($normalizedSourceCommitPath)) {
                                        $sourceCommitPaths[$normalizedSourceCommitPath] = $true
                                    }
                                }
                                $sourceCommitPathCache[$sourceRevision] = $sourceCommitPaths
                            }
                        }

                        if ($sourceCommitPathCache.ContainsKey($sourceRevision)) {
                            $sourceCommitPaths = $sourceCommitPathCache[$sourceRevision]
                            foreach ($inventoryEntry in $distributionInventory) {
                                if (-not $sourceCommitPaths.ContainsKey($inventoryEntry)) {
                                    Add-Failure "Eval source commit is missing distribution inventory file: path=$relativeEvalPath source=$sourceRevision missing=$inventoryEntry"
                                    $recordValid = $false
                                }
                            }
                        }
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
                $caseResult = $caseRow.Groups['value'].Value.Trim().ToLowerInvariant()
                if ($caseResult -eq 'fail') {
                    $caseFailureFound = $true
                }
                if ($evalType -eq 'source_regression' -and $runResult -eq 'pass' -and $caseResult -ne 'pass') {
                    Add-Failure "Canonical source_regression PASS requires case result=pass: path=$relativeEvalPath case=$runCase result=$caseResult"
                    $recordValid = $false
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
                $sourceSnapshotCurrent -and
                $workflowReviewEligible -and
                $releaseTypeEligible
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

$markdownFiles = @(Get-ChildItem -LiteralPath $RepositoryRoot -Recurse -File -Force -Filter '*.md' |
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
