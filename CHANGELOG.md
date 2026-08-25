# Changelog

All notable changes to the Termuna desktop app are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versioning: [SemVer](https://semver.org/) once we hit 0.2 (M2).

## [Unreleased]

## [0.2.4] - 2026-08-25

### Added: a .deb package, and an apt repository that carries its updates

Linux gets a real package: `termuna-amd64.deb` on every release (built
by cargo-deb from the same binary the tarball ships, with the desktop
entry and icon in their proper places), and an apt repository at
`termuna.com/apt` - GPG-signed, `signed-by`-pinned, served as static
files by the site's own nginx. Add it once and Termuna updates with
the rest of the system through `apt upgrade`. A package install lives
in `/usr/bin`, which the in-app updater already treats as not its own
(ADR 0012), so the two update channels never fight. The repository is
signed on the maintainer's machine (`scripts/publish-apt.sh`), never
in CI - the same custody rule as the update manifest key.

### Added: a modal with edits asks before it discards them

Esc, Cancel, or a click outside a modal used to close it no matter
what it held: half a filled-in SSH host, a typed passphrase, a picked
set of teammates - gone on one stray key. A dismiss that would lose
typed input now stops at a small question - keep editing, or discard -
and esc on the question itself keeps editing, so the safe answer is
the easy one. Pristine forms and confirm dialogs close exactly as
before: the question only exists when there is something to lose.

### Fixed: the Windows installer no longer kills your sessions

Upgrading on Windows ran `taskkill /f /im termuna.exe` before copying
the new build - ending the window, the daemon, and every running
session mid-install, the exact thing the product promises never to do.
NTFS allows renaming a running executable, so the installer now moves
the old build aside (`termuna.exe.old`) and lays the new one down
without touching a single process: the window picks the new build up
on its next launch, the daemon on its next restart, where it hands its
shells over instead of losing them. The app sweeps the leftover `.old`
on a later start once nothing runs from it. Verified live on the
Windows test machine: a silent upgrade over a running instance left
both processes untouched, and the relaunched window attached to the
surviving daemon. Uninstall still ends the processes, because there
ending them is the point.

### Fixed: a URL in parentheses is a link again

`(https://...)` - the way agents and docs print links - hovered as
nothing: the opening paren is a legal URL character, the detector
swallowed it, and the "starts with http" check then threw the whole
match away. The link is now anchored on the scheme, so the surrounding
prose punctuation stays prose, and a trailing `)` is only trimmed when
the URL's own parentheses do not balance (a Wikipedia-style path keeps
its parens). Hover underlines exactly what ctrl+click opens, including
under a TUI that owns the mouse.

### Changed: the daemon's health moved to the continuity panel

It was squeezed under the account name in the sessions drawer's foot,
three lines deep in the narrowest corner of the window, while the
continuity panel - the column that already holds the machine facts -
had the room. The daemon block now sits there, above the encryption
line: a calm dot and uptime when healthy, and when the daemon is an
older build, the row itself is the restart button. The drawer's foot
goes back to being about the account: name and email, nothing else.

## [0.2.3] - 2026-08-21

### Changed: on Linux, the update installs itself - in a session you watch (ADR 0012)

"Install" used to end at a file manager opening on a folder with a
tarball in it, which is where the first person to try it reasonably
asked what a terminal was doing showing them a folder. When the
running binary is ours to replace (its directory is writable and lives
under `$HOME`), Install now opens a fresh session named for the
version and executes the install there: the exact `tar` command
scrolls by in a pane, the closing line says what remains, and the
session's scrollback is the install log. Nothing happens off-screen.
A binary that is not ours (a distro package, an admin install) keeps
the hands-off behaviour, because there "don't touch" is still the only
honest answer. The artifact is SHA-256-verified against the signed
manifest before any of this, as before.

## [0.2.2] - 2026-08-21

### Fixed: a daemon restart reconnects quietly instead of alarming you

Pressing "Restart daemon" (or restarting it by hand) dropped every
viewer for under a second, and the window treated that like any dead
daemon: the connecting screen, in red, "connection to mux daemon
lost". A lost daemon connection now walks back in silently first - the
successor holds the same sessions, so the window lands back where it
was, typed-but-unsent input still on screen - and the red screen is
reserved for when coming back actually fails twice. The drawer foot's
daemon line also refreshes on reattach instead of claiming "offline"
until the next slow poll. And the handoff quiesce no longer depends on
the signal mask the daemon happened to inherit: a spawner with SIGUSR1
blocked degraded every restart to a ten-second stall; the reader
thread now unblocks it for itself, and the sandboxed swap went from
10s to 8ms.

### Fixed: a daemon handoff no longer loses output a shell is streaming

From the moment a successor daemon rebuilt the sessions until the
predecessor exited, both were reading the same PTY masters: whatever
the predecessor won died with its log, and whatever the successor won
reused sequence numbers the relay had already seen and silently
dropped. A repro streaming numbered lines through a handoff lost
400-900 lines per swap; the "Restart daemon" button (ADR 0009) put
this path in users' hands. The handoff is now serialized (ADR 0008
amendment): the predecessor stops consuming and provably drains its
pipeline before the snapshot, the successor starts reading only once
the predecessor's exit closes the handoff socket, and a closing delta
covers the seam. Cost: a streaming shell briefly blocks on write
during the swap, which it cannot observe. Stressed on an otherwise
saturated machine (16 busy cores), 30 of 30 handoffs mid-flood now
replay every one of 50,000 numbered lines; the wire change is
compatible in both directions with older builds. The Windows
named-pipe handoff keeps the old semantics until it gets the same
treatment.

### Fixed: a tab's auto-title no longer misses the `cd` that goes quiet

The cwd-based title refreshed on output behind a 2s throttle, and the
first chunk after a `cd` is the terminal's echo of the command - sent
before the shell has run it. That chunk spent the refresh on the old
directory, the real output landed inside the closed window, and a
shell that then went quiet kept its stale title until it next said
something. Now the first throttled chunk of a burst schedules one
recheck for when the window reopens, so the title lands within ~2s of
the change no matter how quiet the shell goes. This is also what
`tabs_auto_title_from_cwd_and_rename_pins` had been failing on since
19.8: not runner load, a refresh race, which is why raising its
deadline never helped.

### Added: a live daemon can say which protocol it speaks

`DaemonStatus` carries the TSP `PROTOCOL_VERSION` beside the crate
version, `termuna-daemon status` prints it for the running process
(with a nudge when the binary on disk speaks a newer one), and the
desktop judges "restart the daemon" on both numbers. The crate version
alone was the wrong signal in both directions: 0.2.1 spanned TSP v2
and v3, so during this week's breaking rollout a daemon two protocols
behind reported itself current, and a same-protocol rebuild reported
itself stale. A daemon too old to report the field reads as protocol
0, which correctly counts as stale.

### Fixed: `Pty::disarm` no longer lets the writer hang up the shell

portable-pty's writer politely writes `"\n"` + VEOF into the terminal
when dropped, and in canonical mode VEOF is end-of-input: dropping a
disarmed pty told the very shell being handed over to exit. The daemon
never hit it (it steps aside with `process::exit`, so no Drop runs),
but the adoption test did, intermittently, and the failures were
misread as CI slowness. Disarm now neutralises the writer, and the
tests assert on printf-assembled output the terminal echo cannot fake,
which is what they believed they were asserting all along.

### Changed: clients ask where to connect (ADR 0011)

The relay address was a constant in every client:
`wss://termuna.com/v1/session` compiled into the desktop and the
headless daemon, derived from `location.host` on the web, derived from
the API base on the phone. That works as long as there is one relay,
forever. The day there is a second one - a node closer to Asia, a
self-hosted deployment, staging - every installed copy would have to be
replaced before it could be told.

Sign-in now asks `GET /v1/config` and writes the answer into
`[cloud] url` / `share_base`, so the compiled-in address is only a
bootstrap: it is how a fresh install reaches the API the first time, and
what the API answers is what is used from then on. `termuna-daemon
login` does the same. Anything unrecognised keeps the address we already
had, because a cloud that cannot answer this is still a cloud worth
signing into.

Session listings also carry an optional `relay_url`, and clients prefer
it: a session lives on whichever relay its host bridged to. It is null
for every session today; clients read it now so that the day it is not
is a config change rather than a protocol change.

Share links deliberately stay on the apex. `termuna.com/s/<id>` gets
pasted into other people's chat histories and outlives every deployment
decision we will ever make, so the region belongs in the routing layer
and is resolved when the link is opened.

Along the way the three sign-in paths (password, TOTP, browser) stopped
carrying three copies of the same tail; they share
`cloud_client::land_sign_in`.

### Changed: the vault records the KDF that made it (ADR 0010)

The Argon2id parameters that stretch a vault passphrase used to exist
only as constants in three separate client source trees, with the server
storing a salt and nothing else. That works exactly until they need
changing, and they will: they are OWASP's *minimum* (19 MiB, t=2), and
Argon2 costs are supposed to rise with hardware. Raising them without
knowing what a given account key was sealed under is impossible, and
the only repair would be asking every user to re-enter the passphrase
that guards custody of their machines.

An account now publishes `kdf` and `kdf_params` alongside `kdf_salt`,
and clients derive with what the server returns rather than with their
own constants. A recovery kit records its own, since one can be minted
long after the account key was. Blobs from before this say nothing, and
the historical values are the right answer for them, not a guess.

Rust also stops inheriting its parameters from `Argon2::default()`: they
are pinned explicitly, with a test asserting they still equal the crate
default. Otherwise a dependency that changed its defaults in a minor
release would change how every passphrase derives, and the symptom of a
routine `cargo update` would be every existing vault reporting a wrong
passphrase.

An algorithm a client cannot derive is now refused by name instead of
attempted anyway: "this vault uses X, update Termuna" rather than a
wrong key presenting as a wrong passphrase.

### Changed: sealed blobs name their own format (TSP v3)

Every sealed blob now begins with a byte naming the construction that
produced it: `version(1) || nonce(24) || ciphertext+tag` for content,
and `version(1) || epk(32) || nonce(24) || box_ct` for a key wrapped to
an account. The byte is checked before the key, and an unrecognised
value is its own error rather than an authentication failure, so a blob
from a newer Termuna reports "this needs a newer client" instead of
something indistinguishable from a wrong passphrase.

One byte per frame buys the ability to ever change how bytes are
sealed. Without it that change is a flag day over data we no longer
control: frames sit durably in the relay's database, a sealed account
secret sits in the accounts database, and share links in other people's
chat histories point at both. "Try the new format, fall back to the
old" is not a substitute, because an AEAD failure looks exactly like a
wrong key, so the fallback would silently retry every real tampering.

`PROTOCOL_VERSION` is 3. The envelope did not change at all, which is
precisely why the version had to: a v2 peer would route v3 frames
flawlessly and then fail to decrypt every one of them, with no way to
say why. **The relay, the desktop, the web client and the phone must
be rebuilt and deployed together.**

The web and Dart clients are now pinned to fixtures this repo emits
(`cargo run -p termuna-sync --example format-fixtures` and
`--example tsp-vectors`) rather than to their own past, or to a scratch
cargo project the docs asked a maintainer to write from scratch.

### Added: the app can tell you it is out of date (ADR 0009)

Termuna had no way to reach an installed build. With `PROTOCOL_VERSION`
refusing peers across major versions, that meant the day the relay was
upgraded every desktop that had not been manually reinstalled would stop
connecting, with no way to say why.

Once a day the app now fetches a signed manifest from the public
releases repo and, if a newer release exists, says so as one line in the
status bar. Pressing it downloads that release's artifact for this
platform and checks it against the SHA-256 the manifest promises;
pressing it again hands the file to the OS (the per-user installer runs
on Windows, the file manager opens on the verified archive on macOS and
Linux). The app never downloads without being asked and never replaces
its own binary.

The manifest is Ed25519-signed and verified in-app against a key
compiled into the build, with the private half on the maintainer's
machine and never in CI: a stolen release token can publish files, but
not files any installed app will accept. The signature covers the
manifest as text and is checked before anything is parsed, and the
trusted keys are a list the envelope selects from, so rotating a key is
a rollout rather than a flag day.

The check is a plain GET of a public file that carries nothing about the
user; the version comparison happens locally. It is on by default with a
switch in Settings → About, and it is deliberately not on the launch
path: the first check waits until twenty seconds after the window is up,
so cold start never waits on the network.

Settings → About also grew the other half of an install: when the daemon
is running an older build than the app (after an install it always is,
and on Unix it is still holding the deleted inode of the old binary), it
offers to restart it. The ADR 0008 handoff means the successor adopts the
running shells rather than ending them.

### Added: the sign-in screen speaks two-factor authentication

An account with TOTP on (Termuna Cloud, Security page) used to be
unable to sign in from the desktop at all: the password came back
without a session and the screen had nothing to say. The password half
now pauses on a code form - six digits from the authenticator app, or
a recovery code - and finishes the sign-in exactly as before. The
browser sign-in (Continue with Google/GitHub) needs nothing: the web
form carries its own 2FA. `termuna-daemon login` explains that a 2FA
account joins a server with a borrowed token instead of failing with
"no session".

### Added: sign in with Google or GitHub

The sign-in screen now offers "Continue with Google" and "Continue with
GitHub" whenever the cloud has those providers configured; without them
the screen is unchanged. The app starts an app sign-in flow, opens the
system browser to finish it, and polls the cloud until the browser half
is done; the device token is minted at claim time and delivered exactly
once, after which everything proceeds as a password sign-in would
(config written, daemon flipped to cloud mode, vault passphrase asked).
A cancelled or failed browser round-trip reports its reason on the
sign-in screen, and a Cancel button stops the wait. This closes a real
hole: an account created with Google on the website has no password, so
the desktop could not sign into it at all.

### Added: the daemon upgrades without killing sessions (ADR 0008)

The `termuna-daemon` server now takes over a running daemon's sessions
instead of refusing to start. On start it looks for a predecessor; if
there is one it adopts its shells over a Unix socket (`SCM_RIGHTS`
carries each pty master), the predecessor acks and steps aside, and the
running shells keep running under the new binary. No predecessor means a
cold start, so the same command does the right thing either way. The
relay connection reconnects (a viewer sees a brief "reconnecting", no
loss); a crash or reboot still resurrects as before, and Windows is
unchanged. Rolling out new daemon code on a machine someone is using no
longer ends their work.

Under systemd the same holds for `systemctl --user restart`, where the
old process is gone before the new one starts: the unit is now
`Type=notify` with a file-descriptor store, so the daemon hands its pty
masters to systemd on stop and reads them back from `LISTEN_FDS` on the
next start (`KillMode=process` keeps the shells in the cgroup meanwhile).
Verified end to end both ways: two hand-started daemons, and a real
`systemctl --user restart`, each with the shell still running under the
new instance (same pid).

Windows does it too, by its own mechanism: the daemon drives ConPTY
natively (portable-pty hides the handles it needs), and a successor
`DuplicateHandle`s each pane's conin/conout pipe out of the predecessor
over a sibling handoff pipe, adopts the still-running shell, and acks
before the predecessor exits. One thing is lost there: the
pseudoconsole's resize handle cannot be transferred, so an adopted
terminal keeps its last size until the session is rebuilt.

Live-verified on all three platforms with a real process surviving a
daemon swap under the same pid: Linux (bash, plus a desktop full of
`claude`/`htop`/`node`), macOS 26.2 (zsh), and Windows 10 (powershell).
The desktop-spawned daemon now adopts on start, so it is covered too.

### Added: a launch-time permission mode that survives a resurrect

`CreateAgentSession`'s `AgentLaunch` now carries an optional
`permission_mode` (one of `AgentCommand::REMOTE_PERMISSION_MODES`,
`bypassPermissions` included). A remote client that starts an agent in
bypass had, until now, only the runtime `SetPermissionMode`, which lasts
the run and is gone after a resurrect. Setting the mode at launch lets
the host write it into the session's meta, so the choice holds when the
conversation is brought back. The host validates it (an unknown mode is
dropped) and ignores it for a shell-typed agent. The field is additive:
an older peer omits it and the host falls back to the CLI default.
Starting an agent on another machine from the desktop now carries its
bypass toggle the same way.

### Fixed: a connection whose id another account holds still syncs

