<#
.SYNOPSIS
Validates PSHomebridge release metadata.

.DESCRIPTION
Validates the manifest version and its dated changelog section. The script can compare the manifest version with earlier or published versions.

.PARAMETER ManifestPath
Specifies the module manifest to validate. The default is the PSHomebridge source manifest.

.PARAMETER ChangelogPath
Specifies the changelog to validate. The default is the repository changelog.

.PARAMETER PreviousVersion
Specifies an earlier repository version. The manifest version must be greater than this version.

.PARAMETER PublishedVersion
Specifies the latest published version. The manifest version must be greater than this version.

.EXAMPLE
./PSHomebridge/tools/Test-ReleaseMetadata.ps1

Validates the current manifest version and its matching changelog section.

.EXAMPLE
./PSHomebridge/tools/Test-ReleaseMetadata.ps1 -PreviousVersion 1.0.0 -PublishedVersion 1.0.0

Validates that the current version is greater than version 1.0.0 in both comparison sources.

.INPUTS
None.

You cannot pipe objects to this script.

.OUTPUTS
System.Management.Automation.PSCustomObject.

This script returns the validated version and release date.
#>
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [System.String]
    $ManifestPath = (Join-Path (Split-Path $PSScriptRoot -Parent) 'Source/PSHomebridge.psd1'),

    [Parameter()]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [System.String]
    $ChangelogPath = (Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) 'CHANGELOG.md'),

    [Parameter()]
    [System.String]
    $PreviousVersion,

    [Parameter()]
    [System.String]
    $PublishedVersion
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$stableVersionPattern = '^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$'
$manifest = Import-PowerShellDataFile -Path $ManifestPath
$version = [System.String]$manifest.ModuleVersion

if ($version -notmatch $stableVersionPattern) {
    throw "Manifest version '$version' is not a stable three-part semantic version."
}

$parsedVersion = [System.Version]$version

foreach ($comparison in @(
        @{
            Name  = 'previous'
            Value = $PreviousVersion
        }
        @{
            Name  = 'published'
            Value = $PublishedVersion
        }
    )) {
    if ([System.String]::IsNullOrWhiteSpace($comparison.Value)) {
        continue
    }

    if ($comparison.Value -notmatch $stableVersionPattern) {
        throw "The $($comparison.Name) version '$($comparison.Value)' is not a stable three-part semantic version."
    }

    if ($parsedVersion -le [System.Version]$comparison.Value) {
        throw "Manifest version $version must be greater than the $($comparison.Name) version $($comparison.Value)."
    }
}

$changelog = Get-Content -LiteralPath $ChangelogPath -Raw
$escapedVersion = [System.Text.RegularExpressions.Regex]::Escape($version)
$releasePattern = "(?ms)^## \[$escapedVersion\] - (?<Date>\d{4}-\d{2}-\d{2})\s*(?<Notes>.*?)(?=^## \[|\z)"
$releaseMatches = [System.Text.RegularExpressions.Regex]::Matches($changelog, $releasePattern)

if ($releaseMatches.Count -ne 1) {
    throw "CHANGELOG.md must contain exactly one dated $version release."
}

$releaseDateText = $releaseMatches[0].Groups['Date'].Value
$releaseDate = [System.DateTime]::MinValue
$validDate = [System.DateTime]::TryParseExact(
    $releaseDateText,
    'yyyy-MM-dd',
    [System.Globalization.CultureInfo]::InvariantCulture,
    [System.Globalization.DateTimeStyles]::None,
    [ref]$releaseDate
)

if (-not $validDate) {
    throw "CHANGELOG.md release date '$releaseDateText' is not valid."
}

$releaseNotes = $releaseMatches[0].Groups['Notes'].Value.Trim()

if ([System.String]::IsNullOrWhiteSpace($releaseNotes) -or $releaseNotes -notmatch '(?m)^###\s+\S') {
    throw "CHANGELOG.md release $version must contain categorized release notes."
}

[PSCustomObject]@{
    Version     = $version
    ReleaseDate = $releaseDate.ToString('yyyy-MM-dd')
}
