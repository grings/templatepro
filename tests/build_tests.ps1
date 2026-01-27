$env:BDS = 'C:\Program Files (x86)\Embarcadero\Studio\37.0'
$env:BDSCOMMONDIR = 'C:\Users\Public\Documents\Embarcadero\Studio\37.0'
$env:FrameworkDir = 'C:\Windows\Microsoft.NET\Framework\v4.0.30319'
$env:PATH = "$env:FrameworkDir;$env:BDS\bin;$env:BDS\bin64;$env:PATH"

Write-Host "=== Building templateprounittests (Win64/Debug) ==="
& "$env:FrameworkDir\msbuild.exe" "C:\DEV\TemplatePro\tests\templateprounittests.dproj" /t:Build "/p:Config=Debug" "/p:Platform=Win64" /verbosity:normal
if ($LASTEXITCODE -ne 0) {
    Write-Host "=== BUILD FAILED (exit code: $LASTEXITCODE) ==="
    exit 1
}
Write-Host "=== BUILD SUCCEEDED ==="
Write-Host ""
Write-Host "=== Running tests ==="
Set-Location "C:\DEV\TemplatePro\tests\bin"
& ".\templateprounittests.exe"
Write-Host "=== Tests finished (exit code: $LASTEXITCODE) ==="
