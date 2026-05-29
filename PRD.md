# PRD — Graviblocks (a Guideline Tetris-style game, for macOS)

> **Audience:** an executor LLM ("Agent 007") building this app one
> vertical slice at a time, driven by the 007-builder orchestrator.
> Every design decision is pre-resolved. **Do not invent behavior,
> values, timings, or libraries.** If something is unspecified, stop and
> ask the product owner.

---

## 0. Reading order

1. Read §1–§6 once, fully, before writing code.
2. Read **§7 (HTTP test API)** and **§8 (architectural invariants)**
   before *every* slice. The quality review enforces §8 mechanically;
   the feature check exercises §7.
3. Every behavior MUST be reachable from the HTTP test API and MUST obey
   the MVC contract (§8.14 + `.agent/skills/mvc-appkit.md`). A behavior
   reachable only by pressing a key is, for this project, untestable and
   therefore unbuilt.
4. **The engine is deterministic (§8.2, §8.17).** Same `(seed, mode,
   input+tick sequence)` ⇒ byte-identical board and state, on any
   machine. This is the property the feature check relies on. Never put
   wall-clock time or the system RNG into engine logic.

---

## 1. Product Overview

### 1.1 What we are building
A native macOS game named **Graviblocks**: a modern **Guideline-style
falling-block game** (10×20 playfield, 7 tetrominoes, SRS rotation with
wall kicks, 7-bag randomizer, hold, ghost piece, lock delay, hard/soft
drop, Guideline scoring with T-spins / back-to-back / combo). Two modes:
**Marathon** (endless, level rises) and **Sprint** (clear 40 lines as
fast as possible).

It has a **retro MSX / chiptune** look (chunky pixel-block cells, a
code-drawn bitmap font, retro palette) and **procedurally synthesized
SCC/Roland-style** music + SFX. Styling is otherwise native macOS.

### 1.2 In scope
- The full Guideline core (§5): SRS rotation + the standard wall-kick
  tables, 7-bag, hold, ghost, lock delay with move-reset cap, soft/hard
  drop, line clears, T-spin detection, scoring, combo, back-to-back.
- **Marathon** mode (level 1→, +1 per 10 lines, Guideline gravity curve,
  ends on top-out) and **Sprint** mode (40 lines, tick-counted timer).
- A mode-select menu, pause, game-over / finished screens, restart.
- Hold piece; a 5-deep next-piece preview; ghost piece.
- Per-mode persisted bests (Marathon: best score; Sprint: best time) in
  `UserDefaults`.
- Retro board + side panels (Hold / Next / score / level / lines / time)
  rendered with a code-defined bitmap font; no font asset files.
- Procedurally synthesized SCC/Roland-style music loop + SFX via
  `AVAudioEngine`, driven by engine-emitted `AudioEvent`s.
- An embedded localhost **HTTP test API** (§7) that seeds the RNG, steps
  ticks, injects inputs, reads the board + state, reads audio intent, and
  returns PNG screenshots.

### 1.3 Out of scope (deferred, §10)
Multiplayer / garbage / versus; online leaderboards; configurable
handling (DAS/ARR/key remap UI); replays; 180° rotation; alternate
randomizers; themes/skins; bundled audio assets (audio is synthesized);
custom app icon; gamepad input.

### 1.4 Success criteria
The game plays as a recognizable modern Tetris; and **every rule and
state is verifiable through the HTTP test API by seeding, inputting,
ticking, and asserting on the board grid, the state JSON, or a
screenshot** — deterministically and repeatably.

---

## 2. Tech Stack (locked, do not deviate)

