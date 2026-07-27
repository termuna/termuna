# Changelog

All notable changes to the Termuna desktop app are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versioning: [SemVer](https://semver.org/) once we hit 0.2 (M2).

## [Unreleased]

## [0.1.0] - 2026-07-27

First public early-access release: the Windows installer and Linux
build on [github.com/termuna/termuna](https://github.com/termuna/termuna/releases).
Everything below shipped in it.

### Fixed — dock launch spinner no longer hangs for ~a minute (Linux)
- The GNOME/Ubuntu dock kept showing the "launching" cursor for up to a
  minute after Termuna's window was already visible. iced/winit never
  completes X11 startup-notification (no `_NET_STARTUP_ID` on the window,
  no completion message), so with `StartupNotify=true` the launcher waited
  out GNOME's whole startup-sequence timeout. Set `StartupNotify=false` in
  the desktop entry; the window appears instantly so no launch feedback is
  needed, and `StartupWMClass` still groups the window under the icon.

### Fixed — shared sessions no longer tear the terminal
- When a session was open in more than one viewer (e.g. the desktop app
  and the web viewer) at different window sizes, the PTY size flapped
  between them and the TUI (a shell full-screen app, an agent) drew for
  one size while a mirror rendered another — garbled, misaligned output.
  The host now reconciles viewer sizes tmux-style (smallest-wins) and
  publishes the authoritative grid size in the layout snapshot; every
  mirror renders exactly that grid and letterboxes any extra window
  space, so the two never disagree. A web viewer's size stops constraining
  the terminal shortly after its tab closes (size heartbeat + TTL), so the
  desktop reclaims full width. Wire-compatible (the size rides the existing
  encrypted layout snapshot; the relay is unchanged).

### Fixed — all live sessions mirror to the cloud, not just the newest
- Cloud bridge: a session's mirror is now self-healing. Previously the
  "bridge already started" latch was never released and the bridge task
  returned on a transient broadcast-channel close, so a mirror that
  stopped for any reason was never restarted — over time only the most
  recently started session stayed live in the cloud even though several
  were live locally. The bridge now reconnects while the session is live
  and releases the latch when it truly stops.

### Changed — desktop chat text is natively selectable (plain, no button)
- Desktop agent chat: every message is now a read-only editor, so you
  can drag to highlight any part and Ctrl+C to copy it — no "select"
  button, no per-message copy button. Markdown is stripped to clean
  plain text (no raw ** # ` or link syntax); iced can't both render
  markdown and allow selection, so on desktop we chose selection. (The
  web viewer keeps rendered markdown AND native selection.)


### Added — select part of a chat message; compaction shows for any provider
- Desktop chat: each message has a "select" toggle that turns it into a
  read-only editor so you can highlight and copy just part of it
  (Ctrl+C) — markdown stays for reading, selection on demand. Web chat
  text is natively selectable (the per-message copy button is gone).
- Compaction now shows a "⟳ conversation compacted" divider for any
  provider: detected from the continuation-summary preamble as well as
  Claude's /compact command.


### Fixed — slash menu typing; web chat text is selectable
- Typing after "/" in the chat composer now works: the command menu
  floats over the composer (as a constant overlay layer) instead of
  reflowing the layout, which was dropping input focus after the first
  character. It filters live as you type.
- Web chat: message text is selectable — select any part and copy it
  natively; the per-message copy button is gone.


### Added — /compact (and slash commands) show in the chat
- Running `/compact` now draws a "⟳ conversation compacted" divider in
  the chat lane (and `/clear` a "conversation cleared" one); other local
  slash commands show a muted "▸ /command" marker. Detected from the
  agent's transcript (system/local_command records) — earlier the chat
  ignored these entirely. Desktop and web.


### Changed — working directory uses a native folder picker
- In the "start agent session" chooser, the working-directory field is
  now a click target that opens the native folder picker, prefilled at
  the current path.


### Changed — nicer "start agent session" chooser + directory ask
- The open chooser got a visual pass (glyph + title + description cards,
  subtle shadow, rounded) and now asks for a working directory when you
  start a NEW agent session — resuming a past conversation keeps its own
  folder, so it skips the field.


### Changed — cleaner picker: agents screen, scroll, copy feedback
- The agents screen dropped the model chips and directory input (they
  used the CLI defaults anyway); "continue a conversation" entries are
  now two-line cards — prompt on top, a muted "provider · folder · when"
  line below — so the list is far easier to scan.
- The picker's scrollbar no longer clips the row controls (rename/kill,
  copy link): the scroll area reserves a right gutter on every screen.
- The chat copy button flashes "copied" in place after a click
  (desktop and web).


### Added — MCP server management (picker "mcp servers")
- A new picker section lists, adds, and removes the MCP servers your
  agents use, per provider (Claude Code, Codex, Gemini) — reading and
  writing each provider's own config (`~/.claude.json`,
  `~/.codex/config.toml`, `~/.gemini/settings.json`) and preserving
  everything else in those files. Add a stdio server (command + args)
  or a remote one (URL). Daemon-side (`McpList`/`McpAdd`/`McpRemove`)
  so the web can reuse it later.


### Added — command palette (Ctrl/Cmd+K)
- A fuzzy command palette opens from anywhere with Ctrl/Cmd+K: jump to
  a session by name, start a local or agent session, open connections
  or settings, and (in a session) switch chat/terminal, new tab, or
  back to the picker. Arrow keys + Enter, Esc closes.


### Added — agent chat composer: slash menu + copy
- Typing "/" in the chat composer opens a menu of the provider's common
  commands (/compact, /clear, /model, /cost, /status…) — pick one to
  drop it in. Every assistant (and user) message has a quiet copy
  button. Desktop and web.


### Added — agent chat shows tool activity, thinking, and token use
- The chat lane is no longer just text: each tool call renders a card
  with its key argument (bash command, file path, grep pattern) and a
  monospace detail block; **Edit/Write show a +/- diff**; tool results
  appear as muted "⤷ result" blocks (clipped). Reasoning shows as a
  muted "thinking" line. A running **token count** sits in the chat
  header. Desktop and web.


### Fixed — agent chat kept up with compaction; less noise
- The chat lane no longer freezes when the agent conversation is
  compacted or "resumed from summary": Claude Code rolls to a new
  session file at that point, and the daemon now FOLLOWS the newest
  transcript in the session's directory instead of staying pinned to
  the launch file. A `/compact` now shows a "⟳ conversation compacted"
  marker followed by the summary.
- The chat drops CLI machinery that isn't a human turn — background-agent
  task-notifications and local slash-command echoes no longer appear as
  message bubbles.


### Added — rich replies + images in the agent chat
- Assistant replies in the agent chat (desktop and web) now render as
  **markdown** — headings, bold, lists, links, and code blocks — instead
  of raw asterisks and backticks.
- You can hand the agent an image from the chat: **Ctrl/⌘+V pastes an
  image straight from the clipboard** (desktop and web), or use the "+"
  button. On the desktop the pasted image is saved locally and its path
  drops into the composer — visible and editable — so you see it worked;
  on the web/mobile viewer it travels E2E-encrypted to the host (new
  `AgentAsset` frame, ≤12 MiB, relay sees only ciphertext) which saves
  it and references it to the agent.
- The chat attach control is a quiet monochrome "+" (was a color emoji
  that clashed with the terminal look).

### Added — desktop agent chat UI + open-as-chat/terminal choice
- Opening an agent session (from a session row, "start agent session",
  or "continue a conversation") now asks how you want to work with it:
  **Chat** — a readable conversation view with message bubbles, built
  from the agent's own transcript, with a composer that types into the
  live agent — or **Terminal**, the agent's full TUI. Both drive the
  same session; a ✳/⌗ button flips between them at any time.
- Agent CLI detection now also looks in the usual user install spots
  (`~/.local/bin`, nvm/fnm/volta/bun node dirs, Homebrew) so Codex,
  Gemini, etc. are recognized even when the daemon's PATH is narrower
  than your shell's — no more false "not installed".
- The provider chips filter the "continue a conversation" list; Codex
  conversation titles skip the injected environment/AGENTS.md preamble
  and show the real first prompt.

### Added — structured agent conversation mirrored to viewers
- For agent sessions the daemon tails the agent CLI's own transcript
  (Claude Code JSONL under `~/.claude/projects`, Codex rollouts) and
  mirrors complete lines as sequenced, E2E-encrypted `AgentEvent`
  frames. The web viewer turns them into a readable chat lane (✳
  button) beside the terminal — the phone-friendly way to follow an
  agent. Backfills recent history on attach; the relay sees only
  ciphertext.

### Added — "needs input" attention on sessions
- The daemon watches every pane's output for a terminal bell (outside
  escape sequences, after 10s of input silence) or an explicit OSC
  9/777 notification — the signals agents and long builds emit when
  they want you. The session flips to "● needs input" in the picker
  (amber, refreshed automatically) and an additive `Attention` frame
  reaches viewers and the cloud relay, which can fan it out as a push
  notification to your phone. Typing anything stands it down.