Item ids are globally unique on the relay, so two independent accounts
that ended up with the same connection id (a vault copied between them)
collided: the server refused to let one account write an id the other
already owned (a 403, correct, so no account can hijack another's item),
and the desktop swallowed it. The connection sat local forever while
the "synced" note stayed green. The push now re-keys its own copy on
that 403 (a fresh id, its own independent item) and retries, dropping
the old local id without a tombstone (the old id belongs to the other
account, so deleting it is not ours to do). A push that fails for any
other reason on the personal vault now surfaces instead of being
shrugged off.

### Fixed: a saved connection reaches the cloud, or says why not

Saving or deleting an SSH connection while signed in but with the vault
locked used to write to this disk and silently skip the sync: the host
stayed local, the "synced" note kept its green tick, and nothing said
the change never reached the cloud or your other devices. Now, when a
vault action needs the passphrase, the app asks for it instead of
falling back in silence, and a failed sync shows as a problem, not a
quiet success. The connections subtitle no longer claims hosts are
"sealed on this device": signed in, they are encrypted end to end and
synced to every device you sign in on. There is one passphrase behind
all of it (the account key that seals connections, sessions and device
custody alike), so unlocking once covers everything through the server.

### Added: start an agent on another machine

"Start agent" now asks which machine should run it, exactly like "new
session" does — but only when another machine is reachable; with just
this device it skips straight to the directory chooser as before. Pick
a remote machine and the directory field targets it (its own recent
directories aren't shown, they're this machine's), the far daemon
creates the agent and answers with its share link, and the
conversation mirrors here. The launch-time bypass toggle stays on the
local path (the wire launch carries no mode); a remote agent reaches
bypass from its chat once it is up.

A provider whose CLI isn't installed on *this* machine is still
selectable when another machine is reachable (it may have it): the
segment no longer greys out just because the local daemon lacks the
binary. The machine picker then marks "this device" as "not installed
here" and unpressable, steering you to a machine that has it. This is
what makes the feature work from a Windows box that has no agent CLIs
locally but is paired with a Linux machine that does.

### Added: launch a managed agent in bypass-permissions mode

A managed Claude session can now run without the per-tool permission
asks, when the operator asks for it (ADR 0007). The start-agent card
has a "bypass permissions" toggle, the chat mode menu (Shift+Tab) gains
a fourth entry beside manual / edit / plan, and the mode is persisted:
a resurrected unattended agent comes back unattended. `bypassPermissions`
is no longer refused on the wire — custody (the account passphrase that
gates reaching a session at all) is the boundary, not a mode the
protocol pretends it can hide from its own operator; so a phone reaches
it too, at runtime. Off by default, always a deliberate choice.

### Fixed: an unfocused window shows the hollow cursor

The cursor kept its solid, blinking self while the window sat in the
background: the universal terminal signal for "typing lands here" shown
somewhere typing could not land. Window focus now joins the pane-focus
test: every pane of an unfocused window draws the hollow outline
cursor, the blink timer stops while nobody is watching (and restarts
on the visible half when focus returns).

### Fixed: the paste-confirm card answers to the keyboard

The multiline-paste question could only be answered with the mouse:
Enter did nothing (worse: keys pressed while the card was open leaked
into the shell underneath, and Esc dismissed the card's animation
without cancelling the paste, leaving it stuck). Enter now pastes, Esc
cancels, every other key stops at the card, and the card says so.
Terminal hands live on the keyboard; a modal that ignores it is a bug,
not a style.

### Added: shells know they run in Termuna

Spawned shells now carry `TERM_PROGRAM=termuna` (and
`TERM_PROGRAM_VERSION`), the convention terminal-aware tools read.
Claude Code's "auto" notification channel, for instance, is a whitelist
of terminals it recognizes by exactly this variable (Apple Terminal,
iTerm2, kitty, ghostty: everyone else gets silence): identifying
ourselves honestly is the prerequisite for ever being on such lists.
Until then, claude's `/config` → Notifications → `terminal_bell` is the
setting that makes it ring here.

### Added: links look like links under the mouse

Hovering a URL in the grid (a detected http(s) one, or an OSC 8
hyperlink an application drew) now underlines its span and turns the
cursor into a pointer, the affordance every other surface taught your
hand to expect. Ctrl+click opens it, as before. The underline stops
where the URL does: trailing punctuation stays plain.

### Added: focus reporting (?1004), so agent CLIs know when you left

Applications that subscribe to focus reporting now hear `ESC[I`/`ESC[O`
when their pane gains or loses the user's attention (window focus, tab
switch and pane focus all count). Claude Code gates its "I'm done" bell
on exactly this: in a terminal that never answers, it believes it is
watched forever and never rings. With its notification channel set to
`terminal_bell` (claude's `/config` → Notifications), a finished answer
in an out-of-sight pane now lands as a desktop notification. An OSC
9/777 notification caught by the daemon (the Attention frame) reaches
the desktop the same way.

### Added: a finished command notifies the desktop

A command that ran at least 15 seconds in a pane you cannot see — a
background tab, or any tab while the window is unfocused — now raises
a desktop notification when it finishes ("finished after 2m 13s"),
detected from the daemon's own busy-tab tracking: nothing is injected
into the shell. Bells from out-of-sight panes (TUIs and agent CLIs
ring one when they need you) notify under the same switch, which also
respects the window's real focus now, not just the active tab.
`notify_when_done` defaults to on; what you are looking at never
notifies, and there is no sound. `notify_on_activity` (first output of
a quiet background tab) stays opt-in.

### Fixed: status emoji render in color

✔️ ⚠️ 💡 📊 🐛 and friends — the emoji every CLI status line leans on —
rendered as small monochrome glyphs: the monospace-first fallback
(right for braille and CJK) let a symbols face win over the color
emoji font. Emoji-class codepoints (the pictograph planes, UTS #51
emoji-default singles, and anything carrying VS16) now route explicitly
to the platform's color emoji face (Noto/Segoe/Apple), the same way PUA
icons route to the bundled Nerd symbols. Bare text-presentation
dingbats (✔ without VS16) stay in the text face, as in other terminals.
Known engine-level limits, unchanged and shared with stock Alacritty:
skin-tone modifiers, ZWJ sequences and flags render as their parts.

### Fixed: dragging selects text in a Claude session

Claude Code turns on mouse reporting with its first prompt, and it ends
up in *any-motion* tracking (1003), because the mouse protocols are
mutually exclusive and that is the last one it sets. The drag-takeover
path (a left-drag in the normal screen becomes a local selection) was
keyed on the *button-event* flag (1002), which 1003 had just replaced:
so in a Claude session a drag reported the press and the release to the
agent and selected nothing at all. The takeover now keys on mouse
reporting itself, whichever protocol is active, including click-only
(1000), where the drag previously vanished with no selection offered.
Verified against a live Claude session: a drag mid-stream selects, the
highlight rides the text into scrollback, and Shift still hands the
drag to the app. (Note xterm.js-based terminals require Shift for this;
a plain drag selecting is on purpose.)

### Fixed: a resurrected session's shells no longer wake at 80×24

A resurrected pane keeps its id, but its PTY spawned at the default
grid, and the window's own bookkeeping believed the size was already
sent, so nothing ever corrected it: prompts wrapped at 80 columns in a
full-width window until a resize crossed a cell boundary. The daemon
now spawns resurrected panes at the size the persisted model remembers
(sizes now persist with the debounced flush, once per burst), the GUI
forgets its size bookkeeping on every attach, and an integration test
resizes, restarts and asks `stty` on both sides of the grave.

### Fixed: resizing reflows in the same frame

The grid waited for the daemon's layout round-trip before adopting a
new size, so every resize had a window where output for the new PTY
grid reflowed into an old mirror: the wrap artifacts you saw while
dragging the window edge. The mirror now resizes optimistically to the
window's own grid (the daemon remains authoritative: a smaller
co-viewer still letterboxes via smallest-wins), background tabs adopt
the authoritative size from layout snapshots, and the reattach repaint
nudge re-reads the model so it can no longer clobber a resize that
landed between its two halves.

### Fixed: pane geometry is computed the way it is drawn

Split sizing ignored the 6px divider grab strip, the broadcast banner's
height was never budgeted, and a maximized pane kept the small grid of
its split slot: each one a column or row the shell believed in and the
window could not draw. One geometry now (and the banner has a fixed
height so the view and the math cannot drift apart). Dragging a divider
also stops writing the session to disk on every mouse-move: ratio
updates are throttled to ~12/s with the final one guaranteed on
release.

### Fixed: selection is anchored to the text, not the glass

Selection lived in screen coordinates and was cleared on every output
frame, which made copying from a streaming TUI (a Claude session, a
build log) practically impossible: the highlight vanished or slid onto
different text. Selection now lives in the emulator, anchored to the
buffer the way VTE and Alacritty do it: it scrolls with the content,
survives streaming output, copies exactly what was swept (wide chars
and soft-wraps handled by the engine), and triple-click grabs a whole
wrapped line. Double-click word selection keeps the configurable
`word_separators`.

### Fixed: grid glyphs: icons, braille, CJK, accents

Four rendering gaps that together read as "the font looks worse than
the system terminal":

- **Nerd icons**: Symbols Nerd Font Mono (MIT, ~2.5MB) is bundled and
  every private-use codepoint routes to it explicitly, so prompt
  glyphs, powerline segments and CLI-agent spinners render identically
  on every machine instead of gambling on installed fonts.
- **Fallback prefers monospace**: cosmic-text's `monospace_fallback`
  feature is on, so glyphs the grid font lacks (braille, legacy blocks,
  CJK) come from a mono face instead of a proportional one that
  wobbles out of its cell.
- **Whole pixels**: grid text was vertically centered, which parked the
  baseline on a half pixel whenever the cell height was odd (the
  default 12.5px × 1.65 = 21px did exactly that): a uniform vertical
  blur, now gone: runs are top-aligned on integer cell tops.
- **Wide glyphs and combining marks**: a double-width glyph's underline,
  strikeout and background now span both columns, and zero-width
  characters (combining accents, ZWJ sequences) reach the renderer
  instead of being dropped.

### Fixed: renaming a session takes the caret, and keeps the icon

The row turns into a field for one purpose and then made you click it
before you could type. It takes focus now, from the drawer's own rows
and from another machine's alike.

A remote row also lost its glyph the moment you started typing and got
it back when you stopped: its editor was the field alone, while a local
row's keeps the icon beside it. Both are the same shape now.


### Fixed: closing the last tab of another machine's session closes it here too

The tab went, the far machine ended the session, and its dead tab sat
on screen waiting for something to notice.

A mirror was never told it was over. When the far host says `Bye` the
watching loop simply stopped watching: the mirror stayed in this
daemon's registry holding the last tree it saw, so the window went on
showing a session that had already ended somewhere else, and only a
later poll shook it loose. A mirror now ends the way a local session
ends, which is what tells the window and takes the row out of the
registry, so closing a remote tab behaves like closing a local one.


### Changed: a signed-in machine stays reachable with its window closed

The idle exit applied to the desktop's daemon too, and that quietly
undid what the device channel is for: fifteen minutes after closing
Termuna, a computer that was still switched on stopped being listed,
stopped accepting a new session, and took its dormant sessions out of
reach with it. Before machines were addressable this cost nothing;
now it is the difference between a promise and a footnote.

Signed in means resident, on every platform. Signed out keeps the
timeout: with no account there is nobody to be reachable for, and an
offline user should not be left carrying a process for nothing.
Checked continuously rather than at startup, so signing in mid-run
keeps the daemon alive and signing out hands it back to the clock.

### Fixed: a headless daemon stops quitting every fifteen minutes

The daemon exits after fifteen idle minutes: the desktop spawns it and
will spawn another when a window needs one, so a process left behind
with nothing live is just a process left behind. On a server that rule
inverts. Nothing is going to start it again, and "nothing live" is its
resting state, which is the entire premise of being addressable at all.

So it quit, systemd restarted it, and it read as `active` to anyone who
looked: eight restarts in two hours, each dropping the device channel
and anything running on it. `termuna-daemon` is resident now and says
so at startup. The desktop's own daemon keeps the timeout.


## [0.2.1] - 2026-08-11

Nothing in the app changed. 0.2.0 was built and published by hand,
which skipped the release pipeline and, with it, the unversioned asset
names every download button on termuna.com links to: those links 404'd
until they were uploaded after the fact.

This version exists to go out the way releases are supposed to, through
the tag. The binaries are 0.2.0's, with the version string moved on.


## [0.2.0] - 2026-08-11

### Added: a machine is a machine, with or without a session on it

The desktop is untouched by all this: it still spawns and owns its own
daemon from its own binary, and there is nothing separate to install.
The operator side of the server case is docs/SERVER.md.

`termuna-daemon` is the daemon on its own: shells, the session tree, the
mux socket and the relay, with no window bolted beside it. 10MB against
the desktop's 32, and no GPU stack, fonts or display connection for a
box in a rack to not use. `termuna-daemon login` joins it to an account
by typing what the sign-in screen asks; `installer/linux/install-daemon.sh`
fetches it, joins it and starts it as a user service that survives
logout. Per-user, no root, nothing outside your home directory.

A server can join by borrowing a token instead of being told a
password: `TERMUNA_TOKEN=<any of the account's tokens> termuna-daemon
login` mints this machine its own, with its own name and id. An account
password typed into a box in a rack is a password that now lives in that
box's shell history and in whatever provisioned it; the borrowed token
is used for one call and never written down there.

That is the easy half. The hard half was that a daemon had no address.
It reached the relay once per live session it hosted, so a machine was
only reachable *through* something it was already holding open, which is
fine for a laptop and circular for a server: it could be signed in,
listed among the account's devices, and impossible to ask for its first
session, because asking required a session.

So a daemon holds one connection of its own now (docs/PROTOCOL.md, the
device channel), and the sessions drawer offers a machine whether or not
anything is running on it. Two things fall out. Online is finally
honest, asked of the machine rather than inferred from its sessions,
which used to call a busy server gone and a closed laptop present. And a
machine that has not published a key yet is still reachable the old way,
so nothing has to be upgraded in step.

Commanding a machine still costs the vault passphrase. The daemon holds
a key of its own and publishes it wrapped to the account, exactly as a
session's content key is: the relay stores a blob it cannot read, and a
stolen device token buys what it bought before.


### Added: the account's other sessions are yours to manage

Rename, kill and wake now reach the machine a session actually runs on.
Before, every session was read-only from every screen but the one
hosting it: the drawer's right-click menu did not even open on another
machine's row, because it looked the session up in the local daemon's
list and gave up when it was not there.

The verbs are the same ones a local row offers and they are carried, not
imitated: renaming a mirror here would have lasted until the next poll,
and killing one would have ended the mirror while the shells went on
running over there, which is not what the word means.

Clicking a dormant remote row wakes it now instead of mirroring nothing.
A dormant session has no connection to the relay, which is exactly why
it needs waking, so the request travels through a live session on the
same machine and the woken session comes back with a fresh key.

A sealed row still offers no menu. Naming something is the one thing
that cannot be done without being able to read its name.

### Added: start a session on another one of your machines

The `+` in the sessions drawer asks where, when there is more than one
answer: this machine, or any other one the account can reach. Pick one
and the session is created over there, mirrored here, and walked into,
the same as clicking a row of that machine's would be.

The phone could already do this and the desktop could not, which was
backwards. Everything for it was on the wire already (`DaemonQuery`, and
a reply that carries the new session's share link sealed to the asking
session's key). What was missing was the desktop's way to reach it: the
GUI speaks no protocol but TSP to its own daemon, and the relay is the
daemon's door, so the daemon now does the asking on the window's behalf
(`MuxRequest::RemoteQuery`).

A machine is only offered when it has something live. A daemon has no
address of its own: it reaches the relay once per session it hosts, so
speaking to one means speaking through something it already holds open,
and one holding nothing cannot be asked to start anything. Nor is a
session offered as that conduit unless this device holds its key, since
the question is sealed to it.


### Fixed: macOS stops asking for the keychain on every launch

Two causes, one symptom.

The app read the passphrase out of the keyring at boot and then, having
unlocked, wrote the same bytes straight back, because "remember on this
device" was true. Every touch of a macOS keychain item is a prompt, so
auto-unlock cost two of them to accomplish nothing. It writes only when
the value would change now.

The rest was the signature. The bundle was ad-hoc signed and `deploy.sh`
re-signed it again on arrival, and an ad-hoc signature has no identity
beyond its own hash. macOS binds a keychain item's permission to the
signing identity that asked for it, so every build was a stranger and
"Always Allow" never meant always. The build signs with a stable
self-signed certificate held outside the repo now, and the install stops
re-signing. The designated requirement is the bundle id and the
certificate, both of which survive a rebuild.

A stable identity was necessary and not sufficient. macOS gives an app
free access to keychain items it created itself and guards everything
else behind the item's access list, and the passphrase already on disk
had been created by an earlier ad-hoc build. So the app went on being a
stranger to its own item. Worse, "remember on this device" updated that
item in place, inheriting its access list and re-arming the problem: the
write replaces the item now, so what ends up on disk is always something
this build owns.

An item stranded by an older build has to go once, by hand, in Keychain
Access. After that nothing asks.

Every keychain touch is logged at info level, with its outcome, because
each one is a dialog in the user's face. The outcome is the point: a
refusal returns as fast as a grant, so a fast call is not evidence that
nobody was asked, and reading it that way misdiagnosed this once.

### Changed: on macOS the window is a macOS window

Termuna drew its own minimize/maximize/close top-right on every
platform. On a Mac that is where no window button has ever been: the app
was announcing itself as a port.

So macOS keeps its real titlebar now, made transparent with its title
hidden and the content running underneath (`fullsize_content_view`). The
system's own traffic lights float over our chrome bar, top-left, with
their real colours, their real hover glyphs, and a green button that
zooms the way a Mac user expects. We draw no window buttons there and
leave 78px of room for the system's.

The wordmark is gone from the bar on macOS with them. The top-left
there belongs to the system's buttons, and the app's name is already in
the menu bar where a Mac user looks for it; a wordmark beside the
traffic lights says a second time what the screen already says once. The
column it occupied stays, empty, because it is exactly as wide as the
drawer beneath it and that is what keeps the panel toggles beginning
where the grid does.

Keeping the decorations hands back more than the buttons: the rounding,
the shadow and the resize edges come with them, so `window_radius` and
our hand-rolled resize strips both stand down on macOS. They exist for
the platforms that will not do it for us.

Drawing lookalike lights ourselves would have meant redrawing another
platform's own controls, which never survives contact with the real
thing beside it.

### Fixed: the unlock modal takes the caret with it

Clicking "Unlock" opened a modal that asks for exactly one thing and
then made you click the field before you could type it. It takes focus
on open now, from either way in (the drawer's locked row, the account
screen). Enter already submitted and still does.

The passphrase field carries two ids, one per place the form can
appear: the account screen keeps its own copy and the modal can open
over it, so a single id would name two widgets at once and focus would
have to pick between them.

### Fixed: the continuity panel reads differently on each machine

It read the same on all three, which is the one thing it exists not to
do. A machine mirroring somebody else's session is itself a viewer at
the relay, so the roster it fetches has itself in it, and the panel drew
it verbatim under a fixed "this device" row: the computer you were
sitting at appeared twice, once as "this device" and once under its own
name. Identity is keyed on the device label, not the token id, for the
reason the sessions drawer already keys on it: a token is minted fresh
on every sign-in, so the id cannot say "this computer".

The machine actually running the session is named now too. A mirror's
panel had listed every screen holding the session except the one it runs
on, and said "Not shared" about a session it was watching arrive over
the relay: it has no share link of its own, only the bridging host mints
one, but the cloud list carries it, rebuilt from the content key the
vault unwrapped. So the link and its QR are there on a mirror too.

### Fixed: a mirrored conversation is one you can take part in

Opening another machine's agent session gave an empty chat, and anything
typed into it vanished: the composer sat on "working…" while the far
machine never heard a word.

The mirror carried a terminal and only a terminal. `Layout` and `Output`
came down, `Input`, `Resize` and `Command` went up, and the whole agent
lane, `AgentFrame` down and `AgentCommand` up, was dropped on the floor
with a comment saying a terminal mirror had no use for it. For a
managed agent session those frames are not a decoration on the session,
they *are* the session: it has no PTY, and the mirror has no agent
process of its own.

Both directions now cross. Turns and asks arrive and are sequenced into
the mirror's log like output, so a window that reattaches gets the
conversation back. Token deltas and the attention nudge are passed
through unsequenced, exactly as the far host sent them: the far host
already decided those describe a moment and should not be replayed.
Upward, saying something, answering a permission ask, interrupting and
changing the permission mode all go up the link instead of looking for a
local agent that does not exist, and an attached image goes with them,
because writing it here would put the file on the wrong machine. The
host validates what it is asked, which is where that belongs:
`bypassPermissions` stays refused.

### Fixed: a conversation on another machine opens as one

Clicking a remote agent session still landed on a terminal, and for a
managed agent that is a blank grid: such a session has no PTY at all.
The window had already worked out it was a conversation, which is why
the panel beside the empty grid read `claude · managed`.

Two things asked the question too early. The drawer's cache cannot
answer for a session this machine does not host, and the fallback (ask
the layout when it lands) was answered by the wrong layout: the daemon
stands a nameless placeholder tree up the moment it starts mirroring, so
the attach has something to show, and replaces it when the far host's
real tree crosses the relay a moment later. The placeholder said "not an
agent", and nobody asked again.

So the placeholder no longer answers, and the question rarely reaches it
now anyway: the cloud list already knows, which is what the row's glyph
was drawn from.

### Fixed: a conversation on another machine looks like one

A remote agent session wore the shell glyph in the sessions drawer, so
the list called a Claude conversation a terminal until you opened it.

The drawer had no way to know better. A local session carries its whole
tree, agent and all; a remote one arrived as a name, a device and a
liveness flag, because the relay stores the tree sealed and cannot read
it to tell anyone what is inside. It hands the sealed tree over for live
sessions now (termuna-website, 2026-08-10) and the desktop opens it with
the content key it already unwraps for the title, so the row says what
the local ones have always said. Dormant sessions still carry no tree:
that would be most of a megabyte of ciphertext to decide a few glyphs.

Reading it takes unwrapping a frame first, not just unsealing a blob:
what the relay retained is the host's whole encoded `Layout` frame,
since its job is to replay those bytes to viewers verbatim.

### Added: a machine with no connection says so

A device heading in the drawer whose sessions are all idle now carries a
quiet `offline`. Nothing on that machine opens and nothing new starts
there, and a heading that looks like every other one promises otherwise.

Only honest because the relay stopped believing a closed laptop
(termuna-website, 2026-08-10). A suspended machine does not hang up, it
goes quiet, so a MacBook with its lid shut counted as a live host for
hours.

### Added: Termuna runs on macOS, built from Linux

There is now a macOS build, and it is produced the same way the Windows
one is: cross-compiled on the Linux box, shipped to the Mac already
assembled. `scripts/build-macos-app.sh` links an arm64 binary with clang
and lld: no osxcross, no zig, nothing on the host that the Windows
cross build did not already install, and wraps it in `Termuna.app`
with an icon drawn from the same moon-cursor geometry as every other
surface. `scripts/macos-qa/deploy.sh` installs it per-user into
`~/Applications` and launches it in the logged-in session.

The one thing that cannot be cross-compiled away is Apple's SDK, which
may not be redistributed; `docs/MACOS-QA.md` says how to copy one off a
Mac and covers the rest of the loop, including the two permissions macOS
demands before an SSH session may screenshot or type.

First run on an M4: Metal selected on its own, the daemon spawned and a
shell attached in 97 ms, first frame at 100 ms, inside the 300 ms
cold-start budget.

### Added: another machine's session opens here, not in a browser

Clicking a session on one of the account's other machines used to open
a browser tab. That was expedient, not right: the desktop is a terminal.

It now opens in the window. `termuna-mux::remote` is the mirror image
of the cloud bridge: there this daemon is a session's *host* and
pushes it to the relay, here it is a *viewer* and pulls one down. Same
wire, same content key, opposite direction. The mirror is registered as
an ordinary `SessionHost`: same registry, same broadcast channel, same
`attach_viewer`. So the window opens another machine's session by
attaching to its own daemon, exactly as it does for a shell downstairs,
and not one line of the UI knows the bytes crossed the internet, which
is the layering rule, and it keeps the network and the keys in the
process that already holds both.

Only two places know the difference: input goes up the link instead of
into a shell, and a structural change (a split, a resize) is a
*request* rather than an edit: the far host makes it and the layout
comes back. Acting locally would fork the tree between two machines,
only one of which runs the session. Mirrors are never listed and never
persisted: a view of somebody else's session must not come back after a
restart as a dormant session of ours.

A guest's resize does reach the host, and the host takes its own size
back when the guest leaves: the relay side of that already existed
(smallest size across live viewers, guest sizes expiring 15s after the
guest stops asserting them). The gap was ours: the window only sends a
resize when its own window changes, so a mirror would have been
forgotten mid-watch and the session would have snapped back under us.
The mirror now repeats its size every 5s.

### Changed: a locked machine is one row, and that row is the way in

A machine whose sessions cannot be read yet used to print one "sealed"
row per session and offer a faint line of text at the foot of the
drawer to do something about it. Both halves were wrong. N identical
anonymous placeholders are noise, and noise with no remedy attached is
the worst kind; and the exit was quiet in exactly the situation where a
person is most stuck, sitting far from the thing it fixes.

Each such machine is now a single bordered row under its own heading:
a lock, how many sessions are there, and `unlock`. It says the true
thing (that there are two of them and that they are shut) and it is
itself the button. From `docs/design/termuna-ui-v6.html`, where the
three states are walkable with `?s=solo|locked|open`.

All or nothing, never half: a session's title is wrapped to the account
key the moment its host hears the account has one, and refreshed on
every reconnect, so either the account has no key and nothing is
readable, or it has one and this device is locked, or it is unlocked
and everything is. Checked against production before relying on it:
zero sessions with a device and no wrapped key.

### Added: the passphrase can be entered where the lock is felt

The vault passphrase was asked for on the ssh screen and nowhere else,
so a signed-in person looking at sessions named "sealed" had no way to
learn what the word meant or what to do about it: the key was asked
for in the one place they had no reason to look. One form now, three
doorways: the ssh screen, the drawer (an "unlock to read names" row,
which appears only while something is sealed), and the account screen,
where a locked passphrase is a row that says what it costs. Unlocking
closes the card and re-reads the names immediately rather than leaving
"sealed" up until the next minute-tick.

### Added: the sessions drawer knows about your other machines

Sign in on a second machine and the drawer stops being a list of this
computer and becomes a list of the account. Live and idle stay the top
division, because that is the one that decides what you can do: a live
session takes a keystroke now, an idle one has to be woken first, and
the machines are the division inside each, this device always first.
Never the other way round: group by machine at the top and "what is
running" ends up scattered across every heading.

Only machines running a daemon appear. The relay stamps a session's
device from the token that attached as its *host*, and only a daemon
ever does that: a phone attaches as a viewer, so a phone cannot become
a heading here. It stays in the account's device list, where it means
something.

With one machine signed in nothing changes: nesting a single group
under a single heading buys nothing and costs a line.

Which machine you are on is worked out, not looked up: `[cloud]
device_id` only exists if the install signed in after that field was
added, and trusting it made an older install list its own computer as a
stranger, under its hostname, beside the sessions it had already
printed. The daemon is the authority on what it hosts: every row the
relay reports that the daemon also has is ours, and the device stamped
on those rows is this machine's whatever the config believes.

The pieces for this had been in the protocol since M9 and unused:
`AccountInfo` hands the host the account's vault public key, and the
host answers with `SessionMeta`: the session's content key wrapped to
the account, and the title sealed with that key. The relay stores both
and can read neither. So the desktop lists the account's sessions with
the device token alone, and opens their names with the vault
passphrase: locked, a machine shows how many sessions it has and calls
them "sealed"; unlocked, they have names. Nothing is faked in between.

Clicking one opens it in the browser through a share link rebuilt from
the unwrapped key: a session this machine was never handed a link to.
The desktop is a host, not a viewer, so that is the honest way in.

### Fixed: signing out lets go of the account's sessions, and says so first

A session bridged under one account stayed bound to it forever. Sign in
on that machine as somebody else and the daemon reconnects the same
session id with the new token; the relay's upsert carried a
`WHERE sessions.user_id = ?` guard, so the row silently refused to move
while the socket stayed open and the host streamed happily into a
session its own dashboard would never list. The app showed it live,
synced, with a share link. The cloud had never heard of it. Nothing
anywhere said why.

Sign-out now asks first, in a card that names what it costs: this
machine stops syncing, N sessions leave the cloud and their share links
stop working, and (the half worth saying) they keep running here.
Confirming releases each of them from the account (`POST
/v1/sessions/{id}/release`, which unlike `DELETE` does not refuse a
running session, because that is exactly the case) before the
credentials that prove they are ours are dropped. A relay that cannot
be reached does not block it: leaving an account has to work offline.

On the relay, a host attaching to another account's session is now
refused outright with a reason instead of accepted and orphaned, and
the `SessionMeta` write is guarded by owner: it had none, so the new
account's host was overwriting the old account's wrapped key with one
wrapped to the wrong vault, leaving a row its owner could no longer
open.

### Fixed: signing out signs the daemon out too, on Windows as well

The window signed out and the daemon carried on. The call that tells it
to drop its cloud settings was wrapped in `#[cfg(unix)]`: a leftover
from before the daemon spoke over a named pipe (`MuxConn::connect` has
had a Windows implementation since 2026-07-23, and `set_cloud` was
never gated). So on Windows a sign-out cleared the window and left the
daemon bridging every live session to the relay under the old device
token, still minting share links, until somebody restarted it. It is no
longer conditional on the platform.

Sign-out also took only half of the account with it. `clear_cloud_auth`
removed `token` and `email` and set `enabled = false`, leaving `name`,
`avatar_url` and `device_id` in `config.toml` and their copies in
memory. The next account to sign in on that machine was greeted by the
previous one's name and picture until a profile fetch happened to
correct them, and the stale `device_id` named a device row the install
no longer owned. Every key `[cloud]` holds about a person now goes; the
relay and share-base URLs a self-hoster set stay, because those are not
the account's to take away.

### Added: point a phone at the share link

The continuity panel can now show the share link as a QR code, under
"Scan with phone". A share URL is a capability: `…/s/<session>#k=<key>`
which nobody is going to type into a phone, and copying it there
needs a channel that then holds the key. A camera needs neither.

The code is generated on this machine (`qrcodegen`, no dependencies of
its own, no network): running a capability URL through somebody's QR
service would hand them the session, which is the same rejection the
relay gets. It is hidden until asked for, and hides again with a second
click, because the line the panel prints beside it deliberately shows
the place and not the key, and a QR shows everything to anyone who can
see the screen. It follows the link it stands for: a session that
re-bridges is issued a new key, and the code is regenerated rather than
left pointing a phone at something it can no longer decrypt.

It is drawn as a light card even on a near-black panel: a reader
thresholds on luminance and the inverted-code case is still where cheap
scanners give up. Verified by decoding it back out of a screenshot of
the running app: the payload matches the URL the daemon minted, key
fragment included, and still reads at half the screen's resolution.

### Added: the window has corners

Termuna's window is rounded now: 9px, square again while maximized,
because a rounded corner flush against the screen edge is not a corner
but a notch showing the desktop through a screen that should be full.

The window has drawn its own chrome since v6, so the rounding is drawn
too rather than asked for: the surface is transparent, and the two
widgets that own the window's corners: the chrome bar at the top, the
status bar at the bottom: carry the radius. Under them the view sits
on an opaque ground rounded to the same radius, because a transparent
surface means a widget that paints no background of its own no longer
falls back on the application's colour but falls all the way through to
the desktop; the split dividers, which were deliberately drawn at
`alpha 0.001`, did exactly that, and now paint their own seam. The only
see-through pixels in the window are the four corners. Without a
compositor those pixels are undefined and the window simply looks the
way it looked before.

### Fixed: a narrow window keeps its titlebar

Below 720px the chrome bar used to disappear: v6 defines that width as
the grid and the status bar and nothing else. That is right for what
the bar draws and wrong for what it *is*: with OS decorations off it
is the window's only title, drag handle and set of window controls, so
a narrow window could not be moved, minimized, maximized or closed with
the mouse, and lost its two upper corners with the bar. The bar is now
in every width class, stripped at quake to the mark, the session name
and the three controls: the panel pins go, because there is nothing to
pin at that width and they were dead buttons, and the share link goes
for room. The tab strip is still the first thing a narrow window gives
back.

### Fixed: one right-click, one menu; a tab looks clickable

Right-clicking a tab opened two menus stacked on each other: the tab's
own, and the pane context menu behind it. Canvas events reach every
pane whether or not the cursor is on that pane, and the terminal's
right-press handler took the cursor's window-absolute position without
first asking whether the click had landed inside its own bounds, so it
answered right-clicks meant for the tab strip, and for the drawers and
panels too. It now opens only for a click that is actually in the pane,
which also means a right-click in a split can no longer be attributed
to its neighbour.

Tabs also show the pointer cursor on hover now, instead of the plain
arrow. The close × already did; the tab itself did not, and a click
target that does not say so reads as decoration.

### Changed: asking a tab a question no longer switches to it

Right-clicking a tab used to activate it first, which meant you could
not so much as read the menu of another tab without leaving the session
you were working in. It did that because every row the menu offers
(move left/right, close to the right, close others) acted on whatever
tab was active. Those rows now name the tab the menu belongs to, so the
menu can be opened, read and used on any tab while the one you are
working in stays on screen. The keyboard shortcuts beside them still
belong to the active tab, so they are shown only when that is the same
tab; a hint that would do something else is worse than no hint. Moving
a tab from the menu also closes it, instead of leaving it hovering over
the slot the tab has just left.

### Fixed: dragging a tab feels like carrying it

Tab drag-reorder was rebuilt. Three things were wrong with it:

- **It never let go.** The release was only heard by the strip itself,
  so a drag that ended anywhere else (over the grid, over a panel)
  left the tab still attached; the next time the pointer crossed the
  strip, with no button held, the tab shuffled again. The drag is now
  followed at the window and ends wherever you let go.
- **It landed in the wrong slot.** The drop target was computed from a
  tab width the drag worked out for itself, and its arithmetic had
  forgotten the search and split glyphs at the end of the strip. Past a
  handful of tabs it disagreed with the strip you were looking at.
  There is now one definition of the slot pitch and both read it.
- **It juddered.** The target came from "which slot is the pointer in",
  but the strip reorders under the pointer, so the tab chased itself
  across every boundary. It is now measured from the press: half a slot
  of travel per swap, in either direction, and a drag out and back
  leaves the tab exactly where it started.

The chip you carry was redrawn to match the rest of the app: chrome
tokens instead of the terminal colour scheme, the tab's own pitch and
ordinal and mono face, the accent rule the active tab wears, and a
neutral depth shadow: it floats, so it casts a shadow, and never a
glow. It also sits where the tab would be rather than 50px left of the
pointer, which is where the old ghost drew itself whenever the sessions
drawer was pinned. The pointer reads the strip as a grab surface while
a tab is in hand.

### Fixed: a rebuilt shell starts on a clean screen

The "session rebuilt" line, the new prompt and (for an agent session)
the program restarted into it were all being drawn on top of the
screen the dead process left behind: interleaved with its corpse,
with the cursor stranded wherever that process had parked it. A pane
whose shell has just been replaced now clears its screen first. The
scrollback above is untouched: that is history, and it is the reason
to resurrect a session at all.

### Fixed: a repainting pane's log is recognised even when it starts mid-repaint

The last hole was the one that could not be seen from inside the bytes.
A pane's retained log is capped, so for a program that repaints
continuously the window almost always begins *inside* the repaint,
the sequence that entered the alternate screen was evicted hours ago,
and nothing that remains says what it is. The filter had nothing to
recognise, so it replayed the lot: fragments of frames scattered
across the screen, which is what a resurrected agent session looked
like.

The daemon watched those bytes go past, so it is the one that knows.
It now records which panes were repainting when it last saved the
session, and a log read back for those panes is discarded rather than
replayed. Logs written before this carry no such record; the ones
belonging to agent sessions were moved aside on this machine, since
their contents could never have been shown.

### Fixed: no program's modes outlive the program

The clicks that printed `64;51;11M` had one more hiding place: the
chunk in which a program takes the alternate screen usually turns
mouse reporting on in the same breath, and that chunk was still being
kept as history. Replay it at a pane now running a fresh shell and the
mirror believes the mouse is wanted again.

An alt-screen span now leaves the log whole: the entering chunk with
it, and the same filter runs over logs read back off disk, so
sessions recorded by older builds are cleaned as they load. On top of
that, every pane's mirror is handed a switched-on terminal (no
alternate screen, no mouse reporting, no bracketed paste, cursor
shown, attributes and scroll region cleared) before a single line of
history is replayed onto it.

### Fixed: a rebuilt session no longer types mouse codes at you

Scrolling in a session the daemon had rebuilt printed streams of
`64;47;22M` into the shell. The modes belonged to the program that
died with the old daemon: a full-screen TUI turns mouse reporting on
and every viewer's mirror still held them, because a mirror is not
restarted when the shell under it is replaced. The wheel dutifully
sent mouse reports; the fresh bash had never asked for any, so it
printed them as text.

A rebuilt session now says outright that its terminal is new: leaving
the alternate screen, mouse reporting, bracketed paste and application
cursor, cursor visible, scroll region and attributes reset: sent to
every viewer just before the "session rebuilt" line.

### Fixed: repaint frames are no longer kept as history

Output a program writes while it holds the alternate screen is one
screen being redrawn, not scrollback. It was being retained anyway:
kept in the replay log, persisted to disk, and handed back on the next
attach or resurrection, where it could only arrive as fragments of
frames. It is now sent live and not kept, which also stops a single
TUI session from filling the retained log within minutes, as the
roadmap noted it did.

### Fixed: reattaching to a full-screen program no longer shows torn glyphs

Opening Termuna onto a session running Claude Code (or vim, or htop)
painted a mangled screen: fragments of several redraws stacked on each
other, words fused together, nothing readable.

The cause is one the roadmap already described for phones, which the
desktop had been spared only because it used to stay attached from the
moment a session began: until launch started walking into an existing
session. A joining viewer builds its screen by replaying the daemon's
retained output, and for a program that repaints in place that window
holds the tail of a repaint stream: half-drawn frames with no
beginning. Replaying it can only produce garbage.

So the daemon no longer replays it. It now tracks which panes hold the
alternate screen (watching the mode sequences go past: it still does
not emulate), replays each such pane's history only up to the moment
the program took the screen, puts the viewer's mirror on the alternate
screen, and nudges the pty size so the program repaints itself in
full. The viewer gets one clean frame, drawn by the program, at the
right size, and the shell history from before is intact underneath,
back on screen the moment the program exits.


### Added: eleven things a daily-driver terminal is expected to have

Surveyed against Tabby (the terminal the maintainer was switching
from) and picked what earns its weight:

- **Paste guard.** A multi-line paste shows what is about to run,
  line count, character count, the text itself: before a single
  newline reaches the shell, because a paste is keystrokes and the
  second command runs before the first can be read. Every paste is
  also normalised: CRLF and lone CR become LF (a Windows clipboard
  would otherwise submit twice) and trailing whitespace goes.
  `[terminal] warn_on_multiline_paste`, `trim_paste`.
- **Search options.** Match case, whole word and regular expressions,
  as three toggles beside the hit counter. A half-typed pattern finds
  nothing rather than erroring.
- **Zoom that stays zoomed.** Ctrl+Shift+plus/minus now writes the
  size to the active appearance profile, and Ctrl+Shift+0 returns to
  what that profile says.
- **Copy current path** (Ctrl+Shift+P): the focused pane's working
  directory to the clipboard.
- **Word separators** (`[terminal] word_separators`): what a
  double-click treats as one word. The default keeps paths and URLs
  whole.
- **Reopen closed tab** (Ctrl+Shift+R), five deep.
- **Broadcast input**: type into every pane of a tab (Ctrl+Shift+I)
  or every tab of the session (Ctrl+Alt+Shift+I): four servers, one
  keystroke. A warm border and a line above the grid say it is on;
  esc or a click in any pane ends it.
- **Maximize pane** (Ctrl+Shift+Z): the focused pane fills the tab
  and gives it back on the next press. The others keep running.
- **Directional pane focus** (Ctrl+Alt+arrows): the pane actually to
  the left, by geometry, not the next one in the tree.
- **Notifications** for background tabs: one when a quiet tab stirs,
  one when a command rings the bell. Both off by default:
  `[terminal] notify_on_activity`, `notify_when_done`.
- **Progress in the status bar.** Long commands announce themselves
  in the only language they all speak (`47%`) and the status bar
  reads it back. `[terminal] detect_progress`.

Also: a **minimum contrast floor** (`[terminal] min_contrast`, WCAG
ratio) that lifts unreadable foregrounds: the fix for a scheme's own
dark blue on a dark background. Off by default at 1.0: a colour
scheme is its author's work until the user says otherwise.


### Changed: the right button belongs to the terminal, always

Right-clicking inside a full-screen TUI (Claude Code, vim) forwarded
the click to the application and left no way to reach copy, split,
search or close-pane: exactly when a user wants them. Mouse
reporting now gets the left button, the drags and the wheel; the
context menu is ours in every mode, no modifier needed. This matches
the terminals people switch from (Tabby intercepts right-click
before its emulator sees it) and costs almost nothing: TUIs binding
button 3 are vanishingly rare, and one still exists: shift is not
needed for the menu any more, so the hint below simply teaches
selection.

### Added: the status bar says who owns the mouse

Drag inside a full-screen TUI that tracks the mouse: Claude Code,
vim, htop, and nothing gets selected, because the application asked
for those events and gets them. Termuna has always had the escape
hatch (hold shift and the mouse is the terminal's again: select,
copy, and shift+right-click for the pane menu), but nothing said so,
so it read as a broken terminal.

Now the first drag an application swallows lights the answer in the
status bar, in place of the session name: "the app owns the mouse ·
hold shift to select, shift+right-click for the menu". It leaves
when the button does. No popup, no toast: the line that was already
there simply answers the question being asked.


### Fixed: a deleted (or revoked) shared vault now leaves the machine

When an owner deleted a shared vault, or revoked this account's
membership: the other machines kept showing it forever, and worse:
their next sync quietly *recreated* the vault in the cloud from
local copies, owned by whoever synced first. Two changes close it:

- **Sync never creates a shared vault from a name's mere presence.**
  The only creations a sync performs come from a durable record of
  this device's own explicit "New vault" actions. Local copies of a
  vault someone deleted have no power to bring it back.
- **The cloud's shared-vault list is reconciled before the push.**
  Vaults it does not mention disappear locally, connections
  included. The list is never substituted with an empty default, so
  a failed fetch cannot masquerade as "everything was deleted".

### Changed: the wordmark is back, on the chrome bar

The brand came off with the old picker and never landed anywhere.
It now rides the chrome bar's top-left: beside a pinned drawer the
wordmark claims the drawer's column and the panel toggles begin
where the grid does; narrower layouts carry the compact mark.

### Changed: the organization's owner manages its vaults here too

The cloud now grants an org's owner management over vaults shared
inside that organization; the desktop follows the server's `manage`
verdict instead of the raw membership role. For an org owner, a
teammate's shared vault is no longer read-only: hosts edit, members
revoke, the vault deletes, while plain members keep the read-and-
clone model.

### Changed: the share popup says who owns the vault

The members list now shows everyone including yourself ("(you)"),
owner first, each with their role chip, plus one line of the rule:
members read and use, only the owner edits, shares and deletes.
Revoke buttons appear only when you are that vault's owner: they
were shown to everyone before, promising a verb the server refuses.

### Changed: shared vaults are read-only for members

A vault shared with you is now yours to use, not to manage: matching
the server, which refuses member writes since the same-day cloud
change. The desktop knows its role in every shared vault from the
sync: read-only vaults say so in the connections tree ("shared ·
read-only", no members/delete buttons), their hosts' menus keep
connect but disable edit/remove/share ("owner only") and offer
**clone to My connections** instead: an editable copy in your own
vault. Read-only vaults are dropped from move targets and the host
form's vault picker, and sync no longer pushes into them (a round
trip per profile for a stack of 403s).

### Changed: the command palette grew into a real launcher

Ctrl+K is now organized like the launchers it competes with: a search
row with its glyph, small-caps section headers, an icon on every row,
and a footer that spells the keys (esc close · ↑↓ navigate · ↵ open).
Three sections: **actions** (tabs, splits, search, screens, settings),
**sessions** (every known session with its freshness: "live", "3h
ago", and provider), and **ssh connections** (every saved host as
`user@host:port`, one Enter from a shell on that machine). Before a
keystroke the palette shows a curated front page: all actions, the
five freshest sessions, the first five hosts; typing searches
everything, label, meta and section alike, so "ssh prod" finds the
prod box.

### Fixed: opening links on Windows opens the browser, not Explorer

"open" on the continuity panel's share link (and every other link the
app opens) went through `explorer <url>`, which drops the URL's
`#fragment` (where a share link carries its decryption key) and
then falls back to a File Explorer window. Links now go through the
shell's own URL handler (`ShellExecuteW`), fragment intact. Verified
on the Windows QA machine: the share link lands in the default
browser and the web viewer decrypts the live session.

