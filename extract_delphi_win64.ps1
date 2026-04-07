# Extract Delphi Win64 Compiler Script
# Usage: .\extract_delphi_win64.ps1 -BDSPath "C:\Program Files (x86)\Embarcadero\Studio\23.0" -OutputPath "C:\DelphiWin64"

param (
    [string]$BDSPath = "C:\Program Files (x86)\Embarcadero\Studio\23.0",
    [string]$OutputPath = "C:\DelphiWin64"
)

# Note: RAD Studio 13 was skipped. Using version 23.0 (RAD Studio 12 Athens) as default.
$Version = "23.0" 

if (-not (Test-Path $BDSPath)) {
    Write-Error "BDS Path not found: $BDSPath"
    exit
}

Write-Host "Starting extraction for Delphi Win64 compiler from $BDSPath..."

# Create output directory structure
$BinOutput = Join-Path $OutputPath "bin"
$LibOutput = Join-Path $OutputPath "lib\win64"
$IncludeOutput = Join-Path $OutputPath "include\windows\rtl"

New-Item -ItemType Directory -Force -Path $BinOutput
New-Item -ItemType Directory -Force -Path $LibOutput
New-Item -ItemType Directory -Force -Path $IncludeOutput

# 1. Copy essential binaries
Write-Host "Copying binaries..."
# dcc64 is the Win64 compiler
Copy-Item (Join-Path $BDSPath "bin\dcc64.exe") $BinOutput
Copy-Item (Join-Path $BDSPath "bin\rsvars.bat") $BinOutput
# Copy all DLLs as many are required by the compiler and tools
Copy-Item (Join-Path $BDSPath "bin\*.dll") $BinOutput

# 2. Copy Win64 Libraries
Write-Host "Copying Win64 libraries..."
Copy-Item -Recurse (Join-Path $BDSPath "lib\win64\release") $LibOutput
Copy-Item -Recurse (Join-Path $BDSPath "lib\win64\debug") $LibOutput

# 3. Copy RTL Includes
Write-Host "Copying RTL includes..."
Copy-Item -Recurse (Join-Path $BDSPath "include\windows\rtl\*") $IncludeOutput

# 4. Export Registry Key
Write-Host "Exporting registry settings..."
$RegFile = Join-Path $OutputPath "Embarcadero_Win64.reg"
reg export "HKEY_CURRENT_USER\Software\Embarcadero\BDS\$Version" $RegFile /y

# 5. Create a slimmed down rsvars.bat for the new location
Write-Host "Updating rsvars.bat..."
$RSVarsContent = @"
@SET BDS=$OutputPath
@SET BDSCOMMONDIR=%PUBLIC%\Documents\Embarcadero\Studio\$Version
@SET PATH=%BDS%\bin;%PATH%
"@
Set-Content (Join-Path $BinOutput "rsvars_win64.bat") $RSVarsContent

Write-Host "Extraction complete! Files are located in: $OutputPath"
Write-Host "To use, run: $BinOutput\rsvars_win64.bat"