### Added — AI agent sessions (picker "agents" screen)
- New "agents" section in the picker: start a Claude Code, Codex,
  Gemini, Cursor, or OpenCode session with a model picker and working
  directory, or continue a past conversation — the daemon discovers
  resumable sessions in the providers' own transcript stores
  (`~/.claude/projects`, `~/.codex/sessions`) and relaunches them with
  the right resume flags. Uninstalled CLIs show dimmed with an install
  hint.
- An agent session is an ordinary Termuna session whose first pane
  runs the agent's TUI: it survives GUI kills, mirrors E2E to the web
  viewer and phones, and resurrects after a daemon restart straight
  back into its conversation (`--resume`/`--continue`/
  `codex resume --last`).
- All agent knowledge lives in the daemon (`ListAgents`,
  `ListAgentSessions`, `CreateSession{agent}` over local IPC), so the
  web dashboard and future mobile apps can offer the same screen.
- Sessions hosting an agent carry a `✳ provider` badge in the picker.

### Added — daemon health indicator
- The picker sidebar shows the mux daemon's state: teal dot with
  version and uptime when healthy, a warning when the daemon runs an
  older binary than the app (restart to update), red "daemon offline"
  when unreachable. Backed by a new local-IPC `Status` request
  (pid, version, uptime, session counts), polled every 5s while the
  picker is visible.