### Fixed: the Windows build compiles again

The cloud bridge's dead-link detection (`TCP_USER_TIMEOUT`) is a
Linux-only socket option and broke the MSVC target when it landed;
it is now cfg-gated to Linux/Android. Windows keeps the keepalive
schedule and relies on the relay-side heartbeat for blackholed
links. Verified live on the Windows QA machine.

### Fixed: the tab strip's verbs can no longer be pushed off screen

With enough tabs open, the search and split buttons (and eventually
the +) slid out of the window: the strip trusted a width estimate,
and the buttons' default padding made them wider than the estimate
said. The right end of the strip is now a fixed section the tabs
physically cannot displace: the flexible part is clipped instead,
and the controls carry explicit padding so the tab math and the
layout agree. Docs: CONFIG.md now also documents the `[quake]`
global-hotkey section.

### Removed: the full-window picker; the app is the session window now

The old home screen (sidebar + full-page sessions/agents/mcp/ssh
screens) is gone. The v6 session window already carried everything it
offered: the drawer lists and switches sessions, the management
screens open over the grid, so the picker had become a second,
inconsistent way to show the same things. There is no longer any
destination outside a session:

- **Launch always lands in a session.** The one the window was closed
  on when the daemon still has it (resurrected if it had gone idle);
  otherwise the newest live session; otherwise a fresh shell. The
  first launch opens at 1440x860: wide enough that the sessions
  drawer and the continuity panel both hold their columns, so the
  whole product is on screen at once. After that the window reopens
  at whatever size it was closed (the minimum stays 400x260; every
  narrower density still works).
