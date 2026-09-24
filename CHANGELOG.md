# Changelog

All notable changes to the Termuna desktop app are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versioning: [SemVer](https://semver.org/) once we hit 0.2 (M2).

## [Unreleased]

## [0.2.16] - 2026-09-24

### Fixed: a known hosts store that cannot be read refuses the connection

Board#426. Trust on first use read any failure to open the known hosts
store as an empty store, so a store at mode 000, a directory where the
store should be, or a data directory under a stale mount accepted
whatever key a host presented, a changed one included, on every
connection, silently. Only a missing store is a first contact now; any
other failure refuses and the pane says why: "could not read the known
hosts store at <path>: <error>; refusing to connect". The same holds
for the other half: a first contact whose key could not be written to
the store used to connect with nothing recorded, so the next
connection was a first contact again and a key change would have gone
unnoticed. It refuses now too, naming the host, the store and the
error. A redial reads the store again on every attempt, so putting the
mode right lets it through without a person. No protocol change.

### Added: the machine stays awake while work is in flight

Board#355. Closing the laptop never ended a session, but letting the
machine suspend froze the work in it: a build stopped mid-link, an
agent mid-tool-call, an SSH pane's far side hung up. The daemon now
holds a power lock while, and only while, something it owns is
genuinely in flight: a local pane's command that has run longer than
`[power] keep_awake_after` (30 seconds, so `ls` never takes one), or,
signed in on a paid plan, a viewer attached from elsewhere (the
dashboard, a share link, your phone). The lock goes the moment the
last reason ends, at `keep_awake_max` (4 hours) even with a reason
still live, and on battery at 20 percent or below.

It is said in one line: "awake: build running" or "awake: phone
attached" in the status bar, amber for the cap's last ten minutes; the
reason and the cap left on the continuity panel's machine row; "Let
this machine sleep" in ctrl+k, scoped to this session, with the
setting untouched; and a `[power]` block in Settings, Terminal, with
`never`, `on_work` (the default) and `while_attached`, the two
thresholds and what is held right now. All three keys travel with the
account's settings.

Linux asks logind over D-Bus (`what=idle:sleep`, `who=Termuna`, a
`why` naming the pane, so `systemd-inhibit --list` reads what the
status bar reads); macOS takes a `PreventUserIdleSystemSleep`
assertion, which does not beat a closed lid, and the app says so;
Windows sets `ES_SYSTEM_REQUIRED`. A machine where no lock can be held
(no session manager, a refused permission, an unsupported platform)
says so once, quietly, and the feature stays off. No protocol change.
### Fixed: an agent session's attention follows its asks, so every ask reaches the phone

A managed agent session raised `Attention{agent_approval}` on its
first `can_use_tool` and stood it down only when a command arrived.
A turn that ended with the ask still open (an interrupt, a mode
switch, the CLI moving on) left the flag standing, and since the flag
only goes up from standing down, every later ask in an autonomous run
raised nothing: no frame for the relay and no push for the phone. And
any command stood it down, so a "go on" typed under an open ask
retracted a nudge for an agent that was still blocked. The flag now
follows the ask set exactly: up on the first ask of an empty set, down
when the set empties however it emptied (the last ask answered, the
turn ending, a fresh process retiring the asks), and untouched by a
message that answers nothing. Bell attention in shell panes is
unchanged.

### Fixed: saving a host no longer asks whether to discard it

Pressing Save on the host card wrote the host to the vault and then
asked "discard changes?" on the way out, because the card compared
what it held to the empty form it opened as. A saved host is not an
unsaved edit: the card leaves quietly, the way the snippet editor and
the layout rename already did.

### Changed: a bell on a background tab is amber, not red

A tab whose program rang the bell while you were looking elsewhere
carried a red dot, the same red as the close button and the close
confirmation, so an agent CLI saying "I am done" looked like
something had failed. The dot is amber now, the colour every other
"a program wants you" signal already uses; red stays for a non-zero
exit and a changed host key, things that actually went wrong.
### Fixed: between two sign-in rounds the card no longer names a round zero

Board#329, QA finding of 2026-09-22. When an answer arrived for a round
the server had already closed and nothing new was waiting yet, the
pane's challenge card printed "the server has moved on to round 0".
Round zero is not a round, it is the gap between two of them, and the
phone and the dashboard have always said so. The card now prints the
same sentence they do, "That was round 2; no round is waiting now.",
and a test pins it against both of those files so the three surfaces
cannot drift apart again.

### Added: the top of a pane's buffer says which cap ended its history

Board#411. Three caps cut a session's scrollback and not one of them
said so, so a buffer that began mid sentence looked like a session that
had only just started. The top of a pane now carries one seam row
naming the reason: the on-disk tail kept on this machine, the
in-memory log this pane keeps while live, this window's own scrollback
cap, or the session's real start with the honest "nothing was cut". It
is the read line's marker recoloured, ink over mint, so a buffer
holding both reads them apart at a glance. The row is chrome: it is
never selectable, never in a copy, never in a pane export or an
asciicast, and it adds no line to the buffer.

### Added: a keepalive keeps an idle SSH link alive, read from the host card and ~/.ssh/config

Nothing Termuna sent ever kept an idle SSH link alive, so a NAT box, a
server's ClientAliveInterval or a load balancer's idle timeout could
reap the connection and leave redial to clean up a problem that did
not have to happen. A keepalive is now on by default for every shared
SSH connection: every 30 seconds of silence, up to 3 unanswered tries
before the link is called dead, about 90 seconds to name a dead path.
The host card gets one new row, "keep the link alive", between port
and identity: default, an explicit interval in seconds, or off, with a
badge naming where the answer came from (this host, ~/.ssh/config, or
the [ssh] default) when it is not the card's own choice. Settings,
[ssh] gets the two rows behind the default, keepalive_interval and
keepalive_max, with a hint that multiplies them out loud so nobody has
to do the arithmetic themselves; 0 turns it off, exactly as OpenSSH
reads ServerAliveInterval 0.

Importing ~/.ssh/config now reads ServerAliveInterval, ServerAliveCountMax
and TCPKeepAlive, and the read report names them per host, in seconds
and tries with the unit always printed, ServerAliveInterval 0 read as
"off" rather than as nothing. A value that is not a plain count, like
ServerAliveInterval 15m, is never guessed at: it is quoted back
verbatim, marked refused, and the report names the fallback the host
gets until it is set on the host card by hand.

When a keepalive goes unanswered, the pane's redial seam now says so:
"no answer to 3 keepalives over 90 seconds" instead of a bare
connection lost, so the sentence reads as the network and not as a
bug in Termuna. A host with keepalives off names the write that found
the link gone instead; a drop neither detector is confident enough to
credit keeps the plain wording it always had.

## [0.2.15] - 2026-09-22
### Fixed: a sign-in question is now visible on the pane's own card and the sealed lane at once

Board#329, QA finding 1. A host marked interactive on its card asked
through the pane's own conversation, and every other SSH host asked
through the daemon's sealed challenge lane; the two were mutually
exclusive per host, so a round was never visible on the desktop card,
a phone and the dashboard all at once, the headline property of the
"keyboard-interactive answered anywhere" epic. Every SSH dial now
registers on the daemon's one challenge lane, marked interactive or
not: the pane's own card is a view of the same round the lane lists,
fed by the lane rather than holding a conversation of its own, and
answering from the pane, a phone or the dashboard passes the same
one-answer-per-round gate and the same one-surface-at-a-time hold, so
a phone holding the question refuses the pane's own answer by name
until it is released. The interactive flag on a host's card still
decides whether opening it parks the pane and dials off the lock
rather than waiting for the dial, which is what it always meant for a
person who might be a while. No wire or protocol change.

Board#397, part 2 of the "keyboard-interactive answered anywhere"
epic (board#396). A host whose server asks a question at sign-in works
from the desktop now. The host card's authentication control has a
fourth segment, "interactive", beside agent, password and key file: a
fallback layered on the credential rather than a fourth choice, so it
reads pressed beside one of the three, and the note under it says so.
With it on, the daemon holds the conversation from part 1 for that
host, and the question lands in the pane whose open caused the dial.

The question is a card at the foot of that pane, the inert redial
card with fields in it. It takes room of its own and the grid above
gives up exactly that much, so the scrollback that says why the
connection is being made is never covered and nothing is a modal over
a live grid. The server's banner and instruction are quoted verbatim
in mono under a rule, every line of a multi-line banner kept, because
servers use the banner to say which code they want; a server that
prints none gets no quote and the card is still whole. Each prompt is
its own field, labelled with the server's own echo flag, "hidden" or
"shown, the server asked", and masked exactly when that flag says so:
a round with a hidden password and a visible token code shows both
fields with both labels. The card is amber while the question waits,
counts the engine's patience down, and says once that it is also
answerable on your phone and the dashboard. Enter or Answer sends a
copy of the fields to the daemon, which moves it into the engine's
wiped buffers; the fields themselves are cleared only once the daemon
has taken the answers, so a refusal (a stale round, a wrong count, a
daemon that did not answer) leaves every field exactly as typed under
the reason, and Enter sends nothing more while an answer is on its
way. Cancel gives the sign-in up at that round. A round with no
prompts is shown to be read and needs nothing. A second round replaces
the first whole, with fresh fields and nothing typed carried over.

Only the pane that leads the dial shows anything. A split, a new tab,
a file browse or a port forward on the same host waits on that dial
and joins its connection, exactly as the shared-connection rule
(board#276) already has them do, so a second pane prints no card, no
seam and no prompt. The daemon writes the ask and the outcome into the
leading pane as seam rows: "bastion.corp.example is asking a question"
above the card, and after the round "answered on this computer
14:22:09, 2 seconds after it was asked" or "cancelled on this
computer 14:24:03; nothing was sent". When another device answers
first the card closes by itself and names the device and how long it
took, so a card vanishing on its own never reads as a bug; this part
renders that state, and the phone that produces it is part 3.

The card turns warn red for one thing only: the server took the
answers and refused them. That card prints the engine's own sentence
from part 1, the count asked and answered, the rounds, and the remedy,
verbatim, and offers "Answer again", which dials for a fresh round. A
timeout, a cancel and a closed conversation stay amber: nothing failed,
a person was not there. On such a host the inert pane's card offers
"Answer again" instead of "Reconnect" too.

The pane state `asking` is new on the layout snapshot, additive: a
build older than this reads it as unknown, draws nothing for it and
drops input to it, which is right for a question it cannot show. The
question itself never rides the layout; a window asks the daemon for
it over the local socket. No protocol change and no relay change.
`docs/design/termuna-ui-v6.html` gains the challenge card in its five
states (`?ask=one|two|read|elsewhere|refused`), the seams, the
"waiting for you" corner tag and the host card's fourth segment
(`?addhost=interactive`), verified by a headless render.

Known limits: a host pane opened from a saved layout still dials
without the conversation, so a layout's Duo host is refused by name
until a later part; the file lane's own dial has no window to ask in
and is refused the same way if it is the first thing to reach a cold
host; two windows on one machine both read "answered on this
computer", because the daemon has one local socket and cannot tell
them apart; the widget that draws a field holds its own copy of the
text while it is on screen, the same limit the engine states about
the SSH library's buffers.

Board#405, review findings 1 and 2 on the fix above. Once every SSH
dial registers a conversation, not only a host marked interactive,
two panes of the same session could each have their own question
open at once, and the daemon still kept one slot for the whole
session: a second pane's question silently displaced the first
pane's own card, and settling either from a phone or the dashboard
could close the wrong pane's card, leaving the other's question
stuck on screen with no way to answer it locally any more. Each
pane's question is now tracked by the conversation it belongs to,
not by its round number, since every conversation counts its own
rounds from 1: two panes with a question open are independent, and
answering, declining, or one dial settling never touches the other
pane's own card. The two sentences the desktop card showed for
"somebody already answered" and "somebody else is answering" now
read exactly as the phone and the dashboard already did.

### Added: keyboard-interactive authentication, part 5 of 5 (the sealed lane)

Board#400, the last part of the "keyboard-interactive answered
anywhere" epic (board#329). Part 1 built the engine; the round a
server was asking lived in the process that dialled it, so a phone or
the dashboard had no way to see it, let alone answer it. Now the
daemon registers every keyboard-interactive conversation it dials on
its own challenge lane, and the daemon-query lane, which rides inside
the sealed envelope like every other daemon query, gained the
vocabulary: what is being asked on this daemon right now (each round
verbatim, the server's name, instruction and banner as sent, the
banner present and empty when the server printed none, every prompt
with the server's own echo flag, who is answering and how long is
left), the answers to one round, a decline, and a claim and release
that move who is answering between surfaces. Answering a round signs
the connection in; the next round arrives on the same lane.

Exactly one answer set reaches the server per round: a second answer
to the same round, an answer to another round, and an answer with the
wrong number of strings are each refused by name with the facts (the
round, the counts), never padded, cut or queued. Who answers is the
one-keyboard rule with a different noun: the first surface to act
holds the conversation, a claim takes it and never asks, a release
hands it back, and any other surface is told who holds it. A refusal
carries facts only; the sentence a surface prints is the engine's own
from part 1, so a pane, a phone and the dashboard say the same words.

An answer rides only inside the sealed envelope, is never persisted or
synced, prints as a count wherever it could be logged, and moves
straight into the engine's wiped buffers on arrival. Proven against a
scripted keyboard-interactive server: the round is listed verbatim,
two rounds sign in through the lane, a decline ends the sign-in with
the engine's cancelled sentence word for word, and a test reads every
log line the exchange writes at every level and finds no answer in
them. Additive on the wire, no `PROTOCOL_VERSION` bump; the fixture
vectors grew twelve keys and the phone and the website regenerate
theirs. The daemon's own dials from a new tab, a split, a session
created over the wire and a resurrection carry a conversation; a
redial of a dropped link does not yet, and a host marked interactive
on its card keeps asking through the pane's own card (board#397)
rather than the lane. `docs/design/termuna-ui-v6.html` does not move.

A dial that stops on a question never holds the session: it waits
for a person, up to three minutes, off the session's state lock and
off a runtime worker, so keystrokes, resizes and splits of the
session's other panes keep flowing while a question waits, and a
keystroke typed meanwhile is proven to come back echoed with the
question still open. A new tab or a split on any SSH host now shows
`connecting` while it dials and settles a dial that fails with
Reconnect on offer, as a host marked interactive already did; a
session created on an SSH host and a resurrected one still answer
their dial's failure as their own. A round the engine has stopped
waiting for, because its patience ran out or the dial ended, is no
longer listed and is refused by name as no such challenge, rather
than reported answered while nothing reached the server.

### Added: keyboard-interactive authentication, part 1 of 4 (engine only)

Board#396, part 1 of the "keyboard-interactive answered anywhere"
epic. A server that asks a question at sign-in instead of taking a
credential (Duo, Google Authenticator, a PAM challenge, an OTP, an
expired password's "new password:") was unreachable: Termuna's SSH
backend could not hold the conversation, so the configured credential
was refused and the connection answered a bare "authentication
failed". The backend speaks the method now. A host may be configured
to go straight to it (the new `Interactive` credential beside password,
key and agent), and a host configured with any other method falls back
to it when the server refuses that method and lists
keyboard-interactive among what it still accepts; a server that does
not list it is never asked. Exchanges with more than one round, a
password round followed by a code round, run to the server's yes.

Every round reaches whoever answers it whole and verbatim: the host
asking, the server's name and instruction text, the banner it printed
before the first question (the empty string when it printed none), and
each prompt with the server's own echo flag, never defaulted. That
flag is the one a client is tempted to lose, and losing it is how a
competitor came to type one-time passwords in plaintext on screen
(Tabby #10793). Answers are handed to the wire once, as a copy, and
the buffers Termuna holds them in are wiped the moment that copy has
been made; the copy itself lives in the SSH library's own packet
buffers and is not wiped by Termuna. Answers appear in no log line at
any level. Two tests hold this to account: one reads every line the
exchange writes, one reads the answer's own bytes at the moment they
are freed after a real exchange and finds them zero.

Nothing ends in "authentication failed" any more. Each way a sign-in
can fail is its own typed refusal with its own sentence, produced by a
pure function so a pane, a phone and the dashboard print identical
words: the server asked N questions, got every answer and refused
them; the server offers keyboard-interactive and it is not enabled for
this host; no answer came within the three-minute bound; the server
closed the conversation without a verdict; the credential was refused
and the server offers no keyboard-interactive to fall back to. Each
names the host, the method and the remedy. A credential with words of
its own, an agent's trace, keeps them above the verdict.

One conversation per connection, not per pane. The exchange happens
where the connection is dialled, so further panes, file browses,
transfers and forwards on the same host ask nothing. The daemon's
connection registry stopped letting two panes racing on a cold host
both dial: the first claims the dial, every later one waits on it and
joins the connection it produces, or hears the same typed refusal, so
two panes opened at once hold exactly one conversation. A dial whose
leader stops before it settles (the dialer panicking partway) wakes
every waiting pane with an error and leaves the host cold for the
next dial, rather than leaving them waiting on a dial nobody is
running. The round waiting for an answer is connection state,
readable by another surface.

This part is the engine only: no pane card, no phone, no dashboard,
and no protocol change. Nothing in the desktop answers a server's
questions yet, so a host that asks them is refused by name today and
answered in part 2. `docs/design/termuna-ui-v6.html` does not move.

### Fixed: the fuzzy tab switcher has a shortcut that works

`ctrl+shift+space` was the default for two different features at once:
pick mode's `pick_key` and the fuzzy tab switcher. The key ladder offers
a press to `pick_key` before it looks at the keybinding table, so pick
mode won every time and the tab switcher could not be opened at all on a
default install, while the settings keybinding editor still listed it.
The switcher now opens on `ctrl+shift+o`, pick mode keeps
`ctrl+shift+space`, and the command palette (ctrl+k) has a "Jump to a
tab by name" row so the feature is reachable without a shortcut at all.
Anyone who had bound `tab_switcher` themselves keeps their own key. A
test now refuses any default binding that lands on the default pick key,
which is the collision no per-feature test could see.

### Fixed: a closed pane takes its quiet watches with it

Closing a pane from the UI left every quiet watch armed on it. The
watches stayed behind forever, so the pane's silence watch still fired
about half a minute later, and a fire is relayed to the cloud exactly
like an attention, which could become a phone notification about a pane
that is no longer on screen. The leaked watches also kept counting
against the per-pane and per-session caps, so a live pane holding
nothing could be refused its very first watch, and a window attaching
afterwards was told about watches on panes that were not in its layout.
Closing a pane now stands its watches down the way a pane whose shell
exits already did, silently: every viewer is told they are gone, nothing
fires, and the budget comes back. The same holds for the panes a closed
tab takes with it, and for a session that ends, either by its last shell
exiting or by being killed from the drawer: it drops its watches with
its panes instead of leaving one to fire at a session that is gone.

## [0.2.14] - 2026-09-18

### Fixed: the ctrl+r palette fits its card at every window width

On a window a little wider than the palette's card, the scope chips
row ran past the card's edge with the match count outside it, the
selected command's "insert" tail was cut off at the edge, and the
foot's key hints, laid out as columns, folded the last one into a
sliver six lines tall. Now the card follows the window down to 320px,
the chips wrap onto further lines under the count, which keeps its
place at the end of the first, a long command is cut with an ellipsis
before its tail is, and the foot is one wrapping line of unbreakable
key and label pairs. When even two lines cannot hold them, hints go
in a fixed order: the "ctrl+r again" reminder first, then tab, then
navigate, then ctrl+enter; esc and enter always stay.

## [0.2.13] - 2026-09-18

### Changed: the app replaces its own install on macOS and Linux

Updating a Mac used to end with Finder showing you a tarball next to
the app you were running; on Linux the app opened a session and ran
`tar` in it. Now, when Termuna is installed under your home directory
(`~/Applications/Termuna.app`, `~/.local/bin/termuna`), pressing
Install in Settings, About downloads the release, checks it against
the signed manifest as before, unpacks it beside the install, verifies
the staged copy (on macOS the code signature and Gatekeeper's own
assessment; on every platform that it answers the promised version),
swaps it in atomically and relaunches. The About row says what is
happening at each step, a build that fails a check is deleted and named
there, and your running install is never touched before the new one
has been proven. The old install stays beside the new one as
`.previous` until the next launch. An install that is not yours to
replace (`/usr/bin`, `/opt`, the system `/Applications`, a `.deb`) is
handed to the OS exactly as before; Windows is unchanged.

### Added: a DMG for the first install on a Mac

The release carries `Termuna-<version>-arm64.dmg` beside the tarball:
open it, drag Termuna onto the Applications link next to it. The image
is signed with Developer ID and notarized like the app inside it.
Installed apps keep updating from the tarball.

## [0.2.12] - 2026-09-18

### Fixed: Ctrl+Tab walks to the next tab, the way the docs have always said

With three tabs open, Ctrl+Tab bounced between two of them forever and
the third was unreachable by keyboard. The defaults bound `ctrl+tab`
twice, to `last_tab` first and to `next_tab` seven lines later, and the
matcher runs the first binding it finds, so the documented next-tab key
was dead code and nothing advanced a tab at all. Ctrl+Tab is now next
tab and Ctrl+Shift+Tab is previous tab, exactly what
termuna.com/docs/keybindings publishes. The MRU toggle, back to the tab
you came from, keeps working and moves to Ctrl+Shift+L. A test now
refuses any duplicate combo in the defaults instead of pinning this one,
which is the check that would have caught it when it was introduced.

An install that has run an earlier build carries the old key in its own
config file, because the app persists the whole keymap, so a new default
alone would never have reached the machines with the bug. A stored
`ctrl+tab = last_tab` that has no other home for the MRU toggle is the
old default repeating itself, not a choice, and it is migrated to the
new key once on load. A keymap that deliberately puts the toggle on
Ctrl+Tab, or binds the combo to anything else, is left alone.
## [0.2.11] - 2026-09-17

### Fixed: a mirrored session whose share link was revoked opens again on another desktop

Opening one of your other machines' sessions on this desktop went
through this machine's daemon, which held the session's root key and
nothing that could open a key rotation: every revoke of a share link
rotates the session's content key, and the new secret is sealed to
your account's vault key, which the daemon does not hold on purpose.
So a session revoked even once showed "never opened" here, forever.
The daemon now asks the window, which holds the unlocked vault, and
the window hands it the key for that epoch and nothing more, exactly
what a share link holder gets. Frames that arrive sealed ahead of the
key wait in order and open when it lands, so the layout and the
scrollback come out whole. If the vault is locked in this window the
session says so once, in the pane, and follows as soon as you unlock
it.

### Fixed: the other machines' sessions no longer lock every few minutes, and the app stops asking the cloud every five seconds

With the sessions drawer open, every desktop signed in asked the
cloud for the account's other machines every five seconds, behind the
daemon health poll, and each round fetched the account key blob and
derived the key from the passphrase again (an Argon2 run each time).
One lost request in that stream sealed every row and asked for the
passphrase the window already held, which on a busy network read as
the vault locking itself every few minutes. The quiet refresh now asks
at most once every twenty seconds (the minute tick and the moments
that change the answer, a session opened elsewhere or the vault
unlocked, still ask at once), and a round that could not say keeps
the last answer on screen. A passphrase the cloud calls wrong still
seals every row, as it must.

## [0.2.10] - 2026-09-17

### Added: "Check now" on the About screen

Settings, About asks GitHub once a day, so for most of a day after a
release it could only say "0.2.4 is the newest release we know of" and
offer no way to ask again. The updates line now carries a "Check now"
button that runs the same signed check at once, shows "Checking..."
while it is out, and lands the answer on the same line; a failed check
offers it beside Dismiss. It is held to one request every ten seconds.

## [0.2.9] - 2026-09-17

### Fixed: after an update the app no longer flickers on "connecting to mux"

Installing a new build leaves the old daemon running, still holding
your shells, and on macOS the update never restarted it. The new window
sent that daemon a frame it had no name for, the daemon dropped the
connection, and the window walked back in once a second, forever,
showing the connecting screen between every attempt and never staying
long enough to reach the About screen's "Restart daemon". Three
things changed. The window now restarts a daemon that is behind its
own build by itself, once, the moment the daemon says its version
(the ADR 0008 handoff, so the shells come along). The daemon skips a
frame it cannot decode instead of ending the attachment. And an attach
the daemon drops within seconds no longer refills the quiet reconnect
allowance, so if the loop ever recurs it ends on the connecting
screen naming the failure instead of flickering. A daemon newer than
the app is left alone.

### Fixed: signing out clears the other devices' sessions from the drawer

The drawer kept listing the account's other machines and their
sessions after a sign-out, because nothing refreshes that list while
signed out, and the daemon kept mirroring any of them you had opened.
Both go with the account now: the lists are emptied on sign-out and
the daemon ends every mirror the moment it is told there is no account.
Your own sessions stay, as before.

## [0.2.8] - 2026-09-17

### Changed: Windows builds are not published until they are signed

The Windows installer was unsigned, so every install went through
SmartScreen's "unknown publisher" warning. A release now ships Linux
and macOS (signed and notarized) only; the Windows installer returns
the moment it can be signed. A Windows install of an earlier version
is told there is no update rather than offered a file, and
termuna.com's Windows button says the same.

## [0.2.7] - 2026-09-17

### Fixed: a session whose share link was revoked before today opens on the phone again once the daemon reconnects

A session that had a share link stopped rotated its content key, and
the relay, which keeps a bounded tail of each session's history, used
to trim the rotation frame with everything else after a while. A phone
or the dashboard opening such a session fresh had the root key and no
way to the current one, so the session never painted. The relay keeps
rotation frames from now on; for a session it had already trimmed, the
daemon now re-publishes its rotations when it reconnects, told by the
relay which ones it lost (`Welcome.tail_from`), so the chain is whole
again and the session opens. Nothing to do: the daemon does it on its
next connect after the relay says.

## [0.2.6] - 2026-09-17

### Fixed: your own phone and the web dashboard type into your sessions again

Since the one-keyboard rule landed (2026-09-07), every keystroke that
came through Termuna Cloud was treated as a guest's, and a guest does
not hold the keyboard while your desktop does: your own phone typed
into nothing. The relay now says who a keystroke came from (your own
device or a share link) and the daemon writes your own devices as one
party with the desktop, so the phone types whenever your desktop
would. A share-link guest is unchanged, and now carries its own name
in the keyboard block instead of "the link it came in on". Needs a
relay that stamps its frames; against an older relay everything stays
exactly as it was.

### Changed: a release publishes, signs and reaches apt with nobody at a keyboard

The three steps that used to wait for the maintainer after a green
release build (publishing the draft as latest, signing the update
manifest installed apps check, rebuilding the apt repository on
termuna.com) are the last job of the release workflow now, with the
keys held by the `release` environment (ADR 0020). A tag cut by the
release train is downloadable, offered to installed apps and on apt by
the time the workflow is green, and the workflow can be rerun in a
publish-only mode on a tag whose draft is already complete. The apt
repository's master copy lives on the server: the publish script pulls
it first and refuses to push over a tree it could not read.

### Fixed: a bad split ratio could destroy a session for good

Dragging a divider inside a very narrow or deeply nested split could
produce a ratio that is not a number. Nothing refused it: it was stored,
written to the session file as `null`, and from that moment no viewer
could decode the layout. On the next start the daemon skipped the file as
unreadable, so the session and its scrollback were gone while the file
sat on disk. A ratio that is not a finite number is now refused by the
session model and by the daemon before it reaches the model, and a
snapshot that already carries a broken ratio decodes to an even split
instead of costing the whole session, so sessions corrupted by an older
build come back on the next start.
### Fixed: the buttons in the amber strips fit their row

"use my size" in the grid-held line and "Take it back" in the keyboard
holder's strip were drawn at the full control height inside a row two
pixels shorter than that, so each pill's border sat on the strip's own
border, top and bottom. Both are the small inline control now, the size
the design always gave them, with a pixel of air on each side; the
strips keep their height and the grid loses nothing.

### Fixed: a phone that comes back from the background is listed once

The continuity panel showed "Termuna mobile (iPhone) · viewing now"
twice, and the grid-held line counted the ghost as "and 1 more",
whenever the phone app had been backgrounded and reopened: the relay
keeps a viewer row per socket, and iOS leaves the old socket half open
until the network gives up. The panel now lists one row per device
(by the relay's device id when it sends one, else by name), the newest
attach winning, so the phone reads as one screen however many sockets
it has been on. Two nameless share-link viewers still count as two.

### Changed: the macOS app is signed with a Developer ID certificate and notarized by Apple

`Termuna.app` from a release now opens on double-click on any Mac:
Gatekeeper finds a Developer ID signature with the hardened runtime and
a stapled notarization ticket, so there is no right-click Open and no
quarantine dance. The release pipeline does all of it on our own runner
(rcodesign signs, submits to Apple's notary service and staples, from
Linux), so the macOS archive is attached to every draft release beside
the Linux and Windows ones instead of being built and uploaded by hand.
One consequence for anyone who ran an earlier release: the signing
identity is new, so the keychain asks once more for the vault item and
then holds.

## [0.2.5] - 2026-09-16
### Fixed: the release runs on our own runner, and cross-builds the Linux artifacts to x86_64

No desktop release had shipped since v0.2.4 (2026-08-25). The release
train and the release itself were pinned to GitHub-hosted runners, and
hosted minutes are billing-blocked on this org, so every run died in
four seconds with "recent account payments have failed" and not one
step executed; the website's services deploy, gated on the newest
desktop tag, stayed blocked with it (board #316). Both workflows now
run on the self-hosted runner the rest of CI uses, the way the
download-links watchdog already did. That runner is aarch64 and the
Linux release is x86_64, so the Linux tarball, daemon binary and .deb
are cross-built with cargo-zigbuild (zig as the linker and the glibc,
no root needed), the job checks the architecture of every binary
before naming it, and the .deb is built for amd64 with the glibc floor
the binary actually imports, compared on every run. The Windows leg
asserts the machine's toolchain instead of trying to apt-get it, and
every job writes only what it built into a directory it emptied first,
so a persistent runner cannot hand a previous release's files to the
next one. `scripts/check-cross-toolchain.sh` knows the Linux target
now, and docs/RUNNER-SETUP.md carries the zig provisioning.

### Added: the permanent download URLs are checked, daily and after every release

The download buttons on termuna.com, the in-app updater and the daemon
install one-liner all fetch through GitHub's permanent
`releases/latest/download/<name>` URLs, and "latest" is whichever
release was published last into `termuna/termuna`, a repo the Android
app now shares. On 2026-09-12 a mobile release took the pointer and
every desktop download answered 404 for four days with nothing to say
so. `scripts/check-release-links.sh` now names the tag that owns
`latest`, refuses one that is not a desktop `vX.Y.Z` (and says the
publisher of the other product must pass `--latest=false`), and probes
all six permanent URLs for a 200; `sign-release.sh` runs it as the last
step of a release, the draft release notes tell the publisher to run
it, and the "Release links" workflow runs it every day.

### Fixed: Escape did not close the pane's context menu, and keys went under it

The right-click menu over a pane was the one overlay Escape did not
reach: any number of presses did nothing, and only a click on the scrim
or on a row took it down. Worse, while it was open every other key went
straight past it into the shell underneath, so a command typed under
the open menu, Return included, ran in the pane behind it, the same
defect the command palette had (board#162) and this menu kept. The
first Escape closes the menu now (board#343), peeling it before the
drawer, a rename, a summoned panel or the tab switcher under it, the
same way a scrim click closes it (the "this command" row and the
condition card go with it), and while it is open no key reaches the
shell: the menu asks the keyboard nothing, so nothing typed at it is
its own. A session ending under the open menu, a failed attach or the
daemon's link dropping take the menu down with the session, and the
menu holds keys only in the terminal view it is drawn in, so the
connecting screen's keyboard is never held by a menu that is not on
it.

### Fixed: a long path in the pane menu's download row ran to the edge

The pane context menu is a fixed width, but nothing shortened the text
in its rows, so `download "/home/ksoldo/dev/sniffs-life"` was drawn
past the row's shortcut column and off the panel's edge. A label built
from what the person selected, named or typed is now cut to the row
(board#303): in the middle, at a `/` where one fits so what stays still
reads as a path, the tail that names the file always kept (`download
"/…/sniffs-life"`), measured in mono cells over grapheme clusters so a
wide glyph counts for two and a combining mark is never orphaned. The
untouched text is a hover away, on a tooltip that exists only when
something was cut. The same one rule now cuts the tab menu's title, the
host menu's `user@host` fact and its "move to <vault>" rows, and the +
menu's profile names, and the row's budget is computed from the panel's
own metrics rather than eyeballed, so a label cut to it fits beside its
hint on the 250px panel (glyph shortcuts, macOS) and the 296px one
(shortcuts spelled in words) alike.

### Fixed: a watch on one split was dismissed by typing in the other

A quiet watch is armed on a pane, but "is the user looking" was read
off the session: the last keystroke into any pane of it. So a bell
watch on a long build in one split, with the person working in the
split beside it, was stood down at the ring as if they had seen it,
with no notification and no watch left. Presence is the watch's own
pane now (board#326): typing next door never touches it, and a bell
under the fingers, in the pane being typed into, still dismisses as
before. The attention badge keeps reading the whole session, because
it is one flag per session that any keystroke stands down.

### Fixed: a command typed with a leading space could land in history after all

A leading space is the shell's own "do not remember this", and the
recorder honours it, but only on the line it had read as the command.
Typed ahead of the shell (the next command entered before the last
one's prompt was back), the recorder snapshotted the prompt off a line
the shell had not drawn yet, an empty snapshot matched every line, and
the hidden command's *output* was sealed into the store as the next
command while the command actually typed next got no record at all.
Now a shell that marks its prompts (bash and zsh out of the box, fish
by itself) is read only off the lines it marks, a keystroke that lands
before the next prompt is read against the last prompt the shell drew
rather than nothing, and where the prompt changed since (a `cd`) the
boundary ends at the prompt and never swallows a space the person
typed. Where the boundary cannot be trusted, nothing is recorded.

### Fixed: a once-only pattern watch no longer dies on the echo of the command that armed it

Arming a watch on a word of the line just typed, which is what the
arm card does from a selection, produced a watch that never fired: the
pane's echo of that command line contains the pattern, it lands while
the user is demonstrably present, and a match under the user's nose
dissolves a once-only watch. So the watch was gone the instant it was
armed, with no notification and nothing left to fire when the line
actually appeared later. A match in the first two seconds after arming
now leaves the watch standing; past that, a match the user watched
happen still dissolves it quietly, and a keep-watching watch is
unchanged.

### Added: bash and zsh report each command's exit status, out of the box

Every row of "while you were away" read `exit unknown`, "open the
failing one" never had anything to open, and a command mark's boundary
was a prompt snapshot rather than the shell's word, because the
recorder reads OSC 133 and bash and zsh do not speak it on their own.
Fish does. Now the daemon carries the integration and gives it to a
local shell the way the shell allows, with nothing to install, source
or switch on: bash is started with `--init-file` naming a script whose
first act is to read the user's own `~/.bashrc` (the system file bash
reads by itself is not read twice), zsh with `ZDOTDIR` pointing at a
directory whose every file reads the user's file of the same name from
their own directory and hands `ZDOTDIR` back at the end. The scripts
are written under the app data dir on the first spawn and kept current
by each build. A user's own `PROMPT_COMMAND` and precmd hooks keep
running and keep seeing the exit status they always did.

The marks are A before the prompt, B where the command starts, D with
the exit status (zsh adds C when the command runs). Any other shell,
and every shell when `TERMUNA_SHELL_INTEGRATION=0` is in the daemon's
environment, is spawned exactly as before. Known limits: local shells
only (a shell on the far side of SSH is the host's; the kit is the
natural carrier, later), Windows untouched, and zsh is pinned by unit
tests rather than run live, since the build machine has none.

### Fixed: "while you were away" counted from the wrong moment

The section took "since you left" from the oldest read stamp among the
session's panes. A pane's stamp only moves while that pane is on
screen, so a tab not opened this attach kept a stamp from whenever it
was last looked at, and the section then listed everything typed in
the other tabs since, by the person who was sitting there typing it.
It is the newest stamp now, the last time this device looked at any
pane of the session, which is when it left.

### Fixed: renaming a tab or a session edits the name in place

Double-clicking a tab swapped it for a bordered well of its own width:
the ordinal and the close glyph vanished, the text scrolled, and esc
fell past it to the shell, so the only way out was to commit a name.
The drawer's rows and the sessions screen did the same with their
own well, and the sessions screen added Save and Cancel beside it.

A rename keeps the row exactly as it was, tab and session alike: the
same shape, height, glyphs and fill, with only the name turned into a
field. The field opens with the whole name selected and the caret
showing, so typing replaces it and an arrow key edits it, Enter
commits and esc backs out with the name untouched. Double-click starts
a rename on a session row (the drawer, a mirrored machine's row, the
sessions screen) as it already did on a tab; the right-click menu and
the rename verb still do too. While a row is being renamed a press in
it places the caret rather than opening the session or arming a tab
drag. The v6 mockup shows both, `?rename=tab|session`.

### Fixed: the drawer's live and idle sections are back

Board#293 gave the session list a fixed order, creation order, so a
row never moved because a session was written to disk or went quiet.
It also dropped the live and idle sections, and that was the part
nobody asked for: the division decides what a row can do (a live
session takes a keystroke now, an idle one has to be woken first),
and losing it is a real loss. The drawer and the sessions screen head
the list with `live` and `idle` again, each divided by machine as
before, and inside each section the rows are in the daemon's creation
order, oldest first, appended and never re-sorted. The command palette
lists sessions in the same order. The v6 mockup moves with it.

### Fixed: the command-mark gutter no longer reads as a gap

The 22px column left of the pane's text (board#201) was painted in
the chrome's own surface with a rule at its edge, and next to a
pinned drawer of the same colour it read as the sidebar continuing
into the terminal, a gap between the two rather than a margin of the
grid. The column is the pane's own background now, still 22px wide so
nothing shifts when the first mark arrives, with the mark hairlines
drawn on it exactly as before.

### Fixed: the host card is wide enough for its form

"new host" and "edit host" opened at the width the other cards take,
and at that width the three-field row, the two inputs with a Test
beside them and their hint lines wrapped and clipped against the
scrollbar. The card states its own width now, 640px, because a card
sizes to what it holds and this one holds the densest form in the
app. Every other card keeps the width its call site states.

Two more things were wrong with the same card, and with the kit
editor, which shares its shape. On a window shorter than the form
the card ran off the bottom and took Cancel and Save with it: the
body scrolls inside the card now, capped by the window's own height,
so the card stays at its anchor with its actions on screen. And the
scrollbar was painted over the body's right edge, covering the end
of every input and the Test beside it: it has a gutter of its own
now.

### Fixed: hovering the share split's caret drew a block over its edge

In the continuity panel's SHARE block, hovering the chevron half of
"Copy view link" filled a square that painted over the control's
right border and stuck out of its rounded corners. The two halves sit
inside the wrapper's border now and take its rounding on their outer
corners, so a lit half ends where the border does. The caret is the
control's own 26px square, as the test beside it already claimed.

### Fixed: copy works on text selected inside a TUI

Board#298. Text selected with the mouse over a program on the
alternate screen (vim, htop, less, an agent's TUI) painted a highlight
and then the pane menu's copy row read "no selection", greyed. The
engine cancels a selection whose cells are erased, which on the
primary screen is right (a `clear` really did remove the text) but on
the alternate screen is what every frame does: erase the line or the
screen and paint it again, so the selection went a frame after the
drag, and the highlight and the menu disagreed. On the alternate
screen the selection is a range of the screen now: a redraw keeps it
and re-reads the cells under it, and only leaving the alternate
screen, a reset or a resize clears it. The primary screen is
unchanged.

The copy row, ctrl+shift+c and the status bar read one value, decided
once. The row is live whenever something is highlighted and carries
the count read from the exact string the clipboard will get, "2
lines, 118 chars"; the status bar counts the same selection. Disabled,
it states the true reason and only that: "no selection" when nothing
is highlighted, "shift-drag to select" when a program is taking the
mouse. While a drag happens over such a program the status bar says
"this program is taking the mouse, hold shift to select" in the quiet
counter register, gone with the release; the same line now also
appears over a program that hears clicks only. A whitespace-only
selection is nothing for the shortcut as it always was for the row.

### Fixed: reset zoom resets

Board#311. `reset_zoom` (ctrl+shift+0) never changed the font size.
Persisting the zoom and resetting it shared one field: a grow or a
shrink wrote the new size into the active profile's `font_size`, and
reset read its target from that same field, so after any zoom the
target already was the live size and reset assigned the size to
itself. Somebody who had zoomed could not reset, and somebody who had
not had nothing to reset.

The two meanings are two fields now. `[[profiles]].font_size` is the
configured size and only an explicit edit in the settings panel moves
it; `zoom_offset`, new on the profile, is how far the live size is
from it, signed, and it is all a zoom ever writes. The size drawn is
the sum, held to 6.0 through 72.0, and the offset is derived from the
clamped size rather than accumulated, so grows at the ceiling bank
nothing and the next shrink shrinks. A size picked in the panel
clears the offset, because it names a new baseline; a profile switch
applies the switched-to profile's own base and offset; the legacy
`[font] size` mirror carries the drawn size, as an older build would
read it. Zoom still survives a restart, and a reset after that
restart returns to the configured size, which is the case one field
could not express. A config file without the key loads unchanged with
no zoom, and the key is only written when there is one.

The offset is this machine's own: the synced settings item is
unchanged and carries the configured size, and a profile adopted from
another machine under the same name keeps the zoom it had here. A
profile made new or duplicated starts at its configured size: the zoom
belonged to the window, not to the profile it was copied from.
### Fixed: ctrl+shift+plus zooms in again

Board#310. The default `font_larger` binding, `ctrl+shift+plus`, never
fired on a normal US layout, because the hotkey matcher only read the
key with no modifier applied (`=`) and iced 0.14 carries the shifted
character (`+`) in a separate `modified_key` field the app ignored.
`ctrl+shift+minus` worked, since `-` is its own unshifted key, so zoom
was a one-way ratchet out of which the only way back was editing
`config.toml`. A binding step now matches either reading of the press,
unmodified first, with the modifiers still compared exactly, so
`ctrl+shift+plus` fires on the `=` key under shift and on the numpad's
own `+` alike, and so does any binding a person writes with a shifted
punctuation name (`ctrl+shift+?`, `ctrl+shift+:`). Chords and
`[terminal] pick_key` read both keys the same way. `docs/CONFIG.md`
says so in one sentence.

### Added: the vault's Kits screen, the kit editor and the host choice, part 4 of 6

Board#307, part 4 of the "carry a kit to the host" epic (board#283).
Part 1 gave a kit a shape and a home in the vault, part 2 said which
host carries which one and why; both were invisible. This is the half a
person can see: kits are a screen beside snippets, layouts and trusted
hosts, a kit is edited in a card, and a host record says which one it
carries.

`apps/termuna/src/kits.rs` is the pure half, no widget and no vault
file: the list row (files, size and how many hosts actually resolve to
the kit), the search, the order, the editor's draft, the size meter and
the single choice, so the ordinary, empty, at-the-cap, over-the-cap,
no-group and many-overrides cases are unit tests rather than something
to click through. `apps/termuna/src/app/kits.rs` is the window half,
the snippets and layouts screens row for row, because a kit is a vault
item like a snippet.

**Nothing here restates a rule.** Every refusal is the vault crate's
own sentence, asked for by handing part 1 the kit it would store, or
one row of it, and letting it judge: the editor cannot be stricter or
milder than the vault it writes into, and a refusal stands beside the
field that earned it, named. A mode that is not octal digits at all is
the one sentence this screen writes itself, because that is about the
text in a field and not about a kit. The one rule the screen adds is
that a kit carrying nothing is not stored: part 1 calls such a kit
valid and it is, but a host carrying an empty kit and a host carrying
no kit are the same host, and one of the two is a row nobody can
explain.

**The size meter is on screen while editing**, read from `Kit::size()`
against `KIT_SIZE_CAP`, so the ceiling is seen rather than met: the cap
in the low tens of KiB is the promise that this can never turn into a
file sync product. It is the same number the refusal names, so the two
cannot disagree. Colour reinforces the number and nothing more: mint
with room to spare, amber in the last tenth, warn over the cap, and the
track never overflows.

The host card gains two fields. A kit choice, one choice defaulting to
"No kit", never a set of ticks that quietly accumulate, with the fact
of what this host carries **and why** above it, in part 2's own words:
chosen for this host, from the group corp, this host carries nothing
whatever its group says, or the amber fact that a kit it names is not
in this vault any more. The group row is drawn only where a group above
the host actually has a default, which is what keeps the third state
reachable without inventing a meaning for it elsewhere. And a group
field, because a group was only ever a string on the record with no
screen to write it: without it a group default could never reach a
host. An edit now writes both from the card, which is what part 2 said
it would do once a screen could show them.

The kits screen lists the groups under the kits, each stating what it
hands out and how many hosts under it decide for themselves; opening
one gives the same single choice over the whole group and lists every
host in it with what it does instead, so an exception is visible from
the group rather than found one host at a time. A host taking a nearer
group's default is an override from up here, and says which group
decided.

Free versus paid is the sentence every other vault item already uses:
kits are defined, edited and carried to hosts on every plan, signed out
included, and what Termuna Cloud buys is carrying them to your other
machines and your phone. Removing a kit names how many hosts carry it
first. A host or a group still naming a deleted kit is not repaired on
the way out: part 2 answers a dangling reference with a reason, the row
says it, and rewriting every record that mentioned it would sync a
decision nobody made.

`docs/design/termuna-ui-v6.html` gains the kits screen with its groups,
the kit editor with the meter and a named refusal, the group default
card with its override list, and the host card's kit and group fields
(`?kits=list|empty|local`, `?kitcard=edit|full|new`, `?kitgroup=1`,
`?addhost=kit`), verified by rendering the page. A long card scrolls
inside itself there now, as it already did in the app.
### Added: the kit carries our terminfo entry, part 5 of 6

Board#308, part 5 of the "carry a kit to the host" epic (board#283).
Part 3 put the kit on the host and left terminfo alone, naming this
part as where it would land: its known limit was true when it was
written and this is the entry that lifts it. A kit that ticks
`install_terminfo` now carries Termuna's own terminal description to
the host, and every kitted pane says which `TERM` it really got.

**The entry is ours and it rides in the binary.**
`assets/terminfo/termuna-256color.ti` is the source description and
`termuna-256color.compiled` what `tic -x` makes of it; the daemon embeds
the compiled bytes (`kits::TERMINFO_ENTRY`, `include_bytes!`), so a host
is given the entry and never asked to have `tic`, a database to merge
into, or anything else installed. A unit test reads the committed bytes
back as a terminfo header and finds our own name in the name section,
so an asset that was truncated, half copied or compiled without `-x`
fails CI rather than somebody's host.

**One write outside the session directory, and only when asked.** Part
3's rule was that the user's own `$HOME` is never written. This is the
one exception, and it is held to it: the entry goes to
`~/.terminfo/t/termuna-256color`, where ncurses looks, under the home
the far side itself names in the same one round trip that makes the
session directory, never a home guessed from a user name; the
destination is resolved through the very `join_under` every kit path
goes through; it is exactly one file, mode 0644; and a kit without the
tick never asks the far side about a home at all, so nothing under one
can have been made for it. Only once the entry has landed does the
pane's `TERM` become `termuna-256color`, exported ahead of everything
else so that a kit naming a `TERM` of its own still wins, the same rule
the rest of the environment already follows.

**The pane states the `TERM` it got.** Whichever way it went, the
connection gets one dim line in the applied row's own mint, `TERM here
is termuna-256color, installed in ~/.terminfo` (or `already in`),
because a terminal type that is wrong in a way nobody prints is how an
afternoon goes into a redrawing `less`.

**A `~/.terminfo` that will not take it refuses the entry, never the
kit.** No home named, a `~/.terminfo` that is not writable or not
there, a lane that would not take the bytes: each is one amber line in
part 3's own grammar, `kit <name> terminfo not installed: <why>, TERM
here stays xterm-256color and the session continues`, and it is the one
refusal that leaves the kit applied. The files are written, the rc is
read, the shell starts, and only the `TERM` is the one the host already
knew.

**What we wrote, we take back; what was there, we leave.** An entry
already at that path that is byte for byte ours is not rewritten and not
removed at the end of the session either: it is not this session's to
take, and a host somebody works on every day keeps one file that costs
one read. One that differs is an older Termuna's, under a name only
Termuna writes, so it is replaced and taken back with the rest. The
session's end removes exactly the entry this connection wrote, both ways
a session can end, beside the kit's own files and never a recursive
delete.

**Nothing changes for anyone who did not ask.** A kit without the tick
and a host carrying no kit run exactly as they did after part 3: no
home is asked for, no `~/.terminfo` is made, no `TERM` is exported and
no line is printed, and `TERM` stays `xterm-256color` there as it always
has.

`docs/design/termuna-ui-v6.html` does not move: the pane gains printed
lines and nothing else, no widget, no affordance, no new chrome.

**Known limits.** Part 3's other limits stand, and the first of them
covers this part too: nothing sets `SshTarget.kit` until part 4's
screens land, so today the tick is a field on the vault item with no
window to tick it in, and no host receives the entry yet. The entry
goes under the user's own `~/.terminfo` only, never a system database,
so a program that ignores the user's own database keeps
`xterm-256color`. A shell that is not bash, zsh or POSIX-ish (fish,
say) still gets the `TERM`, exported like any other variable before the
shell is `exec`ed; part 3's limit that such a shell reads its own
config rather than the kit's rc is unchanged.

### Added: the daemon carries the kit to the host, part 3 of 6

Board#306, part 3 of the "carry a kit to the host" epic (board#283).
Parts 1 and 2 gave a kit a shape and answered which host carries which
one. Nothing put one on a host. Now the daemon does, before the shell
starts, and takes it back when the session ends.

The kit rides the local IPC target the client already resolves
(`SshTarget.kit`, boxed, serde-defaulted, no protocol change and no
`PROTOCOL_VERSION` bump), so the daemon holds no vault and walks no
group tree to open a shell. `termuna-mux::kits` is the whole rule and
almost all of it is pure: the precheck, the one command that makes the
directories, the plan of what to write, the generated rc, the refusals,
the two pane lines.

**The user's own `$HOME` is never written.** Everything a kit carries
goes under one directory in the host's temp space (`$TMPDIR` when the
host names one, `/tmp` otherwise), and the kit's own files go one level
below that, so a kit carrying `.zshrc` or `rc.sh` cannot collide with
the glue that has to read it. Every path a kit names is resolved under
that directory and refused if it would leave, at the write site as well
as in the vault, because a kit can arrive from another machine or from
an account somebody else writes to. `~/.bashrc`, `~/.zshrc`,
`~/.profile`, `~/.vimrc` and `~/.ssh` are read and never written.

The directories are made by one shell command under a umask derived
from the one mode this writes down, not over the file lane: sftp cannot
say "this mode and no other" (`SSH_FXP_SETSTAT` is refused outright by a
good many OpenSSH installations, and `SSH_FXP_MKDIR`'s own mode is
whatever the server's umask leaves of it), and a directory that is
briefly readable by everybody on a shared host is not a boundary at all.
That one round trip also finds the temp space and tells the three
answers apart, so it is the POSIX test as well. The name is random and
unguessable, never the session id. Files go down the existing sealed
sftp lane with their mode asked for at open, so a carried file lands
with at most the bits the kit asked for and never more.

The shell reads it because the server runs a command in place of a login
shell, and that command `exec`s the shell in its own place: an
interactive shell reads no environment a client can set, since `SetEnv`
is refused by nearly every sshd. `ENV`, `ZDOTDIR`, `VIMINIT` and the
kit's own pairs are exported, the kit's last so it can override; bash
gets the generated rc as its `--rcfile` and zsh finds it through
`ZDOTDIR`. Because that shell is then not a login shell, the generated
rc reads the host's own login files back first, and the four zsh startup
files are written to read the host's own: without that, choosing a kit
for a host would quietly cost you the host's own setup.

**One application per connection, not per pane.** The record lives on
the connection itself, so eight panes on one host write the far side
once and the second pane is told nothing at all. The lock is held across
the writing, which is what makes two splits opening at the same instant
one application rather than a race. A redial is a fresh connection and
so a fresh directory, which is how a dropped link comes back with the
same environment.

**A refusal is amber, one line, and never fatal.** A temp space that is
read only, one that is not there, a far side that is not POSIX like, a
kit over the cap, a host with no sftp lane, a path that would climb out:
each is one line in the pane in the same grammar, saying what was not
applied, why, and that the session continues without it. The session
then runs exactly as it did before kits existed. A write that fails
halfway takes back whatever landed, because a half written kit is worse
than none.

The session's end removes the directory, both ways a session can end,
taking back exactly the files and directories that were written and
never a recursive delete. A connection already dead keeps its directory
and nobody hears about it: what is left is mode 0700 under a name nobody
can guess, in a temp space whose own cleaner takes it.

`docs/design/termuna-ui-v6.html` does not move: the pane gains printed
lines and nothing else, no widget, no affordance, no new chrome.

**Known limits.** Terminfo is untouched here, that is part 5
(board#308). Nothing sets `SshTarget.kit` yet: resolving which kit a
host carries needs the vault's kit list and its group defaults, and the
window holds neither until part 4's screens land, so today every host
still carries nothing. A host that forwards its agent never reaches a
shared connection and so carries no kit. A per-pane redial on an
unshared connection dials through `Backend::spawn` and comes back
without one; the connection-level redial, which is the ordinary one,
re-applies it. A shell that is not bash, zsh or POSIX-ish (fish, say)
starts with the kit's environment but reads its own config rather than
the kit's rc.

### Changed: the session list is in creation order and stays there (board#293)

The list on the left was sorted live first, then by the last time each
session was written down. Both halves moved on their own: a persist
refreshes that stamp, so a session lifted itself to the top by doing
nothing but existing, and a session whose last shell exited dropped out
of the live block into the idle one. Position is how a session is found
at a glance, and a list that rearranges itself turns every glance into a
read.

A session now carries the one stamp about it that never moves: when it
was created. `SessionState.created_at` is set at `create_session` time,
written into the session's own file on every persist and never rewritten
by one, and `SessionInfo.created_at` puts it on the wire (additive,
`#[serde(default)]`, no `PROTOCOL_VERSION` bump). `list_sessions` sorts
by it, oldest first, with the session id breaking a shared second so two
listings can never disagree. `live` is out of the sort key altogether: a
new session is appended at the end, a deleted one closes its gap, and
neither age nor going dormant moves anything.

The order survives the daemon. A restart reads the stamp back off disk;
a handoff carries it in the snapshot (`HandoffSession.created_at`,
serde-defaulted). A session persisted before this change has no stamp,
so it is placed by the oldest one its file does carry, `saved_at`, which
is stable across loads, and the next persist writes the answer down: an
upgrade does not scramble a list anyone had learned. A predecessor too
old to carry the stamp through a handoff leaves the successor reading
the session's own file rather than calling every session new.

No surface re-sorts or re-groups what the daemon sends. The drawer's
"live" and "idle" sections are gone, because a section is a sort: one
rule reading `sessions` heads the whole list, keeps the count and the
new-session action, and states how many are live as a fact beside the
total. Whether a session is running is still on every row, in the dot
and in the ink. The machine a session runs on stays a division, since
another computer's sessions are a different axis rather than a sort of
one list, and it still appears only once there is a second machine. The
sessions screen loses the same two groups, its filter narrows without
reordering, and `ctrl+k` lists sessions in the drawer's order rather
than a recency order of its own. `search::order`, which reads panes "in
the order the drawer sorts by", follows: the focused pane first, then
every session in creation order, live and dormant alike.

`docs/design/termuna-ui-v6.html` moves with it, verified by rendering
the page.

### Added: which host carries which kit, part 2 of 6 (the choice)

Board#305, part 2 of the "carry a kit to the host" epic (board#283).
Part 1 gave a kit a shape and a home in the vault; nothing said which
host got which one. Now a host record says it, a group can say it for
every host in it, and one function answers the question with its reason
attached. Data and logic only: no screen shows any of it yet, so
`docs/design/termuna-ui-v6.html` does not move.

`Profile.kit` is a `KitChoice`, additive and serde-defaulted like every
per host field before it (the agent socket, the certificate,
`ForwardAgent`, the environment), so it is sealed and synced with the
rest of the record for free and an older vault loads as it always was.
Three answers, not two, for the same reason `ForwardAgent` has three:
"nobody chose for this host" and "this host carries nothing" are
different sentences. The first lets a group's default through, the
second is a person saying that this one machine is to be landed on
exactly as its administrator made it, and the row can say so.

A group is not a record: it is only the `/`-separated string on a host,
with no id to hang a field off. So the group defaults are a map beside
the items, `group path -> kit id`, sealed and persisted with the rest of
the file and read through `Vault::group_kit`, `set_group_kit` and
`clear_group_kit`. Clearing removes the entry rather than writing an
empty string, and the path is normalized by the same rule `Profile`
already grouped by, now written once as `normalize_group`, so
`clients//acme/` and `clients/acme` cannot become two groups.

`kit::resolve` is the whole rule, pure and unit tested: a host's own
choice wins over any default; a host that has not chosen asks the
nearest group above it, `clients/acme/prod` then `clients/acme` then
`clients`, and a host in no group has nothing above it, because the
root is not a group and there is no vault-wide kit. It answers with the
kit and with a `KitSource` saying why, which is what part 4 renders:
the host chose it, this group handed it down, the host is pinned to
none, nobody chose. A kit deleted here or on another machine while a
host or a group still names it resolves to no kit and reports the
dangling reference by name. It is never an error and it can never
refuse a connection or an unlock: a kit is what a session brings to a
host, not a condition of reaching it.

`~/.ssh/config` learns no keyword. An imported host arrives with no kit
and a reconcile never gives it one, because an import is not a decision
to write files onto somebody's machine, and a host given a kit here
keeps it while the file goes on owning the rest of the record.

**Known limit:** a host's choice travels with its record, but the group
defaults map is not an item, so it stays on the machine that set it
until a later part decides how a group travels.

### Added: a kit is a vault item, part 1 of 6 (the data model)

Board#304, part 1 of the "carry a kit to the host" epic (board#283).
Landing on a remote host gives you the host's bare environment: no rc
files, no aliases, no `EDITOR`, often a terminfo that does not know
what this terminal can do. The epic carries a small kit there for the
session and takes it back at the end; this part is the sealed data
model and its rules only, so the five parts that follow have one
definition to read. Nothing carries a kit anywhere yet: no UI, no
daemon change, nothing new on the wire.

A kit is a vault item (`"type": "kit"`), sealed, stored and synced by
exactly the machinery a snippet, a trusted host key and a layout
already use: a name, a note, the files it writes (a path relative to
the home directory on the host, the contents, the permission mode),
the environment it sets, and whether this terminal's own terminfo entry
is installed. A client that has not learned kits keeps the blob, as it
always did for an unknown type.

Three rules are enforced in the item rather than at the far end,
because the far end is somebody else's machine. A path is relative,
holds no `..` component, no NUL and no newline, and appears once, so a
kit cannot name `/etc/profile` or climb out of the directory it is
written into. A mode is permission bits and nothing else: no setuid,
no setgid, no sticky bit. And a kit is small, 64 KiB over its files and
its environment, measured by one public function that the later size
meter and the refusal both read, so the two cannot disagree about what
full means. Every rule refuses by its own name, and a kit pulled from
the account is held to the same ones as a kit made here.

### Added: one shared SSH connection per host, part 3 of 4 (the desktop says so)

Board#278, part 3 of the "one shared SSH connection per host" epic
(board#267), surfaces only. Parts 1 and 2 made the daemon hold one
connection per host and moved failure and redial onto it; nothing on
screen said so, and a split on an already-connected host looked exactly
like a fresh handshake.

A pane that opens on a connection this machine already holds prints no
connection noise at all and wears a brief mint `shared . 22 ms` badge
carrying the daemon's own measurement of that open, fixed for the few
seconds it is up: the contrast against a fresh handshake's few hundred
milliseconds is stated in the header rather than left to a benchmark. A
pane that fell back to its own connection wears the amber `own
connection` badge with the server's own stated reason, never an invented
one.

The pane that actually pays for a connection says what it bought, before
the dial, in its own scrollback: "This authenticates the connection, not
this pane. Every pane, file browse, transfer and port forward on
kris@bastion.corp.example uses it until it goes idle, including from your
phone and the dashboard." The daemon writes it, because the daemon is
where a hardware key's touch and a push approved on a phone are actually
answered, so it is on screen while the key is waiting rather than after
the fact. Panes that join afterwards are silent.

The host record gains a connection block: target, identity, state,
channels used of the server's limit, that it authenticated once and how
long ago, the linger as a countdown that actually counts down, with
`Keep open` and `Close now`, and every consumer named. A shared
connection's outage shows one redial bar for the whole connection,
naming its consumers with the attempt counter, in place of one count per
pane; `esc` on a pane waiting on that outage stops it, and the bar
offers the key only where it works. `ctrl+k > Connections` lists every
connection this daemon holds with host, identity, state, channels, who
is using it and uptime; closing a row closes the connection and tells
the consumers, it never kills a pane. Settings expose the part 1 keys:
sharing globally and per host, the keep-warm minutes, and an
ask-before-reuse switch that is off by default.

New local IPC verbs (`MachineConnections`, `CloseConnection`,
`KeepConnectionOpen`, `StopConnectionRedial`) and one additive field on
the published `ConnectionEntry` (`pane_opens`: what each pane's own open
cost and how long ago it was). No `PROTOCOL_VERSION` bump;
termuna-mobile's `tsp_vectors.json` should be regenerated, since
`connections_plain` and `connections_sealed` now carry that field.
### Fixed: one control height in the continuity panel

Board#291. In the SHARE block, `Copy view link` (with its caret) and
`Scan with phone` sit stacked and read as one pair, and they were not
the same height: each button set its own padding and its own font size
instead of taking a shared height, so the top control landed about 3px
shorter than the one under it and the caret was padded independently of
the segment it was joined to.

The height is a token now, stated once. `ui::CTL_H` (28px) and
`ui::CTL_PX` (11px) are applied inside `ui::btn` and `ui::btn_icon`, so
no call site passes a vertical padding any more and no change of font
size can move a button off its neighbour; `ui::CTL_H_SM` (20px) and
`ui::CTL_PX_SM` (7px) are the same pair for a control that lives inside
a list row (a link's Stop, a device row's open), which is a difference
of kind rather than the accidental difference of degree. 28px is what
`btn_icon` already drew, so most of the app does not move.

The split button is one control rather than two segments that happen to
touch: the wrapper owns the border, the radius and the height, the
divider is a full-bleed 1px rule instead of a 22px spacer, and the
caret is a fixed 26px square with no padding of its own. The two halves
still light separately, because they still do different things, but the
border reacts as one, which is what says they are one control. Both
SHARE controls take the panel's full width, so the pair has one right
edge. Every other button in the continuity panel that set its own
padding takes the tokens too. Nothing here changes what any control
does.

That shared border is only honest while the hover behind it is: a
control that leaves the screen never sends its exit event, so putting
the panel down with the pointer on the split used to leave the wrapper
lit, and the border was still lit the next time the panel came up. The
hover is forgotten wherever the panel actually leaves the screen (the
one setter every dismissal goes through, and the wide layout's pin),
rather than at each of the ways out.

### Added: pick mode's three actions, discovery and the default action key

Board#273, part 3 of 5 of the pick-any-token-with-the-keyboard epic
(board#266). Landing on a match now does something: `enter`, or the
label press that resolved the match ("enter or just the label"),
copies, `shift+enter` inserts at the prompt and never sends Enter,
`ctrl+enter` opens through the existing link opener where opening
means something (lit for a URL, for `path:line` only once an editor is
configured, greyed with the reason stated otherwise), and an uppercase
label press copies and inserts in one move without changing the
configured default. The action strip is present for the whole life of
pick mode: the three chips with their bindings from the moment it
opens, and once a candidate resolves it additionally states the
matched kind and the exact value before any of this happens, so
nothing is copied blind. Whichever action a bare label or a bare
`enter` would actually commit is what the enter chip's own
availability reflects, greyed with the same stated reason as
`ctrl+enter` when it is not (an armed "Pick and open a link" on a
candidate that never opens, among others). `enter`'s copy is routed
through the same clipboard lane a program's OSC 52 write already uses
(board#214 to #217), so it lands wherever the person is actually
looking. A resolved candidate can also be saved as a snippet with
`ctrl+shift+s`, no mouse selection needed. New config key `[terminal]
pick_default_action` (`"copy"` or `"insert"`, default `"copy"`) chooses
what a bare label press, or a bare `enter`, commits to. Three ctrl+k
entries, beside "Find in this pane", open pick mode already aimed at
an action: `Pick a token on screen`, `Pick and open a link`, `Pick into
the prompt`. The `code` CLI probe behind `ctrl+enter`'s eligibility
runs once, off the UI thread, at launch: opening pick mode never forks
a process, and the enter and ctrl+enter chips read "checking editor..."
in the unlikely case a `path:line` resolves before that probe has
answered.
### Changed: one overlay presenter for every modal (board#292)

Ctrl+K and Ctrl+R opened 80px from the window's top edge and appeared
on the frame they were asked for; every other modal opened dead
centre and rose into place over 150ms with a lift and a scale, so the
two presentations in one app made the slower one feel broken. Nothing
interrupts typing is a hard product rule, and a modal that has to
settle before it takes input breaks it.

`ui::overlay` is now the one function that owns an overlay's scrim,
anchor and dismissal: `OVERLAY_TOP` (80px), `OVERLAY_SCRIM` (0.5) and
`OVERLAY_FADE` (70ms) in `ui.rs` are the only source of that geometry.
`ui::modal` composes over it and keeps its head/actions grammar, but
states no position, lift or scale of its own; `view_palette` and
`view_recall` in `shell.rs` drop their own hand-rolled scrim and
`padding([80, 0])` for the same call. Every modal in the app (forms,
confirmations, share and export dialogs, pickers, the chat rewind
card) now opens at the palette's own anchor with the same scrim and
the same instant arrival: opacity only, over 70ms, symmetric on the
way out. Nothing translates or scales, so the card is at its final
position and size on the first frame and takes input from that frame
regardless of the fade. On a window too short for the anchor the card
slides up to keep an 18px bottom margin; it never re-centres. The
card's own drop shadow now fades in step with the scrim too, rather
than sitting at full opacity over a page that has not dimmed yet.

`docs/design/termuna-ui-v6.html`'s `.keyscrim` cards move to the same
anchor and dim, verified by rendering the page.

### Added: pick mode on screen, the labels and the typed prefix

Board#272, part 2 of 5 of the pick-any-token-with-the-keyboard epic
(board#266). Part 1 decided which tokens are worth copying; this is the
part you can see and use.

`ctrl+shift+space` opens pick mode on the focused pane and every match
on the screen gets a letter. The letters sit in the cells before each
token, never over it, in the same mint the find bar uses, so the output
you are reading stays readable while you aim at it. Nine or fewer
tokens take one letter each off the home row; past nine every token
takes two, and the letters are handed out nearest the cursor first, so
the path that just printed is the shortest thing to type. The line
under the cursor keeps its own mnemonic beside them.

Typing narrows instead of redrawing: each letter dims what it excludes
and leaves the rest exactly where it was, backspace walks the prefix
back, and a complete prefix resolves to one token. Tab cycles the kind
chips, which are a filter and not a mode chosen up front, and the
status bar counts what survives it, `pick s 3 of 14 still reachable`.
When nothing matches, the bar says so in words and offers the whole
line under the cursor, tab to widen and esc to leave, rather than
flashing and closing.

Two calm rules hold. Output arriving while the overlay is open is held
and drawn when it closes, so the grid never reflows under a label you
are aiming at, and the pane is not stopped to achieve it. Escape leaves
the pane exactly as it was: no selection, no leftover mode, nothing to
undo.

Picking a token closes the overlay and, for now, does nothing else: the
three actions (copy, insert at the prompt, open) are part 3, behind a
single call site. `[terminal] pick_key` overrides the binding.
`docs/design/termuna-ui-v6.html` gains the pick bar and the label
styles.

### Added: pick mode, the matcher and the request

Board#271, part 1 of 5 of the pick-any-token-with-the-keyboard epic
(board#266). Nothing a user can see yet: the pure half and the wire.

Copying a path or a URL off a pane needs a pointer drag. Pick mode will
label every interesting token on the screen so the keyboard alone can
choose one; this part is the matcher that says which tokens, and the
request that hands the list to any client. `termuna_mux::pick` reads a
pane's visible grid and answers one entry per match with its cells, its
kind and the exact text that leaves the pane: URL, absolute path,
relative path, `path:line`, git hash, IP address, quoted string, and
the whole line under the cursor, which is the one match that cannot
fail. Overlaps resolve by specificity (`path:line` over the bare path
under it, a URL over the quoted string around it), so no two matches
share a cell, and a line the pane wrapped is one match whose value has
no wrap artefact in it.

`[terminal] pick_patterns` takes your own regexes, run in the same pass
and labelled the same way. A pattern that does not compile is a named
error at load, with its row and the compiler's own sentence, never a
panic and never a pattern quietly dropped.

The daemon answers `PickMatches{session, pane, patterns}` on the sealed
query lane and over local IPC, so a phone or the dashboard can pick
from the same list; additive, no protocol version bump, old hosts and
clients unaffected.
### Added: one shared SSH connection per host, part 1 of 4 (engine only)

Board#276, part 1 of the "one shared SSH connection per host" epic
(board#267). Every SSH pane and every SFTP browse used to dial its own
TCP connection and its own handshake, so a split on a remote host cost
a second full handshake and, with 2FA, a second prompt. The daemon now
owns one connection registry, keyed on the resolved target: user, host,
port, jump chain, and the identity actually used, so two panes that
authenticate differently are always two different connections, never
folded into one. A pane or the file lane asks the registry for the
connection and opens a channel inside it; the second pane on a host
already connected costs a channel open, not a handshake.

Consumers are refcounted, and reaching zero starts a linger (our
ControlPersist) rather than closing at once; any new consumer inside
the window cancels it and reuses the connection. This is the one timer
the feature needed, and it replaced two: the file lane's own fixed
120 second idle reap is gone, folded into the same configured linger a
pane's connection uses. `[ssh] share_connections` (on by default) and
`connection_linger` (`"5m"` by default, `"0"` closes with the last
consumer, `"30s"`/`"1h"`/a bare number of seconds all read too) are the
registry's own settings, with `[ssh.host."<name>"] share_connections =
false` as a per-host override for a server that behaves badly; reading
them out of `config.toml` at daemon start, the way `[ssh] redial`
already is, is the connective piece still to land.

A server that refuses a second channel (`MaxSessions 1`), or a shared
connection that has quietly died, falls back to a fresh connection of
its own with the server's own reason kept, never a silent hang; a
refusal is remembered for the rest of the process so such a host is
not probed again on every split, while a dead connection is simply
retried, since a network blink is not the same fact as a server saying
no. A target that declares port forwards or agent forwarding always
gets its own connection in this part: both are requested per channel
and the existing forward registry (board#232) is wired to one pane's
channel as the connection's carrier, so sharing them correctly is
follow-up work.

This part is the engine and the wire type only: no UI, and
`docs/design/termuna-ui-v6.html` does not move. `Payload::Connections`
carries what the registry holds for a session's panes and file lane
(target, identity, state, channel count, named consumers, the linger
countdown), additive with no `PROTOCOL_VERSION` bump, ready for the
panel and the inspector that read it in parts 2 to 4.

### Added: one shared SSH connection per host, part 2 of 4 (failure and redial)

Board#276, part 2 of the "one shared SSH connection per host" epic
(board#267). Failure and redial move up from the pane to the
connection: a shared connection's death used to cost one redial per
pane on it, so eight panes on a host that blinked meant eight
handshakes and, on a hardware key, eight touches. Now every pane, the
file lane and every port forward carried on the connection are marked
lost in the same moment, and exactly one redial runs for however many
there were: whichever consumer notices first claims it, every other
consumer's own notice folds into the same outage, and a new consumer
(a split into a host that is already being dialled again) joins it too
rather than racing a second dial of its own. The schedule is the
pane-level redial's own (`crate::redial::backoff_secs`: 1s, 2s, 4s, 8s,
then 15s), shared rather than duplicated, so the two read as one
system.

On success, every pane gets a fresh channel through the ordinary
attach path, which is also what restarts whichever forwards it
carried; the connection's own consumer count and named list (`pane
<id>`, `files <id>`, and now `forward <id>`) are simply the ordinary
answer again, current rather than stale, so "who came back" is read off
the same `Connections` state a client already polls rather than a
separate one-shot summary. Exhausted attempts, or a host presenting a
different key, leave every consumer with the exact same named reason:
never one pane inventing its own sentence for a connection eight panes
shared. An unshared (`Own`) connection is untouched, keeping exactly
today's per-pane redial.

Port forwards (board#232) move to the connection too: a target that
declares one is no longer forced onto its own dedicated connection
(only agent forwarding still is), `termuna_ssh::shared::
SharedConnection` runs its own `Forwards` for the connection's whole
life instead of a channel's, and a running rule holds a place among
the connection's consumers for as long as it is `Binding` or
`Listening`, named and reported exactly like a pane. **Known limit**:
that place is kept in step at the points that already touch a
session's forwards (a pane attaching, a redial's own reattach, a
person's start/stop/add/remove) rather than the instant a pane's link
drops; a forward briefly uncountable mid-outage is corrected at the
next of those, never left double-counted or dangling. The file lane is
the other known limit: it is not dialled by the redial itself, and
reconnects lazily on its own next use once the registry stops refusing
a fresh dial for the key, so it can be briefly missing from a fresh
connection's consumer list until it is actually asked for something
again.

`ConnectionEntry` gains one field, `redial: Option<RedialProgress>`
(`{attempt, max, next_in_secs}`), set only while `state` is
`Redialing`, so a viewer counts down the same way a pane's own
`Reconnecting` state already lets it. Additive, no `PROTOCOL_VERSION`
bump. No UI in this part either; `docs/design/termuna-ui-v6.html` does
not move.

### Added: the drawer, the tab and the toast say which kind

Board#251, part 4 of 5 of the name-the-attention-kind epic (board#178).
Parts 1 and 2 put the kind on the wire and had the daemon classify it;
this is the window reading it.

A session raising its hand now carries a word on the drawer's existing
metadata line, where "termuna-srv-1, 2 panes" already lives: "finished"
in mint, "failed, exit 1" in warn, "needs input" and "approval" in the
attention amber, and a plain grey "attention" for a bare bell this
build cannot name. The row keeps its shape, the state icon keeps its
colour and nothing shifts: the only new pixels are the word itself.

A tab strip has no room for a word, so a background tab's dot takes the
kind's colour instead of the one danger tone it had before. A bare bell
and plain activity look exactly as they did.

The desktop toast gains the kind under the session name: "deploy", then
"failed, exit 1". No command line, no output, no invented message text,
on any surface.

Muting governs waking, never the list. Turning notifications off
silences the toast and leaves the drawer word and the tab dot exactly
where they were, so a muted session is still visible to anyone who
looks.

### Added: the pane says where it is, and the paste guard

Board#245, part 2 of 4 of the environment epic (board#177). Part 1 added
the field; this reads it.

A pane whose session is on a host with an environment wears three quiet
marks: a 2px hairline on the pane's own left edge, a lowercase
environment word in the corner (the same register the redial tag
already uses, faded to 55% opacity while the pane is unfocused), and
the tab's selected underline in the environment's colour instead of
mint. The terminal background never changes, and none of this is a
byte in the buffer: scrollback, search, export and the mirror are
exactly what they were. A host with no environment shows nothing, not
even a grey chip.

When a host's `guard_paste` is on, pasting or dropping more than one
line into that pane's session stops and asks first: how many lines and
characters, the host's name, and the first four lines faded and never
editable. Send delivers the block; Cancel and Escape drop it; Enter is
bound to Cancel, not Send, unlike every other card in this app.
"Do not ask for this host" turns `guard_paste` off on the host record
itself and says so in the pane. A single line, however it is typed or
pasted, and any hand-typed heredoc, never asks: the guard counts lines
and names the host, and that is the entire decision procedure, nothing
in the per-keystroke path.

### Added: the line where you left off

Board#254, part 2 of 4 of the per-device read line epic (board#165).
Part 1 taught the daemon where each device stopped reading and nothing
showed it, so coming back to a session still meant reading from the
bottom. The desktop window draws it now.

Reattaching a session this machine read before draws one quiet mint
rule over the grid at the first row you had not seen, with its label,
"new since 14:02, 320 lines", and an x. It is chrome, never content:
it is painted over the pane at the row, it never enters the scrollback
or the mirror, it is not in a selection or a copy, and no timer removes
it. Scrolling down past a line you have looked at, or the x, are the
two ways it goes, both yours. A pill in the corner where scrollback
search lives, "go to where I left off", jumps to it a third of the way
down the screen; so do `ctrl+shift+j` and the same row in the ctrl+k
palette. On a session with no previous read there is no rule, no pill
and no row: silence, never a guessed line, and the shortcut reaches
the shell as it always did.

A tab you are not looking at carries "320 unread" in the amber's quiet
register once this machine has read it: a number and a word, cleared
when the tab comes on screen, never animated, and ranked below a real
attention state, which keeps the slot. A tab never read says nothing.

The continuity panel gains "while you were away" under the device
rows: the commands this session ran since you left, read from the
sealed command history that already carries the exit status, a
non-zero exit in warn red and "open the failing one" jumping the pane
to that command's mark. A quiet session says "Nothing ran. The session
was quiet the whole time."; history switched off names the setting and
links to it; a first read draws no heading at all. `clear` stands the
lines down for this attach.

The window reports where it has read to, per pane, only while it is
focused and the grid is on screen, two seconds after the last scroll
or burst of output and at once when focus leaves or the window walks
into another session. A row is read once it has been on screen, and
never unread by scrolling back. Positions stay on this machine: the
account-wide sync and the phone are parts 3 and 4, so the label never
names another device yet.

Known limits: the sessions drawer shows no count for a session this
window is not attached to, because only the attach carries the
position; `clear` hides the section for this attach rather than
dropping the daemon's stored position, which part 1 has no verb for;
and a pane that has printed more than the window's scrollback without
ever running a command has no marks to place its rows by, so its line
is not drawn rather than drawn wrong.

### Added: the daemon knows where you stopped reading

Board#253, part 1 of 4 of the per-device read line epic (board#165). No
visible change yet: the daemon now learns where each device last read a
session, per pane, stamps the position when the viewer leaves and writes it
to disk at that moment (a report that arrives while somebody scrolls costs
no write), keeps it across restarts like the rest of the session state, and
tells a device's own next attach where it stopped. The line itself is drawn
by parts 2 to 4.
### Added: watch without resizing

Board#257, part 1 of 3 of the watch-without-resizing epic. When a
smaller window wins the grid under the existing smallest-wins rule, the
windows that could have shown more now say so: a mirror window can
switch to watch-only (the window menu's "watch only", remembered per
session per device), which stops proposing a size and renders the
authoritative grid letterboxed while typing still works; the window
under a cap shows one calm amber line naming the side that holds the
grid and both sizes, with "use my size" where the verb can reach the
capper; and the reclaim floors the capping viewer at its own size
instead of kicking it, undoable from the viewer row's context menu.
The cap line's comings and goings ("pixel 8 left, size restored") are
stated once in the status bar's grey counter register.
### Added: the attention kind is on the wire

Board#248, part 1 of 5 of the name-the-attention-kind epic (board#178).

The `Attention` control frame (and its retraction, `AttentionOver`)
gains an additive `AttentionKind`: `finished`, `failed` with the real
exit code, `needs_input`, `agent_approval`, and `unknown` for a bare
bell. The field is serde-defaulted and omitted from the bytes when it
is `unknown`, so hosts that do not classify emit byte-identical frames
to before, old bytes decode exactly as they always did, and an unknown
future kind name degrades to `unknown` instead of failing the frame. A
pane id, a kind name and an exit number are metadata of the same weight
as the pane ids already in the clear, so the E2E boundary does not
move. No host classifies yet: the daemon still emits `unknown`
everywhere, and parts 2 to 5 fill it in. docs/PROTOCOL.md documents the
vocabulary, the default and the mapping rule.

### Added: the daemon classifies why a pane wants you

Board#249, part 2 of 5 of the name-the-attention-kind epic (board#178).
Part 1 put the kind on the wire and left every host emitting
`unknown`. The daemon fills it in now, at the three places attention
is raised. An agent's permission ask is always `agent_approval`. A
pane's bell or OSC 9 notification reads the same chunk's line tracker
events: an unanswered agent ask on that pane still wins first, then
the last exit status the tracker heard (`failed` with the real code
for a non-zero one, `finished` for a zero code or for a shell that
reported a finish with no code at all), then `needs_input` when the
tracker can tell a command is still running (submitted, no finish
heard since) while the pane rang anyway, and `unknown` for a bare bell
with none of that evidence. `AttentionOver` now carries the same kind
it clears: the daemon keeps the raised kind beside the attention
stamp instead of re-deriving it at clear time, when the tracker may
already have moved on. Classification is a pure function,
`termuna-mux::attention::classify`, table-tested for every mapping and
the ordering case where an agent ask outranks a failing exit noted in
the same chunk. No protocol change, no UI change: parts 3 to 5 carry
this to the desktop, web and phone.

### Added: the environment lives on the host record

Board#244, part 1 of 4 of the environment epic (board#177). The
foundation half: the field, its editor and its import path. No pane
chrome yet, that is part 2.

`termuna_vault::Profile` carries an `environment`: one of `Dev`,
`Staging`, `Production` (serde externally tagged, the form the phone and
the dashboard parse), or a custom word (max 10 characters) with a swatch
from the six-colour environment palette the design and the phone offer.
The host editor gains the field, and a per-host "Ask before sending a
pasted block" checkbox, off by default. The ssh config importer reads
`#termuna: env=<word> [guard]` comments: presets map directly, any
other word becomes a custom environment with a deterministic swatch,
and `guard` arms the checkbox. For linked hosts the comment wins and
the editor shows the field read only, guard state included; a termuna
comment trailing on the `Host` line itself marks nothing. Older vaults
load unmarked.
### Added: every forward on this machine, in one sheet

Board#235, part 4 of 4 of the live-port-forwards epic (board#164). Parts
1 to 3 gave the rules states, the panel a per-session list and the palette
a composer; this closes the set: the machine-wide list, reached from
ctrl+k ("Show all forwards on this machine", its meta the machine's own
rule count), shows every live forward on this machine grouped by session,
each group named by its session and the host its shells run on.

One row per rule in the panel's own shape: the direction, the address as
it is bound (a remote rule the server moved elsewhere says "asked 9000"),
the state as a word (binding, listening with the open-connection count,
refused with its reason, stopped), and the action that state allows:
Stop while it is up, Start or Retry when it is not, Remove for an ad-hoc
rule only, because a profile rule would come straight back on the next
dial. Every verb is the daemon's own, so nothing reconnects, and the
sheet re-asks the machine while it shows, so a rule started from the
panel, the palette or a pane is already true here.

An empty machine says the plain sentence instead of a blank box, and a
session that ends takes its group with it. The card is drawn in the
drawer's language, an overlay and never a modal: it steals no focus and
eats no keystroke, and a click outside it closes it.

### Changed: the session log records when each frame arrived

Board#260, part 1 of 3 of export-pane-as-cast (board#237). Every
retained output frame now carries the millisecond the daemon
sequenced it, in memory and in the persisted `<id>.log`, which is
what a cast's timing will be built from. The file gains a short
header marking the timed format; a log the previous release wrote
still loads in full, with no times (never guessed ones), and a
downgraded daemon reads a timed log as empty rather than misreading
it. The asciicast v2 encoder lands with it as a pure module and
nothing reaches it yet: the export card and the file are parts 2 and 3.

### Added: export a pane as an asciicast, from the context menu

Board#237, part 2 of 3. Part 1 taught the session log the clock and
built the pure asciicast v2 encoder with no entry point; this part
gives it one, the pane context menu's file section: "export this pane
as cast", rebuilt from the pane's own persisted output log after the
fact. No recording to start, nothing uploaded. A pane whose log holds
no frames yet says so in place of the shortcut, the same
disabled-with-a-reason pattern "copy" wears with nothing selected.

The card reuses the export archive's own frame (board#14): a scope
choice, this pane or the whole session (one file per pane, the names
disambiguated when two panes share a title), the log's own facts
stated as facts, frame count, span, command marks and idle gaps
compressed over 3 seconds, the quiet gate's own threshold, a markers
toggle on by default (one asciicast marker per command, at its output
start), the destination in the downloads folder with a folder picker
to change it, and the local-only sentence said once, where the
decision is made: nothing leaves the machine, there is no upload step
and no account involved. A log with part of it predating persistence
wears an amber note and still writes the cast, starting where the
timed log does. A write that fails wears the red band, names the
path, and leaves nothing partial behind for the whole export, not
just the file that failed. A running export is one quiet status bar
fact, never a progress modal, and the done card states the file, its
size, its frame count and both runtimes, real and compressed, the
numbers matching what actually landed on disk. Ctrl+K and the hand-off
into the export archive are part 3.

### Added: export a pane as an asciicast, ctrl+k and the archive hand-off

Board#262, part 3 of 3. Two more doors into the same card, sharing one
entry rule with the context menu row: which pane it opens on, and
whether the whole session is preselected, or the reason it is not
offered. Ctrl+K gains "Export this pane as cast" directly above
"Export your data", found by typing "cast", "asciicast" or "export";
a pane with no focused pane or nothing in its log stays as a dimmed
row naming the reason, the palette's own version of the context menu's
disabled state, rather than vanishing. The "Export your data" archive
card gains one quiet line under its scope fact, "Replay a session
instead? Export the whole session as an asciicast", present only when
the same entry rule allows it; taking it dismisses the archive card
and opens the cast card with the whole session preselected, since only
one modal shows at a time.

### Added: the window says who is typing

Board#224, part 2 of 5 of the one-keyboard epic (board#209), ADR 0019.
Part 1 built the rule and nothing showed it, so a shared session
arbitrated the keyboard silently. The desktop window says it now, in
words first and colour second.

The continuity panel has a keyboard block, under sharing, present on
any mirrored session: one named holder ("you, this window, since
14:02", or "maja, since 14:19"), the shortcut stated while there is
nothing to take back, and a Take it back button when there is. Mint
when the keyboard is here, amber when it is not, and both states say
the name, so the ink only reinforces what the words already carry. In
the share list an input link spends its one word on `watching` or
`typing`, and only one row in the list can ever say the second.

A guest asking for the keyboard raises a calm card in the panel, with
Give and Decline, and the same ask is echoed once into the focused
pane as ordinary buffer content on its own lines. Nothing floats over
the grid, nothing takes the focus and no keystroke is eaten: the shell
stays typeable through the whole exchange. Typing while somebody else
holds the keyboard prints one honest sentence in the pane, "Your
keystrokes were not sent", once per handover; after that an amber row
above the grid is the reminder, and that row costs zero pixels while
the keyboard is yours.

Take it back from the row, from the panel block or with `ctrl+shift+k`:
one action, immediate, no confirmation, and it stops no share link.

The row's two edges resize the grid under it, so a handover hands its
line to the shell at once rather than at the next unrelated layout.
And a session mirrored from another machine names the holder and
offers nothing to press: the take-back is the owning machine's, so
neither the button nor the shortcut is claimed here and `ctrl+shift+k`
reaches the shell as it always did.

Settings, Terminal grows a keyboard block with the three `[sharing]`
switches part 1 added: whether people on input links may ask, how long
a quiet holder keeps it before it comes home (default 5 minutes, `off`
allowed), and whether handovers are marked in the scrollback. All
three travel with your account and reach the running daemon at once,
so turning the asks off stands a guest down now rather than at the
next restart.

No protocol change. The cloud dashboard and the phone are parts 3 to 5.
### Added: forward a port from Ctrl+K, on a running session

Board#234, part 3 of 4 of the live-port-forwards epic (board#164), design
v1 exhibit d. Port forwarding was configured only in the host form before
connecting; changing one on a running session meant editing the profile
and reconnecting. Ctrl+K now offers "Forward a port": the palette's own
card takes one line in the host form's grammar (`L 8080:host:80`,
`D 1080`, `R 9000:localhost:3000`), parsed by the vault's one parser as
it is typed, so the rule is explained in words ("local - 127.0.0.1:5433
reaches db-int:5432 through this session") before Enter starts it on the
focused session, with no reconnect. A line that does not parse keeps its
text, names what is wrong in warn ink, and Enter waits; nothing is a
modal or a toast. "Keep on this host" (off by default, Tab toggles)
writes the rule into the vault profile's FORWARDS field, never
duplicating a rule the profile already carries; off, the rule dies with
the session. The composer also accepts a pre-filled rule, which is where
the panel's "Use another port" lands its refused forward.

### Added: one keyboard per shared session, passed explicitly (engine)

Board#223, part 1 of 5 of the one-keyboard epic (board#209), ADR 0019.
Two people holding a typing link into the same session both reached the
shell, and it saw one interleaved stream: a half-finished command from
each and a prompt that ran something neither of them meant. There is
one writer per session now.

Your own devices hold the keyboard by default, so a session you have
not shared is unchanged in every respect. When you give it away, a
guest can ask, you give or decline, and you take it back at any moment,
immediately and without asking them: they keep watching and their link
is untouched. Everyone who is not the holder has their keystrokes
dropped at the daemon, never queued and never delivered late, and is
told once per handover who has it instead of losing keys in silence. A
view-only link can neither hold the keyboard nor ask for it.

A handover writes one dim rule line into the pane's own scrollback,
"keyboard to maja 14:19" and "keyboard back to you 14:24", so reading
the transcript a week later says which side ran a command. A label and
a time, never any content.

Three settings under a new `[sharing]` block in `config.toml`, all of
which travel with your account: `keyboard_asks` (default on; off means
nobody but your own devices can hold the keyboard and no ask ever
reaches you), `keyboard_idle_return` (default 300 seconds, `0` for off:
a guest who types nothing for that long hands the keyboard back, and
your own devices never do) and `keyboard_seams` (default on: the rule
line above).

This part is the engine only: no desktop chrome yet, and the cloud
dashboard and phone follow in later parts. The protocol frames are
additive and `PROTOCOL_VERSION` does not move.
### Added: the forwards a session is holding, in the panel

Board#233, part 2 of 4 of the live port forwards epic (board#164). Part
1 gave a forward a state; this is the window's half of it, so the state
is somewhere a person can see and act on.

The continuity panel has a forwards section now, under sharing, because
both answer the same question: what is this session holding open, and
how do I take it back. One row per rule, in the same two-line shape a
share link takes: the OpenSSH letter (L, D, R), the address the rule
actually bound, and the one action that state offers, over a quiet mono
line of facts.

    L 127.0.0.1:5432                              Stop
    to db-int:5432 · listening

    D 127.0.0.1:1080                              Stop
    socks5 · listening · 3 open

    R staging-box:9001                            Stop
    from staging · listening · asked 9000

    L 127.0.0.1:8080                             Retry
    refused · address in use

The state is a word: listening, binding, refused, stopped. Colour only
reinforces it, so the row is legible with the colour taken away, and
nothing spins or glows for a rule that takes 300ms to bind. Stop is
offered while a rule is up or coming up, Start when you stopped it
yourself, and Retry when it never came up, because "stop" is
meaningless for something that never listened. All three act on the
running session with no reconnect and the row moves as soon as the
daemon answers. "Stop all forwards" mirrors "Stop all sharing" and is
offered only while there is something for it to stop.

A remote rule the server put on a different port says which port it
asked for ("listening · asked 9000"), so the address on screen is the
one something can actually reach.

A session with an SSH connection and no forwards gets a sentence rather
than a blank box: what a forward is, and that it stays up while the
laptop is closed, because the tunnel lives in the daemon. A local
session has no forwards section at all.

A bind refusal now also gets a card at the foot of the pane, under the
one seam line part 1 already writes into the scrollback, in the same
card language as the reconnect card: what could not bind, the rule in
full, and Retry, Stop this forward or Dismiss. It takes room of its own
instead of covering the scrollback, it never takes the keyboard, and
Esc takes it down without swallowing the key, leaving the panel row and
the seam line as the record. "Use another port" arrives with the Ctrl+K composer
in part 3, so it is absent here rather than shipping a button with
nowhere to go.

No protocol change: the window reads the frames part 1 already
publishes.

### Added: a port forward is a thing with a state, not a string

Board#232, part 1 of 4 of the live port forwards epic (board#164). This
part is the engine: there is no new UI yet, and the panel, the palette
and the machine-wide sheet come with parts 2 to 4.

Until now a port forward was a line in a host's FORWARDS field, parsed
once when the session connected. If it came up, nothing said so. If it
did not, because something else already held the port, because the port
was under 1024, or because the far side would not listen, the app wrote
a log line nobody reads and carried on showing a healthy pane in front
of a dead tunnel. There was no way to stop a forward, start one, or add
one without reconnecting the whole session.

Every forward of a session now has an id that lasts as long as the
session, where it came from, and a state that is a word: binding,
listening, refused or stopped. A listening rule reports the address it
actually got, which matters for a remote rule the server bound
somewhere other than where it was asked to, and a refused one carries a
named reason: address in use, permission denied, the server would not
listen, the address could not be resolved, or the words the operating
system used when it was none of those.

A rule that cannot bind now says so in the pane it belongs to, once, on
one line, in the same language the reconnect seam already writes:

    14:02:44 · 1 forward refused · L 8080:app-int:80 · address in use

It is written into the pane's own scrollback, so it scrolls with the
history, is still there tomorrow, and reaches the web viewer and the
phone. It is not a toast, not a dialog, and it never touches the
keyboard: the shell above and below it keeps working. Retrying and
getting the same answer says nothing more; a retry a person asked for
is always answered.

Forwards can be started, stopped and retried on a running session, with
no reconnect anywhere, and a rule can be added to a session that is
already up in exactly the syntax the host form takes ("L
8080:app-int:80"). Stopping one closes its listener, releases the port
and drops the connections through it; starting it again listens.
Pressing start twice cannot produce two listeners, and stopping a rule
while it is still coming up leaves it stopped rather than briefly
alive. A dropped link that reconnects brings back exactly the rules the
session was holding, under the same ids, ad-hoc ones included, and
leaves alone the ones a person had stopped. The reconnect line's count
("2 forwards restored") is now taken from those rules rather than from
the saved profile, so the sentence and the list cannot disagree.

Two long-standing quirks go with this. A second tab on a forwarding
host used to try to bind the same ports all over again and fail; a
session has one set of forwards now, however many tabs are open on it.
And a session that ends, or a pane that is closed, no longer leaves a
port held.

### Added: this machine stays reachable with nothing running

Board#219, part 2 of 5 of the account-level daemon channel epic
(board#151). A signed-in machine used to appear on your phone and in
the dashboard only while it happened to be holding a session open, so
a laptop you had just closed a window on, or a server that had never
been given anything to run, was simply not there. It is there now: the
daemon holds one lightweight connection to Termuna Cloud of its own,
separate from any session, and a machine holding that connection can be
asked to start one.

The account screen gains a single row, "Stay reachable with nothing
running", with a state line under it: "connected 4h 12m" and the
machine's own name while the connection is held,
"reconnecting, last connected 40s ago" while it is coming back. The
switch is per machine, never synced to your account, and takes effect
on the running daemon straight away rather than at the next restart.
There is no "wake it up" button, here or anywhere: a closed laptop
cannot be woken, and a button that usually fails is worse than none.

What Termuna Cloud learns from the channel is stated in the row: that
this machine is signed in and awake, which it already learns the moment
you open a session, and nothing else. No directory, no command, no
output. The channel carries the same sealed payloads your sessions do.

Reaching a machine with nothing running is part of a paid plan. A free
or signed-out account gets the row too, stating the plan once, and the
app behaves exactly as it does today: machines show up while they have
a live session. Nothing nags, and nothing retries in a loop behind the
scenes.

Two things a person would otherwise have to notice for themselves are
fixed with it. Signing out closes the channel at once instead of
leaving it retrying against a token the relay no longer honours, and
signing back in leaves one connection rather than two. And a machine
that answers a request by refusing it now says so in its own words
("vault locked on workstation") rather than behind a generic error.

### Added: the window says where a copy went, and can send one on purpose

Board#215, part 2 of 4 of the clipboard-follows-the-viewer epic
(board#129), ADR 0018. Part 1 shipped the engine: the daemon reads
OSC 52 off a pane's own bytes and routes the text to the viewer being
used. Nothing said so. Now the window does.

A copy that lands on this machine still prints nothing at all: the
expected thing needs no words. A copy that went anywhere else prints
exactly one gold line at the foot of the pane, naming the destination
and, after it, how long that device has been attached and how many
bytes moved. The line is chrome over the grid, not a row in the
buffer: no row is taken from the shell, nothing takes focus, and it
goes by itself after ten seconds. Never a toast, never a modal.

Right-click on a selection gains a "copy to" section listing the
devices genuinely attached, "this machine" first. Picking one is
explicit, one-shot and bypasses the routing rule; a device that
dropped off since the menu opened takes nothing and the pane says so,
rather than the text landing somewhere nobody chose. With nothing else
attached the section stays and reads "no other device is attached",
disabled rather than hidden. The window names a remote device "your
other device", with "web or phone" as the quiet fact after it: the
relay merges every remote viewer into one stream, so the daemon has no
device name to give and this window will not invent one.

The three refusals are said in the pane's own words too. A host asking
to read the clipboard is refused as it always was, and now reads
"<host> asked to read your clipboard. Refused, as always.", in warn
red, once per session rather than once per attempt. A host on the
do-not-copy list says so and where to change it. A destination that
disappeared mid-flight says "your other device dropped off, so it
landed here" and names this machine. The remaining reasons (the global
switch off, a sequence too large, a payload that is not base64) each
get a sentence of their own.

Settings, Terminal grows three rows in the clipboard block: "Clipboard
follows the focused viewer" (the syncable preference, told to the
running daemon on change), "Where the last copy went" (the destination
and the time, tagged "this machine"; nothing about the text is
recorded and nothing is written to disk), and "Hosts that may not copy
at all", a live count of vault hosts on the do-not-copy list with a
route into the host editor.

The vault host editor grows the per-host block from the design:
"Programs on this host may set the clipboard" and "Always land copies
on this machine", both persisted on the host item, so they travel with
the host and survive a restart. Every host row in the connections
screen now carries one quiet mono fact line saying which of the three
it is.

Local IPC only: `SessionViewers` answers the seats the router would
choose among, `CopyToViewer` addresses one of them, and
`ClipboardRouted` is the host-to-window frame that carries where a
copy went (a size and a host label, never a byte of the text; the
bridge drops it). No `PROTOCOL_VERSION` bump, no relay change. Web and
phone are parts 3 and 4.

### Added: an SSH certificate is a credential Termuna can use, and say the truth about

Board#150. An organisation that runs a CA hands its people a
certificate that expires every working day, and Termuna could not
connect with one, or say why. The agent identity loop walked past
every identity that was not a bare public key, with a comment
saying certificates were handled elsewhere; there was no elsewhere.
A `step`, `vault` or 1Password agent holding exactly one credential,
a certificate, read as an agent holding nothing usable, and the user
got the generic refusal on a machine where `ssh` connects fine.

Certificates are offered now. `termuna-ssh::cert` is the pure half:
it reads the OpenSSH certificate blob the agent already hands us
(`ssh-rsa`, `ssh-ed25519`, `ecdsa-sha2-*` and the `sk-` pair, all
`-cert-v01@openssh.com`) into key id, principals, validity window,
cert type and the signing key's fingerprint. Every read is bounds
checked and every failure is a named error, so a truncated or
garbage blob is stated and fallen through past rather than silently
counting as nothing. `agent::offer_plan` is the order: a usable
certificate goes first, because it is the credential the CA issued
for this login, bare keys follow in agent order exactly as they did,
and a certificate outside its validity window is listed and skipped.
The host card's Test lists them with key id, principals, how long
they have left and the order they will be offered in.

Expiry is a sentence, not a failure code. Two named refusals join
the agent failure's existing four: a certificate whose window has
closed says "your certificate expired 2 hours 14 minutes ago" with
the renewal command, and only when the agent socket names the tool
(`step`, `vault`, `op`); nothing names it, no command is printed. A
certificate whose principals cannot cover the user this host
connects as says "this certificate cannot log in as root" with the
principals it does carry. Both are decided locally out of the blob,
so they need no round trip. The principals case is still offered to
the server, because a server may map principals to login names of
its own with `AuthorizedPrincipalsFile` and refusing here would
break a setup `ssh` serves.

`CertificateFile` is read from `~/.ssh/config`, with the same `~`,
`${VAR}`, `$VAR` and percent token expansion `IdentityAgent` got,
`none` clearing the setting, first line winning, and its own row in
the read report. The host card gains one optional certificate field
under the credential block, defaulting to the words "from the
agent", with a Test that states what the certificate is and a
sealed, serde-defaulted per-host vault field that travels to the
other devices exactly the way the agent socket does. A host that
names a file offers that certificate first at connect time, on both
lanes (the shell and the file panel), signed by the profile's key
file or by the agent, with the same local verdicts before any packet
goes out: unreadable, not a certificate, expired with its age and
the renew command, or a window that has not opened yet. A jump host
is never offered it: only the target hop is the CA's subject. Settings gains
a credentials screen: what this machine's agent holds, the honest
empty state for the many people who will never have a certificate,
and `[ssh] cert_expiry_warning`, on by default, which puts one quiet
line in the status bar when a certificate has under thirty minutes
left. No protocol change, no migration break: a vault item written
before this loads as "the agent's own certificate", which is what
those hosts already used.

### Added: Enter on a cross-pane result opens it, and three ways into the every-pane search

Board#195, part 3 of 3 of the find-in-every-pane epic (board#141).
Part 2 drew the result list beside the grid and left Enter doing
nothing on it. Enter (or a click, or the arrows and then Enter) now
opens the result: the window walks into that session and tab,
focuses the pane, puts the matching line about a third of the way
down the viewport rather than pinned to the top where it has no
context above it, and marks the match in the solid mint the bar's
current match wears, with the pane's other hits in the dim mint the
list lights its spans with. The bar stays open with the same query
and flips to `this pane`, so Enter walks that pane's own hits from
there. The list and the scan are kept, not rebuilt: the `every pane`
pill brings the same results back with no rescan while the query and
options stand. A result in a dormant session resurrects it on the
way, and the progress line and the status bar say "resurrecting
atlas-web · tab dev · pane 1" while it does, so the walk never reads
as a hang; a session that cannot be opened lands nowhere and the
list stays. The pane menu gains "search every pane" under "search
scrollback", the ctrl+k palette gains "Search every pane" under
"Search scrollback", and the keys settings list the two as "search
this pane's scrollback" (ctrl+shift+f) and "search every pane"
(ctrl+alt+shift+f, the new `search_every_pane` action). Ctrl+r and
the command history palette are untouched. The in-pane search paints
its matches on the grid now too, which it had not before: only the
counter said where the match was. Two review corrections (PR #96):
the row the arrows chose belongs to the list it was chosen in, so a
new scan, and an emptied query, start with no row chosen rather than
lighting an unrelated row of the new list for Enter to open; and the
grid's marks are bucketed by visible row once when they are built,
so a full grid under the 500-match cap asks a row's few marks per
cell rather than every mark on screen, which kept the keystroke
budget honest while the bar is open.

### Added: the clipboard follows the viewer, part 1 of 4 (engine only)

Board#214, part 1 of the epic board#129, ADR 0018. A copy a program
makes on a host (OSC 52: vim, tmux, neovim and most editors) used to
land on the machine running the shell, whoever was actually watching
the session: yank in vim over SSH from the phone, and the text was on
the laptop at home. The daemon now reads the sequence off the pane's
own bytes and hands the text, as its own sealed frame on the same
encrypted lane as the terminal output, to the viewer the person is
using: this window if it has focus, otherwise the dashboard tab or the
phone that last typed, otherwise the machine running the daemon, which
is what happened before. A viewer that drops off between the decision
and the delivery is skipped and the text lands on the next; with
nobody attached the daemon holds it, for five minutes, for the next
window that opens on that machine, so a yank made while nobody
watched is not lost to the seconds between one window and the next,
and a window opened the next morning does not have an old yank set
over what was copied since. A
program can set the clipboard and can never read it: a host asking to
read is refused on every surface, as it always was, and now the daemon
says so by name instead of staying silent. Two switches per host on the
vault's host item, programs may set the clipboard (on) and copies
always land on this machine (off), and one syncable preference,
`[terminal] clipboard_follows_viewer` (on), which travels with the
account's settings like the "programs may set the clipboard" switch it
depends on. Termuna Cloud stores and forwards ciphertext and reads
none of it; nothing on the relay changes. This part is the engine: the
window writes the clipboard it is handed and logs a refusal, and
nothing is drawn yet. The pane's echo, the host editor rows, the
settings row, the dashboard and the phone are parts 2 to 4.

### Added: the sticky command row, the bounded copy and their entry points

Board#202, part 3 of 3 of the command-marks epic (board#140). The
daemon has known since part 1 where every command in a pane started
and ended; the window now spends that on four things. A sticky command
row: while the viewport sits inside a command's output and that
command's prompt is scrolled above the fold, one row pins at the top
of the pane with the command, when it started and how it stands
(running and for how long, exit unknown, or the code the shell
reported, in the status' own colour). It is chrome drawn over the pane,
never in the buffer: not in the scrollback, not in a selection, not in
a copy and not in what the mirror sends, so a phone or web viewer sees
no phantom row. It disappears the moment the boundary is visible again,
never appears on the alternate screen, and clicking it jumps to the
boundary. Off by default: `[terminal] sticky_command` (Settings,
Terminal, "Sticky command row"; it travels with the account like the
other terminal preferences). Two context-menu rows, "copy this
command's output" and "copy command and output", bounded by the marks
around the row that was right-clicked, each saying how many rows it
takes; both paint the range on the pane before the clipboard changes,
and for a command still running the range stops at the last row
printed and the menu says so. "Jump to this command" beside them. The
ctrl+k palette gains "Jump to this command", "Copy this command's
output" and one row per mark in the focused pane; in the ctrl+r
history palette a record whose command is still in this pane's
scrollback reads "in this pane" and ctrl+enter jumps to it there,
while plain enter inserts as before. Boundaries are read off the
terminal's own echo: nothing is installed on the far side and nothing
about a mark leaves this computer.

### Fixed: a session that has gone quiet keeps its scrollback across a daemon restart

Board#203. The daemon wrote a session's scrollback to disk only as
output went by, throttled to one write every three seconds, so a
session that ran one command and then sat quiet had no log file at
all, and an active session lost everything after its last throttled
write when the daemon stopped. After a restart such a session came
back with its tabs and directories but an empty history, and find in
every pane reported its scrollback as not on this machine. A plain
`kill -TERM` outside systemd lost it the same way, because that exit
wrote nothing. The daemon now flushes every session whose log changed
since its last write on the same three-second cadence, and again on
its way out of an ordinary shutdown (SIGTERM, the Shutdown request,
the idle exit), so a quiet session's scrollback is on disk within a
few seconds and an active session loses at most one interval. A log
nothing has changed is never rewritten: an idle daemon makes no
writes at all, and a session ended on purpose is never brought back.
The systemd fd store and the successor handoff are unchanged.

### Added: command marks in the gutter, and ctrl+up / ctrl+down to jump between them

Board#201, part 2 of 3 of the command-marks epic (board#140), the first
half a user can see. Every pane now has a 22px gutter column left of
its text, chrome and never scrollback, with one hairline per command
the pane ran, at the row where the command line starts: mint when the
shell reported exit 0, the warn red for any other exit code, and a
plain grey rule for a boundary nobody reported, a prompt snapshot or a
command still running. The grey is deliberate: a hairline is never
mint because a command probably worked. A pane that has run nothing
shows the empty column, so nothing shifts when the first mark arrives,
and while a full screen app holds the alternate screen the gutter is
empty.

Ctrl+Up and Ctrl+Down walk the viewport to the previous or the next
boundary, put its command line at the top of the pane and wash that
one row for a moment. The keys are the window's: they never reach the
shell, and every other arrow does exactly what it did. The status bar
names what the jump landed on in the right hand fact slot for four
seconds, then goes back to what it was: the start time, the command
and the status, "14:02 · cargo build --release · exit 0", with "exit
unknown" in amber where the shell never said. At either end of the
list the viewport holds still and the bar says so, "oldest mark in this
pane, 214 lines above the trim"; a fresh pane answers "no commands in
this pane yet" and a full screen app "full screen app, no marks". The
marks are the daemon's (part 1): the window reads them, places them on
its own rows and asks again after output, so nothing about a mark is
stored, sent or synced by this part. No protocol change. The sticky
command row, the copy menu and the settings card are part 3. Mockup:
`?marks=gutter|jump|unknown|edge|empty|alt`.

### Added: a forwarding host can be given only some of the keyring

Board#191, part 3 of 4 of the agent-forwarding epic (board#128). A host
marked to forward used to reach the whole local keyring. The host card
now opens an identity allowlist under the switch (screen A2): the
identities the agent socket's Test listed, each with a tick, the touch
tag from the agent's own flag, and one sentence saying what the host
is offered as a result. Nothing is typed; the rows are facts the agent
stated. None ticked is the whole keyring, the honest default, and the
card says so rather than showing a count. The list is saved with the
host in the vault, syncs with it, survives a restart, and a ticked key
the agent no longer holds is kept and marked "not in agent" rather
than silently dropped from the allowlist. A linked host whose file says
`IdentityAgent none` beside `ForwardAgent yes` has no Test to run and
no agent to forward, and the sentence under the list says exactly that
instead of pointing at a button the card does not show.

The allowlist is enforced where the agent answers: the identities
listing the far host sees is filtered to the ticked keys, and a signing
request for any other key is refused here, before the agent hears of
it, with the agent's own "no" on the channel and the pane's existing
refusal line, "prod.novalabs.dev tried to sign with rsa legacy-deploy,
a key it was not offered · refused here, not forwarded".

Screen B, the vault SSH list: a forwarding host's gold line now reads
"forwards 2 of 3 identities" when an allowlist is set and "forwards all
identities" when it is not (a linked host still names its `ForwardAgent
yes`), so the estate can be audited by scrolling. No protocol change:
the list rides the vault profile and the local IPC only. Mockup:
`?addhost=fwd|fwdall|fwdyes`.

### Added: command marks, the boundary rows

Board#200, part 1 of 3 of the command-marks epic (board#140), the
engine half and nothing a user can see yet. The daemon now keeps, per
pane, one mark per command the shell ran: the row where the command
line starts, the row where its output starts, the row where it ended
(none while it still runs), the command text, the start time and the
exit status. The status is honest: a command the shell marked with OSC
133 is running until OSC 133 D names a code, a boundary read off a
prompt snapshot is unknown, never a guessed zero. A mark is anchored to
the pane's retained output log, the log's own frame numbers, and
resolved to a row on request against the pane's current width, so a
resize that rewraps the buffer moves every mark with it and a boundary
the log has evicted is dropped, never answered as a stale row. While a
program holds the alternate screen no marks are made and the list is
empty and says so; the primary buffer's marks are back once it leaves.
A bounded range read returns a mark's rows as text, the output alone or
the command line and its output, the rows printed so far for a running
command, and nothing for a command that printed nothing. Three local
requests on the mux socket carry it (the list, the neighbouring mark
above or below a row, the range); nothing on the wire, nothing in the
vault, no account, free tier, and no protocol change. The echo model
that reads commands off the terminal now runs whether or not history
capture is on, because the marks read it too; the switch still decides
what is written. The gutter hairlines, the jump and the sticky command
row are parts 2 and 3.
### Added: the search bar searches every pane, and answers with a list

Board#194, part 2 of 3 of the find-in-every-pane epic (board#141): the
chrome for the scan part 1 built. The search bar (ctrl+shift+f) gains a
two-pill scope switch left of the field, `this pane` and `every pane`.
In `this pane` nothing changes: the same input, the same `3/17`
counter, the same `Aa` / `ab|` / `.*` toggles, the same in-pane
highlight. Pressing ctrl+shift+f again while the bar is open toggles
the scope. In `every pane` the same three toggles apply to every pane
the daemon holds, and the answer is a result list in a column beside
the grid: grouped by session with a count per group, each row the
matching line with the term in mint and, under it, the tab, the pane's
place in it, the pane's own title when its program set one, and the
line number in that pane's scrollback. A dormant session's rows say
"dormant, from disk". The column is a column, never an overlay: at the
wide width class it sits beside the grid, which gives it room; below
that it becomes the centre column and the grid steps aside until esc.

Progress is a sentence with numbers, never a spinner: "searched 9 of 14
panes" with a thin bar and a stop while the scan runs, then the elapsed
time and the skipped count. The list is usable while it fills: the
window polls the daemon and appends, groups stay where they first
appeared, and stop keeps what arrived. Skipped panes are listed under
the last group with the reason part 1 named, one of four: on the
alternate screen, scrollback not on this machine, still loading from
disk, or stopped before this pane. Nothing found says `"x" is in none
of them` and how many panes across how many sessions were read; a scan
in which every pane was skipped says that instead of claiming the term
is absent; a machine with one pane says "this is the only pane". The
status bar carries "every pane · 9 matches" while the scope is on, and
beside it, at every width but quake, "nothing left this machine".
Nothing leaves the machine. Enter on a row (the handover to the pane)
is part 3.

Mockup: `docs/design/termuna-ui-v6.html?find=pane|every|scanning|none|one`,
at every width class.

### Added: a forwarding host reaches a second hop, and every signature is printed in the pane

Board#190, part 2 of 4 of the agent-forwarding epic (board#128): the
channel part 1 only promised. A host marked to forward now has the
session channel ask for `auth-agent-req@openssh.com` before the shell
is requested, and every agent channel the server then opens (a second
`ssh`, a `git pull`) is served from this machine's own agent
connection, the socket the host's card names or `SSH_AUTH_SOCK`, on
unix and over the Windows named pipe alike. No key material is read,
held or copied: signatures leave, keys do not. A request that would
change the agent (add or remove a key, lock, unlock, anything this
build cannot name) is refused here with the agent's own "no" and never
forwarded, and the pane says what the host tried. A jump host is passed
through and never given the agent.

Screen C, the signing line: one quiet gold line per signing request in
the pane, "prod.novalabs.dev asked your agent to sign · ed25519
nova@novalabs.dev" (plus "· touch" for a hardware key), naming the host
that asked and the identity used. It is terminal content, written by
the daemon into the pane's own stream, so it scrolls, persists and
reaches the web viewer and the phone with no new frame. A burst of
requests for the same identity within three seconds prints once and
then a count ("asked your agent to sign 4 more times"), so a chatty
deploy script does not paint the pane. Typed from a phone or the
dashboard, the pane adds "signed on nova-mbp · the key never left it",
with an interim "waiting for the touch on nova-mbp" for a hardware
key, replaced whole by the signed line (or the agent's no), whoever is
typing by the time it arrives.

Screen D, the three refusals, each naming who refused, each its own
lines, never a silent fallback: the server's no ("the server refused
agent forwarding", red, before the first prompt, with the sshd_config
directive named), a changed host key ("forwarding refused: this host
is not the one you trusted", under the redial seam, and the agent is
never offered to that host), and a redialed pane ("agent forwarding is
off on the new connection": a redial, automatic or by Reconnect, is a
new connection and does not inherit the agent; open the host from the
vault again to forward). After every one of them the pane is usable
without the agent. The host card's on copy now says what is true: the
host can ask, for this session only, and every signature is printed.
No protocol change: the switch rides the daemon's local `SshTarget`
(absent in an older persisted session, and absent is off), and a
session a phone opens carries no switch. The v6 mockup shows the lines
(`?fwd=signed|phone|refused|hostkey|redial`) and the new on copy.
The identity allowlist and the docs section are parts 3 and 4.

### Added: find in every pane, the scan

Board#193, part 1 of 3 of the find-in-every-pane epic (board#141).
The daemon can now answer "where is this line" over every pane it
holds, with no index, no background job, no on-disk artifact and
nothing leaving the machine. A scan is started, polled and stopped
over the mux socket, and it answers partially: results accumulate as
panes finish and each poll pages what arrived since its cursor, so a
window can paint while the scan runs instead of waiting for the last
pane. The order is the user's: the caller's focused pane is read
first, then live panes newest session first, then dormant sessions,
panes in tree order within a session. Every pane's bytes go through a
throwaway emulator and the in-pane bar's own matcher
(`Emulator::search_with`), so case, whole word and regex give the same
verdict in both scopes by construction. Each hit carries its session,
tab and pane (id and title), the absolute line number, the line text
and the match span, so the caller highlights without searching again;
each pane carries a match count. A pane is never nowhere: it is in the
counts or in the not-searched list with one of four named reasons (on
the alternate screen, scrollback not on this machine, scrollback still
loading from disk, the search was stopped before this pane). Stopping
a scan ends the reading at once and marks every untouched pane with
the stopped reason. Hits are capped per pane at the in-pane bar's own
500, and a very long line is cut around its match so one line cannot
become a frame of its own size. The scan reads a pane down to its
oldest retained line: the throwaway emulator's scrollback follows the
retained log rather than a fixed 10k window, so a line the daemon
still holds is findable. There is one matcher on the machine:
`termuna_core::Needle` compiles a needle once, for the in-pane bar and
for the cross-pane scan, so the two cannot disagree about what a
needle means. No UI in this part: the drawer and the handover are
parts 2 and 3.

### Added: the layouts screen, open a layout, attach instead of duplicate

Board#184, part 4 of 4 of the saved-layouts epic (board#116), the last
mile: the window can now see the saved layouts and open one. The
drawer gains a "layouts" row beside snippets with its count, and the
screen behind it lists every layout the vault holds: the name with its
chips (`trusted`, and "1 pane needs a host" when a pane names a host
this vault lacks), when it was last opened on this machine ("opened 2h
ago on this machine" / "never opened here", a fact kept per machine in
`layouts-used.json`, never in the vault item), then the counts and
targets ("2 tabs · 3 panes · prod-app x2, this machine"). The list
puts the layouts opened here first, newest first, then the rest by
name, and the search box finds one by name or by a pane's directory.
Empty, the screen teaches the one way in ("Save current session");
signed out, the amber fact ("These layouts stay on this machine") takes
the vault's promise's place, and everything else works the same.

Opening: the row, its Open button, or the ctrl+k row "open layout
<name>" (with the same facts as its meta, in the same order as the
screen) asks the daemon to build the session (part 2's request); the
window walks into it as it comes up. Each pane's progress line and the
two named refusals (a host not in this vault, a directory that does
not exist here) arrive as terminal content from the daemon and simply
render; the status bar counts the build in the same register the
armed watch and the redial use, "layout morning: 2 built, 1 dialing, 1
refused", gone when it settles unless something refused, in which case
it stays a minute to be read. One build at a time: a second press
while the first is answering is ignored rather than making two
sessions of one name.

Attach instead of duplicate: when a live or dormant session already
carries the layout's name, the daemon answers with it and the window
asks, in a card over the grid ("morning is already running here" /
"morning is saved here, idle", with the session's tabs, panes and age)
with two answers, "Attach to it" first and "Build a second one"
beside it. Both work; nothing is duplicated silently.

Rename and remove, from the pencil on each row: the rename card keeps
the layout's id (so other machines see it renamed, not replaced),
refuses a name another layout already has, and holds Remove; both
round-trip through the vault, sync on the next round exactly like a
snippet, and survive a restart. A saved layout is on the screen the
moment it is saved, signed out and with the vault locked included
(the list is reloaded from the vault on every save, rename and remove,
not only by the sync round that follows a signed-in save); a saved
rename closes its card without asking whether to discard the edit it
just saved; and a failed open is a fact about that visit, cleared when
the screen is left or opened again. No protocol change.
`docs/design/termuna-ui-v6.html` carries the drawer row, the screen
(`?layouts=list|empty|local`), the palette rows and the attach card
(`?attach=live|dormant`).

### Added: save this session as a layout, the capture card

Board#183, part 3 of 4 of the saved-layouts epic (board#116). Ctrl+K
over a live session lists "Save this session as a layout" (with the
pane count), which opens a review card rather than a confirm dialog:
the captured tree, one tickable row per pane under its tab and split
line, with the pane's target ("this machine" or the vault host's
name), its directory and its opening command when there is one
(literal, or `snippet: <name>`); a name field defaulting to the
session's name; the trust toggle ("Run the opening commands when this
layout opens"), off by default, which is exactly what opening a
layout reads as `trusted`; the seal fact; and "3 of 4 panes" in the
footer. A row ticked off never reaches the sealed item. Every row off
is refused with the reason in the card ("a layout needs at least one
pane"), never a silent no-op. A name the vault already holds turns
Save into a question ("save over morning?") and the second press
replaces that layout by id, so other machines see one layout, not
two. A pane dialed through a host that is no longer in the vault is
shown, said, and left out. A local pane's directory under the home
folder is written as `~`, so the layout lands in the right place on a
machine with another username. Signed out, the amber fact ("These
layouts stay on this machine") takes the seal fact's place and the
save goes on locally, exactly like a snippet; signed in, the item
syncs on the vault round. The daemon gained a local `PaneCwds`
request (not a wire change) so the card can state every pane's
directory: Linux reads it from procfs and macOS from the kernel
(`proc_pidinfo`); on Windows the captured directory is the last one
the shell reported (OSC 7), and is absent for a shell that never
reported one. `docs/design/termuna-ui-v6.html` carries the palette row
and the card (`?layout=save|over|empty|out`). The layouts drawer
screen, opening a layout and the attach card are later parts.

### Fixed: history written by the previous release is no longer dropped as unreadable

Board#188 (parent board#186). The relay replays a host's frames byte
for byte, the daemon reads its own log back off disk on a restart and
the export archives that log, and every one of those readers decoded
with the strict codec that accepts exactly the current protocol
version. A session that was live across the v3 to v4 update therefore
had a stored log of `[v3 frames][v4 frames]`, and its scrollback and
its last layout vanished from every reader after the update: the
daemon's replay to the relay, a mirror of another machine's session,
the account's session list (which reads the stored layout to name the
agent) and the export. Readers of persisted bytes now take the
deprecation window ADR 0017 already declared for the relay
(`termuna_protocol::decode_supported`, v3 and v4 today), which is safe
by that ADR's own bump rule because a v3 frame decodes into the
current types unchanged; a v2 frame, or bytes that are no frame, are
skipped exactly as before. A host replaying a frame it read off disk
stamps it with the current version, so a current host never writes
the previous version into the relay's log. Live connections are
untouched and stay strict; `PROTOCOL_VERSION` stays at 4, the relay
is not changed, and docs/PROTOCOL.md states the rule for persisted
readers. ADR 0017 gains the consequence: a bump that moves the window
beyond stored frames ships with a migration of the stored tail.

### Added: a host can be marked to forward the agent, and the file's answer is read (state only, nothing forwarded yet)

Board#189, part 1 of 4 of the agent-forwarding epic (board#128).
Agent authentication stops at the first hop today: from a pane on host
A nothing can reach host B, because nothing is forwarded. This part is
the state and the surface, no wire: the channel itself is part 2. The
host card grows one switch inside the agent socket field, "Forward this
agent to the host", off by default and per host only, with the off copy
naming the failure you otherwise hit (git, a second ssh hop). It is
stored on the host record (`Profile::forward_agent`), survives the vault
and a restart, and an older vault file loads with it off. Because this
build does not open the channel, the on copy says so rather than
promising a signature. The linked-mode reader of `~/.ssh/config` now
reads `ForwardAgent` with the three states `IdentityAgent` gets, yes, no
and unset, first line wins, into `Profile::forward_agent_directive`: the
file's yes or no decides and the card shows it read only, naming the
directive ("forwarding off, ForwardAgent no", with the reason), while
the file's silence leaves the switch to you and a re-read never flips
it. No percent tokens are expanded: the value is a yes/no answer, and
the socket-path form OpenSSH also accepts is read as yes with the path
left to the part that forwards. **A `ForwardAgent yes` under `Host *`,
a pattern, a `Match` or before any `Host` line is read and never
applied**: the read report gains a "forwarding hosts" row that counts
the per-host ones and says, in so many words, that the wildcard was
read and not applied and that forwarding is turned on per host, plus a
"forwarding off" row for explicit `no`. The vault SSH list wears a
quiet gold "forwarding on" line under a host that is marked, naming
`ForwardAgent yes` when the file decided; the identity allowlist and
its "forwards N of M identities" shape are part 3. No protocol change.
The v6 mockup carries the switch (`?addhost=fwd`), the linked
`ForwardAgent no` card (`?addhost=fwdno`), the report rows and the
list line.

### Fixed: a pane state this build cannot name no longer drops the session's layout

The `Layout` snapshot's `pane_states` map was decoded strictly, so a
`kind` a client had never heard of failed the whole snapshot and every
layout update for that session went missing, not merely a badge. The
first such kind is `connecting` (below), which a desktop built between
board#68 and this change rejects. An unknown `kind` now reads as
`PaneState::Unknown`: it takes no input (the host drops the keystrokes
anyway), the window draws nothing for it rather than inventing words,
and a host never records it about its own panes. docs/PROTOCOL.md
states the rule and the compatibility decision; no released desktop is
affected and `PROTOCOL_VERSION` stays at 4.

### Added: a saved layout opens as a session (engine, nothing to press yet)

Board#182, part 2 of 4 of the saved-layouts epic (board#116). Part 1
made a layout a sealed vault item; nothing could open one. The daemon
builds one now: `MuxRequest::BuildLayout` carries the layout plus what
the caller resolved from the vault (host id to dialable target and
name, snippet id to text; the daemon never holds the vault) and answers
with the session and per-pane facts, or with the live or dormant
session that already carries the layout's name, so the window offers
"attach" rather than building two of everything (an explicit
`build_second` insists). The decisions are one pure module,
`termuna-mux::layouts`, and the daemon only executes them: the exact
tab and split tree, freshly labelled; each local pane spawned in its
directory; each host pane parked in the tree as `PaneState::Connecting`
(a new, additive pane state: no shell yet, input dropped rather than
queued, nothing lit in the chrome) and dialed in the background so the
session is there to attach to at once, its `cd` and opening typed the
moment the shell answers. Honesty as terminal content, through the
same inject lane as the redial seam, so it persists and mirrors: a
host not in this vault opens a local shell in the home directory and
says `host "backup-eu" is not in this vault`; a directory missing here
opens in the home directory and says `directory ~/x does not exist on
macbook`; a snippet missing here types nothing and says so; a host
that does not answer settles as the redial's own inert states with the
Reconnect action. The rest of the layout builds regardless: partial is
an outcome, not an error. The opening command runs only for a trusted
layout, and only in a pane that is what the layout said: any refusal
downgrades it to typed. An empty layout is refused before anything is
made. Under the hood a session may now dial per pane (a prod-app pane
beside a local one), which persists, survives a daemon handoff and is
inherited by a split; a layout whose every pane dials one host is a
plain SSH session on that host. No protocol change and no
`PROTOCOL_VERSION` bump. The layouts screen, the palette actions and
the attach card are part 4, so nothing in the window changed and the
v6 mockup does not move.

### Added: a saved layout is a vault item (foundation, nothing to see yet)

Board#181, part 1 of 4 of the saved-layouts epic (board#116). The
daemon already owns a session's tab and split tree and already knows
each pane's directory; the vault already carries sealed items to every
machine. A layout is those two facts joined: a new vault item type,
`"type": "layout"`, holding a name, when it was saved, whether its
opening commands are trusted to run by themselves (off by default), the
tabs and split tree in the session model's own shape, and per pane its
target (this machine or a vault host by id), an optional directory,
name and opening command (literal text, or a snippet by id). Sealed,
stored, listed, edited, deleted and synced exactly like a snippet, in
the personal vault, with the same tombstone; a vault written before
layouts existed loads with none; a client that has not learned the
type keeps the blob as it always did. No protocol change. The capture
is one pure function over a live session and the rows the caller wants
kept: a pane left out collapses its split onto the sibling that stays,
a tab that loses every pane is dropped, leaving every pane out gives a
layout with no tabs, and nothing a pane printed exists anywhere in the
item, which a test asserts on the sealed bytes by listing every key
the item may carry. The desktop export archive gains
`layouts.json`, sealed or plain by mode like the settings and
trusted-host members, and always present: an empty list when there
are none, never a missing file. The save card, the layouts screen and
opening a layout are parts 2 to 4, so nothing in the window changed
and the v6 mockup does not move.

### Changed: a relay deploy no longer cuts off the previous release

Board#173, ADR 0017. The protocol crate's decoder accepted exactly one
version, its own, so the day Termuna Cloud moved to a new protocol
version every desktop still on the previous one lost continuity at
once, and a routine backend deploy was what ended a user's sessions.
The crate now names the deprecation window,
`MIN_SUPPORTED_PROTOCOL_VERSION` (the previous version, one constant,
one line to change), and offers
`decode_supported`, which accepts the current version and the one
before it and refuses anything older with the same error the relay
already turns into its `client-too-old` close. Strict `decode` is
unchanged. With the relay on the lenient path (a website-repo change
that follows), a user one release behind keeps their sessions
mirrored through a deploy and updates in their own time; the written
bump rule in ADR 0017 (a bump only when an existing frame's shape or
meaning changes, never for additive vocabulary) is what keeps the
window honest. No protocol version bump, no wire change.

### Fixed: a relay that refuses this build says so, once, instead of failing quietly every minute

Board#170. The daemon treated every relay failure the same way: log
it, retry with backoff capped at a minute, forever, and tell the window
nothing. When a cloud deploy moved the relay to a newer protocol than
an installed desktop, every session showed dormant on the phone and
the desktop said nothing about why. The relay now ends a refused
greeting with a typed WebSocket close (termuna-website, part 1 of this
epic), and the daemon reads it: the close code and its `<token>:
<words>` reason map to a `RelayRefusal` (too old, greeting rejected,
malformed, or other), defensively, so a missing, unknown or truncated
reason falls back to the behaviour every close had before. "Client too
old" is terminal, not transient: the daemon holds it, re-checks every
fifteen minutes instead of hammering the relay every minute, and
lifts it by itself the moment the relay admits the daemon again, or
the moment the user signs out, since a machine with no token talks to
no relay and has nothing left to be refused. It
tells every attached window on the session lane (`CloudRefused`,
local only, additive, no protocol version bump) and reports it in its
status, so the status bar reads "app too old for cloud" in place of
"e2e", the continuity panel states the sentence and the versions the
relay named, and the sessions drawer marks each local session with the
same words instead of leaving it to read as plain dormant elsewhere.
Every other relay failure, a network drop, a relay restart, an unknown
close code, the plan limit, behaves exactly as before.

### Fixed: a freshly copied share link opens on a session that had rotated before

Board#176. A link minted from "copy view link" (the `#l=` shape, ADR
0016) opened in the browser to "this link was stopped" although nothing
had been stopped and the session was live. A viewer attaching is
replayed the session's whole log, `KeyRotation` frames included, and
the holder read every rotation that did not name the link's key as a
stop, the ones from before the link was minted too. The host could not
have sealed those to a key that did not exist yet, so on any session
that had ever rotated (every session where a share was once stopped)
every link minted afterwards was locked out on arrival. `Holder::follow`
now treats a rotation at or below the epoch the link's material names
as history the link was not a party to (`Followed::Historic`): ignored,
not followed, not a stop. A rotation above that epoch that omits the
link is still a stop, exactly as before, so a revoke is not weakened.
`KeyRing::floor` is the accessor the rule reads. The sentences are
audited too: "this link was stopped" is reserved for a link a rotation
genuinely excluded, and a link whose material is missing or does not
open keeps its own sentence, the same on the web. No wire change.

### Fixed: one Escape closes the palette, and nothing typed at it reaches the shell

Board#162. The first Escape on the ctrl+k command palette did nothing
visible and the second one closed it, and the same held for the ctrl+r
recall list, the arm card, every modal that says "esc to close" and
broadcast mode. The app listened for keys through `keyboard::listen()`,
which yields only what no widget took, and a focused text input takes
Escape for itself (it unfocuses on it), so the press meant to close the
palette never arrived; the second one arrived only because the field no
longer had the focus. Worse, once the field was blurred and the palette
still open, every key fell through the palette into the shell behind
it: a command typed at the palette ran in the pane. The subscription now
reports a captured Escape press as a message of its own, one shared
ladder answers both arrivals in the same order as before (the layer on
top goes first), a captured Escape never goes on to the shell, an
Escape nothing owns still reaches the shell exactly as it did, and while
the palette, the recall list, the arm card or a machine or directory
pick is up no key reaches the shell at all.

### Changed: a share link is a key holder of its own (share revoke rotates the key, 3 of 4)

Part 3 of board#87 (board#125, ADR 0016). Every share link used to
carry the session's root key in its URL fragment, so after a revoke
the host rotated and locked every link holder out, the entitled ones
included (the honest limit part 2 stated). A minted link now has an
X25519 keypair of its own: the fragment carries the link's secret
(`#l=<secret>`) and never the session key, two links on one session
carry different material, and the current epoch's content key wrapped
to the link's public key travels to Termuna Cloud with the mint as an
opaque blob on the link's row, which the relay cannot open and serves
to whoever opens the link, so a link works while the host is asleep
exactly as before. The daemon mints the material (`MintLinkKey`),
because it holds the current key and the window holds the root at
most. The relay lists the live links' public keys to the host in a
new additive frame, `ShareLinks`, after `Welcome` and on every change,
and a rotation is sealed to exactly those survivors beside the
account: a stopped link finds no entry and reads nothing from that
epoch on, by name. An old `#k=<root>` fragment keeps working until its
own expiry on a session that has not rotated, and on meeting a later
epoch says "this link was replaced when a share was stopped" rather
than failing to decrypt (`termuna_sync::Holder`, the reference the web
viewer and the phone port from). A revoke that lands between the
daemon's mint and the cloud's store is caught: the link is stopped
again before it is copied and the panel says why. No
`PROTOCOL_VERSION` bump; the relay must be rebuilt to send the frame
and store the material, and the web viewer and the phone learn the
new fragment in their own parts. `tsp-vectors` grew `share_links` and
`share_links_empty`; `format-fixtures` grew `share_link`.

### Fixed: a key this machine trusts by first use never reads as another device's

The trusted hosts list decided "trusted on this machine" from the
vault's items alone. A key accepted here by plain first use has a line
in this machine's known-hosts store and, once another device's item
for exactly that key has synced in, no item of its own (the import the
list runs on opening records nothing an item already covers), so its
row read "trusted on iphone on <date>, not on this machine yet" for a
key this machine connects by, and Revoke on that row rewrote this
machine's own store line under a sentence that called it somebody
else's. The store is the source of truth for connecting, so the list
now asks it as well (`trusted::trusted_here` takes the parsed store
beside the items): a row for a key the store holds shows the ordinary
last used or first seen line, and only a key the store does not hold
reads as another device's trust. A store line for a different key of
the same host changes nothing, as before: that is a mismatch story.
The first-contact evidence rule is unchanged. Named regression test:
`a_key_this_machine_trusts_in_the_store_never_reads_as_another_devices`.

### Added: trust travels between devices, informed and never automatic (4 of 4)

The last part of board#78. A trusted host key was a vault item that
synced like a snippet on every plan, and nothing said what a key
another device had accepted meant on this one. Two rules settle it.
Carrying trust between devices is Termuna Cloud's; verification is
not: a sync round now asks the plan (`trusted::plan_carries_trust`,
the same answer as settings and command history, and an unknown or
free plan is a no) before a `known_host` item goes up or comes down,
and hosts and snippets travel exactly as before. Trust on first use,
the known-hosts file and the trusted hosts list are unchanged on a
free or signed-out machine: only the cloud round is gated, on the one
filter both directions read (`trusted::for_the_round`).

And a key that arrives from another device is a review copy and
nothing more. It is never written into this machine's known-hosts
store, so a connection to that host is still first contact until this
machine verifies the key itself; the import the list runs on opening
goes store to item only, and a named regression test holds that
(`a_key_trusted_elsewhere_is_never_written_into_the_local_store`).
What the copy is for is one line of evidence: `trusted::evidence`
answers, for the key a host presents now, whether another device of
the account already trusts exactly that key, naming the device and
the date, and answers nothing when this machine already trusts it or
when any device holds a different key for that host, because a
disagreement between devices is a mismatch story, never an invitation.
The trusted hosts list renders it today: a row for a key this machine
has not accepted itself reads "trusted on iphone on 2026-08-30, not on
this machine yet" instead of a first-seen line that read as trust
here. The first contact card that asks "trust here too" is a
follow-up, with the daemon round trip it needs.

The export carries the keys: a `trusted_hosts` member in the local
document, sealed under the machine-local vault key in the archive and
plain JSON in the readable export, absent when the vault holds none,
with each item naming the device that accepted it. The done card
counts them. `docs/design/termuna-ui-v6.html` has the row
(`?v=trusted`; `?trusted=local` hides it, since a free or signed-out
machine holds only its own keys).

### Added: a pattern watch on the pane, the desktop half (2 of 4)

The user-facing half of board#115, after the daemon learned to wait for
a line. "Notify when this quiets down" gains a fourth condition, "when
a line appears", set off by a rule in the flyout because it is the only
row that opens something: the arm card, a popover anchored where the
right-click was (or at the grid's corner from the command palette),
never a dialog over the grid. The shell keeps printing behind it and a
click anywhere else is a cancel. The card is name first, because the
name is the whole notification: on the lock screen, on the pane's
corner tag and in the status bar; then the pattern, plain text or a
regular expression as a visible choice rather than a guess from the
syntax, and once or keep watching. Its validation asks the daemon's
own compiler, so a regex that does not compile puts the compiler's
sentence under the field and disables Watch, and a pattern that would
match almost every line warns in amber and leaves "Watch anyway"
enabled. A refusal the daemon sends back for that arm (a pane or a
session already holding as many watches as it takes) reopens the card
with the reason under the field, never a toast or a status-bar line.
Arming from a selection is the fastest route: "watch for this line"
sits under "save as snippet" while the selection holds a line worth
waiting for, and the card opens with the pattern filled in, its
timestamp dropped, a name suggested from its first two words, and keep
watching as the default, because a line that appeared once tends to
appear again. When the phone cannot be reached the card says so in
amber at the moment of arming, never in a toast afterwards.

Several watches stand on one pane now, each disarmed on its own: the
corner tags stack in arming order, the unnamed slot still reading
"armed · prompt", a named watch "watching · <name>" behind the eye,
with the count once a keep-watching one has fired. A watch that fired
with nobody looking turns its tag the attention amber and names itself
in the status bar beside the count ("error in ingest · 3 matches ·
last 40s ago") until the pane is viewed. The desktop toast is the
watch's name and where it stands, and a keep watch updates its one
toast instead of stacking a new one; the line that matched is never
shown anywhere but the field the user typed it in. The palette lists
what is watching now and disarms by name. No protocol change beyond
part 1. `docs/design/termuna-ui-v6.html` carries the surface
(`?armcard=menu|selection|regex|wide|offline`, `?watch=named|fired`).
Web and phone follow.

### Added: trusted host keys are vault items, with a desktop list to revoke them (3 of 4)

The desktop half of board#78, after the phone learned trust on first
use (parts 1 and 2). A server key accepted on first use lived only in
each machine's own known-hosts file, where nothing could review it,
revoke it or carry the decision anywhere. It is a vault item now,
`known_host` (`termuna_vault::KnownHost`): host and port, key type,
the base64 key, its `SHA256:` fingerprint, when it was first and last
seen, the device that accepted it, and the last refusal of a different
key when there was one. Sealed, stored and synced exactly like a
snippet, in the personal vault, and additive on the wire: no protocol
change, no `PROTOCOL_VERSION` bump, an older build keeps the item
without reading it. The known-hosts file stays the source of truth
for connecting, on every plan; the item is the review copy. The
store's pure rules moved into `termuna_ssh::known_hosts`: the line
format both ways to the item, the classification of a presented key
(trusted, first contact, mismatch, by exact host and port, so a
wildcard or hashed pattern never trusts a concrete host and another
port is another entry), and revoke. The verifier asks that classifier
now, and what it does is unchanged.

The drawer gains "trusted hosts": each row is the host (and the
connection's name when one points at it), the key type and its full
fingerprint, never shortened, a status line (first seen, last used,
or "key changed, refused on <device>"), the device chips, and Revoke,
for one key or for every key of a host. A host that answered with a
different key sorts to the top with the refusal that put it there;
the desktop notes that refusal on the item the moment a pane goes
inert with a changed key. Revoke asks once, removes the line from
this machine's store as well as the item, and carries the deletion up
on the next sync round. Opening the list imports what the store holds
and no item records yet, once per key. The foot line is the boundary:
sealed with your vault key, the relay never learns which servers you
use, sharing trust across devices is Termuna Cloud and local trust on
each device is free. Cross-device evidence and the informed first
contact card are part 4. `docs/design/termuna-ui-v6.html` carries the
screen (`?v=trusted`, `?trusted=empty|local`).

### Changed: stopping a share link rotates the session's key (2 of 4)

The Stop button on a share link used to stamp the link and drop
whoever was watching through it, and nothing else: the content key
never changed, so anyone who had kept the link's key bytes, or who
replayed the session from the relay later, went on reading. Part 1
(board#123) built the ratchet; this part (board#124, ADR 0015) turns
it. The relay, which learns of a revoke first, tells the session's host
once per revoke action, however many links that action stopped, and
the host mints a fresh rotation secret, records it beside the root key
before anything is sealed under the new epoch, and puts the
`KeyRotation` frame in its own log at the next sequence number, so the
bridge meets it in order and a replay meets it before the first blob
it is needed for. Everything sealed from that frame on is under the
new epoch; a revoked holder's key opens none of it, by the named
epoch error and never a wrong-key one. A daemon restart, or a daemon
upgrade through the handoff, resumes at the stored epoch and never at
zero, and a revoke that happens while the host is away is signalled
the moment it comes back. Frames already in the resume log are
re-sent at the epoch they were written under, and a keystroke sealed
a moment before the rotation reached the viewer is still applied,
one epoch of grace and no more. The rotation secret is sealed to the
owning account's vault key, so the dashboard and the phone follow with
the passphrase they already hold; the title in `SessionMeta` stays
under the root, so the session list is unchanged. **Until part 3, a
revoke locks every link holder out**, the ones you kept included: a
link still carries the root key and has no key of its own to receive
the secret under. The mirror of another machine's session on a second
desktop stops at a rotation too, and says so once. No setting, no UI:
Stop now means stop.

### Added: settings in the export archive (4 of 4)

The anti-hostage half of settings sync (board#77). "Export your data"
wrote the session trees, the connection vault and the command history
and knew nothing about the settings item that now lives in the vault,
so a user who exported everything got everything except the profiles
and the keymap their account carries between machines. The local
document has a `settings` member now, in both honest modes: in the
archive it is the item sealed under the machine-local vault key in the
same envelope the vault member uses, and in the readable JSON it is
the item in plain, the profiles, the default profile, the keymap and
the shell preferences as they travel. It holds only what the boundary
(`termuna_vault::settings::reach`) says travels, by construction: the
item has no field for anything machine local, and the one open map,
the keymap, is passed through `action_reach` once more on the way out
so a platform local binding another client wrote stays where it was
set. A machine with no account or no settings item gets no member at
all, absent rather than present and empty, and the export succeeds as
before. The done card's size row says "· settings" when the item is
inside. The export format version stays at 1: the member is additive
and an existing reader never looks for it. docs/CONFIG.md gains the
settings sync summary (what travels, what stays, the plan gate, the
function that decides).

### Added: a pattern watch on the pane, the daemon half

The pane watch can now wait for a line. Beside "prompt returns",
"30s of silence" and "bell", a watch may carry a pattern, plain and
case-insensitive or a regular expression, and the daemon reads the
pane's own output for it: logical lines assembled across writes, CR LF
and bare LF, a carriage return overwriting the line the way it does on
screen, every escape sequence stripped first so a coloured "FAILED"
still matches. Nothing new crosses the wire to match; the bytes were
already in the daemon. A watch has an id and an optional name now, so
a pane holds several ("deploy done" and "test failure" side by side,
an old-style prompt watch beside them), each disarmed on its own, and a
window that opens late is told about every one that stands. Once fires
and disarms exactly like today's watch; keep watching stays armed and
re-fires, held to the relay's per-session push cooldown so a burst of
matches is one notification with a count instead of a burst. A regex
that does not compile, an empty or over-long pattern, and a watch past
the per-pane or per-session cap are refused with a named reason, never
a hang and never a panic. The fired frame carries no terminal content:
pane, watch, name, condition, count and seconds since arming, never the
line that matched. No user interface yet: the desktop, web and phone
halves follow, and an older client keeps its watch exactly as before.

### Added: the settings screen says what travels

The settings screen now shows the sync that the previous entry made
possible. Every row that maps to a setting carries a small tag, `syncs`
or `this machine`, read from the one boundary function the sync itself
uses, so the tag and the round can never disagree. Each tab that
carries something opens with one mono fact line: what travels from
that tab and when the last round landed, with its age. An offline app,
or one whose first round has not landed yet, says the other machines
are known "as of" that age instead of claiming a sync it did not make.

When two machines edited the same profile, the appearance tab shows a
banner naming the version that lost and the name it was kept under,
with a one-click "Use this" that makes the rescued version the default
profile, and Dismiss. No merge dialog, nothing over a terminal.

A free or signed-out account keeps the whole editor and gets a card in
the fact line's place saying settings stay on this machine, with the
same upgrade path the rest of the app uses. Every row's tag reads
`this machine` there too, the keybindings included, because nothing
travels until a paid account is reached and a row must not claim a
trip the card beside it says is not made. A synced profile whose font
is not installed here keeps its name and its family: the substitution
is stated as a machine-local fact in the new "this machine" block on
the appearance tab (font fallback, window size), and is never written
back over the synced value.

### Added: your settings travel to the second machine

On a paid plan, the appearance profiles, the default profile, the
keybindings and the syncable terminal preferences now ride the
encrypted vault to the account's other machines, and a machine that
signs in arrives dressed instead of naked. The merge is last write
wins, but the version that lost is kept rather than thrown away: a
profile both machines edited comes back as `<name> (from <machine>)`,
so nobody's work disappears into a timestamp comparison. Everything
that belongs to one machine stays on it: the window geometry, the
session it reopens, the history pause switch, the cloud credentials,
the update setting, the quake hotkey, the font fallback and the
`~/.ssh/config` link are untouched by an incoming item.

A free or signed-out account makes no settings calls at all. Not a call
that is refused, no call: the plan is asked here, before the network,
the same way command history sync asks it. And an offline app never
claims a sync it did not make: only a round that actually reached the
server moves the last-synced stamp.

The round settles: a machine that has adopted the account's settings
once has nothing to say on the rounds after it. The keymap that
travels is the resolved one, every default spelled out, which is the
same map the app writes to `config.toml` when it adopts, so the two
halves compare equal and the five-minute round stops rewriting the
file and re-applying the profiles under your hands. One consequence
you can see elsewhere: `[keybindings]` is now written the way the app
actually reads it, so a saved keymap no longer quietly turns `ctrl+tab`
from "last tab" into "next tab" at the next launch.

### Added: the window says what a dropped SSH link is doing

The daemon already kept an SSH pane whose link went away, dialed the
host again and wrote the outage into the pane's own scrollback. The
window said nothing about any of it: a dropped link looked like a pane
that had simply stopped answering, with no way to ask for another try.

It shows now, in the slots that already exist. A pane being dialed
again wears one mono fact in the corner an armed quiet watch uses,
`reconnecting · 8s`, counting down to the next attempt; the status bar
carries the same outage as `web-01 reconnecting 3/8`, so it is visible
while the pane is scrolled away or another tab has the focus; and the
tab's dot takes the attention amber the strip already uses. All three
go the moment the pane has a shell again. Nothing animates, nothing
glows, and no dialog appears over anything.

A pane that cannot come back on its own says so on a card under its
kept scrollback, in the pane, never over the grid: the card takes room
of its own at the foot of the pane and the grid gives up exactly that
height, so the rows the pane is being kept for stay on screen, higher
up, instead of sitting behind the card. Amber when the attempts ran
out, naming the host, what the tries cost and the last error, with
`Reconnect` and `Close pane`; a host that signs in with a password
gets that same card at once, since it never dials itself back. Warn
red is kept for the one case that must not resolve itself, a host key
that changed: the card shows the new fingerprint, offers `Review
fingerprint`, which shows the key in full and trusts nothing, and does
not offer to try again. The room the card takes is worked out from the
card that is really drawn: a hostname long enough to wrap the headline
over two lines takes two lines out of the pane, and opening or closing
the review resizes the grid with it, so the rows the open review costs
come back the moment it is shut.

Typing into a pane that is not live is a plain no-op, as it always was
on the daemon's side: now the cursor dims to the quietest ink to say
so, instead of the pane pretending to take what it drops.

### Fixed: on Windows, a typed `~` names one file again

An agent socket typed as `~/.1password/agent.sock` on a Windows machine
was saved to the vault as `C:\Users\you/.1password/agent.sock` and
probed by the host card's Test button as
`C:\Users\you\.1password\agent.sock`. Same file, two spellings, because
the two lanes expanded the tilde separately: the vault lane glued home
and remainder together as text and kept the forward slashes, while the
app's own expansion joined them the way Windows does. Anything that
compared the saved value with the resolved one therefore disagreed with
itself, and it is what turned the Windows test run red, which in turn
blocked every desktop change from merging.

There is one expansion rule now, `ssh_agent::expand_home`, and both
lanes are it: the part after the tilde is respelled in the platform's
own separator, so home and remainder join once and the vault value is
character for character what the Test button asks about. Unix is
untouched, byte for byte, since there the respelling is the identity.
The rule takes the separator as a parameter, so a Linux test run checks
the Windows spelling too: a rule only Windows can find wrong is a rule
that stays wrong until a Windows user reports it. A `~` shown back in
the field, which on Windows reads `~\.1password\agent.sock`, is read
again as the same path, so editing a saved host and pressing save no
longer changes where it points.

### Fixed: the daemon collects the shells it ends

Every session that ended left one dead process behind. The daemon
killed the shell, which is half of ending a process: the other half is
collecting the exit status the kernel holds until somebody asks for it,
and nothing ever asked. So a shell you killed and a shell you left by
typing `exit` both stayed in the process table as a zombie, holding a
pid and nothing else, for as long as the daemon ran. Six sessions
opened and closed left six of them; a daemon is meant to outlive the
window, your login and the odd reboot, so they only ever accumulated.
It cost no memory to speak of, which is why it went unseen, but a heavy
tab habit or a container with a low process limit would eventually run
out of pids.

The shell's exit status is now collected the moment its pane's output
ends, and again, as a backstop, when the pty is dropped. That backstop
ends a shell the way a closing terminal does, with a hangup, and a
shell may ignore a hangup: so it waits a beat, and a child still there
is killed outright and collected, which the kernel serves in
microseconds. The whole of it is a fraction of a second (measured: 170
milliseconds for a shell that traps the hangup; a shell that takes it
is collected in well under a millisecond), because this runs in a
destructor while the daemon holds its session, and a pane end nobody
asked about must not be something you can feel. A child that will not
go even then is named in the log rather than waited on. The daemon only
ever waits on its own direct children, never on a sweep that could take
an answer meant for something else. A shell handed to a successor
daemon during a live upgrade is untouched, as before: it is no longer
ours to wait on.

### Added: SSH agent auth on Windows, over the named pipe (4 of 4)

Sub-tasks 1 to 3 gave a host its own agent socket, an honest failure
when that agent does not answer, and a Test button that asks it what it
holds. All of it was unix only: on Windows the agent answered "ssh-agent
access is not supported on this platform yet" and there was no agent
authentication at all, so 1Password, the Windows OpenSSH agent and a
hardware key riding either of them were simply not available (board#91).

Windows now speaks the same agent protocol over a named pipe. Identity
listing and authentication are the same code as unix below the
transport: one generic `authenticate_over_agent` holds the identity
loop, the per-identity record in agent order, and the four outcomes,
and the only per-platform part is opening a unix socket or a pipe. No
unix wording changed, because no unix sentence moved.

Which pipe is one pure function, `agent::windows_pipe_name`, compiled
and tested on every platform including the Linux where CI runs: the
host's own socket if it named one, else `SSH_AUTH_SOCK` (some Windows
setups point it at a pipe), else `\\.\pipe\openssh-ssh-agent`, which is
not a question because it is the name the `ssh-agent` service shipped
with Windows serves. A bare name becomes `\\.\pipe\<name>`; anything
already carrying a separator or a drive colon is passed through
verbatim, including a unix-looking path someone pasted in, so a failure
names the string the user actually typed instead of one we invented
around it.

The default pipe answers for itself. A machine that named no socket
and has no `SSH_AUTH_SOCK` reaches `\\.\pipe\openssh-ssh-agent`, and the
likeliest reason nothing answers there is that the `ssh-agent` service
Windows ships is stopped, so that failure is its own origin
(`AgentOrigin::WindowsDefaultPipe`) with its own remedy: start the
service, or name a pipe on this host's card. Blaming `SSH_AUTH_SOCK`
for it would have sent the user to a variable that is unset and had
nothing to do with the pipe that was tried. The pane and the add-host
Test card say the same thing, because both read the same pure rule
(`agent::windows_pipe_source` beside `windows_pipe_name`, one
precedence check so the name and its source cannot drift), and the Test
card on such a machine now heads "no agent at \\.\pipe\openssh-ssh-agent"
rather than naming a variable it never read.

The distinction the whole module exists for holds on Windows too: a
pipe nobody serves is unreachable and names that pipe, a live agent
holding nothing is an empty list, and the two keep their opposite
remedies. A pipe that stays busy is bounded rather than retried
forever, because an SSH connect that never returns is a worse answer
than one that says the agent did not answer.

### Added: the settings vault item and the machine boundary (1 of 4)

Groundwork for carrying appearance profiles, the keymap and the
syncable preferences between an account's machines (board#77).
**Nothing here is reachable by a user yet**: no round runs, no screen
changed, no bytes leave any machine. It is the sealed unit and the
rule, so that the sync, the settings screen and the export in
sub-tasks 2 to 4 have one thing to agree with.

`Item::Settings` (`"type": "settings"`) is a new vault item sealed and
stored exactly like a snippet, carrying the profiles, the default
profile's name, the keybinding map, the preference subset, and the
machine name and unix-millis stamp a last-write-wins resolution needs.
No protocol change and no relay surface: an older client meets a type
it does not know, keeps the blob and reads nothing into it, which is
the contract it already had.

What may be in it at all is one pure function,
`termuna_vault::settings::reach`, the boundary the design writes as a
table and the settings screen will render as a per-row tag. The
default shell path, the window geometry, the history pause switch
(board#48's per machine privacy decision), the font fallback, the
daemon and update settings, everything in `[cloud]`, the
`~/.ssh/config` link, the rest of `[ui]` and the quake hotkey stay on
the machine that set them, and so does a keybinding whose action is
platform specific. A path nobody has classified stays here too: a
setting travels because it was named, never because nobody thought
about it. Such a binding is safe on both sides of the boundary: it
never leaves, and a combo this machine spends on one is never
reassigned by an item that binds the same combo to something syncable.
The desktop's half is `settings_sync`, which builds the item
from `config.toml` and merges one back without ever writing over a
machine-local value; a synced profile naming a font this machine does
not have keeps that font's name, because the substitution is a
render-time fact and not a rewrite of what the user chose.

### Added: a socket field on the host card, and a Test that answers it (3 of 4)

A host could already talk to its own agent, but only if `~/.ssh/config`
said so: nothing in the app let you name one, and nothing let you find
out whether the one you named answers.

The add-host form's Agent choice now carries an optional socket path.
Empty still means `SSH_AUTH_SOCK`, which is what it always was; the
placeholder teaches the common path on this platform (`~/.1password/agent.sock`
on unix, the OpenSSH named pipe on Windows). Next to it, a Test button
asks that socket what it holds and lists the identities in agent order:
key type, the agent's own comment, and the touch a hardware key wants,
taken from the agent's own flag and not from re-reading the name.

The unhappy answers stay apart, because they have opposite remedies. A
socket nobody is listening on is a failure, and it names the path it
tried. A live agent holding zero keys is a warning about the next
connect, not a failure now, and its remedy is to put a key in the
agent. A platform with no agent transport yet says exactly that. The
test never blocks the window: it runs off the UI thread with a 4 second
bound, so a socket that never answers still resolves.

Linked `~/.ssh/config` hosts wear a quiet line when they are different
from the default: `agent · <socket>` when `IdentityAgent` names one,
`agent off · IdentityAgent none` when the file switches it off. Hosts
that say nothing about an agent get no line. The ssh_config read report
gains an `agent sockets` row counting the hosts that named one.

A `~` typed into the field is resolved against this machine's home once,
where the field becomes a stored value, the same shape an imported
`IdentityAgent` path already had. The Test button, the terminal and the
file panel therefore ask the same socket; the field and the host card
still read it back as `~/...`. Before this, the path was stored exactly
as typed and each of the three resolved it for itself, so a Test could
report a live agent holding keys while the file panel on that same host
called the socket dead.

### Added: an SSH agent failure that says which socket and which keys (2 of 4)

When agent authentication failed, the pane could only say the equivalent
of "authentication failed", and every fact that decides the fix was
thrown away with it: which socket was tried, whether the agent even
answered, how many identities it offered, and what the server did with
each one. A dead socket, an agent holding no keys and a server that
refused three good keys read identically and have three different next
steps.

`termuna-ssh` now carries a diagnostic out of agent authentication
(`agent::AgentFailure`: the socket, where it came from, and the
per-identity outcome in agent order) on its own error variant,
`SshError::AgentAuth`, so nothing leaks into the password or key paths,
whose wording is unchanged. `AgentFailure::render` is a pure function
producing the failure text: a quiet trace naming the socket and its
origin (`IdentityAgent` in `~/.ssh/config`, this host's card, or
`SSH_AUTH_SOCK`) and what the agent did, then `authentication failed.`,
then one remedy sentence, different for each of the four cases. Where
identities were refused, every one is listed in the order the agent
offered it, with its type, the agent's own comment and the touch a
hardware key will want:

```
agent ~/.1password/agent.sock (IdentityAgent in ~/.ssh/config) · offered 3 identities · server refused all 3
  ssh-ed25519 · ksoldo@novalabs.dev
  sk-ssh-ed25519@openssh.com · yubikey-5c · touch required
  ssh-rsa · legacy-deploy
then tried: none (no password or key file configured for this host)
authentication failed. The server did not accept any identity from the agent.
Check that one of these keys is in the server's authorized_keys, or add another
method to this host.
```

The text lands where the connect happened. A tab or a split on an SSH
session that fails to authenticate now paints the whole explanation into
its own pane, trace quiet and verdict in warn, instead of being logged
and disappearing; a session that fails to open at all carries the same
lines, with their roles, back to the client, and the cold-start screen
paints them the same way under a heading that names the host rather than
blaming the daemon, which never refused anything. No panel and no modal,
so the chrome is unchanged.

The socket's origin now crosses to the daemon with it, so a host whose
socket was typed on its own card is no longer told to edit an
`IdentityAgent` line that is not in its `~/.ssh/config`, or to unlink a
host that is already unlinked. A session recorded before the field
existed still reads as `IdentityAgent`, which is what the daemon assumed
when it was written.

### Added: a dropped SSH link keeps its pane and dials again (1 of 4)

An SSH pane whose byte stream ended was treated exactly like somebody
typing `exit`: the pane closed, the scrollback went with it, and if it
was the last pane the session ended and was forgotten. A network blink,
a laptop lid or a VPN reconnect was enough. The daemon now tells the
two apart, because they are not the same thing: a remote shell that
finishes says so, with an exit status before the channel closes, and a
link that goes away says nothing at all. Only the second one is dialed
back.

What happens on a drop is that nothing happens to the pane. It keeps
its buffer, its id, its grid and its place in the tree, the session
stays live even when that was its only pane, and the daemon dials the
same host again on the capped backoff the cloud bridge already uses
(1s, 2s, 4s, 8s, then 15s), re-establishing the profile's port forwards
with it. The rule for which targets come back by themselves is the
existing resurrection rule, unchanged: secret-free ones, agent or key
auth. A password target keeps its pane and its scrollback and waits for
a person, and so does one whose host key has changed, which stops after
the first attempt with nothing sent and is never auto-accepted.

The outage is written into the pane's own scrollback rather than drawn
over it: one rule line, rewritten in place as the attempts go by
(`connection lost 13:58:11 · reconnecting, attempt 3 of 8`), and a
second under it when the link is back (`reconnected 13:58:34 · new
shell, 2 forwards restored`). They are terminal content, so they scroll
with the history, sit in the replay log and reach the web viewer and
the phone through the ordinary output stream with no new frame type.
Under the first seam that closes, once per session and never again,
sits the honest sentence: the remote process did not survive the
outage, run inside tmux or screen to keep it. A run that runs out of
attempts settles its line instead (`connection lost 14:20:03 · 8
attempts, gave up 14:22:40`), and a changed host key settles it as
`redial stopped`.

Keystrokes for a pane that is not live are **dropped, never queued**. A
redial gives a fresh shell, and replaying half a typed command into a
new prompt is how somebody runs half of something they meant for
somewhere else. It is enforced at the daemon's single input gate, so
every client inherits it, and viewers see the reason: pane state now
rides in the `Layout` snapshot beside the grid sizes
(live, reconnecting with the attempt and the wait, inert with the last
error, inert with a changed fingerprint), serde-defaulted so older
clients keep parsing and `PROTOCOL_VERSION` stays at 3.

`[ssh] redial = true` and `redial_max = 8` in `config.toml`, on by
default; `redial = false` restores the old close-on-EOF behaviour
exactly. A pane that has gone inert can be dialed again on request
(`MuxRequest::RedialPane`), which is the only way back for a
password-auth target. This is the daemon half; the pane chrome, the web
viewer and the phone follow.

### Added: share links you can take back

The continuity panel handed out one link, the session's own, and there
was no way to say what it could do, no way to say how long it should
last, and no way to stop it afterwards. A link pasted into a chat lived
as long as the session did and typed as freely as you do.

The panel's button is now "Copy view link". One press still copies a
link, and that is the whole common case: view only, good for a day. The
chevron beside it opens the options, where the choice is spelled out
before it is made: "View only. They watch. The relay refuses their
keystrokes." or "View and type. Full input, same as sitting at this
keyboard.", then how long the link works for, 1 hour, 1 day or until
the session ends. The link is minted when you press Copy, never when
you open the options, so browsing them creates nothing.

Every live link is listed under a new "sharing" rule in the same panel:
what it grants ("view only", or "can type" in amber, because that is the
one worth noticing), a Stop button, and the facts that make Stop worth
pressing, "made 1h ago, until session ends, 1 watching", with "nobody
attached" when no one is. Newest first, and "Stop all sharing" under
them. Stopping a link drops anyone attached under it. With no live links
there is no section at all: the panel is exactly what it was.

The list refreshes on the panel's own cloud tick, the one that already
asks who is holding the session, so nothing new polls. The content key
still travels only in the URL fragment and never reaches the relay: a
token takes the session id's place in the link and nothing else about it
changes.

### Added: the app says which plan the account is on

The window knew the account's plan and never said it. Every surface
that could reasonably state it was silent, so the first mention of a
limit was the moment a second live cloud session was refused, which is
the worst place to learn what you are entitled to. The plan is now
ambient in three places, in the same words everywhere, taken from one
shared piece of copy rather than written out per screen: the account
screen states what the plan grants ("1 live cloud session. The
terminal itself stays free forever." on free, the unlimited sentence
and "$6/mo." on Solo) and offers "Upgrade" to a free account and
"Manage" to a paying one; the continuity panel's session facts carry
"free · 1 live session" beside the tab and pane counts, in the same
ink, so the limit is legible long before anything is refused; and the
sessions drawer's account foot prints the plan beside the address,
"nova@orbit.dev · free". The foot has one line of 24 mono characters
to work with, so it shortens the plan rather than the address: the
whole fact if it fits, otherwise the bare plan word, and the address
alone only if not even that fits beside it.

Each plan the relay issues gets its own words, because they do not
cost the same thing and one of them costs nothing. Team reads
"$12/user/mo, billed to the team owner." (a member of a team does not
hold the invoice), and a comped founder account is quoted no price at
all and gets no "Manage" button, because there is no billing behind it
to manage.

Nothing is claimed about a plan the relay has not named. Signed out,
or before the first answer from the account API, none of the three
surfaces prints anything at all, and a paying account that opens the
app offline is never told it is on the free tier. A plan word this
build does not know is treated the same way: the account screen renders
no plan section, the continuity facts line is absent and the drawer
foot falls back to the address alone, rather than printing a word the
app cannot explain or guessing the entitlements behind it.

### Added: `IdentityAgent`, so a host can name its own SSH agent (1 of 4)

Termuna read `~/.ssh/config` and quietly ignored `IdentityAgent`, so a
key kept in a hardware token, in 1Password, in gpg-agent or in any other
per-host agent could not be expressed: every connection went to whatever
`SSH_AUTH_SOCK` happened to point at. The importer now reads the
directive with OpenSSH's own semantics, the first line winning, and
carries it on the saved host, so connecting to that host talks to that
host's agent. The value expands the way ssh expands it: `~`,
`${VAR}` / `$VAR`, and the percent tokens `%d` (home), `%u` (local
user), `%i` (local user id), `%l` (local host name), `%L` (its first
label), `%r` (remote user), `%h` (host), `%n` (the alias as written),
`%p` (port) and `%%`, so the two common dotfile spellings,
`IdentityAgent %d/.1password/agent.sock` and
`IdentityAgent /run/user/%i/gnupg/S.gpg-agent.ssh`, both import as a
socket that actually connects. `%C`, ssh's hash of the connection, is
the one token left as written: its inputs have grown between ssh
releases, so a value computed at import time would quietly disagree
with the ssh the user runs.

Three states, kept apart on purpose: no directive means the
environment's agent, exactly what every existing host already did and
what an older vault keeps doing; a path means this host's own agent;
and `IdentityAgent none` means agent authentication is off for this
host, so the connection falls through to this machine's default key
instead of silently reaching for the environment's agent, which is the
one thing the directive exists to forbid. Both lanes answer such a host
identically now, the terminal and the file panel, and only a machine
with no key either says so, in those words. A re-read of the file
reports a changed `IdentityAgent` beside "new HostName" and "ProxyJump
changed", in the same words.

This is the foundation of "keys that are not on disk": the plumbing and
an API that lists what an agent holds (key type, comment, and whether
the key lives in a security key). Nothing in the UI shows it yet, and
Windows named-pipe agents are still unsupported.

### Added: the app introduces itself on a first run

A brand new install landed in a bare shell and said nothing. Nothing
named session continuity, nothing said an account exists, nothing said
what it costs. The continuity panel now spends the first launch, and
only that one, introducing the feature it is named after: under "this
device / attached now" it draws two rows at rest, "web / after sign in"
and "your phone / after sign in", the shape of the feature before the
account exists, and in place of the share and session sections it says
what continuity is ("Your session survives a closed laptop. Sign in and
it follows you to the browser and your phone.") and what an account
includes ("A free account includes one live cloud session. The terminal
stays free forever, with or without one."). Two actions end it: "Sign
in / create account" opens the sign-in screen, "Not now" is a real
answer.

It is a state of the panel, never a dialog and never over the grid: the
shell is live and typeable from the first frame, and the device list,
the daemon line and the end-to-end-encrypted line stay where they are.
On a window too narrow to pin the panel, the first session summons it
once as an overlay and it never re-opens itself. A launch with nowhere
to put it at all, quake width, or a wide window with the panel
unpinned, shows nothing and loses nothing: it writes
`[ui] first_run_pending = true`, so the `last_session` it records on
exit reads as its own rather than as a previous life, and the intro
waits for a launch with room for it.

Either action writes `[ui] first_run_done = true` (clearing the pending
flag in the same write) and the intro is over
for good, and so does an account arriving any other way: sign in from
the drawer's account foot or from the history palette and the panel
drops to its ordinary signed-in state, share section and all, rather
than going on offering to create the account you just signed into.
Nobody who upgrades ever sees it: the decision is made at
launch, before the app has written anything into config.toml, and any
trace of a previous life counts as done, a stamp, a `last_session` to
come back to that the intro did not write itself, a `[cloud]` block, an
account, or a config file we cannot parse.

### Changed: the sign-in screen says what the account is for

The pitch was one line about syncing across devices that never named
continuity, never said "free" and never said a price. It now tells the
same story /pricing tells: "Your session survives a closed laptop. Sign
in and it follows you to the browser and your phone. A free account
includes one live cloud session to try continuity. The terminal stays
free forever." Under the buttons, one quiet mono fact, not a pricing
table: `Free: 1 live cloud session · Solo: unlimited, $6/mo`.

### Changed: the signed-out continuity panel teaches

Permanently, not only on a first run. The `continuity` rule gains a
subtitle while signed out, "The screens this session is on. Right now:
just this one.", and the share section's passive line becomes "Local
only. Sign in to mirror this session and share it with a link." with a
quiet `Sign in` action under it, so the invitation lives where the gap
is felt instead of three screens away. The signed-in panel is unchanged.

### Fixed: the guard on where the cloud says to connect reads the host

The desktop checks the address `GET /v1/config` hands it and refuses one
that points back at this machine, because such an answer is a
misconfigured proxy talking and believing it stops the daemon bridging
until config.toml is edited by hand. That check was a substring test on
the text of the URL, and text is not a host. It missed three real
spellings of this machine (`[0:0:0:0:0:0:0:1]`, `[::ffff:127.0.0.1]`,
and anything with a userinfo in front of the address, `x@127.0.0.1`),
and it refused two perfectly good public hosts, `localhost.termuna.com`
and `127.eu.termuna.com`, which merely read like loopback.

It now parses the URL and decides on the host as a value: any address in
127/8, `::1` however it is written, the IPv4-mapped forms, the
unspecified addresses, and the name `localhost` exactly. A developer
running the whole stack on localhost is still not overridden, and an
answer that does not parse at all keeps the address we already had
rather than counting as safe. Schemes are checked per key too: the relay
must be `ws`/`wss` and the share base `http`/`https`, so a cloud cannot
hand the daemon an `https://` WebSocket or put a `ws://` address into a
share link. Matches what the phone has done since board#40.

The name is compared rooted or not: `localhost.` with the trailing dot
is the fully qualified spelling of the same name and resolves here, so
one trailing dot comes off before the comparison. Exactly one, so a
public host stays public whether it is written `localhost.termuna.com`
or `localhost.termuna.com.`.

### Added: pull a file back out of the pane (part 3 of 3)

The way in got a way out. Typing `tsz somefile` on the far side is the
native trzsz act, and Termuna now simply answers it: the daemon sees
the helper announce itself on a pane it owns, takes the file over that
pane's own bytes and saves it in this machine's downloads folder, with
the same in-pane progress row a drop draws, wearing the download arrow.
Nothing had to be asked for and no dialog opens. Through a jump chain,
a `docker exec` or a serial console, wherever the shell is.

For a mouse there is the pane context menu. Select something in the
scrollback that plausibly names a path and a `download "<path>"` row
appears directly above `send a file here`, carrying `tsz` as its quiet
right-hand fact the way the other carries `trz`. It is deliberately
strict about what counts as a path, because the row types a command
into your shell: one line, no whitespace, no quotes, nothing a shell
would expand, no URLs, and a `/` or a `.` somewhere in it. The row is
absent when nothing like that is selected, and disabled for a session
whose shells run on another machine, because the file would come back
to that machine and not to this window. The path is quoted for the
remote shell; a leading `~/` is left for the shell to expand and the
rest is still one word.

Nothing in the downloads folder is ever overwritten. A name that is
already taken becomes `crash-0828 (2).log`, then `(3)`, with the number
before the extension so the file still opens in the same program, and
there is no rename prompt: a modal that stole the focus in the middle
of a transfer would be the loudest thing the app does over the least
interesting decision it makes. Instead the settled row names the file
that was actually written, `crash-0828 (2).log  100% · 12.3 MB · saved
to ~/Downloads · 2.1s`, and the status bar echoes it. That row is pane
output like every other one here, so it is in the replay log and every
viewer of the session sees it.

Ctrl+C stops a download and leaves nothing half written behind: the
partial file is removed, and the remote helper is told and exits.
The downloads folder is `XDG_DOWNLOAD_DIR` when the desktop has
recorded one, and `~/Downloads` (`%USERPROFILE%\Downloads` on Windows)
otherwise; it is created if it is not there.

### Fixed: a transfer nobody here started is still yours to stop

A `tsz` typed on the far side was answered by the daemon and moved the
file, but the window knew nothing about it: no progress in the status
bar, no hairline under the row, and ctrl+c went to the shell as a raw
interrupt, so the transfer ended failed instead of cancelled. The
window now asks the file lane about the pane in front of you as well as
about the transfer it started itself, and picks up whatever it finds
there. A session whose shells run on another machine is not asked: the
transfer is that machine's, and its window is already drawing it.

While a file is moving, the pane's bytes are the transfer protocol's,
and a keystroke dropped into them lands in the middle of a chunk and
corrupts the file. The desktop already held its own keys back; a phone
or a web viewer typing into the same session did not, and neither did
this new path. The daemon now holds the pane's input for every client
at once, and lets ctrl+c through to stop the transfer, so a phone can
cancel a transfer the same way the window can.

A cancelled download also reported its bytes as "sent" in the status
bar while the pane's own row correctly said "received". The line does
not carry the direction, so it now says what is true either way:
`transfer cancelled · 4.1 MB moved`.

The running echo had the same problem the other way round: the status
bar drew the upload arrow for every transfer, so a download read
`⇣ big.bin 1%` in the pane and `⇡ big.bin 1%` in the bar an inch below
it. The lane's running state carries the direction now, and the echo
wears the arrow of the file it is echoing. The line in front of it does
too: while a download is still looking for its helper the bar says
`looking for tsz` under the down arrow, not `looking for trz` under the
up one.

### Fixed: a killed session stays killed

A session you ended, by killing it or by exiting its last shell, could
come back. The kill deletes the session's files, but the pane pump was
still draining the output the shell left behind, and its periodic
snapshot wrote both of them straight back a moment later. The next time
the daemon started it offered the session again as dormant and
resurrectable, holding the scrollback of something you had deliberately
finished with, and the sessions on disk grew without bound. It only
happened to sessions that had lived long enough for one snapshot to
run, which is why a quick kill looked fine.

An ended session is now marked as such before its files are removed,
and every writer checks that mark, so nothing can write it again.
Dormant sessions, the ones a restart loads from disk, are untouched:
they are still persisted, and renaming one still survives the next
restart.

### Added: drop a file on the pane (part 2 of 3)

Drag a file onto a pane and it lands in that shell's own directory,
over the shell's own bytes: through a jump chain, a `docker exec`, a
`kubectl exec`, a tmux inside an ssh inside an ssh, anywhere the pane
can reach. Part 1 landed the trzsz engine (ADR 0013); this is the drop,
the routing and the words.

The pane under the pointer wears the scrim while a drag hovers it:
dashed mint on the live-dim tint, no glow, printing what is being
dropped and the shell's current `user@host:cwd` taken from the prompt's
own title, so a person four hops deep sees that the file lands inside
the container and not on the jump host. Several files queue in the
order they were dropped and the scrim counts them with their total
size. A dropped directory is refused as one status-bar line: trzsz
moves files, and saying so beats zipping something in silence.

On drop the daemon types `trz` and watches for the helper. The promise
is that a drop either transfers or explains itself within two seconds:
when no helper answers, the daemon writes the card into the pane's own
output, the way the progress row goes there, so it sits under the
shell's last line in the scrollback flow, scrolls away with it, is in
the replay log and reaches every viewer of the session. One sentence,
the install command as selectable text, and the reminder that the vault
SFTP drawer still serves saved hosts. Nothing is drawn over the pane;
the status bar carries the same fact in four words while it is fresh.
A drop that ended, however it ended, never holds the pane: install the
helper the card asks for and drop again, immediately.

While a transfer runs the pane's bytes are the protocol's, so they
reach the engine and nothing else, not the grid, not the mirrors, not
the replay log. In their place the daemon writes the progress row where
trzsz would have drawn its own bar: name, percent, rate, bytes, time
left and "ctrl+c cancels", one line of terminal text that scrolls with
the buffer, survives a detach and reaches every viewer of the session.
The desktop adds the 2px hairline fill under it and echoes the same
fact in miniature in the status bar, which disappears with the
transfer. Ctrl+C stops it and the row collapses to what had moved; a
finished file settles to its name, size, `md5 ok` (the checksum trzsz
actually exchanges) and how long it took.

The pane context menu gains "send a file here" between the edit verbs
and the quiet-watch rows, with `trz` as its quiet right-hand fact: the
file picker, then the same path a drop takes. Nothing new crosses the
wire for any of it: the lane is three requests on the local socket and
the transfer is pane bytes, so the relay is untouched and
`PROTOCOL_VERSION` stays 3. Downloads (`tsz` typed on the remote) are
part 3.

### Added: command history across your machines (part 4 of 6)

What part 1 records and part 2 searches now reaches the account's other
machines, for an account on a paid Termuna Cloud plan (design v1,
screens a and c; the endpoints shipped in part 3). Every five minutes,
in the background and never in the input path, the desktop carries the
records it has not sent yet to the account's sealed store and fetches
what the other machines put there. The palette then searches both as
one list: a row from elsewhere carries that machine's name in its fact
line, and with more than one machine the chips become "all machines"
and one per machine, this one first, which tab walks through.

The records are readable on another machine because they are re-sealed
for it before they leave. The local store's key is this machine's own
and never leaves it, so a sync opens each record here and seals it
again with the account's history key, derived from the account's
personal vault key (SHA-256 over a domain string and that key), which
every machine on the account reaches by unlocking the vault once and
nobody else ever holds. The server stores an opaque base64 blob it
cannot read, beside the routing metadata that crosses in the clear (a
record id, the name of the machine that recorded it and the time it was
recorded, which is what lets a machine fetch the others' records and
label them), and what comes back is sealed again with this machine's
key before it touches disk. A record this account's key does not open
is counted in the log and dropped, never shown: a palette row of
ciphertext would be worse than no row. A machine that has not unlocked
the account vault yet has no key to seal with and syncs nothing.

Offline-first, and no duplicates. How far the local store has been
pushed and how far the server's own sequence has been consumed are
written to disk after every batch and every page, so a restart resumes
instead of re-uploading; a record id is stable and never recycled, so a
batch whose answer was lost can be sent again and the server no-ops it.
Failing to reach the cloud costs nothing: capture goes on, the queue
drains on the next round, and the palette says "offline · other
machines as of 12m ago" under the chips rather than showing a spinner
or an error. Stale beats absent. The age is only ever a round that
reached the cloud: one that reached nothing leaves it where it was and
says offline, at launch as well, so a window never claims a sync it did
not make.

A free or signed-out account makes no history network calls at all.
The plan is read from the account (`/v1/auth/me`) and cached beside the
account's name and picture, so a paid account launching with no network
is still told what it pays for instead of being shown the free tier's
hint until the network answers. The cached plan is more than wording:
it is what keeps a paid account's queue draining while the profile call
goes unanswered, and an account whose plan has since been downgraded is
refused by the server itself. The free tier is never asked a question
it would have to refuse; if the server refuses anyway, the answer is
taken as an answer: 403
`history_sync_requires_cloud` silences the sync for six hours, 409
`history_quota_exceeded` for an hour, and the palette's existing Cloud
hint stays the only place any of it is ever said to a person. A record
the server refuses as too large (413) is parked by id and skipped for
good, so one command line cannot hold up the queue.

Settings, Terminal grows the sync facts beside the capture switch: on
or off with the plan, how old the other machines' half is, and what
exactly leaves this machine (the sealed records only, ciphertext the
server cannot read). "Delete all history" now takes back the cloud copy
too, and the copy the other machines sent; the pull cursor deliberately
survives it, so what was deleted is not fetched straight back. Signing
out forgets the account history key, which ends the sync where it
starts. docs/design/termuna-ui-v6.html gained the signed-in palette
card and the sync settings row. Web and phone follow in their own
parts.

### Added: ctrl+r, the command history palette (part 2 of 6)

The recall surface for the history the daemon has been capturing since
part 1 (design v1, screens b and d). ctrl+r over any pane opens a
palette in the ctrl+k language, taller: a search row, the scope chips,
and one row per command, the line itself with the query's hits painted
mint over one quiet fact line: machine, host when the command ran over
SSH, directory, exit status as a mono glyph (mint 0, warn otherwise,
nothing when unknown) and age. Typing filters live across the command,
the host and the directory; up and down move, Enter types the
highlighted command at the focused pane's prompt with its trailing
newline stripped, the way a snippet is inserted, and never runs it,
which the foot says in as many words; esc closes and the pane has the
keys again. An empty query lists the focused pane's own host first,
newest first, under "here" and the rest under "elsewhere", so "what did
I just run here" costs zero typing; a typed query is grouped by age. A
repeated command shows once, as its newest run, and a list longer than
a hundred rows says how many it is not showing. The chips narrow: this
machine (the one machine there is until sync arrives), this directory
(the pane's, once a command has been recorded from it) and failed only.
Pressing ctrl+r again while the palette is open closes it and hands the
key to the shell, whose own reverse search it always was; the foot says
so for the first three opens. ctrl+shift+f scrollback search is
untouched: that is "what did it print", this is "what did I run".

The store is read the way the data export reads it, with this
machine's vault key, off the UI thread, so nothing waits on the disk;
the palette then tells the truth about what it found: nothing recorded
yet, recording paused (with the switch one press away, and the same
fact under the chips when there are records to show), or the store
sealed because the vault key did not open it. While signed out the list
ends with one bordered sentence naming what Cloud adds (history from
your other machines, search from your phone), with a link to the
account screen and nothing else. The status bar's one-time line now
reads "history on · ctrl+r searches it · settings to turn off", as the
design wrote it. docs/design/termuna-ui-v6.html gained the ctrl+r
exhibit with the three empty states. Cloud sync, web and phone follow
in their own parts.

### Added: the trzsz engine (drop-a-file, part 1 of 3)

The client half of the trzsz protocol, as a library: `termuna-transfer`
(board#63, ADR 0013). A `trz` or `tsz` run on the far side of any pane,
through a second `ssh`, a `docker exec`, a jump chain the vault never
knew about, prints one trigger line, and the engine moves files over
that pane's own bytes: no second connection, no new credential, and
for a mirrored session nothing new for the relay to see, since
transfer bytes are pane bytes. The daemon's output scanner, the one
that already hears bells and OSC notifications, now also recognises
the trigger, split across reads or not, and ignores a redraw of an old
one. The engine receives what `tsz` sends and sends what `trz` asks
for, in text and binary mode, with the protocol's per-file MD5 checked
and its stop-and-wait acknowledgements, and reports as it goes:
detected, started, progress with a rate, done with the checksum and
time, failed with a typed reason, or cancelled with what had moved.
Cancel tells the helper to stop so it exits cleanly and prints
"Stopped" in the pane; a helper that goes quiet is a typed timeout,
never a hung pane; a directory transfer or a helper on Windows is
declined so the helper prints "Cancelled" and leaves. A probe types
the helper command and says within two seconds whether a helper is
there at all. Names the remote proposes are checked before anything is
written, and a half-written file is removed on failure. Nothing in the
window uses it yet: the drag-and-drop upload and the download flow are
parts 2 and 3. TSP is untouched. Verified end to end against trzsz-go
1.2.0 in a PTY (`cargo test -p termuna-transfer --test live`, which
skips itself when the helpers are not installed).

### Added: chunked transfers on the file-ops lane (sftp-follows-session, part 2 of 4)

Files now move over the same sealed lane part 1 opened (board#32): get
and put, as a sequence of chunks with explicit offsets, so a
multi-gigabyte file streams instead of being buffered whole anywhere.
`Get` or `Put` opens a remote handle the daemon keeps beside the
session's existing SFTP connection and names it; `Read` or `Write`
moves one 256 KiB chunk at a stated offset; `Close` finishes and says
what moved; `Cancel` abandons. No second connection per transfer, and
no new frame: the new operations ride the same `DaemonQuery::FileOp` as
the directory ones, so bytes and paths still exist only inside
ciphertext and the relay is neither changed nor rebuilt.

The chunk size and a cap of eight transfers in flight per daemon are
the app's memory budget written down: a chunk exists in a few copies as
it crosses the daemon, and 256 KiB is what one SFTP round trip carries
on OpenSSH, so a smaller chunk would only buy round trips and a larger
one only memory. Past the cap the answer is `TooManyTransfers`.

Cancel is terminal and idempotent: the remote handle is closed, a
half-written upload is deleted, the transfer is forgotten, and a
transfer the daemon no longer holds answers the same way, so a client
can always send it on the way out. Nothing is left behind on any exit
path: an end-of-file read closes the handle by itself, an abandoned
transfer is closed after two minutes of quiet, and a connection that
dies takes its transfers with it. An interruption is typed and carries
how far it got (`Interrupted{done, cause}`); nothing resumes one yet,
but every chunk states its offset so a resume stays possible later.

Progress is derivable from the replies, with no push channel invented
for it: a download learns its total at open, an upload knows its own,
and both learn their position from the offsets that come back. The
desktop drives all of it through `termuna-mux::transfers`
(`download`/`upload` over a `FileLane`, a `Cancel` handle, `Progress`
per chunk, sinks and sources for memory or a local file); no UI in this
part, the dashboard pane and the mobile mode are parts 3 and 4.
docs/PROTOCOL.md documents the operations, the caps, the cancel
semantics and the error cases; `PROTOCOL_VERSION` stays 3 (additive:
an older daemon simply never answers, which a client already reads as
offline). Verified against a live sshd, a file of two and a half chunks
in both directions compared by SHA-256:
`cargo test -p termuna-mux --test file_ops -- --ignored`.

### Added: the file-ops lane (sftp-follows-session, part 1 of 4)

The wire foundation for browsing a session's files from the phone and
the browser (board#32). A client that can see a session can now ask the
daemon that owns it for directory operations on the host behind it:
list (name, kind, size, mtime, mode), stat, mkdir, rename and remove.
The request is a new question in the existing sealed `Query` lane
(`DaemonQuery::FileOp`, answered with `DaemonReply::File`), so paths and
names only ever exist inside ciphertext, and the relay is neither
changed nor rebuilt: it forwards the same opaque frame it always has.
The daemon resolves the session to the SSH target its vault profile
became, opens one SFTP connection on the existing engine (same auth,
jump chain and trusted host keys as the shells) and keeps it for two
minutes of quiet, so a browse is not one SSH handshake per click; a
mirror of another machine's session forwards the question to the
machine that runs it. Errors are typed, because a browser shows them
differently: not found, permission denied, no SSH host for this session
(a local shell), unknown session, and the daemon not answering. The
desktop reaches it through `MuxConn::file_op` over the local socket;
nothing in the window uses it yet. Transfers, the dashboard files pane
and the mobile files mode are the next three parts. docs/PROTOCOL.md
documents the payloads; `PROTOCOL_VERSION` stays 3 (additive).

### Added: command history capture in the daemon, sealed on this machine

The first part of cross-machine command history (design v1, board#16).
The daemon now records every command line entered into a pane, local
shells and SSH panes alike, with the time, this machine's name, the SSH
host when there is one, the working directory when known and the exit
status when the shell reports one (OSC 133; otherwise "unknown", which
is a valid answer). No shell hooks and nothing installed on remote
hosts: the command is read off the terminal's own echo by a small
per-pane line model in the session pump, so readline editing, history
recall and completion all give the line the shell actually ran. A line
that starts with a space is not remembered, the shell's own convention.
On Linux the terminal's foreground process group decides whether a
keystroke went to the shell or to a program, so typing into vim, a
REPL or a password prompt is never recorded; elsewhere the prompt has
to look like one. Nothing sits in the input path: the only
per-keystroke cost is one channel send, and the record is built,
sealed and written on other threads.

Every record is sealed on its own with the connection vault's
machine-local key through the versioned TSP seal (leading format byte)
before it touches disk, into an append-only store under the app data
dir (history/commands.seal, its own file: the relay's frame log is not
reused, and ctrl+shift+f scrollback search is untouched). Records are
self-contained so a later cloud sync can carry them as opaque sealed
blobs; an exit status that arrives after the record was written rides
as an amendment record that readers fold in.

Settings, Terminal grew the capture block: one sentence saying what is
recorded, the switch (pause recording on this machine; the store
stays), Export (the data export now carries the history stream, sealed
in the archive and as plain rows in the readable JSON) and Delete all
history, which asks once inline and then empties the store, with the
custody sentence as one quiet fact under it. Recording is on by
default, for new and existing installs, and announces itself once: the
first time this machine records a command the status bar shows
"history on · settings to turn off"; pressing it opens the setting, and
after that run of the app the line never returns (the seen flag is
persisted under [ui]). The daemon reads [history] record at start and
the running one is told over the socket, so the switch is immediate.
docs/design/termuna-ui-v6.html shows the block (Settings, Terminal) and
the status line. The ctrl+r palette, cloud sync, web and phone follow
in their own parts.

### Added: snippets in the encrypted vault (2/4: capture from a selection, insert at the prompt)

The two doors the snippets screen promised. Capture: the pane context
menu grows "save as snippet", directly under copy/paste and only while
text is selected in that pane (no disabled row without one); it opens
the snippet editor pre-filled with the selection as the command, under
the subtitle "Taken from your selection in <session> · pane <n>", and
nothing is saved until the card says so. Insert: ctrl+k gains a
"snippets" section between the actions and the sessions (the five most
recently used on the front page, all of them once you type), found by
name, command text and note alike with the palette's own matcher;
Enter types the highlighted snippet at the focused pane's prompt and
never runs it, which the row says beside the return glyph ("insert")
and the footer repeats ("insert at prompt"). A multi-line snippet
inserts as its typed lines with the trailing newline stripped, so the
last line waits at the prompt; the text goes the way a paste does,
bracketed when the program asked for it, to every broadcast target.
With a management view or settings open over the grid there is no
prompt in sight, so the rows stay, dimmed, with the meta "no focused
pane", and Enter leaves the palette open. On the snippets screen,
pressing a row now inserts through the same path and puts the grid
back so the typed command is in view; the pencil at the row's right
edge opens the editor instead. Every insert, from the palette or the
screen, stamps the snippet's last-used time, which both surfaces sort
and display by. The snippets screen's search box uses the palette's
matcher too, so the same words find the same rows in both places.
docs/design/termuna-ui-v6.html shows the menu item and the palette
section.

### Added: snippets in the encrypted vault (1/4: item type, screen, editor)

Saved commands now live in the vault beside the SSH hosts. A snippet is
a name, the command text (multi-line allowed), an optional note on when
it is safe to run, and a last-used timestamp; it is sealed exactly like
a host, in the same local vault file, and the existing cloud vault sync
carries it with no relay, API or protocol change. The item plaintext is
now a documented contract (termuna-vault crate docs): a host is the
profile JSON it always was, a snippet carries "type": "snippet", and a
client that meets a type it does not know skips the item and leaves it
in the cloud, so a phone that has not learned snippets yet cannot lose
them. The desktop grows a "snippets" entry in the drawer nav (between
ssh and settings, with a live count), a management screen in the centre
column with search, a "personal" section that mirrors the ssh screen,
two-line rows (name, line count, last used, the command's first line,
the note), a first-run card, and one editor card for new and edit with
name, command, optional note and nothing else. The foot line states
the boundary instead of selling past it: signed in, "Synced to your
vault, end to end encrypted" with the item count and sync age; signed
out, a quiet lock and "Stored in this device's vault only" with a
link to Termuna Cloud. The promise the feature rests on is on the
screen: a snippet only ever types itself at your prompt, it never runs
on its own. Inserting, saving a selection and the ctrl+k section are
the next three parts. docs/design/termuna-ui-v6.html gains the nav
entry and the screen (?v=snippets, ?snippets=empty|local).

### Added: "Export your data", one palette command, one local archive

The pricing page has promised full data export at every tier, and the
cloud half shipped (GET /v1/export, the dashboard's "your data" rows,
docs/export); the free desktop had no export surface at all. Ctrl+K now
finds "Export your data" (the palette is the only door: no menu entry,
no settings row), and one modal writes everything this machine holds,
the persisted session trees and output logs plus the SSH connection
vault through its existing export_json(), into
~/termuna-export/termuna-export-YYYY-MM-DD.tar.gz, in the same layout
/v1/export serves so one spec describes both. Signed in, the same
command also fetches the cloud archive and puts it beside the local
half; a cloud fetch that fails degrades the export to local only, it
never aborts it. Two honest options, the dashboard's own split: Archive
(sealed), where history frame content keeps its TSP envelope and is
sealed (versioned seal format) under the machine-local vault key that
never leaves the machine, so the archive is safe to store anywhere; and
Readable JSON, decrypted here with those same local keys, terminal
history reassembled per pane, never uploaded. Signed out is a complete
flow, not a degraded one: local scope, one quiet hint, no upsell. The
export runs off the UI thread and shows as one status bar fact with a
small bar ("exporting N/M sessions"), never a progress modal; when it
finishes the modal returns once, as a done card (path, size and counts,
sha256, Reveal in folder as the primary action) or wearing a red band
that names the real cause and the failing path. The write is atomic, a
.partial file renamed only once complete, so "Nothing partial was left
behind" is literally true. Session content keys (cloud_key, share-link
fragments) stay on the machine in every mode.

### Added: ~/.ssh/config can stay linked, not just imported once

The one-time import grew into linked mode. "Link ~/.ssh/config" (the
empty hosts screen's primary action, the ssh screen's bar while
unlinked, and the command palette) reads the file and answers with a
report card instead of a bare count: imported, updated and skipped,
with every skipped block named with its reason (wildcard patterns,
negations, Match conditionals) and every followed Include listed.
Choosing "Keep linked" makes the file the source of truth for those
hosts: Termuna watches it (plus its Includes, a light 3s mtime poll)
and reflects edits silently into the encrypted vault; every device
inherits the result through vault sync. Linked hosts live in their own
section under a rule naming the file and its last-read time, with
"Re-read now" and "Unlink" beside it, and each card wears a small link
glyph; a host just changed by the file says "updated from file" as
quiet text on the card. A host removed from the file is never deleted
silently: its card turns to an amber keep-or-delete decision and stays
connectable until answered. Editing a linked host is redirected where
the rule applies: its menu offers Connect, "open ~/.ssh/config" (at
the host's own line) and "unlink this host" instead of Edit, and a
manual host with the same alias is never overwritten. If the file
becomes unreadable, a red banner keeps the facts straight (hosts
frozen at last read, connections unaffected) and the watch resumes by
itself. The parser also stopped leaking Match-block options onto the
previous Host block and now follows Include directives (globs,
cycle-guarded). `[vault] ssh_config_linked` persists the choice; the
old bordered import note is gone.

### Added: the plan's live-session limit refusal is said, not swallowed

When the relay refuses a session a live cloud slot (WebSocket close
4403, `live_session_limit`), the desktop used to treat it like any
dropped connection: a silent reconnect loop, with the user never told
the session was not syncing. The daemon now parses the structured
refusal and broadcasts a new additive TSP payload (`LiveLimit`, local
viewers only, never relayed) carrying the plan and its limit, and the
app shows a one-line notification bar above the status bar: "This
session stays local. Your plan allows 1 live cloud session and
"~/work" is using it. Upgrade to Solo for unlimited." (the holding
session is named when this daemon knows it; paid plans are named
outright). Upgrade opens the dashboard's billing with the checkout
intent, x dismisses, and a dismissed refusal stays dismissed: the
daemon re-announces on every retry and the bar does not come back for
the same session. Nothing modal, nothing glows, typing is never
interrupted. The bridge also stops hammering a deterministic refusal:
a limit rejection goes straight to the backoff cap (60s) instead of
retrying at 1s, while still retrying at all so a freed slot or an
upgrade takes effect without a daemon restart.

### Fixed: a click on a menu card's own quiet pixels dismissed the menu

Every floating menu sits over a transparent backdrop that closes it on
a stray click, and iced's stack only shields the backdrop where the
layer above is interactive. A press on the card's inert pixels - a
title, a note, a separator, the padding around a row - fell straight
through and dismissed the menu the user was aiming at; the quiet-watch
condition card, being mostly explanation, was nearly unclickable. The
card is now opaque to the pointer as a whole: presses inside it land
on it, presses beside it still close it.

### Added: "Notify when this quiets down", per pane, once

Right-click the pane running the long command and pick when to be
told: when the prompt returns (the default), after 30 seconds of
silence, or on bell (BEL / OSC 9/777). The watch lives in the daemon,
so it works over SSH with zero remote-host setup, and it is one-shot:
it fires once, only if you are not looking at the pane, then disarms.
Armed, the pane wears a small mono corner tag, its tab an at-rest ink
bell, and the status bar counts the session's watches ("1 armed"); on
fire the desktop notification carries facts only - pane, condition,
duration, never a line of output - and the tab's bell turns attention
amber until the pane is viewed. The armed state is shared over the
wire (new additive TSP payloads: `ArmQuietWatch`, `DisarmQuietWatch`,
`QuietWatchArmed`, `QuietWatchDisarmed`, `QuietWatchFired`), and the
fired frame relays through the cloud exactly like `Attention`, so the
server-side push can reach a phone; the payload is metadata the relay
may see, never terminal content. If the cloud is unreachable at arm
time the menu says so in amber: arming never fails, only the push
lane degrades. The global `notify_when_done` setting is untouched.

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

[Unreleased]: https://github.com/termuna/termuna-desktop/compare/v0.2.5...HEAD
[0.2.5]: https://github.com/termuna/termuna/releases/tag/v0.2.5
[0.2.4]: https://github.com/termuna/termuna/releases/tag/v0.2.4
[0.2.3]: https://github.com/termuna/termuna/releases/tag/v0.2.3
[0.2.2]: https://github.com/termuna/termuna/releases/tag/v0.2.2
[0.2.1]: https://github.com/termuna/termuna/releases/tag/v0.2.1
[0.2.0]: https://github.com/termuna/termuna/releases/tag/v0.2.0
[0.1.0]: https://github.com/termuna/termuna/releases/tag/v0.1.0
