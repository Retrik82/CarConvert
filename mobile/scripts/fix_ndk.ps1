# Reinstall broken Android NDK 27 (fixes CXX1101 missing source.properties).
# Run from: mobile\scripts\fix_ndk.ps1

$ErrorActionPreference = "Stop"

$javaHomeCandidates = @(
    "D:\Android Studio\jbr",
    "$env:ProgramFiles\Android\Android Studio\jbr",
    "${env:ProgramFiles(x86)}\Android\Android Studio\jbr"
)

$javaHome = $null
foreach ($candidate in $javaHomeCandidates) {
    if (Test-Path "$candidate\bin\java.exe") {
        $javaHome = $candidate
        break
    }
}

if (-not $javaHome) {
    Write-Error "JDK not found. Install Android Studio or set JAVA_HOME manually."
}

$env:JAVA_HOME = $javaHome
Write-Host "JAVA_HOME=$javaHome"

$sdk = "$env:LOCALAPPDATA\Android\Sdk"
$ndkDir = "$sdk\ndk\27.0.12077973"
$sdkmanager = Get-ChildItem -Path "$sdk\cmdline-tools" -Recurse -Filter "sdkmanager.bat" -ErrorAction SilentlyContinue |
    Select-Object -First 1

if (-not $sdkmanager) {
    Write-Error "sdkmanager.bat not found. Install Android SDK Command-line Tools in Android Studio SDK Manager."
}

if (Test-Path $ndkDir) {
    Write-Host "Removing broken NDK: $ndkDir"
    Remove-Item -Recurse -Force $ndkDir
}

Write-Host "Installing ndk;27.0.12077973 ..."
& $sdkmanager.FullName --install "ndk;27.0.12077973"

if (-not (Test-Path "$ndkDir\source.properties")) {
    Write-Error "NDK install failed. Use Android Studio: SDK Manager -> SDK Tools -> NDK (Side by side) 27.0.12077973 -> Apply."
}

Write-Host "OK: NDK 27 installed at $ndkDir"