### Added — about tab in settings
- Settings gained an "about" tab: wordmark, version + platform, what
  Termuna is, links to termuna.com and the dashboard.

### Added — per-tab colors + tab context menu
- Right-click a tab for its own menu: rename, close, close others /
  to-the-right, and per-tab colors — tab background, label color, and
  a terminal-background tint for the tab's panes (swatch presets, ×
  clears back to the theme). Colors live in the session tree, mirror
  to viewers, and survive daemon restarts (`SetTabColor`, additive).
- The active tab now carries a thin accent underline — visible at a
  glance where the old 1px outline wasn't.
- Dragging a tab shows a floating ghost chip under the cursor while
  the strip reorders underneath; the origin slot dims.

### Added — tab bar, the full treatment
- Ctrl+1..9 jumps to the n-th tab; tabs show a discreet ordinal.
- Middle-click closes a tab; double-click the empty strip opens a new
  one; the wheel over the strip cycles tabs; double-click a tab still
  renames it.
- Drag a tab to reorder it (live, mirrored to every viewer).
- Closing a tab with running child processes asks first: the daemon
  checks the shells' children and an inline strip offers
  "close anyway / cancel". Idle shells close without ceremony.
- Right-click the + button: "new session on host…" lists your saved
  SSH connections.
- Context menu: "close other tabs" and "close tabs to the right".
- Ctrl+Tab toggles to the last-used tab (MRU); ctrl+shift+space opens a
  fuzzy tab switcher (type part of a title, Enter jumps).
- Tabs carry a split badge (⊞n) when they hold panes, show the full
  title in a tooltip once truncated, and below ~30px/tab the strip
  switches to "active tab + dropdown" instead of unreadable slivers.


### Fixed — tab strip is responsive; every tab closable on hover
- Ten tabs pushed the files/home buttons off-screen: tab widths were
  fixed. Tabs now share the space left of the right-side controls and
  shrink (down to slivers) as more open — +, files, and home never move.
  The strip recomputes from the live window size, so resizing or
  maximizing reflows it immediately.
- Every tab shows its × when hovered (the active one always); the slot
  is reserved so nothing shifts on hover.

### Fixed — bold text switched typefaces with variable fonts
- Bold from a variable-font family (Ubuntu Mono on modern Ubuntu is one
  file with a weight axis) fell back per-glyph to a different family —
  bold ls entries rendered in DejaVu. Families with a static Bold face
  keep using it; variable-only families now get SYNTHETIC bold (the
  classic double-strike, same as VTE/xterm): same typeface, same
  metrics, visibly thicker strokes.

### Fixed — column alignment with non-bundled fonts
- With a system font whose advance differs from JetBrains Mono's 0.6em
  (Ubuntu Mono is 0.5em), plain and styled runs drifted apart — ls
  output looked like mixed fonts with uneven gaps. The cell grid now
  measures the active family's real advance from its font file
  (fc-match + ttf-parser) instead of assuming 0.6.

### Added — daily-driver interactions
- Double-click selects the word, triple-click the line (word charset
  matches Terminator's select-by-word set); the selection lands in
  PRIMARY as usual.
- Ctrl+mouse wheel zooms the font.
- Background tabs show an attention dot: muted for new output, red when
  the shell rang the bell (BEL); cleared when the tab is selected.
- Ctrl+click now also opens OSC 8 hyperlinks (the cell's own link wins
  over heuristics) and local file paths with an optional :line:col —
  VS Code gets them via `code -g` when installed.
- Tabs can be reordered: ctrl+shift+pageup/pagedown or the right-click
  menu (new additive MoveTab command, mirrored to every viewer).

### Added — terminal settings tab + quake mode
- Settings gains a "terminal" tab: scrollback lines (new panes), mouse
  wheel speed, copy-on-select, and whether programs may set the
  clipboard (OSC 52).
- Quake mode: a global hotkey (e.g. F9/F12, configurable there) shows/
  hides the window from anywhere. Off by default; X11 and Windows (no
  Wayland global hotkeys yet).

### Added — vault security: revoke + key rotation, recovery kit
- A shared vault's members panel now lists current members with a
  revoke button. Revoking rotates the vault key: every profile is
  re-sealed with a fresh key wrapped only to the remaining members, so
  revoked access truly ends (server swaps everything atomically and
  still sees only ciphertext).
- Recovery kit: the account screen can generate a one-time recovery
  code (shown once, copied to the clipboard) that can recover the
  account key if the vault passphrase is lost. The code never leaves
  the machine; the server stores only a sealed blob.

### Changed — daemon idle policy (M3 leftover)
- With no live sessions and no attached viewers for 15 minutes, the
  daemon exits. Dormant sessions stay on disk; the next launch spawns a
  fresh daemon that loads them.


### Added — Windows sessions survive the window (named pipes)
- The mux daemon now runs out-of-process on Windows too, over a per-user
  named pipe (auto-spawned, detached, one instance per user). Closing or
  killing the window no longer ends your shells: reopening Termuna
  attaches straight back into the live session with scrollback replayed,
  exactly like on Linux. This closes the long-standing M3 item; the
  in-memory transport remains only as the test harness.

### Added — Windows installer
- A real Windows installer (NSIS, ~5 MB): per-user, no admin prompt,
  installs to %LOCALAPPDATA%\Programs\Termuna with a Start Menu shortcut
  and an Apps & Features entry; /S installs and uninstalls silently.
  Uninstall leaves user data (sessions, vault, config) in place.
- The Windows exe is a proper GUI app now: no console window flashes on
  double-click (CLI flags still print when run from a terminal), and the
  moon-cursor icon is embedded (Explorer, taskbar, Alt-Tab).

### Fixed — consistent form styling and Tab focus
- Text inputs and other bare widgets now draw with the app's own theme
  everywhere. They used to fall back to iced's built-in theme, which
  follows the OS light/dark preference — on a light-mode Windows that
  meant white inputs floating in our dark chrome.
- Tab / Shift+Tab move focus between inputs in every form (sign-in,
  connection editor, settings, search). Inside the live terminal Tab
  still belongs to the shell.

### Changed — shared connections work across devices
- A connection whose SSH key path does not exist on this device now
  falls back to this device's default key (~/.ssh/id_*) instead of
  failing with a missing-file error. Profiles sync across machines and
  teammates, but private keys never travel with them — each device
  authenticates with its own key. A leading `~` in key paths is now
  expanded on every platform.
- Opening the ssh connections screen triggers an immediate silent vault
  refresh, so a teammate's fresh share appears right away instead of on
  the next minute tick.

### Changed — share dialog says who can't receive a share
- Teammates who haven't published an encryption key yet (never unlocked
  the vault in their app) are shown as unselectable with the reason,
  instead of being silently skipped at grant time — "shared with 0
  teammate(s)" can no longer happen by surprise.

