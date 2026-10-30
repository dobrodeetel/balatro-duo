# Balatro Duo installer / uninstaller.
#   install:   powershell -ExecutionPolicy Bypass -File install.ps1
#   uninstall: powershell -ExecutionPolicy Bypass -File install.ps1 -Uninstall
# Puts Lovely (version.dll) next to Balatro.exe and the mod into %APPDATA%\Balatro\Mods.
# Saves are not touched. The second window keeps its own profile in %APPDATA%\BalatroDuoP2.
# Messages are in Russian when the Windows display language, regional format or install language is Russian, in English otherwise.
# This file is saved as UTF-8 with BOM: Windows PowerShell 5.1 needs the BOM to read Cyrillic.
param([string]$GameDir = "", [string]$ModsDir = "$env:APPDATA\Balatro\Mods", [switch]$Uninstall, [switch]$DetectOnly)
$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$lovelyZip = Join-Path $here "lovely-0.9.0-x86_64-pc-windows-msvc.zip"
$lovelyZipSha = "40b994a055ee75e5f2aba81e7ae06f2c17460e18cc346483089921899fadd1f7"
$ru = @((Get-UICulture).Name, (Get-Culture).Name, [System.Globalization.CultureInfo]::InstalledUICulture.Name) -like 'ru*'
function T([string]$en, [string]$rus) { if ($ru) { return $rus } else { return $en } }

function Find-Balatro {
  $roots = @()
  $steam = (Get-ItemProperty "HKCU:\Software\Valve\Steam" -ErrorAction SilentlyContinue).SteamPath
  if ($steam) { $roots += $steam }
  $roots += "C:\Program Files (x86)\Steam"
  foreach ($r in $roots) {
    $vdf = Join-Path $r "steamapps\libraryfolders.vdf"
    $libs = @($r)
    if (Test-Path $vdf) {
      foreach ($m in [regex]::Matches((Get-Content $vdf -Raw), '"path"\s+"([^"]+)"')) { $libs += $m.Groups[1].Value -replace '\\\\', '\' }
    }
    foreach ($l in $libs) {
      $d = Join-Path $l "steamapps\common\Balatro"
      if (Test-Path (Join-Path $d "Balatro.exe")) { return $d }
    }
  }
  return $null
}

if (-not $GameDir) { $GameDir = Find-Balatro }
if (-not $GameDir -or -not (Test-Path (Join-Path $GameDir "Balatro.exe"))) {
  Write-Host (T "Balatro.exe not found. Run again with -GameDir ""<folder with Balatro.exe>""" "Balatro.exe не найден. Запусти ещё раз с -GameDir ""<папка с Balatro.exe>""") -ForegroundColor Red
  exit 1
}
Write-Host ((T "Game folder: " "Папка игры: ") + $GameDir)
Write-Host ((T "Mods folder: " "Папка модов: ") + $ModsDir)
if ($DetectOnly) { exit 0 }
$dll = Join-Path $GameDir "version.dll"
$mod = Join-Path $ModsDir "BalatroDuo"

# version.dll of Lovely 0.9.0, taken from the pinned zip
Add-Type -AssemblyName System.IO.Compression.FileSystem
function Get-LovelyDllHash {
  $z = [System.IO.Compression.ZipFile]::OpenRead($lovelyZip)
  try {
    $s = $z.GetEntry("version.dll").Open()
    try { return ([System.BitConverter]::ToString([System.Security.Cryptography.SHA256]::Create().ComputeHash($s)) -replace '-', '').ToLower() }
    finally { $s.Dispose() }
  } finally { $z.Dispose() }
}

if ((Get-FileHash $lovelyZip -Algorithm SHA256).Hash.ToLower() -ne $lovelyZipSha) {
  Write-Host (T "Lovely zip hash mismatch, stopping." "Архив Lovely не совпадает по SHA-256, остановка.") -ForegroundColor Red; exit 1
}
$ourDll = Get-LovelyDllHash

if ($Uninstall) {
  if (Test-Path $mod) { Remove-Item $mod -Recurse -Force; Write-Host ((T "Removed " "Удалено: ") + $mod) }
  if ((Test-Path $dll) -and ((Get-FileHash $dll -Algorithm SHA256).Hash.ToLower() -eq $ourDll)) {
    Remove-Item $dll -Force; Write-Host ((T "Removed " "Удалено: ") + $dll)
  } elseif (Test-Path $dll) {
    Write-Host (T "version.dll is not the one this installer put there, left as is." "version.dll положил не этот установщик, оставлен как есть.") -ForegroundColor Yellow
  }
  Write-Host (T "Done. Balatro is back to normal." "Готово. Balatro снова обычная.") -ForegroundColor Green
  exit 0
}

if (Get-Process Balatro -ErrorAction SilentlyContinue) {
  Write-Host (T "Close Balatro first." "Сначала закрой Balatro.") -ForegroundColor Red; exit 1
}
if ((Test-Path $dll) -and ((Get-FileHash $dll -Algorithm SHA256).Hash.ToLower() -ne $ourDll)) {
  $bak = "$dll.bak-" + (Get-Date -Format "yyyyMMdd-HHmmss")
  Copy-Item $dll $bak
  Write-Host ((T "Existing version.dll backed up to " "Старый version.dll сохранён как ") + $bak) -ForegroundColor Yellow
}
$z = [System.IO.Compression.ZipFile]::OpenRead($lovelyZip)
try { [System.IO.Compression.ZipFileExtensions]::ExtractToFile($z.GetEntry("version.dll"), $dll, $true) } finally { $z.Dispose() }
Write-Host ((T "Lovely installed: " "Lovely установлен: ") + $dll)

New-Item -ItemType Directory -Force $ModsDir | Out-Null
if (Test-Path $mod) { Remove-Item $mod -Recurse -Force }
Copy-Item (Join-Path $here "BalatroDuo") $mod -Recurse
Write-Host ((T "Mod installed: " "Мод установлен: ") + $mod)
Write-Host (T "Done. Start Balatro from Steam, then main menu -> CO-OP." "Готово. Запускай Balatro из Steam, дальше главное меню -> КООП.") -ForegroundColor Green
