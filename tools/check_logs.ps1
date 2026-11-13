# Compare the host and guest flight-recorder logs of one Balatro Duo bot run.
# PowerShell port of check_logs.py (no Python needed), plus the checks added since.
# Usage: check_logs.ps1 <host duo_log.txt> <guest duo_log.txt> [-Mode shared|own] [-ShopLag] [-Planets] ...
#   -Restart host|guest|both : the run had that window killed and restarted (run_restart.ps1);
#     its duo_log.txt only covers the time after the restart, duo_log_prev.txt the time before.
# Exit code 0 when every check passes.
param([string]$HostLog, [string]$GuestLog, [string]$Mode = "", [switch]$ShopLag, [switch]$Planets, [string]$Levels = "planets",
  [switch]$HostShopLag, [switch]$Secret, [string]$Tags = "both",
  [string]$Restart = "", [switch]$TestTags, [switch]$Wish, [switch]$Slow, [switch]$Reroll, [switch]$Pause, [switch]$Ante)

function KV($msg) {
  $kv = @{}
  foreach ($m in [regex]::Matches($msg, '(\w+)=(\S+)')) { $kv[$m.Groups[1].Value] = $m.Groups[2].Value }
  return $kv
}

function Parse($path) {
  $r = @{ sel = @(); skip = @(); rounds = [ordered]@{}; errors = @(); ends = @(); starts = @();
    lvl_own = @(); lvl_peer = @(); blocked = 0; early = 0; clicks = @();
    flush_bad = @(); flushes = 0; tag_own = @(); tag_peer = @(); first_tag_own = -1; first_tag_peer = -1;
    waits = @(); wait_on = $null; hv_peer = @(); pool = @(); resumes = @(); adopts = @(); packs = 0;
    wish_click = 0; wish_recv = 0; wish_seen = 0; waiting = @(); nbc = 0; pulses = @();
    reroll_own = @(); boss_peer = @(); selboss = @(); dollars_before = @();
    pauses = @(); gmenu = @(); ante_own = @(); ante_peer = @(); ante_ignored = @(); shifts = 0 }
  if (-not (Test-Path $path)) { return $r }
  $i = 0
  foreach ($line in [System.IO.File]::ReadAllLines($path)) {
    $i++
    $parts = $line.Split(' ', 3)
    if ($parts.Count -lt 3) { continue }
    $msg = $parts[2]
    $kv = KV $msg
    $t = [double]$parts[0]
    if ($msg.StartsWith('FLUSH ')) {
      # own score goes out only after it has counted into the total
      $r.flushes++
      if ([double]$kv.chips + 1 -lt [double]$kv.mine + [double]$kv.theirs) { $r.flush_bad += $msg }
    }
    elseif ($msg.StartsWith('TAG own')) { if ($kv.k -ne 'tag_boss') { $r.tag_own += $kv.k }; if ($r.first_tag_own -lt 0) { $r.first_tag_own = $i } }
    elseif ($msg.StartsWith('TAG peer')) { $r.tag_peer += $kv.k; if ($r.first_tag_peer -lt 0) { $r.first_tag_peer = $i } }
    elseif ($msg.StartsWith('BLINDWAIT on')) { $r.wait_on = $t }
    elseif ($msg.StartsWith('BLINDWAIT off') -and $null -ne $r.wait_on) { $r.waits += ($t - $r.wait_on); $r.wait_on = $null }
    elseif ($msg.StartsWith('HV peer')) { $r.hv_peer += $kv.h }
    elseif ($msg.StartsWith('BOT pool')) { $r.pool += $kv.planet_x }
    elseif ($msg.StartsWith('RESUME')) {
      $r.resumes += $msg
      if ($kv.round) { $r.resume_round = $kv.round; $r.after_resume = $true }
    }
    elseif ($r.after_resume -and $msg.StartsWith('recv t=ph')) {
      # the partner's first phase after we continued: was it in the same round with us?
      $r.after_resume = $false
      $r.resume_shared = ($kv.p -eq 'round' -and $kv.r -eq $r.resume_round)
    }
    elseif ($msg.StartsWith('ADOPT')) { $r.adopts += $msg }
    elseif ($msg.StartsWith('BOT pack skip')) { $r.packs++ }
    elseif ($msg.StartsWith('BOT wish click')) { $r.wish_click++ }
    elseif ($msg.StartsWith('REROLL own')) { $r.reroll_own += $msg }
    elseif ($msg.StartsWith('BOSS peer')) { $r.boss_peer += $msg }
    elseif ($msg.StartsWith('SELBOSS')) { $r.selboss += "$($kv.own)|$($kv.host)" }
    elseif ($msg.StartsWith('BOT reroll guest')) { $r.dollars_before += $kv.dollars }
    elseif ($msg.StartsWith('WISH pulse')) { $r.pulses += "$($kv.a):$($kv.found)" }
    elseif ($msg.StartsWith('WISH ')) { $r.wish_recv++ }
    elseif ($msg.StartsWith('BOT sees wish')) { $r.wish_seen++ }
    elseif ($msg.StartsWith('BOT waiting')) { $r.waiting += $kv.locked }
    elseif ($msg.StartsWith('NBC fired')) { $r.nbc++ }
    elseif ($msg.StartsWith('GUESTMENU') -or $msg.StartsWith('BLOCKED start_')) { $r.gmenu += $msg }
    elseif ($msg.StartsWith('TESTPAUSE on')) { $r.pauses += $kv.r }
    elseif ($msg.StartsWith('EASE shift')) { $r.shifts++ }
    elseif ($msg.StartsWith('ANTE own')) { $r.ante_own += $msg }
    elseif ($msg -match '^ANTE peer .* ignored') { $r.ante_ignored += $msg }
    elseif ($msg.StartsWith('ANTE peer')) { $r.ante_peer += $msg }
    if ($msg.StartsWith('SEL ')) { $r.sel += "$($kv.r)|$($kv.d)|$($kv.k)|$([double]$kv.g)" }
    elseif ($msg.StartsWith('SKIP ')) { $r.skip += "$($kv.r)|$($kv.d)" }
    elseif ($msg.StartsWith('RE ')) { $r.rounds[$kv.r] = $kv }
    elseif ($msg.StartsWith('START ')) { $r.starts += "$($kv.deck)|$($kv.stake)" }
    elseif ($msg.StartsWith('ERR')) { $r.errors += $msg }
    elseif ($msg.StartsWith('BOT gameover') -or $msg.StartsWith('BOT quit')) { $r.ends += $msg }
    elseif ($msg.StartsWith('LVL own') -and $kv.shared -eq 'true') { $r.lvl_own += "$($kv.hand)|$($kv.n)" }
    elseif ($msg.StartsWith('LVL peer')) { $r.lvl_peer += "$($kv.hand)|$($kv.n)" }
    elseif ($msg.StartsWith('BLOCKED sel')) { $r.blocked++ }
    elseif ($msg.StartsWith('BOT early click')) { $r.early++ }
    elseif ($msg.StartsWith('BOT click select')) { $r.clicks += $kv.disabled }
  }
  return $r
}