- **Ending a session never strands the window.** `exit` in the last
  shell (or killing the current session) walks into the newest other
  live session, or starts a fresh shell when it was the last one. A
  dormant session is never resurrected uninvited.
- **Failures live on the connecting screen.** A daemon that cannot be
  reached or an attach that fails shows the error in-window with
  retry and new-session actions: there is no picker to fall back to.
- **Quake can summon screens too.** A palette command opens
  agents/mcp/ssh/settings over the grid at any width now; quake no
  longer detours anywhere (the old behavior left for the picker).
- The "back to sessions" actions (palette, chat header) now open the
  sessions screen over the grid: the full filterable list the old
  picker had, same rows, same badges.
- Internals for future work: `Phase` is just `Connecting`/`Terminal`,
  `app/picker.rs` became `app/screens.rs` (the management screens +
  modals, one router `view_nav_content`), `PickerNav` is `NavScreen`,
  and the picker-only sidebar/rail/cross-fade/slide machinery is
  deleted. The `[ui] sidebar_collapsed` key is parsed but ignored.

### Changed: one window, three densities (UI v6)

The session window now scales its chrome with its width
(docs/design/termuna-ui-v6.html): power grows with the pixels you give
it, and growing the window never adds chrome by itself:

- **Narrow (under 720px, quake):** the terminal grid and the status
  bar. Nothing else: the drop-down window costs zero chrome.
- **Default:** the tab strip and the grid, as before. The sessions
  drawer and the continuity panel open on demand as overlays (toggles in
  the tab strip / chat header) and give every pixel back on esc or a
  click outside.
