# Fully Portable Slim Delphi Win32/Win64 Compiler Extraction Script (v37.0)
# Usage: .\extract_delphi_win64_slim.ps1 -BDSPath "C:\Program Files (x86)\Embarcadero\Studio\37.0" -OutputPath "C:\Delphi37_Slim"

param (
    [string]$BDSPath = "C:\Program Files (x86)\Embarcadero\Studio\37.0",
    [string]$OutputPath = "C:\Delphi37_Slim"
)

$Version = "37.0" 
$DLLVersion = "370" 

# --- 0. Pre-checks ---
if (-not (Test-Path $BDSPath)) {
    Write-Error "BDS Path not found: $BDSPath"
    exit
}

$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $IsAdmin) {
    Write-Warning "Script is not running as Administrator. Registry export may fail."
}

Write-Host "Starting FULLY PORTABLE SLIM extraction (v$Version) from $BDSPath..."

# --- 1. Create minimal directory structure ---
$BinOutput = Join-Path $OutputPath "bin"
$Lib32Output = Join-Path $OutputPath "lib\win32"
$Lib64Output = Join-Path $OutputPath "lib\win64"

New-Item -ItemType Directory -Force -Path $BinOutput
New-Item -ItemType Directory -Force -Path $Lib32Output
New-Item -ItemType Directory -Force -Path $Lib64Output

# --- 2. Copy BARE MINIMUM binaries (Win32 & Win64) ---
Write-Host "Copying essential binaries and tools..."
$EssentialBins = @(
    "dcc32.exe",
    "dcc32$DLLVersion.dll",
    "dcc32.cfg",
    "dcc64.exe",
    "dcc64$DLLVersion.dll",
    "dcc64${DLLVersion}N.dll",
    "dcc64.cfg",
    "brcc32.exe",     # Resource Compiler
    "borlndmm.dll",
    "rlink32.dll",
    "rsvars.bat"
)

foreach ($file in $EssentialBins) {
    $src = Join-Path $BDSPath "bin\$file"
    if (Test-Path $src) {
        Copy-Item $src $BinOutput
    } else {
        Write-Warning "Essential file not found: $src"
    }
}

# --- 3. Update compiler config files with RELATIVE search paths ---
Write-Host "Configuring relative search paths for portability..."
# Update dcc32.cfg (relative to bin folder)
$CFG32Path = Join-Path $BinOutput "dcc32.cfg"
if (Test-Path $CFG32Path) {
    $NewCFG32Content = @(
        "-aWinTypes=Windows;WinProcs=Windows;DbiProcs=BDE;DbiTypes=BDE;DbiErrs=BDE",
        "-u`"..\lib\win32`"" # Relative path to the lib output folder
    )
    Set-Content $CFG32Path $NewCFG32Content
}

# Update dcc64.cfg (relative to bin folder)
$CFG64Path = Join-Path $BinOutput "dcc64.cfg"
if (Test-Path $CFG64Path) {
    $NewCFG64Content = @(
        "-aWinTypes=Windows;WinProcs=Windows;DbiProcs=BDE;DbiTypes=BDE;DbiErrs=BDE",
        "-u`"..\lib\win64`"" # Relative path to the lib output folder
    )
    Set-Content $CFG64Path $NewCFG64Content
}

# --- 4. Copy Release DCUs, DCPs and resources ---
Write-Host "Copying release DCUs, DCPs and resources..."

# Win32
$Release32Src = Join-Path $BDSPath "lib\win32\release"
if (Test-Path $Release32Src) {
    Copy-Item -Path "$Release32Src\*.dcu" -Destination $Lib32Output
    Copy-Item -Path "$Release32Src\*.dcp" -Destination $Lib32Output # Added .dcp for package support
    Copy-Item -Path "$Release32Src\*.res" -Destination $Lib32Output
    Copy-Item -Path "$Release32Src\*.dfm" -Destination $Lib32Output
    Copy-Item -Path "$Release32Src\*.o" -Destination $Lib32Output
}

# Win64
$Release64Src = Join-Path $BDSPath "lib\win64\release"
if (Test-Path $Release64Src) {
    Copy-Item -Path "$Release64Src\*.dcu" -Destination $Lib64Output
    Copy-Item -Path "$Release64Src\*.dcp" -Destination $Lib64Output # Added .dcp for package support
    Copy-Item -Path "$Release64Src\*.res" -Destination $Lib64Output
    Copy-Item -Path "$Release64Src\*.dfm" -Destination $Lib64Output
    Copy-Item -Path "$Release64Src\*.o" -Destination $Lib64Output
}

# --- 5. Export Registry Key ---
Write-Host "Exporting registry settings..."
$RegFile = Join-Path $OutputPath "Embarcadero_v$Version.reg"
reg export "HKEY_CURRENT_USER\Software\Embarcadero\BDS\$Version" $RegFile /y

# --- 6. Create a portable rsvars_slim.bat ---
Write-Host "Creating portable rsvars_slim.bat..."
$RSVarsContent = @"
@ECHO OFF
@SET BDS=%~dp0..
@SET BDSCOMMONDIR=%PUBLIC%\Documents\Embarcadero\Studio\$Version
@SET PATH=%BDS%\bin;%PATH%
@ECHO -----------------------------------------------------------------
@ECHO Delphi $Version Portable Slim Compilers
@ECHO Root: %BDS%
@ECHO Ready: dcc32, dcc64, brcc32
@ECHO -----------------------------------------------------------------
"@
Set-Content (Join-Path $BinOutput "rsvars_slim.bat") $RSVarsContent

# --- 7. Create verification scripts ---
Write-Host "Creating verification script..."
$TestCode = @"
program TestExtract;
{\$APPTYPE CONSOLE}
begin
  WriteLn('Delphi extraction verified successfully!');
end.
"@
$TestFile = Join-Path $OutputPath "Verify_Extraction.dpr"
Set-Content $TestFile $TestCode

Write-Host "`nExtraction complete! This folder is now fully portable."
Write-Host "Total Size: $((Get-ChildItem $OutputPath -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB) MB"
Write-Host "To use:"
Write-Host "1. Move the folder '$OutputPath' anywhere."
Write-Host "2. Run: bin\rsvars_slim.bat"
Write-Host "3. Run 'dcc32' or 'dcc64' to compile."