| Item | Choice |
| --- | --- |
| Language | Swift 5.9+ |
| UI framework | AppKit. SwiftUI permitted for menu/HUD panels; the **board is AppKit** (`NSView` drawing). |
| Project gen | **XcodeGen** (`Project.yml`). The `.xcodeproj` is generated each build and git-ignored. |
| Build | `xcodegen generate && xcodebuild -scheme Graviblocks -configuration Debug -derivedDataPath build/ build` |
| Min macOS | 13.0 |
| Architecture | Universal (arm64 + x86_64) |
| Third-party deps | **None.** Standard library, AppKit, SwiftUI, CoreGraphics, `AVFoundation`, `Network.framework`. |
| HTTP server | Hand-rolled over `Network.framework` (`NWListener`). No web frameworks. |
| Audio | `AVAudioEngine` synthesis only (no audio asset files). |
| Entry point | Explicit `Graviblocks/main.swift` calling `NSApplication.shared.run()`. **No `@main`** (§8.1). |
| Window | Standard titled `NSWindow` with real traffic lights. |
| Bundle ID | `com.bimboware.graviblocks` |

---

## 3. Project Structure

Every user-visible feature is an `NSViewController` that owns its model,
its view, **and its HTTP routes** (§8.14, `.agent/skills/mvc-appkit.md`).
Routes live in an extension on the controller in the same file. **The
`Engine/` directory is pure Swift and MUST NOT `import AppKit`** (§8.2).

```
Graviblocks/
├── main.swift                          # NSApplication.shared.run()
├── AppDelegate.swift                   # instantiates AppController
│
├── App/
│   ├── AppController.swift             # /healthz, /shutdown, /screenshot
│   ├── MenuBuilder.swift               # macOS menu bar
│   └── TestAPI/
│       ├── TestAPIServer.swift         # NWListener HTTP listener
│       ├── TestAPIRouter.swift         # flat registry; controllers register
│       └── TestAPIRequest+Response.swift
│
├── Window/
│   ├── WindowController.swift          # /window/list
│   ├── WindowState.swift
│   ├── GraviblocksWindow.swift         # NSWindow subclass
│   └── RootView.swift                  # lays out board + side panels + overlays
│
├── Engine/                             # PURE Swift — NO AppKit, NO wall-clock, NO system RNG
│   ├── GameState.swift                 # the complete engine state value
│   ├── Engine.swift                    # tick(), apply(input:), spawn, lock, clearLines
│   ├── Tetromino.swift                 # the 7 pieces + 4 rotation states (cell coords)
│   ├── SRS.swift                       # spawn orientations + wall-kick tables (§5.3)
│   ├── Bag.swift                       # 7-bag generator over PRNG
│   ├── PRNG.swift                      # seedable deterministic xorshift64 (§5.2)
│   ├── Scoring.swift                   # line/T-spin/combo/back-to-back scoring (§5.7)
│   ├── Timing.swift                    # level→ticks/row table, lock delay, drop consts (§5.5)
│   └── AudioEvent.swift               # enum of events the engine emits (§6.3)
│
├── Game/
│   ├── GameController.swift            # /game/*  (new, input, tick, autorun, pause, state, board)
│   ├── BoardView.swift                 # renders grid + active piece + ghost (retro cells)
│   ├── SidePanelView.swift             # Hold / Next / score / level / lines / time
│   ├── OverlayView.swift               # menu / paused / game-over / finished overlays
│   ├── RetroFont.swift                 # code-defined 5×7 bitmap glyph table (§4.4)
│   └── GameClock.swift                 # 60 Hz driver: calls Engine.tick() + redraw ONLY
│
├── Audio/
│   ├── AudioController.swift           # /audio/*  (state, mute)
│   ├── Synth.swift                     # AVAudioEngine voices: SCC wavetable + Roland FM (§6.2)
│   ├── Sequencer.swift                 # plays Song note-data; maps AudioEvent → SFX
│   └── Song.swift                      # in-code note data (public-domain arrangement)
│
├── Menu/
│   └── MenuController.swift            # /menu/invoke (mode select, start, pause, restart)
│
├── Persistence/
│   └── HighScores.swift               # UserDefaults: best Marathon score, best Sprint ticks
│
└── Theme/
    ├── Metrics.swift                   # sizes, paddings (no controllers)
    └── Palette.swift                   # retro piece colors + UI palette
```

Do not create files outside this list without a controller home. Do not
add a top-level route (only the orchestrator routes `/healthz`,
`/shutdown`, `/screenshot` are top-level, §7.3).

---

## 4. Layout & Visual Specifications

