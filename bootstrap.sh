#!/usr/bin/env bash
# Sets up this Doom Emacs config on a new Linux machine. Idempotent; no sudo needed
# except for the apt packages listed in README.md (install those first).
set -euo pipefail

CFG="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="$HOME/.local/bin"
SHARE="$HOME/.local/share"
mkdir -p "$BIN" "$SHARE/fonts"
export PATH="$BIN:$PATH"

step() { printf '\n==> %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

step "Emacs 31 (built from source into ~/.local)"
if ! have emacs || ! emacs --version | head -1 | grep -q ' 31\.'; then
  mkdir -p "$HOME/src" && cd "$HOME/src"
  [ -d emacs ] || git clone --depth 1 --branch emacs-31 git://git.savannah.gnu.org/emacs.git
  cd emacs && ./autogen.sh && ./configure --with-imagemagick --prefix="$HOME/.local" && make -j"$(nproc)" && make install
fi

step "Doom Emacs"
if [ ! -d "$HOME/.config/emacs" ]; then
  git clone --depth 1 https://github.com/doomemacs/doomemacs "$HOME/.config/emacs"
  "$HOME/.config/emacs/bin/doom" install --force --no-config
fi

step "Fonts"
if ! fc-list | grep -qi 'JetBrains Mono'; then
  curl -sL -o /tmp/jb.zip https://github.com/JetBrains/JetBrainsMono/releases/download/v2.304/JetBrainsMono-2.304.zip
  mkdir -p "$SHARE/fonts/JetBrainsMono"
  unzip -oj /tmp/jb.zip 'fonts/ttf/*.ttf' -d "$SHARE/fonts/JetBrainsMono" >/dev/null && rm /tmp/jb.zip
fi
if ! fc-list | grep -qi 'Symbols Nerd Font'; then
  curl -sL -o /tmp/nf.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/NerdFontsSymbolsOnly.zip
  unzip -oj /tmp/nf.zip '*.ttf' -d "$SHARE/fonts" >/dev/null && rm /tmp/nf.zip
fi
fc-cache -f

step "CLI tools (ripgrep, fd) via GitHub releases"
if ! have rg; then
  url=$(curl -s https://api.github.com/repos/BurntSushi/ripgrep/releases/latest | grep -o 'https://[^"]*x86_64-unknown-linux-musl.tar.gz' | head -1)
  curl -sL "$url" | tar xz -C /tmp && cp /tmp/ripgrep-*/rg "$BIN/"
fi
if ! have fd; then
  url=$(curl -s https://api.github.com/repos/sharkdp/fd/releases/latest | grep -o 'https://[^"]*x86_64-unknown-linux-musl.tar.gz' | head -1)
  curl -sL "$url" | tar xz -C /tmp && cp /tmp/fd-*/fd "$BIN/"
fi

step "Language servers"
have rustup && rustup component add rust-analyzer rust-src || echo "rustup not found; install Rust first"
if [ ! -e "$SHARE/tsls/node_modules/.bin/typescript-language-server" ] && [ ! -e "$SHARE/tsls/bin/typescript-language-server" ]; then
  mkdir -p "$SHARE/tsls" && (cd "$SHARE/tsls" && npm init -y >/dev/null && npm i typescript typescript-language-server)
fi
ln -sf "$CFG/bin/typescript-language-server" "$BIN/typescript-language-server"
if [ ! -d "$SHARE/jdtls" ]; then
  mkdir -p "$SHARE/jdtls"
  curl -sL https://download.eclipse.org/jdtls/snapshots/jdt-language-server-latest.tar.gz | tar xz -C "$SHARE/jdtls"
fi
ln -sf "$SHARE/jdtls/bin/jdtls" "$BIN/jdtls"

step "Doom sync"
"$HOME/.config/emacs/bin/doom" sync

step "Tree-sitter grammars (pinned for Emacs 31.1.50 ABI)"
emacs --batch -l "$CFG/ts-grammars.el"

step "Done. Start with: emacs --daemon && emacsclient -c"
