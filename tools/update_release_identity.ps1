param(
  [Parameter(Mandatory=$true)][string]$Stage,
  [string]$Version = "7.1.0",
  [int]$Build = 254,
  [string]$Channel = "LTS",
  [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot ".."))
)

$target = Join-Path $ProjectRoot "lib\app\app_version.dart"
if (-not (Test-Path $target)) {
  throw "Súbor identity neexistuje: $target"
}

$content = Get-Content -Raw -Encoding UTF8 $target
$content = [regex]::Replace($content, "static const String version = '.*?';", "static const String version = '$Version';")
$content = [regex]::Replace($content, "static const int build = \d+;", "static const int build = $Build;")
$content = [regex]::Replace($content, "static const String channel = '.*?';", "static const String channel = '$Channel';")
$content = [regex]::Replace($content, "static const String stage = '.*?';", "static const String stage = '$Stage';")
Set-Content -Path $target -Value $content -Encoding UTF8

Write-Host "Release identity updated:"
Write-Host "  $Version $Channel Build $Build $Stage"
Write-Host "  $target"
