Param(
  [string]$ProjectRoot = "."
)

$ErrorActionPreference = "Stop"

Write-Host "== Release preflight check =="

$keyProps = Join-Path $ProjectRoot "android/key.properties"
$keystore = Join-Path $ProjectRoot "android/upload-keystore.jks"
$gradle = Join-Path $ProjectRoot "android/app/build.gradle.kts"
$manifest = Join-Path $ProjectRoot "android/app/src/main/AndroidManifest.xml"
$mainDart = Join-Path $ProjectRoot "lib/main.dart"

if (-not (Test-Path $keyProps)) {
  throw "Missing android/key.properties"
}

$content = Get-Content $keyProps -Raw
if ($content -match "CHANGE_ME") {
  throw "android/key.properties contains placeholder values."
}

if (-not (Test-Path $keystore)) {
  throw "Missing android/upload-keystore.jks"
}

$gradleContent = Get-Content $gradle -Raw
if ($gradleContent -notmatch "applicationId = `"io.github.kjh96.yeokjangnim`"") {
  throw "applicationId is not set to io.github.kjh96.yeokjangnim"
}

$manifestContent = Get-Content $manifest -Raw
if ($manifestContent -notmatch "ACCESS_FINE_LOCATION") {
  throw "Location permission is missing in AndroidManifest.xml"
}

$dartContent = Get-Content $mainDart -Raw
if ($dartContent -notmatch "kPrivacyPolicyUrl" -or $dartContent -notmatch "kTermsUrl") {
  throw "Policy URL constants are missing in main.dart"
}

Write-Host "All preflight checks passed."