Retro MSX aesthetic. Cells are solid pixel blocks with a 1px inner
bevel; rendering is crisp (no anti-aliasing on cell rects).

### 4.1 Window layout
```
┌───────────────────────────────────────────────┐  native title bar "Graviblocks"
│  ┌────────┐   ┌──────────────────┐  ┌────────┐ │
│  │  HOLD  │   │                  │  │  NEXT  │ │
│  │ [    ] │   │                  │  │ [ ]    │ │
│  └────────┘   │   PLAYFIELD      │  │ [ ]    │ │
│  ┌────────┐   │   10 × 20        │  │ [ ]    │ │
│  │ SCORE  │   │   cells          │  │ [ ]    │ │
│  │ LEVEL  │   │                  │  │ [ ]    │ │
│  │ LINES  │   │                  │  └────────┘ │
│  │ TIME   │   │                  │             │
│  └────────┘   └──────────────────┘             │
└───────────────────────────────────────────────┘
```
- Playfield centered; Hold + stats panel left; Next queue (5) right.
- Overlays (menu / paused / game-over / finished) draw centered on top of
  a dimmed board (`OverlayView`).

### 4.2 Metrics (`Theme/Metrics.swift`)
```swift
enum Metrics {
    static let cell: CGFloat = 28              // pixel size of one board cell
    static let cols = 10                       // visible columns
    static let visibleRows = 20                // visible rows
    static let bufferRows = 2                  // hidden spawn rows above visible
    static let boardInset: CGFloat = 12
    static let panelWidth: CGFloat = 6 * 28    // Hold / Next preview box widths
    static let nextCount = 5                   // pieces shown in the Next queue
    static let defaultWindowSize = NSSize(width: 760, height: 760)
}
```
- Internal grid is `cols × (visibleRows + bufferRows)` = 10×22. Rows
  `0..1` are the **hidden spawn buffer** (never rendered); rows `2..21`
  are the 20 visible rows. Coordinates are `(x: 0..9, y: 0..21)`, origin
  top-left, `y` increasing **downward**.

### 4.3 Piece colors (`Theme/Palette.swift`)
Standard Guideline hues, retro-saturated. Hex:
`I=#00E0E0  O=#E0E000  T=#A000E0  S=#00E000  Z=#E00000  J=#0040E0  L=#E08000`
- Empty cell `#101830` (deep blue-black); board border `#3050A0`;
  grid lines `#1A2040`; ghost = the piece color at 30% over the empty
  cell; locked garbage uses the piece's own color.
- UI text `#E0E0F0`; panel background `#080C18`; panel bevel light
  `#3050A0` / dark `#04060C`.

### 4.4 Retro bitmap font (`Game/RetroFont.swift`)
A **code-defined** 5×7 bitmap glyph table (no font files). Required
charset: `0-9 A-Z : . - space`. Each glyph is a `[UInt8]` row mask; the
renderer draws filled cells per set bit, scaled to an integer pixel size.
Used for all HUD/overlay text (`SCORE`, `LEVEL`, `LINES`, `TIME`,
`HOLD`, `NEXT`, `PAUSED`, `GAME OVER`, `CLEAR`, menu labels).

### 4.5 Board & piece rendering (`Game/BoardView.swift`)
- Draw the 10×20 visible grid; each filled cell is a solid color rect
  with a 1px lighter top/left bevel and 1px darker bottom/right.
- Draw the active piece, then the ghost (drop projection) behind it.
- Never anti-alias cell rects (§8.16-equivalent crispness).

---

## 5. Game Rules (the Guideline core)

All timing is in **integer ticks at 60 ticks/second**. Engine logic
references ticks only — never seconds or wall-clock (§8.2).

### 5.1 Pieces, spawn, coordinates
- 7 tetrominoes: `I O T S Z J L`. Each has 4 rotation states `0,R,2,L`
  (0 = spawn). Cell coordinates per state are defined in
  `Engine/Tetromino.swift` using the canonical SRS bounding boxes
  (I and O in a 4×4 box per SRS; J L S T Z in a 3×3 box).
