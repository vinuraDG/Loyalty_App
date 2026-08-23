param(
    [switch]$SkipFlutterBuild,
    [string]$InnoSetupPath = ""
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

$releaseDir = Join-Path $projectRoot "build\windows\x64\runner\Release"
$exePath = Join-Path $releaseDir "loyalty_app.exe"

if (-not $SkipFlutterBuild) {
    Write-Host "Building Flutter Windows release..."
    flutter build windows --release
}

if (-not (Test-Path -LiteralPath $exePath)) {
    throw "Flutter build output not found: $exePath"
}

if ([string]::IsNullOrWhiteSpace($InnoSetupPath)) {
    $iscc = Get-Command ISCC.exe -ErrorAction SilentlyContinue
    if ($null -eq $iscc) {
        $candidates = @(
            "$env:ProgramFiles\Inno Setup 6\ISCC.exe",
            "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe"
        )
        $InnoSetupPath = $candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    } else {
        $InnoSetupPath = $iscc.Source
    }
}

if ([string]::IsNullOrWhiteSpace($InnoSetupPath) -or -not (Test-Path -LiteralPath $InnoSetupPath)) {
    throw "Inno Setup compiler (ISCC.exe) not found. Install Inno Setup 6 or pass -InnoSetupPath."
}

Write-Host "Creating installer..."
& $InnoSetupPath (Join-Path $projectRoot "installer.iss")
if ($LASTEXITCODE -ne 0) { throw "Inno Setup failed with exit code $LASTEXITCODE" }
Write-Host "Installer created in $projectRoot\installer_output"
