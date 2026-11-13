BALATRO DUO 0.6.3 — two-player co-op on one PC
================================================
(Русский: ПРОЧТИ.txt)

What it is
----------
Two Balatro windows. Each player has their own run: own money, jokers,
deck and shop. Only the blind score is shared: both players' points add up,
and the blind is beaten when the shared score reaches the target.
Blinds, skips and the boss are picked by the host (the window where
"Play together" was pressed).

New in 0.6.3
------------
- Fixed: the partner's points could vanish from the shared score. When counting
  your own hand took longer than 20 seconds (the game paused or a menu open during
  the count, a long joker chain), points the partner scored meanwhile were
  overwritten. The two screens then disagreed: one side won the blind, the other
  lost the run.
- The "Shared score ... (you + partner)" line stays on screen after the round
  ends, until the shop opens.
- The blind screen shows the partner's skip tag under your own ("Partner's tag";
  hover it for the description). Handy when a friend plays over Parsec and only
  sees their own window.
- Hieroglyph / Petroglyph (-1 ante): the ante is shared, both go back. The buyer
  pays and loses the hand or discard; the partner's ante follows for free
  ("Partner moved the ante back..."). Before, the buyer went back alone and the
  blind alignment moved it forward again at once: the voucher was wasted.
- The guest can open the Play menu to look at decks, stakes and challenges.
  Only the host can start or continue a run from it.
- The partner's Orbital Tag shows which hand it levels (it said "[poker hand]").
- Once a minute the log gets a PERF line (frames per second, frame time, memory).
  If a window gets slower over time, send that window's duo_log.txt.
  When the game update takes over 6 ms a frame, every 5 minutes the mod samples
  for 5 s which game functions take the time (PROF lines).
- Fixed: the gamepad window lost frames over a long session (60 down to 20 in two
  hours). The game itself leaks there: in gamepad mode the Buy / Sell / Use buttons under
  a card leave their UI elements behind, and the game updated all of them every frame
  (up to 8000). Every 10 s the mod takes them out of the update (LEAK line in the log)
  and also closes two more of the game's leaks (blind particles, the Cash Out button).
  A 107-minute playtest after that stayed at 60 fps.

New in 0.6.2
------------
- Fixed: when both players got a pack tag from a skip (e.g. two Charm Tags), the
  guest could open both packs at once. Packs now open one after another on both sides.
- Boss rerolls work from both windows: the Director's Cut / Retcon button (costs
  $10 to whoever presses it) and Boss Tag. The partner gets the same new boss for free
  ("Partner rerolled the boss: ...").

New in 0.6.1
------------
- When the guest presses "Skip", the host's Skip button and that blind's tag
  now pulse too (before, only "Select" did).
- The mod's text is translated into every language the game has: English,
  Russian, German, French, Spanish, Italian, Portuguese, Polish, Dutch,
  Indonesian, Japanese, Korean, Chinese (simplified and traditional). It follows
  the game's language setting.
- While a menu is open, the co-op status bar is drawn at the bottom of the
  screen instead of over the menu title.
- The installer talks Russian on a Russian Windows and English elsewhere.
  Install.cmd / Uninstall.cmd are the same as Установить.cmd / Удалить.cmd.

Updating
--------
No need to uninstall the old version. Close both Balatro windows, unpack the
archive and run Install.cmd: it replaces the mod folder, version.dll stays.
A run started on 0.5.0 or older cannot be continued together (its save has no
co-op state): start a new run. Runs from 0.6.0 continue fine.

Install
-------
1. Close Balatro.
2. Double-click Install.cmd. It finds the game in Steam and:
   - puts version.dll (the Lovely 0.9.0 mod loader) next to Balatro.exe;
   - puts the mod folder into %APPDATA%\Balatro\Mods\BalatroDuo.
   Saves are not touched. An older version of the mod is replaced.
3. Start Balatro from Steam as usual.
   A black loader console flashes for a second or two; the mod hides it.
   To keep it (for debugging), start the game with --duo-console.

How to play
-----------
1. Main menu -> CO-OP -> "Play together (2 windows)". A second window opens.
2. Host window: mouse and keyboard. Guest window: gamepad #1.
   Change it in the CO-OP menu ("Gamepad #1 drives").