- **Spawn:** piece appears in state `0`, horizontally centered (columns
  3–6 for I/O-area, 3–5 for 3-wide), with its lowest cells in the hidden
  buffer (rows 0–1) so it scrolls into view. If the spawn cells overlap
  any filled cell → **top-out** (game over for Marathon).

### 5.2 Randomizer (`Engine/Bag.swift`, `Engine/PRNG.swift`)
- **7-bag:** each bag is a permutation of all 7 pieces; refill+shuffle
  when empty; pull from the front. The Next queue shows the next 5.
- **PRNG:** a seedable deterministic `xorshift64` defined in
  `PRNG.swift`. Seeded via `/game/new {seed}` (§7.3). The shuffle is a
  Fisher–Yates using this PRNG. `SystemRandomNumberGenerator`,
  `arc4random`, `Int.random`, and `Date`-based seeds are **forbidden in
  the engine** (§8.2). Default seed when unspecified: `1`.

### 5.3 Rotation — SRS with wall kicks (`Engine/SRS.swift`)
On a rotate input, compute the rotated cells, then try the 5 kick
offsets in order; the first that fits is applied; if none fit, the
rotation is rejected. Offsets are `(dx, dy)` with `dy` **up-positive**
(the engine negates `dy` for the downward-`y` grid).

**J L S T Z** kick table:
```
0→R: (0,0) (-1,0) (-1,+1) (0,-2) (-1,-2)
R→0: (0,0) (+1,0) (+1,-1) (0,+2) (+1,+2)
R→2: (0,0) (+1,0) (+1,-1) (0,+2) (+1,+2)
2→R: (0,0) (-1,0) (-1,+1) (0,-2) (-1,-2)
2→L: (0,0) (+1,0) (+1,+1) (0,-2) (+1,-2)
L→2: (0,0) (-1,0) (-1,-1) (0,+2) (-1,+2)
L→0: (0,0) (-1,0) (-1,-1) (0,+2) (-1,+2)
0→L: (0,0) (+1,0) (+1,+1) (0,-2) (+1,-2)
```
**I** kick table:
```
0→R: (0,0) (-2,0) (+1,0) (-2,-1) (+1,+2)
R→0: (0,0) (+2,0) (-1,0) (+2,+1) (-1,-2)
R→2: (0,0) (-1,0) (+2,0) (-1,+2) (+2,-1)
2→R: (0,0) (+1,0) (-2,0) (+1,-2) (-2,+1)
2→L: (0,0) (+2,0) (-1,0) (+2,+1) (-1,-2)
L→2: (0,0) (-2,0) (+1,0) (-2,-1) (+1,+2)
L→0: (0,0) (+1,0) (-2,0) (+1,-2) (-2,+1)
0→L: (0,0) (-1,0) (+2,0) (-1,+2) (+2,-1)
```
**O** never kicks (single offset `(0,0)`).

### 5.4 Hold (`Engine/Engine.swift`)
- Hold swaps the active piece with the held piece (or stores it and
  spawns the next). After a hold, hold is **locked** until the active
  piece locks down (`canHold = false` until next lock). A held piece
  re-enters in spawn state `0`.

### 5.5 Gravity, drops, lock delay (`Engine/Timing.swift`)
- **Gravity:** the active piece falls one row every `G(level)` ticks.
  Table (ticks/row), Marathon levels:
  `L1:60 L2:48 L3:37 L4:28 L5:21 L6:16 L7:11 L8:8 L9:6 L10:4 L11:3 L12:2 L13+:1`.
  Sprint uses a fixed gravity of `L1` (60).
- **Soft drop:** while soft-drop is active, gravity interval becomes
  `max(1, G/20)`; each cell descended by soft drop scores +1 (§5.7).
  (Over the API, the discrete `softDrop` input moves the piece down one
  cell immediately and adds +1.)
- **Hard drop:** moves the piece straight down to the landing row,
  scores +2 per cell, and locks immediately.
- **Lock delay:** when a piece rests on the stack, a lock timer of **30
  ticks** counts down; locking commits the piece. A successful move or
  rotation that keeps the piece resting **resets** the timer, up to a cap
  of **15 resets**, after which the next rest locks immediately.