### Added — background vault sync
- Shared connections now arrive on their own: while you are signed in
  with the vault unlocked (or the passphrase remembered on this device),
  the app quietly re-syncs every vault once a minute, so a teammate's
  share shows up without pressing sync or restarting. Offline failures
  are silently ignored — nothing interrupts.

### Fixed — Windows actually works
- Terminal query responses (cursor-position reports, device attributes)
  from the pane emulator are now written back to the shell's pty. ConPTY
  probes the terminal on startup and blocks all further output until the
  probe is answered, so every Windows pane sat frozen at an empty grid;
  the same fix answers vim/tmux probes over SSH on every platform.
- Windows now defaults the renderer to DX12. Hybrid-GPU laptops with
  dated Vulkan drivers picked Vulkan on the discrete GPU and presented
  into the void: a stale first frame (the app looked unclickable) and a
  render loop spinning a full core. An explicit WGPU_BACKEND still wins.
- Session persistence, the connection vault, and config.toml resolve to
  real Windows locations (%LOCALAPPDATA%\termuna, %APPDATA%\termuna)
  instead of an XDG-shaped relative path that landed in whatever
  directory the process started from (and failed with access denied).

### Added — settings tabs, color picker, Tango Dark
- Settings are organized into tabs (appearance / keybindings) — room to
  grow without a wall of controls.
- Custom colors got a real picker: color wells that expand into curated
  swatches (theme default, grays, luna, the Tango ramp) plus hue/
  saturation/lightness sliders with a live preview and hex readout.
- New built-in theme "Tango Dark": the GNOME/VTE default palette on a
  near-black surface — the classic Terminator look. (Any installed
  monospace font, e.g. Ubuntu Mono, is already offered in the font
  dropdown.)

### Added — resizable splits, appearance profiles, keybinding editor
- Split dividers are draggable: grab the strip between panes to resize
  (the cursor shows a resize arrow); the new SetSplitRatio command keeps
  every viewer and the daemon on the same layout. Clicking into a pane
  focuses it in every mouse path (including apps that own the mouse).
- Appearance profiles (Terminator-style): named presets holding theme,
  font, cursor, and custom foreground/background overrides (#rrggbb over
  any theme). New / duplicate / remove in settings; "set as default"
  picks what the app uses everywhere. Old flat configs migrate into a
  "default" profile automatically.
- Keybindings are editable in settings: every action with its combo,
  Enter applies (chords supported), saved to config.toml.

### Added — mouse reporting, OSC 52, URL clicks, PRIMARY selection
- Mouse reporting: clicks, drags (deduped per cell), and wheel are
  forwarded to applications that request them (SGR 1006 and legacy X10
  encodings), so htop/vim/tmux respond to the mouse. Shift bypasses
  reporting for local selection, as everywhere else.
- OSC 52 clipboard, write-only: programs (vim/tmux over SSH) can set the
  local clipboard; read requests are never answered, so nothing can
  exfiltrate what you copied.
- Ctrl+click opens http(s) links under the cursor (wrapped lines joined).
- Finishing a selection copies it to the PRIMARY selection and
  middle-click pastes it — the Linux terminal convention.
