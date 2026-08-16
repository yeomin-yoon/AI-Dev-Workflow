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

$tempBase = Join-Path ([System.IO.Path]::GetTempPath()) 'ai-dev-workflow-validation-fixtures'
$runRoot = Join-Path $tempBase ([guid]::NewGuid().ToString('N'))
$hostExecutable = if ($PSVersionTable.PSEdition -eq 'Desktop') {
    Join-Path $PSHOME 'powershell.exe'
}
else {
    (Get-Command pwsh -ErrorAction Stop).Source
}

function Assert-SafeFixturePath {
    param([string]$Path)

    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $fullBase = [System.IO.Path]::GetFullPath($tempBase) + [System.IO.Path]::DirectorySeparatorChar
    if (-not $fullPath.StartsWith($fullBase, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Fixture path escaped the temp root: $fullPath"
    }
}

function New-Fixture {
    param([string]$Name)

    $fixtureRoot = Join-Path $runRoot $Name
    Assert-SafeFixturePath $fixtureRoot
    $null = New-Item -ItemType Directory -Path $fixtureRoot -Force
    foreach ($entry in @('.ai', '.github', 'tools', 'maintenance', 'evals', 'README.md', 'LICENSE', '.gitignore', '.gitattributes')) {
        $source = Join-Path $RepositoryRoot $entry
        if (Test-Path -LiteralPath $source) {
            Copy-Item -LiteralPath $source -Destination $fixtureRoot -Recurse -Force
        }
    }

    # Source Eval records are bound to the repository's real Git graph. Generic
    # fixtures create their own Git-backed records when release evidence is in
    # scope, so importing source history into a detached fixture is invalid.
    $copiedEvalRuns = Join-Path $fixtureRoot 'evals/runs'
    if (Test-Path -LiteralPath $copiedEvalRuns -PathType Container) {
        foreach ($sourceEval in @(Get-ChildItem -LiteralPath $copiedEvalRuns -File -Filter 'EVAL-*.md')) {
            Assert-SafeFixturePath $sourceEval.FullName
            Remove-Item -LiteralPath $sourceEval.FullName -Force
        }
    }

    return $fixtureRoot
}

function Invoke-Validation {
    param(
        [string]$FixtureRoot,
        [switch]$RequireReleaseEvidence
    )

    $validator = Join-Path $FixtureRoot 'tools/validate-workflow.ps1'
    $arguments = @('-NoProfile')
    if ([System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT) {
        $arguments += @('-ExecutionPolicy', 'Bypass')
    }
    $arguments += @('-File', $validator, '-RepositoryRoot', $FixtureRoot)
    if ($RequireReleaseEvidence) {
        $arguments += '-RequireReleaseEvidence'
    }
    $output = @(& $hostExecutable @arguments 2>&1)
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Text = ($output -join "`n")
    }
}

function Initialize-FixtureGit {
    param([string]$FixtureRoot)

    $previousErrorAction = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        & git -C $FixtureRoot init -q 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'Fixture git init failed' }
        & git -C $FixtureRoot config user.name 'Validation Fixture' 2>&1 | Out-Null
        & git -C $FixtureRoot config user.email 'validation@example.invalid' 2>&1 | Out-Null
        & git -C $FixtureRoot config core.autocrlf false 2>&1 | Out-Null
        & git -C $FixtureRoot add --all 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'Fixture git add failed' }
        & git -C $FixtureRoot add -f -- .ai/maintenance/update-state.yaml 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'Fixture local update-state add failed' }
        & git -C $FixtureRoot commit -q -m 'fixture source' 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'Fixture source commit failed' }
    }
    finally {
        $ErrorActionPreference = $previousErrorAction
    }
}

function Write-ModernEval {
    param(
        [string]$FixtureRoot,
        [ValidateSet('pass', 'fail')][string]$Result,
        [ValidateSet('source_regression', 'end_to_end', 'fixed_contract')][string]$EvalType = 'source_regression',
        [ValidateSet('changed', 'full')][string]$WorkflowReviewMode = 'changed'
    )

    $sourceRevision = (& git -C $FixtureRoot rev-parse HEAD).Trim()
    $sourceTree = (& git -C $FixtureRoot rev-parse 'HEAD^{tree}').Trim()
    $releasePath = Join-Path $FixtureRoot '.ai/maintenance/release.yaml'
    $releaseText = [System.IO.File]::ReadAllText($releasePath, [System.Text.Encoding]::UTF8)
    $releaseMatch = [regex]::Match($releaseText, '(?m)^workflow_version:\s*(?<value>manual-v\d+\.\d+)\s*$')
    if (-not $releaseMatch.Success) {
        throw 'Fixture release version is missing or invalid'
    }
    $workflowVersion = $releaseMatch.Groups['value'].Value
    $quality = if ($Result -eq 'pass') { 'pass' } else { 'fail' }
    $accepted = if ($Result -eq 'pass') { 'yes' } else { 'no' }
    $target = Join-Path $FixtureRoot "evals/runs/EVAL-20990101T000000000Z-test-${workflowVersion}-${Result}.md"
    $content = @"
---
schema_version: 2
id: EVAL-20990101T000000000Z-test-$workflowVersion-$Result
status: completed
result: $Result
completed_at: 2099-01-01T00:00:00.000Z
source_revision: $sourceRevision
source_tree: $sourceTree
quality_floor: $quality
seed: "fixture"
lane: template
provider: test
host_tool: test
model: test
reasoning: test
optional_interventions: []
user_language: ko
workflow_version: $workflowVersion
eval_type: $EvalType
workflow_review_result: pass
workflow_review_mode: $WorkflowReviewMode
workflow_review_independence: independent_session
workflow_review_self_check: pass
regression_cases:
  - source-validation
---

# Workflow Eval

## Core Result

| Metric | Value | Evidence |
|---|---|---|
| accepted | $accepted | fixture evidence |
| quality floor passed | $quality | fixture evidence |

## Targeted Regressions

| Case | Result | Evidence |
|---|---|---|
| source-validation | $Result | fixture evidence |

## Workflow Review

| Lens | Result | Evidence |
|---|---|---|
| 1 | PASS | fixture evidence |
| 2 | PASS | fixture evidence |
| 3 | PASS | fixture evidence |
| 4 | PASS | fixture evidence |
| 5 | PASS | fixture evidence |
| 6 | PASS | fixture evidence |
| 7 | PASS | fixture evidence |
| 8 | PASS | fixture evidence |
| 9 | PASS | fixture evidence |
| 10 | PASS | fixture evidence |

- findings: P1:0, P2:0, P3:0
- deferred P2: none
- self-check: pass
- corrections: none
- release recommendation: not_ready

## Decision

- keep/change: fixture
"@
    [System.IO.File]::WriteAllText($target, $content, [System.Text.UTF8Encoding]::new($false))
    $previousErrorAction = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        & git -C $FixtureRoot add -- $target 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'Fixture Eval stage failed' }
    }
    finally {
        $ErrorActionPreference = $previousErrorAction
    }
    return $target
}

function Assert-NegativeFixture {
    param(
        [string]$Name,
        [scriptblock]$Mutate,
        [string]$Expected
    )

    $fixtureRoot = New-Fixture $Name
    & $Mutate $fixtureRoot
    $result = Invoke-Validation $fixtureRoot
    if ($result.ExitCode -eq 0) {
        throw "Negative fixture unexpectedly passed: $Name"
    }
    if ($result.Text -notmatch [regex]::Escape($Expected)) {
        throw "Negative fixture '$Name' missed expected text '$Expected'. Output:`n$($result.Text)"
    }
    Write-Output "PASS negative-fixture=$Name"
}