- **Spawn delay (ARE) = 0** and **line-clear delay = 0** (resolve within
  the tick) to keep timing deterministic and simple.

### 5.6 Line clears & top-out
- After a lock, full rows are cleared; rows above shift down. Cleared
  count drives scoring (§5.7), level (Marathon: `level = 1 +
  totalLines/10`), and the Sprint goal (40).
- **Top-out:** a newly spawned piece overlaps a filled cell → Marathon
  game over (`phase = .over`). Sprint has no level rise; reaching 40
  cleared lines → `phase = .finished` and the elapsed tick count is the
  result.

### 5.7 Scoring (`Engine/Scoring.swift`)
Per action, multiplied by current `level` unless noted:
- Single 100 · Double 300 · Triple 500 · Tetris 800.
- **T-spin** (detected by the 3-corner rule: last successful action was a
  rotation and ≥3 of the T's 4 diagonal corners are occupied; "mini" if
  the rotation used a non-standard kick and <2 front corners filled):
  T-spin no-lines 400 · mini 100 · T-spin Single 800 · Double 1200 ·
  Triple 1600.
- **Back-to-back:** consecutive Tetrises / T-spin line clears multiply
  the line component by **1.5** (`b2b` flag tracked across locks).
- **Combo:** `50 × comboCount × level` added per consecutive line-clear
  lock (`comboCount` increments while clears continue, resets on a
  no-clear lock).
- **Soft drop** +1/cell, **hard drop** +2/cell (not ×level).

### 5.8 Input model
The engine exposes one `apply(input:)` path used by **both** keyboard and
`/game/input` (§8.3). Discrete inputs:
`left, right, rotateCW, rotateCCW, softDrop, hardDrop, hold`.
- Keyboard handling (real play): `←/→` move with DAS=10 ticks, ARR=2
  ticks; `↓` soft drop (hold); `Space` hard drop; `↑` or `X` rotate CW;
  `Z` rotate CCW; `C`/`Shift` hold; `P`/`Esc` pause; `Enter` start/
  confirm; `R` restart. DAS/ARR are realized by the keyboard layer
  emitting discrete inputs on tick boundaries; the API issues discrete
  inputs directly (no DAS needed for tests).

### 5.9 State machine (`Engine/GameState.swift`)
`phase ∈ { menu, playing, paused, over, finished }`.
`menu` (mode select) → `playing` → `paused` ⇄ `playing` →
`over` (Marathon top-out) or `finished` (Sprint 40). From `over`/
`finished`, restart → `playing`; back → `menu`. Bests persist on entering
`over`/`finished` (§ Persistence).

---

## 6. Audio (synthesized, SCC/Roland style)

### 6.1 Principle
Audio is **event-driven and observable**: the engine emits typed
`AudioEvent`s (§6.3); `AudioController` plays them and exposes
`/audio/state` so the harness can assert the engine *requested* the right
sound on the right game event, without hearing the waveform. **Tests run
muted by default** (`/audio/mute {on:true}`); the engine never depends on
audio state (§8.16).

### 6.2 Synthesis (`Audio/Synth.swift`, `Sequencer.swift`, `Song.swift`)
- A small software synth on `AVAudioEngine` (an `AVAudioSourceNode`
  rendering samples). Voices: **SCC-style** band-limited wavetable
  channels and **Roland-style** simple 2-operator FM voices, mixed to a
  handful of channels (melody, harmony, bass, percussion-ish).
- `Song.swift` holds the music as **in-code note-event data** — an
  original arrangement of a **public-domain** folk melody (e.g.
  *Korobeiniki*) — that the `Sequencer` plays on a loop while
  `phase == .playing`. No audio asset files; nothing to license.
- SFX (move, rotate, lock, line-clear, tetris, level-up, hold,
  hard-drop, top-out) are short synthesized blips produced by the same
  synth.

### 6.3 Audio events (`Engine/AudioEvent.swift`)
The engine appends to an `audioEvents` list each tick (cleared after the
view/controller drains it). Cases:
`move, rotate, softDrop, hardDrop, lock, hold, lineClear(rows:Int),
levelUp, topOut, musicStart, musicStop`. The engine **only enqueues**
events (pure); `AudioController` drains and plays them on the main queue.

