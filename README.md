# Doom Emacs config

Moving to a new machine:

```bash
# one-time system packages (need sudo)
sudo apt install build-essential git autoconf texinfo libgtk-3-dev libgnutls28-dev \
  libtree-sitter-dev libjansson-dev libgccjit-dev libmagickwand-dev libxpm-dev \
  libjpeg-dev libgif-dev libtiff-dev librsvg2-dev libsqlite3-dev unzip curl

git clone <this-repo-url> ~/.config/doom
~/.config/doom/bootstrap.sh
```

`bootstrap.sh` builds Emacs 31, installs Doom, fonts, rg/fd, language servers and tree-sitter
grammars, then runs `doom sync`. Safe to re-run.

Files: `init.el` (modules), `packages.el` (extra packages), `config.el` (all custom behaviour),
`bin/typescript-language-server` (Node >= 20 wrapper), `ts-grammars.el` (grammar builder).
Also install Rust (rustup), Node (nvm) and a JDK 21+ yourself.
Copilot CLI (`copilot`) must be on PATH for `SPC o c`.

## Appearance and Git layout

The local `themes/doom-jetbrains-theme.el` supplies charcoal editor/sidebar
backgrounds, restrained syntax colors, flat tabs, and green/red diff highlights.
Code uses JetBrains Mono 14; interface text uses Noto Sans 13.

`M-x magit-status` opens a changes sidebar on the left. `RET` on a tracked change
opens its syntax-highlighted diff in a separate, reusable native window; untracked
files open in the editor. Commit-message buffers appear below the changes list.
`q` closes the diff window and returns to its originating window, or closes the
status sidebar when used there. Standard Magit staging and commit commands remain
available.

Restart Emacs after applying these settings; no `doom sync` is needed for changes
to `config.el`, `magit-frame.el`, or the local theme.

## Custom keybindings

| Keys | Action | Where |
|------|--------|-------|
| `SPC o c` | Copilot CLI (agent-shell) | global |
| `F8` | Toggle Treemacs | global |
| `C-<next>` / `C-<tab>` | Next tab (centaur-tabs) | global |
| `C-<prior>` / `C-S-<iso-lefttab>` | Previous tab | global |
| `RET` | Open changed-file diff in a separate native window | Magit status |
| `q` | Close diff window / quit status sidebar | Magit |
| `C-c h` | Show Rust docs in popup near cursor (eldoc-box) | rust-mode / rust-ts-mode |
| `C-S-t t` or `C-S-t C-S-t` | Go to implementation (Eglot) | rust-mode / rust-ts-mode |

Doom defaults used with Rust/Eglot: `gd` definition, `gD` references, `gI` implementation, `K` docs.
