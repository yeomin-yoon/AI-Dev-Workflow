#Requires -Version 5.1
param(
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot),

    # Validator to compare against. Defaults to the committed HEAD copy, which is
    # the last state a human reviewed. Pass an explicit path to compare against
    # any other revision or working copy.
    [string]$Baseline,

    # Dynamically mutate this many still-enforced tokens and require the current
    # validator to fail on each. Proves the static reasoning below is sound.
    # 0 skips the dynamic pass.
    [int]$VerifySample = 12
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Why this tool exists
# -------------------
# Refactoring the validator means replacing enumerated string tokens with derived
# structural checks. The failure mode is silent: a token disappears from the list
# while its sentence still sits in the contract, so the rule reads as protected
# but nothing enforces it. Reviewing that by eye does not scale past a few hundred
# tokens and has already produced one real regression.
#
# So the comparison is mechanical. Every baseline token lands in exactly one class:
#
#   enforced           still in the current validator's list        -> fine
#   dropped_protection sentence still in the contract file,
#                      but no longer in the validator's list        -> REGRESSION
#   wording_drift      sentence gone, but the same text is present
#                      once case and whitespace are normalized       -> the rule
#                                                                      survived and
#                                                                      only its guard
#                                                                      died
#   enforcement_ended  sentence not found at all                     -> unknown:
#                                                                      the rule may
#                                                                      have been
#                                                                      removed, or
#                                                                      rewritten far
#                                                                      enough that no
#                                                                      guard matches
#
# `dropped_protection` and `wording_drift` must be zero. `enforcement_ended` is not a
# failure and is not evidence of intent either: this tool cannot tell a deliberate
# rule removal from a rewrite that quietly lost its guard, so it lists them for a
# human instead of claiming they were deliberate.

function Get-TokenMap {
    param([string]$ValidatorText)

    $map = @{}
    $lines = $ValidatorText -split "`r?`n"
    $inBlock = $false
    $currentPath = $null

    foreach ($line in $lines) {
        if (-not $inBlock) {
            if ($line -match '^\$contractTokenRequirements = @\{') {
                $inBlock = $true
            }
            continue
        }
        if ($line -match '^\}') {
            break
        }
        if ($line -match "^    '(?<path>[^']+)' = @\($") {
            $currentPath = $Matches['path']
            if (-not $map.ContainsKey($currentPath)) {
                $map[$currentPath] = New-Object System.Collections.Generic.List[string]
            }
            continue
        }
        if ($line -match '^    \)') {
            $currentPath = $null
            continue
        }
        if ($null -ne $currentPath -and $line -match "^        '(?<token>.*)',?\s*$") {
            $raw = $Matches['token']
            $raw = $raw -replace ",$", ''
            $raw = $raw -replace "'$", ''
            $map[$currentPath].Add($raw.Replace("''", "'"))
        }
    }
    return $map
}

$repoRoot = (Resolve-Path -LiteralPath $RepositoryRoot).ProviderPath
$currentValidatorPath = Join-Path $repoRoot 'tools/validate-workflow.ps1'
if (-not (Test-Path -LiteralPath $currentValidatorPath -PathType Leaf)) {
    Write-Output 'FAIL compare: tools/validate-workflow.ps1 not found'
    exit 1
}

if ($Baseline) {
    if (-not (Test-Path -LiteralPath $Baseline -PathType Leaf)) {
        Write-Output "FAIL compare: baseline not found: $Baseline"
        exit 1
    }
    $baselineText = [System.IO.File]::ReadAllText((Resolve-Path -LiteralPath $Baseline).ProviderPath, [System.Text.Encoding]::UTF8)
    $baselineLabel = $Baseline
}
else {
    $previousErrorAction = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $baselineText = (& git -C $repoRoot show 'HEAD:tools/validate-workflow.ps1') -join "`n"
    $gitExit = $LASTEXITCODE
    $ErrorActionPreference = $previousErrorAction
    if ($gitExit -ne 0 -or [string]::IsNullOrWhiteSpace($baselineText)) {
        Write-Output 'FAIL compare: could not read HEAD:tools/validate-workflow.ps1'
        exit 1
    }
    $baselineLabel = 'HEAD'
}

$currentText = [System.IO.File]::ReadAllText($currentValidatorPath, [System.Text.Encoding]::UTF8)

$baselineMap = Get-TokenMap $baselineText
$currentMap = Get-TokenMap $currentText

function Get-Normalized {
    param([string]$Text)
    return ((($Text -replace '\s+', ' ')).ToLowerInvariant())
}

# Match the current guard set on normalized text. A guard that differs only in
# case or spacing is the same guard, so re-guarding a drifted rule under its
# corrected wording counts as enforced rather than as a fresh drift.
$currentTokens = New-Object System.Collections.Generic.HashSet[string]
foreach ($path in $currentMap.Keys) {
    foreach ($token in $currentMap[$path]) {
        $null = $currentTokens.Add("$path`t$(Get-Normalized $token)")
    }
}

$fileCache = @{}
function Get-ContractText {
    param([string]$RelativePath)
    if ($fileCache.ContainsKey($RelativePath)) {
        return $fileCache[$RelativePath]
    }
    $full = Join-Path $repoRoot $RelativePath
    $text = if (Test-Path -LiteralPath $full -PathType Leaf) {
        [System.IO.File]::ReadAllText($full, [System.Text.Encoding]::UTF8)
    }
    else {
        $null
    }
    $fileCache[$RelativePath] = $text
    return $text
}

