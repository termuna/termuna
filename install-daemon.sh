#!/usr/bin/env sh
# Install the Termuna daemon on a machine with no screen.
#
#   curl -fsSL https://raw.githubusercontent.com/termuna/termuna/main/install-daemon.sh | sh
#
# It pulls the binary from the latest GitHub release, which is where the
# binaries actually are. An earlier draft of this script invented a
# termuna.com/dl that nothing has ever served, and pointed the install
# instructions at it too.
#
# Installs per-user into ~/.local/bin, joins the machine to an account,
# and starts it as a user service that survives logout. No root, and
# nothing outside your home directory.
set -eu

BASE=${TERMUNA_DOWNLOAD:-https://github.com/termuna/termuna/releases/latest/download}
BIN="$HOME/.local/bin"
UNITS="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"

# Only what the release actually carries. Listing aarch64 here would
# turn "we do not build that yet" into a 404 halfway through an install.
case "$(uname -s)-$(uname -m)" in
  Linux-x86_64) TARGET=x86_64-unknown-linux-gnu ;;
  *) echo "no daemon build for $(uname -s)-$(uname -m) yet" >&2; exit 1 ;;
esac

echo "==> fetching termuna-daemon ($TARGET)"
mkdir -p "$BIN"
curl -fsSL "$BASE/termuna-daemon-$TARGET" -o "$BIN/termuna-daemon.new"
chmod +x "$BIN/termuna-daemon.new"
mv "$BIN/termuna-daemon.new" "$BIN/termuna-daemon"

# The daemon has to outlive the SSH session that installed it, or the
# sessions it holds die at logout and the machine stops being a device.
if command -v loginctl >/dev/null 2>&1; then
  loginctl enable-linger "$(id -un)" 2>/dev/null ||
    echo "    (could not enable lingering; sessions will end at logout)"
fi

# Written here rather than fetched: it is twenty lines, and a second
# download is a second thing that can 404 in the middle of an install.
if [ ! -f "$UNITS/termuna-daemon.service" ]; then
  echo "==> installing the user service"
  mkdir -p "$UNITS"
  cat > "$UNITS/termuna-daemon.service" <<UNIT
[Unit]
Description=Termuna session daemon
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=%h/.local/bin/termuna-daemon run
Restart=always
RestartSec=3
Environment=RUST_LOG=info
KillMode=mixed

[Install]
WantedBy=default.target
UNIT
  systemctl --user daemon-reload 2>/dev/null || true
fi

if "$BIN/termuna-daemon" status | grep -q "^not joined"; then
  echo "==> joining this machine to your account"
  "$BIN/termuna-daemon" login
fi

echo "==> starting"
systemctl --user enable --now termuna-daemon 2>/dev/null ||
  echo "    no systemd here; run '$BIN/termuna-daemon run' yourself"
"$BIN/termuna-daemon" status