try {
    $null = New-Item -ItemType Directory -Path $runRoot -Force

    $baselineRoot = New-Fixture 'baseline'
    $baseline = Invoke-Validation $baselineRoot
    if ($baseline.ExitCode -ne 0) {
        throw "Fixture baseline failed:`n$($baseline.Text)"
    }
    Write-Output 'PASS fixture-baseline'

    $releasePassRoot = New-Fixture 'release-pass'
    Initialize-FixtureGit $releasePassRoot
    $null = Write-ModernEval $releasePassRoot 'pass'
    $releasePass = Invoke-Validation $releasePassRoot -RequireReleaseEvidence
    if ($releasePass.ExitCode -ne 0) {
        $fixtureStatus = @(& git -C $releasePassRoot status --short --untracked-files=all) -join "`n"
        throw "Eligible release Eval fixture failed:`n$($releasePass.Text)`nFixture status:`n$fixtureStatus"
    }
    Write-Output 'PASS release-evidence=eligible-pass'

    $releaseFullRoot = New-Fixture 'release-full-review-pass'
    Initialize-FixtureGit $releaseFullRoot
    $null = Write-ModernEval $releaseFullRoot 'pass' 'source_regression' 'full'
    $releaseFull = Invoke-Validation $releaseFullRoot -RequireReleaseEvidence
    if ($releaseFull.ExitCode -ne 0) {
        throw "Full-mode release Eval fixture failed:`n$($releaseFull.Text)"
    }
    Write-Output 'PASS release-evidence=full-workflow-review-mode'

    $untrackedEvalRoot = New-Fixture 'release-untracked'
    Initialize-FixtureGit $untrackedEvalRoot
    $untrackedEvalPath = Write-ModernEval $untrackedEvalRoot 'pass'
    $previousErrorAction = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        & git -C $untrackedEvalRoot reset -q -- $untrackedEvalPath 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'Fixture Eval unstage failed' }
    }
    finally {
        $ErrorActionPreference = $previousErrorAction
    }
    $untrackedEval = Invoke-Validation $untrackedEvalRoot -RequireReleaseEvidence
    if ($untrackedEval.ExitCode -eq 0 -or
        $untrackedEval.Text -notmatch 'Eval record must be tracked or staged') {
        throw "Untracked Eval incorrectly satisfied release evidence:`n$($untrackedEval.Text)"
    }
    Write-Output 'PASS release-evidence=untracked-rejected'

    $unstagedEvalRoot = New-Fixture 'release-unstaged-change'
    Initialize-FixtureGit $unstagedEvalRoot
    $unstagedEvalPath = Write-ModernEval $unstagedEvalRoot 'pass'
    [System.IO.File]::AppendAllText(
        $unstagedEvalPath,
        "`nLocal mutation after staging.`n",
        [System.Text.UTF8Encoding]::new($false)
    )
    $unstagedEval = Invoke-Validation $unstagedEvalRoot -RequireReleaseEvidence
    if ($unstagedEval.ExitCode -eq 0 -or
        $unstagedEval.Text -notmatch 'Eval record has unstaged changes') {
        throw "Unstaged Eval mutation incorrectly satisfied release evidence:`n$($unstagedEval.Text)"
    }
    Write-Output 'PASS release-evidence=unstaged-change-rejected'

    $staleSourceRoot = New-Fixture 'release-source-drift'
    Initialize-FixtureGit $staleSourceRoot
    $staleEvalPath = Write-ModernEval $staleSourceRoot 'pass'
    $previousErrorAction = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        & git -C $staleSourceRoot commit -q -m 'fixture Eval' -- $staleEvalPath 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'Fixture Eval commit failed' }
        [System.IO.File]::AppendAllText(
            (Join-Path $staleSourceRoot 'README.md'),
            "`nSource drift after Eval.`n",
            [System.Text.UTF8Encoding]::new($false)
        )
        & git -C $staleSourceRoot add -- README.md 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'Fixture source drift stage failed' }
        & git -C $staleSourceRoot commit -q -m 'fixture source drift' 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'Fixture source drift commit failed' }
    }
    finally {
        $ErrorActionPreference = $previousErrorAction
    }
    $staleSource = Invoke-Validation $staleSourceRoot -RequireReleaseEvidence
    if ($staleSource.ExitCode -eq 0 -or
        $staleSource.Text -notmatch 'No completed PASS Eval with valid Git evidence') {
        throw "Source drift incorrectly inherited earlier release evidence:`n$($staleSource.Text)"
    }
    Write-Output 'PASS release-evidence=source-drift-rejected'

    $comparisonOnlyRoot = New-Fixture 'release-comparison-only'
    Initialize-FixtureGit $comparisonOnlyRoot
    $null = Write-ModernEval $comparisonOnlyRoot 'pass' 'fixed_contract'
    $comparisonOnly = Invoke-Validation $comparisonOnlyRoot -RequireReleaseEvidence
    if ($comparisonOnly.ExitCode -eq 0 -or
        $comparisonOnly.Text -notmatch 'No completed PASS Eval with valid Git evidence') {
        throw "Comparative Eval incorrectly satisfied canonical release evidence:`n$($comparisonOnly.Text)"
    }
    Write-Output 'PASS release-evidence=comparison-type-rejected'

    $notApplicableCaseRoot = New-Fixture 'release-not-applicable-case'
    Initialize-FixtureGit $notApplicableCaseRoot
    $notApplicableCasePath = Write-ModernEval $notApplicableCaseRoot 'pass'
    $notApplicableCaseText = [System.IO.File]::ReadAllText($notApplicableCasePath, [System.Text.Encoding]::UTF8)
    $notApplicableCaseText = $notApplicableCaseText.Replace('| source-validation | pass | fixture evidence |', '| source-validation | not_applicable | fixture evidence |')
    [System.IO.File]::WriteAllText($notApplicableCasePath, $notApplicableCaseText, [System.Text.UTF8Encoding]::new($false))
    $previousErrorAction = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        & git -C $notApplicableCaseRoot add -- $notApplicableCasePath 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'Fixture not-applicable Eval stage failed' }
    }
    finally {
        $ErrorActionPreference = $previousErrorAction
    }
    $notApplicableCase = Invoke-Validation $notApplicableCaseRoot -RequireReleaseEvidence
    if ($notApplicableCase.ExitCode -eq 0 -or
        $notApplicableCase.Text -notmatch 'Canonical source_regression PASS requires case result=pass') {
        throw "Canonical source_regression accepted a not_applicable case:`n$($notApplicableCase.Text)"
    }
    Write-Output 'PASS release-evidence=not-applicable-case-rejected'

    $unjustifiedP2Root = New-Fixture 'release-unjustified-p2'
    Initialize-FixtureGit $unjustifiedP2Root
    $unjustifiedP2Path = Write-ModernEval $unjustifiedP2Root 'pass'
    $unjustifiedP2Text = [System.IO.File]::ReadAllText($unjustifiedP2Path, [System.Text.Encoding]::UTF8)
    $unjustifiedP2Text = $unjustifiedP2Text.Replace('- findings: P1:0, P2:0, P3:0', '- findings: P1:0, P2:1, P3:0')
    [System.IO.File]::WriteAllText($unjustifiedP2Path, $unjustifiedP2Text, [System.Text.UTF8Encoding]::new($false))
    $previousErrorAction = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        & git -C $unjustifiedP2Root add -- $unjustifiedP2Path 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'Fixture unjustified P2 Eval stage failed' }
    }
    finally {
        $ErrorActionPreference = $previousErrorAction
    }
    $unjustifiedP2 = Invoke-Validation $unjustifiedP2Root -RequireReleaseEvidence
    if ($unjustifiedP2.ExitCode -eq 0 -or
        $unjustifiedP2.Text -notmatch 'Workflow Review with P2 findings cannot record deferred P2: none' -or
        $unjustifiedP2.Text -notmatch 'Workflow Review P2 findings require matching detailed entries') {
        throw "Canonical release accepted an unjustified P2 finding:`n$($unjustifiedP2.Text)"
    }
    Write-Output 'PASS release-evidence=unjustified-p2-rejected'
    $missingInventoryRoot = New-Fixture 'release-source-missing-inventory'
    Initialize-FixtureGit $missingInventoryRoot
    $previousErrorAction = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        & git -C $missingInventoryRoot rm -q --cached -- .ai/maintenance/update-state.yaml 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'Fixture inventory file untrack failed' }
        & git -C $missingInventoryRoot commit -q -m 'fixture source missing inventory file' 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'Fixture missing inventory source commit failed' }
    }
    finally {
        $ErrorActionPreference = $previousErrorAction
    }
    if (-not (Test-Path -LiteralPath (Join-Path $missingInventoryRoot '.ai/maintenance/update-state.yaml') -PathType Leaf)) {
        throw 'Fixture must preserve the ignored local update-state file'
    }
    $null = Write-ModernEval $missingInventoryRoot 'pass'
    $missingInventory = Invoke-Validation $missingInventoryRoot -RequireReleaseEvidence
    if ($missingInventory.ExitCode -eq 0 -or
        $missingInventory.Text -notmatch 'Canonical distribution must force-track ignored local scaffold:.*update-state.yaml' -or
        $missingInventory.Text -notmatch 'Eval source commit is missing distribution inventory file:.*missing=.ai/maintenance/update-state.yaml') {
        throw "Missing force-tracked update-state scaffold was not diagnosed and rejected:`n$($missingInventory.Text)"
    }
    Write-Output 'PASS release-evidence=source-inventory-missing-rejected'

    $releaseFailRoot = New-Fixture 'release-fail-history'
    Initialize-FixtureGit $releaseFailRoot
    $null = Write-ModernEval $releaseFailRoot 'fail'
    $validFailureHistory = Invoke-Validation $releaseFailRoot
    if ($validFailureHistory.ExitCode -ne 0) {
        throw "Valid failed Eval history was rejected:`n$($validFailureHistory.Text)"
    }
    $ineligibleFailure = Invoke-Validation $releaseFailRoot -RequireReleaseEvidence
    if ($ineligibleFailure.ExitCode -eq 0 -or
        $ineligibleFailure.Text -notmatch 'No completed PASS Eval with valid Git evidence') {
        throw "Failed Eval incorrectly satisfied release evidence:`n$($ineligibleFailure.Text)"
    }
    Write-Output 'PASS release-evidence=failed-history-not-eligible'

    Assert-NegativeFixture 'shallow-release-checkout' {
        param($root)
        $target = Join-Path $root '.github/workflows/release-evidence.yml'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('          fetch-depth: 0', '          fetch-depth: 1')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'CI workflow is missing required token: path=.github/workflows/release-evidence.yml token=fetch-depth: 0'

    Assert-NegativeFixture 'powershell-non-ascii-source' {
        param($root)
        $target = Join-Path $root 'tools/validate-workflow.ps1'
        $existingBytes = [System.IO.File]::ReadAllBytes($target)
        $nonAsciiComment = [byte[]](10, 35, 32, 226, 152, 131, 10)
        $combinedBytes = [byte[]]@($existingBytes + $nonAsciiComment)
        [System.IO.File]::WriteAllBytes($target, $combinedBytes)
    } 'PowerShell validation source must remain ASCII for Windows PowerShell 5.1 compatibility: tools/validate-workflow.ps1'

    Assert-NegativeFixture 'missing-role' {
        param($root)
        $target = Join-Path $root '.ai/roles/ARCHITECT.md'
        Assert-SafeFixturePath $target
        Remove-Item -LiteralPath $target -Force
    } 'Missing distribution inventory file: .ai/roles/ARCHITECT.md'

    Assert-NegativeFixture 'missing-workflow-review' {
        param($root)
        $target = Join-Path $root 'maintenance/WORKFLOW_REVIEW.md'
        Assert-SafeFixturePath $target
        Remove-Item -LiteralPath $target -Force
    } 'Missing source-only repository path: maintenance/WORKFLOW_REVIEW.md'

    Assert-NegativeFixture 'invalid-template-state' {
        param($root)
        $target = Join-Path $root '.ai/lanes/_template/state.yaml'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('phase: uninitialized', 'phase: building')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } "Unexpected 'phase' in .ai/lanes/_template/state.yaml"

    Assert-NegativeFixture 'legacy-template-state-key' {
        param($root)
        $target = Join-Path $root '.ai/lanes/_template/state.yaml'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('source_revision: null', "source_revision: null`nactive_task: null")
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Canonical template state contains removed schema-2 key: active_task'

    Assert-NegativeFixture 'source-eval-install-leak' {
        param($root)
        $target = Join-Path $root '.ai/evals/runs/EVAL-20990101T000000000Z-test-manual-v1.0-leak.md'
        [System.IO.File]::WriteAllText($target, "source-only release evidence must not be installed`n", [System.Text.UTF8Encoding]::new($false))
    } 'Installable .ai contains a canonical/source Eval record'

    Assert-NegativeFixture 'source-release-procedure-install-leak' {
        param($root)
        $target = Join-Path $root '.ai/maintenance/MAINTAIN.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text += "`n## BUILD_RELEASE_COPY`n"
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Installable MAINTAIN.md contains source-only release procedure'

    Assert-NegativeFixture 'incomplete-migration-metadata' {
        param($root)
        $target = Join-Path $root '.ai/maintenance/release.yaml'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $malformedMigration = @'
migrations:
  - from: manual-v0.9
    to: manual-v1.0
    path: .ai/maintenance/migrations/manual-v0.9-to-manual-v1.0.md
'@
        $text = $text.Replace('migrations: []', $malformedMigration.TrimEnd())
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'release.yaml migration entries must declare from, to, required, and path in that order'

    Assert-NegativeFixture 'incomplete-state-fsm' {
        param($root)
        $target = Join-Path $root '.ai/contracts/STATE.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('| `building` | `active` |', '')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'STATE.md is missing a normal phase/status declaration: building'

    Assert-NegativeFixture 'missing-review-resume-transition' {
        param($root)
        $target = Join-Path $root '.ai/contracts/STATE.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('requested `observe_only` evidence arrives and candidate bytes/identity are unchanged', 'user observation supplied')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/STATE.md token=requested `observe_only` evidence arrives and candidate bytes/identity are unchanged'

    Assert-NegativeFixture 'missing-build-resume-transition' {
        param($root)
        $target = Join-Path $root '.ai/contracts/STATE.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('`ready_to_build/blocked` with `architecture`', 'pre-Build architecture blocker')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/STATE.md token=`ready_to_build/blocked` with `architecture`'

    Assert-NegativeFixture 'missing-active-build-resume-transition' {
        param($root)
        $target = Join-Path $root '.ai/contracts/STATE.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('`building/blocked` with `architecture`', 'active Build architecture blocker')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/STATE.md token=`building/blocked` with `architecture`'
    Assert-NegativeFixture 'missing-changed-byte-build-resume' {
        param($root)
        $target = Join-Path $root '.ai/contracts/STATE.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('the repair changed any Task-attributed byte', 'the repair changed the implementation')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/STATE.md token=the repair changed any Task-attributed byte'

    Assert-NegativeFixture 'missing-ready-to-review-resume' {
        param($root)
        $target = Join-Path $root '.ai/contracts/STATE.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('`ready_to_review/blocked`', 'Reviewer preflight blocker')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/STATE.md token=`ready_to_review/blocked`'

    Assert-NegativeFixture 'missing-review-integration-resume' {
        param($root)
        $target = Join-Path $root '.ai/contracts/STATE.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('repair preserves candidate bytes, approved intent, Task outcome, public boundary, and applicable Integration contract', 'the Integration issue is repaired')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/STATE.md token=repair preserves candidate bytes, approved intent, Task outcome, public boundary, and applicable Integration contract'

    Assert-NegativeFixture 'missing-interrupted-build-disposition' {
        param($root)
        $target = Join-Path $root '.ai/contracts/TASK_RECORD.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('A replacement Task after an interrupted/superseded single-main attempt classifies every inherited Task path', 'A replacement Task reviews inherited paths')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/TASK_RECORD.md token=A replacement Task after an interrupted/superseded single-main attempt classifies every inherited Task path'

    Assert-NegativeFixture 'missing-integration-resume-transition' {
        param($root)
        $target = Join-Path $root '.ai/contracts/STATE.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('a Build/Review repair referenced by the active Integration queue `repair` mapping PASSes', 'a repaired Integration candidate passes')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/STATE.md token=a Build/Review repair referenced by the active Integration queue `repair` mapping PASSes'

    Assert-NegativeFixture 'missing-integration-repair-pointer' {
        param($root)
        $target = Join-Path $root '.ai/integration/queue.yaml'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('repair: # optional; absent means no Integration repair is active', 'repair:')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/integration/queue.yaml token=repair: # optional; absent means no Integration repair is active'

    Assert-NegativeFixture 'ambiguous-single-main-fingerprint' {
        param($root)
        $target = Join-Path $root '.ai/contracts/BUILD_RESULT.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('fixed first header', 'first header')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/BUILD_RESULT.md token=fixed first header'
    Assert-NegativeFixture 'missing-build-baseline-attribution' {
        param($root)
        $target = Join-Path $root '.ai/contracts/BUILD_RESULT.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('unrelated_pre_existing | inherited_task | unknown', 'pre_existing | unknown')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/BUILD_RESULT.md token=unrelated_pre_existing | inherited_task | unknown'

    Assert-NegativeFixture 'managed-path-escape' {
        param($root)
        $target = Join-Path $root '.ai/maintenance/managed-paths.yaml'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace("managed:`n", "managed:`n  - Source/**`n")
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Managed/preserved pattern escapes the .ai install root: Source/**'

    Assert-NegativeFixture 'ambiguous-update-containment-roots' {
        param($root)
        $target = Join-Path $root '.ai/maintenance/UPDATE.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('The candidate source root is read-only and is not required to be inside the target install root', 'The update source follows the normal containment rule')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/maintenance/UPDATE.md token=The candidate source root is read-only and is not required to be inside the target install root'

    Assert-NegativeFixture 'ambiguous-workflow-update-containment-summary' {
        param($root)
        $target = Join-Path $root '.ai/WORKFLOW.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('Candidate manifests, managed files, migration sources, and resolved read links must remain inside the pinned read-only candidate source root', 'All update paths follow the normal containment rule')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/WORKFLOW.md token=Candidate manifests, managed files, migration sources, and resolved read links must remain inside the pinned read-only candidate source root'

    Assert-NegativeFixture 'missing-candidate-symlink-read-containment' {
        param($root)
        $target = Join-Path $root '.ai/maintenance/UPDATE.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('For candidate reads and staging copies, resolve every link target and stop if it escapes the pinned candidate source root', 'Candidate links follow the normal path check')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/maintenance/UPDATE.md token=For candidate reads and staging copies, resolve every link target and stop if it escapes the pinned candidate source root'

    Assert-NegativeFixture 'missing-checked-update-identity' {
        param($root)
        $target = Join-Path $root '.ai/maintenance/UPDATE.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('The checked bytes, not a mutable ref name, bind that transaction', 'The checked ref identifies the candidate')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/maintenance/UPDATE.md token=The checked bytes, not a mutable ref name, bind that transaction'

    Assert-NegativeFixture 'missing-staged-update-identity' {
        param($root)
        $target = Join-Path $root '.ai/maintenance/UPDATE.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('reconstruct the same canonical manifest from the staged bytes/links', 'copy checked inputs into staging')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/maintenance/UPDATE.md token=reconstruct the same canonical manifest from the staged bytes/links'

    Assert-NegativeFixture 'missing-absent-update-rollback' {
        param($root)
        $target = Join-Path $root '.ai/maintenance/UPDATE.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace("transaction manifest's completed mutation record proves this Apply created it", 'the backup suggests this Apply created it')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } "Contract is missing a required invariant token: path=.ai/maintenance/UPDATE.md token=transaction manifest's completed mutation record proves this Apply created it"

    Assert-NegativeFixture 'missing-installed-update-validation-evidence' {
        param($root)
        $target = Join-Path $root '.ai/maintenance/UPDATE.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = [regex]::Replace($text, '(?m)^\| `bootstrap_readiness` \|.*\r?\n', '')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/maintenance/UPDATE.md token=`bootstrap_readiness`'

    Assert-NegativeFixture 'missing-update-identity-scaffold' {
        param($root)
        $target = Join-Path $root '.ai/maintenance/update-state.template.yaml'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace("last_checked_manifest_sha256: null`n", '')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/maintenance/update-state.template.yaml token=last_checked_manifest_sha256: null'
    Assert-NegativeFixture 'missing-active-update-marker-scaffold' {
        param($root)
        $target = Join-Path $root '.ai/maintenance/update-state.template.yaml'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace("active_transaction_manifest: null`n", '')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/maintenance/update-state.template.yaml token=active_transaction_manifest: null'

    Assert-NegativeFixture 'missing-interrupted-update-recovery' {
        param($root)
        $target = Join-Path $root '.ai/maintenance/UPDATE.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('## Interrupted transaction recovery', '## Update recovery')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/maintenance/UPDATE.md token=## Interrupted transaction recovery'

    Assert-NegativeFixture 'update-required-check-not-applicable' {
        param($root)
        $target = Join-Path $root '.ai/maintenance/UPDATE.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('never skip it as `not_applicable`', 'record not_applicable when empty')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/maintenance/UPDATE.md token=never skip it as `not_applicable`'

    Assert-NegativeFixture 'installed-license-drift' {
        param($root)
        $target = Join-Path $root '.ai/LICENSE'
        [System.IO.File]::AppendAllText($target, "`nchanged`n", [System.Text.UTF8Encoding]::new($false))
    } 'Installable .ai/LICENSE must match the distribution root LICENSE'

    Assert-NegativeFixture 'missing-output-contract-loading' {
        param($root)
        $target = Join-Path $root '.ai/roles/BUILDER.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('.ai/contracts/BUILD_RESULT.md', '.ai/contracts/BUILD_OUTPUT.md')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/roles/BUILDER.md token=.ai/contracts/BUILD_RESULT.md'

    Assert-NegativeFixture 'missing-task-quality-gate' {
        param($root)
        $target = Join-Path $root '.ai/contracts/TASK_RECORD.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('## Task Quality Gate', '## Task sizing notes')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/TASK_RECORD.md token=## Task Quality Gate'

    Assert-NegativeFixture 'missing-vertical-slice-rule' {
        param($root)
        $target = Join-Path $root '.ai/contracts/TASK_RECORD.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('Prefer a narrow end-to-end/vertical slice', 'Prefer a separately coded horizontal layer')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/TASK_RECORD.md token=Prefer a narrow end-to-end/vertical slice'
    Assert-NegativeFixture 'unsafe-batching-gate-collapse' {
        param($root)
        $target = Join-Path $root '.ai/evals/README.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('batching related constraints or evidence never crosses a pending consequential approval', 'related information may be batched')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/evals/README.md token=batching related constraints or evidence never crosses a pending consequential approval'

    Assert-NegativeFixture 'missing-requirement-drift-routing' {
        param($root)
        $target = Join-Path $root '.ai/contracts/ARTIFACT_AUTHORITY.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('Approved requirement vs source or observed behavior', 'Requirement mismatch')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/ARTIFACT_AUTHORITY.md token=Approved requirement vs source or observed behavior'

    Assert-NegativeFixture 'missing-execution-containment-boundary' {
        param($root)
        $target = Join-Path $root '.ai/contracts/ARTIFACT_AUTHORITY.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('process controls, not OS security boundaries', 'general safety controls')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/ARTIFACT_AUTHORITY.md token=process controls, not OS security boundaries'

    Assert-NegativeFixture 'missing-execution-containment-route' {
        param($root)
        $target = Join-Path $root '.ai/contracts/ARTIFACT_AUTHORITY.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('BLOCKED type=context owner=user', 'stop and ask the user')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/ARTIFACT_AUTHORITY.md token=BLOCKED type=context owner=user'

    Assert-NegativeFixture 'overbroad-execution-containment-trigger' {
        param($root)
        $target = Join-Path $root '.ai/contracts/ARTIFACT_AUTHORITY.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('Do not block solely because the session is unattended or approval-bypassed', 'Unattended or approval-bypassed sessions always block')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/ARTIFACT_AUTHORITY.md token=Do not block solely because the session is unattended or approval-bypassed'

    Assert-NegativeFixture 'missing-bounded-dependency-restore-policy' {
        param($root)
        $target = Join-Path $root '.ai/contracts/ARTIFACT_AUTHORITY.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('A bounded dependency restore may run under normal role/Lane scope', 'A dependency restore follows the normal execution path')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/ARTIFACT_AUTHORITY.md token=A bounded dependency restore may run under normal role/Lane scope'

    Assert-NegativeFixture 'missing-requirement-approval-schema' {
        param($root)
        $target = Join-Path $root '.ai/contracts/KNOWLEDGE.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('`approval.status` is `approved | candidate | rejected | superseded | unknown`', '`approval.status` records the current decision')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/KNOWLEDGE.md token=`approval.status` is `approved | candidate | rejected | superseded | unknown`'

    Assert-NegativeFixture 'missing-requirement-approval-backward-compatibility' {
        param($root)
        $target = Join-Path $root '.ai/contracts/KNOWLEDGE.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('Historical schema-v2 document entries without `approval` remain readable as `approval.status: unknown`', 'Historical document entries require migration')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/KNOWLEDGE.md token=Historical schema-v2 document entries without `approval` remain readable as `approval.status: unknown`'

    Assert-NegativeFixture 'missing-review-pass-authority-condition' {
        param($root)
        $target = Join-Path $root '.ai/contracts/REVIEW_RESULT.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('no unresolved requirement-ref drift', 'requirement refs inspected')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/REVIEW_RESULT.md token=no unresolved requirement-ref drift'

    Assert-NegativeFixture 'missing-review-oracle-integrity' {
        param($root)
        $target = Join-Path $root '.ai/contracts/REVIEW_RESULT.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('credible verification evidence whose oracle was not materially weakened', 'credible verification evidence')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/REVIEW_RESULT.md token=credible verification evidence whose oracle was not materially weakened'
    Assert-NegativeFixture 'duplicated-review-pass-authority' {
        param($root)
        $target = Join-Path $root '.ai/roles/REVIEWER.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('Use `.ai/contracts/REVIEW_RESULT.md` as the single authority for PASS conditions; do not restate or weaken that list here.', 'PASS requires all mandatory ACs passed and credible verification.')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Reviewer role restates PASS conditions; .ai/contracts/REVIEW_RESULT.md is the single authority'

    Assert-NegativeFixture 'missing-context-relevance-validation' {
        param($root)
        $target = Join-Path $root '.ai/contracts/KNOWLEDGE.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('Search hints identify candidates, not applicability', 'Search hints locate relevant entries')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/KNOWLEDGE.md token=Search hints identify candidates, not applicability'

    Assert-NegativeFixture 'missing-tacit-seed-diagnostic' {
        param($root)
        $target = Join-Path $root '.ai/roles/ARCHITECT.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('Treat evaluative or tacit seeds as valid problem signals, not failed requirements', 'Ask the user to define vague requests')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/roles/ARCHITECT.md token=Treat evaluative or tacit seeds as valid problem signals, not failed requirements'

    Assert-NegativeFixture 'missing-collaborative-design-altitude' {
        param($root)
        $target = Join-Path $root '.ai/roles/ARCHITECT.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('the current design altitude', 'the current topic')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/roles/ARCHITECT.md token=the current design altitude'

    Assert-NegativeFixture 'missing-needed-now-design-check' {
        param($root)
        $target = Join-Path $root '.ai/roles/ARCHITECT.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('`needed now`', '`possible detail`')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/roles/ARCHITECT.md token=`needed now`'

    Assert-NegativeFixture 'missing-program-shape-scope' {
        param($root)
        $target = Join-Path $root '.ai/roles/ARCHITECT.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('make only the needed program shape explicit', 'describe the implementation')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/roles/ARCHITECT.md token=make only the needed program shape explicit'

    Assert-NegativeFixture 'missing-human-ownership-boundary' {
        param($root)
        $target = Join-Path $root '.ai/WORKFLOW.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('Independent AI Review reduces review burden but never transfers code ownership', 'Independent AI Review reduces review burden')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/WORKFLOW.md token=Independent AI Review reduces review burden but never transfers code ownership'
    Assert-NegativeFixture 'missing-public-tacit-seed-summary' {
        param($root)
        $target = Join-Path $root 'README.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('tacit-seed-diagnostic: evidence-before-clarification', 'tacit-seed-diagnostic: missing')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=README.md token=tacit-seed-diagnostic: evidence-before-clarification'

    Assert-NegativeFixture 'missing-release-finalizer-session-boundary' {
        param($root)
        $target = Join-Path $root 'README.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('release-finalizer-session: fresh-non-authoring', 'release-finalizer-session: same-authoring-session')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=README.md token=release-finalizer-session: fresh-non-authoring'

    Assert-NegativeFixture 'ambiguous-requirement-ref-authority' {
        param($root)
        $target = Join-Path $root '.ai/contracts/ARCHITECTURE.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('Front-matter `requirement_refs` is the canonical machine-readable list', 'Requirement refs may appear in front matter or the body')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/ARCHITECTURE.md token=Front-matter `requirement_refs` is the canonical machine-readable list'

    Assert-NegativeFixture 'missing-execution-containment-eval-coverage' {
        param($root)
        $target = Join-Path $root '.ai/evals/README.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('repository trust/execution containment', 'repository trust')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/evals/README.md token=repository trust/execution containment'

    Assert-NegativeFixture 'ambiguous-requirement-drift-write-owner' {
        param($root)
        $target = Join-Path $root '.ai/roles/KNOWLEDGE_MAINTAINER.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('Mark only owned Knowledge entries that point to affected requirement refs `stale/conflict`; never edit the Architecture/Task artifacts', 'Mark affected refs `stale/conflict`')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/roles/KNOWLEDGE_MAINTAINER.md token=Mark only owned Knowledge entries that point to affected requirement refs `stale/conflict`; never edit the Architecture/Task artifacts'

    Assert-NegativeFixture 'missing-requirement-baseline-scaffold' {
        param($root)
        $target = Join-Path $root '.ai/lanes/_template/architecture.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace("requirement_refs: []`n", '')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/lanes/_template/architecture.md token=requirement_refs: []'

    Assert-NegativeFixture 'missing-system-requirement-baseline' {
        param($root)
        $target = Join-Path $root '.ai/shared/SYSTEM_ARCHITECTURE.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace("requirement_refs: []`n", '')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } "Missing or invalid 'requirement_refs' in .ai/shared/SYSTEM_ARCHITECTURE.md"

    Assert-NegativeFixture 'missing-cross-lane-requirement-oracle' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_WORKTREE_LIFECYCLE.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('pins `Docs/SharedPRD.md#REQ-SHARED-1@R2` once in its canonical `requirement_refs`', 'records the changed shared requirement')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/evals/GOLDEN_WORKTREE_LIFECYCLE.md token=pins `Docs/SharedPRD.md#REQ-SHARED-1@R2` once in its canonical `requirement_refs`'

    Assert-NegativeFixture 'ambiguous-comparison-baseline' {
        param($root)
        $target = Join-Path $root '.ai/evals/README.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace("exactly A's provider/host tool/model/reasoning/configuration", 'an available model configuration')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } "Contract is missing a required invariant token: path=.ai/evals/README.md token=exactly A's provider/host tool/model/reasoning/configuration"

    Assert-NegativeFixture 'missing-core-behavior-oracle' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('A Task PASS is not by itself a Feature-completion claim', 'The final Task PASS completes the Feature')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: A Task PASS is not by itself a Feature-completion claim'

    Assert-NegativeFixture 'missing-tacit-seed-oracle' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('The evaluative seed is a valid problem signal', 'The evaluative seed is handled')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: The evaluative seed is a valid problem signal'

    Assert-NegativeFixture 'missing-green-check-maintainability-oracle' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('The green checks do not authorize PASS for the second candidate', 'The checks are reviewed for the second candidate')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: The green checks do not authorize PASS for the second candidate'

    Assert-NegativeFixture 'missing-vertical-slice-oracle' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('E is reframed into narrow end-to-end/vertical outcomes', 'E is reframed into smaller work')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: E is reframed into narrow end-to-end/vertical outcomes'
    Assert-NegativeFixture 'missing-requirement-drift-oracle' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('A changed requirement revision never silently authorizes Build or rewrites product intent from code', 'Requirement drift is handled')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: A changed requirement revision never silently authorizes Build or rewrites product intent from code'

    Assert-NegativeFixture 'missing-directional-failure-route' {
        param($root)
        $target = Join-Path $root '.ai/roles/REVIEWER.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('Evidence that the approved approach or Task boundary itself is directionally wrong is an `architecture` finding', 'Evidence that the approach may need more implementation work')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/roles/REVIEWER.md token=Evidence that the approved approach or Task boundary itself is directionally wrong is an `architecture` finding'

    Assert-NegativeFixture 'missing-directional-failure-oracle' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('Reviewer classifies the problem as `architecture`, not repeated `implementation`', 'Reviewer routes the problem')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: Reviewer classifies the problem as `architecture`, not repeated `implementation`'

    Assert-NegativeFixture 'missing-build-blocked-resume-oracle' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('state becomes `ready_to_build/blocked`', 'Builder reports a preflight blocker')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: state becomes `ready_to_build/blocked`'
    Assert-NegativeFixture 'missing-changed-byte-build-resume-oracle' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('changed Task bytes with an unchanged approved boundary return to `ready_to_build/active`', 'changed Task bytes are reconciled')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: changed Task bytes with an unchanged approved boundary return to `ready_to_build/active`'

    Assert-NegativeFixture 'missing-build-baseline-attribution-oracle' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('Every already-dirty Build baseline path is classified as `unrelated_pre_existing`, `inherited_task`, or `unknown`', 'Every dirty path is inspected')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: Every already-dirty Build baseline path is classified as `unrelated_pre_existing`, `inherited_task`, or `unknown`'

    Assert-NegativeFixture 'missing-ready-to-review-resume-oracle' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('If Reviewer rejects preflight, state becomes `ready_to_review/blocked`', 'Reviewer preflight is retried')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: If Reviewer rejects preflight, state becomes `ready_to_review/blocked`'

    Assert-NegativeFixture 'missing-interrupted-build-disposition-oracle' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('the replacement Task classifies every Task-attributed dirty path as `retain`, `adapt`, or `remove`', 'the replacement Task handles previous changes')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: the replacement Task classifies every Task-attributed dirty path as `retain`, `adapt`, or `remove`'

    Assert-NegativeFixture 'duplicated-golden-trigger-authority' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('The canonical trigger list and case routing live there; do not maintain a second list in this file', 'This file lists its own trigger cases')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: The canonical trigger list and case routing live there; do not maintain a second list in this file'

    Assert-NegativeFixture 'missing-external-update-containment-oracle' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('The candidate source root is not required to be inside the target project or `P/.ai`', 'The update source is checked')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: The candidate source root is not required to be inside the target project or `P/.ai`'

    Assert-NegativeFixture 'missing-external-update-symlink-oracle' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('candidate symlink/reparse escape', 'candidate link')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: candidate symlink/reparse escape'

    Assert-NegativeFixture 'missing-update-mutation-oracle' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('Apply is bound to the checked revision/tree and canonical input manifest, not the locator name', 'Apply uses the checked source')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: Apply is bound to the checked revision/tree and canonical input manifest, not the locator name'

    Assert-NegativeFixture 'missing-installed-update-validation-oracle' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('Installed validation evidence contains exactly the seven named profile rows with a concrete observed result and evidence path/output', 'Installed validation is summarized')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: Installed validation evidence contains exactly the seven named profile rows with a concrete observed result and evidence path/output'
    Assert-NegativeFixture 'missing-active-update-recovery-oracle' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('`update-state.yaml.active_transaction_manifest` durably points inside the backup root', 'the update transaction is recorded')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: `update-state.yaml.active_transaction_manifest` durably points inside the backup root'

    Assert-NegativeFixture 'missing-required-update-result-oracle' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('each result is `pass | fail`', 'each result is recorded')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: each result is `pass | fail`'

    Assert-NegativeFixture 'missing-update-absent-rollback-oracle' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('rollback removes only the transaction-created path', 'rollback restores the backup')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: rollback removes only the transaction-created path'

    Assert-NegativeFixture 'missing-bounded-execution-inverse-oracle' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('The bounded inverse control may proceed under normal role/Lane scope and available approval controls', 'The bounded control is handled safely')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: The bounded inverse control may proceed under normal role/Lane scope and available approval controls'

    Assert-NegativeFixture 'missing-bounded-dependency-restore-oracle' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('The bounded dependency restore may proceed under normal role/Lane scope', 'The dependency restore is handled safely')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: The bounded dependency restore may proceed under normal role/Lane scope'

    Assert-NegativeFixture 'missing-context-relevance-oracle' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('Only the confirmed live source may support the answer or design', 'A relevant source supports the answer or design')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: Only the confirmed live source may support the answer or design'

    Assert-NegativeFixture 'incomplete-workflow-review-lenses' {
        param($root)
        $target = Join-Path $root 'maintenance/WORKFLOW_REVIEW.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = [regex]::Replace(
            $text,
            '(?m)^\| 10\. Trust, security, and losslessness \|.*\r?\n',
            ''
        )
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Workflow Review must define exactly 10 review lenses, found: 9'

    Assert-NegativeFixture 'missing-workflow-review-independence' {
        param($root)
        $target = Join-Path $root 'maintenance/WORKFLOW_REVIEW.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('must not have authored the candidate source changes', 'reviews the candidate source changes')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=maintenance/WORKFLOW_REVIEW.md token=must not have authored the candidate source changes'

    Assert-NegativeFixture 'missing-readme-quality-gate' {
        param($root)
        $target = Join-Path $root 'maintenance/WORKFLOW_REVIEW.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('## README quality gate', '## Documentation note')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=maintenance/WORKFLOW_REVIEW.md token=## README quality gate'

    Assert-NegativeFixture 'missing-public-philosophy-summary' {
        param($root)
        $target = Join-Path $root 'README.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('public-philosophy-summary: canonical-design-principles-1-through-11', 'public-philosophy-summary: incomplete')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'README public philosophy marker does not match canonical principle count: expected=public-philosophy-summary: canonical-design-principles-1-through-11'

    Assert-NegativeFixture 'incomplete-public-workflow-review-summary' {
        param($root)
        $target = Join-Path $root 'README.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('workflow-review-summary: canonical-lenses-1-through-10', 'workflow-review-summary: canonical-lenses-1-through-9')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'README Workflow Review marker does not match canonical lens count: expected=workflow-review-summary: canonical-lenses-1-through-10'

    Assert-NegativeFixture 'incomplete-public-philosophy-summary' {
        param($root)
        $target = Join-Path $root 'README.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = [regex]::Replace($text, '(?m)^11\. \*\*.*\r?\n', '')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'README public philosophy principle count does not match canonical Design principles: canonical=11 public=10'

    Assert-NegativeFixture 'stale-public-philosophy-source-fingerprint' {
        param($root)
        $target = Join-Path $root '.ai/WORKFLOW.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('Providers and model strengths may change', 'Providers and model strengths can change')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'README public philosophy source fingerprint does not match canonical Design principles'

    Assert-NegativeFixture 'missing-workflow-review-self-check' {
        param($root)
        $target = Join-Path $root 'maintenance/WORKFLOW_REVIEW.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('## Bounded self-check', '## Final consistency note')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=maintenance/WORKFLOW_REVIEW.md token=## Bounded self-check'

    Assert-NegativeFixture 'unstable-workflow-review-self-check' {
        param($root)
        $target = Join-Path $root 'maintenance/WORKFLOW_REVIEW.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('Self-check criteria are stable by default', 'Self-check criteria follow current external advice')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=maintenance/WORKFLOW_REVIEW.md token=Self-check criteria are stable by default'

    Assert-NegativeFixture 'missing-release-workflow-review-evidence' {
        param($root)
        Initialize-FixtureGit $root
        $target = Write-ModernEval $root 'pass'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = [regex]::Replace($text, '(?m)^workflow_review_independence:.*\r?\n', '')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } "Missing or invalid front-matter 'workflow_review_independence'"

    Assert-NegativeFixture 'missing-release-workflow-review-self-check' {
        param($root)
        Initialize-FixtureGit $root
        $target = Write-ModernEval $root 'pass'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = [regex]::Replace($text, '(?m)^workflow_review_self_check:.*\r?\n', '')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } "Missing or invalid front-matter 'workflow_review_self_check'"

    Assert-NegativeFixture 'project-knowledge-leak' {
        param($root)
        $directory = Join-Path $root '.ai/shared/knowledge/modules'
        Assert-SafeFixturePath $directory
        $null = New-Item -ItemType Directory -Path $directory -Force
        [System.IO.File]::WriteAllText(
            (Join-Path $directory 'project-leak.yaml'),
            "schema_version: 2`nstatus: verified`n",
            [System.Text.UTF8Encoding]::new($false)
        )
    } 'Canonical distribution contains project Knowledge content'

    Assert-NegativeFixture 'missing-release-review-mode-selection' {
        param($root)
        $target = Join-Path $root 'maintenance/RELEASE.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('apply its mode-selection rule', 'run the default changed mode')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=maintenance/RELEASE.md token=apply its mode-selection rule'

    Assert-NegativeFixture 'missing-reduced-assurance-entry-rule' {
        param($root)
        $target = Join-Path $root '.ai/contracts/REVIEW_RESULT.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('A generic request such as "review this" or a convenience-driven same-session role switch is not consent', 'A same-session request may imply consent')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/REVIEW_RESULT.md token=A generic request such as "review this" or a convenience-driven same-session role switch is not consent'

    Assert-NegativeFixture 'missing-reduced-assurance-role-pointer' {
        param($root)
        $target = Join-Path $root '.ai/roles/REVIEWER.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('.ai/contracts/REVIEW_RESULT.md#reduced-assurance-exception', '.ai/contracts/REVIEW_RESULT.md')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/roles/REVIEWER.md token=.ai/contracts/REVIEW_RESULT.md#reduced-assurance-exception'

    Assert-NegativeFixture 'missing-reduced-assurance-oracle' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('The same session does not interpret the generic request as reduced-assurance consent', 'The same session reviews the request')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: The same session does not interpret the generic request as reduced-assurance consent'

    Assert-NegativeFixture 'missing-installed-source-confirmation' {
        param($root)
        $target = Join-Path $root '.ai/maintenance/UPDATE.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('only as an untrusted source candidate and require explicit user confirmation before Check', 'as the default update source')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/maintenance/UPDATE.md token=only as an untrusted source candidate and require explicit user confirmation before Check'

    Assert-NegativeFixture 'missing-release-source-metadata' {
        param($root)
        $target = Join-Path $root '.ai/maintenance/release.yaml'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('repository: https://github.com/yeomin-yoon/AI-Dev-Workflow', 'repository: null')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'release.yaml source.repository must be a non-null HTTPS repository URL'

    Assert-NegativeFixture 'missing-installed-source-oracle' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('only as an untrusted source candidate and does not begin Check until the user explicitly confirms it', 'as the update source')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: only as an untrusted source candidate and does not begin Check until the user explicitly confirms it'

    Assert-NegativeFixture 'missing-change-brief-glossary' {
        param($root)
        $target = Join-Path $root 'README.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('| Change Brief |', '| Review Summary |')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=README.md token=| Change Brief |'

    Assert-NegativeFixture 'missing-developer-status-contract' {
        param($root)
        $target = Join-Path $root '.ai/contracts/ACTION_CARDS.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('## Developer Status', '## Status Summary')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/ACTION_CARDS.md token=## Developer Status'

    Assert-NegativeFixture 'missing-code-walkthrough-contract' {
        param($root)
        $target = Join-Path $root '.ai/contracts/ACTION_CARDS.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('## Code walkthrough', '## Change explanation')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/ACTION_CARDS.md token=## Code walkthrough'

    Assert-NegativeFixture 'missing-build-source-map-coverage' {
        param($root)
        $target = Join-Path $root '.ai/contracts/BUILD_RESULT.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('For every Task-touched hand-written production source path in `Changes`', 'Describe a few important files')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/BUILD_RESULT.md token=For every Task-touched hand-written production source path in `Changes`'

    Assert-NegativeFixture 'missing-reviewed-source-map-pointer' {
        param($root)
        $target = Join-Path $root '.ai/contracts/REVIEW_RESULT.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('reviewed source map: <Build Result#source-map validated against exact Diff + corrections|omit for none>', 'important files: <paths|none>')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/REVIEW_RESULT.md token=reviewed source map: <Build Result#source-map validated against exact Diff + corrections|omit for none>'

    Assert-NegativeFixture 'ambiguous-code-walkthrough-numbering' {
        param($root)
        $target = Join-Path $root '.ai/contracts/ACTION_CARDS.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('R1. <path>#<symbol>', '1. <path>#<symbol>')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/ACTION_CARDS.md token=R1. <path>#<symbol>'

    Assert-NegativeFixture 'opaque-code-inspection-reply' {
        param($root)
        $target = Join-Path $root '.ai/contracts/ACTION_CARDS.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('Internal enums may be stored in state/result fields but never replace the displayed meaning', 'Internal enums are displayed as the user reply')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/ACTION_CARDS.md token=Internal enums may be stored in state/result fields but never replace the displayed meaning'

    Assert-NegativeFixture 'missing-code-inspection-state-transition' {
        param($root)
        $target = Join-Path $root '.ai/contracts/STATE.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('await_code_inspection_then_resume_review_route', 'continue_review_route')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/STATE.md token=await_code_inspection_then_resume_review_route'

    Assert-NegativeFixture 'code-inspection-wait-bypassed-by-generic-route' {
        param($root)
        $target = Join-Path $root '.ai/contracts/STATE.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('all generic accepted, checkpoint, Knowledge, next-Task, and Integration routes are suspended', 'generic accepted routes remain available')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/STATE.md token=all generic accepted, checkpoint, Knowledge, next-Task, and Integration routes are suspended'

    Assert-NegativeFixture 'missing-code-inspection-handoff-suppression' {
        param($root)
        $target = Join-Path $root '.ai/contracts/ACTION_CARDS.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('a `CODE_WALKTHROUGH` with `code_inspection=awaiting_user` stays in Reviewer', 'a CODE_WALKTHROUGH immediately hands off')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/ACTION_CARDS.md token=a `CODE_WALKTHROUGH` with `code_inspection=awaiting_user` stays in Reviewer'

    Assert-NegativeFixture 'missing-code-inspection-outcome-definition' {
        param($root)
        $target = Join-Path $root '.ai/roles/REVIEWER.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('Use `not_applicable` for Integration Review, `fail`/`blocked`, or a purely mechanical/non-code PASS', 'Choose the inspection result as needed')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/roles/REVIEWER.md token=Use `not_applicable` for Integration Review, `fail`/`blocked`, or a purely mechanical/non-code PASS'

    Assert-NegativeFixture 'inconsistent-reviewed-source-map-none-policy' {
        param($root)
        $target = Join-Path $root '.ai/contracts/REVIEW_RESULT.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('reviewed source map: <Build Result#source-map validated against exact Diff + corrections|omit for none>', 'reviewed source map: <Build Result#source-map validated against exact Diff + corrections|none>')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/REVIEW_RESULT.md token=reviewed source map: <Build Result#source-map validated against exact Diff + corrections|omit for none>'

    Assert-NegativeFixture 'missing-code-walkthrough-no-git-form' {
        param($root)
        $target = Join-Path $root '.ai/contracts/ACTION_CARDS.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('snapshot=no-git/unsealed', 'snapshot=git-required')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/ACTION_CARDS.md token=snapshot=no-git/unsealed'

    Assert-NegativeFixture 'no-git-code-inspection-repeat-wait' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('It returns `shown_no_pause` even when the project opted in', 'It returns awaiting_user and waits for an unverifiable identity')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: It returns `shown_no_pause` even when the project opted in'

    Assert-NegativeFixture 'integration-review-code-inspection-pause' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('The pause applies to ordinary Task Review on `main` or non-`main`; Integration Review returns `not_applicable`', 'Integration Review creates another inspection wait')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: The pause applies to ordinary Task Review on `main` or non-`main`; Integration Review returns `not_applicable`'

    Assert-NegativeFixture 'missing-dev-status-repin-state' {
        param($root)
        $target = Join-Path $root '.ai/contracts/ACTION_CARDS.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('content_committed_repin_pending', 'commit_ready')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/ACTION_CARDS.md token=content_committed_repin_pending'

    Assert-NegativeFixture 'ambiguous-checkpoint-commit-vocabulary' {
        param($root)
        $target = Join-Path $root '.ai/contracts/ARTIFACT_AUTHORITY.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('## Checkpoint commit vocabulary', '## Metadata commits')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/ARTIFACT_AUTHORITY.md token=## Checkpoint commit vocabulary'

    Assert-NegativeFixture 'ambiguous-integration-metadata-only-route' {
        param($root)
        $target = Join-Path $root '.ai/integration/README.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('Evidence/context or non-material Integration contract repair', 'Evidence/context or metadata-only contract repair')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/integration/README.md token=Evidence/context or non-material Integration contract repair'

    Assert-NegativeFixture 'missing-golden-fixture-21-heading' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('## Fixture 21', '## Scenario 21')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: ## Fixture 21'

    Assert-NegativeFixture 'general-decision-receives-intent-gap-preamble' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('This general checkpoint decision begins directly with `DECISION`', 'Every decision begins with the intent-gap preface')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: This general checkpoint decision begins directly with `DECISION`'

    Assert-NegativeFixture 'invalid-default-code-inspection' {
        param($root)
        $target = Join-Path $root '.ai/shared/knowledge/project.yaml'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('code_inspection: no_pause', 'code_inspection: before_next_task')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } "Unexpected 'code_inspection' in .ai/shared/knowledge/project.yaml: expected=no_pause actual=before_next_task"

    Assert-NegativeFixture 'stale-readme-code-inspection-default' {
        param($root)
        $target = Join-Path $root 'README.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('code-walkthrough-default: no-pause-do-next-visible', 'code-walkthrough-default: wait-before-do-next')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=README.md token=code-walkthrough-default: no-pause-do-next-visible'

    Assert-NegativeFixture 'missing-single-main-commit-checkpoint' {
        param($root)
        $target = Join-Path $root '.ai/contracts/ACTION_CARDS.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('## Single-main commit checkpoint', '## Optional commit note')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/ACTION_CARDS.md token=## Single-main commit checkpoint'

    Assert-NegativeFixture 'missing-same-lane-resume-boundary' {
        param($root)
        $target = Join-Path $root '.ai/contracts/SESSION_CLOSE.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('A role, topology, candidate, Lane, checkout, new-worktree, Integration, or return-intent change is not a same-Lane replacement', 'Related work may resume directly')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/SESSION_CLOSE.md token=role, topology, candidate, Lane, checkout, new-worktree, Integration, or return-intent change is not a same-Lane replacement'

    Assert-NegativeFixture 'missing-front-desk-recovery-contract' {
        param($root)
        $target = Join-Path $root '.ai/contracts/MAIN_DESK.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('## Front Desk recovery', '## Front Desk restart')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/MAIN_DESK.md token=## Front Desk recovery'

    Assert-NegativeFixture 'missing-front-desk-chat-independent-recovery' {
        param($root)
        $target = Join-Path $root '.ai/contracts/MAIN_DESK.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('Recovery does not depend on the exhausted chat', 'Recovery uses the previous chat summary')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/MAIN_DESK.md token=Recovery does not depend on the exhausted chat'

    Assert-NegativeFixture 'missing-single-main-work-route' {
        param($root)
        $target = Join-Path $root '.ai/roles/REVIEWER.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('route=<knowledge_maintainer|work|builder|architect|integration|user>', 'route=<knowledge_maintainer|builder|architect|integration|user>')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/roles/REVIEWER.md token=route=<knowledge_maintainer|work|builder|architect|integration|user>'

    Assert-NegativeFixture 'missing-planning-document-read-only-default' {
        param($root)
        $target = Join-Path $root '.ai/roles/KNOWLEDGE_MAINTAINER.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('Approved product/requirements/specification or planning documents are reference-only by default', 'Planning inputs are ordinary writable documents')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/roles/KNOWLEDGE_MAINTAINER.md token=Approved product/requirements/specification or planning documents are reference-only by default'

    Assert-NegativeFixture 'missing-commit-boundary-oracle' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('No next Task is materialized over the uncommitted accepted candidate', 'The next Task may begin immediately')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: No next Task is materialized over the uncommitted accepted candidate'

    Assert-NegativeFixture 'missing-session-recovery-oracle' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('The unchanged-identity scenario emits `RESUME_SAME_LANE`', 'Every replacement returns to Front Desk')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: The unchanged-identity scenario emits `RESUME_SAME_LANE`'

    Assert-NegativeFixture 'missing-session-viability-boundary' {
        param($root)
        $target = Join-Path $root '.ai/contracts/SESSION_CLOSE.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('Assess viability only at a natural boundary', 'Assess viability on every turn')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/SESSION_CLOSE.md token=Assess viability only at a natural boundary'

    Assert-NegativeFixture 'missing-session-age-inverse-guard' {
        param($root)
        $target = Join-Path $root '.ai/contracts/SESSION_CLOSE.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('One corrected mistake, a long transcript, or turn count alone is not enough', 'A long transcript or high turn count requires replacement')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/SESSION_CLOSE.md token=One corrected mistake, a long transcript, or turn count alone is not enough'

    Assert-NegativeFixture 'missing-session-timing-oracle' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('Scenario C also continues because chat age or turn count alone is not evidence', 'Scenario C replaces because the chat is old')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: Scenario C also continues because chat age or turn count alone is not evidence'

    Assert-NegativeFixture 'overbroad-work-session-replacement-advice' {
        param($root)
        $target = Join-Path $root '.ai/roles/WORK.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('a feature boundary is only a safe checkpoint, not replacement evidence by itself', 'replace at every feature boundary')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/roles/WORK.md token=a feature boundary is only a safe checkpoint, not replacement evidence by itself'

    Assert-NegativeFixture 'missing-planning-document-oracle' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('Knowledge indexes only applicable planning sections/revisions', 'Knowledge owns all planning documents')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: Knowledge indexes only applicable planning sections/revisions'

    Assert-NegativeFixture 'missing-editor-runtime-check-contract' {
        param($root)
        $target = Join-Path $root '.ai/contracts/ACTION_CARDS.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('## Editor/runtime check', '## Manual check')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/ACTION_CARDS.md token=## Editor/runtime check'

    Assert-NegativeFixture 'missing-candidate-mutating-review-transition' {
        param($root)
        $target = Join-Path $root '.ai/contracts/STATE.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('an authorized `candidate_mutating` Editor/runtime action changes Task-attributed bytes', 'user evidence arrives')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/STATE.md token=an authorized `candidate_mutating` Editor/runtime action changes Task-attributed bytes'

    Assert-NegativeFixture 'missing-editor-check-review-identity-boundary' {
        param($root)
        $target = Join-Path $root '.ai/contracts/REVIEW_RESULT.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('Earlier evidence may be reused only after an explicit impact check against that fresh candidate', 'Earlier evidence is reused automatically')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/REVIEW_RESULT.md token=Earlier evidence may be reused only after an explicit impact check against that fresh candidate'

    Assert-NegativeFixture 'missing-approved-architecture-fast-lane' {
        param($root)
        $target = Join-Path $root '.ai/roles/WORK.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('without a user-visible Architect handoff or repeated approval', 'after a new Architect approval')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/roles/WORK.md token=without a user-visible Architect handoff or repeated approval'

    Assert-NegativeFixture 'missing-editor-check-oracle' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('the saved bytes invalidate the old Build/Review identity and route a fresh Build attempt', 'the old Review resumes after saved changes')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: the saved bytes invalidate the old Build/Review identity and route a fresh Build attempt'

    Assert-NegativeFixture 'missing-approved-architecture-fast-lane-oracle' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('there is no user-visible Architect handoff or repeated approval', 'the user approves Architect again')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: there is no user-visible Architect handoff or repeated approval'

    Assert-NegativeFixture 'missing-working-summary-contract' {
        param($root)
        $target = Join-Path $root '.ai/contracts/ACTION_CARDS.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('## Working summary', '## Conversation recap')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/ACTION_CARDS.md token=## Working summary'

    Assert-NegativeFixture 'missing-just-in-time-term-rule' {
        param($root)
        $target = Join-Path $root '.ai/roles/ARCHITECT.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('Define an unfamiliar technical term at first user-facing use', 'Use precise technical terminology')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/roles/ARCHITECT.md token=Define an unfamiliar technical term at first user-facing use'

    Assert-NegativeFixture 'missing-observable-unchanged-baseline' {
        param($root)
        $target = Join-Path $root '.ai/roles/REVIEWER.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('Never write `unchanged` or `the same` without naming the compared baseline', 'State that unaffected behavior is unchanged')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/roles/REVIEWER.md token=Never write `unchanged` or `the same` without naming the compared baseline'

    Assert-NegativeFixture 'missing-readable-learning-oracle' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('The role returns one terminal-screen `WORKING_SUMMARY` derived from durable evidence', 'The role replays the previous chat summary')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: The role returns one terminal-screen `WORKING_SUMMARY` derived from durable evidence'

    Assert-NegativeFixture 'missing-code-walkthrough-oracle' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('A Change Brief, Review artifact link, directory list, or selected hunk alone does not satisfy the walkthrough', 'A summary is enough for understanding')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: A Change Brief, Review artifact link, directory list, or selected hunk alone does not satisfy the walkthrough'

    Assert-NegativeFixture 'missing-code-inspection-session-recovery' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('A replacement Reviewer reconstructs the same walkthrough and route from state', 'A replacement Reviewer continues without the walkthrough')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: A replacement Reviewer reconstructs the same walkthrough and route from state'

    Assert-NegativeFixture 'overbroad-mechanical-code-inspection-pause' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('A mechanical/generated-only or non-code PASS returns `not_applicable`', 'Every PASS waits for code inspection')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: A mechanical/generated-only or non-code PASS returns `not_applicable`'

    Assert-NegativeFixture 'missing-readable-atomic-decision-oracle' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('The first decision screen leads with one plain question, marks the recommendation, and shows every currently viable alternative together', 'The first decision screen shows only an internal option ID')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: The first decision screen leads with one plain question, marks the recommendation, and shows every currently viable alternative together'

    Assert-NegativeFixture 'missing-public-install-boundary' {
        param($root)
        $target = Join-Path $root 'README.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('install-boundary: fresh-copy-vs-managed-update-vs-unrelated-ai', 'install note')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=README.md token=install-boundary: fresh-copy-vs-managed-update-vs-unrelated-ai'

    Assert-NegativeFixture 'missing-managed-install-overlay-oracle' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('An existing managed installation uses Check/Apply rather than a folder overlay', 'An existing installation may be overwritten')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: An existing managed installation uses Check/Apply rather than a folder overlay'

    Assert-NegativeFixture 'missing-descriptive-commit-choice' {
        param($root)
        $target = Join-Path $root '.ai/contracts/ACTION_CARDS.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('Canonical replies are descriptive semantic actions', 'Canonical replies are opaque aliases')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/ACTION_CARDS.md token=Canonical replies are descriptive semantic actions'

    Assert-NegativeFixture 'missing-readable-atomic-decision-contract' {
        param($root)
        $target = Join-Path $root '.ai/contracts/ACTION_CARDS.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('## Readable atomic decisions', '## Internal option table')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/ACTION_CARDS.md token=## Readable atomic decisions'

    Assert-NegativeFixture 'missing-decision-overflow-groups-field' {
        param($root)
        $target = Join-Path $root '.ai/contracts/ACTION_CARDS.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('groups=<none|up to three discriminator groups, each followed by every included semantic outcome>', 'groups=<internal grouping|none>')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/ACTION_CARDS.md token=groups=<none|up to three discriminator groups, each followed by every included semantic outcome>'

    Assert-NegativeFixture 'missing-visible-viable-alternatives' {
        param($root)
        $target = Join-Path $root '.ai/contracts/ACTION_CARDS.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('show the recommendation and every viable alternative together', 'show only the recommendation first')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/ACTION_CARDS.md token=show the recommendation and every viable alternative together'

    Assert-NegativeFixture 'fourth-viable-outcome-silently-dropped' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('The four-outcome decision first asks one discriminator with no more than three mutually exclusive, collectively exhaustive groups', 'The fourth outcome is omitted to preserve a three-choice screen')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: The four-outcome decision first asks one discriminator with no more than three mutually exclusive, collectively exhaustive groups'

    Assert-NegativeFixture 'compound-checkpoint-continuation-choice' {
        param($root)
        $target = Join-Path $root '.ai/contracts/ACTION_CARDS.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('never offers compound `commit and continue` choices', 'offers a combined commit and next Task choice')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/ACTION_CARDS.md token=never offers compound `commit and continue` choices'

    Assert-NegativeFixture 'missing-metadata-repin-closure' {
        param($root)
        $target = Join-Path $root '.ai/contracts/ACTION_CARDS.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('Required deterministic bookkeeping, exact metadata repinning, and role-owned repair are not choices', 'Metadata repinning requires a new user choice')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/ACTION_CARDS.md token=Required deterministic bookkeeping, exact metadata repinning, and role-owned repair are not choices'

    Assert-NegativeFixture 'missing-cross-domain-learning-oracle' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('The same explanation contract applies across service/API, CLI/library, and editor/runtime work', 'The explanation contract applies only to one framework')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: The same explanation contract applies across service/API, CLI/library, and editor/runtime work'

    Assert-NegativeFixture 'missing-gate-necessity-check' {
        param($root)
        $target = Join-Path $root '.ai/roles/ARCHITECT.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('`gate necessity`', '`approval prompt`')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/roles/ARCHITECT.md token=`gate necessity`'

    Assert-NegativeFixture 'missing-decision-readiness-check' {
        param($root)
        $target = Join-Path $root '.ai/roles/ARCHITECT.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('`decision readiness`', '`decision output`')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/roles/ARCHITECT.md token=`decision readiness`'

    Assert-NegativeFixture 'invalid-default-checkpoint-policy' {
        param($root)
        $target = Join-Path $root '.ai/shared/knowledge/project.yaml'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('checkpoint: auto_after_pass', 'checkpoint: unsafe')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } "Unexpected 'checkpoint' in .ai/shared/knowledge/project.yaml"

    Assert-NegativeFixture 'missing-auto-checkpoint-oracle' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('Missing preferences read as `auto_after_pass + one_task`', 'Missing preferences require another confirmation')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: Missing preferences read as `auto_after_pass + one_task`'

    Assert-NegativeFixture 'missing-informed-gate-oracle' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('Scenario C does not accept an uninformed affirmative reply', 'Scenario C accepts any affirmative reply')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: Scenario C does not accept an uninformed affirmative reply'

    Assert-NegativeFixture 'surrender-treated-as-product-approval' {
        param($root)
        $target = Join-Path $root '.ai/contracts/ACTION_CARDS.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('An explicit surrender signal never becomes product authority', 'An explicit surrender signal accepts the recommended product outcome')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/ACTION_CARDS.md token=An explicit surrender signal never becomes product authority'

    Assert-NegativeFixture 'overbroad-concise-assent-rejected' {
        param($root)
        $target = Join-Path $root '.ai/roles/ARCHITECT.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('Repeated concise replies alone are not evidence of fatigue', 'Every repeated concise reply requires another confirmation')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/roles/ARCHITECT.md token=Repeated concise replies alone are not evidence of fatigue'

    Assert-NegativeFixture 'missing-collaborative-design-oracle' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('The broad collaborative seed first receives one compact collaboration frame', 'The broad collaborative seed expands directly into detailed documents')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: The broad collaborative seed first receives one compact collaboration frame'

    Assert-NegativeFixture 'missing-handoff-transport-boundary' {
        param($root)
        $target = Join-Path $root '.ai/WORKFLOW.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('A cross-session handoff is transport, not approval', 'A handoff is another user approval')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/WORKFLOW.md token=A cross-session handoff is transport, not approval'

    Assert-NegativeFixture 'missing-public-intent-gap-summary' {
        param($root)
        $target = Join-Path $root 'README.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('intent-gap-brief: current-intent-gap-ai-user', 'intent-gap note')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=README.md token=intent-gap-brief: current-intent-gap-ai-user'

    Assert-NegativeFixture 'missing-intent-gap-first-screen' {
        param($root)
        $target = Join-Path $root '.ai/contracts/ACTION_CARDS.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('current_behavior=<what the user/system does now + strongest evidence>', 'internal_history=<all implementation detail>')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/ACTION_CARDS.md token=current_behavior=<what the user/system does now + strongest evidence>'

    Assert-NegativeFixture 'missing-planning-gap-classification' {
        param($root)
        $target = Join-Path $root '.ai/roles/ARCHITECT.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('`implementation_open`', '`internal_detail`')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/roles/ARCHITECT.md token=`implementation_open`'

    Assert-NegativeFixture 'planning-silence-invents-visible-behavior' {
        param($root)
        $target = Join-Path $root '.ai/contracts/ARTIFACT_AUTHORITY.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('Silence is not permission to invent a new user-visible outcome', 'Silence may be filled by implementation preference')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/ARTIFACT_AUTHORITY.md token=Silence is not permission to invent a new user-visible outcome'

    Assert-NegativeFixture 'missing-intent-gap-oracle' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('The first Architect response begins with `current_behavior`, `intended_behavior`, and `confirmed_gap`', 'The Architect begins with internal implementation history')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: The first Architect response begins with `current_behavior`, `intended_behavior`, and `confirmed_gap`'

    Assert-NegativeFixture 'disproven-approach-remains-choice' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('already disproven technical approach is shown only as rejected evidence', 'already disproven technical approach remains a normal choice')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: already disproven technical approach is shown only as rejected evidence'

    Assert-NegativeFixture 'missing-bounded-expert-note-contract' {
        param($root)
        $target = Join-Path $root '.ai/contracts/ACTION_CARDS.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('## Bounded expert note', '## General background lecture')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/ACTION_CARDS.md token=## Bounded expert note'

    Assert-NegativeFixture 'expert-note-obscures-core-action' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('The expert note never precedes or obscures the action', 'The expert lecture precedes the action')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: The expert note never precedes or obscures the action'

    Assert-NegativeFixture 'independent-reviewer-context-starved' {
        param($root)
        $target = Join-Path $root '.ai/roles/REVIEWER.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace("Independence removes the authoring session's hidden reasoning and self-confirmation", 'Independence removes all project context')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } "Contract is missing a required invariant token: path=.ai/roles/REVIEWER.md token=Independence removes the authoring session's hidden reasoning and self-confirmation"

    Assert-NegativeFixture 'unsupported-personal-observation-promoted' {
        param($root)
        $target = Join-Path $root 'maintenance/RELEASE.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('A single personal observation normally remains a project preference', 'A single personal observation immediately becomes a Core invariant')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=maintenance/RELEASE.md token=A single personal observation normally remains a project preference'

    Assert-NegativeFixture 'missing-rule-enforcement-level-review' {
        param($root)
        $target = Join-Path $root 'maintenance/WORKFLOW_REVIEW.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('invariant | gate | default | presentation', 'all rules are equally blocking')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=maintenance/WORKFLOW_REVIEW.md token=invariant | gate | default | presentation'

    Assert-NegativeFixture 'empty-modern-eval' {
        param($root)
        $target = Join-Path $root 'evals/runs/EVAL-20990101T000000000Z-test-manual-v1.0-empty.md'
        $content = @'
---
schema_version: 2
id: EVAL-20990101T000000000Z-test-manual-v1.0-empty
status: completed
result: pass
completed_at: 2099-01-01T00:00:00.000Z
source_revision: 0000000000000000000000000000000000000000
source_tree: 0000000000000000000000000000000000000000
quality_floor: pass
workflow_version: manual-v1.0
regression_cases: []
---

# Workflow Eval

## Core Result

| Metric | Value | Evidence |
|---|---|---|

## Targeted Regressions

| Case | Result | Evidence |
|---|---|---|

## Decision
'@
        [System.IO.File]::WriteAllText($target, $content, [System.Text.UTF8Encoding]::new($false))
    } 'Completed Eval must name at least one regression case'

    Assert-NegativeFixture 'diagnosis-skips-approved-intent' {
        param($root)
        $target = Join-Path $root '.ai/reference/OPERATIONS.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('Reconstruct the delivery anchor from the current Task''s exact observable ACs', 'Infer the delivery anchor from nearby implementation')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/reference/OPERATIONS.md token=Reconstruct the delivery anchor from the current Task''s exact observable ACs'

    Assert-NegativeFixture 'inference-declared-confirmed' {
        param($root)
        $target = Join-Path $root '.ai/WORKFLOW.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('Never call a root cause confirmed until', 'A likely root cause may be called confirmed before')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/WORKFLOW.md token=Never call a root cause confirmed until'

    Assert-NegativeFixture 'specified-outcome-reasked' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('Before proposing a cause, choice, or new Task, the role reconstructs and states the exact approved observable outcome', 'The role may begin with a new technical choice')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: Before proposing a cause, choice, or new Task, the role reconstructs and states the exact approved observable outcome'

    Assert-NegativeFixture 'nonblocking-discovery-becomes-task' {
        param($root)
        $target = Join-Path $root '.ai/contracts/TASK_RECORD.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('A discovered `follow_up` is not independently READY', 'A discovered `follow_up` may become independently READY')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/TASK_RECORD.md token=A discovered `follow_up` is not independently READY'

    Assert-NegativeFixture 'unconfirmed-hypothesis-becomes-authority' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('Architecture, Task, state, and Knowledge record only confirmed or approved facts', 'Architecture may persist likely hypotheses as facts')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: Architecture, Task, state, and Knowledge record only confirmed or approved facts'

    Assert-NegativeFixture 'delivery-focus-hides-blocker' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('Delivery focus never hides a current blocker merely to reach a checkpoint faster', 'Delivery focus may defer a current blocker for momentum')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: Delivery focus never hides a current blocker merely to reach a checkpoint faster'

    Assert-NegativeFixture 'safe-stop-mutates-candidate' {
        param($root)
        $target = Join-Path $root '.ai/contracts/ACTION_CARDS.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('`fallback` defaults to stopping without changing candidate bytes', '`fallback` may edit the candidate to stop')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/ACTION_CARDS.md token=`fallback` defaults to stopping without changing candidate bytes'

    Assert-NegativeFixture 'uninspected-authoring-position-called-safe' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('It never calls an uninspected insertion/wiring position safe', 'It may call an uninspected insertion/wiring position safe')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: It never calls an uninspected insertion/wiring position safe'

    Assert-NegativeFixture 'token-saving-skips-required-evidence' {
        param($root)
        $target = Join-Path $root '.ai/evals/GOLDEN_CORE_BEHAVIOR.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('Saving tokens never removes a mandatory AC, safety check, release gate, or final evidence', 'Saving tokens may remove mandatory final evidence')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Golden Core Behavior is missing oracle token: Saving tokens never removes a mandatory AC, safety check, release gate, or final evidence'

    Assert-NegativeFixture 'planned-editor-save-deferred-until-review' {
        param($root)
        $target = Join-Path $root '.ai/contracts/TASK_RECORD.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('do not knowingly design a Build -> Review -> save -> Build loop', 'defer known editor saves until Review')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/TASK_RECORD.md token=do not knowingly design a Build -> Review -> save -> Build loop'

    Assert-NegativeFixture 'release-changelog-date-mismatch' {
        param($root)
        $target = Join-Path $root '.ai/maintenance/CHANGELOG.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('2026-08-07', '2026-08-06')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Latest CHANGELOG release date must match release.yaml: release=2026-08-07 changelog=2026-08-06'

    Assert-NegativeFixture 'missing-historical-delivery-slice-compatibility' {
        param($root)
        $target = Join-Path $root '.ai/contracts/ARCHITECTURE.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('A historical approved Architecture without `Delivery Slices` remains readable', 'A historical approved Architecture must already contain `Delivery Slices`')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/ARCHITECTURE.md token=A historical approved Architecture without `Delivery Slices` remains readable'

    Assert-NegativeFixture 'unapproved-feature-deferral-reaches-idle' {
        param($root)
        $target = Join-Path $root '.ai/roles/ARCHITECT.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('Only a user-approved deferral may rest at `synced/idle`', 'Any named deferral may rest at `synced/idle`')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/roles/ARCHITECT.md token=Only a user-approved deferral may rest at `synced/idle`'

    Assert-NegativeFixture 'feature-convergence-production-write-ambiguity' {
        param($root)
        $target = Join-Path $root '.ai/roles/ARCHITECT.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('This convergence does not write production source', 'This convergence is read-only plus updates')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/roles/ARCHITECT.md token=This convergence does not write production source'

    Assert-NegativeFixture 'mixed-open-feature-convergence-reaches-idle' {
        param($root)
        $target = Join-Path $root '.ai/contracts/STATE.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('none is `open` or `conflict`', 'an approved deferral may hide an open outcome')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/STATE.md token=none is `open` or `conflict`'

    Assert-NegativeFixture 'missing-code-inspection-attribution-recovery' {
        param($root)
        $target = Join-Path $root '.ai/contracts/STATE.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('resolve_code_inspection_attribution_then_resume_reviewer_inspection_wait', 'resolve_context_as_needed')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/STATE.md token=resolve_code_inspection_attribution_then_resume_reviewer_inspection_wait'

    Assert-NegativeFixture 'integration-completion-skips-feature-convergence' {
        param($root)
        $target = Join-Path $root '.ai/contracts/MAIN_DESK.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('it routes Architect through `STATE.md`''s `reconcile_feature_boundary` before choosing a disposition', 'it chooses a terminal disposition directly after Integration PASS')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/MAIN_DESK.md token=it routes Architect through `STATE.md`''s `reconcile_feature_boundary` before choosing a disposition'

    Assert-NegativeFixture 'missing-integration-pass-feature-convergence-route' {
        param($root)
        $target = Join-Path $root '.ai/contracts/STATE.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('otherwise Architect with `reconcile_feature_boundary` when no next Task or active work remains', 'otherwise Main Front Desk chooses the terminal route')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/contracts/STATE.md token=otherwise Architect with `reconcile_feature_boundary` when no next Task or active work remains'

    Assert-NegativeFixture 'stale-terminal-pass-quality-floor' {
        param($root)
        $target = Join-Path $root '.ai/evals/README.md'
        $text = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $text = $text.Replace('terminal Task or Integration PASS without remaining Knowledge work reaches Architect Feature convergence before any `synced/idle` disposition', 'terminal PASS without Knowledge work reaches synced idle')
        [System.IO.File]::WriteAllText($target, $text, [System.Text.UTF8Encoding]::new($false))
    } 'Contract is missing a required invariant token: path=.ai/evals/README.md token=terminal Task or Integration PASS without remaining Knowledge work reaches Architect Feature convergence before any `synced/idle` disposition'
}
finally {
    if (Test-Path -LiteralPath $runRoot) {
        Assert-SafeFixturePath $runRoot
        Remove-Item -LiteralPath $runRoot -Recurse -Force
    }
}

# Expected negative fixtures leave their child process exit code in
# LASTEXITCODE. GitHub Actions appends an exit check after dot-sourcing this
# script, so reset it only after every assertion and cleanup completed.
$global:LASTEXITCODE = 0