---

## 7. Testability (the HTTP test API)

### 7.1 Why
Headless, deterministic verification is the whole point. `osascript` /
`CGEvent` synthetic input silently no-ops without permission and reads as
"passed". Graviblocks' contract: **every behavior reachable via HTTP on
`127.0.0.1`, and gameplay reproducible from a seed + an input/tick
sequence.** The feature check uses HTTP only.

### 7.2 Enabling the API
- Binds when `GRAVIBLOCKS_TEST_API=1` is in the environment. Default off.
- Port is OS-chosen (`:0`) and written to
  `~/Library/Application Support/Graviblocks/test-api.port` (decimal,
  newline-terminated) **before** the listener accepts connections.
- Handlers run off the main queue but `DispatchQueue.main.sync` before
  touching the engine/AppKit (§8.12).
- **In test mode the 60 Hz auto-clock starts OFF.** The harness advances
  time explicitly with `/game/tick`. `/game/autorun {on:true}` enables
  real-time play (used for screenshots / manual poking).

### 7.3 Required endpoints
Organised by owning controller (`.agent/skills/mvc-appkit.md`). Every
route is `/<prefix>/<action>`; the only top-level routes are the three
orchestrator routes `/healthz`, `/shutdown`, `/screenshot`. JSON unless
noted; errors return `{"error":"..."}` with a 4xx/5xx.

#### App (`AppController`) — top-level orchestrator routes
| Method | Path | Body / Query | Response | Purpose |
|---|---|---|---|---|
| GET | `/healthz` | — | `{"ok":true}` | Readiness probe |
| POST | `/shutdown` | — | `{"ok":true}` | `NSApp.terminate(nil)` after responding |
| GET | `/screenshot` | `?region=window` (default) | `image/png` | contentView PNG (§7.6). Orchestrator calls with no query. |

#### Window (`WindowController`)
| Method | Path | Response | Purpose |
|---|---|---|---|
| GET | `/window/list` | `[{"id":"w1","title":"Graviblocks","isKey":true}]` | Window inventory |

#### Game (`GameController`)
| Method | Path | Body / Query | Response | Purpose |
|---|---|---|---|---|
| POST | `/game/new` | `{"mode":"marathon\|sprint","seed":1}` | `{"ok":true,"mode":"marathon","seed":1}` | Start a fresh game, seed the bag, phase→playing, auto-clock stays off in test mode |
| POST | `/game/input` | `{"action":"left\|right\|rotateCW\|rotateCCW\|softDrop\|hardDrop\|hold"}` | `{"ok":true}` | Apply one discrete input immediately via the shared `apply(input:)` path |
| POST | `/game/tick` | `{"n":1}` | `{"ok":true,"tick":123}` | Advance the engine by `n` ticks (gravity, lock delay, clears, spawns) |
| POST | `/game/autorun` | `{"on":true}` | `{"ok":true}` | Start/stop the 60 Hz auto-clock |
| POST | `/game/pause` | `{"on":true}` | `{"ok":true}` | phase ⇄ paused |
| GET | `/game/state` | — | see below | Full engine state mirror |
| GET | `/game/board` | — | `{"width":10,"height":20,"grid":["..........",...]}` | Visible board: 20 strings of 10 chars; `.`=empty, else piece letter |

`/game/state` shape:
```json
{
  "phase": "playing",
  "mode": "marathon",
  "seed": 1,
  "tick": 123,
  "level": 1, "lines": 0, "score": 0, "combo": 0, "backToBack": false,
  "elapsedTicks": 123,
  "active": {"type":"T","rotation":0,"cells":[[4,1],[3,2],[4,2],[5,2]]},
  "ghostCells": [[4,18],[3,19],[4,19],[5,19]],
  "hold": null, "canHold": true,
  "next": ["L","J","S","Z","O"],
  "lockTimer": 0, "lockResets": 0,
  "topOut": false
}
```
Coordinates are grid cells `(x,y)`, origin top-left, `y` down; `active`/
`next`/`hold` use **internal** coords (including the 2 hidden rows);
`/game/board` returns only the 20 **visible** rows.

