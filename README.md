# Balatro Duo

Two-player local co-op for [Balatro](https://store.steampowered.com/app/2379780/Balatro/) on one PC.
Two game windows, each player with their own run (money, jokers, deck, shop); the blind score
is shared, so both players' hands add up towards one target. The host picks blinds, skips and
the boss. Made with [CoOp:Anything](https://github.com/cranebeaker/coop-anything).

*Русский: [package/ПРОЧТИ.txt](package/ПРОЧТИ.txt).*

- Game: Balatro 1.0.1o-FULL (Steam build 17459173), Windows.
- Loader: [Lovely](https://github.com/ethangreen-dev/lovely-injector) 0.9.0. Steamodded is not needed.
- Text in all 15 languages the game has.

## Install

Download `BalatroDuo-<version>.zip` from [Releases](../../releases), unpack it, close Balatro and
run `Install.cmd` (or `Установить.cmd`). It finds the game in Steam, puts Lovely's `version.dll`
next to `Balatro.exe` and the mod into `%APPDATA%\Balatro\Mods\BalatroDuo`. Saves are not
touched. `Uninstall.cmd` removes both again.

Then: main menu -> **CO-OP** -> **Play together (2 windows)**. Host window: mouse and keyboard;
guest window: gamepad #1. Full player guide: [package/README.txt](package/README.txt).

## What is shared

Set by the host in CO-OP -> *What is shared...*:

| Setting | Options |
|---|---|
| Blind difficulty | x1 ... x3 (blind target multiplier) |
| Deck and stake | shared (the host starts, the guest follows) / each their own |
| Hand levels | each their own / shared: planets (default) / shared: all upgrades |
| Skip tags | both tags to both (default) / each their own |
| Secret hands | shared (default; their planets can appear for both) / each their own |

Other things that are synced: the partner's score only after its count animation, the boss
(host's), blind progress, the guest's select/skip wishes shown on the host's screen.

## How it works

- `BalatroDuo/lovely.toml` patches a few lines of the game's Lua (hand score, round end,
  deck-out check, main menu button, secret-hand planet pool). Everything else is
  `BalatroDuo/duo.lua`, appended to `main.lua`, hooking game functions.
- The two windows talk over TCP on `127.0.0.1:22123`, one text line per message.
- The second window has its own save identity (`%APPDATA%\BalatroDuoP2`).
- The co-op state (run id, score split of the current round, hands the partner found) is
  stored in the game's own save (`G.GAME.duo`), so **Continue** works after a crash or restart.
  Each side sends its whole run position when it changes. The side that is further along wins:
  the one behind catches up on its blind screen or joins the blind the partner is already
  playing.
- Development notes, root causes and every bug found: the
  [CoOp:Anything write-up](https://github.com/cranebeaker/coop-anything/tree/main/games/balatro).

## Tests

Bot clients play real games against each other (`--duo-bot`); a flight recorder log on each
side (`duo_log.txt`) is compared by `tools/check_logs.ps1`. Run on Windows PowerShell 5.1.

| Script | What it does |
|---|---|
| `tools/run_all.ps1` | all 9 scenarios below, 400 s timeout each (~35 min) |
| `tools/run_suite.ps1` | one bot game; `-ShopLag`, `-HostShopLag`, `-Planets`, `-Secret`, `-TestTags`, `-Wish`, `-Slow`, `-DeckMode own` |
| `tools/run_restart.ps1` | kills the host, the guest or both mid-run and restarts them; `-SelfRelaunch` lets the host reopen a dead guest |
| `tools/lang_test.ps1` | switches the game language and screenshots the CO-OP menus |
| `tools/win_test.ps1` | window placement across restarts |

Scenarios: shop lag + planets, host shop lag + secret hands, tag stack (Double Tag + Charm Tag
on both: the old host crash), guest wishes + slow guest (out of hands), own decks, host killed,
guest killed, both killed, guest killed and reopened by the host. Last full run (0.6.0): 9/9
passed. 0.6.1: scenarios 1-2, the wish run (47/47) and all 15 languages.

The scripts expect this layout (paths are at the top of each script):
`C:\coop-anything\local\bal-test` (a copy of the game folder with Lovely), `...\balatro-duo\BalatroDuo`
(this mod), `...\bal-appdata\` (test profiles, the scripts redirect `APPDATA` there), and
`...\bal-save-backup` (a copy of `settings.jkr`, `1\profile.jkr`, `1\meta.jkr`).

Build the player zip: `tools/build_package.ps1` (downloads Lovely 0.9.0 from its release page,
checks SHA-256 `40b994a0...1f7`, writes `dist/BalatroDuo-<version>.zip`).

## Known issues / not tested

- A gamepad in the window without focus (button presses) is not tested.
- Antes above 2, Mr. Bones, boss reroll vouchers and Boss Tag on the guest are not tested.
- Continue and catch-up were tested by bots on antes 1-2, not at high antes.
- Starting a second window from Steam while one runs opens it with the host's profile; only
  the host opens the guest window.

## License

MIT, see [LICENSE](LICENSE). Lovely (bundled in the release zip) is MIT, © Ethan Green
([package/files/LOVELY-LICENSE.md](package/files/LOVELY-LICENSE.md)).
Balatro is © LocalThunk / Playstack; no game files are included.
