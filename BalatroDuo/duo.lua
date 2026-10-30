
----------------------------------------------------------------------------
-- Balatro Duo: two windows, two own runs, one shared blind score.
-- Appended to main.lua by Lovely. Everything lives in the DUO table.
-- Host decides blinds (select, skip, boss). Each player has own deck,
-- money, jokers and shop. Hand scores go into one shared pot per blind.
----------------------------------------------------------------------------
DUO = DUO or {}
local D = DUO
D.VERSION = '0.6.1'
D.PORT = 22123
D.DIFFS = {1, 1.5, 2, 2.5, 3}

local socket_ok, socket = pcall(require, 'socket')

--------------------------------------------------------------------- args
local function arg_index(name)
  for i, v in ipairs(arg or {}) do if v == name then return i end end
end
local function arg_value(name)
  local i = arg_index(name)
  return i and arg[i + 1] or nil
end
D.args = {
  guest = arg_index('--duo-guest') ~= nil,
  host = arg_index('--duo-host') ~= nil,
  bot = arg_index('--duo-bot') ~= nil,
  two_windows = arg_index('--duo-two-windows') ~= nil,
  deck_mode = arg_value('--duo-deck'),
  bot_deck = arg_value('--duo-bot-deck'),
  bot_stake = tonumber(arg_value('--duo-bot-stake') or ''),
  test_lag = tonumber(arg_value('--duo-test-lag') or ''),
  window = arg_value('--duo-window'),
  identity = arg_value('--duo-identity'),
  seed = arg_value('--duo-seed'),
  speed = tonumber(arg_value('--duo-speed') or ''),
  quit_ante = tonumber(arg_value('--duo-quit-ante') or ''),
  diff = tonumber(arg_value('--duo-diff') or ''),
  layout = arg_value('--duo-layout'),
  levels = arg_value('--duo-levels'),
  test_shop_lag = tonumber(arg_value('--duo-test-shop-lag') or ''),
  test_planets = arg_index('--duo-test-planets') ~= nil,
  test_host_shop_lag = tonumber(arg_value('--duo-test-host-shop-lag') or ''),
  test_secret = arg_index('--duo-test-secret') ~= nil,
  test_tags = arg_index('--duo-test-tags') ~= nil,
  test_old_nbc = arg_index('--duo-test-old-nbc') ~= nil,
  test_wish = arg_index('--duo-test-wish') ~= nil,
  test_slow = tonumber(arg_value('--duo-test-slow') or ''),
  test_continue = arg_index('--duo-test-continue') ~= nil,
  test_lang = arg_value('--duo-test-lang'),
  tags = arg_value('--duo-tags'),
  mod_dir = arg_value('--mod-dir'),
}

-- Lovely opens a log console next to the game. Players don't need it:
-- hide it unless started with --duo-console.
if not arg_index('--duo-console') then
  pcall(function()
    local ffi = require('ffi')
    pcall(ffi.cdef, 'void* GetConsoleWindow(void); int ShowWindow(void* hwnd, int cmd);')
    local hwnd = ffi.C.GetConsoleWindow()
    if hwnd ~= nil then ffi.load('user32').ShowWindow(hwnd, 0) end
  end)
end

------------------------------------------------------------------ strings
local STR = {
  ru = {
    menu_button = 'КООП',
    title = 'Кооп на двоих',
    two_windows = 'Играть вдвоём (2 окна)',
    host_only = 'Хост: ждать подключения',
    join = 'Подключиться к хосту',
    disconnect = 'Выключить кооп',
    diff = 'Сложность блайндов (хост)',
    pad = 'Геймпад №1 управляет',
    deck_mode = 'Колода и ставка',
    deck_shared = 'общие',
    deck_own = 'у каждого свои',
    guest_settings = 'Настройки хоста:',
    host_starts = 'Забег начинает хост',
    pad_guest = 'окном гостя',
    pad_host = 'окном хоста',
    side = 'Окно хоста (мышь)',
    side_right = 'справа',
    side_left = 'слева',
    off = 'Кооп выключен',
    host_wait = 'Кооп: хост, ждём напарника',
    host_ok = 'Кооп: хост, напарник на месте',
    guest_wait = 'Кооп: подключаемся к хосту...',
    guest_ok = 'Кооп: подключено к хосту',
    score = 'Общий счёт %s / %s   (вы %s + напарник %s)',
    wait_partner = 'Ждём напарника',
    wait_host = 'Ждём, пока хост выберет блайнд',
    host_picks = 'Блайнд выбирает хост',
    won_wait = 'Блайнд побеждён! Ждём, пока напарник доиграет',
    out_wait = 'Руки закончились. Ждём напарника',
    peer_shop = 'Напарник ещё в магазине',
    peer_menu = 'Напарник в меню',
    peer_over = 'Напарник проиграл',
    peer_new = 'Напарник начал новый забег',
    lost_conn = 'Связь с напарником потеряна',
    ver = 'Разные версии мода: %s и %s',
    shared_menu = 'Что общее...',
    shared_title = 'Что общее, а что у каждого своё',
    levels = 'Уровни рук (планеты)',
    levels_off = 'у каждого свои',
    levels_planets = 'общие: планеты',
    levels_all = 'общие: все прокачки',
    peer_level = 'Напарник прокачал: %s (ур. %s)',
    layout = 'Окна при запуске',
    layout_keep = 'как стояли',
    layout_halves = 'половинки экрана',
    tags = 'Теги за пропуск',
    tags_own = 'у каждого свой',
    tags_both = 'оба тега обоим',
    peer_tag = 'Тег от напарника: %s',
    hands = 'Секретные комбинации',
    hands_own = 'у каждого свои',
    hands_shared = 'общие',
    peer_hand = 'Напарник открыл: %s',
    wish_sel = 'Напарник хочет: ВЫБРАТЬ %s',
    wish_skip = 'Напарник хочет: ПРОПУСТИТЬ %s',
    wish_sent = 'Выбирает хост. Он видит, что ты хочешь',
    resume = 'Напарник в забеге: продолжаю сохранение',
    other_run = 'У напарника другой забег: нажми "Продолжить" или начни новый',
    own_start = 'Колоды у каждого свои: начни свой забег',
    boss_wait = 'Ждём босса от хоста',
  },
  en = {
    menu_button = 'CO-OP',
    title = 'Two-player co-op',
    two_windows = 'Play together (2 windows)',
    host_only = 'Host: wait for partner',
    join = 'Join host',
    disconnect = 'Turn co-op off',
    diff = 'Blind difficulty (host)',
    pad = 'Gamepad #1 drives',
    deck_mode = 'Deck and stake',
    deck_shared = 'shared',
    deck_own = 'each their own',
    guest_settings = 'Host settings:',
    host_starts = 'The host starts the run',
    pad_guest = 'guest window',
    pad_host = 'host window',
    side = 'Host window (mouse)',
    side_right = 'right',
    side_left = 'left',
    off = 'Co-op off',
    host_wait = 'Co-op: host, waiting for partner',
    host_ok = 'Co-op: host, partner connected',
    guest_wait = 'Co-op: connecting to host...',
    guest_ok = 'Co-op: connected to host',
    score = 'Shared score %s / %s   (you %s + partner %s)',
    wait_partner = 'Waiting for partner',
    wait_host = 'Waiting for the host to pick a blind',
    host_picks = 'The host picks blinds',
    won_wait = 'Blind beaten! Waiting for partner to finish',
    out_wait = 'Out of hands. Waiting for partner',
    peer_shop = 'Partner is still in the shop',
    peer_menu = 'Partner is in the menu',
    peer_over = 'Partner lost',
    peer_new = 'Partner started a new run',
    lost_conn = 'Lost connection to partner',
    ver = 'Mod versions differ: %s and %s',
    shared_menu = 'What is shared...',
    shared_title = 'What is shared and what is your own',
    levels = 'Hand levels (planets)',
    levels_off = 'each their own',
    levels_planets = 'shared: planets',
    levels_all = 'shared: all upgrades',
    peer_level = 'Partner leveled up: %s (lvl %s)',
    layout = 'Windows on start',
    layout_keep = 'as they were',
    layout_halves = 'screen halves',
    tags = 'Skip tags',
    tags_own = 'each their own',
    tags_both = 'both tags to both',
    peer_tag = 'Tag from partner: %s',
    hands = 'Secret hands',
    hands_own = 'each their own',
    hands_shared = 'shared',
    peer_hand = 'Partner found: %s',
    wish_sel = 'Partner wants to: SELECT %s',
    wish_skip = 'Partner wants to: SKIP %s',
    wish_sent = 'The host picks. The host sees what you want',
    resume = 'Partner is in a run: continuing the save',
    other_run = 'Partner is in another run: press Continue or start a new one',
    own_start = 'Own decks: start your run',
    boss_wait = 'Waiting for the boss from the host',
  },
}
-- other languages come from duo_lang.lua (appended before this file)
for k, v in pairs(DUO_LANG or {}) do STR[k] = v end

-- the game's language codes: en-us, ru, de, fr, es_ES, es_419, it, pt_BR, pl, nl, id,
-- ja, ko, zh_CN, zh_TW. Full code first (zh_CN / zh_TW differ), then the first two letters.
function DUO_L(key)
  local code = G and G.SETTINGS and G.SETTINGS.language or 'en'
  local t = STR[code] or STR[code:sub(1, 2)] or STR.en
  return t[key] or STR.en[key] or key
end
local L = DUO_L

------------------------------------------------------------------ logging
-- Flight recorder: one line per event, read by the test checker.
local LOG_FILE = 'duo_log.txt'
function D.log(fmt, ...)
  local ok, msg = pcall(string.format, fmt, ...)
  if not ok then msg = tostring(fmt) end
  local line = string.format('%.3f %s %s', love.timer.getTime(), D.role or '-', msg)
  print('[DUO] ' .. line)
  pcall(love.filesystem.append, LOG_FILE, line .. '\n')
end

local function num(x) return string.format('%.17g', x or 0) end

------------------------------------------------------------ save identity
-- The second window must not share a save folder with the first one.
-- It gets its own identity; on first start it copies the profile (unlocks).
local function copy_profile(from_identity)
  local base = love.filesystem.getAppdataDirectory() .. '/' .. from_identity .. '/'
  for _, f in ipairs({'settings.jkr', '1/profile.jkr', '1/meta.jkr'}) do
    if not love.filesystem.getInfo(f) then
      local h = io.open(base .. f, 'rb')
      if h then
        local data = h:read('*a'); h:close()
        if f:find('/') then love.filesystem.createDirectory('1') end
        love.filesystem.write(f, data)
        -- the window settings came from the other window: don't stack on top of it
        if f == 'settings.jkr' then D.fresh_profile = true end
      end
    end
  end
end

do
  local identity = D.args.identity or (D.args.guest and 'BalatroDuoP2') or nil
  if identity then
    local old = love.filesystem.getIdentity()
    love.filesystem.setIdentity(identity)
    copy_profile(old)
  end
  -- keep the previous log: after a crash and restart the interesting part is in there
  local old_log = love.filesystem.read(LOG_FILE)
  if old_log and #old_log > 0 then pcall(love.filesystem.write, 'duo_log_prev.txt', old_log) end
  pcall(love.filesystem.write, LOG_FILE, '')
end

------------------------------------------------------------------- config
-- Host settings (the guest gets them over the network and never saves them).
-- deck_mode: 'shared' = the host's run start starts the guest's run with the
-- same deck and stake; 'own' = each player picks their own.
-- host_side: where the host window (mouse) goes in "Play together"; the guest takes the other half.
-- layout: 'keep' = each window starts as it was last time (game's own screen mode and
-- monitor, saved position for windowed); 'halves' = always put both on screen halves.
-- levels: hand levels shared between players: 'off', 'planets' (Planet cards, Black Hole)
-- or 'all' (any level up, e.g. Space Joker, Burnt Joker, Orbital Tag). Level downs (The Arm)
-- never cross over: each player plays against their own boss.
D.cfg = {diff = 2, address = '127.0.0.1', bind = '127.0.0.1', pad_first = 'guest', deck_mode = 'shared',
  host_side = 'right', layout = 'keep', levels = 'planets', tags = 'both', hands = 'shared'}
-- tags: 'own' = vanilla; 'both' = a skip gives each player their own tag plus the
-- partner's (host's first). Boss Tag is never copied: the host's boss reroll is already synced.
-- hands: 'shared' = a secret hand (Five of a Kind, Flush House, Flush Five) one player
-- found shows up for the other too, and its planet can appear in their shops.
local CFG_KEYS = {'diff', 'address', 'bind', 'pad_first', 'deck_mode', 'host_side', 'layout', 'levels',
  'tags', 'hands'}