- **Wide (1400px and up):** a pin turns each panel into a real column,
  sessions drawer on the left (live and dormant sessions, attention
  badges, agents/mcp/ssh/settings nav, account), continuity panel on
  the right (which screens hold the session now, the share link, the
  session's facts, the encryption state). Pins persist across restarts.

From inside a session, the nav no longer leaves for the picker: agents,
mcp servers, ssh, settings and account open in the centre column over
the grid, behind a bar with the way back: the shells keep running
underneath, and esc returns to them. Switching sessions happens in
place from the drawer, including into an agent's chat.

New: a status bar on every width: the mark, the session and where it
is, this process's measured memory, and whether it syncs (e2e) or
stays local.

New: the window comes back the way you left it. Closing (the × or the
WM's close) persists the unmaximized size, whether the window was
maximized, and the session on screen; the next launch opens at that
size, re-maximizes if needed, and walks straight back into that
session: resurrecting it if it had gone idle. Leaving for the picker
first means the next launch lands on the picker, and a session that
no longer exists falls back there too.

New: the window draws its own chrome bar (OS decorations are off),
panel pins on the left, the window's name centred, the session's web
link and minimize/maximize/close on the right. The bar drags the
window, a double click maximizes, and invisible edge strips take over
border resizing. Quake width shows no chrome at all, as before.

Luna Dark now paints the grid the way the design draws it: ink-black
background, quiet grey prose, and the chrome's accent family as the
ANSI hues (green `#4fd6a8`, blue `#6e9fd4`, red `#d96a5f`, yellow
`#d6a24f`): a default prompt looks exactly like the mockup. The ramp
stays honest (green is green); the cursor keeps the luna brand teal.
The active tab now merges with the grid and carries a 2px accent on
its top edge; tab titles are set in the mono face. The default grid
metrics are the design's too: 12.5px JetBrains Mono at 1.65 line
height (existing configs keep whatever they say). Grid text is
pixel-snapped, and bold text renders the real Bold face: the bundled
bold TTFs carried a wrong weight class (558), which made the renderer
lay synthetic bold over the already-bold outlines: every prompt came
out smeared and overweight.

### Fixed: a conversation you come back to comes back with itself

Three faults, one symptom: opening a chat you had left gave you an empty
screen, or a screen where the agent looked like it was re-running your
last message.

- **The conversation was never written to disk.** The session log is
  persisted while frames arrive, at most every three seconds, and the
  frames that matter are the last ones. A turn ends, nothing else is
  sent, and everything since the previous write is still only in memory,
  so a dormant chat came back empty. It is now written at the moments
  the flow stops: the end of a turn, an ask the agent is blocked on, and
  when the agent process goes.
- **"Continue" from the agents list did not continue anything.** The
  session id being resumed was dropped on the way into session creation,
  so it started a *fresh* conversation in the same directory: a
  stranger who had never met the work. It is passed through now.
- **A resumed conversation now arrives with its history.** Such a
  session is new and has no log, and the CLI loads its history into the
  model's context without saying a word of it on the stream. The host
  reads the provider's own transcript once, at resume, and seeds the
  replay log with it (last 200 turns), so every client: desktop, web,
  phone: gets the conversation it picked. This is not the transcript
  *tailing* ADR 0005 removed: nothing follows the file, and every frame
  after the seed comes from the SDK stream as before.

Seeded frames carry `termuna_replay` (docs/PROTOCOL.md) and no client
starts a turn on one. Without that, an old message read as a message
being picked up and the composer sat "working" on a turn that had ended
days ago, which is what "it re-sent my message and the agent worked on
it" actually was.

### Changed: an agent conversation is headed by the agent glyph

The chat header led with the brand mark, which says "Termuna", and the
window already says that. It now carries the same agent glyph that marks
"agents" in the sidebar and every agent session in the picker, so one
picture means one thing wherever it appears.

### Fixed: the effort dial showed the wrong model's levels

The running model is reported by its *resolved* id, `claude-opus-5[1m]`,
which is a different string from the one `set_model` takes, `opus[1m]`.
Matching the running model against the catalog by that second string
found nothing, so the dial fell through to the `default` entry and
offered its levels instead of the running model's: five where Sonnet
takes two, say. The catalog carries `resolvedModel`; it is now read and
matched on, here and in both other clients.

### Fixed: a deleted connection stays deleted

Removing an SSH host took it out of the local vault and left the copy in
the cloud alone, so the next sync: the one that runs at startup,
pulled it straight back down. Delete, restart, and there it was again.

The vault now records the deletion as well as performing it. A sync
carries those records up before it pulls anything down: each one becomes
a `DELETE` of that item in the vault it belonged to, and only then is it
forgotten. A deletion made offline, or against a shared vault this
account may not write to, stays recorded and is filtered out of the
merge, so the connection cannot come back while the deletion is still
owed. Deleting now also syncs immediately when the cloud is configured,
so the other devices hear about it without waiting for a restart.

Verified end-to-end against a local cloud service: delete online (the
cloud item goes with it), and delete with the service down, then restart
with it back up: the connection stays gone and the deferred delete
lands. Records are capped at 256 so one that can never be flushed cannot
grow the file forever.

The other half of that is a second device that still holds the
connection and has not heard: on its next sync it would push the profile
straight back. The relay now remembers deletions too (termuna-website,
schema v12), refuses a push of a deleted id, and lists the deletions
beside the items, so a sync also carries them *down*. A connection
deleted on the phone disappears from the desktop, and a device that was
offline through the whole thing cannot undo it when it returns. A
deletion heard from the cloud is applied without being recorded again:
we heard it there, so telling it back would be an echo. Against a server
too old to send the list, nothing is dropped and the behaviour is
exactly what it was before. Verified with a real GUI as one device and
the API as the other, in both directions.

### Fixed: half the model menu did nothing

Picking Opus or Fable had no effect at all: the daemon dropped the
request before it ever reached the agent. Its model ids are validated by
a checker written for shell words, and the CLI names two of its own
models `opus[1m]` and `claude-fable-5[1m]`: brackets and all. Both were
refused as junk.

The refusal was silent, and the label went on truthfully showing the
model that was still running, which is what made it look like the pick
had been ignored rather than rejected. It had been rejected.

Model ids now have their own check, wider by exactly two characters and
no more: still not a shell sentence. The launch path that does build a
shell line quotes the model, so a bracketed id cannot be read as a glob.
This applied to starting a session as well as switching mid-conversation:
launching *on* Opus was refused the same way.

### Fixed: the model and effort you pick actually stick

Picking a model changed nothing on screen, and the composer sometimes
went to "queue another message…" and stayed there. Two faults behind one
symptom, both about a frame the CLI sends that we were reading wrong.

The model label waited for a `system/init` frame naming the new model.
That frame comes once, when a session starts, and never again, so the
label sat on whatever it said before, or on nothing. The daemon now asks
`get_settings` right after any `set_model` or effort change and lets the
answer be what the clients show: a request we sent is not evidence it
was honoured.

What the CLI *does* send back is a user-role frame reading
`<local-command-stdout>Set model to sonnet (claude-sonnet-5)</local-command-stdout>`
shaped exactly like our own echoed message, down to `isReplay: true`.
Only the wrapper tells them apart. We were reading it as a message being
picked up, marking the agent busy, and then waiting forever for a
`result` that was never coming, because no turn had started. The chat
log already filtered these; the busy flag did not, and now does.

### Fixed: the chat says which effort it is on

The effort dial drew five identical dots with none of them filled, and
the model row read `default`, until the first message had been sent.
Neither was a display bug: nothing had ever asked. The CLI does not
volunteer its model until the `system/init` frame, which does not arrive
until a session starts, and it never volunteers the effort level at all.

The daemon now sends a `get_settings` control request right behind the
`initialize` it already sent. The reply says what the agent is actually
running on, so the menu shows the real model and the real effort level
before a word is typed, and the effort is named next to the dots, not
only drawn, because five dots and a hover tooltip do not tell you which
one you are on.

### Changed: the agent's own catalog, instead of ours

The model picker listed four names Termuna had hard-coded: `default`,
`sonnet`, `opus`, `haiku`, and the slash menu ten commands from the
same kind of table. Both were guesses that could only go stale.

The daemon has always sent the CLI an `initialize` control request at
spawn, and the reply carries the CLI's own catalog. Termuna now reads
it:

- **Models** come with the names and descriptions the CLI gives them,
  "Opus (1M context) · Opus 5 with 1M context · Best for everyday,
  complex tasks", and the list is whatever that install actually offers.
- **Effort levels are per model.** `max` is a real level and the
  hard-coded four had hidden it; a model that takes no effort now shows
  no dial rather than a dial that would be refused.
- **Slash commands are the CLI's own**: sixty of them here, including
  every skill and plugin the user has installed, which no table of ours
  could have listed. Whether picking one runs it or drops it in the
  composer follows the CLI's own argument hint: `<required>` waits for
  you, `[optional]` and `<optional …>` go straight out.

The static tables stay as the fallback for providers that answer no such
request, and for the moment before the first one arrives. Names and
descriptions are clipped to their columns, because iced draws unwrapped
text at full length rather than shrinking it, and two unclipped columns
in a fixed-width menu write over each other.

### Added: the rest of the agent's control surface

The CLI's SDK protocol carries more than "say this" and "allow that";
Termuna now speaks the parts a person actually reaches for. Four
additive `AgentCommand` variants (`docs/PROTOCOL.md`), each validated
host-side and each mapped to the CLI's own control request:

- **Switch model** mid-conversation (`set_model`). The menu lists the
  daemon's catalog for the provider plus whatever the CLI reports it is
  running, and the tick follows the CLI's `init` frame rather than our
  last request: a refused switch must not leave the label lying.
- **Thinking** on or off (`set_max_thinking_tokens`). A switch, not a
  budget: a person decides *whether* the model should think, and the
  daemon turns that into the SDK's number.
- **Effort**: whichever levels the running model takes
  (`apply_flag_settings`), as a named row of dots in the modes menu.
- **Rewind the files** to before any of your messages (`rewind_files`).
  A dry run goes first, so the card names the files it would restore
  before you commit to it; when the agent has file checkpointing turned
  off it says so in the agent's own words, and which setting turns it
  on. This restores *code*, not the conversation: the CLI has no
  conversation rewind on this channel, and pretending otherwise would be
  the wrong promise.

Everything the CLI already reported and Termuna was discarding is now
read: `system/init` names the model, `system/status` corrects the
permission mode (so a `/model` or a plan-mode exit shows up even though
it happened without us), `result` carries the model's context window,
`compact_boundary` empties it, and `TodoWrite` calls are the agent's
plan.

- **A context meter** in the header: `42% context`, click to compact,
  instead of a token count with no denominator. It appears after the
  first answer, because that is when the CLI says how big the window is.
- **The agent's plan**, as a count in the header and a floating panel
  that does not reflow what you were reading.
- **Queued messages** are shown when an interrupt reports them still
  waiting.
- The rewind affordance appears only on turns the CLI gave an id for; a
  message drawn optimistically now inherits that id from the echo
  instead of dropping it.

### Added: the agent chat gets a composer that can do something

- **Permission modes.** A control beside the send button puts the agent
  in **manual** (asks before every edit and command), **edit
  automatically**, or **plan** (explores and proposes, changes nothing).
  **Shift+Tab** walks the three. The daemon and the wire have carried
  `SetPermissionMode` since M11; until now nothing on the desktop sent
  it. `bypassPermissions` is *not* offered, because the daemon refuses
  it from any client and a button that silently does nothing is worse
  than no button.
- **A `+` menu**: upload a picture from this machine, or start an `@`
  mention to point the agent at a file.
- **A command menu** on the `/` button: everything the composer can do,
  in one filterable list: attach, mention, the provider's own slash
  commands, the modes, and the way back to sessions. Commands that need
  an argument (`/model`, `/resume`) land in the composer for you to
  finish; the rest are sent as they stand, because there is nothing left
  to type. Enter runs the first row the filter leaves standing.
- **Esc stops the turn**, and the working row says so: it now carries a
  live clock (`working · 12s`) instead of a bare "working…".

### Changed: the chat, on the v5 tokens

- The composer is one card: the message line, and under it the controls
  that decide what the message can do. The send square lights when there
  is something to send and becomes a stop square while the agent works;
  the placeholder says *queue another message…* rather than pretending
  Enter does the same thing it did a second ago.
- An empty conversation shows the mark, the agent's name, and where to
  start, instead of a grey sentence apologising for being empty.
- What you said sits in a quiet bordered block; what the agent said is
  simply the page. The filled accent bubble made every question shout
  louder than every answer. Prose is Inter whoever wrote it, code stays
  monospace and highlighted, and streaming text now arrives in the same
  furniture it settles into rather than flashing a box on the way in.
- The header is icons and a hairline: the project, the token count, the
  terminal view where there is one, and the way back.

### Changed: the SFTP drawer, redrawn

- The files pane followed the redesign in `termuna_files_pane_redesign
  .html`: a header with sort, refresh and close; the host and path
  above the filter; **folders** and **files** as named groups; and a
  footer that says what is here (`127 items · 1.2 MiB`) beside **New**
  and **Upload**.
- Sizes live in a column of their own, right-aligned, so you can read
  down them. They are written short: `68.8 M`, `2.6 K`, `0 B`,
  because `454.5 KiB` wrapped to a second line and dragged the row
  with it.
- Dotfiles are folded away behind `hidden · N entries` and shown dimmed
  when you ask. They are most of a home directory and almost never what
  you came for.
- Row actions appear on hover, in place of the size, so nothing shifts
  when they arrive and no row carries a pair of buttons it does not
  need. File icons are one page shape with a different mark inside,
  archive, code, patch, plain: tinted by kind: archives amber,
  configuration and code blue, everything else quiet.
- The drawer is a card: 330px with a hairline, an 8px radius and a
  neutral shadow, floating over the terminal. Nothing is painted behind
  it but its own margin: a black strip beside the card would hide work
  the card itself is not covering. Folders carry the accent at rest and brighten under the
  pointer, the breadcrumb names the folder you are in rather than the
  path you climbed, the filter has its magnifier inside it, and each
  group folds its own dotfiles away behind its own count.


### Changed: one way out, one settle, and no work for a click that changes nothing

- The ⌂ button is gone from the tab strip. The rail's own **sessions**
  is the way back, and two of them was one too many.
- Screens cross-fade when you pick them: out to the background and
  back, 190ms end to end, with the swap under the curtain so neither
  screen is ever seen half-drawn. (iced has no opacity for arbitrary
  widgets; the fade is a page-coloured curtain drawn over the content,
  which costs no layout: the earlier version moved the content and
  juddered for exactly that reason.)
- Entering a session collapses the sidebar instead of cutting to the
  rail, and leaving one opens it again. It is the same motion as
  collapsing by hand, labels and all, because it is the same slide.
- Clicking the screen you are already on does nothing. It used to
  re-run that screen's loaders: a status line, a round trip to the
  daemon and a flicker, in exchange for no change.


### Added: a live session keeps the rail

- Opening a session used to take the whole window and the nav with it:
  every other screen was behind a detach. A session now keeps the
  collapsed rail on its left: the mark, the five destinations as
  icons, the account disc, so sessions, agents, mcp, ssh and settings
  are one click away.
- The rail in a session is always collapsed and has no expand handle:
  the width belongs to the terminal. Hovering an icon still names it.
- Clicking one leaves the session for that screen. The session keeps
  running; the daemon owns it, which is the whole point of the daemon.
- The terminal grid, the tab strip and the divider drags all measure
  from the window less the rail, so the PTY is sized to what you can
  actually see.
- The "connecting…" moment now wears the chrome of wherever it is
  going: the rail on the way into a session, the full sidebar on the
  way back, so the sidebar no longer blinks out and back between two
  screens that both have one.


### Added: the sidebar collapses to a rail

- A round handle rides the seam between the sidebar and the work, at
  the wordmark's height, and takes the sidebar down to a 46px rail: the
  moon mark, then one icon per destination, then the account disc.
  Hovering an icon names it, and says its count too: a rail you cannot
  read is a rail you cannot use.
- The sidebar slides between the two widths in 180ms and the handle
  rides the seam the whole way; its chevron turns through half a circle
  as it goes, so the button says it reverses itself rather than just
  swapping for its mirror image.
- Labels appear and disappear on the width, not on a fraction of the
  animation: they are drawn while there is room for them, which is what
  keeps one from painting over the work beside it mid-slide.
- The rail is a 16px glyph centred with a gutter's worth of air, no
  wider. Expanded, the glyph column lines up with the wordmark above
  it, as the mockup's `padding: 7px var(--gut)` intends.
- The choice is remembered (`[ui] sidebar_collapsed`). A layout you
  chose that every launch undoes is not a choice.


### Changed: settings, laid out the way the design draws it

- All four sections are the mockup's `.sr` rows now: the name of the
  setting, one line saying what it does to you, and its control on the
  right, under hairline rules that group them (profile / type / cursor
  / preview, scrollback / clipboard / quake mode). Bare `−` and `+`
  buttons became one stepper, on/off buttons became switches, and the
  cursor shape became the same chips the rest of the app uses.
- Keybindings gained a search box. Sixty actions is a list you search,
  not one you scroll.
- About is the mockup's card: the wordmark, the build line
  (`0.1.0 · linux-x86_64 · iced 0.14 / wgpu`), what the app is, and the
  three promises ticked off: offline-first, no telemetry unless you
  opt in, the relay never sees plaintext.


### Added: the account screen the design asks for

- `docs/design/termuna-ui-v5.html` has drawn this screen all along and
  the app showed a grey card with two buttons instead. It is now the
  mockup's: who you are with the account disc, then the three settings
  that belong to an account: **session sync** on a real switch,
  **recovery kit**, **billing**, and then every device holding a token
  for the account.
- Devices come from `GET /v1/devices`: host, platform, when it was last
  seen, and a **revoke** for each one but the machine you are sitting
  at. Revoking that one would sign you out sideways with the config
  still claiming you were in; there is a Sign out button for it.
- New device tokens are labelled `host · os-arch` instead of
  `host (termuna desktop)`, so the platform column has something true
  in it. Tokens minted before this keep their old label and are parsed
  as best they can be, never invented.
- Session sync is a setting you can turn off from the app now. It
  writes `[cloud] enabled` and tells the running daemon at once, rather
  than waiting for a restart to become true.


### Changed: the sidebar's foot is the mockup's

- Two stacked rows: a daemon line and a boxed "account" button with
  the whole mailbox under it: are now the one row
  `docs/design/termuna-ui-v5.html` draws: a 26px account disc bearing
  the initial, the name beside it, and the daemon's own line beneath
  (`daemon · 4h 55m` behind a live dot). It is one button because it is
  one destination.
- The name and the picture come from the account. The app now asks
  `/v1/auth/me` at sign-in and at launch, remembers what it says, and
  draws the real name and the real face. An account with neither (one
  created with an email and a password, rather than through Google)
  falls back to a name derived from the mailbox,
  `soldo.devices@gmail.com` is shown as `soldo`, because everything
  after the first separator is routing, and to the initial on the
  tinted disc, exactly as before.
- The picture is masked to a disc before it reaches the renderer, which
  has no notion of a rounded image, and cached beside the session store
  keyed by its URL: a launch costs no network, and a changed face can
  never be served from a stale cache. Binary cost of the image pipeline
  and the JPEG decoder: 31.91MB → 32.52MB (+0.6MB); the installer
  budget is unaffected in practice.
- Signed out, the disc is an empty ring and the name reads "sign in",
  the slot is there, nobody is in it. The daemon reports either way,
  and a stale daemon still gets its extra line, because only that case
  needs an instruction.


### Changed: the host card is quieter, its menu is the app's own

- Clicking **⋯** on an SSH host (or right-clicking the card) now opens
  the same menu the terminal opens on right-click: icons, hairline
  separators, the destructive item in warn red. It floats at the
  pointer instead of unfolding under the card and pushing the grid
  down. Connect, edit, duplicate, share, **move to <vault>** and remove
  are all in it: the separate "move" strip and the inline confirm
  strip are gone, and removing a connection asks in the same card as
  every other question.
- A host card is one line for the name and one for the address, always.
  Both were cut to a fixed character count that a narrow card could not
  hold, so a long `user@host` wrapped and that card grew taller than
  its neighbours. The budget now comes from the card's real width, and
  neither line may wrap.
- Hovering a host no longer paints the card. A tinted slab under a
  dozen cards is noise; the glyph and the name take the luna accent
  instead, which is the same "this one" the rest of the app uses.


### Added: a vault you made is a vault you can unmake

- Shared vaults had no way out: the desktop could create one, share it
  and revoke a member, but never delete it. Every vault header now
  carries **delete**, behind a confirmation that states the two things
  worth knowing before you press it: the connections in it move to
  Personal, and everyone you shared it with loses access. Deleting a
  vault is about who can reach a group of hosts; it never throws the
  hosts away.
- The delete reaches the cloud (`DELETE /v1/vaults/:id`, owner only),
  because a vault removed only on this device comes back on the next
  sync and the teammates never lost anything. With the cloud vault
  locked the app says exactly that instead of pretending; if the server
  refuses (a member cannot delete a vault out from under its owner) the
  vault goes back in the list rather than waiting for the next sync to
  contradict it. The personal vault is refused outright: it is where
  the other vaults' connections land.
- **members** now opens in the same card as the rest of the app.


### Changed: one modal, one input, everywhere

- The forms that used to unfold inside a screen now open the way the
  start-agent dialog always did: a card over a dimmed page. **Add
  host** / **Edit host**, **New vault** and **Add MCP server** are all
  the same card, so a long list can never push the form out of sight
  and a half-filled form can never scroll away from you.
- Modals arrive and leave with a short, quiet transition: 150ms in,
  110ms out, the card settling the last few pixels and the page
  darkening with it. A dismissed modal keeps its contents until it has
  finished leaving, so it never empties itself in front of you.
- One text input in the whole app: the window's own colour recessed
  into the surface, a hairline that brightens under the pointer, the
  live accent only while it holds the caret. Search boxes, the command
  palette, the chat composer, the keybinding editor, the scrollback
  search and every field in every form now share it: as do the
  dropdowns, which are the same well with a handle.
- Settings sections are the filter chips the agents and MCP screens
  use, not underlined tabs. One list of choices, drawn one way.
- The cloud-vault line under **Search hosts** ("synced 7
  connection(s)…") had no space above it and read as the search box's
  error message. It now sits in its own row behind a live dot.


### Changed: sessions no longer come back on their own (ADR 0006)

- A daemon restart takes every shell it owned with it. On its next
  start the daemon used to respawn them for any session live within the
  last 48 hours, restore the scrollback, re-bridge and report the
  session as live: up to 32 of them, without anyone asking. On the
  phone that was indistinguishable from a session that had never
  stopped, except that the build you left running in it was gone.
- Either the process ran the whole time or it did not. Sessions now
  load dormant after a restart, with their history readable, and come
  back only when a human asks for them: from the picker, the phone or
  the web. `spawn_boot_resurrect`, the 48-hour window, the 32-session
  cap and the `[cloud] keep_alive` option are gone. (The config key is
  still parsed and ignored, so an existing `[cloud]` section does not
  become invalid and take sync down with it.)
- What you asked for, you can still see you asked for: a rebuilt
  session writes `── session rebuilt · new shell in <dir> ──` into each
  pane before the new prompt, so restored scrollback above a fresh
  shell cannot pass for continuity.
- The real fix for surviving an upgrade is a daemon that does not die
  (restart-in-place with the PTYs inherited); it is on the roadmap, and
  this change stops papering over its absence.

### Fixed: "needs you" stayed lit after the ask was answered

- The amber badge is the relay's `attention_at`, and the only thing that
  ever cleared it was a viewer's `Input` frame. A managed agent session
  has no PTY, so nobody types into it: it is answered with
  `AgentCommand`, and an ask answered on the host's own desktop never
  crosses the relay at all. The badge therefore stayed lit on the phone
  indefinitely, for an agent that had long since carried on.
- The protocol gains `AttentionOver` (additive, unit variant): the host
  says when a session stops wanting its user, whatever stood it down.
  The relay clears the flag on it, and also on a viewer's
  `AgentCommand`, which is the same human being present.
- A restart is the other half of it: a fresh daemon has no attention to
  retract, so it would have left the badge up forever. The bridge now
  states this the moment it attaches, which asks still stand, and
  whether the session wants its user at all: instead of leaving the
  relay holding whatever it was told last time.

### Fixed: a permission ask answered on one device stayed open on the others

- Allow a tool call on the desktop and the phone kept showing
  Allow/Decline for it, indefinitely. Nothing in the agent CLI's stream
  says an ask is over: the answer is a `control_response` Termuna sends
  *to* it, so a client that did not send that answer never learned the
  agent had moved on.
- The daemon now states it. When the pending set changes: an ask
  arrives, one is answered, a turn ends and abandons what it was
  waiting on: it broadcasts a sequenced frame of its own
  (`{"type":"termuna","subtype":"permission_state"}`) carrying the whole
  waiting set, and naming the one that just changed along with what the
  human chose. Carrying the set rather than only the transition is what
  makes it work for a client replaying history: the asks are in the log,
  and this says which of them still stand.
- Desktop, phone and web all render a settled card without buttons,
  "allowed", "declined", or "answered elsewhere" for one that was
  resolved while they were away.

### Fixed: after a daemon restart, an agent conversation stopped arriving in the cloud

- The relay stores frames by sequence number. The daemon's counter is
  recovered from the persisted frame log, but that log was only ever
  written by the PTY output pump, and a managed agent session has no
  PTY. Its counter therefore restarted at 1 on every daemon restart, so
  the relay overwrote its own stored history row by row and every frame
  the daemon sent was dropped as one it had already seen, until the
  count climbed back past where it left off.
- Three changes, because one alone leaves a hole: the agent pump
  persists the session and its log on the same throttle the PTY pump
  uses; the sequence counter is also stored in the session snapshot
  (one integer, and it survives a log that was capped or never written);
  and on attaching to the relay the bridge winds its counter forward to
  the head the relay reports, so a daemon that recovered less than the
  relay kept never talks into a void.
- The bridge also announces the agent's pending asks as soon as it
  attaches, which is what retires a card left over from before the
  restart.

### Fixed: an idle session could go dormant in the cloud and never come back

- A session nobody is typing in sends nothing for hours, and an idle TCP
  flow is what a home router or a carrier NAT quietly drops. The relay's
  end then closed: it logged the host detaching and set `live = 0`,
  while the daemon's socket sat in ESTABLISHED believing it was still
  mirroring. It never reconnected, so every session read as dormant on
  the phone with the desktop running the whole time, and daemon queries
  (which route through a live session) timed out as "the desktop is
  taking a long time to answer".
- Observed on 2026-07-30: both bridges died at 21:52 with nothing in the
  daemon log, and were still dead 8 hours later against a daemon with
  18h uptime.
- `Payload::Heartbeat` has been in the protocol for exactly this and
  nothing was sending it. The host now sends one every 20s per bridge,
  which keeps the flow warm: an idle flow being what gets dropped in the
  first place. It is unsequenced, so the relay broadcasts it and stores
  nothing.
- The bridge socket also sets `TCP_USER_TIMEOUT` (60s) and TCP keepalive.
  Keepalive alone would not have helped, and measuring showed why: the
  keepalive timer only runs on an *idle* socket, and the heartbeat means
  the socket is never idle: with the link blackholed the kernel sat in
  retransmit for over seven minutes without firing a probe.
  `TCP_USER_TIMEOUT` is the one that bounds unacknowledged data, which is
  the case that actually applies.
- Measured against production by blackholing the relay's address (a DROP
  rule, so packets vanish with no RST: the same shape as a NAT
  forgetting the flow): the link died at 06:47:38 and the daemon reported
  it at 06:48:55, **77 seconds**. Traffic restored at 06:55:07; all four
  bridges were reattached by 06:55:52, **45 seconds** later. Before this
  change the same test ran seven minutes with the daemon noticing
  nothing.

### Removed

- `AgentEvent` and the transcript-tailing machinery behind it. Agent
  conversations no longer come from parsing the provider's own log file;
  see Added. Providers without a structured mode (Codex, Gemini, Cursor,
  OpenCode) still launch into a shell and are terminals with a program
  running in them (`AgentInfo.structured` says which you get) but they
  no longer produce a chat lane until each grows an adapter.
- Protocol v1. `PROTOCOL_VERSION` is 2 and v1 peers are refused. The
  frames are CBOR-tagged by name, so a v1 peer would just see unknown
  variants and carry on showing an empty agent session: the version
  check turns that silent confusion into a clear refusal. Relays and
  clients must be rebuilt; existing agent sessions do not migrate.

### Fixed: the wordmark is the brand's drawing, not an approximation

- `termuna` is drawn from outlines converted once from
  `termuna-website/assets/brand/logo-wordmark.svg`, so the letterforms are
  the brand's own. No typeface ships for one word, and the logo cannot
  come out in the wrong face if a font fails to load.
- The cursor keeps the SVG's exact geometry: 40x76 block, corner radius
  6, bite r21 at the upper-right shoulder, all relative to the baseline,
  but not its x position. The drawing puts it four ems past the word
  because it was laid out for a wider Martian Mono than the one that
  ships; the mark means "the next character of a running session", so it
  follows the last letter by a hair.
- Inter is subset to the ranges the chrome can actually show (856 KB →
  283 KB): Latin, Latin-1, Latin Extended-A for Croatian diacritics,
  punctuation, arrows and the geometric glyphs the UI draws with.
- CI reports the binary size instead of asserting it. The assertion was a
  stand-in for the installer budget; the installer is still ~5MB and
  still asserted in `windows-exe.yml`, so the proxy is what had drifted,
  not the promise. A real size pass is recorded in docs/ROADMAP.md.

### Changed: the desktop is being rebuilt on the v5 design

- `apps/termuna/src/ui.rs` makes `docs/design/termuna-ui-v5.html`
  executable: the ink ladder, accents, metrics and type scale as tokens,
  one per CSS custom property. The app chrome used to take its colours
  from whatever terminal scheme was loaded, so it could not match a
  design at all, and looked nothing like the phone. The scheme now does
  the one job it should: painting the grid.
- Inter ships beside JetBrains Mono. Prose in sans, anything a machine
  produced in mono: the same split as the phone.
- Shell and sessions screen rebuilt: a sidebar with counts and a left
  accent rule on the active item; a row that reads running → name → what
  it is → when it was touched, with a rule down the live ones' left edge
  instead of a box, and actions held back until the pointer arrives.
- The desktop chat's parser is written against the SDK stream instead of
  the transcript file it used to read. That file is gone, and its quirks
  were still in the code doing the wrong thing on fields the stream
  spells differently: compaction numbers were read as `compactMetadata`
  where the stream sends `compact_metadata`, so every one was silently
  dropped; subagent output was filtered by `isSidechain`, which the
  stream never sets, so it leaked into the lane. Both fixed, a failed
  turn and a rule-denied tool now say so instead of vanishing, and the
  compaction divider carries its numbers. Unit-tested against real frame
  shapes.
- The agent chat can answer. A `can_use_tool` ask renders as a card with
  the tool, its full arguments and Allow/Decline; text streams into a
  live bubble the finished turn replaces; send becomes stop while the
  agent works. Verified live: the desktop approved a Write and the file
  appeared.
### Fixed: desktop UI details from first use

- Sending a message looked like it had been swallowed: the chat waited
  for the CLI to echo it back (`--replay-user-messages`), which only
  happens once the agent picks the message up: seconds later. It appears
  the moment you press Enter now, and the echo is dropped when it arrives
  so nothing shows twice.
- The chat header no longer offers "terminal" for a managed agent. That
  session has no PTY, so the button opened an empty grid; a
  terminal-launched agent still has one and keeps the button.

- A session row's actions appeared only sometimes. The clickable body was
  a button nested inside the hover area, and it swallowed the enter/exit
  events, so whether a row lit up depended on where the pointer crossed
  its edge: the first row, entered from the heading above, missed most
  often. One widget owns both the pointer and the click now, and the
  cursor turns into a pointer over the row, so what is clickable says so
  rather than leaving a tint to imply it.
- Segmented controls (agents, mcp) had their buttons adjoining, so their
  borders doubled up and the set read as one crammed block. They are
  spaced, like the phone's.
- The SSH host filter sits on the actions row beside "New vault" and
  "Add host", the way the sessions filter does, instead of on a line of
  its own below them.
- SSH host cards had less vertical room than every other row in the app,
  and none between grid rows.

### Changed: the start-agent dialog

- Rebuilt to the maintainer's redesign: the provider named in a chip
  beside the title, the working directory as a field you can **type**
  rather than only browse to, a Browse button beside it, and the
  directories this machine has already run agents in listed underneath
  with their conversation counts: busiest first, one tap to pick.
- Long paths are shortened from the left (the last components identify a
  project; the prefix is the same for all of them), so a row stays a row.
- `esc` closes it, which the footer now says and previously did not do.

### Added

- Sidebar icons, drawn rather than shipped as a font: the mockup gives
  their paths on a 24×24 grid, so they stay the same source of truth as
  the colours.
- A managed agent session is named after the directory it works in. It
  has no shell to set a title and no pane cwd to poll, so it used to stay
  "shell" forever and every agent session looked like every other; the
  chat header then paired that with the provider and read "claude claude".
- Opening any agent session goes straight to the chat. It has no
  PTY, so the chat-or-terminal question offered a choice one side of
  which opened an empty grid. `SessionInfo` carries `sdk` for that, which
  every client needs anyway.
- Agents screen on the same anatomy: provider segments (a CLI that is
  not installed stays visible and plainly unavailable rather than
  vanishing), then resumable conversations named by the project they ran
  in, with the prompt beneath and the time on the right.
- MCP and SSH screens on the same anatomy: a segmented provider control
  and a configured list with the endpoint and its kind; hosts as cards
  under collapsible vault headings that say how many and whether the
  vault is private or shared, with the ~/.ssh/config import as a bordered
  note rather than a button pretending to be a row.
- Settings and account follow: underlined tabs instead of filled pills
  (a pill reads as a button you press, not a section you are in), group
  labels as small headings, the design's button language throughout, and
  an account identity block with the avatar initial and the org in the
  colour that already means "shared with others".
- The terminal's own chrome joins them: the tab strip, the search bar and
  the files drawer take the fixed tokens, and so do the picker's inline
  editors (add host, new vault, members). The colour scheme now paints
  the grid and nothing else, which is what makes one app out of a themed
  terminal and a designed shell.

### Added

- Agent sessions are conversations now, not terminals with a CLI typed
  into them (ADR 0005, protocol v2). The daemon runs Claude Code as a
  managed process over its SDK protocol and mirrors the conversation as
  `AgentFrame`s: streaming deltas, typed tool calls and results,
  compaction boundaries, cost. Clients answer with `AgentCommand`,
  message, **answer a permission ask**, interrupt, change permission
  mode, so a phone or browser can approve the tool the agent is
  blocked on instead of typing blind into a TUI it cannot read.
  `bypassPermissions` is refused from remote clients on purpose. A
  managed session has no PTY and resumes by the CLI's own session id.
  Verified end to end through the daemon
  (`cargo test -p termuna-mux --test live_agent_session -- --ignored`) and
  live from a phone through the production relay: a Write outside the
  working directory stopped the agent, the card appeared on the phone,
  Allow released it, and the file landed on the desktop.
- Token deltas are sent live but never stored: `stream_event` frames go
  out unsequenced, so they stay out of the replay log and off the relay's
  disk. A reader who joins later gets the conversation rather than a
  recording of its keystrokes.
- `termuna-agent`: a crate that drives an agent CLI over its own SDK
  protocol instead of its terminal. Claude Code in `stream-json` mode
  speaks NDJSON both ways, so the conversation arrives as typed frames,
  streaming deltas, tool calls with their inputs and results, compaction
  boundaries, a result with cost, and, crucially, a `can_use_tool`
  permission ask that Termuna can route to whoever is watching and
  answer. This is the foundation for replacing the transcript-tailing
  chat lane. Verified against a real Claude Code process: ask → answer →
  tool runs → typed result (`cargo test -p termuna-agent -- --ignored`).

- Cloud keep-alive: with sync enabled, sessions that were live when the
  daemon last stopped come back automatically on the next daemon start
  (or reboot) and re-bridge to the cloud, so you can continue them from
  the web or phone without the desktop app having to reopen each one
  first. Previously the daemon loaded every saved session dormant and
  only respawned one when a viewer opened it, so with the GUI closed
  nothing stayed live on the relay. Bounded and safe: only sessions
  active within the last 48h are respawned, capped at 32, staggered, and
  run off the startup path so cold start is unaffected; older sessions
  stay dormant (still viewable read-only from the dashboard). Opt-in with
  cloud sync (ADR 0002): nothing respawns unless `[cloud] enabled`. On by
  default when sync is on; set `[cloud] keep_alive = false` to opt out and
  keep the old behavior (sessions load dormant until reopened).

### Fixed

- Scrolling and selecting work in apps that turn mouse reporting on
  without taking the alternate screen: a CLI agent's TUI being the case
  that exposed it. Termuna forwarded every wheel notch and every drag to
  such an app, which ignores them, so the scrollback could not be
  scrolled and no text could be selected or copied at all. The wheel now
  scrolls the scrollback in the normal screen, and a drag becomes a
  selection there (the button is released for the application first, so
  a plain click still reaches it). Full-screen apps on the alternate
  screen (vim, htop, lazygit) keep the wheel and the drag, since they
  own the viewport and there is no scrollback behind them. Shift still
  bypasses reporting everywhere, as before.
- Right-click opens the context menu, and middle-click pastes the primary
  selection, in the normal screen too. Both were forwarded to any app
  with mouse reporting on, which is how a selection could exist with no
  reachable way to copy it.


### Added

- TSP grows a daemon-query channel (`Query`/`QueryReply`, additive):
  viewers attached to a live session can ask the daemon for the
  installed agent CLIs, recent resumable agent conversations, and to
  launch an agent in a fresh session: everything E2E-sealed with the
  asking session's key, correlated by envelope id, never persisted by
  the relay. `SessionCreated` replies carry the new session's share
  link inside the sealed payload so the asking viewer (the mobile
  app's agents screen) can open it immediately. The channel also
  covers plain session management: create, rename, kill, and
  resurrect-with-share-link, and opening vault connections:
  `CreateSshSession` carries the resolved SSH target (host, auth,
  jumps, forwards) inside the sealed query, so a phone can open a
  saved connection Termius-style without any secret touching the
  relay. Spec: docs/PROTOCOL.md.

## [0.1.0] - 2026-07-27

First public early-access release: the Windows installer and Linux
build on [github.com/termuna/termuna](https://github.com/termuna/termuna/releases).
Everything below shipped in it.

### Fixed: dock launch spinner no longer hangs for ~a minute (Linux)
- The GNOME/Ubuntu dock kept showing the "launching" cursor for up to a
  minute after Termuna's window was already visible. iced/winit never
  completes X11 startup-notification (no `_NET_STARTUP_ID` on the window,
  no completion message), so with `StartupNotify=true` the launcher waited
  out GNOME's whole startup-sequence timeout. Set `StartupNotify=false` in
  the desktop entry; the window appears instantly so no launch feedback is
  needed, and `StartupWMClass` still groups the window under the icon.

### Fixed: shared sessions no longer tear the terminal
- When a session was open in more than one viewer (e.g. the desktop app
  and the web viewer) at different window sizes, the PTY size flapped
  between them and the TUI (a shell full-screen app, an agent) drew for
  one size while a mirror rendered another: garbled, misaligned output.
  The host now reconciles viewer sizes tmux-style (smallest-wins) and
  publishes the authoritative grid size in the layout snapshot; every
  mirror renders exactly that grid and letterboxes any extra window
  space, so the two never disagree. A web viewer's size stops constraining
  the terminal shortly after its tab closes (size heartbeat + TTL), so the
  desktop reclaims full width. Wire-compatible (the size rides the existing
  encrypted layout snapshot; the relay is unchanged).

### Fixed: all live sessions mirror to the cloud, not just the newest
- Cloud bridge: a session's mirror is now self-healing. Previously the
  "bridge already started" latch was never released and the bridge task
  returned on a transient broadcast-channel close, so a mirror that
  stopped for any reason was never restarted: over time only the most
  recently started session stayed live in the cloud even though several
  were live locally. The bridge now reconnects while the session is live
  and releases the latch when it truly stops.

### Changed: desktop chat text is natively selectable (plain, no button)
- Desktop agent chat: every message is now a read-only editor, so you
  can drag to highlight any part and Ctrl+C to copy it: no "select"
  button, no per-message copy button. Markdown is stripped to clean
  plain text (no raw ** # ` or link syntax); iced can't both render
  markdown and allow selection, so on desktop we chose selection. (The
  web viewer keeps rendered markdown AND native selection.)


### Added: select part of a chat message; compaction shows for any provider
- Desktop chat: each message has a "select" toggle that turns it into a
  read-only editor so you can highlight and copy just part of it
  (Ctrl+C): markdown stays for reading, selection on demand. Web chat
  text is natively selectable (the per-message copy button is gone).
- Compaction now shows a "⟳ conversation compacted" divider for any
  provider: detected from the continuation-summary preamble as well as
  Claude's /compact command.


### Fixed: slash menu typing; web chat text is selectable
- Typing after "/" in the chat composer now works: the command menu
  floats over the composer (as a constant overlay layer) instead of
  reflowing the layout, which was dropping input focus after the first
  character. It filters live as you type.
- Web chat: message text is selectable: select any part and copy it
  natively; the per-message copy button is gone.


### Added: /compact (and slash commands) show in the chat
- Running `/compact` now draws a "⟳ conversation compacted" divider in
  the chat lane (and `/clear` a "conversation cleared" one); other local
  slash commands show a muted "▸ /command" marker. Detected from the
  agent's transcript (system/local_command records): earlier the chat
  ignored these entirely. Desktop and web.


### Changed: working directory uses a native folder picker
- In the "start agent session" chooser, the working-directory field is
  now a click target that opens the native folder picker, prefilled at
  the current path.


### Changed: nicer "start agent session" chooser + directory ask
- The open chooser got a visual pass (glyph + title + description cards,
  subtle shadow, rounded) and now asks for a working directory when you
  start a NEW agent session: resuming a past conversation keeps its own
  folder, so it skips the field.


### Changed: cleaner picker: agents screen, scroll, copy feedback
- The agents screen dropped the model chips and directory input (they
  used the CLI defaults anyway); "continue a conversation" entries are
  now two-line cards: prompt on top, a muted "provider · folder · when"
  line below, so the list is far easier to scan.
- The picker's scrollbar no longer clips the row controls (rename/kill,
  copy link): the scroll area reserves a right gutter on every screen.
- The chat copy button flashes "copied" in place after a click
  (desktop and web).


### Added: MCP server management (picker "mcp servers")
- A new picker section lists, adds, and removes the MCP servers your
  agents use, per provider (Claude Code, Codex, Gemini): reading and
  writing each provider's own config (`~/.claude.json`,
  `~/.codex/config.toml`, `~/.gemini/settings.json`) and preserving
  everything else in those files. Add a stdio server (command + args)
  or a remote one (URL). Daemon-side (`McpList`/`McpAdd`/`McpRemove`)
  so the web can reuse it later.


### Added: command palette (Ctrl/Cmd+K)
- A fuzzy command palette opens from anywhere with Ctrl/Cmd+K: jump to
  a session by name, start a local or agent session, open connections
  or settings, and (in a session) switch chat/terminal, new tab, or
  back to the picker. Arrow keys + Enter, Esc closes.


### Added: agent chat composer: slash menu + copy
- Typing "/" in the chat composer opens a menu of the provider's common
  commands (/compact, /clear, /model, /cost, /status…): pick one to
  drop it in. Every assistant (and user) message has a quiet copy
  button. Desktop and web.


### Added: agent chat shows tool activity, thinking, and token use
- The chat lane is no longer just text: each tool call renders a card
  with its key argument (bash command, file path, grep pattern) and a
  monospace detail block; **Edit/Write show a +/- diff**; tool results
  appear as muted "⤷ result" blocks (clipped). Reasoning shows as a
  muted "thinking" line. A running **token count** sits in the chat
  header. Desktop and web.


### Fixed: agent chat kept up with compaction; less noise
- The chat lane no longer freezes when the agent conversation is
  compacted or "resumed from summary": Claude Code rolls to a new
  session file at that point, and the daemon now FOLLOWS the newest
  transcript in the session's directory instead of staying pinned to
  the launch file. A `/compact` now shows a "⟳ conversation compacted"
  marker followed by the summary.
- The chat drops CLI machinery that isn't a human turn: background-agent
  task-notifications and local slash-command echoes no longer appear as
  message bubbles.


### Added: rich replies + images in the agent chat
- Assistant replies in the agent chat (desktop and web) now render as
  **markdown** (headings, bold, lists, links, and code blocks) instead
  of raw asterisks and backticks.
- You can hand the agent an image from the chat: **Ctrl/⌘+V pastes an
  image straight from the clipboard** (desktop and web), or use the "+"
  button. On the desktop the pasted image is saved locally and its path
  drops into the composer (visible and editable) so you see it worked;
  on the web/mobile viewer it travels E2E-encrypted to the host (new
  `AgentAsset` frame, ≤12 MiB, relay sees only ciphertext) which saves
  it and references it to the agent.
- The chat attach control is a quiet monochrome "+" (was a color emoji
  that clashed with the terminal look).

### Added: desktop agent chat UI + open-as-chat/terminal choice
- Opening an agent session (from a session row, "start agent session",
  or "continue a conversation") now asks how you want to work with it:
  **Chat**: a readable conversation view with message bubbles, built
  from the agent's own transcript, with a composer that types into the
  live agent, or **Terminal**, the agent's full TUI. Both drive the
  same session; a ✳/⌗ button flips between them at any time.
- Agent CLI detection now also looks in the usual user install spots
  (`~/.local/bin`, nvm/fnm/volta/bun node dirs, Homebrew) so Codex,
  Gemini, etc. are recognized even when the daemon's PATH is narrower
  than your shell's: no more false "not installed".
- The provider chips filter the "continue a conversation" list; Codex
  conversation titles skip the injected environment/AGENTS.md preamble
  and show the real first prompt.

### Added: structured agent conversation mirrored to viewers
- For agent sessions the daemon tails the agent CLI's own transcript
  (Claude Code JSONL under `~/.claude/projects`, Codex rollouts) and
  mirrors complete lines as sequenced, E2E-encrypted `AgentEvent`
  frames. The web viewer turns them into a readable chat lane (✳
  button) beside the terminal: the phone-friendly way to follow an
  agent. Backfills recent history on attach; the relay sees only
  ciphertext.

### Added: "needs input" attention on sessions
- The daemon watches every pane's output for a terminal bell (outside
  escape sequences, after 10s of input silence) or an explicit OSC
  9/777 notification: the signals agents and long builds emit when
  they want you. The session flips to "● needs input" in the picker
  (amber, refreshed automatically) and an additive `Attention` frame
  reaches viewers and the cloud relay, which can fan it out as a push
  notification to your phone. Typing anything stands it down.

### Added: AI agent sessions (picker "agents" screen)
- New "agents" section in the picker: start a Claude Code, Codex,
  Gemini, Cursor, or OpenCode session with a model picker and working
  directory, or continue a past conversation: the daemon discovers
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

### Added: daemon health indicator
- The picker sidebar shows the mux daemon's state: teal dot with
  version and uptime when healthy, a warning when the daemon runs an
  older binary than the app (restart to update), red "daemon offline"
  when unreachable. Backed by a new local-IPC `Status` request
  (pid, version, uptime, session counts), polled every 5s while the
  picker is visible.

### Added: about tab in settings
- Settings gained an "about" tab: wordmark, version + platform, what
  Termuna is, links to termuna.com and the dashboard.

### Added: per-tab colors + tab context menu
- Right-click a tab for its own menu: rename, close, close others /
  to-the-right, and per-tab colors: tab background, label color, and
  a terminal-background tint for the tab's panes (swatch presets, ×
  clears back to the theme). Colors live in the session tree, mirror
  to viewers, and survive daemon restarts (`SetTabColor`, additive).
- The active tab now carries a thin accent underline: visible at a
  glance where the old 1px outline wasn't.
- Dragging a tab shows a floating ghost chip under the cursor while
  the strip reorders underneath; the origin slot dims.

### Added: tab bar, the full treatment
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


### Fixed: tab strip is responsive; every tab closable on hover
- Ten tabs pushed the files/home buttons off-screen: tab widths were
  fixed. Tabs now share the space left of the right-side controls and
  shrink (down to slivers) as more open: +, files, and home never move.
  The strip recomputes from the live window size, so resizing or
  maximizing reflows it immediately.
- Every tab shows its × when hovered (the active one always); the slot
  is reserved so nothing shifts on hover.

### Fixed: bold text switched typefaces with variable fonts
- Bold from a variable-font family (Ubuntu Mono on modern Ubuntu is one
  file with a weight axis) fell back per-glyph to a different family,
  bold ls entries rendered in DejaVu. Families with a static Bold face
  keep using it; variable-only families now get SYNTHETIC bold (the
  classic double-strike, same as VTE/xterm): same typeface, same
  metrics, visibly thicker strokes.

### Fixed: column alignment with non-bundled fonts
- With a system font whose advance differs from JetBrains Mono's 0.6em
  (Ubuntu Mono is 0.5em), plain and styled runs drifted apart: ls
  output looked like mixed fonts with uneven gaps. The cell grid now
  measures the active family's real advance from its font file
  (fc-match + ttf-parser) instead of assuming 0.6.

### Added: daily-driver interactions
- Double-click selects the word, triple-click the line (word charset
  matches Terminator's select-by-word set); the selection lands in
  PRIMARY as usual.
- Ctrl+mouse wheel zooms the font.
- Background tabs show an attention dot: muted for new output, red when
  the shell rang the bell (BEL); cleared when the tab is selected.
- Ctrl+click now also opens OSC 8 hyperlinks (the cell's own link wins
  over heuristics) and local file paths with an optional :line:col,
  VS Code gets them via `code -g` when installed.
- Tabs can be reordered: ctrl+shift+pageup/pagedown or the right-click
  menu (new additive MoveTab command, mirrored to every viewer).

### Added: terminal settings tab + quake mode
- Settings gains a "terminal" tab: scrollback lines (new panes), mouse
  wheel speed, copy-on-select, and whether programs may set the
  clipboard (OSC 52).
- Quake mode: a global hotkey (e.g. F9/F12, configurable there) shows/
  hides the window from anywhere. Off by default; X11 and Windows (no
  Wayland global hotkeys yet).

### Added: vault security: revoke + key rotation, recovery kit
- A shared vault's members panel now lists current members with a
  revoke button. Revoking rotates the vault key: every profile is
  re-sealed with a fresh key wrapped only to the remaining members, so
  revoked access truly ends (server swaps everything atomically and
  still sees only ciphertext).
- Recovery kit: the account screen can generate a one-time recovery
  code (shown once, copied to the clipboard) that can recover the
  account key if the vault passphrase is lost. The code never leaves
  the machine; the server stores only a sealed blob.

### Changed: daemon idle policy (M3 leftover)
- With no live sessions and no attached viewers for 15 minutes, the
  daemon exits. Dormant sessions stay on disk; the next launch spawns a
  fresh daemon that loads them.


### Added: Windows sessions survive the window (named pipes)
- The mux daemon now runs out-of-process on Windows too, over a per-user
  named pipe (auto-spawned, detached, one instance per user). Closing or
  killing the window no longer ends your shells: reopening Termuna
  attaches straight back into the live session with scrollback replayed,
  exactly like on Linux. This closes the long-standing M3 item; the
  in-memory transport remains only as the test harness.

### Added: Windows installer
- A real Windows installer (NSIS, ~5 MB): per-user, no admin prompt,
  installs to %LOCALAPPDATA%\Programs\Termuna with a Start Menu shortcut
  and an Apps & Features entry; /S installs and uninstalls silently.
  Uninstall leaves user data (sessions, vault, config) in place.
- The Windows exe is a proper GUI app now: no console window flashes on
  double-click (CLI flags still print when run from a terminal), and the
  moon-cursor icon is embedded (Explorer, taskbar, Alt-Tab).

### Fixed: consistent form styling and Tab focus
- Text inputs and other bare widgets now draw with the app's own theme
  everywhere. They used to fall back to iced's built-in theme, which
  follows the OS light/dark preference: on a light-mode Windows that
  meant white inputs floating in our dark chrome.
- Tab / Shift+Tab move focus between inputs in every form (sign-in,
  connection editor, settings, search). Inside the live terminal Tab
  still belongs to the shell.

### Changed: shared connections work across devices
- A connection whose SSH key path does not exist on this device now
  falls back to this device's default key (~/.ssh/id_*) instead of
  failing with a missing-file error. Profiles sync across machines and
  teammates, but private keys never travel with them: each device
  authenticates with its own key. A leading `~` in key paths is now
  expanded on every platform.
- Opening the ssh connections screen triggers an immediate silent vault
  refresh, so a teammate's fresh share appears right away instead of on
  the next minute tick.

### Changed: share dialog says who can't receive a share
- Teammates who haven't published an encryption key yet (never unlocked
  the vault in their app) are shown as unselectable with the reason,
  instead of being silently skipped at grant time: "shared with 0
  teammate(s)" can no longer happen by surprise.

### Added: background vault sync
- Shared connections now arrive on their own: while you are signed in
  with the vault unlocked (or the passphrase remembered on this device),
  the app quietly re-syncs every vault once a minute, so a teammate's
  share shows up without pressing sync or restarting. Offline failures
  are silently ignored: nothing interrupts.

### Fixed: Windows actually works
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

### Added: settings tabs, color picker, Tango Dark
- Settings are organized into tabs (appearance / keybindings): room to
  grow without a wall of controls.
- Custom colors got a real picker: color wells that expand into curated
  swatches (theme default, grays, luna, the Tango ramp) plus hue/
  saturation/lightness sliders with a live preview and hex readout.
- New built-in theme "Tango Dark": the GNOME/VTE default palette on a
  near-black surface: the classic Terminator look. (Any installed
  monospace font, e.g. Ubuntu Mono, is already offered in the font
  dropdown.)

### Added: resizable splits, appearance profiles, keybinding editor
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

### Added: mouse reporting, OSC 52, URL clicks, PRIMARY selection
- Mouse reporting: clicks, drags (deduped per cell), and wheel are
  forwarded to applications that request them (SGR 1006 and legacy X10
  encodings), so htop/vim/tmux respond to the mouse. Shift bypasses
  reporting for local selection, as everywhere else.
- OSC 52 clipboard, write-only: programs (vim/tmux over SSH) can set the
  local clipboard; read requests are never answered, so nothing can
  exfiltrate what you copied.
- Ctrl+click opens http(s) links under the cursor (wrapped lines joined).
- Finishing a selection copies it to the PRIMARY selection and
  middle-click pastes it: the Linux terminal convention.
- New core stress test: alt-screen x resize x clear (the most re-broken
  bug in Warp's public history) runs in CI.

### Added: terminal input correctness (vim/less/htop basics)
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
  keys, three per notch) instead of doing nothing: vim, less, and htop
  scroll from the wheel now.
- New research note docs/research/warp.md: basics comparison against
  Warp plus a bug-lesson checklist mined from its public issue history.

### Added: session names and one-key access on the dashboard
- The daemon now wraps each cloud session's content key to the account's
  vault public key (the same key custody as the SSH connection vault)
  and pushes the session title sealed with the content key; renames
  refresh it. The relay stores blobs it cannot read.
- On termuna.com/app, one vault-passphrase unlock now shows every
  session's real name and lets Open work in any browser: no more
  pasting a share link per session. New additive TSP frames
  (AccountInfo, SessionMeta); old peers ignore them.

### Added: "copied ✓" feedback on copy link
- Clicking "copy link" on a session row now flashes the button to
  "copied ✓" for two seconds, so you know the share link is on the
  clipboard.

### Fixed: closing the last tab returns home
- Closing the only tab (or exiting the last shell) quit the whole app,
  a leftover from before the picker existed. The end of a session now
  returns to the sessions screen.

### Added: confirmation before removing a connection
- "remove" on a host no longer deletes immediately: an inline
  `remove "<name>"?` confirm (red remove / cancel) appears under the
  card first.

### Changed: quieter ⋯ on host cards
- The ⋯ (actions) affordance no longer paints a hover box inside the
  card; the dots just brighten on hover.

### Fixed: host actions: move and share respond again
- Clicking "move" or "share" on a connection did nothing: they opened
  their panel state but left the actions strip open, and the actions
  branch renders first, so the new panel never appeared. Both now close
  the strip and swap to their panel.

### Added: vault picker in the host form
- Adding or editing a connection asks which vault it belongs to (a
  dropdown next to the port field); Personal is preselected for new
  hosts, and editing keeps the host's current vault.

### Changed: picker actions in the heading row
- "+ new local session", "+ add ssh host", and "+ new vault" moved from
  the bottom of their lists into the heading row, top-right: long lists
  were pushing them out of sight. Their editors (host form, vault name)
  now open directly under the heading for the same reason.

### Fixed: files panel survives re-attach
- Re-attaching to an SSH session from the picker lost the files button:
  the viewer forgot which connection profile the session belonged to.
  The daemon now reports each session's SSH destination
  (`user@host:port`) in the session list, and the viewer maps it back to
  the vault profile on attach, so SFTP stays available.

### Fixed: SFTP files panel: upload and mkdir
- Upload now opens a native "open file" dialog and sends the chosen file
  to the current remote directory. Previously one text box served both
  upload and mkdir, so "upload" did nothing unless you happened to type a
  full local path into it: unclear, and it looked broken.
- That box is now purely a folder search: it filters the listing, and
  the mkdir button stays disabled until the search names a folder that
  doesn't exist yet, then it arms as "mkdir <name>" and creates it.

### Added: Linux desktop integration
- `scripts/install-desktop.sh` installs the binary plus a launcher entry
  and the moon-cursor icon into the hicolor theme, so Termuna shows up in
  app search and the dock with its own icon. The window now sets
  `application_id`/WM_CLASS to `termuna`, matching `StartupWMClass` for
  correct dock grouping. New `apps/termuna/assets/` (icon SVG + .desktop).

### Changed: luna teal rebrand + app icon
- The default theme is now "Luna Dark": near-black surface with luna-teal
  accents (#2dd4bf, the brand color) on the cursor, active tab, focused
  pane border, and selection. The ANSI ramp keeps honest terminal
  semantics: green output stays green. "Luna Light" replaces "Phosphor
  Light"; the old `phosphor-*` theme ids still resolve so existing
  configs keep working.
- The window/taskbar icon is the moon cursor: a luna-teal block cursor
  with a circular lunar bite (luna is in the name: ter-muna): drawn
  procedurally, no image assets or decoders.
- The sidebar wordmark matches the website: "termuna" with the moon
  cursor as its eighth character (vector-drawn canvas mark), replacing
  the plain dot.

### Added: close tabs
- The active tab now has an inline × (red on hover) that closes it,
  every pane in the tab goes; closing the only tab ends the session and
  returns to the picker. Also available as "close tab" in the
  right-click menu (which now says "home" instead of "sessions").

### Changed: leaner terminal tab bar
- The tab bar's right side is now a single ⌂ home button that returns to
  the picker (where sessions, connections, and settings live). The
  "copy cloud link", "sessions", and ⚙ buttons are gone: the cloud link
  stays available on the session's row in the picker. "files" still shows
  for SSH sessions.

### Added: scrollback survives reboot
- A session's terminal output (scrollback) is now persisted to disk (the
  last ~1MB per session, written on a 3s throttle only while output
  flows) and replayed on resurrection. Combined with the existing
  tab/split tree + per-pane working directories, resurrecting a session
  after a reboot brings back the same layout, the same directories, and
  the prior on-screen history, then a fresh shell continues from there.
  Running processes still don't survive a reboot (a reboot kills them);
  this restores the view, not live process state. New per-session `.log`
  file; covered by `scrollback_survives_daemon_restart`.

### Added: manage sessions from the picker
- Rename a session inline in the picker ("rename" → type → Enter/save),
  and end one for good with "kill". Rename and kill work on live and
  dormant sessions alike; killing deletes the persisted tree so it does
  not come back on the next daemon start. A rename mirrors to any
  attached viewer and, for cloud-bridged sessions, syncs end to end via
  the session tree. New `MuxRequest::{RenameSession,KillSession}` and
  `Session::rename`.

### Changed: launch always lands on the picker
- Starting Termuna now always opens the session picker (sessions, saved
  hosts, cloud sign-in), even on a fresh install with nothing saved. It
  no longer auto-spawns a local shell on launch; "+ new local session"
  is one click away.

### Changed: two-pane connection manager
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
  cleanly: the sidebar stays fixed, the grid reflows.

### Fixed: host card grid on wide windows
- Maximizing the window squeezed host cards into overlapping slivers:
  the grid computed its column count from the full window width while
  the content column is capped, so it asked for more columns than fit.
  Both now derive from the same cap. Card texts are truncated so a long
  host can never paint over its neighbor, and the card hover tint is the
  dark selection color instead of a bright accent fill that swallowed
  the text.

### Added: full connection management
- Every saved host now has an actions menu (⋯): edit, duplicate, move to
  vault, share, and remove. Editing reopens the form pre-filled and
  round-trips auth, jump hosts, and port forwards losslessly.
- Adding or editing a host now just saves and returns to the list;
  connecting is a separate, explicit click (no more auto-connect on save).
- A search box filters hosts by name, host, or user (and expands all
  vaults so matches show). Deleting a host is finally possible.

### Added: Termius-style vaults (connection organization)
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
  never uploaded), and from then on changes sync automatically: moving a
  connection pushes it to its vault, and a vault's "members" button grants
  teammates access (the vault key is wrapped to each member's public key).
  Each connection uploads into the cloud vault named by its `vault`
  (Personal → personal vault, others → same-named shared vaults, created
  on demand). Replaces the old all-or-nothing "share with team" and the
  separate passphrase box / "sync all vaults" button.

### Added: remember vault passphrase (opt-in)
- The cloud-vault unlock is now a discreet "🔒 unlock cloud vault" link
  that expands into the passphrase field on demand, instead of a prompt
  that shows on every launch.
- A "remember on this device" checkbox stores the passphrase in the OS
  secret store (GNOME Keyring / macOS Keychain / Windows Credential
  Manager) so the vault auto-unlocks on launch. Off by default; the
  passphrase still never touches the relay or plaintext disk.

### Added: settings panel (appearance)
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

### Changed: tab and session titles
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
  rejects) no longer blanks the picker: the existing sessions stay
  visible and the error is shown instead of looking like everything died.