#### Audio (`AudioController`)
| Method | Path | Body | Response | Purpose |
|---|---|---|---|---|
| GET | `/audio/state` | — | `{"muted":true,"lastEvent":"lineClear","counts":{"lock":3,"lineClear":1,...}}` | Audio intent mirror (lets probes assert the engine emitted the right event) |
| POST | `/audio/mute` | `{"on":true}` | `{"ok":true}` | Mute/unmute (tests mute) |

#### Menu (`MenuController`)
| Method | Path | Body | Response | Purpose |
|---|---|---|---|---|
| POST | `/menu/invoke` | `{"path":["Game","New Marathon"]}` | `{"ok":true}` | Invoke a macOS menu item by title path. Covers New Marathon / New Sprint / Pause / Restart. |

New controllers MAY add prefixes; new behavior MUST belong to a
controller — never a top-level route.

### 7.4 Per-issue contract
Each `slice` issue body carries an `acceptance:` JSON block of HTTP
probes. Example — "a hard-dropped O locks at the bottom-left after moving
left" (deterministic, seed-pinned):
```json
{
  "acceptance": [
    {"step": "spawn-and-harddrop",
     "calls": [
       {"method":"POST","path":"/game/new","body":{"mode":"marathon","seed":1}},
       {"method":"GET","path":"/game/state","expect":{"phase":"playing"}},
       {"method":"POST","path":"/game/input","body":{"action":"hardDrop"}},
       {"method":"GET","path":"/game/state","expect":{"score":2,"canHold":true}}
     ]}
  ]
}
```
The feature check fails the issue if any `expect` assertion fails.
(Array responses like `/window/list` and string-array `grid` are matched
with order-independent containment for arrays and key-subset for objects.)

### 7.5 Security
Binds only to `127.0.0.1`, no auth, opt-in via `GRAVIBLOCKS_TEST_API=1`
(an env var, not a build flag), so shipped binaries stay inert by default.

### 7.6 Self-screenshot
`/screenshot` renders the key window's `contentView` to PNG using
**in-process drawing only**:
```swift
let view = win.contentView!
let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds)!
view.cacheDisplay(in: view.bounds, to: rep)
let png = rep.representation(using: .png, properties: [:])!
```
It MUST NOT call `CGWindowListCreateImage`, `CGDisplayCreateImage`,
`NSScreen` grabs, or `screencapture` (all TCC-gated, degrade to no-op).
Must work the moment `GRAVIBLOCKS_TEST_API=1` is set, no prompts.

---

## 8. Architectural invariants

The code-quality review uses this list as its checklist; any violation
blocks the PR.

### 8.1 Entry point
Explicit `Graviblocks/main.swift` constructs `NSApplication.shared`,
assigns the delegate, calls `setActivationPolicy(.regular)`, and
`app.run()`. `@main` on an `NSApplicationDelegate` is forbidden.

### 8.2 Deterministic engine (the headline rule)
`Engine/` is pure Swift and MUST NOT `import AppKit`/`SwiftUI`/`AVFoundation`.
It MUST NOT read wall-clock time (`Date`, `CACurrentMediaTime`,
`DispatchTime`) or use the system RNG (`SystemRandomNumberGenerator`,
`arc4random`, `.random(in:)`). All timing is in integer ticks; all
randomness flows through the seeded `PRNG`. A PR that breaks this fails
review.

### 8.3 One input path / clock-render separation
Keyboard input and `/game/input` both funnel through the single
`Engine.apply(input:)`. `GameClock` (the 60 Hz timer) only calls
`Engine.tick()` and requests a redraw — it contains no game logic. The
board view renders state; it does not mutate the engine.

### 8.4 Image loading
`NSImage(imageLiteralResourceName:)` is forbidden. Use failable
`NSImage(named:)` with a non-trapping fallback. (The retro font is drawn,
not loaded.)

### 8.5 Callback re-entrancy
A method that "sets phase / selects mode / sets the active piece" updates
state only; it MUST NOT re-emit the user-action callback used to request
that same change (no notification feedback loops).

