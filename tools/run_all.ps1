# Every bot scenario in a row; prints one PASS/FAIL line per scenario and the details of failures.
#   -Skip N : start at scenario N+1 (after an interrupted run)
# Each scenario has a 400 s timeout: a stuck run is a failure, not a wait.
param([int]$Skip = 0)
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$scenarios = @(
  @{ name = 'shop lag + planets'; cmd = { & "$here\run_suite.ps1" -ShopLag 6 -Planets -TimeoutSec 400 } },
  @{ name = 'host shop lag + secret + planets'; cmd = { & "$here\run_suite.ps1" -HostShopLag 6 -Secret -Planets -TimeoutSec 400 } },
  @{ name = 'tag stack (Double + Charm)'; cmd = { & "$here\run_suite.ps1" -TestTags -TimeoutSec 400 } },
  @{ name = 'guest wishes + slow guest'; cmd = { & "$here\run_suite.ps1" -Wish -Slow 4 -TimeoutSec 400 } },
  @{ name = 'own decks'; cmd = { & "$here\run_suite.ps1" -DeckMode own -TimeoutSec 400 } },
  @{ name = 'restart host at 110 s'; cmd = { & "$here\run_restart.ps1" -Kill host -KillAfter 110 -TimeoutSec 400 } },
  @{ name = 'restart guest at 45 s'; cmd = { & "$here\run_restart.ps1" -Kill guest -KillAfter 45 -TimeoutSec 400 } },
  @{ name = 'restart both at 130 s'; cmd = { & "$here\run_restart.ps1" -Kill both -KillAfter 130 -TimeoutSec 400 } },
  @{ name = 'guest dies, host reopens it'; cmd = { & "$here\run_restart.ps1" -Kill guest -KillAfter 80 -SelfRelaunch -TimeoutSec 400 } },
  @{ name = 'tag stack, slow packs (guest double pack)'; cmd = { & "$here\run_suite.ps1" -TestTags -PackLag 6 -GuestLag 1 -TimeoutSec 400 } },
  @{ name = 'boss rerolls on both sides'; cmd = { & "$here\run_suite.ps1" -Reroll -TimeoutSec 400 } },
  @{ name = 'host paused 30 s during its own count'; cmd = { & "$here\run_suite.ps1" -Pause 30 -TimeoutSec 500 } },
  @{ name = 'ante vouchers on both sides'; cmd = { & "$here\run_suite.ps1" -Ante -TimeoutSec 700 } }
)
$results = @()
$i = 0
foreach ($s in $scenarios) {
  $i++
  if ($i -le $Skip) { continue }
  $out = & $s.cmd 2>&1 | Out-String
  $ok = $LASTEXITCODE -eq 0
  $summary = ($out -split "`n" | Where-Object { $_ -match 'checks=' }) -join ' '
  $results += ("{0} {1}. {2}: {3}" -f ($(if ($ok) { 'PASS' } else { 'FAIL' })), $i, $s.name, $summary.Trim())
  Write-Host $results[-1]
  if (-not $ok) { Write-Host $out }
}
"==== summary"
$results
