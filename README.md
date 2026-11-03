# Doom Emacs config

This repository is the Doom user configuration (`$DOOMDIR`), normally stored at
`~/.config/doom`. The modules, packages, keybindings, local theme, Magit layout,
and setup scripts are tracked in Git and transfer with a clone.

## Set up another machine

The bootstrap recipe targets Debian/Ubuntu-style **x86_64 Linux**; its ripgrep
and fd downloads are architecture-specific. Use the paths below, and back up any
existing Emacs/Doom configuration before installing.

```bash
# one-time system packages (need sudo)
sudo apt install build-essential git autoconf texinfo libgtk-3-dev libgnutls28-dev \
  libtree-sitter-dev libjansson-dev libgccjit-dev libmagickwand-dev libxpm-dev \
  libjpeg-dev libgif-dev libtiff-dev librsvg2-dev libsqlite3-dev unzip curl \
  fontconfig fonts-noto-core
```

Before running bootstrap, install and activate **Node 20+ with npm**, **Rust via
rustup**, and a **JDK 21+**. Their commands must be available in the terminal
running bootstrap. Install and sign in to Copilot CLI separately if you use
`SPC o c`; `copilot` must be on PATH.

```bash
# Clone the branch containing the configuration described here.
git clone --branch latest-from-work \
  https://github.com/emiltomov/doom-emacs-setup-and-config.git ~/.config/doom

export PATH="$HOME/.local/bin:$HOME/.config/emacs/bin:$PATH"
~/.config/doom/bootstrap.sh

emacs --daemon
emacsclient -c
```

Keep the PATH export in your shell startup configuration for later sessions.
`bootstrap.sh` builds Emacs 31 into `~/.local` unless a version 31 installation
is already available, installs Doom at `~/.config/emacs`, installs JetBrains Mono
and Symbols Nerd Font, provisions CLI tools and language servers, runs
`doom sync`, and then builds tree-sitter grammars. It can be rerun.

**A clone reproduces the configuration, not a fully locked installation.**
Use the same Git commit on both devices for identical configuration files.
Bootstrap follows the Emacs 31 branch, Doom's default branch, and several latest
upstream releases, so dependency versions can differ between installations.
The grammar pins in `ts-grammars.el` address Emacs 31.1.50 ABI compatibility.

## What stays machine-local

- Installed Emacs, Doom, packages, fonts, and language servers are outside this
  repository, principally under `~/.local/` and `~/.config/emacs/`. Bootstrap
  recreates these rather than Git copying them.
- `custom.el` and `.agent-shell/` are gitignored. Saved desktops, workspaces, and
  window-layout state live in Doom's local data/cache directories and do not
  transfer with a clone. The configured Git sidebar and diff-window behavior
  do transfer.
- Shell setup, Rust/Node/JDK installations, Git configuration (including its
  default editor), credentials, and Copilot sign-in must be set up separately.

## Appearance and Git layout

The local `themes/doom-jetbrains-theme.el` supplies charcoal editor/sidebar
backgrounds, restrained syntax colors, flat tabs, and green/red diff highlights.
Code uses JetBrains Mono 14; interface text uses Noto Sans 13.

`M-x magit-status` opens a changes sidebar on the left. `RET` on a tracked change
opens its syntax-highlighted diff in a separate, reusable native window; untracked
files open in the editor. Commit-message buffers appear below the changes list.
`q` closes the diff window and returns to its originating window, or closes the
status sidebar when used there. Standard Magit staging and commit commands remain
available. Separate native diff windows require a graphical session; terminal
sessions use ordinary Emacs windows.

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

## Terminal editor keys

In `ansi-term`, press `C-x C-x` (hold Ctrl and press X twice) to send a literal
`Ctrl+X` to nano, then answer nano's save prompt. If the buffer is in line mode,
first run `M-x term-char-mode` so input is forwarded to the terminal application.
