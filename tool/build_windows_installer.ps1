$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$pubspecPath = Join-Path $repoRoot "pubspec.yaml"
$installerPath = Join-Path $repoRoot "windows/installer/toney.iss"

if (-not (Test-Path $pubspecPath)) {
  Write-Error "Missing $pubspecPath."
  exit 1
}

if (-not (Test-Path $installerPath)) {
  Write-Error "Missing $installerPath."
  exit 1
}

$versionMatch = Select-String -Path $pubspecPath -Pattern '^\s*version:\s*(.+)$' | Select-Object -First 1
if (-not $versionMatch) {
  Write-Error "Missing version in pubspec.yaml."
  exit 1
}

$version = $versionMatch.Matches[0].Groups[1].Value.Trim()
if ([string]::IsNullOrWhiteSpace($version)) {
  Write-Error "Missing version in pubspec.yaml."
  exit 1
}

$content = Get-Content -Path $installerPath -Raw
$pattern = '(?m)^\s*#define\s+AppVersion\s+"[^"]*"'
$replaced = $content -replace $pattern, { "#define AppVersion `"$version`"" }
if ($replaced -eq $content) {
  Write-Error "Missing AppVersion define in $installerPath."
  exit 1
}

if ($replaced -ne $content) {
  [System.IO.File]::WriteAllText($installerPath, $replaced)
}

& ISCC $installerPath
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}
