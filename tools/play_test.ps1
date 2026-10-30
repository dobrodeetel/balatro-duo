# Play Balatro Duo by hand in the TEST copy of the game.
# Uses a copy of the owner's profile (unlocks, language, window mode); the real
# profile and the real game folder are not touched.
# In the game: main menu -> CO-OP -> "Play together (2 windows)".
$root = "C:\coop-anything\local"
$exe = "$root\bal-test\Balatro.exe"
$appdata = "$root\bal-appdata\play"
$mods = "$appdata\Balatro\Mods"
Get-Process Balatro -ErrorAction SilentlyContinue | Stop-Process -Force
New-Item -ItemType Directory -Force "$appdata\Balatro\1" | Out-Null
foreach ($f in "settings.jkr", "1\profile.jkr", "1\meta.jkr") {
  if (-not (Test-Path "$appdata\Balatro\$f")) { Copy-Item "$root\bal-save-backup\$f" "$appdata\Balatro\$f" }
}
New-Item -ItemType Directory -Force $mods | Out-Null
if (Test-Path "$mods\BalatroDuo") { Remove-Item "$mods\BalatroDuo" -Recurse -Force }
Copy-Item "$root\balatro-duo\BalatroDuo" "$mods\BalatroDuo" -Recurse
$env:APPDATA = $appdata
Start-Process $exe -WorkingDirectory "$root\bal-test" -ArgumentList "--mod-dir", $mods