3. CO-OP menu settings (only the host changes them, the guest sees them):
   - Gamepad #1 drives: the guest window / the host window;
   - Host window (mouse): right or left (for screen halves);
   - Windows on start:
       "as they were": each window opens the way you left it: fullscreen or
         borderless on the same monitor (that is the game's own setting:
         Options -> Video), windowed at the same spot; on the very first start
         the windows go to the two screen halves;
       "screen halves": always put the windows on two halves of the monitor.
   - "What is shared..." submenu:
       Blind difficulty: x1 ... x3 (the blind target is multiplied by it);
       Deck and stake: "shared": the host starts the run and the guest's run
         starts by itself with the same deck and stake; "each their own":
         each player picks;
       Hand levels:
         "each their own": as in the normal game;
         "shared: planets": a Planet card (and Black Hole) levels the hand up
           for both (default);
         "shared: all upgrades": also jokers and tags that level hands
           (Space Joker, Burnt Joker, Orbital Tag).
       A level-down by the boss The Arm is never passed on: each player plays
       against their own boss.
       Skip tags:
         "both tags to both" (default): each player gets their own tag and the
           partner's; Double Tag copies the partner's tag like any other;
         "each their own": as in the normal game.
       Secret hands:
         "shared" (default): a secret hand one player finds shows up for both,
           and its planet can turn up for both;
         "each their own": as in the normal game.
4. Each window has a bar at the top: the shared score, how much you and your
   partner put in, and what is being waited for (at the bottom while a menu
   is open).
5. The guest can press Select or Skip too: the host then sees
   "Partner wants to: SELECT <blind>" (or SKIP) and that button pulses on the
   host's screen. The host still decides.

Two monitors
------------
In each window: Options -> Video -> pick the monitor and the mode (Fullscreen
or Borderless) -> Apply. The mod remembers it (each window has its own
settings), and after a restart the windows open there again.

Crashes and continuing
----------------------
The co-op state (run id, score of the current round, hands the partner found)
is kept in the game's own save, so Continue works for both windows.
- The guest window crashed: nothing to do. After 10 seconds the host opens
  the guest window again and it continues the run.
- The host window crashed: start Balatro from Steam, CO-OP -> "Play together".
  No new guest window opens, the old one reconnects. The host continues the
  same run by itself once the main menu is up (about 20-25 seconds).
- Both closed: the host presses "Play together", then Play -> Continue; the
  guest continues by itself.
- Don't open a second window from Steam while the first one runs: it would
  open with the host's profile, not the guest's. Only the host opens the guest.
While the partner is gone (crashed, restarting), the round doesn't end: if you
are out of hands, the mod waits for the partner for up to 90 seconds.
If one window saved earlier than the other (say one round behind), it catches
up on the blind screen: ante, round, which blinds are done, and the boss. If the
partner is already playing a blind, the one behind goes into the same blind and
the points add up. Nobody is moved backwards.

End of a blind
--------------
- Shared score reached: whoever isn't animating waits, whoever is finishes
  the animation. Then both go on.
- One player out of hands: waits for the partner (input stays free; only
  Play is off).
- Both out of hands and the score not reached: both lose.
- The partner is behind (restarting, or continued an older save): it is
  waited for up to 2 minutes and joins this blind. The partner is already past
  this round: the round ends without it after a few seconds.

Second window profile
---------------------
The second window keeps its saves apart: %APPDATA%\BalatroDuoP2.
On its first start your profile is copied there (unlocked decks and so on).

If something goes wrong
-----------------------
Logs:
  window 1: %APPDATA%\Balatro\duo_log.txt and duo_log_prev.txt
  window 2: %APPDATA%\BalatroDuoP2\duo_log.txt and duo_log_prev.txt
  loader:   %APPDATA%\Balatro\Mods\lovely\log\
duo_log.txt is the current start, duo_log_prev.txt the one before (after a
crash and restart, that one has the log up to the crash). If the game shows
"Oops! Something went wrong", take a photo of the error text.

Uninstall
---------
Close Balatro, double-click Uninstall.cmd. It removes version.dll and the mod
folder; the game is back to normal. The second window's profile
(%APPDATA%\BalatroDuoP2) stays; delete it by hand if you like.

Not tested yet
--------------
- a gamepad in the window that doesn't have focus (button presses);
- antes above 2, the Mr. Bones joker;
- continuing and catching up were tested with bots on antes 1-2, not yet at
  high antes or with people;
- shared hand levels switched on in the middle of a run (levels gained before
  are not passed on).
