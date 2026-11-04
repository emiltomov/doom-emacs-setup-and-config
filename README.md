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
  fontconfig fonts-noto-core kitty pandoc cmake libvterm-dev libtool-bin \
  libxml2-dev
```

Before running bootstrap, install and activate **Node 22.13+ with npm**, **Rust via
rustup**, and a **JDK 21+**. Their commands must be available in the terminal
running bootstrap. Install and sign in to Copilot CLI separately if you use
`C-c o c`; `copilot` must be on PATH.
For Mermaid diagrams, install Chrome or Chromium and put its launcher on PATH.
Bootstrap installs Mermaid CLI without downloading another browser.

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
files open in the editor. A dedicated commit-message pane appears below the
changes list. Write your draft there, then click **Commit**, press `C-c C-c`,
or use Magit's usual `c c`. Magit copies the draft into its normal commit
editor; `C-c C-c` there finishes the commit, and `C-c C-k` cancels.

Drafts are separate for each repository/worktree and stored in its Git metadata
as `DOOM_COMMIT_DRAFT` (never staged). `C-x C-s` saves an unfinished draft for
later sessions; closing the status sidebar also saves it. Successful commits
clear the draft; cancellation or failure keeps it. Existing amend, merge, rebase
and template messages are not overwritten.
`M-x my/magit-commit-message` opens the pane directly.

`q` closes the diff window and returns to its originating window, or closes the
status sidebar and its draft pane when used there. Standard Magit staging and
commit commands remain available. Separate native diff windows require a
graphical session; terminal sessions use ordinary Emacs windows.

Restart Emacs after applying these settings; no `doom sync` is needed for changes
to `config.el`, `magit-frame.el`, or the local theme.

## Custom keybindings

Evil is disabled in this configuration: the Doom leader is `C-c` and the local
leader is `C-c l`, rather than `SPC` and `SPC m`.

| Keys | Action | Where |
|------|--------|-------|
| `C-c o c` | Copilot CLI (agent-shell) | global |
| `C-c o d` | Open dashboard | global |
| `C-c o k` | Open Kitty at the project root | global |
| `C-c o t` | Toggle terminal inside Emacs (vterm) | global |
| `C-c l p` | Render Markdown in an Emacs preview pane | Markdown |
| `F8` | Toggle Treemacs | global |
| `C-<next>` / `C-<tab>` | Next tab (centaur-tabs) | global |
| `C-<prior>` / `C-S-<iso-lefttab>` | Previous tab | global |
| `RET` | Open changed-file diff in a separate native window | Magit status |
| `C-c C-c` | Review draft / finish the actual commit | Commit-message pane |
| `q` | Close diff window / quit status sidebar | Magit |
| `C-c h` | Show Rust docs in popup near cursor (eldoc-box) | rust-mode / rust-ts-mode |
| `C-S-t t` or `C-S-t C-S-t` | Go to implementation (Eglot) | rust-mode / rust-ts-mode |

Doom defaults used with Rust/Eglot: `gd` definition, `gD` references, `gI` implementation, `K` docs.

## Dashboard and session restoration

The menu bar and project-grouped tabs are enabled. `C-c o d`
(`M-x my/open-dashboard`) opens the dashboard at any time. It is also available
in the workspace buffer list and shown when there is no saved editor layout.
A saved layout takes priority at startup so the dashboard does not replace an
open file or remove a split.

The last main editor layout, selected workspace, and local file buffers are
saved before closing the editor frame or quitting Emacs normally. Background
layout and desktop autosaves are disabled. On restart, buffers are loaded
before the saved splits are restored; Treemacs, Magit status, Markdown previews,
and vterm panes are recreated. Reopening a client after closing the last editor
frame also restores the layout. Child popups and native Git diff windows are not
restored and cannot overwrite the main layout.
Split proportions adapt to the current frame size, and diagram images fit their
restored panes. Explicitly opening a file with an `emacsclient +LINE:COLUMN`
argument retains that requested position.

This state stays local under Doom's cache directory (`layout.eld`,
`workspaces.eld`, and `desktop/`); it is not part of a Git clone. A crash or
`kill -9` can recover only the snapshot from the last normal exit/frame close.
Terminal panes start new shells:
running jobs and other process sessions cannot resume after Emacs exits. Remote
buffers are not automatically reopened. Save file edits normally; layout
snapshots do not store unsaved buffer text.

## Terminals and Markdown preview

`C-c o k` (`M-x my/open-kitty`) launches Kitty in a separate native window at the
current project root, falling back to the buffer's directory outside a project.
Use `C-u C-c o k` to use the current directory instead. Kitty is a standalone
application, not an Emacs-buffer terminal; remote/TRAMP directories are rejected.
For a terminal inside Emacs, use `C-c o t` (`M-x +vterm/toggle`).

In a Markdown buffer, `C-c l p` (`M-x my/markdown-preview`) renders the current
contents, including unsaved edits, in a read-only pane on the right. Pandoc and
Emacs' built-in HTML renderer do the work locally; no GitHub API or preview server
is used, and no HTML files are written into the project. Press `g` in the preview
to refresh or `q` to close it. Relative links and images resolve from the source
directory.

Fenced `mermaid` blocks render locally as SVG diagrams, including flowcharts and
sequence diagrams. Rendering uses Mermaid CLI with Chrome/Chromium and keeps the
browser sandbox enabled; no diagram or Markdown service receives the document.
Generated SVGs are cached under Doom's `markdown-diagrams/` cache directory.
Invalid diagrams show their source plus an error; other Markdown still renders.
Diagram images require graphical Emacs.

On an existing installation, install Mermaid CLI once with an active Node 22.13+:

```bash
PUPPETEER_SKIP_DOWNLOAD=1 npm install --prefix "$HOME/.local/share/mermaid" \
  @mermaid-js/mermaid-cli
ln -sf "$HOME/.config/doom/bin/mmdc" "$HOME/.local/bin/mmdc"
```

The tracked `bin/mmdc` wrapper selects Node 22.13+ from nvm if Emacs inherits an
older default. Install Chrome or Chromium separately if neither is available.

On an existing installation, install the new dependencies and sync once:

```bash
sudo apt install kitty pandoc cmake libvterm-dev libtool-bin libxml2-dev
~/.config/emacs/bin/doom sync
```

Restart Emacs afterward to enable vterm. Its native module builds on first use
and needs CMake, Make, and a C compiler. Markdown preview requires an Emacs build
with libxml2 support; installing `libxml2-dev` only helps when building Emacs.

## Terminal editor keys

In `ansi-term`, press `C-x C-x` (hold Ctrl and press X twice) to send a literal
`Ctrl+X` to nano, then answer nano's save prompt. If the buffer is in line mode,
first run `M-x term-char-mode` so input is forwarded to the terminal application.
In vterm, use `C-q C-x` to forward nano's `Ctrl+X` instead.