$enforced = New-Object System.Collections.Generic.List[string]
$droppedProtection = New-Object System.Collections.Generic.List[string]
$wordingDrift = New-Object System.Collections.Generic.List[string]
$enforcementEnded = New-Object System.Collections.Generic.List[string]
$missingFile = New-Object System.Collections.Generic.List[string]
$baselineTokenCount = 0

foreach ($path in ($baselineMap.Keys | Sort-Object)) {
    foreach ($token in $baselineMap[$path]) {
        $baselineTokenCount++
        if ($currentTokens.Contains("$path`t$(Get-Normalized $token)")) {
            $enforced.Add("$path :: $token")
            continue
        }
        $contractText = Get-ContractText $path
        if ($null -eq $contractText) {
            $missingFile.Add("$path :: $token")
            continue
        }
        if ($contractText.Contains($token)) {
            $droppedProtection.Add("$path :: $token")
        }
        elseif ((Get-Normalized $contractText).Contains((Get-Normalized $token))) {
            $wordingDrift.Add("$path :: $token")
        }
        else {
            $enforcementEnded.Add("$path :: $token")
        }
    }
}

Write-Output "COMPARE baseline=$baselineLabel baseline_tokens=$baselineTokenCount current_tokens=$($currentTokens.Count)"
Write-Output "enforced=$($enforced.Count) dropped_protection=$($droppedProtection.Count) wording_drift=$($wordingDrift.Count) enforcement_ended=$($enforcementEnded.Count) missing_file=$($missingFile.Count)"

if ($wordingDrift.Count -gt 0) {
    Write-Output ''
    Write-Output "wording_drift ($($wordingDrift.Count)) - the rule text is still there under different case or spacing, so the rule survived and only its guard died:"
    foreach ($item in $wordingDrift) {
        Write-Output "  ~ $item"
    }
}

if ($enforcementEnded.Count -gt 0) {
    Write-Output ''
    Write-Output "enforcement_ended ($($enforcementEnded.Count)) - no guard matches any more. This tool cannot tell a deliberate removal from a rewrite that lost its guard; check each against the current contract:"
    foreach ($item in $enforcementEnded) {
        Write-Output "  ? $item"
    }
}

if ($missingFile.Count -gt 0) {
    Write-Output ''
    Write-Output "missing_file ($($missingFile.Count)) - guarded file no longer exists:"
    foreach ($item in $missingFile) {
        Write-Output "  ? $item"
    }
}

$dynamicFailures = New-Object System.Collections.Generic.List[string]
$dynamicChecked = 0
if ($VerifySample -gt 0 -and $enforced.Count -gt 0) {
    # Static classification says these tokens are still enforced. Prove it on a
    # sample by corrupting each one and requiring the current validator to fail.
    $sample = @($enforced | Get-Random -Count ([Math]::Min($VerifySample, $enforced.Count)))
    foreach ($item in $sample) {
        $separator = $item.IndexOf(' :: ')
        $path = $item.Substring(0, $separator)
        $token = $item.Substring($separator + 4)
        $full = Join-Path $repoRoot $path
        $original = [System.IO.File]::ReadAllText($full, [System.Text.Encoding]::UTF8)
        $mutated = $original.Replace($token, 'COMPARE_HARNESS_MUTATION')
        if ($mutated -eq $original) {
            $dynamicFailures.Add("token not present in file, cannot mutate: $item")
            continue
        }
        try {
            [System.IO.File]::WriteAllText($full, $mutated, [System.Text.UTF8Encoding]::new($false))
            $previousErrorAction = $ErrorActionPreference
            $ErrorActionPreference = 'Continue'
            $null = & powershell -NoProfile -ExecutionPolicy Bypass -File $currentValidatorPath -RepositoryRoot $repoRoot
            $validatorExit = $LASTEXITCODE
            $ErrorActionPreference = $previousErrorAction
            $dynamicChecked++
            if ($validatorExit -eq 0) {
                $dynamicFailures.Add("validator passed on a corrupted enforced token: $item")
            }
        }
        finally {
            [System.IO.File]::WriteAllText($full, $original, [System.Text.UTF8Encoding]::new($false))
        }
    }
}

Write-Output ''
Write-Output "dynamic_verified=$dynamicChecked dynamic_failures=$($dynamicFailures.Count)"
foreach ($failure in $dynamicFailures) {
    Write-Output "  ! $failure"
}

if ($wordingDrift.Count -gt 0) {
    Write-Output ''
    Write-Output 'FAIL compare: a rule survived a rewrite but its guard no longer matches.'
    exit 1
}

if ($droppedProtection.Count -gt 0) {
    Write-Output ''
    Write-Output "dropped_protection ($($droppedProtection.Count)) - sentence still in the contract but no longer enforced:"
    foreach ($item in $droppedProtection) {
        Write-Output "  - $item"
    }
    Write-Output ''
    Write-Output 'FAIL compare: a refactor removed enforcement without removing the rule.'
    exit 1
}

if ($dynamicFailures.Count -gt 0) {
    Write-Output ''
    Write-Output 'FAIL compare: dynamic verification contradicted the static classification.'
    exit 1
}

Write-Output ''
Write-Output 'PASS compare: every baseline protection is still enforced, or its rule was removed from the contract.'
exit 0
