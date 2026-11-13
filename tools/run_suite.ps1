# One bot run end to end: start both bot clients, wait until both quit, check the logs.
# e.g.: run_suite.ps1 -ShopLag 6 -Planets ; run_suite.ps1 -TestTags ; run_suite.ps1 -Wish -Slow 4
param([int]$TimeoutSec = 900, [string]$DeckMode = "shared", [int]$ShopLag = 0, [switch]$Planets,
  [int]$HostShopLag = 0, [switch]$Secret, [string]$Tags = "both",
  [string]$Levels = "planets", [double]$Diff = 0.3, [int]$QuitAnte = 2,
  [switch]$TestTags, [switch]$OldNbc, [switch]$Wish, [int]$Slow = 0, [int]$GuestLag = 0, [int]$PackLag = 0, [switch]$Reroll, [int]$Pause = 0, [switch]$Ante, [switch]$OldEase)
$root = "C:\coop-anything\local"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
& "$here\run_bots.ps1" -DeckMode $DeckMode -ShopLag $ShopLag -Planets:$Planets -Levels $Levels -Diff $Diff -QuitAnte $QuitAnte `
  -HostShopLag $HostShopLag -Secret:$Secret -Tags $Tags -TestTags:$TestTags -OldNbc:$OldNbc -Wish:$Wish -Slow $Slow -GuestLag $GuestLag -PackLag $PackLag -Reroll:$Reroll -Pause $Pause -Ante:$Ante -OldEase:$OldEase
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
Write-Host ("duration {0:n0} s" -f ((Get-Date) - $t0).TotalSeconds)
& "$here\check_logs.ps1" "$root\bal-appdata\p1\Balatro\duo_log.txt" "$root\bal-appdata\p2\BalatroDuoP2\duo_log.txt" `
  -Mode $DeckMode -ShopLag:($ShopLag -gt 0) -Planets:$Planets -Levels $Levels -HostShopLag:($HostShopLag -gt 0) -Secret:$Secret -Tags $Tags `
  -TestTags:$TestTags -Wish:$Wish -Slow:($Slow -gt 0) -Reroll:$Reroll -Pause:($Pause -gt 0) -Ante:$Ante
exit $LASTEXITCODE
