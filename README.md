<p align="center">
  <img src="assets/moonmark.png" width="76" alt="Termuna: the moon cursor">
</p>

<h1 align="center">Termuna</h1>

<p align="center">A fast, lightweight terminal whose sessions follow you everywhere.<br>
One session. Every screen.</p>

<p align="center">
  <a href="https://github.com/termuna/termuna/releases/latest"><strong>Download</strong></a> ·
  <a href="https://termuna.com">termuna.com</a> ·
  <a href="https://termuna.com/docs/">Documentation</a> ·
  <a href="https://github.com/termuna/termuna/issues">Issues</a>
</p>

---

## What is Termuna

A GPU-rendered terminal for Linux, Windows, and macOS built around one
idea: your live sessions - tabs, splits, scrollback, running programs -
should survive the window, the reboot, and the machine. Sessions mirror
end-to-end encrypted to Termuna Cloud, so you can continue them from a
browser or phone while the host is up. The relay never sees plaintext.

- Cold start under 300 ms, idle under 100 MB, keystrokes under 20 ms.
- Local terminal is free forever, works fully offline, no account.
- Cloud continuity is the paid part - and export is never held hostage.
- SSH built in: profiles in an encrypted vault, shareable with your
  team (also end-to-end encrypted; the server stores only ciphertext).

## Downloads

Grab the latest from the
[releases page](https://github.com/termuna/termuna/releases/latest):

| Platform | File |
|---|---|
| Windows 10/11 (x64) | `termuna-setup-<version>-x64.exe` - per-user installer, no admin needed |
| Linux (x86_64) | `termuna-<version>-linux-x86_64.tar.gz` |
| macOS (Apple silicon) | `Termuna-<version>-arm64.tar.gz` - unzip into `~/Applications` |
| Any machine with no screen | `termuna-daemon-<version>-<target>` - see below |

### A machine you never sit at

A server can hold sessions too. `termuna-daemon` is the same daemon the
app runs, without the window: 10MB instead of 32, no GPU stack, no
display. Join it to your account and it appears beside your laptops,
ready to start sessions on, whether or not anything is running on it.

```sh
install -m755 termuna-daemon ~/.local/bin/
TERMUNA_TOKEN=<a token this account already has> termuna-daemon login
systemctl --user enable --now termuna-daemon
```

The desktop app needs none of this: it starts and owns its own daemon,
as it always has.

## About this repository

This is Termuna's public home for **issue tracking and releases**. The
source code is developed in a private repository while the product is
in early access. Bug reports, feature requests, and questions are very
welcome here - the
[issue tracker](https://github.com/termuna/termuna/issues) is read
daily.

For anything security-sensitive, please mail
[security@termuna.com](mailto:security@termuna.com) instead of opening
a public issue.