$h = Parse $HostLog; $g = Parse $GuestLog
$script:checks = 0; $script:fails = @()
function Check($ok, $what) { $script:checks++; if (-not $ok) { $script:fails += $what } }
function Same($a, $b) { return (($a -join ',') -eq ($b -join ',')) }
function Bag($a) { return (@($a | Sort-Object) -join ',') }
# after a restart one log starts later: the shorter list must be the end of the longer one
function Tail($a, $b) {
  $a = @($a); $b = @($b)
  if ($a.Count -gt $b.Count) { $x = $a; $a = $b; $b = $x }
  if ($a.Count -eq 0) { return $true }
  return (($b[($b.Count - $a.Count)..($b.Count - 1)]) -join ',') -eq ($a -join ',')
}

if ($Restart) {
  $hp = Parse ($HostLog -replace 'duo_log\.txt$', 'duo_log_prev.txt')
  $gp = Parse ($GuestLog -replace 'duo_log\.txt$', 'duo_log_prev.txt')
  if ($Restart -eq 'host' -or $Restart -eq 'both') {
    Check ($h.resumes | Where-Object { $_ -match 'id=' -and $_ -notmatch 'none' }) "host did not continue the run: $($h.resumes -join ' / ')"
    Check ($hp.errors.Count -eq 0) "host errors before the restart: $($hp.errors)"
  }
  if ($Restart -eq 'guest' -or $Restart -eq 'both') {
    Check ($g.resumes | Where-Object { $_ -match 'id=' -and $_ -notmatch 'none' }) "guest did not continue the run: $($g.resumes -join ' / ')"
    Check ($gp.errors.Count -eq 0) "guest errors before the restart: $($gp.errors)"
  }
  Check (Tail $h.sel $g.sel) "blind selections differ after the restart: host $($h.sel -join ' ') guest $($g.sel -join ' ')"
  Check (Tail $h.skip $g.skip) "skips differ after the restart: host $($h.skip -join ' ') guest $($g.skip -join ' ')"
} else {
  Check ($h.starts.Count -eq 1 -and $g.starts.Count -eq 1) "expected one run start each: host $($h.starts) guest $($g.starts)"
  if ($Mode -eq 'shared' -and $h.starts -and $g.starts) { Check ($h.starts[0] -eq $g.starts[0]) "shared deck/stake differ: $($h.starts[0]) vs $($g.starts[0])" }
  if ($Mode -eq 'own' -and $h.starts -and $g.starts) { Check ($h.starts[0].Split('|')[0] -ne $g.starts[0].Split('|')[0]) "own decks expected to differ" }
  Check (Same $h.sel $g.sel) "blind selections differ: host $($h.sel -join ' ') guest $($g.sel -join ' ')"
  Check (Same $h.skip $g.skip) "skips differ: host $($h.skip -join ' ') guest $($g.skip -join ' ')"
}
Check ($h.errors.Count -eq 0 -and $g.errors.Count -eq 0) "errors: $($h.errors + $g.errors)"
$common = @($h.rounds.Keys | Where-Object { $g.rounds.Contains($_) } | Sort-Object { [int]$_ })
if (-not $Restart) {
  Check ($common.Count -eq $h.rounds.Count -and $common.Count -eq $g.rounds.Count) "rounds differ: host $($h.rounds.Keys) guest $($g.rounds.Keys)"
} else {
  Check ($common.Count -gt 0) "no round finished on both sides after the restart"
}
# A side that continued an older save replays the round it was in on its own when the
# partner had already finished it: those totals can't match and are only reported.
$replayed = @()
foreach ($x in @($h, $g)) { if ($x.resume_round -and -not $x.resume_shared) { $replayed += $x.resume_round } }
foreach ($r in $common) {
  $a = $h.rounds[$r]; $b = $g.rounds[$r]
  if ($replayed -contains $r) { "  r$($r) replayed alone after a continue: host $($a.chips) guest $($b.chips) (not compared)"; continue }
  Check ($a.target -eq $b.target) "r$r target $($a.target) vs $($b.target)"
  Check ($a.won -eq $b.won) "r$r outcome $($a.won) vs $($b.won)"
  # every hand of both players lands in both totals before either side closes the round
  Check ($a.chips -eq $b.chips) "r$r totals differ: host $($a.chips) vs guest $($b.chips)"
  foreach ($x in @(@('host', $a), @('guest', $b))) {
    $total = [double]$x[1].mine + [double]$x[1].theirs
    Check ([math]::Abs($total - [double]$x[1].chips) -lt 1) "r$r $($x[0]) chips $($x[1].chips) != mine+theirs $total"
  }
}
Check ($h.ends.Count -gt 0 -and $g.ends.Count -gt 0) "run did not finish: host $($h.ends) guest $($g.ends)"
if ($h.ends -and $g.ends) { Check ($h.ends[-1].Split(' ')[1] -eq $g.ends[-1].Split(' ')[1]) "end differs: $($h.ends[-1]) / $($g.ends[-1])" }

