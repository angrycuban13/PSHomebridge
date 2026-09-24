$script:HomebridgeAccessTokens = @{}

$privatePath = Join-Path $PSScriptRoot 'Private'
$publicPath = Join-Path $PSScriptRoot 'Public'

foreach ($scriptFile in @(Get-ChildItem -LiteralPath $privatePath -Filter '*.ps1' -File | Sort-Object Name)) {
    . $scriptFile.FullName
}

foreach ($scriptFile in @(Get-ChildItem -LiteralPath $publicPath -Filter '*.ps1' -File | Sort-Object Name)) {
    . $scriptFile.FullName
}
