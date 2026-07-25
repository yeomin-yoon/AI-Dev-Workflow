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
        [ValidateSet('pass', 'fail')][string]$Result
    )

    $sourceRevision = (& git -C $FixtureRoot rev-parse HEAD).Trim()
    $sourceTree = (& git -C $FixtureRoot rev-parse 'HEAD^{tree}').Trim()
    $quality = if ($Result -eq 'pass') { 'pass' } else { 'fail' }
    $accepted = if ($Result -eq 'pass') { 'yes' } else { 'no' }
    $target = Join-Path $FixtureRoot "evals/runs/EVAL-20990101T000000000Z-test-manual-v1.0-${Result}.md"
    $content = @"
---
schema_version: 2
id: EVAL-20990101T000000000Z-test-manual-v1.0-$Result
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
workflow_version: manual-v1.0
eval_type: fixed_contract
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

    Assert-NegativeFixture 'missing-role' {
        param($root)
        $target = Join-Path $root '.ai/roles/ARCHITECT.md'
        Assert-SafeFixturePath $target
        Remove-Item -LiteralPath $target -Force
    } 'Missing distribution inventory file: .ai/roles/ARCHITECT.md'

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
}
finally {
    if (Test-Path -LiteralPath $runRoot) {
        Assert-SafeFixturePath $runRoot
        Remove-Item -LiteralPath $runRoot -Recurse -Force
    }
}
