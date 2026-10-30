# Window placement check in a separate test profile (local\bal-appdata\wt).
#   -Phase 1: fresh profile. Start "Play together" from the command line, then move the
#             guest window by hand-like SetWindowPos, let the mod record it, close both.
#   -Phase 2: start again; the log must show "place keep" (host, game's own mode) and
#             "place restore" (guest, the moved spot).
param([int]$Phase = 1, [string]$Shot = "")
$root = "C:\coop-anything\local"
$exe = "$root\bal-test\Balatro.exe"
$appdata = "$root\bal-appdata\wt"
$mods = "$appdata\Balatro\Mods"
Add-Type @"
using System; using System.Runtime.InteropServices;
public static class DuoWin {
  [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr a, int x, int y, int w, int hh, uint f);
}
"@
Get-Process Balatro -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep 1
if ($Phase -eq 1) {
  if (Test-Path $appdata) { Remove-Item $appdata -Recurse -Force }
  New-Item -ItemType Directory -Force "$appdata\Balatro\1" | Out-Null
  foreach ($f in "settings.jkr", "1\profile.jkr", "1\meta.jkr") { Copy-Item "$root\bal-save-backup\$f" "$appdata\Balatro\$f" }
}
New-Item -ItemType Directory -Force $mods | Out-Null
if (Test-Path "$mods\BalatroDuo") { Remove-Item "$mods\BalatroDuo" -Recurse -Force }
Copy-Item "$root\balatro-duo\BalatroDuo" "$mods\BalatroDuo" -Recurse
$env:APPDATA = $appdata
Start-Process $exe -WorkingDirectory "$root\bal-test" -ArgumentList "--mod-dir", $mods, "--duo-two-windows"
Start-Sleep 25
if ($Shot) { & "$root\balatro-duo\tools\screenshot.ps1" -Out $Shot }
$procs = @(Get-Process Balatro -ErrorAction SilentlyContinue | Sort-Object StartTime)
"windows: $($procs.Count)"
if ($Phase -eq 1 -and $procs.Count -ge 2) {
  [DuoWin]::SetWindowPos($procs[1].MainWindowHandle, [IntPtr]::Zero, 200, 150, 900, 600, 0x0004) | Out-Null
  Start-Sleep 5
}
"--- host log"; Get-Content "$appdata\Balatro\duo_log.txt" | Select-String "place|arrange|ERR|loaded"
"--- guest log"; Get-Content "$appdata\BalatroDuoP2\duo_log.txt" | Select-String "place|arrange|ERR|loaded"
"--- saved: host $(Get-Content "$appdata\Balatro\duo_window.txt" -ErrorAction SilentlyContinue) / guest $(Get-Content "$appdata\BalatroDuoP2\duo_window.txt" -ErrorAction SilentlyContinue)"
if ($Phase -eq 1) { Get-Process Balatro -ErrorAction SilentlyContinue | Stop-Process -Force }