### Added: M9 cloud connection vault (desktop)
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

### Added: M7 (desktop UX: the app explains itself)
- Interactive cloud sign-in: a "termuna cloud" section in the picker
  signs in or creates an account, mints a device token, writes
  config.toml, and flips the daemon to cloud mode at runtime: sessions
  start syncing immediately, no manual config and no restart. Each
  synced session shows a "copy link" button; the terminal gets a
  "copy cloud link" chip.
- Tabs are titled by the shell's working directory (`~`, `lightweight-cli`,
  …) and follow `cd`; double-click (or right-click → rename) gives a tab
  a permanent name. New `RenameTab` protocol command.
- Right-click context menu on the terminal: new tab, split right/down,
  rename tab, copy, paste, close pane, sessions.
- A "sessions" button in the tab bar detaches back to the picker: the
  session list, ssh connection manager, and cloud sign-in are always
  reachable now (previously the first launch dropped you straight into
  a terminal with no way back).

### Fixed: cross-platform builds + CI (green on all three OSes)
- Windows: agent auth is cleanly unix-gated, the GUI falls back to the
  in-process mux (sessions end with the window until named-pipe
  transport), home-dir resolution uses HOME/USERPROFILE. The workspace
  now compiles and tests green on Windows for the first time since M3.
- macOS: procfs-only field no longer trips -D warnings.
- CI: perf-budget job asserts binary <30MB, daemon socket <500ms,
  daemon idle RSS <30MB on every push.