### 8.6 Window
Standard titled `NSWindow` with real traffic lights, title `Graviblocks`.
Any `.borderless` subclass (overlays should be views, not windows) must
override `canBecomeKey`/`canBecomeMain`.

### 8.7 No hidden I/O
The only persistence is `UserDefaults` (high scores). The only network
listener is the test server (§7), bound to loopback and gated by the env
var. No other file or network I/O.

### 8.8 Force-unwrap discipline
`try!`, `as!`, and `!`-on-optionals are forbidden except: `NSScreen.main`
(guard + fallback); `URL(string:)` of compile-time literals; the
`bitmapImageRepForCachingDisplay`/`representation(using:)` pair in §7.6.

### 8.9 Test API parity
Every PR adding user-visible behavior MUST extend the owning controller's
routes so the behavior is reachable and assertable via HTTP. A new rule
with no probe path fails review.

### 8.10 Silent failure
`catch { /* ignore */ }` is forbidden. Errors propagate or surface an
`NSAlert` on the main queue.

### 8.11 Notifications & observers
Closures stored by `NotificationCenter` capture `self` weakly.

### 8.12 Main-queue dispatch from background
Test API handlers run on a background queue; touching the engine or
AppKit goes through `DispatchQueue.main.sync`.

### 8.13 Self-screenshot only
`/screenshot` uses only the in-process path in §7.6. Any
`CGWindowListCreateImage`/`CGDisplayCreateImage`/`screencapture`/TCC-gated
API is a blocker.

### 8.14 Controller owns its routes (MVC)
Every user-visible feature lives in an `NSViewController` under
`Graviblocks/<Feature>/<Name>Controller.swift`, conforming to
`TestAPIControllerRoutes` and registering its routes in `viewDidLoad`.
Route handlers live in an extension on the controller in the same file —
never a shared routes file. Views MUST NOT reference `TestAPIRouter`/
`URLSession`/HTTP types. Models (the engine) MUST NOT `import AppKit`.
Top-level routes forbidden except `/healthz`, `/shutdown`, `/screenshot`.

### 8.15 SRS correctness
Rotation uses the exact spawn orientations and wall-kick tables in §5.3.
Hard-coding ad-hoc rotation offsets instead of the tables is a failure.

### 8.16 Audio is event-driven & observable
The engine only enqueues `AudioEvent`s (§6.3); `AudioController` plays
them and exposes `/audio/state`. Audio uses synthesis only (no asset
files); the engine never imports `AVFoundation` or depends on audio
state.

### 8.17 Determinism guarantee
For a fixed `(seed, mode, sequence of /game/input and /game/tick calls)`,
`/game/state` and `/game/board` MUST be identical across runs and
machines. This is the property the feature check relies on; preserve it.

---

## 9. The orchestrator's contract
(Informational; not implemented by coding agents.)
- Issues are labelled `slice`, numbered `S1`, `S2`, …
- `S1` ≈ "app launches via `main.swift`, shows the window with an empty
  10×20 board, `GET /healthz` → 200, `GET /window/list` → one entry,
  `GET /screenshot` → a PNG."
- `next-issue` reads §1–§6 + closed slices to propose the next smallest
  vertical slice; each carries an `acceptance:` block (§7.4) and extends
  the test API (§8.9). Good early slices: empty board render → spawn a
  seeded piece → gravity on tick → left/right move → SRS rotate → hard
  drop + lock → line clear + score → hold → ghost → next queue → level/
  gravity → top-out → Sprint mode + timer → menu/pause/restart → retro
  font HUD → audio events + synth.
- Each issue cycles `code-agent → xcodebuild → feature-test →
  quality-review`; failure bumps `attempt:N`; at the cap it hands off for
  human review.

---

## 10. Out of v1, deferred
Multiplayer / versus / garbage; online leaderboards; replays; in-app
handling config & key remapping; 180° rotation and alternate kick sets;
alternate randomizers; Ultra (2-min) and other modes; themes/skins;
bundled audio assets; gamepad input; custom app icon.

End of PRD.
