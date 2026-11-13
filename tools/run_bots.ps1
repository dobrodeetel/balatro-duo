# Deploy BalatroDuo into two isolated test profiles and start two bot clients.
# Saves go to local\bal-appdata\p1|p2 (APPDATA redirected), never to the real profile.
#   -ShopLag N : the guest stays N s longer in each shop; the host clicks the real select button early
#   -Planets   : host uses Pluto then Black Hole, guest uses Neptune (hand level sharing)
#   -Levels    : off | planets | all
#   -HostShopLag N : the host stays N s longer in each shop (guest reaches the blind screen first)
#   -Secret    : the guest "finds" Five of a Kind, the host checks Planet X is in its pool
#   -Tags      : both | own
#   -TestTags  : both start with a Double Tag, Small blind of ante 1 gives a Charm Tag, bots skip it
#   -OldNbc    : 0.5.0 behaviour for a received pack tag (fires at once), to reproduce the crash
#   -Wish      : the guest presses the real select button on each blind; the host waits for it
#   -Slow N    : the guest waits N s before each hand (the host runs out of hands first)
#   -Only host|guest : (re)start only that window, keep the other and the deployed mod
#   -Continue  : the host bot continues its saved run instead of starting a new one
#   -PackLag N : bots stay N s in each booster pack (like a person picking cards)
#   -Pause N   : the host pauses the game N s while its own hand counts (round 2 on)
#   -OldEase   : 0.6.2 score count handling (20 s cap, overwritten points), to reproduce the bug
#   -Profile   : sample the game with the LuaJIT profiler every 5 minutes (PROF lines in the log)
#   -Jokers N  : bots fill up to N joker slots with random jokers in each shop
#   -Pad N     : in each shop, move a joker N times with the gamepad (A held + D-pad)
#   -Ante      : host uses Hieroglyph at ante 2, then the guest uses Petroglyph at ante 2
#   -TwoWindows: start only the host, with "Play together" (the host opens the guest window itself)
param([double]$Diff = 1, [int]$QuitAnte = 3, [int]$Speed = 4, [switch]$NoBot,
  [string]$DeckMode = "shared", [string]$HostDeck = "b_blue", [string]$GuestDeck = "b_yellow", [int]$Stake = 2,
  [int]$GuestLag = 0, [int]$ShopLag = 0, [switch]$Planets, [string]$Levels = "planets",
  [int]$HostShopLag = 0, [switch]$Secret, [string]$Tags = "both",
  [switch]$TestTags, [switch]$OldNbc, [switch]$Wish, [int]$Slow = 0, [string]$Only = "", [switch]$Continue, [switch]$TwoWindows,
  [int]$PackLag = 0, [switch]$Reroll, [int]$Pause = 0, [switch]$Ante, [switch]$OldEase, [switch]$Profile, [int]$Jokers = 0, [int]$Pad = 0)
$root = "C:\coop-anything\local"
$exe = "$root\bal-test\Balatro.exe"
$mod = "$root\balatro-duo\BalatroDuo"
if (-not $Only) {
  Get-Process Balatro -ErrorAction SilentlyContinue | Stop-Process -Force
  Start-Sleep 1
  foreach ($p in "p1", "p2") {
    $mods = "$root\bal-appdata\$p\Balatro\Mods"
    New-Item -ItemType Directory -Force $mods | Out-Null
    if (Test-Path "$mods\probe") { Remove-Item "$mods\probe" -Recurse -Force }
    if (Test-Path "$mods\BalatroDuo") { Remove-Item "$mods\BalatroDuo" -Recurse -Force }
    Copy-Item $mod "$mods\BalatroDuo" -Recurse
  }
}
$bot = @(); if (-not $NoBot) { $bot = @("--duo-bot") }
$common = @("--disable-console", "--duo-diff", "$Diff", "--duo-quit-ante", "$QuitAnte", "--duo-speed", "$Speed",
  "--duo-deck", $DeckMode, "--duo-bot-stake", "$Stake", "--duo-levels", $Levels, "--duo-tags", $Tags) + $bot
if ($ShopLag -gt 0) { $common += @("--duo-test-shop-lag", "$ShopLag") }
if ($Planets) { $common += @("--duo-test-planets") }
if ($HostShopLag -gt 0) { $common += @("--duo-test-host-shop-lag", "$HostShopLag") }
if ($Secret) { $common += @("--duo-test-secret") }
if ($TestTags) { $common += @("--duo-test-tags") }
if ($OldNbc) { $common += @("--duo-test-old-nbc") }
if ($Wish) { $common += @("--duo-test-wish") }
if ($Slow -gt 0) { $common += @("--duo-test-slow", "$Slow") }
if ($PackLag -gt 0) { $common += @("--duo-test-pack-lag", "$PackLag") }
if ($Reroll) { $common += @("--duo-test-reroll") }
if ($Pause -gt 0) { $common += @("--duo-test-pause", "$Pause") }
if ($Ante) { $common += @("--duo-test-ante") }
if ($OldEase) { $common += @("--duo-test-old-ease") }
if ($Profile) { $common += @("--duo-profile") }
if ($Jokers -gt 0) { $common += @("--duo-test-jokers", "$Jokers") }
if ($Pad -gt 0) { $common += @("--duo-test-pad", "$Pad") }
if ($Only -ne "guest") {
  $hostMode = "--duo-host"; if ($TwoWindows) { $hostMode = "--duo-two-windows" }
  $hostArgs = @("--mod-dir", "$root\bal-appdata\p1\Balatro\Mods", $hostMode, "--duo-window", "left", "--duo-seed", "HOSTSEED", "--duo-bot-deck", $HostDeck) + $common
  if ($Continue) { $hostArgs += @("--duo-test-continue") }
  $env:APPDATA = "$root\bal-appdata\p1"
  Start-Process $exe -WorkingDirectory "$root\bal-test" -ArgumentList $hostArgs
  if ($Only -ne "host" -and -not $TwoWindows) { Start-Sleep 3 }
}
if ($Only -ne "host" -and -not $TwoWindows) {
  $env:APPDATA = "$root\bal-appdata\p2"
  Start-Process $exe -WorkingDirectory "$root\bal-test" -ArgumentList (@("--mod-dir", "$root\bal-appdata\p2\Balatro\Mods", "--duo-guest", "--duo-window", "right", "--duo-seed", "GUESTSEED", "--duo-bot-deck", $GuestDeck, "--duo-test-lag", "$GuestLag") + $common)
}