- New core stress test: alt-screen x resize x clear (the most re-broken
  bug in Warp's public history) runs in CI.

### Added — terminal input correctness (vim/less/htop basics)
- Bracketed paste: when the running program enables it, pasted text is
  wrapped in paste markers (end marker stripped from the payload), so a
  multiline paste no longer executes line by line in the shell and vim
  stops auto-indenting pastes.
- Application cursor keys (DECCKM): arrows and Home/End switch to SS3
  encoding when full-screen programs ask for it.
- Modifier-encoded keys: ctrl/alt/shift + arrows, Home/End, Delete,
  Insert, PageUp/Down now send the xterm CSI-1;m forms (ctrl+arrow word
  jump in shells works), and F1-F12 are wired up.
- Mouse wheel in the alternate screen scrolls the application (arrow
  keys, three per notch) instead of doing nothing — vim, less, and htop
  scroll from the wheel now.
- New research note docs/research/warp.md: basics comparison against
  Warp plus a bug-lesson checklist mined from its public issue history.

### Added — session names and one-key access on the dashboard
- The daemon now wraps each cloud session's content key to the account's
  vault public key (the same key custody as the SSH connection vault)
  and pushes the session title sealed with the content key; renames
  refresh it. The relay stores blobs it cannot read.
- On termuna.com/app, one vault-passphrase unlock now shows every
  session's real name and lets Open work in any browser — no more
  pasting a share link per session. New additive TSP frames
  (AccountInfo, SessionMeta); old peers ignore them.

### Added — "copied ✓" feedback on copy link
- Clicking "copy link" on a session row now flashes the button to
  "copied ✓" for two seconds, so you know the share link is on the
  clipboard.

### Fixed — closing the last tab returns home
- Closing the only tab (or exiting the last shell) quit the whole app —
  a leftover from before the picker existed. The end of a session now
  returns to the sessions screen.

### Added — confirmation before removing a connection
- "remove" on a host no longer deletes immediately: an inline
  `remove "<name>"?` confirm (red remove / cancel) appears under the
  card first.

### Changed — quieter ⋯ on host cards
- The ⋯ (actions) affordance no longer paints a hover box inside the
  card; the dots just brighten on hover.

### Fixed — host actions: move and share respond again
- Clicking "move" or "share" on a connection did nothing: they opened
  their panel state but left the actions strip open, and the actions
  branch renders first, so the new panel never appeared. Both now close
  the strip and swap to their panel.

### Added — vault picker in the host form
- Adding or editing a connection asks which vault it belongs to (a
  dropdown next to the port field); Personal is preselected for new
  hosts, and editing keeps the host's current vault.

### Changed — picker actions in the heading row
- "+ new local session", "+ add ssh host", and "+ new vault" moved from
  the bottom of their lists into the heading row, top-right — long lists
  were pushing them out of sight. Their editors (host form, vault name)
  now open directly under the heading for the same reason.

### Fixed — files panel survives re-attach
- Re-attaching to an SSH session from the picker lost the files button:
  the viewer forgot which connection profile the session belonged to.
  The daemon now reports each session's SSH destination
  (`user@host:port`) in the session list, and the viewer maps it back to
  the vault profile on attach, so SFTP stays available.

### Fixed — SFTP files panel: upload and mkdir
- Upload now opens a native "open file" dialog and sends the chosen file
  to the current remote directory. Previously one text box served both
  upload and mkdir, so "upload" did nothing unless you happened to type a
  full local path into it — unclear, and it looked broken.
- That box is now purely a folder search: it filters the listing, and
  the mkdir button stays disabled until the search names a folder that
  doesn't exist yet — then it arms as "mkdir <name>" and creates it.

### Added — Linux desktop integration
- `scripts/install-desktop.sh` installs the binary plus a launcher entry
  and the moon-cursor icon into the hicolor theme, so Termuna shows up in
  app search and the dock with its own icon. The window now sets
  `application_id`/WM_CLASS to `termuna`, matching `StartupWMClass` for
  correct dock grouping. New `apps/termuna/assets/` (icon SVG + .desktop).

### Changed — luna teal rebrand + app icon
- The default theme is now "Luna Dark": near-black surface with luna-teal
  accents (#2dd4bf, the brand color) on the cursor, active tab, focused
  pane border, and selection. The ANSI ramp keeps honest terminal
  semantics — green output stays green. "Luna Light" replaces "Phosphor
  Light"; the old `phosphor-*` theme ids still resolve so existing
  configs keep working.
- The window/taskbar icon is the moon cursor — a luna-teal block cursor
  with a circular lunar bite (luna is in the name: ter-muna) — drawn
  procedurally, no image assets or decoders.
- The sidebar wordmark matches the website: "termuna" with the moon
  cursor as its eighth character (vector-drawn canvas mark), replacing
  the plain dot.

### Added — close tabs
- The active tab now has an inline × (red on hover) that closes it —
  every pane in the tab goes; closing the only tab ends the session and
  returns to the picker. Also available as "close tab" in the
  right-click menu (which now says "home" instead of "sessions").

### Changed — leaner terminal tab bar
- The tab bar's right side is now a single ⌂ home button that returns to
  the picker (where sessions, connections, and settings live). The
  "copy cloud link", "sessions", and ⚙ buttons are gone — the cloud link
  stays available on the session's row in the picker. "files" still shows
  for SSH sessions.

### Added — scrollback survives reboot
- A session's terminal output (scrollback) is now persisted to disk (the
  last ~1MB per session, written on a 3s throttle only while output
  flows) and replayed on resurrection. Combined with the existing
  tab/split tree + per-pane working directories, resurrecting a session
  after a reboot brings back the same layout, the same directories, and
  the prior on-screen history — then a fresh shell continues from there.
  Running processes still don't survive a reboot (a reboot kills them);
  this restores the view, not live process state. New per-session `.log`
  file; covered by `scrollback_survives_daemon_restart`.

### Added — manage sessions from the picker
- Rename a session inline in the picker ("rename" → type → Enter/save),
  and end one for good with "kill". Rename and kill work on live and
  dormant sessions alike; killing deletes the persisted tree so it does
  not come back on the next daemon start. A rename mirrors to any
  attached viewer and, for cloud-bridged sessions, syncs end to end via
  the session tree. New `MuxRequest::{RenameSession,KillSession}` and
  `Session::rename`.

### Changed — launch always lands on the picker
- Starting Termuna now always opens the session picker (sessions, saved
  hosts, cloud sign-in), even on a fresh install with nothing saved. It
  no longer auto-spawns a local shell on launch; "+ new local session"
  is one click away.

### Changed — two-pane connection manager
- The picker is a two-pane layout with a persistent left sidebar
  (lowercase nav: sessions, ssh connections, settings, and an account
  entry pinned at the bottom showing the signed-in email). The sidebar
  stays visible on every section, including settings, and shows a live
  session count.
- New account screen (sidebar → account): signed-in email, organization
  and team-member count, and a sign-out button (clears the local token
  and any remembered passphrase, and stops the daemon's cloud bridge).
  The cloud sign-in / status moved here out of the SSH Connections
  section, where it didn't belong. Signed out, the sidebar item and the
  pane say "sign in" instead of "account".
- Hosts render as a responsive multi-column card grid (name +
  user@host:port with a ⋯ actions button inside each card), grouped under
  collapsible vault headers; the column count follows the window width.
  A card opens its actions on the ⋯ button or a right-click. Resizes
  cleanly — the sidebar stays fixed, the grid reflows.

### Fixed — host card grid on wide windows
- Maximizing the window squeezed host cards into overlapping slivers:
  the grid computed its column count from the full window width while
  the content column is capped, so it asked for more columns than fit.
  Both now derive from the same cap. Card texts are truncated so a long
  host can never paint over its neighbor, and the card hover tint is the
  dark selection color instead of a bright accent fill that swallowed
  the text.

### Added — full connection management
- Every saved host now has an actions menu (⋯): edit, duplicate, move to
  vault, share, and remove. Editing reopens the form pre-filled and
  round-trips auth, jump hosts, and port forwards losslessly.
- Adding or editing a host now just saves and returns to the list;
  connecting is a separate, explicit click (no more auto-connect on save).
- A search box filters hosts by name, host, or user (and expands all
  vaults so matches show). Deleting a host is finally possible.

### Added — Termius-style vaults (connection organization)
- The connection manager is now organized by vault: connections live in a
  named vault (Personal by default, plus any shared vaults you create).
  The picker renders a collapsible Vault → Host tree (connections sorted
  by name) with per-vault counts. Vaults are the single grouping level;
  the earlier per-connection folders were dropped as redundant (the
  `group` field remains in the format but is no longer used by the UI).
- "＋ new vault" creates a named vault; each connection has a
  "move" action to reassign it between vaults. `termuna-vault::Profile`
  gains a `vault` field; assignment persists to the local vault.
- Cloud sync is per-vault and action-driven: unlock the vault once with
  your encryption passphrase (asked inline in the connections section,
  never uploaded), and from then on changes sync automatically — moving a
  connection pushes it to its vault, and a vault's "members" button grants
  teammates access (the vault key is wrapped to each member's public key).
  Each connection uploads into the cloud vault named by its `vault`
  (Personal → personal vault, others → same-named shared vaults, created
  on demand). Replaces the old all-or-nothing "share with team" and the
  separate passphrase box / "sync all vaults" button.

### Added — remember vault passphrase (opt-in)
- The cloud-vault unlock is now a discreet "🔒 unlock cloud vault" link
  that expands into the passphrase field on demand, instead of a prompt
  that shows on every launch.
- A "remember on this device" checkbox stores the passphrase in the OS
  secret store (GNOME Keyring / macOS Keychain / Windows Credential
  Manager) so the vault auto-unlocks on launch. Off by default; the
  passphrase still never touches the relay or plaintext disk.

### Added — settings panel (appearance)
- In-app settings (⚙ in the picker and the tab bar): pick a color scheme,
  font family, font size and line-height, and cursor style, with a live
  preview. Changes apply immediately and persist to `config.toml`
  (only the appearance keys are rewritten; keybindings/cloud are kept).
- Seven built-in color schemes: Phosphor Dark (default), Phosphor Light,
  Dracula, Nord, Gruvbox Dark, Solarized Dark, Tokyo Night. The
  configured theme is now actually applied on launch (it was ignored
  before).
- Font family is selectable from installed monospace fonts (detected via
  fontconfig) plus bundled JetBrains Mono.
- Cursor style: block (default), bar, or underline, with an optional
  blink. Unfocused panes still show a hollow cursor.

### Changed — tab and session titles
- Tab titles now follow the shell's own title (OSC 0/2, e.g.
  `user@host: ~/dev/project`) as the authoritative source, forwarded to
  the daemon so it mirrors to every viewer and the cloud. The cwd-based
  auto-title is only a fallback for shells that set no title, so titles
  no longer flip-flop between the shell title and a bare `~`. New
  `Session::set_shell_title`, `Tab::shell_title`, and
  `SessionCommand::SetTabTitle`. Tab labels show more of the title.
- The picker shows a renamed session by its name alone (`prod cluster ·
  live`); auto-named sessions keep the `N tabs, N panes` summary so they
  stay distinguishable. `Session::rename` now marks the title manual and
  `SessionInfo` carries `renamed`.

### Fixed
- Terminal column alignment: styled runs (e.g. colored directory names in
  `ls -l`) no longer drift left and overlap the column beside them. The
  cell width was rounded to a whole pixel while the renderer advances
  glyphs by the true fractional width, so long runs drifted off the grid;
  the cell width is now the exact glyph advance.
- A failed session-list refresh (e.g. a kill/rename an older daemon
  rejects) no longer blanks the picker — the existing sessions stay
  visible and the error is shown instead of looking like everything died.

### Added — M9 cloud connection vault (desktop)
- Save your SSH connections to Termuna Cloud, end to end encrypted, and
  share them with your team. A vault passphrase (never leaves the
  machine) unlocks an account keypair; connections are sealed with a
  vault key and, for sharing, that key is wrapped to each teammate's
  public key. The relay only stores ciphertext.
- Picker gains, once signed in: a vault passphrase field with
  "sync connections" (push local, pull cloud, merge) and
  "share with team" (share with everyone in your organization).
- New crate module `termuna-sync::vaultcrypto` (X25519 + Argon2id +
  sealed boxes); desktop client `apps/termuna::cloud_vault`. See
  docs/adr/0004-connection-vault.md.

### Changed
- macOS tab auto-titles now use the last persisted working directory
  (like Windows) instead of a live procfs read; dropping the
  darwin-libproc dependency unblocked the vault crypto crates.

### Added — M7 (desktop UX: the app explains itself)
- Interactive cloud sign-in: a "termuna cloud" section in the picker
  signs in or creates an account, mints a device token, writes
  config.toml, and flips the daemon to cloud mode at runtime — sessions
  start syncing immediately, no manual config and no restart. Each
  synced session shows a "copy link" button; the terminal gets a
  "copy cloud link" chip.
- Tabs are titled by the shell's working directory (`~`, `lightweight-cli`,
  …) and follow `cd`; double-click (or right-click → rename) gives a tab
  a permanent name. New `RenameTab` protocol command.
- Right-click context menu on the terminal: new tab, split right/down,
  rename tab, copy, paste, close pane, sessions.
- A "sessions" button in the tab bar detaches back to the picker — the
  session list, ssh connection manager, and cloud sign-in are always
  reachable now (previously the first launch dropped you straight into
  a terminal with no way back).

### Fixed — cross-platform builds + CI (green on all three OSes)
- Windows: agent auth is cleanly unix-gated, the GUI falls back to the
  in-process mux (sessions end with the window until named-pipe
  transport), home-dir resolution uses HOME/USERPROFILE. The workspace
  now compiles and tests green on Windows for the first time since M3.
- macOS: procfs-only field no longer trips -D warnings.
- CI: perf-budget job asserts binary <30MB, daemon socket <500ms,
  daemon idle RSS <30MB on every push.

### Fixed — memory budget (M2 closeout)
- Measured the idle-memory budget honestly: with 3 tabs idle the GUI is
  83MB PSS and the daemon 4MB — 87MB total, under the 100MB budget. The
  previously reported 157MB was RSS, which double-counts ~70MB of
  shared, evictable GPU-driver (Mesa/LLVM) and libc code pages; private
  memory is ~26MB. Added scripts/mem-budget.sh so the number is
  reproducible (same isolated-daemon, 3-tab scenario). For scale: an
  Electron terminal on the same machine idles at ~492MB PSS.

### Added — M5 alpha (cloud continuity)
- Cloud bridge in the mux daemon: with `[cloud] enabled` in config, every
  live session connects outbound (WSS) to the Termuna Cloud relay as its
  TSP host. Output and layout are sealed with a per-session
  XChaCha20-Poly1305 content key before leaving the machine; viewer input
  and commands are opened and applied through the same paths as local
  viewers. Share link `https://termuna.com/s/<id>#k=<key>` carries the key
  in the URL fragment, which browsers never send to the server. Sync
  stays opt-in and off by default (ADR 0002).
- Session content keys persist with the session (reboot keeps the URL);
  reconnect resumes from the relay's acknowledged head with capped
  backoff.

- `[cloud] token` in config: a device token from the termuna.com dashboard
  binds the daemon's sessions to your account (Authorization header on the
  relay connection). Free plan allows 1 concurrent live cloud session;
  Solo removes the limit.

