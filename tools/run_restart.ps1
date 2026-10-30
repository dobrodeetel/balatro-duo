# Restart scenario: two bots play, then one window (or both) is killed mid-run and
# started again. The restarted side must continue the same co-op run and both must
# play on to the quit ante with the same blinds and totals.
#   -Kill host|guest|both   which window dies
#   -KillAfter N            seconds after start (vary it to hit shop, blind screen, round)
#   -SelfRelaunch           the host opens the guest window itself ("Play together"); after
#                           the guest is killed nobody restarts it: the host must reopen it
param([string]$Kill = "host", [int]$KillAfter = 60, [int]$TimeoutSec = 900, [double]$Diff = 0.3, [int]$QuitAnte = 2,
  [switch]$SelfRelaunch)
$root = "C:\coop-anything\local"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
& "$here\run_bots.ps1" -Diff $Diff -QuitAnte $QuitAnte -TwoWindows:$SelfRelaunch
Start-Sleep $KillAfter
foreach ($p in Get-CimInstance Win32_Process -Filter "Name='Balatro.exe'") {
  if ($Kill -eq "both" -or $p.CommandLine -like "*--duo-$Kill *") {
    Write-Host "killing $Kill pid $($p.ProcessId) at $KillAfter s"
    Stop-Process -Id $p.ProcessId -Force
  }
}
Start-Sleep 3
if ($SelfRelaunch) { Write-Host "not restarting the guest: the host has to" }
elseif ($Kill -eq "both") { & "$here\run_bots.ps1" -Diff $Diff -QuitAnte $QuitAnte -Only both -Continue }
else { & "$here\run_bots.ps1" -Diff $Diff -QuitAnte $QuitAnte -Only $Kill }
$t0 = Get-Date
Start-Sleep 10
while (Get-Process Balatro -ErrorAction SilentlyContinue) {
  if (((Get-Date) - $t0).TotalSeconds -gt $TimeoutSec) {
    Write-Host "TIMEOUT after $TimeoutSec s, killing clients"
    Get-Process Balatro -ErrorAction SilentlyContinue | Stop-Process -Force
    break
  }
  Start-Sleep 3
}
Write-Host ("after restart {0:n0} s" -f ((Get-Date) - $t0).TotalSeconds)
# a guest opened by the host inherits the host's APPDATA (p1)
$guestLog = "$root\bal-appdata\p2\BalatroDuoP2\duo_log.txt"
if ($SelfRelaunch) { $guestLog = "$root\bal-appdata\p1\BalatroDuoP2\duo_log.txt" }
& "$here\check_logs.ps1" "$root\bal-appdata\p1\Balatro\duo_log.txt" $guestLog -Restart $Kill
exit $LASTEXITCODE
