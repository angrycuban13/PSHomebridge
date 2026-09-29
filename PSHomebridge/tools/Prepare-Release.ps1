<#
.SYNOPSIS
Prepares the PSHomebridge manifest and changelog for a release.

.DESCRIPTION
Sets the module version and converts the unreleased changelog content into a dated release. The script does not commit, tag, push, or publish changes.

.PARAMETER Version
Specifies the new stable semantic version. The version must be greater than the current manifest version.

.PARAMETER ReleaseDate
Specifies the release date for the changelog. The default is the current local date.

.PARAMETER ManifestPath
Specifies the module manifest to update. The default is the PSHomebridge source manifest.

.PARAMETER ChangelogPath
Specifies the changelog to update. The default is the repository changelog.

.EXAMPLE
./PSHomebridge/tools/Prepare-Release.ps1 -Version 1.1.0

Prepares version 1.1.0 with the current local date.

.EXAMPLE
./PSHomebridge/tools/Prepare-Release.ps1 -Version 1.1.0 -ReleaseDate '2026-10-01' -WhatIf

Shows the manifest and changelog changes for version 1.1.0 without writing them.

.INPUTS
None.

You cannot pipe objects to this script.

.OUTPUTS
System.Management.Automation.PSCustomObject.

This script returns the prepared version, release date, manifest path, and changelog path.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$')]
    [System.String]
    $Version,

    [Parameter()]
    [System.DateTime]
    $ReleaseDate = [System.DateTime]::Today,

    [Parameter()]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [System.String]
    $ManifestPath = (Join-Path (Split-Path $PSScriptRoot -Parent) 'Source/PSHomebridge.psd1'),

    [Parameter()]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [System.String]
    $ChangelogPath = (Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) 'CHANGELOG.md')
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$resolvedManifestPath = (Resolve-Path -LiteralPath $ManifestPath).Path
$resolvedChangelogPath = (Resolve-Path -LiteralPath $ChangelogPath).Path
$manifest = Import-PowerShellDataFile -Path $resolvedManifestPath
$currentVersion = [System.Version]$manifest.ModuleVersion
$targetVersion = [System.Version]$Version

if ($targetVersion -le $currentVersion) {
    throw "Version $Version must be greater than the current module version $currentVersion."
}

$manifestContent = Get-Content -LiteralPath $resolvedManifestPath -Raw
$manifestVersionPattern = "(?m)^(?<Prefix> {4}ModuleVersion\s*=\s*)'[^']+'"
$manifestVersionMatches = [System.Text.RegularExpressions.Regex]::Matches($manifestContent, $manifestVersionPattern)

if ($manifestVersionMatches.Count -ne 1) {
    throw "Expected exactly one ModuleVersion assignment in $resolvedManifestPath."
}

$updatedManifestContent = [System.Text.RegularExpressions.Regex]::Replace(
    $manifestContent,
    $manifestVersionPattern,
    { param($match) "$($match.Groups['Prefix'].Value)'$Version'" }
)

$releaseNotesPattern = "(?m)^(?<Prefix>\s*ReleaseNotes\s*=\s*)'[^']*'"
$releaseNotesMatches = [System.Text.RegularExpressions.Regex]::Matches($updatedManifestContent, $releaseNotesPattern)

if ($releaseNotesMatches.Count -eq 1) {
    $releaseNotes = "PSHomebridge $Version release. See https://github.com/angrycuban13/PSHomebridge/blob/main/CHANGELOG.md."
    $updatedManifestContent = [System.Text.RegularExpressions.Regex]::Replace(
        $updatedManifestContent,
        $releaseNotesPattern,
        { param($match) "$($match.Groups['Prefix'].Value)'$releaseNotes'" }
    )
}

$changelogContent = Get-Content -LiteralPath $resolvedChangelogPath -Raw
$escapedVersion = [System.Text.RegularExpressions.Regex]::Escape($Version)
$datedHeadingPattern = "(?m)^## \[$escapedVersion\] - \d{4}-\d{2}-\d{2}\s*$"

if ([System.Text.RegularExpressions.Regex]::IsMatch($changelogContent, $datedHeadingPattern)) {
    throw "CHANGELOG.md already contains a dated $Version release."
}

$versionHeadingPattern = "(?m)^## \[$escapedVersion\] - Unreleased\s*$"
$genericHeadingPattern = '(?m)^## \[Unreleased\]\s*$'
$newHeading = "## [Unreleased]$([System.Environment]::NewLine)$([System.Environment]::NewLine)## [$Version] - $($ReleaseDate.ToString('yyyy-MM-dd'))"

if ([System.Text.RegularExpressions.Regex]::IsMatch($changelogContent, $versionHeadingPattern)) {
    $unreleasedSectionPattern = "(?ms)^## \[$escapedVersion\] - Unreleased\s*(?<Body>.*?)(?=^## \[|\z)"
    $updatedChangelogContent = [System.Text.RegularExpressions.Regex]::Replace(
        $changelogContent,
        $versionHeadingPattern,
        $newHeading,
        1
    )
}
elseif ([System.Text.RegularExpressions.Regex]::IsMatch($changelogContent, $genericHeadingPattern)) {
    $unreleasedSectionPattern = '(?ms)^## \[Unreleased\]\s*(?<Body>.*?)(?=^## \[|\z)'
    $updatedChangelogContent = [System.Text.RegularExpressions.Regex]::Replace(
        $changelogContent,
        $genericHeadingPattern,
        $newHeading,
        1
    )
}
else {
    throw 'CHANGELOG.md does not contain an unreleased section.'
}

$unreleasedSection = [System.Text.RegularExpressions.Regex]::Match($changelogContent, $unreleasedSectionPattern)

if (-not $unreleasedSection.Success -or $unreleasedSection.Groups['Body'].Value -notmatch '(?m)^###\s+') {
    throw 'The unreleased changelog section does not contain any categorized changes.'
}

$targetDescription = "$resolvedManifestPath and $resolvedChangelogPath"

if ($PSCmdlet.ShouldProcess($targetDescription, "Prepare PSHomebridge $Version release")) {
    Set-Content -LiteralPath $resolvedManifestPath -Value $updatedManifestContent -NoNewline

    Set-Content -LiteralPath $resolvedChangelogPath -Value $updatedChangelogContent -NoNewline

    [PSCustomObject]@{
        Version       = $Version
        ReleaseDate   = $ReleaseDate.ToString('yyyy-MM-dd')
        ManifestPath  = $resolvedManifestPath
        ChangelogPath = $resolvedChangelogPath
    }
}