### Changed — M5 alpha
- Content crypto switched from seq-derived nonces to random 24-byte
  nonces prepended to the ciphertext — seq nonces would repeat across
  multiple writers sharing the session key (host + viewers), which is
  catastrophic for Poly1305. Interop-tested against the web viewer's JS
  implementation.
- TSP ciphertext fields now encode as CBOR byte strings (`serde_bytes`)
  instead of integer arrays — smaller frames, sane browser decoding.

### Added — M3 (persistence: the mux daemon)
- `termuna-mux` crate: a daemon (`termuna --daemon`, auto-spawned by the
  GUI, detached so it outlives it) that owns every PTY and the
  authoritative session tree. Transport: TSP frames over a Unix socket
  (0700 runtime dir) with a small handshake (list/create/resurrect/attach);
  in-memory duplex transport for tests and socketless platforms.
- Sessions survive the window: killing the GUI leaves shells running;
  reattaching replays the daemon's retained output log — full screen and
  scrollback reconstructed. Verified live on X11.
- Reboot resurrection: every structural change persists the session tree
  and per-pane working directories (procfs) to disk; after a daemon
  restart, sessions appear as dormant and one click restores the whole
  layout with fresh shells in their saved directories. Verified live.
- Session picker on startup: live/dormant list with tab/pane counts, plus
  new-session; shell `exit` cleanly ends the session everywhere.