### Fixed: memory budget (M2 closeout)
- Measured the idle-memory budget honestly: with 3 tabs idle the GUI is
  83MB PSS and the daemon 4MB: 87MB total, under the 100MB budget. The
  previously reported 157MB was RSS, which double-counts ~70MB of
  shared, evictable GPU-driver (Mesa/LLVM) and libc code pages; private
  memory is ~26MB. Added scripts/mem-budget.sh so the number is
  reproducible (same isolated-daemon, 3-tab scenario). For scale: an
  Electron terminal on the same machine idles at ~492MB PSS.

### Added: M5 alpha (cloud continuity)
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

### Changed: M5 alpha
- Content crypto switched from seq-derived nonces to random 24-byte
  nonces prepended to the ciphertext: seq nonces would repeat across
  multiple writers sharing the session key (host + viewers), which is
  catastrophic for Poly1305. Interop-tested against the web viewer's JS
  implementation.
- TSP ciphertext fields now encode as CBOR byte strings (`serde_bytes`)
  instead of integer arrays: smaller frames, sane browser decoding.

### Added: M3 (persistence: the mux daemon)
- `termuna-mux` crate: a daemon (`termuna --daemon`, auto-spawned by the
  GUI, detached so it outlives it) that owns every PTY and the
  authoritative session tree. Transport: TSP frames over a Unix socket
  (0700 runtime dir) with a small handshake (list/create/resurrect/attach);
  in-memory duplex transport for tests and socketless platforms.