if ($ShopLag) {
  Check ($h.early -gt 0) "host never clicked select while the guest was in the shop"
  Check ($h.blocked -ge $h.early) "early clicks $($h.early) but only $($h.blocked) refused"
  Check (-not ($h.clicks -contains 'true')) "select button still disabled after a refused click: $($h.clicks -join ',')"
}
if ($Planets) {
  # every level up one side shared arrives once on the other side, nothing else arrives
  Check ((Bag $h.lvl_own) -eq (Bag $g.lvl_peer)) "host shared levels [$(Bag $h.lvl_own)] != guest received [$(Bag $g.lvl_peer)]"
  Check ((Bag $g.lvl_own) -eq (Bag $h.lvl_peer)) "guest shared levels [$(Bag $g.lvl_own)] != host received [$(Bag $h.lvl_peer)]"
  if ($Levels -eq 'off') { Check ($h.lvl_own.Count + $g.lvl_own.Count -eq 0) "levels=off but levels were shared" }
  else {
    Check ($h.lvl_own.Count -ge 13) "host expected Pluto + Black Hole (13 shared level ups), got $($h.lvl_own.Count)"
    Check ($g.lvl_own.Count -ge 1) "guest expected Neptune shared, got $($g.lvl_own.Count)"
  }
}

Check ($h.flush_bad.Count + $g.flush_bad.Count -eq 0) "score sent before it counted in: $($h.flush_bad + $g.flush_bad)"
Check ($h.flushes -gt 0 -and $g.flushes -gt 0) "no FLUSH lines (host $($h.flushes), guest $($g.flushes))"
if (-not $Restart) {
  if ($Tags -eq 'both') {
    Check ($h.tag_own.Count -gt 0) "no skip tag on the host (bots skip one Small blind)"
    Check ((Bag $h.tag_own) -eq (Bag $g.tag_peer)) "host tags [$(Bag $h.tag_own)] != guest received [$(Bag $g.tag_peer)]"
    Check ((Bag $g.tag_own) -eq (Bag $h.tag_peer)) "guest tags [$(Bag $g.tag_own)] != host received [$(Bag $h.tag_peer)]"
    Check ($g.first_tag_peer -gt 0 -and $g.first_tag_peer -lt $g.first_tag_own) "guest got its own tag before the host's"
  } else {
    Check ($h.tag_peer.Count + $g.tag_peer.Count -eq 0) "tags=own but tags were copied"
  }
}
$maxwait = ($g.waits | Measure-Object -Maximum).Maximum
if ($HostShopLag) { Check ($null -eq $maxwait -or $maxwait -lt 3) "guest sat on an empty blind screen for $maxwait s" }
if ($Secret) {
  Check ($h.hv_peer -contains 'Five_of_a_Kind') "host never learned Five of a Kind from the guest"
  Check ($h.pool -contains 'true') "Planet X not in the host's planet pool: $($h.pool)"
}
if ($TestTags) {
  # own Charm + its Double Tag copy + the partner's Charm = 3 mega arcana packs each, one at a time
  Check ($h.packs -ge 3) "host opened $($h.packs) packs, expected 3"
  Check ($g.packs -ge 3) "guest opened $($g.packs) packs, expected 3"
}
if ($Wish) {
  Check ($g.wish_click -gt 0) "guest bot never pressed select"
  Check ($h.wish_recv -eq $g.wish_click) "guest pressed $($g.wish_click) times, host got $($h.wish_recv) wishes"
  # the guest may open the Play menu, but Play in it is refused and the menu stays open
  Check (($g.gmenu -join ' / ') -match 'GUESTMENU open overlay=true / BLOCKED start_setup_run / GUESTMENU after play overlay=true') "guest Play menu: $($g.gmenu -join ' / ')"
  Check ($h.wish_seen -gt 0) "host bot never saw a wish on its blind screen"
  # every wish pulses something on the host; a skip pulses the skip button and the tag
  Check ($h.pulses.Count -eq $h.wish_recv) "host pulsed $($h.pulses.Count) of $($h.wish_recv) wishes: $($h.pulses -join ',')"
  Check (@($h.pulses | Where-Object { $_ -like 'skip:*' }).Count -gt 0) "no skip wish was pulsed: $($h.pulses -join ',')"
  Check (-not ($h.pulses | Where-Object { $_ -eq 'skip:0' -or $_ -eq 'skip:1' -or $_ -eq 'sel:0' })) "a wish found nothing (or only part) to pulse: $($h.pulses -join ',')"
}
if ($Reroll) {
  # host rerolls at ante 1, guest at ante 2: each new boss reaches the other side, and the
  # guest faces the host's boss when the Boss blind is selected
  Check ($h.reroll_own.Count -ge 1) "host never finished a reroll"
  Check ($g.reroll_own.Count -ge 1) "guest never finished a reroll"
  Check ($g.boss_peer.Count -ge 1) "guest never took the host's rerolled boss"
  Check ($h.boss_peer.Count -ge 1) "host never took the guest's rerolled boss"
  Check ($g.selboss.Count -ge 2) "fewer than 2 Boss selections on the guest: $($g.selboss -join ',')"
  Check (-not ($g.selboss | Where-Object { $a, $b = $_.Split('|'); $a -ne $b })) "guest boss differed from the host's at selection: $($g.selboss -join ',')"
  if ($g.dollars_before -and $g.reroll_own) {
    $after = [regex]::Match($g.reroll_own[-1], 'dollars=(\S+)').Groups[1].Value
    Check (([double]$g.dollars_before[-1] - [double]$after) -eq 10) "guest reroll cost $($g.dollars_before[-1]) -> $after, expected -10"
  }
}
if ($Pause) {
  # the host's own count was paused for longer than 0.6.2's 20 s wait while the guest
  # scored: the round totals checks above must still hold
  Check ($h.pauses.Count -ge 1) "the host never paused during its own count"
}
if ($Ante) {
  # Hieroglyph on the host, then Petroglyph on the guest: each time both go back one ante
  Check ($h.ante_own.Count -eq 1 -and $g.ante_own.Count -eq 1) "expected one ante voucher each: host $($h.ante_own.Count) guest $($g.ante_own.Count)"
  Check ($g.ante_peer.Count -eq $h.ante_own.Count -and $h.ante_peer.Count -eq $g.ante_own.Count) "ante moves not followed: host own/peer $($h.ante_own.Count)/$($h.ante_peer.Count) guest $($g.ante_own.Count)/$($g.ante_peer.Count)"
  Check (($h.ante_ignored.Count + $g.ante_ignored.Count) -eq 0) "ante message ignored: $($h.ante_ignored + $g.ante_ignored)"
  Check (-not ($h.adopts + $g.adopts | Where-Object { $_ -match 'ADOPT ante (\d+)->(\d+)' -and $Matches[1] -ne $Matches[2] })) "blind alignment moved an ante: $($h.adopts + $g.adopts)"
}
if ($Slow) {
  Check ($h.waiting.Count + $g.waiting.Count -gt 0) "nobody waited for the partner (no out-of-hands case)"
  Check (-not (($h.waiting + $g.waiting) -contains 'true')) "input locked while waiting: host $($h.waiting -join ',') guest $($g.waiting -join ',')"
}