- TSP gains the `Command` payload (`SessionCommand`: NewTab, Split,
  ClosePane, SelectTab, FocusPane, ResizePane) — viewers request
  structural changes, the host applies and broadcasts a `Layout`
  snapshot. The GUI is now literally the first TSP viewer; the web
  dashboard will reuse this path unchanged.
- Scrollback search: Ctrl+Shift+F opens a search bar; case-insensitive
  scan over the full scrollback with match counter and jump-to-match
  (Enter walks older matches). 40k lines scan in well under 500ms in the
  test suite — the anti-benchmark being the popular Electron terminal's
  search hang.
- 4 mux integration tests (attach/type roundtrip over real shells, split
  broadcast, detach/reattach replay, persistence + resurrection across a
  daemon restart); 39 tests total across the workspace.

### Changed — M3
- The GUI holds no PTYs anymore: `pane.rs` mirrors daemon state
  (emulator + cache + selection per pane) and all input/structure flows
  through TSP frames. Focus and tab selection are session state shared by
  all viewers, applied by the daemon.
- Startup with the daemon hop measured at 288ms to first output frame
  (debug build, cold daemon spawn) — still inside the <300ms budget.

### Added — M2 (windowed terminal)
- Windowed GPU terminal (iced 0.14 + wgpu): canvas grid renderer with
  run-batched text, per-pane geometry caching, block cursor (filled when
  focused, hollow otherwise), underline/strikethrough, selection overlay,
  and a scrollback position indicator.