- Sessions survive the window: killing the GUI leaves shells running;
  reattaching replays the daemon's retained output log: full screen and
  scrollback reconstructed. Verified live on X11.
- Reboot resurrection: every structural change persists the session tree
  and per-pane working directories (procfs) to disk; after a daemon
  restart, sessions appear as dormant and one click restores the whole
  layout with fresh shells in their saved directories. Verified live.
- Session picker on startup: live/dormant list with tab/pane counts, plus
  new-session; shell `exit` cleanly ends the session everywhere.
- TSP gains the `Command` payload (`SessionCommand`: NewTab, Split,
  ClosePane, SelectTab, FocusPane, ResizePane): viewers request
  structural changes, the host applies and broadcasts a `Layout`
  snapshot. The GUI is now literally the first TSP viewer; the web
  dashboard will reuse this path unchanged.
- Scrollback search: Ctrl+Shift+F opens a search bar; case-insensitive
  scan over the full scrollback with match counter and jump-to-match
  (Enter walks older matches). 40k lines scan in well under 500ms in the
  test suite: the anti-benchmark being the popular Electron terminal's
  search hang.
- 4 mux integration tests (attach/type roundtrip over real shells, split
  broadcast, detach/reattach replay, persistence + resurrection across a
  daemon restart); 39 tests total across the workspace.

### Changed: M3
- The GUI holds no PTYs anymore: `pane.rs` mirrors daemon state
  (emulator + cache + selection per pane) and all input/structure flows
  through TSP frames. Focus and tab selection are session state shared by
  all viewers, applied by the daemon.
- Startup with the daemon hop measured at 288ms to first output frame
  (debug build, cold daemon spawn): still inside the <300ms budget.

### Added: M2 (windowed terminal)
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
  (installer budget <30MB ✓), RSS ~157MB with a shell running: above the
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
