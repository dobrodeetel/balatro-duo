# Screenshots of the CO-OP menu and the "What is shared" submenu in each game language.
# Uses its own profile (local\bal-appdata\lang) so the language switch touches no other test.
#   lang_test.ps1 [-Langs de,fr,...]   -> local\bal-shots\lang\<code>-menu.png, <code>-shared.png
param([string[]]$Langs = @('en-us', 'ru', 'de', 'fr', 'es_ES', 'es_419', 'it', 'pt_BR', 'pl', 'nl', 'id', 'ja', 'ko', 'zh_CN', 'zh_TW'))
$root = "C:\coop-anything\local"
$exe = "$root\bal-test\Balatro.exe"
$appdata = "$root\bal-appdata\lang"
$mods = "$appdata\Balatro\Mods"
$shots = "$root\bal-shots\lang"
$log = "$appdata\Balatro\duo_log.txt"
New-Item -ItemType Directory -Force $shots, "$appdata\Balatro\1" | Out-Null
foreach ($f in "settings.jkr", "1\profile.jkr", "1\meta.jkr") {
  if (-not (Test-Path "$appdata\Balatro\$f")) { Copy-Item "$root\bal-save-backup\$f" "$appdata\Balatro\$f" }
}
New-Item -ItemType Directory -Force $mods | Out-Null
if (Test-Path "$mods\BalatroDuo") { Remove-Item "$mods\BalatroDuo" -Recurse -Force }
Copy-Item "$root\balatro-duo\BalatroDuo" "$mods\BalatroDuo" -Recurse
function Wait-Log($pattern, $sec) {
  $deadline = (Get-Date).AddSeconds($sec)
  while ((Get-Date) -lt $deadline) {
    Start-Sleep -Milliseconds 400
    if ((Test-Path $log) -and (Select-String -Path $log -Pattern $pattern -Quiet)) { return $true }
  }
  return $false
}
foreach ($code in $Langs) {
  Get-Process Balatro -ErrorAction SilentlyContinue | Stop-Process -Force
  Start-Sleep 1
  $env:APPDATA = $appdata
  Start-Process $exe -WorkingDirectory "$root\bal-test" -ArgumentList "--mod-dir", $mods, "--duo-host", "--duo-test-lang", $code
  Start-Sleep 3
  if (-not (Wait-Log "LANGTEST menu" 90)) { "$code : no menu"; continue }
  Start-Sleep -Milliseconds 1500
  & "$root\balatro-duo\tools\screenshot.ps1" -Out "$shots\$code-menu.png"
  if (-not (Wait-Log "LANGTEST shared" 15)) { "$code : no submenu"; continue }
  Start-Sleep -Milliseconds 1500
  & "$root\balatro-duo\tools\screenshot.ps1" -Out "$shots\$code-shared.png"
  $err = Select-String -Path $log -Pattern 'ERR' | ForEach-Object { $_.Line }
  "$code : ok $(if ($err) { 'ERRORS: ' + ($err -join ' | ') })"
}
Get-Process Balatro -ErrorAction SilentlyContinue | Stop-Process -Force