local CFG_FILE = 'duo_config.txt'
function D.load_cfg()
  local s = love.filesystem.read(CFG_FILE)
  if not s then return end
  for k, v in s:gmatch('([%w_]+)%s*=%s*([^\r\n]+)') do
    if k == 'diff' then D.cfg.diff = tonumber(v) or D.cfg.diff else D.cfg[k] = v end
  end
end
function D.save_cfg()
  local lines = {'# Balatro Duo settings'}
  for _, k in ipairs(CFG_KEYS) do
    lines[#lines + 1] = k .. '=' .. (k == 'diff' and num(D.cfg.diff) or tostring(D.cfg[k]))
  end
  love.filesystem.write(CFG_FILE, table.concat(lines, '\n') .. '\n')
end
function D.shared_deck() return D.cfg.deck_mode ~= 'own' end
function D.guest_side() return D.cfg.host_side == 'left' and 'right' or 'left' end
-- Host: push the settings the guest must follow.
function D.send_cfg()
  if D.role == 'host' then
    D.send({t = 'cfg', d = num(D.cfg.diff), pf = D.cfg.pad_first, dm = D.cfg.deck_mode, hs = D.cfg.host_side,
      ly = D.cfg.layout, lv = D.cfg.levels, tg = D.cfg.tags, hd = D.cfg.hands})
  end
end
local function apply_args()
  if D.args.diff then D.cfg.diff = D.args.diff end
  if D.args.layout then D.cfg.layout = D.args.layout end
  if D.args.levels then D.cfg.levels = D.args.levels end
  if D.args.tags then D.cfg.tags = D.args.tags end
end
D.load_cfg()
apply_args()

------------------------------------------------------------------ network
-- One TCP line per message: "t=sc r=3 a=1200". Non-blocking, polled each frame.
local function in_run() return G.STAGE == G.STAGES.RUN and G.GAME and G.GAME.blind end
D.role = nil        -- 'host' | 'guest' | nil
D.active = false    -- partner connected and said hello
D.peer = {}
D.inbox = {}

local function encode(m)
  local parts = {}
  for k, v in pairs(m) do parts[#parts + 1] = k .. '=' .. tostring(v) end
  return table.concat(parts, ' ')
end
local function decode(line)
  local m = {}
  for k, v in line:gmatch('(%w+)=(%S+)') do m[k] = v end
  return m
end

function D.send(m)
  if not D.conn then return end
  local line = encode(m)
  D.outbuf = (D.outbuf or '') .. line .. '\n'
  if m.t ~= 'hb' then D.log('send %s', line) end
end

local function close_conn(reason)
  if D.conn then pcall(function() D.conn:close() end) end
  local was = D.active
  D.conn, D.active, D.inbuf, D.outbuf = nil, false, '', ''
  D.peer = {}
  D.release_wait()
  if was then D.toast(L('lost_conn')); D.log('disconnect %s', tostring(reason)) end
end

function D.start_host()
  if not socket_ok then return end
  D.stop()
  D.role = 'host'
  D.load_cfg()
  apply_args()
  if D.args.deck_mode then D.cfg.deck_mode = D.args.deck_mode end
  D.allow_background_pads()
  D.server = socket.bind(D.cfg.bind or '127.0.0.1', D.PORT)
  if D.server then D.server:settimeout(0) end
  D.log('host listen %s:%d %s', D.cfg.bind, D.PORT, tostring(D.server ~= nil))
end

function D.start_guest()
  if not socket_ok then return end
  D.stop()
  D.role = 'guest'
  D.allow_background_pads()
  D.next_connect = 0
  D.log('guest connect %s:%d', D.cfg.address, D.PORT)
end

function D.stop()
  close_conn('stop')
  if D.server then pcall(function() D.server:close() end) end
  D.server, D.role = nil, nil
  D.launched_guest, D.launch_at = nil, nil
  D.reset_run_state()
end

local function on_connected(c)
  c:settimeout(0)
  pcall(function() c:setoption('tcp-nodelay', true) end)
  D.conn, D.inbuf, D.outbuf = c, '', ''
  D.last_rx = love.timer.getTime()
  D.send({t = 'hi', v = D.VERSION, role = D.role})
  D.send_cfg()
  D.sent_phase = nil
  D.sent_sync = nil
end

-- After a (re)connect nothing sent before can be trusted to have arrived: forget the
-- round statuses so round_update sends them again, ask for the partner's score, and
-- allow one automatic continue of a saved run.
function D.on_hello()
  D.auto_resume_tried = nil
  D.launch_at = nil
  D.relaunched = nil
  if in_run() and G.GAME.facing_blind then
    local r = D.R(G.GAME.round)
    if not r.ended then r.my_status, r.peer_status, r.peer_playing = nil, nil, nil end
  end
  D.send_tot(true)
end

function D.net_update()
  if not D.role then return end
  local now = love.timer.getTime()
  if D.role == 'host' and D.server and not D.conn then
    local c = D.server:accept()
    if c then on_connected(c); D.log('accepted') end
  elseif D.role == 'guest' and not D.conn and now >= (D.next_connect or 0) then
    D.next_connect = now + 1
    local c = socket.tcp()
    c:settimeout(0.05)
    if c:connect(D.cfg.address, D.PORT) then on_connected(c); D.log('connected')
    else c:close() end
  end
  if not D.conn then return end
  -- receive
  while true do
    local line, err, partial = D.conn:receive('*l', D.inbuf)
    if line then
      D.inbuf = ''
      D.last_rx = now
      D.inbox[#D.inbox + 1] = line
    else
      if err == 'timeout' then D.inbuf = partial or '' break end
      close_conn(err); return
    end
  end
  -- heartbeat
  if now - (D.last_hb or 0) > 1 then D.last_hb = now; D.send({t = 'hb'}) end
  if now - (D.last_rx or now) > 10 then close_conn('timeout'); return end
  -- send
  if D.outbuf ~= '' then
    local i, err, last = D.conn:send(D.outbuf)
    local sent = i or last or 0
    if sent > 0 then D.outbuf = D.outbuf:sub(sent + 1) end
    if err == 'closed' then close_conn(err); return end
  end
  -- handle
  while #D.inbox > 0 do
    local line = table.remove(D.inbox, 1)
    D.handle(decode(line), line)
  end
end

------------------------------------------------------------ run state
-- rounds[rid]: rid is G.GAME.round, the same on both sides because
-- blind selection is synced.
function D.reset_run_state()
  D.rounds = {}
  D.actions = {}
  D.host_boss = nil
  D.host_bst = nil
  D.hv_sent = {}
  D.peer_known = {}
  D.next_target = nil
  D.own_easing = false
  D.wish = nil
  D.nbc_pending = nil
  D.mismatch_since = nil
  D.blind_wait = nil
  D.release_wait()
  -- a fresh run on the guest: get the host's state again
  if D.role == 'guest' then D.send({t = 'need'}) end
end

function D.R(rid)
  rid = tonumber(rid) or 0
  local r = D.rounds[rid]
  if not r then
    r = {mine = 0, theirs = 0, pending = 0}
    D.rounds[rid] = r
  end
  return r
end

function D.coop() return D.active and in_run() end

------------------------------------------------------------ state sync
-- Each side sends its whole run position ('sy') whenever it changes: run id, ante,
-- round, blind states, boss, phase, deck. The guest follows the host from it:
-- which run to be in (D.reconcile), which boss, which blinds are done (adoption on the
-- blind screen). The host uses the guest's to continue the same saved run after a restart.
function D.new_id() return string.format('%d%04d', os.time(), math.random(0, 9999)) end
function D.run_id() return in_run() and G.GAME.duo and G.GAME.duo.id or nil end

function D.send_sync(ph)
  local ir = in_run()
  local rr = ir and G.GAME.round_resets
  local f
  if ir then
    local back = G.GAME.selected_back and G.GAME.selected_back.effect and G.GAME.selected_back.effect.center.key
    f = {'1', tostring(D.run_id() or '-'), ph, rr.ante, G.GAME.round, G.GAME.blind_on_deck or '-',
      rr.blind_states.Small or '-', rr.blind_states.Big or '-', rr.blind_states.Boss or '-',
      rr.blind_choices.Boss or '-', back or '-', G.GAME.stake or 1, G.GAME.challenge or '-'}
  else
    f = {'0', '-', ph}
  end
  local key = table.concat(f, ':')
  if key == D.sent_sync then return end
  D.sent_sync = key
  D.send({t = 'sy', i = f[1], id = f[2], p = f[3], a = f[4], r = f[5], o = f[6], s = f[7], b = f[8], x = f[9],
    k = f[10], dk = f[11], sk = f[12], ch = f[13]})
end

local function on_sync(m)
  local now = love.timer.getTime()
  local H = {inrun = m.i == '1', id = m.id, p = m.p, ante = tonumber(m.a), round = tonumber(m.r), od = m.o,
    s = m.s, b = m.b, x = m.x, k = (m.k and m.k ~= '-') and m.k or nil, dk = m.dk, sk = tonumber(m.sk),
    ch = m.ch, t = now}
  D.peer_sync = H
  if D.role ~= 'guest' or not H.inrun then return end
  -- the host's blind states are only stable on its blind screen
  if H.p == 'blind' then
    local hb = D.host_bst
    if not hb or hb.ante ~= H.ante or hb.Small ~= H.s or hb.Big ~= H.b then
      D.host_bst = {ante = H.ante, Small = H.s, Big = H.b, t = now}
    end
  end
  -- the next ante's boss is rolled at cash out: known from the shop on, stale in round/eval
  if H.k and (H.p == 'blind' or H.p == 'blind_wait' or H.p == 'shop') then
    D.host_boss = {ante = H.ante, key = H.k}
  end
end

-- Score resync after a reconnect or a continue: each side's own contribution is the
-- truth for the other's "partner" part. q=1 asks for an answer.
function D.send_tot(query)
  if not (D.active and in_run() and G.GAME.facing_blind) then return end
  local r = D.R(G.GAME.round)
  D.send({t = 'tot', r = G.GAME.round, m = num(r.mine + (r.unsent or 0)), q = query and 1 or 0})
end

function D.apply_tot()
  local m = D.pending_tot
  if not m or D.own_easing or not in_run() then return end
  -- a total for a round we are past: drop it; for the round we are just entering: keep
  -- it until we are in it (the answer to our own query arrives while the blind loads)
  if G.GAME.round > tonumber(m.r) then D.pending_tot = nil; return end
  -- only inside the round itself: facing_blind is still set in the shop, and a total
  -- written there carried into the next round (found by run_restart.ps1: 156 + 120 = 276)
  local s, S = G.STATE, G.STATES
  local in_round = s == S.SELECTING_HAND or s == S.DRAW_TO_HAND or s == S.HAND_PLAYED or s == S.PLAY_TAROT
  if not (in_round and G.GAME.facing_blind and G.GAME.round == tonumber(m.r)) then return end
  D.pending_tot = nil
  local r = D.R(m.r)
  if r.ended or r.reported then return end
  local t = tonumber(m.m) or 0
  if t ~= r.theirs or r.pending ~= 0 then
    r.theirs, r.pending = t, 0
    G.GAME.chips = r.mine + (r.unsent or 0) + r.theirs
    D.log('TOT r=%s theirs=%s chips=%s', m.r, num(t), num(G.GAME.chips))
  end
end

function D.handle(m, line)
  if m.t ~= 'hb' then D.log('recv %s', line) end
  if m.t == 'hi' then
    D.active = true
    if m.v ~= D.VERSION then D.toast(string.format(L('ver'), D.VERSION, tostring(m.v))) end
    D.on_hello()
  elseif m.t == 'ph' then
    D.peer.phase, D.peer.round, D.peer.ante, D.peer.od = m.p, tonumber(m.r), tonumber(m.a), m.o
  elseif m.t == 'sy' then
    on_sync(m)
  elseif m.t == 'need' then
    D.sent_sync = nil
  elseif m.t == 'tot' then
    D.pending_tot = m
    if m.q == '1' then D.send_tot(false) end
  elseif m.t == 'wish' then
    D.wish = {a = m.a, d = m.d, r = tonumber(m.r), t = love.timer.getTime()}
    D.log('WISH a=%s d=%s r=%s', tostring(m.a), tostring(m.d), tostring(m.r))
    pcall(play_sound, 'highlight1', 1.2, 0.6)
  elseif m.t == 'pl' then
    D.R(m.r).peer_playing = true
  elseif m.t == 'sc' then
    local r = D.R(m.r)
    r.pending = r.pending + (tonumber(m.a) or 0)
    r.peer_playing = nil
  elseif m.t == 'st' then
    D.R(m.r).peer_status = m.s
    D.R(m.r).peer_playing = nil
  elseif m.t == 'sel' or m.t == 'skp' then
    D.actions[#D.actions + 1] = m
  elseif m.t == 'cfg' then
    D.cfg.diff = tonumber(m.d) or D.cfg.diff
    D.cfg.pad_first = m.pf == 'host' and 'host' or 'guest'
    D.cfg.deck_mode = m.dm == 'own' and 'own' or 'shared'
    D.cfg.host_side = m.hs == 'left' and 'left' or 'right'
    D.cfg.layout = m.ly == 'halves' and 'halves' or 'keep'
    D.cfg.levels = (m.lv == 'off' or m.lv == 'all') and m.lv or 'planets'
    D.cfg.tags = m.tg == 'own' and 'own' or 'both'
    D.cfg.hands = m.hd == 'own' and 'own' or 'shared'
    -- windows placed by "Play together" follow a side change
    if D.arranged and D.arranged ~= D.guest_side() then D.arrange(D.guest_side()) end
  elseif m.t == 'new' then
    D.toast(L('peer_new'))
  elseif m.t == 'tag' then
    D.peer_tag(m)
  elseif m.t == 'hv' then
    D.peer_hand(m.h and m.h:gsub('_', ' '))
  elseif m.t == 'lvl' then
    D.peer_level(m.h and m.h:gsub('_', ' '), tonumber(m.n) or 1)
  end
end

------------------------------------------------------------ phases
local function phase()
  if not (G.STAGE == G.STAGES.RUN and G.GAME) then return 'menu' end
  local s, S = G.STATE, G.STATES
  if s == S.BLIND_SELECT then return G.blind_select and 'blind' or 'blind_wait' end
  if s == S.SHOP or s == S.TAROT_PACK or s == S.PLANET_PACK or s == S.SPECTRAL_PACK
    or s == S.STANDARD_PACK or s == S.BUFFOON_PACK then return 'shop' end
  if s == S.ROUND_EVAL or s == S.NEW_ROUND then return 'eval' end
  if s == S.GAME_OVER then return 'over' end
  return 'round'
end
D.phase = phase

-- Partner sits on the blind screen of the same round with the same blind up next.
-- Or the partner is already inside the blind we are about to pick (after a continue or
-- a crash it got there first): picking it joins the partner.
function D.peer_ready()
  if not D.active then return false end
  if D.peer.phase == 'blind' and D.peer.round == G.GAME.round and D.peer.od == G.GAME.blind_on_deck then return true end
  return D.peer.phase == 'round' and D.peer.round == G.GAME.round + 1 and D.peer.od == G.GAME.blind_on_deck
end

------------------------------------------------------------ messages on screen
D.toasts = {}
-- key: a toast with the same key replaces the previous one (Black Hole = 12 level ups)
function D.toast(text, key)
  local until_t = love.timer.getTime() + 3
  for _, t in ipairs(D.toasts) do
    if key and t.key == key then t.text, t.t = text, until_t; D.log('toast %s', text); return end
  end
  D.toasts[#D.toasts + 1] = {text = text, t = until_t, key = key}
  D.log('toast %s', text)
end

function D.release_wait()
  if G and G.CONTROLLER and G.CONTROLLER.locks then G.CONTROLLER.locks.duo_wait = nil end
  D.wait_text = nil
end

------------------------------------------------------------ score hooks
-- Called from evaluate_play (patched): own hand score. The game computes the score
-- here, then plays the card-by-card count. The partner gets it only once our own
-- count has landed in the total (D.flush_score), so both screens show it in that order.
function DUO_on_hand(cur, amt)
  -- counted while the partner is away too: 'tot' hands it over after the reconnect
  if D.role and in_run() then
    local rid = G.GAME.round
    local r = D.R(rid)
    r.unsent = (r.unsent or 0) + amt
    -- tell the partner a hand is counting here: it must not close the round on its
    -- own win before these points arrive
    D.send({t = 'pl', r = rid})
    D.own_easing = true
    D.own_target = cur + amt
    D.own_ease_t = love.timer.getTime()
  end
  return cur + amt
end

-- Called from update_hand_played (patched): end the round now?
function DUO_hp_end()
  if G.GAME.chips - G.GAME.blind.chips >= 0 then
    -- won, but the partner's hand is still counting: wait for its points
    -- (round_update ends the round once the partner reports its status)
    if D.coop() and D.R(G.GAME.round).peer_playing then return false end
    return true
  end
  if G.GAME.current_round.hands_left < 1 then
    -- wait in SELECTING_HAND for the partner, also while it is disconnected: round_update
    -- ends the round with it, or D.update after 90 s alone
    if D.role and in_run() then return false end
    return true
  end
  return false
end

-- Called from update_selecting_hand (patched): deck is empty.
function DUO_deck_out_ok()
  if D.role and in_run() and G.GAME.chips - G.GAME.blind.chips < 0 then
    D.R(G.GAME.round).deck_out = true
    return false
  end
  return true
end

------------------------------------------------------------ hand levels
-- level_up_hand is the one place every hand upgrade goes through (Planet cards,
-- Black Hole, Space Joker, Burnt Joker, Orbital Tag, The Arm with -1).
local function is_planet(card)
  local a = type(card) == 'table' and card.ability
  return a and (a.set == 'Planet' or a.name == 'Black Hole') or false
end

local orig_level_up_hand = level_up_hand
function level_up_hand(card, hand, instant, amount)
  orig_level_up_hand(card, hand, instant, amount)
  -- a tag the partner gave us (Orbital Tag copy) levels only our side, the partner has its own copy
  if D.from_peer or not D.coop() or not G.GAME.hands[hand] then return end
  if type(card) == 'table' and card.duo_from_peer then return end
  local n = amount or 1
  local share = n > 0 and (D.cfg.levels == 'all' or (D.cfg.levels == 'planets' and is_planet(card)))
  D.log('LVL own hand=%s n=%d lv=%d shared=%s', hand:gsub(' ', '_'), n, G.GAME.hands[hand].level, tostring(share))
  if share then D.send({t = 'lvl', h = hand:gsub(' ', '_'), n = n}) end
end

function D.peer_level(hand, n)
  if not (in_run() and hand and G.GAME.hands[hand]) then return end
  D.from_peer = true
  pcall(orig_level_up_hand, nil, hand, true, n)
  D.from_peer = nil
  local lv = G.GAME.hands[hand].level
  D.log('LVL peer hand=%s n=%d lv=%d', hand:gsub(' ', '_'), n, lv)
  D.toast(string.format(L('peer_level'), localize(hand, 'poker_hands'), lv), 'lvl')
end

------------------------------------------------------------ skip tags
-- Both players skip the same blind (the host decides). With tags = 'both' each side
-- sends the tag it got; the other adds a copy. The host's tag reaches the guest before
-- the host's blind states do, so the guest gets the host's tag first, then its own.
function D.share_tag(e)
  if not (D.coop() and D.cfg.tags == 'both' and e and e.UIBox) then return end
  local c = e.UIBox:get_UIE_by_ID('tag_container')
  local tag = c and c.config.ref_table
  if not (tag and tag.key) then return end
  local o = tag.ability and tag.ability.orbital_hand
  o = (o and G.GAME.hands[o]) and o:gsub(' ', '_') or '-'
  D.log('TAG own k=%s n=%d d=%s', tag.key, G.GAME.round_resets.ante, tostring(G.GAME.blind_on_deck))
  if tag.key == 'tag_boss' then return end
  D.send({t = 'tag', k = tag.key, n = G.GAME.round_resets.ante, d = G.GAME.blind_on_deck, o = o})
end

function D.peer_tag(m)
  if not (in_run() and m.k and G.P_TAGS[m.k]) or D.cfg.tags ~= 'both' then return end
  local tag = Tag(m.k, false, m.d)
  local o = m.o and m.o:gsub('_', ' ')
  if o and G.GAME.hands[o] then tag.ability.orbital_hand = o end
  tag.duo_from_peer = true
  add_tag(tag)
  tag:apply_to_run({type = 'immediate'})
  -- Pack tags (Charm, Meteor, Ethereal, Standard, Buffoon) fire on 'new_blind_choice'.
  -- The game runs that as a loop that stops at the first tag that fires, and runs it
  -- again when the pack closes (end_consumeable), so packs open one after another.
  -- 0.5.0 fired the received tag directly: with a pack from an own tag already
  -- opening, two packs opened at once and the host crashed when they closed.
  -- Now we only run the game's own loop, and only when nothing is opening.
  if D.args.test_old_nbc and D.role == 'host' and G.STATE == G.STATES.BLIND_SELECT then
    tag:apply_to_run({type = 'new_blind_choice'})
  else
    D.nbc_pending = true
  end
  D.log('TAG peer k=%s', m.k)
  local ok, name = pcall(localize, {type = 'name_text', set = 'Tag', key = m.k})
  D.toast(string.format(L('peer_tag'), ok and name or m.k), 'tag')
end

local function tags_busy()
  for _, t in ipairs(G.GAME.tags or {}) do
    if G.CONTROLLER.locks[t.ID] then return true end
  end
  return false
end

-- Run the game's new_blind_choice loop for tags the partner gave us, once our blind
-- screen is up and idle (no pack opening, no tag animating).
function D.run_pending_nbc()
  if not D.nbc_pending then return end
  if not (G.STATE == G.STATES.BLIND_SELECT and G.STATE_COMPLETE and G.blind_select) then return end
  if G.CONTROLLER.locks.skip_blind or G.screenwipe or D.busy() or tags_busy() then return end
  D.nbc_pending = nil
  for i = 1, #G.GAME.tags do
    if G.GAME.tags[i]:apply_to_run({type = 'new_blind_choice'}) then
      D.log('NBC fired %s', tostring(G.GAME.tags[i].key))
      break
    end
  end
end

------------------------------------------------------------ secret hands
-- Secret hands become visible when played (evaluate_play). Their planets are
-- "softlock": only in the pool once the hand was played (patched to also accept a
-- hand the partner found, DUO_hand_known).
local SECRET = {['Five of a Kind'] = true, ['Flush House'] = true, ['Flush Five'] = true}

function DUO_hand_known(hand)
  return D.cfg.hands ~= 'own' and D.peer_known and D.peer_known[hand] or false
end

function D.hands_update()
  if D.cfg.hands == 'own' then return end
  for h in pairs(SECRET) do
    local v = G.GAME.hands[h]
    if v and v.visible and not D.hv_sent[h] then
      D.hv_sent[h] = true
      D.send({t = 'hv', h = h:gsub(' ', '_')})
      D.log('HV own h=%s', h:gsub(' ', '_'))
    end
  end
end

function D.peer_hand(h)
  if not (in_run() and h and SECRET[h] and G.GAME.hands[h]) or D.cfg.hands == 'own' then return end
  D.peer_known[h] = true
  D.hv_sent[h] = true
  local was = G.GAME.hands[h].visible
  G.GAME.hands[h].visible = true
  D.log('HV peer h=%s was=%s', h:gsub(' ', '_'), tostring(was))
  if not was then D.toast(string.format(L('peer_hand'), localize(h, 'poker_hands')), 'hv') end
end

------------------------------------------------------------ blind target
local function blind_key(proto)
  for k, v in pairs(G.P_BLINDS) do if v == proto then return k end end
end

function D.shared_target(key)
  local proto = G.P_BLINDS[key]
  local base = get_blind_amount(G.GAME.round_resets.ante) * proto.mult * G.GAME.starting_params.ante_scaling
  return math.floor(base * (D.cfg.diff or 1))
end

local orig_set_blind = Blind.set_blind
function Blind:set_blind(blind, reset, silent)
  orig_set_blind(self, blind, reset, silent)
  if blind and not reset and D.coop() and D.next_target then
    self.chips = D.next_target
    self.chip_text = number_format(self.chips)
    D.R(G.GAME.round).target = self.chips
    D.log('target r=%d chips=%s', G.GAME.round, num(self.chips))
    D.next_target = nil
    -- if the partner is already in this blind (we joined it late), ask for its score
    D.want_tot = true
  end
end

------------------------------------------------------------ blind select
-- The select and skip buttons are one_press: a click disables them for good.
-- When co-op refuses the click, turn the button back on.
local function refuse(e, text, what)
  if e then e.disable_button = nil end
  D.toast(text)
  D.log('BLOCKED %s', what)
end

-- Depth-first search of a UIBox's element tree.
function D.find_uie(node, pred)
  if not node then return nil end
  if pred(node) then return node end
  for _, c in ipairs(node.children or {}) do
    local r = D.find_uie(c, pred)
    if r then return r end
  end
end

-- Guest pressed select/skip: the host decides, but sees what the guest wants.
local function send_wish(a, d)
  D.send({t = 'wish', a = a, d = d or '-', r = G.GAME.round})
end

local orig_select_blind = G.FUNCS.select_blind
G.FUNCS.select_blind = function(e)
  if D.coop() then
    if D.role == 'guest' and not D.net_action then
      local key = e and e.config and blind_key(e.config.ref_table)
      send_wish('sel', key == 'bl_small' and 'Small' or key == 'bl_big' and 'Big' or key and 'Boss' or G.GAME.blind_on_deck)
      return refuse(e, L('wish_sent'), 'sel')
    end
    if D.role == 'host' then
      D.wish = nil
      if not D.peer_ready() then
        return refuse(e, D.peer.phase == 'shop' and L('peer_shop') or L('wait_partner'), 'sel')
      end
      local key = blind_key(e.config.ref_table)
      local d = key == 'bl_small' and 'Small' or key == 'bl_big' and 'Big' or 'Boss'
      local target = D.shared_target(key)
      D.next_target = target
      D.send({t = 'sel', d = d, k = key, g = num(target), n = G.GAME.round_resets.ante, rr = G.GAME.round + 1})
      D.log('SEL r=%d d=%s k=%s g=%s', G.GAME.round + 1, d, key, num(target))
    end
  end
  return orig_select_blind(e)
end

local orig_skip_blind = G.FUNCS.skip_blind
G.FUNCS.skip_blind = function(e)
  if D.coop() then
    if D.role == 'guest' and not D.net_action then
      send_wish('skip', G.GAME.blind_on_deck)
      return refuse(e, L('wish_sent'), 'skip')
    end
    if D.role == 'host' then
      D.wish = nil
      if not D.peer_ready() then
        return refuse(e, D.peer.phase == 'shop' and L('peer_shop') or L('wait_partner'), 'skip')
      end
      -- the guest follows the resulting blind states (sent from D.update)
      D.log('SKIP r=%d d=%s', G.GAME.round, G.GAME.blind_on_deck)
    end
    pcall(D.share_tag, e)
  end
  return orig_skip_blind(e)
end

local orig_reroll_boss = G.FUNCS.reroll_boss
G.FUNCS.reroll_boss = function(e)
  if D.coop() and D.role == 'guest' and not D.net_action then return refuse(e, L('host_picks'), 'reroll') end
  return orig_reroll_boss(e)
end

-- Guest: build the blind select screen only once the host's boss is known.
local function set_guest_boss(key)
  local rr = G.GAME.round_resets
  local old = rr.blind_choices.Boss
  if old == key then return end
  if old and G.GAME.bosses_used[old] and G.GAME.bosses_used[old] > 0 then
    G.GAME.bosses_used[old] = G.GAME.bosses_used[old] - 1
  end
  G.GAME.bosses_used[key] = (G.GAME.bosses_used[key] or 0) + 1
  rr.blind_choices.Boss = key
  D.log('guest boss %s -> %s', tostring(old), key)
end

-- Guest: use the host's boss for this ante when it is known. If it isn't yet, ask for
-- it and wait at most a second, then show the blinds with our own boss; the blind
-- screen adoption below swaps in the host's boss as soon as it arrives.
local orig_update_blind_select = Game.update_blind_select
function Game:update_blind_select(dt)
  if D.coop() and D.role == 'guest' and not G.STATE_COMPLETE then
    local hb = D.host_boss
    local ante = G.GAME.round_resets.ante
    if hb and hb.ante == ante then
      if D.blind_wait then D.log('BLINDWAIT off ante=%d', ante) end
      D.blind_wait = nil
      set_guest_boss(hb.key)
    else
      local now = love.timer.getTime()
      if not D.blind_wait then
        D.blind_wait = now
        D.log('BLINDWAIT on ante=%d', ante)
        D.send({t = 'need'})
      end
      if now - D.blind_wait < 1 then
        if self.buttons then self.buttons:remove(); self.buttons = nil end
        if self.shop then self.shop:remove(); self.shop = nil end
        return
      end
      D.log('BLINDWAIT off ante=%d own boss', ante)
      D.blind_wait = nil
    end
  end
  return orig_update_blind_select(self, dt)
end

-- Rebuild the blind screen in place from the current blind states (the same UIBox the
-- game builds in update_blind_select; create_UIBox_blind_select also recomputes
-- blind_on_deck from the states).
function D.rebuild_blind_select()
  if not G.blind_select then return end
  G.blind_select:remove(); G.blind_select = nil
  if G.blind_prompt_box then G.blind_prompt_box:remove(); G.blind_prompt_box = nil end
  G.blind_select = UIBox{
    definition = create_UIBox_blind_select(),
    config = {align = 'bmi', offset = {x = 0, y = G.ROOM.T.y + 29}, major = G.hand, bond = 'Weak'}
  }
  G.blind_select.alignment.offset.y = 0.8 - (G.hand.T.y - G.jokers.T.y) + G.blind_select.T.h
  G.blind_select.alignment.offset.x = 0
end

-- Blind screen alignment (both sides). Whoever is further along is right: the one
-- behind takes the other's ante, round, blind states and boss and redraws its blind
-- screen. If the partner is already inside a blind, we take the position just before
-- it and go into the same blind, so the two play it together (scores then merge
-- through 'tot'). Nobody is ever moved backwards. With equal progress the host's boss
-- counts (a boss reroll on the host).
-- Lines the two up after a continue from saves made at different moments, a crash of
-- one window, or a lost message. Skips get 3 s to sync first so they still hand out
-- their tags.
local function progress(round, st)
  local n = 0
  for _, d in ipairs({'Small', 'Big', 'Boss'}) do if st[d] == 'Skipped' then n = n + 1 end end
  return (round or 0) * 4 + n
end
-- 'Select' and 'Upcoming' both mean "still to play"; the game marks the next one Select
-- when it draws the screen
local function open(s) return (s == 'Select' or s == 'Upcoming') and 'open' or s end

local function align_blinds()
  local H = D.peer_sync
  local my_id = D.run_id()
  if not (H and H.inrun and my_id and H.id == my_id and H.ante and H.round) then D.mismatch_since = nil; return end
  if not (H.p == 'blind' or H.p == 'round' or H.p == 'shop') then D.mismatch_since = nil; return end
  if not (G.STATE == G.STATES.BLIND_SELECT and G.STATE_COMPLETE and G.blind_select and G.blind_prompt_box) then
    D.mismatch_since = nil; return
  end
  local locks = G.CONTROLLER.locks
  if locks.skip_blind or locks.boss_reroll or G.screenwipe or #D.actions > 0 or D.busy() then return end
  local rr = G.GAME.round_resets
  local st = rr.blind_states
  -- the partner's position as a blind screen: inside a blind = that blind still to pick
  local T = {ante = H.ante, round = H.round, Small = H.s, Big = H.b, Boss = H.x, boss = H.k}
  local join
  if H.p == 'round' then
    for _, d in ipairs({'Small', 'Big', 'Boss'}) do
      if T[d] == 'Current' then T[d] = 'Select'; join = d end
    end
    T.round = H.round - 1
  end
  local now = love.timer.getTime()
  local same = T.ante == rr.ante and T.round == G.GAME.round and open(T.Small) == open(st.Small)
    and open(T.Big) == open(st.Big) and open(T.Boss) == open(st.Boss)
  if same then
    D.mismatch_since = nil
    if D.role == 'guest' and H.p == 'blind' and T.boss and T.boss ~= rr.blind_choices.Boss then
      D.log('ADOPT boss %s->%s', tostring(rr.blind_choices.Boss), T.boss)
      set_guest_boss(T.boss)
      D.rebuild_blind_select()
      return
    end
    if join and (not D.join_t or now - D.join_t > 3) then
      -- the partner already plays the blind we are about to pick: go in with it
      D.join_t = now
      if T.boss and join == 'Boss' then set_guest_boss(T.boss) end
      local key = join == 'Small' and 'bl_small' or join == 'Big' and 'bl_big' or rr.blind_choices.Boss
      D.log('JOIN %s r=%d (partner already in it)', join, G.GAME.round + 1)
      G.GAME.blind_on_deck = join
      if D.role == 'guest' then
        D.actions[#D.actions + 1] = {t = 'sel', d = join, k = key, g = num(D.shared_target(key)), rr = G.GAME.round + 1}
      else
        G.FUNCS.select_blind({config = {ref_table = G.P_BLINDS[key]}})
      end
    end
    return
  end
  -- partner behind (or level): it catches up to us, we don't move back
  if T.ante < rr.ante or (T.ante == rr.ante and progress(T.round, T) <= progress(G.GAME.round, st)) then
    D.mismatch_since = nil; return
  end
  D.mismatch_since = D.mismatch_since or now
  if now - D.mismatch_since < 3 then return end
  D.mismatch_since = nil
  D.log('ADOPT ante %s->%s round %s->%s states %s/%s/%s->%s/%s/%s boss %s->%s (partner %s)', tostring(rr.ante),
    tostring(T.ante), tostring(G.GAME.round), tostring(T.round), tostring(st.Small), tostring(st.Big), tostring(st.Boss),
    tostring(T.Small), tostring(T.Big), tostring(T.Boss), tostring(rr.blind_choices.Boss), tostring(T.boss), H.p)
  if T.ante ~= rr.ante then
    rr.ante, rr.blind_ante = T.ante, T.ante
    rr.blind_tags.Small, rr.blind_tags.Big = get_next_tag_key(), get_next_tag_key()
  end
  G.GAME.round = T.round
  local function keep(s) return s == 'Select' and 'Upcoming' or s end
  st.Small, st.Big, st.Boss = keep(T.Small), keep(T.Big), keep(T.Boss)
  if T.boss then set_guest_boss(T.boss) end
  D.rebuild_blind_select()
end

-- Guest: skip whatever the host has skipped on this ante and we have not.
-- State based, so a missed or garbled message heals itself.
local function guest_skip_sync()
  local hs = D.host_bst
  if not hs or hs.ante ~= G.GAME.round_resets.ante then return false end
  -- test hook: pretend the skip arrived late
  if D.args.test_lag and love.timer.getTime() < hs.t + D.args.test_lag then return false end
  local states = G.GAME.round_resets.blind_states
  for _, d in ipairs({'Small', 'Big'}) do
    if hs[d] == 'Skipped' and states[d] ~= 'Skipped' and states[d] ~= 'Defeated' then
      local box = G.blind_select_opts and G.blind_select_opts[string.lower(d)]
      D.log('SKIP r=%d d=%s', G.GAME.round, d)
      G.GAME.blind_on_deck = d
      D.net_action = true
      if box then pcall(G.FUNCS.skip_blind, {UIBox = box}) end
      D.net_action = false
      return true
    end
  end
  return false
end

-- Guest: run the host's blind actions in order, one per safe moment.
local function guest_actions()
  local locks = G.CONTROLLER.locks
  if not (G.STATE == G.STATES.BLIND_SELECT and G.blind_select and G.blind_prompt_box) then return end
  if locks.skip_blind or locks.boss_reroll or G.screenwipe then return end
  if guest_skip_sync() then return end
  if #D.actions == 0 then return end
  local m = table.remove(D.actions, 1)
  -- a select for a round we are already past (we got into that blind first, or the
  -- message is from before a continue): drop it
  if m.t == 'sel' and m.rr and G.GAME.round >= tonumber(m.rr) then
    D.log('DROP sel r=%s d=%s (we are at round %d)', tostring(m.rr), tostring(m.d), G.GAME.round)
    return
  end
  G.GAME.blind_on_deck = m.d
  D.net_action = true
  if m.t == 'sel' then
    if m.d == 'Boss' then set_guest_boss(m.k) end
    D.next_target = tonumber(m.g)
    D.log('SEL r=%d d=%s k=%s g=%s', G.GAME.round + 1, m.d, m.k, m.g)
    pcall(G.FUNCS.select_blind, {config = {ref_table = G.P_BLINDS[m.k]}})
  elseif m.t == 'skp' then
    local box = G.blind_select_opts and G.blind_select_opts[string.lower(m.d)]
    D.log('SKIP r=%d d=%s', G.GAME.round, m.d)
    if box then pcall(G.FUNCS.skip_blind, {UIBox = box}) end
  end
  D.net_action = false
end

------------------------------------------------------------ play button
-- Tell the partner a hand is coming the moment Play is pressed: the score is only
-- known ~3 s later (after the cards are dealt into play). With 'pl' sent at scoring
-- time the partner could close its won round in between and miss this hand (found by
-- run_restart.ps1: host 230 vs guest 202).
local orig_play_cards = G.FUNCS.play_cards_from_highlighted
G.FUNCS.play_cards_from_highlighted = function(e)
  if D.active and in_run() and G.GAME.facing_blind then D.send({t = 'pl', r = G.GAME.round}) end
  return orig_play_cards(e)
end

local orig_can_play = G.FUNCS.can_play
G.FUNCS.can_play = function(e)
  orig_can_play(e)
  if D.coop() and (G.GAME.current_round.hands_left < 1 or G.GAME.chips - G.GAME.blind.chips >= 0) then
    e.config.colour = G.C.UI.BACKGROUND_INACTIVE
    e.config.button = nil
  end
end

------------------------------------------------------------ new run
-- Shared deck mode: only the host starts runs; the guest follows.
local function guest_locked()
  return D.active and D.role == 'guest' and D.shared_deck() and not D.net_action
end

local orig_setup_run = G.FUNCS.setup_run
G.FUNCS.setup_run = function(e)
  if guest_locked() then D.toast(L('host_starts')); return end
  return orig_setup_run(e)
end

local orig_start_run = G.FUNCS.start_run
G.FUNCS.start_run = function(e, args)
  if guest_locked() then D.toast(L('host_starts')); return end
  D.reset_run_state()
  local cont = args and args.savetext
  if D.active and not cont then D.send({t = 'new'}) end
  D.log('start_run continue=%s', tostring(cont ~= nil))
  return orig_start_run(e, args)
end

------------------------------------------------------------ save / continue
-- The co-op state of a run lives in G.GAME.duo, so it is in every save the game makes
-- (save_run serialises G.GAME) and comes back with "Continue":
--   id     run id, the same on both sides (the host makes it, the guest takes it)
--   rid, mine, theirs, target   score split of the current round
--   known  secret hands the partner found
local orig_save_run = save_run
function save_run()
  pcall(function()
    if not (G.GAME and in_run()) then return end
    local s = G.GAME.duo or {}
    G.GAME.duo = s
    local r = D.rounds[G.GAME.round]
    s.rid = G.GAME.round
    s.mine = r and (r.mine + (r.unsent or 0)) or 0
    s.theirs = r and r.theirs or 0
    s.target = r and r.target or nil
    local known = {}
    for h in pairs(D.peer_known or {}) do known[h] = true end
    s.known = known
  end)
  return orig_save_run()
end

local function restore_from_save()
  local s = G.GAME.duo
  if not (s and s.id) then
    G.GAME.duo = {id = D.new_id()}
    D.log('RESUME old save without co-op state, new id %s', G.GAME.duo.id)
    return
  end
  if s.rid then
    local r = D.R(s.rid)
    r.mine, r.theirs, r.target = s.mine or 0, s.theirs or 0, s.target
  end
  for h in pairs(s.known or {}) do D.peer_known[h] = true end
  if D.role == 'guest' then
    D.host_boss = {ante = G.GAME.round_resets.ante, key = G.GAME.round_resets.blind_choices.Boss}
  end
  D.log('RESUME id=%s round=%s ante=%s state=%s mine=%s theirs=%s', tostring(s.id), tostring(G.GAME.round),
    tostring(G.GAME.round_resets.ante), tostring(G.STATE), num(s.mine), num(s.theirs))
end

local orig_game_start_run = Game.start_run
function Game:start_run(args)
  if D.forced_back then
    self.GAME.viewed_back = Back(G.P_CENTERS[D.forced_back])
    D.forced_back = nil
  end
  orig_game_start_run(self, args)
  if args and args.savetext then
    restore_from_save()
    D.resumed_at = love.timer.getTime()
  else
    -- a new run: the guest takes the host's id, the host makes one
    G.GAME.duo = {id = D.pending_id or (D.role == 'guest' and D.peer_sync and D.peer_sync.inrun and D.peer_sync.id)
      or D.new_id()}
    D.pending_id = nil
    if D.args.test_tags then
      -- test: Charm Tag on the Small blind, and a Double Tag to start with
      G.GAME.round_resets.blind_tags.Small = 'tag_charm'
      G.E_MANAGER:add_event(Event({func = function() add_tag(Tag('tag_double')); return true end}))
    end
  end
  D.log('START deck=%s stake=%s id=%s continue=%s', G.GAME.selected_back.effect.center.key, tostring(G.GAME.stake),
    tostring(G.GAME.duo.id), tostring(args and args.savetext ~= nil))
  D.sent_sync = nil
  if args and args.savetext then D.send_tot(true) end
end

function D.saved_game()
  local ok, t = pcall(function()
    local raw = get_compressed(G.SETTINGS.profile .. '/save.jkr')
    return raw and STR_UNPACK(raw)
  end)
  return ok and t or nil
end
local function saved_id(t) return t and t.GAME and t.GAME.duo and t.GAME.duo.id end

-- Starting a run from code is only safe once the main menu is fully up: during the
-- splash the game's own menu setup still runs and left a continued run paused
-- (found by run_restart.ps1: the host resumed 2.5 s after start and never moved).
local function menu_ready()
  local now = love.timer.getTime()
  if G.STAGE == G.STAGES.MAIN_MENU and G.MAIN_MENU_UI and not G.screenwipe then
    D.menu_seen = D.menu_seen or now
    return now - D.menu_seen > 1.5
  end
  D.menu_seen = nil
  return false
end
-- same check with its own timer, for the language test
function D.lang_menu_ready()
  local now = love.timer.getTime()
  if G.STAGE == G.STAGES.MAIN_MENU and G.MAIN_MENU_UI and not G.screenwipe then
    D.lang_seen = D.lang_seen or now
    return now - D.lang_seen > 1.5
  end
  D.lang_seen = nil
  return false
end

local function find_challenge(id)
  if not id or id == '-' then return nil end
  for _, c in ipairs(G.CHALLENGES) do if c.id == id then return c end end
end

-- Guest: be in the host's run. Continue our own save of it if we have one, otherwise
-- (shared decks) start a new run with the host's deck; the blind screen adoption then
-- brings it to the host's ante and blinds.
local function guest_reconcile_run()
  local H = D.peer_sync
  if not (H and H.inrun and H.id ~= '-') or G.screenwipe then return end
  local now = love.timer.getTime()
  if now < (D.reconcile_t or 0) then return end
  local my_id = D.run_id()
  if my_id == H.id then return end
  if in_run() and not D.shared_deck() then
    -- own decks: the run we play is our side of the host's run
    G.GAME.duo.id = H.id
    D.log('JOIN own run to id=%s', H.id)
    return
  end
  if not in_run() and not menu_ready() then return end
  D.reconcile_t = now + 6
  local saved = D.saved_game()
  if G.OVERLAY_MENU then G.FUNCS.exit_overlay_menu() end
  if saved_id(saved) == H.id and not in_run() then
    D.log('RESUME follow id=%s', H.id)
    D.net_action = true
    G.FUNCS.start_run(nil, {savetext = saved})
    D.net_action = false
  elseif D.shared_deck() then
    if not G.P_CENTERS[H.dk] then D.log('ERR unknown deck %s', tostring(H.dk)); return end
    D.log('RUN follow id=%s deck=%s stake=%s challenge=%s (mine %s, save %s)', H.id, H.dk, tostring(H.sk),
      tostring(H.ch), tostring(my_id), tostring(saved_id(saved)))
    D.pending_id = H.id
    D.forced_back = H.dk
    D.net_action = true
    G.FUNCS.start_run(nil, {stake = H.sk or 1, challenge = find_challenge(H.ch), seed = D.args.seed})
    D.net_action = false
  elseif not D.own_start_told then
    D.own_start_told = true
    D.toast(L('own_start'))
  end
end

-- Host just (re)started and sits in the main menu while the guest is in a run: continue
-- our save of that run, once per connection (so going to the menu on purpose works).
local function host_reconcile_run()
  local P = D.peer_sync
  if D.auto_resume_tried or not (P and P.inrun) or in_run() or G.screenwipe then return end
  if not menu_ready() then return end
  D.auto_resume_tried = true
  local saved = D.saved_game()
  if saved_id(saved) == P.id then
    if G.OVERLAY_MENU then G.FUNCS.exit_overlay_menu() end
    D.log('RESUME auto id=%s', P.id)
    D.toast(L('resume'))
    G.FUNCS.start_run(nil, {savetext = saved})
  else
    D.log('RESUME none: guest id=%s save id=%s', tostring(P.id), tostring(saved_id(saved)))
    D.toast(L('other_run'))
  end
end

------------------------------------------------------------ round flow
-- Busy = an animation or effect is queued. The game keeps a few
-- non-blocking watcher events in the queue forever; those don't count.
function D.busy()
  for _, ev in ipairs(G.E_MANAGER.queues.base) do
    if ev.blocking ~= false then return true end
  end
  return false
end

local function idle()
  return G.STATE == G.STATES.SELECTING_HAND and G.STATE_COMPLETE and G.play and #G.play.cards == 0
    and not D.own_easing and not D.busy()
end
D.idle = idle

local function end_round_now(r, why)
  D.release_wait()
  r.ended = true
  D.log('force_end r=%d why=%s', G.GAME.round, why)
  G.STATE = G.STATES.NEW_ROUND
  G.STATE_COMPLETE = false
end

-- Own score has finished counting into the total: now tell the partner.
-- Always called before a round status goes out, so 'sc' arrives before 'st'.
function D.flush_score(rid)
  local r = D.R(rid)
  -- a hand that scored 0 (debuffed, The Flint) still goes out: it clears the partner's 'pl'
  if r.unsent == nil then return end
  r.mine = r.mine + r.unsent
  D.send({t = 'sc', r = rid, a = num(r.unsent)})
  D.log('FLUSH r=%d a=%s chips=%s mine=%s theirs=%s', rid, num(r.unsent), num(G.GAME.chips), num(r.mine), num(r.theirs))
  r.unsent = nil
end

local function round_update()
  local rid = G.GAME.round
  local r = D.R(rid)
  local now = love.timer.getTime()

  if D.own_easing and (G.GAME.chips == D.own_target or now - D.own_ease_t > 20) then
    D.own_easing = false
    D.flush_score(rid)
  end
  if D.want_tot and D.peer.phase == 'round' and D.peer.round == rid then
    D.want_tot = nil
    D.send_tot(true)
  end
  D.apply_tot()

  local s, S = G.STATE, G.STATES
  local in_round = s == S.SELECTING_HAND or s == S.DRAW_TO_HAND or s == S.HAND_PLAYED or s == S.PLAY_TAROT
  if in_round and r.pending ~= 0 and not D.own_easing and G.GAME.facing_blind then
    G.GAME.chips = G.GAME.chips + r.pending
    r.theirs = r.theirs + r.pending
    D.log('apply r=%d +%s chips=%s', rid, num(r.pending), num(G.GAME.chips))
    r.pending = 0
    local ui = G.HUD and G.HUD:get_UIE_by_ID('chip_UI_count')
    if ui then ui:juice_up() end
    play_sound('chips2', 1.1, 0.5)
  end

  -- Round over on this side (own hand won, or forced): tell the partner.
  if s == S.NEW_ROUND and not r.reported then
    r.reported = true
    D.own_easing = false
    D.flush_score(rid)
    local won = G.GAME.chips - G.GAME.blind.chips >= 0
    if not r.my_status then
      r.my_status = won and 'done' or 'out'
      D.send({t = 'st', r = rid, s = r.my_status})
    end
    D.log('RE r=%d chips=%s target=%s mine=%s theirs=%s won=%s', rid, num(G.GAME.chips),
      num(G.GAME.blind.chips), num(r.mine), num(r.theirs), tostring(won))
  end

  if s ~= S.SELECTING_HAND or r.ended or not idle() then return end
  local won = G.GAME.chips - G.GAME.blind.chips >= 0
  local out = G.GAME.current_round.hands_left < 1 or r.deck_out
  local status = won and 'done' or (out and 'out') or nil
  D.flush_score(rid)
  if status and r.my_status ~= status then
    r.my_status = status
    D.send({t = 'st', r = rid, s = status})
  end
  if not r.my_status then return end
  local ps = r.peer_status
  local peer_gone = D.peer.phase == 'over' or (D.peer.round and D.peer.round > rid and D.peer.phase ~= 'menu')
  -- partner not in this round at all (e.g. one side continued an older save): don't
  -- wait forever, the blind screen lines both up again afterwards
  local away = not (D.peer.phase == 'round' and D.peer.round == rid)
  if away and not r.peer_playing then r.away_since = r.away_since or now else r.away_since = nil end
  -- a partner that is behind us (continued an older save) comes into this blind on
  -- its blind screen (align_blinds / peer_ready): wait for it, up to two minutes
  -- (in the menu = restarting: it continues its save and comes back the same way)
  local behind = D.peer.phase == 'menu' or (D.peer.round and D.peer.round < rid and D.peer.phase ~= 'over')
  local peer_lost = r.away_since and now - r.away_since > (behind and 120 or 4)
  if behind and r.away_since then D.wait_text = L('wait_partner') end
  if (r.my_status == 'done' and ps) or (r.my_status == 'out' and ps == 'out') or peer_gone or peer_lost then
    end_round_now(r, 'peer=' .. tostring(ps) .. (peer_lost and ' away' or ''))
  else
    -- input stays free (jokers, consumables, run info); only Play is off (can_play)
    D.wait_text = r.my_status == 'done' and L('won_wait') or L('out_wait')
  end
end

function D.update(dt)
  D.net_update()
  if not G.STAGE then return end
  local now = love.timer.getTime()
  if D.role and now - (D.win_t or 0) > 2 then D.win_t = now; D.track_window() end

  -- No partner while out of hands (or won) in a round: finish the round as a solo game
  -- would, but only once co-op is off or the partner stayed away for 90 s. A crashed
  -- window comes back (restart, or the host reopens the guest) and continues its save;
  -- ending the round at once lost whole runs (found by run_restart.ps1).
  if D.active or not D.role then D.alone_since = nil end
  if not D.active and in_run() and G.STATE == G.STATES.SELECTING_HAND and G.STATE_COMPLETE then
    local r = D.rounds[G.GAME.round]
    local stuck = G.GAME.current_round.hands_left < 1 or G.GAME.chips - G.GAME.blind.chips >= 0 or (r and r.deck_out)
    if stuck and #G.play.cards == 0 and not D.busy() then
      if D.role then
        D.alone_since = D.alone_since or now
        D.wait_text = L('lost_conn')
      end
      if not D.role or now - D.alone_since > 90 then
        D.log('solo end r=%d (partner away %ds)', G.GAME.round, D.alone_since and math.floor(now - D.alone_since) or 0)
        D.alone_since, D.wait_text = nil, nil
        G.STATE = G.STATES.NEW_ROUND; G.STATE_COMPLETE = false
      end
    end
  end

  -- "Play together": a guest window may still be running from before (the host
  -- restarted). Give it a moment to reconnect before opening a second one.
  if D.launch_at and now > D.launch_at then
    D.launch_at = nil
    if D.active then D.log('launch skipped: a guest is already connected') else D.launch_guest() end
  end
  -- The guest window we opened is gone (crashed or closed) and doesn't come back:
  -- open it again; it continues the run by itself. Once per loss.
  if D.role == 'host' and D.launched_guest and not D.active and not D.launch_at then
    D.lost_at = D.lost_at or now
    if not D.relaunched and now - D.lost_at > 10 then
      D.relaunched = true
      D.log('RELAUNCH guest after %ds without it', math.floor(now - D.lost_at))
      D.launch_guest()
    end
  else
    D.lost_at = nil
  end

  if not D.active then return end
  local ph = phase()
  local rid = G.GAME and G.GAME.round or 0
  local ante = G.GAME and G.GAME.round_resets and G.GAME.round_resets.ante or 0
  local od = G.GAME and G.GAME.blind_on_deck or '-'
  local key = ph .. ':' .. rid .. ':' .. ante .. ':' .. od
  if key ~= D.sent_phase then
    D.sent_phase = key
    D.send({t = 'ph', p = ph, r = rid, a = ante, o = od})
  end
  D.send_sync(ph)
  if D.role == 'guest' then guest_reconcile_run() else host_reconcile_run() end
  if not in_run() then return end

  -- safety net: a run we continued must not stay paused with no menu open
  if D.resumed_at and now - D.resumed_at < 30 then
    if G.SETTINGS.paused and not G.OVERLAY_MENU and not G.screenwipe then
      D.paused_since = D.paused_since or now
      if now - D.paused_since > 3 then
        G.SETTINGS.paused = false
        D.paused_since = nil
        D.log('UNPAUSE after continue')
      end
    else
      D.paused_since = nil
    end
  end

  -- Blind select state with no blind screen: after continuing inside a pack that a tag
  -- opened on the blind screen, closing the pack returns to BLIND_SELECT with
  -- STATE_COMPLETE already set, so the game never draws the screen (found by
  -- run_restart.ps1, host killed while a Meteor pack from the partner's tag was open).
  -- Let the game build it again.
  if G.STATE == G.STATES.BLIND_SELECT and G.STATE_COMPLETE and not G.blind_select and not G.screenwipe
    and not D.busy() then
    D.noscreen_since = D.noscreen_since or now
    if now - D.noscreen_since > 2 then
      D.noscreen_since = nil
      D.log('REBUILD blind screen (state complete, no screen)')
      G.STATE_COMPLETE = false
    end
  else
    D.noscreen_since = nil
  end

  D.hands_update()
  D.run_pending_nbc()
  align_blinds()
  if D.role == 'guest' then
    guest_actions()
  elseif D.wish then
    -- show the guest's wish on our blind screen: pulse the button it pressed
    if ph ~= 'blind' or D.wish.r ~= G.GAME.round or now - D.wish.t > 30 then
      D.wish = nil
    elseif now - (D.wish.pulse or 0) > 0.8 then
      D.wish.pulse = now
      local ok, err = pcall(function()
        local opt = G.blind_select_opts and G.blind_select_opts[string.lower(D.wish.d)]
        if not opt then return end
        local els = {}
        if D.wish.a == 'sel' then
          els[1] = opt:get_UIE_by_ID('select_blind_button')
        else
          -- the skip button has no id (create_UIBox_blind_tag): find it by its button,
          -- and pulse the tag next to it ('tag_Small' / 'tag_Big') too
          els[1] = D.find_uie(opt.UIRoot, function(n) return n.config and n.config.button == 'skip_blind' end)
          els[2] = opt:get_UIE_by_ID('tag_' .. D.wish.d)
        end
        local found = 0
        for _, el in pairs(els) do el:juice_up(0.25, 0.25); found = found + 1 end
        if not D.wish.logged then
          D.wish.logged = true
          D.log('WISH pulse a=%s found=%d', D.wish.a, found)
        end
      end)
      if not ok then D.log('ERR wish pulse %s', tostring(err)) end
    end
  end
  if G.GAME.facing_blind or G.STATE == G.STATES.NEW_ROUND then round_update() end
end

------------------------------------------------------------ windows
-- The game keeps its own screen mode and monitor in settings.jkr (per window: the
-- second window has its own save identity) and restores them at start. Anything we do
-- to the window goes through G.SETTINGS.WINDOW too, so the game's video settings
-- always show the real mode.
local WIN_FILE = 'duo_window.txt'

-- Put the window on one half of the monitor it is on, windowed.
function D.arrange(side)
  if G.SETTINGS.WINDOW.screenmode ~= 'Windowed' then
    G.SETTINGS.WINDOW.screenmode = 'Windowed'
    G:save_settings()
  end
  local _, _, disp = love.window.getPosition()
  disp = disp or 1
  local dw, dh = love.window.getDesktopDimensions(disp)
  local w, h = math.floor(dw / 2), dh - 80
  local x = side == 'right' and w or 0
  love.window.updateMode(w, h, {fullscreen = false, x = x, y = 30, display = disp})
  if love.resize then love.resize(love.graphics.getDimensions()) end
  D.arranged = side
  D.log('arrange %s %dx%d at %d display %d', side, w, h, x, disp)
end

-- Last windowed position and size of this window: "x y w h display".
local function load_win()
  local s = love.filesystem.read(WIN_FILE)
  if not s then return end
  local x, y, w, h, d = s:match('(-?%d+) (-?%d+) (%d+) (%d+) (%d+)')
  if not x then return end
  return {x = tonumber(x), y = tonumber(y), w = tonumber(w), h = tonumber(h), d = tonumber(d)}
end

-- Called every couple of seconds while in co-op: remember where a windowed window sits.
function D.track_window()
  if G.SETTINGS.WINDOW.screenmode ~= 'Windowed' or love.window.getFullscreen() then return end
  local x, y, d = love.window.getPosition()
  local w, h = love.window.getMode()
  local s = string.format('%d %d %d %d %d', x, y, w, h, d or 1)
  if s ~= D.saved_win then
    D.saved_win = s
    love.filesystem.write(WIN_FILE, s .. '\n')
  end
end

-- Window placement at co-op start.
-- 'keep': fullscreen / borderless stays where the game put it (its own settings);
--   windowed goes back to its saved spot, or to a half when nothing is saved.
-- 'halves': always a half. A second window whose settings were just copied from the
--   first one also gets a half, so the two don't start on top of each other.
function D.place(side)
  local mode = G.SETTINGS.WINDOW.screenmode
  if D.cfg.layout ~= 'halves' and not D.fresh_profile then
    if mode ~= 'Windowed' then
      D.log('place keep %s display %s', mode, tostring(G.SETTINGS.WINDOW.selected_display))
      return
    end
    local s = load_win()
    if s and s.d <= love.window.getDisplayCount() then
      love.window.updateMode(s.w, s.h, {fullscreen = false, x = s.x, y = s.y, display = s.d})
      if love.resize then love.resize(love.graphics.getDimensions()) end
      D.log('place restore %dx%d at %d,%d display %d', s.w, s.h, s.x, s.y, s.d)
      return
    end
  end
  D.arrange(side)
end

-- Starts the second window directly (no cmd window flashing).
function D.launch_guest()
  D.launched_guest = true
  local dir = love.filesystem.getSourceBaseDirectory()
  local exe = dir .. '\\Balatro.exe'
  local params = '--disable-console --duo-guest --duo-window ' .. D.guest_side() .. ' --duo-layout ' .. D.cfg.layout
  if D.args.mod_dir then params = params .. ' --mod-dir "' .. D.args.mod_dir .. '"' end
  if D.args.bot then
    -- test runs: the second window plays as a bot too
    params = params .. ' --duo-bot --duo-seed GUESTSEED'
    if D.args.speed then params = params .. ' --duo-speed ' .. D.args.speed end
    if D.args.quit_ante then params = params .. ' --duo-quit-ante ' .. D.args.quit_ante end
  end
  D.log('launch %s %s', exe, params)
  local ok, err = pcall(function()
    local ffi = require('ffi')
    pcall(ffi.cdef, [[void* ShellExecuteA(void* hwnd, const char* op, const char* file,
      const char* params, const char* dir, int show);]])
    ffi.load('shell32').ShellExecuteA(nil, 'open', exe, params, dir, 1)
  end)
  if not ok then
    D.log('ShellExecute failed (%s), using start', tostring(err))
    os.execute(string.format('start "" /D "%s" "%s" %s', dir, exe, params))
  end
end

------------------------------------------------------------ input
-- One PC, two windows: mouse+keyboard drive the focused window, gamepads
-- are split between windows. pad_first = which window gets gamepad #1
-- ('guest' = second window, 'host' = first window); the other window gets #2.
function D.allow_background_pads()
  if D.bg_pads then return end
  local ok, err = pcall(function()
    local ffi = require('ffi')
    pcall(ffi.cdef, 'int SDL_SetHint(const char *name, const char *value);')
    local sdl = ffi.load('SDL2')
    sdl.SDL_SetHint('SDL_JOYSTICK_ALLOW_BACKGROUND_EVENTS', '1')
    -- the click that focuses a window also counts as a click in the game
    sdl.SDL_SetHint('SDL_MOUSE_FOCUS_CLICKTHROUGH', '1')
  end)
  D.bg_pads = ok
  D.log('background pads %s %s', tostring(ok), tostring(err or ''))
end

local function pad_index(joystick)
  local n = 0
  for _, j in ipairs(love.joystick.getJoysticks()) do
    if j:isGamepad() then
      n = n + 1
      if j == joystick then return n end
    end
  end
end

function D.pad_allowed(joystick)
  if not D.role or not joystick or joystick == (G.CONTROLLER and G.CONTROLLER.keyboard_controller) then return true end
  if type(joystick) ~= 'userdata' then return true end
  local idx = pad_index(joystick)
  if not idx then return true end
  local mine = (D.role == (D.cfg.pad_first or 'guest')) and 1 or 2
  return idx == mine
end

local function guard_pad(name)
  local orig = love[name]
  if not orig then return end
  love[name] = function(joystick, ...)
    if not D.pad_allowed(joystick) then return end
    return orig(joystick, ...)
  end
end
guard_pad('gamepadpressed')
guard_pad('gamepadreleased')
guard_pad('joystickaxis')

local function guard_mouse(name)
  local orig = love[name]
  if not orig then return end
  love[name] = function(...)
    if D.role and not love.window.hasFocus() then return end
    return orig(...)
  end
end
-- Only passing movement is ignored. A click on the other window works at once:
-- the game picks the clicked element from the last move, so move it there first.
local orig_mousemoved = love.mousemoved
guard_mouse('mousemoved')
local orig_mousepressed = love.mousepressed
love.mousepressed = function(x, y, ...)
  if D.role and orig_mousemoved then orig_mousemoved(x, y, 0, 0, false) end
  return orig_mousepressed(x, y, ...)
end
guard_mouse('wheelmoved')

------------------------------------------------------------ menu
-- Host (or not in co-op yet): connection buttons + settings.
-- Guest: status, the host's settings as text, and "turn off".
G.FUNCS.duo_menu = function(e)
  G.SETTINGS.paused = true
  local function btn(id, label, colour)
    return {n = G.UIT.R, config = {align = 'cm', padding = 0.06}, nodes = {
      UIBox_button{button = id, label = {label}, minw = 6, minh = 0.8, colour = colour, scale = 0.45}}}
  end
  local function text(t, scale)
    return {n = G.UIT.R, config = {align = 'cm', padding = 0.05}, nodes = {
      {n = G.UIT.T, config = {text = t, scale = scale or 0.4, colour = G.C.UI.TEXT_LIGHT, shadow = true}}}}
  end
  local pad_text = D.cfg.pad_first == 'host' and L('pad_host') or L('pad_guest')
  local nodes = {text(L('title'), 0.6)}
  if D.role == 'guest' then
    nodes[#nodes + 1] = text(D.active and L('guest_ok') or L('guest_wait'))
    nodes[#nodes + 1] = text(L('guest_settings'), 0.45)
    nodes[#nodes + 1] = text(L('pad') .. ': ' .. pad_text)
    nodes[#nodes + 1] = text(L('side') .. ': ' .. (D.cfg.host_side == 'left' and L('side_left') or L('side_right')))
    nodes[#nodes + 1] = btn('duo_shared_menu', L('shared_menu'), G.C.PURPLE)
    nodes[#nodes + 1] = btn('duo_off', L('disconnect'), G.C.RED)
  else
    if D.role == 'host' then
      nodes[#nodes + 1] = text(D.active and L('host_ok') or L('host_wait'))
      nodes[#nodes + 1] = btn('duo_off', L('disconnect'), G.C.RED)
    else
      nodes[#nodes + 1] = btn('duo_two_windows', L('two_windows'), G.C.BLUE)
      nodes[#nodes + 1] = btn('duo_host', L('host_only'), G.C.GREEN)
      nodes[#nodes + 1] = btn('duo_join', L('join'), G.C.ORANGE)
    end
    nodes[#nodes + 1] = btn('duo_shared_menu', L('shared_menu'), G.C.PURPLE)
    nodes[#nodes + 1] = create_option_cycle({label = L('pad'), scale = 0.8, w = 4,
      options = {L('pad_guest'), L('pad_host')}, current_option = D.cfg.pad_first == 'host' and 2 or 1,
      opt_callback = 'duo_set_pad'})
    nodes[#nodes + 1] = create_option_cycle({label = L('side'), scale = 0.8, w = 4,
      options = {L('side_right'), L('side_left')}, current_option = D.cfg.host_side == 'left' and 2 or 1,
      opt_callback = 'duo_set_side'})
    nodes[#nodes + 1] = create_option_cycle({label = L('layout'), scale = 0.8, w = 4,
      options = {L('layout_keep'), L('layout_halves')}, current_option = D.cfg.layout == 'halves' and 2 or 1,
      opt_callback = 'duo_set_layout'})
  end
  G.FUNCS.overlay_menu{definition = create_UIBox_generic_options({contents = nodes})}
end

-- Submenu: game rules, what is shared and what each player keeps.
-- Host edits them; the guest sees them as text.
local LEVELS = {'off', 'planets', 'all'}
G.FUNCS.duo_shared_menu = function(e)
  local function text(t, scale)
    return {n = G.UIT.R, config = {align = 'cm', padding = 0.05}, nodes = {
      {n = G.UIT.T, config = {text = t, scale = scale or 0.4, colour = G.C.UI.TEXT_LIGHT, shadow = true}}}}
  end
  local level_names = {L('levels_off'), L('levels_planets'), L('levels_all')}
  local cur_level = 2
  for i, v in ipairs(LEVELS) do if v == D.cfg.levels then cur_level = i end end
  local nodes = {text(L('shared_title'), 0.5)}
  if D.role == 'guest' then
    nodes[#nodes + 1] = text(L('guest_settings'), 0.45)
    nodes[#nodes + 1] = text(L('diff') .. ': x' .. tostring(D.cfg.diff))
    nodes[#nodes + 1] = text(L('deck_mode') .. ': ' .. (D.shared_deck() and L('deck_shared') or L('deck_own')))
    nodes[#nodes + 1] = text(L('levels') .. ': ' .. level_names[cur_level])
    nodes[#nodes + 1] = text(L('tags') .. ': ' .. (D.cfg.tags == 'own' and L('tags_own') or L('tags_both')))
    nodes[#nodes + 1] = text(L('hands') .. ': ' .. (D.cfg.hands == 'own' and L('hands_own') or L('hands_shared')))
  else
    local cur = 1
    for i, v in ipairs(D.DIFFS) do if v == D.cfg.diff then cur = i end end
    local opts = {}
    for i, v in ipairs(D.DIFFS) do opts[i] = 'x' .. tostring(v) end
    nodes[#nodes + 1] = create_option_cycle({label = L('diff'), scale = 0.8, w = 4, options = opts,
      current_option = cur, opt_callback = 'duo_set_diff'})
    nodes[#nodes + 1] = create_option_cycle({label = L('deck_mode'), scale = 0.8, w = 4,
      options = {L('deck_shared'), L('deck_own')}, current_option = D.shared_deck() and 1 or 2,
      opt_callback = 'duo_set_deck'})
    nodes[#nodes + 1] = create_option_cycle({label = L('levels'), scale = 0.8, w = 4,
      options = level_names, current_option = cur_level, opt_callback = 'duo_set_levels'})
    nodes[#nodes + 1] = create_option_cycle({label = L('tags'), scale = 0.8, w = 4,
      options = {L('tags_both'), L('tags_own')}, current_option = D.cfg.tags == 'own' and 2 or 1,
      opt_callback = 'duo_set_tags'})
    nodes[#nodes + 1] = create_option_cycle({label = L('hands'), scale = 0.8, w = 4,
      options = {L('hands_shared'), L('hands_own')}, current_option = D.cfg.hands == 'own' and 2 or 1,
      opt_callback = 'duo_set_hands'})
  end
  G.FUNCS.overlay_menu{definition = create_UIBox_generic_options({contents = nodes, back_func = 'duo_menu'})}
end
G.FUNCS.duo_set_levels = function(args)
  D.cfg.levels = LEVELS[args.to_key] or 'planets'
  D.save_cfg(); D.send_cfg()
end
G.FUNCS.duo_set_tags = function(args)
  D.cfg.tags = args.to_key == 2 and 'own' or 'both'
  D.save_cfg(); D.send_cfg()
end
G.FUNCS.duo_set_hands = function(args)
  D.cfg.hands = args.to_key == 2 and 'own' or 'shared'
  D.save_cfg(); D.send_cfg()
end
G.FUNCS.duo_set_layout = function(args)
  D.cfg.layout = args.to_key == 2 and 'halves' or 'keep'
  D.save_cfg(); D.send_cfg()
end
G.FUNCS.duo_set_diff = function(args)
  D.cfg.diff = D.DIFFS[args.to_key] or 1
  D.save_cfg(); D.send_cfg()
end
G.FUNCS.duo_set_deck = function(args)
  D.cfg.deck_mode = args.to_key == 2 and 'own' or 'shared'
  D.save_cfg(); D.send_cfg()
end
G.FUNCS.duo_set_pad = function(args)
  D.cfg.pad_first = args.to_key == 2 and 'host' or 'guest'
  D.save_cfg(); D.send_cfg()
end
G.FUNCS.duo_set_side = function(args)
  D.cfg.host_side = args.to_key == 2 and 'left' or 'right'
  D.save_cfg(); D.send_cfg()
  if D.arranged then D.arrange(D.cfg.host_side) end
end
G.FUNCS.duo_two_windows_go = function()
  D.start_host()
  D.place(D.cfg.host_side)
  -- a guest still running from before reconnects within a second; open a new one only if not
  D.launch_at = love.timer.getTime() + 2.5
end
G.FUNCS.duo_two_windows = function(e)
  G.FUNCS.duo_two_windows_go()
  G.FUNCS.exit_overlay_menu()
end
G.FUNCS.duo_host = function(e) D.start_host(); G.FUNCS.exit_overlay_menu() end
G.FUNCS.duo_join = function(e) D.start_guest(); G.FUNCS.exit_overlay_menu() end
G.FUNCS.duo_off = function(e) D.stop(); G.FUNCS.exit_overlay_menu() end

------------------------------------------------------------ overlay
local function status_lines()
  local lines = {}
  if D.role == 'host' then lines[#lines + 1] = D.active and L('host_ok') or L('host_wait')
  elseif D.role == 'guest' then lines[#lines + 1] = D.active and L('guest_ok') or L('guest_wait') end
  if D.coop() then
    if G.GAME.facing_blind then
      local r = D.R(G.GAME.round)
      lines[#lines + 1] = string.format(L('score'), number_format(G.GAME.chips), number_format(G.GAME.blind.chips),
        number_format(r.mine), number_format(r.theirs + r.pending))
    end
    if D.wait_text then lines[#lines + 1] = D.wait_text end
    if D.role == 'host' and D.wish and G.STATE == G.STATES.BLIND_SELECT then
      local key = G.GAME.round_resets.blind_choices[D.wish.d]
      local ok, name = pcall(localize, {type = 'name_text', set = 'Blind', key = key})
      lines[#lines + 1] = string.format(L(D.wish.a == 'sel' and 'wish_sel' or 'wish_skip'), ok and name or tostring(D.wish.d))
    end
    if G.STATE == G.STATES.BLIND_SELECT then
      if D.role == 'guest' then lines[#lines + 1] = D.blind_wait and L('boss_wait') or L('wait_host')
      elseif not D.peer_ready() then
        lines[#lines + 1] = D.peer.phase == 'shop' and L('peer_shop') or L('wait_partner')
      end
    end
    if D.peer.phase == 'over' then lines[#lines + 1] = L('peer_over') end
  end
  local now = love.timer.getTime()
  for i = #D.toasts, 1, -1 do
    if D.toasts[i].t < now then table.remove(D.toasts, i) end
  end
  for _, t in ipairs(D.toasts) do lines[#lines + 1] = t.text end
  return lines
end

function D.draw()
  if not D.role then return end
  local lines = status_lines()
  if #lines == 0 then return end
  local font = G.LANG and G.LANG.font and G.LANG.font.FONT
  if not font then return end
  love.graphics.push('all')
  love.graphics.origin()
  love.graphics.setCanvas()
  love.graphics.setShader()
  local sw = love.graphics.getWidth()
  -- the game's font is loaded large; aim for ~20px lines on a 900px wide window
  local px = math.max(14, math.min(26, sw / 45))
  -- a menu is open (CO-OP, options...): keep to the strip above it, so smaller and
  -- at most two lines (status + newest message); the menu's Back button is at the bottom
  if G.OVERLAY_MENU then
    px = px * 0.75
    if #lines > 2 then lines = {lines[1], lines[#lines]} end
  end
  local scale = px / font:getHeight()
  local lh = font:getHeight() * scale * 1.15
  local w = 0
  for _, l in ipairs(lines) do w = math.max(w, font:getWidth(l) * scale) end
  local x, y = (sw - w) / 2, 6
  love.graphics.setColor(0, 0, 0, 0.7)
  love.graphics.rectangle('fill', x - 12, y - 4, w + 24, lh * #lines + 8, 6, 6)
  love.graphics.setFont(font)
  love.graphics.setColor(1, 1, 1, 1)
  for i, l in ipairs(lines) do love.graphics.print(l, x, y + (i - 1) * lh, 0, scale, scale) end
  love.graphics.pop()
end

------------------------------------------------------------ bot (tests)
-- --duo-bot plays by itself: simple hands, leaves shops, host picks blinds.
D.botst = {next = 0}
local function bot_pick()
  local cards = {}
  for _, c in ipairs(G.hand.cards) do cards[#cards + 1] = c end
  local by = {}
  for _, c in ipairs(cards) do
    local id = c:get_id(); by[id] = by[id] or {}; table.insert(by[id], c)
  end
  local best
  for id, g in pairs(by) do
    if not best or #g > #best or (#g == #best and id > best.id) then best = g; best.id = id end
  end
  if best and #best >= 2 then
    local out = {}
    for i = 1, math.min(4, #best) do out[i] = best[i] end
    return out, false
  end
  table.sort(cards, function(a, b) return a:get_id() > b:get_id() end)
  local out = {}
  for i = 1, math.min(5, #cards) do out[i] = cards[i] end
  return out, true
end

function D.bot_update(dt)
  local st = D.botst
  local now = love.timer.getTime()
  if now < st.next then return end
  st.next = now + 0.4
  if not G.STAGE then return end
  if D.args.speed then G.SETTINGS.GAMESPEED = D.args.speed end
  G.SETTINGS.tutorial_complete = true
  if now - (st.dbg or 0) > 5 then
    st.dbg = now
    D.log('BOT stage=%s st=%s q=%d complete=%s wipe=%s paused=%s bs=%s overlay=%s resumed=%s', tostring(G.STAGE),
      tostring(G.STATE), #G.E_MANAGER.queues.base, tostring(G.STATE_COMPLETE), tostring(G.screenwipe ~= nil),
      tostring(G.SETTINGS.paused), tostring(G.blind_select ~= nil), tostring(G.OVERLAY_MENU ~= nil),
      tostring(D.resumed_at))
  end

  if G.STAGE == G.STAGES.MAIN_MENU then
    local follows = D.role == 'guest' and D.shared_deck()
    -- the partner is already in a run: the mod continues ours (host) or follows it (guest)
    local partner_in_run = D.peer_sync and D.peer_sync.inrun and not (D.role == 'guest' and not D.shared_deck())
    if not st.started and not follows and not partner_in_run and (D.active or not D.role) and not G.screenwipe and G.MAIN_MENU_UI
      and now > (st.menu_t or now + 3) then
      st.started = true
      if D.args.test_continue then
        D.log('BOT continue')
        G.FUNCS.start_run(nil, {savetext = D.saved_game()})
      else
        D.log('BOT start')
        D.forced_back = D.args.bot_deck
        G.FUNCS.start_run(nil, {stake = D.args.bot_stake or 1, seed = D.args.seed or ('DUO' .. (D.role or 'SOLO'))})
      end
    end
    st.menu_t = st.menu_t or now + 3
    return
  end
  local s, S = G.STATE, G.STATES
  if in_run() and s == S.GAME_OVER then
    if not st.over then st.over = now; D.log('BOT gameover ante=%d round=%d', G.GAME.round_resets.ante, G.GAME.round) end
    if now - st.over > 4 then love.event.quit() end
    return
  end
  -- a person clicks unlock / discovery popups away; the bot does it after a moment
  if in_run() and G.OVERLAY_MENU and s ~= S.GAME_OVER then
    st.overlay_t = st.overlay_t or now
    if now - st.overlay_t > 3 then
      st.overlay_t = nil
      D.log('BOT close overlay paused=%s', tostring(G.SETTINGS.paused))
      G.FUNCS.exit_overlay_menu()
    end
    return
  end
  st.overlay_t = nil
  if not in_run() or G.screenwipe or G.SETTINGS.paused then return end
  local quiet = not D.busy()

  if D.args.quit_ante and G.GAME.round_resets.ante > D.args.quit_ante and s == S.BLIND_SELECT then
    D.log('BOT quit ante=%d', G.GAME.round_resets.ante); love.event.quit(); return
  end
  if s == S.SELECTING_HAND and D.wait_text and st.wait_logged ~= G.GAME.round then
    -- out of hands / won and waiting: input must stay free
    st.wait_logged = G.GAME.round
    D.log('BOT waiting r=%d locked=%s text=%s', G.GAME.round,
      tostring(G.CONTROLLER.locks.duo_wait ~= nil or G.CONTROLLER.locked == true), D.wait_text)
  end
  if s == S.SELECTING_HAND and idle() and not D.wait_text then
    if G.GAME.current_round.hands_left < 1 then return end
    -- test: the guest plays slowly, so the host runs out of hands first
    if D.args.test_slow and D.role == 'guest' and now < (st.slow_t or 0) then return end
    st.slow_t = now + (D.args.test_slow or 0)
    local pick, weak = bot_pick()
    local discard = weak and G.GAME.current_round.discards_left > 0 and G.GAME.current_round.hands_played == 0
    if discard then
      table.sort(pick, function(a, b) return a:get_id() < b:get_id() end)
    end
    for _, c in ipairs(pick) do G.hand:add_to_highlighted(c, true) end
    if discard then G.FUNCS.discard_cards_from_highlighted(nil)
    else G.FUNCS.play_cards_from_highlighted(nil) end
    st.next = now + 1
  elseif s == S.ROUND_EVAL and quiet and G.round_eval then
    if not st.eval_t then st.eval_t = now end
    if now - st.eval_t > 1.5 then
      st.eval_t = nil
      G.FUNCS.cash_out({config = {button = 'cash_out'}})
      st.next = now + 1
    end
  elseif s == S.SHOP and quiet and G.shop and not G.CONTROLLER.locks.toggle_shop then
    if not st.shop_t then st.shop_t = now end
    -- test: use planets through the real use_card path (host: Pluto, then Black Hole; guest: Neptune)
    if D.args.test_planets and st.planet_round ~= G.GAME.round then
      st.planet_round = G.GAME.round
      st.planets = (st.planets or 0) + 1
      local list = D.role == 'guest' and {'c_neptune'} or {'c_pluto', 'c_black_hole'}
      local key = list[st.planets]
      if key then
        local card = create_card(key == 'c_black_hole' and 'Spectral' or 'Planet', G.consumeables, nil, nil, nil, nil,
          key, 'duotest')
        card:add_to_deck()
        G.consumeables:emplace(card)
        D.log('BOT use %s', key)
        G.FUNCS.use_card({config = {ref_table = card}})
        st.shop_t = now; st.next = now + 3
        return
      end
    end
    -- test: the guest "finds" Five of a Kind in its first shop; the host checks that
    -- Planet X is now in its own planet pool
    if D.args.test_secret and D.role == 'guest' and not st.secret then
      st.secret = true
      G.GAME.hands['Five of a Kind'].visible = true
      G.GAME.hands['Five of a Kind'].played = 1
      D.log('BOT secret Five_of_a_Kind')
    end
    if D.args.test_secret and D.role == 'host' and D.peer_known['Five of a Kind'] and not st.pool then
      st.pool = true
      local pool = get_current_pool('Planet')
      local found = false
      for _, k in ipairs(pool) do if k == 'c_planet_x' then found = true end end
      D.log('BOT pool planet_x=%s visible=%s', tostring(found), tostring(G.GAME.hands['Five of a Kind'].visible))
    end
    -- test: the guest lingers in the shop so the host clicks select too early, or the
    -- host lingers so the guest reaches the blind screen first
    local stay = 1 + (D.role == 'guest' and D.args.test_shop_lag or 0)
      + (D.role == 'host' and D.args.test_host_shop_lag or 0)
    if now - st.shop_t > stay then st.shop_t = nil; G.FUNCS.toggle_shop(nil); st.next = now + 1 end
  elseif (s == S.TAROT_PACK or s == S.PLANET_PACK or s == S.SPECTRAL_PACK or s == S.STANDARD_PACK
    or s == S.BUFFOON_PACK) and quiet and G.pack_cards then
    D.log('BOT pack skip state=%s', tostring(s))
    G.FUNCS.skip_booster(nil); st.next = now + 1
  elseif s == S.BLIND_SELECT and quiet and G.blind_select and D.role == 'guest' and D.args.test_wish then
    -- test: the guest presses a real button once per blind (skip on Small, select on the
    -- others); the host must see it
    local od = G.GAME.blind_on_deck
    local wkey = G.GAME.round .. od
    local opt = G.blind_select_opts and G.blind_select_opts[string.lower(od)]
    local skip = od == 'Small'
    local btn = opt and (skip and D.find_uie(opt.UIRoot, function(n) return n.config and n.config.button == 'skip_blind' end)
      or opt:get_UIE_by_ID('select_blind_button'))
    if btn and st.wished ~= wkey then
      st.wished = wkey
      D.log('BOT wish click r=%d d=%s a=%s', G.GAME.round, od, skip and 'skip' or 'sel')
      btn:click()
    end
  elseif s == S.BLIND_SELECT and quiet and G.blind_select and D.role ~= 'guest' then
    -- test: give the guest's wish time to arrive, then act
    if D.args.test_wish and D.role == 'host' and D.peer_ready() and not D.wish then
      local wkey = G.GAME.round .. G.GAME.blind_on_deck
      if st.wish_key ~= wkey then st.wish_key = wkey; st.wish_t = now end
      if now - st.wish_t < 5 then return end
    end
    if D.args.test_wish and D.wish then
      -- leave the wish on screen a moment (screenshot check), then act
      if not st.wish_seen_t or st.wish_seen_key ~= G.GAME.round .. G.GAME.blind_on_deck then
        st.wish_seen_t, st.wish_seen_key = now, G.GAME.round .. G.GAME.blind_on_deck
        D.log('BOT sees wish a=%s d=%s', D.wish.a, D.wish.d)
      end
      if now - st.wish_seen_t < 4 then return end
    end
    local od = G.GAME.blind_on_deck
    -- with --duo-test-shop-lag the host presses the real on-screen button (one_press),
    -- once too early while the guest shops, then again when the guest is ready
    local opt = G.blind_select_opts and G.blind_select_opts[string.lower(od)]
    local btn = D.args.test_shop_lag and opt and opt:get_UIE_by_ID('select_blind_button')
    if D.role == 'host' and not D.peer_ready() then
      if btn and D.peer.phase == 'shop' and st.early ~= G.GAME.round then
        st.early = G.GAME.round
        D.log('BOT early click r=%d', G.GAME.round)
        btn:click()
      end
      return
    end
    if od == 'Small' and G.GAME.round_resets.ante == (D.args.test_tags and 1 or 2) and not st.skipped then
      st.skipped = true
      G.FUNCS.skip_blind({UIBox = G.blind_select_opts.small})
    elseif btn then
      D.log('BOT click select r=%d disabled=%s', G.GAME.round, tostring(btn.disable_button == true))
      btn:click()
    else
      local key = G.GAME.round_resets.blind_choices[od]
      G.FUNCS.select_blind({config = {ref_table = G.P_BLINDS[key]}})
    end
    st.next = now + 1.5
  end
end

------------------------------------------------------------ main loop hooks
local orig_load = love.load
function love.load(...)
  orig_load(...)
  if D.args.window then
    local ok, err = pcall(D.place, D.args.window)
    if not ok then D.log('ERR place %s', tostring(err)) end
  end
  if D.args.guest then D.start_guest() elseif D.args.host then D.start_host()
  elseif D.args.two_windows then G.FUNCS.duo_two_windows_go() end
  D.log('loaded v%s socket=%s guest=%s host=%s bot=%s', D.VERSION, tostring(socket_ok),
    tostring(D.args.guest), tostring(D.args.host), tostring(D.args.bot))
  for i, j in ipairs(love.joystick.getJoysticks()) do
    D.log('joystick %d name=%s gamepad=%s', i, j:getName(), tostring(j:isGamepad()))
  end
end

-- Test (--duo-test-lang <code>): switch the game to that language, then show the CO-OP
-- menu, the "What is shared" submenu and a few toasts, logging LANGTEST lines so a
-- script can take screenshots.
D.langst = {stage = 0}
function D.lang_test()
  local st, now = D.langst, love.timer.getTime()
  local code = D.args.test_lang
  if st.stage == 0 then
    if not D.lang_menu_ready() then return end
    if G.SETTINGS.language ~= code then
      D.log('LANGTEST switch %s -> %s', tostring(G.SETTINGS.language), code)
      G.FUNCS.change_lang({config = {ref_table = G.LANGUAGES[code]}})
    end
    st.stage, st.t = 1, now
  elseif st.stage == 1 then
    if G.SETTINGS.language ~= code or not D.lang_menu_ready() then return end
    G.FUNCS.duo_menu()
    D.toast(string.format(L('wish_sel'), localize({type = 'name_text', set = 'Blind', key = 'bl_small'})))
    D.toast(string.format(L('peer_level'), localize('Flush', 'poker_hands'), 3))
    D.log('LANGTEST menu %s', code)
    st.stage, st.t = 2, now
  elseif st.stage == 2 and now - st.t > 3 then
    G.FUNCS.duo_shared_menu()
    D.toast(L('won_wait'))
    D.toast(L('other_run'))
    D.log('LANGTEST shared %s', code)
    st.stage, st.t = 3, now
  elseif st.stage == 3 and now - st.t > 3 then
    D.log('LANGTEST done %s', code)
    st.stage = 4
  end
end

local orig_update = love.update
function love.update(dt)
  orig_update(dt)
  local ok, err = pcall(D.update, dt)
  if not ok then D.log('ERR update %s', tostring(err)) end
  if D.args.test_lang then
    local ok3, err3 = pcall(D.lang_test)
    if not ok3 then D.log('ERR langtest %s', tostring(err3)) end
  end
  if D.args.bot then
    local ok2, err2 = pcall(D.bot_update, dt)
    if not ok2 then D.log('ERR bot %s', tostring(err2)) end
  end
end

local orig_draw = love.draw
function love.draw()
  orig_draw()
  pcall(D.draw)
end

D.reset_run_state()