- Tabs UI with OSC-title tracking and nested split panes rendered straight
  from the `termuna-session` tree; pane focus follows clicks and hotkeys.
- Default hotkeys (all remappable, two-step chords supported):
  Ctrl+Shift+T/W new/close, Ctrl+Shift+D/E split right/down,
  Ctrl+Shift+arrows focus, Ctrl(+Shift)+Tab tabs, Ctrl+Shift+C/V
  copy/paste, Shift+PgUp/PgDn scrollback, Ctrl+Shift+plus/minus font size.
- TOML config at `~/.config/termuna/config.toml` (font, theme,
  keybindings, scrollback) with graceful fallback on parse errors.
- Phosphor Dark theme (brand palette as ANSI-16), bundled JetBrains Mono
  (Regular/Bold/Italic/BoldItalic, OFL).
- Mouse: click to focus, drag to select, wheel scrollback; typing jumps
  back to the live view.
- `termuna-core`: render-snapshot API (palette-resolved RGB cells, cursor,
  styles) and scrollback scrolling behind the facade; `TermEvent` re-export.
- `termuna --inline` keeps the M1 engine harness; the window is now the
  default entry point.
- Verified live on X11: bash, colored ls, htop full-screen TUI, splits,
  tabs, scrollback. Release-build measurements on Linux/X11: cold start to
  first shell output **176ms** (budget <300ms ✓), binary **14.8MB**
  (installer budget <30MB ✓), RSS ~157MB with a shell running — above the
  <100MB budget, dominated by wgpu/driver allocations; memory optimization
  is an open M2 item (tracked in docs/ROADMAP.md).

### Added
- Cargo workspace with the M1 engine crates: `termuna-protocol`,
  `termuna-session`, `termuna-pty`, `termuna-core`, `termuna-sync`, and the
  `termuna` binary.
- TSP v1 wire format (CBOR frames, per-session sequence numbers, resume
  semantics) with roundtrip and version-rejection tests.
- Session model: tabs and nested split trees with focus handling,
  revision-counted snapshots for cloud mirroring, full unit coverage.
- Portable PTY layer (Unix pty verified by a live shell test; Windows
  ConPTY path compiles, pending manual QA).
- VT emulation core wrapping `alacritty_terminal` behind a swappable facade.
- Sync engine skeleton: XChaCha20-Poly1305 content encryption with
  seq-derived nonces, injectable transports, ack/resume watermarks.
- Inline dev harness: `cargo run` executes your shell through the engine
  and logs engine-ready time (startup budget instrumentation from day one).
- Project documentation: ARCHITECTURE, PROTOCOL (TSP draft), ROADMAP
  (M1–M6), competitive research (Tabby, Termius, tech stack), ADR 0001
  (tech stack) and ADR 0002 (offline-first, opt-in sync), CLAUDE.md.

### Decided
- Stack: Rust everywhere; alacritty_terminal core; iced 0.14 + cosmic-text
  UI (M2); local mux daemon for persistence (M3); axum cloud (M5). See
  ADR 0001.
- Product: offline-first, no mandatory account, full export at every tier,
  no AI in the input path. See ADR 0002.
