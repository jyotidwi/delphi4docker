# Build script for Delphi Slim Compiler using .bdsproj settings
# Usage: .\build_activator.ps1

$ProjectDir = "c:\CFRBACKUP\delphi4docker\4K Download Products Activator\Source"
$SlimBDS = "C:\Delphi37_Slim"
$ProjectFile = "Activator.dpr"

# --- 1. Load Slim Environment ---
$env:PATH = "$SlimBDS\bin;" + $env:PATH
$env:BDS = $SlimBDS

# --- 2. Create directories defined in .bdsproj ---
$OutputDir = Join-Path $ProjectDir "Bin"
$DcuDir = Join-Path $ProjectDir "Dcu"

if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir }
if (-not (Test-Path $DcuDir)) { New-Item -ItemType Directory -Path $DcuDir }

# --- 3. Build Command ---
# Based on Activator.bdsproj settings:
# - OutputDir: .\Bin (-E)
# - UnitOutputDir: .\Dcu (-N)
# - ConsoleApp: 1 (-CC)
# - Namespaces: Vcl;Vcl.Imaging;System;Winapi;System.Win (-NS)
# - SearchPath: Units;Forms (-U)

$BuildCmd = "dcc32.exe"
$Args = @(
    "-B",                             # Build all units
    "-Q",                             # Quiet mode
    "-E`"$OutputDir`"",                # Executable output directory
    "-N`"$DcuDir`"",                   # DCU output directory
    "-U`"Units;Forms`"",               # Unit search path
    "-NS`"Vcl;Vcl.Imaging;System;Winapi;System.Win`"", # Namespaces
    "-CC",                            # Console application (as per .bdsproj Linker/ConsoleApp=1)
    "`"$ProjectDir\$ProjectFile`""     # Target project
)

Write-Host "Building $ProjectFile using settings from .bdsproj..."
Set-Location $ProjectDir
& $BuildCmd $Args

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nBuild Successful!"
    Write-Host "Output: $OutputDir\Activator.exe"
} else {
    Write-Error "Build Failed!"
}