"rounds=$($common.Count) selects=$($h.sel.Count)/$($g.sel.Count) skips=$($h.skip.Count) early_clicks=$($h.early) refused=$($h.blocked) " +
  "levels host->guest=$($h.lvl_own.Count)/$($g.lvl_peer.Count) guest->host=$($g.lvl_own.Count)/$($h.lvl_peer.Count) checks=$script:checks failed=$($script:fails.Count)"
foreach ($r in $common) {
  $a = $h.rounds[$r]; $b = $g.rounds[$r]
  "  r$($r): target=$($a.target) host $($a.mine)+$($a.theirs)=$($a.chips) guest $($b.mine)+$($b.theirs)=$($b.chips) won=$($a.won)"
}
"  flushes host/guest=$($h.flushes)/$($g.flushes) tags host->guest=$($h.tag_own -join ',') guest->host=$($g.tag_own -join ',') " +
  "guest blind waits=$(($g.waits | ForEach-Object { '{0:n1}' -f $_ }) -join ',') secret=$($h.hv_peer -join ',') pool=$($h.pool -join ',')"
"  packs host/guest=$($h.packs)/$($g.packs) nbc=$($h.nbc)/$($g.nbc) wishes clicked/received/seen=$($g.wish_click)/$($h.wish_recv)/$($h.wish_seen) waiting host=$($h.waiting -join ',') guest=$($g.waiting -join ',')"
"  pauses host=$($h.pauses -join ',') ease shifts h/g=$($h.shifts)/$($g.shifts) ante host: $($h.ante_own + $h.ante_peer -join ' / ') | guest: $($g.ante_own + $g.ante_peer -join ' / ')"
"  reroll host: $($h.reroll_own -join ' / ') | guest: $($g.reroll_own -join ' / ') | boss peer h/g: $($h.boss_peer.Count)/$($g.boss_peer.Count) | selboss: $($g.selboss -join ',')"
"  resume host: $($h.resumes -join ' / ')"
"  resume guest: $($g.resumes -join ' / ')"
"  adopt host: $($h.adopts.Count) guest: $($g.adopts -join ' / ')"
"  start: $($h.starts) / $($g.starts)"
"  end: $($h.ends | Select-Object -Last 1) / $($g.ends | Select-Object -Last 1)"
foreach ($f in $script:fails) { "FAIL $f" }
if ($script:fails.Count) { exit 1 } else { exit 0 }
